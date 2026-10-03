shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec3 tint : source_color = vec3(1.0, 0.55, 0.9);

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	vec3 rainbow = 0.5 + 0.5 * cos(6.2831 * (rim * 1.5 + TIME * 0.4 + vec3(0.0, 0.33, 0.67)));
	ALBEDO = mix(tint, rainbow, 0.45) * (0.08 + rim * 1.6);
}
