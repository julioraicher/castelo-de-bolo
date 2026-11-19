class_name Finalizar
extends RefCounted
## Finalização de herói (Ciclo 2.34).
##
## Herói raro (Nv6) que cai fica CAÍDO como todo mundo (Reanimar, Ciclo 2.18) e
## o time dele pode reanimá-lo em reanimar_tempo s, de volta com o chapéu. Agora
## o outro lado tem resposta: um inimigo vivo colado no corpo segura [F] por
## finalizar_tempo s (0,8 s, bem menos que os 3 s de reanimar) e o finaliza.
## Finalizado não levanta mais; quem finalizou ganha Chi, super e pontos.
## É uma corrida: o time dele quer reanimar, o seu quer finalizar, e quem
## finaliza fica parado e exposto. O canal NÃO para com dano (como o Reanimar).
##
## Duas camadas de espetáculo, as duas só visuais (a regra é igual em todo PC):
##  - herói caiu: letreiro, meio segundo de câmera lenta perto do jogador e uma
##    marca vermelha no corpo para o time inimigo correr até ele;
##  - finalizou: golpe próprio da personalidade de quem bate (Personalidade),
##    selo e hanko de quem finalizou, câmera lenta e faixas de cinema.
## Online (lockstep) não tem câmera lenta: Engine.time_scale mexe na física e
## separaria a partida; fica o congelamento do golpe (hitstop, que é regra e
## roda igual nos dois PCs) e a câmera.
##
## A Unit só guarda o estado (finalizado, finalizador, finalizando,
## finalizar_prog); a regra e a marca no chão moram aqui. A tecla é a mesma do
## Reanimar (wants_reanimar = [F] segurado): perto de herói inimigo caído o [F]
## finaliza; perto de aliado caído, reanima.

const ANEL := preload("res://assets/shaders/anel_reanimar.gdshader")
const COR := Color(1.0, 0.28, 0.18)

var game: Game
var cfg: GameConfig
## Corpo -> {raiz, anel, placa} (só para o time que pode finalizar).
var _visuais := {}
## Corpo -> bot que está indo finalizar (um por corpo).
var _reservas := {}
var _efeito_t := 0.0
static var _mat_anel: ShaderMaterial


func _init(g: Game) -> void:
	game = g
	cfg = Config.cfg


# --- Regra ----------------------------------------------------------------------

## Herói caído que ainda dá para finalizar.
func pode_finalizar(corpo: Unit) -> bool:
	return cfg.finalizar_ligado and corpo != null and is_instance_valid(corpo) and not corpo.alive \
			and corpo.stats.heroi and not corpo.finalizado and not corpo.em_voo and corpo._respawn_t > 0.0


## Corpo de herói inimigo finalizável mais perto de `u`, dentro de `raio`.
func corpo_perto(u: Unit, raio: float) -> Unit:
	var melhor: Unit = null
	var dmin := raio
	for c in game.units:
		if c.team == u.team or not pode_finalizar(c):
			continue
		if c.finalizador != null and c.finalizador != u:
			continue
		var d := u.global_position.distance_to(c.global_position)
		if d < dmin:
			dmin = d
			melhor = c
	return melhor


func _pode_canalizar(u: Unit) -> bool:
	return u.alive and not u.em_voo and u._dodge_t <= 0.0 and u.carried_princess == null \
			and u.carried_tora == null and not u.is_equipping() and u.reanimando == null


## Roda antes do Reanimar.tick (Game._physics_process): quem está finalizando
## não começa a reanimar no mesmo [F].
func tick(delta: float) -> void:
	if not cfg.finalizar_ligado:
		return
	_efeito_t -= delta
	var efeito := _efeito_t <= 0.0
	if efeito:
		_efeito_t = 0.15
	for u in game.units:
		if not u.alive:
			continue
		if u.finalizando:
			var c := u.finalizando
			if not u.wants_reanimar or not _pode_canalizar(u) or not pode_finalizar(c) \
					or u.global_position.distance_to(c.global_position) > cfg.finalizar_raio + 0.6:
				parar(u)
				continue
			u.finalizar_prog += delta / maxf(cfg.finalizar_tempo, 0.05)
			if efeito:
				Personalidade.canal_fx(u, c, u.finalizar_prog)
			if u.finalizar_prog >= 1.0:
				executar(u, c)
		elif u.wants_reanimar and _pode_canalizar(u):
			var c := corpo_perto(u, cfg.finalizar_raio)
			if c:
				comecar(u, c)
	_tick_visuais()
	_tick_hud()


