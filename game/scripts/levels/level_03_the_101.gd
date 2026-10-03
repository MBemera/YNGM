class_name Level03The101
extends Level

const HALF_WIDTH := 14.0
const START_Z := 8.0
const DECK_END_Z := -140.0
const PLATFORM_END_Z := -162.0
const PLATFORM_Y := 6.0
const TOLL_Z := -82.0
const BARRIER_HEIGHT := 1.1
const SODIUM := Color(1.0, 0.62, 0.28)
const CARS: Array[Dictionary] = [
	{"model": "sedan", "position": Vector3(-10.5, 0, -14), "yaw": 4.0},
	{"model": "suv", "position": Vector3(-5.5, 0, -18), "yaw": -6.0},
	{"model": "taxi", "position": Vector3(10.5, 0, -12), "yaw": 0.0},
	{"model": "van", "position": Vector3(5.5, 0, -26), "yaw": 25.0},
	{"model": "delivery", "position": Vector3(-6.5, 0, -32), "yaw": 70.0},
	{"model": "hatchback-sports", "position": Vector3(10.5, 0, -38), "yaw": -10.0},
	{"model": "suv-luxury", "position": Vector3(-10.5, 0, -44), "yaw": 0.0},
	{"model": "sedan-sports", "position": Vector3(5.5, 0, -50), "yaw": 8.0},
	{"model": "truck", "position": Vector3(-5.5, 0, -58), "yaw": -4.0},
	{"model": "police", "position": Vector3(10.5, 0, -62), "yaw": 35.0},
	{"model": "sedan", "position": Vector3(-10.5, 0, -68), "yaw": -20.0},
	{"model": "taxi", "position": Vector3(4.5, 0, -72), "yaw": 0.0},
	{"model": "ambulance", "position": Vector3(-10.5, 0, -100), "yaw": 0.0},
	{"model": "suv", "position": Vector3(5.5, 0, -104), "yaw": -15.0},
	{"model": "firetruck", "position": Vector3(-4.5, 0, -112), "yaw": 10.0},
	{"model": "sedan", "position": Vector3(10.5, 0, -116), "yaw": 0.0},
	{"model": "van", "position": Vector3(-10.5, 0, -124), "yaw": 5.0},
	{"model": "hatchback-sports", "position": Vector3(3.5, 0, -126), "yaw": 80.0},
]
const BURNING_WRECKS: Array[Vector3] = [Vector3(-5.5, 1.2, -32), Vector3(10.5, 1.2, -62), Vector3(-4.5, 1.6, -112)]
const MEDIAN_SEGMENTS: Array[Vector2] = [Vector2(0, -16), Vector2(-24, -44), Vector2(-52, -74), Vector2(-96, -118), Vector2(-124, -136)]
const STREET_LIGHT_Z: Array[float] = [-6.0, -30.0, -56.0, -100.0, -124.0]


