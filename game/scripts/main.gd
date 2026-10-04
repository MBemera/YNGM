extends Node3D

signal navigation_ready

enum GameState { LOADING, MENU, INTRO, READY, PLAYING, WON, LOST, ENDING, FINISHED }

const NAVIGATION_SOURCE_GROUP := "navigation_source"
const SKY_TEXTURE_PATH := "res://assets/sky/the_sky_is_on_fire_2k.hdr"
const SKY_SHADER_PATH := "res://shaders/hellscape_sky.gdshader"
const CONTROLS_TEXT := "WASD move  |  Mouse look  |  Space jump  |  Shift sprint\nLeft click fire  |  1-7 or mouse wheel switch weapon\nGreen BRIDGE ROUND crates restore runway\nR restart  |  Esc free the mouse"
const RUNWAY_LOSS_HEADING := "OUT OF RUNWAY."
const RUNWAY_LOSS_BODY := "Don't get left behind... too late.\nWelcome to the permanent underclass."
const FALL_LOSS_HEADING := "YOU FELL THROUGH THE CRACKS."
const FALL_LOSS_BODY := "Nobody was there to catch you.\nWelcome to the permanent underclass."
const LOSS_FOOTER := "\n\nPress R to try again  |  M for the menu"
const FINISHED_HEADING := "NOBODY GOT LEFT BEHIND."
const RESULT_INPUT_DELAY_MSEC := 900
const FINISHED_BODY := "You made it. We all did.\n\nThanks for playing Escape from the Permanent Underclass.\nDifficulty: %s\n\nPress M for the menu  |  Enter to play again from Level 1"

static var current_level_number := 1
static var should_show_menu := true
static var should_play_story := true
static var is_staged_loading_enabled := true

var state := GameState.LOADING
var level: Level
var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var player: Player
var hud: Hud
var screen_overlay: ScreenOverlay
var start_menu: StartMenu
var loading_screen: LoadingScreen
var intro: IntroSequence
var objectives: ObjectiveTracker
var navigation_region: NavigationRegion3D
var is_navigation_ready := false
var enemies_defeated := 0
var elapsed_seconds := 0.0
var loaded_difficulty := ""
var needs_navigation_rebake := false
var result_shown_msec := 0


func _ready() -> void:
	InputActions.register()
	if not SaveData.has_loaded:
		SaveData.load_progress()
	AudioBank.preload_enemy_voices()
	level = LevelCatalog.create(current_level_number)
	loaded_difficulty = Difficulty.current
	if is_staged_loading_enabled:
		build_level_in_stages()
	else:
		build_level_now()


func build_level_now() -> void:
	create_lighting()
	build_static_world()
	spawn_actors()
	bake_navigation()
	choose_opening_screen()


func build_level_in_stages() -> void:
	loading_screen = LoadingScreen.new()
	add_child(loading_screen)
	loading_screen.setup(level.get_chapter_label())
	loading_screen.set_progress(0.05, "PREPARING")
	await get_tree().process_frame
	create_lighting()
	loading_screen.set_progress(0.15, "BUILDING THE WORLD")
	await get_tree().process_frame
	build_static_world()
	loading_screen.set_progress(0.6, "HIRING ENEMIES")
	await get_tree().process_frame
	spawn_actors()
	loading_screen.set_progress(0.75, "MAPPING ROUTES")
	await get_tree().process_frame
	bake_navigation()
	if not is_navigation_ready:
		await navigation_ready
	loading_screen.finish()
	choose_opening_screen()


func create_lighting() -> void:
	world_environment = create_world_environment()
	add_child(world_environment)
	sun = create_sun()
	add_child(sun)
	apply_graphics_settings()
	get_viewport().size_changed.connect(_on_viewport_resized)


func build_static_world() -> void:
	level.build_world(self)
	StaticBatcher.batch(self, get_batching_exclusions())


func spawn_actors() -> void:
	spawn_player()
	spawn_enemies()
	spawn_health_packs()
	spawn_hud()
	create_objectives()


func _exit_tree() -> void:
	LevelBuilder.material_cache.clear()
	Surfaces.material_cache.clear()


func get_batching_exclusions() -> Array[Node]:
	var excluded: Array[Node] = []
	for door: Node in level.doors.values():
		excluded.append(door)
	for child: Node in get_children():
		if child.get_script() != null:
			excluded.append(child)
	return excluded


func choose_opening_screen() -> void:
	if should_show_menu:
		show_menu()
	elif should_play_story:
		start_intro()
	else:
		show_ready()


func _unhandled_input(event: InputEvent) -> void:
	match state:
		GameState.INTRO, GameState.ENDING:
			handle_story_input(event)
		GameState.READY:
			if event.is_action_pressed("fire"):
				capture_mouse_and_play()
		GameState.PLAYING:
			handle_gameplay_input(event)
		GameState.WON:
			handle_won_input(event)
		GameState.LOST:
			handle_lost_input(event)
		GameState.FINISHED:
			handle_finished_input(event)


