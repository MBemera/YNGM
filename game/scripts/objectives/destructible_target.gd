class_name DestructibleTarget
extends StaticBody3D

signal destroyed(target: DestructibleTarget)

const GROUP := "destructibles"
const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const NAVIGATION_SHRINK := 0.3
const BAR_SEGMENTS := 10
const FLASH_SECONDS := 0.08

var display_name := "TARGET"
var model_path := ""
var model_height := 2.0
var max_health := 300
var health := 300
var accent_color := Color(1.0, 0.3, 0.3)
var model: Node3D
var health_label: Label3D
var navigation_blocker: StaticBody3D
var is_destroyed := false
var flash_material: StandardMaterial3D


static func spawn(parent: Node3D, config: Dictionary) -> DestructibleTarget:
	var target := DestructibleTarget.new()
	target.display_name = config.get("name", "TARGET")
	target.model_path = config["model"]
	target.model_height = config.get("height", 2.0)
	target.max_health = config.get("health", 300)
	target.health = target.max_health
	target.accent_color = config.get("color", Color(1.0, 0.3, 0.3))
	target.position = config["position"]
	target.rotation_degrees.y = config.get("yaw", 0.0)
	parent.add_child(target)
	return target


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = ENEMY_LAYER
	collision_mask = 0
	model = Models.spawn_fitted(self, model_path, Vector3.ZERO, 0.0, model_height)
	var bounds := Models.get_world_bounds(model)
	add_hit_shape(bounds)
	navigation_blocker = add_navigation_blocker(bounds)
	add_warning_light()
	health_label = create_health_label(bounds)
	flash_material = create_flash_material()
	update_health_label()


func add_hit_shape(bounds: AABB) -> void:
	var shape := BoxShape3D.new()
	shape.size = bounds.size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = to_local(bounds.get_center())
	collision.rotation = -rotation
	add_child(collision)


func add_navigation_blocker(bounds: AABB) -> StaticBody3D:
	var inner_size := (bounds.size - Vector3.ONE * NAVIGATION_SHRINK).max(Vector3.ONE * 0.1)
	return LevelBuilder.add_collider(get_parent(), inner_size, bounds.get_center())


func add_warning_light() -> void:
	var light := OmniLight3D.new()
	light.light_color = accent_color
	light.light_energy = 1.6
	light.omni_range = 4.5
	light.position = Vector3(0, model_height + 0.4, 0)
	add_child(light)


func create_health_label(bounds: AABB) -> Label3D:
	var label := LevelBuilder.add_sign(self, "", Vector3(0, bounds.size.y + 0.7, 0), 0.0, 40, accent_color)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 10
	return label


func create_flash_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(1, 1, 1, 0.0)
	return material


func update_health_label() -> void:
	var filled := ceili(float(health) / max_health * BAR_SEGMENTS)
	var bar := "|".repeat(filled) + ".".repeat(BAR_SEGMENTS - filled)
	health_label.text = "%s\n[%s]" % [display_name, bar]


func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	health = maxi(health - amount, 0)
	update_health_label()
	flash()
	AudioBank.play_at(get_parent(), AudioBank.HIT, global_position + Vector3.UP, 0.6, -4.0)
	if health == 0:
		destroy()


func flash() -> void:
	for mesh_instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh_instance.material_overlay = flash_material
	flash_material.albedo_color.a = 0.6
	var tween := create_tween()
	tween.tween_property(flash_material, "albedo_color:a", 0.0, FLASH_SECONDS)


func destroy() -> void:
	is_destroyed = true
	collision_layer = 0
	var center := global_position + Vector3.UP * model_height * 0.5
	Effects.spawn_flash(get_parent(), center, accent_color, 10.0, 12.0, 0.5)
	Effects.spawn_shockwave(get_parent(), center, Color(accent_color, 0.35), 4.0, 0.35)
	Effects.spawn_spark_burst(get_parent(), center, accent_color, 60)
	Effects.spawn_confetti_burst(get_parent(), center, 30)
	AudioBank.play_at(get_parent(), AudioBank.SLOP_EXPLOSION, center, 1.3, 2.0)
	destroyed.emit(self)
	navigation_blocker.queue_free()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(model, "scale", model.scale * Vector3(1.2, 0.05, 1.2), 0.35).set_ease(Tween.EASE_IN)
	tween.tween_property(health_label, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)
