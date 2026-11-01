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
## Em cima, o contador "NN% · faltam N" + barra (dourado = madeira entregue,
## claro = já construído), grande para quem joga de Construtor. O progresso
## fica guardado na casinha: quem volta (ele ou um aliado) continua dali, e a
## opção do terreno trava assim que a obra começa.
##
## Caminho dos magos (caminho >= 0): terreno fixo de um dos magos opostos.
## Começar um sela o do outro lado (selada) pelo resto da partida; pronto, ele
## está no nível 2 e sobe com madeira (GameConfig.mago_nivel_custo) até o 5.

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
## Caminho dos magos: -1 = terreno comum; 0/1 = índice em magos_opostos.
var caminho := -1
## O time escolheu o outro caminho: este terreno nunca será construído.
var selada := false
## Nível do mago (2 ao ficar pronta; sobe até mago_nivel_max com madeira).
var nivel := 1
var madeira_nivel := 0
var _lista: Array[ClassStats] = []
var _selo: Node3D
var _titulo: Label3D
var _bandeira: Node3D

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
var _contador: ContadorMadeira


func setup(game: Game, p_team: int, pos: Vector3, opcao: int, lista: Array[ClassStats] = [], p_caminho := -1) -> void:
	_game = game
	team = p_team
	opcao_i = opcao
	_lista = lista
	caminho = p_caminho
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
	_contador = ContadorMadeira.new()
	add_child(_contador)
	if caminho >= 0:
		_montar_placa()
	_update_label()


## Nome curto do caminho ("Luz", "Sombra").
func nome_caminho() -> String:
	var n := Config.cfg.magos_caminho_nomes
	return n[caminho] if caminho >= 0 and caminho < n.size() else opcao().display_name


## Terreno de mago: estandarte (nobori) na cor do mago, de pé desde o começo
## para os dois lados do castelo se lerem de longe, e o título a pincel.
func _montar_placa() -> void:
	var cor := opcao().hat_color
	var lado := -1.0 if position.z < 0.0 else 1.0  # para fora, longe do pátio
	_bandeira = Node3D.new()
	_bandeira.position = Vector3(1.9, 0, lado * 1.9)
	add_child(_bandeira)
	var mastro := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.05
	m.bottom_radius = 0.07
	m.height = 3.6
	mastro.mesh = m
	mastro.position.y = 1.8
	mastro.material_override = Fx.lit(Color(0.22, 0.15, 0.1))
	_bandeira.add_child(mastro)
	var pano := MeshInstance3D.new()
	pano.name = "Pano"
	pano.mesh = _box(Vector3(0.04, 2.1, 0.75))
	pano.position = Vector3(0, 2.35, 0.42)
	pano.material_override = Fx.lit(cor.darkened(0.15))
	_bandeira.add_child(pano)
	var faixa := MeshInstance3D.new()
	faixa.mesh = _box(Vector3(0.05, 0.22, 0.8))
	faixa.position = Vector3(0, 3.3, 0.42)
	faixa.material_override = Fx.unshaded(cor.lightened(0.45))
	_bandeira.add_child(faixa)
	_titulo = Label3D.new()
	_titulo.font = Estilo.TITULO
	_titulo.font_size = 64
	_titulo.pixel_size = 0.011
	_titulo.outline_size = 14
	_titulo.outline_modulate = Estilo.TINTA
	_titulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_titulo.text = nome_caminho()
	_titulo.modulate = cor.lightened(0.4)
	add_child(_titulo)
	_alt_label = 3.2
	_label.font = Estilo.FORTE
	_label.font_size = 46
	_label.pixel_size = 0.01
	_label.outline_modulate = Estilo.TINTA


func opcao() -> ClassStats:
	var list := _lista if not _lista.is_empty() else Config.cfg.oficina_classes
	return list[opcao_i % list.size()]


## A obra começou (tem progresso ou madeira): a opção fica travada e o
## progresso é guardado para quem voltar, o mesmo Construtor ou um aliado.
func comecada() -> bool:
	return estado != Estado.VAZIO or progresso > 0.0 or madeira_entregue > 0


## Troca a variação do terreno. Só antes de a obra começar: depois disso o
## [E] não apaga nada. Devolve true se trocou.
func trocar_opcao() -> bool:
	if comecada() or caminho >= 0:
		return false
	opcao_i = (opcao_i + 1) % (_lista.size() if not _lista.is_empty() else Config.cfg.oficina_classes.size())
	Sfx.play("pickup", global_position, 0.1)
	_update_label()
	return true


func custo() -> int:
	return Config.cfg.oficina_custo_madeira


