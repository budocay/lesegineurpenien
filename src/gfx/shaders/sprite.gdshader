shader_type spatial;
// Sprite pixel art dans un monde 3D (personnages, arbres, accessoires).
// - pixels nets (nearest), découpe franche de la transparence
// - reçoit les lumières et les ombres quelle que soit son orientation
// - projette une ombre à sa silhouette
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform float sway = 0.0;   // balancement au vent (végétation)
uniform float glow = 0.0;   // part d'auto-illumination
instance uniform vec4 frame_rect = vec4(0.0, 0.0, 1.0, 1.0);
instance uniform float sway_phase = 0.0;
instance uniform float flash = 0.0;   // éclair blanc quand un combattant est touché
// Point à ne jamais cacher (le héros) : un sprite placé devant lui s'ajoure autour de lui.
global uniform vec3 focus_world;

varying float in_front;
varying vec4 focus_clip;

void vertex() {
	in_front = step(focus_world.z + 0.35, NODE_POSITION_WORLD.z);
	focus_clip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(focus_world, 1.0));
	if (sway > 0.0) {
		float k = 1.0 - UV.y;
		VERTEX.x += sin(TIME * 1.3 + sway_phase) * sway * k * k;
	}
}

void fragment() {
	vec4 c = texture(sheet, frame_rect.xy + UV * frame_rect.zw);
	if (c.a < 0.5) {
		discard;
	}
	if (in_front > 0.5 && !IN_SHADOW_PASS && focus_clip.w > 0.0) {
		vec2 f = focus_clip.xy / focus_clip.w * 0.5 + 0.5;
		vec2 d = (SCREEN_UV - f) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float r = length(d * vec2(1.0, 0.75));
		if (r < 0.1) {
			// trame : presque tout s'efface au centre, la moitié sur le bord
			vec2 g = floor(FRAGCOORD.xy / 3.0);
			float cell = mod(g.x, 2.0) + mod(g.y, 2.0) * 2.0;
			if (cell < (r < 0.07 ? 3.0 : 2.0)) {
				discard;
			}
		}
	}
	// léger dégradé vers le sol : le pied du sprite s'ancre dans le décor
	vec3 grounded = c.rgb * mix(1.04, 0.9, UV.y * UV.y);
	ALBEDO = mix(grounded, vec3(1.0), flash * 0.5);
	EMISSION = c.rgb * glow * (1.0 - flash) + vec3(flash * 0.25);
	ROUGHNESS = 1.0;
}

void light() {
	// Pas de terme N.L : un sprite plat doit être éclairé comme un volume.
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (0.85 / PI);
}
