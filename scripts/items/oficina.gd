class_name Oficina
extends Node3D
## Terreno de oficina no castelo. O time escolhe qual variação construir
## (jogador: [E] troca a opção; bots: escolha aleatória) e os Construtores
## erguem a casinha. Pronta, ela ganha um pedestal com o item da variação:
## é assim que o time libera Ronin Oni, Kitsune etc.
##
## Obra: d(progresso)/dt = Σ velocidade_obra / oficina_build_time, somando
## todos os Construtores do time a menos de BUILD_RADIUS, mas o progresso não
## passa de madeira_entregue / oficina_custo_madeira (Ciclo 2.3). Quem está na
## obra puxa 1 madeira do estoque do time a cada oficina_puxar_intervalo / Σv s.
## Em cima, o contador "faltam N" + barra (grande para quem joga de Construtor).

enum Estado { VAZIO, OBRA, PRONTA }

const BUILD_RADIUS := 3.2

var team := 0
var estado := Estado.VAZIO
var progresso := 0.0
var opcao_i := 0
var pad: HatPad
var madeira_entregue := 0
## Obra parada porque o time não tem madeira (o contador pisca).
var falta_madeira := false

var _game: Game
var _face := 0.0
var _label: Label3D
var _casa: Node3D
var _roof: Node3D
var _walls: Node3D
var _dust_t := 0.0
## Casa do tema (ThemeConfig.oficina_model): as peças "Gira_*" giram pelo
## relógio próprio (pintura.gdshader, `relogio`), que anda na velocidade da obra.
var _mats_gira: Array[ShaderMaterial] = []
var _relogio := 0.0
var _ritmo := 0.0
var _alt_label := 3.6
var _puxar_t := 0.0
var _barra: Node3D
var _barra_fill: MeshInstance3D
var _barra_mad: MeshInstance3D


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
	_label.position.y = _alt_label
	add_child(_label)
	_build_barra()
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


func custo() -> int:
	return Config.cfg.oficina_custo_madeira


func faltam() -> int:
	return maxi(custo() - madeira_entregue, 0)


## Teto da obra: a fração de madeira já entregue.
func teto() -> float:
	return 1.0 if custo() <= 0 else float(madeira_entregue) / custo()


## Puxa 1 madeira do estoque do time para a obra. false = sem estoque ou já cheia.
func puxar_madeira() -> bool:
	if estado == Estado.PRONTA or faltam() <= 0 or not _game.gastar_madeira(team, 1):
		return false
	madeira_entregue += 1
	if is_inside_tree():
		Fx.burst(_game, global_position + Vector3(0, 0.6, 0), Color(0.7, 0.5, 0.25), 5, 2.5)
	return true


func add_progress(frac: float, by: Unit) -> void:
	if estado == Estado.PRONTA:
		return
	progresso = minf(progresso + frac, teto())
	estado = Estado.OBRA
	_casa.visible = true
	if by:
		by.building_t = 0.25
	if progresso >= 1.0 - 1e-6:
		progresso = 1.0
		_finish()


func _physics_process(delta: float) -> void:
	if estado == Estado.PRONTA or _game.game_over:
		return
	var rate := 0.0
	for u in _game.units:
		if u.alive and u.team == team and u.stats.velocidade_obra > 0.0 and not u.carried_princess \
				and not u.carried_tora and u.global_position.distance_to(global_position) < BUILD_RADIUS:
			rate += u.stats.velocidade_obra
			u.building_t = 0.25
	_ritmo = rate
	if rate <= 0.0:
		falta_madeira = false
		_update_label()
		return
	_puxar_t -= delta * rate
	if _puxar_t <= 0.0 and faltam() > 0:
		if puxar_madeira():
			_puxar_t = Config.cfg.oficina_puxar_intervalo
	falta_madeira = faltam() > 0 and progresso >= teto() - 1e-4 and _game.madeira[team] <= 0
	if progresso >= teto() - 1e-4:
		_update_label()
		return  # esperando madeira: sem poeira nem martelada
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
	# Ao lado da casa, do lado do portão: atrás dela (z menor) a câmera não vê.
	var lado := signf(_game.arena.spawn_center[team].x - global_position.x)
	pad.setup(team, opcao(), global_position + Vector3(lado * 3.0, 0, 0))
	_game.hat_pads.append(pad)
	_label.position.y = _alt_label + 1.0
	_update_label()
	_game.on_oficina_pronta(self)


