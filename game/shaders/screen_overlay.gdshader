shader_type canvas_item;

uniform float vignette_strength = 0.5;
uniform float grain_strength = 0.03;
uniform float danger = 0.0;
uniform vec3 danger_color : source_color = vec3(0.75, 0.04, 0.02);
uniform vec3 tint_color : source_color = vec3(0.0, 0.0, 0.0);

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV - 0.5;
	float distance_from_center = length(centered * vec2(1.0, 0.75));
	float vignette = smoothstep(0.3, 0.85, distance_from_center) * vignette_strength;
	float pulse = danger * (0.65 + 0.35 * sin(TIME * 6.0));
	float danger_edge = smoothstep(0.2, 0.75, distance_from_center) * pulse;
	float grain = hash(floor(UV * vec2(640.0, 360.0)) + fract(TIME * 13.0) * 97.0) * grain_strength;
	float total = vignette + danger_edge;
	vec3 color = mix(tint_color, danger_color, danger_edge / max(total, 0.0001));
	COLOR = vec4(color, clamp(total * 0.85 + grain, 0.0, 0.92));
}
