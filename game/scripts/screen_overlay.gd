class_name ScreenOverlay
extends CanvasLayer

const SHADER_PATH := "res://shaders/screen_overlay.gdshader"
const DANGER_FADE_SPEED := 2.0

var overlay_material: ShaderMaterial
var target_danger := 0.0
var current_danger := 0.0


func _ready() -> void:
	layer = 1
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = load(SHADER_PATH)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = overlay_material
	add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	current_danger = move_toward(current_danger, target_danger, DANGER_FADE_SPEED * delta)
	overlay_material.set_shader_parameter("danger", current_danger)


func set_danger(amount: float) -> void:
	target_danger = clampf(amount, 0.0, 1.0)


func set_vignette(strength: float) -> void:
	overlay_material.set_shader_parameter("vignette_strength", strength)
