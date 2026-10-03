class_name Level11Omega
extends Level

const GOLD := Color(1.0, 0.74, 0.3)
const RED := Color(1.0, 0.12, 0.16)


func _init() -> void:
	number = 11
	title = "OMEGA"
	tagline = "One founder. One objective. Everybody gets a ladder."
	story_path = "res://data/story/level_11.json"
	player_start = Vector3(0, 0.1, 12)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-27, -2, -62), Vector3(54, 20, 80))
	kill_height = -10.0
	weapon_count = 7
	win_heading = "WE ALL MADE IT."
	win_body = "New objective: nobody gets left behind.\nEven you, Preston. Grab a ladder."
	mood = {"sky_shadow": Color(0.28, 0.13, 0.3), "sky_mid": Color(0.9, 0.5, 0.48),
		"sky_highlight": Color(1, 0.9, 0.62), "sky_haze": Color(0.95, 0.64, 0.5),
		"fog_color": Color(0.8, 0.55, 0.5), "fog_density": 0.003,
		"sun_color": Color(1, 0.76, 0.5), "sun_rotation": Vector3(-7, 150, 0), "sun_energy": 1.7,
		"ambient_color": Color(0.65, 0.5, 0.6), "ambient_energy": 0.8, "particles": ["gold"]}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["lab_bot", "delivery_bot", "manager"]
	var positions: Array[Vector3] = [Vector3(-4, 0.1, -4), Vector3(4, 0.1, -6),
		Vector3(-14, 0.1, -14), Vector3(14, 0.1, -14), Vector3(-21, 3.1, -33),
		Vector3(21, 3.1, -33), Vector3(-21, 0.1, -53), Vector3(21, 0.1, -53),
		Vector3(-13, 0.1, -56), Vector3(13, 0.1, -56)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index], "health_scale": 1.4})
	health_packs = [Vector3(-20, 0, -15), Vector3(20, 0, -15), Vector3(-21, 3, -40),
		Vector3(21, 3, -40), Vector3(-10, 0, -55), Vector3(10, 0, -55), Vector3(0, 0, 1)]


func set_objectives() -> void:
	objectives = [
		{"type": "reach", "text": "Get to the launch pad", "position": Vector3(0, 0, -13), "beacon_text": "LAUNCH PAD"},
		{"type": "boss", "text": "Defeat Preston Exitwell", "boss_name": "PRESTON EXITWELL - EXOSUIT",
			"bosses": [{"type": "exosuit", "position": Vector3(0, 0.1, -35)}]},
	]


func set_shots() -> void:
	shots = {
		"overview": {"from": Vector3(-23, 18, 0), "to": Vector3(-18, 14, -9), "look": Vector3(0, 2, -35)},
		"exosuit": {"from": Vector3(-7, 3, -18), "to": Vector3(-4, 2.5, -23), "look": Vector3(0, 3.4, -35)},
		"omega": {"from": Vector3(10, 8, -40), "to": Vector3(6, 6, -45), "look": Vector3(0, 6, -56)},
		"ending_wide": {"from": Vector3(22, 20, -7), "to": Vector3(16, 24, -12), "look": Vector3(0, 1, -35)},
		"ending_close": {"from": Vector3(-7, 6, -46), "to": Vector3(-3, 5, -49), "look": Vector3(0, 5.5, -56)},
		"ending_sunrise": {"from": Vector3(-18, 11, -53), "to": Vector3(-18, 16, -59), "look": Vector3(-180, 18, -330)},
	}


func build_world(parent: Node3D) -> void:
	build_deck(parent)
	build_approach(parent)
	build_cover(parent)
	build_platforms(parent)
	build_monolith(parent)
	build_rocket(parent)
	ArenaKit.water(parent, Vector3(0, -90, -35), Vector2(1200, 1200), Color(0.13, 0.13, 0.23), Color(0.6, 0.35, 0.3))
	ArenaKit.skyline(parent, Vector3(0, -80, -35), 12, 220, 350, 1170, 20, 36)


func build_deck(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.HANGAR_CONCRETE, 3.0, Color(0.65, 0.6, 0.6))
	ArenaKit.floor_slab(parent, -25, 25, -60, -10, 0, concrete)
	ArenaKit.floor_slab(parent, -7, 7, -10, 16, 0, concrete)
	guard_edge(parent, Vector3(-25, 0, -60), Vector3(25, 0, -60))
	for x: float in [-25.0, 25.0]:
		guard_edge(parent, Vector3(x, 0, -60), Vector3(x, 0, -10))
	guard_edge(parent, Vector3(-25, 0, -10), Vector3(-7, 0, -10))
	guard_edge(parent, Vector3(7, 0, -10), Vector3(25, 0, -10))
	for x: float in [-7.0, 7.0]:
		guard_edge(parent, Vector3(x, 0, -10), Vector3(x, 0, 16))
	guard_edge(parent, Vector3(-7, 0, 16), Vector3(7, 0, 16))
	for x: float in [-12.0, 12.0]:
		ArenaKit.neon(parent, Vector3(0.15, 0.04, 24), Vector3(x, 0.025, -35), GOLD, 1.0)
	for z: float in [-23.0, -47.0]:
		ArenaKit.neon(parent, Vector3(24, 0.04, 0.15), Vector3(0, 0.025, z), GOLD, 1.0)


