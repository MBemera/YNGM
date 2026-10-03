class_name Enemy
extends CharacterBody3D

signal defeated(enemy: Enemy)

enum State { IDLE, ENGAGED, DEFEATED }

const YELL_LINES: Array[String] = ["Don't get left behind!", "You're not gonna make it!"]
const HURT_LINES: Array[String] = ["Ow! My valuation!", "That's not in the term sheet!"]
const SLOP_LINES: Array[String] = ["It doesn't even compile!", "Who wrote this?!"]
const STUN_BUBBLE := "[REDACTED]"
const ENEMY_GROUP := "enemies"
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4
const PROJECTILE_MASK := WORLD_LAYER | PLAYER_LAYER
const GRAVITY := 14.0
const SIGHT_RANGE := 28.0
const SAME_LEVEL_TOLERANCE := 4.5
const ALERT_RADIUS := 14.0
const EYE_HEIGHT := 1.6
const BUBBLE_SECONDS := 2.2
const MIN_MSEC_BETWEEN_ANY_YELLS := 1200
const VOICE_VOLUME_DB := 4.0
const HURT_BARK_SECONDS := 3.0
const HURT_BARK_CHANCE := 0.6
const WRECK_DISTANCE := 5.0
const WRECK_HEIGHT := 3.0
const WRECK_SECONDS := 1.1
const MIN_MSEC_BETWEEN_RANGED_ATTACKS := 350
const REACTION_SECONDS_MIN := 0.45
const REACTION_SECONDS_MAX := 0.9
const REPATH_SECONDS := 0.3
const STRAFE_SWITCH_SECONDS_MIN := 1.2
const STRAFE_SWITCH_SECONDS_MAX := 2.8
const STUCK_SECONDS := 0.8
const SEPARATION_RADIUS := 1.6
const SEPARATION_WEIGHT := 0.9
const SEPARATION_HEIGHT_TOLERANCE := 1.5
const TERM_SHEET_SPEED := 15.0
const HYPE_BEAM_SPEED := 26.0
const BURST_SHOT_COUNT := 3
const BURST_SHOT_INTERVAL := 0.15
const BURST_WIND_UP_SECONDS := 0.45
const MELEE_WIND_UP_SECONDS := 0.25
const LUNGE_RANGE := 5.0
const LUNGE_SECONDS := 0.6
const LUNGE_SPEED_MULTIPLIER := 1.6
const LUNGE_COOLDOWN_SECONDS := 2.5
const ATTACK_ANIMATION_SECONDS := 0.6
const MOVING_SPEED_THRESHOLD := 0.3
const ANIMATION_BLEND_SECONDS := 0.15
const HOT_TAKE_SPEED := 18.0
const FAN_SPREAD_RADIANS := 0.32
const DEFAULT_COLLISION_RADIUS := 0.4
const DEFAULT_COLLISION_HEIGHT := 1.8
const FLASH_SECONDS := 0.1
const STUN_COLOR := Color(0.05, 0.05, 0.05, 0.55)

static var last_yell_msec := -100000
static var next_ranged_attack_msec := 0

var type_id := ""
var config: Dictionary = {}
var display_name := ""
var voice_name := ""
var target: Player
var health := 1
var max_health := 1
var stun_left := 0.0
var overlay_material: StandardMaterial3D
var base_overlay_color := Color(0, 0, 0, 0)
var state := State.IDLE
var attack_cooldown_left := 0.0
var wind_up_left := 0.0
var burst_shots_left := 0
var burst_interval_left := 0.0
var lunge_left := 0.0
var lunge_cooldown_left := 0.0
var yell_cooldown_left := 0.0
var hurt_cooldown_left := 0.0
var is_slopped := false
var blast_origin := Vector3.ZERO
var bubble_seconds_left := 0.0
var repath_left := 0.0
var strafe_direction := 1.0
var strafe_switch_left := 0.0
var stuck_time := 0.0
var attack_animation_left := 0.0
var model: Node3D
var animation_player: AnimationPlayer
var navigation_agent: NavigationAgent3D
var bubble: Label3D
var punch_tween: Tween


