shader_type spatial;
// Eau en pixels. Tout est calculé sur la grille des pixels du monde et passe par un tramage
// ordonné (comme les dégradés des jeux en pixel art) : jamais de bandes dures ni de taches.
//  - profondeur : `shore_tex` donne, pour chaque point, la distance à la rive la plus proche ;
//    clair et turquoise près du bord, de plus en plus sombre vers le large ;
//  - rive : liseré d'écume irrégulier qui respire, deuxième trait plus pâle qui avance ;
//  - surface : rides fines qui se cassent, éclats qui scintillent, brume très douce qui dérive ;
//  - lac profond (champ « lake ») : surface lisse et sombre, reflet de la paroi du fond (silhouette
//    déchiquetée et traînées verticales de lueur qui ondulent), grandes lueurs qui flottent.

uniform vec3 deep : source_color = vec3(0.06, 0.12, 0.26);
uniform vec3 shallow : source_color = vec3(0.17, 0.32, 0.48);
uniform vec3 ripple : source_color = vec3(0.55, 0.72, 0.86);
uniform vec3 glint : source_color = vec3(1.0, 0.8, 0.58);
uniform float texels_per_unit = 24.0;
// lac profond (champ « lake » de l'eau de la carte : x, z, largeur, profondeur en cases ; 0 : eau ordinaire).
uniform vec4 lake = vec4(0.0);
uniform vec3 glow : source_color = vec3(0.2, 0.85, 0.8);
uniform float glow_power = 0.0;
// carte des distances à la rive (R : distance en cases divisée par 8) et zone qu'elle recouvre (x, z, largeur, hauteur)
uniform sampler2D shore_tex : filter_linear, repeat_disable;
uniform vec4 shore_rect = vec4(0.0, 0.0, 1.0, 1.0);

// reflets des sources de lumière posées au bord de l'eau (cristaux, torches) : x, z, longueur du reflet, sens (+1 vers
// la caméra, -1 à l'opposé, 0 : inutilisé) et leur couleur
uniform vec4 refl[12];
uniform vec4 refl_c[12];

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

