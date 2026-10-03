class_name StreetDecorator
extends RefCounted

const BUILDING_SCALE := 11.0
const CAR_SCALE := 1.5
const ROAD_TILE_LENGTH := 15.0
const ROAD_TILE_YAW := 90.0
const SKYLINE_CENTER := Vector3(0, 0, -55)
const SKYLINE_COUNT := 44
const LEFT_BUILDINGS: Array[String] = ["building-j", "building-skyscraper-b", "building-a", "building-n", "building-l", "building-skyscraper-d", "building-k", "building-g"]
const RIGHT_BUILDINGS: Array[String] = ["building-skyscraper-c", "building-e", "building-m", "building-i", "building-skyscraper-e", "building-b", "building-f", "building-h"]
const SKYLINE_MODELS: Array[String] = ["low-detail-building-a", "low-detail-building-c", "low-detail-building-e", "low-detail-building-g", "low-detail-building-i", "low-detail-building-k", "low-detail-building-m", "low-detail-building-wide-a", "building-skyscraper-a", "building-skyscraper-d"]
const CARS: Array[Dictionary] = [
	{"model": "taxi", "position": Vector3(-4, 0, -18), "yaw": 35.0},
	{"model": "police", "position": Vector3(5, 0, -41), "yaw": -65.0},
	{"model": "sedan", "position": Vector3(-2.5, 0, -61), "yaw": 12.0},
	{"model": "van", "position": Vector3(9.8, 0, -3), "yaw": 0.0},
	{"model": "garbage-truck", "position": Vector3(9.6, 0, -67), "yaw": 0.0},
]
const DUMPSTER_POSITIONS: Array[Vector3] = [Vector3(9.5, 0, -8), Vector3(-9.5, 0, -30), Vector3(9.5, 0, -52), Vector3(-9.5, 0, -74)]
const STREET_LIGHTS: Array[Vector3] = [Vector3(-11, 0, 0), Vector3(11, 0, -12), Vector3(-11, 0, -22), Vector3(11, 0, -30), Vector3(-11, 0, -48), Vector3(11, 0, -58), Vector3(-11, 0, -64)]
const CONE_POSITIONS: Array[Vector3] = [Vector3(-6, 0, -9), Vector3(-5, 0, -10.5), Vector3(2, 0, -47), Vector3(3.2, 0, -48), Vector3(6, 0, -77), Vector3(-6, 0, -78)]
const SMOKE_PLUMES: Array[Vector3] = [Vector3(-60, 0, -40), Vector3(70, 0, -110), Vector3(-40, 0, -170), Vector3(55, 0, 10)]


static func build(parent: Node3D) -> void:
	lay_road(parent)
	line_street(parent, -1, LEFT_BUILDINGS)
	line_street(parent, 1, RIGHT_BUILDINGS)
	close_street_behind_start(parent)
	place_barricade(parent)
	place_cars(parent)
	place_burning_dumpsters(parent)
	place_street_lights(parent)
	place_cones(parent)
	build_skyline(parent)
	place_smoke_plumes(parent)


static func lay_road(parent: Node3D) -> void:
	var tile_count := int(ceil((LevelBuilder.STREET_START_Z - LevelBuilder.STREET_END_Z) / ROAD_TILE_LENGTH))
	for tile_index: int in tile_count:
		var center_z := LevelBuilder.STREET_START_Z - ROAD_TILE_LENGTH * (tile_index + 0.5)
		var tile := Models.spawn(parent, Models.ROADS + "road-straight.glb", Vector3(0, 0.0, center_z), ROAD_TILE_YAW)
		var width := LevelBuilder.ROAD_HALF_WIDTH * 2.0
		tile.scale = Vector3(width, 1.0, ROAD_TILE_LENGTH) if is_zero_approx(ROAD_TILE_YAW) else Vector3(ROAD_TILE_LENGTH, 1.0, width)


