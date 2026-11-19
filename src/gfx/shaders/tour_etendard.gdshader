shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_opaque;
// Grand étendard de la Tour Blanche : une toile attachée au mât (côté x = 0) qui ondule de plus en
// plus vers sa pointe, avec des plis clairs et sombres qui courent. Découpe franche (pas de flou de profondeur).

uniform sampler2D tex : source_color, filter_nearest, repeat_disable;
uniform float amp = 0.45;
uniform float speed = 2.4;
varying float fold;

void vertex() {
	float k = clamp(UV.x, 0.0, 1.0);
	float t = TIME * speed;
	float ph = UV.x * 7.0 - t;
	VERTEX.z += sin(ph) * amp * k;
	VERTEX.y += sin(ph * 0.7 + 1.3) * amp * 0.22 * k;
	fold = cos(ph) * k;
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	vec3 col = c.rgb * (1.0 + fold * 0.14);
	ALBEDO = col;
}
