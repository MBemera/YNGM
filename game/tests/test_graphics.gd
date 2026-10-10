extends SceneTree

var check_count := 0
var failures: Array[String] = []


func _initialize() -> void:
	SaveData.is_persistence_enabled = false
	run_tests.call_deferred()


func run_tests() -> void:
	validate_assets("weapons", 800)
	validate_assets("enemies", 500)
	validate_assets("scenery", 800)
	await test_weapon_animations()
	await test_enemy_attachments()
	test_scenery_placements()
	print("%d graphics checks, %d failed" % [check_count, failures.size()])
	quit(0 if failures.is_empty() else 1)


func validate_assets(folder: String, triangle_limit: int) -> void:
	var root_path := Models.GRAPHICS_ROOT + folder + "/"
	var gallery := Node3D.new()
	root.add_child(gallery)
	for filename: String in DirAccess.get_files_at(root_path):
		if not filename.ends_with(".glb"):
			continue
		var model := Models.spawn(gallery, root_path + filename, Vector3.ZERO)
		var triangles := 0
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			triangles += count_triangles(mesh.mesh)
			check(has_vertex_colors(mesh.mesh), filename + " retains its colour palette")
			check(mesh.material_override == Models.palette_material, filename + " shares the palette material")
		check(triangles > 0 and triangles <= triangle_limit, "%s stays within %d triangles (%d)" % [filename, triangle_limit, triangles])
		model.free()
	gallery.free()


func count_triangles(mesh: Mesh) -> int:
	var triangles := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		triangles += (indices.size() if not indices.is_empty() else vertices.size()) / 3
	return triangles


func has_vertex_colors(mesh: Mesh) -> bool:
	for surface: int in mesh.get_surface_count():
		var colors: PackedColorArray = mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
		if colors.is_empty():
			return false
	return true


func test_weapon_animations() -> void:
	var player := Player.new()
	root.add_child(player)
	player.is_frozen = true
	player.unlocked_weapon_count = Weapons.ALL.size()
	for index: int in Weapons.ALL.size():
		player.select_weapon(index)
		await process_frame
		if Weapons.get_weapon(index)["kind"] == Weapons.GRENADE:
			continue
		var animation := player.weapon_animation
		check(animation != null and animation.has_animation("fire"), "weapon %d imports its firing animation" % (index + 1))
		if animation == null:
			continue
		var mechanism := player.weapon_model.find_child("*_Mechanism", true, false) as Node3D
		check(mechanism != null, "weapon %d imports a moving mechanism" % (index + 1))
		if mechanism == null:
			continue
		var before := mechanism.transform
		player.play_fire_feedback(Weapons.get_weapon(index), player.get_muzzle_position())
		animation.advance(0.06)
		check(animation.current_animation == "fire" and not mechanism.transform.is_equal_approx(before), "weapon %d moves its mechanism when fired" % (index + 1))
	player.queue_free()
	await process_frame


func test_enemy_attachments() -> void:
	var gallery := Node3D.new()
	root.add_child(gallery)
	for role: String in EnemyTypes.CONFIGS:
		var config: Dictionary = EnemyTypes.CONFIGS[role]
		for filename: String in config["models"]:
			var model := EnemyModels.build(role, filename, gallery)
			await process_frame
			var attachments := model.find_children("Appearance_*", "BoneAttachment3D", true, false)
			check(attachments.size() == 2, "%s / %s has torso and head equipment" % [role, filename])
			for attachment: BoneAttachment3D in attachments:
				check(attachment.bone_idx >= 0 and attachment.get_child_count() == 1, role + " equipment follows an existing bone")
			var animations := Models.find_animation_player(model)
			check(animations != null and animations.has_animation(config["animations"]["attack"]), role + " retains its attack animation")
			model.free()
	gallery.free()


func test_scenery_placements() -> void:
	check(GraphicsScenery.PLACEMENTS.size() == 11, "every level receives authored scenery")
	for level_number: int in range(1, 12):
		var level := LevelCatalog.create(level_number)
		for placement: Array in GraphicsScenery.PLACEMENTS[level_number]:
			check(level.navigation_bounds.has_point(placement[1] + Vector3.UP * 0.1), "level %d scenery is inside its playable bounds" % level_number)


func check(condition: bool, message: String) -> void:
	check_count += 1
	if condition:
		return
	failures.append(message)
	push_error("FAIL " + message)
