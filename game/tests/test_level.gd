extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_SCRIPT_PATH := "res://scripts/main.gd"
const SCREEN_SIZE := Vector2i(1280, 720)
const REQUIRED_PHRASES: Array[String] = ["Don't get left behind!", "You're not gonna make it!"]

var check_count := 0
var failures: Array[String] = []


func _initialize() -> void:
	SaveData.is_persistence_enabled = false
	load("res://scripts/main.gd").is_staged_loading_enabled = false
	Difficulty.set_current(Difficulty.NORMAL)
	GraphicsSettings.set_current(GraphicsSettings.HIGH)
	run_all_tests()


func run_all_tests() -> void:
	await test_level_contains_every_enemy_type()
	await test_enemies_yell_the_required_phrases()
	await test_defeated_enemy_leaves_without_dying()
	await test_confetti_cannon_fires_a_spread()
	await test_running_out_of_runway_loses()
	await test_ladder_timer_expiring_loses()
	await test_grabbing_the_ladder_wins()
	await test_route_from_lobby_to_ladder_is_walkable()
	await test_start_menu_intro_and_ready_flow()
	await test_intro_lines_have_voice_over()
	await test_navigation_connects_street_to_roof()
	await test_engaging_enemy_alerts_neighbours()
	await test_founder_closes_distance()
	await test_vc_backs_off_when_crowded()
	test_ranged_aim_leads_a_moving_target()
	await test_menu_and_intro_respond_to_real_input()
	await test_slop_grenade_wrecks_nearby_enemies_and_showers_rust_code()
	await test_thrown_slop_grenade_explodes_after_its_fuse()
	await test_health_pack_restores_runway()
	await test_early_enemies_are_easier_to_defeat()
	await test_enemies_shout_when_hit()
	await test_difficulty_scales_enemies_and_player()
	await test_locked_weapons_cannot_be_selected()
	await test_nda_stapler_stuns_an_enemy()
	await test_hype_railgun_pierces_a_line_of_enemies()
	await test_valuation_bubble_pops_with_splash_damage()
	await test_disruptor_chains_between_enemies()
	await test_shots_leave_from_the_barrel_tip()
	await test_beams_start_at_the_barrel()
	await test_weapons_hit_what_the_crosshair_is_on()
	await test_thrown_grenade_leaves_the_hand()
	await test_point_blank_shot_stays_on_this_side_of_a_wall()
	await test_destroy_stage_opens_the_door_and_exit_wins()
	await test_survive_stage_opens_the_elevator()
	await test_timed_reach_fails_when_the_clock_runs_out()
	await test_boss_enrages_and_final_boss_plays_the_ending()
	test_going_to_the_next_level_updates_progress()
	test_every_story_line_has_a_voice_clip()
	test_every_voice_clip_uses_a_listed_voice()
	await test_menu_difficulty_change_rebuilds_the_level()
	await test_level_select_requests_the_chosen_level()
	await test_board_bosses_can_be_beaten_one_at_a_time()
	await test_destroy_stage_survives_freed_targets()
	await test_graphics_presets_apply_to_the_renderer()
	await test_menu_graphics_and_fps_toggles()
	await test_staged_loading_shows_progress_then_the_menu()
	await test_loading_screen_scrolls_tips()
	report_and_quit()


func test_level_contains_every_enemy_type() -> void:
	var main = await load_main()
	var found_types := {}
	for enemy: Enemy in find_enemies(main):
		found_types[enemy.type_id] = true
	for type_id: String in [EnemyTypes.VC, EnemyTypes.FOUNDER, EnemyTypes.LAB_BOT]:
		check(found_types.has(type_id), "level spawns a '%s'" % type_id)
	await unload_main(main)


func test_enemies_yell_the_required_phrases() -> void:
	for phrase: String in REQUIRED_PHRASES:
		check(Enemy.YELL_LINES.has(phrase), "enemy yell lines include \"%s\"" % phrase)
	for voice: String in AudioBank.VOICES:
		var line_ids: Array = AudioBank.YELL_LINE_IDS + AudioBank.DEFEAT_LINE_IDS + AudioBank.HURT_LINE_IDS + AudioBank.SLOP_LINE_IDS + AudioBank.STUN_LINE_IDS
		var missing := line_ids.filter(func(line_id: String) -> bool: return not ResourceLoader.exists(AudioBank.get_voice_clip_path(voice, line_id)))
		check(missing.is_empty(), "voice '%s' has every yell, hurt, slop and exit clip" % voice)
	var main = await load_main()
	var enemy: Enemy = find_enemies(main)[0]
	Enemy.last_yell_msec = -100000
	enemy.yell()
	check(enemy.bubble.visible and REQUIRED_PHRASES.has(enemy.bubble.text), "a yelling enemy shows a required phrase")
	await unload_main(main)


func test_defeated_enemy_leaves_without_dying() -> void:
	var main = await load_main()
	var enemy: Enemy = find_enemies(main)[0]
	enemy.take_damage(1000)
	check(enemy.state == Enemy.State.DEFEATED, "enemy is defeated after enough damage")
	check(enemy.bubble.text == enemy.config["defeat_line"], "defeated enemy says its exit line")
	await create_timer(3.4).timeout
	check(not is_instance_valid(enemy), "defeated enemy leaves the level")
	await unload_main(main)


func test_confetti_cannon_fires_a_spread() -> void:
	var main = await load_main()
	var player: Player = main.player
	var projectiles_before := count_projectiles(main)
	player.select_weapon(1)
	player.fire_weapon()
	var expected_pellets: int = Weapons.ALL[1]["pellets"]
	check(count_projectiles(main) - projectiles_before == expected_pellets, "confetti cannon fires %d pellets" % expected_pellets)
	await unload_main(main)


