shader_type spatial;
// Sol d'une arène de combat : le sol de son lieu (herbe, sous-bois, vase, pavés, dalles),
// dégagé et éclairé. La texture reste visible : elle est nuancée par plaques (comme
// ground.gdshader), une seconde texture peut la recouvrir par taches (herbe dans l'humus,
// vase dans l'herbe), des flaques et un semis ras de fleurs et de touffes à plat sont peints
// directement sur le sol (rien qui dépasse, rien qui cache un combattant). Une nappe de
// lumière éclaircit le centre sans changer la teinte, les bords et le premier plan
// s'assombrissent doucement.
// Sert aussi, avec pool_boost = 0, de dessus de paroi (assombri, désaturé).

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform sampler2D tex2 : source_color, filter_nearest, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 base : source_color = vec3(0.5, 0.45, 0.35);   // couleur moyenne de la texture
uniform float flatten = 0.15;       // 0 : texture intacte, 1 : couleur unie
uniform float variation = 0.09;     // nuances par plaques (clair, sombre)
uniform float grain = 0.04;         // grain fin, pixel par pixel
uniform float texels_per_unit = 24.0;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);   // teinte du lieu (multiplie le sol)
uniform vec3 patch_tint : source_color = vec3(1.0, 1.0, 1.0);   // teinte de la seconde texture
uniform float patch_amount = 0.0;   // part du sol couverte par la seconde texture (0 à 1)
uniform float puddle_amount = 0.0;  // part du sol couverte de flaques (0 à 0,4)
uniform vec3 puddle_color : source_color = vec3(0.24, 0.38, 0.38);
uniform float fleck_density = 0.0;  // fleurs et touffes à plat, par case de 4 pixels
uniform vec3 fleck_a : source_color = vec3(0.96, 0.94, 0.88);   // pétales
uniform vec3 fleck_b : source_color = vec3(0.95, 0.80, 0.25);   // coeur
uniform vec3 tuft_color : source_color = vec3(0.45, 0.72, 0.32);
uniform float cloud_amount = 0.0;   // ombres de nuages : larges plaques douces qui assombrissent le sol (0 à 0,4)
uniform float cloud_scale = 0.06;   // finesse des nuages (petit : très larges)
uniform float dapple_amount = 0.0;  // ombres de feuillage tachetées, hors de la zone de jeu (bas et côtés de l'image)
uniform float stone_density = 0.0;  // pierres plates, hors de la zone de jeu, par case de 6 pixels
uniform float blade_density = 0.0;  // brins d'herbe dressés (traits de 3 pixels), un peu partout
uniform vec3 blade_a : source_color = vec3(0.85, 0.72, 0.30);   // brin éclairé
uniform vec3 blade_b : source_color = vec3(0.45, 0.36, 0.14);   // brin à l'ombre
uniform vec2 pool_center = vec2(0.0, 0.0);
uniform vec2 pool_radius = vec2(12.0, 7.5);   // demi-largeur et demi-profondeur de la nappe
uniform vec3 pool_color : source_color = vec3(1.0, 0.92, 0.78);
uniform float pool_boost = 0.45;    // éclat ajouté au centre
uniform float edge = 0.45;          // luminosité aux bords (1 = aucune vignette)
uniform float dim = 1.0;            // assombrissement général
uniform float desat = 0.0;          // 0 : couleurs pleines, 1 : gris

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
	vec4 c = texture(tex, UV * uv_scale);
	if (c.a < 0.5) {
		discard;
	}
	vec2 px = floor(wpos.xz * texels_per_unit);
	vec2 q = px / texels_per_unit;
	vec3 col = mix(c.rgb, base, flatten);

	// seconde matière par taches : bord grignoté pixel par pixel
	if (patch_amount > 0.0) {
		float m = vnoise(q * 0.17 + 7.0) * 0.6 + vnoise(q * 0.46 + 3.0) * 0.4;
		m += (hash(px + 5.0) - 0.5) * 0.07;
		if (m > mix(0.74, 0.34, clamp(patch_amount, 0.0, 1.0))) {
			col = texture(tex2, UV * uv_scale).rgb * patch_tint;
		}
	}

	// plaques de teinte, calculées sur la grille des pixels, tournées par rapport au monde
	vec2 r = vec2(q.x * 0.8 - q.y * 0.6, q.x * 0.6 + q.y * 0.8);
	float n = vnoise(r * 0.31) * 0.5 + vnoise(r * 0.83 + 17.0) * 0.3 + vnoise(r * 2.1 + 41.0) * 0.2;
	n += (hash(px + 9.0) - 0.5) * 0.2;
	n = floor(clamp(n, 0.0, 0.999) * 5.0) / 4.0;
	col *= 1.0 + (n - 0.5) * 2.0 * variation;
	col *= 1.0 + (hash(px) - 0.5) * 2.0 * grain;

	// flaques : taches plates, plus larges que hautes, liseré de vase
	if (puddle_amount > 0.0) {
		float p = vnoise(vec2(q.x * 0.30, q.y * 0.55) + 21.0) * 0.65 + vnoise(vec2(q.x * 0.9, q.y * 1.6) + 5.0) * 0.35;
		float thr = 0.88 - clamp(puddle_amount, 0.0, 0.4) * 0.9;
		if (p > thr + 0.025) {
			col = puddle_color * (0.92 + 0.16 * vnoise(vec2(q.x * 1.3, q.y * 3.0)));
		} else if (p > thr) {
			col = col * 0.62;
		}
	}

	// fleurs et touffes à plat : une case de 4 pixels sur 1/density, un petit motif de 3 x 3
	if (fleck_density > 0.0) {
		vec2 cell = floor(px / 4.0);
		float h = hash(cell + 31.0);
		if (h < fleck_density) {
			vec2 off = floor(vec2(hash(cell + 1.7), hash(cell + 2.9)) * 2.0);
			vec2 lp = px - cell * 4.0 - off;
			bool flower = hash(cell + 4.1) < 0.5;
			if (lp.x >= 0.0 && lp.x < 3.0 && lp.y >= 0.0 && lp.y < 3.0) {
				if (flower) {
					vec3 petal = hash(cell + 6.3) < 0.5 ? fleck_a : fleck_a * vec3(1.0, 0.82, 0.9);
					if (lp == vec2(1.0, 1.0)) {
						col = fleck_b;
					} else if (abs(lp.x - 1.0) + abs(lp.y - 1.0) == 1.0) {
						col = petal;
					}
				} else {
					if (lp == vec2(1.0, 1.0) || lp == vec2(0.0, 0.0) || lp == vec2(2.0, 0.0)) {
						col = tuft_color;
					} else if (lp == vec2(1.0, 2.0)) {
						col = tuft_color * 0.6;
					}
				}
			}
		}
	}

	// hors de la zone de jeu (sous les combattants, sur les côtés) : le sol se compose
	float away = max(smoothstep(2.4, 4.4, wpos.z), smoothstep(7.5, 10.5, abs(wpos.x)));
	if (blade_density > 0.0) {
		vec2 bc = floor(px / 3.0);
		if (hash(bc + 71.0) < blade_density * (0.4 + 0.6 * away)) {
			vec2 bl = px - bc * 3.0;
			float lean = floor(hash(bc + 3.3) * 3.0);   // brin penché à gauche, droit ou à droite
			if (bl.x == lean) {
				col = bl.y < 1.0 ? blade_a : (bl.y < 2.0 ? mix(blade_a, blade_b, 0.4) : blade_b);
			}
		}
	}
	if (stone_density > 0.0 && away > 0.0) {
		vec2 sc = floor(px / 6.0);
		if (hash(sc + 53.0) < stone_density * away) {
			vec2 so = vec2(hash(sc + 1.3), hash(sc + 8.1)) * 1.5;
			vec2 sp = (px - sc * 6.0 - vec2(3.0) - so + vec2(0.75)) / vec2(2.7, 1.7);
			if (length(sp) < 1.0) {
				float sl = dot(col, vec3(0.299, 0.587, 0.114));
				vec3 st = mix(col, vec3(sl * 1.3), 0.55);
				col = sp.y < -0.25 ? st * 1.25 : (sp.y > 0.45 ? st * 0.62 : st * 0.95);
			} else if (length(sp) < 1.35 && sp.y > 0.0) {
				col *= 0.7;   // ombre portée sous la pierre
			}
		}
	}
	if (dapple_amount > 0.0) {
		float dp = vnoise(q * vec2(0.5, 0.75) + 13.0) * 0.6 + vnoise(q * 1.6 + 29.0) * 0.4;
		float dm = smoothstep(0.5, 0.56, dp) * (0.55 + 0.45 * step(0.5, vnoise(q * 3.1 + 2.0)));
		col *= 1.0 - dapple_amount * away * dm;
	}
	if (cloud_amount > 0.0) {
		vec2 cq = wpos.xz * cloud_scale + vec2(3.0, 11.0);
		float cl = vnoise(cq) * 0.62 + vnoise(cq * 2.3 + 5.0) * 0.38;
		col *= 1.0 - cloud_amount * smoothstep(0.46, 0.7, cl);
	}

	col *= tint;
	float d = length((wpos.xz - pool_center) / pool_radius);
	float lit = 1.0 - smoothstep(0.3, 1.25, d);
	lit = lit * lit * (3.0 - 2.0 * lit);
	col *= mix(edge, 1.0, lit);
	col *= mix(vec3(1.0), pool_color, lit * 0.3);   // la nappe éclaircit, elle ne change presque pas la teinte
	col *= 1.0 + pool_boost * lit * lit;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat) * dim;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
