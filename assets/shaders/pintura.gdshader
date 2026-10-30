shader_type spatial;
// Material "pintado à mão" do cenário (Ciclo 2.2). Tudo é matemática no pixel,
// sem textura e sem polígono a mais:
//  - cor da peça = cor por vértice (COLOR.rgb, em sRGB);
//  - oclusão pintada = COLOR.a (1 = aberto, 0 = fresta escura), assada no gerador;
//  - pincel = ruído de valor em espaço de mundo, de BAIXA frequência (manchas de
//    ~0,4-1 m): uma casa ocupa ~150-250 px na tela, então 1 m ≈ 30 px e a menor
//    mancha fica com ~12 px, acima do limite de Nyquist (~2 px) mesmo com a câmera
//    andando. Veio fino de madeira viraria chuvisco, por isso não existe aqui;
//  - luz em faixas suaves, sombra puxada para uma cor fria (roxo/azul) e borda
//    clara do lado do sol;
//  - vento = seno no vértice com peso em UV.x (0 = parado, 1 = balança inteiro).
render_mode specular_disabled;

uniform float forca_pincel : hint_range(0.0, 0.6) = 0.32;
uniform float escala_pincel = 1.0;
uniform float forca_ao : hint_range(0.0, 1.0) = 0.85;
uniform vec3 cor_sombra : source_color = vec3(0.32, 0.36, 0.62);
uniform float forca_sombra : hint_range(0.0, 1.0) = 0.35;
uniform float faixas : hint_range(0.0, 1.0) = 0.35;
uniform vec3 cor_borda : source_color = vec3(1.0, 0.85, 0.6);
uniform float forca_borda : hint_range(0.0, 2.0) = 0.45;
uniform float vento_amp = 0.06;
uniform float vento_vel = 1.7;

varying vec3 v_mundo;
varying vec3 v_normal_mundo;
varying float v_alt;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec3 linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void vertex() {
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float peso = UV.x;
	if (peso > 0.0) {
		float t = TIME * vento_vel + mundo.x * 0.35 + mundo.z * 0.27;
		VERTEX.x += sin(t) * vento_amp * peso;
		VERTEX.z += sin(t * 0.77 + 1.3) * vento_amp * 0.6 * peso;
		mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	}
	v_mundo = mundo;
	v_normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_alt = mundo.y - NODE_POSITION_WORLD.y;
}

void fragment() {
	vec3 n = abs(v_normal_mundo);
	// Plano de projeção pela normal; pinceladas esticadas na horizontal.
	vec2 p = n.y > 0.6 ? v_mundo.xz : (n.x > n.z ? v_mundo.zy : v_mundo.xy);
	p *= escala_pincel * vec2(0.4, 1.5);
	float b = ruido(p * 1.1) * 0.6 + ruido(p * 2.5 + 17.0) * 0.4;
	vec3 cor = linear(COLOR.rgb);
	cor *= 1.0 + (b - 0.5) * 2.0 * forca_pincel;
	cor *= mix(vec3(0.9, 0.95, 1.1), vec3(1.1, 1.0, 0.88), b);  // mancha fria / quente
	cor *= mix(0.9, 1.06, clamp(v_alt / 5.0, 0.0, 1.0));           // gradiente de cima para baixo
	ALBEDO = cor * mix(1.0, COLOR.a, forca_ao);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = clamp((ndl + 0.3) / 1.3, 0.0, 1.0) * ATTENUATION;
	float suave = smoothstep(0.0, 1.0, w);
	float luz = mix(suave, floor(suave * 3.0 + 0.5) / 3.0, faixas);
	DIFFUSE_LIGHT += LIGHT_COLOR * luz;
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += cor_sombra * (1.0 - luz) * forca_sombra;
		float aro = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		SPECULAR_LIGHT += cor_borda * aro * max(ndl, 0.0) * ATTENUATION * forca_borda * ALBEDO;
	}
}