func test_running_out_of_runway_loses() -> void:
	var main = await load_main()
	main.start_game()
	main.player.take_damage(main.player.max_runway_months)
	check(main.get_state_name() == "LOST", "running out of runway loses the level")
	await unload_main(main)


func test_ladder_timer_expiring_loses() -> void:
	var main = await load_main()
	main.start_game()
	var ladder: LadderStage = main.objectives.current_stage
	ladder.start_ladder_timer()
	ladder.update_ladder_timer(1000.0)
	check(main.get_state_name() == "LOST", "the ladder timer running out loses the level")
	await unload_main(main)


func test_grabbing_the_ladder_wins() -> void:
	var main = await load_main()
	main.start_game()
	main.objectives.current_stage.start_ladder_timer()
	main.player.global_position = main.level.helicopter.get_ladder_bottom_position() + Vector3(0, -0.5, 0)
	for frame_index: int in 5:
		await physics_frame
	check(main.get_state_name() == "WON", "touching the ladder before time runs out wins")
	await unload_main(main)


func test_route_from_lobby_to_ladder_is_walkable() -> void:
	var main = await load_main()
	for enemy: Enemy in find_enemies(main):
		enemy.queue_free()
	main.start_game()
	var player: Player = main.player
	player.global_position = Vector3(11, 0.1, -83)
	await walk_player_to(player, Vector3(11, 0, -101), 8.0)
	check(player.global_position.y > LevelBuilder.MEZZANINE_HEIGHT - 0.3, "ramp A reaches the mezzanine")
	await walk_player_to(player, Vector3(-10.75, 0, -101.2), 8.0)
	await walk_player_to(player, Vector3(-10.75, 0, -118.7), 8.0)
	check(player.global_position.y > LevelBuilder.ROOF_HEIGHT - 0.3, "ramp B reaches the roof")
	check(main.objectives.current_stage.is_timer_running, "reaching the roof starts the ladder timer")
	await walk_player_to(player, Vector3(-6, 0, -118.8), 4.0)
	await walk_player_to(player, Vector3(0, 0, -116), 4.0)
	var ladder_bottom: Vector3 = main.level.helicopter.get_ladder_bottom_position()
	await walk_player_to(player, ladder_bottom, 8.0)
	check(main.get_state_name() == "WON", "walking from the landing to the ladder wins")
	await unload_main(main)


func test_start_menu_intro_and_ready_flow() -> void:
	var main = await load_main()
	check(main.get_state_name() == "MENU" and main.start_menu != null, "the game opens on the start menu")
	main.start_intro()
	await process_frame
	check(main.get_state_name() == "INTRO" and main.hud.is_dialogue_visible(), "START plays the intro with dialogue on screen")
	check(main.intro.voice_player.playing, "the intro plays a voice-over")
	main.intro.skip()
	check(main.get_state_name() == "READY", "skipping the intro goes to the ready screen")
	main.start_game()
	check(main.get_state_name() == "PLAYING" and main.player.controls_enabled, "clicking from the ready screen starts play")
	await unload_main(main)


func test_intro_lines_have_voice_over() -> void:
	var level := LevelCatalog.create(1)
	var lines: Array = IntroSequence.load_json(level.story_path)["lines"]
	var cast := IntroSequence.load_json(IntroSequence.CAST_PATH)
	check(lines.size() >= 5, "the intro script tells the story in %d lines" % lines.size())
	var missing := lines.filter(func(line: Dictionary) -> bool: return not ResourceLoader.exists(AudioBank.get_story_clip_path(IntroSequence.get_line_voice(cast, line), line["id"])))
	check(missing.is_empty(), "every intro line has a voice-over clip")
	var shots := lines.map(func(line: Dictionary) -> String: return line["shot"])
	var unknown_shots := shots.filter(func(shot: String) -> bool: return shot != IntroSequence.PLAYER_SHOT and not level.shots.has(shot))
	check(unknown_shots.is_empty(), "every intro line uses a known camera shot")


func test_navigation_connects_street_to_roof() -> void:
	var main = await load_main()
	await wait_for_navigation(main)
	var map_rid: RID = main.get_world_3d().navigation_map
	var destination := Vector3(5, LevelBuilder.ROOF_HEIGHT, -96)
	var path := NavigationServer3D.map_get_path(map_rid, Vector3(0, 0, -20), destination, true)
	var path_end: Vector3 = path[path.size() - 1] if not path.is_empty() else Vector3.INF
	var reaches_roof := path_end.distance_to(destination) < 1.5
	check(reaches_roof, "enemy navigation connects the street to the roof via the ramps (%d points, ends %s)" % [path.size(), path_end])
	await unload_main(main)


func test_engaging_enemy_alerts_neighbours() -> void:
	var main = await load_main()
	main.start_game()
	var enemies := find_enemies(main)
	var first_enemy: Enemy = enemies[0]
	first_enemy.engage()
	var alerted := enemies.filter(func(enemy: Enemy) -> bool: return enemy != first_enemy and enemy.state == Enemy.State.ENGAGED)
	var far_idle := enemies.filter(func(enemy: Enemy) -> bool: return enemy.global_position.distance_to(first_enemy.global_position) > Enemy.ALERT_RADIUS + 1.0 and enemy.state == Enemy.State.IDLE)
	check(not alerted.is_empty(), "an enemy that spots you alerts nearby enemies")
	check(not far_idle.is_empty(), "enemies far away stay unaware")
	await unload_main(main)


