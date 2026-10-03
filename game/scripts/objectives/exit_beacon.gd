class_name ExitBeacon
extends Area3D

signal player_entered

const PLAYER_LAYER := 2
const COLUMN_HEIGHT := 9.0
const RING_SPIN_RADIANS_PER_SECOND := 1.2
const PULSE_SPEED := 3.0

var radius := 2.0
var color := Color(0.3, 1.0, 0.6)
var label_text := "EXIT"
var ring: MeshInstance3D
var column_material: StandardMaterial3D
var pulse_time := 0.0
var has_triggered := false


static func spawn(parent: Node3D, floor_position: Vector3, beacon_radius: float, beacon_color: Color, text: String) -> ExitBeacon:
	var beacon := ExitBeacon.new()
	beacon.radius = beacon_radius
	beacon.color = beacon_color
	beacon.label_text = text
	beacon.position = floor_position
	parent.add_child(beacon)
	return beacon


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	add_trigger_shape()
	add_column()
	ring = add_ring()
	add_label()
	add_light()


func _process(delta: float) -> void:
	pulse_time += delta
	ring.rotate_y(RING_SPIN_RADIANS_PER_SECOND * delta)
	ring.position.y = 0.15 + (sin(pulse_time * PULSE_SPEED) * 0.5 + 0.5) * 1.6
	column_material.albedo_color.a = 0.14 + 0.06 * sin(pulse_time * PULSE_SPEED * 1.3)


func _physics_process(_delta: float) -> void:
	if has_triggered:
		return
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			has_triggered = true
			player_entered.emit()
			return


func add_trigger_shape() -> void:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 4.0
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 2.0, 0)
	add_child(collision)


func add_column() -> void:
	column_material = StandardMaterial3D.new()
	column_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	column_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	column_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	column_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	column_material.albedo_color = Color(color, 0.18)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.8
	mesh.bottom_radius = radius
	mesh.height = COLUMN_HEIGHT
	mesh.cap_top = false
	mesh.cap_bottom = false
	var column := MeshInstance3D.new()
	column.mesh = mesh
	column.material_override = column_material
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.position = Vector3(0, COLUMN_HEIGHT / 2.0, 0)
	add_child(column)
	var floor_disc := LevelBuilder.add_decor(self, Vector3(radius * 1.6, 0.04, radius * 1.6), Vector3(0, 0.03, 0), color, 2.0)
	floor_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func add_ring() -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.9
	mesh.outer_radius = radius
	var ring_instance := MeshInstance3D.new()
	ring_instance.mesh = mesh
	ring_instance.material_override = LevelBuilder.get_material(color, 4.0)
	ring_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring_instance)
	return ring_instance


func add_label() -> void:
	var label := LevelBuilder.add_sign(self, label_text, Vector3(0, 3.6, 0), 0.0, 64, color)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0012


func add_light() -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.5
	light.omni_range = radius * 4.0
	light.position = Vector3(0, 1.5, 0)
	add_child(light)
