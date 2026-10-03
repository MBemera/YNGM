class_name NeonFlicker
extends Node

const MIN_STEADY_SECONDS := 1.5
const MAX_STEADY_SECONDS := 6.0
const FLICKER_STEPS := 5
const DIM_ALPHA := 0.25

var label: Label3D
var full_alpha := 1.0
var steady_left := 0.0


func _ready() -> void:
	label = get_parent() as Label3D
	if label == null:
		push_warning("NeonFlicker needs a Label3D parent")
		set_process(false)
		return
	full_alpha = label.modulate.a
	steady_left = randf_range(MIN_STEADY_SECONDS, MAX_STEADY_SECONDS)


func _process(delta: float) -> void:
	steady_left -= delta
	if steady_left > 0.0:
		return
	steady_left = randf_range(MIN_STEADY_SECONDS, MAX_STEADY_SECONDS)
	play_flicker()


func play_flicker() -> void:
	var tween := create_tween()
	for step_index: int in FLICKER_STEPS:
		var alpha := DIM_ALPHA if step_index % 2 == 0 else full_alpha
		tween.tween_property(label, "modulate:a", alpha, randf_range(0.03, 0.09))
	tween.tween_property(label, "modulate:a", full_alpha, 0.05)