func test_founder_closes_distance() -> void:
	var main = await load_main()
	await wait_for_navigation(main)
	main.start_game()
	main.player.runway_months = 9999
	var founder := find_first_enemy_of_type(main, EnemyTypes.FOUNDER)
	main.player.global_position = founder.global_position + Vector3(0, 0, 9)
	var start_distance := founder.global_position.distance_to(main.player.global_position)
	await wait_physics_seconds(2.0)
	var end_distance := founder.global_position.distance_to(main.player.global_position)
	check(end_distance < start_distance - 3.0, "AI founders rush the player (%.1f m -> %.1f m)" % [start_distance, end_distance])
	await unload_main(main)


func test_vc_backs_off_when_crowded() -> void:
	var main = await load_main()
	await wait_for_navigation(main)
	main.start_game()
	main.player.runway_months = 9999
	var vc := find_first_enemy_of_type(main, EnemyTypes.VC)
	main.player.global_position = vc.global_position + Vector3(0, 0, 3)
	var start_distance := vc.global_position.distance_to(main.player.global_position)
	await wait_physics_seconds(2.0)
	var end_distance := vc.global_position.distance_to(main.player.global_position)
	check(end_distance > start_distance + 1.5, "VCs back off to throwing range (%.1f m -> %.1f m)" % [start_distance, end_distance])
	await unload_main(main)


func test_ranged_aim_leads_a_moving_target() -> void:
	var origin := Vector3.ZERO
	var target_point := Vector3(0, 0, -20)
	var predicted := EnemyAim.predict_intercept(origin, target_point, Vector3(6, 0, 0), 15.0)
	check(predicted.x > 3.0, "ranged enemies aim ahead of a moving player (lead %.1f m)" % predicted.x)


func test_menu_and_intro_respond_to_real_input() -> void:
	set_main_flags(1, true, true)
	var screen := SubViewport.new()
	screen.size = SCREEN_SIZE
	root.add_child(screen)
	var main = load(MAIN_SCENE_PATH).instantiate()
	screen.add_child(main)
	await process_frame
	var start_button := find_button(main.start_menu, "START")
	await click_at(screen, start_button.get_global_rect().get_center())
	check(main.get_state_name() == "INTRO", "clicking the START button with the mouse starts the intro")
	var first_line: int = main.intro.line_index
	await press_key(screen, KEY_SPACE)
	check(main.intro.line_index == first_line + 1, "pressing Space advances the intro")
	await press_key(screen, KEY_ENTER)
	check(main.get_state_name() == "READY", "pressing Enter skips the intro")
	await click_at(screen, Vector2(SCREEN_SIZE) / 2.0)
	check(main.get_state_name() == "PLAYING", "clicking on the ready screen starts play")
	screen.queue_free()
	await process_frame


func test_slop_grenade_wrecks_nearby_enemies_and_showers_rust_code() -> void:
	var main = await load_main()
	main.start_game()
	var enemies := find_enemies(main)
	var target: Enemy = enemies[0]
	var far_enemy: Enemy = enemies[enemies.size() - 1]
	var grenade := SlopGrenade.spawn(main, target.global_position + Vector3(1.0, 0.5, 0.0), Vector3.ZERO, main.player)
	grenade.explode()
	check(target.state == Enemy.State.DEFEATED and target.is_slopped, "a slop grenade wrecks an enemy caught in the blast")
	check(Enemy.SLOP_LINES.has(target.bubble.text), "a wrecked enemy complains about the code (\"%s\")" % target.bubble.text)
	check(far_enemy.state != Enemy.State.DEFEATED, "enemies outside the blast are unharmed")
	var code_lines := find_children_of_type(main, RustSlop)
	check(code_lines.size() == SlopGrenade.CODE_LINE_COUNT, "the blast showers %d lines of Rust code" % code_lines.size())
	var readable := code_lines.filter(func(line: RustSlop) -> bool: return line.text != "" and line.billboard == BaseMaterial3D.BILLBOARD_ENABLED)
	check(readable.size() == code_lines.size(), "every code line is a camera-facing label")
	await wait_physics_seconds(3.0)
	var landed := code_lines.filter(func(line: RustSlop) -> bool: return is_instance_valid(line) and line.has_landed)
	check(landed.size() == code_lines.size(), "the code lines land and stay on screen (%d of %d)" % [landed.size(), code_lines.size()])
	await unload_main(main)


func test_thrown_slop_grenade_explodes_after_its_fuse() -> void:
	var main = await load_main()
	remove_all_enemies(main)
	main.start_game()
	var player: Player = main.player
	player.select_weapon(2)
	check(main.hud.weapon_label.text.begins_with("SLOP GRENADE"), "weapon 3 is the slop grenade")
	player.fire_weapon()
	var grenades := find_children_of_type(main, SlopGrenade)
	check(grenades.size() == 1, "firing the slop grenade throws one grenade")
	await wait_physics_seconds(SlopGrenade.FUSE_SECONDS + 0.3)
	check(not grenades.is_empty() and not is_instance_valid(grenades[0]), "the thrown grenade explodes when its fuse runs out")
	check(not find_children_of_type(main, RustSlop).is_empty(), "the thrown grenade showers Rust code")
	await unload_main(main)


func test_health_pack_restores_runway() -> void:
	var main = await load_main()
	remove_all_enemies(main)
	main.start_game()
	var player: Player = main.player
	var packs := find_children_of_type(main, HealthPack)
	check(packs.size() == main.level.health_packs.size(), "the level has %d health packs" % packs.size())
	var pack: HealthPack = packs[0]
	var pack_months := pack.runway_months
	player.global_position = pack.global_position + Vector3(0, 0.1, 0)
	await wait_physics_seconds(0.3)
	check(is_instance_valid(pack), "a health pack is left alone while runway is full")
	player.take_damage(10)
	await wait_physics_seconds(0.3)
	var expected_months := player.max_runway_months - 10 + pack_months
	check(player.runway_months == expected_months, "a health pack restores runway (%d -> %d months)" % [player.max_runway_months - 10, player.runway_months])
	check(not is_instance_valid(pack), "a used health pack disappears")
	await unload_main(main)


