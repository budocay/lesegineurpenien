shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, fog_disabled;
// Bouffée de fumée : un disque doux qui fait face à la caméra, monte, grossit, dérive avec le vent et
// s'efface ; `phase` (par bouffée) étale les bouffées d'une colonne le long de sa montée.

uniform vec4 col : source_color = vec4(0.3, 0.28, 0.3, 0.5);
uniform float speed = 0.12;
uniform float rise = 8.0;
uniform float drift = 3.0;
uniform float grow = 2.2;
instance uniform float phase = 0.0;
varying float life;

void vertex() {
	life = fract(TIME * speed + phase);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	vec3 v = VERTEX * (0.5 + life * grow);
	v.y += life * rise;
	v.x += life * life * drift;
	VERTEX = v;
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = smoothstep(1.0, 0.25, d) * (1.0 - life) * smoothstep(0.0, 0.1, life) * col.a;
	ALBEDO = col.rgb;
	ALPHA = a;
}
