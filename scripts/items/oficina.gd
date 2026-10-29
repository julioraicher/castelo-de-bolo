class_name Oficina
extends Node3D
## Terreno de oficina no castelo. O time escolhe qual variação construir
## (jogador: [E] troca a opção; bots: escolha aleatória) e os Construtores
## erguem a casinha. Pronta, ela ganha um pedestal com o item da variação:
## é assim que o time libera Ronin Oni, Kitsune etc.
##
## Obra: d(progresso)/dt = Σ velocidade_obra / oficina_build_time, somando
## todos os Construtores do time a menos de BUILD_RADIUS.

enum Estado { VAZIO, OBRA, PRONTA }

const BUILD_RADIUS := 3.2

var team := 0
var estado := Estado.VAZIO
var progresso := 0.0
var opcao_i := 0
var pad: HatPad

var _game: Game
var _face := 0.0
var _label: Label3D
var _casa: Node3D
var _roof: Node3D
var _walls: Node3D
var _dust_t := 0.0


func setup(game: Game, p_team: int, pos: Vector3, opcao: int) -> void:
	_game = game
	team = p_team
	opcao_i = opcao
	position = pos
	_face = 0.0 if team == Config.TEAM_BLUE else PI
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # cresce por código
	_build_lot()
	_casa = _build_house()
	_casa.visible = false
	_walls.scale.y = 0.02
	_roof.visible = false
	add_child(_casa)
	_label = Label3D.new()
	_label.font = Estilo.FORTE
	_label.font_size = 44
	_label.pixel_size = 0.012
	_label.outline_size = 10
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 3.6
	add_child(_label)
	_update_label()


func opcao() -> ClassStats:
	var list := Config.cfg.oficina_classes
	return list[opcao_i % list.size()]


func trocar_opcao() -> void:
	if estado == Estado.PRONTA:
		return
	opcao_i = (opcao_i + 1) % Config.cfg.oficina_classes.size()
	progresso = 0.0
	estado = Estado.VAZIO
	_casa.visible = false
	Sfx.play("pickup", global_position, 0.1)
	_update_label()


func add_progress(frac: float, by: Unit) -> void:
	if estado == Estado.PRONTA:
		return
	progresso = minf(progresso + frac, 1.0)
	estado = Estado.OBRA
	_casa.visible = true
	if by:
		by.building_t = 0.25
	if progresso >= 1.0:
		_finish()


func _physics_process(delta: float) -> void:
	if estado == Estado.PRONTA or _game.game_over:
		return
	var rate := 0.0
	for u in _game.units:
		if u.alive and u.team == team and u.stats.velocidade_obra > 0.0 and not u.carried_princess \
				and u.global_position.distance_to(global_position) < BUILD_RADIUS:
			rate += u.stats.velocidade_obra
			u.building_t = 0.25
	if rate <= 0.0:
		return
	add_progress(rate * delta / Config.cfg.oficina_build_time, null)
	_walls.scale.y = maxf(progresso, 0.02)
	_dust_t -= delta
	if _dust_t <= 0.0:
		_dust_t = 0.35
		Fx.burst(_game, global_position + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)), Color(0.75, 0.65, 0.5), 4, 2.5)
		Sfx.play("swing", global_position, 0.3)
	_update_label()


func _finish() -> void:
	estado = Estado.PRONTA
	_walls.scale.y = 1.0
	_roof.visible = true
	_roof.position.y = 4.0
	var tw := _roof.create_tween()
	tw.tween_property(_roof, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): Fx.burst(_game, global_position + Vector3(0, 2.2, 0), Color(0.75, 0.65, 0.5), 16, 5.0))
	Fx.pillar(_game, global_position, Config.team_color(team).lightened(0.3), 3.0)
	Sfx.play("score", global_position, 0.05)
	pad = HatPad.new()
	_game.add_child(pad)
	var to_center := _game.arena.spawn_center[team] - global_position
	to_center.y = 0
	pad.setup(team, opcao(), global_position + to_center.normalized() * 3.2)
	_game.hat_pads.append(pad)
	_label.position.y = 4.6
	_update_label()
	_game.on_oficina_pronta(self)


func _update_label() -> void:
	var cls := opcao()
	_label.modulate = cls.hat_color.lightened(0.35)
	match estado:
		Estado.PRONTA:
			_label.text = "Oficina: %s" % cls.display_name
		Estado.OBRA:
			_label.text = "Obra: %s  %d%%" % [cls.display_name, int(progresso * 100.0)]
		_:
			_label.text = "Terreno: %s\n(Construtor constrói)" % cls.display_name


## Estacas nos cantos + chão de terra batida.
func _build_lot() -> void:
	var dirt := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 2.4
	c.bottom_radius = 2.5
	c.height = 0.06
	c.radial_segments = 6
	dirt.mesh = c
	dirt.position.y = 0.03
	dirt.material_override = Fx.lit(Color(0.42, 0.33, 0.24))
	add_child(dirt)
	var stake := CylinderMesh.new()
	stake.top_radius = 0.07
	stake.bottom_radius = 0.09
	stake.height = 0.9
	stake.radial_segments = 5
	var wood := Fx.lit(Color(0.55, 0.4, 0.22))
	for i in 6:
		var a := TAU * i / 6.0
		var s := MeshInstance3D.new()
		s.mesh = stake
		s.material_override = wood
		s.position = Vector3(cos(a) * 2.3, 0.45, sin(a) * 2.3)
		add_child(s)


## Casinha de oficina japonesa: base de madeira, telhado na cor do time e lanterna.
func _build_house() -> Node3D:
	var root := Node3D.new()
	var col := Config.team_color(team)
	_walls = Node3D.new()
	_roof = Node3D.new()
	root.add_child(_walls)
	root.add_child(_roof)
	# Base, paredes de papel (shoji) com vigas, e a viga do topo.
	var parts := [
		[root, _box(Vector3(3.0, 0.3, 3.0)), Vector3(0, 0.15, 0), Fx.lit(Color(0.3, 0.22, 0.16))],
		[_walls, _box(Vector3(2.6, 1.7, 2.6)), Vector3(0, 1.15, 0), Fx.lit(Color(0.9, 0.85, 0.72))],
		[_walls, _box(Vector3(2.7, 0.18, 2.7)), Vector3(0, 2.05, 0), Fx.lit(Color(0.25, 0.17, 0.12))],
	]
	for x in [-1.3, 1.3]:
		for z in [-1.3, 1.3]:
			parts.append([_walls, _box(Vector3(0.2, 1.9, 0.2)), Vector3(x, 1.15, z), Fx.lit(Color(0.25, 0.17, 0.12))])
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p[1]
		mi.position = p[2]
		mi.material_override = p[3]
		p[0].add_child(mi)
	var roof := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.2
	rc.bottom_radius = 2.4
	rc.height = 1.1
	rc.radial_segments = 4
	roof.mesh = rc
	roof.rotation.y = PI / 4
	roof.position.y = 2.65
	roof.material_override = Fx.lit(col.darkened(0.25))
	_roof.add_child(roof)
	var lamp := MeshInstance3D.new()
	var ls := SphereMesh.new()
	ls.radius = 0.22
	ls.height = 0.5
	lamp.mesh = ls
	lamp.position = Vector3(1.45, 1.6, 1.45)
	lamp.material_override = Fx.unshaded(col.lightened(0.3) * 1.6)
	_roof.add_child(lamp)
	return root


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b
