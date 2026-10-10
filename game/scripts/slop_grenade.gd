class_name SlopGrenade
extends RigidBody3D

const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const MODEL_PATH := Weapons.MODEL_ROOT + "slop-grenade.glb"
const MODEL_LENGTH := 0.3
const THROWN_START_SCALE := 0.37
const THROWN_GROW_SECONDS := 0.25
const COLLISION_RADIUS := 0.12
const FUSE_SECONDS := 1.6
const BLAST_RADIUS := 7.0
const FULL_DAMAGE_RADIUS := 3.0
const BLAST_DAMAGE := 250
const EDGE_DAMAGE_FRACTION := 0.6
const ENEMY_AIM_HEIGHT := 1.0
const ALERT_RADIUS := 22.0
const CODE_LINE_COUNT := 20
const SHAKE_DISTANCE := 16.0
const MAX_SHAKE_STRENGTH := 0.12
const BOUNCE_SOUND_MIN_SPEED := 2.0
const SLOP_GREEN := Color(0.55, 1.0, 0.2)

var thrower: Player
var fuse_left := FUSE_SECONDS
var has_hit_enemy := false
var has_exploded := false


static func spawn(parent: Node, origin: Vector3, launch_velocity: Vector3, grenade_thrower: Player) -> SlopGrenade:
	var grenade := SlopGrenade.new()
	grenade.thrower = grenade_thrower
	grenade.linear_velocity = launch_velocity
	grenade.angular_velocity = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))
	parent.add_child(grenade)
	grenade.global_position = origin
	return grenade


func _ready() -> void:
	collision_layer = 0
	collision_mask = WORLD_LAYER | ENEMY_LAYER
	mass = 0.4
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4
	physics_material_override = create_bouncy_material()
	add_collision_shape()
	add_model()
	add_glow()
	add_child(create_slop_trail())
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	fuse_left -= delta
	if has_hit_enemy or fuse_left <= 0.0:
		explode()


func create_bouncy_material() -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.bounce = 0.35
	material.friction = 0.8
	return material


func add_collision_shape() -> void:
	var shape := SphereShape3D.new()
	shape.radius = COLLISION_RADIUS
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)


func add_model() -> void:
	var visual := Node3D.new()
	add_child(visual)
	var model := Models.spawn(visual, MODEL_PATH, Vector3.ZERO)
	var bounds := Models.get_world_bounds(model)
	var longest_side := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	model.scale = Vector3.ONE * (MODEL_LENGTH / longest_side)
	model.position = -to_local(Models.get_world_bounds(model).get_center())
	visual.scale = Vector3.ONE * THROWN_START_SCALE
	visual.create_tween().tween_property(visual, "scale", Vector3.ONE, THROWN_GROW_SECONDS)


func add_glow() -> void:
	var glow := OmniLight3D.new()
	glow.light_color = SLOP_GREEN
	glow.light_energy = 1.5
	glow.omni_range = 2.5
	add_child(glow)


func create_slop_trail() -> CPUParticles3D:
	var trail := Effects.create_particles()
	trail.amount = 24
	trail.lifetime = 0.5
	trail.local_coords = false
	trail.direction = Vector3.DOWN
	trail.spread = 30.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.gravity = Vector3(0, -6, 0)
	trail.mesh = Effects.create_blob_mesh(0.035)
	trail.color_initial_ramp = Effects.create_palette_gradient(Effects.SLOP_COLORS)
	return trail


func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		has_hit_enemy = true
		return
	if linear_velocity.length() > BOUNCE_SOUND_MIN_SPEED:
		AudioBank.play_at(get_parent(), AudioBank.BOUNCE, global_position, randf_range(0.9, 1.2), -4.0)


func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	var origin := global_position
	var parent := get_parent()
	wreck_enemies_in_blast(origin)
	damage_destructibles_in_blast(origin)
	Effects.spawn_slop_explosion(parent, origin)
	RustSlop.spawn_shower(parent, origin, CODE_LINE_COUNT)
	AudioBank.play_at(parent, AudioBank.SLOP_EXPLOSION, origin, randf_range(0.95, 1.05), 6.0)
	Enemy.alert_enemies_near(get_tree(), origin, ALERT_RADIUS)
	shake_thrower_camera(origin)
	queue_free()


func wreck_enemies_in_blast(origin: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group(Enemy.ENEMY_GROUP):
		var enemy := node as Enemy
		if enemy == null or enemy.state == Enemy.State.DEFEATED:
			continue
		var target_point := enemy.global_position + Vector3.UP * ENEMY_AIM_HEIGHT
		var distance := origin.distance_to(target_point)
		if distance > BLAST_RADIUS or not has_clear_path(origin, target_point):
			continue
		enemy.take_slop_hit(get_blast_damage(distance), origin)
		register_thrower_hit(enemy)


func damage_destructibles_in_blast(origin: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group(DestructibleTarget.GROUP):
		var target := node as DestructibleTarget
		if target == null or target.is_destroyed:
			continue
		var distance := origin.distance_to(target.global_position + Vector3.UP)
		if distance <= BLAST_RADIUS:
			target.take_damage(get_blast_damage(distance))
			register_thrower_hit(target)


func register_thrower_hit(target: Object) -> void:
	if thrower != null and is_instance_valid(thrower):
		thrower.register_hit(target)


func has_clear_path(origin: Vector3, target_point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.2, target_point, WORLD_LAYER)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func get_blast_damage(distance: float) -> int:
	if distance <= FULL_DAMAGE_RADIUS:
		return BLAST_DAMAGE
	var edge_progress := (distance - FULL_DAMAGE_RADIUS) / (BLAST_RADIUS - FULL_DAMAGE_RADIUS)
	return roundi(lerpf(BLAST_DAMAGE, BLAST_DAMAGE * EDGE_DAMAGE_FRACTION, edge_progress))


func shake_thrower_camera(origin: Vector3) -> void:
	if thrower == null or not is_instance_valid(thrower):
		return
	var closeness := 1.0 - thrower.global_position.distance_to(origin) / SHAKE_DISTANCE
	if closeness > 0.0:
		thrower.shake_camera(MAX_SHAKE_STRENGTH * closeness)
