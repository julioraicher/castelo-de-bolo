shader_type spatial;
// Selo que se escreve no chão (Ciclo 2.20). Um quad deitado; o desenho sai de
// campos de distância em coordenadas polares: dois anéis, marcas de runa entre
// eles e uma estrela de `pontas` (0 = sem estrela; `petalas` > 0 troca a
// estrela por uma flor). `escreve` 0..1 puxa o traço como um pincel dando a
// volta; `corroi` desfaz o selo no fim. Traço com filete de tinta por fora.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D ruido : repeat_enable, filter_linear_mipmap;
uniform vec4 cor : source_color = vec4(0.7, 0.4, 1.0, 1.0);
uniform vec4 cor_nucleo : source_color = vec4(1.0);
uniform vec4 cor_tinta : source_color = vec4(0.09, 0.03, 0.14, 1.0);
uniform float escreve = 1.0;
uniform float corroi = 0.0;
uniform float aceso = 0.0;      // 0 traço na cor, 1 miolo branco e chão tingido
uniform int pontas = 5;
uniform int petalas = 0;
uniform float giro = 0.15;      // voltas por segundo
uniform float semente = 0.0;
uniform float fino = 1.0;       // < 1 afina o traço em selos grandes (espessura quase fixa em metros)

float seg(vec2 p, vec2 a, vec2 b, float ate) {
	vec2 ba = (b - a) * ate;
	vec2 pa = p - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-5), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float g = TIME * giro * TAU;
	p = mat2(vec2(cos(g), -sin(g)), vec2(sin(g), cos(g))) * p;
	float a = atan(p.y, p.x);
	float volta = fract(a / TAU + 0.25);          // 0..1 a partir do topo
	float n = texture(ruido, UV * 1.5 + semente).r;
	float pena = (0.75 + n * 0.6) * fino;                // pincel: traço engrossa e afina
	// Anéis: o de fora escreve num sentido, o de dentro no outro.
	float e1 = clamp(escreve * 1.6, 0.0, 1.0);
	float e2 = clamp(escreve * 1.6 - 0.2, 0.0, 1.0);
	float d = 9.0;
	if (volta <= e1) {
		d = min(d, abs(r - 0.92) - 0.034 * pena);
	}
	if (1.0 - volta <= e2) {
		d = min(d, abs(r - 0.72) - 0.016 * pena);
		// Runas: tracinhos entre os anéis.
		float k = abs(fract(volta * 24.0 + 0.5) - 0.5) * TAU * r / 24.0;
		float alterna = step(0.5, fract(floor(volta * 24.0) * 0.37 + semente));
		d = min(d, max(k - 0.012 * pena, abs(r - mix(0.80, 0.84, alterna)) - mix(0.035, 0.06, alterna) * mix(1.0, fino, 0.5)));
	}
	// Estrela {n/2}: cada traço nasce depois do anterior.
	float e3 = clamp(escreve * 1.7 - 0.55, 0.0, 1.0);
	if (petalas > 0) {
		float pr = 0.66 * (0.25 + 0.75 * abs(cos(a * float(petalas) * 0.5)));
		d = min(d, max(abs(r - pr) - 0.02 * pena, r - 0.70 * e3 * 1.4));
	} else if (pontas > 1) {
		float nf = float(pontas);
		for (int i = 0; i < pontas; i++) {
			float ate = clamp(e3 * nf - float(i), 0.0, 1.0);
			if (ate <= 0.0) {
				break;
			}
			float a0 = TAU * float(i * 2) / nf - PI * 0.5;
			float a1 = TAU * float(i * 2 + 2) / nf - PI * 0.5;
			d = min(d, seg(p, vec2(cos(a0), sin(a0)) * 0.70, vec2(cos(a1), sin(a1)) * 0.70, ate) - 0.02 * pena);
		}
	}
	float some = corroi * 1.3 - n;                // corrói por ruído, de dentro do traço
	float w = fwidth(d) + 0.002;
	float traco = (1.0 - smoothstep(-w, w, d)) * step(some, 0.0);
	float filete = (1.0 - smoothstep(0.03 * fino - w, 0.03 * fino + w, d)) * step(some, 0.08);
	float chao = aceso * 0.22 * step(r, 0.92) * (1.0 - corroi) * (0.6 + 0.4 * n);
	vec3 c = mix(cor_tinta.rgb, mix(cor.rgb, cor_nucleo.rgb, aceso * smoothstep(0.0, -0.02, d)), traco);
	ALBEDO = mix(cor.rgb, c, max(filete, traco));
	ALPHA = max(max(filete * 0.9, traco), chao);
	if (ALPHA < 0.01) {
		discard;
	}
}
