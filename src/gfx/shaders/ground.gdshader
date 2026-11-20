shader_type spatial;
// Sol en pixel art : la texture répétée est nuancée par grandes plaques (plus claires,
// plus sombres, plus chaudes), calculées sur la grille des pixels du monde pour rester
// nettes. Cela casse la répétition du motif sans repeindre chaque carte.

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform float variation = 0.07;
uniform float texels_per_unit = 24.0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
// ombres de nuages (force réglée par la carte, voir `clouds` dans FORMAT_DONNEES.md) : grandes plaques qui dérivent lentement
global uniform float cloud_shadow;

// bord de l'eau (cartes qui en ont) : G de `shore_tex` = distance à l'eau côté terre, en cases divisée par 2
uniform sampler2D shore_tex : filter_linear, repeat_disable;
uniform vec4 shore_rect = vec4(0.0, 0.0, 1.0, 1.0);

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

float bayer(vec2 px) {
	ivec2 i = ivec2(mod(px, 4.0));
	int idx = i.x + i.y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[idx] / 16.0 - 0.47;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 c = texture(tex, UV * uv_scale);
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
	if (cloud_shadow > 0.0) {
		vec2 drift = vec2(TIME * 0.35, TIME * 0.12);
		float cl = vnoise((q + drift) * 0.05) * 0.62 + vnoise((q - drift * 0.6) * 0.12 + 9.0) * 0.38;
		// quatre paliers tramés : une ombre de nuage en pixels, pas un voile flou
		float edge = smoothstep(0.5, 0.74, cl);
		float dith = (hash(floor(q * texels_per_unit * 0.5)) - 0.5) * 0.35;
		float shade_q = floor(clamp(edge + dith * edge * (1.0 - edge) * 3.0, 0.0, 1.0) * 3.0 + 0.5) / 3.0;
		col *= mix(vec3(1.0), vec3(0.8, 0.86, 0.98), shade_q * cloud_shadow * 0.3);
	}
	if (shore_rect.z > 1.0) {
		float land = texture(shore_tex, (wpos.xz - shore_rect.xy) / shore_rect.zw).g * 2.0;
		if (land < 0.9) {
			vec2 px = floor(wpos.xz * texels_per_unit);
			float ord = bayer(px);
			float lj = land + (vnoise(q * 2.3) - 0.5) * 0.14 + ord * 0.05;
			// berge mouillée : sombre et fraîche au contact, elle sèche en trois paliers tramés
			float wet = floor(clamp(1.0 - smoothstep(0.0, 0.62, lj), 0.0, 1.0) * 4.0 + 0.5) / 4.0;
			col *= 1.0 - wet * 0.34;
			col = mix(col, col * vec3(0.8, 0.95, 1.05), wet);
			// mousse en plaques sur la berge humide
			float moss = step(0.56, vnoise(q * 1.3 + 3.0)) * step(0.35, vnoise(q * 3.7)) * (1.0 - smoothstep(0.12, 0.5, lj)) * step(0.1, lj);
			col = mix(col, col * vec3(0.72, 1.12, 0.62), moss * 0.7);
			// galets : quelques pixels clairs et sombres, plus serrés tout au bord
			float h1 = hash(floor(q * texels_per_unit * 0.5));
			float pebble = step(0.9, h1) * (1.0 - smoothstep(0.2, 0.55, lj)) * step(0.06, lj);
			float lit = step(0.5, hash(floor(q * texels_per_unit * 0.5) + 7.0));
			col = mix(col, mix(col * 0.55, vec3(0.62, 0.62, 0.58) * (0.85 + 0.3 * h1), lit), pebble * 0.85);
		}
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
