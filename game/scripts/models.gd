class_name Models
extends RefCounted

const CITY := "res://assets/models/city/"
const ROADS := "res://assets/models/roads/"
const CARS := "res://assets/models/cars/"
const BLASTERS := "res://assets/models/blasters/"
const CHARACTERS := "res://assets/models/characters/"
const STATION := "res://assets/models/station/"
const FURNITURE := "res://assets/models/furniture/"
const ROBOT := "res://assets/models/robot/RobotExpressive.glb"
const HELICOPTER := "res://assets/models/helicopter/helicopter.glb"


static func spawn(parent: Node3D, path: String, position: Vector3, yaw_degrees := 0.0, uniform_scale := 1.0) -> Node3D:
	var model: Node3D = load(path).instantiate()
	model.position = position
	model.rotation_degrees.y = yaw_degrees
	model.scale = Vector3.ONE * uniform_scale
	parent.add_child(model)
	return model


static func spawn_fitted(parent: Node3D, path: String, floor_position: Vector3, yaw_degrees: float, target_height: float) -> Node3D:
	var model := spawn(parent, path, floor_position, yaw_degrees)
	var bounds := get_world_bounds(model)
	if bounds.size.y > 0.001:
		model.scale = Vector3.ONE * (target_height / bounds.size.y)
	bounds = get_world_bounds(model)
	model.global_position.y += parent.to_global(floor_position).y - bounds.position.y
	return model


static func get_world_bounds(root: Node3D) -> AABB:
	var bounds := AABB(root.global_position, Vector3.ZERO)
	var has_bounds := false
	for mesh_instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_bounds: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		bounds = mesh_bounds if not has_bounds else bounds.merge(mesh_bounds)
		has_bounds = true
	return bounds


static func get_front_point(root: Node3D, space: Node3D, depth_tolerance := 0.015) -> Vector3:
	var vertices := collect_vertices(root, space)
	if vertices.is_empty():
		return Vector3.ZERO
	var front_z := INF
	for vertex: Vector3 in vertices:
		front_z = minf(front_z, vertex.z)
	var total := Vector3.ZERO
	var count := 0
	for vertex: Vector3 in vertices:
		if vertex.z <= front_z + depth_tolerance:
			total += vertex
			count += 1
	return total / count


static func collect_vertices(root: Node3D, space: Node3D) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	var to_space := space.global_transform.affine_inverse()
	for mesh_instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var to_local := to_space * mesh_instance.global_transform
		for surface_index: int in mesh_instance.mesh.get_surface_count():
			for vertex: Vector3 in mesh_instance.mesh.surface_get_arrays(surface_index)[Mesh.ARRAY_VERTEX]:
				vertices.append(to_local * vertex)
	return vertices


static func add_collider_around(parent: Node3D, model: Node3D) -> StaticBody3D:
	var bounds := get_world_bounds(model)
	return LevelBuilder.add_collider(parent, bounds.size, bounds.get_center())


static func find_animation_player(root: Node) -> AnimationPlayer:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	return players[0] if not players.is_empty() else null


static func loop_animations(animation_player: AnimationPlayer, animation_names: Array) -> void:
	for animation_name: String in animation_names:
		if animation_player.has_animation(animation_name):
			animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
