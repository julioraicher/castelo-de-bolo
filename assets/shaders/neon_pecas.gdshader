shader_type spatial;
// Peças que brilham dos bonecos (fogo de raposa, halo, marcas): cor do vértice
// sem luz, ×2 para estourar no bloom. Grava 1 no stencil como o toon (o raio X
// não acende por cima do próprio boneco). O fogo boia/treme com balanco() e
// apaga quando o boneco morre (agito -1).
render_mode unshaded;
stencil_mode write, compare_always, 1;

#include "res://assets/shaders/balanco.gdshaderinc"

instance uniform float poder_carga = 0.0;  // mesma ordem do toon (agito, poder_carga, cor_poder)
instance uniform vec4 cor_poder : source_color = vec4(1.0, 0.75, 0.3, 1.0);

varying float v_fogo;

void vertex() {
	VERTEX += balanco(CUSTOM1, TIME);
	v_fogo = CUSTOM1.z > 0.5 && CUSTOM1.x != 0.0 ? 1.0 : 0.0;
}

void fragment() {
	if (v_fogo > 0.5 && agito < -0.5) {
		discard;
	}
	// O fogo acende mais com o poder [Q] carregando (poder no corpo, Ciclo 2.2).
	float forca = 2.0 + v_fogo * (0.8 * poder_carga + 0.6 * clamp(agito, 0.0, 1.0));
	ALBEDO = pow(COLOR.rgb, vec3(2.2)) * forca;
}
