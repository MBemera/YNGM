class_name GraphicsSettings
extends RefCounted

const AUTO := "auto"
const LOW := "low"
const MEDIUM := "medium"
const HIGH := "high"
const ORDER: Array[String] = [AUTO, LOW, MEDIUM, HIGH]
const INTEGRATED_GPU_HINTS: Array[String] = ["intel", "uhd", "iris", "radeon(tm) graphics", "radeon graphics", "vega", "adreno", "mali", "apple"]
const SOFTWARE_RENDERER_HINTS: Array[String] = ["llvmpipe", "softpipe", "swiftshader", "basic render"]
const PRESETS := {
	"low": {
		"label": "LOW",
		"render_height": 432.0,
		"shadows": false,
		"shadow_mode": DirectionalLight3D.SHADOW_ORTHOGONAL,
		"shadow_distance": 40.0,
		"shadow_atlas": 1024,
		"glow": false,
		"msaa": Viewport.MSAA_DISABLED,
		"particle_scale": 0.5,
	},
	"medium": {
		"label": "MEDIUM",
		"render_height": 600.0,
		"shadows": true,
		"shadow_mode": DirectionalLight3D.SHADOW_ORTHOGONAL,
		"shadow_distance": 45.0,
		"shadow_atlas": 2048,
		"glow": true,
		"msaa": Viewport.MSAA_DISABLED,
		"particle_scale": 0.75,
	},
	"high": {
		"label": "HIGH",
		"render_height": 0.0,
		"shadows": true,
		"shadow_mode": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"shadow_distance": 70.0,
		"shadow_atlas": 4096,
		"glow": true,
		"msaa": Viewport.MSAA_2X,
		"particle_scale": 1.0,
	},
}

const MIN_RENDER_SCALE := 0.35

static var current := AUTO
static var show_fps := false


static func set_current(quality_id: String) -> void:
	if quality_id != AUTO and not PRESETS.has(quality_id):
		push_warning("Unknown graphics quality '%s', keeping %s" % [quality_id, current])
		return
	current = quality_id


static func get_next(quality_id: String) -> String:
	return ORDER[posmod(ORDER.find(quality_id) + 1, ORDER.size())]


static func get_resolved() -> String:
	return detect_quality() if current == AUTO else current


static func get_preset() -> Dictionary:
	return PRESETS[get_resolved()]


static func get_label() -> String:
	var resolved_label: String = get_preset()["label"]
	return "AUTO (%s)" % resolved_label if current == AUTO else resolved_label


static func detect_quality() -> String:
	if is_software_renderer():
		return LOW
	return MEDIUM if is_integrated_gpu() else HIGH


static func is_software_renderer() -> bool:
	var adapter_name := RenderingServer.get_video_adapter_name().to_lower()
	for hint: String in SOFTWARE_RENDERER_HINTS:
		if adapter_name.contains(hint):
			return true
	return false


static func is_integrated_gpu() -> bool:
	if RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU:
		return true
	var adapter_name := RenderingServer.get_video_adapter_name().to_lower()
	for hint: String in INTEGRATED_GPU_HINTS:
		if adapter_name.contains(hint):
			return true
	return false


static func get_render_scale(output_height: float) -> float:
	var render_height: float = get_preset()["render_height"]
	if render_height <= 0.0 or output_height <= 0.0:
		return 1.0
	return clampf(render_height / output_height, MIN_RENDER_SCALE, 1.0)


static func get_output_height(viewport: Viewport) -> float:
	var window := viewport as Window
	if window != null and window.size.y > 0:
		return float(window.size.y)
	return viewport.get_visible_rect().size.y


static func apply_to_viewport(viewport: Viewport) -> void:
	var preset := get_preset()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = get_render_scale(get_output_height(viewport))
	viewport.msaa_3d = preset["msaa"]
	RenderingServer.directional_shadow_atlas_set_size(preset["shadow_atlas"], true)


static func apply_to_environment(environment: Environment) -> void:
	var has_glow: bool = get_preset()["glow"]
	environment.glow_enabled = environment.glow_enabled and has_glow


static func apply_to_sun(sun: DirectionalLight3D) -> void:
	var preset := get_preset()
	var has_shadows: bool = preset["shadows"]
	sun.shadow_enabled = sun.shadow_enabled and has_shadows
	sun.directional_shadow_mode = preset["shadow_mode"]
	sun.directional_shadow_max_distance = preset["shadow_distance"]


static func scale_particle_amount(amount: int) -> int:
	var particle_scale: float = get_preset()["particle_scale"]
	return maxi(1, roundi(amount * particle_scale))
