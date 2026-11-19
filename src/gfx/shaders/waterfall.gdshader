shader_type spatial;
// Cascade en pixels : de larges filets lisses qui coulent chacun à sa vitesse, plus clairs au centre qu'aux bords,
// traversés de longues coulées brillantes et de rares bulles, avec un épais liseré d'écume au seuil et des
// bouffées d'écume au pied. Bords déchiquetés mais sans trous. Opaque (découpe franche) pour ne pas être
// floutée par le flou de profondeur. À poser sur un quad vertical ; `size` est sa taille en unités.
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

void fragment() {
	vec2 p = floor(UV * size * texels_per_unit);
	float x = p.x;
	float y = p.y;
	float dx = abs(UV.x - 0.5);
	float ragged = 0.465 + 0.035 * hash(vec2(floor(y / 4.0), 7.0)) - 0.02 * (1.0 - UV.y);
	if (dx > ragged) {
		discard;
	}
	// filets de 5 texels de large : chacun sa vitesse et son rythme
	float g = floor(x / 5.0);
	float gh = hash(vec2(g, 3.0));
	float across = fract(x / 5.0);
	float rim = smoothstep(0.0, 0.28, across) * (1.0 - smoothstep(0.72, 1.0, across));
	float spd = speed * (0.45 + gh * 0.75);
	float v = fract(y / (18.0 + gh * 16.0) - TIME * spd * 0.22 + gh * 9.0);
	float band = smoothstep(0.55, 0.62, v) * (1.0 - smoothstep(0.86, 0.95, v));
	float gleam = step(0.88, v) * step(0.4, rim);
	vec3 c = mix(deep, body, 0.7 + 0.3 * rim);
	c = mix(c, body * 1.1, band * 0.55 * rim);
	c = mix(c, foam, gleam * 0.7);
	// rares bulles qui montent dans la masse
	float bub = step(0.992, hash(vec2(x, floor(y / 3.0) + floor(TIME * 1.5 * (0.5 + gh)))));
	c = mix(c, foam, bub * 0.9);
	// épais liseré d'écume au seuil, bouffées d'écume au pied
	float top = 1.0 - smoothstep(0.0, 0.09, UV.y);
	float bottom = smoothstep(0.84, 0.97, UV.y);
	float puff = step(0.4, hash(vec2(x + floor(TIME * 3.0), floor(y / 2.0) + 5.0)));
	c = mix(c, foam, clamp(top, 0.0, 1.0));
	c = mix(c, foam, bottom * puff);
	if (bottom > 0.9 && puff < 0.5 && hash(vec2(x * 3.0, floor(TIME * 4.0))) < 0.5) {
		discard;
	}
	ALBEDO = c * brightness;
}
