shader_type canvas_item;
// Vignette : assombrit doucement les coins de l'image, sous l'interface.

uniform float strength = 0.28;

void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 0.86);
	float v = smoothstep(0.42, 0.86, length(d));
	COLOR = vec4(0.03, 0.02, 0.06, v * strength);
}
