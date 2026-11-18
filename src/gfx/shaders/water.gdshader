shader_type spatial;
// Eau en pixels : bandes de couleur animées et reflets, calculés sur une grille de texels monde.

uniform vec3 deep : source_color = vec3(0.07, 0.13, 0.27);
uniform vec3 shallow : source_color = vec3(0.16, 0.30, 0.46);
uniform vec3 glint : source_color = vec3(1.0, 0.78, 0.55);
uniform float texels_per_unit = 24.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = floor(wpos.xz * texels_per_unit) / texels_per_unit;
	float t = TIME;
	float w = sin(p.x * 1.9 + t * 0.8 + sin(p.y * 1.3 + t * 0.45) * 1.4) * 0.5
			+ sin(p.y * 4.3 - t * 1.1 + p.x * 0.7) * 0.5;
	float band = floor((w * 0.5 + 0.5) * 4.0) / 4.0;
	float g = sin(p.x * 5.0 + t * 0.9 + sin(p.y * 8.0 + t * 0.3) * 2.0) * sin(p.y * 13.0 - t * 1.5);
	ALBEDO = mix(deep, shallow, band);
	EMISSION = glint * step(0.9, g) * 0.35;
	ROUGHNESS = 0.3;
	SPECULAR = 0.5;
}