func test_early_enemies_are_easier_to_defeat() -> void:
	var main = await load_main()
	var enemies := find_enemies(main)
	var first_enemy: Enemy = enemies[0]
	var dart_damage: int = Weapons.ALL[0]["damage"]
	check(first_enemy.health <= dart_damage * 2, "the first street enemy drops in two dart hits (%d health, %d per dart)" % [first_enemy.health, dart_damage])
	var roof_enemy: Enemy = enemies[enemies.size() - 1]
	var full_health: int = roof_enemy.config["health"]
	check(roof_enemy.health == full_health, "enemies on the roof keep full health (%d)" % roof_enemy.health)
	await unload_main(main)


func test_enemies_shout_when_hit() -> void:
	var main = await load_main()
	main.start_game()
	var enemy := find_first_enemy_of_type(main, EnemyTypes.LAB_BOT)
	enemy.engage_silently()
	for attempt_index: int in 20:
		Enemy.last_yell_msec = -100000
		enemy.hurt_cooldown_left = 0.0
		enemy.take_damage(1)
		if Enemy.HURT_LINES.has(enemy.bubble.text):
			break
	check(Enemy.HURT_LINES.has(enemy.bubble.text), "enemies shout when they get hit (\"%s\")" % enemy.bubble.text)
	await unload_main(main)


func remove_all_enemies(main: Node) -> void:
	for enemy: Enemy in find_enemies(main):
		enemy.queue_free()


func find_children_of_type(main: Node, type: Variant) -> Array:
	return main.get_children().filter(func(child: Node) -> bool: return is_instance_of(child, type))


func find_button(root_node: Node, text: String) -> Button:
	for button: Button in root_node.find_children("*", "Button", true, false):
		if button.text == text:
			return button
	return null


func press_key(screen: SubViewport, keycode: Key) -> void:
	for is_pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		event.pressed = is_pressed
		screen.push_input(event)
	await process_frame


func click_at(screen: SubViewport, screen_position: Vector2) -> void:
	for is_pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = screen_position
		event.global_position = screen_position
		event.pressed = is_pressed
		screen.push_input(event)
	await process_frame


func find_first_enemy_of_type(main: Node, type_id: String) -> Enemy:
	for enemy: Enemy in find_enemies(main):
		if enemy.type_id == type_id:
			return enemy
	return null


func wait_for_navigation(main: Node) -> void:
	while not main.is_navigation_ready:
		await process_frame


func wait_physics_seconds(seconds: float) -> void:
	for frame_index: int in int(seconds * Engine.physics_ticks_per_second):
		await physics_frame


func walk_player_to(player: Player, target: Vector3, max_seconds: float) -> void:
	Input.action_press("move_forward")
	var elapsed := 0.0
	while elapsed < max_seconds and player.controls_enabled:
		var offset := target - player.global_position
		offset.y = 0.0
		if offset.length() < 0.5:
			break
		player.rotation.y = atan2(-offset.x, -offset.z)
		await physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
	Input.action_release("move_forward")


func set_main_flags(level_number: int, show_menu: bool, play_story: bool) -> void:
	var main_script = load(MAIN_SCRIPT_PATH)
	main_script.current_level_number = level_number
	main_script.should_show_menu = show_menu
	main_script.should_play_story = play_story


func load_level(level_number: int) -> Node:
	set_main_flags(level_number, false, false)
	var main: Node = load(MAIN_SCENE_PATH).instantiate()
	root.add_child(main)
	await process_frame
	return main


func load_main() -> Node:
	set_main_flags(1, true, true)
	var main: Node = load(MAIN_SCENE_PATH).instantiate()
	root.add_child(main)
	await process_frame
	return main


func unload_main(main: Node) -> void:
	main.queue_free()
	await process_frame


func find_enemies(main: Node) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child: Node in main.get_children():
		if child is Enemy:
			enemies.append(child)
	return enemies


func count_projectiles(main: Node) -> int:
	var count := 0
	for child: Node in main.get_children():
		if child is Projectile:
			count += 1
	return count


func check(condition: bool, description: String) -> void:
	check_count += 1
	if condition:
		print("PASS  " + description)
		return
	failures.append(description)
	printerr("FAIL  " + description)


