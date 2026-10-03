extends SceneTree

const FrameStats := preload("res://tests/autoplay/frame_stats.gd")
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_SCRIPT_PATH := "res://scripts/main.gd"
const PROBE_SECONDS := 4.0
const VARIANTS: Array[String] = ["baseline", "no_msaa", "no_glow", "no_shadows", "no_overlay", "no_particles", "no_omni_lights", "no_fog", "no_labels", "all_off"]

var current_stats: RefCounted
var is_recording := false


func _initialize() -> void:
	SaveData.is_persistence_enabled = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	run_probe.call_deferred()


func _process(delta: float) -> bool:
	if is_recording and current_stats != null:
		current_stats.add_frame(delta)
	return false


func run_probe() -> void:
	var levels: Array[int] = []
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--levels="):
			for part: String in argument.trim_prefix("--levels=").split(","):
				levels.append(int(part))
	for level_number: int in levels:
		for variant: String in VARIANTS:
			await probe_variant(level_number, variant)
	quit(0)


func probe_variant(level_number: int, variant: String) -> void:
	var main := await load_level(level_number)
	main.hud.hide_message()
	main.start_game()
	var player: Player = main.player
	player.runway_months = 99999
	apply_variant(main, variant)
	await wait_frames(45)
	current_stats = FrameStats.new()
	is_recording = true
	var elapsed := 0.0
	while elapsed < PROBE_SECONDS:
		await process_frame
		elapsed += get_root().get_process_delta_time()
	is_recording = false
	var summary: Dictionary = current_stats.get_summary()
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var primitives := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var process_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	print("L%02d %-15s %5.1f fps  draws %5d  objects %5d  prims %7d  process %4.1f ms  physics %4.1f ms" % [level_number, variant, summary["average_fps"], draw_calls, objects, primitives, process_ms, physics_ms])
	main.queue_free()
	await wait_frames(5)


func apply_variant(main: Node, variant: String) -> void:
	var environment: Environment = (main.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
	var everything := variant == "all_off"
	if variant == "no_msaa" or everything:
		get_root().msaa_3d = Viewport.MSAA_DISABLED
	if variant == "no_glow" or everything:
		environment.glow_enabled = false
	if variant == "no_fog" or everything:
		environment.fog_enabled = false
	if variant == "no_shadows" or everything:
		for sun: DirectionalLight3D in main.find_children("*", "DirectionalLight3D", true, false):
			sun.shadow_enabled = false
	if variant == "no_overlay" or everything:
		main.screen_overlay.visible = false
	if variant == "no_particles" or everything:
		for particles: CPUParticles3D in main.find_children("*", "CPUParticles3D", true, false):
			particles.visible = false
			particles.emitting = false
	if variant == "no_omni_lights" or everything:
		for light: OmniLight3D in main.find_children("*", "OmniLight3D", true, false):
			light.visible = false
	if variant == "no_labels" or everything:
		for label: Label3D in main.find_children("*", "Label3D", true, false):
			label.visible = false


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
