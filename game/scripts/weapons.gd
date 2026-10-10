class_name Weapons
extends RefCounted

const BLASTER := "blaster"
const GRENADE := "grenade"
const STUN := "stun"
const RAIL := "rail"
const BUBBLE := "bubble"
const CHAIN := "chain"
const STARTING_WEAPON_COUNT := 3
const MODEL_ROOT := Models.GRAPHICS_ROOT + "weapons/"
const ALL: Array[Dictionary] = [
	{
		"name": "FOAM DART BLASTER",
		"short_name": "DARTS",
		"kind": BLASTER,
		"cooldown": 0.14,
		"automatic": true,
		"pellets": 1,
		"spread": 0.012,
		"speed": 60.0,
		"damage": 20,
		"lifetime": 1.5,
		"pellet_size": Vector3(0.08, 0.08, 0.5),
		"color": Color(1.0, 0.55, 0.1),
		"model": "foam-dart",
		"model_length": 0.36,
		"muzzle_confetti": 0,
		"recoil": 0.05,
		"fire_sound": AudioBank.DART,
		"fire_volume_db": -8.0,
	},
	{
		"name": "CONFETTI CANNON",
		"short_name": "CONFETTI",
		"kind": BLASTER,
		"cooldown": 0.9,
		"automatic": false,
		"pellets": 10,
		"spread": 0.09,
		"speed": 42.0,
		"damage": 18,
		"lifetime": 0.5,
		"pellet_size": Vector3(0.12, 0.12, 0.12),
		"color": Color(1.0, 0.35, 0.7),
		"model": "confetti-cannon",
		"model_length": 0.42,
		"muzzle_confetti": 14,
		"recoil": 0.16,
		"fire_sound": AudioBank.CONFETTI,
		"fire_volume_db": -2.0,
	},
	{
		"name": "SLOP GRENADE",
		"short_name": "SLOP",
		"kind": GRENADE,
		"cooldown": 1.2,
		"automatic": false,
		"color": SlopGrenade.SLOP_GREEN,
		"model": "slop-grenade",
		"model_length": 0.11,
		"muzzle_confetti": 0,
		"recoil": 0.08,
		"fire_sound": AudioBank.THROW,
		"fire_volume_db": -2.0,
	},
	{
		"name": "NDA STAPLER",
		"short_name": "NDA",
		"kind": STUN,
		"cooldown": 0.45,
		"automatic": false,
		"pellets": 1,
		"spread": 0.004,
		"speed": 48.0,
		"damage": 12,
		"stun_seconds": 3.0,
		"lifetime": 1.5,
		"pellet_size": Vector3(0.3, 0.02, 0.4),
		"color": Color(0.95, 0.95, 0.9),
		"model": "nda-stapler",
		"model_length": 0.3,
		"muzzle_confetti": 0,
		"recoil": 0.07,
		"fire_sound": AudioBank.STAPLE,
		"fire_volume_db": -3.0,
	},
	{
		"name": "HYPE RAILGUN",
		"short_name": "RAIL",
		"kind": RAIL,
		"cooldown": 1.1,
		"automatic": false,
		"damage": 95,
		"range": 120.0,
		"max_pierce": 5,
		"color": Color(0.35, 0.8, 1.0),
		"model": "hype-railgun",
		"model_length": 0.56,
		"muzzle_confetti": 0,
		"recoil": 0.2,
		"fire_sound": AudioBank.RAIL,
		"fire_volume_db": -2.0,
	},
	{
		"name": "VALUATION BUBBLE",
		"short_name": "BUBBLE",
		"kind": BUBBLE,
		"cooldown": 1.0,
		"automatic": false,
		"damage": 120,
		"speed": 15.0,
		"color": Color(1.0, 0.55, 0.9),
		"model": "valuation-bubble",
		"model_length": 0.44,
		"muzzle_confetti": 0,
		"recoil": 0.12,
		"fire_sound": AudioBank.BUBBLE,
		"fire_volume_db": -2.0,
	},
	{
		"name": "DISRUPTOR",
		"short_name": "DISRUPT",
		"kind": CHAIN,
		"cooldown": 0.6,
		"automatic": true,
		"damage": 45,
		"range": 34.0,
		"aim_cone_degrees": 9.0,
		"chain_count": 4,
		"chain_range": 9.0,
		"color": Color(0.7, 0.55, 1.0),
		"model": "disruptor",
		"model_length": 0.5,
		"muzzle_confetti": 0,
		"recoil": 0.09,
		"fire_sound": AudioBank.ZAP,
		"fire_volume_db": -4.0,
	},
]


static func get_weapon(index: int) -> Dictionary:
	return ALL[index]


static func find_index(weapon_name: String) -> int:
	for index: int in ALL.size():
		if ALL[index]["name"] == weapon_name:
			return index
	return -1