func report_and_quit() -> void:
	print("%d checks, %d failed" % [check_count, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func test_difficulty_scales_enemies_and_player() -> void:
	var hit_damage: Array[int] = []
	for difficulty_id: String in Difficulty.ORDER:
		Difficulty.set_current(difficulty_id)
		hit_damage.append(Difficulty.scale_damage(2))
		var main = await load_main()
		var player: Player = main.player
		var first_enemy: Enemy = find_enemies(main)[0]
		var base_health: int = first_enemy.config["health"]
		var expected_health := maxi(1, roundi(base_health * Level01SouthOfMarket.EARLY_HEALTH_SCALE * Difficulty.get_value("enemy_health")))
		check(first_enemy.max_health == expected_health, "%s: the first enemy has %d health" % [difficulty_id, first_enemy.max_health])
		check(player.max_runway_months == Difficulty.get_player_runway(), "%s: the player starts with %d months of runway" % [difficulty_id, player.max_runway_months])
		var pack: HealthPack = find_children_of_type(main, HealthPack)[0]
		check(pack.runway_months == Difficulty.get_health_pack_months(), "%s: bridge rounds restore %d months" % [difficulty_id, pack.runway_months])
		await unload_main(main)
	Difficulty.set_current(Difficulty.NORMAL)
	check(hit_damage == [1, 2, 3, 4], "enemy hits get harder with each difficulty (%s)" % [hit_damage])
	var countdowns: Array[float] = []
	for difficulty_id: String in Difficulty.ORDER:
		countdowns.append(Difficulty.PRESETS[difficulty_id]["countdown_time"])
	check(countdowns[0] > countdowns[1] and countdowns[1] > countdowns[2] and countdowns[2] > countdowns[3], "timers get shorter with each difficulty")


func test_locked_weapons_cannot_be_selected() -> void:
	var main = await load_main()
	main.start_game()
	var player: Player = main.player
	player.select_weapon(5)
	check(player.current_weapon_index == 0, "weapon 6 is locked on level 1")
	check(main.hud.weapon_slots[5].modulate.a < 0.5, "locked weapon slots are dimmed on the HUD")
	player.unlocked_weapon_count = Weapons.ALL.size()
	player.select_weapon(5)
	check(player.current_weapon_index == 5 and main.hud.weapon_label.text == "VALUATION BUBBLE", "an unlocked weapon can be selected")
	await unload_main(main)


func test_nda_stapler_stuns_an_enemy() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	var enemy := spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(0, 0.1, -4))
	await wait_physics_seconds(0.1)
	enemy.set_physics_process(false)
	player.select_weapon(3)
	player.fire_weapon()
	await wait_physics_seconds(0.4)
	check(enemy.is_stunned() and enemy.bubble.text == Enemy.STUN_BUBBLE, "the NDA stapler stuns an enemy and redacts its speech")
	check(enemy.health < enemy.max_health, "the NDA stapler also does a little damage")
	await unload_main(main)


func test_hype_railgun_pierces_a_line_of_enemies() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	var near_enemy := spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(0, 0.1, -2))
	var far_enemy := spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(0, 0.1, -9))
	await wait_physics_seconds(0.1)
	player.select_weapon(4)
	player.fire_weapon()
	check(near_enemy.health < near_enemy.max_health and far_enemy.health < far_enemy.max_health, "the hype railgun pierces both enemies in a line")
	await unload_main(main)


func test_valuation_bubble_pops_with_splash_damage() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	var target := spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(0, 0.1, -5))
	var neighbour := spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(2.2, 0.1, -5.5))
	await wait_physics_seconds(0.1)
	target.set_physics_process(false)
	neighbour.set_physics_process(false)
	player.select_weapon(5)
	player.fire_weapon()
	check(not find_children_of_type(main, ValuationBubble).is_empty(), "the valuation bubble gun launches a bubble")
	await wait_physics_seconds(1.6)
	check(target.health < target.max_health and neighbour.health < neighbour.max_health, "the bubble pops and splashes nearby enemies")
	await unload_main(main)


func test_disruptor_chains_between_enemies() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	var enemies: Array[Enemy] = [
		spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(0, 0.1, -4)),
		spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(4, 0.1, -6)),
		spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(-4, 0.1, -7)),
	]
	await wait_physics_seconds(0.1)
	player.select_weapon(6)
	player.fire_weapon()
	var damaged := enemies.filter(func(enemy: Enemy) -> bool: return enemy.health < enemy.max_health)
	check(damaged.size() == 3, "the disruptor arcs through all three enemies (%d hit)" % damaged.size())
	await unload_main(main)


func test_shots_leave_from_the_barrel_tip() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	for weapon_index: int in [0, 1, 2, 3, 5]:
		player.select_weapon(weapon_index)
		await process_frame
		var bounds := Models.get_world_bounds(player.weapon_model).grow(0.02)
		var shots_before := get_shot_nodes(main)
		player.fire_cooldown_left = 0.0
		player.fire_weapon()
		var new_shots := get_shot_nodes(main).filter(func(shot: Node3D) -> bool: return not shots_before.has(shot))
		var from_barrel := new_shots.all(func(shot: Node3D) -> bool: return is_at_gun_front(shot.global_position, bounds))
		check(not new_shots.is_empty() and from_barrel, "%s shots leave from the front of the gun model" % Weapons.get_weapon(weapon_index)["name"])
	await unload_main(main)


func get_shot_nodes(main: Node) -> Array:
	return main.get_children().filter(func(child: Node) -> bool: return child is Projectile or child is SlopGrenade or child is ValuationBubble)


func is_at_gun_front(point: Vector3, gun_bounds: AABB) -> bool:
	return gun_bounds.has_point(point) and point.z <= gun_bounds.position.z + 0.04


func test_beams_start_at_the_barrel() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	spawn_test_enemy(main, EnemyTypes.LAB_BOT, Vector3(0, 0.1, -8))
	await wait_physics_seconds(0.1)
	for weapon_index: int in [4, 6]:
		player.select_weapon(weapon_index)
		await process_frame
		var muzzle := player.get_muzzle_position()
		player.fire_cooldown_left = 0.0
		player.fire_weapon()
		var nearest := INF
		for segment: MeshInstance3D in find_children_of_type(main, MeshInstance3D):
			var box := segment.mesh as BoxMesh
			if box != null:
				nearest = minf(nearest, get_segment_start(segment, box).distance_to(muzzle))
		check(nearest < 0.05, "the %s beam starts at the barrel (%.2f m away)" % [Weapons.get_weapon(weapon_index)["name"], nearest])
		await wait_physics_seconds(0.7)
	await unload_main(main)


func get_segment_start(segment: MeshInstance3D, box: BoxMesh) -> Vector3:
	return segment.global_position + segment.global_transform.basis.z.normalized() * box.size.z * 0.5


