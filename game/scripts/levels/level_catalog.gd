class_name LevelCatalog
extends RefCounted

const LEVEL_PATHS: Array[String] = [
	"res://scripts/levels/level_01_south_of_market.gd",
	"res://scripts/levels/level_02_opportunity_center.gd",
	"res://scripts/levels/level_03_the_101.gd",
	"res://scripts/levels/level_04_sand_hill_road.gd",
	"res://scripts/levels/level_05_disrupt_a_thon.gd",
	"res://scripts/levels/level_06_overclass_campus.gd",
	"res://scripts/levels/level_07_cold_aisle.gd",
	"res://scripts/levels/level_08_pier_70.gd",
	"res://scripts/levels/level_09_the_ark.gd",
	"res://scripts/levels/level_10_the_boardroom.gd",
	"res://scripts/levels/level_11_omega.gd",
]
const ENDING_STORY_PATH := "res://data/story/ending.json"


static func get_count() -> int:
	return LEVEL_PATHS.size()


static func create(level_number: int) -> Level:
	var index := clampi(level_number, 1, get_count()) - 1
	var level_script: Script = load(LEVEL_PATHS[index])
	var level: Level = level_script.new()
	return level


static func is_final_level(level_number: int) -> bool:
	return level_number >= get_count()


static func get_titles() -> Array[String]:
	var titles: Array[String] = []
	for level_number: int in range(1, get_count() + 1):
		var is_built := ResourceLoader.exists(LEVEL_PATHS[level_number - 1])
		titles.append(create(level_number).title if is_built else "UNDER CONSTRUCTION")
	return titles
