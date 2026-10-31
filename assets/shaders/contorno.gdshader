shader_type spatial;
// Contorno por casca invertida: a malha cresce na normal e só as costas aparecem.
render_mode unshaded, cull_front;

uniform float espessura = 0.025;
uniform vec4 cor : source_color = vec4(0.02, 0.02, 0.06, 1.0);
uniform float relogio = -1.0;
uniform bool girar = false;   // só o cenário (os bonecos podem ter UV2 próprio)

void vertex() {
	// Peça que gira: mesma conta do pintura.gdshader (UV2 = velocidade, amplitude).
	if (girar && UV2.x != 0.0) {
		float t = relogio >= 0.0 ? relogio : TIME;
		float ang = UV2.y > 0.0 ? UV2.y * sin(t * UV2.x) : t * UV2.x;
		mat2 r = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang)));
		VERTEX.xy = r * VERTEX.xy;
		NORMAL.xy = r * NORMAL.xy;
	}
	VERTEX += NORMAL * espessura;
}

void fragment() {
	ALBEDO = cor.rgb;
}
