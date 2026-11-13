class_name Torreta
extends Node3D
## Torreta de defesa do Construtor (Ciclo 2.9b). Fica num terreno fixo na
## frente do castelo (MapLayout.torreta_spots), marcado por um SELO na cor do
## time. Construtor por perto ergue com madeira do time, como as oficinas:
## d(progresso)/dt = Σv / torreta_obra. Pronta, a besta encantada gira para o
## inimigo mais perto (torreta_alcance) e atira um virote.
##
## Visual (princípio 13): modelo do tema (ThemeConfig.torreta_model, estilo
## game_config.torreta_estilo ou --torreta=a|b|c), gerado por
## tools/gerar_torretas.gd. Nó "Arma" = a besta (frente +Z, pivô em
## ALTURA_ARMA); "Arma/Gira_magia" = fogos-fátuos que orbitam no shader.
## Animações: obra (cresce do chão e "pula" no fim), tiro (coice da besta e
## clarão), dano (tranco) e queda (tomba e some, o terreno volta ao selo).
##
## Defesa (botão direito) contra torreta: o escudo segura torreta_bloqueio do
## dano e, virado para o virote, ele VOLTA e acerta a própria torreta
## (torreta_devolve × dano, pouco: o jeito de tirar uma torreta é derrubá-la
## na porrada). Esquiva atravessa. Golpes e tiros inimigos derrubam a torreta.

enum Estado { VAZIO, OBRA, PRONTA }

const RAIO_OBRA := 3.0
const RAIO_CORPO := 1.0  # para golpes e tiros acertarem a torreta
const ALTURA_ARMA := 2.6
const ALT_LABEL := 4.5    # estado (madeira, %, vida)
const ALT_EMBLEMA := 5.3  # emblema da besta girando
const ALT_TITULO := 6.2   # "TORRETA"

var team := 0
var estado := Estado.VAZIO
var progresso := 0.0
var madeira_entregue := 0
var hp := 0.0

var _game: Game
var _casa: Node3D
var _arma: Node3D
var _selo: Node3D
var _selo_mat: StandardMaterial3D
var _label: Label3D
var _titulo: Label3D
var _emblema: Node3D
var _emblema_mat: StandardMaterial3D
var _tiro_t := 0.0
var _puxar_t := 0.0
var _dust_t := 0.0
var _caindo := false
var _t := 0.0


func setup(game: Game, p_team: int, pos: Vector3) -> void:
	_game = game
	team = p_team
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_montar_selo()
	_casa = _montar_torre()
	add_child(_casa)
	_label = Label3D.new()
	_label.font = Estilo.LETREIRO
	_label.font_size = 40
	_label.pixel_size = 0.011
	_label.outline_size = 10
	_label.outline_modulate = Estilo.TINTA
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = ALT_LABEL
	_label.add_to_group("letreiro_perto")  # some de longe (Game._letreiros_perto)
	add_child(_label)
	_titulo = Label3D.new()
	_titulo.font = Estilo.TITULO
	_titulo.font_size = 60
	_titulo.pixel_size = 0.011
	_titulo.outline_size = 14
	_titulo.outline_modulate = Estilo.TINTA
	_titulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_titulo.position.y = ALT_TITULO
	_titulo.text = "TORRETA"
	add_child(_titulo)
	_montar_emblema()
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
	_caindo = false
	_casa.visible = false
	_casa.transform = Transform3D(Basis(), Vector3.ZERO)
	_casa.scale = Vector3(1, 0.05, 1)
	if _arma:
		_arma.position = Vector3(0, ALTURA_ARMA, 0)
	_emblema.visible = true
	_atualizar_label()


func _physics_process(delta: float) -> void:
	if _game.game_over or _caindo:
		return
	if estado == Estado.PRONTA:
		_atirar(delta)
		return
	_obra(delta)


