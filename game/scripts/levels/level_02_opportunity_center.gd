class_name Level02OpportunityCenter
extends Level

const HALF_WIDTH := 20.0
const BACK_Z := 8.0
const DOCK_Z := -90.0
const BAY_END_Z := -112.0
const BAY_HALF_WIDTH := 12.0
const CEILING_Y := 10.0
const CATWALK_Y := 4.0
const CATWALK_NEAR_Z := -10.0
const CATWALK_FAR_Z := -60.0
const CATWALK_INNER_X := 15.0
const DESK_COLUMNS: Array[float] = [-12.0, -8.5, -5.0, 5.0, 8.5, 12.0]
const DESK_ROWS: Array[float] = [-9.0, -15.0, -21.0, -27.0]
const SHELF_COLUMNS: Array[float] = [-14.0, -9.0, 9.0, 14.0]
const LAMP_COLUMNS: Array[float] = [-9.0, 9.0]
const LAMP_ROWS: Array[float] = [-6.0, -22.0, -38.0, -54.0, -70.0]
const FLUORESCENT := Color(0.82, 1.0, 0.85)
const TERMINAL_PINK := Color(1.0, 0.3, 0.6)
const TERMINAL_MODEL := "res://assets/models/station/computer-wide.glb"


func _init() -> void:
	number = 2
	title = "THE OPPORTUNITY CENTER"
	tagline = "You climbed the ladder. It led to a data-labeling farm. Break out through the loading dock."
	story_path = "res://data/story/level_02.json"
	player_start = Vector3(0, 0.1, 4)
	navigation_bounds = AABB(Vector3(-22, -2, -114), Vector3(44, 16, 124))
	kill_height = -8.0
	weapon_count = 4
	win_heading = "SHIFT ENDED."
	win_body = "You clocked out of the Opportunity Center.\nPermanently. Somewhere, a quota went unmet."
	mood = {
		"sky_shadow": Color(0.02, 0.03, 0.08),
		"sky_mid": Color(0.15, 0.12, 0.3),
		"sky_highlight": Color(0.6, 0.45, 0.65),
		"sky_haze": Color(0.08, 0.06, 0.12),
		"sky_exposure": 0.6,
		"fog_color": Color(0.5, 0.6, 0.5),
		"fog_density": 0.0045,
		"sun_color": Color(0.6, 0.7, 1.0),
		"sun_energy": 0.5,
		"sun_rotation": Vector3(-50, 30, 0),
		"ambient_color": Color(0.5, 0.56, 0.5),
		"ambient_energy": 0.85,
		"glow_intensity": 0.8,
		"saturation": 0.92,
		"particles": ["ash"],
		"sun_shadows": false,
	}
	shots = {
		"overview": {"from": Vector3(0, 8.5, 6), "to": Vector3(0, 7.5, -4), "look": Vector3(0, 1, -40)},
		"desks": {"from": Vector3(-11, 3.2, -3), "to": Vector3(-6, 2.6, -10), "look": Vector3(3, 1, -24)},
		"terminals": {"from": Vector3(9, 4.5, -36), "to": Vector3(5, 4, -41), "look": Vector3(0, 1.2, -48)},
	}
	objectives = [
		{
			"type": "destroy",
			"text": "Smash the shift-quota terminals",
			"opens": "dock",
			"targets": [
				create_terminal(Vector3(-17.5, CATWALK_Y, -40)),
				create_terminal(Vector3(0, 0, -48)),
				create_terminal(Vector3(17.5, CATWALK_Y, -54)),
			],
		},
		{"type": "reach", "text": "Escape through the loading dock", "position": Vector3(-3, 0, -102), "beacon_text": "LOADING DOCK"},
	]
	enemies = [
		{"type": "manager", "position": Vector3(-6.5, 0.1, -18), "health_scale": 0.6},
		{"type": "founder", "position": Vector3(6.5, 0.1, -17), "health_scale": 0.6},
		{"type": "founder", "position": Vector3(-1, 0.1, -26), "health_scale": 0.6},
		{"type": "vc", "position": Vector3(10.5, 0.1, -30)},
		{"type": "manager", "position": Vector3(0, 0.1, -34)},
		{"type": "vc", "position": Vector3(-17.5, CATWALK_Y + 0.1, -30)},
		{"type": "influencer", "position": Vector3(17.5, CATWALK_Y + 0.1, -36)},
		{"type": "lab_bot", "position": Vector3(-17.5, CATWALK_Y + 0.1, -52)},
		{"type": "manager", "position": Vector3(-6, 0.1, -52)},
		{"type": "lab_bot", "position": Vector3(6, 0.1, -58)},
		{"type": "influencer", "position": Vector3(0, 0.1, -63)},
		{"type": "founder", "position": Vector3(-11.5, 0.1, -66)},
		{"type": "founder", "position": Vector3(11.5, 0.1, -67)},
		{"type": "lab_bot", "position": Vector3(-6, 0.1, -80)},
		{"type": "manager", "position": Vector3(6, 0.1, -82)},
		{"type": "vc", "position": Vector3(0, 0.1, -86)},
	]
	health_packs = [
		Vector3(-15, 0, -12),
		Vector3(17.5, CATWALK_Y, -24),
		Vector3(3, 0, -42),
		Vector3(-11.5, 0, -61),
		Vector3(11, 0, -77),
	]