func guard_edge(parent: Node3D, from: Vector3, to: Vector3) -> void:
	ArenaKit.railing(parent, from, to, GOLD)
	ArenaKit.invisible_wall(parent, from.min(to) - Vector3(0.08, 0, 0.08), from.max(to) + Vector3(0.08, 9, 0.08))


func build_approach(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.3, 0.3, 0.4))
	for x: float in [-7.0, 7.0]:
		ArenaKit.wall_along_z(parent, 5, 16, x, 6, metal)
	ArenaKit.wall_along_x(parent, -7, 7, 16, 6, metal)
	ArenaKit.ceiling(parent, -7, 7, 5, 16, 6, metal)
	ArenaKit.screen(parent, "ROOFTOP / FINAL ESCALATION", Vector3(0, 3.5, 15.6), 180, 8, 1.5, GOLD)
	ArenaKit.place_sign(parent, "LAUNCH PAD\nFOUNDER PARKING ONLY", Vector3(0, 6, -10), 0, 56, GOLD)
	ArenaKit.lamp(parent, Vector3(0, 5, 9), GOLD, 2, 15)
	for x: float in [-6.0, 6.0]:
		ArenaKit.neon(parent, Vector3(0.1, 0.1, 23), Vector3(x, 0.15, 2), GOLD)


func build_cover(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.35, 0.32, 0.4))
	for x: float in [-14.0, 14.0]:
		ArenaKit.pillar(parent, Vector3(x, 0, -35), Vector2(2, 2), 5, metal)
		ArenaKit.neon(parent, Vector3(2.1, 0.15, 2.1), Vector3(x, 4.8, -35), GOLD)
		for z: float in [-20.0, -50.0]:
			ArenaKit.solid(parent, Vector3(x - 1, 0, z - 0.6), Vector3(x + 1, 1.2, z + 0.6), metal)
	for point: Vector3 in [Vector3(-23, 0, -57), Vector3(23, 0, -57)]:
		ArenaKit.crate(parent, point, 0, 1.3, 1)


func build_platforms(parent: Node3D) -> void:
	var grate := Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0, Color(0.8, 0.65, 0.55))
	for x: float in [-21.0, 21.0]:
		ArenaKit.floor_slab(parent, x - 3, x + 3, -46, -28, 3, grate)
		ArenaKit.ramp(parent, Vector3(x, 0, -18), Vector3(x, 3, -28), 6, grate)
		ArenaKit.railing(parent, Vector3(x - 3, 3, -46), Vector3(x + 3, 3, -46), GOLD)
		for edge: float in [x - 3, x + 3]:
			ArenaKit.railing(parent, Vector3(edge, 3, -46), Vector3(edge, 3, -28), GOLD)
		ArenaKit.lamp(parent, Vector3(x, 7, -40), GOLD, 2, 16)


func build_monolith(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.08, 0.08, 0.12))
	ArenaKit.solid(parent, Vector3(-3, 0, -58), Vector3(3, 12, -54), metal)
	for x: float in [-3.05, 3.05]:
		ArenaKit.neon(parent, Vector3(0.18, 12, 4.15), Vector3(x, 6, -56), RED, 3)
	for y: float in [0.3, 11.8]:
		ArenaKit.neon(parent, Vector3(6.2, 0.2, 4.2), Vector3(0, y, -56), RED, 3)
	ArenaKit.flickering_sign(parent, "OMEGA", Vector3(0, 7, -53.8), 0, 130, RED)
	ArenaKit.screen(parent, "OBJECTIVE: PROTECT THE FOUNDER", Vector3(0, 3.5, -53.7), 0, 8, 1.5, RED)
	ArenaKit.lamp(parent, Vector3(0, 10, -52), RED, 2.5, 18, false)


func build_rocket(parent: Node3D) -> void:
	var material := Surfaces.get_textured(Surfaces.BLUE_METAL, 4.0, Color(0.85, 0.8, 0.75))
	add_rocket_section(parent, Vector3(46, 4, -79), 40, 4, 4, material)
	add_rocket_section(parent, Vector3(46, 28, -79), 8, 4, 0, material)
	for x: float in [39.0, 53.0]:
		LevelBuilder.add_decor(parent, Vector3(1, 50, 1), Vector3(x, 4, -85), Color(0.7, 0.35, 0.1))
	for y: float in [-12.0, 0.0, 12.0, 24.0]:
		LevelBuilder.add_decor(parent, Vector3(15, 0.7, 2), Vector3(46, y, -85), GOLD)
	ArenaKit.place_sign(parent, "THE ARK", Vector3(46, 16, -74.8), 0, 90, GOLD)


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
