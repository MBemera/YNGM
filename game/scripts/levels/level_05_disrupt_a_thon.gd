class_name Level05DisruptAThon
extends Level

const PINK := Color(1.0, 0.2, 0.65)
const CYAN := Color(0.2, 0.85, 1.0)
const PURPLE := Color(0.6, 0.25, 1.0)
const STARTUPS: Array[String] = ["WRAPPERWRAPPER", "PROMPTSLURRY", "AGI-ISH", "HALLUCINATR", "DEMO DAY DESPAIR", "YET ANOTHER WRAPPER"]


func _init() -> void:
	number = 5
	title = "DISRUPT-A-THON"
	tagline = "Six brands. One API call. No exits."
	story_path = "res://data/story/level_05.json"
	player_start = Vector3(0, 0.1, 0)
	player_yaw_degrees = 0.0
	navigation_bounds = AABB(Vector3(-32, -2, -82), Vector3(64, 17, 94))
	kill_height = -6.0
	weapon_count = 6
	win_heading = "YOU WON TRANSPORT."
	win_body = "First prize was a bubble. Second prize was exposure.\nYou took the shuttle. It has actual seats."
	mood = {"sky_shadow": Color(0.05, 0.01, 0.1), "sky_mid": Color(0.2, 0.05, 0.3),
		"fog_color": Color(0.28, 0.12, 0.35), "fog_density": 0.004, "sun_energy": 0.05,
		"ambient_color": Color(0.62, 0.45, 0.72), "ambient_energy": 1.25,
		"glow_intensity": 0.9, "particles": ["data"], "sun_shadows": false}
	set_encounters()
	set_objectives()
	set_shots()


func set_encounters() -> void:
	var types: Array[String] = ["founder", "founder", "influencer", "founder", "vc", "manager", "founder"]
	var positions: Array[Vector3] = [Vector3(-5, 0.1, -15), Vector3(5, 0.1, -17),
		Vector3(-16, 0.1, -23), Vector3(16, 0.1, -25), Vector3(0, 0.1, -28),
		Vector3(-5, 0.1, -32), Vector3(5, 0.1, -34), Vector3(-16, 0.1, -39),
		Vector3(16, 0.1, -41), Vector3(0, 0.1, -45), Vector3(-5, 0.1, -51),
		Vector3(5, 0.1, -53), Vector3(-22, 5.1, -30), Vector3(22, 5.1, -39)]
	for index: int in positions.size():
		enemies.append({"type": types[index % types.size()], "position": positions[index]})
	health_packs = [Vector3(-12, 0, -5), Vector3(12, 0, -27), Vector3(-12, 0, -43),
		Vector3(-22, 5, -24), Vector3(22, 5, -44), Vector3(10, 0, -56)]


func set_objectives() -> void:
	var waves: Array[Dictionary] = []
	var types: Array[String] = ["founder", "influencer", "vc", "manager"]
	for index: int in 4:
		var wave_enemies: Array[Dictionary] = []
		var z := -22.0 if index % 2 == 0 else -40.0
		for enemy_index: int in 4:
			var x := -27.5 if enemy_index < 2 else 27.5
			wave_enemies.append({"type": types[(index + enemy_index) % types.size()],
				"position": Vector3(x, 0.1, z - 1.5 + 3.0 * (enemy_index % 2))})
		waves.append({"at": index * 0.25, "enemies": wave_enemies})
	objectives = [
		{"type": "survive", "text": "Survive until Dana cracks the doors", "seconds": 60.0,
			"countdown_label": "DOORS OPEN IN", "opens": "shuttle_doors", "waves": waves},
		{"type": "reach", "text": "Get on the Overclass campus shuttle",
			"position": Vector3(0, 0.6, -74), "beacon_text": "SHUTTLE"},
	]


func set_shots() -> void:
	shots = {
		"overview": {"from": Vector3(0, 10, -1), "to": Vector3(3, 9, -10), "look": Vector3(0, 2, -36)},
		"stage": {"from": Vector3(7, 5, -12), "to": Vector3(4, 4, -8), "look": Vector3(0, 5, 8)},
		"shuttle": {"from": Vector3(-10, 5, -63), "to": Vector3(-7, 4, -65), "look": Vector3(0, 2, -73)},
	}


func build_world(parent: Node3D) -> void:
	build_shell(parent)
	build_stage(parent)
	build_booths(parent)
	for side: float in [-1.0, 1.0]:
		build_balcony(parent, side)
		build_side_entrances(parent, side)
	build_back_hall(parent)
	build_shuttle(parent)
	build_lighting(parent)


