shader_type spatial;
// Sol en pixel art : la texture répétée est nuancée par grandes plaques (plus claires,
// plus sombres, plus chaudes), calculées sur la grille des pixels du monde pour rester
// nettes. Cela casse la répétition du motif sans repeindre chaque carte.

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform float variation = 0.07;
uniform float texels_per_unit = 24.0;

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
	if (c.a < 0.5) {
		discard;
	}
	vec2 q = floor(wpos.xz * texels_per_unit) / texels_per_unit;
	// grille du bruit tournée : les plaques ne suivent pas les cases de la carte
	vec2 r = vec2(q.x * 0.8 - q.y * 0.6, q.x * 0.6 + q.y * 0.8);
	float n = vnoise(r * 0.31) * 0.5 + vnoise(r * 0.83 + 17.0) * 0.3 + vnoise(r * 2.1 + 41.0) * 0.2;
	// bord des plaques grignoté pixel par pixel, puis teinte par paliers
	n += (hash(q * texels_per_unit) - 0.5) * 0.2;
	n = floor(clamp(n, 0.0, 0.999) * 5.0) / 4.0;
	vec3 col = c.rgb * (1.0 + (n - 0.5) * 2.0 * variation);
	col *= mix(vec3(0.95, 1.0, 1.05), vec3(1.05, 1.02, 0.93), n);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
