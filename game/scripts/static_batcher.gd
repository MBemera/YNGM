class_name StaticBatcher
extends RefCounted

const CELL_SIZE := 20.0


static func batch(root: Node3D, excluded_roots: Array[Node]) -> int:
	var groups := collect_groups(root, excluded_roots)
	for group_key: String in groups:
		root.add_child(build_batch(groups[group_key]))
	return groups.size()


static func collect_groups(root: Node3D, excluded_roots: Array[Node]) -> Dictionary:
	var groups: Dictionary = {}
	for mesh_instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if not can_batch(mesh_instance, excluded_roots):
			continue
		add_mesh_surfaces(groups, mesh_instance)
		mesh_instance.visible = false
	return groups


static func can_batch(mesh_instance: MeshInstance3D, excluded_roots: Array[Node]) -> bool:
	if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
		return false
	if mesh_instance.skin != null or mesh_instance.material_overlay != null:
		return false
	for excluded: Node in excluded_roots:
		if excluded == mesh_instance or excluded.is_ancestor_of(mesh_instance):
			return false
	for surface_index: int in mesh_instance.mesh.get_surface_count():
		if not is_batchable_material(get_surface_material(mesh_instance, surface_index)):
			return false
	return true


static func is_batchable_material(material: Material) -> bool:
	var standard := material as BaseMaterial3D
	if standard == null:
		return false
	return standard.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and standard.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED


static func get_surface_material(mesh_instance: MeshInstance3D, surface_index: int) -> Material:
	if mesh_instance.material_override != null:
		return mesh_instance.material_override
	var override := mesh_instance.get_surface_override_material(surface_index)
	return override if override != null else mesh_instance.mesh.surface_get_material(surface_index)


static func add_mesh_surfaces(groups: Dictionary, mesh_instance: MeshInstance3D) -> void:
	var center := (mesh_instance.global_transform * mesh_instance.get_aabb()).get_center()
	var cell := Vector2i(floori(center.x / CELL_SIZE), floori(center.z / CELL_SIZE))
	for surface_index: int in mesh_instance.mesh.get_surface_count():
		var material := get_surface_material(mesh_instance, surface_index)
		var key := "%d|%d|%d|%d" % [material.get_instance_id(), mesh_instance.cast_shadow, cell.x, cell.y]
		if not groups.has(key):
			groups[key] = {"material": material, "cast_shadow": mesh_instance.cast_shadow, "parts": []}
		groups[key]["parts"].append({"mesh": mesh_instance.mesh, "surface": surface_index, "transform": mesh_instance.global_transform})


static func build_batch(group: Dictionary) -> MeshInstance3D:
	var surface_tool := SurfaceTool.new()
	for part: Dictionary in group["parts"]:
		surface_tool.append_from(part["mesh"], part["surface"], part["transform"])
	var batched := MeshInstance3D.new()
	batched.name = "StaticBatch"
	batched.mesh = surface_tool.commit()
	batched.material_override = group["material"]
	batched.cast_shadow = group["cast_shadow"]
	return batched
