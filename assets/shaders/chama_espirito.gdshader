shader_type spatial;
// Chama de espírito do aliado caído (Ciclo 2.18): fogo-raposa na cor do time
// pairando sobre o peito. Um quad billboard; a forma (gota com ponta que
// tremula) sai do campo de distância, sem textura. Fica por cima de tudo para
// o time achar quem pode reanimar (o marcador do Battlefield).
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

instance uniform vec4 cor : source_color = vec4(0.4, 0.7, 1.0, 1.0);
// 1 = acabou de cair, 0 = a espera acabou (a chama encolhe e apaga).
instance uniform float vida = 1.0;
// 0..1 progresso da reanimação: a chama esbranquiça e tremula mais rápido.
instance uniform float brilho = 0.0;

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = mv * mat4(vec4(s, 0, 0, 0), vec4(0, s, 0, 0), vec4(0, 0, s, 0), vec4(0, 0, 0, 1));
}

// Meia-largura da gota na altura y (y de -1 embaixo a 1 em cima).
float largura(float y, float topo) {
	float y0 = -0.38;
	float r = 0.46;
	if (y < y0) {
		float d = y - y0;
		return sqrt(max(r * r - d * d, 0.0));
	}
	return r * pow(max(1.0 - (y - y0) / (topo - y0), 0.0), 1.25);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float v = clamp(vida, 0.0, 1.0);
	float t = TIME * (2.2 + brilho * 4.0);
	// Encolhe com a espera: ao fim da janela vira uma brasa.
	float esc = mix(0.45, 1.0, sqrt(v));
	p /= esc;
	p.y += 0.12 * (1.0 - esc);
	// Ponta que dança (mais no alto) e uma segunda língua menor ao lado.
	float altura = clamp((p.y + 1.0) * 0.5, 0.0, 1.0);
	p.x += sin(p.y * 3.4 - t * 2.6) * 0.11 * altura * altura;
	float topo = 0.92 + sin(t * 1.7) * 0.06;
	float d = abs(p.x) / max(largura(p.y, topo), 0.001);
	vec2 q = p - vec2(0.24, 0.05);
	q.x += sin(q.y * 4.0 - t * 3.1 + 1.3) * 0.06;
	float d2 = abs(q.x) / max(largura(q.y * 1.5 + 0.2, 0.7) * 0.55, 0.001);
	float fora = smoothstep(1.0, 0.72, d);
	float lingua = smoothstep(1.0, 0.7, d2) * 0.7;
	float corpo = max(fora, lingua);
	// Miolo branco: cresce enquanto reanimam.
	float miolo = smoothstep(0.42 + brilho * 0.3, 0.0, d) * smoothstep(0.55, -0.4, p.y);
	// Borda escura da própria cor: lê em chão claro (pedra, areia) e escuro.
	float borda = smoothstep(0.55, 0.95, d);
	vec3 c = mix(cor.rgb * 1.15, cor.rgb * 0.45, borda);
	c = mix(c, vec3(1.0, 0.97, 0.9), clamp(miolo + brilho * 0.3, 0.0, 1.0));
	// Brilho dourado do resgate por cima da cor do time.
	c = mix(c, vec3(1.0, 0.82, 0.38), brilho * 0.45 * (1.0 - miolo));
	float pisca = 0.85 + 0.15 * sin(t * 5.3) * sin(t * 2.1);
	ALBEDO = c * pisca * (1.0 + brilho * 0.6);
	ALPHA = corpo * mix(0.6, 0.95, v) * step(-1.0, p.y);
}
