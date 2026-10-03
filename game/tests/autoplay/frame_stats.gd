extends RefCounted

var frame_seconds := PackedFloat32Array()


func add_frame(delta: float) -> void:
	if delta > 0.0:
		frame_seconds.append(delta)


func get_summary() -> Dictionary:
	if frame_seconds.is_empty():
		return {"frames": 0}
	var sorted_seconds := frame_seconds.duplicate()
	sorted_seconds.sort()
	var total := 0.0
	for seconds: float in sorted_seconds:
		total += seconds
	var worst_count := maxi(1, sorted_seconds.size() / 100)
	var worst_total := 0.0
	for index: int in range(sorted_seconds.size() - worst_count, sorted_seconds.size()):
		worst_total += sorted_seconds[index]
	return {
		"frames": sorted_seconds.size(),
		"seconds": snappedf(total, 0.1),
		"average_fps": snappedf(sorted_seconds.size() / total, 0.1),
		"one_percent_low_fps": snappedf(worst_count / worst_total, 0.1),
		"minimum_fps": snappedf(1.0 / sorted_seconds[sorted_seconds.size() - 1], 0.1),
		"median_fps": snappedf(1.0 / sorted_seconds[sorted_seconds.size() / 2], 0.1),
	}
