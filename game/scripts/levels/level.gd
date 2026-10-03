class_name Level
extends RefCounted

const DEFAULT_MOOD := {
	"sky_shadow": Color(0.16, 0.02, 0.03),
	"sky_mid": Color(0.85, 0.22, 0.05),
	"sky_highlight": Color(1.0, 0.78, 0.35),
	"sky_haze": Color(0.42, 0.1, 0.05),
	"sky_exposure": 0.85,
	"fog_color": Color(0.7, 0.32, 0.16),
	"fog_density": 0.004,
	"sun_color": Color(1.0, 0.55, 0.3),
	"sun_energy": 1.5,
	"sun_rotation": Vector3(-22, 155, 0),
	"ambient_color": Color(0.42, 0.42, 0.5),
	"ambient_energy": 0.75,
	"glow_intensity": 0.7,
	"contrast": 1.1,
	"saturation": 1.0,
	"particles": ["ash", "embers"],
	"sun_shadows": true,
}

var number := 0
var title := ""
var tagline := ""
var story_path := ""
var mood: Dictionary = {}
var player_start := Vector3.ZERO
var player_yaw_degrees := 0.0
var navigation_bounds := AABB()
var kill_height := -20.0
var weapon_count := Weapons.STARTING_WEAPON_COUNT
var enemies: Array[Dictionary] = []
var health_packs: Array[Vector3] = []
var objectives: Array[Dictionary] = []
var shots: Dictionary = {}
var hologram_position := Vector3.INF
var menu_shot: Dictionary = {}
var win_heading := "LEVEL COMPLETE"
var win_body := ""
var doors: Dictionary = {}


func build_world(_parent: Node3D) -> void:
	push_error("Level %d does not build a world" % number)


func add_door(parent: Node3D, door_name: String, min_corner: Vector3, max_corner: Vector3, sign_yaw_degrees := 0.0) -> StaticBody3D:
	var door := ArenaKit.solid(parent, min_corner, max_corner, Surfaces.get_textured(Surfaces.BLUE_METAL, 2.0, Color(0.8, 0.85, 0.9)))
	door.name = "Door_" + door_name
	var size := max_corner - min_corner
	var facing := Basis.from_euler(Vector3(0, deg_to_rad(sign_yaw_degrees), 0))
	var front_offset := facing.z * (minf(size.x, size.z) / 2.0 + 0.05)
	var warning_strip := LevelBuilder.add_decor(door, Vector3(maxf(size.x, size.z) * 0.9, 0.15, 0.15), Vector3(0, size.y / 2.0 - 0.4, 0) + front_offset, LevelBuilder.NEON_PINK, 3.0)
	warning_strip.basis = facing
	ArenaKit.place_sign(door, "LOCKED", Vector3(0, 0.2, 0) + front_offset * 1.5, sign_yaw_degrees, 72, LevelBuilder.NEON_PINK)
	doors[door_name] = door
	return door


func open_door(door_name: String) -> bool:
	if not doors.has(door_name):
		push_warning("Level %d has no door '%s'" % [number, door_name])
		return false
	var door: StaticBody3D = doors[door_name]
	doors.erase(door_name)
	door.collision_layer = 0
	var height := Models.get_world_bounds(door).size.y
	var tween := door.create_tween()
	tween.tween_property(door, "position:y", door.position.y - height - 0.2, 1.4).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(door.queue_free)
	AudioBank.play_at(door.get_parent(), AudioBank.SLAM, door.global_position, 1.6, -4.0)
	return true


func on_completed(_main: Node3D, _player: Player) -> void:
	pass


func on_failed() -> void:
	pass


func get_mood_value(key: String) -> Variant:
	return mood.get(key, DEFAULT_MOOD[key])


func get_chapter_label() -> String:
	return "LEVEL %d: %s" % [number, title]


func has_hologram() -> bool:
	return hologram_position != Vector3.INF
