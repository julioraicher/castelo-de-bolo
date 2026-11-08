shader_type canvas_item;
// Fundo do placar (Tab): o jogo continua rodando atrás, borrado, sem cor e
// escuro, mas ainda dá para ver a briga. Desfoque de 25 amostras com peso
// em cone (sem mipmap da tela, que o modo Compatibilidade/WebGL não garante).
uniform sampler2D tela : hint_screen_texture, filter_linear;
uniform float raio = 3.0;          // px entre amostras (5x5 = ±2·raio)
uniform float escurecer = 0.58;    // 0 = jogo como está, 1 = só a tinta
uniform float dessaturar = 0.45;
uniform vec4 tinta : source_color = vec4(0.06, 0.04, 0.09, 1.0);
uniform float vinheta = 0.35;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * raio;
	vec3 soma = vec3(0.0);
	float peso = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float k = 1.0 - length(vec2(float(x), float(y))) / 3.3;
			soma += texture(tela, SCREEN_UV + vec2(float(x), float(y)) * px).rgb * k;
			peso += k;
		}
	}
	vec3 c = soma / peso;
	float luz = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(luz), dessaturar);
	float borda = smoothstep(0.35, 0.85, length(UV - 0.5) * 1.4);
	c = mix(c, tinta.rgb, clamp(escurecer + borda * vinheta, 0.0, 1.0));
	COLOR = vec4(c, 1.0);
}
