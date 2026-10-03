shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform sampler2D detail_texture : source_color, filter_nearest;
uniform vec3 hologram_color : source_color = vec3(0.25, 0.85, 1.0);
uniform float scanline_density = 18.0;
uniform float intensity = 1.2;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float detail = dot(texture(detail_texture, UV).rgb, vec3(0.3, 0.59, 0.11));
	float scanline = 0.65 + 0.35 * sin(world_position.y * scanline_density - TIME * 5.0);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float flicker = 0.9 + 0.1 * sin(TIME * 31.0) * sin(TIME * 7.0);
	ALBEDO = hologram_color * (0.25 + detail * 0.6 + rim * 1.4) * scanline * flicker * intensity;
}
