class_name Level09TheArk
extends Level

const AMBER := Color(1.0, 0.5, 0.15)
const INDIGO := Color(0.35, 0.45, 0.85)


func _init() -> void:
	number = 9
	title = "THE ARK"
	tagline = "A lifeboat for the people who sold the life jackets."
	story_path = "res://data/story/level_09.json"
	player_start = Vector3(0, 0.1, 6)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-32, -2, -112), Vector3(64, 20, 124))
	kill_height = -12.0
	weapon_count = 7
	win_heading = "COUNTDOWN RECONSIDERED."
	win_body = "Dana has the launch controls.\nThe board still has the top floor."
	mood = {"sky_shadow": Color(0.035, 0.025, 0.14), "sky_mid": Color(0.18, 0.14, 0.34),
		"sky_highlight": Color(1.0, 0.48, 0.2), "sky_haze": Color(0.5, 0.28, 0.32),
		"fog_color": Color(0.25, 0.25, 0.42), "fog_density": 0.005,
		"sun_color": AMBER, "sun_rotation": Vector3(-8, 145, 0), "sun_energy": 1.0,
		"ambient_color": INDIGO, "ambient_energy": 0.8, "particles": ["embers"]}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["lab_bot", "manager", "delivery_bot", "vc", "founder"]
	var positions: Array[Vector3] = [Vector3(-12, 0.1, -8), Vector3(12, 0.1, -10),
		Vector3(-6, 0.1, -17), Vector3(7, 0.1, -22), Vector3(-23, 0.1, -23),
		Vector3(23, 0.1, -25), Vector3(-12, 0.1, -33), Vector3(11, 0.1, -37),
		Vector3(-22, 6.1, -54), Vector3(22, 6.1, -54), Vector3(-17, 6.1, -64),
		Vector3(17, 6.1, -66), Vector3(-16, 6.1, -77), Vector3(16, 6.1, -78),
		Vector3(-5, 6.1, -73), Vector3(5, 6.1, -74), Vector3(-18, 6.1, -91), Vector3(18, 6.1, -93)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index], "health_scale": 1.2})
	health_packs = [Vector3(-26, 0, 0), Vector3(15, 0, -28), Vector3(-26, 6, -57),
		Vector3(26, 6, -58), Vector3(-6, 6, -68), Vector3(6, 6, -77), Vector3(-13, 6, -96)]


func set_objectives() -> void:
	var waves: Array[Dictionary] = []
	for fraction: float in [0.0, 0.35, 0.7]:
		waves.append({"at": fraction, "enemies": [
			{"type": "lab_bot", "position": Vector3(-24, 6.1, -65)},
			{"type": "manager", "position": Vector3(24, 6.1, -65)},
			{"type": "delivery_bot", "position": Vector3(-24, 6.1, -86)},
			{"type": "lab_bot", "position": Vector3(24, 6.1, -86)}]})
	objectives = [
		{"type": "reach", "text": "Get to launch control", "position": Vector3(0, 6, -70), "beacon_text": "LAUNCH CONTROL"},
		{"type": "survive", "text": "Hold launch control while Dana overrides the countdown", "seconds": 45.0,
			"countdown_label": "OVERRIDE IN", "opens": "tower_elevator", "waves": waves},
		{"type": "reach", "text": "Get to the tower elevator", "position": Vector3(0, 6, -107), "beacon_text": "ELEVATOR"},
	]


func set_shots() -> void:
	shots = {
		"overview": {"from": Vector3(-40, 30, 20), "to": Vector3(-32, 25, 4), "look": Vector3(3, 5, -60)},
		"rocket": {"from": Vector3(18, 18, -26), "to": Vector3(23, 23, -36), "look": Vector3(43, 24, -68)},
		"control": {"from": Vector3(0, 9, -53), "to": Vector3(0, 8.5, -64), "look": Vector3(0, 8, -76)},
	}


func build_world(parent: Node3D) -> void:
	build_decks(parent)
	build_control(parent)
	build_elevator(parent)
	build_equipment(parent)
	build_rocket(parent)
	ArenaKit.water(parent, Vector3(0, -16, -50), Vector2(800, 800), Color(0.025, 0.03, 0.12), Color(0.22, 0.18, 0.35))
	ArenaKit.skyline(parent, Vector3(0, -25, -50), 10, 260, 340, 970, 10, 20)


func build_decks(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.HANGAR_CONCRETE, 4.0, Color(0.55, 0.6, 0.75))
	var grate := Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0, Color(0.7, 0.7, 0.8))
	ArenaKit.floor_slab(parent, -30, 30, -110, 10, 0, concrete)
	ArenaKit.floor_slab(parent, -30, 30, -110, -50, 6, grate)
	for x: float in [-22.0, 22.0]:
		ArenaKit.ramp(parent, Vector3(x, 0, -30), Vector3(x, 6, -50), 6, grate)
	for segment: Vector2 in [Vector2(-30, -25), Vector2(-19, 19), Vector2(25, 30)]:
		ArenaKit.railing(parent, Vector3(segment.x, 6, -50), Vector3(segment.y, 6, -50), AMBER)
	for x: float in [-30.0, 30.0]:
		ArenaKit.railing(parent, Vector3(x, 0, -110), Vector3(x, 0, 10), AMBER)
		ArenaKit.railing(parent, Vector3(x, 6, -110), Vector3(x, 6, -50), AMBER)
		ArenaKit.invisible_wall(parent, Vector3(x - 0.1, 0, -110), Vector3(x + 0.1, 12, 10))
	ArenaKit.railing(parent, Vector3(-30, 0, 10), Vector3(30, 0, 10), AMBER)
	ArenaKit.railing(parent, Vector3(-30, 0, -110), Vector3(30, 0, -110), AMBER)
	ArenaKit.railing(parent, Vector3(-30, 6, -110), Vector3(30, 6, -110), AMBER)
	ArenaKit.invisible_wall(parent, Vector3(-30, 0, 9.9), Vector3(30, 12, 10.1))
	ArenaKit.invisible_wall(parent, Vector3(-30, 0, -110.1), Vector3(30, 12, -109.9))


