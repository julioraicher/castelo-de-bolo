class_name Respingo
extends MultiMeshInstance3D
## Respingo de tinta no chão onde o golpe acertou (Ciclo 2.26), na cor do time
## de quem apanhou. Mancha de pincel esticada na direção do golpe (a tinta voa
## para longe de quem bateu) + gotas na frente; abre em ~0,1 s, fica e some
## comida pelas bordas (como o `corroi` do kit Magia).
##
## Orçamento: TODOS os respingos num MultiMesh só = 1 chamada de desenho, sem
## textura (forma por shader). Anel de respingo_max quadrados reaproveitados.

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// INSTANCE_CUSTOM: r = idade (0 nasce, 1 some), g = semente, b = força (0..1).
varying vec4 dados;
varying vec4 cor_i;

float hash(float n) { return fract(sin(n) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	dados = INSTANCE_CUSTOM;
	cor_i = COLOR;
}

void fragment() {
	float idade = dados.r;
	float sem = dados.g * 37.0;
	float forca = dados.b;
	// p: x = de lado, y = para onde o golpe empurrou (a tinta voa para +y).
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float abre = smoothstep(0.0, 0.06, idade);  // espirra rápido
	// Mancha principal: raio que ondula com o ângulo (borda de pincel).
	vec2 c = p - vec2(0.0, -0.12);
	float r = length(c);
	float a = atan(c.y, c.x);
	float borda = 0.42 + 0.07 * sin(a * 5.0 + sem) + 0.05 * sin(a * 9.0 + sem * 1.7)
			+ 0.06 * (ruido(vec2(a * 2.0, sem)) - 0.5);
	borda *= mix(0.55, 1.0, abre) * mix(0.8, 1.05, forca);
	float m = 1.0 - smoothstep(borda - 0.03, borda + 0.01, r);
	// Língua de tinta que escorre na direção do golpe.
	float lingua = (1.0 - smoothstep(0.08, 0.13 + 0.05 * forca, abs(p.x + 0.05 * sin(p.y * 6.0 + sem))))
			* step(0.0, p.y) * (1.0 - smoothstep(0.55, 0.78 * abre, p.y));
	m = max(m, lingua);
	// Gotas na frente (5), maiores perto, menores longe.
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		float ang = (hash(sem + fi * 3.1) - 0.5) * 1.4;
		float dist = mix(0.55, 0.92, hash(sem + fi * 7.7)) * abre;
		vec2 g = vec2(sin(ang), cos(ang)) * dist;
		float rg = mix(0.035, 0.085, hash(sem + fi * 1.3)) * (1.1 - dist * 0.5) * mix(0.7, 1.0, forca);
		m = max(m, 1.0 - smoothstep(rg - 0.01, rg + 0.005, length(p - g)));
	}
	// Some comida pelas bordas: o ruído "rói" a mancha conforme envelhece.
	float roi = smoothstep(0.55, 1.0, idade);
	float n = ruido(p * 5.0 + sem) * 0.7 + ruido(p * 13.0 - sem) * 0.3;
	m *= step(roi * 1.05, n * (1.0 - r * 0.4));
	if (m < 0.5) { discard; }
	// Tinta: miolo mais escuro e úmido, borda mais clara (pigmento acumula).
	float aro = smoothstep(borda - 0.12, borda, r) * (1.0 - lingua);
	vec3 cor = cor_i.rgb * mix(0.62, 0.95, aro);
	cor += vec3(0.08) * (1.0 - smoothstep(0.0, 0.18, length(p - vec2(-0.12, 0.0))));  // brilho molhado
	ALBEDO = cor;
	ALPHA = cor_i.a * (1.0 - smoothstep(0.85, 1.0, idade) * 0.6);
}
"""

static var _shader: Shader

var _vida := 2.0
var _nasc: PackedFloat32Array = []
var _prox := 0
var _vivos := 0
var _t := 0.0  # relógio próprio: para junto com a pausa


## Pinta um respingo: pos = pé de quem apanhou, dir = direção do golpe
## (de quem bate para quem apanha), forca 0..1 (tamanho).
static func em(game: Node, pos: Vector3, dir: Vector3, cor: Color, forca := 0.6) -> void:
	if game == null or Config.cfg.respingo_max <= 0:
		return
	var r: Respingo = game.get_node_or_null("Respingo")
	if r == null:
		r = Respingo.new()
		r.name = "Respingo"
		game.add_child(r)
	r._pintar(pos, dir, cor, forca)


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var n := maxi(Config.cfg.respingo_max, 1)
	_vida = maxf(Config.cfg.respingo_vida, 0.2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := PlaneMesh.new()
	q.size = Vector2(1, 1)
	mm.mesh = q
	mm.instance_count = n
	mm.visible_instance_count = 0
	multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.render_priority = -1  # por baixo dos outros transparentes (marcas de poder, bonecos)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_nasc.resize(n)
	_nasc.fill(-100.0)
	for i in n:
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	# Caixa grande: o MultiMesh não recalcula o AABB a cada respingo.
	custom_aabb = AABB(Vector3(-200, -20, -200), Vector3(400, 60, 400))


func _pintar(pos: Vector3, dir: Vector3, cor: Color, forca: float) -> void:
	var mm := multimesh
	var frente := Vector3(dir.x, 0.0, dir.z)
	frente = frente.normalized() if frente.length() > 0.05 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var lado := Vector3.UP.cross(frente).normalized()
	var tam := lerpf(1.0, 1.9, forca)
	# PlaneMesh: x = lado, z = frente (UV.y cresce com z; o shader inverte).
	var b := Basis(lado * tam * 0.85, Vector3.UP, -frente * tam * 1.25)
	var t := Transform3D(b, pos + frente * tam * 0.35 + Vector3.UP * 0.045)
	var i := _prox
	_prox = (_prox + 1) % mm.instance_count
	_vivos = mini(_vivos + 1, mm.instance_count)
	mm.visible_instance_count = _vivos
	mm.set_instance_transform(i, t)
	var tinta := cor.darkened(0.15)
	tinta.a = 0.88
	mm.set_instance_color(i, tinta)
	mm.set_instance_custom_data(i, Color(0.0, randf(), forca, 0.0))
	_nasc[i] = _t


func _process(delta: float) -> void:
	_t += delta
	if _vivos == 0:
		return
	var mm := multimesh
	var agora := _t
	var algum := false
	for i in _vivos:
		var nasc := _nasc[i]
		if nasc < -50.0:
			continue
		var idade := (agora - nasc) / _vida
		if idade >= 1.0:
			_nasc[i] = -100.0
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
			continue
		algum = true
		var c := mm.get_instance_custom_data(i)
		c.r = idade
		mm.set_instance_custom_data(i, c)
	if not algum:
		_vivos = 0
		_prox = 0
		mm.visible_instance_count = 0
