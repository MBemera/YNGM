class_name Level04SandHillRoad
extends Level

const GOLD := Color(1.0, 0.72, 0.3)
const FIRMS: Array[String] = ["HOPIUM HOCKEY STICK FUND", "UNICORN TAXIDERMY PARTNERS", "MOSTLY VIBES CAPITAL", "PIVOTSAURUS VENTURES"]


func _init() -> void:
	number = 4
	title = "SAND HILL ROAD"
	tagline = "The lawns are liquid. Your assets are not."
	story_path = "res://data/story/level_04.json"
	player_start = Vector3(0, 0.1, 6)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-26, -2, -98), Vector3(52, 20, 110))
	kill_height = -6.0
	weapon_count = 5
	win_heading = "STRATEGIC INVESTMENT."
	win_body = "Upround hands over the campus keys as a strategic investment.\nHe still wants a board seat in your escape."
	mood = {"sky_shadow": Color(0.22, 0.09, 0.12), "sky_mid": Color(0.85, 0.4, 0.16),
		"sky_highlight": Color(1.0, 0.85, 0.5), "sky_haze": Color(0.7, 0.4, 0.22),
		"sun_color": GOLD, "sun_rotation": Vector3(-16, 125, 0), "sun_energy": 1.5,
		"fog_color": Color(0.8, 0.57, 0.35), "fog_density": 0.003,
		"ambient_color": Color(0.65, 0.52, 0.42), "ambient_energy": 0.8, "particles": ["gold"]}
	set_encounters()
	set_objectives()
	shots = {
		"overview": {"from": Vector3(1, 11, 6), "to": Vector3(3, 9, -7), "look": Vector3(0, 2, -38)},
		"courtyard": {"from": Vector3(-10, 8, -62), "to": Vector3(-7, 6, -66), "look": Vector3(0, 4, -90)},
	}


func set_encounters() -> void:
	var types: Array[String] = ["vc", "vc", "influencer", "vc", "founder", "vc", "manager"]
	var positions: Array[Vector3] = [Vector3(-5, 0.1, -9), Vector3(5, 0.1, -12),
		Vector3(-13, 0.1, -17), Vector3(1, 0.1, -22), Vector3(12, 0.1, -25),
		Vector3(-5, 0.1, -28), Vector3(6, 0.1, -32), Vector3(-12, 0.1, -35),
		Vector3(0, 0.1, -39), Vector3(12, 0.1, -41), Vector3(-5, 0.1, -44),
		Vector3(6, 0.1, -48), Vector3(-10, 0.1, -52), Vector3(3, 0.1, -54),
		Vector3(-11, 0.1, -64), Vector3(11, 0.1, -85)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index]})
	health_packs = [Vector3(-9, 0, 0), Vector3(8, 0, -21), Vector3(-8, 0, -42),
		Vector3(10, 0, -55), Vector3(-10, 0, -88), Vector3(10, 0, -66)]


func set_objectives() -> void:
	objectives = [
		{"type": "reach", "text": "Fight through the office park to Down Round Capital",
			"position": Vector3(0, 0, -59), "beacon_text": "DOWN ROUND CAPITAL"},
		{"type": "boss", "text": "Take the campus keys from Lance Upround",
			"boss_name": "LANCE UPROUND - DOWN ROUND CAPITAL",
			"bosses": [{"type": "board_member", "position": Vector3(0, 0.1, -76)}]},
	]


func build_world(parent: Node3D) -> void:
	build_park(parent)
	build_offices(parent)
	build_boulevard(parent)
	build_fountain(parent)
	build_sculpture(parent)
	build_courtyard(parent)
	ArenaKit.skyline(parent, Vector3(0, -2, -40), 20, 80, 125, 404, 10, 17)


func build_park(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.SIDEWALK_CONCRETE, 3.0, Color(0.88, 0.83, 0.7))
	ArenaKit.floor_slab(parent, -24, 24, -94, 10, 0, concrete)
	for x: float in [-15.5, 15.5]:
		for segment: Vector2 in [Vector2(-16, 10), Vector2(-40, -22), Vector2(-58, -46)]:
			var center := Vector3(x, 0.012, (segment.x + segment.y) / 2.0)
			LevelBuilder.add_decor(parent, Vector3(17, 0.02, segment.y - segment.x), center, Color(0.25, 0.45, 0.2))
	var brick := Surfaces.get_textured(Surfaces.RED_BRICK, 3.0, Color(0.85, 0.7, 0.62))
	for x: float in [-24.0, 24.0]:
		ArenaKit.wall_along_z(parent, -94, 10, x, 7, brick)
	for z: float in [-94.0, 10.0]:
		ArenaKit.wall_along_x(parent, -24, 24, z, 7, brick)
	ArenaKit.place_sign(parent, "SAND HILL ROAD\nCAPITAL HAS RIGHT OF WAY", Vector3(0, 4, 9.6), 180, 65, GOLD)


func build_offices(parent: Node3D) -> void:
	var stone := Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 3.0, Color(0.8, 0.75, 0.64))
	for index: int in FIRMS.size():
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := 21.0 * side
		var z := -12.0 if index < 2 else -38.0
		ArenaKit.solid(parent, Vector3(x - 3, 0, z - 8), Vector3(x + 3, 6, z + 8), stone)
		for offset: float in [-5.0, 0.0, 5.0]:
			ArenaKit.solid(parent, Vector3(x - 3.06, 1, z + offset - 1.8), Vector3(x + 3.06, 4.6, z + offset + 1.8), Surfaces.get_window_glass())
		ArenaKit.place_sign(parent, FIRMS[index], Vector3(x - 3.15 * side, 5.2, z), -90 * side, 42, GOLD)
		ArenaKit.neon(parent, Vector3(0.12, 0.1, 15), Vector3(x - 3.2 * side, 5.8, z), GOLD, 1.0)


