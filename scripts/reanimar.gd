class_name Reanimar
extends RefCounted
## Reanimar aliados caídos (Ciclo 2.18, estilo Battlefield 6).
##
## Quem morre fica CAÍDO no chão enquanto conta a espera de renascer. Um aliado
## vivo colado no corpo segura [F] (Unit.wants_reanimar) e o anel dourado
## enche em reanimar_tempo s; aí o caído levanta ali mesmo, com a classe e o
## chapéu que tinha, reanimar_vida da vida e intocável por reanimar_intocavel s.
## Ninguém chegou (ou ele desistiu segurando [F]) = renasce no castelo como recruta.
##
## - Quem reanima continua apanhando e o canal NÃO para com dano: o risco é dele.
## - Classe comum arrasta o corpo para longe da briga (anda a reanimar_arrasto_vel,
##   corda de reanimar_corda m); a Kitsune fica parada abençoando, e reanima
##   reanimar_mago_mult × mais rápido (até reanimar_mago_mult_max no nível 5).
## - Caído esperando ajuda: o relógio dele corre a reanimar_ritmo_espera (janela
##   maior). Sem aliado de pé no time inteiro, ninguém reanima e o relógio é o normal.
##
## A Unit só guarda o estado (reanimar_prog, reanimador, reanimando, desistiu);
## a regra e o visual (chama de espírito + anel no chão) moram aqui.

const CHAMA := preload("res://assets/shaders/chama_espirito.gdshader")
const ANEL := preload("res://assets/shaders/anel_reanimar.gdshader")
## Segurar [F] caído por este tempo = desistir e ir para o castelo.
const DESISTIR_T := 0.5
## Bot caído sem aliado por perto desiste depois deste tempo no chão.
const BOT_DESISTE_T := 1.5

var game: Game
var cfg: GameConfig
## Corpo -> {raiz, chama, anel} (visual só para o time do jogador).
var _visuais := {}
## Corpo -> espera total no instante da morte (para a chama encolher).
var _espera_total := {}
## Corpo -> bot que está indo reanimar (um por corpo).
var _reservas := {}
var _desistir_t := 0.0
## Modo teste: aliado de treino que espera caído para sempre.
var boneco_treino: Unit = null
var _treino_t := -1.0
var _efeito_t := 0.0
static var _mat_chama: ShaderMaterial
static var _mat_anel: ShaderMaterial


func _init(g: Game) -> void:
	game = g
	cfg = Config.cfg


# --- Regra ----------------------------------------------------------------------

## Chamado na morte (Game._on_unit_died).
func ao_cair(u: Unit) -> void:
	if u.reanimando:
		parar(u)  # morreu reanimando: o progresso fica guardado no corpo
	u.reanimar_prog = 0.0
	u.reanimador = null
	u.desistiu = false
	_espera_total[u] = maxf(u._respawn_t, 0.01)
	# Só o time do jogador vê a chama (o inimigo não ganha mapa dos caídos).
	if cfg.reanimar_ligado and game.player and u.team == game.player.team:
		_criar_visual(u)
	if u == game.player:
		_desistir_t = 0.0


## Ainda dá para reanimar este corpo?
func pode_reanimar(corpo: Unit) -> bool:
	return cfg.reanimar_ligado and corpo != null and not corpo.alive and not corpo.em_voo \
			and not corpo.desistiu and corpo._respawn_t > 0.0 and _tem_aliado_de_pe(corpo.team)


func _tem_aliado_de_pe(team: int) -> bool:
	for u in game.units:
		if u.alive and u.team == team:
			return true
	return false


## Modo teste: deixa `u` caído para treinar (Game._aliado_de_treino).
func treino(u: Unit) -> void:
	boneco_treino = u
	u._die(null)


## Ritmo do relógio de quem está caído (Unit._physics_process multiplica o delta).
func ritmo(corpo: Unit) -> float:
	if corpo == boneco_treino:
		return 0.0
	if not pode_reanimar(corpo):
		return 1.0
	if corpo.reanimador != null:
		return 0.0  # sendo reanimado: o relógio para (não renasce no meio do resgate)
	return cfg.reanimar_ritmo_espera


