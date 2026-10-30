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
//  - vento = seno no vértice com peso em UV.x (0 = parado, 1 = balança inteiro);
//  - desenho do material em UV.y: 0 liso, 1 tábuas, 2 telhas, 3 pedras, 4 reboco.
//    Tamanhos de 20-35 cm; fwidth() apaga o desenho quando ele fica denso demais
//    para a tela, o mesmo papel do mipmap numa textura.
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
varying float v_mat;

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

// Linha escura antialiasada: `f` = fração dentro da célula, `w` = meia-largura.
// fwidth mede quantas células cabem num pixel; quando o desenho fica denso
// demais para a tela (perto de Nyquist), ele some em vez de virar chuvisco.
float sulco(float f, float w, float dens) {
	float d = min(f, 1.0 - f);
	return 1.0 - smoothstep(w - dens, w + dens, d);
}

// Distância às bordas de células de Voronoi (pedras com rejunte).
vec3 voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 9.0;
	float d2 = 9.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 31.7)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; id = i + g; }
			else if (d < d2) { d2 = d; }
		}
	}
	return vec3(d2 - d1, id);
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
	v_mat = UV.y;
}

void fragment() {
	vec3 n = abs(v_normal_mundo);
	bool deitado = n.y > 0.6;
	float lado = n.x > n.z ? v_mundo.z : v_mundo.x;   // coordenada horizontal da face
	vec2 q = deitado ? v_mundo.xz : vec2(lado, v_mundo.y);
	// Pincel: manchas grandes esticadas na horizontal.
	vec2 p = q * escala_pincel * vec2(0.4, 1.5);
	float b = ruido(p * 1.1) * 0.6 + ruido(p * 2.5 + 17.0) * 0.4;
	vec3 cor = linear(COLOR.rgb);
	float m = 1.0;            // multiplicador do desenho do material
	int id = int(v_mat + 0.5);
	if (id == 1) {
		// Tábuas: faixas de 26 cm com sulco, emendas desencontradas e tom por tábua.
		float t = (deitado ? v_mundo.z : v_mundo.y) / 0.26;
		float fila = floor(t);
		float u = (deitado ? v_mundo.x : lado) / 1.6 + hash(vec2(fila, 3.1));
		float dt = fwidth(t);
		m *= 1.0 - 0.45 * sulco(fract(t), 0.06, dt);
		m *= 1.0 - 0.4 * sulco(fract(u), 0.015, fwidth(u));
		m *= 0.88 + 0.24 * hash(vec2(fila, floor(u)));
		m *= 0.92 + 0.16 * ruido(vec2(u * 6.0, fila));           // veio largo
	} else if (id == 2) {
		// Telhas: fileiras pela altura, meia-cana desencontrada, sombra em arco embaixo.
		float t = v_mundo.y / 0.2;
		float fila = floor(t);
		float c = lado / 0.34 + fila * 0.5;
		float fc = fract(c);
		float fr = fract(t);
		float arco = 0.18 + 0.2 * (1.0 - sin(3.14159 * fc));
		float dens = fwidth(t) + fwidth(c);
		float some = clamp(1.6 - dens * 2.5, 0.0, 1.0);
		float sombra = 1.0 - smoothstep(arco - dens, arco + dens, fr);
		m *= 1.0 - some * (0.5 * sombra + 0.3 * sulco(fc, 0.04, fwidth(c)));
		m *= 1.0 + some * 0.18 * smoothstep(0.6, 0.95, fr) * sin(3.14159 * fc);   // brilho no lombo
		m *= 0.9 + 0.2 * hash(vec2(floor(c), fila));
	} else if (id == 3) {
		// Pedras: células de ~35 cm, rejunte escuro, tom e musgo por pedra.
		vec3 v = voronoi(q / 0.35);
		float dens = fwidth(q.x / 0.35) * 1.5;
		m *= mix(0.45, 1.0, smoothstep(0.05, 0.12 + dens, v.x));
		float h = hash(v.yz);
		m *= 0.82 + 0.3 * h;
		cor = mix(cor, cor * vec3(0.75, 1.05, 0.6), step(0.78, h) * 0.6);
		m *= 0.9 + 0.2 * smoothstep(0.1, 0.4, v.x);               // pedra abaulada
	} else if (id == 4) {
		// Reboco: manchas de umidade, sujeira escorrendo de cima e rodapé encardido.
		float mancha = ruido(q * vec2(1.2, 0.6) + 5.0);
		m *= 1.0 - 0.22 * smoothstep(0.55, 0.85, mancha);
		float escorre = ruido(vec2(lado * 3.0, 0.0)) * smoothstep(0.4, 1.0, fract(v_alt / 1.9));
		m *= 1.0 - 0.18 * escorre * step(n.y, 0.6);
		m *= 1.0 - 0.08 * sulco(fract(lado / 2.3 + ruido(q * 2.0) * 0.2), 0.004, fwidth(lado / 2.3));
	}
	cor *= m;
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
