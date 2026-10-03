extends SceneTree

var recording_root := ""
var audio_effect: AudioEffectRecord
var audio_started := 0.0
var next_status := 0.0

func _initialize() -> void:
	recording_root = OS.get_cmdline_user_args()[0]
	audio_effect = AudioEffectRecord.new()
	audio_effect.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, audio_effect)
	call_deferred("load_game")

func load_game() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	current_scene = game

func _process(_delta: float) -> bool:
	if audio_started == 0.0 and FileAccess.file_exists(recording_root.path_join("start-audio")):
		audio_started = Time.get_unix_time_from_system()
		audio_effect.set_recording_active(true)
	if Time.get_unix_time_from_system() >= next_status:
		next_status = Time.get_unix_time_from_system() + 0.25
		write_status()
	if FileAccess.file_exists(recording_root.path_join("stop-audio")):
		audio_effect.set_recording_active(false)
		var recording := audio_effect.get_recording()
		var result := recording.save_to_wav(recording_root.path_join("game-audio.wav"))
		print("Audio saved: ", result, " duration: ", recording.get_length())
		write_status()
		quit(result)
	return false

func write_status() -> void:
	if current_scene == null or current_scene.get("player") == null:
		return
	var game := current_scene
	var player: Node3D = game.player
	var status := {
		"state": ["MENU", "INTRO", "READY", "PLAYING", "WON", "LOST"][game.state],
		"position": [player.position.x, player.position.y, player.position.z],
		"yaw": player.rotation.y, "pitch": player.head.rotation.x,
		"runway": player.runway_months, "weapon": player.current_weapon_index + 1,
		"audio_started": audio_started, "time": Time.get_unix_time_from_system(),
		"ladder_seconds": game.ladder_time_left,
	}
	var file := FileAccess.open(recording_root.path_join("game-state.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(status))