func test_weapons_hit_what_the_crosshair_is_on() -> void:
	var ranges := {0: 30.0, 1: 8.0, 3: 30.0, 4: 30.0, 5: 12.0, 6: 25.0}
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	for weapon_index: int in ranges:
		var enemy: Enemy = main.spawn_enemy({"type": EnemyTypes.LAB_BOT, "position": Vector3(0, 0.1, 4.0 - ranges[weapon_index]), "health_scale": 20.0})
		await wait_physics_seconds(0.1)
		enemy.set_physics_process(false)
		aim_player_at(player, enemy.global_position + Vector3.UP * 1.1)
		player.select_weapon(weapon_index)
		player.fire_cooldown_left = 0.0
		player.fire_weapon()
		await wait_physics_seconds(1.9)
		check(enemy.health < enemy.max_health, "the %s hits an enemy %.0f m away under the crosshair" % [Weapons.get_weapon(weapon_index)["name"], ranges[weapon_index]])
		enemy.queue_free()
		await wait_physics_seconds(0.1)
	await unload_main(main)


func aim_player_at(player: Player, point: Vector3) -> void:
	var direction := point - player.camera.global_position
	player.rotation.y = atan2(-direction.x, -direction.z)
	player.head.rotation.x = atan2(direction.y, Vector2(direction.x, direction.z).length())


func test_thrown_grenade_leaves_the_hand() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	player.select_weapon(2)
	await process_frame
	check(player.weapon_model.visible, "the slop grenade is held before it is thrown")
	player.fire_weapon()
	await process_frame
	check(not player.weapon_model.visible, "the held grenade leaves the hand when thrown")
	await wait_physics_seconds(Weapons.ALL[2]["cooldown"])
	await process_frame
	check(player.weapon_model.visible, "a new grenade is in hand once the throw cools down")
	await unload_main(main)


func test_point_blank_shot_stays_on_this_side_of_a_wall() -> void:
	var main = await load_main()
	var player := await prepare_weapon_range(main)
	var wall_z := player.camera.global_position.z - 0.35
	LevelBuilder.add_collider(main, Vector3(6, 6, 0.2), Vector3(0, 2, wall_z - 0.1))
	await wait_physics_seconds(0.1)
	check(player.get_muzzle_position().z > wall_z, "a shot fired into a wall at point blank starts on the player's side")
	await unload_main(main)


func test_destroy_stage_opens_the_door_and_exit_wins() -> void:
	var main = await load_level(2)
	remove_all_enemies(main)
	main.start_game()
	await wait_physics_seconds(0.1)
	var stage := main.objectives.current_stage as DestroyStage
	check(stage != null and stage.targets.size() == 3, "level 2 opens with three terminals to smash")
	check(main.level.doors.has("dock"), "the loading dock starts locked")
	for target: DestructibleTarget in stage.get_remaining_targets():
		target.take_damage(100000)
	await wait_physics_seconds(0.2)
	check(not main.level.doors.has("dock"), "smashing every terminal unlocks the loading dock")
	var reach := main.objectives.current_stage as ReachStage
	check(reach != null, "the next objective is to reach the dock")
	main.player.global_position = reach.config["position"] + Vector3(0, 0.2, 0)
	await wait_physics_seconds(0.3)
	check(main.get_state_name() == "WON", "reaching the dock completes level 2")
	check(SaveData.highest_unlocked_level >= 3, "completing level 2 unlocks level 3")
	await unload_main(main)


func test_survive_stage_opens_the_elevator() -> void:
	var main = await load_level(9)
	remove_all_enemies(main)
	main.start_game()
	main.player.runway_months = 9999
	await wait_physics_seconds(0.1)
	var first_stage := main.objectives.current_stage as ReachStage
	main.player.global_position = first_stage.config["position"] + Vector3(0, 0.2, 0)
	await wait_physics_seconds(0.3)
	var survive := main.objectives.current_stage as SurviveStage
	check(survive != null, "reaching launch control starts the hold-out")
	check(not find_enemies(main).is_empty(), "the hold-out sends a wave of enemies")
	survive.time_left = 0.05
	await wait_physics_seconds(0.3)
	check(not main.level.doors.has("tower_elevator"), "surviving the hold-out unlocks the tower elevator")
	check(main.objectives.current_stage is ReachStage, "the next objective is the elevator")
	await unload_main(main)


func test_timed_reach_fails_when_the_clock_runs_out() -> void:
	var main = await load_level(3)
	remove_all_enemies(main)
	main.start_game()
	await wait_physics_seconds(0.1)
	main.player.global_position = main.objectives.current_stage.config["position"] + Vector3(0, 0.2, 0)
	await wait_physics_seconds(0.3)
	var timed := main.objectives.current_stage as ReachStage
	check(timed != null and timed.time_left > 0.0, "passing the toll plaza starts the train countdown")
	timed.time_left = 0.02
	await wait_physics_seconds(0.2)
	check(main.get_state_name() == "LOST" and main.hud.message_heading.text == "YOU MISSED THE TRAIN.", "missing the train loses the level")
	await unload_main(main)


func test_boss_enrages_and_final_boss_plays_the_ending() -> void:
	var main = await load_level(11)
	remove_all_enemies(main)
	main.start_game()
	main.player.runway_months = 9999
	await wait_physics_seconds(0.1)
	main.player.global_position = main.objectives.current_stage.config["position"] + Vector3(0, 0.2, 0)
	await wait_physics_seconds(0.3)
	var boss_stage := main.objectives.current_stage as BossStage
	check(boss_stage != null and boss_stage.bosses.size() == 1, "the launch pad spawns Exitwell's exosuit")
	var boss: Boss = boss_stage.bosses[0]
	check(is_equal_approx(main.objectives.get_boss_progress(), 1.0), "the boss bar starts full")
	await wait_physics_seconds(0.1)
	check(main.hud.boss_panel.visible, "the boss health bar is on screen")
	boss.take_damage(boss.max_health / 2 + 1)
	check(boss.is_enraged, "the exosuit enrages below half health")
	boss.take_damage(boss.max_health)
	await wait_physics_seconds(0.2)
	check(main.get_state_name() == "ENDING" and main.hud.is_dialogue_visible(), "defeating the final boss plays the ending story")
	main.intro.skip()
	check(main.get_state_name() == "FINISHED", "skipping the ending shows the finale screen")
	await unload_main(main)