func _init() -> void:
	number = 3
	title = "THE 101"
	tagline = "Every self-driving car stopped at once. Run the freeway and catch the last train south."
	story_path = "res://data/story/level_03.json"
	player_start = Vector3(0, 0.1, 4)
	navigation_bounds = AABB(Vector3(-16, -2, -164), Vector3(32, 18, 174))
	kill_height = -10.0
	weapon_count = 5
	win_heading = "YOU CAUGHT THE TRAIN."
	win_body = "The last commuter train south pulls away.\nBehind you, the 101 is still a parking lot. Forever."
	mood = {
		"sky_shadow": Color(0.03, 0.02, 0.06),
		"sky_mid": Color(0.35, 0.1, 0.12),
		"sky_highlight": Color(1.0, 0.5, 0.25),
		"sky_haze": Color(0.25, 0.08, 0.06),
		"sky_exposure": 0.55,
		"fog_color": Color(0.35, 0.18, 0.12),
		"fog_density": 0.007,
		"sun_color": Color(0.55, 0.65, 1.0),
		"sun_energy": 0.45,
		"sun_rotation": Vector3(-35, -150, 0),
		"ambient_color": Color(0.4, 0.36, 0.45),
		"ambient_energy": 0.6,
		"glow_intensity": 0.9,
		"particles": ["ash", "embers"],
	}
	shots = {
		"overview": {"from": Vector3(0, 9, 10), "to": Vector3(0, 8, 0), "look": Vector3(0, 1, -50)},
		"traffic": {"from": Vector3(-12, 3, -6), "to": Vector3(-8, 2.5, -14), "look": Vector3(4, 1, -36)},
		"station": {"from": Vector3(12, 11, -112), "to": Vector3(6, 10, -120), "look": Vector3(0, 7, -152)},
	}
	objectives = [
		{"type": "reach", "text": "Fight down the 101 to the toll plaza", "position": Vector3(0, 0, -90), "beacon_text": "TOLL PLAZA"},
		{
			"type": "reach",
			"text": "Catch the last train south!",
			"position": Vector3(4, PLATFORM_Y, -152),
			"beacon_text": "LAST TRAIN",
			"time_limit": 40.0,
			"countdown_label": "LAST TRAIN LEAVES IN",
			"color": Color(1.0, 0.85, 0.3),
			"fail_heading": "YOU MISSED THE TRAIN.",
			"fail_body": "There isn't another one. Ever.\nWelcome to the permanent underclass.",
		},
	]
	enemies = [
		{"type": "delivery_bot", "position": Vector3(-2, 0.1, -20), "health_scale": 0.7},
		{"type": "delivery_bot", "position": Vector3(8, 0.1, -24), "health_scale": 0.7},
		{"type": "vc", "position": Vector3(-12, 0.1, -36)},
		{"type": "founder", "position": Vector3(2, 0.1, -38)},
		{"type": "delivery_bot", "position": Vector3(-8, 0.1, -46)},
		{"type": "influencer", "position": Vector3(8, 0.1, -54)},
		{"type": "influencer", "position": Vector3(-12, 0.1, -60)},
		{"type": "delivery_bot", "position": Vector3(2, 0.1, -64)},
		{"type": "vc", "position": Vector3(12, 0.1, -70)},
		{"type": "lab_bot", "position": Vector3(-2.5, 0.1, -74)},
		{"type": "manager", "position": Vector3(-7.5, 0.1, -88)},
		{"type": "manager", "position": Vector3(7.5, 0.1, -88)},
		{"type": "lab_bot", "position": Vector3(2.5, 0.1, -97)},
		{"type": "delivery_bot", "position": Vector3(-7, 0.1, -106)},
		{"type": "delivery_bot", "position": Vector3(8, 0.1, -110)},
		{"type": "influencer", "position": Vector3(0, 0.1, -120)},
		{"type": "vc", "position": Vector3(-6, 0.1, -132)},
		{"type": "lab_bot", "position": Vector3(-4, PLATFORM_Y + 0.1, -150)},
		{"type": "manager", "position": Vector3(8, PLATFORM_Y + 0.1, -156)},
	]
	health_packs = [
		Vector3(-12.5, 0, -28),
		Vector3(12.5, 0, -48),
		Vector3(-2, 0, -92),
		Vector3(12.5, 0, -120),
		Vector3(10, PLATFORM_Y, -148),
	]


func build_world(parent: Node3D) -> void:
	build_deck(parent)
	build_barriers(parent)
	build_lane_markings(parent)
	build_traffic_jam(parent)
	build_overclass_van(parent)
	build_sign_gantry(parent)
	build_toll_plaza(parent)
	build_station(parent)
	build_street_lights(parent)
	ArenaKit.skyline(parent, Vector3(0, -30, -70), 48, 115.0, 170.0, 303, 16.0, 26.0)
	for plume: Vector3 in [Vector3(-60, -20, -40), Vector3(70, -20, -110), Vector3(-45, -20, -170)]:
		ArenaKit.smoke(parent, plume)


func build_deck(parent: Node3D) -> void:
	var asphalt := Surfaces.get_textured(Surfaces.ASPHALT, 5.0, Color(0.75, 0.75, 0.8))
	var concrete := Surfaces.get_textured(Surfaces.LAB_CONCRETE, 4.0, Color(0.7, 0.7, 0.72))
	ArenaKit.floor_slab(parent, -HALF_WIDTH, HALF_WIDTH, DECK_END_Z, START_Z, 0.0, asphalt)
	ArenaKit.solid(parent, Vector3(-HALF_WIDTH, -6, DECK_END_Z), Vector3(HALF_WIDTH, -1, START_Z), concrete)
	for pier_z: float in range(0, int(DECK_END_Z), -24):
		ArenaKit.pillar(parent, Vector3(0, -40, pier_z), Vector2(6, 3), 34.0, concrete)
	ArenaKit.wall_along_x(parent, -HALF_WIDTH, HALF_WIDTH, START_Z, 3.0, concrete)


func build_barriers(parent: Node3D) -> void:
	var concrete := Surfaces.get_textured(Surfaces.SIDEWALK_CONCRETE, 2.0, Color(0.85, 0.85, 0.82))
	for side: float in [-1.0, 1.0]:
		var barrier_x := (HALF_WIDTH - 0.3) * side
		ArenaKit.solid(parent, Vector3(barrier_x - 0.3, 0, DECK_END_Z), Vector3(barrier_x + 0.3, BARRIER_HEIGHT, START_Z), concrete)
		ArenaKit.invisible_wall(parent, Vector3(barrier_x - 0.3, BARRIER_HEIGHT, DECK_END_Z), Vector3(barrier_x + 0.3, 12, START_Z))
		ArenaKit.neon(parent, Vector3(0.05, 0.08, absf(DECK_END_Z - START_Z)), Vector3(barrier_x - 0.33 * side, 0.9, (DECK_END_Z + START_Z) / 2.0), Color(1.0, 0.35, 0.2), 1.2)
	for segment: Vector2 in MEDIAN_SEGMENTS:
		ArenaKit.solid(parent, Vector3(-0.3, 0, segment.y), Vector3(0.3, 0.9, segment.x), concrete)


