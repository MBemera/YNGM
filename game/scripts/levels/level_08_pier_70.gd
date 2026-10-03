class_name Level08Pier70
extends Level

const BLUE := Color(0.3, 0.6, 1.0)
const GOLD := Color(1.0, 0.68, 0.2)


func _init() -> void:
	number = 8
	title = "PIER 70"
	tagline = "Priority boarding is a class system with a gangway."
	story_path = "res://data/story/level_08.json"
	player_start = Vector3(0, 0.1, 6)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-27, -4, -148), Vector3(56, 24, 161))
	kill_height = -6.0
	weapon_count = 7
	win_heading = "BOARDING EXCEPTION GRANTED."
	win_body = "One unexpected passenger.\nNext stop: The Ark."
	mood = {"sky_shadow": Color(0.015, 0.015, 0.07), "sky_mid": Color(0.08, 0.08, 0.2),
		"sky_highlight": Color(0.28, 0.3, 0.48), "sky_haze": Color(0.09, 0.1, 0.22),
		"fog_color": Color(0.12, 0.16, 0.3), "fog_density": 0.008, "sky_exposure": 0.7,
		"sun_color": BLUE, "sun_energy": 0.6, "ambient_color": Color(0.5, 0.55, 0.8),
		"ambient_energy": 1.35, "particles": ["rain"]}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["vc", "influencer", "manager", "delivery_bot", "lab_bot"]
	var positions: Array[Vector3] = [Vector3(-5, 0.1, -9), Vector3(5, 0.1, -12),
		Vector3(-19, 0.1, -23), Vector3(12, 0.1, -24), Vector3(-4, 0.1, -30),
		Vector3(4, 0.1, -37), Vector3(-17, 0.1, -40), Vector3(17, 0.1, -42),
		Vector3(-3, 0.1, -48), Vector3(4, 0.1, -54), Vector3(-18, 0.1, -58),
		Vector3(18, 0.1, -60), Vector3(-3, 0.1, -69), Vector3(5, 0.1, -75),
		Vector3(-5, 0.1, -95), Vector3(4, 0.1, -108), Vector3(-4, 0.1, -121), Vector3(5, 0.1, -130)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index], "health_scale": 1.1})
	health_packs = [Vector3(-20, 0, 1), Vector3(19, 0, -24), Vector3(-20, 0, -43),
		Vector3(19, 0, -75), Vector3(-6, 0, -101), Vector3(6, 0, -126)]


func set_objectives() -> void:
	objectives = [
		{"type": "reach", "text": "Get through the container yard", "position": Vector3(0, 0, -80), "beacon_text": "GATE", "opens": "yard_gate"},
		{"type": "reach", "text": "Board the tender before it leaves!", "position": Vector3(15.5, 0, -134.5),
			"beacon_text": "TENDER", "time_limit": 55.0, "countdown_label": "TENDER LEAVES IN",
			"fail_heading": "THE BOAT LEFT.", "fail_body": "The board waved from the deck.\nWelcome to the permanent underclass."},
	]


func set_shots() -> void:
	shots = {
		"overview": {"from": Vector3(22, 21, 10), "to": Vector3(17, 18, -6), "look": Vector3(0, 1, -62)},
		"containers": {"from": Vector3(-18, 8, -12), "to": Vector3(-12, 6, -24), "look": Vector3(0, 1, -55)},
		"tender": {"from": Vector3(35, 10, -105), "to": Vector3(31, 7, -117), "look": Vector3(20, 1, -132)},
	}


func build_world(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.HANGAR_CONCRETE, 4.0, Color(0.5, 0.55, 0.65))
	ArenaKit.floor_slab(parent, -24, 24, -90, 10, 0, concrete)
	ArenaKit.floor_slab(parent, -9, 9, -145, -90, 0, concrete)
	ArenaKit.water(parent, Vector3(0, -2.5, -65), Vector2(600, 600))
	ArenaKit.skyline(parent, Vector3(0, -9, -60), 12, 180, 250, 870, 10, 18)
	build_boundaries(parent)
	build_containers(parent)
	build_cranes(parent)
	build_gate(parent)
	build_tender(parent)


func build_boundaries(parent: Node3D) -> void:
	guard_edge(parent, Vector3(-24, 0, 10), Vector3(24, 0, 10))
	for x: float in [-24.0, 24.0]:
		guard_edge(parent, Vector3(x, 0, -90), Vector3(x, 0, 10))
	guard_edge(parent, Vector3(-24, 0, -90), Vector3(-9, 0, -90))
	guard_edge(parent, Vector3(9, 0, -90), Vector3(24, 0, -90))
	guard_edge(parent, Vector3(-9, 0, -145), Vector3(-9, 0, -90))
	guard_edge(parent, Vector3(-9, 0, -145), Vector3(9, 0, -145))
	guard_edge(parent, Vector3(9, 0, -132), Vector3(9, 0, -90))
	guard_edge(parent, Vector3(9, 0, -145), Vector3(9, 0, -137))
	for z: float in [-97.0, -112.0, -128.0, -141.0]:
		ArenaKit.neon(parent, Vector3(0.16, 0.06, 3), Vector3(-7.5, 0.04, z), GOLD)