static func line_street(parent: Node3D, side: int, building_names: Array[String]) -> void:
	var cursor_z := LevelBuilder.STREET_START_Z + 4.0
	for building_name: String in building_names:
		var remaining_length := cursor_z - LevelBuilder.STREET_END_Z
		if remaining_length < 4.0:
			return
		var building := Models.spawn(parent, Models.CITY + building_name + ".glb", Vector3.ZERO, 90.0 * -side, BUILDING_SCALE)
		var bounds := Models.get_world_bounds(building)
		if bounds.size.z > remaining_length:
			building.scale *= remaining_length / bounds.size.z
			bounds = Models.get_world_bounds(building)
		var facade_x := LevelBuilder.STREET_HALF_WIDTH * side
		var shift_x := facade_x - bounds.end.x if side < 0 else facade_x - bounds.position.x
		building.position += Vector3(shift_x, -bounds.position.y, cursor_z - bounds.end.z)
		cursor_z -= bounds.size.z


static func close_street_behind_start(parent: Node3D) -> void:
	var building := Models.spawn(parent, Models.CITY + "building-n.glb", Vector3.ZERO, 180.0, BUILDING_SCALE * 1.2)
	var bounds := Models.get_world_bounds(building)
	building.position += Vector3(-bounds.get_center().x, -bounds.position.y, LevelBuilder.STREET_START_Z + 3.0 - bounds.position.z)


static func place_barricade(parent: Node3D) -> void:
	var barricade_z := LevelBuilder.STREET_START_Z - 0.6
	for barrier_x: float in [-10.0, -7.5, -5.0, -2.5, 0.0, 2.5, 5.0, 7.5, 10.0]:
		Models.spawn_fitted(parent, Models.ROADS + "construction-barrier.glb", Vector3(barrier_x, 0, barricade_z), 90.0, 1.2)
	for light_x: float in [-11.2, 11.2]:
		Models.spawn_fitted(parent, Models.ROADS + "construction-light.glb", Vector3(light_x, 0, barricade_z), 0.0, 2.0)


static func place_cars(parent: Node3D) -> void:
	for car: Dictionary in CARS:
		var model := Models.spawn(parent, Models.CARS + car["model"] + ".glb", car["position"], car["yaw"], CAR_SCALE)
		Models.add_collider_around(parent, model)


static func place_burning_dumpsters(parent: Node3D) -> void:
	for dumpster_position: Vector3 in DUMPSTER_POSITIONS:
		var dumpster := Models.spawn_fitted(parent, Models.ROADS + "dumpster.glb", dumpster_position, 90.0, 1.4)
		Models.add_collider_around(parent, dumpster)
		var fire_position := dumpster_position + Vector3(0, 1.4, 0)
		parent.add_child(Effects.create_fire(fire_position))
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.5, 0.15)
		light.light_energy = 3.0
		light.omni_range = 9.0
		light.position = fire_position + Vector3(0, 0.8, 0)
		parent.add_child(light)


static func place_street_lights(parent: Node3D) -> void:
	for pole_position: Vector3 in STREET_LIGHTS:
		var side := signf(pole_position.x)
		Models.spawn_fitted(parent, Models.ROADS + "light-square.glb", pole_position, 90.0 * side, 6.5)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.82, 0.55)
		lamp.light_energy = 1.6
		lamp.omni_range = 11.0
		lamp.position = pole_position + Vector3(-1.6 * side, 6.0, 0)
		parent.add_child(lamp)


static func place_cones(parent: Node3D) -> void:
	for cone_position: Vector3 in CONE_POSITIONS:
		Models.spawn_fitted(parent, Models.ROADS + "construction-cone.glb", cone_position, randf_range(0.0, 360.0), 0.7)


static func build_skyline(parent: Node3D) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 1234
	for index: int in SKYLINE_COUNT:
		var angle := TAU * index / SKYLINE_COUNT + random.randf_range(-0.05, 0.05)
		var distance := random.randf_range(95.0, 150.0)
		var position := SKYLINE_CENTER + Vector3(sin(angle), 0, cos(angle)) * distance
		var model_name := SKYLINE_MODELS[random.randi() % SKYLINE_MODELS.size()]
		Models.spawn(parent, Models.CITY + model_name + ".glb", position, random.randf_range(0.0, 360.0), random.randf_range(14.0, 22.0))


static func place_smoke_plumes(parent: Node3D) -> void:
	for plume_position: Vector3 in SMOKE_PLUMES:
		parent.add_child(Effects.create_smoke_plume(plume_position))
