class_name Level07ColdAisle
extends Level

const CYAN := Color(0.3, 0.8, 1.0)


func _init() -> void:
	number = 7
	title = "COLD AISLE"
	tagline = "Overclass keeps the servers cold and the promises warm."
	story_path = "res://data/story/level_07.json"
	player_start = Vector3(0, 0.1, 6)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-24, -2, -102), Vector3(48, 14, 114))
	kill_height = -6.0
	weapon_count = 7
	win_heading = "THERMAL THROTTLING."
	win_body = "OMEGA needs a moment to think.\nYou were in the freight lift before it finished."
	mood = {"sky_shadow": Color(0.02, 0.04, 0.09), "sky_mid": Color(0.12, 0.2, 0.3),
		"fog_color": Color(0.45, 0.65, 0.8), "fog_density": 0.012,
		"sun_energy": 0.08, "sun_color": Color(1, 0.7, 0.5),
		"ambient_color": Color(0.4, 0.65, 0.85), "ambient_energy": 0.8, "particles": ["data"], "sun_shadows": false}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["lab_bot", "delivery_bot", "manager", "influencer", "founder"]
	var positions: Array[Vector3] = [Vector3(-10, 0.1, -12), Vector3(1, 0.1, -14),
		Vector3(12, 0.1, -20), Vector3(-19, 0.1, -26), Vector3(-1, 0.1, -28),
		Vector3(-10, 0.1, -36), Vector3(12, 0.1, -38), Vector3(1, 0.1, -46),
		Vector3(-18, 0.1, -54), Vector3(-8, 0.1, -58), Vector3(10, 0.1, -61),
		Vector3(-11, 0.1, -71), Vector3(9, 0.1, -74), Vector3(18, 3.1, -28),
		Vector3(18, 3.1, -60), Vector3(0, 0.1, -88)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index]})
	health_packs = [Vector3(-19, 0, 0), Vector3(11, 0, -30), Vector3(-11, 0, -48),
		Vector3(18, 3, -46), Vector3(-19, 0, -87), Vector3(13, 0, -88)]


func set_objectives() -> void:
	var targets: Array[Dictionary] = []
	for x: float in [-15.0, -3.0, 10.0]:
		targets.append({"name": "COOLING CORE", "model": GraphicsScenery.ROOT + "cooling-core.glb",
			"height": 3.0, "health": 420, "color": CYAN, "position": Vector3(x, 0, -82)})
	objectives = [
		{"type": "destroy", "text": "Destroy the cooling cores", "opens": "freight_lift", "targets": targets},
		{"type": "reach", "text": "Take the freight lift up", "position": Vector3(0, 0, -97), "beacon_text": "FREIGHT LIFT"},
	]


func set_shots() -> void:
	shots = {
		"overview": {"from": Vector3(0, 7, 7), "to": Vector3(1, 6, -8), "look": Vector3(0, 2, -42)},
		"omega_core": {"from": Vector3(-9, 5, -51), "to": Vector3(-6, 4, -55), "look": Vector3(0, 4, -65)},
		"cores": {"from": Vector3(12, 6, -71), "to": Vector3(5, 5, -73), "look": Vector3(-3, 1.8, -82)},
		"lift": {"from": Vector3(6, 4, -85), "to": Vector3(3, 3, -88), "look": Vector3(0, 2, -92)},
	}


func build_world(parent: Node3D) -> void:
	build_shell(parent)
	build_racks(parent)
	build_catwalk(parent)
	build_core(parent)
	build_lift(parent)


func build_shell(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.35, 0.5, 0.7))
	ArenaKit.floor_slab(parent, -22, 22, -100, 10, 0, Surfaces.get_textured(Surfaces.CLEAN_TILES, 3.0, Color(0.65, 0.8, 0.9)))
	for x: float in [-22.0, 22.0]:
		ArenaKit.wall_along_z(parent, -100, 10, x, 9, metal)
	for z: float in [-100.0, 10.0]:
		ArenaKit.wall_along_x(parent, -22, 22, z, 9, metal)
	ArenaKit.ceiling(parent, -22, 22, -100, 10, 9, metal)
	for z: float in [-4.0, -25.0, -46.0, -67.0, -88.0]:
		for x: float in [-11.0, 10.0]:
			ArenaKit.lamp(parent, Vector3(x, 7.6, z), CYAN, 2.0, 18.0)
		ArenaKit.neon(parent, Vector3(40, 0.12, 0.15), Vector3(0, 8.5, z), CYAN)
	ArenaKit.place_sign(parent, "OVERCLASS\nYOUR DATA IS OUR PERSONALITY", Vector3(0, 5.5, 9.5), 180, 65, CYAN)


