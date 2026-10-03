class_name IntroSequence
extends Node3D

signal finished

const CAST_PATH := "res://data/story/cast.json"
const PAUSE_AFTER_LINE_SECONDS := 0.6
const PLAYER_SHOT := "player"
const DEFAULT_SPEAKER_COLOR := Color(0.25, 0.85, 1.0)

var hud: Hud
var player: Player
var level: Level
var story_path := ""
var camera: Camera3D
var hologram: Hologram
var voice_player: AudioStreamPlayer
var camera_tween: Tween
var cast: Dictionary = {}
var lines: Array = []
var line_index := -1
var is_running := false
var is_dismissed := false
var line_generation := 0


func setup(game_hud: Hud, game_player: Player, game_level: Level, story_path_override := "") -> void:
	hud = game_hud
	player = game_player
	level = game_level
	story_path = story_path_override if story_path_override != "" else level.story_path


func _ready() -> void:
	cast = load_json(CAST_PATH)
	lines = load_json(story_path)["lines"]
	camera = Camera3D.new()
	camera.fov = 70.0
	add_child(camera)
	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	if level.has_hologram():
		hologram = Hologram.new()
		hologram.position = level.hologram_position
		add_child(hologram)


static func load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("Could not parse story file %s" % path)
		return {"lines": []}
	return parsed


static func get_line_voice(cast_data: Dictionary, line: Dictionary) -> String:
	return cast_data[line["cast"]]["voice"]


func show_menu_backdrop() -> void:
	camera.make_current()
	move_camera(level.menu_shot, 30.0)


func start() -> void:
	is_running = true
	line_index = -1
	camera.make_current()
	play_next_line()


func advance() -> void:
	if is_running:
		play_next_line()


func skip() -> void:
	if is_running:
		finish()


func play_next_line() -> void:
	line_index += 1
	if line_index >= lines.size():
		finish()
		return
	var line: Dictionary = lines[line_index]
	var speaker: Dictionary = cast[line["cast"]]
	var clip := AudioBank.get_story_clip(speaker["voice"], line["id"])
	var speaker_color := Color.html(speaker.get("color", DEFAULT_SPEAKER_COLOR.to_html()))
	hud.show_dialogue(speaker["name"], line.get("role", speaker["role"]), line["text"], line_index + 1, lines.size(), speaker_color)
	if hologram != null and line.has("gesture"):
		hologram.play_gesture(line["gesture"])
	frame_shot(line["shot"], clip.get_length())
	voice_player.stream = clip
	voice_player.pitch_scale = speaker.get("pitch", 1.0)
	voice_player.play()
	schedule_auto_advance(clip.get_length() / voice_player.pitch_scale + PAUSE_AFTER_LINE_SECONDS)


func frame_shot(shot_name: String, duration: float) -> void:
	var is_player_shot := shot_name == PLAYER_SHOT
	hud.set_gameplay_visible(is_player_shot)
	if is_player_shot:
		player.camera.make_current()
		return
	camera.make_current()
	if not level.shots.has(shot_name):
		push_warning("Level %d has no camera shot '%s'" % [level.number, shot_name])
		return
	move_camera(level.shots[shot_name], duration)


func move_camera(shot: Dictionary, duration: float) -> void:
	if camera_tween != null:
		camera_tween.kill()
	var look_target: Vector3 = shot["look"]
	place_camera(shot["from"], look_target)
	camera_tween = create_tween()
	camera_tween.tween_method(place_camera.bind(look_target), shot["from"], shot["to"], duration)


func place_camera(camera_position: Vector3, look_target: Vector3) -> void:
	camera.position = camera_position
	camera.look_at(look_target)


func schedule_auto_advance(delay_seconds: float) -> void:
	line_generation += 1
	var expected_generation := line_generation
	get_tree().create_timer(delay_seconds).timeout.connect(auto_advance.bind(expected_generation))


func auto_advance(expected_generation: int) -> void:
	if is_running and expected_generation == line_generation:
		play_next_line()


func finish() -> void:
	dismiss()
	finished.emit()


func dismiss() -> void:
	if is_dismissed:
		return
	is_dismissed = true
	is_running = false
	line_generation += 1
	voice_player.stop()
	if camera_tween != null:
		camera_tween.kill()
	hud.hide_dialogue()
	hud.set_gameplay_visible(true)
	player.camera.make_current()
	if hologram != null:
		hologram.fade_out()
