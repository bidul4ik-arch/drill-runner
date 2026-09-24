shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D dust_texture : source_color;
uniform vec4 dust_tint : source_color = vec4(0.84, 0.65, 0.40, 0.18);
void vertex() {
	vec3 size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * size.x, INV_VIEW_MATRIX[1] * size.y, INV_VIEW_MATRIX[2] * size.z, MODEL_MATRIX[3]);
}
void fragment() {
	vec4 puff = texture(dust_texture, UV);
	ALBEDO = dust_tint.rgb * (0.75 + puff.r * 0.25);
	ALPHA = puff.a * COLOR.a * dust_tint.a;
}