func handle_story_input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_intro"):
		intro.skip()
	elif event.is_action_pressed("fire") or event.is_action_pressed("jump"):
		intro.advance()


func handle_gameplay_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_level()
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("fire") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		capture_mouse_and_play()


func handle_won_input(event: InputEvent) -> void:
	if GameClock.get_msec() - result_shown_msec < RESULT_INPUT_DELAY_MSEC:
		return
	if event.is_action_pressed("restart"):
		restart_level()
	elif event.is_action_pressed("menu"):
		return_to_menu()
	elif event.is_action_pressed("fire") or event.is_action_pressed("skip_intro"):
		go_to_level(current_level_number + 1)


func handle_lost_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_level()
	elif event.is_action_pressed("menu"):
		return_to_menu()


func handle_finished_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		return_to_menu()
	elif event.is_action_pressed("skip_intro"):
		go_to_level(1)


func _physics_process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	elapsed_seconds += delta
	hud.set_boss_progress(objectives.get_boss_name(), objectives.get_boss_progress())
	if player.global_position.y < level.kill_height:
		lose_game(FALL_LOSS_HEADING, FALL_LOSS_BODY)


func create_world_environment() -> WorldEnvironment:
	var world_settings := Environment.new()
	world_settings.background_mode = Environment.BG_SKY
	world_settings.sky = create_sky()
	world_settings.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	world_settings.ambient_light_color = level.get_mood_value("ambient_color")
	world_settings.ambient_light_sky_contribution = 0.2
	world_settings.ambient_light_energy = level.get_mood_value("ambient_energy")
	world_settings.tonemap_mode = Environment.TONE_MAPPER_ACES
	world_settings.tonemap_white = 6.0
	world_settings.glow_enabled = true
	world_settings.glow_intensity = level.get_mood_value("glow_intensity")
	world_settings.glow_bloom = 0.05
	world_settings.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	world_settings.fog_enabled = true
	world_settings.fog_light_color = level.get_mood_value("fog_color")
	world_settings.fog_density = level.get_mood_value("fog_density")
	world_settings.fog_sky_affect = 0.1
	world_settings.adjustment_enabled = true
	world_settings.adjustment_contrast = level.get_mood_value("contrast")
	world_settings.adjustment_saturation = level.get_mood_value("saturation")
	var world_environment := WorldEnvironment.new()
	world_environment.environment = world_settings
	return world_environment


func create_sky() -> Sky:
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load(SKY_SHADER_PATH)
	sky_material.set_shader_parameter("panorama", load(SKY_TEXTURE_PATH))
	sky_material.set_shader_parameter("exposure", level.get_mood_value("sky_exposure"))
	sky_material.set_shader_parameter("shadow_color", level.get_mood_value("sky_shadow"))
	sky_material.set_shader_parameter("mid_color", level.get_mood_value("sky_mid"))
	sky_material.set_shader_parameter("highlight_color", level.get_mood_value("sky_highlight"))
	sky_material.set_shader_parameter("horizon_haze", level.get_mood_value("sky_haze"))
	var sky := Sky.new()
	sky.sky_material = sky_material
	return sky


func create_sun() -> DirectionalLight3D:
	var level_sun := DirectionalLight3D.new()
	level_sun.light_color = level.get_mood_value("sun_color")
	level_sun.light_energy = level.get_mood_value("sun_energy")
	level_sun.rotation_degrees = level.get_mood_value("sun_rotation")
	return level_sun


func apply_graphics_settings() -> void:
	GraphicsSettings.apply_to_viewport(get_viewport())
	world_environment.environment.glow_enabled = true
	GraphicsSettings.apply_to_environment(world_environment.environment)
	sun.shadow_enabled = level.get_mood_value("sun_shadows")
	GraphicsSettings.apply_to_sun(sun)


func spawn_player() -> void:
	player = Player.new()
	player.position = level.player_start
	player.rotation_degrees.y = level.player_yaw_degrees
	player.unlocked_weapon_count = level.weapon_count
	add_child(player)
	player.add_ambient_particles(level.get_mood_value("particles"))
	player.runway_changed.connect(_on_player_runway_changed)
	player.runway_restored.connect(_on_player_runway_restored)
	player.out_of_runway.connect(_on_player_out_of_runway)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.weapon_fired.connect(_on_player_weapon_fired)
	player.hit_registered.connect(_on_player_hit_registered)


func spawn_enemies() -> void:
	for spawn: Dictionary in level.enemies:
		spawn_enemy(spawn)


