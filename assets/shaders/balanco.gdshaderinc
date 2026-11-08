// Balanço das peças dos bonecos (Personagens 2.0): caudas que varrem, fogo de
// raposa que boia ou treme. NinjaVisual grava em CUSTOM1 de cada vértice das
// peças: x = peso (0 = parada; nas caudas cresce da base à ponta), y = fase,
// z = tipo (0 cauda, 1 fogo calmo, 2 fogo tremido). Corpo e cenário não têm
// CUSTOM1 (lê 0) e não mexem. Usado pelo toon, neon, contorno e raio X, para
// o contorno e a silhueta acompanharem a peça.
//
// agito (por boneco, Unit._tick_agito): 0 parado, sobe a 1 no ataque/poder
// (cauda abre e varre rápido, fogo agita) e vai a -1 na morte (cauda para
// mole, fogo apaga).
instance uniform float agito = 0.0;

vec3 balanco(vec4 b, float t) {
	if (b.x == 0.0) {
		return vec3(0.0);
	}
	float viva = clamp(agito, 0.0, 1.0);
	float morta = clamp(-agito, 0.0, 1.0);
	if (b.z < 0.5) {
		// Cauda: viga presa na base, deslocamento ~ peso² (modo 1 de uma
		// viga em balanço, aproximado). Na ação a frequência sobe e ela ergue.
		float w2 = b.x * b.x;
		float f = mix(1.7, 6.0, viva);
		float lado = sin(t * f + b.y) * mix(0.10, 0.16, viva) * (1.0 - morta);
		float cima = (sin(t * f * 2.0 + b.y * 1.7) * 0.025 + 0.10 * viva) * (1.0 - morta);
		return vec3(lado, cima, 0.0) * w2;
	}
	if (b.z < 1.5) {
		// Fogo calmo (Luz): boia devagar, como lanterna na água.
		return vec3(0.0, sin(t * mix(1.6, 4.0, viva) + b.y) * 0.05 * b.x, 0.0);
	}
	// Fogo tremido (Sombria): três senos de frequências primas entre si,
	// quase sem repetição visível.
	float a = mix(0.018, 0.04, viva) * b.x;
	return vec3(sin(t * 23.0 + b.y * 7.0) * sin(t * 7.3 + b.y),
			sin(t * 31.0 + b.y * 3.0) * 0.6,
			sin(t * 19.0 + b.y * 5.0) * sin(t * 5.1)) * a;
}
