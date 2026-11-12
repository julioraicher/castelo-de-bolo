shader_type spatial;
// Assinatura de cada personagem (Ciclo 2.24). O desenho vem de um atlas de
// campo de distância (tools/assinaturas/): 0,5 = borda do traço, claro = dentro.
// Daí saem o traço (com a borda tremida de pincel), o filete de tinta por fora
// e um brilho no chão em volta, nítidos em qualquer tamanho.
// `revela` escolhe o VERBO com que o desenho aparece conforme `escreve` 0..1:
// x = dá a volta (pincel), y = raio (ondas; `inverte` = de fora para dentro,
// mordida), z = ruído (névoa, carimbo), w = da esquerda para a direita (risco).
// A frente da escrita acende (a ponta do pincel, a faísca do pavio).
// `em_pe` = figura de frente para a câmera; `hanko` = carimbo quadrado vermelho.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform sampler2D ruido : repeat_enable, filter_linear_mipmap;
uniform vec4 celula = vec4(0.0, 0.0, 0.16667, 0.16667);
uniform vec4 cor : source_color = vec4(0.7, 0.4, 1.0, 1.0);
uniform vec4 cor_nucleo : source_color = vec4(1.0);
uniform vec4 cor_tinta : source_color = vec4(0.09, 0.03, 0.14, 1.0);
uniform vec4 cor_halo : source_color = vec4(0.7, 0.4, 1.0, 1.0);
uniform float escreve = 1.0;
uniform float corroi = 0.0;
uniform float aceso = 0.0;
uniform float giro = 0.0;       // voltas por segundo
uniform float rot = 0.0;        // ângulo fixo (rad), animável
uniform float semente = 0.0;
uniform vec4 revela = vec4(1.0, 0.0, 0.0, 0.0);
uniform float inverte = 0.0;
uniform float pulso = 0.0;      // ondas correndo pelo traço (água, som)
uniform float em_pe = 0.0;
uniform float hanko = 0.0;
uniform float alfa = 1.0;
uniform float fino = 1.0;       // < 1 afina o filete em desenhos grandes (espessura quase fixa em metros)

void vertex() {
	if (em_pe > 0.5) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float g = TIME * giro * TAU + rot;
	p = mat2(vec2(cos(g), -sin(g)), vec2(sin(g), cos(g))) * p;
	vec2 uv = p * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		discard;
	}
	float r = clamp(length(p), 0.0, 1.0);
	float n = texture(ruido, UV * 1.5 + semente).r;
	float sd = (texture(atlas, celula.xy + uv * celula.zw).r - 0.5) * 2.0;
	float w = fwidth(sd) * 0.75 + 0.02;
	if (hanko > 0.5) {
		float q = max(abs(p.x), abs(p.y)) + (n - 0.5) * 0.1;
		float fundo = 1.0 - smoothstep(0.86, 0.92, q);
		float gasto = step(corroi * 1.3 - n, 0.0) * smoothstep(0.0, 0.25, escreve + n * 0.25);
		float t = smoothstep(-w, w, sd - 0.12);
		ALBEDO = mix(cor.rgb * (0.82 + 0.3 * n), cor_nucleo.rgb, t);
		ALPHA = fundo * gasto * alfa;
	} else {
		float volta = fract(atan(p.y, p.x) / TAU + 0.25);
		float rr = mix(r, 1.0 - r, inverte);
		float soma = revela.x + revela.y + revela.z + revela.w;
		float q = (revela.x * volta + revela.y * rr + revela.z * n + revela.w * uv.x) / max(soma, 0.001);
		float cabeca = escreve * 1.1 - q;
		float vis = smoothstep(0.0, 0.07, cabeca);
		float frente = (1.0 - smoothstep(0.0, 0.1, abs(cabeca - 0.04))) * step(escreve, 0.995);
		float d = sd + (n - 0.5) * 0.24 + pulso * 0.2 * sin(r * 20.0 - TIME * 7.0);
		float some = corroi * 1.3 - n;
		float traco = smoothstep(-w, w, d) * vis * step(some, 0.0);
		float filete = smoothstep(-0.42 * fino - w, -0.42 * fino + w, d) * vis * step(some, 0.08);
		float halo = smoothstep(-1.0, 0.15, sd);
		float brilho = halo * sqrt(halo) * (0.3 + 0.35 * aceso + 0.5 * frente) * vis * (1.0 - corroi);
		vec3 miolo = mix(cor.rgb, cor_nucleo.rgb, max(aceso * 0.75 * smoothstep(0.3, 0.85, d), frente));
		vec3 c = mix(mix(cor_halo.rgb, cor_nucleo.rgb, frente), cor_tinta.rgb, filete);
		ALBEDO = mix(c, miolo, traco);
		ALPHA = max(max(filete * 0.92, traco), brilho) * alfa;
	}
	if (ALPHA < 0.01) {
		discard;
	}
}
