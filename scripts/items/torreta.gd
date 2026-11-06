class_name Torreta
extends Node3D
## Torreta de defesa do Construtor (Ciclo 2.9, piloto). Fica num terreno fixo
## na frente do castelo (MapLayout.torreta_spots). Construtor por perto ergue
## com madeira do time, como as oficinas: d(progresso)/dt = Σv / torreta_obra.
## Pronta, atira um virote no inimigo mais perto a até torreta_alcance m.
##
## Defesa (botão direito) contra torreta: o escudo segura torreta_bloqueio do
## dano; erguido na janela do contra-golpe (parry_janela), o virote VOLTA e
## acerta a própria torreta (torreta_devolve × dano). Esquiva atravessa.
## Golpes e tiros inimigos derrubam a torreta; caída, o terreno volta a vazio.

enum Estado { VAZIO, OBRA, PRONTA }

const RAIO_OBRA := 3.0
const RAIO_CORPO := 1.0  # para golpes e tiros acertarem a torreta
const ALTURA_ARMA := 2.6

var team := 0
var estado := Estado.VAZIO
var progresso := 0.0
var madeira_entregue := 0
var hp := 0.0

var _game: Game
var _casa: Node3D
var _arma: Node3D
var _label: Label3D
var _tiro_t := 0.0
var _puxar_t := 0.0
var _dust_t := 0.0
var _flash_t := 0.0
var _mats: Array[StandardMaterial3D] = []


func setup(game: Game, p_team: int, pos: Vector3) -> void:
	_game = game
	team = p_team
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_montar_terreno()
	_casa = _montar_torre()
	add_child(_casa)
	_label = Label3D.new()
	_label.font = Estilo.LETREIRO
	_label.font_size = 40
	_label.pixel_size = 0.011
	_label.outline_size = 10
	_label.outline_modulate = Estilo.TINTA
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 4.4
	add_child(_label)
	_zerar()


func max_hp() -> float:
	return Config.cfg.torreta_vida * Config.cfg.vida_mult


func custo() -> int:
	return Config.cfg.torreta_custo


func faltam() -> int:
	return maxi(custo() - madeira_entregue, 0)


func pronta() -> bool:
	return estado == Estado.PRONTA


## Terreno vazio de novo (começo da partida ou torreta derrubada).
func _zerar() -> void:
	estado = Estado.VAZIO
	progresso = 0.0
	madeira_entregue = 0
	hp = 0.0
	_casa.visible = false
	_casa.scale = Vector3(1, 0.05, 1)
	_atualizar_label()


func _physics_process(delta: float) -> void:
	if _game.game_over:
		return
	if _flash_t > 0.0:
		_flash_t -= delta
		for m in _mats:
			m.emission_enabled = _flash_t > 0.0
	if estado == Estado.PRONTA:
		_atirar(delta)
		return
	_obra(delta)


# --- Obra -----------------------------------------------------------------------

func _obra(delta: float) -> void:
	var rate := 0.0
	for u in _game.units:
		if u.alive and u.team == team and u.lenhador() and not u.carried_princess and not u.carried_tora \
				and u.global_position.distance_to(global_position) < RAIO_OBRA:
			rate += u.stats.velocidade_obra
			u.building_t = 0.25
	if rate <= 0.0:
		return
	_puxar_t -= delta * rate
	if _puxar_t <= 0.0 and faltam() > 0 and _game.gastar_madeira(team, 1):
		madeira_entregue += 1
		_puxar_t = Config.cfg.oficina_puxar_intervalo
		Fx.burst(_game, global_position + Vector3(0, 0.6, 0), Color(0.7, 0.5, 0.25), 5, 2.5)
	var teto := float(madeira_entregue) / maxf(custo(), 1)
	if progresso >= teto - 1e-4:
		_atualizar_label()
		return
	add_progress(rate * delta / Config.cfg.torreta_obra)
	_dust_t -= delta
	if _dust_t <= 0.0:
		_dust_t = 0.35
		Fx.burst(_game, global_position + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)), Color(0.75, 0.65, 0.5), 4, 2.5)
		Sfx.play("swing", global_position, 0.3)


## Construtor chegou com a tora nos braços: ela vira madeira da torreta.
func receber_tora(u: Unit) -> void:
	var t := u.carried_tora
	if t == null or faltam() <= 0:
		return
	u.carried_tora = null
	_game.toras.erase(t)
	t.queue_free()
	madeira_entregue += 1
	if estado == Estado.VAZIO:
		estado = Estado.OBRA
		_casa.visible = true
	Sfx.play("pickup", global_position, 0.05)
	Fx.burst(_game, global_position + Vector3(0, 0.8, 0), Color(0.9, 0.7, 0.4), 8, 3.0)
	if u.is_player:
		_game.hud.show_big("+1 madeira na torreta  ·  faltam %d" % faltam(), Color(1, 0.8, 0.5), 0.9)
	_atualizar_label()