func build_shell(parent: Node3D) -> void:
	var wall := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.3, 0.27, 0.4))
	ArenaKit.floor_slab(parent, -25, 25, -80, 10, 0, Surfaces.get_textured(Surfaces.HANGAR_CONCRETE, 4.0))
	for z: float in [-80.0, 10.0]:
		ArenaKit.wall_along_x(parent, -25, 25, z, 12, wall)
	ArenaKit.ceiling(parent, -25, 25, -80, 10, 12, wall)
	for x: float in [-24.5, 24.5]:
		ArenaKit.neon(parent, Vector3(0.15, 0.2, 68), Vector3(x, 9, -25), PINK)
	ArenaKit.place_sign(parent, "PIVOT UNTIL SOMETHING SOUNDS LEGAL", Vector3(0, 8, -59.5), 0, 75, PINK)


func build_stage(parent: Node3D) -> void:
	var metal := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.22, 0.18, 0.3))
	ArenaKit.floor_slab(parent, -12, 12, 4, 9.5, 1, metal)
	ArenaKit.ramp(parent, Vector3(0, 0, 1), Vector3(0, 1, 4), 6, metal)
	ArenaKit.railing(parent, Vector3(-12, 1, 4), Vector3(-3, 1, 4), PINK)
	ArenaKit.railing(parent, Vector3(3, 1, 4), Vector3(12, 1, 4), PINK)
	for x: float in [-12.0, 12.0]:
		ArenaKit.railing(parent, Vector3(x, 1, 4), Vector3(x, 1, 9.5), PINK)
	ArenaKit.railing(parent, Vector3(-12, 1, 9.5), Vector3(12, 1, 9.5), PINK)
	ArenaKit.screen(parent, "DISRUPT-A-THON\nTHEME: THE SAME APP", Vector3(0, 6.6, 9.4), 180, 20, 4.5, CYAN)
	ArenaKit.pillar(parent, Vector3(6, 1, 6), Vector2(1.8, 1.8), 1.2, LevelBuilder.get_material(Color(0.95, 0.7, 0.2)))
	ArenaKit.place_sign(parent, "FIRST PRIZE\nVALUATION BUBBLE GUN [6]", Vector3(6, 2.8, 4.9), 180, 32, PINK)
	ArenaKit.prop(parent, Models.BLASTERS + "blaster-f.glb", Vector3(6, 2.2, 6), 90, 0.6, false)


func build_booths(parent: Node3D) -> void:
	for row: int in 3:
		for side: int in 2:
			var x := -10.0 if side == 0 else 10.0
			var z := -16.0 - row * 16.0
			var index := row * 2 + side
			ArenaKit.screen(parent, STARTUPS[index], Vector3(x, 3.8, z - 2), 0, 7, 1.4, CYAN if side == 0 else PINK)
			for offset: float in [-2.0, 2.0]:
				build_workstation(parent, Vector3(x + offset, 0, z))
			ArenaKit.crate(parent, Vector3(x + 3, 0, z - 5), 15, 1.1, index)
			ArenaKit.prop(parent, Models.FURNITURE + "benchCushionLow.glb", Vector3(x - 3, 0, z - 5), 0, 0.7)


func build_workstation(parent: Node3D, position: Vector3) -> void:
	ArenaKit.prop(parent, Models.FURNITURE + "table.glb", position, 0, 0.85)
	ArenaKit.prop(parent, Models.FURNITURE + "laptop.glb", position + Vector3(0, 0.85, 0), 0, 0.4, false)
	ArenaKit.prop(parent, Models.FURNITURE + "chairDesk.glb", position + Vector3(0, 0, 1.3), 180, 1.0)


func build_balcony(parent: Node3D, side: float) -> void:
	var metal := Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0, Color(0.6, 0.45, 0.75))
	var x := 22.0 * side
	ArenaKit.floor_slab(parent, x - 2.5, x + 2.5, -47, -15, 5, metal)
	ArenaKit.ramp(parent, Vector3(x, 0, -3), Vector3(x, 5, -15), 5, metal)
	ArenaKit.ramp(parent, Vector3(x, 0, -59), Vector3(x, 5, -47), 5, metal)
	for edge_x: float in [x - 2.5, x + 2.5]:
		ArenaKit.railing(parent, Vector3(edge_x, 5, -47), Vector3(edge_x, 5, -15), CYAN)
	ArenaKit.place_sign(parent, "MENTOR BALCONY\nADVICE HAS NO WARRANTY", Vector3(x, 7, -46), 0, 30, CYAN)


