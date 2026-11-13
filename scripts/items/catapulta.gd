class_name Catapulta
extends Node3D
## Catapulta da base (Ciclo 2.9b; quiz 2026-11-06: bambu + mão do Oni, pouso
## em meteoro de Chi, barra de força com o ponto de queda no minimapa).
## Fica em MapLayout.catapulta_spot, virada para o castelo inimigo, sempre de
## pé. F perto dela sobe na mão do Oni; a barra de força vai e volta (ping-pong,
## ~1,4 s por ciclo) e F de novo lança. Bots atacantes também usam (Game).
##
## Física do voo: parábola fechada p(s) = lerp(p0, p1, s) + ŷ·4h·s(1-s), s = t/T,
## com T = catapulta_voo e h crescendo com a distância (12 m + 10% do alcance):
## tempo fixo deixa a sensação igual perto e longe, e o passageiro não pode ser
## atingido no ar (Unit.em_voo). Pouso: pilar de Chi, rachaduras, tranco de
## câmera e dano + empurrão em quem estiver a catapulta_raio.
##
## Sons (nomes fixos para a thread de sons trocar o arquivo): catapulta_arma
## (subiu, bambu range), catapulta_lanca (braço bate, vento), catapulta_meteoro
## (assobio caindo + estrondo de energia). Timbre: bambu, pedra, Chi (luz).
##
## Visual: ThemeConfig.catapulta_model (tools/gerar_torretas.gd): nó "Braco" com
## pivô no eixo, vara ao longo de +Y e a mão a BRACO_COMP do pivô.

const ALCANCE_EMBARQUE := 2.8
const BRACO_REPOUSO := -100.0  # graus: mão baixa, atrás (quem sobe fica a ~1,2 m)
const BRACO_FIM := 60.0        # fim do golpe do braço
const BRACO_COMP := 3.1        # pivô até a palma da mão
const SOLTA_T := 0.12          # s depois do lançamento em que a mão solta
const TREMOR := 0.22

var team := 0
var passageiro: Unit
var reservado: Unit   # bot a caminho (um por vez)
var reserva_t := 0.0  # última vez (Game._time) que o bot renovou a reserva
var forca := 0.0

var _game: Game
var _casa: Node3D
var _braco: Node3D
var _recarga_t := 0.0
var _subindo := true
var _voo: Array[Voo] = []  # passageiros no ar
var _marca: Node3D
var _marca_mat: StandardMaterial3D


func setup(game: Game, p_team: int, pos: Vector3) -> void:
	_game = game
	team = p_team
	position = pos
	var fwd := game.arena.forward(team)
	rotation.y = atan2(fwd.x, fwd.z)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_casa = _montar()
	add_child(_casa)
	_montar_marca()


func pronta() -> bool:
	return passageiro == null and _recarga_t <= 0.0


func recarregando() -> float:
	return _recarga_t


## Posição da palma da mão no mundo.
func mao_pos() -> Vector3:
	if _braco:
		return _braco.global_transform * Vector3(0, BRACO_COMP, 0)
	return global_position + Vector3(0, 1.2, 0)


## Onde cai com a força f (0..1): na metade inimiga, da beira do rio até perto
## da muralha, sobre a estrada do meio.
func ponto_queda(f: float) -> Vector3:
	var cfg := Config.cfg
	var a := _game.arena
	var fwd := a.forward(team)
	var x0: float = fwd.x * cfg.catapulta_queda_min
	var muralha: float = fwd.x * (a.map.castle_distance - a.map.wall_front)
	var x1: float = muralha - fwd.x * cfg.catapulta_folga_muralha
	var z := signf(position.z) * 1.5 if absf(position.z) > 0.1 else 0.0
	return Vector3(lerpf(x0, x1, clampf(f, 0.0, 1.0)), 0.0, z)


func embarcar(u: Unit) -> void:
	if not pronta() or u.em_voo or u.carried_princess:
		return
	passageiro = u
	reservado = null
	forca = 0.0
	_subindo = true
	u.em_voo = true
	u.velocity = Vector3.ZERO
	u.wants_attack = false
	u.wants_block = false
	u.global_position = mao_pos() + Vector3(0, 0.15, 0)
	u.reset_physics_interpolation()
	u.pose_voo(true)
	_marca.visible = true
	Sfx.play("catapulta_arma", global_position, 0.05)
	if u.is_player:
		_game.hud.show_big("[F] lançar  ·  a barra marca a força", Config.team_color(team).lightened(0.4), 1.4)


