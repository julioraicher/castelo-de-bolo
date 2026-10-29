shader_type spatial;
// Contorno por casca invertida: a malha cresce na normal e só as costas aparecem.
render_mode unshaded, cull_front;

uniform float espessura = 0.025;
uniform vec4 cor : source_color = vec4(0.02, 0.02, 0.06, 1.0);

void vertex() {
	VERTEX += NORMAL * espessura;
}

void fragment() {
	ALBEDO = cor.rgb;
}
