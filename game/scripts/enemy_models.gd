class_name EnemyModels
extends RefCounted

const FACING_YAW_DEGREES := 180.0


static func pick_model_file(type_id: String) -> String:
	var config: Dictionary = EnemyTypes.CONFIGS[type_id]
	var model_names: Array = config["models"]
	return model_names[randi() % model_names.size()]


static func build(type_id: String, model_file: String, parent: Node3D) -> Node3D:
	var config: Dictionary = EnemyTypes.CONFIGS[type_id]
	var model_folder: String = config["model_folder"]
	var pivot := Node3D.new()
	parent.add_child(pivot)
	Models.spawn_fitted(pivot, model_folder + model_file, Vector3.ZERO, FACING_YAW_DEGREES, config["model_height"])
	return pivot
