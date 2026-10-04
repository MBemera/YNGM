extends Node

const FrameStats := preload("res://tests/autoplay/frame_stats.gd")
const TURN_DEGREES_PER_SECOND := 420.0
const ENGAGE_RANGE := 36.0
const TARGET_RANGE := 45.0
const FIRE_ANGLE_DEGREES := 2.5
const REPATH_SECONDS := 0.35
const STUCK_CHECK_SECONDS := 1.2
const STUCK_DISTANCE := 0.7
const MAX_ATTEMPT_SECONDS := 600.0
const MAX_ATTEMPTS_PER_LEVEL := 8
const LOW_RUNWAY_FRACTION := 0.45
const HEALTH_DETOUR_RANGE := 30.0
const QUICK_STATE_SECONDS := {"MENU": 1.0, "INTRO": 1.0, "ENDING": 1.0, "READY": 1.0, "WON": 1.6, "LOST": 1.0, "FINISHED": 0.0}
const RECORDING_STATE_SECONDS := {"MENU": 4.0, "READY": 3.0, "WON": 5.0, "LOST": 4.0, "FINISHED": 8.0}
const PERSON_TURN_DEGREES_PER_SECOND := 260.0
const PERSON_AIM_RESPONSE := 9.0
const PERSON_REACTION_SECONDS := Vector2(0.25, 0.5)
const PERSON_AIM_WOBBLE_METERS := 0.22
const PERSON_ENGAGE_RANGE := 30.0
const PERSON_MAX_ATTEMPT_SECONDS := 420.0
const PERSON_DODGE_CHANCE := 0.75
const PERSON_DODGE_REACTION_SECONDS := 0.25
const PERSON_LOW_RUNWAY_FRACTION := 0.55
const PERSON_DEATHS_TO_FULL_SKILL := 3.0
const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const DARTS := 0
const CONFETTI := 1
const GRENADE := 2
const NDA := 3
const BUBBLE := 5
const DISRUPTOR := 6

var report_directory := "user://playthrough"
var is_recording := false
var stop_after_level := 0
var current_target: Node3D
var reaction_left := 0.0
var wobble_time := 0.0
var last_runway := 0
var person_amount := 0.0
var noticed_projectiles: Dictionary = {}
var main: Node
var last_state := ""
var state_entered_msec := 0
var has_acted_in_state := false
var level_results: Dictionary = {}
var level_frame_stats: Dictionary = {}
var attempt_start_msec := 0
var run_start_msec := 0
var path := PackedVector3Array()
var path_index := 0
var path_goal := Vector3.INF
var repath_left := 0.0
var stuck_timer := 0.0
var stuck_origin := Vector3.ZERO
var stuck_count := 0
var strafe_sign := 1.0
var strafe_left := 0.0
var unstick_left := 0.0
var unstick_direction := Vector3.ZERO
var weapon_hold_left := 0.0
var aim_error := PI
var is_jump_held := false
var has_mid_level_screenshot := false
var weapon_shots: Dictionary = {}
var is_restarting := false
var trace_left := 5.0
var capture_frames_left := 0
var was_navigation_ready := false


func _ready() -> void:
	run_start_msec = GameClock.get_msec()
	DirAccess.make_dir_recursive_absolute(report_directory)


func _process(delta: float) -> void:
	if main == null or not is_instance_valid(main) or main.get_state_name() != "PLAYING":
		return
	if capture_frames_left > 0:
		capture_frames_left -= 1
		return
	var level_number: int = main.level.number
	if not level_frame_stats.has(level_number):
		level_frame_stats[level_number] = FrameStats.new()
	level_frame_stats[level_number].add_frame(delta)
	if delta > 0.08:
		print("[hitch] L%d t=%.2f %.0f ms nav_ready=%s" % [level_number, get_attempt_seconds(), delta * 1000.0, main.is_navigation_ready])


func _physics_process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("get_state_name") or not scene.is_node_ready():
		return
	if scene != main:
		on_new_scene(scene)
	var state_name: String = main.get_state_name()
	if state_name != last_state:
		on_state_changed(state_name)
	if main.is_navigation_ready and not was_navigation_ready:
		print("[nav] L%d navigation ready in state %s t=%.2f" % [main.level.number, state_name, get_attempt_seconds()])
	was_navigation_ready = main.is_navigation_ready
	handle_state(state_name, delta)


func on_new_scene(scene: Node) -> void:
	main = scene
	was_navigation_ready = false
	last_state = ""
	reset_navigation()
	release_movement()


