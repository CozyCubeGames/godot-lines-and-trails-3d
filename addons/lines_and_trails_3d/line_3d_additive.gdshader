shader_type spatial;

render_mode
	blend_add,
	cull_disabled,
	shadows_disabled,
	unshaded,
	depth_draw_never,
	skip_vertex_transform;

uniform sampler2D color_tex : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform float tex_tile_factor = 1.0;
uniform float tex_offset = 0.0;

void vertex() {
	vec3 p = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 t = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	VERTEX = p + UV.y * normalize(cross(p, t));
	UV.y = (sign(UV.y) + 1.0) / 2.0;
}

void fragment() {
	vec4 c = texture(color_tex, vec2(UV.x * tex_tile_factor + tex_offset, UV.y));
	ALBEDO = COLOR.rgb * c.rgb;
	ALPHA = COLOR.a * c.a;
}
