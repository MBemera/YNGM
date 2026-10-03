class_name ArenaKit
extends RefCounted

const RAILING_HEIGHT := 1.1
const RAILING_THICKNESS := 0.12
const RAMP_RAIL_SETBACK := 0.8
const LAMP_PANEL_SIZE := Vector3(2.4, 0.1, 1.0)
const WATER_SHADER_PATH := "res://shaders/water.gdshader"
const SKYLINE_MODELS: Array[String] = ["low-detail-building-a", "low-detail-building-c", "low-detail-building-e", "low-detail-building-g", "low-detail-building-i", "low-detail-building-k", "low-detail-building-m", "low-detail-building-wide-a", "building-skyscraper-a", "building-skyscraper-d"]
const CRATE_MODELS: Array[String] = ["crate-medium", "crate-wide", "crate-small"]


static func solid(parent: Node3D, min_corner: Vector3, max_corner: Vector3, material: Material) -> StaticBody3D:
	return LevelBuilder.add_block_between(parent, min_corner, max_corner, material)


static func floor_slab(parent: Node3D, min_x: float, max_x: float, min_z: float, max_z: float, top_y: float, material: Material) -> StaticBody3D:
	return solid(parent, Vector3(min_x, top_y - 1.0, min_z), Vector3(max_x, top_y, max_z), material)


static func wall_along_x(parent: Node3D, from_x: float, to_x: float, z: float, height: float, material: Material, base_y := 0.0, thickness := 0.5) -> StaticBody3D:
	var half := thickness / 2.0
	return solid(parent, Vector3(minf(from_x, to_x), base_y, z - half), Vector3(maxf(from_x, to_x), base_y + height, z + half), material)


static func wall_along_z(parent: Node3D, from_z: float, to_z: float, x: float, height: float, material: Material, base_y := 0.0, thickness := 0.5) -> StaticBody3D:
	var half := thickness / 2.0
	return solid(parent, Vector3(x - half, base_y, minf(from_z, to_z)), Vector3(x + half, base_y + height, maxf(from_z, to_z)), material)


static func ceiling(parent: Node3D, min_x: float, max_x: float, min_z: float, max_z: float, y: float, material: Material) -> StaticBody3D:
	return solid(parent, Vector3(min_x, y, min_z), Vector3(max_x, y + 0.3, max_z), material)


static func ramp(parent: Node3D, bottom_edge_center: Vector3, top_edge_center: Vector3, width: float, material: Material, has_rails := true) -> StaticBody3D:
	var ramp_body := LevelBuilder.add_ramp(parent, bottom_edge_center, top_edge_center, width, material)
	if has_rails:
		add_ramp_rail(parent, bottom_edge_center, top_edge_center, width / 2.0)
		add_ramp_rail(parent, bottom_edge_center, top_edge_center, -width / 2.0)
	return ramp_body


static func add_ramp_rail(parent: Node3D, bottom_edge_center: Vector3, top_edge_center: Vector3, side_offset: float) -> void:
	var direction := top_edge_center - bottom_edge_center
	var ramp_basis := Basis.looking_at(direction, Vector3.UP)
	var rail_material := LevelBuilder.get_material(LevelBuilder.SAFETY_YELLOW)
	var rail_start := bottom_edge_center + direction.normalized() * RAMP_RAIL_SETBACK
	var rail_length := direction.length() - RAMP_RAIL_SETBACK
	var rail_center := (rail_start + top_edge_center) / 2.0 + ramp_basis.x * side_offset + ramp_basis.y * RAILING_HEIGHT / 2.0
	var rail := LevelBuilder.add_block(parent, Vector3(RAILING_THICKNESS, RAILING_HEIGHT, rail_length), rail_center, rail_material)
	rail.basis = ramp_basis
	var flat_direction := Vector3(direction.x, 0.0, direction.z).normalized()
	var yaw_basis := Basis.looking_at(flat_direction, Vector3.UP)
	var curb_center := bottom_edge_center + flat_direction * RAMP_RAIL_SETBACK / 2.0 + yaw_basis.x * side_offset + Vector3.UP * RAILING_HEIGHT / 2.0
	var curb := LevelBuilder.add_block(parent, Vector3(RAILING_THICKNESS, RAILING_HEIGHT, RAMP_RAIL_SETBACK), curb_center, rail_material)
	curb.basis = yaw_basis


static func railing(parent: Node3D, from: Vector3, to: Vector3, color := LevelBuilder.SAFETY_YELLOW) -> StaticBody3D:
	var half := RAILING_THICKNESS / 2.0
	var min_corner := Vector3(minf(from.x, to.x) - half, from.y, minf(from.z, to.z) - half)
	var max_corner := Vector3(maxf(from.x, to.x) + half, from.y + RAILING_HEIGHT, maxf(from.z, to.z) + half)
	return solid(parent, min_corner, max_corner, LevelBuilder.get_material(color))