func comecar(u: Unit, c: Unit) -> void:
	u.finalizando = c
	u.finalizar_prog = 0.0
	c.finalizador = u
	_reservas.erase(c)
	u.comecar_reanimar()  # solta golpe/bloqueio/carga, como no Reanimar
	var to := c.global_position - u.global_position
	to.y = 0.0
	if to.length() > 0.1:
		u.aim_dir = to.normalized()  # olha para o corpo (o cérebro reescreve no próximo quadro)
	Sfx.play("pavio", u.global_position, 0.08, 1.3, -6.0)
	if c == game.player and game.hud:
		game.hud.show_big("%s vai te finalizar!" % _nome(u), Color(1.0, 0.45, 0.35), 1.0)


func parar(u: Unit) -> void:
	if u.finalizando and is_instance_valid(u.finalizando) and u.finalizando.finalizador == u:
		u.finalizando.finalizador = null
	u.finalizando = null
	u.finalizar_prog = 0.0
	u.parar_reanimar()


## Morreu (Game._on_unit_died): solta o corpo que finalizava.
func ao_cair(u: Unit) -> void:
	if u.finalizando:
		parar(u)


## O golpe que fecha: regra (estado, recompensa, placar) + o espetáculo.
func executar(u: Unit, c: Unit) -> void:
	parar(u)
	if not pode_finalizar(c):
		return
	c.finalizado = true
	c.finalizador = null
	# Quem estava reanimando solta: não tem mais o que levantar.
	if c.reanimador:
		game.reanimar.parar(c.reanimador)
	game.reanimar.finalizado(c)
	u.add_power(cfg.finalizar_chi)
	u.add_super(cfg.finalizar_super)
	game.placar.somar(u, "finalizar")
	# Congela os dois no impacto (regra: roda igual em todo PC).
	u.hitstop(cfg.hitstop_time * 3.0)
	game._log("finalizou %s %s -> %s %s (t=%.0fs)" % [Config.TEAM_NAMES[u.team], u.stats.id, Config.TEAM_NAMES[c.team], c.stats.id, game._time])
	Personalidade.golpe(u, c)
	_espetaculo(u, c)


## Câmera, faixas, letreiro: só quem está perto (ou é um dos dois) vê.
func _espetaculo(u: Unit, c: Unit) -> void:
	var p := game.player
	if p == null or game.hud == null:
		return
	var envolvido := u == p or c == p
	var perto := envolvido or p.global_position.distance_to(c.global_position) < cfg.finalizar_ver_raio
	if not perto:
		return
	var lento := cfg.finalizar_lento
	game.slowmo(lento.x, lento.y)  # não faz nada no online
	game.camera.cinema(c.global_position + Vector3(0, 0.6, 0), 9.0 if envolvido else 5.0, lento.y + 0.35)
	game.camera.add_trauma(0.45 if envolvido else 0.2)
	game.hud.cinema(lento.y + 0.5)
	if u == p:
		game.hud.show_big("Finalizou %s!  +%d" % [c.stats.display_name, int(cfg.pts_finalizar)], Assinatura.cor(u).lightened(0.3), 1.4)
		game.hud.flash(Color(Assinatura.cor_flash(u), 0.3), 0.35)
	elif c == p:
		game.hud.show_big("Finalizado por %s" % _nome(u), Color(1.0, 0.45, 0.35), 1.6)
		game.hud.flash(Color(0.6, 0.05, 0.05, 0.35), 0.4)


## Um herói acabou de cair (Game._on_unit_died): avisa e marca o corpo.
func heroi_caiu(c: Unit, killer: Unit) -> void:
	if not cfg.finalizar_ligado or not c.stats.heroi:
		return
	game._log("heroi caiu %s %s (t=%.0fs)" % [Config.TEAM_NAMES[c.team], c.stats.id, game._time])
	if killer and killer != c:
		killer.hitstop(cfg.hitstop_time * 2.0)  # regra: igual em todo PC
	var p := game.player
	if p == null or game.hud == null:
		return
	if c.team != p.team:
		_criar_visual(c)
	var d := p.global_position.distance_to(c.global_position)
	var cor := Assinatura.cor(c).lightened(0.2)
	if killer == p:
		game.hud.show_big("Herói caiu! Segure [F] nele", Estilo.OURO_CLARO, 1.4)
	elif c == p:
		pass  # o Reanimar já diz "Você caiu!"
	elif c.team == p.team:
		game.hud.show_big("Seu %s caiu! Reanime!" % c.stats.display_name, cor, 1.3)
	elif d < 40.0:
		game.hud.show_big("%s inimigo caiu! Finalize!" % c.stats.display_name, Estilo.OURO_CLARO, 1.2)
	if killer == p or d < cfg.finalizar_ver_raio:
		var lento := cfg.heroi_caiu_lento
		game.slowmo(lento.x, lento.y)
		game.camera.punch_fov(5.0)
		game.camera.add_trauma(0.3)
	Magia.clarao(game, c.global_position, cor, 6.0, 0.3, 2.0)
	Sfx.play("corte_critico", c.global_position, 0.05, 0.7)


