class_name Hologram
extends Node3D

const CHARACTER_PATH := "res://assets/models/characters/character-male-e.glb"
const DETAIL_TEXTURE_PATH := "res://assets/models/characters/Textures/colormap.png"
const SHADER_PATH := "res://shaders/hologram.gdshader"
const HEIGHT := 8.5
const HOLOGRAM_COLOR := Color(0.05, 0.55, 1.0)

var animation_player: AnimationPlayer


func _ready() -> void:
	var character := Models.spawn_fitted(self, CHARACTER_PATH, Vector3.ZERO, 0.0, HEIGHT)
	apply_hologram_material(character)
	animation_player = Models.find_animation_player(character)
	if animation_player != null:
		Models.loop_animations(animation_player, ["idle"])
		animation_player.play("idle")
	build_projector()


func apply_hologram_material(character: Node3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH)
	material.set_shader_parameter("detail_texture", load(DETAIL_TEXTURE_PATH))
	material.set_shader_parameter("hologram_color", HOLOGRAM_COLOR)
	for mesh_instance: MeshInstance3D in character.find_children("*", "MeshInstance3D", true, false):
		mesh_instance.material_override = material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func build_projector() -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.6
	base_mesh.bottom_radius = 1.9
	base_mesh.height = 0.25
	base.mesh = base_mesh
	base.material_override = LevelBuilder.get_material(HOLOGRAM_COLOR, 2.5)
	base.position = Vector3(0, 0.12, 0)
	add_child(base)
	var glow := OmniLight3D.new()
	glow.light_color = HOLOGRAM_COLOR
	glow.light_energy = 2.5
	glow.omni_range = 9.0
	glow.position = Vector3(0, 2.0, 1.5)
	add_child(glow)


func play_gesture(animation_name: String) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		return
	animation_player.play(animation_name, 0.2)
	animation_player.queue("idle")


func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.01, 1.0), 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