func add_progress(frac: float) -> void:
	if estado == Estado.PRONTA:
		return
	var teto := float(madeira_entregue) / maxf(custo(), 1)
	progresso = minf(progresso + frac, teto)
	estado = Estado.OBRA
	_casa.visible = true
	_casa.scale = Vector3(1, maxf(progresso, 0.05), 1)
	if progresso >= 1.0 - 1e-6:
		_concluir()
	else:
		_atualizar_label()


func _concluir() -> void:
	_game._log("TORRETA %s pronta (t=%.0fs)" % [Config.TEAM_NAMES[team], _game._time])
	estado = Estado.PRONTA
	progresso = 1.0
	hp = max_hp()
	_casa.scale = Vector3.ONE
	_tiro_t = 0.6
	Fx.pillar(_game, global_position, Config.team_color(team).lightened(0.3), 2.0)
	Sfx.play("score", global_position, 0.05)
	_atualizar_label()


## Modo teste e testes de regra: pronta na hora.
func concluir_ja() -> void:
	madeira_entregue = custo()
	_casa.visible = true
	_concluir()


# --- Tiro -----------------------------------------------------------------------

func _alvo() -> Unit:
	var best: Unit = null
	var best_d := Config.cfg.torreta_alcance
	for u in _game.units:
		if not u.alive or u.team == team or u._sombra_t > 0.0:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 4.0:
			continue
		d.y = 0
		if d.length() < best_d:
			best_d = d.length()
			best = u
	return best


func _atirar(delta: float) -> void:
	var alvo := _alvo()
	if alvo:
		var to := alvo.global_position - global_position
		_arma.rotation.y = lerp_angle(_arma.rotation.y, atan2(to.x, to.z), minf(delta * 10.0, 1.0))
	_tiro_t -= delta
	if alvo == null or _tiro_t > 0.0:
		return
	_tiro_t = Config.cfg.torreta_cadencia
	var v := Virote.new()
	_game.add_child(v)
	v.setup(_game, self, global_position + Vector3(0, ALTURA_ARMA, 0), alvo)
	Sfx.play("shoot", global_position, 0.1)


# --- Dano na torreta ----------------------------------------------------------------

func take_hit(amount: float, from_team: int) -> void:
	if estado != Estado.PRONTA or from_team == team:
		return
	hp -= amount
	_flash_t = 0.1
	for m in _mats:
		m.emission_enabled = true
	Fx.damage_number(_game, global_position + Vector3(0, 2.5, 0), str(int(amount)), Color(1, 0.85, 0.6))
	Fx.burst(_game, global_position + Vector3(0, 1.6, 0), Color(0.6, 0.45, 0.3), 6, 4.0)
	if hp <= 0.0:
		Fx.burst(_game, global_position + Vector3(0, 1.2, 0), Color(0.55, 0.4, 0.25), 30, 7.0)
		_game.camera.shake_at(global_position, 0.4)
		Sfx.play("explosao", global_position, 0.1)
		_zerar()
	else:
		_atualizar_label()


## Alvo de golpe/tiro: horizontal a até RAIO_CORPO + r e na altura do corpo.
func encosta(p: Vector3, r: float) -> bool:
	if estado != Estado.PRONTA:
		return false
	var d := p - global_position
	if d.y < -0.5 or d.y > 3.5:
		return false
	d.y = 0
	return d.length() <= RAIO_CORPO + r


# --- Visual (provisório: primitivas, aguardando o pitaco do Julio) ---------------

func _atualizar_label() -> void:
	match estado:
		Estado.VAZIO:
			_label.text = "Torreta · %d madeiras" % custo() if madeira_entregue == 0 else "Torreta · faltam %d" % faltam()
			_label.modulate = Color(1, 1, 1, 0.75)
		Estado.OBRA:
			_label.text = "Torreta %d%% · faltam %d" % [roundi(progresso * 100.0), faltam()]
			_label.modulate = Color(1, 0.9, 0.6)
		Estado.PRONTA:
			_label.text = "Torreta %d/%d" % [ceili(hp), int(max_hp())]
			_label.modulate = Config.team_color(team).lightened(0.4)
	_label.visible = estado != Estado.PRONTA or hp < max_hp()


func _mat(c: Color) -> StandardMaterial3D:
	var m := Fx.lit(c)
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = 0.6
	_mats.append(m)
	return m


func _montar_terreno() -> void:
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 1.3
	t.outer_radius = 1.5
	anel.mesh = t
	anel.scale = Vector3(1, 0.05, 1)
	anel.position.y = 0.05
	anel.material_override = Fx.unshaded(Color(Config.team_color(team), 0.5), true)
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anel)


