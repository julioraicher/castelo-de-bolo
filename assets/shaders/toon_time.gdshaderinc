// Corpo do toon dos personagens, dividido por toon_time.gdshader (opaco) e
// toon_fantasma.gdshader (Passo da Sombra, translúcido). Ver toon_time.gdshader.
#ifdef FANTASMA
uniform float fantasma = 0.6;  // 0 opaco, 1 invisível
uniform vec3 cor_fantasma : source_color = vec3(0.62, 0.38, 1.0);
#endif
uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec4 cor_time : source_color = vec4(0.16, 0.45, 1.0, 1.0);
uniform bool usar_cor_fixa = false;
uniform bool usar_cor_vertice = false;  // peças montadas por código (cor no vértice, sRGB)
uniform vec4 cor_fixa : source_color = vec4(1.0);
// Piloto "cor da classe" (revisão 2026-11-06, item 7; só a prancha liga):
// roupa na cor da classe e o time numa faixa (cinto, punhos, gola).
uniform bool usar_cor_classe = false;
uniform vec4 cor_classe : source_color = vec4(0.3, 0.3, 0.32, 1.0);
uniform float aro = 0.7;
// Medidor do poder [Q] deste boneco (Unit._tick_aura), 0..1. Por instância:
// o material é dividido por todos do time. O contraluz acende com a carga,
// puxa para a cor do poder e pulsa quando está pronto.
instance uniform float poder_carga = 0.0;
instance uniform vec4 cor_poder : source_color = vec4(1.0, 0.75, 0.3, 1.0);
// Marcas de poder (Ciclo 2.2): selos desenhados na pose de repouso (CUSTOM0,
// gravada por NinjaVisual), então ficam grudados no corpo durante a animação.
// Apagados = traço de tinta fraco; acendem com a carga e pulsam quando pronto.
// Anéis a cada ~15 cm em braços e pernas e faixas no tronco: maiores que ~2 px na
// tela a 60-100 px de boneco (Nyquist), e quebrados em "letras" pelo ângulo.
uniform bool usar_marcas = false;
uniform float tinta_marcas = 0.25;

varying vec3 v_repouso;
varying float v_tem_repouso;

void vertex() {
	v_repouso = CUSTOM0.xyz;
	v_tem_repouso = CUSTOM0.w;
}

float marcas(vec3 p) {
	// Braço em T na pose de repouso: anéis ao longo de x; resto: ao longo de y.
	bool braco = abs(p.x) > 0.3 && p.y > 0.85;
	float eixo = braco ? abs(p.x) : p.y;
	vec2 volta = braco ? p.yz : p.xz;
	float ang = atan(volta.y, volta.x) / 6.2832 + 0.5;
	float anel = abs(fract(eixo / 0.15 + 0.2 * sin(ang * 12.566)) - 0.5);
	float traco = 1.0 - smoothstep(0.06, 0.12, anel);
	float letra = step(0.5, fract(ang * 4.0 + floor(eixo / 0.15) * 0.37));
	// Só no meio dos membros e do tronco (nem cabeça, nem mãos, nem pés).
	float zona = braco ? step(0.4, abs(p.x)) * step(abs(p.x), 0.85)
			: step(0.2, p.y) * step(p.y, 1.05) * (1.0 - step(0.45, abs(p.x)) * step(0.85, p.y));
	return traco * letra * zona;
}

void fragment() {
	vec3 c;
	if (usar_cor_vertice) {
		c = pow(COLOR.rgb, vec3(2.2));
	} else if (usar_cor_fixa) {
		c = cor_fixa.rgb;
	} else {
		vec3 lin = texture(textura, UV).rgb;
		vec3 g = sqrt(lin);  // volta perto do sRGB para os limiares
		float lum = dot(g, vec3(0.299, 0.587, 0.114));
		float sat = max(g.r, max(g.g, g.b)) - min(g.r, min(g.g, g.b));
		// pele: clara, quente e pouco saturada (couro é quente porém escuro)
		bool pele = lum > 0.68 && g.r >= g.g && g.g >= g.b && g.r - g.b > 0.08;
		if (pele) {
			c = lin;  // pele
		} else if (lum < 0.13) {
			c = vec3(0.01, 0.012, 0.03);  // olhos e traços
		} else if (sat < 0.1) {
			c = mix(vec3(0.02, 0.025, 0.06), vec3(0.3, 0.36, 0.5), lum);  // metal
		} else {
			c = cor_time.rgb * (0.25 + 1.0 * lum);  // roupa
			if (usar_cor_classe && v_tem_repouso > 0.5) {
				vec3 p = v_repouso;
				bool braco = abs(p.x) > 0.3 && p.y > 0.85;
				float faixa = braco ? step(0.6, abs(p.x)) * step(abs(p.x), 0.74)
						: max(step(0.5, p.y) * step(p.y, 0.64), step(0.96, p.y) * step(p.y, 1.06));
				c = mix(cor_classe.rgb * (0.35 + 1.0 * lum), c * 1.15, faixa);
			}
		}
	}
	float pronto = step(0.999, poder_carga) * (0.6 + 0.4 * sin(TIME * 7.0));
	float m = (usar_marcas && v_tem_repouso > 0.5) ? marcas(v_repouso) : 0.0;
	c *= 1.0 - m * tinta_marcas * (1.0 - poder_carga);
	ALBEDO = c;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 aura = mix(cor_time.rgb, cor_poder.rgb, poder_carga);
	EMISSION = aura * fres * (aro + 1.8 * poder_carga * poder_carga + 1.6 * pronto);
	// Selos acendendo: começam a aparecer com 15% de carga, cheios em 100%.
	float acende = smoothstep(0.15, 1.0, poder_carga);
	EMISSION += cor_poder.rgb * m * (2.2 * acende + 1.8 * pronto);
	// Olhos (traço escuro da textura) brilham com o poder quase cheio.
	if (!usar_cor_vertice && !usar_cor_fixa) {
		float olho = 1.0 - step(0.13, dot(sqrt(texture(textura, UV).rgb), vec3(0.299, 0.587, 0.114)));
		EMISSION += cor_poder.rgb * olho * (3.0 * smoothstep(0.7, 1.0, poder_carga) + 2.0 * pronto);
	}
#ifdef FANTASMA
	// Passo da Sombra visto pelo próprio time (toon_fantasma.gdshader): corpo
	// meio transparente com borda roxa de fantasma (Fresnel) pulsando de leve.
	float borda = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(ALBEDO, cor_fantasma, 0.35);
	EMISSION = mix(EMISSION, cor_fantasma * 1.6, borda) * (0.85 + 0.15 * sin(TIME * 9.0));
	ALPHA = clamp(1.0 - fantasma + borda * 0.6, 0.0, 1.0);
#endif
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float faixa = mix(0.4, 1.0, smoothstep(0.0, 0.04, ndl));  // sombra clara de desenho animado
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * faixa;
}