## Animações leves: o selo gira e pulsa, a besta volta do coice.
func _process(delta: float) -> void:
	_t += delta
	_selo.rotation.y += delta * 0.25
	var a := 0.3 if estado == Estado.PRONTA else 0.45 + 0.25 * sin(_t * 2.2)
	_selo_mat.albedo_color.a = a
	_emblema.rotation.y += delta * 1.3
	_emblema.position.y = ALT_EMBLEMA + 0.14 * sin(_t * 2.0)
	_emblema_mat.albedo_color.a = (0.95 if estado == Estado.PRONTA else 0.6 + 0.25 * sin(_t * 2.2))
	if _arma and _arma.position.z != 0.0:
		_arma.position.z = lerpf(_arma.position.z, 0.0, minf(delta * 9.0, 1.0))
		if absf(_arma.position.z) < 0.005:
			_arma.position.z = 0.0


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
	# "Pula" ao ficar de pé, como a oficina.
	var tw := _casa.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_casa, "scale", Vector3(0.92, 1.14, 0.92), 0.12)
	tw.tween_property(_casa, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.pillar(_game, global_position, Config.team_color(team).lightened(0.3), 2.0)
	Fx.burst(_game, global_position + Vector3(0, 1.0, 0), Color(0.75, 0.65, 0.5), 16, 5.0)
	Sfx.play("torreta_pronta", global_position, 0.05)
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
		if not u.alive or u.team == team or u.em_voo or u._sombra_t > 0.0 or u._disfarce_t > 0.0:
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
	if alvo and _arma:
		var to := alvo.global_position - global_position
		_arma.rotation.y = lerp_angle(_arma.rotation.y, atan2(to.x, to.z), minf(delta * 10.0, 1.0))
	_tiro_t -= delta
	if alvo == null or _tiro_t > 0.0:
		return
	_tiro_t = Config.cfg.torreta_cadencia
	var boca := global_position + Vector3(0, ALTURA_ARMA + 0.1, 0)
	if _arma:
		_arma.position.z = -0.22  # coice (volta em _process)
		# Direção da besta só pelo giro dela (rotation.y), sem o balanço visual
		# da casa (_casa.rotation.z sorteado ao apanhar): o tiro é regra e
		# precisa sair igual em todos os PCs da partida online.
		var ry := _arma.rotation.y
		boca += (global_transform.basis * Vector3(sin(ry), 0.0, cos(ry))).normalized() * 0.7
	var v := Virote.new()
	_game.add_child(v)
	v.setup(_game, self, boca, alvo)
	Fx.burst(_game, boca, Config.team_color(team).lightened(0.5), 5, 2.5)
	Sfx.play("besta_virote", global_position, 0.1)


# --- Dano na torreta ----------------------------------------------------------------

func take_hit(amount: float, from_team: int) -> void:
	if estado != Estado.PRONTA or from_team == team or _caindo:
		return
	hp -= amount
	Fx.damage_number(_game, global_position + Vector3(0, 2.5, 0), str(int(amount)), Color(1, 0.85, 0.6))
	Fx.burst(_game, global_position + Vector3(0, 1.6, 0), Color(0.6, 0.45, 0.3), 6, 4.0)
	Sfx.play("madeira_golpe", global_position, 0.12)
	if hp <= 0.0:
		_cair()
		return
	# Tranco: encolhe e torce um pouco, volta com mola.
	_casa.scale = Vector3(1.07, 0.93, 1.07)
	_casa.rotation.z = randf_range(-0.07, 0.07)
	var tw := _casa.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel(true)
	tw.tween_property(_casa, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_casa, "rotation:z", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_atualizar_label()


## Derrubada: tomba para um lado, afunda e some; o terreno volta ao selo.
func _cair() -> void:
	_game._log("TORRETA %s derrubada (t=%.0fs)" % [Config.TEAM_NAMES[team], _game._time])
	_caindo = true
	estado = Estado.VAZIO
	progresso = 0.0
	madeira_entregue = 0
	hp = 0.0
	_atualizar_label()
	_emblema.visible = false
	Fx.burst(_game, global_position + Vector3(0, 1.2, 0), Color(0.55, 0.4, 0.25), 24, 6.0)
	_game.camera.shake_at(global_position, 0.4)
	Sfx.play("torreta_cai", global_position, 0.1)
	var lado := randf_range(0.0, TAU)
	var eixo := Vector3(cos(lado), 0, sin(lado))
	var tw := _casa.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel(true)
	tw.tween_property(_casa, "rotation", eixo * 1.25, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_casa, "position:y", -0.5, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		Fx.burst(_game, global_position + Vector3(0, 0.4, 0), Color(0.6, 0.5, 0.35), 30, 7.0)
		Fx.ring(_game, global_position + Vector3(0, 0.1, 0), Config.team_color(team), 2.2)
		_zerar())


## Alvo de golpe/tiro: horizontal a até RAIO_CORPO + r e na altura do corpo.
func encosta(p: Vector3, r: float) -> bool:
	if estado != Estado.PRONTA:
		return false
	var d := p - global_position
	if d.y < -0.5 or d.y > 3.5:
		return false
	d.y = 0
	return d.length() <= RAIO_CORPO + r


# --- Visual ---------------------------------------------------------------------------

func _atualizar_label() -> void:
	match estado:
		Estado.VAZIO:
			_label.text = "%d madeiras · Construtor" % custo() if madeira_entregue == 0 else "faltam %d madeiras" % faltam()
			_label.modulate = Color(1, 1, 1, 0.85)
			_titulo.modulate = Color(1, 1, 1, 0.8)
		Estado.OBRA:
			_label.text = "%d%% · faltam %d" % [roundi(progresso * 100.0), faltam()]
			_label.modulate = Color(1, 0.9, 0.6)
			_titulo.modulate = Color(1, 0.9, 0.6)
		Estado.PRONTA:
			_label.text = "%d/%d" % [ceili(hp), int(max_hp())]
			_label.modulate = Config.team_color(team).lightened(0.4)
			_titulo.modulate = Config.team_color(team).lightened(0.45)
	_label.visible = estado != Estado.PRONTA or hp < max_hp()


## Selo no chão (quiz 2026-11-06, T3): dois anéis, quatro traços e o losango
## do meio, na cor do time, sem sombra; gira e pulsa em _process.
func _montar_selo() -> void:
	_selo = Node3D.new()
	_selo.position.y = 0.04
	_selo.scale = Vector3(1.6, 1, 1.6)  # passa da base da torre: lê de cima, ao redor
	_selo_mat = Fx.unshaded(Color(Config.team_color(team), 0.4), true)
	var pecas: Array = []
	var fora := TorusMesh.new()
	fora.inner_radius = 1.28
	fora.outer_radius = 1.42
	fora.rings = 24
	fora.ring_segments = 4
	pecas.append([fora, Transform3D(Basis.from_scale(Vector3(1, 0.06, 1)), Vector3.ZERO)])
	var dentro := TorusMesh.new()
	dentro.inner_radius = 0.56
	dentro.outer_radius = 0.66
	dentro.rings = 16
	dentro.ring_segments = 4
	pecas.append([dentro, Transform3D(Basis.from_scale(Vector3(1, 0.06, 1)), Vector3.ZERO)])
	for k in 4:
		var traco := BoxMesh.new()
		traco.size = Vector3(0.09, 0.02, 0.62)
		var a := PI / 4.0 + k * PI / 2.0
		pecas.append([traco, Transform3D(Basis.from_euler(Vector3(0, a, 0)), Vector3(sin(a), 0, cos(a)) * 0.97)])
	var meio := BoxMesh.new()
	meio.size = Vector3(0.34, 0.02, 0.34)
	pecas.append([meio, Transform3D(Basis.from_euler(Vector3(0, PI / 4.0, 0)), Vector3.ZERO)])
	Fx.montar_pecas(_selo, pecas, _selo_mat)
	add_child(_selo)


## Emblema flutuante em cima da torre (pedido do Julio, 2026-11-06: "mais
## identificável, algo em cima"): anel com a besta estilizada dentro (arco,
## coronha e virote), na cor do time, sem sombra; gira e sobe/desce em _process.
## É marcação de interface (como o selo), não a peça em si.
func _montar_emblema() -> void:
	_emblema = Node3D.new()
	_emblema.position.y = ALT_EMBLEMA
	_emblema.scale = Vector3.ONE * 1.35
	_emblema_mat = Fx.unshaded(Color(Config.team_color(team).lightened(0.25), 0.9), true)
	var pecas: Array = []
	var anel := TorusMesh.new()
	anel.inner_radius = 0.5
	anel.outer_radius = 0.6
	anel.rings = 24
	anel.ring_segments = 6
	pecas.append([anel, Transform3D(Basis.from_euler(Vector3(PI / 2.0, 0, 0)), Vector3.ZERO)])
	var arco := TorusMesh.new()  # arco da besta: meio toro deitado, cortado pelo anel
	arco.inner_radius = 0.3
	arco.outer_radius = 0.38
	arco.rings = 16
	arco.ring_segments = 4
	pecas.append([arco, Transform3D(Basis.from_euler(Vector3(PI / 2.0, 0, 0)).scaled(Vector3(1, 0.55, 1)), Vector3(0, 0.08, 0))])
	var coronha := BoxMesh.new()
	coronha.size = Vector3(0.09, 0.62, 0.06)
	pecas.append([coronha, Transform3D(Basis(), Vector3(0, -0.05, 0))])
	var corda := BoxMesh.new()
	corda.size = Vector3(0.7, 0.04, 0.04)
	pecas.append([corda, Transform3D(Basis(), Vector3(0, 0.08, 0))])
	var ponta := PrismMesh.new()
	ponta.size = Vector3(0.2, 0.2, 0.06)
	pecas.append([ponta, Transform3D(Basis(), Vector3(0, 0.36, 0))])
	Fx.montar_pecas(_emblema, pecas, _emblema_mat)
	add_child(_emblema)


## Modelo do tema. Sem contorno de tinta abaixo da qualidade Alta (igual à
## oficina). Sem modelo (tema antigo): fica só o selo e um aviso.
func _montar_torre() -> Node3D:
	var raiz := Node3D.new()
	var th := _game.arena.theme
	var estilo: String = _game.torreta_estilo if _game.torreta_estilo != "" else Config.cfg.torreta_estilo
	var path := th.model_path(th.torreta_model.replace("{estilo}", estilo), team)
	if not ResourceLoader.exists(path):
		push_warning("Torreta sem modelo: " + path)
		return raiz
	var casa: Node3D = (load(path) as PackedScene).instantiate()
	raiz.add_child(casa)
	_arma = casa.get_node_or_null("Arma")
	if Settings.quality < 3:
		Fx.tirar_contorno(casa)
	MalhaUnica.juntar(casa, [_arma] if _arma else [])
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
		var cor := Config.team_color(dono.team).lightened(0.5)
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.07, 0.07, 0.75)
		mi.mesh = b
		mi.material_override = Fx.unshaded(cor)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		# Ponta encantada: um brilho na frente.
		var ponta := MeshInstance3D.new()
		var e := SphereMesh.new()
		e.radius = 0.11
		e.height = 0.22
		e.radial_segments = 6
		e.rings = 3
		ponta.mesh = e
		ponta.position.z = 0.4
		ponta.material_override = Fx.unshaded(Color(cor, 0.8), true)
		ponta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ponta)

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
		# Escudo virado para o virote: ele volta (sem janela de tempo; quiz 2026-11-06).
		if _alvo._blocking and _alvo._facing().dot(-dir) > Unit.BLOCK_COS:
			_volta = true
			_vida = 1.6
			Fx.burst(_game, global_position, Color(1, 0.9, 0.5), 10, 6.0)
			Sfx.play("besta_devolve", global_position, 0.1)
			if _alvo.is_player:
				Fx.damage_number(_game, _alvo.global_position + Vector3(0, 0.5, 0), "DEVOLVEU!", Color(1, 0.9, 0.5))
			_alvo.add_power(cfg.chi_esquiva)
			return
		_alvo.take_damage(cfg.torreta_dano, null, dir, 0.4, false, "torreta", 1)
		queue_free()
