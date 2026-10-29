shader_type spatial;
// Toon dos personagens: 2 faixas de luz + contraluz na cor do time.
// A textura KayKit é uma paleta; cada cor vira um papel:
// pele fica, cinza vira aço azul-noite, o resto (pano, couro) vira cor do time.

uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec4 cor_time : source_color = vec4(0.16, 0.45, 1.0, 1.0);
uniform bool usar_cor_fixa = false;
uniform bool usar_cor_vertice = false;  // peças montadas por código (cor no vértice, sRGB)
uniform vec4 cor_fixa : source_color = vec4(1.0);
uniform float aro = 0.7;

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
		}
	}
	ALBEDO = c;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = cor_time.rgb * fres * aro;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float faixa = mix(0.25, 1.0, smoothstep(0.0, 0.06, ndl));
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * faixa;
}
