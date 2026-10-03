class_name SaveData
extends RefCounted

const SAVE_PATH := "user://progress.cfg"
const SECTION := "progress"

static var is_persistence_enabled := true
static var highest_unlocked_level := 1
static var has_loaded := false


static func load_progress() -> void:
	has_loaded = true
	if not is_persistence_enabled:
		return
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("Could not read %s (error %d); starting fresh" % [SAVE_PATH, error])
		return
	highest_unlocked_level = maxi(1, int(config.get_value(SECTION, "highest_unlocked_level", 1)))
	Difficulty.set_current(str(config.get_value(SECTION, "difficulty", Difficulty.NORMAL)))
	GraphicsSettings.set_current(str(config.get_value(SECTION, "graphics_quality", GraphicsSettings.AUTO)))
	GraphicsSettings.show_fps = bool(config.get_value(SECTION, "show_fps", false))


static func save_progress() -> void:
	if not is_persistence_enabled:
		return
	var config := ConfigFile.new()
	config.set_value(SECTION, "highest_unlocked_level", highest_unlocked_level)
	config.set_value(SECTION, "difficulty", Difficulty.current)
	config.set_value(SECTION, "graphics_quality", GraphicsSettings.current)
	config.set_value(SECTION, "show_fps", GraphicsSettings.show_fps)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save %s (error %d)" % [SAVE_PATH, error])


static func unlock_level(level_number: int) -> void:
	if level_number <= highest_unlocked_level:
		return
	highest_unlocked_level = level_number
	save_progress()


static func is_level_unlocked(level_number: int) -> bool:
	return level_number <= highest_unlocked_level
