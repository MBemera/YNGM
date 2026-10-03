class_name Effects
extends RefCounted

const CONFETTI_COLORS: Array[Color] = [
	Color(1.0, 0.3, 0.5),
	Color(0.3, 0.8, 1.0),
	Color(1.0, 0.9, 0.2),
	Color(0.5, 1.0, 0.4),
	Color(0.8, 0.5, 1.0),
]
const SLOP_COLORS: Array[Color] = [
	Color(0.45, 0.85, 0.15),
	Color(0.35, 0.25, 0.1),
	Color(0.7, 1.0, 0.3),
	Color(0.55, 0.2, 0.6),
]
const SLOP_FLASH_COLOR := Color(0.6, 1.0, 0.3)
const SLOP_SHOCKWAVE_COLOR := Color(0.55, 1.0, 0.2, 0.4)


static func create_particles() -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


static func random_confetti_color() -> Color:
	return CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]


static func spawn_confetti_burst(parent: Node, position: Vector3, amount: int) -> void:
	var particles := create_particles()
	particles.amount = amount
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 7.0
	particles.damping_min = 2.0
	particles.damping_max = 4.0
	particles.gravity = Vector3(0, -6, 0)
	particles.mesh = create_particle_mesh(Vector3(0.12, 0.02, 0.08), false)
	particles.color_initial_ramp = create_confetti_gradient()
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func spawn_puff(parent: Node, position: Vector3, color: Color) -> void:
	var particles := create_particles()
	particles.amount = 8
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 1.2
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3(0, -3, 0)
	particles.mesh = create_particle_mesh(Vector3(0.08, 0.08, 0.08), false)
	particles.color = color
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func spawn_hit_burst(parent: Node, position: Vector3, color: Color) -> void:
	var particles := create_particles()
	particles.amount = 14
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(0, -8, 0)
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.4
	particles.mesh = create_particle_mesh(Vector3(0.09, 0.09, 0.09), false)
	particles.color = color
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func spawn_muzzle_flash(parent: Node, position: Vector3, color: Color) -> void:
	spawn_flash(parent, position, color, 3.0, 4.0, 0.08)
	var particles := create_particles()
	particles.amount = 6
	particles.lifetime = 0.12
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3.ZERO
	particles.mesh = create_particle_mesh(Vector3(0.03, 0.03, 0.03), false)
	particles.color = color.lightened(0.4)
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.3)


static func create_fire(offset: Vector3) -> CPUParticles3D:
	var particles := create_particles()
	particles.amount = 24
	particles.lifetime = 0.9
	particles.direction = Vector3.UP
	particles.spread = 15.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.2
	particles.gravity = Vector3(0, 1.0, 0)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.25
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.mesh = create_particle_mesh(Vector3(0.14, 0.14, 0.14), true)
	particles.color_ramp = create_fire_gradient()
	particles.position = offset
	return particles


static func create_smoke_plume(base_position: Vector3) -> CPUParticles3D:
	var particles := create_particles()
	particles.amount = 40
	particles.lifetime = 14.0
	particles.preprocess = 14.0
	particles.direction = Vector3.UP
	particles.spread = 12.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(1.2, 0.4, 0.3)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 4.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 12.0
	particles.mesh = create_smoke_mesh()
	particles.color_ramp = create_smoke_gradient()
	particles.position = base_position
	return particles


static func create_smoke_mesh() -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1, 1)
	mesh.material = material
	return mesh


static func create_smoke_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 0.45, 0.1, 0.0), Color(0.18, 0.12, 0.1, 0.55), Color(0.1, 0.08, 0.08, 0.0)])
	return gradient


static func create_embers() -> CPUParticles3D:
	var particles := create_particles()
	particles.amount = 70
	particles.lifetime = 5.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(16, 3, 16)
	particles.direction = Vector3.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 0.4
	particles.initial_velocity_max = 1.2
	particles.gravity = Vector3(0.6, 0.25, 0.2)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.2
	particles.mesh = create_particle_mesh(Vector3(0.05, 0.05, 0.05), true)
	particles.color_ramp = create_ember_gradient()
	particles.position = Vector3(0, 2, 0)
	return particles


static func create_ember_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	gradient.colors = PackedColorArray([Color(3.0, 1.2, 0.3, 0.0), Color(3.0, 1.1, 0.25, 1.0), Color(2.0, 0.5, 0.1, 0.8), Color(1.0, 0.2, 0.05, 0.0)])
	return gradient


