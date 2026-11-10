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
var _pa: PackedVector3Array = []
var _pb: PackedVector3Array = []
var _t := 0.0
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
	_t += delta
	if _t >= passo:
		_t = 0.0
		if vivo:
			var x := alvo.global_transform
			_pa.insert(0, x * a)
			_pb.insert(0, x * b)
		if _pa.size() > pontos or (not vivo and _pa.size() > 0):
			_pa.remove_at(_pa.size() - 1)
			_pb.remove_at(_pb.size() - 1)
	if not vivo and _pa.size() < 2:
		queue_free()
		return
	_im.clear_surfaces()
	var n := _pa.size()
	if n < 2:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	# A cabeça acompanha o alvo neste quadro (sem degrau entre amostras).
	if vivo:
		var x := alvo.global_transform
		_im.surface_set_uv(Vector2(0, 0))
		_im.surface_add_vertex(x * a)
		_im.surface_set_uv(Vector2(1, 0))
		_im.surface_add_vertex(x * b)
	for i in n:
		var v := float(i + 1) / float(pontos)
		_im.surface_set_uv(Vector2(0, v))
		_im.surface_add_vertex(_pa[i])
		_im.surface_set_uv(Vector2(1, v))
		_im.surface_add_vertex(_pb[i])
	_im.surface_end()
