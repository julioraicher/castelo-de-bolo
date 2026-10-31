class_name Pilha
extends Node3D
## Pilha de madeira do castelo: onde o Construtor entrega as toras. A pilha
## cresce com o estoque do time (Game.madeira) e mostra o número em cima.
## Modelo do tema (ThemeConfig.pilha_model): nós "Nivel_1".."Nivel_N" (cada um
## vale TORAS_POR_NIVEL) e o marcador "Contador" onde fica o número.

const TORAS_POR_NIVEL := 3

var team := 0

var _label: Label3D
var _toras: Array[Node3D] = []  # provisória: 1 por tora; modelo: 1 por nível
var _por_item := 1
var _alt_label := 2.4
var _visto := -1
var _game: Game
var _anel: MeshInstance3D
var _placa: Sprite3D
var _t := 0.0


func setup(game: Game, p_team: int, pos: Vector3) -> void:
	team = p_team
	_game = game
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var th := game.arena.theme
	if th.pilha_model:
		var m: Node3D = th.pilha_model.instantiate()
		add_child(m)
		for i in range(1, 20):
			var n := m.find_child("Nivel_%d" % i, true, false) as Node3D
			if n == null:
				break
			_toras.append(n)
		_por_item = TORAS_POR_NIVEL
		var c := m.find_child("Contador", true, false) as Node3D
		if c:
			_alt_label = c.position.y
	else:
		_provisoria()
	_label = Label3D.new()
	_label.font = Estilo.LETREIRO
	_label.font_size = 56
	_label.pixel_size = 0.012
	_label.outline_size = 12
	_label.outline_modulate = Estilo.TINTA
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position.y = _alt_label
	add_child(_label)
	_sinalizar()
	atualizar(0)


## Placa do depósito (ícone de tora grande flutuando) e anel no chão do raio
## de entrega: o anel acende e pulsa quando o jogador chega com uma tora.
func _sinalizar() -> void:
	_placa = Sprite3D.new()
	_placa.texture = preload("res://assets/ui/icone_tora.png")
	_placa.pixel_size = 2.0 / maxf(_placa.texture.get_width(), 1.0)
	_placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_placa.no_depth_test = true
	_placa.position.y = _alt_label + 1.0
	add_child(_placa)
	_anel = MeshInstance3D.new()
	var tor := TorusMesh.new()
	var r := Config.cfg.pilha_raio
	tor.inner_radius = r - 0.12
	tor.outer_radius = r + 0.12
	tor.rings = 32
	tor.ring_segments = 4
	_anel.mesh = tor
	_anel.scale = Vector3(1, 0.25, 1)
	_anel.position.y = 0.06
	_anel.material_override = Fx.unshaded(Color(Config.team_color(team).lerp(Color(1, 0.75, 0.35), 0.5), 0.55), true)
	_anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_anel)


func _process(delta: float) -> void:
	_t += delta
	var p := _game.player if _game else null
	var meu := p != null and p.team == team
	var chamando := meu and p.carried_tora
	_placa.position.y = _alt_label + 1.0 + sin(_t * 2.5) * 0.15
	_placa.modulate = Color(1, 1, 1, 1.0 if meu else 0.6)
	var mat := _anel.material_override as StandardMaterial3D
	if chamando:
		var k := 0.5 + 0.5 * sin(_t * 7.0)
		mat.albedo_color = Color(1.0, 0.82, 0.36, 0.55 + 0.4 * k)
		_anel.scale = Vector3(1.0 + 0.06 * k, 0.25, 1.0 + 0.06 * k)
	else:
		mat.albedo_color = Color(Config.team_color(team).lerp(Color(1, 0.75, 0.35), 0.5), 0.4 if meu else 0.2)
		_anel.scale = Vector3(1, 0.25, 1)


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
	# Nível i aparece a partir da 1ª tora dele (ceil(n / por_item) níveis).
	for i in _toras.size():
		_toras[i].visible = i * _por_item < n
	_label.text = "DEPÓSITO · %d" % n
	_label.modulate = Color(1.0, 0.85, 0.55) if n > 0 else Color(0.8, 0.8, 0.8, 0.8)
	if cresceu:
		_label.scale = Vector3.ONE * 1.4
		_label.create_tween().tween_property(_label, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
