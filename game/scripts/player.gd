class_name Player
extends CharacterBody3D

signal runway_changed(months: int, max_months: int)
signal runway_restored(months: int, max_months: int)
signal out_of_runway
signal weapon_changed(weapon_index: int)
signal hit_registered(was_defeat: bool)
signal weapon_fired

const WALK_SPEED := 6.5
const SPRINT_SPEED := 10.0
const JUMP_VELOCITY := 5.6
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0025
const MAX_PITCH_RADIANS := 1.48
const EYE_HEIGHT := 1.6
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4
const PROJECTILE_MASK := WORLD_LAYER | ENEMY_LAYER
const AIM_DISTANCE := 200.0
const GUNFIRE_ALERT_RADIUS := 18.0
const WEAPON_REST_POSITION := Vector3(0.24, -0.21, -0.52)
const GRENADE_THROW_SPEED := 17.0
const GRENADE_THROW_LIFT := 3.0
const BOB_FREQUENCY := 9.0
const BOB_AMOUNT := Vector2(0.012, 0.016)
const SWAY_AMOUNT := 0.0006
const SWAY_LIMIT := 0.05
const SWAY_RETURN_SPEED := 9.0
const WEAPON_SWITCH_SECONDS := 0.18

var max_runway_months := 24
var runway_months := 24
var unlocked_weapon_count := Weapons.STARTING_WEAPON_COUNT
var controls_enabled := false
var is_frozen := false
var current_weapon_index := 0
var fire_cooldown_left := 0.0
var head: Node3D
var camera: Camera3D
var weapon_pivot: Node3D
var weapon_model: Node3D
var muzzle_light: OmniLight3D
var bob_time := 0.0
var sway_offset := Vector2.ZERO
var recoil_offset := 0.0


func _ready() -> void:
	max_runway_months = Difficulty.get_player_runway()
	runway_months = max_runway_months
	collision_layer = PLAYER_LAYER
	collision_mask = WORLD_LAYER | ENEMY_LAYER
	floor_snap_length = 0.4
	add_collision_shape()
	create_camera()
	create_weapon_model()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_view(mouse_motion.relative)
		return
	for slot_index: int in Weapons.ALL.size():
		if event.is_action_pressed("weapon_%d" % (slot_index + 1)):
			select_weapon(slot_index)
			return
	if event.is_action_pressed("weapon_next"):
		cycle_weapon(1)
	elif event.is_action_pressed("weapon_previous"):
		cycle_weapon(-1)


func _physics_process(delta: float) -> void:
	if is_frozen:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if controls_enabled:
		move_from_input()
		update_firing(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()


func _process(delta: float) -> void:
	update_weapon_motion(delta)


func add_ambient_particles(kinds: Array) -> void:
	for kind: String in kinds:
		var particles := Effects.create_ambient_particles(kind)
		if particles != null:
			particles.amount = GraphicsSettings.scale_particle_amount(particles.amount)
			add_child(particles)


func add_collision_shape() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 0.9, 0)
	add_child(collision)


func create_camera() -> void:
	head = Node3D.new()
	head.position = Vector3(0, EYE_HEIGHT, 0)
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 80.0
	head.add_child(camera)
	camera.make_current()


func create_weapon_model() -> void:
	weapon_pivot = Node3D.new()
	weapon_pivot.position = WEAPON_REST_POSITION
	camera.add_child(weapon_pivot)
	weapon_model = Node3D.new()
	weapon_pivot.add_child(weapon_model)
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_energy = 0.0
	muzzle_light.visible = false
	muzzle_light.omni_range = 4.0
	muzzle_light.position = Vector3(0, 0.05, -0.35)
	weapon_pivot.add_child(muzzle_light)
	update_weapon_model()


func update_weapon_model() -> void:
	for part: Node in weapon_model.get_children():
		part.queue_free()
	var weapon := Weapons.get_weapon(current_weapon_index)
	var blaster := Models.spawn(weapon_model, Models.BLASTERS + weapon["model"] + ".glb", Vector3.ZERO)
	var bounds := Models.get_world_bounds(blaster)
	var longest_side := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var model_length: float = weapon["model_length"]
	blaster.scale = Vector3.ONE * (model_length / longest_side)
	for mesh_instance: MeshInstance3D in blaster.find_children("*", "MeshInstance3D", true, false):
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if weapon["kind"] == Weapons.GRENADE:
		SlopGrenade.paint_slop(blaster)


