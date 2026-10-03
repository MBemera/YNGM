class_name Level06OverclassCampus
extends Level

const CYAN := Color(0.2, 0.8, 1.0)
const AMBER := Color(1.0, 0.6, 0.2)
const RELAYS: Array[Vector3] = [Vector3(-17, 0, -15), Vector3(17, 0, -15), Vector3(-17, 0, -51), Vector3(17, 0, -51)]


func _init() -> void:
	number = 6
	title = "OVERCLASS CAMPUS"
	tagline = "Bring your whole self to work. Leave it here."
	story_path = "res://data/story/level_06.json"
	player_start = Vector3(0, 0.1, 6)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-32, -2, -84), Vector3(64, 24, 96))
	kill_height = -6.0
	weapon_count = 6
	hologram_position = Vector3(0, 0, -15)
	win_heading = "CAMPUS CULTURE: OFFLINE."
	win_body = "Four relays down. One valuation in free fall.\nThe headquarters finally has an open-door policy."
	mood = {"sky_shadow": Color(0.12, 0.04, 0.23), "sky_mid": Color(0.45, 0.2, 0.42),
		"sky_highlight": Color(1.0, 0.5, 0.23), "sky_haze": Color(0.5, 0.3, 0.45),
		"sun_color": AMBER, "sun_rotation": Vector3(-9, 140, 0), "sun_energy": 0.85,
		"fog_color": Color(0.4, 0.3, 0.52), "fog_density": 0.004,
		"ambient_color": Color(0.48, 0.4, 0.68), "ambient_energy": 0.85, "particles": ["embers"]}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["founder", "lab_bot", "vc", "founder", "influencer", "manager", "delivery_bot"]
	var positions: Array[Vector3] = [Vector3(-7, 0.1, -9), Vector3(7, 0.1, -11),
		Vector3(-21, 0.1, -19), Vector3(21, 0.1, -19), Vector3(-9, 0.1, -24),
		Vector3(9, 0.1, -24), Vector3(0, 0.1, -29), Vector3(-16, 0.1, -31),
		Vector3(16, 0.1, -33), Vector3(-8, 0.1, -40), Vector3(8, 0.1, -42),
		Vector3(-22, 0.1, -46), Vector3(22, 0.1, -46), Vector3(-9, 0.1, -54),
		Vector3(9, 0.1, -56), Vector3(-18, 0.1, -61), Vector3(18, 0.1, -61), Vector3(0, 0.1, -65)]
	for index: int in positions.size():
		var spawn := {"type": types[index % types.size()], "position": positions[index]}
		if spawn["type"] == "founder":
			spawn["display_name"] = "BITTER ACQUI-HIRE"
		enemies.append(spawn)
	health_packs = [Vector3(-10, 0, 1), Vector3(10, 0, -19), Vector3(-20, 0, -27),
		Vector3(20, 0, -38), Vector3(-10, 0, -59), Vector3(10, 0, -65)]


func set_objectives() -> void:
	var targets: Array[Dictionary] = []
	for position: Vector3 in RELAYS:
		targets.append({"name": "POWER RELAY", "model": Models.STATION + "container-tall.glb",
			"height": 3.0, "health": 450, "color": AMBER, "position": position})
	objectives = [
		{"type": "destroy", "text": "Knock out OMEGA's power relays", "opens": "hq_entrance", "targets": targets},
		{"type": "reach", "text": "Get inside Overclass HQ", "position": Vector3(0, 0, -77), "beacon_text": "OVERCLASS HQ"},
	]


func set_shots() -> void:
	shots = {
		"hologram": {"from": Vector3(2, 4.5, 7), "to": Vector3(0, 5, 3), "look": Vector3(0, 4.3, -15)},
		"overview": {"from": Vector3(-9, 17, 5), "to": Vector3(-5, 15, -5), "look": Vector3(0, 2, -38)},
		"relays": {"from": Vector3(0, 16, -27), "to": Vector3(2, 14, -32), "look": Vector3(0, 1.5, -51)},
	}


