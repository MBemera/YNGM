class_name WeaponFire
extends RefCounted

const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const CHEST_HEIGHT := 1.1
const FIZZLE_DISTANCE := 6.0


static func fire_rail(shooter: Player, muzzle: Vector3, weapon: Dictionary) -> void:
	var space := shooter.get_world_3d().direct_space_state
	var origin := shooter.camera.global_position
	var weapon_range: float = weapon["range"]
	var end := origin + shooter.get_camera_forward() * weapon_range
	var excluded: Array[RID] = [shooter.get_rid()]
	var beam_end := end
	var color: Color = weapon["color"]
	for pierce_index: int in weapon["max_pierce"] + 1:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, WORLD_LAYER | ENEMY_LAYER, excluded))
		if hit.is_empty():
			break
		var collider: Object = hit["collider"]
		if not collider.has_method("take_damage") or pierce_index == weapon["max_pierce"]:
			beam_end = hit["position"]
			break
		collider.take_damage(weapon["damage"])
		shooter.register_hit(collider)
		Effects.spawn_spark_burst(shooter.get_parent(), hit["position"], color, 24)
		excluded.append((collider as CollisionObject3D).get_rid())
	Effects.spawn_beam(shooter.get_parent(), muzzle, beam_end, color, 0.06, 0.4)
	Effects.spawn_spark_burst(shooter.get_parent(), beam_end, color, 16)
	Effects.spawn_flash(shooter.get_parent(), beam_end, color, 4.0, 5.0, 0.2)


static func fire_chain(shooter: Player, muzzle: Vector3, weapon: Dictionary) -> void:
	var color: Color = weapon["color"]
	var first_target := find_chain_start(shooter, weapon)
	if first_target == null:
		var fizzle_end := muzzle + shooter.get_camera_forward() * FIZZLE_DISTANCE
		Effects.spawn_lightning(shooter.get_parent(), [muzzle, fizzle_end], color, 0.15)
		return
	var chained := collect_chain(shooter, first_target, weapon)
	var points: Array[Vector3] = [muzzle]
	for target: Node3D in chained:
		points.append(get_target_point(target))
		target.take_damage(weapon["damage"])
		shooter.register_hit(target)
		Effects.spawn_spark_burst(shooter.get_parent(), get_target_point(target), color, 14)
	Effects.spawn_lightning(shooter.get_parent(), points, color, 0.22)


static func find_chain_start(shooter: Player, weapon: Dictionary) -> Node3D:
	var space := shooter.get_world_3d().direct_space_state
	var origin := shooter.camera.global_position
	var forward := shooter.get_camera_forward()
	var weapon_range: float = weapon["range"]
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + forward * weapon_range, WORLD_LAYER | ENEMY_LAYER, [shooter.get_rid()]))
	if not hit.is_empty() and hit["collider"].has_method("take_damage"):
		return hit["collider"]
	var max_angle := deg_to_rad(weapon["aim_cone_degrees"])
	var best_target: Node3D = null
	var best_angle := max_angle
	for candidate: Node3D in get_living_damageables(shooter.get_tree()):
		var offset := get_target_point(candidate) - origin
		if offset.length() > weapon_range:
			continue
		var angle := forward.angle_to(offset)
		if angle < best_angle and has_line_of_sight(shooter, origin, get_target_point(candidate)):
			best_angle = angle
			best_target = candidate
	return best_target


static func collect_chain(shooter: Player, first_target: Node3D, weapon: Dictionary) -> Array[Node3D]:
	var chained: Array[Node3D] = [first_target]
	var chain_range: float = weapon["chain_range"]
	var candidates := get_living_damageables(shooter.get_tree())
	while chained.size() < weapon["chain_count"]:
		var last_point := get_target_point(chained[chained.size() - 1])
		var next_target := find_nearest(shooter, candidates, chained, last_point, chain_range)
		if next_target == null:
			break
		chained.append(next_target)
	return chained


static func find_nearest(shooter: Player, candidates: Array[Node3D], exclude: Array[Node3D], from_point: Vector3, max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_distance := max_distance
	for candidate: Node3D in candidates:
		if exclude.has(candidate):
			continue
		var distance := from_point.distance_to(get_target_point(candidate))
		if distance < best_distance and has_line_of_sight(shooter, from_point, get_target_point(candidate)):
			best_distance = distance
			best = candidate
	return best


static func get_living_damageables(tree: SceneTree) -> Array[Node3D]:
	var living: Array[Node3D] = []
	for node: Node in tree.get_nodes_in_group(Enemy.ENEMY_GROUP):
		var enemy := node as Enemy
		if enemy != null and enemy.state != Enemy.State.DEFEATED:
			living.append(enemy)
	for node: Node in tree.get_nodes_in_group(DestructibleTarget.GROUP):
		var target := node as DestructibleTarget
		if target != null and not target.is_destroyed:
			living.append(target)
	return living


static func get_target_point(target: Node3D) -> Vector3:
	return target.global_position + Vector3.UP * CHEST_HEIGHT


static func has_line_of_sight(shooter: Node3D, from_point: Vector3, to_point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from_point, to_point, WORLD_LAYER)
	return shooter.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


static func apply_splash(parent: Node3D, origin: Vector3, radius: float, damage: int, edge_fraction: float, shooter: Player) -> void:
	for target: Node3D in get_living_damageables(parent.get_tree()):
		var target_point := get_target_point(target)
		var distance := origin.distance_to(target_point)
		if distance > radius or not has_line_of_sight(parent, origin + Vector3.UP * 0.2, target_point):
			continue
		var falloff := lerpf(1.0, edge_fraction, distance / radius)
		target.take_damage(roundi(damage * falloff))
		if shooter != null and is_instance_valid(shooter):
			shooter.register_hit(target)
