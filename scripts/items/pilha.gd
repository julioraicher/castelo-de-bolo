class_name Pilha
extends Node3D
## Pilha de madeira do castelo: onde o Construtor entrega as toras. A pilha
## cresce com o estoque do time (Game.madeira) e mostra o número em cima.

const MAX_VISIVEL := 12

var team := 0

var _label: Label3D
var _toras: Array[Node3D] = []
var _visto := -1


func setup(game: Game, p_team: int, pos: Vector3) -> void:
	team = p_team
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var th := game.arena.theme
	if th.pilha_model:
		var m: Node3D = th.pilha_model.instantiate()
		add_child(m)
		for n in m.find_children("Tora_*", "Node3D", true, false):
			_toras.append(n)
		_toras.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	else:
		_provisoria()
	_label = Label3D.new()
	_label.font = Estilo.FORTE
	_label.font_size = 56
	_label.pixel_size = 0.012
	_label.outline_size = 12
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position.y = 2.4
	add_child(_label)
	atualizar(0)


## Estrado de madeira e 12 toras empilhadas (3-3-2-2-1-1), escondidas até o estoque chegar.
func _provisoria() -> void:
	var base := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(2.0, 0.12, 1.6)
	base.mesh = b
	base.position.y = 0.06
	base.material_override = Fx.lit(Config.team_color(team).lerp(Color(0.35, 0.25, 0.15), 0.7))
	add_child(base)
	var camadas := [3, 3, 2, 2, 1, 1]
	var y := 0.32
	for n in camadas:
		for i in n:
			var t := Tora.make_visual()
			t.rotation.y = PI / 2
			t.scale = Vector3.ONE * 0.95
			t.position = Vector3((i - (n - 1) / 2.0) * 0.42, y, 0)
			add_child(t)
			_toras.append(t)
		y += 0.34


func atualizar(n: int) -> void:
	if n == _visto:
		return
	var cresceu := n > _visto and _visto >= 0
	_visto = n
	for i in _toras.size():
		_toras[i].visible = i < n
	_label.text = "Madeira %d" % n
	_label.modulate = Color(1.0, 0.85, 0.55) if n > 0 else Color(0.8, 0.8, 0.8, 0.8)
	if cresceu:
		_label.scale = Vector3.ONE * 1.4
		_label.create_tween().tween_property(_label, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