func build_world(parent: Node3D) -> void:
	build_quad(parent)
	build_offices(parent)
	build_logo(parent)
	build_kombucha_bar(parent)
	build_nap_pods(parent)
	build_relay_markings(parent)
	build_headquarters(parent)
	build_lighting(parent)
	ArenaKit.skyline(parent, Vector3(0, -4, -32), 24, 100, 155, 606, 16, 24)
	for x: float in [-60.0, 60.0]:
		Models.spawn(parent, Models.CITY + "building-skyscraper-a.glb", Vector3(x, 0, -95), 0, 20)


func build_quad(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.SIDEWALK_CONCRETE, 3.0, Color(0.7, 0.73, 0.82))
	ArenaKit.floor_slab(parent, -30, 30, -82, 10, 0, concrete)
	for x: float in [-11.0, 11.0]:
		for z: float in [-13.0, -49.0]:
			LevelBuilder.add_decor(parent, Vector3(10, 0.02, 20), Vector3(x, 0.012, z), Color(0.22, 0.36, 0.25))
	for x: float in [-30.0, 30.0]:
		ArenaKit.wall_along_z(parent, -82, 10, x, 8, concrete)
	for z: float in [-82.0, 10.0]:
		ArenaKit.wall_along_x(parent, -30, 30, z, 8, concrete)
	ArenaKit.place_sign(parent, "OVERCLASS CAMPUS\nVISITORS MUST SIGN AWAY", Vector3(0, 4, 9.6), 180, 58, CYAN)
	for x: float in [-8.0, 8.0]:
		ArenaKit.prop(parent, Models.FURNITURE + "bench.glb", Vector3(x, 0, -32), 0, 1.0)
	ArenaKit.pillar(parent, Vector3(-7, 0, -63), Vector2(2.8, 0.8), 1.4, Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 2.0))
	ArenaKit.place_sign(parent, "ALIGNMENT (DEPRECATED)", Vector3(-7, 1.1, -62.55), 0, 23, AMBER)


func build_offices(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.LAB_CONCRETE, 3.0, Color(0.45, 0.45, 0.6))
	for side: float in [-1.0, 1.0]:
		var x := 27.0 * side
		for z: float in [-14.0, -49.0]:
			ArenaKit.solid(parent, Vector3(x - 3, 0, z - 12), Vector3(x + 3, 12, z + 12), concrete)
			for y: float in [2.0, 6.0, 10.0]:
				ArenaKit.solid(parent, Vector3(x - 3.06, y - 1, z - 11), Vector3(x + 3.06, y + 1, z + 11), Surfaces.get_window_glass())
			ArenaKit.neon(parent, Vector3(0.12, 0.18, 24), Vector3(x - side * 3.15, 11.7, z), CYAN)
			ArenaKit.place_sign(parent, "OVERCLASS\nHUMAN RESOURCES: FINITE", Vector3(x - side * 3.2, 4.5, z), -90 * side, 40, CYAN)


func build_logo(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.4, 0.65, 0.8))
	ArenaKit.pillar(parent, Vector3(0, 0, -44), Vector2(4, 3), 0.5, metal)
	ArenaKit.solid(parent, Vector3(-1.5, 0.5, -44.5), Vector3(-0.5, 9, -43.5), metal)
	ArenaKit.solid(parent, Vector3(-0.5, 8, -44.5), Vector3(3, 9, -43.5), metal)
	ArenaKit.solid(parent, Vector3(-0.5, 4.5, -44.5), Vector3(2, 5.5, -43.5), metal)
	ArenaKit.neon(parent, Vector3(0.12, 8.5, 0.1), Vector3(-1.55, 4.75, -43.4), CYAN)
	ArenaKit.neon(parent, Vector3(4.5, 0.12, 0.1), Vector3(0.75, 9, -43.4), CYAN)
	ArenaKit.place_sign(parent, "THE FUTURE IS PROPRIETARY", Vector3(0, 1.5, -42.3), 0, 30, CYAN)


func build_kombucha_bar(parent: Node3D) -> void:
	var wood := Surfaces.get_textured(Surfaces.WOOD_FLOOR, 2.0, Color(0.8, 0.6, 0.5))
	ArenaKit.solid(parent, Vector3(-23, 0, -39), Vector3(-19, 1.1, -33), wood)
	for z: float in [-38.5, -33.5]:
		ArenaKit.pillar(parent, Vector3(-22.5, 0, z), Vector2(0.3, 0.3), 3.6, wood)
	ArenaKit.ceiling(parent, -23.5, -18.5, -39.5, -32.5, 3.6, wood)
	ArenaKit.place_sign(parent, "KOMBUCHA BAR\nCULTURES WE HAVEN'T FIRED", Vector3(-18.4, 2.6, -36), 90, 32, AMBER)
	for z: float in [-37.5, -35.0]:
		ArenaKit.pillar(parent, Vector3(-20, 1.1, z), Vector2(0.45, 0.45), 0.8, LevelBuilder.get_material(AMBER))


