class_name InputActions
extends RefCounted

const KEY_BINDINGS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"sprint": KEY_SHIFT,
	"weapon_1": KEY_1,
	"weapon_2": KEY_2,
	"weapon_3": KEY_3,
	"weapon_4": KEY_4,
	"weapon_5": KEY_5,
	"weapon_6": KEY_6,
	"weapon_7": KEY_7,
	"restart": KEY_R,
	"menu": KEY_M,
	"skip_intro": KEY_ENTER,
	"release_mouse": KEY_ESCAPE,
}

const MOUSE_BINDINGS := {
	"fire": MOUSE_BUTTON_LEFT,
	"weapon_next": MOUSE_BUTTON_WHEEL_UP,
	"weapon_previous": MOUSE_BUTTON_WHEEL_DOWN,
}


static func register() -> void:
	for action_name: String in KEY_BINDINGS:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = KEY_BINDINGS[action_name]
		add_action_event(action_name, key_event)
	for action_name: String in MOUSE_BINDINGS:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BINDINGS[action_name]
		add_action_event(action_name, mouse_event)


static func add_action_event(action_name: String, event: InputEvent) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)
