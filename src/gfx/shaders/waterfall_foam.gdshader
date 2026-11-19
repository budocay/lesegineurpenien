shader_type spatial;
// Nappe d'écume au pied d'une cascade : un disque de bulles qui se dissout en trame vers le bord, des cercles
// d'écume qui s'écartent du point de chute, des éclats qui miroitent. Bord irrégulier, découpe franche (pas de
// transparence : elle serait floutée par le flou de profondeur). Quad posé à plat ; `size` est sa taille en unités.
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform vec2 size = vec2(4.0, 2.0);
uniform float texels_per_unit = 24.0;

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
	vec2 px = floor(UV * size * texels_per_unit);
	vec2 q = (UV - vec2(0.5)) * 2.0;
	float dith = bayer(px);
	float d = length(q);
	float ang = atan(q.y, q.x);
	// contour irrégulier qui respire
	float rag = 0.86 + 0.14 * (vnoise(vec2(ang * 2.2 + 4.0, TIME * 0.3)) - 0.5) * 2.0;
	float core = 1.0 - d / rag;
	if (core < 0.04 + dith * 0.12) {
		discard;
	}
	// bulles : l'écume se dissout en trame vers le bord
	float bub = vnoise(px * 0.55 + vec2(TIME * 1.1, -TIME * 0.7));
	float dens = core * 1.25 + (bub - 0.5) * 0.5;
	if (dens < 0.26 + dith * 0.35) {
		discard;
	}
	// cercles qui s'écartent du point de chute
	float ring = 0.5 + 0.5 * sin(d * 13.0 - TIME * 3.2);
	float ringline = step(0.86, ring) * (1.0 - d);
	vec3 c = mix(tint * 0.74, tint, clamp(core * 1.3 + bub * 0.3, 0.0, 1.0));
	c = mix(c, vec3(1.0), clamp(ringline * 0.85 + step(0.9, core) * 0.3, 0.0, 1.0));
	// éclats
	float glint = step(0.955, hash(px * 1.7 + vec2(floor(TIME * 4.0), 9.0)));
	c = mix(c, vec3(1.0), glint * 0.9);
	ALBEDO = c;
}