func build_lane_markings(parent: Node3D) -> void:
	for dash_z: float in range(int(START_Z), int(DECK_END_Z), -6):
		for lane_x: float in [-8.0, -3.0, 3.0, 8.0]:
			var dash := LevelBuilder.add_decor(parent, Vector3(0.15, 0.02, 2.4), Vector3(lane_x, 0.015, dash_z), Color(0.9, 0.9, 0.85), 0.2)
			dash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func build_traffic_jam(parent: Node3D) -> void:
	for car: Dictionary in CARS:
		var car_position: Vector3 = car["position"]
		var yaw: float = car["yaw"]
		ArenaKit.car(parent, car["model"], car_position, yaw)
	for wreck: Vector3 in BURNING_WRECKS:
		ArenaKit.fire(parent, wreck, 2.5)


func build_overclass_van(parent: Node3D) -> void:
	ArenaKit.car(parent, "delivery-flat", Vector3(9.5, 0, -20), -70.0, 1.6)
	ArenaKit.fire(parent, Vector3(9.5, 1.0, -20), 2.0)
	ArenaKit.place_sign(parent, "OVERCLASS DELIVERY\nWE DELIVER THE FUTURE*", Vector3(9.5, 3.4, -20), 180.0, 56, LevelBuilder.NEON_CYAN)
	ArenaKit.place_sign(parent, "*FUTURE NOT INCLUDED", Vector3(9.5, 2.7, -20), 180.0, 32, LevelBuilder.NEON_PINK)


func build_sign_gantry(parent: Node3D) -> void:
	var steel := LevelBuilder.get_material(Color(0.35, 0.37, 0.4))
	for post_x: float in [-HALF_WIDTH + 0.8, HALF_WIDTH - 0.8]:
		ArenaKit.pillar(parent, Vector3(post_x, 0, -50), Vector2(0.5, 0.5), 7.0, steel)
	LevelBuilder.add_decor(parent, Vector3(HALF_WIDTH * 2.0, 0.4, 0.5), Vector3(0, 7.0, -50), Color(0.35, 0.37, 0.4))
	LevelBuilder.add_decor(parent, Vector3(9.0, 2.6, 0.2), Vector3(-5, 8.6, -50), Color(0.05, 0.35, 0.18))
	LevelBuilder.add_decor(parent, Vector3(9.0, 2.6, 0.2), Vector3(5, 8.6, -50), Color(0.05, 0.35, 0.18))
	ArenaKit.place_sign(parent, "101 SOUTH\nSAN JOSE", Vector3(-5, 8.6, -49.85), 0.0, 90, Color.WHITE)
	ArenaKit.place_sign(parent, "SINGULARITY\n12 MI", Vector3(5, 8.6, -49.85), 0.0, 90, Color.WHITE)


func build_toll_plaza(parent: Node3D) -> void:
	var booth := Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.85, 0.9, 1.0))
	for booth_x: float in [-11.0, -5.5, 0.0, 5.5, 11.0]:
		ArenaKit.solid(parent, Vector3(booth_x - 0.8, 0, TOLL_Z - 1.5), Vector3(booth_x + 0.8, 2.8, TOLL_Z + 1.5), booth)
		ArenaKit.neon(parent, Vector3(1.7, 0.15, 0.1), Vector3(booth_x, 2.6, TOLL_Z + 1.56), Color(0.3, 1.0, 0.5), 2.5)
		ArenaKit.pillar(parent, Vector3(booth_x, 2.8, TOLL_Z), Vector2(0.4, 0.4), 2.4, LevelBuilder.get_material(Color(0.6, 0.6, 0.65)))
	LevelBuilder.add_decor(parent, Vector3(HALF_WIDTH * 2.0, 0.5, 6.0), Vector3(0, 5.4, TOLL_Z), Color(0.12, 0.13, 0.16))
	ArenaKit.neon(parent, Vector3(HALF_WIDTH * 2.0, 0.2, 0.1), Vector3(0, 5.1, TOLL_Z + 3.05), Color(1.0, 0.75, 0.2), 3.0)
	ArenaKit.place_sign(parent, "TOLL: YOUR PERSONAL DATA", Vector3(0, 6.2, TOLL_Z + 3.1), 0.0, 120, Color(1.0, 0.8, 0.3))
	ArenaKit.lamp(parent, Vector3(-6, 5.0, TOLL_Z), SODIUM, 2.6, 14.0, false)
	ArenaKit.lamp(parent, Vector3(6, 5.0, TOLL_Z), SODIUM, 2.6, 14.0, false)


