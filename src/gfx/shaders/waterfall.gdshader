shader_type spatial;
// Cascade en pixels : filets d'eau qui tombent à des vitesses différentes, écume en haut
// et en bas, bords déchiquetés. Opaque (découpe franche) pour ne pas être floutée par le
// flou de profondeur. À poser sur un quad vertical ; `size` est sa taille en unités.
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
	float cols = floor(size.x * texels_per_unit);
	float x = p.x;
	float y = p.y;
	// bords irréguliers : l'eau s'élargit un peu en bas
	float edge = 0.5 - (0.05 + 0.02 * hash(vec2(0.0, y * 0.5))) - UV.y * 0.0;
	float dx = abs(UV.x - 0.5);
	float ragged = 0.46 + 0.05 * hash(vec2(floor(y / 3.0), 7.0)) - 0.02 * (1.0 - UV.y);
	if (dx > ragged) {
		discard;
	}
	// filets : chaque colonne a sa vitesse et son rythme
	float col = hash(vec2(x, 3.0));
	float spd = speed * (0.55 + col * 0.9);
	float v = fract(y / (7.0 + col * 11.0) + TIME * spd * 0.35 + col * 9.0);
	float streak = step(0.55, v);
	float light = step(0.82, v);
	float c2 = hash(vec2(floor(x / 2.0), 11.0));
	vec3 c = mix(deep, body, streak * 0.8 + c2 * 0.2);
	c = mix(c, foam, light * 0.85);
	// écume du haut (le seuil) et du pied (la chute dans le bassin)
	float top = 1.0 - smoothstep(0.0, 0.07, UV.y);
	float bottom = smoothstep(0.84, 0.97, UV.y);
	float puff = step(0.45, hash(vec2(x + floor(TIME * 3.0), floor(y / 2.0) + 5.0)));
	c = mix(c, foam, clamp(top, 0.0, 1.0));
	c = mix(c, foam, bottom * puff);
	if (bottom > 0.9 && puff < 0.5 && hash(vec2(x * 3.0, floor(TIME * 4.0))) < 0.5) {
		discard;
	}
	ALBEDO = c * brightness;
}
