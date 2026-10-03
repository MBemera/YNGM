class_name HealthPack
extends Area3D

const PLAYER_LAYER := 2
const MODEL_PATH := Models.BLASTERS + "crate-small.glb"
const MODEL_LENGTH := 0.8
const HOVER_HEIGHT := 0.55
const BOB_HEIGHT := 0.12
const BOB_SPEED := 2.5
const SPIN_RADIANS_PER_SECOND := 1.6
const GLOW_GREEN := Color(0.25, 1.0, 0.4)
const LABEL_TEXT := "BRIDGE ROUND\n+%d MONTHS RUNWAY"

var runway_months := 8
var visual: Node3D
var bob_time := 0.0


static func spawn(parent: Node3D, floor_position: Vector3) -> HealthPack:
	var health_pack := HealthPack.new()
	health_pack.position = floor_position
	parent.add_child(health_pack)
	return health_pack


func _ready() -> void:
	runway_months = Difficulty.get_health_pack_months()
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	add_trigger_shape()
	visual = build_visual()
	add_label()
	add_glow()
	bob_time = randf() * TAU


func _process(delta: float) -> void:
	bob_time += delta
	visual.rotate_y(SPIN_RADIANS_PER_SECOND * delta)
	visual.position.y = HOVER_HEIGHT + sin(bob_time * BOB_SPEED) * BOB_HEIGHT


func _physics_process(_delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.needs_runway():
			collect(player)
			return


func add_trigger_shape() -> void:
	var shape := CylinderShape3D.new()
	shape.radius = 0.9
	shape.height = 2.0
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 1.0, 0)
	add_child(collision)


func build_visual() -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0, HOVER_HEIGHT, 0)
	add_child(pivot)
	var crate := Models.spawn(pivot, MODEL_PATH, Vector3.ZERO)
	var bounds := Models.get_world_bounds(crate)
	var longest_side := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	crate.scale = Vector3.ONE * (MODEL_LENGTH / longest_side)
	crate.position = -pivot.to_local(Models.get_world_bounds(crate).get_center())
	add_plus_sign(pivot)
	return pivot


func add_plus_sign(pivot: Node3D) -> void:
	var top_y := MODEL_LENGTH * 0.5 + 0.03
	LevelBuilder.add_decor(pivot, Vector3(0.42, 0.05, 0.13), Vector3(0, top_y, 0), GLOW_GREEN, 3.0)
	LevelBuilder.add_decor(pivot, Vector3(0.13, 0.05, 0.42), Vector3(0, top_y, 0), GLOW_GREEN, 3.0)


func add_label() -> void:
	var label := LevelBuilder.add_sign(self, LABEL_TEXT % runway_months, Vector3(0, HOVER_HEIGHT + 0.85, 0), 0.0, 22, GLOW_GREEN)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8


func add_glow() -> void:
	var glow := OmniLight3D.new()
	glow.light_color = GLOW_GREEN
	glow.light_energy = 1.8
	glow.omni_range = 3.5
	glow.position = Vector3(0, HOVER_HEIGHT + 0.4, 0)
	add_child(glow)


func collect(player: Player) -> void:
	player.restore_runway(runway_months)
	AudioBank.play_ui(player, AudioBank.PICKUP, -3.0)
	Effects.spawn_flash(get_parent(), global_position + Vector3.UP * 0.5, GLOW_GREEN, 4.0, 5.0, 0.4)
	Effects.spawn_puff(get_parent(), global_position + Vector3.UP * HOVER_HEIGHT, GLOW_GREEN)
	queue_free()