func setup(enemy_type_id: String, player_target: Player, health_scale := 1.0, display_name_override := "") -> void:
	type_id = enemy_type_id
	config = EnemyTypes.CONFIGS[enemy_type_id]
	target = player_target
	display_name = display_name_override if display_name_override != "" else config["display_name"]
	max_health = maxi(1, roundi(config["health"] * health_scale * Difficulty.get_value("enemy_health")))
	health = max_health
	strafe_direction = 1.0 if randf() < 0.5 else -1.0


func _ready() -> void:
	add_to_group(ENEMY_GROUP)
	collision_layer = ENEMY_LAYER
	collision_mask = WORLD_LAYER | PLAYER_LAYER | ENEMY_LAYER
	add_collision_shape()
	var model_file := EnemyModels.pick_model_file(type_id)
	voice_name = EnemyTypes.pick_voice(type_id, model_file)
	model = EnemyModels.build(type_id, model_file, self)
	apply_overlay_material()
	setup_animations()
	navigation_agent = create_navigation_agent()
	add_name_tag()
	bubble = create_bubble()


func _physics_process(delta: float) -> void:
	if state == State.DEFEATED:
		return
	update_bubble(delta)
	apply_gravity(delta)
	if state == State.IDLE and can_see_target():
		engage()
	if is_stunned():
		update_stun(delta)
	elif state == State.ENGAGED:
		update_movement(delta)
		update_attack(delta)
		update_yelling(delta)
	var intended_speed := Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	update_stuck_detection(intended_speed, delta)
	update_animation(delta)


static func alert_enemies_near(tree: SceneTree, origin: Vector3, radius: float) -> void:
	for node: Node in tree.get_nodes_in_group(ENEMY_GROUP):
		var enemy := node as Enemy
		if enemy != null and enemy.state == State.IDLE and enemy.is_within_alert_range(origin, radius):
			enemy.engage_silently()


func is_within_alert_range(origin: Vector3, radius: float) -> bool:
	var offset := origin - global_position
	return absf(offset.y) <= SAME_LEVEL_TOLERANCE and offset.length() <= radius


func add_collision_shape() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = config.get("collision_radius", DEFAULT_COLLISION_RADIUS)
	shape.height = config.get("collision_height", DEFAULT_COLLISION_HEIGHT)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, shape.height / 2.0, 0)
	add_child(collision)


func apply_overlay_material() -> void:
	overlay_material = StandardMaterial3D.new()
	overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	base_overlay_color = config.get("tint", Color(0, 0, 0, 0))
	overlay_material.albedo_color = base_overlay_color
	set_overlay_attached(base_overlay_color.a > 0.0)


func set_overlay_attached(is_attached: bool) -> void:
	var overlay: Material = overlay_material if is_attached else null
	for mesh_instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh_instance.material_overlay = overlay


func detach_overlay_if_idle() -> void:
	if get_resting_overlay_color().a <= 0.0:
		set_overlay_attached(false)


func flash_hit() -> void:
	set_overlay_attached(true)
	overlay_material.albedo_color = Color(1, 1, 1, 0.7)
	var tween := create_tween()
	tween.tween_property(overlay_material, "albedo_color", get_resting_overlay_color(), FLASH_SECONDS)
	tween.tween_callback(detach_overlay_if_idle)


func get_resting_overlay_color() -> Color:
	return STUN_COLOR if is_stunned() else base_overlay_color


func create_navigation_agent() -> NavigationAgent3D:
	var agent := NavigationAgent3D.new()
	agent.radius = 0.45
	agent.height = 1.8
	agent.path_desired_distance = 0.7
	agent.target_desired_distance = 0.9
	add_child(agent)
	return agent


