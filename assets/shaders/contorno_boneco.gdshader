shader_type spatial;
// Contorno de tinta dos BONECOS (casca invertida, como o contorno.gdshader),
// com o balanço das peças (caudas, fogo). Separado do contorno do cenário
// porque `agito` é instance uniform: cada instância que usa o shader ocupa um
// lugar no buffer global (4096). Com o balanço no contorno do cenário, as
// milhares de peças do mapa estouravam o buffer (erro "Too many instances
// using shader instance variables", Ciclo 2.14 a 2.15).
render_mode unshaded, cull_front;

uniform float espessura = 0.025;
uniform vec4 cor : source_color = vec4(0.02, 0.02, 0.06, 1.0);

#include "res://assets/shaders/balanco.gdshaderinc"

void vertex() {
	VERTEX += balanco(CUSTOM1, TIME);
	VERTEX += NORMAL * espessura;
}

void fragment() {
	ALBEDO = cor.rgb;
}
