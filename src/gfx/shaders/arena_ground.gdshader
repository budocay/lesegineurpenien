shader_type spatial;
// Sol d'une arène de combat : une scène dégagée, comme une piste éclairée.
// La texture est aplatie vers sa couleur moyenne (sol uni, grain fin), puis une nappe de
// lumière chaude éclaire le centre, là où se tiennent les combattants, et le sol
// s'assombrit nettement vers les bords et le premier plan.
// Sert aussi, avec pool_boost = 0, de dessus de paroi (assombri, désaturé).

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 base : source_color = vec3(0.5, 0.45, 0.35);   // couleur moyenne de la texture
uniform float flatten = 0.6;        // 0 : texture intacte, 1 : couleur unie
uniform float grain = 0.05;         // grain fin, pixel par pixel
uniform float texels_per_unit = 24.0;
uniform vec2 pool_center = vec2(0.0, 0.0);
uniform vec2 pool_radius = vec2(12.0, 7.5);   // demi-largeur et demi-profondeur de la nappe
uniform vec3 pool_color : source_color = vec3(1.0, 0.86, 0.62);
uniform float pool_boost = 0.55;    // éclat ajouté au centre
uniform float edge = 0.22;          // luminosité aux bords (1 = aucune vignette)
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
	vec2 q = floor(wpos.xz * texels_per_unit) / texels_per_unit;
	float g = (hash(q * texels_per_unit) - 0.5) * 2.0 * grain;
	float plate = (vnoise(q * 0.35) - 0.5) * 0.06;
	vec3 col = mix(c.rgb, base, flatten) * (1.0 + g + plate);
	float d = length((wpos.xz - pool_center) / pool_radius);
	float lit = 1.0 - smoothstep(0.3, 1.25, d);
	lit = lit * lit * (3.0 - 2.0 * lit);
	col *= mix(edge, 1.0, lit);
	col *= mix(vec3(1.0), pool_color, lit * 0.85);
	col *= 1.0 + pool_boost * lit * lit;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat) * dim;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
