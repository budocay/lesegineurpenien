shader_type spatial;
// Paroi de roche : texture stratifiée nette, assombrie au pied (couleur des sommets),
// nuancée par grandes plaques calculées sur la grille des pixels du monde.

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform float variation = 0.10;
uniform float texels_per_unit = 24.0;
uniform float dim = 1.0;     // assombrissement du fond (décor repoussé)
uniform float desat = 0.0;   // désaturation du fond
uniform vec3 haze_color : source_color = vec3(0.3, 0.28, 0.4);
uniform float haze = 0.0;    // brume de distance mêlée à la paroi

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 c = texture(tex, UV);
	vec2 q = floor(wpos.xy * texels_per_unit) / texels_per_unit + vec2(wpos.z * 0.7, 0.0);
	float n = vnoise(q * vec2(0.35, 0.9)) * 0.6 + vnoise(q * 1.7 + 9.0) * 0.4;
	n = floor(n * 4.0) / 3.0;
	vec3 col = c.rgb * COLOR.rgb * (1.0 + (n - 0.5) * 2.0 * variation);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat) * dim;
	col = mix(col, haze_color, haze);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