## Bot caído sem aliado vivo por perto (ninguém vai vir) desiste, como o
## jogador faria segurando [F].
func _bot_desiste(corpo: Unit) -> bool:
	if not (corpo.brain is BotBrain) or corpo == boneco_treino or corpo.reanimador:
		return false
	if _espera_total.get(corpo, 0.0) - corpo._respawn_t < BOT_DESISTE_T * cfg.reanimar_ritmo_espera:
		return false
	for u in game.units:
		if u.alive and u.team == corpo.team and u.global_position.distance_to(corpo.global_position) < cfg.reanimar_bot_espera_raio:
			return false
	return true


## Multiplicador de velocidade de quem reanima (Kitsunes mais rápidas).
func velocidade(u: Unit) -> float:
	if not u.eh_mago():
		return 1.0
	var degraus := maxi(cfg.mago_nivel_max - 2, 1)
	var k := clampf(float(game.bonus_mago(u.team, u.stats.id)) / degraus, 0.0, 1.0)
	return lerpf(cfg.reanimar_mago_mult, cfg.reanimar_mago_mult_max, k)


## Corpo aliado reanimável mais perto de `u`, dentro de `raio`.
func corpo_perto(u: Unit, raio: float) -> Unit:
	var melhor: Unit = null
	var dmin := raio
	for c in game.units:
		if c == u or c.team != u.team or not pode_reanimar(c):
			continue
		if c.reanimador != null and c.reanimador != u:
			continue
		var d := u.global_position.distance_to(c.global_position)
		if d < dmin:
			dmin = d
			melhor = c
	return melhor


## [F] do jogador fica com a reanimação quando há corpo ao alcance.
func segura_f(u: Unit) -> bool:
	return cfg.reanimar_ligado and (u.reanimando != null or corpo_perto(u, cfg.reanimar_raio) != null)


func _pode_canalizar(u: Unit) -> bool:
	return u.alive and not u.em_voo and u._dodge_t <= 0.0 and u.carried_princess == null \
			and u.carried_tora == null and not u.is_equipping()


func tick(delta: float) -> void:
	if not cfg.reanimar_ligado:
		return
	_efeito_t -= delta
	var efeito := _efeito_t <= 0.0
	if efeito:
		_efeito_t = 0.15
	for u in game.units:
		if not u.alive:
			if pode_reanimar(u) and _bot_desiste(u):
				desistir(u)
			continue
		if u.reanimando:
			var c := u.reanimando
			if not u.wants_reanimar or not _pode_canalizar(u) or not pode_reanimar(c) \
					or u.global_position.distance_to(c.global_position) > cfg.reanimar_raio + 0.6:
				parar(u)
				continue
			c.reanimar_prog += delta / maxf(cfg.reanimar_tempo, 0.05) * velocidade(u)
			if not u.eh_mago():
				_arrastar(u, c)
			if efeito:
				_efeito_canal(u, c)
			if c.reanimar_prog >= 1.0:
				levantar(c, u)
		elif u.wants_reanimar and _pode_canalizar(u):
			var c := corpo_perto(u, cfg.reanimar_raio)
			if c:
				comecar(u, c)
	if _treino_t >= 0.0:
		_treino_t -= delta
		if _treino_t < 0.0 and is_instance_valid(boneco_treino) and boneco_treino.alive:
			boneco_treino._die(null)
	_tick_jogador_caido(delta)
	_tick_visuais()


func comecar(u: Unit, c: Unit) -> void:
	u.reanimando = c
	c.reanimador = u
	_reservas.erase(c)
	u.comecar_reanimar()
	Sfx.play("reanimar_arrasto" if not u.eh_mago() else "luz", u.global_position, 0.08)
	if c == game.player:
		game.hud.show_big("%s está te reanimando!" % _nome(u), Color(1.0, 0.85, 0.45), 1.2)


func parar(u: Unit) -> void:
	if u.reanimando and is_instance_valid(u.reanimando) and u.reanimando.reanimador == u:
		u.reanimando.reanimador = null
	u.reanimando = null
	u.parar_reanimar()


