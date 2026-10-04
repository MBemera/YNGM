extends SceneTree

const AutoplayBot := preload("res://tests/autoplay/autoplay_bot.gd")
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_SCRIPT_PATH := "res://scripts/main.gd"


func _initialize() -> void:
	SaveData.is_persistence_enabled = false
	Difficulty.set_current(get_argument("--difficulty=", Difficulty.NORMAL))
	GraphicsSettings.set_current(get_argument("--quality=", GraphicsSettings.AUTO))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var bot := AutoplayBot.new()
	bot.report_directory = get_argument("--report-dir=", "user://playthrough")
	bot.is_recording = OS.get_cmdline_user_args().has("--recording")
	bot.stop_after_level = int(get_argument("--stop-after-level=", "0"))
	root.add_child(bot)
	start_campaign.call_deferred()


func get_argument(prefix: String, fallback: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func start_campaign() -> void:
	var main_script = load(MAIN_SCRIPT_PATH)
	main_script.current_level_number = int(get_argument("--start-level=", "1"))
	main_script.should_show_menu = main_script.current_level_number == 1
	main_script.should_play_story = true
	var main: Node = load(MAIN_SCENE_PATH).instantiate()
	root.add_child(main)
	current_scene = main
