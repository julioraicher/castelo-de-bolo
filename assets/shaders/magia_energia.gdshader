shader_type spatial;
// Energia viva (Ciclo 2.20): fogo, vento, luz e sombra dos poderes. A malha
// continua simples (tubo, disco, fita); quem dá vida é o ruído rolando por
// dentro. Duas contas com a mesma máscara m (forma, pelo UV):
//   a = m + ruído·força − corrosão   -> onde existe (a < 0 some; a pequeno = filete de tinta)
//   c = min(m + ruído leve, borda+a) -> a cor em degraus: núcleo claro no fundo
//       da forma, cor no meio, borda perto de onde ela se rasga.
// Subir `corroi` faz a forma se desfazer em línguas em vez de só ficar
// transparente. Máscara: > 0,62 núcleo, > 0,42 cor, > 0,27 borda.
// Custo: 2 leituras de uma textura 128², sem luz, sem ler a tela.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D ruido : repeat_enable, filter_linear_mipmap;
uniform vec4 cor_nucleo : source_color = vec4(1.0);
uniform vec4 cor_meio : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform vec4 cor_borda : source_color = vec4(0.1, 0.4, 0.9, 1.0);
uniform vec4 cor_tinta : source_color = vec4(0.09, 0.03, 0.14, 1.0);
uniform vec2 escala = vec2(2.0, 1.0);   // x inteiro em tubo/disco (emenda)
uniform vec2 rola = vec2(0.15, -1.2);   // voltas de ruído por segundo
uniform float semente = 0.0;
uniform float corroi = 0.0;             // 0 inteira .. 1 sumiu
uniform float forca = 0.9;              // quanto o ruído come a forma
uniform float tinta = 0.07;             // largura do filete escuro
uniform float base = 1.0;               // máscara em v = 0
uniform float topo = 0.0;               // máscara em v = 1
uniform float banda = 0.0;              // > 0: faixa de meia-largura `banda` em volta de `centro`
uniform float centro = 0.8;
uniform float lados = 0.0;              // 1: some nas bordas de u (fita, arco)
uniform float alfa = 1.0;
uniform float teto = 1.0;               // > 1: a cor segue a espessura do traço, não a altura (vento, faixas)
uniform float fresnel = 0.0;            // > 0: a forma some na silhueta (quem olha de lado vê a borda se rasgar)
uniform float ondula = 0.0;             // a malha respira para os lados (língua de fogo)

void vertex() {
	VERTEX.xz *= 1.0 + ondula * sin(UV.y * 9.0 - TIME * 9.0 + UV.x * TAU * 2.0 + semente);
}

void fragment() {
	vec2 desl = rola * TIME + vec2(semente, semente * 1.7);
	float n = texture(ruido, UV * escala + desl).r * 0.62
			+ texture(ruido, UV * escala * 2.17 + desl * 1.6 + 0.37).r * 0.38;
	float m = mix(base, topo, UV.y);
	if (banda > 0.0) {
		m *= clamp(1.0 - abs(UV.y - centro) / banda, 0.0, 1.0);
	}
	float lx = UV.x * 2.0 - 1.0;
	m *= 1.0 - lados * lx * lx;
	if (fresnel > 0.0) {
		float nv = abs(dot(normalize(NORMAL), normalize(VIEW)));
		m *= mix(1.0, smoothstep(0.0, 0.75, nv) * 1.15, fresnel);
	}
	m *= COLOR.a;  // malhas com cor por vértice modelam a forma (arco do golpe)
	float a = m + (n - 0.5) * forca - corroi * (1.0 + forca * 0.5);
	float w = fwidth(a) + 0.002;
	if (a < -w) {
		discard;
	}
	float f = min(m * teto + (n - 0.5) * 0.45, 0.27 + (a - tinta) * 1.3);
	float wf = fwidth(f) + 0.002;
	vec3 c = mix(cor_borda.rgb, cor_meio.rgb, smoothstep(0.42 - wf, 0.42 + wf, f));
	c = mix(c, cor_nucleo.rgb, smoothstep(0.62 - wf, 0.62 + wf, f));
	c = mix(cor_tinta.rgb, c, smoothstep(tinta - w, tinta + w, a));
	ALBEDO = c;
	ALPHA = alfa * smoothstep(-w, w, a);
}
