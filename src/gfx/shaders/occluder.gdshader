shader_type spatial;
// Mur, tour ou pilier qui peut cacher le héros : au lieu de devenir translucide (ce qui laissait un voile
// aux bords nets, avec les faces arrière et les boîtes voisines empilées en transparence), il reste
// opaque et s'ouvre en trame autour du héros, comme les sprites (voir sprite.gdshader).
render_mode specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float use_tex = 1.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform sampler2D emission_tex : source_color, filter_nearest, repeat_enable;
uniform float use_emission_tex = 0.0;
instance uniform float cut = 0.0;   // 0 : plein ; 1 : trou complet autour du héros
global uniform vec3 focus_world;

varying vec3 wpos;
varying vec4 focus_clip;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	focus_clip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(focus_world, 1.0));
}

float bayer4(vec2 p) {
	ivec2 q = ivec2(mod(p, 4.0));
	int i = q.x + q.y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[i] + 0.5) / 16.0;
}

void fragment() {
	if (cut > 0.001 && !IN_SHADOW_PASS && wpos.z > focus_world.z + 0.2 && focus_clip.w > 0.0) {
		vec2 f = focus_clip.xy / focus_clip.w * 0.5 + 0.5;
		vec2 d = (SCREEN_UV - f) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float r = length(d * vec2(1.0, 0.8));
		float big = 0.24 * cut;
		float open = 1.0 - smoothstep(big * 0.45, big, r);
		if (open > bayer4(floor(FRAGCOORD.xy / 2.0))) {
			discard;
		}
	}
	vec4 c = albedo_color;
	if (use_tex > 0.5) {
		c *= texture(albedo_tex, UV);
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	vec3 e = emission_color.rgb;
	if (use_emission_tex > 0.5) {
		e *= texture(emission_tex, UV).rgb;
	}
	EMISSION = e * emission_energy;
}
