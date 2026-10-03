class_name Crosshair
extends Control

const GAP := 5.0
const ARM_LENGTH := 8.0
const THICKNESS := 2.0
const SPREAD_KICK := 7.0
const SPREAD_RECOVERY := 30.0
const MARKER_SECONDS := 0.18
const MARKER_SIZE := 9.0
const BASE_COLOR := Color(1, 1, 1, 0.9)
const HIT_COLOR := Color(1, 1, 1, 1)
const DEFEAT_COLOR := Color(1.0, 0.3, 0.25, 1)

var spread := 0.0
var marker_left := 0.0
var marker_color := HIT_COLOR


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	spread = move_toward(spread, 0.0, SPREAD_RECOVERY * delta)
	marker_left = maxf(marker_left - delta, 0.0)
	queue_redraw()


func kick() -> void:
	spread = minf(spread + SPREAD_KICK, 18.0)


func show_hit(was_defeat: bool) -> void:
	marker_left = MARKER_SECONDS * (1.6 if was_defeat else 1.0)
	marker_color = DEFEAT_COLOR if was_defeat else HIT_COLOR


func _draw() -> void:
	var center := size / 2.0
	var offset := GAP + spread
	draw_arm(center + Vector2(0, -offset), Vector2(0, -ARM_LENGTH))
	draw_arm(center + Vector2(0, offset), Vector2(0, ARM_LENGTH))
	draw_arm(center + Vector2(-offset, 0), Vector2(-ARM_LENGTH, 0))
	draw_arm(center + Vector2(offset, 0), Vector2(ARM_LENGTH, 0))
	draw_circle(center, 1.5, BASE_COLOR)
	if marker_left > 0.0:
		draw_hit_marker(center)


func draw_arm(start: Vector2, extent: Vector2) -> void:
	draw_line(start, start + extent, Color(0, 0, 0, 0.6), THICKNESS + 2.0)
	draw_line(start, start + extent, BASE_COLOR, THICKNESS)


func draw_hit_marker(center: Vector2) -> void:
	var color := Color(marker_color, marker_left / MARKER_SECONDS)
	for direction: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var inner := center + direction * 6.0
		draw_line(inner, inner + direction * MARKER_SIZE, color, 2.5)
