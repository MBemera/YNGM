class_name ValuationBubble
extends Node3D

const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const SHADER_PATH := "res://shaders/bubble.gdshader"
const START_RADIUS := 0.25
const END_RADIUS := 1.0
const GROW_SECONDS := 1.0
const LIFETIME_SECONDS := 1.8
const POP_RADIUS := 4.5
const EDGE_DAMAGE_FRACTION := 0.6
const DRAG := 0.6
const PROXIMITY_FRACTION := 0.9
const POP_TEXTS: Array[String] = ["POP!", "CORRECTION!", "MARKDOWN!", "BUBBLE BURST!"]

var velocity := Vector3.ZERO
var damage := 100
var color := Color(1.0, 0.55, 0.9)
var shooter: Player
var age := 0.0
var radius := START_RADIUS
var visual: MeshInstance3D
var has_popped := false


static func spawn(parent: Node, origin: Vector3, launch_velocity: Vector3, weapon: Dictionary, bubble_shooter: Player) -> ValuationBubble:
	var bubble := ValuationBubble.new()
	bubble.velocity = launch_velocity
	bubble.damage = weapon["damage"]
	bubble.color = weapon["color"]
	bubble.shooter = bubble_shooter
	parent.add_child(bubble)
	bubble.global_position = origin
	return bubble


func _ready() -> void:
	visual = create_visual()
	add_child(visual)
	var glow := OmniLight3D.new()
	glow.light_color = color
	glow.light_energy = 1.2
	glow.omni_range = 3.0
	add_child(glow)


func create_visual() -> MeshInstance3D:
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH)
	material.set_shader_parameter("tint", color)
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var sphere := MeshInstance3D.new()
	sphere.mesh = mesh
	sphere.material_override = material
	sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere.scale = Vector3.ONE * START_RADIUS
	return sphere


func _physics_process(delta: float) -> void:
	if has_popped:
		return
	age += delta
	radius = lerpf(START_RADIUS, END_RADIUS, clampf(age / GROW_SECONDS, 0.0, 1.0))
	visual.scale = Vector3.ONE * radius * (1.0 + 0.05 * sin(age * 18.0))
	velocity *= maxf(1.0 - DRAG * delta, 0.0)
	var next_position := global_position + velocity * delta
	if hits_something(global_position, next_position) or touches_enemy() or age >= LIFETIME_SECONDS:
		pop()
		return
	global_position = next_position


func hits_something(from: Vector3, to: Vector3) -> bool:
	var excluded: Array[RID] = []
	if shooter != null and is_instance_valid(shooter):
		excluded.append(shooter.get_rid())
	var query := PhysicsRayQueryParameters3D.create(from, to + velocity.normalized() * radius, WORLD_LAYER | ENEMY_LAYER, excluded)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func touches_enemy() -> bool:
	for target: Node3D in WeaponFire.get_living_damageables(get_tree()):
		if WeaponFire.get_target_point(target).distance_to(global_position) < radius + PROXIMITY_FRACTION:
			return true
	return false


func pop() -> void:
	has_popped = true
	var origin := global_position
	var parent := get_parent() as Node3D
	WeaponFire.apply_splash(parent, origin, POP_RADIUS, damage, EDGE_DAMAGE_FRACTION, shooter)
	Effects.spawn_shockwave(parent, origin, Color(color, 0.35), POP_RADIUS, 0.3)
	Effects.spawn_confetti_burst(parent, origin, 40)
	Effects.spawn_flash(parent, origin, color, 8.0, 9.0, 0.35)
	spawn_pop_text(parent, origin)
	AudioBank.play_at(parent, AudioBank.POP, origin, randf_range(0.9, 1.1), 4.0)
	Enemy.alert_enemies_near(get_tree(), origin, POP_RADIUS * 3.0)
	queue_free()


func spawn_pop_text(parent: Node3D, origin: Vector3) -> void:
	var label := LevelBuilder.add_sign(parent, POP_TEXTS[randi() % POP_TEXTS.size()], Vector3.ZERO, 0.0, 96, color.lightened(0.3))
	label.global_position = origin + Vector3.UP * 0.6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", origin.y + 2.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)
