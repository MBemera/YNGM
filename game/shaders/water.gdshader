shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.02, 0.08, 0.12);
uniform vec3 shallow_color : source_color = vec3(0.1, 0.35, 0.45);
uniform float wave_height = 0.18;
uniform float wave_scale = 0.12;
uniform float wave_speed = 0.9;

varying vec3 world_position;

float wave(vec2 position, float time) {
	return sin(position.x * wave_scale + time) * 0.6
		+ sin(position.y * wave_scale * 1.7 - time * 1.3) * 0.4
		+ sin((position.x + position.y) * wave_scale * 2.3 + time * 0.7) * 0.25;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float time = TIME * wave_speed;
	VERTEX.y += wave(world_position.xz, time) * wave_height;
	float step_size = 0.5;
	float height_x = wave(world_position.xz + vec2(step_size, 0.0), time) - wave(world_position.xz - vec2(step_size, 0.0), time);
	float height_z = wave(world_position.xz + vec2(0.0, step_size), time) - wave(world_position.xz - vec2(0.0, step_size), time);
	NORMAL = normalize(vec3(-height_x * wave_height * 2.0, 1.0, -height_z * wave_height * 2.0));
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float shimmer = 0.5 + 0.5 * sin(world_position.x * 0.9 + world_position.z * 1.1 + TIME * 2.0);
	ALBEDO = mix(deep_color, shallow_color, fresnel * 0.8 + shimmer * 0.08);
	ROUGHNESS = 0.08;
	METALLIC = 0.3;
	SPECULAR = 0.8;
}
