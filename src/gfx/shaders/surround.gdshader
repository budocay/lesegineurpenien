shader_type spatial;
// Hors-carte d'un intérieur : roche (ou gouffre) qui se prolonge au-delà de la pièce et se fond
// peu à peu dans l'ombre. Jamais noir franc : à la limite de la carte elle est sombre mais
// texturée, puis l'ombre gagne avec la distance. Purement décoratif.

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform vec4 box = vec4(0.0, 0.0, 10.0, 10.0);   // x0, z0, x1, z1 de la carte
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float fade = 9.0;
uniform float near_level = 0.62;
uniform float far_level = 0.1;
uniform float glow = 0.45;   // part de la teinte rendue même sans lumière : jamais noir franc

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
	vec4 c = texture(tex, wpos.xz / 2.0);
	float dx = max(max(box.x - wpos.x, wpos.x - box.z), 0.0);
	float dz = max(max(box.y - wpos.z, wpos.z - box.w), 0.0);
	float d = length(vec2(dx, dz));
	float k = 1.0 - smoothstep(0.0, fade, d);
	float n = vnoise(wpos.xz * 0.45) * 0.6 + vnoise(wpos.xz * 1.3 + 9.0) * 0.4;
	vec3 col = c.rgb * tint * mix(far_level, near_level, k) * (0.6 + 0.8 * n);
	ALBEDO = col;
	EMISSION = col * glow;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