func update_weapon_motion(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_walking := controls_enabled and is_on_floor() and horizontal_speed > 0.5
	if is_walking:
		bob_time += delta * BOB_FREQUENCY * (horizontal_speed / WALK_SPEED)
	var bob_strength := clampf(horizontal_speed / WALK_SPEED, 0.0, 1.4) if is_walking else 0.0
	var bob := Vector3(sin(bob_time) * BOB_AMOUNT.x, -absf(cos(bob_time)) * BOB_AMOUNT.y, 0.0) * bob_strength
	sway_offset = sway_offset.lerp(Vector2.ZERO, clampf(SWAY_RETURN_SPEED * delta, 0.0, 1.0))
	recoil_offset = lerpf(recoil_offset, 0.0, clampf(14.0 * delta, 0.0, 1.0))
	weapon_pivot.position = WEAPON_REST_POSITION + bob + Vector3(sway_offset.x, sway_offset.y, recoil_offset)
	weapon_pivot.rotation = Vector3(recoil_offset * 2.5, -sway_offset.x * 2.0, sway_offset.x * 1.5)
	muzzle_light.light_energy = lerpf(muzzle_light.light_energy, 0.0, clampf(25.0 * delta, 0.0, 1.0))
	muzzle_light.visible = muzzle_light.light_energy > 0.05


func rotate_view(relative: Vector2) -> void:
	rotate_y(-relative.x * MOUSE_SENSITIVITY)
	var pitch := head.rotation.x - relative.y * MOUSE_SENSITIVITY
	head.rotation.x = clampf(pitch, -MAX_PITCH_RADIANS, MAX_PITCH_RADIANS)
	sway_offset.x = clampf(sway_offset.x - relative.x * SWAY_AMOUNT, -SWAY_LIMIT, SWAY_LIMIT)
	sway_offset.y = clampf(sway_offset.y + relative.y * SWAY_AMOUNT, -SWAY_LIMIT, SWAY_LIMIT)


func move_from_input() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func update_firing(delta: float) -> void:
	fire_cooldown_left -= delta
	if fire_cooldown_left > 0.0 or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var weapon := Weapons.get_weapon(current_weapon_index)
	var is_automatic: bool = weapon["automatic"]
	var wants_to_fire := Input.is_action_pressed("fire") if is_automatic else Input.is_action_just_pressed("fire")
	if wants_to_fire:
		fire_weapon()


func fire_weapon() -> void:
	var weapon := Weapons.get_weapon(current_weapon_index)
	fire_cooldown_left = weapon["cooldown"]
	var muzzle := get_muzzle_position()
	var aim_direction := get_aim_direction(muzzle)
	match weapon["kind"]:
		Weapons.GRENADE:
			throw_slop_grenade(muzzle, aim_direction)
		Weapons.RAIL:
			WeaponFire.fire_rail(self, muzzle, weapon)
		Weapons.BUBBLE:
			ValuationBubble.spawn(get_parent(), muzzle, aim_direction * weapon["speed"], weapon, self)
		Weapons.CHAIN:
			WeaponFire.fire_chain(self, muzzle, weapon)
		_:
			fire_pellets(weapon, muzzle, aim_direction)
	play_fire_feedback(weapon, muzzle)
	weapon_fired.emit()
	Enemy.alert_enemies_near(get_tree(), global_position, GUNFIRE_ALERT_RADIUS)


func get_muzzle_position() -> Vector3:
	var camera_basis := camera.global_transform.basis
	return camera.global_position - camera_basis.z * 0.4 + camera_basis.x * 0.12 - camera_basis.y * 0.1


func get_camera_forward() -> Vector3:
	return -camera.global_transform.basis.z


func fire_pellets(weapon: Dictionary, muzzle: Vector3, aim_direction: Vector3) -> void:
	var pellet_count: int = weapon["pellets"]
	for pellet_index: int in pellet_count:
		spawn_pellet(weapon, muzzle, aim_direction)


func throw_slop_grenade(muzzle: Vector3, aim_direction: Vector3) -> void:
	var launch_velocity := aim_direction * GRENADE_THROW_SPEED + Vector3.UP * GRENADE_THROW_LIFT + Vector3(velocity.x, 0.0, velocity.z)
	SlopGrenade.spawn(get_parent(), muzzle, launch_velocity, self)


func get_aim_direction(muzzle: Vector3) -> Vector3:
	var ray_end := camera.global_position + get_camera_forward() * AIM_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, ray_end, PROJECTILE_MASK, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var aim_point: Vector3 = ray_end if hit.is_empty() else hit["position"]
	return (aim_point - muzzle).normalized()


func spawn_pellet(weapon: Dictionary, muzzle: Vector3, aim_direction: Vector3) -> void:
	var spread: float = weapon["spread"]
	var jitter := Vector3(randf_range(-spread, spread), randf_range(-spread, spread), randf_range(-spread, spread))
	var direction := (aim_direction + jitter).normalized()
	var is_single_pellet: bool = weapon["pellets"] == 1
	var color: Color = weapon["color"] if is_single_pellet else Effects.random_confetti_color()
	var speed: float = weapon["speed"]
	var projectile := Projectile.spawn(get_parent(), muzzle, direction * speed, weapon["damage"], PROJECTILE_MASK, self, weapon["pellet_size"], color, weapon["lifetime"])
	projectile.stun_seconds = weapon.get("stun_seconds", 0.0)


func play_fire_feedback(weapon: Dictionary, muzzle: Vector3) -> void:
	var confetti_amount: int = weapon["muzzle_confetti"]
	if confetti_amount > 0:
		Effects.spawn_confetti_burst(get_parent(), muzzle, confetti_amount)
	if weapon["kind"] != Weapons.GRENADE:
		muzzle_light.light_color = weapon["color"]
		muzzle_light.light_energy = 2.5
		muzzle_light.visible = true
	AudioBank.play_ui(self, weapon["fire_sound"], weapon["fire_volume_db"], randf_range(0.9, 1.1))
	recoil_offset = weapon["recoil"]


func register_hit(collider: Object) -> void:
	var enemy := collider as Enemy
	var was_defeat := enemy != null and enemy.state == Enemy.State.DEFEATED
	var target := collider as DestructibleTarget
	was_defeat = was_defeat or (target != null and target.is_destroyed)
	hit_registered.emit(was_defeat)


func cycle_weapon(step: int) -> void:
	select_weapon(posmod(current_weapon_index + step, unlocked_weapon_count))


func select_weapon(index: int) -> void:
	if index >= unlocked_weapon_count or index == current_weapon_index:
		return
	current_weapon_index = index
	update_weapon_model()
	weapon_pivot.position = WEAPON_REST_POSITION + Vector3(0, -0.25, 0)
	recoil_offset = 0.0
	weapon_changed.emit(index)


func take_damage(months: int) -> void:
	if not is_targetable():
		return
	runway_months = maxi(runway_months - months, 0)
	runway_changed.emit(runway_months, max_runway_months)
	AudioBank.play_ui(self, AudioBank.HURT, -4.0)
	shake_camera(0.03)
	if runway_months == 0:
		controls_enabled = false
		out_of_runway.emit()


func needs_runway() -> bool:
	return is_targetable() and runway_months < max_runway_months


func restore_runway(months: int) -> void:
	runway_months = mini(runway_months + months, max_runway_months)
	runway_restored.emit(runway_months, max_runway_months)


func shake_camera(strength: float) -> void:
	var tween := create_tween()
	for step_index: int in 6:
		tween.tween_property(camera, "h_offset", randf_range(-strength, strength), 0.035)
		tween.parallel().tween_property(camera, "v_offset", randf_range(-strength, strength), 0.035)
	tween.tween_property(camera, "h_offset", 0.0, 0.06)
	tween.parallel().tween_property(camera, "v_offset", 0.0, 0.06)


func is_targetable() -> bool:
	return controls_enabled and runway_months > 0


func freeze() -> void:
	controls_enabled = false
	is_frozen = true
	velocity = Vector3.ZERO
