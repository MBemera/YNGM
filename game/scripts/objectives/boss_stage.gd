class_name BossStage
extends ObjectiveStage

var bosses: Array[Enemy] = []
var total_max_health := 0


func begin() -> void:
	for spawn: Dictionary in config["bosses"]:
		var boss: Enemy = spawn_enemy.call(spawn)
		boss.defeated.connect(_on_boss_defeated)
		bosses.append(boss)
		total_max_health += boss.max_health
	super.begin()
	AudioBank.play_ui(self, AudioBank.ALARM, -6.0)


func get_boss_progress() -> float:
	if is_finished or total_max_health <= 0:
		return -1.0
	var remaining := 0
	for boss: Enemy in bosses:
		remaining += maxi(boss.health, 0)
	return float(remaining) / total_max_health


func get_boss_name() -> String:
	return config.get("boss_name", "BOSS")


func _on_boss_defeated(boss: Enemy) -> void:
	bosses.erase(boss)
	if bosses.is_empty():
		finish()
