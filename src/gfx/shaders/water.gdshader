shader_type spatial;
// Eau en pixels : nappes de couleur qui dérivent, rides qui passent, éclats qui
// scintillent. Tout est calculé sur la grille des pixels du monde.

uniform vec3 deep : source_color = vec3(0.06, 0.12, 0.26);
uniform vec3 shallow : source_color = vec3(0.17, 0.32, 0.48);
uniform vec3 ripple : source_color = vec3(0.55, 0.72, 0.86);
uniform vec3 glint : source_color = vec3(1.0, 0.8, 0.58);
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
	ALBEDO = mix(deep, shallow, band) + ripple * line * 0.16;
	EMISSION = glint * twinkle * 0.7 + ripple * line * 0.05;
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
