class_name SurviveStage
extends ObjectiveStage

var total_seconds := 0.0
var time_left := 0.0
var next_wave_index := 0


func begin() -> void:
	var base_seconds: float = config["seconds"]
	total_seconds = base_seconds * Difficulty.get_value("survive_time")
	time_left = total_seconds
	super.begin()
	countdown_changed.emit(time_left)
	AudioBank.play_ui(self, AudioBank.ALARM, -8.0)


func _physics_process(delta: float) -> void:
	if is_finished:
		return
	time_left = maxf(time_left - delta, 0.0)
	countdown_changed.emit(time_left)
	spawn_due_waves()
	if time_left <= 0.0:
		finish()


func spawn_due_waves() -> void:
	var waves: Array = config.get("waves", [])
	var elapsed_fraction := 1.0 - time_left / total_seconds
	while next_wave_index < waves.size() and elapsed_fraction >= float(waves[next_wave_index]["at"]):
		spawn_wave(waves[next_wave_index])
		next_wave_index += 1


func spawn_wave(wave: Dictionary) -> void:
	for spawn: Dictionary in wave["enemies"]:
		var enemy: Enemy = spawn_enemy.call(spawn)
		enemy.engage_silently()


func get_countdown_label() -> String:
	return config.get("countdown_label", "HOLD OUT")
