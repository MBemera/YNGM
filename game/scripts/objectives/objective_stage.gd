class_name ObjectiveStage
extends Node3D

signal completed
signal failed(heading: String, body: String)
signal text_changed(text: String)
signal countdown_changed(seconds_left: float)

const DEFAULT_FAIL_HEADING := "TOO SLOW."
const DEFAULT_FAIL_BODY := "The window closed. Welcome to the permanent underclass."

var config: Dictionary = {}
var player: Player
var level: Level
var spawn_enemy: Callable
var is_finished := false


func setup(stage_config: Dictionary, game_player: Player, game_level: Level, enemy_spawner: Callable) -> void:
	config = stage_config
	player = game_player
	level = game_level
	spawn_enemy = enemy_spawner


func begin() -> void:
	text_changed.emit(get_text())


func get_text() -> String:
	return config.get("text", "")


func get_boss_progress() -> float:
	return -1.0


func get_boss_name() -> String:
	return ""


func finish() -> void:
	if is_finished:
		return
	is_finished = true
	countdown_changed.emit(-1.0)
	completed.emit()


func fail() -> void:
	if is_finished:
		return
	is_finished = true
	countdown_changed.emit(-1.0)
	failed.emit(config.get("fail_heading", DEFAULT_FAIL_HEADING), config.get("fail_body", DEFAULT_FAIL_BODY))


func stop() -> void:
	is_finished = true
	set_physics_process(false)
