class_name DestroyStage
extends ObjectiveStage

var targets: Array[DestructibleTarget] = []
var destroyed_count := 0


func begin() -> void:
	for target_config: Dictionary in config["targets"]:
		var target := DestructibleTarget.spawn(get_parent(), target_config)
		target.destroyed.connect(_on_target_destroyed)
		targets.append(target)
	super.begin()


func get_text() -> String:
	var base_text: String = config.get("text", "Destroy the targets")
	return "%s  (%d / %d)" % [base_text, destroyed_count, config["targets"].size()]


func get_remaining_targets() -> Array[DestructibleTarget]:
	var remaining: Array[DestructibleTarget] = []
	for target: DestructibleTarget in targets:
		if not target.is_destroyed:
			remaining.append(target)
	return remaining


func _on_target_destroyed(target: DestructibleTarget) -> void:
	targets.erase(target)
	destroyed_count += 1
	text_changed.emit(get_text())
	if destroyed_count >= config["targets"].size():
		finish()
