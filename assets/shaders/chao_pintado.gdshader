shader_type spatial;
// Chão pintado (Ciclo 2.2): grama em manchas de duas cores, touceiras
// mais escuras, pinceladas claras e uma estrada de terra com borda irregular.
// Mesma regra de frequência do pintura.gdshader (manchas >= ~25 cm).
render_mode specular_disabled;

uniform vec3 grama_escura : source_color = vec3(0.3, 0.62, 0.14);
uniform vec3 grama_clara : source_color = vec3(0.45, 0.78, 0.2);
uniform vec3 terra_escura : source_color = vec3(0.68, 0.6, 0.48);
uniform vec3 terra_clara : source_color = vec3(0.82, 0.75, 0.6);
uniform float rua_z = 5.6;       // centro da estrada (z, em metros)
uniform float rua_meia = 1.6;    // meia-largura da estrada (0 = sem estrada)
uniform float rua_x_max = 1000.0; // a estrada acaba em |x| = rua_x_max (portões)
uniform float trilha_z = 30.0;    // trilhas da floresta em |z| = trilha_z
uniform float trilha_meia = 0.0;  // meia-largura da trilha (0 = sem trilha)
uniform float trilha_x_max = 80.0;

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

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_mundo.xz;
	float grande = ruido(p * 0.12) * 0.6 + ruido(p * 0.35 + 7.0) * 0.4;
	vec3 grama = mix(grama_escura, grama_clara, smoothstep(0.3, 0.7, grande));
	float touceira = ruido(p * 1.6 + 3.0);
	grama *= 1.0 - 0.25 * smoothstep(0.62, 0.8, touceira);
	float risco = ruido(p * vec2(3.5, 0.9) + 11.0);
	grama *= 1.0 + 0.14 * smoothstep(0.7, 0.9, risco);
	// Estrada: borda ondulada, terra manchada e trilhas de roda mais escuras.
	float borda = rua_meia + (ruido(vec2(p.x * 0.8, 1.0)) - 0.5) * 0.7;
	float dz = abs(p.y - rua_z) + max(abs(p.x) - rua_x_max, 0.0);
	float na_rua = (1.0 - smoothstep(borda - 0.15, borda + 0.15, dz)) * step(0.01, rua_meia);
	vec3 terra = mix(terra_escura, terra_clara, ruido(p * 0.9 + 21.0)) * 0.85;
	terra *= 1.0 - 0.15 * (1.0 - smoothstep(0.1, 0.3, abs(dz - rua_meia * 0.45)));
	vec3 cor = mix(grama, terra, na_rua);
	// Faixa de grama pisada / sombra na borda da estrada.
	cor *= 1.0 - 0.18 * (1.0 - smoothstep(0.0, 0.35, abs(dz - borda))) * step(0.01, rua_meia);
	// Trilhas da floresta: terra mais escura e estreita, serpenteando de leve,
	// com tufos de grama no meio (caminho de pé, não de carroça).
	if (trilha_meia > 0.01) {
		float tz = abs(abs(p.y) - trilha_z + sin(p.x * 0.11) * 0.55) + max(abs(p.x) - trilha_x_max, 0.0) * 1.5;
		float bt = trilha_meia + (ruido(vec2(p.x * 1.1, 5.0)) - 0.5) * 0.6;
		float na_trilha = 1.0 - smoothstep(bt - 0.2, bt + 0.2, tz);
		na_trilha *= 1.0 - 0.7 * smoothstep(0.6, 0.85, ruido(p * 2.2 + 31.0)) * (1.0 - smoothstep(0.0, 0.5, tz));
		vec3 terra_t = mix(terra_escura, terra_clara, ruido(p * 1.3 + 41.0) * 0.6) * vec3(0.8, 0.68, 0.52);
		cor = mix(cor, terra_t, na_trilha);
		cor *= 1.0 - 0.15 * (1.0 - smoothstep(0.0, 0.4, abs(tz - bt)));
	}
	ALBEDO = cor;
	ROUGHNESS = 1.0;
}
