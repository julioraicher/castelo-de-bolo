shader_type spatial;
// Fantasma da casa evoluída em cima de cada tapete do bairro (Ciclo 2.21):
// o futuro da casa, translúcido, na cor do caminho. Borda (fresnel) acesa,
// miolo quase vazio e faixas de luz subindo devagar, como papel de lanterna
// contra a luz. depth_prepass_alpha: só a camada da frente aparece (o telhado
// de trás não soma transparência por cima). Sem luz nem sombra: 1 passe barato.
render_mode unshaded, depth_prepass_alpha, cull_back, shadows_disabled;

uniform vec4 cor : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform float alfa : hint_range(0.0, 1.0) = 0.5;
uniform float altura = 4.0;   // da casa, para as faixas andarem por ela inteira

varying float v_y;

void vertex() {
	v_y = VERTEX.y / max(altura, 0.1);
}

void fragment() {
	float fr = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.6);
	float faixa = smoothstep(0.55, 1.0, sin((v_y * 7.0 - TIME * 0.9) * 3.14159));
	vec3 c = cor.rgb;
	ALBEDO = mix(c * 0.45, c * 1.35 + vec3(0.12), fr) + c * faixa * 0.35;
	ALPHA = alfa * (0.22 + 0.78 * fr + 0.25 * faixa) * smoothstep(-0.05, 0.12, v_y);
}
