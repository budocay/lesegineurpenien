shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_opaque;
// Plan peint d'un arrière-plan à parallaxe (src/world/horizon.gd) : texture découpée net,
// brume qui monte du pied (haze_bottom) vers le haut (haze_top), feux et fenêtres allumées.

uniform sampler2D tex : source_color, filter_nearest, repeat_disable;
uniform vec3 haze_col : source_color = vec3(0.82, 0.87, 0.93);
uniform float haze_top = 0.15;
uniform float haze_bottom = 0.7;
uniform float light = 1.0;

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	float h = mix(haze_top, haze_bottom, clamp(UV.y, 0.0, 1.0));
	vec3 col = mix(c.rgb * light, haze_col, h);
	float glow = 0.0;
	if (c.r > 0.9 && c.g > 0.35 && c.b < 0.45) {
		glow = 1.0;
		col = c.rgb;
	}
	ALBEDO = col;
	EMISSION = c.rgb * glow * 1.6;
}
