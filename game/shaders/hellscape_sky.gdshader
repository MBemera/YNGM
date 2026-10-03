shader_type sky;

uniform sampler2D panorama : filter_linear, hint_default_black;
uniform float exposure = 1.0;
uniform float yaw_offset = 0.0;
uniform vec3 shadow_color : source_color = vec3(0.16, 0.02, 0.03);
uniform vec3 mid_color : source_color = vec3(0.85, 0.22, 0.05);
uniform vec3 highlight_color : source_color = vec3(1.0, 0.78, 0.35);
uniform vec3 horizon_haze : source_color = vec3(0.42, 0.1, 0.05);
uniform float haze_height = 0.14;

vec2 panorama_uv(vec3 direction) {
	float u = atan(direction.x, -direction.z) / (2.0 * PI) + 0.5 + yaw_offset;
	float v = acos(clamp(direction.y, -1.0, 1.0)) / PI;
	return vec2(fract(u), v);
}

vec3 grade_to_fire(vec3 source) {
	float luminance = dot(source, vec3(0.2126, 0.7152, 0.0722));
	vec3 graded = mix(shadow_color, mid_color, smoothstep(0.0, 0.55, luminance));
	graded = mix(graded, highlight_color, smoothstep(0.55, 2.0, luminance));
	return graded * (1.0 + max(luminance - 2.0, 0.0) * 0.5);
}

void sky() {
	vec3 source = texture(panorama, panorama_uv(EYEDIR)).rgb * exposure;
	float haze_amount = 1.0 - smoothstep(-0.05, haze_height, EYEDIR.y);
	COLOR = mix(grade_to_fire(source), horizon_haze, haze_amount);
}
