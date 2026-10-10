class_name GraphicsScenery
extends RefCounted

const ROOT := Models.GRAPHICS_ROOT + "scenery/"
const PLACEMENTS := {
	1: [["kiosk", Vector3(-8, 0, -12), 1.8], ["planter", Vector3(8, 0, -18), 1.2],
		["pylon", Vector3(-9, 0, -62), 2.4], ["pylon", Vector3(9, 0, -62), 2.4]],
	2: [["pylon", Vector3(-18, 0, -6), 2.1], ["pylon", Vector3(18, 0, -6), 2.1],
		["kiosk", Vector3(-18, 0, -70), 1.8], ["kiosk", Vector3(18, 0, -70), 1.8]],
	3: [["pylon", Vector3(-12.5, 0, -24), 2.2], ["pylon", Vector3(12.5, 0, -24), 2.2],
		["pylon", Vector3(-12.5, 0, -94), 2.2], ["pylon", Vector3(12.5, 0, -94), 2.2]],
	4: [["planter", Vector3(-17, 0, -12), 1.3], ["planter", Vector3(17, 0, -12), 1.3],
		["podium", Vector3(-18, 0, -55), 1.6], ["podium", Vector3(18, 0, -55), 1.6]],
	5: [["podium", Vector3(-18, 0, -11), 1.8], ["podium", Vector3(18, 0, -11), 1.8],
		["kiosk", Vector3(-23, 0, -55), 2.0], ["kiosk", Vector3(23, 0, -55), 2.0]],
	6: [["planter", Vector3(-25, 0, -12), 1.4], ["planter", Vector3(25, 0, -12), 1.4],
		["kiosk", Vector3(-26, 0, -58), 2.0], ["kiosk", Vector3(26, 0, -58), 2.0]],
	7: [["server-rack", Vector3(-20, 0, -18), 2.6], ["server-rack", Vector3(-20, 0, -44), 2.6],
		["server-rack", Vector3(20, 0, -18), 2.6], ["server-rack", Vector3(20, 0, -44), 2.6]],
	8: [["pylon", Vector3(-22, 0, -8), 2.3], ["pylon", Vector3(22, 0, -8), 2.3],
		["pylon", Vector3(-20, 0, -55), 2.3], ["pylon", Vector3(20, 0, -55), 2.3]],
	9: [["pylon", Vector3(-26, 0, -12), 2.4], ["pylon", Vector3(26, 0, -12), 2.4],
		["power-relay", Vector3(-24, 6, -80), 2.8], ["power-relay", Vector3(24, 6, -80), 2.8]],
	10: [["podium", Vector3(-18, 0, -8), 1.7], ["podium", Vector3(18, 0, -8), 1.7],
		["planter", Vector3(-20, 0, -60), 1.3], ["planter", Vector3(20, 0, -60), 1.3]],
	11: [["power-relay", Vector3(-22, 0, -22), 2.6], ["power-relay", Vector3(22, 0, -22), 2.6],
		["pylon", Vector3(-18, 0, -50), 2.5], ["pylon", Vector3(18, 0, -50), 2.5]],
}


static func decorate(parent: Node3D, level_number: int) -> void:
	var scenery := Node3D.new()
	scenery.name = "GraphicsScenery"
	parent.add_child(scenery)
	for placement: Array in PLACEMENTS[level_number]:
		ArenaKit.prop(scenery, ROOT + placement[0] + ".glb", placement[1], 0, placement[2])
