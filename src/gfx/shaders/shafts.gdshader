shader_type canvas_item;
render_mode blend_add;
// Rayons de lumière obliques sur l'image entière (combat) : quelques larges bandes douces qui
// descendent du haut, s'éteignent avant le sol et respirent à peine. Sous l'interface, ajoutés
// à l'image : ils éclairent, ils ne cachent rien. strength = 0 : aucun effet.

uniform vec3 tint : source_color = vec3(1.0, 0.9, 0.7);
uniform float strength = 0.1;
uniform float slant = 0.55;      // inclinaison des bandes (0 : verticales)
uniform float scale = 5.5;       // nombre de bandes sur la largeur

void fragment() {
	vec2 uv = UV;
	float x = uv.x + uv.y * slant;
	float band = 0.5 + 0.5 * sin(x * scale * 3.14159 + 0.6 + 0.12 * sin(TIME * 0.2));
	band = smoothstep(0.55, 1.0, band);
	float wide = 0.5 + 0.5 * sin(x * scale * 0.37 * 3.14159 + 2.0);
	float fade = smoothstep(0.85, 0.05, uv.y) * smoothstep(0.0, 0.1, uv.y + 0.1);
	float k = band * (0.35 + 0.65 * wide) * fade;
	COLOR = vec4(tint, k * strength);
}
