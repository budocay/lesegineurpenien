shader_type sky;
// Ciel peint des cartes à horizon (champ `horizon` : voir src/world/horizon.gd) : dégradé du
// zénith à la brume, lueur du soleil bas, nuages en grosses cases qui dérivent lentement.

uniform vec3 top_col : source_color = vec3(0.25, 0.45, 0.78);
uniform vec3 mid_col : source_color = vec3(0.55, 0.74, 0.92);
uniform vec3 low_col : source_color = vec3(0.95, 0.90, 0.80);
uniform vec3 below_col : source_color = vec3(0.80, 0.80, 0.78);
uniform vec3 sun_dir = vec3(0.4, 0.22, 0.8);
uniform vec3 sun_col : source_color = vec3(1.0, 0.86, 0.6);
uniform float cloud_amount = 0.55;
uniform float cloud_speed = 0.006;
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.70, 0.85);
uniform float cell = 22.0;
uniform float seed = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(7.3, 1.9);
		a *= 0.5;
	}
	return s;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float e = d.y;
	vec3 col;
	if (e >= 0.0) {
		col = mix(low_col, mid_col, smoothstep(0.0, 0.2, e));
		col = mix(col, top_col, smoothstep(0.1, 0.75, e));
		float s = max(dot(d, normalize(sun_dir)), 0.0);
		col += sun_col * (pow(s, 5.0) * 0.22 + pow(s, 48.0) * 0.35);
		if (e > 0.008) {
			vec2 uv = d.xz / (e + 0.14);
			uv = floor(uv * cell) / cell;
			vec2 q = uv * 1.1 + vec2(TIME * cloud_speed, seed);
			float n = fbm(q);
			float dens = smoothstep(1.0 - cloud_amount, 1.0 - cloud_amount + 0.05, n);
			float n2 = fbm(q + normalize(sun_dir).xz * 0.09);
			float lit = clamp((n - n2) * 9.0 + 0.55, 0.0, 1.0);
			lit = floor(lit * 3.0 + 0.5) / 3.0;
			vec3 cc = mix(cloud_shade, cloud_lit, lit);
			cc = mix(cc, low_col, 0.35 * (1.0 - smoothstep(0.0, 0.3, e)));
			float fade = smoothstep(0.008, 0.14, e);
			col = mix(col, cc, dens * fade * 0.96);
		}
	} else {
		col = mix(low_col, below_col, smoothstep(0.0, -0.12, e));
	}
	COLOR = col;
}
