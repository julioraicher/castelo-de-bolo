class_name MarcaChao
extends RefCounted
## Marca no chão dos poderes de área: um quadrado só, com um shader que desenha
## o símbolo de cada poder (1 draw call por zona, sem textura):
##   nuvem       borda de pincel de tinta (sumi-e) e manchas de tinta girando
##   selo        estrela de 5 pontas (Kitsune Sombria) e anel de "escrita" correndo
##   coluna_fogo língua de fogo-raposa na borda e 3 caudas girando dentro
##   chuva       sombras das flechas chegando, borda tracejada e 4 setas fechando
## A borda some como um relógio conforme o tempo do poder acaba. Um aro fino na
## cor do time diz de quem é a zona.

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform int tipo = 0;
uniform vec4 cor : source_color = vec4(1.0);
uniform vec4 cor_time : source_color = vec4(1.0);
uniform float progresso = 0.0;
uniform float alerta = 0.0;
uniform float alpha_geral = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) { v += a * ruido(p); p *= 2.03; a *= 0.5; }
	return v;
}
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}
vec2 gira(vec2 p, float a) { return vec2(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y); }

void fragment() {
	vec2 p = (UV - 0.5) * 2.16;
	float r = length(p);
	if (r > 1.08) { discard; }
	float a = atan(p.y, p.x);
	float t = TIME;
	float ang01 = fract(a / 6.2831853 + 0.25);
	float relogio = step(ang01, 1.0 - progresso);
	vec3 escuro = cor.rgb * 0.22;
	vec3 c = vec3(0.0);
	float al = 0.0;
	float x;

	if (tipo == 0) {
		// Tinta: fundo lavado, manchas girando e borda de pincel irregular.
		vec2 q = gira(p, r * 2.2 - t * 0.35);
		float n = fbm(q * 2.6 + vec2(t * 0.12, -t * 0.08));
		x = step(r, 1.0) * (0.16 + 0.42 * smoothstep(0.5, 0.72, n));
		c = mix(c, escuro, x); al = max(al, x);
		float w = 0.045 + 0.07 * fbm(normalize(p) * 3.0 + vec2(1.7, t * 0.1));
		x = smoothstep(w, w * 0.4, abs(r - 0.94)) * mix(0.35, 0.95, relogio);
		c = mix(c, mix(escuro, cor.rgb, 0.35), x); al = max(al, x);
		vec2 id = floor(p * 9.0);
		float pingo = step(0.86, hash(id)) * smoothstep(0.16, 0.08, length(fract(p * 9.0) - 0.5)) * step(0.98, r) ;
		c = mix(c, escuro, pingo * 0.8); al = max(al, pingo * 0.8);
	} else if (tipo == 1) {
		// Selo: sombra escura por baixo e traço de luz por cima.
		x = step(r, 1.0) * 0.14;
		c = mix(c, cor.rgb, x); al = max(al, x);
		float th = t * 0.25;
		float d = 9.0;
		for (int i = 0; i < 5; i++) {
			float a0 = th + float(i) * 1.2566371;
			float a1 = th + float(i + 2) * 1.2566371;
			d = min(d, seg(p, 0.76 * vec2(cos(a0), sin(a0)), 0.76 * vec2(cos(a1), sin(a1))));
		}
		d = min(d, abs(r - 0.78));
		float aneis = min(abs(r - 0.97), abs(r - 0.84));
		x = smoothstep(0.045, 0.02, min(d, aneis)) * 0.55;
		c = mix(c, escuro, x); al = max(al, x);
		float u = (ang01 + t * 0.03) * 40.0;
		float cel = floor(u);
		float alt = 0.88 + 0.06 * hash(vec2(cel, 3.0));
		float escrita = step(0.3, hash(vec2(cel, 7.0))) * step(0.2, fract(u)) * step(fract(u), 0.75) * step(0.865, r) * step(r, alt);
		x = max(smoothstep(0.018, 0.006, d), smoothstep(0.012, 0.004, aneis) * mix(0.3, 1.0, step(abs(r - 0.97), 0.02) * relogio + step(abs(r - 0.84), 0.02)));
		x = max(x, escrita * 0.9);
		c = mix(c, cor.rgb * 1.5, x); al = max(al, x);
	} else if (tipo == 2) {
		// Fogo-raposa: línguas de fogo na borda e 3 caudas girando dentro.
		float s = sin(3.0 * a + r * 7.0 - t * 3.0);
		x = step(r, 1.0) * (0.14 + 0.45 * smoothstep(0.7, 1.0, s) * smoothstep(1.0, 0.15, r));
		c = mix(c, cor.rgb, x); al = max(al, x);
		float h = (0.1 + 0.26 * fbm(normalize(p) * 3.5 + vec2(0.0, -t * 2.2))) * mix(0.35, 1.0, relogio);
		float base = 0.98 - h;
		float k = clamp((r - base) / max(h, 0.001), 0.0, 1.0);
		x = step(base, r) * step(r, 0.99) * (1.0 - k * k) * 0.95;
		c = mix(c, mix(cor.rgb * 0.45, cor.rgb * 1.5, k), x); al = max(al, x);
		float borda = smoothstep(0.035, 0.0, abs(r - base)) * 0.75;
		c = mix(c, escuro, borda * (1.0 - x)); al = max(al, borda);
	} else {
		// Chuva de flechas: sombras das flechas chegando, tracejado e setas.
		x = step(r, 1.0) * (0.1 + 0.25 * alerta);
		c = mix(c, cor.rgb, x); al = max(al, x);
		vec2 q = p * 5.0;
		vec2 id = floor(q);
		vec2 f = fract(q) - 0.5;
		float vida = fract(t * 1.4 + hash(id));
		float d = seg(f, vec2(-0.05, -0.02), vec2(-0.05, -0.02) + vec2(0.3, 0.12) * (1.2 - vida));
		x = smoothstep(0.07, 0.03, d) * vida * vida * step(r, 0.93) * mix(0.35, 0.8, 1.0 - alerta);
		c = mix(c, vec3(0.05, 0.04, 0.06), x); al = max(al, x);
		float tra = step(0.45, fract(ang01 * 28.0 - t * 0.6)) * smoothstep(0.03, 0.012, abs(r - 0.96));
		c = mix(c, cor.rgb, tra * mix(0.3, 1.0, relogio)); al = max(al, tra * mix(0.3, 1.0, relogio));
		float rc = 0.8 - 0.1 * sin(t * 4.0);
		for (int i = 0; i < 4; i++) {
			float ag = float(i) * 1.5707963 + t * 0.3;
			vec2 dir = vec2(cos(ag), sin(ag));
			vec2 l = vec2(dot(p, dir) - rc, dot(p, vec2(-dir.y, dir.x)));
			float v = smoothstep(0.035, 0.015, abs(l.x - abs(l.y) * 0.9)) * step(abs(l.y), 0.13);
			c = mix(c, mix(cor.rgb, vec3(1.0), 0.4), v); al = max(al, v);
		}
	}
	float aro = smoothstep(0.016, 0.004, abs(r - 1.02));
	c = mix(c, cor_time.rgb, aro * 0.9); al = max(al, aro * 0.9);
	ALBEDO = c;
	ALPHA = clamp(al, 0.0, 1.0) * alpha_geral;
}
"""

const TIPOS := {"nuvem": 0, "selo": 1, "coluna_fogo": 2, "chuva": 3}

static var _shader: Shader


## Cria a marca como filha de `pai` (no centro da zona). `dur` é o tempo que o
## relógio da borda leva para esvaziar; `atraso` espera antes de começar.
static func criar(pai: Node3D, tipo: String, raio: float, cor: Color, cor_time: Color, dur: float, atraso := 0.0) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("tipo", TIPOS.get(tipo, 0))
	mat.set_shader_parameter("cor", cor)
	mat.set_shader_parameter("cor_time", cor_time)
	var mi := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2.ONE * raio * 2.16
	mi.mesh = plano
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.08
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(mi)
	var tw := mi.create_tween()
	if atraso > 0.0:
		tw.tween_interval(atraso)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progresso", v), 0.0, 1.0, maxf(dur, 0.05))
	return mat
