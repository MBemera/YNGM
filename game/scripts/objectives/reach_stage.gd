class_name ReachStage
extends ObjectiveStage

const DEFAULT_RADIUS := 2.2
const DEFAULT_COLOR := Color(0.3, 1.0, 0.6)

var beacon: ExitBeacon
var time_left := -1.0


func begin() -> void:
	super.begin()
	var beacon_color: Color = config.get("color", DEFAULT_COLOR)
	beacon = ExitBeacon.spawn(get_parent(), config["position"], config.get("radius", DEFAULT_RADIUS), beacon_color, config.get("beacon_text", "EXIT"))
	beacon.player_entered.connect(finish)
	if config.has("time_limit"):
		var base_seconds: float = config["time_limit"]
		time_left = base_seconds * Difficulty.get_value("countdown_time")
		countdown_changed.emit(time_left)
		AudioBank.play_ui(self, AudioBank.ALARM, -10.0)


func _physics_process(delta: float) -> void:
	if is_finished or time_left < 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	countdown_changed.emit(time_left)
	if time_left <= 0.0:
		fail()


func finish() -> void:
	super.finish()
	if is_instance_valid(beacon):
		beacon.queue_free()


func get_countdown_label() -> String:
	return config.get("countdown_label", "TIME LEFT")
