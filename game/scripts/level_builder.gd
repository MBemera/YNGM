class_name LevelBuilder
extends RefCounted

const WORLD_LAYER := 1
const STREET_HALF_WIDTH := 12.0
const ROAD_HALF_WIDTH := 8.0
const STREET_START_Z := 10.0
const STREET_END_Z := -80.0
const LAB_BACK_Z := -120.0
const LAB_HALF_WIDTH := 14.0
const MEZZANINE_HEIGHT := 7.5
const ROOF_HEIGHT := 15.0
const RAMP_THICKNESS := 0.4
const STREET_WALL_HEIGHT := 40.0
const STREET_WALL_DEPTH := 10.0

const SAFETY_YELLOW := Color(0.95, 0.8, 0.15)
const NEON_CYAN := Color(0.2, 1.0, 0.95)
const NEON_PINK := Color(1.0, 0.25, 0.7)
const RECEPTION_WHITE := Color(0.92, 0.93, 0.95)
const CEILING_WHITE := Color(0.86, 0.9, 0.95)
const INTERIOR_TINT := Color(0.78, 0.86, 0.98)

const BILLBOARDS: Array[Dictionary] = [
	{"text": "DON'T GET LEFT BEHIND", "side": -1, "z": -12.0, "height": 9.0, "color": Color(1.0, 0.3, 0.6)},
	{"text": "AGI BY FRIDAY", "side": 1, "z": -27.0, "height": 8.0, "color": Color(0.3, 1.0, 0.95)},
	{"text": "YOUR JOB,\nBUT CHEAPER", "side": -1, "z": -43.0, "height": 8.0, "color": Color(1.0, 0.85, 0.2)},
	{"text": "RAISE NOW.\nASK QUESTIONS NEVER.", "side": 1, "z": -58.0, "height": 9.0, "color": Color(0.5, 1.0, 0.4)},
	{"text": "YOU'RE NOT\nGONNA MAKE IT", "side": -1, "z": -72.0, "height": 8.0, "color": Color(1.0, 0.3, 0.3)},
]

static var material_cache: Dictionary = {}


static func build(parent: Node3D) -> void:
	build_street_collision(parent)
	build_billboards(parent)
	build_lab_shell(parent)
	build_lab_facade(parent)
	build_lab_signs(parent)
	build_reception(parent)
	build_ramps_and_mezzanine(parent)
	build_lab_ceilings(parent)
	build_roof(parent)
	build_roof_railings(parent)
	build_helipad(parent)


