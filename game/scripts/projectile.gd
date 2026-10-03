class_name Projectile
extends Node3D

var velocity := Vector3.ZERO
var damage := 0
var collision_mask := 0
var remaining_lifetime := 2.0
var spin_degrees_per_second := 0.0
var stun_seconds := 0.0
var impact_color := Color.WHITE
var excluded_rids: Array[RID] = []
var shooter: Node3D


static func spawn(parent: Node, origin: Vector3, launch_velocity: Vector3, hit_damage: int, mask: int, projectile_shooter: CollisionObject3D, visual_size: Vector3, color: Color, lifetime: float) -> Projectile:
	var projectile := Projectile.new()
	projectile.velocity = launch_velocity
	projectile.damage = hit_damage
	projectile.collision_mask = mask
	projectile.remaining_lifetime = lifetime
	projectile.impact_color = color
	projectile.shooter = projectile_shooter
	projectile.excluded_rids = [projectile_shooter.get_rid()]
	projectile.add_child(create_visual(visual_size, color))
	parent.add_child(projectile)
	projectile.global_position = origin
	projectile.face_direction()
	return projectile


static func create_visual(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = LevelBuilder.get_material(color, 1.5)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var trail := MeshInstance3D.new()
	var trail_mesh := BoxMesh.new()
	trail_mesh.size = Vector3(size.x * 0.45, size.y * 0.45, maxf(size.z, 0.2) * 2.2)
	trail.mesh = trail_mesh
	trail.material_override = Effects.get_trail_material(color)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail.position = Vector3(0, 0, trail_mesh.size.z * 0.5)
	visual.add_child(trail)
	return visual


func _physics_process(delta: float) -> void:
	var start := global_position
	var end := start + velocity * delta
	var hit := cast_ray(start, end)
	if not hit.is_empty():
		handle_hit(hit)
		return
	global_position = end
	if spin_degrees_per_second != 0.0:
		rotate_object_local(Vector3.UP, deg_to_rad(spin_degrees_per_second) * delta)
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()


func cast_ray(start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, collision_mask, excluded_rids)
	return get_world_3d().direct_space_state.intersect_ray(query)


func handle_hit(hit: Dictionary) -> void:
	var collider: Object = hit["collider"]
	if collider.has_method("take_damage"):
		collider.take_damage(damage)
		report_hit_to_shooter(collider)
	if stun_seconds > 0.0 and collider is Enemy:
		(collider as Enemy).stun(stun_seconds)
	if collider is Enemy or collider is DestructibleTarget:
		Effects.spawn_hit_burst(get_parent(), hit["position"], impact_color)
	else:
		Effects.spawn_puff(get_parent(), hit["position"], impact_color)
	queue_free()


func report_hit_to_shooter(collider: Object) -> void:
	var player := shooter as Player
	if player != null and is_instance_valid(player):
		player.register_hit(collider)


func face_direction() -> void:
	if velocity.length_squared() < 0.001:
		return
	var up := Vector3.UP if absf(velocity.normalized().y) < 0.99 else Vector3.FORWARD
	look_at(global_position + velocity, up)
