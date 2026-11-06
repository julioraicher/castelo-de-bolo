shader_type spatial;
// Toon dos personagens: 2 faixas de luz + contraluz na cor do time.
// A textura KayKit é uma paleta; cada cor vira um papel:
// pele fica, cinza vira aço azul-noite, o resto (pano, couro) vira cor do time.
// Grava 1 no stencil onde o boneco aparece: o passe raio_x.gdshader desenha a
// silhueta só onde ficou 0 (atrás de parede).
stencil_mode write, compare_always, 1;

#include "res://assets/shaders/toon_time.gdshaderinc"