func faltam() -> int:
	return maxi(custo() - madeira_entregue, 0)


## Teto da obra: a fração de madeira já entregue.
func teto() -> float:
	return 1.0 if custo() <= 0 else float(madeira_entregue) / custo()


## Puxa 1 madeira do estoque do time para a obra. false = sem estoque ou já cheia.
func puxar_madeira() -> bool:
	if selada or estado == Estado.PRONTA or faltam() <= 0 or not _game.gastar_madeira(team, 1):
		return false
	madeira_entregue += 1
	_game.on_obra_comecou(self)
	if is_inside_tree():
		Fx.burst(_game, global_position + Vector3(0, 0.6, 0), Color(0.7, 0.5, 0.25), 5, 2.5)
	return true


func add_progress(frac: float, by: Unit) -> void:
	if estado == Estado.PRONTA or selada:
		return
	_game.on_obra_comecou(self)
	progresso = minf(progresso + frac, teto())
	estado = Estado.OBRA
	_casa.visible = true
	_walls.scale.y = maxf(progresso, 0.02)
	if by:
		by.building_t = 0.25
	if progresso >= 1.0 - 1e-6:
		progresso = 1.0
		_finish()


## Σ velocidade_obra dos Construtores do time na obra (e os marca construindo).
func _ritmo_obra() -> float:
	var rate := 0.0
	for u in _game.units:
		if u.alive and u.team == team and u.stats.velocidade_obra > 0.0 and not u.carried_princess \
				and not u.carried_tora and u.global_position.distance_to(global_position) < BUILD_RADIUS:
			rate += u.stats.velocidade_obra
			u.building_t = 0.25
	return rate


func _physics_process(delta: float) -> void:
	if selada or _game.game_over:
		return
	if estado == Estado.PRONTA:
		if pode_subir():
			_obra_nivel(delta)
		return
	var rate := _ritmo_obra()
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
	_dust_t -= delta
	if _dust_t <= 0.0:
		_dust_t = 0.35
		Fx.burst(_game, global_position + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)), Color(0.75, 0.65, 0.5), 4, 2.5)
		Sfx.play("swing", global_position, 0.3)
	_update_label()


# --- Caminho dos magos: selo e níveis 3 a 5 -----------------------------------

## Oficina de mago pronta e abaixo do nível máximo: aceita madeira para subir.
func pode_subir() -> bool:
	return caminho >= 0 and estado == Estado.PRONTA and not selada and nivel < Config.cfg.mago_nivel_max


func custo_nivel() -> int:
	var c := Config.cfg.mago_nivel_custo
	var i := nivel - 2
	return c[clampi(i, 0, c.size() - 1)] if not c.is_empty() else 0


func faltam_nivel() -> int:
	return maxi(custo_nivel() - madeira_nivel, 0) if pode_subir() else 0


## Puxa 1 madeira do estoque para o próximo nível; a última sobe o nível.
func puxar_madeira_nivel() -> bool:
	if not pode_subir() or not _game.gastar_madeira(team, 1):
		return false
	madeira_nivel += 1
	if is_inside_tree():
		Fx.burst(_game, global_position + Vector3(0, 1.2, 0), opcao().hat_color.lightened(0.3), 5, 2.5)
	if faltam_nivel() <= 0:
		subir_nivel()
	return true