func _montar_torre() -> Node3D:
	var raiz := Node3D.new()
	var pedra := Color(0.42, 0.4, 0.38)
	var madeira := Color(0.45, 0.3, 0.18)
	var cor := Config.team_color(team)
	var base := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.85
	cil.bottom_radius = 1.05
	cil.height = 1.2
	base.mesh = cil
	base.position.y = 0.6
	base.material_override = _mat(pedra)
	raiz.add_child(base)
	for i in 4:  # pernas de madeira
		var perna := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.18, 1.3, 0.18)
		perna.mesh = bx
		var a := TAU * (i + 0.5) / 4.0
		perna.position = Vector3(cos(a) * 0.55, 1.8, sin(a) * 0.55)
		perna.material_override = _mat(madeira)
		raiz.add_child(perna)
	var piso := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(1.6, 0.16, 1.6)
	piso.mesh = pb
	piso.position.y = 2.45
	piso.material_override = _mat(madeira)
	raiz.add_child(piso)
	var teto := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 1.15
	cone.height = 0.8
	cone.radial_segments = 4
	teto.mesh = cone
	teto.position.y = 3.65
	teto.rotation.y = PI / 4.0
	teto.material_override = _mat(cor.darkened(0.35))
	raiz.add_child(teto)
	# Besta que gira para o alvo.
	_arma = Node3D.new()
	_arma.position.y = ALTURA_ARMA + 0.15
	raiz.add_child(_arma)
	var corpo := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.18, 0.18, 1.1)
	corpo.mesh = cb
	corpo.position.z = 0.25
	corpo.material_override = _mat(madeira.darkened(0.2))
	_arma.add_child(corpo)
	var arco := MeshInstance3D.new()
	var ab := BoxMesh.new()
	ab.size = Vector3(1.0, 0.1, 0.1)
	arco.mesh = ab
	arco.position.z = 0.65
	arco.material_override = _mat(cor)
	_arma.add_child(arco)
	return raiz


## Virote da torreta: voa reto (corrigindo a mira um pouco) até o alvo.
class Virote extends Node3D:
	const VEL := 24.0
	var _game: Game
	var _dono: Torreta
	var _alvo: Unit
	var _dir := Vector3.FORWARD
	var _vida := 1.6
	var _volta := false

	func setup(game: Game, dono: Torreta, origem: Vector3, alvo: Unit) -> void:
		_game = game
		_dono = dono
		_alvo = alvo
		position = origem
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_dir = (alvo.global_position + Vector3(0, 1.1, 0) - origem).normalized()
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.08, 0.08, 0.7)
		mi.mesh = b
		mi.material_override = Fx.unshaded(Config.team_color(dono.team).lightened(0.5))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

	func _physics_process(delta: float) -> void:
		_vida -= delta
		if _vida <= 0.0 or not is_instance_valid(_dono):
			queue_free()
			return
		if _volta:
			var to_t := _dono.global_position + Vector3(0, 1.8, 0) - global_position
			_dir = to_t.normalized()
			if to_t.length() < 0.8:
				_dono.take_hit(Config.cfg.torreta_dano * Config.cfg.torreta_devolve, -1)
				queue_free()
				return
		elif is_instance_valid(_alvo) and _alvo.alive:
			var to := _alvo.global_position + Vector3(0, 1.1, 0) - global_position
			_dir = _dir.lerp(to.normalized(), minf(delta * 4.0, 1.0)).normalized()
			if to.length() < 0.8:
				_acertar()
				return
		global_position += _dir * VEL * delta
		if _dir.length_squared() > 1e-6:
			look_at(global_position + _dir, Vector3.UP if absf(_dir.y) < 0.99 else Vector3.RIGHT)

	func _acertar() -> void:
		var cfg := Config.cfg
		var dir := _dir
		dir.y = 0
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
		# Escudo virado para o virote: na janela do contra-golpe, ele volta.
		if _alvo._blocking and _alvo._facing().dot(-dir) > Unit.BLOCK_COS and _alvo._block_t <= cfg.parry_janela:
			_volta = true
			_vida = 1.6
			Fx.burst(_game, global_position, Color(1, 0.9, 0.5), 10, 6.0)
			Sfx.play("block", global_position, 0.1)
			if _alvo.is_player:
				Fx.damage_number(_game, _alvo.global_position + Vector3(0, 0.5, 0), "DEVOLVEU!", Color(1, 0.9, 0.5))
			_alvo.add_power(cfg.chi_esquiva)
			return
		_alvo.take_damage(cfg.torreta_dano, null, dir, 0.4, false, "torreta", 1)
		queue_free()