static func create_terminal(position: Vector3) -> Dictionary:
	return {"name": "SHIFT QUOTA TERMINAL", "model": TERMINAL_MODEL, "height": 2.2, "health": 300, "color": TERMINAL_PINK, "position": position, "yaw": 90.0}


func build_world(parent: Node3D) -> void:
	build_shell(parent)
	build_labeling_floor(parent)
	build_catwalk(parent, -1)
	build_catwalk(parent, 1)
	build_stock_area(parent)
	build_dock(parent)
	build_outside_bay(parent)
	build_lighting(parent)
	build_signs(parent)


func build_shell(parent: Node3D) -> void:
	var carpet := Surfaces.get_textured(Surfaces.CARPET, 2.0, Color(0.55, 0.62, 0.7))
	var concrete := Surfaces.get_textured(Surfaces.HANGAR_CONCRETE, 4.0, Color(0.8, 0.82, 0.8))
	var iron := Surfaces.get_textured(Surfaces.CORRUGATED_IRON, 3.0, Color(0.55, 0.62, 0.6))
	ArenaKit.floor_slab(parent, -HALF_WIDTH, HALF_WIDTH, -36, BACK_Z, 0.0, carpet)
	ArenaKit.floor_slab(parent, -HALF_WIDTH, HALF_WIDTH, DOCK_Z, -36, 0.0, concrete)
	ArenaKit.wall_along_z(parent, DOCK_Z, BACK_Z, -HALF_WIDTH, CEILING_Y, iron)
	ArenaKit.wall_along_z(parent, DOCK_Z, BACK_Z, HALF_WIDTH, CEILING_Y, iron)
	ArenaKit.wall_along_x(parent, -HALF_WIDTH, HALF_WIDTH, BACK_Z, CEILING_Y, iron)
	ArenaKit.ceiling(parent, -HALF_WIDTH, HALF_WIDTH, DOCK_Z, BACK_Z, CEILING_Y, LevelBuilder.get_material(Color(0.2, 0.22, 0.24)))
	for truss_z: float in range(-6, int(DOCK_Z), -12):
		LevelBuilder.add_decor(parent, Vector3(HALF_WIDTH * 2.0, 0.5, 0.4), Vector3(0, CEILING_Y - 0.4, truss_z), Color(0.3, 0.32, 0.35))


func build_labeling_floor(parent: Node3D) -> void:
	var partition := Surfaces.get_textured(Surfaces.CARPET, 1.0, Color(0.35, 0.4, 0.55))
	for row_z: float in DESK_ROWS:
		for column_x: float in DESK_COLUMNS:
			place_workstation(parent, Vector3(column_x, 0, row_z))
		ArenaKit.wall_along_x(parent, -13.5, -3.5, row_z - 1.0, 1.3, partition, 0.0, 0.12)
		ArenaKit.wall_along_x(parent, 3.5, 13.5, row_z - 1.0, 1.3, partition, 0.0, 0.12)
	ArenaKit.screen(parent, "QUOTA\n4,000 LABELS / HOUR", Vector3(0, 6.5, -30), 0.0, 6.0, 2.6, LevelBuilder.NEON_CYAN)


