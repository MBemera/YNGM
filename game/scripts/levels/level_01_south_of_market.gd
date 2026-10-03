class_name Level01SouthOfMarket
extends Level

const HELICOPTER_POSITION := Vector3(5, 23, -95)
const EARLY_HEALTH_SCALE := 0.4
const MID_STREET_HEALTH_SCALE := 0.7

var helicopter: Helicopter


func _init() -> void:
	number = 1
	title = "SOUTH OF MARKET"
	tagline = "The transition is here. The helicopter is leaving. Don't get left behind."
	story_path = "res://data/story/level_01.json"
	player_start = Vector3(0, 0.1, 4)
	navigation_bounds = AABB(Vector3(-16, -2, -122), Vector3(32, 20, 136))
	kill_height = -10.0
	weapon_count = 3
	hologram_position = Vector3(0, 0, -20)
	win_heading = "YOU MADE IT."
	win_body = "For now.\nThe ladder is up. Someone else is still down there."
	menu_shot = {"from": Vector3(0, 2.2, 8), "to": Vector3(0, 2.6, 6), "look": Vector3(0, 6.5, -30)}
	shots = {
		"hologram": {"from": Vector3(0, 3.5, 8), "to": Vector3(0, 5.0, -3), "look": Vector3(0, 6.8, -20)},
		"street": {"from": Vector3(7, 3.5, -24), "to": Vector3(5, 3.0, -30), "look": Vector3(-2, 1.2, -46)},
		"lab": {"from": Vector3(0, 4.0, -46), "to": Vector3(0, 6.0, -58), "look": Vector3(0, 8.0, -80)},
		"helicopter": {"from": Vector3(-6, 14, -60), "to": Vector3(-3, 20, -70), "look": Vector3(5, 22, -95)},
		"hologram_close": {"from": Vector3(2.5, 6.0, -9), "to": Vector3(0.5, 7.0, -13), "look": Vector3(0, 7.4, -20)},
	}
	objectives = [
		{
			"type": "ladder",
			"fail_heading": "THE LADDER WENT UP.",
			"fail_body": "You're not gonna make it.\nWelcome to the permanent underclass.",
		},
	]
	enemies = [
		{"type": "vc", "position": Vector3(-6, 0.1, -22), "health_scale": EARLY_HEALTH_SCALE},
		{"type": "founder", "position": Vector3(3, 0.1, -28), "health_scale": EARLY_HEALTH_SCALE},
		{"type": "vc", "position": Vector3(8, 0.1, -34), "health_scale": EARLY_HEALTH_SCALE},
		{"type": "founder", "position": Vector3(-7, 0.1, -46), "health_scale": EARLY_HEALTH_SCALE},
		{"type": "vc", "position": Vector3(-5, 0.1, -56), "health_scale": MID_STREET_HEALTH_SCALE},
		{"type": "founder", "position": Vector3(7, 0.1, -63), "health_scale": MID_STREET_HEALTH_SCALE},
		{"type": "vc", "position": Vector3(4, 0.1, -71), "health_scale": MID_STREET_HEALTH_SCALE},
		{"type": "lab_bot", "position": Vector3(-5, 0.1, -96)},
		{"type": "lab_bot", "position": Vector3(4, 0.1, -106)},
		{"type": "lab_bot", "position": Vector3(-2, 0.1, -112)},
		{"type": "vc", "position": Vector3(1, 7.6, -112)},
		{"type": "founder", "position": Vector3(-4, 7.6, -105)},
		{"type": "lab_bot", "position": Vector3(-2, 15.1, -92)},
		{"type": "lab_bot", "position": Vector3(10, 15.1, -102)},
		{"type": "founder", "position": Vector3(1, 15.1, -106)},
		{"type": "founder", "position": Vector3(9, 15.1, -86)},
		{"type": "vc", "position": Vector3(11, 15.1, -118)},
	]
	health_packs = [
		Vector3(-7, 0, -37),
		Vector3(7, 0, -57),
		Vector3(3, 0, -86),
		Vector3(8, LevelBuilder.MEZZANINE_HEIGHT, -112),
		Vector3(-2, LevelBuilder.ROOF_HEIGHT, -100),
	]


func build_world(parent: Node3D) -> void:
	LevelBuilder.build(parent)
	StreetDecorator.build(parent)
	LabDecorator.build(parent)
	helicopter = Helicopter.new()
	helicopter.position = HELICOPTER_POSITION
	parent.add_child(helicopter)


func on_completed(_main: Node3D, player: Player) -> void:
	player.freeze()
	player.reparent.call_deferred(helicopter)
	helicopter.pull_ladder_up()
	helicopter.fly_away()


func on_failed() -> void:
	helicopter.pull_ladder_up()
	helicopter.fly_away()
