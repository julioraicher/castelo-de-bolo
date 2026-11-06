shader_type spatial;
// Toon do personagem no Passo da Sombra (super do Samurai), visto pelo próprio
// time: o mesmo corpo de toon_time.gdshader, mas translúcido. depth_prepass_alpha
// grava a profundidade antes da cor, então só a camada da frente aparece (um braço
// atrás do tronco não soma transparência por cima). Trocado só enquanto dura
// (Unit._aplicar_sombra): no resto do tempo nenhum boneco paga o passe de alfa.
render_mode depth_prepass_alpha;
stencil_mode write, compare_always, 1;
#define FANTASMA
#include "res://assets/shaders/toon_time.gdshaderinc"
