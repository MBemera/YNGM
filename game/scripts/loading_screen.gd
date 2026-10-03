class_name LoadingScreen
extends CanvasLayer

const COVER_ART_PATH := "res://assets/branding/cover-art.png"
const TIP_SECONDS := 3.2
const TIP_SCROLL_DISTANCE := 26.0
const PROGRESS_SPEED := 2.5
const FADE_SECONDS := 0.35
const TEXT_COLOR := Color(1.0, 0.95, 0.88)
const ACCENT_COLOR := Color(1.0, 0.6, 0.2)
const TIPS: Array[String] = [
	"The Foam Dart Blaster never runs dry. Hold the trigger and keep moving.",
	"Green BRIDGE ROUND crates restore runway. Your difficulty decides how much.",
	"AI founders rush you. The NDA Stapler (4) stops them talking - and moving.",
	"The Hype Railgun (5) goes straight through a whole row of VCs.",
	"Valuation Bubbles (6) grow as they fly. Pop one in the middle of a crowd.",
	"The Disruptor (7) arcs from target to target, like a layoff email.",
	"Slop grenades bounce. Bank them off walls to reach enemies behind cover.",
	"VCs lead their throws. Strafe side to side and their term sheets miss.",
	"Lab security bots charge up before a three-shot burst. Break line of sight.",
	"Shift managers hit hard but walk slowly. Keep your distance and keep firing.",
	"Thought leaders fire hot takes in threes. Sidestep the spread.",
	"Delivery bots are fast and fragile. The Confetti Cannon (2) shreds them up close.",
	"Bosses enrage at half health and call in backup. Clear the adds first.",
	"Locked doors open as soon as the objective before them is done.",
	"Timed runs reward sprinting. Shift to sprint, shoot only what blocks you.",
	"Frame rate low? Try GRAPHICS: MEDIUM or LOW on the main menu.",
	"SHOW FPS on the main menu puts a frame counter in the corner.",
	"Too hard? EASY - TRUST FUND gives you more runway and longer timers.",
	"Too easy? NIGHTMARE - PERMANENT UNDERCLASS is waiting for you.",
	"Press R to restart a level instantly. No judgement. Some judgement.",
	"LEVEL SELECT replays any level you have already reached.",
	"Your health is runway, measured in months. Every hit burns some.",
	"Overclass reminds you: you're not gonna make it. Publicly, we believe in you.",
]

var level_label: Label
var status_label: Label
var progress_bar: ProgressBar
var tip_label: Label
var tip_holder: Control
var artwork: TextureRect
var bottom_panel: PanelContainer
var target_progress := 0.0
var shown_progress := 0.0
var tip_index := 0
var tip_seconds_left := TIP_SECONDS
var is_finishing := false


func _ready() -> void:
	layer = 20
	tip_index = randi() % TIPS.size()
	add_background()
	add_bottom_panel()
	show_tip(TIPS[tip_index])


func setup(chapter_label: String) -> void:
	level_label.text = chapter_label


func _process(delta: float) -> void:
	shown_progress = move_toward(shown_progress, target_progress, PROGRESS_SPEED * delta)
	progress_bar.value = shown_progress * 100.0
	tip_seconds_left -= delta
	if tip_seconds_left <= 0.0:
		tip_seconds_left = TIP_SECONDS
		scroll_to_next_tip()


func set_progress(fraction: float, status: String) -> void:
	target_progress = maxf(target_progress, clampf(fraction, 0.0, 1.0))
	status_label.text = status


func finish() -> void:
	if is_finishing:
		return
	is_finishing = true
	set_progress(1.0, "READY")
	var tween := create_tween()
	tween.tween_interval(0.25)
	for child: Node in get_children():
		var control := child as Control
		if control != null:
			tween.parallel().tween_property(control, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(queue_free)


func add_background() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cover_texture: Texture2D = load(COVER_ART_PATH)
	var ambience := create_cover_rect(cover_texture, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	ambience.modulate = Color(0.3, 0.26, 0.26)
	artwork = create_cover_rect(cover_texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)


func create_cover_rect(texture: Texture2D, stretch: TextureRect.StretchMode) -> TextureRect:
	var cover := TextureRect.new()
	cover.texture = texture
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = stretch
	add_child(cover)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return cover


func add_bottom_panel() -> void:
	var panel := PanelContainer.new()
	bottom_panel = panel
	panel.resized.connect(fit_artwork_above_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.02, 0.82)
	style.border_color = ACCENT_COLOR
	style.border_width_top = 2
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(create_header_row())
	progress_bar = create_progress_bar()
	column.add_child(progress_bar)
	tip_holder = Control.new()
	tip_holder.custom_minimum_size = Vector2(0, 54)
	tip_holder.clip_contents = true
	column.add_child(tip_holder)
	tip_label = create_label(20, TEXT_COLOR)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_holder.add_child(tip_label)
	tip_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func fit_artwork_above_panel() -> void:
	artwork.offset_bottom = -bottom_panel.size.y


func create_header_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	level_label = create_label(24, ACCENT_COLOR)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(level_label)
	status_label = create_label(18, TEXT_COLOR)
	status_label.text = "LOADING"
	row.add_child(status_label)
	return row


func create_progress_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(1, 1, 1, 0.12)
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT_COLOR
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func create_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func show_tip(text: String) -> void:
	tip_label.text = "TIP:  " + text


func scroll_to_next_tip() -> void:
	tip_index = (tip_index + 1) % TIPS.size()
	var tween := create_tween()
	tween.tween_property(tip_label, "position:y", -TIP_SCROLL_DISTANCE, 0.25).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(tip_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(show_tip.bind(TIPS[tip_index]))
	tween.tween_property(tip_label, "position:y", TIP_SCROLL_DISTANCE, 0.0)
	tween.tween_property(tip_label, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(tip_label, "modulate:a", 1.0, 0.3)