static func create_falling_ash() -> CPUParticles3D:
	var particles := create_particles()
	particles.amount = 220
	particles.lifetime = 7.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(18, 0.5, 18)
	particles.direction = Vector3.DOWN
	particles.spread = 20.0
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.8
	particles.gravity = Vector3(0.3, -0.6, 0.1)
	particles.mesh = create_particle_mesh(Vector3(0.05, 0.05, 0.05), false)
	particles.color = Color(0.78, 0.75, 0.72)
	particles.position = Vector3(0, 9, 0)
	return particles


static func create_particle_mesh(size: Vector3, is_transparent: bool) -> BoxMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if is_transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	return mesh


static func create_confetti_gradient() -> Gradient:
	return create_palette_gradient(CONFETTI_COLORS)


static func create_palette_gradient(palette: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for index: int in palette.size():
		offsets.append(float(index) / palette.size())
		colors.append(palette[index])
	gradient.offsets = offsets
	gradient.colors = colors
	return gradient


static func spawn_slop_explosion(parent: Node, position: Vector3) -> void:
	spawn_flash(parent, position + Vector3.UP * 0.5, SLOP_FLASH_COLOR, 12.0, 16.0, 0.6)
	spawn_shockwave(parent, position, SLOP_SHOCKWAVE_COLOR, 6.5, 0.4)
	spawn_slop_splatter(parent, position)
	spawn_slop_smoke(parent, position)


static func spawn_flash(parent: Node, position: Vector3, color: Color, energy: float, light_range: float, seconds: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	parent.add_child(light)
	light.global_position = position
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, seconds)
	tween.tween_callback(light.queue_free)


static func spawn_shockwave(parent: Node, position: Vector3, color: Color, radius: float, seconds: float) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var ball := MeshInstance3D.new()
	ball.mesh = mesh
	ball.material_override = material
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ball)
	ball.global_position = position
	ball.scale = Vector3.ONE * 0.2
	var tween := ball.create_tween().set_parallel(true)
	tween.tween_property(ball, "scale", Vector3.ONE * radius, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, seconds)
	tween.chain().tween_callback(ball.queue_free)


static func spawn_slop_splatter(parent: Node, position: Vector3) -> void:
	var particles := create_particles()
	particles.amount = 90
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 80.0
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 13.0
	particles.gravity = Vector3(0, -16, 0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.8
	particles.mesh = create_blob_mesh(0.09)
	particles.color_initial_ramp = create_palette_gradient(SLOP_COLORS)
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func spawn_slop_smoke(parent: Node, position: Vector3) -> void:
	var particles := create_particles()
	particles.amount = 14
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.direction = Vector3.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 1.5
	particles.initial_velocity_max = 3.5
	particles.damping_min = 1.0
	particles.damping_max = 2.0
	particles.gravity = Vector3(0, 0.8, 0)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 1.2
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 4.5
	particles.mesh = create_smoke_mesh()
	particles.color_ramp = create_slop_smoke_gradient()
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func create_blob_mesh(radius: float) -> SphereMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = material
	return mesh


static func create_slop_smoke_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	gradient.colors = PackedColorArray([Color(0.6, 1.0, 0.3, 0.0), Color(0.3, 0.45, 0.12, 0.6), Color(0.15, 0.15, 0.1, 0.0)])
	return gradient


static func create_fire_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 0.9, 0.3), Color(1.0, 0.4, 0.05), Color(0.4, 0.05, 0.0, 0.0)])
	return gradient


static func free_after(node: Node, seconds: float) -> void:
	node.get_tree().create_timer(seconds).timeout.connect(node.queue_free)


static var trail_material_cache: Dictionary = {}


static func get_trail_material(color: Color) -> StandardMaterial3D:
	var cache_key := color.to_html()
	if trail_material_cache.has(cache_key):
		return trail_material_cache[cache_key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color, 0.35)
	trail_material_cache[cache_key] = material
	return material


static func spawn_damage_number(parent: Node, position: Vector3, amount: int) -> void:
	var label := Label3D.new()
	label.text = "-$%dM" % amount
	label.font_size = 44 if amount < 60 else 64
	label.modulate = Color(1.0, 0.9, 0.3) if amount < 60 else Color(1.0, 0.45, 0.2)
	label.outline_size = 10
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0013
	label.shaded = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
	label.global_position = position + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + 0.9, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.25)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.45).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)


static func spawn_coin_burst(parent: Node, position: Vector3, amount: int) -> void:
	var particles := create_particles()
	particles.amount = amount
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 50.0
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 7.0
	particles.angular_velocity_min = 360.0
	particles.angular_velocity_max = 720.0
	particles.gravity = Vector3(0, -14, 0)
	particles.mesh = create_coin_mesh()
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func create_coin_mesh() -> CylinderMesh:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.25)
	material.metallic = 0.9
	material.roughness = 0.25
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.2)
	material.emission_energy_multiplier = 0.4
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.07
	mesh.height = 0.02
	mesh.radial_segments = 10
	mesh.material = material
	return mesh