## Corda: o corpo fica a no máximo reanimar_corda m de quem puxa (vem atrás pelo
## caminho que ele já andou, então não atravessa parede).
func _arrastar(u: Unit, c: Unit) -> void:
	var de := c.global_position - u.global_position
	de.y = 0.0
	var d := de.length()
	if d > cfg.reanimar_corda and d > 0.001:
		var alvo := u.global_position + de / d * cfg.reanimar_corda
		alvo.y = lerpf(c.global_position.y, u.global_position.y, 0.3)
		c.global_position = game.arena.clamp_to_arena(alvo)


func levantar(c: Unit, quem: Unit) -> void:
	parar(quem)
	if not pode_reanimar(c):
		return  # desistiu ou renasceu no mesmo quadro: não levanta dois
	c.levantar_reanimado()
	if c == boneco_treino:
		_treino_t = 4.0
	_remover_visual(c)
	_espera_total.erase(c)
	game.placar.somar(quem, "reanimar")
	game._log("reanimou %s %s -> %s %s" % [Config.TEAM_NAMES[quem.team], quem.stats.id, c.stats.id, "(mago)" if quem.eh_mago() else ""])
	var cor := Config.team_color(c.team)
	Fx.pillar(game, c.global_position, Color(1.0, 0.85, 0.45), 0.9)
	Fx.ring(game, c.global_position, Color(1.0, 0.85, 0.45), 2.4)
	Fx.burst(game, c.global_position + Vector3(0, 1.0, 0), cor.lightened(0.4), 16, 5.0)
	Fx.burst(game, c.global_position + Vector3(0, 0.6, 0), Color(1.0, 0.9, 0.5), 10, 3.0)
	Sfx.play("reanimado", c.global_position)
	Sfx.play("renascer", c.global_position, 0.04)
	if quem == game.player:
		Fx.damage_number(game, c.global_position + Vector3(0, 1.0, 0), "REANIMOU +%d" % int(cfg.pts_reanimar), Color(1.0, 0.85, 0.45))
	if c == game.player:
		game.hud.show_big("De pé de novo! (%s)" % c.stats.display_name, Color(1.0, 0.85, 0.45), 1.4)
		game.camera.add_trauma(0.15)


func _nome(u: Unit) -> String:
	var l := game.placar.linha(u)
	return String(l.get("nome", u.stats.display_name))


## Jogador caído: barra da espera, quem está reanimando e [F] para desistir.
func _tick_jogador_caido(delta: float) -> void:
	var p := game.player
	if p == null or game.hud == null:
		return
	if p.alive:
		_desistir_t = 0.0
		if p.reanimando:
			game.hud.reanimar_barra(p.reanimando.reanimar_prog, "REANIMANDO  ·  solte [F] para parar", Color(1.0, 0.8, 0.35))
		else:
			game.hud.reanimar_barra(-1.0, "", Color.WHITE)
		return
	if p.brain is BotBrain:
		game.hud.reanimar_barra(-1.0, "", Color.WHITE)
		return
	# Segurar [F] caído desiste, mesmo no meio de uma reanimação (a escolha é sua).
	if not p.desistiu and Input.is_action_pressed("interact"):
		_desistir_t += delta
		if _desistir_t >= DESISTIR_T:
			_desistir_t = 0.0
			desistir(p)
			game.hud.show_big("Desistiu: renascendo no castelo", Color(0.85, 0.82, 0.8), 1.0)
	else:
		_desistir_t = 0.0
	var total: float = _espera_total.get(p, 1.0)
	if _desistir_t > 0.0:
		# O progresso do desistir aparece por cima de tudo (antes sumia atrás do "te reanimando").
		game.hud.reanimar_barra(_desistir_t / DESISTIR_T, "DESISTINDO... continue segurando [F]", Color(0.9, 0.45, 0.4))
	elif p.desistiu or not pode_reanimar(p):
		game.hud.reanimar_barra(clampf(p._respawn_t / total, 0.0, 1.0),
				"RENASCENDO NO CASTELO EM %d s" % ceili(p._respawn_t), Color(0.75, 0.72, 0.7))
	elif p.reanimador:
		game.hud.reanimar_barra(p.reanimar_prog, "%s TE REANIMANDO  ·  segure [F] para desistir" % _nome(p.reanimador).to_upper(), Color(1.0, 0.8, 0.35))
	else:
		game.hud.reanimar_barra(clampf(p._respawn_t / total, 0.0, 1.0),
				"CAÍDO  ·  espere um aliado  ·  segure [F] para renascer rápido no castelo", Config.team_color(p.team).lightened(0.3))


