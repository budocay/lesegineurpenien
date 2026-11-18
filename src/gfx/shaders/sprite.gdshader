shader_type spatial;
// Sprite pixel art dans un monde 3D (personnages, arbres, accessoires).
// - pixels nets (nearest), découpe franche de la transparence
// - reçoit les lumières et les ombres quelle que soit son orientation
// - projette une ombre à sa silhouette
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform float sway = 0.0;   // balancement au vent (végétation)
uniform float glow = 0.0;   // part d'auto-illumination
uniform float see_through = 1.0;   // 1 : décor qui s'ajoure devant le héros ; 0 : personnage, jamais tramé
instance uniform vec4 frame_rect = vec4(0.0, 0.0, 1.0, 1.0);
instance uniform float sway_phase = 0.0;
instance uniform float flash = 0.0;   // éclair blanc quand un combattant est touché
instance uniform float rim = 0.0;     // liseré clair de contre-jour (combat seulement ; 0 = aucun effet)
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
	if (see_through > 0.5 && in_front > 0.5 && !IN_SHADOW_PASS && focus_clip.w > 0.0) {
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
	vec3 rim_light = vec3(0.0);
	if (rim > 0.0) {
		// pixel du bord haut (et, plus faiblement, des côtés) de la silhouette : il prend la lumière du fond
		vec2 ts = 1.0 / vec2(textureSize(sheet, 0));
		vec2 at = frame_rect.xy + UV * frame_rect.zw;
		float gap_up = 1.0 - step(0.5, texture(sheet, at + vec2(0.0, -ts.y)).a);
		float gap_l = 1.0 - step(0.5, texture(sheet, at + vec2(-ts.x, 0.0)).a);
		float gap_r = 1.0 - step(0.5, texture(sheet, at + vec2(ts.x, 0.0)).a);
		rim_light = vec3(1.0, 0.93, 0.78) * max(gap_up, 0.45 * max(gap_l, gap_r)) * rim;
	}
	ALBEDO = mix(grounded, vec3(1.0), flash * 0.5);
	EMISSION = c.rgb * glow * (1.0 - flash) + vec3(flash * 0.25) + rim_light * 0.5;
	ROUGHNESS = 1.0;
}

void light() {
	// Pas de terme N.L : un sprite plat doit être éclairé comme un volume.
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (0.85 / PI);
}
