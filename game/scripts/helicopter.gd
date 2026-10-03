class_name Helicopter
extends Node3D

signal player_grabbed_ladder

const PLAYER_LAYER := 2
const MODEL_SCALE := 2.6
const MODEL_YAW := 90.0
const SKID_Y := -1.6
const LADDER_LENGTH := 6.6
const LADDER_WIDTH := 0.66
const RUNG_SPACING := 0.4
const SLOW_RETRACT_DISTANCE := 1.8
const LADDER_ANCHOR := Vector3(0, -1.1, 0)
const STATIC_ROTOR_MATERIAL := "Material.002"
const LEADER_VOICE := "norman"
const ROTOR_RADIUS := 5.6
const ROTOR_RADIANS_PER_SECOND := 18.0
const METAL_COLOR := Color(0.25, 0.25, 0.27)
const ROPE_COLOR := Color(0.85, 0.72, 0.45)
const GOLD := Color(1.0, 0.85, 0.3)

var ladder: Node3D
var ladder_area: Area3D
var ladder_shape: BoxShape3D
var rotor: Node3D
var leaders_bubble: Label3D
var is_ladder_active := false
var current_ladder_length := LADDER_LENGTH
var body_top_y := 0.0


func _ready() -> void:
	build_body()
	rotor = build_rotor()
	build_labels()
	build_ladder()
	build_ladder_area()
	start_rotor_audio()


func _process(delta: float) -> void:
	rotor.rotate_y(ROTOR_RADIANS_PER_SECOND * delta)


func _physics_process(_delta: float) -> void:
	if not is_ladder_active:
		return
	for body: Node3D in ladder_area.get_overlapping_bodies():
		if body is Player:
			is_ladder_active = false
			player_grabbed_ladder.emit()
			return


func build_body() -> void:
	var body := Models.spawn(self, Models.HELICOPTER, Vector3.ZERO, MODEL_YAW, MODEL_SCALE)
	var bounds := Models.get_world_bounds(body)
	var local_center := to_local(bounds.get_center())
	var local_bottom := to_local(bounds.position).y
	body.position += Vector3(-local_center.x, SKID_Y - local_bottom, -local_center.z)
	body_top_y = SKID_Y + bounds.size.y
	hide_static_rotor(body)


func hide_static_rotor(body: Node3D) -> void:
	var invisible := LevelBuilder.get_material(Color(0, 0, 0, 0))
	for mesh_instance: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		for surface_index: int in mesh_instance.mesh.get_surface_count():
			var surface_material := mesh_instance.mesh.surface_get_material(surface_index)
			if surface_material != null and surface_material.resource_name == STATIC_ROTOR_MATERIAL:
				mesh_instance.set_surface_override_material(surface_index, invisible)


func build_rotor() -> Node3D:
	var rotor_hub := Node3D.new()
	rotor_hub.position = Vector3(0, body_top_y + 0.05, 0)
	add_child(rotor_hub)
	LevelBuilder.add_decor(rotor_hub, Vector3(ROTOR_RADIUS * 2.0, 0.06, 0.3), Vector3.ZERO, METAL_COLOR)
	LevelBuilder.add_decor(rotor_hub, Vector3(0.3, 0.06, ROTOR_RADIUS * 2.0), Vector3.ZERO, METAL_COLOR)
	var blur := MeshInstance3D.new()
	var blur_mesh := CylinderMesh.new()
	blur_mesh.top_radius = ROTOR_RADIUS
	blur_mesh.bottom_radius = ROTOR_RADIUS
	blur_mesh.height = 0.02
	blur.mesh = blur_mesh
	blur.material_override = LevelBuilder.get_material(Color(0.1, 0.1, 0.12, 0.12))
	rotor_hub.add_child(blur)
	return rotor_hub


func build_labels() -> void:
	var name_label := LevelBuilder.add_sign(self, "OVERCLASS", Vector3(0, body_top_y + 0.9, 0), 0.0, 150, GOLD)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	leaders_bubble = LevelBuilder.add_sign(self, "", Vector3(0, body_top_y + 3.8, 0), 0.0, 64, Color(1, 0.95, 0.4))
	leaders_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	leaders_bubble.no_depth_test = true
	leaders_bubble.fixed_size = true
	leaders_bubble.pixel_size = 0.0014
	leaders_bubble.visible = false


func build_ladder() -> void:
	ladder = Node3D.new()
	ladder.position = LADDER_ANCHOR
	add_child(ladder)
	for rail_x: float in [-LADDER_WIDTH / 2.0, LADDER_WIDTH / 2.0]:
		LevelBuilder.add_decor(ladder, Vector3(0.06, LADDER_LENGTH, 0.06), Vector3(rail_x, -LADDER_LENGTH / 2.0, 0), ROPE_COLOR)
	var rung_count := int(LADDER_LENGTH / RUNG_SPACING)
	for rung_index: int in range(1, rung_count + 1):
		LevelBuilder.add_decor(ladder, Vector3(LADDER_WIDTH, 0.05, 0.08), Vector3(0, -rung_index * RUNG_SPACING, 0), ROPE_COLOR)


func build_ladder_area() -> void:
	ladder_area = Area3D.new()
	ladder_area.collision_layer = 0
	ladder_area.collision_mask = PLAYER_LAYER
	ladder_shape = BoxShape3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = ladder_shape
	ladder_area.add_child(collision)
	add_child(ladder_area)
	set_ladder_length(LADDER_LENGTH)


func start_rotor_audio() -> void:
	var rotor_audio := AudioStreamPlayer3D.new()
	rotor_audio.stream = AudioBank.ROTOR
	rotor_audio.unit_size = 12.0
	rotor_audio.max_distance = 90.0
	rotor_audio.volume_db = -2.0
	add_child(rotor_audio)
	rotor_audio.finished.connect(rotor_audio.play)
	rotor_audio.play()


func set_ladder_length(length: float) -> void:
	current_ladder_length = length
	ladder.scale = Vector3(1, maxf(length / LADDER_LENGTH, 0.001), 1)
	ladder_shape.size = Vector3(1.4, maxf(length, 0.1), 1.4)
	ladder_area.position = LADDER_ANCHOR + Vector3(0, -length / 2.0, 0)


func activate_ladder() -> void:
	is_ladder_active = true


func set_retract_progress(progress: float) -> void:
	if not is_ladder_active:
		return
	set_ladder_length(LADDER_LENGTH - SLOW_RETRACT_DISTANCE * clampf(progress, 0.0, 1.0))


func pull_ladder_up() -> void:
	is_ladder_active = false
	create_tween().tween_method(set_ladder_length, current_ladder_length, 0.0, 0.8)


func fly_away() -> void:
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(self, "position", position + Vector3(0, 35, -80), 7.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func get_ladder_bottom_position() -> Vector3:
	return to_global(LADDER_ANCHOR + Vector3(0, -current_ladder_length, 0))


func leaders_yell(line_index: int) -> void:
	leaders_bubble.text = Enemy.YELL_LINES[line_index]
	leaders_bubble.visible = true
	var clip := AudioBank.get_voice_clip(LEADER_VOICE, AudioBank.YELL_LINE_IDS[line_index])
	AudioBank.play_at(self, clip, global_position, 1.0, 10.0)
	get_tree().create_timer(3.0).timeout.connect(hide_leaders_bubble)


func hide_leaders_bubble() -> void:
	leaders_bubble.visible = false