func subir_nivel() -> void:
	nivel += 1
	madeira_nivel = 0
	if pad:
		pad.estoque_max += 1
		pad.intervalo *= Config.cfg.mago_pad_intervalo_mult
		pad.estoque = mini(pad.estoque + 1, pad.estoque_max)
	if is_inside_tree():
		var cor := opcao().hat_color.lightened(0.3)
		Fx.pillar(_game, global_position, cor, 2.6 + 0.4 * nivel)
		FxPoder.subir_nivel(_game, global_position, cor, nivel)
		Sfx.play("nivel", global_position, 0.02)
		var tw := _casa.create_tween()
		var esc := Vector3.ONE * (1.0 + 0.06 * (nivel - 2))
		tw.tween_property(_casa, "scale", esc * 1.15, 0.15)
		tw.tween_property(_casa, "scale", esc, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_update_label()
	_game.on_mago_nivel(self)


func _obra_nivel(delta: float) -> void:
	var rate := _ritmo_obra()
	_ritmo = rate
	if rate > 0.0:
		_puxar_t -= delta * rate
		if _puxar_t <= 0.0 and puxar_madeira_nivel():
			_puxar_t = Config.cfg.oficina_puxar_intervalo
	falta_madeira = rate > 0.0 and _game.madeira[team] <= 0
	_update_label()


## O time escolheu o caminho oposto: o terreno ganha a corda de selo
## (shimenawa com papéis) e some das obras para sempre.
func selar() -> void:
	if selada or comecada():
		return
	selada = true
	_selo = Node3D.new()
	add_child(_selo)
	var corda := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 2.18
	t.outer_radius = 2.36
	t.rings = 24
	t.ring_segments = 6
	corda.mesh = t
	corda.position.y = 0.72
	corda.material_override = Fx.lit(Color(0.78, 0.68, 0.45))
	_selo.add_child(corda)
	var papel := Fx.unshaded(Color(0.95, 0.93, 0.86))
	for i in 6:
		var a := TAU * (i + 0.5) / 6.0
		var f := MeshInstance3D.new()
		f.mesh = _box(Vector3(0.22, 0.42, 0.02))
		f.material_override = papel
		f.position = Vector3(cos(a) * 2.27, 0.48, sin(a) * 2.27)
		f.rotation.y = -a + PI / 2
		_selo.add_child(f)
	if is_inside_tree():
		Fx.burst(_game, global_position + Vector3(0, 0.8, 0), Color(0.5, 0.45, 0.6), 12, 3.0)
	if _bandeira:
		# Estandarte tombado e apagado: este caminho não volta mais.
		_bandeira.create_tween().tween_property(_bandeira, "rotation:x", deg_to_rad(-62.0) * signf(position.z if position.z != 0.0 else 1.0), 0.6) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		var pano := _bandeira.get_node("Pano") as MeshInstance3D
		pano.material_override = Fx.lit(opcao().hat_color.darkened(0.7).lerp(Color(0.3, 0.3, 0.32), 0.5))
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
	if caminho >= 0:
		nivel = 2
	_label.position.y = _alt_label + (0.4 if _titulo else 1.0)
	_update_label()
	_game.on_oficina_pronta(self)


func _update_label() -> void:
	var cls := opcao()
	var txt := "Oficina: %s" % cls.display_name
	if estado != Estado.PRONTA:
		txt = "Obra: %s" % cls.display_name if comecada() else "Terreno: %s" % cls.display_name
	if caminho >= 0:
		txt = _texto_caminho(cls)
	if _label.text != txt:
		_label.text = txt
	if estado != Estado.PRONTA:
		# O letreiro acompanha a altura da obra: perto do Construtor (e longe
		# do placar no alto da tela) enquanto a casa ainda é baixa.
		_label.position.y = lerpf(2.6, _alt_label, progresso)
	_label.modulate = Estilo.TEXTO_FRACO if selada else cls.hat_color.lightened(0.35)
	if _titulo:
		_titulo.position.y = _label.position.y + 0.75
		_titulo.modulate = Estilo.TEXTO_FRACO.darkened(0.25) if selada else cls.hat_color.lightened(0.4)
		_titulo.text = nome_caminho()
	# Contador de madeira: grande para quem joga de Construtor, pequeno nas
	# outras classes; pisca "falta madeira" quando o time não tem estoque.
	_contador.visible = estado != Estado.PRONTA and not selada
	if pode_subir():
		var p := _game.player
		var perto := p != null and p.team == team and p.global_position.distance_to(global_position) < BUILD_RADIUS + 2.0
		_contador.visible = madeira_nivel > 0 or perto
		if _contador.visible:
			_contador.position.y = _label.position.y + (1.75 if _titulo else 0.9)
			_contador.mostrar(faltam_nivel(), custo_nivel(), p != null and p.lenhador(), falta_madeira)
		return
	if _contador.visible:
		var p := _game.player
		var grande := p != null and p.team == team and p.lenhador()
		_contador.position.y = _label.position.y + (1.0 if grande else 0.7) + (0.8 if _titulo else 0.0)
		_contador.mostrar(faltam(), custo(), grande, falta_madeira or (faltam() > 0 and _game.madeira[team] <= 0), progresso if comecada() else -1.0)


## Letreiro do terreno de mago: o caminho, o selo ou o nível.
func _texto_caminho(cls: ClassStats) -> String:
	if selada:
		return "SELADO"
	if estado == Estado.PRONTA:
		var mx := Config.cfg.mago_nivel_max
		return "%s · NÍVEL %d/%d" % [cls.display_name.to_upper(), nivel, mx]
	var outro := _game.mago_oposto(self)
	var nome_outro := outro.nome_caminho() if outro else "o outro"
	if comecada():
		return "%s · %s SELADA" % [cls.display_name.to_upper(), nome_outro.to_upper()]
	return "%s · SELA A %s" % [cls.display_name.to_upper(), nome_outro.to_upper()]


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