func place_workstation(parent: Node3D, floor_position: Vector3) -> void:
	ArenaKit.prop(parent, Models.FURNITURE + "desk.glb", floor_position, 0.0, 0.8)
	Models.spawn_fitted(parent, Models.FURNITURE + "computerScreen.glb", floor_position + Vector3(0, 0.8, -0.15), 0.0, 0.5)
	Models.spawn_fitted(parent, Models.FURNITURE + "chairDesk.glb", floor_position + Vector3(0, 0, 0.9), 180.0, 1.1)
	LevelBuilder.add_decor(parent, Vector3(0.5, 0.3, 0.02), floor_position + Vector3(0, 1.08, -0.1), Color(0.3, 1.0, 0.6), 1.5)


func build_catwalk(parent: Node3D, side: int) -> void:
	var grate := Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0)
	var center_x := 17.5 * side
	var outer_x := HALF_WIDTH * side
	var inner_x := CATWALK_INNER_X * side
	ArenaKit.solid(parent, Vector3(minf(outer_x, inner_x), CATWALK_Y - 0.4, CATWALK_FAR_Z), Vector3(maxf(outer_x, inner_x), CATWALK_Y, CATWALK_NEAR_Z), grate)
	ArenaKit.ramp(parent, Vector3(center_x, 0, -2), Vector3(center_x, CATWALK_Y, CATWALK_NEAR_Z), 4.0, grate)
	ArenaKit.railing(parent, Vector3(inner_x, CATWALK_Y, CATWALK_NEAR_Z), Vector3(inner_x, CATWALK_Y, CATWALK_FAR_Z))
	ArenaKit.railing(parent, Vector3(outer_x, CATWALK_Y, CATWALK_FAR_Z), Vector3(inner_x, CATWALK_Y, CATWALK_FAR_Z))
	for post_z: float in range(int(CATWALK_NEAR_Z), int(CATWALK_FAR_Z), -10):
		ArenaKit.pillar(parent, Vector3(inner_x - 0.3 * side, 0, post_z - 5), Vector2(0.3, 0.3), CATWALK_Y - 0.4, LevelBuilder.get_material(Color(0.35, 0.35, 0.38)))
	ArenaKit.prop(parent, Models.STATION + "container.glb", Vector3(center_x, CATWALK_Y, -45), 0.0, 1.2)


func build_stock_area(parent: Node3D) -> void:
	var shelf := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.9, 0.55, 0.25))
	for column_x: float in SHELF_COLUMNS:
		ArenaKit.solid(parent, Vector3(column_x - 0.6, 0, -60), Vector3(column_x + 0.6, 3.5, -50), shelf)
		ArenaKit.solid(parent, Vector3(column_x - 0.6, 0, -74), Vector3(column_x + 0.6, 3.5, -66), shelf)
		for stack_z: float in [-52.0, -55.0, -58.0, -68.0, -71.0]:
			ArenaKit.crate(parent, Vector3(column_x, 3.5, stack_z), 0.0, 0.9, int(stack_z))
	for crate_position: Vector3 in [Vector3(-4, 0, -57), Vector3(4.5, 0, -62), Vector3(-3.5, 0, -70), Vector3(3, 0, -73)]:
		ArenaKit.crate(parent, crate_position, randf_range(0, 40), 1.2, int(crate_position.z))


func build_dock(parent: Node3D) -> void:
	var iron := Surfaces.get_textured(Surfaces.CORRUGATED_IRON, 3.0, Color(0.55, 0.62, 0.6))
	ArenaKit.wall_along_x(parent, -HALF_WIDTH, -6, DOCK_Z, CEILING_Y, iron)
	ArenaKit.wall_along_x(parent, 6, HALF_WIDTH, DOCK_Z, CEILING_Y, iron)
	ArenaKit.solid(parent, Vector3(-6, 5, DOCK_Z - 0.25), Vector3(6, CEILING_Y, DOCK_Z + 0.25), iron)
	add_door(parent, "dock", Vector3(-6, 0, DOCK_Z - 0.4), Vector3(6, 5, DOCK_Z + 0.4), 0.0)
	for stripe_x: float in [-6.4, 6.4]:
		ArenaKit.neon(parent, Vector3(0.25, 5.0, 0.1), Vector3(stripe_x, 2.5, DOCK_Z + 0.3), LevelBuilder.SAFETY_YELLOW, 2.0)
	ArenaKit.prop(parent, Models.CARS + "tractor-shovel.glb", Vector3(-12, 0, -84), 30.0, 2.2)
	for pallet_x: float in [-15.0, 12.0, 15.0]:
		ArenaKit.crate(parent, Vector3(pallet_x, 0, -86), 0.0, 1.4, int(pallet_x))
	LevelBuilder.add_decor(parent, Vector3(2.0, 0.5, 14.0), Vector3(16.5, 0.6, -78), Color(0.15, 0.15, 0.17))


