extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_SCRIPT_PATH := "res://scripts/main.gd"
const FLOOR_SEARCH_DEPTH := 3.0
const GOAL_TOLERANCE := 2.5
const WALK_SECONDS_PER_METRE := 0.35
const VALID_OBJECTIVES: Array[String] = ["reach", "destroy", "survive", "boss", "ladder"]

var check_count := 0
var failures: Array[String] = []


func _initialize() -> void:
	SaveData.is_persistence_enabled = false
	Difficulty.set_current(Difficulty.NORMAL)
	run_all.call_deferred()


func run_all() -> void:
	for level_number: int in get_requested_levels():
		await check_level(level_number)
	print("%d checks, %d failed" % [check_count, failures.size()])
	for failure: String in failures:
		printerr("  FAILED: " + failure)
	quit(1 if failures.size() > 0 else 0)


func get_requested_levels() -> Array[int]:
	var requested: Array[int] = []
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--levels="):
			for part: String in argument.trim_prefix("--levels=").split(","):
				requested.append(int(part))
	if requested.is_empty():
		for level_number: int in range(2, LevelCatalog.get_count() + 1):
			requested.append(level_number)
	return requested


func check_level(level_number: int) -> void:
	print("== LEVEL %d" % level_number)
	if not ResourceLoader.exists(LevelCatalog.LEVEL_PATHS[level_number - 1]):
		check(false, "level %d script exists" % level_number)
		return
	var main := await load_level(level_number)
	var level: Level = main.level
	check_level_data(level)
	check_story(level)
	await wait_physics_frames(2)
	check_floor_below(main, level.player_start, "player start")
	for spawn: Dictionary in level.enemies:
		check_floor_below(main, spawn["position"], "%s spawn at %s" % [spawn["type"], spawn["position"]])
	for pack_position: Vector3 in level.health_packs:
		check_floor_below(main, pack_position + Vector3.UP * 0.2, "health pack at %s" % pack_position)
	await open_all_doors(main)
	await check_goals_reachable(main)
	await unload(main)


func check_level_data(level: Level) -> void:
	var tag := "L%d" % level.number
	check(level.title != "" and level.tagline != "", "%s has a title and tagline" % tag)
	check(level.weapon_count >= 3 and level.weapon_count <= Weapons.ALL.size(), "%s unlocks %d weapons" % [tag, level.weapon_count])
	check(not level.objectives.is_empty(), "%s has objectives" % tag)
	check(level.enemies.size() >= 8, "%s has %d enemies" % [tag, level.enemies.size()])
	check(level.health_packs.size() >= 3, "%s has %d health packs" % [tag, level.health_packs.size()])
	check(level.navigation_bounds.has_point(level.player_start), "%s navigation bounds contain the player start" % tag)
	check(not level.menu_shot.is_empty() or level.number > 1, "%s has a menu shot when needed" % tag)
	for stage: Dictionary in level.objectives:
		check(VALID_OBJECTIVES.has(stage.get("type", "")), "%s objective '%s' is a known type" % [tag, stage.get("type", "")])
		check(stage.get("text", "") != "" or stage["type"] == "ladder", "%s objective '%s' has text" % [tag, stage["type"]])
		if stage.has("opens"):
			check(level.doors.has(stage["opens"]), "%s door '%s' exists" % [tag, stage["opens"]])
		for enemy_spawn: Dictionary in stage.get("bosses", []):
			check(EnemyTypes.CONFIGS.has(enemy_spawn["type"]), "%s boss type %s exists" % [tag, enemy_spawn["type"]])
	for spawn: Dictionary in level.enemies:
		check(EnemyTypes.CONFIGS.has(spawn["type"]), "%s enemy type %s exists" % [tag, spawn["type"]])


func check_story(level: Level) -> void:
	var tag := "L%d" % level.number
	check(FileAccess.file_exists(level.story_path), "%s story file %s exists" % [tag, level.story_path])
	var story := IntroSequence.load_json(level.story_path)
	var cast := IntroSequence.load_json(IntroSequence.CAST_PATH)
	var lines: Array = story["lines"]
	check(lines.size() >= 3, "%s story has %d lines" % [tag, lines.size()])
	for line: Dictionary in lines:
		var shot: String = line["shot"]
		check(shot == IntroSequence.PLAYER_SHOT or level.shots.has(shot), "%s story line %s uses known shot '%s'" % [tag, line["id"], shot])
		check(cast.has(line["cast"]), "%s story line %s has known cast '%s'" % [tag, line["id"], line["cast"]])


