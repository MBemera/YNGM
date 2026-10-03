extends SceneTree

const FrameStats := preload("res://tests/autoplay/frame_stats.gd")
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_SCRIPT_PATH := "res://scripts/main.gd"
const SETTLE_FRAMES := 60
const PHASE_SECONDS := {"start_view": 3.0, "turn_360": 3.0, "overview": 2.0}
const DEFAULT_RUNS := "high@1280x720,high@1920x1080"

var runs: Array[Dictionary] = []
var report_path := ""
var results: Array[Dictionary] = []
var current_stats: RefCounted
var is_recording := false


func _initialize() -> void:
	SaveData.is_persistence_enabled = false
	Difficulty.set_current(Difficulty.NORMAL)
	report_path = get_argument("--report=", "user://benchmark.json")
	runs = parse_runs(get_argument("--runs=", DEFAULT_RUNS))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	run_benchmark.call_deferred()


func get_argument(prefix: String, fallback: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func parse_runs(text: String) -> Array[Dictionary]:
	var parsed: Array[Dictionary] = []
	for entry: String in text.split(","):
		var parts := entry.split("@")
		var size := parts[1].split("x")
		parsed.append({"quality": parts[0], "resolution": Vector2i(int(size[0]), int(size[1]))})
	return parsed


func _process(delta: float) -> bool:
	if is_recording and current_stats != null:
		current_stats.add_frame(delta)
	return false


func run_benchmark() -> void:
	print("GPU: %s (%s)" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()])
	var has_warmed_up := false
	for run: Dictionary in runs:
		var resolution: Vector2i = run["resolution"]
		GraphicsSettings.set_current(run["quality"])
		apply_resolution(resolution)
		await wait_frames(20)
		if not has_warmed_up:
			await warm_up()
			has_warmed_up = true
		for level_number: int in range(1, LevelCatalog.get_count() + 1):
			await benchmark_level(level_number, resolution)
	write_report()
	quit(0)


func warm_up() -> void:
	for level_number: int in range(1, LevelCatalog.get_count() + 1):
		var main := await load_level(level_number)
		main.hud.hide_message()
		main.start_game()
		await wait_frames(20)
		main.queue_free()
		await wait_frames(3)


func apply_resolution(resolution: Vector2i) -> void:
	if resolution == DisplayServer.screen_get_size():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(resolution)


func benchmark_level(level_number: int, resolution: Vector2i) -> void:
	var main := await load_level(level_number)
	main.hud.hide_message()
	main.start_game()
	var player: Player = main.player
	player.runway_months = 99999
	await wait_frames(SETTLE_FRAMES)
	var rendered_size := get_root().get_visible_rect().size
	var row := {"level": level_number, "title": main.level.title, "quality": GraphicsSettings.get_resolved(), "resolution": "%dx%d" % [int(rendered_size.x), int(rendered_size.y)]}
	row["start_view"] = await record_phase(PHASE_SECONDS["start_view"], Callable())
	row["turn_360"] = await record_phase(PHASE_SECONDS["turn_360"], turn_player.bind(player))
	row["overview"] = await record_overview(main)
	results.append(row)
	print("%-6s %s L%02d %-24s start %5.1f  turn %5.1f  overview %5.1f fps" % [row["quality"], row["resolution"], level_number, row["title"], row["start_view"]["average_fps"], row["turn_360"]["average_fps"], row["overview"]["average_fps"]])
	main.queue_free()
	await wait_frames(5)


func record_phase(seconds: float, per_frame: Callable) -> Dictionary:
	current_stats = FrameStats.new()
	is_recording = true
	var elapsed := 0.0
	while elapsed < seconds:
		await process_frame
		var delta := get_root().get_process_delta_time()
		elapsed += delta
		if per_frame.is_valid():
			per_frame.call(delta, seconds)
	is_recording = false
	return current_stats.get_summary()


func turn_player(delta: float, seconds: float, player: Player) -> void:
	player.rotate_y(TAU * delta / seconds)


func record_overview(main: Node) -> Dictionary:
	var level: Level = main.level
	var shot_name: String = "overview" if level.shots.has("overview") else level.shots.keys()[0]
	var shot: Dictionary = level.shots[shot_name]
	var camera := Camera3D.new()
	camera.fov = 70.0
	main.add_child(camera)
	camera.position = shot["to"]
	camera.look_at(shot["look"])
	camera.make_current()
	await wait_frames(5)
	return await record_phase(PHASE_SECONDS["overview"], Callable())


func load_level(level_number: int) -> Node:
	var main_script = load(MAIN_SCRIPT_PATH)
	main_script.current_level_number = level_number
	main_script.should_show_menu = false
	main_script.should_play_story = false
	var main: Node = load(MAIN_SCENE_PATH).instantiate()
	root.add_child(main)
	await process_frame
	var frames := 0
	while not main.is_navigation_ready and frames < 900:
		await process_frame
		frames += 1
	return main


func wait_frames(count: int) -> void:
	for frame_index: int in count:
		await process_frame


func write_report() -> void:
	var report := {
		"gpu": RenderingServer.get_video_adapter_name(),
		"vendor": RenderingServer.get_video_adapter_vendor(),
		"renderer": "gl_compatibility",
		"vsync": "disabled",
		"difficulty": Difficulty.current,
		"results": results,
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write benchmark report to %s" % report_path)
		return
	file.store_string(JSON.stringify(report, "\t"))
	print("Report: " + report_path)