## Espera depois de desistir: a contagem rápida (reanimar_desistir_frac da espera
## da morte, mínimo reanimar_desistir_min) menos o pedaço da barra que já correu
## caído. Nunca passa do que faltava esperando, e pode zerar (renasce na hora).
func espera_ao_desistir(total: float, restante: float) -> float:
	var rapido := maxf(total * cfg.reanimar_desistir_frac, cfg.reanimar_desistir_min)
	var ja_esperou := maxf(total - restante, 0.0)
	return clampf(rapido - ja_esperou, 0.0, maxf(restante, 0.0))


## Desiste da ajuda: a chama apaga e o relógio volta ao normal.
func desistir(c: Unit) -> void:
	if c.alive or c.desistiu:
		return
	c.desistiu = true
	c._respawn_t = espera_ao_desistir(_espera_total.get(c, c._respawn_t), c._respawn_t)
	_espera_total[c] = maxf(c._respawn_t, 0.01)
	if c.reanimador:
		parar(c.reanimador)
	if _visuais.has(c):
		var pos: Vector3 = (_visuais[c].raiz as Node3D).global_position
		Fx.burst(game, pos + Vector3(0, 1.0, 0), Config.team_color(c.team).lightened(0.3), 8, 2.5)
	_remover_visual(c)


# --- Bots -----------------------------------------------------------------------

## Corpo que o bot `u` deve ir reanimar (ou null). Um bot por corpo.
func corpo_para_bot(u: Unit) -> Unit:
	if not cfg.reanimar_ligado or u.carried_princess or u.carried_tora:
		return null
	var raio := cfg.reanimar_bot_raio * (2.0 if u.eh_mago() else 1.0)
	var melhor: Unit = null
	var dmin := raio
	for c in game.units:
		if c.team != u.team or not pode_reanimar(c):
			continue
		var r: Unit = _reservas.get(c)
		if r and r != u and is_instance_valid(r) and r.alive:
			continue
		if c.reanimador and c.reanimador != u:
			continue
		var d := u.global_position.distance_to(c.global_position)
		if d < dmin:
			dmin = d
			melhor = c
	if melhor:
		_reservas[melhor] = u
	return melhor


# --- Visual: chama de espírito + anel no chão ---------------------------------------

