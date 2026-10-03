class_name EnemyAim
extends RefCounted

const MAX_LEAD_SECONDS := 1.5
const LEAD_FACTOR := 0.8


static func predict_intercept(origin: Vector3, target_point: Vector3, target_velocity: Vector3, projectile_speed: float) -> Vector3:
	var flight_seconds := minf(origin.distance_to(target_point) / projectile_speed, MAX_LEAD_SECONDS)
	var horizontal_velocity := Vector3(target_velocity.x, 0.0, target_velocity.z)
	return target_point + horizontal_velocity * flight_seconds * LEAD_FACTOR


static func add_spread(direction: Vector3, error_radians: float) -> Vector3:
	var side := direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	var up := side.cross(direction).normalized()
	var offset := side * randf_range(-error_radians, error_radians) + up * randf_range(-error_radians, error_radians) * 0.5
	return (direction + offset).normalized()