func build_outside_bay(parent: Node3D) -> void:
	var asphalt := Surfaces.get_textured(Surfaces.ASPHALT, 4.0, Color(0.7, 0.7, 0.75))
	var fence := Surfaces.get_textured(Surfaces.CORRUGATED_IRON, 3.0, Color(0.35, 0.38, 0.42))
	ArenaKit.floor_slab(parent, -BAY_HALF_WIDTH, BAY_HALF_WIDTH, BAY_END_Z, DOCK_Z, 0.0, asphalt)
	ArenaKit.wall_along_z(parent, BAY_END_Z, DOCK_Z, -BAY_HALF_WIDTH, 6.0, fence)
	ArenaKit.wall_along_z(parent, BAY_END_Z, DOCK_Z, BAY_HALF_WIDTH, 6.0, fence)
	ArenaKit.wall_along_x(parent, -BAY_HALF_WIDTH, BAY_HALF_WIDTH, BAY_END_Z, 6.0, fence)
	ArenaKit.invisible_wall(parent, Vector3(-BAY_HALF_WIDTH, 6, BAY_END_Z), Vector3(BAY_HALF_WIDTH, 30, DOCK_Z))
	ArenaKit.car(parent, "truck", Vector3(6, 0, -103), 0.0, 1.8)
	ArenaKit.skyline(parent, Vector3(0, 0, -230), 24, 75.0, 120.0, 202)
	ArenaKit.smoke(parent, Vector3(-50, 0, -150))
	ArenaKit.lamp(parent, Vector3(-9, 5.5, -95), Color(1.0, 0.75, 0.45), 2.5, 16.0)


func build_lighting(parent: Node3D) -> void:
	for lamp_z: float in LAMP_ROWS:
		for lamp_x: float in LAMP_COLUMNS:
			ArenaKit.lamp(parent, Vector3(lamp_x, CEILING_Y - 0.5, lamp_z), FLUORESCENT, 2.4, 17.0)
	var warning := OmniLight3D.new()
	warning.light_color = Color(1.0, 0.2, 0.15)
	warning.light_energy = 2.0
	warning.omni_range = 8.0
	warning.position = Vector3(0, 6, DOCK_Z + 1.5)
	parent.add_child(warning)


func build_signs(parent: Node3D) -> void:
	ArenaKit.flickering_sign(parent, "WELCOME TO THE OPPORTUNITY CENTER", Vector3(0, 7.5, BACK_Z - 0.3), 180.0, 110, LevelBuilder.NEON_CYAN)
	ArenaKit.place_sign(parent, "YOUR LABELS TRAIN\nYOUR REPLACEMENT", Vector3(-HALF_WIDTH + 0.3, 7.2, -24), 90.0, 120, LevelBuilder.NEON_PINK)
	ArenaKit.place_sign(parent, "BATHROOM BREAKS ARE\nA PREMIUM FEATURE", Vector3(HALF_WIDTH - 0.3, 7.2, -30), -90.0, 110, LevelBuilder.SAFETY_YELLOW)
	ArenaKit.flickering_sign(parent, "EMPLOYEE OF THE MONTH: OMEGA", Vector3(-HALF_WIDTH + 0.3, 7.0, -70), 90.0, 90, Color(0.5, 1.0, 0.4))
	ArenaKit.place_sign(parent, "SHIPPING: YOUR FUTURE\n(NON-REFUNDABLE)", Vector3(0, 7.2, DOCK_Z + 0.35), 0.0, 100, LevelBuilder.SAFETY_YELLOW)
	ArenaKit.place_sign(parent, "STOCK ROOM\nHAPPINESS IS NOT IN STOCK", Vector3(HALF_WIDTH - 0.3, 6.5, -62), -90.0, 80, Color(1.0, 0.6, 0.3))
