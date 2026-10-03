class_name ObjectiveTracker
extends Node3D

signal all_completed
signal failed(heading: String, body: String)
signal text_changed(text: String)
signal countdown_changed(seconds_left: float, label: String)
signal stage_completed(stage_index: int)

var level: Level
var player: Player
var spawn_enemy: Callable
var opens_door: Callable
var stage_index := -1
var current_stage: ObjectiveStage
var is_running := false


func setup(game_level: Level, game_player: Player, enemy_spawner: Callable, door_opener: Callable) -> void:
	level = game_level
	player = game_player
	spawn_enemy = enemy_spawner
	opens_door = door_opener


func start() -> void:
	is_running = true
	advance_stage()


func stop() -> void:
	is_running = false
	if current_stage != null:
		current_stage.stop()


func advance_stage() -> void:
	if current_stage != null:
		current_stage.queue_free()
	stage_index += 1
	if stage_index >= level.objectives.size():
		current_stage = null
		is_running = false
		all_completed.emit()
		return
	current_stage = create_stage(level.objectives[stage_index])
	current_stage.begin()


func instantiate_stage(stage_type: String) -> ObjectiveStage:
	match stage_type:
		"reach":
			return ReachStage.new()
		"destroy":
			return DestroyStage.new()
		"survive":
			return SurviveStage.new()
		"boss":
			return BossStage.new()
		"ladder":
			return LadderStage.new()
	push_error("Unknown objective type '%s'" % stage_type)
	return ReachStage.new()


func create_stage(stage_config: Dictionary) -> ObjectiveStage:
	var stage_type: String = stage_config["type"]
	var stage := instantiate_stage(stage_type)
	stage.setup(stage_config, player, level, spawn_enemy)
	stage.name = "Stage%d_%s" % [stage_index + 1, stage_type]
	stage.completed.connect(_on_stage_completed)
	stage.failed.connect(_on_stage_failed)
	stage.text_changed.connect(_on_stage_text_changed)
	stage.countdown_changed.connect(_on_stage_countdown_changed)
	get_parent().add_child(stage)
	return stage


func get_boss_progress() -> float:
	return current_stage.get_boss_progress() if current_stage != null else -1.0


func get_boss_name() -> String:
	return current_stage.get_boss_name() if current_stage != null else ""


func _on_stage_completed() -> void:
	if not is_running:
		return
	var finished_config: Dictionary = level.objectives[stage_index]
	stage_completed.emit(stage_index)
	if finished_config.has("opens"):
		opens_door.call(finished_config["opens"])
	if stage_index < level.objectives.size() - 1:
		AudioBank.play_ui(self, AudioBank.OBJECTIVE, -4.0)
	advance_stage.call_deferred()


func _on_stage_failed(heading: String, body: String) -> void:
	if not is_running:
		return
	is_running = false
	failed.emit(heading, body)


func _on_stage_text_changed(text: String) -> void:
	text_changed.emit(text)


func _on_stage_countdown_changed(seconds_left: float) -> void:
	var label := ""
	if current_stage != null and current_stage.has_method("get_countdown_label"):
		label = current_stage.get_countdown_label()
	countdown_changed.emit(seconds_left, label)
