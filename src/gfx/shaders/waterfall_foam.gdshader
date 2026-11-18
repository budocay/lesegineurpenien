shader_type spatial;
// Nappe d'écume et reflet au pied d'une cascade : un disque de bulles pixelisées qui se
// renouvellent, plus clair au centre, avec des reflets qui miroitent. Découpe franche (pas de
// transparence : elle serait floutée par le flou de profondeur). Quad posé à plat.
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float texels_per_unit = 22.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 q = (UV - vec2(0.5, 0.5)) * vec2(2.0, 2.0);
	vec2 cell = floor(UV * vec2(34.0, 18.0));
	float d = length(q * vec2(1.0, 1.0));
	float t = floor(TIME * 2.5);
	float ragged = 0.78 + 0.22 * hash(cell + vec2(3.0, 5.0));
	if (d > ragged) {
		discard;
	}
	float bubbles = step(0.52, hash(cell + vec2(t, 1.0)));
	float core = 1.0 - smoothstep(0.0, 0.7, d);
	float glint = step(0.9, hash(cell * 1.7 + vec2(floor(TIME * 4.0), 9.0)));
	if (bubbles < 0.5 && core < 0.35) {
		discard;
	}
	vec3 c = mix(tint * 0.78, tint, bubbles * 0.6 + core * 0.4);
	c = mix(c, vec3(1.0), glint * 0.8);
	ALBEDO = c;
}
