class_name GameClock
extends RefCounted


static func get_msec() -> int:
	return Engine.get_physics_frames() * 1000 / Engine.physics_ticks_per_second