func setup_animations() -> void:
	animation_player = Models.find_animation_player(model)
	if animation_player == null:
		return
	var animations: Dictionary = config["animations"]
	Models.loop_animations(animation_player, [animations["idle"], animations["move"], animations["exit"]])
	play_animation("idle")


func play_animation(animation_key: String) -> void:
	if animation_player == null:
		return
	var animation_name: String = config["animations"][animation_key]
	if animation_player.current_animation == animation_name or not animation_player.has_animation(animation_name):
		return
	animation_player.play(animation_name, ANIMATION_BLEND_SECONDS)


func update_animation(delta: float) -> void:
	if attack_animation_left > 0.0:
		attack_animation_left -= delta
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	play_animation("move" if horizontal_speed > MOVING_SPEED_THRESHOLD else "idle")


func add_name_tag() -> void:
	var model_height: float = config["model_height"]
	var name_tag := LevelBuilder.add_sign(self, display_name, Vector3(0, model_height + 0.35, 0), 0.0, 28, Color(1, 1, 1, 0.85))
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.outline_size = 6


func create_bubble() -> Label3D:
	var model_height: float = config["model_height"]
	var speech_bubble := LevelBuilder.add_sign(self, "", Vector3(0, model_height + 0.8, 0), 0.0, 56, Color(1.0, 0.95, 0.4))
	speech_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	speech_bubble.fixed_size = true
	speech_bubble.pixel_size = 0.0011
	speech_bubble.visible = false
	return speech_bubble


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func engage() -> void:
	engage_silently()
	yell()
	alert_enemies_near(get_tree(), global_position, ALERT_RADIUS)


func engage_silently() -> void:
	if state != State.IDLE:
		return
	state = State.ENGAGED
	attack_cooldown_left = randf_range(REACTION_SECONDS_MIN, REACTION_SECONDS_MAX) * Difficulty.get_value("enemy_reaction")
	yell_cooldown_left = randf_range(1.5, 4.0)


func can_see_target() -> bool:
	if target == null or not target.is_targetable():
		return false
	var offset := target.global_position - global_position
	if absf(offset.y) > SAME_LEVEL_TOLERANCE or offset.length() > SIGHT_RANGE:
		return false
	return has_line_of_sight()


func has_line_of_sight() -> bool:
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var target_eye := target.global_position + Vector3.UP * EYE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(eye, target_eye, WORLD_LAYER)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func update_movement(delta: float) -> void:
	if not target.is_targetable() or wind_up_left > 0.0:
		stop_moving()
		return
	var flat_offset := target.global_position - global_position
	flat_offset.y = 0.0
	face_toward(flat_offset)
	update_strafe_timer(delta)
	update_lunge(flat_offset.length(), delta)
	repath_left -= delta
	if repath_left <= 0.0:
		repath_left = REPATH_SECONDS
		navigation_agent.target_position = choose_destination(flat_offset)
	var move_direction := (get_path_direction() + get_separation() * SEPARATION_WEIGHT).normalized()
	var base_speed: float = config["move_speed"] * Difficulty.get_value("enemy_speed")
	var speed := base_speed * (LUNGE_SPEED_MULTIPLIER if lunge_left > 0.0 else 1.0)
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed


func stop_moving() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func update_strafe_timer(delta: float) -> void:
	strafe_switch_left -= delta
	if strafe_switch_left > 0.0:
		return
	strafe_switch_left = randf_range(STRAFE_SWITCH_SECONDS_MIN, STRAFE_SWITCH_SECONDS_MAX)
	strafe_direction *= -1.0


func update_lunge(distance: float, delta: float) -> void:
	lunge_left -= delta
	lunge_cooldown_left -= delta
	if config["attack"] != "melee" or lunge_cooldown_left > 0.0 or distance > LUNGE_RANGE:
		return
	if has_line_of_sight():
		lunge_left = LUNGE_SECONDS
		lunge_cooldown_left = LUNGE_COOLDOWN_SECONDS