func _criar_visual(u: Unit) -> void:
	if _visuais.has(u):
		return
	if _mat_chama == null:
		_mat_chama = ShaderMaterial.new()
		_mat_chama.shader = CHAMA
		_mat_anel = ShaderMaterial.new()
		_mat_anel.shader = ANEL
	var raiz := Node3D.new()
	raiz.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	game.add_child(raiz)
	raiz.global_position = u.global_position
	var chama := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.25, 1.25)
	chama.mesh = q
	chama.material_override = _mat_chama
	chama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chama.position = Vector3(0, 1.2, 0)
	chama.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	raiz.add_child(chama)
	var anel := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	var lado := cfg.reanimar_raio * 2.0
	pl.size = Vector2(lado, lado)
	anel.mesh = pl
	anel.material_override = _mat_anel
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anel.position = Vector3(0, 0.07, 0)
	anel.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	raiz.add_child(anel)
	var cor := Config.team_color(u.team)
	chama.set_instance_shader_parameter("cor", cor)
	anel.set_instance_shader_parameter("cor", cor)
	# Letreiro: deixa claro que está CAÍDO (vira "REANIMANDO 40%" no canal).
	var placa := Label3D.new()
	placa.text = "CAÍDO"
	placa.font = Estilo.LETREIRO
	placa.font_size = 44
	placa.outline_size = 14
	placa.pixel_size = 0.006
	placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placa.no_depth_test = true
	placa.fixed_size = false
	placa.modulate = cor.lightened(0.45)
	placa.outline_modulate = Color(0.05, 0.04, 0.08, 0.9)
	placa.position = Vector3(0, 2.05, 0)
	placa.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	raiz.add_child(placa)
	# Entrada: a chama sai do corpo com um "puf" e cresce.
	chama.scale = Vector3.ONE * 0.2
	var tw := chama.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(chama, "scale", Vector3.ONE, 0.5).set_delay(0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_visuais[u] = {"raiz": raiz, "chama": chama, "anel": anel, "placa": placa}


func _remover_visual(u: Unit) -> void:
	if not _visuais.has(u):
		return
	var v: Dictionary = _visuais[u]
	(v.raiz as Node3D).queue_free()
	_visuais.erase(u)


func _tick_visuais() -> void:
	for u in _visuais.keys():
		if not is_instance_valid(u) or u.alive or not pode_reanimar(u):
			if is_instance_valid(u) and not u.alive and not u.desistiu:
				# A espera acabou (ou o time todo caiu): a chama sobe e apaga.
				var pos: Vector3 = (_visuais[u].raiz as Node3D).global_position
				Fx.burst(game, pos + Vector3(0, 1.1, 0), Config.team_color(u.team).lightened(0.3), 6, 2.0)
			_remover_visual(u)
			continue
		var v: Dictionary = _visuais[u]
		var raiz: Node3D = v.raiz
		raiz.global_position = u.global_position
		var total: float = _espera_total.get(u, 1.0)
		var vida := clampf(u._respawn_t / total, 0.0, 1.0)
		var chama: MeshInstance3D = v.chama
		var anel: MeshInstance3D = v.anel
		chama.position.y = 1.2 + sin(game._time * 2.4 + float(u.get_instance_id() % 7)) * 0.08
		chama.set_instance_shader_parameter("vida", vida)
		chama.set_instance_shader_parameter("brilho", clampf(u.reanimar_prog, 0.0, 1.0) if u.reanimador else u.reanimar_prog * 0.3)
		anel.set_instance_shader_parameter("vida", vida)
		anel.set_instance_shader_parameter("progresso", clampf(u.reanimar_prog, 0.0, 1.0))
		var placa: Label3D = v.placa
		var txt := "REANIMANDO %d%%" % int(clampf(u.reanimar_prog, 0.0, 1.0) * 100.0) if u.reanimador else "CAÍDO"
		if placa.text != txt:
			placa.text = txt
			placa.modulate = Color(1.0, 0.85, 0.45) if u.reanimador else Config.team_color(u.team).lightened(0.45)


## Faíscas do canal: a Kitsune solta um feixe de benção; os outros levantam
## fagulhas douradas do anel enquanto puxam.
func _efeito_canal(u: Unit, c: Unit) -> void:
	var peito := c.global_position + Vector3(0, 0.45, 0)
	if u.eh_mago():
		var cor := Color(1.0, 0.88, 0.5)
		if u.stats.estilo_ninja == "_kitsune_sombria":
			cor = Color(0.72, 0.4, 1.0)
		elif u.stats.estilo_ninja != "_kitsune_luz":
			cor = Color(0.75, 0.9, 1.0)
		var mao := u.global_position + Vector3(0, 1.3, 0) + u.aim_dir * 0.4
		Fx.beam(game, mao, peito, cor, 0.24, 0.22)
		Fx.burst(game, peito + Vector3(0, 0.3, 0), cor, 6, 2.0)
		Fx.burst(game, mao, cor, 3, 1.2)
	else:
		Fx.burst(game, peito, Color(1.0, 0.85, 0.45), 3, 1.8)
		if randf() < 0.3:
			Sfx.play("reanimar_arrasto", u.global_position, 0.12)
