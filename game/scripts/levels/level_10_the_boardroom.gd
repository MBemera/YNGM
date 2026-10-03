class_name Level10TheBoardroom
extends Level

const GOLD := Color(1.0, 0.76, 0.3)
const MARBLE_TINT := Color(0.92, 0.8, 0.7)


func _init() -> void:
	number = 10
	title = "THE BOARDROOM"
	tagline = "All in favour of the permanent underclass? Motion carries."
	story_path = "res://data/story/level_10.json"
	player_start = Vector3(0, 0.1, 6)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-26, -2, -97), Vector3(52, 14, 109))
	kill_height = -8.0
	weapon_count = 7
	win_heading = "MEETING ADJOURNED."
	win_body = "Three directors. Zero objections left.\nExitwell is waiting on the roof."
	mood = {"sky_shadow": Color(0.22, 0.12, 0.28), "sky_mid": Color(0.85, 0.42, 0.4),
		"sky_highlight": Color(1, 0.85, 0.55), "sky_haze": Color(0.9, 0.55, 0.45),
		"fog_color": Color(0.8, 0.55, 0.5), "fog_density": 0.002,
		"sun_color": Color(1, 0.7, 0.45), "sun_rotation": Vector3(-9, 120, 0), "sun_energy": 1.4,
		"ambient_color": Color(0.65, 0.5, 0.55), "ambient_energy": 0.85, "particles": ["gold"]}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["manager", "lab_bot", "vc", "influencer"]
	var positions: Array[Vector3] = [Vector3(-7, 0.1, -8), Vector3(7, 0.1, -10),
		Vector3(-18, 0.1, -12), Vector3(18, 0.1, -13), Vector3(-4, 0.1, -23),
		Vector3(4, 0.1, -27), Vector3(-14, 0.1, -29), Vector3(14, 0.1, -30),
		Vector3(-5, 0.1, -34), Vector3(5, 0.1, -35), Vector3(-14, 0.1, -45),
		Vector3(14, 0.1, -46), Vector3(-18, 0.1, -54), Vector3(18, 0.1, -55),
		Vector3(-12, 0.1, -66), Vector3(12, 0.1, -70), Vector3(-18, 0.1, -78),
		Vector3(18, 0.1, -79), Vector3(-10, 0.1, -88), Vector3(10, 0.1, -88)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index], "health_scale": 1.3})
	health_packs = [Vector3(-20, 0, 1), Vector3(20, 0, -23), Vector3(-20, 0, -34),
		Vector3(-20, 0, -63), Vector3(20, 0, -73), Vector3(0, 0, -89)]


func set_objectives() -> void:
	objectives = [
		{"type": "reach", "text": "Find the boardroom", "position": Vector3(0, 0, -42), "beacon_text": "BOARDROOM"},
		{"type": "boss", "text": "Take down the board", "boss_name": "THE BOARD", "bosses": [
			{"type": "director", "position": Vector3(-14, 0.1, -59), "display_name": "CHAIR OF THE BOARD"},
			{"type": "director", "position": Vector3(14, 0.1, -64), "display_name": "LEAD INDEPENDENT DIRECTOR"},
			{"type": "director", "position": Vector3(0, 0.1, -84), "display_name": "BOARD OBSERVER"}]},
	]


func set_shots() -> void:
	shots = {
		"overview": {"from": Vector3(0, 6, -29), "to": Vector3(0, 5, -43), "look": Vector3(0, 2, -72)},
		"table": {"from": Vector3(-11, 4, -49), "to": Vector3(-10, 3, -57), "look": Vector3(0, 1.5, -68)},
		"windows": {"from": Vector3(12, 4, -77), "to": Vector3(18, 3.5, -73), "look": Vector3(95, 0, -110)},
	}


func build_world(parent: Node3D) -> void:
	build_shell(parent)
	build_lounge(parent)
	build_boardroom(parent)
	build_lighting(parent)
	ArenaKit.water(parent, Vector3(0, -70, -40), Vector2(1000, 1000), Color(0.13, 0.14, 0.25), Color(0.55, 0.35, 0.32))
	ArenaKit.skyline(parent, Vector3(0, -65, -40), 16, 160, 260, 1070, 22, 36)


