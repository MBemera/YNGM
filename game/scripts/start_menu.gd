class_name StartMenu
extends CanvasLayer

signal new_game_requested
signal level_requested(level_number: int)
signal graphics_changed

const TITLE_COLOR := Color(1.0, 0.6, 0.2)
const TEXT_COLOR := Color(1.0, 0.95, 0.88)
const ACCENT_COLOR := Color(0.25, 0.85, 1.0)
const PANEL_COLOR := Color(0.05, 0.03, 0.06, 0.82)
const LOCKED_TEXT_COLOR := Color(1, 1, 1, 0.35)
const HOW_TO_PLAY_TEXT := """[b]THE STORY[/b]
The AI transition has arrived. Overclass's CEO, Preston Exitwell, is escaping the city by helicopter, and he's taking the future with him. Grab the ladder, then follow it all the way to the top: through his labeling farm, down the 101, along Sand Hill Road, into Overclass's datacenter, and onto the Ark itself. Eleven levels. One ladder.

[b]OBJECTIVES[/b]
Each level shows its current objective top-left: reach the glowing exit beacons, smash targets, hold out against waves, beat the clock or take down a boss. Locked doors open when the objective before them is done.

[b]CONTROLS[/b]
WASD move   |   Mouse look   |   Space jump   |   Shift sprint
Left click fire   |   1-7 or mouse wheel switch weapon
R restart   |   Esc free the mouse   |   Enter skip story   |   M menu (after a level)

[b]WEAPONS[/b] (nobody gets hurt; new ones unlock as the story goes)
1 Foam Dart Blaster: hold to fire.   2 Confetti Cannon: close-range spread.
3 Slop Grenade: bounces, then showers the area in terrible Rust code.
4 NDA Stapler: stuns. They stop talking.   5 Hype Railgun: pierces a whole line.
6 Valuation Bubble: grows, then pops on a crowd.   7 Disruptor: arcs between targets.

[b]RUNWAY[/b]
Your health is runway, in months. Every hit burns runway. Zero means game over.
Green BRIDGE ROUND crates top it back up. Difficulty sets how much you get.

[b]GRAPHICS[/b]
AUTO picks MEDIUM on integrated graphics and HIGH on dedicated cards. MEDIUM and LOW render 3D at a capped
internal resolution (about 600p / 430p) so fullscreen costs no more than a small window; LOW also drops shadows
and glow. HIGH renders at full resolution with anti-aliasing. SHOW FPS displays the frame counter in the corner."""
const CREDITS_TEXT := "Free CC0 assets: Kenney, Poly Haven, Quaternius, Poly Pizza  |  Voices: Piper TTS (public-domain voices)"

var main_panel: Control
var how_to_panel: Control
var level_select_panel: Control
var difficulty_button: Button
var difficulty_description: Label
var graphics_button: Button
var fps_button: Button
var level_grid: GridContainer


func _ready() -> void:
	layer = 5
	add_backdrop()
	main_panel = build_main_panel()
	how_to_panel = build_how_to_panel()
	level_select_panel = build_level_select_panel()
	show_main_panel()


func add_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.0, 0.02, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func build_main_panel() -> Control:
	var column := create_centered_column(8)
	column.add_child(create_label("ESCAPE FROM THE\nPERMANENT UNDERCLASS", 52, TITLE_COLOR))
	column.add_child(create_label("ELEVEN LEVELS. ONE LADDER.", 22, ACCENT_COLOR))
	column.add_child(create_spacer(14))
	column.add_child(create_button("START", new_game_requested.emit))
	column.add_child(create_continue_button())
	column.add_child(create_button("LEVEL SELECT", show_level_select_panel))
	difficulty_button = create_button("", cycle_difficulty)
	difficulty_button.custom_minimum_size = Vector2(520, 52)
	column.add_child(difficulty_button)
	difficulty_description = create_label("", 16, Color(1, 1, 1, 0.75))
	column.add_child(difficulty_description)
	column.add_child(create_settings_row())
	column.add_child(create_button("HOW TO PLAY", show_how_to_panel))
	column.add_child(create_button("QUIT", get_tree().quit))
	column.add_child(create_spacer(14))
	column.add_child(create_label(CREDITS_TEXT, 14, Color(1, 1, 1, 0.6)))
	update_difficulty_labels()
	update_graphics_labels()
	return column.get_parent()