static func spawn_spark_burst(parent: Node, position: Vector3, color: Color, amount: int) -> void:
	var particles := create_particles()
	particles.amount = amount
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 11.0
	particles.damping_min = 3.0
	particles.damping_max = 6.0
	particles.gravity = Vector3(0, -9, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.3
	particles.mesh = create_particle_mesh(Vector3(0.04, 0.04, 0.18), false)
	particles.color = Color(color.r * 2.5, color.g * 2.5, color.b * 2.5)
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	free_after(particles, particles.lifetime + 0.5)


static func spawn_beam(parent: Node, from: Vector3, to: Vector3, color: Color, width: float, seconds: float) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var direction := (to - from) / length
	var up := Vector3.UP if absf(direction.y) < 0.99 else Vector3.FORWARD
	var core := create_beam_segment(length, width, Color(1, 1, 1, 0.9))
	var glow := create_beam_segment(length, width * 3.5, Color(color, 0.45))
	for segment: MeshInstance3D in [core, glow]:
		parent.add_child(segment)
		segment.global_position = (from + to) / 2.0
		segment.look_at(to, up)
		var material: StandardMaterial3D = segment.material_override
		var tween := segment.create_tween().set_parallel(true)
		tween.tween_property(material, "albedo_color:a", 0.0, seconds)
		tween.tween_property(segment, "scale", Vector3(0.2, 0.2, 1.0), seconds)
		tween.chain().tween_callback(segment.queue_free)


static func create_beam_segment(length: float, width: float, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, width, length)
	var segment := MeshInstance3D.new()
	segment.mesh = mesh
	segment.material_override = material
	segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return segment


static func spawn_lightning(parent: Node, points: Array[Vector3], color: Color, seconds: float) -> void:
	for index: int in points.size() - 1:
		var jagged := create_jagged_path(points[index], points[index + 1])
		for step: int in jagged.size() - 1:
			spawn_beam(parent, jagged[step], jagged[step + 1], color, 0.05, seconds)


static func create_jagged_path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var path: Array[Vector3] = [from]
	var segment_count := clampi(int(from.distance_to(to) / 1.2), 2, 10)
	for step: int in range(1, segment_count):
		var point := from.lerp(to, float(step) / segment_count)
		path.append(point + Vector3(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35), randf_range(-0.35, 0.35)))
	path.append(to)
	return path


static func create_rain() -> CPUParticles3D:
	var particles := create_particles()
	particles.amount = 500
	particles.lifetime = 1.1
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(20, 0.5, 20)
	particles.direction = Vector3.DOWN
	particles.spread = 3.0
	particles.initial_velocity_min = 16.0
	particles.initial_velocity_max = 20.0
	particles.gravity = Vector3(1.5, -6, 0)
	particles.mesh = create_streak_mesh(Color(0.7, 0.8, 1.0, 0.35))
	particles.position = Vector3(0, 14, 0)
	return particles


static func create_streak_mesh(color: Color) -> BoxMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.015, 0.5, 0.015)
	mesh.material = material
	return mesh


static func create_data_motes(color: Color) -> CPUParticles3D:
	var particles := create_particles()
	particles.amount = 120
	particles.lifetime = 6.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(16, 4, 16)
	particles.direction = Vector3.UP
	particles.spread = 40.0
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.6
	particles.gravity = Vector3(0, 0.1, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.mesh = create_particle_mesh(Vector3(0.04, 0.04, 0.04), true)
	particles.color_ramp = create_mote_gradient(color)
	particles.position = Vector3(0, 2, 0)
	return particles


static func create_mote_gradient(color: Color) -> Gradient:
	var bright := Color(color.r * 2.0, color.g * 2.0, color.b * 2.0)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	gradient.colors = PackedColorArray([Color(color, 0.0), Color(bright, 0.9), Color(bright, 0.6), Color(color, 0.0)])
	return gradient


static func create_ambient_particles(kind: String) -> CPUParticles3D:
	match kind:
		"ash":
			return create_falling_ash()
		"embers":
			return create_embers()
		"rain":
			return create_rain()
		"data":
			return create_data_motes(Color(0.3, 0.8, 1.0))
		"gold":
			return create_data_motes(Color(1.0, 0.75, 0.3))
	push_warning("Unknown ambient particle kind: " + kind)
	return null
