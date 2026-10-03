class_name Hud
extends CanvasLayer

const EDGE_MARGIN := 20
const TEXT_COLOR := Color(1.0, 0.95, 0.85)
const WARNING_COLOR := Color(1.0, 0.35, 0.25)
const HEADING_COLOR := Color(1.0, 0.6, 0.2)
const ACCENT_COLOR := Color(0.25, 0.85, 1.0)
const HEALTHY_COLOR := Color(0.35, 1.0, 0.45)
const CAUTION_COLOR := Color(1.0, 0.75, 0.2)
const PANEL_COLOR := Color(0.03, 0.03, 0.06, 0.72)
const LOCKED_COLOR := Color(1, 1, 1, 0.25)
const LOW_RUNWAY_FRACTION := 0.3
const SLOT_SIZE := Vector2(74, 46)

var runway_bar: ProgressBar
var runway_label: Label
var objective_chapter: Label
var objective_label: Label
var objective_panel: PanelContainer
var countdown_label: Label
var boss_panel: VBoxContainer
var boss_name_label: Label
var boss_bar: ProgressBar
var weapon_label: Label
var weapon_slots: Array[PanelContainer] = []
var weapon_panel: VBoxContainer
var runway_panel: PanelContainer
var message_backdrop: ColorRect
var message_heading: Label
var message_body: Label
var damage_flash: ColorRect
var heal_flash: ColorRect
var crosshair: Crosshair
var title_card: VBoxContainer
var title_card_chapter: Label
var title_card_name: Label
var toast_label: Label
var dialogue_panel: PanelContainer
var dialogue_style: StyleBoxFlat
var dialogue_speaker: Label
var dialogue_text: Label
var dialogue_hint: Label
var fps_label: Label
var fps_refresh_left := 0.0


func _ready() -> void:
	layer = 2
	damage_flash = add_full_screen_rect(Color(1.0, 0.45, 0.1, 0.0))
	heal_flash = add_full_screen_rect(Color(0.2, 1.0, 0.4, 0.0))
	crosshair = Crosshair.new()
	add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_runway_panel()
	build_weapon_panel()
	build_objective_panel()
	build_countdown()
	build_boss_panel()
	build_title_card()
	build_toast()
	build_message_panel()
	build_dialogue_panel()
	build_fps_label()
	set_countdown(-1.0)
	set_boss_progress("", -1.0)
	hide_message()


func create_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	return label


func create_panel_style(background: Color, border: Color, border_width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style


func create_panel(border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", create_panel_style(PANEL_COLOR, border))
	return panel


func create_bar(fill_color: Color, bar_size: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.custom_minimum_size = bar_size
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.6)
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func add_full_screen_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


func build_runway_panel() -> void:
	runway_panel = create_panel(Color(1, 1, 1, 0.15))
	add_child(runway_panel)
	runway_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, EDGE_MARGIN)
	runway_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	runway_panel.add_child(column)
	runway_label = create_label(20, TEXT_COLOR)
	column.add_child(runway_label)
	runway_bar = create_bar(HEALTHY_COLOR, Vector2(300, 16))
	column.add_child(runway_bar)


func build_weapon_panel() -> void:
	weapon_panel = VBoxContainer.new()
	weapon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_panel.alignment = BoxContainer.ALIGNMENT_END
	add_child(weapon_panel)
	weapon_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, EDGE_MARGIN)
	weapon_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	weapon_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	weapon_label = create_label(24, TEXT_COLOR)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_panel.add_child(weapon_label)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	weapon_panel.add_child(row)
	for slot_index: int in Weapons.ALL.size():
		var slot := create_weapon_slot(slot_index)
		row.add_child(slot)
		weapon_slots.append(slot)


func create_weapon_slot(slot_index: int) -> PanelContainer:
	var slot := create_panel(Color(1, 1, 1, 0.2))
	slot.custom_minimum_size = SLOT_SIZE
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	slot.add_child(column)
	var number_label := create_label(16, ACCENT_COLOR)
	number_label.text = str(slot_index + 1)
	column.add_child(number_label)
	var name_label := create_label(12, TEXT_COLOR)
	name_label.text = Weapons.get_weapon(slot_index)["short_name"]
	column.add_child(name_label)
	return slot


func build_objective_panel() -> void:
	objective_panel = create_panel(Color(1.0, 0.6, 0.2, 0.5))
	add_child(objective_panel)
	objective_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, EDGE_MARGIN)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.add_child(column)
	objective_chapter = create_label(14, HEADING_COLOR)
	column.add_child(objective_chapter)
	objective_label = create_label(20, TEXT_COLOR)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(380, 0)
	column.add_child(objective_label)


func build_countdown() -> void:
	countdown_label = create_label(40, WARNING_COLOR)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(countdown_label)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, EDGE_MARGIN)


func build_boss_panel() -> void:
	boss_panel = VBoxContainer.new()
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_panel)
	boss_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_panel.offset_top = 80
	boss_name_label = create_label(22, WARNING_COLOR)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_panel.add_child(boss_name_label)
	boss_bar = create_bar(WARNING_COLOR, Vector2(560, 18))
	boss_panel.add_child(boss_bar)


func build_title_card() -> void:
	title_card = VBoxContainer.new()
	title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_card)
	title_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	title_card.offset_top = -160
	title_card_chapter = create_label(22, ACCENT_COLOR)
	title_card_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card.add_child(title_card_chapter)
	title_card_name = create_label(64, HEADING_COLOR)
	title_card_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card.add_child(title_card_name)
	title_card.modulate.a = 0.0


func build_toast() -> void:
	toast_label = create_label(26, HEALTHY_COLOR)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(toast_label)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_label.offset_top = 90
	toast_label.modulate.a = 0.0


