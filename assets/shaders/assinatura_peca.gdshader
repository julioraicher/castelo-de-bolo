shader_type spatial;
// Partícula com forma (Ciclo 2.24): pena, folha de bordo, talismã, nota, sal...
// Um quad virado para a câmera por partícula; a forma vem do atlas de campo de
// distância (tools/assinaturas/), com miolo na cor da partícula, brilho no
// centro e filete de tinta. `vira` > 0 faz a peça tombar no ar (pena e papel
// caindo): o quad achata e desachata ao longo da vida.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform vec4 celula = vec4(0.0, 0.0, 0.25, 0.25);
uniform vec4 cor_tinta : source_color = vec4(0.09, 0.03, 0.14, 1.0);
uniform float vira = 0.0;

void vertex() {
	float ang = INSTANCE_CUSTOM.x;
	float fase = INSTANCE_CUSTOM.y;
	float semente = float(INSTANCE_ID) * 1.7;
	if (vira > 0.0) {
		VERTEX.x *= cos(fase * vira * TAU + semente);
		ang += sin(fase * vira * 4.0 + semente) * 0.6;
	}
	mat4 m = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	m = m * mat4(vec4(cos(ang), -sin(ang), 0.0, 0.0), vec4(sin(ang), cos(ang), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	m = m * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float sd = (texture(atlas, celula.xy + UV * celula.zw).r - 0.5) * 2.0;
	float w = fwidth(sd) * 0.75 + 0.03;
	float miolo = smoothstep(-w, w, sd);
	float filete = smoothstep(-0.5 - w, -0.5 + w, sd);
	vec3 c = mix(COLOR.rgb, min(COLOR.rgb * 1.25 + 0.2, vec3(1.0)), smoothstep(0.25, 0.9, sd));
	ALBEDO = mix(cor_tinta.rgb, c, miolo);
	ALPHA = max(miolo, filete * 0.85) * COLOR.a;
	if (ALPHA < 0.01) {
		discard;
	}
}