func choose_destination(flat_offset: Vector3) -> Vector3:
	if config["attack"] == "melee":
		return choose_melee_destination(flat_offset)
	return choose_ranged_destination(flat_offset)


func choose_melee_destination(flat_offset: Vector3) -> Vector3:
	if flat_offset.length() < 6.0:
		return target.global_position
	var flank_offset := flat_offset.normalized().cross(Vector3.UP) * strafe_direction * 3.0
	return target.global_position + flank_offset


func choose_ranged_destination(flat_offset: Vector3) -> Vector3:
	var distance := flat_offset.length()
	var min_range: float = config["min_range"]
	var max_range: float = config["max_range"]
	if not has_line_of_sight() or distance > max_range:
		return target.global_position
	if distance < min_range:
		return global_position - flat_offset.normalized() * 5.0
	return global_position + flat_offset.normalized().cross(Vector3.UP) * strafe_direction * 3.0


func get_path_direction() -> Vector3:
	if not is_navigation_map_ready():
		return get_flat_direction_to(navigation_agent.target_position)
	if navigation_agent.is_navigation_finished():
		return Vector3.ZERO
	return get_flat_direction_to(navigation_agent.get_next_path_position())


func is_navigation_map_ready() -> bool:
	return NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0


func get_flat_direction_to(point: Vector3) -> Vector3:
	var direction := point - global_position
	direction.y = 0.0
	return direction.normalized() if direction.length_squared() > 0.01 else Vector3.ZERO


func get_separation() -> Vector3:
	var push := Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var other := node as Enemy
		if other == null or other == self or other.state == State.DEFEATED:
			continue
		var offset := global_position - other.global_position
		if absf(offset.y) > SEPARATION_HEIGHT_TOLERANCE:
			continue
		offset.y = 0.0
		var distance := offset.length()
		if distance > 0.01 and distance < SEPARATION_RADIUS:
			push += offset / distance * (SEPARATION_RADIUS - distance) / SEPARATION_RADIUS
	return push


func update_stuck_detection(intended_speed: float, delta: float) -> void:
	var wants_to_move := intended_speed > MOVING_SPEED_THRESHOLD
	var actual_speed := get_real_velocity()
	if not wants_to_move or Vector2(actual_speed.x, actual_speed.z).length() > 0.4:
		stuck_time = 0.0
		return
	stuck_time += delta
	if stuck_time > STUCK_SECONDS:
		stuck_time = 0.0
		strafe_direction *= -1.0
		repath_left = 0.0


func face_toward(flat_direction: Vector3) -> void:
	if flat_direction.length_squared() < 0.01:
		return
	model.rotation.y = atan2(-flat_direction.x, -flat_direction.z)


func update_attack(delta: float) -> void:
	attack_cooldown_left -= delta
	update_wind_up(delta)
	update_burst(delta)
	if attack_cooldown_left > 0.0 or wind_up_left > 0.0 or burst_shots_left > 0:
		return
	if not target.is_targetable() or not is_target_in_attack_range():
		return
	if config["attack"] != "melee" and not claim_ranged_attack_slot():
		return
	start_attack()


func is_target_in_attack_range() -> bool:
	var attack_range: float = config["attack_range"]
	if global_position.distance_to(target.global_position) > attack_range:
		return false
	return has_line_of_sight()


func claim_ranged_attack_slot() -> bool:
	var now_msec := Time.get_ticks_msec()
	if now_msec < next_ranged_attack_msec:
		return false
	next_ranged_attack_msec = now_msec + MIN_MSEC_BETWEEN_RANGED_ATTACKS
	return true


func start_attack() -> void:
	attack_cooldown_left = get_attack_cooldown()
	attack_animation_left = ATTACK_ANIMATION_SECONDS
	play_animation("attack")
	match config["attack"]:
		"melee":
			wind_up_left = MELEE_WIND_UP_SECONDS
		"throw":
			throw_term_sheet()
		"fan":
			fire_hot_takes(config.get("fan_count", 3))
		"burst":
			wind_up_left = BURST_WIND_UP_SECONDS
			AudioBank.play_at(get_parent(), AudioBank.BEAM, global_position + Vector3.UP * 1.4, 0.5, -2.0)


