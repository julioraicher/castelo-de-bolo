shader_type canvas_item;
// FXAA (caça aos bugs 2026-11-15): o Viewport.screen_space_aa só existe no
// Forward+/Mobile; no Compatibility (o renderizador do jogo em tudo) o Godot
// recusa e a Alta ficava sem antisserrilhado nenhum desde o 2.19.
//
// Como funciona (FXAA "console" de T. Lottes): o olho percebe serrilhado como
// degrau de BRILHO, então tudo é feito na luma L = 0,299R + 0,587G + 0,114B.
// 1. Lê as 4 diagonais; o gradiente de luma entre elas dá a direção da borda
//    (dir é perpendicular ao gradiente, ao longo do degrau).
// 2. Amostra 2 e 4 pontos ao longo dessa direção e tira a média: borra só
//    ao longo da borda, nunca através dela (o contorno de tinta não engorda).
// 3. Se a média de 4 sair do intervalo [min, max] de luma da vizinhança, ela
//    pegou outra borda: fica a de 2 (mais curta). Região lisa: dir ~ 0 e o
//    pixel volta igual.
// Custo: 9 leituras de textura por pixel, numa passada só sobre a tela pronta.

uniform sampler2D tela : hint_screen_texture, filter_linear;

const float REDUZ_MIN = 1.0 / 128.0;
const float REDUZ_MUL = 1.0 / 8.0;
const float ALCANCE = 8.0;
const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV;
	float l_no = dot(texture(tela, uv + vec2(-1.0, -1.0) * px).rgb, LUMA);
	float l_ne = dot(texture(tela, uv + vec2(1.0, -1.0) * px).rgb, LUMA);
	float l_so = dot(texture(tela, uv + vec2(-1.0, 1.0) * px).rgb, LUMA);
	float l_se = dot(texture(tela, uv + vec2(1.0, 1.0) * px).rgb, LUMA);
	vec4 meio = texture(tela, uv);
	float l_m = dot(meio.rgb, LUMA);
	float l_min = min(l_m, min(min(l_no, l_ne), min(l_so, l_se)));
	float l_max = max(l_m, max(max(l_no, l_ne), max(l_so, l_se)));

	vec2 dir = vec2(-((l_no + l_ne) - (l_so + l_se)), (l_no + l_so) - (l_ne + l_se));
	float reduz = max((l_no + l_ne + l_so + l_se) * 0.25 * REDUZ_MUL, REDUZ_MIN);
	float inv = 1.0 / (min(abs(dir.x), abs(dir.y)) + reduz);
	dir = clamp(dir * inv, vec2(-ALCANCE), vec2(ALCANCE)) * px;

	vec3 a = 0.5 * (texture(tela, uv + dir * (1.0 / 3.0 - 0.5)).rgb
			+ texture(tela, uv + dir * (2.0 / 3.0 - 0.5)).rgb);
	vec3 b = a * 0.5 + 0.25 * (texture(tela, uv + dir * -0.5).rgb
			+ texture(tela, uv + dir * 0.5).rgb);
	float l_b = dot(b, LUMA);
	COLOR = vec4((l_b < l_min || l_b > l_max) ? a : b, 1.0);
}
