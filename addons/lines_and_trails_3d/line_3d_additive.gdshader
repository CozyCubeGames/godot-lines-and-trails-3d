shader_type spatial;

render_mode
	blend_add,
	cull_back,
	shadows_disabled,
	unshaded,
	depth_draw_never,
	world_vertex_coords;

uniform sampler2D color_tex : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform float tex_tile_factor = 1.0;
uniform float tex_offset = 0.0;

void vertex() {
	vec3 p = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 t = (VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 b = normalize(cross(p, t));
	p += UV.y * b;
	VERTEX = (INV_VIEW_MATRIX * vec4(p, 1.0)).xyz;
	UV.y = (sign(UV.y) + 1.0) / 2.0;
}

void fragment() {
	vec4 c = texture(color_tex, vec2(UV.x * tex_tile_factor + tex_offset, UV.y));
	ALBEDO = COLOR.rgb * c.rgb;
	ALPHA = COLOR.a * c.a;
}
