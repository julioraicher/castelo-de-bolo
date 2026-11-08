shader_type spatial;
// Raio X (Ciclo 2.10b): o pedaço do boneco escondido atrás de parede, telhado
// ou árvore aparece como silhueta na cor do time, por cima de tudo.
//
// Como sabe o que está escondido (stencil, 1 byte por pixel):
//   - o cenário (pintura.gdshader) grava 2 onde aparece;
//   - o boneco (toon_time.gdshader e o neon) grava 1 onde aparece.
// Este passe desenha SEM teste de profundidade, mas só onde o stencil == 2, isto
// é, onde quem ganhou o pixel foi o cenário e não o boneco. Um braço na frente
// do próprio tronco não acende (ali vale 1), os pés enterrados no chão também
// não (o chão não grava nada), nem um boneco atrás de outro boneco. Custo: os
// pixels escondidos de cada boneco; não há leitura da textura de profundidade.
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, blend_mix, shadows_disabled;
stencil_mode read, compare_equal, 2;

uniform vec4 cor_time : source_color = vec4(0.16, 0.45, 1.0, 1.0);
uniform float preenche = 0.28;   // miolo apagado: dá para ver a parede atrás
uniform float borda = 0.95;      // aro forte: a silhueta se lê a qualquer distância
// O Samurai invisível não acende: Unit._aplicar_sombra esconde o _visual inteiro.
global uniform float raio_x_forca;  // 0 desliga tudo (--sem-recorte, prancha de antes)

#include "res://assets/shaders/balanco.gdshaderinc"

void vertex() {
	VERTEX += balanco(CUSTOM1, TIME);
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(cor_time.rgb, vec3(1.0), 0.25 * fres);
	ALPHA = mix(preenche, borda, fres) * raio_x_forca;
}