func build_boulevard(parent: Node3D) -> void:
	for z: float in [-3.0, -27.0, -51.0]:
		for x: float in [-10.0, 10.0]:
			build_tree(parent, Vector3(x, 0, z))
		ArenaKit.lamp(parent, Vector3(0, 6, z), GOLD, 0.8, 14, false)
	ArenaKit.car(parent, "suv-luxury", Vector3(-14, 0, -7), 0, 1.5)
	ArenaKit.car(parent, "sedan-sports", Vector3(14, 0, -15), 180, 1.5)
	ArenaKit.car(parent, "hatchback-sports", Vector3(14, 0, -46), 170, 1.5)
	for z: float in [-18.0, -42.0]:
		ArenaKit.prop(parent, Models.FURNITURE + "bench.glb", Vector3(-9, 0, z), 90, 1.0)


func build_tree(parent: Node3D, position: Vector3) -> void:
	ArenaKit.pillar(parent, position, Vector2(0.45, 0.45), 3.8, LevelBuilder.get_material(Color(0.3, 0.2, 0.12)))
	LevelBuilder.add_decor(parent, Vector3(3.8, 2.6, 3.8), position + Vector3(0, 4.4, 0), Color(0.22, 0.38, 0.14))
	LevelBuilder.add_decor(parent, Vector3(2.7, 1.5, 2.7), position + Vector3(0.3, 6, 0), Color(0.35, 0.48, 0.19))


func build_fountain(parent: Node3D) -> void:
	var stone := Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 2.0)
	ArenaKit.solid(parent, Vector3(-16, 0, -32), Vector3(-10, 0.45, -26), stone)
	for x: float in [-16.0, -10.0]:
		ArenaKit.wall_along_z(parent, -32, -26, x, 0.8, stone)
	for z: float in [-32.0, -26.0]:
		ArenaKit.wall_along_x(parent, -16, -10, z, 0.8, stone)
	ArenaKit.water(parent, Vector3(-13, 0.65, -29), Vector2(5.4, 5.4))
	ArenaKit.pillar(parent, Vector3(-13, 0.45, -29), Vector2(0.7, 0.7), 2.0, stone)
	ArenaKit.solid(parent, Vector3(-14.3, 2.35, -30.3), Vector3(-11.7, 2.45, -27.7), stone)
	for x: float in [-14.3, -11.7]:
		ArenaKit.wall_along_z(parent, -30.3, -27.7, x, 0.25, stone, 2.35, 0.15)
	for z: float in [-30.3, -27.7]:
		ArenaKit.wall_along_x(parent, -14.3, -11.7, z, 0.25, stone, 2.35, 0.15)
	ArenaKit.water(parent, Vector3(-13, 2.5, -29), Vector2(2.3, 2.3))
	ArenaKit.place_sign(parent, "LIQUIDITY POOL\nWITHDRAWALS PAUSED", Vector3(-13, 1.5, -25.6), 0, 30, GOLD)


func build_sculpture(parent: Node3D) -> void:
	ArenaKit.pillar(parent, Vector3(13, 0, -33), Vector2(3, 3), 0.8, Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 2.0))
	for index: int in 3:
		var beam := LevelBuilder.add_decor(parent, Vector3(0.7, 5, 0.7), Vector3(13, 3.1, -33), GOLD, 0.4)
		beam.rotation_degrees = Vector3(25 * index, 60 * index, 25)
	ArenaKit.place_sign(parent, "DISRUPTION\nPLEASE DO NOT DISRUPT", Vector3(13, 1.6, -31.3), 0, 32, GOLD)


func build_courtyard(parent: Node3D) -> void:
	var stone := Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 3.0, Color(0.8, 0.74, 0.62))
	for x: float in [-18.0, 18.0]:
		ArenaKit.wall_along_z(parent, -94, -58, x, 7, stone)
	ArenaKit.wall_along_x(parent, -18, -4, -58, 7, stone)
	ArenaKit.wall_along_x(parent, 4, 18, -58, 7, stone)
	ArenaKit.wall_along_x(parent, -18, 18, -93, 11, stone)
	for x: float in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		ArenaKit.solid(parent, Vector3(x - 2, 2, -92.7), Vector3(x + 2, 7, -92.6), Surfaces.get_window_glass())
	ArenaKit.place_sign(parent, "DOWN ROUND CAPITAL", Vector3(0, 9, -92.5), 0, 145, GOLD)
	ArenaKit.place_sign(parent, "WARM INTROS. COLD TERMS.", Vector3(0, 1.8, -92.5), 0, 52, GOLD)
	for x: float in [-14.0, 14.0]:
		for z: float in [-65.0, -86.0]:
			ArenaKit.solid(parent, Vector3(x - 1.5, 0, z - 2), Vector3(x + 1.5, 1.1, z + 2), stone)
			LevelBuilder.add_decor(parent, Vector3(2.8, 0.5, 3.8), Vector3(x, 1.3, z), Color(0.25, 0.45, 0.2))
		ArenaKit.prop(parent, Models.FURNITURE + "bench.glb", Vector3(x, 0, -76), 90, 1.1)
		ArenaKit.lamp(parent, Vector3(x, 6, -76), GOLD, 1.5, 17, false)