func spawn_enemy(spawn: Dictionary) -> Enemy:
	var type_id: String = spawn["type"]
	var enemy: Enemy = Boss.new() if EnemyTypes.is_boss(type_id) else Enemy.new()
	enemy.setup(type_id, player, spawn.get("health_scale", 1.0), spawn.get("display_name", ""))
	if enemy is Boss:
		(enemy as Boss).spawner = spawn_enemy
	enemy.position = spawn["position"]
	add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	return enemy


func spawn_health_packs() -> void:
	for pack_position: Vector3 in level.health_packs:
		HealthPack.spawn(self, pack_position)


func spawn_hud() -> void:
	screen_overlay = ScreenOverlay.new()
	add_child(screen_overlay)
	hud = Hud.new()
	add_child(hud)
	hud.set_chapter(level.get_chapter_label())


func create_objectives() -> void:
	objectives = ObjectiveTracker.new()
	objectives.name = "Objectives"
	add_child(objectives)
	objectives.setup(level, player, spawn_enemy, open_door)
	objectives.all_completed.connect(complete_level)
	objectives.failed.connect(lose_game)
	objectives.text_changed.connect(hud.set_objective)
	objectives.countdown_changed.connect(hud.set_countdown)


func open_door(door_name: String) -> void:
	if level.open_door(door_name):
		hud.show_toast("DOOR UNLOCKED", Hud.ACCENT_COLOR)
		request_navigation_rebake()


func request_navigation_rebake() -> void:
	if navigation_region.is_baking():
		needs_navigation_rebake = true
		return
	navigation_region.bake_navigation_mesh(true)


func bake_navigation() -> void:
	add_to_group(NAVIGATION_SOURCE_GROUP)
	navigation_region = NavigationRegion3D.new()
	navigation_region.navigation_mesh = create_navigation_mesh()
	add_child(navigation_region)
	navigation_region.bake_finished.connect(_on_navigation_baked, CONNECT_ONE_SHOT)
	navigation_region.bake_finished.connect(_on_any_navigation_bake_finished)
	navigation_region.bake_navigation_mesh(true)


func create_navigation_mesh() -> NavigationMesh:
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh.geometry_collision_mask = LevelBuilder.WORLD_LAYER
	navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	navigation_mesh.geometry_source_group_name = NAVIGATION_SOURCE_GROUP
	navigation_mesh.agent_radius = 0.5
	navigation_mesh.agent_height = 1.75
	navigation_mesh.agent_max_climb = 0.25
	navigation_mesh.agent_max_slope = 40.0
	navigation_mesh.cell_size = 0.25
	navigation_mesh.cell_height = 0.25
	navigation_mesh.filter_baking_aabb = level.navigation_bounds
	return navigation_mesh


func show_menu() -> void:
	state = GameState.MENU
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prepare_hud()
	hud.set_gameplay_visible(false)
	intro = create_intro()
	intro.show_menu_backdrop()
	start_menu = StartMenu.new()
	add_child(start_menu)
	start_menu.new_game_requested.connect(_on_new_game_requested)
	start_menu.level_requested.connect(go_to_level)
	start_menu.graphics_changed.connect(apply_graphics_settings)


func create_intro(story_path_override := "") -> IntroSequence:
	var intro_sequence := IntroSequence.new()
	intro_sequence.setup(hud, player, level, story_path_override)
	add_child(intro_sequence)
	intro_sequence.finished.connect(_on_intro_finished)
	return intro_sequence


func start_intro() -> void:
	state = GameState.INTRO
	close_start_menu()
	prepare_hud()
	if intro == null:
		intro = create_intro()
	intro.start()


func close_start_menu() -> void:
	if start_menu != null:
		start_menu.queue_free()
		start_menu = null


func show_ready() -> void:
	state = GameState.READY
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prepare_hud()
	hud.set_gameplay_visible(true)
	var body := "%s\n%s\n\n%s\n\nCLICK TO START" % [level.tagline, Difficulty.get_label(), CONTROLS_TEXT]
	hud.show_message(level.get_chapter_label(), body)
	player.camera.make_current()


func prepare_hud() -> void:
	hud.set_runway(player.runway_months, player.max_runway_months)
	hud.set_weapon(player.current_weapon_index, player.unlocked_weapon_count)


func capture_mouse_and_play() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.fire_cooldown_left = 0.3
	if state == GameState.READY:
		start_game()


func start_game() -> void:
	if intro != null:
		intro.dismiss()
	close_start_menu()
	state = GameState.PLAYING
	hud.hide_message()
	hud.hide_dialogue()
	hud.set_gameplay_visible(true)
	player.camera.make_current()
	player.controls_enabled = true
	objectives.start()
	hud.show_title_card("LEVEL %d" % level.number, level.title)
	announce_new_weapon()