// matrice de Bayer 4x4, de -0.5 à 0.5
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
	vec2 px = floor(wpos.xz * texels_per_unit);
	vec2 p = px / texels_per_unit;
	float t = TIME;
	float dith = bayer(px);
	bool is_lake = lake.z > 0.0;

	// distance à la rive, en cases (un bassin posé à la main n'a pas de carte : eau peu profonde)
	float d = 1.5;
	if (shore_rect.z > 1.0) {
		d = texture(shore_tex, (wpos.xz - shore_rect.xy) / shore_rect.zw).r * 8.0;
	}
	float wob = (vnoise(p * 0.9 + vec2(t * 0.05, 0.0)) - 0.5) * 0.8 + (vnoise(p * 2.7 - vec2(0.0, t * 0.08)) - 0.5) * 0.25;
	d = max(d + wob, 0.0);

	// nappes lentes : deux bruits qui dérivent
	float w = vnoise(vec2(p.x * 0.5 + t * 0.07, p.y * 1.1 - t * 0.05)) * 0.6
			+ vnoise(vec2(p.x * 1.3 - t * 0.12, p.y * 2.7 + t * 0.09)) * 0.4;

	// profondeur : 0 sur la rive, 1 au large (plus longue dans un lac)
	float span = is_lake ? 4.2 : 2.8;
	float dep = smoothstep(0.15, span, d);
	// teintes : fond clair vu à travers l'eau peu profonde, couleur de l'eau, couleur profonde
	vec3 shore_col = is_lake ? mix(shallow * 1.5, mix(ripple, glow, 0.3), 0.34) : mix(shallow * 1.22, ripple, 0.1);
	vec3 deep_col = is_lake ? deep * 0.62 : deep;
	float tone = clamp(dep * 0.8 + (w - 0.5) * 0.22 * dep, 0.0, 1.0);
	float steps = 7.0;
	float tq = floor(clamp(tone + dith / steps * 1.2, 0.0, 1.0) * steps) / steps;
	vec3 base = tq < 0.5 ? mix(shore_col, shallow, tq * 2.0) : mix(shallow, deep_col, (tq - 0.5) * 2.0);

	// fond visible dans les hauts-fonds : galets sombres qui ondulent un peu
	float stones = vnoise(p * 2.3 + vec2(sin(t * 0.4 + p.y * 2.0) * 0.12, 0.0));
	float shallows = 1.0 - smoothstep(0.5, 1.9, d);
	base = mix(base, shallow * 0.8, step(0.7, stones) * shallows * (is_lake ? 0.5 : 0.22));

	vec3 em = vec3(0.0);

	// rides : traits fins horizontaux qui avancent et se cassent
	float wave = sin(p.y * 7.0 + sin(p.x * 0.9 + t * 0.5) * 1.8 - t * 0.9);
	float broken = vnoise(vec2(p.x * 0.9 - t * 0.25, p.y * 4.0));
	float line = step(0.9, wave) * step(0.56, broken) * (is_lake ? 0.5 : 1.0);
	base += ripple * line * (is_lake ? 0.08 : 0.17) * (0.4 + 0.6 * dep);

	// éclats : quelques cases s'allument et s'éteignent chacune à son rythme
	vec2 cell = floor(vec2(p.x * 4.0 + sin(p.y * 1.7 + t * 0.3) * 0.8, p.y * 9.0 - t * 0.5));
	float h = hash(cell);
	float twinkle = step(0.955, h) * max(0.0, sin(t * 2.6 + h * 57.0));
	em += glint * twinkle * (is_lake ? 0.22 : 0.62);

	// rive : liseré d'écume irrégulier qui respire, puis un second trait plus pâle qui s'éloigne
	float edge = (is_lake ? 0.2 : 0.11) + (is_lake ? 0.16 : 0.1) * vnoise(p * 3.1 + vec2(t * 0.35, 0.0)) + 0.05 * sin(t * 0.9 + p.x * 1.6);
	float foam1 = step(d, edge) * step(0.42, vnoise(p * 4.5 + 3.0));
	float ring = abs(d - (0.62 + 0.18 * sin(t * 0.55 + p.x * 0.8) + 0.2 * (vnoise(p * 1.7) - 0.5)));
	float foam2 = step(ring, 0.055) * step(0.45, vnoise(p * 2.6 - vec2(t * 0.2, 0.0)));
	vec3 foam_col = mix(ripple, vec3(1.0), 0.55);
	base = mix(base, foam_col * (is_lake ? 0.6 : 0.78), foam1 * (is_lake ? 0.5 : 0.5) + foam2 * 0.35);
	em += foam_col * (foam1 * 0.28 + foam2 * 0.12);

	// brume très douce, qui dérive au-dessus de l'eau
	float mist = smoothstep(0.55, 0.9, vnoise(p * vec2(0.3, 0.55) + vec2(t * 0.025, -t * 0.012)));
	float mist_q = floor(mist * 4.0 + dith * 0.9 + 0.5) / 4.0;
	em += mix(ripple, glow, is_lake ? 0.4 : 0.0) * mist_q * (is_lake ? 0.07 : 0.035) * smoothstep(0.8, 3.0, d);

	if (is_lake) {
		vec2 q = wpos.xz - lake.xy;
		float north = q.y;                       // cases depuis la paroi du fond
		float across = q.x;
		// reflet de la paroi du fond : silhouette déchiquetée qui descend vers nous, sombre, rendue plus nette près du bord
		float jag = vnoise(vec2(p.x * 1.7, 4.0)) * 1.5 + vnoise(vec2(p.x * 5.0, 9.0)) * 0.6;
		float refl_len = 1.6 + jag;
		float wall = 1.0 - smoothstep(refl_len * 0.55, refl_len, north + sin(p.x * 3.0 + t * 0.7) * 0.07);
		base = mix(base, deep * 0.22, wall * 0.78);
		// quelques gouttes de lueur de la voûte, très rares, qui se reflètent en courts traits verticaux
		float colx = floor((p.x + sin(north * 5.0 + t * 0.9) * 0.06) * 2.0);
		float hc = hash(vec2(colx, 5.0));
		float reach = 0.8 + hc * 2.2;
		float dash = step(0.45, fract(north * 3.2 - t * 0.3 + hc * 9.0));
		float streak = step(0.9, hc) * (1.0 - smoothstep(0.0, reach, north)) * dash;
		vec3 streak_col = mix(glow, ripple, 0.35);
		base += streak_col * streak * 0.14;
		em += streak_col * streak * 0.16;
		// grandes lueurs bleutées, tramées, qui flottent sans jamais faire de taches franches
		float g = vnoise(p * vec2(0.4, 0.75) + vec2(t * 0.04, -t * 0.028)) * 0.65 + vnoise(p * 0.85 - vec2(t * 0.06, 0.0)) * 0.35;
		float gl = clamp((g - 0.56) * 2.6, 0.0, 1.0);
		float glq = floor(gl * 5.0 + dith * 1.1 + 0.5) / 5.0;
		em += glow * glq * glow_power * 0.5 * (0.45 + 0.55 * dep);
		// reflet doux de la rive claire (les côtés) : un voile pâle qui s'estompe vers le large
		em += ripple * (1.0 - smoothstep(0.0, 1.6, d)) * 0.06;
	}
	// reflets alignés sur les sources de lumière : un trait vertical qui ondule, coupé de rides, qui s'éteint en s'éloignant
	for (int i = 0; i < 12; i++) {
		vec4 r = refl[i];
		if (r.w == 0.0) {
			continue;
		}
		float dx = p.x - r.x;
		float dz = (p.y - r.y) * r.w;
		if (dz > 0.0 && dz < r.z) {
			float k = dz / r.z;
			float wig = sin(dz * 9.0 - t * 1.4 + r.x * 3.0) * 0.07 * (0.3 + k);
			float body = step(abs(dx + wig), 0.2 - 0.11 * k);
			float cut = step(0.3, fract(dz * 3.4 - t * 0.22 + hash(vec2(r.x, r.y)) * 5.0));
			float a = body * cut * (1.0 - k * 0.8);
			base = mix(base, refl_c[i].rgb * 0.8, a * 0.5);
			em += refl_c[i].rgb * a * refl_c[i].a * 0.55;
		}
	}
	ALBEDO = base;
	EMISSION = em;
	ROUGHNESS = 0.22;
	SPECULAR = 0.6;
}
