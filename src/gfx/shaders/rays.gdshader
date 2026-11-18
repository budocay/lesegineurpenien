shader_type spatial;
// Rayon de lumière oblique : un voile additif, doux sur les bords, qui s'éteint vers le sol
// et respire lentement.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(1.0, 0.85, 0.6);
uniform float strength = 0.1;
instance uniform float phase = 0.0;

void fragment() {
	float across = sin(UV.x * PI);
	across *= across;
	// deux ou trois filets plus clairs dans le faisceau
	float streaks = 0.75 + 0.25 * sin(UV.x * 19.0 + phase * 3.0);
	float along = smoothstep(1.0, 0.25, UV.y) * smoothstep(0.0, 0.12, UV.y);
	float breathe = 0.75 + 0.25 * sin(TIME * 0.45 + phase);
	ALBEDO = tint;
	ALPHA = across * streaks * along * breathe * strength;
}