static func invisible_wall(parent: Node3D, min_corner: Vector3, max_corner: Vector3) -> StaticBody3D:
	return LevelBuilder.add_collider_between(parent, min_corner, max_corner)


static func pillar(parent: Node3D, center: Vector3, size: Vector2, height: float, material: Material) -> StaticBody3D:
	var half := Vector3(size.x / 2.0, 0.0, size.y / 2.0)
	return solid(parent, center - half, center + half + Vector3.UP * height, material)


static func prop(parent: Node3D, path: String, floor_position: Vector3, yaw_degrees: float, height: float, is_solid := true) -> Node3D:
	var model := Models.spawn_fitted(parent, path, floor_position, yaw_degrees, height)
	if is_solid:
		Models.add_collider_around(parent, model)
	return model


static func crate(parent: Node3D, floor_position: Vector3, yaw_degrees := 0.0, height := 1.1, model_index := 0) -> Node3D:
	var model_name := CRATE_MODELS[model_index % CRATE_MODELS.size()]
	return prop(parent, Models.BLASTERS + model_name + ".glb", floor_position, yaw_degrees, height)


static func car(parent: Node3D, model_name: String, position: Vector3, yaw_degrees: float, scale := 1.5) -> Node3D:
	var model := Models.spawn(parent, Models.CARS + model_name + ".glb", position, yaw_degrees, scale)
	Models.add_collider_around(parent, model)
	return model


static func lamp(parent: Node3D, position: Vector3, color: Color, energy := 2.2, light_range := 14.0, has_panel := true) -> OmniLight3D:
	if has_panel:
		LevelBuilder.add_decor(parent, LAMP_PANEL_SIZE, position + Vector3(0, 0.1, 0), color.lightened(0.3), 4.0)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.position = position - Vector3(0, 0.4, 0)
	parent.add_child(light)
	return light


static func neon(parent: Node3D, size: Vector3, center: Vector3, color: Color, energy := 3.0) -> MeshInstance3D:
	var strip := LevelBuilder.add_decor(parent, size, center, color, energy)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return strip


static func place_sign(parent: Node3D, text: String, position: Vector3, yaw_degrees: float, font_size: int, color: Color) -> Label3D:
	return LevelBuilder.add_sign(parent, text, position, yaw_degrees, font_size, color)


static func flickering_sign(parent: Node3D, text: String, position: Vector3, yaw_degrees: float, font_size: int, color: Color) -> Label3D:
	var label := place_sign(parent, text, position, yaw_degrees, font_size, color)
	label.add_child(NeonFlicker.new())
	return label


static func fire(parent: Node3D, position: Vector3, light_energy := 3.0) -> void:
	parent.add_child(Effects.create_fire(position))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.15)
	light.light_energy = light_energy
	light.omni_range = 9.0
	light.position = position + Vector3(0, 0.8, 0)
	parent.add_child(light)


static func smoke(parent: Node3D, position: Vector3) -> void:
	parent.add_child(Effects.create_smoke_plume(position))


static func water(parent: Node3D, center: Vector3, size: Vector2, deep_color := Color(0.02, 0.08, 0.12), shallow_color := Color(0.1, 0.35, 0.45)) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = 48
	mesh.subdivide_depth = 48
	var material := ShaderMaterial.new()
	material.shader = load(WATER_SHADER_PATH)
	material.set_shader_parameter("deep_color", deep_color)
	material.set_shader_parameter("shallow_color", shallow_color)
	var surface := MeshInstance3D.new()
	surface.mesh = mesh
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.position = center
	parent.add_child(surface)
	return surface


static func skyline(parent: Node3D, center: Vector3, count: int, min_distance: float, max_distance: float, random_seed: int, min_scale := 14.0, max_scale := 22.0) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	for index: int in count:
		var angle := TAU * index / count + random.randf_range(-0.05, 0.05)
		var distance := random.randf_range(min_distance, max_distance)
		var position := center + Vector3(sin(angle), 0, cos(angle)) * distance
		var model_name := SKYLINE_MODELS[random.randi() % SKYLINE_MODELS.size()]
		Models.spawn(parent, Models.CITY + model_name + ".glb", position, random.randf_range(0.0, 360.0), random.randf_range(min_scale, max_scale))


static func screen(parent: Node3D, text: String, center: Vector3, yaw_degrees: float, width: float, height: float, color: Color) -> void:
	var facing := Basis.from_euler(Vector3(0, deg_to_rad(yaw_degrees), 0))
	var panel := LevelBuilder.add_decor(parent, Vector3(width, height, 0.12), center, Color(0.02, 0.03, 0.05))
	panel.basis = facing
	var frame := LevelBuilder.add_decor(parent, Vector3(width + 0.25, height + 0.25, 0.08), center - facing.z * 0.03, color, 1.6)
	frame.basis = facing
	var font_size := int(clampf(height * 40.0, 32.0, 160.0))
	place_sign(parent, text, center + facing.z * 0.08, yaw_degrees, font_size, color)
