shader_type spatial;
render_mode unshaded, cull_disabled;
// Lave et braises : coulées sombres sur fond incandescent, qui dérivent lentement.
// Tout est calculé sur la grille des pixels du monde.

uniform vec3 hot : source_color = vec3(1.0, 0.78, 0.25);
uniform vec3 warm : source_color = vec3(0.95, 0.36, 0.08);
uniform vec3 crust : source_color = vec3(0.22, 0.06, 0.04);
uniform float texels_per_unit = 16.0;
uniform float energy = 1.4;

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
	float t = TIME * 0.12;
	float n = vnoise(p * 0.9 + vec2(t, -t * 0.6)) * 0.55 + vnoise(p * 2.3 - vec2(t * 1.5, t)) * 0.45;
	float veins = abs(n - 0.5);
	vec3 col = mix(hot, warm, smoothstep(0.0, 0.14, veins));
	col = mix(col, crust, smoothstep(0.1, 0.26, veins));
	ALBEDO = col * energy;
	ALPHA = COLOR.a;
}
