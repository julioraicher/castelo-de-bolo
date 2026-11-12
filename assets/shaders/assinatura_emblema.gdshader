shader_type canvas_item;
// Emblema do personagem na interface (ficha da classe): o mesmo carimbo
// vermelho (hanko) que aparece ao lado do nome do golpe, tirado do atlas de
// campo de distância das assinaturas (Ciclo 2.24). Use num ColorRect quadrado.
uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform vec4 celula = vec4(0.0, 0.0, 0.16667, 0.16667);
uniform vec4 cor : source_color = vec4(0.82, 0.13, 0.1, 1.0);
uniform vec4 papel : source_color = vec4(1.0, 0.96, 0.86, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float sd = (texture(atlas, celula.xy + UV * celula.zw).r - 0.5) * 2.0;
	float w = fwidth(sd) * 0.75 + 0.02;
	float t = smoothstep(-w, w, sd - 0.1);
	float q = max(abs(p.x), abs(p.y));
	float fundo = 1.0 - smoothstep(0.88, 0.96, q);
	COLOR = vec4(mix(cor.rgb, papel.rgb, t), fundo);
}
