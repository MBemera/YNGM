class_name LadderStage
extends ObjectiveStage

const LADDER_TIME_SECONDS := 25.0
const FINAL_TAUNT_SECONDS := 8.0
const STREET_OBJECTIVE := "Fight your way up the street to Hypersynergy Labs"
const LAB_OBJECTIVE := "Take the ramps up to the roof"
const ROOF_OBJECTIVE := "Grab the ladder before they pull it up!"

var helicopter: Helicopter
var is_timer_running := false
var ladder_seconds := LADDER_TIME_SECONDS
var time_left := LADDER_TIME_SECONDS
var has_taunted_final_seconds := false
var current_text := STREET_OBJECTIVE


func begin() -> void:
	helicopter = (level as Level01SouthOfMarket).helicopter
	helicopter.player_grabbed_ladder.connect(finish)
	ladder_seconds = LADDER_TIME_SECONDS * Difficulty.get_value("countdown_time")
	time_left = ladder_seconds
	super.begin()


func get_text() -> String:
	return current_text


func get_countdown_label() -> String:
	return "LADDER GOING UP IN"


func _physics_process(delta: float) -> void:
	if is_finished:
		return
	if not is_timer_running:
		update_route_text()
		if has_player_reached_roof():
			start_ladder_timer()
		return
	update_ladder_timer(delta)


func update_route_text() -> void:
	var is_inside_lab := player.global_position.z < LevelBuilder.STREET_END_Z
	var next_text := LAB_OBJECTIVE if is_inside_lab else STREET_OBJECTIVE
	if next_text != current_text:
		current_text = next_text
		text_changed.emit(current_text)


func has_player_reached_roof() -> bool:
	var player_position := player.global_position
	var is_at_roof_height := player_position.y > LevelBuilder.ROOF_HEIGHT - 0.5 and player_position.z < LevelBuilder.STREET_END_Z
	return is_at_roof_height and player.is_on_floor()


func start_ladder_timer() -> void:
	is_timer_running = true
	time_left = ladder_seconds
	helicopter.activate_ladder()
	helicopter.leaders_yell(0)
	current_text = ROOF_OBJECTIVE
	text_changed.emit(current_text)
	countdown_changed.emit(time_left)


func update_ladder_timer(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	countdown_changed.emit(time_left)
	helicopter.set_retract_progress(1.0 - time_left / ladder_seconds)
	if not has_taunted_final_seconds and time_left < FINAL_TAUNT_SECONDS:
		has_taunted_final_seconds = true
		helicopter.leaders_yell(1)
	if time_left <= 0.0:
		fail()


func finish() -> void:
	is_timer_running = false
	super.finish()


func fail() -> void:
	is_timer_running = false
	super.fail()