func reset_navigation() -> void:
	path = PackedVector3Array()
	path_index = 0
	path_goal = Vector3.INF
	repath_left = 0.0
	stuck_timer = 0.0
	stuck_count = 0
	unstick_left = 0.0


func on_state_changed(state_name: String) -> void:
	last_state = state_name
	state_entered_msec = GameClock.get_msec()
	has_acted_in_state = false
	is_restarting = false
	print("[bot] L%d %s" % [main.level.number, state_name])
	match state_name:
		"PLAYING":
			begin_attempt()
		"WON", "ENDING":
			record_win()
		"LOST":
			record_death(main.hud.message_heading.text)


func handle_state(state_name: String, delta: float) -> void:
	if state_name == "PLAYING":
		play(delta)
		return
	var state_seconds: Dictionary = RECORDING_STATE_SECONDS if is_recording else QUICK_STATE_SECONDS
	if not state_seconds.has(state_name):
		return
	var waited_seconds := (GameClock.get_msec() - state_entered_msec) / 1000.0
	act_once(waited_seconds >= state_seconds[state_name], get_state_action(state_name))


func get_state_action(state_name: String) -> Callable:
	match state_name:
		"MENU":
			return press_start_button
		"READY":
			return tap_action.bind("fire")
		"WON":
			return continue_after_win
		"LOST":
			return retry_or_abort
		"FINISHED":
			return finish_run.bind(true)
	return tap_action.bind("skip_intro")


func continue_after_win() -> void:
	if main.level.number == stop_after_level:
		finish_run(true)
		return
	tap_action("fire")


func act_once(is_ready: bool, action: Callable) -> void:
	if not is_ready or has_acted_in_state:
		return
	has_acted_in_state = true
	action.call()


func press_start_button() -> void:
	for button: Button in main.start_menu.find_children("*", "Button", true, false):
		if button.text == "START":
			button.pressed.emit()
			return


func tap_action(action_name: String) -> void:
	for is_pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = is_pressed
		Input.parse_input_event(event)


func get_level_result() -> Dictionary:
	var level_number: int = main.level.number
	if not level_results.has(level_number):
		level_results[level_number] = {"title": main.level.title, "attempts": 0, "deaths": [], "hits_taken": 0, "runway_lost": 0}
	return level_results[level_number]


func begin_attempt() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	attempt_start_msec = GameClock.get_msec()
	get_level_result()["attempts"] += 1
	last_runway = main.player.runway_months
	noticed_projectiles.clear()
	person_amount = get_person_amount()
	has_mid_level_screenshot = false
	reset_navigation()


func get_person_amount() -> float:
	if not is_recording:
		return 0.0
	var deaths: int = get_level_result()["deaths"].size()
	return clampf(1.0 - deaths / PERSON_DEATHS_TO_FULL_SKILL, 0.0, 1.0)


func get_attempt_seconds() -> float:
	return (GameClock.get_msec() - attempt_start_msec) / 1000.0


func record_win() -> void:
	release_movement()
	var result := get_level_result()
	var player: Player = main.player
	result["won"] = true
	result["win_seconds"] = snappedf(get_attempt_seconds(), 0.1)
	result["runway_left"] = player.runway_months
	result["max_runway"] = player.max_runway_months
	result["enemies_defeated"] = main.enemies_defeated
	print("[bot] L%d WON in %.1fs, runway %d/%d, attempt %d" % [main.level.number, result["win_seconds"], player.runway_months, player.max_runway_months, result["attempts"]])
	save_screenshot("L%02d_won" % main.level.number)


func record_death(heading: String) -> void:
	release_movement()
	var result := get_level_result()
	result["deaths"].append({"attempt": result["attempts"], "reason": heading, "seconds": snappedf(get_attempt_seconds(), 0.1)})
	print("[bot] L%d attempt %d failed: %s after %.1fs" % [main.level.number, result["attempts"], heading, get_attempt_seconds()])
	if result["deaths"].size() == 1:
		save_screenshot("L%02d_first_failure" % main.level.number)


func retry_or_abort() -> void:
	if get_level_result()["attempts"] >= MAX_ATTEMPTS_PER_LEVEL:
		finish_run(false)
		return
	tap_action("restart")