func build_station(parent: Node3D) -> void:
	var platform := Surfaces.get_textured(Surfaces.SIDEWALK_CONCRETE, 3.0, Color(0.8, 0.78, 0.75))
	var concrete := Surfaces.get_textured(Surfaces.LAB_CONCRETE, 4.0, Color(0.6, 0.6, 0.62))
	ArenaKit.solid(parent, Vector3(-HALF_WIDTH, -6, PLATFORM_END_Z), Vector3(HALF_WIDTH, PLATFORM_Y, DECK_END_Z), platform)
	ArenaKit.ramp(parent, Vector3(9.5, 0, -128), Vector3(9.5, PLATFORM_Y, DECK_END_Z), 5.0, Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0))
	ArenaKit.ramp(parent, Vector3(-9.5, 0, -128), Vector3(-9.5, PLATFORM_Y, DECK_END_Z), 5.0, Surfaces.get_textured(Surfaces.RUSTY_GRATE, 2.0))
	ArenaKit.railing(parent, Vector3(-6.9, PLATFORM_Y, DECK_END_Z), Vector3(6.9, PLATFORM_Y, DECK_END_Z))
	ArenaKit.wall_along_x(parent, -HALF_WIDTH, HALF_WIDTH, PLATFORM_END_Z, 4.0, concrete, PLATFORM_Y)
	for side: float in [-1.0, 1.0]:
		ArenaKit.wall_along_z(parent, PLATFORM_END_Z, DECK_END_Z, HALF_WIDTH * side, 1.2, concrete, PLATFORM_Y)
		ArenaKit.invisible_wall(parent, Vector3(HALF_WIDTH * side - 0.3, PLATFORM_Y + 1.2, PLATFORM_END_Z), Vector3(HALF_WIDTH * side + 0.3, PLATFORM_Y + 12, DECK_END_Z))
	build_train(parent)
	build_platform_canopy(parent)


func build_train(parent: Node3D) -> void:
	var body := Surfaces.get_textured(Surfaces.BLUE_METAL, 3.0, Color(0.9, 0.9, 0.95))
	ArenaKit.solid(parent, Vector3(-13.6, PLATFORM_Y, -161), Vector3(-9.6, PLATFORM_Y + 4.2, -141), body)
	LevelBuilder.add_decor(parent, Vector3(0.1, 1.0, 18.0), Vector3(-9.55, PLATFORM_Y + 2.6, -151), Color(1.0, 0.85, 0.55), 2.0)
	LevelBuilder.add_decor(parent, Vector3(0.1, 0.35, 19.6), Vector3(-9.55, PLATFORM_Y + 1.2, -151), Color(0.85, 0.1, 0.1), 1.0)
	ArenaKit.place_sign(parent, "COMMUTER RAIL  -  LAST TRAIN SOUTH", Vector3(-9.5, PLATFORM_Y + 3.7, -151), 90.0, 64, Color(1.0, 0.9, 0.6))
	var platform_edge := LevelBuilder.add_decor(parent, Vector3(0.4, 0.03, 20.0), Vector3(-9.0, PLATFORM_Y + 0.02, -151), LevelBuilder.SAFETY_YELLOW, 0.5)
	platform_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func build_platform_canopy(parent: Node3D) -> void:
	var steel := LevelBuilder.get_material(Color(0.3, 0.32, 0.36))
	for post_z: float in [-144.0, -152.0, -160.0]:
		ArenaKit.pillar(parent, Vector3(2, PLATFORM_Y, post_z), Vector2(0.4, 0.4), 4.5, steel)
		ArenaKit.lamp(parent, Vector3(2, PLATFORM_Y + 4.3, post_z), Color(0.95, 0.95, 1.0), 2.2, 12.0)
	LevelBuilder.add_decor(parent, Vector3(16.0, 0.3, 20.0), Vector3(-2, PLATFORM_Y + 4.8, -151), Color(0.16, 0.17, 0.2))
	ArenaKit.flickering_sign(parent, "MOUNTAIN VIEW: NOT FOR YOU", Vector3(6, PLATFORM_Y + 3.2, PLATFORM_END_Z + 0.35), 0.0, 80, LevelBuilder.NEON_PINK)


func build_street_lights(parent: Node3D) -> void:
	for light_z: float in STREET_LIGHT_Z:
		Models.spawn_fitted(parent, Models.ROADS + "light-curved-double.glb", Vector3(0, 0.9, light_z), 0.0, 7.0)
		ArenaKit.lamp(parent, Vector3(0, 7.2, light_z), SODIUM, 2.2, 18.0, false)
