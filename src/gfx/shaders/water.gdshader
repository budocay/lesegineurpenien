shader_type spatial;
// Eau en pixels : nappes de couleur qui dérivent, rides qui passent, éclats qui
// scintillent. Tout est calculé sur la grille des pixels du monde.

uniform vec3 deep : source_color = vec3(0.06, 0.12, 0.26);
uniform vec3 shallow : source_color = vec3(0.17, 0.32, 0.48);
uniform vec3 ripple : source_color = vec3(0.55, 0.72, 0.86);
uniform vec3 glint : source_color = vec3(1.0, 0.8, 0.58);
uniform float texels_per_unit = 24.0;
// lac profond (champ « lake » de l'eau de la carte : x, z, largeur, profondeur en cases ; 0 : eau ordinaire).
// Bords clairs et peu profonds, centre sombre, reflets irréguliers et lueur qui flotte à la surface.
uniform vec4 lake = vec4(0.0);
uniform vec3 glow : source_color = vec3(0.2, 0.85, 0.8);
uniform float glow_power = 0.0;

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
	vec2 p = floor(wpos.xz * texels_per_unit) / texels_per_unit;
	float t = TIME;
	// nappes : deux bruits qui dérivent à des vitesses différentes
	float w = vnoise(vec2(p.x * 0.55 + t * 0.10, p.y * 1.3 - t * 0.06)) * 0.6
			+ vnoise(vec2(p.x * 1.4 - t * 0.17, p.y * 3.1 + t * 0.11)) * 0.4;
	float band = floor(clamp(w, 0.0, 0.999) * 5.0) / 4.0;
	// rides : traits horizontaux courts, qui avancent et se cassent
	float wave = sin(p.y * 7.0 + sin(p.x * 0.9 + t * 0.5) * 1.8 - t * 0.9);
	float broken = vnoise(vec2(p.x * 0.9 - t * 0.25, p.y * 4.0));
	float line = step(0.9, wave) * step(0.56, broken);
	// éclats : quelques cases s'allument et s'éteignent chacune à son rythme
	vec2 cell = floor(vec2(p.x * 4.0 + sin(p.y * 1.7 + t * 0.3) * 0.8, p.y * 9.0 - t * 0.5));
	float h = hash(cell);
	float twinkle = step(0.955, h) * max(0.0, sin(t * 2.6 + h * 57.0));
	vec3 base = mix(deep, shallow, band);
	vec3 em = glint * twinkle * 0.7 + ripple * line * 0.05;
	if (lake.z > 0.0) {
		// distance à la rive, en cases : 0 au bord, grande au centre ; la rive est un peu irrégulière
		vec2 q = wpos.xz - lake.xy;
		float wob = (vnoise(p * 0.8 + vec2(t * 0.05, 0.0)) - 0.5) * 0.9;
		float d = min(min(q.x, lake.z - q.x), min(q.y, lake.w - q.y)) + wob;
		float shore = 1.0 - smoothstep(0.0, 2.4, d);
		float core = smoothstep(1.5, 5.0, d);
		// profondeur : le centre s'assombrit, les bords s'éclaircissent et prennent la couleur du fond
		base = mix(base, deep * 0.45, core * 0.85);
		base = mix(base, shallow * 1.25 + ripple * 0.08, shore * 0.8);
		// reflets : traits horizontaux de longueurs et de hauteurs inégales, jamais deux fois pareils
		float row = floor(p.y * 5.0);
		float rh = hash(vec2(row, 3.1));
		float len = 0.6 + rh * 2.6;
		float x0 = p.x * 0.8 + t * (0.05 + rh * 0.07) * (rh > 0.5 ? 1.0 : -1.0);
		float seg = floor(x0 / len);
		float hs = hash(vec2(seg, row));
		float inside = step(0.0, fract(x0 / len)) * step(fract(x0 / len), 0.18 + hs * 0.3);
		float stroke = step(0.62, hs) * inside * step(0.35, vnoise(p * 1.3 + 7.0));
		stroke *= 0.45 + 0.55 * (1.0 - core * 0.5);
		// la lueur : de grandes taches douces, en trois paliers, qui dérivent lentement
		float g = vnoise(p * vec2(0.42, 0.8) + vec2(t * 0.045, -t * 0.03)) * 0.65 + vnoise(p * 0.9 - vec2(t * 0.07, 0.0)) * 0.35;
		float gl = floor(smoothstep(0.55, 0.9, g) * 3.0) / 3.0;
		gl *= 0.5 + 0.5 * core;
		base += ripple * stroke * 0.22;
		em = ripple * stroke * 0.18 + glow * gl * glow_power + glint * twinkle * 0.18;
		base += glow * gl * glow_power * 0.25;
	}
	ALBEDO = base + (lake.z > 0.0 ? vec3(0.0) : ripple * line * 0.16);
	EMISSION = em;
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