func guard_edge(parent: Node3D, from: Vector3, to: Vector3) -> void:
	ArenaKit.railing(parent, from, to, GOLD)
	ArenaKit.invisible_wall(parent, from.min(to) - Vector3(0.08, 0, 0.08), from.max(to) + Vector3(0.08, 5, 0.08))


func build_containers(parent: Node3D) -> void:
	var colors: Array[Color] = [Color(0.65, 0.16, 0.12), Color(0.15, 0.35, 0.65), Color(0.15, 0.45, 0.3), Color(0.8, 0.36, 0.08)]
	for row: int in 4:
		var z := -15.0 - row * 17.0
		for column: int in 4:
			var x: float = [-17.0, -7.0, 7.0, 17.0][column]
			var material := Surfaces.get_textured(Surfaces.CORRUGATED_IRON, 2.0, colors[(row + column) % 4])
			ArenaKit.solid(parent, Vector3(x - 3, 0, z - 1.25), Vector3(x + 3, 2.6, z + 1.25), material)
			if (row + column) % 3 == 0:
				ArenaKit.solid(parent, Vector3(x - 3, 2.6, z - 1.25), Vector3(x + 3, 5.2, z + 1.25), material)
			ArenaKit.place_sign(parent, "OVERCLASS\nHUMAN CAPITAL", Vector3(x, 1.5, z + 1.28), 0, 27, Color(0.85, 0.85, 0.7))
	for z: float in [-24.0, -58.0]:
		ArenaKit.solid(parent, Vector3(-3, 0, z - 1.25), Vector3(3, 2.6, z + 1.25), Surfaces.get_textured(Surfaces.CORRUGATED_IRON, 2.0, colors[1]))
	for point: Vector3 in [Vector3(-21, 0, -34), Vector3(21, 0, -52), Vector3(-6, 0, -115)]:
		ArenaKit.crate(parent, point, 15, 1.3)


func build_cranes(parent: Node3D) -> void:
	var yellow := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, GOLD)
	for z: float in [-26.0, -63.0]:
		for x: float in [-22.0, 22.0]:
			ArenaKit.pillar(parent, Vector3(x, 0, z), Vector2(1.2, 2), 16, yellow)
			ArenaKit.lamp(parent, Vector3(x * 0.8, 13, z), BLUE, 3.5, 30)
		ArenaKit.solid(parent, Vector3(-23, 15, z - 1), Vector3(23, 17, z + 1), yellow)
		ArenaKit.neon(parent, Vector3(44, 0.1, 0.12), Vector3(0, 15.2, z + 1.1), GOLD)
		ArenaKit.neon(parent, Vector3(0.12, 8, 0.12), Vector3(10, 11, z), Color(0.2, 0.25, 0.3), 0)
	for z: float in [-5.0, -82.0, -109.0, -140.0]:
		var x := -21.0 if z > -90 else -7.0
		ArenaKit.pillar(parent, Vector3(x, 0, z), Vector2(0.5, 0.5), 9, yellow)
		ArenaKit.lamp(parent, Vector3(x, 9, z), Color(0.65, 0.75, 1), 3, 24)


func build_gate(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.2, 0.3, 0.45))
	ArenaKit.wall_along_x(parent, -24, -4, -84, 5, metal)
	ArenaKit.wall_along_x(parent, 4, 24, -84, 5, metal)
	ArenaKit.wall_along_x(parent, -4, 4, -84, 1, metal, 5)
	add_door(parent, "yard_gate", Vector3(-4, 0, -84.25), Vector3(4, 5, -83.75))
	ArenaKit.place_sign(parent, "THE ARK / PRIORITY BOARDING\nLEAVE YOUR CONSCIENCE HERE", Vector3(0, 6.9, -83.6), 0, 46, GOLD)


func build_tender(parent: Node3D) -> void:
	var hull := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.12, 0.2, 0.35))
	var white := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.8, 0.85, 0.9))
	ArenaKit.solid(parent, Vector3(14, -3.2, -143), Vector3(26, 0, -117), hull)
	ArenaKit.floor_slab(parent, 9, 14, -137, -132, 0, Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0))
	guard_edge(parent, Vector3(9, 0, -137), Vector3(14, 0, -137))
	guard_edge(parent, Vector3(9, 0, -132), Vector3(14, 0, -132))
	guard_edge(parent, Vector3(14, 0, -143), Vector3(26, 0, -143))
	guard_edge(parent, Vector3(26, 0, -143), Vector3(26, 0, -117))
	guard_edge(parent, Vector3(14, 0, -117), Vector3(26, 0, -117))
	guard_edge(parent, Vector3(14, 0, -143), Vector3(14, 0, -137))
	guard_edge(parent, Vector3(14, 0, -132), Vector3(14, 0, -117))
	ArenaKit.solid(parent, Vector3(18, 0, -128), Vector3(24, 3.5, -120), white)
	ArenaKit.solid(parent, Vector3(17.8, 1.6, -127.8), Vector3(17.95, 2.9, -120.2), Surfaces.get_window_glass())
	ArenaKit.neon(parent, Vector3(6.2, 0.2, 0.1), Vector3(21, 3.3, -128.1), GOLD)
	ArenaKit.place_sign(parent, "THE ARK\nNO ECONOMY CLASS", Vector3(21, 1.8, -128.1), 180, 35, GOLD)
	ArenaKit.lamp(parent, Vector3(20, 5, -133), GOLD, 2, 14, false)