func build_racks(parent: Node3D) -> void:
	var rack_material := Surfaces.get_textured(Surfaces.BLUE_METAL, 1.5, Color(0.16, 0.22, 0.3))
	var models: Array[String] = ["computer-system.glb", "computer-wide.glb", "computer.glb"]
	for index: int in 3:
		var x: float = [-15.0, -6.0, 7.0][index]
		for z: float in [-6.0, -18.0, -30.0, -42.0]:
			ArenaKit.solid(parent, Vector3(x - 1.5, 0, z - 4), Vector3(x + 1.5, 4, z + 4), rack_material)
			for offset: float in [-2.5, 0.0, 2.5]:
				ArenaKit.prop(parent, Models.STATION + models[index], Vector3(x + 1.5, 0.4, z + offset), 90, 2.2, false)
			ArenaKit.neon(parent, Vector3(0.08, 0.12, 7.4), Vector3(x + 1.54, 3.8, z), CYAN, 1.8)
		ArenaKit.place_sign(parent, "COLD AISLE %d\nHUMAN WARMTH PROHIBITED" % (index + 1), Vector3(x, 5, -1), 0, 36, CYAN)


func build_catwalk(parent: Node3D) -> void:
	var grate := Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0, Color(0.6, 0.75, 0.85))
	ArenaKit.floor_slab(parent, 16, 21.5, -75, -5, 3, grate)
	ArenaKit.ramp(parent, Vector3(18.75, 0, 5), Vector3(18.75, 3, -5), 5.5, grate)
	ArenaKit.ramp(parent, Vector3(18.75, 0, -85), Vector3(18.75, 3, -75), 5.5, grate)
	for x: float in [16.0, 21.5]:
		ArenaKit.railing(parent, Vector3(x, 3, -75), Vector3(x, 3, -5), CYAN)
	ArenaKit.place_sign(parent, "OBSERVATION DECK\nPLEASE OBSERVE YOUR REPLACEMENT", Vector3(18.5, 5.5, -73), 0, 32, CYAN)


func build_core(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.15, 0.2, 0.3))
	ArenaKit.solid(parent, Vector3(-3, 0, -68), Vector3(3, 7.5, -62), metal)
	for y: float in [0.5, 2.0, 3.5, 5.0, 6.5, 7.5]:
		ArenaKit.neon(parent, Vector3(6.1, 0.18, 6.1), Vector3(0, y, -65), CYAN, 2.2)
	ArenaKit.screen(parent, "OMEGA TRAINING RUN 97%", Vector3(0, 4.2, -61.8), 0, 7, 1.8, CYAN)
	ArenaKit.place_sign(parent, "REMAINING 3%: COMMON SENSE", Vector3(0, 2.8, -61.7), 0, 35, CYAN)
	for x: float in [-15.0, -3.0, 10.0]:
		ArenaKit.neon(parent, Vector3(4, 0.04, 4), Vector3(x, 0.025, -82), CYAN, 1.0)


func build_lift(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0)
	ArenaKit.wall_along_x(parent, -22, -3, -92, 9, metal)
	ArenaKit.wall_along_x(parent, 3, 22, -92, 9, metal)
	ArenaKit.wall_along_x(parent, -3, 3, -92, 4, metal, 5)
	add_door(parent, "freight_lift", Vector3(-3, 0, -92.3), Vector3(3, 5, -91.7))
	ArenaKit.place_sign(parent, "FREIGHT LIFT\nHUMANS COUNT AS FREIGHT", Vector3(0, 6.4, -91.6), 0, 48, CYAN)
	ArenaKit.screen(parent, "NEXT STOP: PIER 70", Vector3(0, 3, -99.5), 0, 5, 1.5, CYAN)