static func get_material(color: Color, emission_energy := 0.0) -> StandardMaterial3D:
	var cache_key := "%s|%s" % [color.to_html(), emission_energy]
	if material_cache.has(cache_key):
		return material_cache[cache_key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_cache[cache_key] = material
	return material


static func add_decor(parent: Node3D, size: Vector3, center: Vector3, color: Color, emission_energy := 0.0) -> MeshInstance3D:
	return add_mesh_box(parent, size, center, get_material(color, emission_energy))


static func add_mesh_box(parent: Node3D, size: Vector3, center: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = center
	parent.add_child(mesh_instance)
	return mesh_instance


static func add_collider(parent: Node3D, size: Vector3, center: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = center
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body


static func add_collider_between(parent: Node3D, min_corner: Vector3, max_corner: Vector3) -> StaticBody3D:
	return add_collider(parent, max_corner - min_corner, (min_corner + max_corner) / 2.0)


static func add_block(parent: Node3D, size: Vector3, center: Vector3, material: Material) -> StaticBody3D:
	var body := add_collider(parent, size, center)
	add_mesh_box(body, size, Vector3.ZERO, material)
	return body


static func add_block_between(parent: Node3D, min_corner: Vector3, max_corner: Vector3, material: Material) -> StaticBody3D:
	return add_block(parent, max_corner - min_corner, (min_corner + max_corner) / 2.0, material)


static func add_ramp(parent: Node3D, bottom_edge_center: Vector3, top_edge_center: Vector3, width: float, material: Material) -> StaticBody3D:
	var direction := top_edge_center - bottom_edge_center
	var ramp_basis := Basis.looking_at(direction, Vector3.UP)
	var center := (bottom_edge_center + top_edge_center) / 2.0 - ramp_basis.y * RAMP_THICKNESS / 2.0
	var body := add_block(parent, Vector3(width, RAMP_THICKNESS, direction.length()), center, material)
	body.basis = ramp_basis
	return body


static func add_sign(parent: Node3D, text: String, position: Vector3, yaw_degrees: float, font_size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.01
	label.modulate = color
	label.outline_size = 12
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.shaded = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label.position = position
	label.rotation_degrees.y = yaw_degrees
	parent.add_child(label)
	return label


static func build_street_collision(parent: Node3D) -> void:
	add_collider_between(parent, Vector3(-ROAD_HALF_WIDTH, -1, STREET_END_Z), Vector3(ROAD_HALF_WIDTH, 0, STREET_START_Z))
	var sidewalk := Surfaces.get_textured(Surfaces.SIDEWALK_CONCRETE, 3.0, Color(0.85, 0.8, 0.78))
	add_block_between(parent, Vector3(-STREET_HALF_WIDTH, -1, STREET_END_Z), Vector3(-ROAD_HALF_WIDTH, 0.02, STREET_START_Z), sidewalk)
	add_block_between(parent, Vector3(ROAD_HALF_WIDTH, -1, STREET_END_Z), Vector3(STREET_HALF_WIDTH, 0.02, STREET_START_Z), sidewalk)
	var wall_outer_x := STREET_HALF_WIDTH + STREET_WALL_DEPTH
	add_collider_between(parent, Vector3(-wall_outer_x, 0, STREET_END_Z), Vector3(-STREET_HALF_WIDTH, STREET_WALL_HEIGHT, STREET_START_Z + 4))
	add_collider_between(parent, Vector3(STREET_HALF_WIDTH, 0, STREET_END_Z), Vector3(wall_outer_x, STREET_WALL_HEIGHT, STREET_START_Z + 4))
	add_collider_between(parent, Vector3(-STREET_HALF_WIDTH, 0, STREET_START_Z - 1), Vector3(STREET_HALF_WIDTH, 3, STREET_START_Z))
	add_sign(parent, "ROAD CLOSED\nSERIES Z FUNDING IN PROGRESS", Vector3(0, 2.6, STREET_START_Z - 1.3), 180.0, 48, Color(1, 0.9, 0.7))


static func build_billboards(parent: Node3D) -> void:
	for billboard: Dictionary in BILLBOARDS:
		var side: int = billboard["side"]
		var height: float = billboard["height"]
		var z: float = billboard["z"]
		var glow_color: Color = billboard["color"]
		var center := Vector3((STREET_HALF_WIDTH - 0.25) * side, height, z)
		add_decor(parent, Vector3(0.3, 3.6, 14.0), center, glow_color, 1.2)
		add_decor(parent, Vector3(0.34, 3.2, 13.5), center, Color(0.03, 0.03, 0.05))
		var text_position := center + Vector3(-0.2 * side, 0, 0)
		add_sign(parent, billboard["text"], text_position, -90.0 * side, 90, glow_color)


static func build_lab_shell(parent: Node3D) -> void:
	var front := STREET_END_Z
	var back := LAB_BACK_Z
	var outer := LAB_HALF_WIDTH + 0.5
	var inner := LAB_HALF_WIDTH - 0.5
	var concrete := Surfaces.get_textured(Surfaces.LAB_CONCRETE, 4.0, INTERIOR_TINT)
	add_block_between(parent, Vector3(-outer, -1, back), Vector3(outer, 0, front), Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 3.0, INTERIOR_TINT))
	add_block_between(parent, Vector3(-outer, 0, front - 0.5), Vector3(-2.5, ROOF_HEIGHT, front + 0.5), concrete)
	add_block_between(parent, Vector3(2.5, 0, front - 0.5), Vector3(outer, ROOF_HEIGHT, front + 0.5), concrete)
	add_block_between(parent, Vector3(-2.5, 4.5, front - 0.5), Vector3(2.5, ROOF_HEIGHT, front + 0.5), concrete)
	add_block_between(parent, Vector3(-outer, 0, back - 0.5), Vector3(-inner, ROOF_HEIGHT, front), concrete)
	add_block_between(parent, Vector3(inner, 0, back - 0.5), Vector3(outer, ROOF_HEIGHT, front), concrete)
	add_block_between(parent, Vector3(-outer, 0, back - 0.5), Vector3(outer, ROOF_HEIGHT, back + 0.5), concrete)


static func build_lab_facade(parent: Node3D) -> void:
	var facade_z := STREET_END_Z + 0.55
	for band_y: float in [10.2, 12.9]:
		add_mesh_box(parent, Vector3(27.0, 1.8, 0.12), Vector3(0, band_y, facade_z), Surfaces.get_window_glass())
	for fin_x: int in range(-13, 14, 3):
		add_decor(parent, Vector3(0.25, 5.2, 0.35), Vector3(fin_x, 11.55, facade_z + 0.1), Color(0.8, 0.82, 0.86))
	add_decor(parent, Vector3(16.0, 3.4, 0.2), Vector3(0, 7.1, facade_z), Color(0.04, 0.05, 0.08))
	add_block_between(parent, Vector3(-4.0, 4.5, STREET_END_Z + 0.5), Vector3(4.0, 4.8, STREET_END_Z + 3.5), get_material(Color(0.15, 0.16, 0.2)))
	add_decor(parent, Vector3(8.0, 0.08, 0.1), Vector3(0, 4.45, STREET_END_Z + 3.5), NEON_CYAN, 3.0)


static func build_lab_signs(parent: Node3D) -> void:
	var facade_z := STREET_END_Z + 0.7
	add_sign(parent, "HYPERSYNERGY LABS", Vector3(0, 7.7, facade_z), 0.0, 150, NEON_CYAN)
	add_sign(parent, "NOW HIRING: AGENTS ONLY", Vector3(0, 6.1, facade_z), 0.0, 64, NEON_PINK)
	add_sign(parent, "AGI SOON*", Vector3(0, 11.8, LAB_BACK_Z + 0.6), 0.0, 170, NEON_CYAN)
	add_sign(parent, "*TERMS AND CONDITIONS APPLY", Vector3(0, 10.2, LAB_BACK_Z + 0.6), 0.0, 48, NEON_PINK)


static func build_reception(parent: Node3D) -> void:
	add_block_between(parent, Vector3(-4, 0, -91), Vector3(4, 1.1, -89.5), get_material(RECEPTION_WHITE))
	add_decor(parent, Vector3(8, 0.08, 0.3), Vector3(0, 1.14, -89.4), NEON_CYAN, 2.5)
	for glass_z: float in [-86.0, -95.0]:
		add_block_between(parent, Vector3(-11, 0, glass_z - 0.1), Vector3(-6, 3, glass_z + 0.1), Surfaces.get_glass())


static func build_ramps_and_mezzanine(parent: Node3D) -> void:
	var inner := LAB_HALF_WIDTH - 0.5
	var diamond_plate := Surfaces.get_textured(Surfaces.DIAMOND_PLATE, 1.5)
	add_block_between(parent, Vector3(-inner, MEZZANINE_HEIGHT - 0.5, LAB_BACK_Z + 0.5), Vector3(inner, MEZZANINE_HEIGHT, -100), Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 3.0, INTERIOR_TINT))
	add_block_between(parent, Vector3(-inner, MEZZANINE_HEIGHT, -100.1), Vector3(8.5, MEZZANINE_HEIGHT + 1.1, -99.9), Surfaces.get_glass())
	add_ramp(parent, Vector3(11, 0, -84), Vector3(11, MEZZANINE_HEIGHT, -100), 5.0, diamond_plate)
	add_ramp(parent, Vector3(-10.75, MEZZANINE_HEIGHT, -102), Vector3(-10.75, ROOF_HEIGHT, -118), 5.5, diamond_plate)
	add_block_between(parent, Vector3(-inner, ROOF_HEIGHT - 0.5, LAB_BACK_Z + 0.5), Vector3(-8, ROOF_HEIGHT, -118), diamond_plate)


static func build_lab_ceilings(parent: Node3D) -> void:
	var inner := LAB_HALF_WIDTH - 0.5
	var ceiling := get_material(CEILING_WHITE, 0.3)
	var roof_ceiling_y := ROOF_HEIGHT - 0.55
	var mezzanine_ceiling_y := MEZZANINE_HEIGHT - 0.55
	add_mesh_box(parent, Vector3(inner * 2.0, 0.08, 19.5), Vector3(0, roof_ceiling_y, -90.25), ceiling)
	add_mesh_box(parent, Vector3(inner - (-8.0), 0.08, 19.5), Vector3((inner - 8.0) / 2.0, roof_ceiling_y, -109.75), ceiling)
	add_mesh_box(parent, Vector3(inner * 2.0, 0.08, 19.5), Vector3(0, mezzanine_ceiling_y, -109.75), ceiling)


static func build_roof(parent: Node3D) -> void:
	var outer := LAB_HALF_WIDTH + 0.5
	var slab_bottom := ROOF_HEIGHT - 0.5
	var parapet_top := ROOF_HEIGHT + 1.2
	var roof_surface := Surfaces.get_textured(Surfaces.ROOF_CONCRETE, 4.0)
	var parapet := Surfaces.get_textured(Surfaces.LAB_CONCRETE, 4.0)
	add_block_between(parent, Vector3(-8, slab_bottom, LAB_BACK_Z - 0.5), Vector3(outer, ROOF_HEIGHT, STREET_END_Z + 0.5), roof_surface)
	add_block_between(parent, Vector3(-outer, slab_bottom, -108), Vector3(-8, ROOF_HEIGHT, STREET_END_Z + 0.5), roof_surface)
	add_block_between(parent, Vector3(-outer, ROOF_HEIGHT, STREET_END_Z - 0.5), Vector3(outer, parapet_top, STREET_END_Z + 0.5), parapet)
	add_block_between(parent, Vector3(-outer, ROOF_HEIGHT, LAB_BACK_Z - 0.5), Vector3(outer, parapet_top, LAB_BACK_Z + 0.5), parapet)
	add_block_between(parent, Vector3(-outer, ROOF_HEIGHT, LAB_BACK_Z), Vector3(-outer + 1, parapet_top, STREET_END_Z), parapet)
	add_block_between(parent, Vector3(outer - 1, ROOF_HEIGHT, LAB_BACK_Z), Vector3(outer, parapet_top, STREET_END_Z), parapet)


static func build_roof_railings(parent: Node3D) -> void:
	var inner := LAB_HALF_WIDTH - 0.5
	var railing := get_material(SAFETY_YELLOW)
	add_block_between(parent, Vector3(-inner, ROOF_HEIGHT, -108.1), Vector3(-8, ROOF_HEIGHT + 1.0, -107.9), railing)
	add_block_between(parent, Vector3(-8.1, ROOF_HEIGHT, -117.4), Vector3(-7.9, ROOF_HEIGHT + 1.0, -107.9), railing)


static func build_helipad(parent: Node3D) -> void:
	var pad_y := ROOF_HEIGHT + 0.02
	add_decor(parent, Vector3(9, 0.04, 9), Vector3(5, pad_y, -95), Color(0.18, 0.18, 0.2))
	add_decor(parent, Vector3(8.4, 0.05, 0.25), Vector3(5, pad_y + 0.01, -99.1), SAFETY_YELLOW)
	add_decor(parent, Vector3(8.4, 0.05, 0.25), Vector3(5, pad_y + 0.01, -90.9), SAFETY_YELLOW)
	add_decor(parent, Vector3(0.8, 0.06, 5), Vector3(3.5, pad_y + 0.02, -95), Color.WHITE)
	add_decor(parent, Vector3(0.8, 0.06, 5), Vector3(6.5, pad_y + 0.02, -95), Color.WHITE)
	add_decor(parent, Vector3(2.2, 0.06, 0.8), Vector3(5, pad_y + 0.02, -95), Color.WHITE)