func build_control(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.65, 0.7, 0.8))
	for z: float in [-60.0, -80.0]:
		ArenaKit.wall_along_x(parent, -10, -3, z, 4.5, metal, 6)
		ArenaKit.wall_along_x(parent, 3, 10, z, 4.5, metal, 6)
		ArenaKit.wall_along_x(parent, -3, 3, z, 1, metal, 9.5)
	for x: float in [-10.0, 10.0]:
		ArenaKit.wall_along_z(parent, -80, -60, x, 1.1, metal, 6)
		ArenaKit.wall_along_z(parent, -80, -60, x, 3.4, Surfaces.get_glass(), 7.1, 0.2)
		ArenaKit.neon(parent, Vector3(0.12, 0.12, 20), Vector3(x, 10.5, -70), INDIGO)
	ArenaKit.ceiling(parent, -10, 10, -80, -60, 10.5, metal)
	ArenaKit.screen(parent, "THE ARK / LAUNCH CONTROL\nSEATS REMAINING: ZERO", Vector3(6, 8.5, -79.6), 0, 6, 2, AMBER)
	ArenaKit.place_sign(parent, "LAUNCH CONTROL", Vector3(0, 10, -59.6), 0, 50, AMBER)
	for z: float in [-64.0, -75.0]:
		ArenaKit.prop(parent, Models.STATION + "computer-wide.glb", Vector3(-8, 6, z), 90, 1.8)
		ArenaKit.lamp(parent, Vector3(0, 10, z), INDIGO, 2, 14)


func build_elevator(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.3, 0.35, 0.5))
	ArenaKit.wall_along_x(parent, -30, -3, -101, 7, metal, 6)
	ArenaKit.wall_along_x(parent, 3, 30, -101, 7, metal, 6)
	ArenaKit.wall_along_x(parent, -3, 3, -101, 2, metal, 11)
	add_door(parent, "tower_elevator", Vector3(-3, 6, -101.3), Vector3(3, 11, -100.7))
	ArenaKit.place_sign(parent, "TOWER ELEVATOR\nUPWARD MOBILITY: RESTRICTED", Vector3(0, 12, -100.6), 0, 44, AMBER)
	ArenaKit.ceiling(parent, -30, 30, -110, -101, 13, metal)
	ArenaKit.screen(parent, "EXECUTIVE FLOOR", Vector3(0, 9, -109.5), 0, 6, 1.6, AMBER)


func build_equipment(parent: Node3D) -> void:
	for point: Vector3 in [Vector3(-16, 0, -15), Vector3(17, 0, -18), Vector3(-6, 0, -35), Vector3(7, 0, -43), Vector3(-16, 6, -84), Vector3(16, 6, -90)]:
		ArenaKit.crate(parent, point, 0, 1.5, 1)
	for z: float in [-12.0, -47.0, -88.0]:
		for x: float in [-28.0, 28.0]:
			var y := 6.0 if z < -50 else 0.0
			ArenaKit.pillar(parent, Vector3(x, y, z), Vector2(0.6, 0.6), 7, LevelBuilder.get_material(AMBER))
			ArenaKit.lamp(parent, Vector3(x, y + 7, z), AMBER, 2.5, 22)
	ArenaKit.place_sign(parent, "THE ARK\nSAVING HUMANITY / SELECT ACCOUNTS ONLY", Vector3(0, 5, -48), 0, 62, AMBER)


func build_rocket(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 4.0, Color(0.85, 0.85, 0.9))
	ArenaKit.solid(parent, Vector3(35, -4, -77), Vector3(51, 0, -59), metal)
	add_rocket_section(parent, Vector3(43, 19, -68), 38, 4.5, 4.5, metal)
	add_rocket_section(parent, Vector3(43, 42, -68), 8, 4.5, 0, metal)
	for x: float in [36.0, 50.0]:
		LevelBuilder.add_decor(parent, Vector3(1, 42, 1), Vector3(x, 21, -75), Color(0.6, 0.28, 0.08))
	for y: float in [8.0, 18.0, 28.0, 38.0]:
		LevelBuilder.add_decor(parent, Vector3(15, 0.6, 2), Vector3(43, y, -75), AMBER)
		ArenaKit.neon(parent, Vector3(9.1, 0.25, 0.15), Vector3(43, y, -63.4), AMBER)
	ArenaKit.place_sign(parent, "THE ARK\nESCAPE VELOCITY", Vector3(43, 25, -63.3), 0, 100, AMBER)


func add_rocket_section(parent: Node3D, center: Vector3, height: float, bottom_radius: float, top_radius: float, material: Material) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.height = height
	cylinder.bottom_radius = bottom_radius
	cylinder.top_radius = top_radius
	cylinder.radial_segments = 24
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.material_override = material
	mesh.position = center
	parent.add_child(mesh)