func build_side_entrances(parent: Node3D, side: float) -> void:
	var wall := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.3, 0.27, 0.4))
	var x := 25.0 * side
	for segment: Vector2 in [Vector2(-80, -44), Vector2(-36, -26), Vector2(-18, 10)]:
		ArenaKit.wall_along_z(parent, segment.x, segment.y, x, 12, wall)
	for z: float in [-22.0, -40.0]:
		ArenaKit.wall_along_z(parent, z - 4, z + 4, x, 8.5, wall, 3.5)
		ArenaKit.floor_slab(parent, minf(x, 30 * side), maxf(x, 30 * side), z - 4, z + 4, 0, wall)
		ArenaKit.wall_along_z(parent, z - 4, z + 4, 30 * side, 4, wall)
		for edge_z: float in [z - 4, z + 4]:
			ArenaKit.wall_along_x(parent, minf(x, 30 * side), maxf(x, 30 * side), edge_z, 4, wall)
		ArenaKit.ceiling(parent, minf(x, 30 * side), maxf(x, 30 * side), z - 4, z + 4, 3.5, wall)
		ArenaKit.place_sign(parent, "PITCH INTAKE", Vector3(x - 0.3 * side, 2.7, z), -90 * side, 32, PINK)


func build_back_hall(parent: Node3D) -> void:
	var wall := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.35, 0.4, 0.5))
	ArenaKit.wall_along_x(parent, -25, -4, -60, 12, wall)
	ArenaKit.wall_along_x(parent, 4, 25, -60, 12, wall)
	ArenaKit.wall_along_x(parent, -4, 4, -60, 7, wall, 5)
	add_door(parent, "shuttle_doors", Vector3(-4, 0, -60.3), Vector3(4, 5, -59.7))
	ArenaKit.place_sign(parent, "OVERCLASS CAMPUS SHUTTLE", Vector3(0, 6, -59.5), 0, 55, CYAN)
	ArenaKit.screen(parent, "ONE WAY\nRETURN TRIPS ARE NOT ON THE ROADMAP", Vector3(12, 3, -79.6), 0, 12, 2.2, CYAN)


func build_shuttle(parent: Node3D) -> void:
	var body := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.7, 0.85, 0.95))
	ArenaKit.solid(parent, Vector3(-3, 0, -78), Vector3(3, 0.6, -68), body)
	ArenaKit.ramp(parent, Vector3(0, 0, -65), Vector3(0, 0.6, -68), 4, body)
	for x: float in [-3.0, 3.0]:
		ArenaKit.wall_along_z(parent, -78, -68, x, 3.6, body, 0.6)
		ArenaKit.solid(parent, Vector3(x - 0.27, 1.8, -77.5), Vector3(x + 0.27, 3.4, -69), Surfaces.get_window_glass())
		ArenaKit.neon(parent, Vector3(0.1, 0.2, 9), Vector3(x + 0.3 * signf(x), 1.2, -73), CYAN)
	ArenaKit.wall_along_x(parent, -3, 3, -78, 3.6, body, 0.6)
	ArenaKit.ceiling(parent, -3.3, 3.3, -78, -68, 4.3, body)
	ArenaKit.place_sign(parent, "OVERCLASS", Vector3(0, 4, -67.9), 0, 48, CYAN)
	for x: float in [-2.0, 2.0]:
		ArenaKit.prop(parent, Models.FURNITURE + "benchCushion.glb", Vector3(x, 0.6, -76), 90, 0.8)
		for z: float in [-70.0, -76.0]:
			ArenaKit.pillar(parent, Vector3(x * 1.65, 0, z), Vector2(0.5, 1.2), 1, LevelBuilder.get_material(Color(0.04, 0.04, 0.05)))


func build_lighting(parent: Node3D) -> void:
	for z: float in [-8.0, -28.0, -48.0]:
		for x: float in [-12.0, 12.0]:
			ArenaKit.lamp(parent, Vector3(x, 10, z), PINK if x < 0 else CYAN, 4.0, 26)
		ArenaKit.neon(parent, Vector3(38, 0.2, 0.2), Vector3(0, 11, z), PURPLE)
	ArenaKit.lamp(parent, Vector3(-7, 8, 5), PURPLE, 3, 15)
	ArenaKit.lamp(parent, Vector3(7, 8, 5), PINK, 3, 15)
	ArenaKit.lamp(parent, Vector3(0, 8, -69), CYAN, 2.5, 18)