func play(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	release_jump_if_held()
	if is_restarting:
		return
	if get_attempt_seconds() > (PERSON_MAX_ATTEMPT_SECONDS if is_recording else MAX_ATTEMPT_SECONDS):
		is_restarting = true
		record_death("TIMEOUT")
		tap_action("restart")
		return
	if not has_mid_level_screenshot and get_attempt_seconds() > 20.0:
		has_mid_level_screenshot = true
		save_screenshot("L%02d_action" % main.level.number)
	drive(delta)


func drive(delta: float) -> void:
	var player: Player = main.player
	if player == null or not player.controls_enabled:
		release_movement()
		return
	record_damage_taken(player)
	var stage: ObjectiveStage = main.objectives.current_stage
	var target := choose_target(player, stage)
	track_target(target, delta)
	var goal := choose_goal(player, stage, target)
	update_path(player, goal, delta)
	trace(player, goal, target, delta)
	aim_at(player, target, delta)
	fire_if_ready(player, target, delta)
	move(player, stage, target, delta)


func record_damage_taken(player: Player) -> void:
	if player.runway_months < last_runway:
		var result := get_level_result()
		result["hits_taken"] += 1
		result["runway_lost"] += last_runway - player.runway_months
	last_runway = player.runway_months


func track_target(target: Node3D, delta: float) -> void:
	wobble_time += delta
	reaction_left -= delta
	if target != current_target:
		current_target = target
		reaction_left = randf_range(PERSON_REACTION_SECONDS.x, PERSON_REACTION_SECONDS.y) * person_amount


func trace(player: Player, goal: Vector3, target: Node3D, delta: float) -> void:
	trace_left -= delta
	if trace_left > 0.0:
		return
	trace_left = 5.0
	var next_point: Vector3 = path[path_index] if path_index < path.size() else Vector3.INF
	var target_name: String = target.name if target != null else "-"
	print("[trace] L%d t=%.0f pos=%s goal=%s next=%s path=%d/%d target=%s stuck=%d runway=%d" % [main.level.number, get_attempt_seconds(), player.global_position.snapped(Vector3.ONE * 0.1), goal.snapped(Vector3.ONE * 0.1), next_point.snapped(Vector3.ONE * 0.1), path_index, path.size(), target_name, stuck_count, player.runway_months])


func choose_target(player: Player, stage: ObjectiveStage) -> Node3D:
	var eye := player.camera.global_position
	var best: Node3D = null
	var best_score := INF
	for node: Node in get_tree().get_nodes_in_group(Enemy.ENEMY_GROUP):
		var enemy := node as Enemy
		if enemy == null or enemy.state == Enemy.State.DEFEATED:
			continue
		var score := score_enemy(player, enemy, eye)
		if score < best_score:
			best = enemy
			best_score = score
	var destroy := stage as DestroyStage
	if destroy == null:
		return best
	for target: DestructibleTarget in destroy.get_remaining_targets():
		var distance := eye.distance_to(get_aim_point(target))
		if distance < TARGET_RANGE and has_line_of_sight(player, eye, target) and distance - 6.0 < best_score:
			best = target
			best_score = distance - 6.0
	return best


func score_enemy(player: Player, enemy: Enemy, eye: Vector3) -> float:
	var distance := eye.distance_to(get_aim_point(enemy))
	var engage_range := lerpf(ENGAGE_RANGE, PERSON_ENGAGE_RANGE, person_amount)
	if distance > engage_range or not has_line_of_sight(player, eye, enemy):
		return INF
	var score := distance
	if enemy.config["attack"] == "melee" and distance < 10.0:
		score -= 8.0
	if enemy is Boss:
		score -= 4.0
	return score


func get_aim_point(target: Node3D) -> Vector3:
	var enemy := target as Enemy
	if enemy != null:
		var height: float = enemy.config.get("collision_height", 1.8)
		return enemy.global_position + Vector3.UP * height * 0.62
	var destructible := target as DestructibleTarget
	return destructible.global_position + Vector3.UP * destructible.model_height * 0.5


func has_line_of_sight(player: Player, eye: Vector3, target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(eye, get_aim_point(target), WORLD_LAYER | ENEMY_LAYER, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit["collider"]
	if collider is Enemy or collider is DestructibleTarget:
		return true
	return (hit["position"] as Vector3).distance_to(get_aim_point(target)) < 1.6


func choose_goal(player: Player, stage: ObjectiveStage, target: Node3D) -> Vector3:
	var pack := find_health_pack(player)
	if pack != null and not is_rushing(stage):
		return pack.global_position
	if stage is LadderStage:
		return (main.level as Level01SouthOfMarket).helicopter.get_ladder_bottom_position()
	if stage is ReachStage:
		return stage.config["position"]
	if stage is DestroyStage:
		return find_nearest_position(player, (stage as DestroyStage).get_remaining_targets())
	if stage is BossStage:
		return find_nearest_position(player, get_living_enemies((stage as BossStage).bosses))
	if stage is SurviveStage and target == null:
		return find_nearest_position(player, get_living_enemies(get_tree().get_nodes_in_group(Enemy.ENEMY_GROUP)))
	return Vector3.INF


func find_health_pack(player: Player) -> HealthPack:
	var low_fraction := lerpf(LOW_RUNWAY_FRACTION, PERSON_LOW_RUNWAY_FRACTION, person_amount)
	if player.runway_months > player.max_runway_months * low_fraction:
		return null
	var best: HealthPack = null
	var best_distance := HEALTH_DETOUR_RANGE
	for child: Node in main.get_children():
		var pack := child as HealthPack
		if pack != null and not pack.is_queued_for_deletion():
			var distance := pack.global_position.distance_to(player.global_position)
			if distance < best_distance:
				best = pack
				best_distance = distance
	return best


func get_living_enemies(nodes: Array) -> Array[Node3D]:
	var living: Array[Node3D] = []
	for node: Variant in nodes:
		if not is_instance_valid(node):
			continue
		var enemy := node as Enemy
		if enemy != null and enemy.state != Enemy.State.DEFEATED:
			living.append(enemy)
	return living


func find_nearest_position(player: Player, nodes: Array) -> Vector3:
	var best := Vector3.INF
	var best_distance := INF
	for node: Variant in nodes:
		if not is_instance_valid(node):
			continue
		var candidate := node as Node3D
		if candidate == null:
			continue
		var distance := candidate.global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = candidate.global_position
			best_distance = distance
	return best


func is_rushing(stage: ObjectiveStage) -> bool:
	var reach := stage as ReachStage
	if reach != null and reach.time_left > 0.0:
		return true
	var ladder := stage as LadderStage
	return ladder != null and ladder.is_timer_running


func update_path(player: Player, goal: Vector3, delta: float) -> void:
	repath_left -= delta
	if goal == Vector3.INF:
		path = PackedVector3Array()
		return
	if repath_left <= 0.0 or goal.distance_to(path_goal) > 1.0:
		repath_left = REPATH_SECONDS
		path_goal = goal
		path = NavigationServer3D.map_get_path(player.get_world_3d().navigation_map, player.global_position, goal, true)
		path_index = 0
	while path_index < path.size() and flat_distance(player.global_position, path[path_index]) < 0.6:
		path_index += 1


func get_path_direction(player: Player) -> Vector3:
	if path_index < path.size():
		return flat_direction(player.global_position, path[path_index])
	if path_goal != Vector3.INF and flat_distance(player.global_position, path_goal) > 0.5:
		return flat_direction(player.global_position, path_goal)
	return Vector3.ZERO


func aim_at(player: Player, target: Node3D, delta: float) -> void:
	var eye := player.camera.global_position
	var look_point := Vector3.INF
	if target != null:
		look_point = get_aim_point(target) + get_lead(player, target) + get_aim_wobble()
	elif path_index < path.size():
		look_point = path[path_index] + Vector3.UP * Player.EYE_HEIGHT
	if look_point == Vector3.INF:
		return
	var direction := look_point - eye
	var desired_yaw := atan2(-direction.x, -direction.z)
	var desired_pitch := atan2(direction.y, Vector2(direction.x, direction.z).length()) if target != null else 0.0
	var yaw_error := wrapf(desired_yaw - player.rotation.y, -PI, PI)
	var pitch_error := desired_pitch - player.head.rotation.x
	var max_step := deg_to_rad(lerpf(TURN_DEGREES_PER_SECOND, PERSON_TURN_DEGREES_PER_SECOND, person_amount)) * delta
	var ease := lerpf(1.0, clampf(PERSON_AIM_RESPONSE * delta, 0.0, 1.0), person_amount)
	var yaw_step := clampf(yaw_error * ease, -max_step, max_step)
	var pitch_step := clampf(pitch_error * ease, -max_step, max_step)
	player.rotate_view(Vector2(-yaw_step, -pitch_step) / Player.MOUSE_SENSITIVITY)
	aim_error = Vector2(yaw_error - yaw_step, pitch_error - pitch_step).length()


func get_aim_wobble() -> Vector3:
	var wobble := Vector3(sin(wobble_time * 1.7), sin(wobble_time * 2.3 + 1.0) * 0.6, cos(wobble_time * 1.3))
	return wobble * PERSON_AIM_WOBBLE_METERS * person_amount


func get_lead(player: Player, target: Node3D) -> Vector3:
	var enemy := target as Enemy
	var weapon := Weapons.get_weapon(player.current_weapon_index)
	if enemy == null or not weapon.has("speed"):
		return Vector3.ZERO
	var speed: float = weapon["speed"]
	var flight_seconds := player.camera.global_position.distance_to(enemy.global_position) / speed
	return Vector3(enemy.velocity.x, 0.0, enemy.velocity.z) * flight_seconds


func fire_if_ready(player: Player, target: Node3D, delta: float) -> void:
	weapon_hold_left -= delta
	if target == null:
		return
	var distance := player.camera.global_position.distance_to(get_aim_point(target))
	var weapon_index := choose_weapon(player, target, distance)
	if weapon_index != player.current_weapon_index and weapon_hold_left <= 0.0:
		tap_action("weapon_%d" % (weapon_index + 1))
		weapon_hold_left = 1.0
	var tolerance := maxf(deg_to_rad(FIRE_ANGLE_DEGREES), atan(0.45 / maxf(distance, 1.0)))
	if aim_error > tolerance or player.fire_cooldown_left > 0.0 or reaction_left > 0.0:
		return
	player.fire_weapon()
	var weapon_name: String = Weapons.get_weapon(player.current_weapon_index)["short_name"]
	weapon_shots[weapon_name] = weapon_shots.get(weapon_name, 0) + 1


func choose_weapon(player: Player, target: Node3D, distance: float) -> int:
	var enemy := target as Enemy
	if enemy == null or enemy is Boss:
		return DARTS
	var unlocked := player.unlocked_weapon_count
	var cluster := count_enemies_near(enemy.global_position, 4.5)
	if cluster >= 3 and distance > 7.0 and distance < 22.0:
		if unlocked > BUBBLE:
			return BUBBLE
		if distance < 14.0:
			return GRENADE
	if distance < 5.5:
		return CONFETTI
	var is_tough_rusher: bool = enemy.config["attack"] == "melee" and enemy.health > 60
	if unlocked > NDA and is_tough_rusher and distance < 9.0 and not enemy.is_stunned():
		return NDA
	if unlocked > DISRUPTOR and cluster >= 2:
		return DISRUPTOR
	return DARTS


func count_enemies_near(point: Vector3, radius: float) -> int:
	var count := 0
	for node: Node3D in get_living_enemies(get_tree().get_nodes_in_group(Enemy.ENEMY_GROUP)):
		if node.global_position.distance_to(point) <= radius:
			count += 1
	return count


func move(player: Player, stage: ObjectiveStage, target: Node3D, delta: float) -> void:
	var path_direction := get_path_direction(player)
	var direction := path_direction
	var enemy := target as Enemy
	if unstick_left > 0.0:
		unstick_left -= delta
		direction = unstick_direction
	elif enemy != null and not is_rushing(stage):
		direction = get_combat_direction(player, enemy, path_direction, delta)
	elif target is DestructibleTarget and player.global_position.distance_to(target.global_position) < 16.0:
		direction = get_strafe_direction(player, target.global_position, delta) * 0.5
	direction += get_dodge_direction(player) * 1.5
	var is_walking := person_amount >= 0.5 and target != null and not stage is BossStage
	apply_movement(player, direction, is_walking)
	update_stuck(player, direction, delta)


func get_strafe_direction(player: Player, point: Vector3, delta: float) -> Vector3:
	strafe_left -= delta
	if strafe_left <= 0.0:
		strafe_left = randf_range(0.8, 1.8)
		strafe_sign *= -1.0
	return flat_direction(player.global_position, point).cross(Vector3.UP) * strafe_sign


func get_combat_direction(player: Player, enemy: Enemy, path_direction: Vector3, delta: float) -> Vector3:
	var distance := flat_distance(player.global_position, enemy.global_position)
	var toward := flat_direction(player.global_position, enemy.global_position)
	var preferred := 11.0
	if enemy is Boss:
		preferred = 14.0
	elif enemy.config["attack"] == "melee":
		preferred = 8.0
	var radial := Vector3.ZERO
	if distance < preferred - 2.0:
		radial = -toward
	elif distance > preferred + 6.0:
		radial = path_direction if path_direction != Vector3.ZERO else toward
	return (get_strafe_direction(player, enemy.global_position, delta) * 0.9 + radial).normalized()


func get_dodge_direction(player: Player) -> Vector3:
	var chest := player.global_position + Vector3.UP * 1.1
	var dodge := Vector3.ZERO
	for child: Node in main.get_children():
		var projectile := child as Projectile
		if projectile == null or projectile.shooter == player or not is_projectile_noticed(projectile):
			continue
		var offset := chest - projectile.global_position
		if offset.length() > 14.0 or projectile.velocity.dot(offset) <= 0.0:
			continue
		var seconds := offset.dot(projectile.velocity) / projectile.velocity.length_squared()
		var closest := projectile.global_position + projectile.velocity * seconds
		if seconds < 0.9 and seconds > PERSON_DODGE_REACTION_SECONDS * person_amount and closest.distance_to(chest) < 1.3:
			var away := chest - closest
			away.y = 0.0
			dodge += away.normalized() if away.length() > 0.05 else projectile.velocity.cross(Vector3.UP).normalized()
	return dodge


func is_projectile_noticed(projectile: Projectile) -> bool:
	var projectile_id := projectile.get_instance_id()
	if not noticed_projectiles.has(projectile_id):
		noticed_projectiles[projectile_id] = randf() < lerpf(1.0, PERSON_DODGE_CHANCE, person_amount)
	return noticed_projectiles[projectile_id]


func apply_movement(player: Player, world_direction: Vector3, is_walking: bool) -> void:
	var flat := Vector3(world_direction.x, 0.0, world_direction.z)
	if flat.length() < 0.05:
		release_movement()
		return
	var local := player.global_transform.basis.inverse() * flat.normalized()
	set_action_strength("move_right", local.x)
	set_action_strength("move_left", -local.x)
	set_action_strength("move_back", local.z)
	set_action_strength("move_forward", -local.z)
	if is_walking:
		Input.action_release("sprint")
	else:
		Input.action_press("sprint")


func set_action_strength(action_name: String, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action_name, clampf(strength, 0.0, 1.0))
	else:
		Input.action_release(action_name)


func release_movement() -> void:
	for action_name: String in ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump"]:
		Input.action_release(action_name)


func update_stuck(player: Player, direction: Vector3, delta: float) -> void:
	if direction.length() < 0.1:
		stuck_timer = 0.0
		stuck_origin = player.global_position
		return
	stuck_timer += delta
	if stuck_timer < STUCK_CHECK_SECONDS:
		return
	var moved := flat_distance(player.global_position, stuck_origin)
	stuck_timer = 0.0
	stuck_origin = player.global_position
	if moved >= STUCK_DISTANCE:
		stuck_count = 0
		return
	stuck_count += 1
	on_stuck(direction)


func on_stuck(direction: Vector3) -> void:
	Input.action_press("jump")
	is_jump_held = true
	strafe_sign *= -1.0
	repath_left = 0.0
	if stuck_count >= 2:
		unstick_left = 0.8
		unstick_direction = direction.cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)


func release_jump_if_held() -> void:
	if is_jump_held:
		Input.action_release("jump")
		is_jump_held = false


func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func flat_direction(from: Vector3, to: Vector3) -> Vector3:
	var offset := Vector3(to.x - from.x, 0.0, to.z - from.z)
	return offset.normalized() if offset.length() > 0.01 else Vector3.ZERO


func save_screenshot(file_stem: String) -> void:
	capture_frames_left = 4
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(report_directory.path_join(file_stem + ".png"))


func finish_run(is_complete: bool) -> void:
	release_movement()
	var summary := {}
	for level_number: int in level_frame_stats:
		summary[level_number] = level_frame_stats[level_number].get_summary()
	var report := {
		"complete": is_complete,
		"difficulty": Difficulty.current,
		"gpu": RenderingServer.get_video_adapter_name(),
		"total_minutes": snappedf((GameClock.get_msec() - run_start_msec) / 60000.0, 0.1),
		"levels": level_results,
		"fps_while_playing": summary,
		"weapon_shots": weapon_shots,
	}
	var file := FileAccess.open(report_directory.path_join("playthrough.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
	print("[bot] RUN %s in %.1f min" % ["COMPLETE" if is_complete else "ABORTED", report["total_minutes"]])
	await get_tree().create_timer(1.5).timeout
	get_tree().quit(0 if is_complete else 1)