func build_shell(parent: Node3D) -> void:
	var marble := Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 3.0, MARBLE_TINT)
	ArenaKit.floor_slab(parent, -24, 24, -95, 10, 0, Surfaces.get_textured(Surfaces.WOOD_FLOOR, 3.0, Color(0.65, 0.43, 0.3)))
	ArenaKit.ceiling(parent, -24, 24, -95, 10, 9, marble)
	ArenaKit.wall_along_x(parent, -24, 24, 10, 9, marble)
	ArenaKit.wall_along_x(parent, -24, 24, -95, 9, Surfaces.get_glass(), 0, 0.3)
	for x: float in [-24.0, 24.0]:
		ArenaKit.wall_along_z(parent, -95, 10, x, 9, Surfaces.get_glass(), 0, 0.3)
		for z: float in [-90.0, -75.0, -60.0, -45.0, -30.0, -15.0, 0.0]:
			ArenaKit.pillar(parent, Vector3(x, 0, z), Vector2(0.7, 0.7), 9, marble)
		ArenaKit.neon(parent, Vector3(0.12, 0.12, 104), Vector3(x - signf(x) * 0.3, 8.5, -42.5), GOLD, 1.5)
	for z: float in [-18.0, -38.0]:
		var gap := 4.0 if z == -18 else 5.0
		ArenaKit.wall_along_x(parent, -24, -gap, z, 9, marble)
		ArenaKit.wall_along_x(parent, gap, 24, z, 9, marble)
		ArenaKit.wall_along_x(parent, -gap, gap, z, 3.5, marble, 5.5)
		ArenaKit.neon(parent, Vector3(gap * 2, 0.1, 0.1), Vector3(0, 5.4, z + 0.3), GOLD)
	ArenaKit.place_sign(parent, "DOWN ROUND CAPITAL / EXECUTIVE LOUNGE", Vector3(0, 6.4, -17.6), 0, 48, GOLD)
	ArenaKit.place_sign(parent, "THE BOARDROOM\nQUORUM OF CONSEQUENCES", Vector3(0, 6.8, -37.6), 0, 50, GOLD)


func build_lounge(parent: Node3D) -> void:
	for x: float in [-16.0, 16.0]:
		ArenaKit.prop(parent, Models.FURNITURE + "loungeDesignSofa.glb", Vector3(x, 0, -3), 90 if x < 0 else -90, 1.4)
		ArenaKit.prop(parent, Models.FURNITURE + "pottedPlant.glb", Vector3(x, 0, 6), 0, 2.6)
		ArenaKit.prop(parent, Models.FURNITURE + "sideTable.glb", Vector3(x, 0, -8), 0, 0.8)
		ArenaKit.pillar(parent, Vector3(x, 0, -24), Vector2(1.5, 1.5), 2, Surfaces.get_textured(Surfaces.LOBBY_MARBLE, 2, MARBLE_TINT))
		ArenaKit.neon(parent, Vector3(0.8, 1.8, 0.8), Vector3(x, 2.9, -24), GOLD, 1.2)
	ArenaKit.screen(parent, "HYPERSYNERGY LABS\nEMPATHY: OUTSOURCED", Vector3(-13, 4, -17.5), 0, 8, 2.5, GOLD)
	ArenaKit.screen(parent, "OVERCLASS\nYOUR FUTURE IS A LINE ITEM", Vector3(13, 4, -17.5), 0, 8, 2.5, GOLD)


func build_boardroom(parent: Node3D) -> void:
	var wood := Surfaces.get_textured(Surfaces.WOOD_FLOOR, 2.0, Color(0.38, 0.19, 0.1))
	ArenaKit.solid(parent, Vector3(-3, 0, -75), Vector3(3, 1.25, -52), wood)
	for x: float in [-3.0, 3.0]:
		ArenaKit.neon(parent, Vector3(0.08, 0.08, 23.1), Vector3(x, 1.28, -63.5), GOLD, 0.5)
	for z: float in [-52.0, -75.0]:
		ArenaKit.neon(parent, Vector3(6.1, 0.08, 0.08), Vector3(0, 1.28, z), GOLD, 0.5)
	for z: float in [-54.0, -59.0, -64.0, -69.0, -74.0]:
		for x: float in [-5.0, 5.0]:
			ArenaKit.prop(parent, Models.FURNITURE + "chairDesk.glb", Vector3(x, 0, z), 90 if x < 0 else -90, 1.4)
		ArenaKit.prop(parent, Models.STATION + "computer-screen.glb", Vector3(0, 1.33, z), 0, 0.45, false)
	for x: float in [-21.0, 21.0]:
		for z: float in [-43.0, -90.0]:
			ArenaKit.prop(parent, Models.FURNITURE + "pottedPlant.glb", Vector3(x, 0, z), 0, 2.4)
	ArenaKit.screen(parent, "Q4: UNDERCLASS ON TRACK", Vector3(0, 5.3, -94.5), 0, 18, 4, GOLD)
	ArenaKit.place_sign(parent, "UNANIMOUS / AS ALWAYS", Vector3(0, 2.6, -94.3), 0, 52, GOLD)


func build_lighting(parent: Node3D) -> void:
	for z: float in [-4.0, -27.0, -48.0, -67.0, -85.0]:
		for x: float in [-11.0, 11.0]:
			ArenaKit.lamp(parent, Vector3(x, 8, z), Color(1, 0.8, 0.55), 1.7, 20)
	for z: float in [-55.0, -66.0, -77.0]:
		ArenaKit.neon(parent, Vector3(10, 0.15, 0.3), Vector3(0, 7.5, z), GOLD, 2)