func announce_new_weapon() -> void:
	if level.number <= 1:
		return
	var previous_count := LevelCatalog.create(level.number - 1).weapon_count
	if level.weapon_count > previous_count:
		var weapon := Weapons.get_weapon(level.weapon_count - 1)
		hud.show_toast("NEW WEAPON: %s  [%d]" % [weapon["name"], level.weapon_count])


func complete_level() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.WON
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	clear_combat_hud()
	level.on_completed(self, player)
	SaveData.unlock_level(mini(level.number + 1, LevelCatalog.get_count()))
	AudioBank.play_ui(self, AudioBank.WIN)
	result_shown_msec = GameClock.get_msec()
	if LevelCatalog.is_final_level(level.number):
		start_ending()
		return
	hud.show_message(level.win_heading, "%s\n\n%s\n\nClick or Enter: next level  |  R: replay  |  M: menu" % [level.win_body, get_stats_text()])


func get_stats_text() -> String:
	var minutes := int(elapsed_seconds) / 60
	var seconds := int(elapsed_seconds) % 60
	return "Time %d:%02d   |   Defeated %d   |   Runway left %d months   |   %s" % [minutes, seconds, enemies_defeated, player.runway_months, Difficulty.get_label()]


func start_ending() -> void:
	state = GameState.ENDING
	if intro != null:
		intro.queue_free()
	intro = create_intro(LevelCatalog.ENDING_STORY_PATH)
	intro.start()


func show_finished() -> void:
	state = GameState.FINISHED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_gameplay_visible(false)
	hud.show_message(FINISHED_HEADING, FINISHED_BODY % Difficulty.get_label())


func lose_game(heading: String, body: String) -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.LOST
	player.controls_enabled = false
	objectives.stop()
	level.on_failed()
	clear_combat_hud()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_message(heading, body + LOSS_FOOTER)
	AudioBank.play_ui(self, AudioBank.LOSE)


func clear_combat_hud() -> void:
	hud.set_countdown(-1.0)
	hud.set_objective("")
	hud.set_boss_progress("", -1.0)
	screen_overlay.set_danger(0.0)


func restart_level() -> void:
	should_show_menu = false
	should_play_story = false
	get_tree().reload_current_scene()


func go_to_level(level_number: int) -> void:
	current_level_number = clampi(level_number, 1, LevelCatalog.get_count())
	should_show_menu = false
	should_play_story = true
	get_tree().reload_current_scene()


func return_to_menu() -> void:
	current_level_number = 1
	should_show_menu = true
	should_play_story = true
	get_tree().reload_current_scene()


func get_state_name() -> String:
	return GameState.keys()[state]


func needs_rebuild_for_new_game() -> bool:
	return level.number != 1 or Difficulty.current != loaded_difficulty


func _on_viewport_resized() -> void:
	GraphicsSettings.apply_to_viewport(get_viewport())


func _on_new_game_requested() -> void:
	if needs_rebuild_for_new_game():
		go_to_level(1)
	else:
		start_intro()


func _on_intro_finished() -> void:
	if state == GameState.INTRO:
		show_ready()
	elif state == GameState.ENDING:
		show_finished()


func _on_any_navigation_bake_finished() -> void:
	if needs_navigation_rebake:
		needs_navigation_rebake = false
		navigation_region.bake_navigation_mesh(true)


func _on_navigation_baked() -> void:
	NavigationServer3D.map_changed.connect(_on_navigation_map_changed)


func _on_navigation_map_changed(map_rid: RID) -> void:
	if map_rid != get_world_3d().navigation_map:
		return
	NavigationServer3D.map_changed.disconnect(_on_navigation_map_changed)
	is_navigation_ready = true
	navigation_ready.emit()


func _on_enemy_defeated(_enemy: Enemy) -> void:
	enemies_defeated += 1


func _on_player_runway_changed(months: int, max_months: int) -> void:
	hud.set_runway(months, max_months)
	hud.flash_damage()
	update_danger(months, max_months)


func _on_player_runway_restored(months: int, max_months: int) -> void:
	hud.set_runway(months, max_months)
	hud.flash_heal()
	update_danger(months, max_months)


func update_danger(months: int, max_months: int) -> void:
	var is_low := hud.is_runway_low(months, max_months) and months > 0
	screen_overlay.set_danger(0.8 if is_low else 0.0)


func _on_player_out_of_runway() -> void:
	lose_game(RUNWAY_LOSS_HEADING, RUNWAY_LOSS_BODY)


func _on_player_weapon_changed(weapon_index: int) -> void:
	hud.set_weapon(weapon_index, player.unlocked_weapon_count)


func _on_player_weapon_fired() -> void:
	hud.kick_crosshair()


func _on_player_hit_registered(was_defeat: bool) -> void:
	hud.show_hit_marker(was_defeat)
