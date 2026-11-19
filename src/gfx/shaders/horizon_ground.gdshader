shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_opaque;
// Sol lointain d'une carte à horizon : prolonge le sol de la carte jusqu'à l'horizon, moucheté
// et noyé dans la brume avec la distance.

uniform vec3 near_col : source_color = vec3(0.35, 0.27, 0.2);
uniform vec3 far_col : source_color = vec3(0.6, 0.55, 0.5);
uniform vec3 haze_col : source_color = vec3(0.82, 0.87, 0.93);
uniform float fade_from = 30.0;
uniform float fade_to = 230.0;

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = floor(wpos.xz * 0.5);
	float n = hash(g) * 0.5 + hash(floor(wpos.xz * 0.1)) * 0.5;
	float d = distance(wpos.xz, CAMERA_POSITION_WORLD.xz);
	vec3 col = mix(near_col, far_col, smoothstep(fade_from, fade_to, d));
	col *= 0.86 + n * 0.28;
	col = mix(col, haze_col, smoothstep(fade_from * 1.6, fade_to, d) * 0.85);
	ALBEDO = col;
}