func get_attack_cooldown() -> float:
	var base_cooldown: float = config["attack_cooldown"]
	return base_cooldown * randf_range(0.8, 1.25) * Difficulty.get_value("enemy_attack_cooldown")


func get_attack_damage() -> int:
	return Difficulty.scale_damage(config["damage"])


func get_attack_origin() -> Vector3:
	var model_height: float = config["model_height"]
	return global_position + Vector3.UP * model_height * 0.8


func update_wind_up(delta: float) -> void:
	if wind_up_left <= 0.0:
		return
	wind_up_left -= delta
	if wind_up_left > 0.0:
		return
	if config["attack"] == "melee":
		finish_melee_attack()
	else:
		burst_shots_left = get_burst_shot_count()
		burst_interval_left = 0.0


func get_burst_shot_count() -> int:
	return BURST_SHOT_COUNT


func finish_melee_attack() -> void:
	var attack_range: float = config["attack_range"]
	if global_position.distance_to(target.global_position) > attack_range + 0.5:
		return
	if not target.is_targetable() or not has_line_of_sight():
		return
	target.take_damage(get_attack_damage())
	AudioBank.play_at(get_parent(), AudioBank.HIT, global_position + Vector3.UP, 0.7)
	punch_model()


func update_burst(delta: float) -> void:
	if burst_shots_left <= 0:
		return
	burst_interval_left -= delta
	if burst_interval_left > 0.0:
		return
	burst_interval_left = BURST_SHOT_INTERVAL
	burst_shots_left -= 1
	fire_hype_beam()


func throw_term_sheet() -> void:
	var origin := get_attack_origin()
	var launch_velocity := get_aim_direction(origin, TERM_SHEET_SPEED) * TERM_SHEET_SPEED
	var projectile := Projectile.spawn(get_parent(), origin, launch_velocity, get_attack_damage(), PROJECTILE_MASK, self, Vector3(0.35, 0.02, 0.45), Color(0.97, 0.97, 0.94), 3.0)
	projectile.spin_degrees_per_second = 900.0
	AudioBank.play_at(get_parent(), AudioBank.THROW, origin)


func fire_hype_beam() -> void:
	var origin := get_attack_origin()
	var launch_velocity := get_aim_direction(origin, HYPE_BEAM_SPEED) * HYPE_BEAM_SPEED
	Projectile.spawn(get_parent(), origin, launch_velocity, get_attack_damage(), PROJECTILE_MASK, self, Vector3(0.07, 0.07, 0.9), LevelBuilder.NEON_CYAN, 2.0)
	AudioBank.play_at(get_parent(), AudioBank.BEAM, origin, randf_range(0.9, 1.1), -4.0)


func fire_hot_takes(count: int) -> void:
	var origin := get_attack_origin()
	var center_direction := get_aim_direction(origin, HOT_TAKE_SPEED)
	for shot_index: int in count:
		var offset := 0.0 if count == 1 else lerpf(-FAN_SPREAD_RADIANS, FAN_SPREAD_RADIANS, float(shot_index) / (count - 1))
		var direction := center_direction.rotated(Vector3.UP, offset)
		Projectile.spawn(get_parent(), origin, direction * HOT_TAKE_SPEED, get_attack_damage(), PROJECTILE_MASK, self, Vector3(0.22, 0.22, 0.22), Color(1.0, 0.35, 0.1), 2.5)
	AudioBank.play_at(get_parent(), AudioBank.THROW, origin, 1.3)


func get_aim_direction(origin: Vector3, projectile_speed: float) -> Vector3:
	var aim_error: float = config["aim_error"] * Difficulty.get_value("enemy_aim_error")
	var target_point := target.global_position + Vector3.UP * 1.1
	var predicted_point := EnemyAim.predict_intercept(origin, target_point, target.velocity, projectile_speed)
	return EnemyAim.add_spread((predicted_point - origin).normalized(), aim_error)