func check_floor_below(main: Node3D, point: Vector3, description: String) -> void:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.5, point + Vector3.DOWN * FLOOR_SEARCH_DEPTH, LevelBuilder.WORLD_LAYER)
	var hit := main.get_world_3d().direct_space_state.intersect_ray(query)
	var is_on_floor: bool = not hit.is_empty() and hit["normal"].y > 0.6
	var level: Level = main.level
	check(is_on_floor, "L%d %s stands on a floor" % [level.number, description])
	if is_on_floor:
		check(not is_inside_solid(main, hit["position"] + Vector3.UP * 1.0), "L%d %s is not inside a wall" % [level.number, description])


func is_inside_solid(main: Node3D, point: Vector3) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), point)
	query.collision_mask = LevelBuilder.WORLD_LAYER
	return not main.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func open_all_doors(main: Node3D) -> void:
	var level: Level = main.level
	if level.doors.is_empty():
		await wait_for_navigation(main)
		return
	await wait_for_navigation(main)
	for door_name: String in level.doors.keys():
		level.open_door(door_name)
	main.is_navigation_ready = false
	main.navigation_region.bake_finished.connect(main._on_navigation_baked, CONNECT_ONE_SHOT)
	main.navigation_region.bake_navigation_mesh(true)
	await wait_for_navigation(main)


func get_goals(level: Level) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	for stage: Dictionary in level.objectives:
		if stage["type"] == "reach":
			goals.append({"label": stage["text"], "position": stage["position"]})
		for target: Dictionary in stage.get("targets", []):
			goals.append({"label": "target " + str(target.get("name", "")), "position": target["position"], "near": true})
		for boss: Dictionary in stage.get("bosses", []):
			goals.append({"label": "boss " + str(boss["type"]), "position": boss["position"], "near": true})
	return goals


func check_goals_reachable(main: Node3D) -> void:
	var level: Level = main.level
	var player: Player = main.player
	for enemy: Node in main.get_children():
		if enemy is Enemy:
			enemy.queue_free()
	await wait_physics_frames(1)
	player.controls_enabled = true
	player.runway_months = 9999
	var map_rid: RID = main.get_world_3d().navigation_map
	for goal: Dictionary in get_goals(level):
		var destination: Vector3 = goal["position"]
		var path := NavigationServer3D.map_get_path(map_rid, player.global_position, destination, true)
		var path_end: Vector3 = path[path.size() - 1] if not path.is_empty() else Vector3.INF
		var tolerance := GOAL_TOLERANCE + (3.0 if goal.get("near", false) else 0.0)
		check(flat_distance(path_end, destination) < tolerance and absf(path_end.y - destination.y) < 2.0, "L%d navigation reaches %s (path ends %s)" % [level.number, goal["label"], path_end])
		if path.is_empty():
			continue
		await walk_path(player, path)
		var arrived := flat_distance(player.global_position, destination) < tolerance and absf(player.global_position.y - destination.y) < 2.0
		check(arrived, "L%d player can walk to %s (ended at %s)" % [level.number, goal["label"], player.global_position])
		if not arrived:
			player.global_position = path_end + Vector3.UP * 0.2
			await wait_physics_frames(2)


func walk_path(player: Player, path: PackedVector3Array) -> void:
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for point: Vector3 in path:
		var budget := maxf(player.global_position.distance_to(point) * WALK_SECONDS_PER_METRE, 0.5) + 1.0
		var elapsed := 0.0
		while elapsed < budget:
			var offset := point - player.global_position
			var height_gap := absf(offset.y - 0.5)
			offset.y = 0.0
			if offset.length() < 0.35 and height_gap < 1.0:
				break
			player.rotation.y = atan2(-offset.x, -offset.z)
			await physics_frame
			elapsed += 1.0 / Engine.physics_ticks_per_second
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await wait_physics_frames(2)


func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func load_level(level_number: int) -> Node3D:
	var main_script = load(MAIN_SCRIPT_PATH)
	main_script.current_level_number = level_number
	main_script.should_show_menu = false
	main_script.should_play_story = false
	var main: Node3D = load(MAIN_SCENE_PATH).instantiate()
	root.add_child(main)
	await process_frame
	return main


func unload(main: Node3D) -> void:
	main.queue_free()
	await process_frame
	await process_frame


func wait_for_navigation(main: Node3D) -> void:
	var frames := 0
	while not main.is_navigation_ready and frames < 1200:
		await process_frame
		frames += 1


func wait_physics_frames(count: int) -> void:
	for frame_index: int in count:
		await physics_frame


func check(condition: bool, description: String) -> void:
	check_count += 1
	if condition:
		print("PASS  " + description)
		return
	failures.append(description)
	printerr("FAIL  " + description)