func build_dialogue_panel() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_style = create_panel_style(Color(0.02, 0.05, 0.08, 0.88), ACCENT_COLOR)
	dialogue_style.set_content_margin_all(18)
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)
	add_child(dialogue_panel)
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.custom_minimum_size = Vector2(980, 0)
	dialogue_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialogue_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialogue_panel.offset_bottom = -30
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(column)
	dialogue_speaker = create_label(22, ACCENT_COLOR)
	column.add_child(dialogue_speaker)
	dialogue_text = create_label(24, TEXT_COLOR)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size = Vector2(940, 0)
	column.add_child(dialogue_text)
	dialogue_hint = create_label(16, Color(1, 1, 1, 0.6))
	dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(dialogue_hint)
	dialogue_panel.visible = false


func build_message_panel() -> void:
	message_backdrop = add_full_screen_rect(Color(0, 0, 0, 0.62))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_backdrop.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)
	message_heading = create_label(52, HEADING_COLOR)
	message_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(message_heading)
	message_body = create_label(22, TEXT_COLOR)
	message_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(message_body)


func build_fps_label() -> void:
	fps_label = create_label(18, HEALTHY_COLOR)
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(fps_label)
	fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, EDGE_MARGIN)
	fps_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _process(delta: float) -> void:
	fps_label.visible = GraphicsSettings.show_fps
	fps_refresh_left -= delta
	if not fps_label.visible or fps_refresh_left > 0.0:
		return
	fps_refresh_left = 0.5
	fps_label.text = "%d FPS  |  %s" % [Engine.get_frames_per_second(), GraphicsSettings.get_preset()["label"]]


func set_runway(months: int, max_months: int) -> void:
	runway_label.text = "RUNWAY  %d / %d MONTHS" % [months, max_months]
	runway_bar.max_value = max_months
	runway_bar.value = months
	var fraction := float(months) / maxf(max_months, 1)
	var color := HEALTHY_COLOR
	if fraction <= LOW_RUNWAY_FRACTION:
		color = WARNING_COLOR
	elif fraction <= 0.6:
		color = CAUTION_COLOR
	(runway_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = color
	runway_label.add_theme_color_override("font_color", WARNING_COLOR if fraction <= LOW_RUNWAY_FRACTION else TEXT_COLOR)


func is_runway_low(months: int, max_months: int) -> bool:
	return float(months) / maxf(max_months, 1) <= LOW_RUNWAY_FRACTION


func set_weapon(weapon_index: int, unlocked_count: int) -> void:
	weapon_label.text = Weapons.get_weapon(weapon_index)["name"]
	for slot_index: int in weapon_slots.size():
		update_weapon_slot(weapon_slots[slot_index], slot_index == weapon_index, slot_index < unlocked_count)


func update_weapon_slot(slot: PanelContainer, is_selected: bool, is_unlocked: bool) -> void:
	var border := Color(1, 1, 1, 0.2)
	var background := PANEL_COLOR
	if is_selected:
		border = HEADING_COLOR
		background = Color(0.35, 0.12, 0.04, 0.85)
	slot.add_theme_stylebox_override("panel", create_panel_style(background, border))
	slot.modulate = Color.WHITE if is_unlocked else LOCKED_COLOR


func set_chapter(text: String) -> void:
	objective_chapter.text = text


func set_objective(text: String) -> void:
	objective_label.text = text
	objective_panel.visible = text != "" and crosshair.visible


func set_countdown(seconds_left: float, label := "") -> void:
	countdown_label.visible = seconds_left >= 0.0
	countdown_label.text = "%s %.1f" % [label, seconds_left] if label != "" else "%.1f" % seconds_left


func set_boss_progress(boss_name: String, fraction: float) -> void:
	boss_panel.visible = fraction >= 0.0
	if fraction < 0.0:
		return
	boss_name_label.text = boss_name
	boss_bar.value = fraction * 100.0


func show_title_card(chapter: String, level_title: String) -> void:
	title_card_chapter.text = chapter
	title_card_name.text = level_title
	var tween := create_tween()
	tween.tween_property(title_card, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.2)
	tween.tween_property(title_card, "modulate:a", 0.0, 0.8)


func show_toast(text: String, color := HEALTHY_COLOR) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.4)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)


func show_message(heading: String, body: String) -> void:
	message_heading.text = heading
	message_body.text = body
	message_backdrop.visible = true


func hide_message() -> void:
	message_backdrop.visible = false


func show_dialogue(speaker: String, role: String, text: String, line_number: int, line_count: int, speaker_color := ACCENT_COLOR) -> void:
	dialogue_speaker.text = "%s  -  %s" % [speaker, role]
	dialogue_speaker.add_theme_color_override("font_color", speaker_color)
	dialogue_style.border_color = speaker_color
	dialogue_text.text = text
	dialogue_hint.text = "%d / %d     SPACE or CLICK: next     ENTER: skip" % [line_number, line_count]
	dialogue_panel.visible = true


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func is_dialogue_visible() -> bool:
	return dialogue_panel.visible


func set_gameplay_visible(should_show: bool) -> void:
	for element: CanvasItem in [crosshair, runway_panel, weapon_panel]:
		element.visible = should_show
	objective_panel.visible = should_show and objective_label.text != ""


func show_hit_marker(was_defeat: bool) -> void:
	crosshair.show_hit(was_defeat)


func kick_crosshair() -> void:
	crosshair.kick()


func flash_damage() -> void:
	damage_flash.color.a = 0.35
	create_tween().tween_property(damage_flash, "color:a", 0.0, 0.35)


func flash_heal() -> void:
	heal_flash.color.a = 0.3
	create_tween().tween_property(heal_flash, "color:a", 0.0, 0.5)