func take_damage(amount: int) -> void:
	if state == State.DEFEATED:
		return
	health -= amount
	punch_model()
	flash_hit()
	var model_height: float = config["model_height"]
	Effects.spawn_damage_number(get_parent(), global_position + Vector3.UP * (model_height + 0.2), amount)
	AudioBank.play_at(get_parent(), AudioBank.HIT, global_position + Vector3.UP, randf_range(0.9, 1.2), -4.0)
	if state == State.IDLE:
		engage()
	if health <= 0:
		defeat()
	else:
		react_to_hit()


func take_slop_hit(amount: int, origin: Vector3) -> void:
	is_slopped = true
	blast_origin = origin
	take_damage(amount)
	if state != State.DEFEATED:
		is_slopped = false


func stun(seconds: float) -> void:
	if state == State.DEFEATED:
		return
	var resistance: float = config.get("stun_resistance", 1.0)
	stun_left = maxf(stun_left, seconds * resistance)
	wind_up_left = 0.0
	burst_shots_left = 0
	lunge_left = 0.0
	stop_moving()
	set_overlay_attached(true)
	overlay_material.albedo_color = STUN_COLOR
	show_bubble(STUN_BUBBLE)
	bubble_seconds_left = stun_left
	if state == State.IDLE:
		engage_silently()
	if claim_voice_slot():
		var clip := AudioBank.get_voice_clip(voice_name, AudioBank.STUN_LINE_IDS[0])
		AudioBank.play_at(self, clip, global_position + Vector3.UP * EYE_HEIGHT, config["voice_pitch"], VOICE_VOLUME_DB - 4.0)


func is_stunned() -> bool:
	return stun_left > 0.0


func update_stun(delta: float) -> void:
	stop_moving()
	stun_left -= delta
	if stun_left <= 0.0:
		overlay_material.albedo_color = base_overlay_color
		detach_overlay_if_idle()
		bubble.visible = false


func react_to_hit() -> void:
	if hurt_cooldown_left > 0.0 or randf() > HURT_BARK_CHANCE or not claim_voice_slot():
		return
	hurt_cooldown_left = HURT_BARK_SECONDS
	var line_index := randi() % HURT_LINES.size()
	speak(HURT_LINES[line_index], AudioBank.HURT_LINE_IDS[line_index])


func punch_model() -> void:
	if punch_tween != null:
		punch_tween.kill()
	model.scale = Vector3.ONE * 1.15
	punch_tween = create_tween()
	punch_tween.tween_property(model, "scale", Vector3.ONE, 0.12)


func yell() -> void:
	yell_cooldown_left = randf_range(5.0, 9.0)
	if not claim_voice_slot():
		return
	var line_index := randi() % YELL_LINES.size()
	speak(YELL_LINES[line_index], AudioBank.YELL_LINE_IDS[line_index])


func claim_voice_slot() -> bool:
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_yell_msec < MIN_MSEC_BETWEEN_ANY_YELLS:
		return false
	last_yell_msec = now_msec
	return true


func speak(text: String, line_id: String) -> void:
	show_bubble(text)
	var clip := AudioBank.get_voice_clip(voice_name, line_id)
	AudioBank.play_at(self, clip, global_position + Vector3.UP * EYE_HEIGHT, config["voice_pitch"], VOICE_VOLUME_DB)


func speak_last_words(text: String, line_id: String) -> void:
	show_bubble(text)
	var clip := AudioBank.get_voice_clip(voice_name, line_id)
	AudioBank.play_at(get_parent(), clip, global_position + Vector3.UP * EYE_HEIGHT, config["voice_pitch"], VOICE_VOLUME_DB)


func update_yelling(delta: float) -> void:
	yell_cooldown_left -= delta
	hurt_cooldown_left -= delta
	if yell_cooldown_left <= 0.0 and can_see_target():
		yell()