## Desce sem lançar (morte, fim de jogo).
func desembarcar() -> void:
	if passageiro == null:
		return
	var u := passageiro
	passageiro = null
	u.em_voo = false
	u.pose_voo(false)
	u.global_position = global_position + Vector3(0, 0, -2.5).rotated(Vector3.UP, rotation.y)
	u.reset_physics_interpolation()
	_esconder_mira()


func lancar() -> void:
	if passageiro == null:
		return
	var u := passageiro
	passageiro = null
	_recarga_t = Config.cfg.catapulta_recarga * (Config.cfg.sandbox_catapulta_mult if _game.sandbox else 1.0)
	var p1 := ponto_queda(forca)
	p1.y = _game.arena.ground_y(p1.x, p1.z)
	var dist := global_position.distance_to(p1)
	var h := 12.0 + dist * 0.1
	# Brilho do meteoro de Chi preso ao passageiro.
	var cor := Config.team_color(team)
	var brilho := MeshInstance3D.new()
	var e := SphereMesh.new()
	e.radius = 0.85
	e.height = 1.7
	e.radial_segments = 10
	e.rings = 5
	brilho.mesh = e
	brilho.position.y = 0.9
	brilho.material_override = Fx.unshaded(Color(cor.lightened(0.3), 0.4), true)
	brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	u.add_child(brilho)
	var voo := Voo.new()
	voo.unit = u
	voo.t = -SOLTA_T
	voo.T = Config.cfg.catapulta_voo
	voo.p0 = mao_pos()
	voo.p1 = p1
	voo.h = h
	voo.brilho = brilho
	_voo.append(voo)
	# Braço: golpe rápido para a frente, volta devagar enquanto recarrega.
	if _braco:
		var tw := _braco.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_property(_braco, "rotation:x", deg_to_rad(BRACO_FIM), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.0)
		tw.tween_property(_braco, "rotation:x", deg_to_rad(BRACO_REPOUSO), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_esconder_mira()
	Fx.burst(_game, mao_pos(), cor.lightened(0.4), 14, 6.0)
	Sfx.play("catapulta_lanca", global_position, 0.06)
	_game.camera.shake_at(global_position, TREMOR)
	_game._log("CATAPULTA %s lançou %s (força %.2f, t=%.0fs)" % [Config.TEAM_NAMES[team], u.name, forca, _game._time])


func _esconder_mira() -> void:
	_marca.visible = false
	if _game.catapulta_alvo_time == team:
		_game.catapulta_alvo = Vector3.INF
		_game.catapulta_alvo_time = -1
	if _game.player and _game.player.team == team:
		_game.hud.catapulta_forca(-1.0)


func _physics_process(delta: float) -> void:
	if _recarga_t > 0.0:
		_recarga_t = maxf(_recarga_t - delta, 0.0)
	if _game.game_over:
		if passageiro:
			desembarcar()
		for v in _voo:  # quem estava no ar desce no ponto de queda, sem meteoro
			_pousar_quieto(v)
		_voo.clear()
		return
	if passageiro:
		if not passageiro.alive:
			desembarcar()
		else:
			# Barra de força vai e volta (ping-pong).
			forca += delta / 0.7 * (1.0 if _subindo else -1.0)
			if forca >= 1.0:
				forca = 1.0
				_subindo = false
			elif forca <= 0.0:
				forca = 0.0
				_subindo = true
			passageiro.global_position = mao_pos() + Vector3(0, 0.15, 0)
			var alvo := ponto_queda(forca)
			_marca.global_position = Vector3(alvo.x, 0.06, alvo.z)
			_marca_mat.albedo_color.a = 0.45 + 0.25 * sin(_game._time * 9.0)
			if passageiro.is_player:
				_game.catapulta_alvo = alvo
				_game.catapulta_alvo_time = team
				_game.hud.catapulta_forca(forca)
	# Voos em andamento.
	var i := _voo.size() - 1
	while i >= 0:
		var v := _voo[i]
		var u := v.unit
		v.t += delta
		if v.t < 0.0:
			v.p0 = mao_pos()  # ainda na mão: solta em t = 0
			u.global_position = v.p0 + Vector3(0, 0.15, 0)
		else:
			var s := minf(v.t / v.T, 1.0)
			u.global_position = v.p0.lerp(v.p1, s) + Vector3(0, 4.0 * v.h * s * (1.0 - s), 0)
			v.rastro_t -= delta
			if v.rastro_t <= 0.0:
				v.rastro_t = 0.07
				Fx.burst(_game, u.global_position + Vector3(0, 0.9, 0), Config.team_color(team).lightened(0.3), 3, 1.5)
			if s >= 1.0:
				_aterrissar(u, v.p1, v.brilho)
				_voo.remove_at(i)
		i -= 1


## Fim de jogo com alguém no ar: põe no chão sem dano nem efeito.
func _pousar_quieto(v: Voo) -> void:
	if is_instance_valid(v.brilho):
		v.brilho.queue_free()
	var u := v.unit
	if not is_instance_valid(u):
		return
	u.em_voo = false
	u.pose_voo(false)
	u.global_position = v.p1
	u.velocity = Vector3.ZERO
	u.reset_physics_interpolation()


## Meteoro de Chi: pilar, rachaduras, tranco e dano + empurrão em volta.
func _aterrissar(u: Unit, p1: Vector3, brilho: Node) -> void:
	var cfg := Config.cfg
	var cor := Config.team_color(team)
	if is_instance_valid(brilho):
		brilho.queue_free()
	u.em_voo = false
	u.pose_voo(false)
	u.global_position = p1
	u.velocity = Vector3.ZERO
	u.reset_physics_interpolation()
	u.aterrissagem()
	Fx.pillar(_game, p1, cor.lightened(0.3), 2.6)
	Fx.ring(_game, p1 + Vector3(0, 0.1, 0), cor, cfg.catapulta_raio)
	Fx.cracks(_game, p1, cor.darkened(0.2), cfg.catapulta_raio * 0.8)
	Fx.burst(_game, p1 + Vector3(0, 0.5, 0), cor.lightened(0.4), 24, 7.0)
	_game.camera.shake_at(p1, 0.5)
	Sfx.play("catapulta_meteoro", p1, 0.05)
	if u.is_player:
		_game.hud.show_big("Meteoro de Chi!", cor.lightened(0.4), 1.0)
	for v in _game.units:
		if not v.alive or v.team == team or v == u:
			continue
		var d := v.global_position - p1
		d.y = 0
		if d.length() <= cfg.catapulta_raio:
			var dir := d.normalized() if d.length() > 0.05 else Vector3.FORWARD
			v.take_damage(cfg.catapulta_dano, u, dir, 1.6, false, "chi", 1)
	for t in _game.torretas:
		if t.team != team and t.encosta(p1, cfg.catapulta_raio - Torreta.RAIO_CORPO):
			t.take_hit(cfg.catapulta_dano, team)


# --- Visual ------------------------------------------------------------------------------

func _montar() -> Node3D:
	var raiz := Node3D.new()
	var th := _game.arena.theme
	var path := th.model_path(th.catapulta_model, team)
	if not ResourceLoader.exists(path):
		push_warning("Catapulta sem modelo: " + path)
		return raiz
	var casa: Node3D = (load(path) as PackedScene).instantiate()
	raiz.add_child(casa)
	_braco = casa.get_node_or_null("Braco")
	if _braco:
		_braco.rotation.x = deg_to_rad(BRACO_REPOUSO)
	if Settings.quality < 3:
		Fx.tirar_contorno(casa)
	return raiz


## Marca de onde vai cair: anel na cor do time com uma cruz no meio (some ao lançar).
func _montar_marca() -> void:
	_marca = Node3D.new()
	_marca.top_level = true
	_marca.visible = false
	_marca_mat = Fx.unshaded(Color(Config.team_color(team), 0.5), true)
	var anel := TorusMesh.new()
	anel.inner_radius = Config.cfg.catapulta_raio - 0.18
	anel.outer_radius = Config.cfg.catapulta_raio
	anel.rings = 28
	anel.ring_segments = 4
	var pecas: Array = [[anel, Transform3D(Basis.from_scale(Vector3(1, 0.05, 1)), Vector3.ZERO)]]
	for k in 2:
		var b := BoxMesh.new()
		b.size = Vector3(0.1, 0.02, 1.4)
		pecas.append([b, Transform3D(Basis.from_euler(Vector3(0, k * PI / 2.0, 0)), Vector3.ZERO)])
	Fx.montar_pecas(_marca, pecas, _marca_mat)
	add_child(_marca)


## Um passageiro no ar: p(s) = lerp(p0, p1, s) + ŷ·4h·s(1−s), s = t/T.
class Voo:
	var unit: Unit
	var t := 0.0          # começa em −SOLTA_T: a mão ainda segura
	var T := 1.0          # duração do voo (catapulta_voo)
	var p0 := Vector3.ZERO
	var p1 := Vector3.ZERO
	var h := 0.0          # altura do ápice acima da corda p0-p1
	var brilho: Node3D
	var rastro_t := 0.0