func create_settings_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	graphics_button = create_button("", cycle_graphics_quality)
	graphics_button.custom_minimum_size = Vector2(320, 44)
	graphics_button.add_theme_font_size_override("font_size", 18)
	row.add_child(graphics_button)
	fps_button = create_button("", toggle_fps_counter)
	fps_button.custom_minimum_size = Vector2(190, 44)
	fps_button.add_theme_font_size_override("font_size", 18)
	row.add_child(fps_button)
	return row


func create_continue_button() -> Button:
	var level_number := SaveData.highest_unlocked_level
	var button := create_button("CONTINUE: LEVEL %d" % level_number, level_requested.emit.bind(level_number))
	button.visible = level_number > 1
	return button


func build_how_to_panel() -> Control:
	var column := create_centered_column(8)
	column.add_child(create_label("HOW TO PLAY", 34, TITLE_COLOR))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", create_panel_style(PANEL_COLOR, ACCENT_COLOR))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(1000, 0)
	body.add_theme_font_size_override("normal_font_size", 14)
	body.add_theme_font_size_override("bold_font_size", 16)
	body.add_theme_color_override("default_color", TEXT_COLOR)
	body.text = HOW_TO_PLAY_TEXT
	scroll.add_child(body)
	panel.add_child(scroll)
	column.add_child(panel)
	column.add_child(create_button("BACK", show_main_panel))
	return column.get_parent()


func build_level_select_panel() -> Control:
	var column := create_centered_column(14)
	column.add_child(create_label("LEVEL SELECT", 40, TITLE_COLOR))
	level_grid = GridContainer.new()
	level_grid.columns = 3
	level_grid.add_theme_constant_override("h_separation", 10)
	level_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(level_grid)
	var titles := LevelCatalog.get_titles()
	for index: int in titles.size():
		level_grid.add_child(create_level_button(index + 1, titles[index]))
	column.add_child(create_button("BACK", show_main_panel))
	return column.get_parent()


func create_level_button(level_number: int, level_title: String) -> Button:
	var is_unlocked := SaveData.is_level_unlocked(level_number)
	var label := "%d. %s" % [level_number, level_title] if is_unlocked else "%d. LOCKED" % level_number
	var button := create_button(label, level_requested.emit.bind(level_number))
	button.custom_minimum_size = Vector2(340, 52)
	button.add_theme_font_size_override("font_size", 18)
	button.disabled = not is_unlocked
	button.add_theme_color_override("font_disabled_color", LOCKED_TEXT_COLOR)
	return button


func create_centered_column(separation: int) -> VBoxContainer:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", separation)
	center.add_child(column)
	return column


func create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 10)
	return label


func create_spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


func create_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", create_panel_style(PANEL_COLOR, TITLE_COLOR))
	button.add_theme_stylebox_override("hover", create_panel_style(Color(0.35, 0.08, 0.04, 0.9), Color(1.0, 0.8, 0.3)))
	button.add_theme_stylebox_override("pressed", create_panel_style(Color(0.5, 0.12, 0.05, 0.95), Color.WHITE))
	button.add_theme_stylebox_override("disabled", create_panel_style(Color(0.05, 0.05, 0.05, 0.6), Color(1, 1, 1, 0.15)))
	button.add_theme_stylebox_override("focus", create_panel_style(Color(0, 0, 0, 0), ACCENT_COLOR))
	button.pressed.connect(on_pressed)
	return button


func create_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style


func cycle_difficulty() -> void:
	Difficulty.set_current(Difficulty.get_next(Difficulty.current))
	SaveData.save_progress()
	update_difficulty_labels()


func cycle_graphics_quality() -> void:
	GraphicsSettings.set_current(GraphicsSettings.get_next(GraphicsSettings.current))
	SaveData.save_progress()
	update_graphics_labels()
	graphics_changed.emit()


func toggle_fps_counter() -> void:
	GraphicsSettings.show_fps = not GraphicsSettings.show_fps
	SaveData.save_progress()
	update_graphics_labels()
	graphics_changed.emit()


func update_graphics_labels() -> void:
	graphics_button.text = "GRAPHICS:  %s" % GraphicsSettings.get_label()
	fps_button.text = "SHOW FPS:  %s" % ("ON" if GraphicsSettings.show_fps else "OFF")


func update_difficulty_labels() -> void:
	difficulty_button.text = "DIFFICULTY:  %s" % Difficulty.get_label()
	difficulty_description.text = Difficulty.get_description()


func show_main_panel() -> void:
	main_panel.visible = true
	how_to_panel.visible = false
	level_select_panel.visible = false


func show_how_to_panel() -> void:
	main_panel.visible = false
	how_to_panel.visible = true


func show_level_select_panel() -> void:
	main_panel.visible = false
	level_select_panel.visible = true
