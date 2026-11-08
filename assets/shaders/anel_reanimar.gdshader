shader_type spatial;
// Anel no chão em volta do aliado caído (Ciclo 2.18): traço fino na cor do
// time marca até onde dá para reanimar; o arco dourado enche no sentido
// horário com o progresso. Um quad deitado, sem textura nem sombra.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

instance uniform vec4 cor : source_color = vec4(0.4, 0.7, 1.0, 1.0);
instance uniform float progresso = 0.0;  // 0..1
instance uniform float vida = 1.0;       // 1 = acabou de cair, 0 = espera no fim

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	// Ângulo de 0 (em cima) a 1, sentido horário visto de cima.
	float a = fract(atan(p.x, -p.y) / 6.2831853 + 1.0);
	float aa = fwidth(r) * 1.5;
	float base = smoothstep(0.06 + aa, 0.06, abs(r - 0.86)) * 0.55;
	// Tracinhos girando devagar: o anel "respira" enquanto espera.
	float tracos = step(0.5, fract(a * 24.0 + TIME * 0.25));
	base *= mix(0.45, 1.0, tracos) * mix(0.35, 1.0, vida);
	float arco = smoothstep(0.11 + aa, 0.11, abs(r - 0.86)) * step(a, progresso);
	float halo = smoothstep(0.32, 0.0, abs(r - 0.86)) * step(a, progresso) * 0.35;
	vec3 ouro = vec3(1.0, 0.8, 0.35);
	vec3 c = mix(cor.rgb, ouro, clamp(arco + halo, 0.0, 1.0));
	ALBEDO = c * (1.0 + arco * 0.8);
	ALPHA = clamp(max(base, max(arco, halo)), 0.0, 1.0);
}