func show_bubble(text: String) -> void:
	bubble.text = text
	bubble.visible = true
	bubble_seconds_left = BUBBLE_SECONDS


func update_bubble(delta: float) -> void:
	if bubble_seconds_left <= 0.0:
		return
	bubble_seconds_left -= delta
	if bubble_seconds_left <= 0.0:
		bubble.visible = false


func defeat() -> void:
	state = State.DEFEATED
	stun_left = 0.0
	overlay_material.albedo_color = base_overlay_color
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	Effects.spawn_confetti_burst(get_parent(), global_position + Vector3.UP * 1.2, 40)
	Effects.spawn_coin_burst(get_parent(), global_position + Vector3.UP * 1.2, 12)
	if is_slopped:
		var line_index := randi() % SLOP_LINES.size()
		speak_last_words(SLOP_LINES[line_index], AudioBank.SLOP_LINE_IDS[line_index])
	else:
		speak_last_words(config["defeat_line"], config["defeat_clip"])
	AudioBank.play_at(get_parent(), AudioBank.CONFETTI, global_position, 1.3, -6.0)
	play_defeat_animation()
	defeated.emit(self)


func play_defeat_animation() -> void:
	if punch_tween != null:
		punch_tween.kill()
	model.scale = Vector3.ONE
	play_animation("defeat")
	var tween := create_tween()
	var defeat_style: String = "wrecked" if is_slopped else config["defeat_style"]
	match defeat_style:
		"wrecked":
			add_wrecked_steps(tween)
		"walk_away":
			add_walk_away_steps(tween)
		"spin":
			add_spin_steps(tween)
		_:
			add_rise_steps(tween)
	tween.chain().tween_callback(queue_free)


func add_wrecked_steps(tween: Tween) -> void:
	var start := global_position
	var landing := find_wreck_landing(start)
	tween.set_parallel(true)
	tween.tween_method(place_on_wreck_arc.bind(start, landing), 0.0, 1.0, WRECK_SECONDS)
	tween.tween_property(model, "rotation:x", model.rotation.x + TAU * 2.0, WRECK_SECONDS)
	tween.chain().tween_property(model, "scale", Vector3.ZERO, 0.3)


func find_wreck_landing(start: Vector3) -> Vector3:
	var away := start - blast_origin
	away.y = 0.0
	away = away.normalized() if away.length_squared() > 0.01 else Vector3.BACK
	var landing := start + away * WRECK_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(start + Vector3.UP, landing + Vector3.UP, WORLD_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return landing
	var wall_point: Vector3 = hit["position"]
	return Vector3(wall_point.x, start.y, wall_point.z) - away * 0.6


func place_on_wreck_arc(progress: float, start: Vector3, landing: Vector3) -> void:
	global_position = start.lerp(landing, progress) + Vector3.UP * WRECK_HEIGHT * 4.0 * progress * (1.0 - progress)


func add_walk_away_steps(tween: Tween) -> void:
	var away := global_position - target.global_position
	away.y = 0.0
	away = away.normalized() if away.length_squared() > 0.01 else Vector3.BACK
	tween.tween_interval(0.9)
	tween.tween_callback(face_toward.bind(away))
	tween.tween_callback(play_animation.bind("exit"))
	tween.tween_property(self, "global_position", global_position + away * 3.0, 1.6)
	tween.tween_property(model, "scale", Vector3.ZERO, 0.4)


func add_spin_steps(tween: Tween) -> void:
	tween.set_parallel(true)
	tween.tween_property(model, "rotation:y", model.rotation.y + TAU * 4.0, 1.2)
	tween.tween_property(model, "scale", Vector3.ZERO, 1.2).set_ease(Tween.EASE_IN)


func add_rise_steps(tween: Tween) -> void:
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", global_position + Vector3.UP * 6.0, 1.5).set_ease(Tween.EASE_IN)
	tween.tween_property(model, "scale", Vector3.ONE * 0.2, 1.5)
