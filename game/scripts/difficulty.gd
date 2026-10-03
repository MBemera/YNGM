class_name Difficulty
extends RefCounted

const EASY := "easy"
const NORMAL := "normal"
const HARD := "hard"
const NIGHTMARE := "nightmare"
const ORDER: Array[String] = [EASY, NORMAL, HARD, NIGHTMARE]
const PRESETS := {
	"easy": {
		"label": "EASY - TRUST FUND",
		"description": "More runway, bigger bridge rounds, sloppier enemies, longer timers.",
		"enemy_health": 0.65,
		"enemy_damage": 0.5,
		"enemy_aim_error": 1.7,
		"enemy_attack_cooldown": 1.4,
		"enemy_speed": 0.85,
		"enemy_reaction": 1.5,
		"player_runway": 36,
		"health_pack_months": 12,
		"countdown_time": 1.4,
		"survive_time": 0.75,
	},
	"normal": {
		"label": "NORMAL - SERIES A",
		"description": "The intended experience. You might make it.",
		"enemy_health": 1.0,
		"enemy_damage": 1.0,
		"enemy_aim_error": 1.0,
		"enemy_attack_cooldown": 1.0,
		"enemy_speed": 1.0,
		"enemy_reaction": 1.0,
		"player_runway": 24,
		"health_pack_months": 8,
		"countdown_time": 1.0,
		"survive_time": 1.0,
	},
	"hard": {
		"label": "HARD - BOOTSTRAPPED",
		"description": "Tougher, faster, sharper enemies. Less runway. Shorter timers.",
		"enemy_health": 1.3,
		"enemy_damage": 1.5,
		"enemy_aim_error": 0.7,
		"enemy_attack_cooldown": 0.85,
		"enemy_speed": 1.1,
		"enemy_reaction": 0.75,
		"player_runway": 20,
		"health_pack_months": 6,
		"countdown_time": 0.85,
		"survive_time": 1.15,
	},
	"nightmare": {
		"label": "NIGHTMARE - PERMANENT UNDERCLASS",
		"description": "Double damage, deadly aim, tiny bridge rounds. You're not gonna make it.",
		"enemy_health": 1.6,
		"enemy_damage": 2.0,
		"enemy_aim_error": 0.5,
		"enemy_attack_cooldown": 0.7,
		"enemy_speed": 1.2,
		"enemy_reaction": 0.55,
		"player_runway": 16,
		"health_pack_months": 4,
		"countdown_time": 0.7,
		"survive_time": 1.3,
	},
}

static var current := NORMAL


static func set_current(difficulty_id: String) -> void:
	if not PRESETS.has(difficulty_id):
		push_warning("Unknown difficulty '%s', keeping %s" % [difficulty_id, current])
		return
	current = difficulty_id


static func get_value(key: String) -> float:
	return PRESETS[current][key]


static func get_label() -> String:
	return PRESETS[current]["label"]


static func get_description() -> String:
	return PRESETS[current]["description"]


static func get_next(difficulty_id: String) -> String:
	var index := ORDER.find(difficulty_id)
	return ORDER[posmod(index + 1, ORDER.size())]


static func scale_damage(base_damage: int) -> int:
	return maxi(1, roundi(base_damage * get_value("enemy_damage")))


static func get_player_runway() -> int:
	return int(get_value("player_runway"))


static func get_health_pack_months() -> int:
	return int(get_value("health_pack_months"))
