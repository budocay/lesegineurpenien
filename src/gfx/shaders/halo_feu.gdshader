shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
// Halo chaud d'un brasier ou d'un feu de camp : un disque additif qui fait face à la caméra et vacille.

uniform vec4 col : source_color = vec4(1.0, 0.55, 0.18, 1.0);
uniform float strength = 0.9;
instance uniform float phase = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float fl = 0.82 + 0.12 * sin(TIME * 7.0 + phase * 6.28) + 0.06 * sin(TIME * 13.0 + phase * 3.0);
	float a = pow(clamp(1.0 - d, 0.0, 1.0), 2.0) * strength * fl;
	ALBEDO = col.rgb * a;
}