func test_going_to_the_next_level_updates_progress() -> void:
	check(LevelCatalog.get_count() == 11, "the campaign has eleven levels")
	for level_number: int in range(1, LevelCatalog.get_count() + 1):
		var level := LevelCatalog.create(level_number)
		check(level.number == level_number, "level script %d reports number %d" % [level_number, level.number])
	check(LevelCatalog.is_final_level(11) and not LevelCatalog.is_final_level(10), "level 11 is the finale")
	var weapon_counts: Array[int] = []
	for level_number: int in range(1, LevelCatalog.get_count() + 1):
		weapon_counts.append(LevelCatalog.create(level_number).weapon_count)
	var is_non_decreasing := true
	for index: int in range(1, weapon_counts.size()):
		is_non_decreasing = is_non_decreasing and weapon_counts[index] >= weapon_counts[index - 1]
	check(is_non_decreasing and weapon_counts[0] == 3 and weapon_counts[-1] == Weapons.ALL.size(), "weapons unlock as the story goes (%s)" % [weapon_counts])


func test_every_story_line_has_a_voice_clip() -> void:
	var cast := IntroSequence.load_json(IntroSequence.CAST_PATH)
	var missing: Array[String] = []
	var line_count := 0
	for file_name: String in DirAccess.get_files_at("res://data/story"):
		if not file_name.ends_with(".json") or file_name == "cast.json":
			continue
		for line: Dictionary in IntroSequence.load_json("res://data/story/" + file_name)["lines"]:
			line_count += 1
			if not ResourceLoader.exists(AudioBank.get_story_clip_path(IntroSequence.get_line_voice(cast, line), line["id"])):
				missing.append(line["id"])
	check(line_count >= 40 and missing.is_empty(), "all %d story lines have voice-over (missing %s)" % [line_count, missing])


func prepare_weapon_range(main: Node) -> Player:
	remove_all_enemies(main)
	main.start_game()
	var player: Player = main.player
	player.unlocked_weapon_count = Weapons.ALL.size()
	player.runway_months = 9999
	player.global_position = Vector3(0, 0.1, 4)
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	await wait_physics_seconds(0.1)
	return player


func spawn_test_enemy(main: Node, type_id: String, position: Vector3) -> Enemy:
	return main.spawn_enemy({"type": type_id, "position": position})


func test_menu_difficulty_change_rebuilds_the_level() -> void:
	var main = await load_main()
	check(not main.needs_rebuild_for_new_game(), "START keeps the loaded level when the difficulty is unchanged")
	main.start_menu.cycle_difficulty()
	check(main.needs_rebuild_for_new_game(), "START rebuilds the level after the difficulty changes on the menu")
	Difficulty.set_current(Difficulty.NORMAL)
	await unload_main(main)


func test_level_select_requests_the_chosen_level() -> void:
	SaveData.highest_unlocked_level = 3
	var menu := StartMenu.new()
	root.add_child(menu)
	await process_frame
	var requested: Array[int] = []
	menu.level_requested.connect(func(level_number: int) -> void: requested.append(level_number))
	var level_three := find_button(menu, "3. THE 101")
	var level_four := find_button(menu, "4. LOCKED")
	check(level_three != null and not level_three.disabled, "unlocked levels are selectable on the level select screen")
	check(level_four != null and level_four.disabled, "levels beyond your progress are locked")
	level_three.pressed.emit()
	check(requested == [3], "pressing a level button requests that level (%s)" % [requested])
	menu.queue_free()
	SaveData.highest_unlocked_level = 1
	await process_frame


func test_board_bosses_can_be_beaten_one_at_a_time() -> void:
	var main = await load_level(10)
	remove_all_enemies(main)
	main.start_game()
	main.player.runway_months = 9999
	await wait_physics_seconds(0.1)
	main.player.global_position = main.objectives.current_stage.config["position"] + Vector3(0, 0.2, 0)
	await wait_physics_seconds(0.3)
	var boss_stage := main.objectives.current_stage as BossStage
	check(boss_stage != null and boss_stage.bosses.size() == 3, "the boardroom spawns three directors")
	var first: Boss = boss_stage.bosses[0]
	first.summon_minions()
	first.summon_minions()
	check(first.summons.size() == Boss.SUMMON_COUNT * 2, "a director can summon security twice (%d minions)" % first.summons.size())
	first.summons[0].take_damage(100000)
	check(first.summons.size() == Boss.SUMMON_COUNT * 2 - 1, "a defeated minion leaves the summon list")
	for boss_index: int in 3:
		var boss: Enemy = boss_stage.bosses[0]
		boss.take_damage(100000)
		await wait_physics_seconds(4.0)
		var progress: float = main.objectives.get_boss_progress()
		if boss_index < 2:
			check(progress > 0.0 and progress < 1.0, "the board bar drops after director %d leaves (%.2f)" % [boss_index + 1, progress])
	check(main.get_state_name() == "WON", "beating all three directors one at a time completes the boardroom")
	await unload_main(main)


func test_destroy_stage_survives_freed_targets() -> void:
	var main = await load_level(2)
	remove_all_enemies(main)
	main.start_game()
	await wait_physics_seconds(0.1)
	var stage := main.objectives.current_stage as DestroyStage
	stage.get_remaining_targets()[0].take_damage(100000)
	await wait_physics_seconds(1.0)
	check(stage.get_remaining_targets().size() == 2, "remaining targets are listed after one is destroyed and freed")
	await unload_main(main)


