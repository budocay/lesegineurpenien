shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_opaque;
// Oiseau lointain : une silhouette plate dont les ailes battent (les bouts montent et descendent) et
// qui tourne en cercle lent autour de son point d'attache.

uniform sampler2D tex : source_color, filter_nearest, repeat_disable;
uniform float radius = 6.0;
uniform float rate = 0.25;
uniform float phase = 0.0;
uniform float flap = 7.0;

void vertex() {
	float t = TIME * rate + phase;
	float wing = abs(VERTEX.x);
	VERTEX.y += sin(TIME * flap + phase * 3.0) * wing * 0.7;
	VERTEX.x += sin(t) * radius;
	VERTEX.y += sin(t * 2.0) * radius * 0.12;
	VERTEX.z += cos(t) * radius * 0.5;
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb;
}
