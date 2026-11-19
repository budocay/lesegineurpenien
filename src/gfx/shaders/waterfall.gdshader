shader_type spatial;
// Cascade en pixels : une nappe d'eau qui tombe. Trois couches de coulées verticales douces défilent à des
// vitesses différentes (plus claires au centre, plus sombres et plus minces vers les bords), des filets brillants
// les traversent, la nappe devient transparente vers les bords (transparence tramée : on voit la roche mouillée
// derrière), un liseré d'écume la coiffe au seuil et une brume d'écume l'enveloppe au pied.
// Opaque (découpe franche) pour ne pas être floutée par le flou de profondeur. À poser sur un quad vertical ;
// `size` est sa taille en unités.
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec3 body : source_color = vec3(0.70, 0.86, 0.95);
uniform vec3 deep : source_color = vec3(0.40, 0.64, 0.80);
uniform vec3 foam : source_color = vec3(0.98, 1.0, 1.0);
uniform vec2 size = vec2(2.0, 3.0);
uniform float texels_per_unit = 24.0;
uniform float speed = 2.4;
uniform float brightness = 1.0;

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

void fragment() {
	vec2 px = floor(vec2(UV.x * size.x, UV.y * size.y) * texels_per_unit);
	vec2 p = px / texels_per_unit;           // x : 0 à size.x ; y : distance sous le seuil, en unités
	float t = TIME * speed * 0.42;
	float dith = bayer(px);
	float ex = abs(UV.x - 0.5) * 2.0;        // 0 au centre, 1 au bord
	float side = step(0.5, UV.x) * 5.0;

	// bord : la nappe s'amincit et se troue ; plus large au pied où elle s'étale
	float spread = smoothstep(size.y - 1.6, size.y, p.y) * 0.12;
	float wob = vnoise(vec2(p.y * 0.8 - t * 0.35, 3.0 + side)) - 0.5;
	float cover = 1.0 - smoothstep(0.74, 1.0 - spread, ex + wob * 0.12);
	if (cover < 0.5 + dith * 0.85) {
		discard;
	}

	// trois couches de coulées : fines et rapides, moyennes, larges et lentes
	float s1 = vnoise(vec2(p.x * 3.4, p.y * 0.5 - t * 2.3));
	float s2 = vnoise(vec2(p.x * 7.5 + 11.0, p.y * 0.8 - t * 3.5));
	float s3 = vnoise(vec2(p.x * 1.5 + 23.0, p.y * 0.28 - t * 1.5));
	float flow = s1 * 0.38 + s2 * 0.27 + s3 * 0.35;
	float mid = 1.0 - ex;
	float tone = clamp((flow - 0.4) * 1.7 + mid * 0.25 + 0.42 + dith * 0.14, 0.0, 1.0);
	float tq = floor(tone * 5.0) / 4.0;
	vec3 c = mix(deep * 0.62, body, clamp(tq, 0.0, 1.0));
	c = mix(c, body * 1.12, smoothstep(0.7, 1.0, tq) * 0.4);
	// vers les bords l'eau s'amincit et fonce
	c *= mix(1.0, 0.7, smoothstep(0.5, 1.0, ex));

	// filets brillants : de longs traits verticaux plus clairs
	float fil = smoothstep(0.62, 0.78, vnoise(vec2(p.x * 12.0 + 5.0, p.y * 0.33 - t * 4.4)));
	float fil2 = smoothstep(0.74, 0.88, vnoise(vec2(p.x * 6.0 + 40.0, p.y * 0.45 - t * 3.0)));
	float shine = max(fil, fil2 * 0.7) * (0.35 + 0.65 * mid);
	c = mix(c, mix(body, foam, 0.7), step(0.5, shine + dith * 0.25) * 0.75);

	// seuil : liseré d'écume qui déborde, tramé vers le bas
	float lip = 1.0 - smoothstep(0.0, 0.5, p.y);
	float lace = 0.55 + 0.45 * vnoise(vec2(p.x * 7.0, t * 2.0));
	c = mix(c, foam, step(0.45 + dith * 0.5, lip * lace) * 0.9);

	// pied : brume d'écume qui monte et se déchire
	float low = smoothstep(size.y - 1.5, size.y - 0.1, p.y);
	float puff = vnoise(vec2(p.x * 3.2, p.y * 2.4 + TIME * 1.3));
	c = mix(c, foam, step(0.52 + dith * 0.5, low * (0.4 + 0.9 * puff)) * 0.92);
	if (p.y > size.y - 0.3 && vnoise(vec2(p.x * 5.0, p.y * 6.0 + TIME * 2.0)) < 0.42 + dith * 0.2) {
		discard;
	}
	ALBEDO = c * brightness;
}
