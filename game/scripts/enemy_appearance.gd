class_name EnemyAppearance
extends RefCounted

const ROOT := Models.GRAPHICS_ROOT + "enemies/"
const BONE_NAMES := {"head": ["head", "head_2"], "torso": ["torso", "torso_2"]}


static func attach(role: String, model: Node3D) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Enemy appearance requires a skeleton: " + role)
		return
	var skeleton: Skeleton3D = skeletons[0]
	var bounds := Models.get_world_bounds(model)
	var origin := Vector3(model.global_position.x, bounds.position.y, model.global_position.z)
	var normalized_pose := Transform3D(model.global_basis.orthonormalized() * bounds.size.y, origin)
	var authored_to_skeleton := skeleton.global_transform.affine_inverse() * normalized_pose
	var gear := Models.spawn(model, ROOT + role + ".glb", Vector3.ZERO)
	for part: MeshInstance3D in gear.find_children("*", "MeshInstance3D", true, false):
		attach_part(part, gear, skeleton, authored_to_skeleton)
	gear.queue_free()


static func attach_part(part: MeshInstance3D, gear: Node3D, skeleton: Skeleton3D, authored_to_skeleton: Transform3D) -> void:
	var name_parts := String(part.name).split("_")
	var bone_index := find_bone(skeleton, name_parts[-1].to_lower())
	if bone_index < 0:
		push_error("Missing appearance bone: " + part.name)
		return
	var part_pose := gear.global_transform.affine_inverse() * part.global_transform
	var attachment := BoneAttachment3D.new()
	attachment.name = "Appearance_" + part.name
	attachment.bone_name = skeleton.get_bone_name(bone_index)
	skeleton.add_child(attachment)
	part.reparent(attachment, false)
	part.transform = skeleton.get_bone_global_rest(bone_index).affine_inverse() * authored_to_skeleton * part_pose
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func find_bone(skeleton: Skeleton3D, name: String) -> int:
	for index: int in skeleton.get_bone_count():
		if skeleton.get_bone_name(index).to_lower() in BONE_NAMES.get(name, []):
			return index
	return -1