func _nome(u: Unit) -> String:
	var l := game.placar.linha(u)
	return String(l.get("nome", u.stats.display_name))


## HUD do jogador: barra enquanto finaliza; dica é em Game (_dica do [F]).
func _tick_hud() -> void:
	var p := game.player
	if p == null or game.hud == null or not p.alive or p.finalizando == null:
		return
	game.hud.reanimar_barra(p.finalizar_prog, "FINALIZANDO %s  ·  solte [F] para parar" % p.finalizando.stats.display_name.to_upper(), COR.lightened(0.15))


# --- Bots -----------------------------------------------------------------------

## Herói inimigo caído que o bot `u` deve ir finalizar (ou null). Um bot por corpo.
func corpo_para_bot(u: Unit) -> Unit:
	if not cfg.finalizar_ligado or u.carried_princess or u.carried_tora:
		return null
	var melhor: Unit = null
	var dmin := cfg.finalizar_bot_raio
	for c in game.units:
		if c.team == u.team or not pode_finalizar(c):
			continue
		var r: Unit = _reservas.get(c)
		if r and r != u and is_instance_valid(r) and r.alive:
			continue
		var d := u.global_position.distance_to(c.global_position)
		if d < dmin:
			dmin = d
			melhor = c
	if melhor:
		_reservas[melhor] = u
	return melhor


# --- Marca no corpo (só para quem pode finalizar) ---------------------------------

func _criar_visual(u: Unit) -> void:
	if _visuais.has(u):
		return
	if _mat_anel == null:
		_mat_anel = ShaderMaterial.new()
		_mat_anel.shader = ANEL
	var raiz := Node3D.new()
	raiz.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	game.add_child(raiz)
	raiz.global_position = u.global_position
	var anel := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	var lado := cfg.finalizar_raio * 2.0
	pl.size = Vector2(lado, lado)
	anel.mesh = pl
	anel.material_override = _mat_anel
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anel.position = Vector3(0, 0.08, 0)
	anel.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	anel.set_instance_shader_parameter("cor", COR)
	raiz.add_child(anel)
	var placa := Label3D.new()
	placa.text = "FINALIZE  [F]"
	placa.font = Estilo.LETREIRO
	placa.font_size = 44
	placa.outline_size = 14
	placa.pixel_size = 0.006
	placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placa.no_depth_test = true
	placa.modulate = COR.lightened(0.35)
	placa.outline_modulate = Color(0.05, 0.04, 0.08, 0.9)
	placa.position = Vector3(0, 2.05, 0)
	placa.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	raiz.add_child(placa)
	_visuais[u] = {"raiz": raiz, "anel": anel, "placa": placa}


func _remover_visual(u: Unit) -> void:
	if not _visuais.has(u):
		return
	(_visuais[u].raiz as Node3D).queue_free()
	_visuais.erase(u)


func _tick_visuais() -> void:
	for u in _visuais.keys():
		if not is_instance_valid(u) or not pode_finalizar(u):
			_remover_visual(u)
			continue
		var v: Dictionary = _visuais[u]
		var raiz: Node3D = v.raiz
		raiz.global_position = u.global_position
		var prog: float = u.finalizador.finalizar_prog if u.finalizador and is_instance_valid(u.finalizador) else 0.0
		var anel: MeshInstance3D = v.anel
		anel.set_instance_shader_parameter("progresso", clampf(prog, 0.0, 1.0))
		anel.set_instance_shader_parameter("vida", 0.6 + 0.4 * sin(game._time * 6.0))
		var placa: Label3D = v.placa
		var txt := "FINALIZANDO %d%%" % int(prog * 100.0) if prog > 0.0 else "FINALIZE  [F]"
		if placa.text != txt:
			placa.text = txt
