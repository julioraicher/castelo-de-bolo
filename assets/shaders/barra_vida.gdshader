shader_type spatial;
// Barra de vida dos bonecos (Ciclo 2.17): fundo escuro e preenchimento na
// cor do time num quad só (eram duas MeshInstance3D por boneco). Billboard
// que mantém a escala; sempre por cima (sem teste de profundidade).
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 cor_cheia : source_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform vec4 cor_fundo : source_color = vec4(0.0, 0.0, 0.0, 0.6);
uniform float margem = 0.125;        // fundo que sobra em cima/embaixo (fração da altura)
instance uniform float fracao = 1.0;  // vida / vida máxima

void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mat4 esc = mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = mv * esc;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	bool dentro = UV.x < fracao && UV.y > margem && UV.y < 1.0 - margem;
	ALBEDO = dentro ? cor_cheia.rgb : cor_fundo.rgb;
	ALPHA = dentro ? cor_cheia.a : cor_fundo.a;
}