func _update_label() -> void:
	var cls := opcao()
	var txt := ""
	var cor := cls.hat_color.lightened(0.35)
	match estado:
		Estado.PRONTA:
			txt = "Oficina: %s" % cls.display_name
		_:
			txt = "%s\nMadeira: faltam %d" % [cls.display_name, faltam()] if faltam() > 0 \
					else "%s\nObra %d%%" % [cls.display_name, int(progresso * 100.0)]
			if falta_madeira:
				txt = "%s\nFALTA MADEIRA (faltam %d)" % [cls.display_name, faltam()]
				cor = Color(1, 0.45, 0.35) if Time.get_ticks_msec() % 600 < 300 else Color(1, 0.85, 0.6)
	if _label.text != txt:
		_label.text = txt
	_label.modulate = cor
	# Grande para quem joga de Construtor, pequeno nas outras classes.
	var p := _game.player
	var grande := p != null and p.team == team and p.stats.velocidade_obra > 0.0
	var esc := 1.35 if grande else 0.8
	_label.scale = Vector3.ONE * esc
	if _barra:
		_barra.visible = estado != Estado.PRONTA
		_barra.scale = Vector3.ONE * esc
		_barra.position.y = _label.position.y - 0.75 * esc
		# Barra: madeira entregue (fundo claro) e obra (cheia).
		_barra_fill.scale.x = maxf(progresso, 0.001)
		_barra_mad.scale.x = maxf(teto(), 0.001)


## Barrinha da obra em cima do terreno: fundo, madeira entregue e progresso.
func _build_barra() -> void:
	_barra = Node3D.new()
	add_child(_barra)
	var partes := []
	for cfg in [[Color(0, 0, 0, 0.6), 0.22, 0], [Color(0.75, 0.55, 0.3), 0.16, 1], [Config.team_color(team).lightened(0.3), 0.16, 2]]:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(2.0, cfg[1])
		q.center_offset = Vector3(1.0, 0, 0.01 * cfg[2])
		mi.mesh = q
		var m := Fx.unshaded(cfg[0], cfg[2] == 0)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.billboard_keep_scale = true
		m.no_depth_test = true
		m.render_priority = cfg[2]
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position.x = -1.0
		_barra.add_child(mi)
		partes.append(mi)
	_barra_mad = partes[1]
	_barra_fill = partes[2]


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


func _process(delta: float) -> void:
	if _mats_gira.is_empty() or not _casa.visible:
		return
	# Pronta: gira devagar sozinha. Em obra: na velocidade dos Construtores.
	_relogio += delta * (0.6 if estado == Estado.PRONTA else _ritmo)
	for m in _mats_gira:
		m.set_shader_parameter("relogio", _relogio)


## Casa do tema: o corpo cresce com a obra, o "Telhado" cai no fim e as peças
## "Gira_*" ganham material próprio (o relógio é desta oficina).
func _casa_do_tema(path: String) -> Node3D:
	var root := Node3D.new()
	var casa: Node3D = (load(path) as PackedScene).instantiate()
	root.add_child(casa)
	_walls = casa
	_roof = casa.get_node_or_null("Telhado")
	if _roof:
		casa.remove_child(_roof)  # não achata junto com as paredes
		_roof.owner = null
		for n in _roof.find_children("*", "", true, false):
			n.owner = null
	else:
		_roof = Node3D.new()
	root.add_child(_roof)
	var contorno := Settings.quality >= 3
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var gira := mi.name.begins_with("Gira_")
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as ShaderMaterial
			if mat == null or (not gira and (contorno or mat.next_pass == null)):
				continue
			var m: ShaderMaterial = mat.duplicate()
			m.next_pass = (mat.next_pass.duplicate() as ShaderMaterial) if contorno and mat.next_pass else null
			mi.set_surface_override_material(s, m)
			if gira:
				_mats_gira.append(m)
				if m.next_pass:
					_mats_gira.append(m.next_pass)
	_alt_label = 5.6
	return root


## Casinha de oficina japonesa: base de madeira, telhado na cor do time e lanterna.
func _build_house() -> Node3D:
	var th := _game.arena.theme
	if th.oficina_model != "" and ResourceLoader.exists(th.model_path(th.oficina_model, team)):
		return _casa_do_tema(th.model_path(th.oficina_model, team))
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
