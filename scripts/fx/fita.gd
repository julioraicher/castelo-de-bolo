class_name Fita
extends MeshInstance3D
## Fita de rastro (Ciclo 2.20): segue dois pontos de um nó (base e ponta de uma
## lâmina, ou as bordas de um projétil) e desenha a faixa por onde passaram.
## Uma malha refeita por quadro (≤ 2·N vértices, 1 chamada de desenho). V vai de
## 0 na cabeça a 1 na cauda, U atravessa a fita: o shader `magia_energia`
## afina e desfaz a cauda. Some sozinha: `soltar()` deixa a cauda alcançar a
## cabeça e libera o nó.

var alvo: Node3D
var a := Vector3.ZERO           # pontos no espaço do alvo
var b := Vector3(0, 1, 0)
var pontos := 12
var passo := 0.016              # segundos entre amostras
## Caça 2026-11-19 (FX-03): a fita mede o comprimento em TEMPO (pontos × passo,
## ~0,2 s), não em quadros. Antes guardava 1 amostra por quadro: a 10 FPS os 12
## pontos cobriam 1,2 s (fita 6× mais comprida) e a cauda demorava 1,2 s a sumir.
var _pa: PackedVector3Array = []
var _pb: PackedVector3Array = []
var _idade: PackedFloat32Array = []  # instante (em _agora) de cada amostra
var _agora := 0.0
var _solta := false
var _im := ImmediateMesh.new()


func _init() -> void:
	mesh = _im
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	extra_cull_margin = 8.0


func _ready() -> void:
	global_transform = Transform3D.IDENTITY


## Para de seguir: a cauda encolhe até sumir e o nó se libera.
func soltar() -> void:
	_solta = true


func _process(delta: float) -> void:
	var vivo := is_instance_valid(alvo) and alvo.is_inside_tree() and not _solta
	_agora += delta
	var janela := pontos * passo
	# A lâmina e o projétil são desenhados interpolados (física a 60 Hz, tela a
	# qualquer taxa): ler a posição interpolada para a fita não descolar (FX-29).
	var x := alvo.get_global_transform_interpolated() if vivo else Transform3D.IDENTITY
	if vivo and (_idade.is_empty() or _agora - _idade[0] >= passo):
		_pa.insert(0, x * a)
		_pb.insert(0, x * b)
		_idade.insert(0, _agora)
	# Guarda uma amostra além da janela (a ponta da cauda) enquanto a seguinte
	# ainda estiver dentro: com FPS baixo a fita não fica mais curta.
	while _idade.size() >= 2 and _agora - _idade[_idade.size() - 2] > janela:
		_pa.remove_at(_pa.size() - 1)
		_pb.remove_at(_pb.size() - 1)
		_idade.remove_at(_idade.size() - 1)
	if not vivo and (_pa.size() < 2 or _agora - _idade[0] > janela):
		queue_free()
		return
	_im.clear_surfaces()
	var n := _pa.size()
	if n < 2 and not (vivo and n == 1):
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	# A cabeça acompanha o alvo neste quadro (sem degrau entre amostras).
	if vivo:
		_im.surface_set_uv(Vector2(0, 0))
		_im.surface_add_vertex(x * a)
		_im.surface_set_uv(Vector2(1, 0))
		_im.surface_add_vertex(x * b)
	for i in n:
		# V = idade da amostra na janela: 0 na cabeça, 1 na ponta da cauda.
		var v := clampf((_agora - _idade[i]) / janela, 0.0, 1.0)
		_im.surface_set_uv(Vector2(0, v))
		_im.surface_add_vertex(_pa[i])
		_im.surface_set_uv(Vector2(1, v))
		_im.surface_add_vertex(_pb[i])
	_im.surface_end()