func build_nap_pods(parent: Node3D) -> void:
	var shell := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.55, 0.45, 0.7))
	for z: float in [-28.0, -34.0]:
		ArenaKit.solid(parent, Vector3(19, 0, z - 1.6), Vector3(22.5, 0.5, z + 1.6), shell)
		ArenaKit.wall_along_z(parent, z - 1.6, z + 1.6, 22.5, 2.5, shell)
		for end_z: float in [z - 1.6, z + 1.6]:
			ArenaKit.wall_along_x(parent, 19, 22.5, end_z, 2.5, shell)
		ArenaKit.ceiling(parent, 19, 22.5, z - 1.6, z + 1.6, 2.5, shell)
		ArenaKit.prop(parent, Models.FURNITURE + "benchCushionLow.glb", Vector3(20.5, 0.5, z), 90, 0.6, false)
		ArenaKit.neon(parent, Vector3(0.1, 0.12, 3.2), Vector3(18.9, 2.5, z), CYAN)
	ArenaKit.place_sign(parent, "NAP PODS\nDREAMS SUBJECT TO IP ASSIGNMENT", Vector3(18.8, 3.4, -31), -90, 32, CYAN)


func build_relay_markings(parent: Node3D) -> void:
	for index: int in RELAYS.size():
		var position := RELAYS[index]
		ArenaKit.neon(parent, Vector3(4.4, 0.02, 4.4), position + Vector3(0, 0.04, 0), AMBER, 0.7)
		ArenaKit.place_sign(parent, "POWER RELAY %02d\nLOAD: ONE MAN'S NET WORTH" % (index + 1), position + Vector3(0, 4, -1), 0, 28, AMBER)


func build_headquarters(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 3.0, Color(0.6, 0.65, 0.8))
	ArenaKit.wall_along_x(parent, -30, -4, -70, 16, concrete)
	ArenaKit.wall_along_x(parent, 4, 30, -70, 16, concrete)
	ArenaKit.wall_along_x(parent, -4, 4, -70, 11, concrete, 5)
	add_door(parent, "hq_entrance", Vector3(-4, 0, -70.3), Vector3(4, 5, -69.7))
	for x: float in [-24.0, -16.0, -8.0, 8.0, 16.0, 24.0]:
		ArenaKit.solid(parent, Vector3(x - 2.5, 2, -69.7), Vector3(x + 2.5, 10, -69.6), Surfaces.get_window_glass())
	ArenaKit.neon(parent, Vector3(58, 0.2, 0.12), Vector3(0, 15.5, -69.6), CYAN)
	ArenaKit.place_sign(parent, "OVERCLASS", Vector3(0, 12.5, -69.5), 0, 160, CYAN)
	ArenaKit.place_sign(parent, "MAIN HQ", Vector3(0, 6.2, -69.5), 0, 60, AMBER)
	ArenaKit.ceiling(parent, -30, 30, -82, -70, 7, concrete)
	ArenaKit.screen(parent, "OMEGA\nTRAINING THE PERMANENT REPLACEMENT", Vector3(0, 3.5, -81.6), 0, 12, 2.2, CYAN)


func build_lighting(parent: Node3D) -> void:
	for x: float in [-21.0, 21.0]:
		for z: float in [-4.0, -57.0]:
			ArenaKit.pillar(parent, Vector3(x, 0, z), Vector2(0.3, 0.3), 5.5, LevelBuilder.get_material(Color(0.2, 0.22, 0.3)))
			ArenaKit.lamp(parent, Vector3(x, 5.5, z), CYAN, 2, 16)
	ArenaKit.lamp(parent, Vector3(-20, 3.2, -36), AMBER, 1.5, 10, false)
	ArenaKit.lamp(parent, Vector3(0, 6, -77), CYAN, 2, 14)
