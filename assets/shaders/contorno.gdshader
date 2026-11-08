shader_type spatial;
// Contorno por casca invertida: a malha cresce na normal e só as costas aparecem.
render_mode unshaded, cull_front;

uniform float espessura = 0.025;
uniform vec4 cor : source_color = vec4(0.02, 0.02, 0.06, 1.0);
uniform float relogio = -1.0;
uniform bool girar = false;   // só o cenário (os bonecos podem ter UV2 próprio); também liga o recorte dos telhados

#include "res://assets/shaders/recorte.gdshaderinc"
// Sem balanco.gdshaderinc aqui: o instance uniform dele estourava o buffer
// global com as peças do cenário. Bonecos usam contorno_boneco.gdshader.

varying vec3 v_mundo;

void vertex() {
	// Peça que gira: mesma conta do pintura.gdshader (UV2 = velocidade, amplitude).
	if (girar && UV2.x != 0.0) {
		float t = relogio >= 0.0 ? relogio : TIME;
		float ang = UV2.y > 0.0 ? UV2.y * sin(t * UV2.x) : t * UV2.x;
		mat2 r = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang)));
		VERTEX.xy = r * VERTEX.xy;
		NORMAL.xy = r * NORMAL.xy;
	}
	VERTEX += NORMAL * espessura;
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (girar) {
		recorte(v_mundo, CAMERA_POSITION_WORLD, FRAGCOORD.xy);
	}
	ALBEDO = cor.rgb;
}
