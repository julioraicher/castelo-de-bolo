// Recorte dos telhados (Ciclo 2.10b): o cenário entre a câmera e quem está
// brigando vira pontilhado, para a briga não sumir debaixo das casas.
//
// Geometria: cada foco F (peito do boneco) define um cone com vértice na
// câmera C e eixo d = (F - C)/|F - C|. Um pixel P do cenário some se
//   1) está na frente do boneco:     s = (P - C)·d  <  |F - C| - margem
//   2) está dentro do cone:          r = |(P - C) - s d|  <  R s / |F - C|
//   3) está acima dos pés do boneco: P.y > F.y - 0,7 m (chão, ponte e degrau ficam)
// O cone projeta um círculo de raio ~R em volta do boneco na tela, qualquer que
// seja a distância. O "transparente" é pontilhado (matriz de Bayer 4x4 no pixel
// da tela): não precisa de passe com alfa, nem de ordenar objetos, e o telhado
// continua escrevendo profundidade, então custa um descarte por pixel.
// Focos: CameraRig preenche recorte_foco0..3 (xyz = peito, w = raio em m; 0 = desligado).

global uniform vec4 recorte_foco0;
global uniform vec4 recorte_foco1;
global uniform vec4 recorte_foco2;
global uniform vec4 recorte_foco3;

float recorte_bayer(vec2 fc) {
	ivec2 p = ivec2(mod(fc, 4.0));
	int i = p.x + p.y * 4;
	// Matriz de Bayer 4x4 (limiares 0..15)/16, desenrolada para o GLSL ES 3.
	float b[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
			3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (b[i] + 0.5) / 16.0;
}

// Quanto do pixel fica (1 = inteiro, ~0,25 = no meio do recorte).
float recorte_um(vec4 foco, vec3 p, vec3 cam) {
	if (foco.w <= 0.01) {
		return 1.0;
	}
	vec3 f = foco.xyz;
	vec3 cf = f - cam;
	float l = length(cf);
	vec3 d = cf / l;
	vec3 cp = p - cam;
	float s = dot(cp, d);
	float r = length(cp - d * s);
	float lim = foco.w * s / l;
	float frente = 1.0 - smoothstep(l - 1.6, l - 0.6, s);
	float acima = smoothstep(f.y - 0.9, f.y - 0.5, p.y);
	float dentro = 1.0 - smoothstep(0.55, 1.0, r / max(lim, 0.001));
	return 1.0 - 0.78 * frente * acima * dentro;
}

void recorte(vec3 p, vec3 cam, vec2 fragcoord) {
	float fica = min(min(recorte_um(recorte_foco0, p, cam), recorte_um(recorte_foco1, p, cam)),
			min(recorte_um(recorte_foco2, p, cam), recorte_um(recorte_foco3, p, cam)));
	if (fica < 0.999 && recorte_bayer(fragcoord) > fica) {
		discard;
	}
}
