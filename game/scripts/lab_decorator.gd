class_name LabDecorator
extends RefCounted

const MEZZANINE_Y := LevelBuilder.MEZZANINE_HEIGHT
const ROOF_Y := LevelBuilder.ROOF_HEIGHT
const PLANT_POSITIONS: Array[Vector3] = [Vector3(-12.5, 0, -82.5), Vector3(6.5, 0, -83), Vector3(-6, 0, -98)]
const SERVER_RACK_X: Array[float] = [-9.0, -6.0, -3.0, 3.0, 6.0]
const OFFICE_DESKS: Array[Vector3] = [Vector3(-2, MEZZANINE_Y, -107), Vector3(2.5, MEZZANINE_Y, -107), Vector3(-2, MEZZANINE_Y, -115.5), Vector3(2.5, MEZZANINE_Y, -115.5), Vector3(7, MEZZANINE_Y, -107)]
const ROOF_UNITS: Array[Dictionary] = [
	{"model": "container-wide", "position": Vector3(-3, ROOF_Y, -85)},
	{"model": "container-tall", "position": Vector3(9, ROOF_Y, -114)},
	{"model": "container", "position": Vector3(-4, ROOF_Y, -112)},
]
const INTERIOR_LIGHTS: Array[Vector3] = [Vector3(-6, 14.15, -86), Vector3(5, 14.15, -93), Vector3(-4, 6.7, -106), Vector3(4, 6.7, -113), Vector3(2, 14.15, -110), Vector3(-2, 14.15, -117)]
const LIGHT_PANEL_SIZE := Vector3(3.0, 0.1, 1.2)


static func build(parent: Node3D) -> void:
	furnish_lobby(parent)
	place_server_racks(parent)
	furnish_mezzanine(parent)
	place_roof_units(parent)
	light_interior(parent)


static func place_solid(parent: Node3D, path: String, floor_position: Vector3, yaw_degrees: float, height: float) -> Node3D:
	var model := Models.spawn_fitted(parent, path, floor_position, yaw_degrees, height)
	Models.add_collider_around(parent, model)
	return model


static func furnish_lobby(parent: Node3D) -> void:
	for plant_position: Vector3 in PLANT_POSITIONS:
		place_solid(parent, Models.FURNITURE + "pottedPlant.glb", plant_position, 0.0, 1.6)
	place_solid(parent, Models.FURNITURE + "loungeSofaLong.glb", Vector3(-10.5, 0, -90.5), 90.0, 0.9)
	place_solid(parent, Models.FURNITURE + "tableCoffee.glb", Vector3(-8.2, 0, -90.5), 90.0, 0.45)
	Models.spawn_fitted(parent, Models.FURNITURE + "lampRoundFloor.glb", Vector3(-12.5, 0, -93.5), 0.0, 1.8)
	for screen_x: float in [-2.2, 2.2]:
		Models.spawn_fitted(parent, Models.FURNITURE + "computerScreen.glb", Vector3(screen_x, 1.1, -90.4), 180.0, 0.5)
		Models.spawn_fitted(parent, Models.FURNITURE + "chairDesk.glb", Vector3(screen_x, 0, -92.2), 0.0, 1.1)
	Models.spawn_fitted(parent, Models.STATION + "display-wall-wide.glb", Vector3(-13.4, 1.8, -103), 90.0, 1.8)
	Models.spawn_fitted(parent, Models.STATION + "display-wall-wide.glb", Vector3(13.4, 1.8, -108), -90.0, 1.8)


static func place_server_racks(parent: Node3D) -> void:
	for rack_x: float in SERVER_RACK_X:
		place_solid(parent, Models.STATION + "computer-system.glb", Vector3(rack_x, 0, -117.8), 0.0, 3.0)


static func furnish_mezzanine(parent: Node3D) -> void:
	for desk_position: Vector3 in OFFICE_DESKS:
		place_solid(parent, Models.FURNITURE + "desk.glb", desk_position, 0.0, 0.8)
		Models.spawn_fitted(parent, Models.FURNITURE + "computerScreen.glb", desk_position + Vector3(0, 0.8, -0.1), 0.0, 0.5)
		Models.spawn_fitted(parent, Models.FURNITURE + "chairDesk.glb", desk_position + Vector3(0, 0, 1.0), 180.0, 1.1)
	place_solid(parent, Models.FURNITURE + "kitchenCoffeeMachine.glb", Vector3(11.5, MEZZANINE_Y, -118.5), 0.0, 0.6)
	Models.spawn_fitted(parent, Models.STATION + "display-wall-wide.glb", Vector3(-13.4, MEZZANINE_Y + 2.0, -112), 90.0, 1.6)


static func place_roof_units(parent: Node3D) -> void:
	for unit: Dictionary in ROOF_UNITS:
		place_solid(parent, Models.STATION + unit["model"] + ".glb", unit["position"], 0.0, 1.8)


static func light_interior(parent: Node3D) -> void:
	for light_position: Vector3 in INTERIOR_LIGHTS:
		LevelBuilder.add_decor(parent, LIGHT_PANEL_SIZE, light_position + Vector3(0, 0.1, 0), Color(0.9, 0.97, 1.0), 4.0)
		var light := OmniLight3D.new()
		light.light_color = Color(0.8, 0.92, 1.0)
		light.light_energy = 2.2
		light.omni_range = 16.0
		light.position = light_position - Vector3(0, 0.4, 0)
		parent.add_child(light)