func test_graphics_presets_apply_to_the_renderer() -> void:
	for quality: String in [GraphicsSettings.LOW, GraphicsSettings.MEDIUM, GraphicsSettings.HIGH]:
		GraphicsSettings.set_current(quality)
		var main = await load_level(3)
		var preset := GraphicsSettings.get_preset()
		var viewport: Viewport = main.get_viewport()
		var render_scale := GraphicsSettings.get_render_scale(GraphicsSettings.get_output_height(viewport))
		check(is_equal_approx(viewport.scaling_3d_scale, render_scale), "%s: 3D renders at %d%% resolution" % [quality, roundi(render_scale * 100.0)])
		check(viewport.msaa_3d == preset["msaa"], "%s: anti-aliasing matches the preset" % quality)
		var has_shadows: bool = preset["shadows"]
		check(main.sun.shadow_enabled == has_shadows and main.sun.directional_shadow_mode == preset["shadow_mode"], "%s: sun shadows %s" % [quality, "on" if has_shadows else "off"])
		var has_glow: bool = preset["glow"]
		check(main.world_environment.environment.glow_enabled == has_glow, "%s: glow %s" % [quality, "on" if has_glow else "off"])
		var ash: CPUParticles3D = main.player.find_children("*", "CPUParticles3D", false, false)[0]
		check(ash.amount == GraphicsSettings.scale_particle_amount(220), "%s: ambient particles scaled to %d" % [quality, ash.amount])
		await unload_main(main)
	GraphicsSettings.set_current(GraphicsSettings.AUTO)
	check(GraphicsSettings.get_resolved() in [GraphicsSettings.MEDIUM, GraphicsSettings.HIGH], "AUTO resolves to a preset (%s)" % GraphicsSettings.get_resolved())
	GraphicsSettings.set_current(GraphicsSettings.HIGH)


func test_menu_graphics_and_fps_toggles() -> void:
	var main = await load_main()
	var menu: StartMenu = main.start_menu
	GraphicsSettings.set_current(GraphicsSettings.AUTO)
	menu.cycle_graphics_quality()
	check(GraphicsSettings.current == GraphicsSettings.LOW and menu.graphics_button.text.ends_with("LOW"), "the graphics button cycles to LOW")
	var expected_scale := GraphicsSettings.get_render_scale(GraphicsSettings.get_output_height(main.get_viewport()))
	check(is_equal_approx(main.get_viewport().scaling_3d_scale, expected_scale), "changing graphics on the menu applies immediately")
	menu.toggle_fps_counter()
	await process_frame
	check(GraphicsSettings.show_fps and main.hud.fps_label.visible, "SHOW FPS turns on the frame counter")
	menu.toggle_fps_counter()
	await process_frame
	check(not main.hud.fps_label.visible, "SHOW FPS can be turned off again")
	GraphicsSettings.set_current(GraphicsSettings.HIGH)
	await unload_main(main)


func test_staged_loading_shows_progress_then_the_menu() -> void:
	var main_script = load(MAIN_SCRIPT_PATH)
	main_script.is_staged_loading_enabled = true
	var main = await load_main()
	var loading_screen: LoadingScreen = main.loading_screen
	check(loading_screen != null and main.get_state_name() == "LOADING", "staged loading starts on the loading screen")
	check(loading_screen != null and loading_screen.level_label.text == main.level.get_chapter_label(), "loading screen names the level")
	var highest_progress := 0.0
	var frames_waited := 0
	while main.get_state_name() == "LOADING" and frames_waited < 600:
		if is_instance_valid(loading_screen):
			highest_progress = maxf(highest_progress, loading_screen.target_progress)
		frames_waited += 1
		await process_frame
	if is_instance_valid(loading_screen):
		highest_progress = maxf(highest_progress, loading_screen.target_progress)
	check(main.get_state_name() == "MENU", "staged loading ends on the start menu")
	check(is_equal_approx(highest_progress, 1.0), "progress bar reaches 100% as the menu opens")
	for frame: int in 60:
		await process_frame
	check(not is_instance_valid(loading_screen), "loading screen removes itself after fading out")
	main_script.is_staged_loading_enabled = false
	await unload_main(main)


func test_loading_screen_scrolls_tips() -> void:
	var loading_screen := LoadingScreen.new()
	root.add_child(loading_screen)
	await process_frame
	var first_tip := loading_screen.tip_label.text
	check(first_tip.begins_with("TIP:"), "loading screen shows a tip")
	loading_screen.tip_seconds_left = 0.0
	for frame: int in 45:
		await process_frame
	check(loading_screen.tip_label.text != first_tip and loading_screen.tip_label.text.begins_with("TIP:"), "loading screen scrolls to the next tip")
	loading_screen.set_progress(0.4, "BUILDING")
	loading_screen.set_progress(0.2, "BUILDING")
	check(is_equal_approx(loading_screen.target_progress, 0.4), "progress never moves backwards")
	loading_screen.queue_free()
	await process_frame


func test_every_voice_clip_uses_a_listed_voice() -> void:
	var unexpected: Array[String] = []
	var clip_count := 0
	for file_name: String in ResourceLoader.list_directory(AudioBank.VOICE_FOLDER):
		if not file_name.ends_with(".wav"):
			continue
		clip_count += 1
		if not AudioBank.VOICES.has(file_name.get_slice("_", 0)):
			unexpected.append(file_name)
	check(clip_count > 0 and unexpected.is_empty(), "all %d voice clips use the listed public-domain voices (unexpected %s)" % [clip_count, unexpected])
