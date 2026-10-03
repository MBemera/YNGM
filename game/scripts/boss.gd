class_name Boss
extends Enemy

const VOLLEY_SPEED := 17.0
const VOLLEY_SPREAD_RADIANS := 0.55
const SLAM_WIND_UP_SECONDS := 0.9
const SLAM_RADIUS := 8.0
const SLAM_HEIGHT_TOLERANCE := 2.5
const CHARGE_SECONDS := 1.1
const CHARGE_SPEED_MULTIPLIER := 3.2
const CHARGE_HIT_DISTANCE := 2.2
const MAX_SUMMONS_ALIVE := 4
const SUMMON_COUNT := 2
const SUMMON_DISTANCE := 3.5
const ENRAGE_HEALTH_FRACTION := 0.5
const ENRAGE_COOLDOWN_MULTIPLIER := 0.65
const ENRAGE_EXTRA_VOLLEY := 2
const BOSS_BURST_SHOTS := 6
const ENRAGED_TINT := Color(1.0, 0.15, 0.1, 0.22)

var spawner: Callable
var attack_cycle_index := 0
var slam_wind_up_left := 0.0
var charge_left := 0.0
var has_charge_hit := false
var summons: Array[Enemy] = []
var is_enraged := false


func get_attack_cooldown() -> float:
	var cooldown := super.get_attack_cooldown()
	return cooldown * ENRAGE_COOLDOWN_MULTIPLIER if is_enraged else cooldown


func get_burst_shot_count() -> int:
	return BOSS_BURST_SHOTS


func claim_ranged_attack_slot() -> bool:
	return true


func start_attack() -> void:
	var attacks: Array = config["boss_attacks"]
	var attack_name: String = attacks[attack_cycle_index % attacks.size()]
	attack_cycle_index += 1
	attack_cooldown_left = get_attack_cooldown()
	attack_animation_left = ATTACK_ANIMATION_SECONDS
	play_animation("attack")
	match attack_name:
		"volley":
			fire_volley()
		"burst":
			wind_up_left = BURST_WIND_UP_SECONDS
			AudioBank.play_at(get_parent(), AudioBank.BEAM, get_attack_origin(), 0.4, 0.0)
		"slam":
			start_slam()
		"charge":
			start_charge()
		"summon":
			summon_minions()


func update_movement(delta: float) -> void:
	if slam_wind_up_left > 0.0:
		stop_moving()
		return
	if charge_left > 0.0:
		update_charge(delta)
		return
	super.update_movement(delta)


func update_attack(delta: float) -> void:
	update_slam(delta)
	if slam_wind_up_left > 0.0 or charge_left > 0.0:
		return
	super.update_attack(delta)


func fire_volley() -> void:
	var count: int = config.get("volley_count", 5) + (ENRAGE_EXTRA_VOLLEY if is_enraged else 0)
	var origin := get_attack_origin()
	var center_direction := get_aim_direction(origin, VOLLEY_SPEED)
	var volley_color: Color = config.get("volley_color", Color(0.97, 0.97, 0.94))
	var volley_size: Vector3 = config.get("volley_size", Vector3(0.4, 0.03, 0.5))
	for shot_index: int in count:
		var offset := lerpf(-VOLLEY_SPREAD_RADIANS, VOLLEY_SPREAD_RADIANS, float(shot_index) / maxi(count - 1, 1))
		var direction := center_direction.rotated(Vector3.UP, offset)
		var projectile := Projectile.spawn(get_parent(), origin, direction * VOLLEY_SPEED, get_attack_damage(), PROJECTILE_MASK, self, volley_size, volley_color, 3.0)
		projectile.spin_degrees_per_second = 720.0
	AudioBank.play_at(get_parent(), AudioBank.THROW, origin, 0.8, 4.0)


func start_slam() -> void:
	slam_wind_up_left = SLAM_WIND_UP_SECONDS
	show_bubble("!!!")
	Effects.spawn_flash(get_parent(), global_position + Vector3.UP, Color(1.0, 0.4, 0.1), 6.0, SLAM_RADIUS, SLAM_WIND_UP_SECONDS)


func update_slam(delta: float) -> void:
	if slam_wind_up_left <= 0.0:
		return
	slam_wind_up_left -= delta
	if slam_wind_up_left <= 0.0:
		land_slam()


func land_slam() -> void:
	var feet := global_position + Vector3.UP * 0.3
	Effects.spawn_shockwave(get_parent(), feet, Color(1.0, 0.55, 0.15, 0.35), SLAM_RADIUS, 0.45)
	Effects.spawn_spark_burst(get_parent(), feet, Color(1.0, 0.7, 0.2), 70)
	AudioBank.play_at(get_parent(), AudioBank.SLAM, feet, 1.0, 6.0)
	var offset := target.global_position - global_position
	var horizontal_distance := Vector2(offset.x, offset.z).length()
	if horizontal_distance <= SLAM_RADIUS and absf(offset.y) <= SLAM_HEIGHT_TOLERANCE and target.is_targetable():
		target.take_damage(Difficulty.scale_damage(config.get("slam_damage", 4)))
		target.shake_camera(0.15)


func start_charge() -> void:
	charge_left = CHARGE_SECONDS
	has_charge_hit = false
	show_bubble("CHARGE!")


func update_charge(delta: float) -> void:
	charge_left -= delta
	var flat_offset := target.global_position - global_position
	flat_offset.y = 0.0
	face_toward(flat_offset)
	var speed: float = config["move_speed"] * Difficulty.get_value("enemy_speed") * CHARGE_SPEED_MULTIPLIER
	var direction := flat_offset.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not has_charge_hit and flat_offset.length() < CHARGE_HIT_DISTANCE and target.is_targetable():
		has_charge_hit = true
		charge_left = 0.0
		target.take_damage(get_attack_damage() + 1)
		target.shake_camera(0.1)
		AudioBank.play_at(get_parent(), AudioBank.HIT, global_position + Vector3.UP, 0.5, 2.0)


func summon_minions() -> void:
	if not spawner.is_valid() or summons.size() >= MAX_SUMMONS_ALIVE:
		fire_volley()
		return
	var summon_types: Array = config.get("summon_types", ["vc"])
	for summon_index: int in SUMMON_COUNT:
		var angle := TAU * summon_index / SUMMON_COUNT + randf() * 0.6
		var spawn_position := global_position + Vector3(cos(angle), 0.3, sin(angle)) * SUMMON_DISTANCE
		var minion: Enemy = spawner.call({"type": summon_types[summon_index % summon_types.size()], "position": spawn_position})
		minion.engage_silently()
		minion.defeated.connect(_on_minion_defeated)
		summons.append(minion)
		Effects.spawn_confetti_burst(get_parent(), spawn_position + Vector3.UP, 20)
	show_bubble(config.get("summon_line", "Associates!"))


func _on_minion_defeated(minion: Enemy) -> void:
	summons.erase(minion)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if is_enraged or state == State.DEFEATED:
		return
	if float(health) / max_health <= ENRAGE_HEALTH_FRACTION:
		become_enraged()


func become_enraged() -> void:
	is_enraged = true
	base_overlay_color = ENRAGED_TINT
	set_overlay_attached(true)
	overlay_material.albedo_color = ENRAGED_TINT
	show_bubble(config.get("enrage_line", "Now I'm angry!"))
	AudioBank.play_at(get_parent(), AudioBank.ALARM, global_position, 0.7, -2.0)
