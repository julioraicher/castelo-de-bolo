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

// INSTANCE_CUSTOM: r = hora em que nasceu (relógio do nó), g = semente,
// b = força (0..1). A idade sai de `agora` (um uniform por quadro): nada de
// regravar cada instância por quadro.
uniform float agora = 0.0;
uniform float vida = 2.0;
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
	float idade = clamp((agora - dados.r) / vida, 0.0, 1.0);
	float sem = dados.g * 37.0;
	float forca = dados.b;
	// p: x = de lado, y = para onde o golpe empurrou (a tinta voa para +y).
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float abre = smoothstep(0.0, 0.06, idade);  // espirra rápido
	// Mancha principal: redonda, borda de pincel irregular (muitos lóbulos
	// baixos + ruído), não flor: tinta que bateu e espalhou.
	vec2 c = p - vec2(0.0, -0.18);
	float r = length(c);
	float a = atan(c.y, c.x);
	float borda = 0.6 + 0.035 * sin(a * 7.0 + sem) + 0.025 * sin(a * 13.0 + sem * 1.7)
			+ 0.09 * (ruido(vec2(a * 1.6 + sem, sem)) - 0.5) + 0.06 * max(c.y, 0.0);
	borda *= mix(0.5, 1.0, abre) * mix(0.82, 1.0, forca);
	float m = 1.0 - smoothstep(borda - 0.02, borda + 0.01, r);
	// Língua de tinta que escorre na direção do golpe, afinando na ponta.
	float comp = mix(0.25, 0.8, abre) * mix(0.75, 1.0, forca);
	float y = c.y / comp;
	float larg = mix(0.2, 0.03, clamp(y, 0.0, 1.0));
	float lingua = (1.0 - smoothstep(larg - 0.02, larg + 0.01, abs(p.x + 0.04 * sin(c.y * 7.0 + sem))))
			* step(0.0, y) * (1.0 - step(1.0, y));
	// Gotas na frente e dos lados (8): maiores perto, menores longe.
	float gotas = 0.0;
	for (int i = 0; i < 8; i++) {
		float fi = float(i);
		float ang = (hash(sem + fi * 3.1) - 0.5) * 2.2;
		float dist = mix(0.72, 0.97, hash(sem + fi * 7.7)) * mix(0.6, 1.0, abre);
		vec2 g = vec2(0.0, -0.18) + vec2(sin(ang), cos(ang)) * dist;
		float rg = max(mix(0.04, 0.1, hash(sem + fi * 1.3)) * (1.25 - dist * 0.6) * mix(0.75, 1.0, forca), 0.04);
		gotas = max(gotas, 1.0 - smoothstep(rg * 0.8, rg, length(p - g)));
	}
	m = max(max(m, lingua), gotas);
	// Some comida pelas bordas: o ruído "rói" a mancha conforme envelhece.
	float roi = smoothstep(0.55, 1.0, idade);
	float n = ruido(p * 5.0 + sem) * 0.7 + ruido(p * 13.0 - sem) * 0.3;
	m *= step(roi * 1.05, n * (1.0 - r * 0.4));
	if (m < 0.5) { discard; }
	// Tinta: miolo mais escuro e úmido, borda mais clara (pigmento acumula).
	float aro = smoothstep(borda - 0.14, borda, r) * (1.0 - lingua) * (1.0 - gotas);
	vec3 cor = cor_i.rgb * mix(0.78, 1.05, aro);
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
	mat.set_shader_parameter("vida", _vida)
	# Depois do chão (que tem camadas transparentes e, desenhado depois, cobria a
	# tinta) e antes dos efeitos (prioridade 2+).
	mat.render_priority = 1
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
	var tam := lerpf(1.7, 2.6, forca)
	# PlaneMesh: x = lado, z = frente (UV.y cresce com z; o shader inverte).
	var b := Basis(lado * tam, Vector3.UP, -frente * tam * 1.2)
	# Centro à frente do pé: a tinta voa com o golpe e quem apanhou também é
	# empurrado para lá; perto demais o corpo e o aro cobriam a mancha.
	var t := Transform3D(b, pos + frente * (0.7 + tam * 0.35) + Vector3.UP * 0.12)
	var i := _prox
	_prox = (_prox + 1) % mm.instance_count
	_vivos = mini(_vivos + 1, mm.instance_count)
	mm.visible_instance_count = _vivos
	mm.set_instance_transform(i, t)
	var tinta := cor.lerp(Color(0.12, 0.04, 0.06), 0.12)  # tinta: um pouco de nanquim na cor
	tinta.a = 0.92
	mm.set_instance_color(i, tinta)
	mm.set_instance_custom_data(i, Color(_t, randf(), forca, 0.0))
	_nasc[i] = _t
	(material_override as ShaderMaterial).set_shader_parameter("agora", _t)


func _process(delta: float) -> void:
	_t += delta
	if _vivos == 0:
		return
	(material_override as ShaderMaterial).set_shader_parameter("agora", _t)
	# O mais novo passou da vida: todos passaram (nascem em ordem).
	var ultimo := (_prox - 1 + multimesh.instance_count) % multimesh.instance_count
	if _t - _nasc[ultimo] > _vida:
		_vivos = 0
		_prox = 0
		multimesh.visible_instance_count = 0
