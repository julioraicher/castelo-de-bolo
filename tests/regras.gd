extends Node
## Testes de regra: conferem números do jogo que um bug pode quebrar sem
## erro de script (a fumaça do CI não pega). Rodam dentro de uma partida real:
##   godot --headless --path . -- --autoplay --testes
## Imprime "TESTES OK" ou cada falha e sai com código 1.
##
## Regra nova que importa? Acrescente um _check aqui.

var game  # Game (sem tipo: o script é carregado em tempo de execução)
var _falhas: Array[String] = []
var _total := 0


func _ready() -> void:
	# Espera a partida montar e os bonecos nascerem.
	await get_tree().create_timer(0.5).timeout
	_dados()
	_mascara_pesada()  # antes de qualquer teste mexer no peso
	_dano()
	_contra_golpe()
	_guarda_quebra()
	_carga()
	_poderes_q()
	_sohei_kusarigama()
	_controles()
	await _empurrao()
	_madeira()
	_machadada()
	_maquina()
	await _obra()
	_nivel2()
	_caminho_magos()
	_dash_estilos()
	await _alma()
	_ferradura()
	_lote_2_7()
	_super()
	_super_uma_vez()
	_super_nivel1()
	_torretas()
	_catapulta()
	_equilibrio_2_10()
	_respawn_cresce()
	_bolo_mascara_cheia()
	await _mira()
	_placar()
	_reanimar()
	_alta_dinamica()
	await _magia()
	_assinaturas()
	_heroi_nv6()
	await _herois_regras()
	await _herois_2_27()
	await _herois_2_27b()
	_menos_empate()
	_multiplayer()
	_arena_chapeus()
	_poderes_2_29b()
	_sons_proprios()
	_relogio()  # por último: encerra a partida
	print("TESTES: %d/%d ok" % [_total - _falhas.size(), _total])
	if _falhas.is_empty():
		print("TESTES OK")
	for f in _falhas:
		print("TESTE FALHOU: ", f)
	get_tree().quit(1 if not _falhas.is_empty() else 0)


## Lote 2.7 (2026-11-06): Chi pelo tempo, Q mais curto, 3º tiro forte,
## Construtor sem variação e item perto da briga.
func _lote_2_7() -> void:
	var cfg = get_node("/root/Config").cfg
	var u = _alvo()
	if u == null:
		_check(false, "lote 2.7: faltou boneco")
		return
	u.set_class(load("res://config/classes/guerreiro.tres"))
	u.power = 0.0
	u._power_active_t = 0.0
	u._tick_power(1.0)
	_check(u.power >= cfg.power_regen - 0.01, "Chi por tempo: 1 s deveria dar %.1f, deu %.2f" % [cfg.power_regen, u.power])
	_check(_perto(u.quick_cooldown(), u.stats.skill_cooldown * cfg.rapida_cooldown_mult, 1e-4), "Q: recarga deveria ser skill_cooldown × rapida_cooldown_mult")
	for id in ["kitsune", "arqueiro"]:
		u.set_class(load("res://config/classes/%s.tres" % id))
		_check(u.stats.combo_tiros == 3, "%s deveria ter combo de 3 tiros" % id)
		var finais := []
		for i in 3:
			u._attack_cd = 0.0
			u._attack()
			finais.append(u._golpe_final)
			if u._windup_t > 0.0:
				u._attack_hit()
		_check(finais == [false, false, true], "%s: só o 3º tiro deveria ser o forte (%s)" % [id, str(finais)])
	var construtor = load("res://config/classes/construtor.tres")
	_check(construtor.skill == "armadilha", "Construtor: Q deveria armar estrepes")
	# Ciclo 2.21: toda classe do pátio tem dois caminhos opostos, que apontam
	# de volta para ela e têm nome curto (tapete, estandarte, avisos).
	for c in cfg.hat_classes():
		_check(c.caminhos.size() == 2 and c.caminhos[0] != c.caminhos[1], "%s: deveria ter 2 caminhos" % c.id)
		for e in c.caminhos:
			_check(e.classe_base == c.id and e.caminho_nome != "", "%s: caminho %s sem classe_base/nome" % [c.id, e.id])
	var p = game._spot_perto_da_briga()
	_check(p == null or p is Vector3, "item perto da briga: posição inválida")
	_check(cfg.final_arco_mult > 0.0 and cfg.final_arco_mult < 1.0, "golpe final vertical deveria ser mais estreito")


## Super (R): enche só jogando, cada classe solta o seu, a sombra esconde
## dos bots e o "maior" volta aos números normais depois.
func _super() -> void:
	var cfg = get_node("/root/Config").cfg
	var u = _alvo()
	if u == null:
		_check(false, "super: faltou boneco")
		return
	var inimigo = null
	for x in game.units:
		if x.alive and x.team != u.team:
			inimigo = x
			break
	var classes: Array = cfg.todas_classes()
	var poderes0: bool = game._poderes
	game._poderes = true  # sem a trava do nível 1 (testada em _super_nivel1)
	for c in classes:
		u.set_class(c)
		u.super_carga = 0.0
		u._tick_super(1.0)
		_check(u.super_carga == 0.0, "super: não deveria encher com o tempo")
		u.add_super(30.0)
		_check(_perto(u.super_carga, 30.0, 0.01), "super: add_super deveria somar")
		u.super_carga = 100.0
		u._dodge_t = 0.0
		u._equip_t = 0.0
		u._spin_t = 0.0
		u._ciranda_t = 0.0
		var mats0 := []
		for mi in u._meshes:
			mats0.append(mi.material_override)
		u._use_super()
		_check(u.super_carga == 0.0, "super %s: não saiu" % c.id)
		if c.super_tipo == "sombra":
			_check(u._sombra_t > 0.0, "super sombra: deveria ficar invisível")
			# O próprio time vê o corpo translúcido (fantasma), não opaco.
			var fantasma := false
			for mi in u._meshes:
				var m := mi.material_override as ShaderMaterial
				if m and m.shader == u.TOON_FANTASMA and float(m.get_shader_parameter("fantasma")) > 0.3:
					fantasma = true
			_check(fantasma, "super sombra: corpo deveria ficar translúcido para o time")
			if inimigo:
				var p0: Vector3 = u.global_position
				u.global_position = inimigo.global_position + Vector3(cfg.sombra_visto + 3.0, 0, 0)
				_check(u.na_sombra_para(inimigo), "super sombra: bot inimigo a %.0f m não deveria ver" % (cfg.sombra_visto + 3.0))
				u.global_position = p0
			u._fim_sombra()
			var volta := true
			for i in u._meshes.size():
				volta = volta and u._meshes[i].material_override == mats0[i] and not u._meshes[i].has_meta("sombra_orig")
			_check(volta, "super sombra: material do corpo deveria voltar ao opaco")
		else:
			_check(_perto(u.stats.power_radius, c.power_radius * cfg.super_mult_raio, 0.01), "super %s: raio deveria crescer" % c.id)
			u._tick_super(999.0)
			_check(u.stats == c, "super %s: stats deveria voltar ao normal" % c.id)
		u.reset_physics_interpolation()
	game._poderes = poderes0


## Ciclo 2.22: o Selo (Kitsune Sombria) e a Fúria (Ronin Oni) ferem no mesmo
## quadro em que saem e o dano devolve Chi; antes o Super lia isso como "não
## saiu", devolvia a barra e saía de novo a cada quadro (5 a 20 seguidos).
func _super_uma_vez() -> void:
	var cfg = get_node("/root/Config").cfg
	var u = _alvo()
	var inimigo = null
	for x in game.units:
		if x.alive and x.team != u.team and not x.is_player:
			inimigo = x
			break
	if u == null or inimigo == null:
		_check(false, "super uma vez: faltou boneco")
		return
	var antes = u.stats
	var p_ini: Vector3 = inimigo.global_position
	var poderes0: bool = game._poderes
	game._poderes = true
	for id in ["kitsune_sombria", "ronin_oni"]:
		u.set_class(load("res://config/classes/%s.tres" % id))
		inimigo.global_position = u.global_position + Vector3(2.0, 0, 0)
		inimigo.hp = inimigo.max_hp()
		inimigo._shield = 0.0
		u.aim_point = inimigo.global_position
		u.aim_dir = Vector3.RIGHT
		u.power = 0.0
		u.super_carga = 100.0
		u._dodge_t = 0.0
		u._equip_t = 0.0
		u._spin_t = 0.0
		u._ciranda_t = 0.0
		u._silence_t = 0.0
		var hp0: float = inimigo.hp
		u._use_super()
		_check(inimigo.hp < hp0, "super %s: deveria ferir o inimigo colado" % id)
		_check(u.super_carga == 0.0 and u._super_t > 0.0 and u._stats_normal != null,
			"super %s: ferir no mesmo quadro não pode devolver a barra (barra %.0f)" % [id, u.super_carga])
		_check(not u.super_ready(), "super %s: não deveria poder sair de novo no quadro seguinte" % id)
		u._tick_super(999.0)
		inimigo.hp = inimigo.max_hp()
	game._poderes = poderes0
	inimigo.global_position = p_ini
	inimigo.reset_physics_interpolation()
	u.set_class(antes)


## Ciclo 2.22: com a casa da classe no nível 1 o Super (R) fica travado (a barra
## enche igual); no nível 2 ele libera. Classe sem casa no pátio não trava.
func _super_nivel1() -> void:
	var of = null
	for o in game.oficinas:
		of = o
		break
	var u = null
	for x in game.units:
		if x.alive and not x.is_player and x.team == of.team:
			u = x
			break
	if of == null or u == null:
		_check(false, "super nível 1: faltou casa ou boneco")
		return
	var antes = u.stats
	var n0: int = of.nivel
	u.set_class(of.base)
	u.super_carga = 100.0
	of.nivel = 1
	_check(u.super_travado() and not u.super_ready(), "super nível 1: %s deveria ficar travado com a casa no Nv1" % of.base.id)
	of.nivel = 2
	_check(not u.super_travado() and u.super_ready(), "super nível 1: no Nv2 o R de %s deveria liberar" % of.base.id)
	of.nivel = n0
	u.set_class(antes)
	u.super_carga = 0.0


## Torretas: dano do virote, escudo segura torreta_bloqueio, escudo na hora
## devolve o virote, e a torreta derrubada volta a terreno vazio.
func _torretas() -> void:
	var cfg = get_node("/root/Config").cfg
	_check(game.torretas.size() == 4, "torretas: esperado 2 por time, há %d" % game.torretas.size())
	if game.torretas.is_empty():
		return
	var t = game.torretas[0]
	t.concluir_ja()
	_check(t.pronta() and _perto(t.hp, t.max_hp(), 0.01), "torreta pronta deveria nascer com vida cheia")
	var u = null
	for x in game.units:
		if x.alive and x.team != t.team and not x.is_player:
			u = x
			break
	if u == null:
		_check(false, "torretas: faltou alvo")
		return
	u.set_class(load("res://config/classes/guerreiro.tres"))
	u._sombra_t = 0.0
	u._shield = 0.0
	u._dodge_t = 0.0
	u.global_position = t.global_position + Vector3(6, 0, 0)
	var V = t.get_script().Virote
	# Quiz 2026-11-06: escudo virado para a torreta devolve o virote (sem janela
	# de tempo); de costas, o virote acerta normal.
	var casos = [["sem escudo", false, -1.0, cfg.torreta_dano], ["escudo", true, -1.0, 0.0], ["escudo de costas", true, 1.0, cfg.torreta_dano]]
	for c in casos:
		u.hp = u.max_hp()
		u._blocking = c[1]
		u._block_t = 5.0
		u._visual.rotation.y = atan2(c[2], 0.0)  # -1 = virado para a torreta (-x)
		var v = V.new()
		game.add_child(v)
		v.setup(game, t, t.global_position + Vector3(0, 2.6, 0), u)
		v._dir = Vector3(1, 0, 0)
		v._acertar()
		_check(_perto(u.max_hp() - u.hp, c[3], 0.05), "torreta %s: dano esperado %.1f, deu %.2f" % [c[0], c[3], u.max_hp() - u.hp])
		if c[0] == "escudo":
			_check(v._volta, "torreta: escudo virado deveria devolver o virote")
		v.queue_free()
	u._blocking = false
	t.take_hit(t.max_hp() + 1.0, 1 - t.team)
	_check(not t.pronta() and t.madeira_entregue == 0, "torreta derrubada deveria voltar a terreno vazio")
	# 2.12: com a obra no teto da madeira entregue e o estoque vazio, o Construtor
	# não fica parado na torreta (vai cortar); com estoque ou obra atrás do teto, vai.
	var m0: int = game.madeira[t.team]
	t.madeira_entregue = 1
	t.progresso = 1.0 / maxf(t.custo(), 1)
	game.madeira[t.team] = 0
	_check(game.torreta_para_construir(t.team, t.global_position, null) == null,
		"torreta no teto e sem estoque: o Construtor deveria ir cortar")
	game.madeira[t.team] = 1
	_check(game.torreta_para_construir(t.team, t.global_position, null) == t,
		"torreta com estoque no time: o Construtor deveria ir construir")
	game.madeira[t.team] = 0
	t.progresso = 0.0
	_check(game.torreta_para_construir(t.team, t.global_position, null) == t,
		"torreta com madeira entregue e obra atrás: o Construtor deveria ir construir")
	t.madeira_entregue = 0
	game.madeira[t.team] = m0
	# 2.12d: com outra torreta do time de pé e o mago podendo subir, o terreno
	# vazio espera (a madeira vai antes para o mago).
	var mago = null
	for of in game.oficinas:
		if of.team == t.team and of.caminho >= 0 and of.estado == of.Estado.PRONTA and not of.selada:
			mago = of
	var outra = null
	for x in game.torretas:
		if x != t and x.team == t.team:
			outra = x
	_check(mago != null and outra != null, "torreta x mago: faltou o mago pronto ou a 2ª torreta do time")
	if mago and outra:
		var n0: int = mago.nivel
		mago.nivel = cfg.mago_nivel_max - 1
		outra.concluir_ja()
		_check(game.torreta_para_obra(t.team, t.global_position) == null,
			"torreta vazia deveria esperar o mago subir com a outra torreta de pé")
		var niveis := {}
		for of in game.oficinas:
			if of.team == t.team:
				niveis[of] = of.nivel
				of.nivel = cfg.mago_nivel_max
		_check(game.torreta_para_obra(t.team, t.global_position) == t,
			"casas no máximo: a torreta vazia volta a ser obra")
		for of in niveis:
			of.nivel = niveis[of]
		mago.nivel = n0
		outra.take_hit(outra.max_hp() + 1.0, 1 - outra.team)


## Catapulta (2.9b): sobe, lança com força 1 e cai perto da muralha inimiga;
## no ar nada acerta; no chão volta a ter física própria.
func _catapulta() -> void:
	var cfg := Config.cfg
	if game.catapultas.is_empty():
		_check(false, "catapulta: o mapa não tem catapulta_spot")
		return
	var cat: Catapulta = game.catapultas[0]
	var u: Unit = null
	for c in game.units:
		if c.team == cat.team and c.alive and not c.is_player:
			u = c
			break
	_check(cat.pronta(), "catapulta deveria começar pronta")
	cat.embarcar(u)
	_check(u.em_voo and cat.passageiro == u, "catapulta: embarcar deveria prender o passageiro")
	var hp0 := u.hp
	u.take_damage(50.0, null, Vector3.FORWARD)
	_check(_perto(u.hp, hp0, 0.01), "catapulta: no ar nada acerta")
	cat.forca = 1.0
	var alvo := cat.ponto_queda(1.0)
	cat.lancar()
	_check(not cat.pronta() and cat.passageiro == null, "catapulta: lançou e entrou em recarga")
	for i in int((cfg.catapulta_voo + 0.5) * 60.0):
		cat._physics_process(1.0 / 60.0)
	_check(not u.em_voo, "catapulta: depois do voo o passageiro volta ao chão")
	_check(_perto(u.global_position.x, alvo.x, 1.0) and _perto(u.global_position.z, alvo.z, 1.0),
		"catapulta: deveria cair em x=%.1f, caiu em x=%.1f" % [alvo.x, u.global_position.x])
	var fwd: Vector3 = game.arena.forward(cat.team)
	_check(alvo.x * fwd.x > game.arena.map.castle_distance * 0.3, "catapulta: a queda com força 1 fica na metade inimiga")


## Ciclo 2.10: atirar deixa lento, Samurai pelas costas, queda do shuriken,
## escolta da máscara.
func _equilibrio_2_10() -> void:
	var cfg = get_node("/root/Config").cfg
	var a = null
	var b = null
	for x in game.units:
		if x.alive and not x.is_player:
			if a == null and x.team == 0:
				a = x
			elif b == null and x.team == 1:
				b = x
	if a == null or b == null:
		_check(false, "2.10: faltou boneco")
		return
	a.set_class(load("res://config/classes/arqueiro.tres"))
	a._boost_t = 0.0
	a._slow_t = 0.0
	a.carried_princess = null
	a._tiro_lento_t = 0.0
	a._sombra_t = 0.0
	var livre = a.current_speed()
	a._tiro_lento_t = 0.3
	_check(_perto(a.current_speed(), livre * cfg.atirador_lento_mult, 0.01), "atirou: deveria andar a %.2f da velocidade" % cfg.atirador_lento_mult)
	a._tiro_lento_t = 0.0
	var p = load("res://scripts/items/projectile.gd").new()
	p.owner_unit = a
	_check(_perto(p.queda_em(4.0), 1.0, 1e-4), "shuriken perto: dano cheio")
	_check(_perto(p.queda_em(a.stats.attack_range), a.stats.queda_dano_min, 1e-3), "shuriken no alcance: dano mínimo")
	p.free()
	var sam = load("res://config/classes/guerreiro.tres")
	_check(sam.dano_costas > 0.0, "Samurai deveria ter bônus pelas costas")
	a.set_class(sam)
	b._visual.rotation.y = atan2(1.0, 0.0)  # b olha para +x
	_check(_perto(a.mult_costas(b, Vector3(-1, 0, 0)), 1.0, 1e-4), "Samurai de frente: sem bônus")
	_check(_perto(a.mult_costas(b, Vector3(1, 0, 0)), 1.0 + sam.dano_costas, 1e-4), "Samurai pelas costas: com bônus")
	_check(_perto(a.mult_costas(b, Vector3(0, 0, 1)), 1.0 + sam.dano_costas, 1e-4), "Samurai pelo lado: com bônus")
	var ronin = load("res://config/classes/ronin_oni.tres")
	var ninja = load("res://config/classes/arqueiro.tres")
	_check(ronin.move_speed < sam.move_speed and ninja.move_speed > sam.move_speed, "velocidades: Ninja > Samurai > Ronin")
	_check(ronin.max_hp > sam.max_hp and sam.max_hp > ninja.max_hp, "vidas: Ronin > Samurai > Ninja")


## Mira 2.11: o tiro vai onde o jogador clica, em qualquer altura. Clicar
## num inimigo mira NELE (não no chão atrás dele), e parapeito da ponte /
## travas do rio seguram quem anda mas deixam tiro e mira passarem.
func _mira() -> void:
	var Cfg = get_node("/root/Config")
	# A trava do rio continua "chão alto" para bolo/enfeites (máscara padrão),
	# mas o raio do tiro (LAYER_WORLD) passa por ela e acha a água.
	_check(game.arena.ground_y(0.0, 14.0) > 2.5, "trava do rio deveria contar como chão alto por padrão")
	_check(game.arena.ground_y(0.0, 14.0, 30.0, Cfg.LAYER_WORLD) < 0.3, "o raio do tiro deveria atravessar a trava do rio")
	var a = game.player
	var e = null
	for u in game.units:
		if u.alive and u != a and u.team != a.team:
			e = u
			break
	if a == null or e == null:
		_check(false, "mira: faltou boneco")
		return
	var brains := [a.brain, e.brain]
	a.brain = null
	e.brain = null
	for u in [a, e]:
		u.move_intent = Vector3.ZERO
		u.wants_attack = false
	var cam = game.camera
	cam.set_process(false)
	var alvo_cam = cam.target
	# [nome, atirador, inimigo, classe]: ponte (o bug do Julio), rio (trava
	# invisível no caminho) e chão plano (controle).
	var casos := [
		["da ponte para a margem (arco)", Vector3(2, 0, 0), Vector3(6.5, 0, 8), "arqueiro_yumi"],
		["da ponte para a margem (reto)", Vector3(2, 0, 0), Vector3(6.5, 0, 8), "arqueiro"],
		["atravessando o rio", Vector3(8, 0, 22), Vector3(-8, 0, 22), "arqueiro_yumi"],
		["chão plano", Vector3(14, 0, 0), Vector3(20, 0, 3), "arqueiro"],
	]
	for c in casos:
		var p0: Vector3 = c[1]
		var p1: Vector3 = c[2]
		p0.y = game.arena.ground_y(p0.x, p0.z) + 0.1
		p1.y = game.arena.ground_y(p1.x, p1.z) + 0.1
		a.set_class(load("res://config/classes/%s.tres" % c[3]))
		a.global_position = p0
		a.reset_physics_interpolation()
		e.global_position = p1
		e.reset_physics_interpolation()
		e.hp = e.max_hp()
		e._shield = 0.0
		e._blocking = false
		e._dodge_t = 0.0
		cam.target = a
		for i in 3:
			await get_tree().physics_frame
		cam.snap()
		# "Clique" no peito do inimigo.
		var tela: Vector2 = cam.unproject_position(e.global_position + Vector3(0, 1.0, 0))
		var aim: Vector3 = cam.aim_na_tela(tela)
		_check(cam.mira_unidade == e, "%s: clicar no inimigo deveria mirar nele" % c[0])
		_check(aim.distance_to(e.global_position) < 0.5, "%s: ponto de mira deveria ser onde o inimigo está" % c[0])
		a.aim_unit = cam.mira_unidade
		var to: Vector3 = aim - a.global_position
		to.y = 0
		a.aim_dir = to.normalized()
		a.aim_point = aim
		var hp0: float = e.hp
		a._attack_cd = 0.0
		var p = a._shoot_arrow(1.0, 1.0)
		for i in 180:
			# Os dois ficam parados enquanto o tiro voa.
			a.global_position = p0
			a.velocity = Vector3.ZERO
			e.global_position = p1
			e.velocity = Vector3.ZERO
			if not is_instance_valid(p):
				break
			await get_tree().physics_frame
		_check(e.hp < hp0, "%s: o tiro deveria acertar quem foi clicado" % c[0])
	a.brain = brains[0]
	e.brain = brains[1]
	cam.target = alvo_cam
	cam.set_process(true)


## 2.13: máscara no peso máximo não aceita espírito e o bot com bolo na mão
## não fica plantado embaixo dela (o "guarda-costas eterno" do Julio).
func _bolo_mascara_cheia() -> void:
	var u: Unit = null
	for b in game.units:
		if b.brain is BotBrain and b.alive and not b.carried_princess:
			u = b
			break
	if u == null:
		_check(false, "bolo: faltou bot vivo")
		return
	var p = game.princesses[u.team]
	var fat0: float = p.fatness
	var cake0: bool = u.has_cake
	p.fatness = 1.0
	_check(not p.feed(), "máscara cheia não deveria aceitar espírito")
	u.has_cake = true
	var brain: BotBrain = u.brain
	brain._think()
	_check(brain._goal.distance_to(p.global_position) > 1.0,
			"bot com bolo e máscara cheia não deveria acampar embaixo dela")
	p.fatness = fat0
	p._apply_fatness()
	u.has_cake = cake0


## 2.13: a morte pesa mais no fim: renascer cresce com o tempo e tem teto.
func _respawn_cresce() -> void:
	var cfg = Config.cfg
	var t0: float = game._time
	var sb: bool = game.sandbox
	game.sandbox = false
	game._time = 0.0
	_check(_perto(game.respawn_atual(), cfg.respawn_time, 0.01),
			"respawn: no início deveria ser o base")
	game._time = 240.0
	_check(_perto(game.respawn_atual(), cfg.respawn_time + cfg.respawn_cresce * 4.0, 0.01),
			"respawn: aos 4 min deveria ter crescido respawn_cresce por minuto")
	game._time = 3600.0
	_check(_perto(game.respawn_atual(), cfg.respawn_max, 0.01),
			"respawn: deveria parar no teto respawn_max")
	game.sandbox = true
	_check(_perto(game.respawn_atual(), cfg.respawn_time, 0.01),
			"respawn: no modo teste não deveria crescer")
	game.sandbox = sb
	game._time = t0


## Dash por personalidade: só valores conhecidos (o resto cairia no padrão calado).
func _dash_estilos() -> void:
	var cfg = get_node("/root/Config").cfg
	for c in cfg.todas_classes():
		_check(c.dash_estilo in ["", "rolar", "rolamento", "ninja", "chama", "polvora", "tropeco"], "dash: estilo desconhecido em %s: '%s'" % [c.id, c.dash_estilo])


## Placar (Tab, Ciclo 2.16): todo boneco tem linha, todo campo tem peso
## no game_config, a conta é Σ campo × peso e o abate dá abate/assistência/morte.
func _placar() -> void:
	var cfg = get_node("/root/Config").cfg
	var pl = game.placar
	_check(pl != null, "placar: game.placar não existe")
	if pl == null:
		return
	_check(pl.time(0).size() + pl.time(1).size() == game.units.size(), "placar: nem todo boneco tem linha")
	for c in pl.CAMPOS:
		_check(cfg.get("pts_" + c) != null, "placar: falta pts_%s no GameConfig" % c)
	var l := {"abates": 2.0, "assist": 1.0, "madeira": 3.0, "obra_s": 2.5}
	var esperado: int = int(round(2 * cfg.pts_abates + cfg.pts_assist + 3 * cfg.pts_madeira + 2.5 * cfg.pts_obra_s))
	_check(pl.pontos_de(l, cfg) == esperado, "placar: conta deu %d, esperado %d" % [pl.pontos_de(l, cfg), esperado])
	# Abate de verdade: c bate, a mata -> a abate, c assistência, b morte.
	var b = null
	var a = null
	var c = null
	for u in game.units:
		if not u.alive or u.is_player:
			continue
		if b == null:
			b = u
		elif u.team != b.team and a == null:
			a = u
		elif a != null and u.team == a.team and c == null:
			c = u
	if b == null or a == null or c == null:
		return
	var la: Dictionary = pl.linha(a).duplicate()
	var lb: Dictionary = pl.linha(b).duplicate()
	var lc: Dictionary = pl.linha(c).duplicate()
	b._dodge_t = 0.0
	b._blocking = false
	b._shield = 0.0
	b.hp = b.max_hp()
	b.take_damage(5.0, c, Vector3.RIGHT)
	b.take_damage(b.hp + 10.0, a, Vector3.RIGHT)
	_check(not b.alive, "placar: o alvo do teste não morreu")
	_check(pl.linha(a).abates == la.abates + 1, "placar: quem matou não ganhou o abate")
	_check(pl.linha(c).assist == lc.assist + 1, "placar: quem ajudou não ganhou a assistência")
	_check(pl.linha(a).assist == la.assist, "placar: quem matou não ganha assistência junto")
	_check(pl.linha(b).mortes == lb.mortes + 1, "placar: quem caiu não ganhou a morte")
	_check(pl.linha(c).dano >= lc.dano + 5.0 - 0.01, "placar: dano de quem ajudou não contou")


## Reanimar (Ciclo 2.18): o caído levanta com a classe que tinha, metade da
## vida e intocável; o canal não para com dano; Kitsune mais rápida; time
## todo caído não reanima; quem puxa arrasta o corpo na corda.
func _reanimar() -> void:
	var cfg = get_node("/root/Config").cfg
	var r = game.reanimar
	_check(r != null, "reanimar: game.reanimar não existe")
	if r == null:
		return
	_check(cfg.reanimar_tempo > 0.0 and cfg.reanimar_vida > 0.0 and cfg.reanimar_vida <= 1.0, "reanimar: tempo/vida fora do lugar")
	_check(cfg.reanimar_mago_mult >= 1.0 and cfg.reanimar_mago_mult <= cfg.reanimar_mago_mult_max, "reanimar: mago deveria ser 1× < começo <= máximo")
	_check(cfg.reanimar_ritmo_espera > 0.0 and cfg.reanimar_ritmo_espera < 1.0, "reanimar: esperar deveria alongar a janela")
	var a = null
	var b = null
	var inimigo = null
	for u in game.units:
		if not u.alive or u.is_player or u.carried_princess or u.carried_tora or u == r.boneco_treino:
			continue
		if a == null:
			a = u
		elif u.team == a.team and b == null:
			b = u
		elif u.team != a.team and inimigo == null:
			inimigo = u
	if a == null or b == null or inimigo == null:
		_check(false, "reanimar: faltou boneco")
		return
	var guerreiro = load("res://config/classes/guerreiro.tres")
	a.set_class(guerreiro)
	b.set_class(load("res://config/classes/arqueiro.tres"))
	var classe_b = b.stats
	for u in [a, b]:
		u._dodge_t = 0.0
		u._equip_t = 0.0
		u._blocking = false
		u._shield = 0.0
		u._intocavel_t = 0.0
		u.hp = u.max_hp()
	var antes: float = game.placar.linha(a).get("reanimar", 0.0)
	b.take_damage(b.hp + 50.0, inimigo, Vector3.RIGHT)
	_check(not b.alive, "reanimar: o alvo do teste não caiu")
	_check(r.pode_reanimar(b), "reanimar: recém-caído deveria ser reanimável")
	a.global_position = b.global_position + Vector3(1.0, 0, 0)
	_check(_perto(r.ritmo(b), cfg.reanimar_ritmo_espera, 1e-4), "reanimar: caído com aliado perto deveria esperar mais devagar")
	_check(r.velocidade(a) == 1.0, "reanimar: classe comum deveria ter velocidade 1")
	# Time inteiro caído: ninguém reanima.
	var vivos := []
	for u in game.units:
		if u.team == b.team and u.alive:
			vivos.append(u)
			u.alive = false
	_check(not r.pode_reanimar(b), "reanimar: com o time todo caído não deveria dar")
	_check(r.ritmo(b) == 1.0, "reanimar: time todo caído deveria ter relógio normal")
	for u in vivos:
		u.alive = true
	# Canal: segura F; o dano não para.
	a.wants_reanimar = true
	r.tick(0.05)
	_check(a.reanimando == b and b.reanimador == a, "reanimar: segurar F colado deveria começar")
	a.take_damage(1.0, inimigo, Vector3.RIGHT)
	r.tick(0.05)
	_check(a.reanimando == b, "reanimar: tomar dano não deveria parar o canal")
	# Arrasto: quem puxa se afasta e o corpo vem na corda.
	a.global_position = b.global_position + Vector3(1.5, 0, 0)
	r.tick(0.05)
	_check(a.global_position.distance_to(b.global_position) <= cfg.reanimar_corda + 0.05, "reanimar: o corpo deveria vir atrás na corda")
	for i in int(ceil(cfg.reanimar_tempo / 0.1)) + 2:
		if b.alive:
			break
		a.wants_reanimar = true
		r.tick(0.1)
	_check(b.alive, "reanimar: deveria levantar em reanimar_tempo s")
	_check(b.stats == classe_b, "reanimar: deveria levantar com a classe que tinha")
	_check(_perto(b.hp, b.max_hp() * cfg.reanimar_vida, 0.5), "reanimar: vida ao levantar deveria ser reanimar_vida")
	_check(a.reanimando == null and b.reanimador == null, "reanimar: canal deveria acabar ao levantar")
	_check(game.placar.linha(a).get("reanimar", 0.0) == antes + 1.0, "reanimar: placar não contou")
	var hp0: float = b.hp
	b.take_damage(10.0, inimigo, Vector3.RIGHT)
	_check(b.hp == hp0, "reanimar: recém-reanimado deveria estar intocável")
	b._intocavel_t = 0.0
	a.wants_reanimar = false
	# Desistir no meio da reanimação (bug do Julio 2026-11-08: levantava mesmo
	# assim): ninguém mais reanima e renasce rápido, mas não na hora.
	b.take_damage(b.hp + 50.0, inimigo, Vector3.RIGHT)
	var espera: float = b._respawn_t
	a.global_position = b.global_position + Vector3(1.0, 0, 0)
	a.wants_reanimar = true
	r.tick(0.05)
	_check(a.reanimando == b, "reanimar: deveria começar de novo")
	_check(r.ritmo(b) == 0.0, "reanimar: sendo reanimado, o relógio do caído deveria parar")
	r.desistir(b)
	_check(b.desistiu and not r.pode_reanimar(b), "desistir: deveria travar a reanimação")
	_check(a.reanimando == null and b.reanimador == null, "desistir: deveria soltar quem estava reanimando")
	var rapido: float = maxf(espera * cfg.reanimar_desistir_frac, cfg.reanimar_desistir_min)
	_check(b._respawn_t <= rapido + 0.01, "desistir: deveria renascer em reanimar_desistir_frac da espera (%.1f > %.1f)" % [b._respawn_t, rapido])
	_check(b._respawn_t >= minf(espera, cfg.reanimar_desistir_min) - 0.01, "desistir logo ao cair: deveria esperar a contagem rápida inteira")
	for i in 40:
		a.wants_reanimar = true
		r.tick(0.1)
	_check(not b.alive, "desistir: aliado não deveria conseguir levantar quem desistiu")
	r.levantar(b, a)
	_check(not b.alive, "desistir: levantar() direto também não deveria valer")
	a.wants_reanimar = false
	b._respawn()
	_check(b.alive and not b.desistiu, "desistir: renascer deveria limpar o estado")
	# O pedaço da barra que já correu caído sai da contagem do desistir (Julio
	# 2026-11-09: desistir tarde não pode recomeçar a contagem do zero).
	var t_total := 12.0
	var t_rapido := maxf(t_total * cfg.reanimar_desistir_frac, cfg.reanimar_desistir_min)
	_check(_perto(r.espera_ao_desistir(t_total, t_total), t_rapido, 0.01), "desistir: sem espera passada, contagem rápida inteira")
	_check(_perto(r.espera_ao_desistir(t_total, t_total - 2.0), t_rapido - 2.0, 0.01), "desistir: 2 s já esperados deveriam sair da contagem")
	_check(r.espera_ao_desistir(t_total, t_total - t_rapido - 1.0) == 0.0, "desistir: já esperou mais que a contagem rápida = renasce na hora")
	for rest in [t_total, 9.0, 5.0, 1.0, 0.2]:
		_check(r.espera_ao_desistir(t_total, rest) <= rest + 1e-4, "desistir: nunca pode demorar mais que a espera normal (%.1f)" % rest)
	_check(r.espera_ao_desistir(2.0, 2.0) <= 2.0 + 1e-4, "desistir: espera curta (menor que o mínimo) não pode crescer")
	# Kitsune: começa em reanimar_mago_mult (nível baixo).
	a.set_class(load("res://config/classes/kitsune.tres"))
	_check(a.eh_mago(), "reanimar: kitsune deveria contar como mago")
	_check(r.velocidade(a) >= cfg.reanimar_mago_mult - 1e-4 and r.velocidade(a) <= cfg.reanimar_mago_mult_max + 1e-4, "reanimar: mago fora da faixa")
	a.set_class(guerreiro)


## Alta dinâmica (Ciclo 2.19): a escada de degraus desliga primeiro os ajustes
## da Alta (resolução 80% -> sem glow -> sem contorno), depois cai de nível, e
## para na Mínima. Também confere a casca de contorno do cenário e o FXAA.
func _alta_dinamica() -> void:
	var aq = load("res://scripts/fx/auto_quality.gd")
	_check(aq.degrau(3, 0) == Vector2i(3, 1), "alta dinâmica: 1º degrau é resolução 80%")
	_check(aq.degrau(3, 1) == Vector2i(3, 2), "alta dinâmica: 2º degrau é sem glow")
	_check(aq.degrau(3, 2) == Vector2i(3, 3), "alta dinâmica: 3º degrau é sem contorno")
	_check(aq.degrau(3, 3) == Vector2i(2, 0), "alta dinâmica: depois cai para a Média")
	_check(aq.degrau(2, 0) == Vector2i(1, 0), "alta dinâmica: Média cai para a Baixa")
	_check(aq.degrau(0, 0) == Vector2i(0, 0), "alta dinâmica: para na Mínima")
	var settings = get_node("/root/Settings")
	_check(settings.ALTA_AJUSTES.size() == 4, "alta dinâmica: 4 estados de ajuste")
	var arena = game.arena
	_check(arena.get_node_or_null("CascaContorno") != null, "casca de contorno existe no cenário")
	var casca = arena.get_node_or_null("CascaContorno")
	if casca:
		_check(casca.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "casca não projeta sombra")
		_check(casca.visible == (settings.quality >= 3), "casca aparece só na Alta")
	# Nos pedaços do cenário, nenhum material de cor pode manter o next_pass:
	# o contorno deles agora é a casca (senão pagaria as 2 chamadas de novo).
	var dupla := false
	for mi in arena.get_children():
		if mi is MeshInstance3D and String(mi.name).begins_with("Cenario_"):
			for s in mi.mesh.get_surface_count():
				var m = mi.mesh.surface_get_material(s)
				if m and m.next_pass:
					dupla = true
	_check(not dupla, "pedaços do cenário sem next_pass (contorno só na casca)")


func _check(ok: bool, nome: String) -> void:
	_total += 1
	if not ok:
		_falhas.append(nome)


func _perto(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


## Conteúdo: tudo que o game_config lista existe e tem números com sentido.
func _dados() -> void:
	var cfg = get_node("/root/Config").cfg
	var classes: Array = cfg.todas_classes()
	classes.append(cfg.villager)
	for c in classes:
		_check(c != null, "classe nula no game_config")
		if c == null:
			continue
		_check(c.model != null, "classe %s sem modelo" % c.id)
		_check(c.max_hp > 0.0, "classe %s com vida <= 0" % c.id)
		_check(c.move_speed > 0.0, "classe %s com velocidade <= 0" % c.id)
	# Ficha do menu (seção Classes): toda classe jogável tem epíteto e identidade.
	for c in cfg.todas_classes():
		if c:
			_check(c.epiteto != "" and c.descricao != "", "classe %s sem epíteto/descrição na ficha" % c.id)
	_check(not cfg.themes.is_empty(), "nenhum tema em game_config.themes")
	for t in cfg.themes:
		_check(t != null, "tema nulo em game_config.themes")
	_check(not cfg.maps.is_empty(), "nenhum mapa em game_config.maps")
	_check(cfg.carrier_damage_mult > 0.0 and cfg.carrier_damage_mult <= 1.0,
		"carrier_damage_mult fora de (0, 1]")


func _alvo():
	for u in game.units:
		if u.alive and not u.is_player:
			return u
	return null


## Dano, carregador, esquiva, escudo e cura.
func _dano() -> void:
	var u = _alvo()
	_check(u != null, "nenhum boneco vivo para testar")
	if u == null:
		return
	var cfg = get_node("/root/Config").cfg
	var dir := Vector3(1, 0, 0)
	u._blocking = false
	u._dodge_t = 0.0
	u._shield = 0.0
	u.hp = u.max_hp()

	var antes: float = u.hp
	u.take_damage(10.0, null, dir)
	_check(_perto(antes - u.hp, 10.0, 0.01), "dano simples: esperado 10, deu %.2f" % (antes - u.hp))

	# Quem carrega a máscara leva menos dano.
	u.hp = u.max_hp()
	antes = u.hp
	u.carried_princess = game.princesses[0]
	u.take_damage(10.0, null, dir)
	u.carried_princess = null
	_check(_perto(antes - u.hp, 10.0 * cfg.carrier_damage_mult, 0.01),
		"carregador: esperado %.1f, deu %.2f" % [10.0 * cfg.carrier_damage_mult, antes - u.hp])

	# Esquiva (dash) é invulnerável.
	u.hp = u.max_hp()
	u._dodge_t = 0.2
	u.take_damage(10.0, null, dir)
	_check(_perto(u.hp, u.max_hp(), 0.01), "dash deveria anular o dano")
	# Esquiva perfeita: golpe de alguém dentro do dash dá Chi.
	var outro = null
	for x in game.units:
		if x.alive and x.team != u.team:
			outro = x
			break
	u.power = 0.0
	u._esquiva_t = -10.0
	u.take_damage(10.0, outro, dir)
	_check(_perto(u.hp, u.max_hp(), 0.01) and u.power >= cfg.chi_esquiva - 0.01,
		"esquiva perfeita: sem dano e +%.0f de Chi (Chi %.1f)" % [cfg.chi_esquiva, u.power])
	u._dodge_t = 0.0
	u.power = 0.0

	# Escudo absorve antes da vida.
	u.hp = u.max_hp()
	u._shield = 6.0
	u.take_damage(10.0, null, dir)
	_check(_perto(u.max_hp() - u.hp, 4.0, 0.01), "escudo de 6 contra 10: esperado 4 na vida")
	_check(_perto(u._shield, 0.0, 0.01), "escudo deveria zerar")

	# Cura não passa do máximo.
	u.hp = u.max_hp() - 5.0
	u.heal(50.0)
	_check(_perto(u.hp, u.max_hp(), 0.01), "cura passou do máximo")

	# Autocura do Q vale cura_propria_mult da cura em aliado (2.25b).
	var stats_antigos = u.stats
	var stats_cura = u.stats.duplicate()
	stats_cura.heal_amount = 10.0
	stats_cura.heal_radius = 0.1  # pequeno para só pegar ele mesmo
	u.stats = stats_cura
	u.hp = u.max_hp() - 50.0
	var hp_antes: float = u.hp
	u._heal()
	u.stats = stats_antigos
	var esperado: float = 10.0 * cfg.vida_mult * cfg.cura_propria_mult
	_check(_perto(u.hp - hp_antes, esperado, 0.01),
		"autocura: esperado %.1f, deu %.2f" % [esperado, u.hp - hp_antes])


## Contra-golpe: bloqueio erguido há ≤ parry_janela s anula o golpe de perto,
## atordoa quem bateu e devolve parry_mult × dano; erguido antes disso é só
## bloqueio (reduz pela block_reduction).
func _contra_golpe() -> void:
	var cfg = get_node("/root/Config").cfg
	var d = null
	var a = null
	for u in game.units:
		if u.alive and not u.is_player:
			if d == null:
				d = u
			elif a == null and u.team != d.team:
				a = u
	if d == null or a == null:
		_check(false, "contra-golpe: faltou boneco")
		return
	d.set_class(load("res://config/classes/guerreiro.tres"))
	var dir := Vector3(1, 0, 0)  # golpe de a para d
	d._visual.rotation.y = atan2(-dir.x, -dir.z)  # d de frente para a
	for x in [d, a]:
		x._dodge_t = 0.0
		x._shield = 0.0
		x.hp = x.max_hp()
	d._blocking = true
	d._block_t = cfg.parry_janela * 0.5
	a._attack_cd = 0.0
	d.take_damage(20.0, a, dir, 1.0, true)
	_check(_perto(d.hp, d.max_hp(), 0.01), "contra-golpe: quem bloqueou na hora não deveria levar dano (levou %.1f)" % (d.max_hp() - d.hp))
	var volta: float = d.stats.damage * cfg.parry_mult
	_check(_perto(a.max_hp() - a.hp, volta, 0.5), "contra-golpe: devolvido esperado %.1f, deu %.1f" % [volta, a.max_hp() - a.hp])
	_check(a._attack_cd >= cfg.parry_atordoa - 0.01, "contra-golpe: quem bateu deveria ficar atordoado")
	# Bloqueio velho: só reduz.
	d.hp = d.max_hp()
	d._block_t = cfg.parry_janela + 0.5
	d.take_damage(20.0, a, dir, 1.0, true)
	_check(_perto(d.max_hp() - d.hp, 20.0 * (1.0 - d.stats.block_reduction), 0.01), "bloqueio fora da janela deveria só reduzir")
	d._blocking = false
	d.hp = d.max_hp()
	a.hp = a.max_hp()


## Ciclo 2.26: guarda que quebra, rastro da barra de vida e respingo de tinta.
func _guarda_quebra() -> void:
	var cfg = get_node("/root/Config").cfg
	var d = null
	var a = null
	for u in game.units:
		if u.alive and not u.is_player:
			if d == null:
				d = u
			elif a == null and u.team != d.team:
				a = u
	if d == null or a == null:
		_check(false, "guarda: faltou boneco")
		return
	d.set_class(load("res://config/classes/guerreiro.tres"))
	var dir := Vector3(1, 0, 0)
	d._visual.rotation.y = atan2(-dir.x, -dir.z)
	d._dodge_t = 0.0
	d._shield = 0.0
	d.carried_princess = null
	d.hp = d.max_hp()
	d._blocking = true
	d._block_t = cfg.parry_janela + 0.5
	d.guarda = 0.0
	# Golpe de perto soma dano/vida; de longe soma × guarda_tiro; torreta não soma.
	d.take_damage(20.0, a, dir, 1.0, true)
	var g1: float = d.guarda
	_check(g1 > 0.0 and g1 < cfg.guarda_limite, "guarda: um golpe na defesa deveria gastar um pouco (%.3f)" % g1)
	d.take_damage(20.0, a, dir, 1.0, false)
	_check(_perto(d.guarda - g1, g1 * cfg.guarda_tiro, 0.002), "guarda: tiro deveria gastar × guarda_tiro")
	var g2: float = d.guarda
	d.take_damage(20.0, a, dir, 1.0, false, "torreta")
	_check(_perto(d.guarda, g2, 0.0001), "guarda: virote de torreta não deveria gastar a guarda")
	# Recupera só depois de guarda_espera s sem apanhar.
	d._tick_guarda(cfg.guarda_espera * 0.5)
	_check(_perto(d.guarda, g2, 0.0001), "guarda: não deveria recuperar antes de guarda_espera")
	d._tick_guarda(cfg.guarda_espera)
	_check(d.guarda < g2, "guarda: deveria recuperar depois de guarda_espera")
	# Perto do limite: o próximo golpe quebra, atordoa e trava a defesa.
	d.guarda = cfg.guarda_limite - 0.001
	var chi0: float = a.power
	d.take_damage(20.0, a, dir, 1.0, true)
	_check(not d._blocking, "guarda: quebrada deveria baixar a defesa")
	_check(d._guarda_trava_t > 0.0 and d._preso_t > 0.0, "guarda: quebrada deveria atordoar e travar a defesa")
	_check(_perto(d.guarda, 0.0, 0.0001), "guarda: depois de quebrar volta a zero")
	_check(a.power > chi0, "guarda: quem quebrou deveria ganhar Chi")
	d.wants_block = true
	d._update_skill(0.016, true)
	_check(not d._blocking, "guarda: não deveria defender enquanto a guarda está travada")
	d.wants_block = false
	d._guarda_trava_t = 0.0
	d._preso_t = 0.0
	d._anim_lock = 0.0
	d._attack_cd = 0.0
	# Rastro: o branco fica na vida de antes e desce depois da espera.
	d.hp = d.max_hp()
	d._tick_rastro(0.016)
	d.take_damage(40.0, a, dir, 1.0, true)
	var r: float = d.hp_ratio()
	_check(r < 1.0 and d.hp_rastro > r + 0.1, "rastro: deveria ficar branco onde a vida estava (%.2f, vida %.2f)" % [d.hp_rastro, r])
	d._tick_rastro(cfg.rastro_espera * 0.5)
	_check(d.hp_rastro > r + 0.1, "rastro: não deveria descer antes da espera")
	for i in 120:
		d._tick_rastro(1.0 / 60.0)
	_check(_perto(d.hp_rastro, d.hp_ratio(), 0.001), "rastro: deveria chegar à vida atual")
	# Respingo: um MultiMesh só no jogo, cresce um por golpe.
	load("res://scripts/fx/respingo.gd").em(game, d.global_position, dir, Color.RED, 0.8)
	var rs = game.get_node_or_null("Respingo")
	_check(rs != null and rs.multimesh.visible_instance_count >= 1, "respingo: deveria existir no jogo")
	d.hp = d.max_hp()
	a.hp = a.max_hp()


## Carga máxima: flecha/shuriken atravessa carga_perfura; bomba fica maior.
func _carga() -> void:
	var cfg = get_node("/root/Config").cfg
	var u = _alvo()
	if u == null:
		return
	var p = game.spawn_projectile(u, Vector3(0, -50, 0), Vector3.RIGHT, "shuriken")
	p.set_physics_process(false)
	p.carregar()
	_check(p.perfura == cfg.carga_perfura, "carga: shuriken cheia deveria atravessar %d" % cfg.carga_perfura)
	var b = game.spawn_projectile(u, Vector3(0, -50, 0), Vector3.RIGHT, "bomba")
	b.set_physics_process(false)
	b.carregar()
	_check(_perto(b.raio_mult, cfg.carga_raio_bomba, 0.001), "carga: bomba cheia deveria crescer o raio")
	p.queue_free()
	b.queue_free()


## Controles do 2.5: direito defende em TODA classe; Q (rápida) tem recarga
## e todas as classes com chapéu têm um Q; E é o poder de Chi.
func _controles() -> void:
	var cfg = get_node("/root/Config").cfg
	var im = InputMap
	_check(im.has_action("quick") and im.has_action("block") and im.has_action("power") and im.has_action("interact"), "controles: faltou ação quick/block/power/interact")
	var tecla := func(acao: String) -> int:
		for ev in InputMap.action_get_events(acao):
			if ev is InputEventKey:
				return ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
		return -1
	_check(tecla.call("quick") == KEY_Q, "controles: Q deveria ser a habilidade rápida")
	_check(tecla.call("power") == KEY_E, "controles: E deveria ser o poder de Chi")
	_check(tecla.call("interact") == KEY_F, "controles: F deveria interagir")
	var u = _alvo()
	if u == null:
		return
	var classes: Array = cfg.todas_classes()
	for c in classes:
		if c == null:
			continue
		u.set_class(c)
		_check(u.tem_rapida(), "classe %s sem habilidade no Q" % c.id)
		_check(c.skill_name != "", "classe %s sem skill_name (nome no HUD)" % c.id)
		_check(c.power != "nenhum", "classe %s sem poder de Chi no E" % c.id)
		# Solta o Q de verdade (pega erro de script em cada habilidade).
		var pos0: Vector3 = u.global_position
		u._quick_cd = 0.0
		u._dodge_t = 0.0
		u._equip_t = 0.0
		u.wants_quick = true
		u._update_skill(0.0, true)
		_check(u._quick_cd > 0.0, "classe %s: o Q não saiu" % c.id)
		u.global_position = pos0
		u.reset_physics_interpolation()
	# Defesa de uma classe que não é guerreiro: reduz pela block_reduction dela.
	var a = null
	for x in game.units:
		if x.alive and x.team != u.team and not x.is_player:
			a = x
			break
	if a == null:
		return
	u.set_class(load("res://config/classes/kitsune.tres"))
	u._dodge_t = 0.0
	u._shield = 0.0
	u.carried_princess = null
	u.hp = u.max_hp()
	var dir := Vector3(1, 0, 0)
	u._visual.rotation.y = atan2(-dir.x, -dir.z)
	u._blocking = true
	u._block_t = cfg.parry_janela + 0.5
	u.take_damage(20.0, a, dir, 1.0, true)
	_check(_perto(u.max_hp() - u.hp, 20.0 * (1.0 - u.stats.block_reduction), 0.01), "defesa da Kitsune deveria reduzir o dano")
	u._blocking = false
	u.hp = u.max_hp()
	# Q: sai e entra em recarga.
	u._quick_cd = 0.0
	u.wants_quick = true
	u._update_skill(0.0, true)
	_check(u._quick_cd > 0.0 and not u.quick_ready(), "Q deveria entrar em recarga depois de usado")
	u._quick_cd = 0.0
	u.set_class(cfg.villager)


## Q do 2.4: Campo Minado põe power_duration minas; Fúria deixa o Ronin
## gigante e quase sem empurrão.
func _poderes_q() -> void:
	var cfg = get_node("/root/Config").cfg
	var u = _alvo()
	if u == null:
		return
	u._dodge_t = 0.0
	u._equip_t = 0.0
	u._spin_t = 0.0
	u.carried_princess = null
	u.set_class(load("res://config/classes/armadilheiro.tres"))
	var antes := get_tree().get_nodes_in_group("traps").size()
	u.power = u.POWER_MAX
	u._use_power()
	var novas := get_tree().get_nodes_in_group("traps").size() - antes
	_check(novas == int(u.stats.power_duration), "Campo Minado: esperadas %d minas, saíram %d" % [int(u.stats.power_duration), novas])
	for t in get_tree().get_nodes_in_group("traps"):
		if t.owner_unit == u:
			t.queue_free()
	u.set_class(load("res://config/classes/ronin_oni.tres"))
	u._fury_t = 1.0
	u._knock = Vector3.ZERO
	u.hp = u.max_hp()
	u._shield = 0.0
	u.take_damage(1.0, null, Vector3.RIGHT, 1.0)
	_check(u._knock.length() < 4.0 * 0.21, "Fúria: o Ronin gigante quase não deveria ser empurrado (%.2f)" % u._knock.length())
	u._fury_t = 0.0
	u._knock = Vector3.ZERO
	u.hp = u.max_hp()
	u.power = 0.0
	# Bombardeio: cada explosão fere quem está no raio (inimigo), não o próprio time.
	var inim = null
	for x in game.units:
		if x.alive and x.team != u.team and not x.is_player:
			inim = x
			break
	if inim:
		inim.hp = inim.max_hp()
		inim._shield = 0.0
		inim._dodge_t = 0.0
		inim._block_t = 0.0
		u.set_class(load("res://config/classes/bombardeiro.tres"))
		u._explosao(inim.global_position, 20.0, u.stats.power_radius)
		_check(inim.hp < inim.max_hp(), "Bombardeio: a explosão deveria ferir o inimigo no centro")
		inim.hp = inim.max_hp()
		inim._knock = Vector3.ZERO
		u.hp = u.max_hp()
		u._explosao(u.global_position, 20.0, 1.0)
		_check(_perto(u.hp, u.max_hp(), 0.01), "Bombardeio: a explosão não fere o próprio time")


## Ciclo 2.21: Sohei corta só na faixa [alcance_min, alcance] (colado = cabo,
## só empurra), Varrida dá escudo aos aliados, Muralha empurra até a borda;
## Kusarigama puxa e prende com o Gancho e a Ciranda poupa o miolo.
func _sohei_kusarigama() -> void:
	var cfg = get_node("/root/Config").cfg
	var u = _alvo()
	if u == null:
		return
	var inim = null
	var aliado = null
	for x in game.units:
		if not x.alive or x == u or x.is_player:
			continue
		if x.team != u.team and inim == null:
			inim = x
		elif x.team == u.team and aliado == null:
			aliado = x
	if inim == null or aliado == null:
		_check(false, "sohei/kusarigama: faltou boneco")
		return
	var p0: Vector3 = u.global_position
	var i0: Vector3 = inim.global_position
	var a0: Vector3 = aliado.global_position
	var dir := Vector3(1, 0, 0)
	var limpa := func() -> void:
		inim.hp = inim.max_hp()
		inim._shield = 0.0
		inim._dodge_t = 0.0
		inim._blocking = false
		inim._knock = Vector3.ZERO
		inim._preso_t = 0.0
		inim._intocavel_t = 0.0
	var poe := func(quem, d: float) -> void:
		quem.global_position = p0 + dir * d
	u._dodge_t = 0.0
	u._equip_t = 0.0
	u._spin_t = 0.0
	u._ciranda_t = 0.0
	u.carried_princess = null
	u.aim_dir = dir
	u._visual.rotation.y = atan2(-dir.x, -dir.z)
	# Sohei: colado leva o cabo (empurra, sem dano); na ponta, a lâmina.
	u.set_class(load("res://config/classes/sohei.tres"))
	u.aim_dir = dir
	limpa.call()
	poe.call(inim, 0.9)
	u._golpe_mult = 1.0
	u._golpe_final = false
	u._attack_hit()
	_check(_perto(inim.hp, inim.max_hp(), 0.01) and inim._knock.length() > 1.0, "Sohei: colado (0,9 m) deveria só empurrar, sem dano")
	limpa.call()
	poe.call(inim, 3.0)
	u._attack_hit()
	_check(inim.hp < inim.max_hp(), "Sohei: a 3 m a lâmina deveria ferir")
	# Varrida: faixa da lâmina fere; aliado perto ganha escudo.
	limpa.call()
	poe.call(inim, 0.9)
	aliado._shield = 0.0
	aliado.global_position = p0 - dir * 2.0
	u._varrida()
	_check(_perto(inim.hp, inim.max_hp(), 0.01), "Varrida: colado não deveria levar dano")
	_check(aliado._shield >= cfg.varrida_escudo - 0.01, "Varrida: aliado a 2 m deveria ganhar escudo")
	limpa.call()
	poe.call(inim, 3.5)
	u._varrida()
	_check(inim.hp < inim.max_hp(), "Varrida: a 3,5 m deveria ferir")
	# Muralha de Fé: inimigo a 2 m do centro sai com v0 = sqrt(2a(R+0,5-2)).
	limpa.call()
	poe.call(inim, 2.0)
	u.power = u.POWER_MAX
	u._use_power()
	var v_esp := sqrt(2.0 * u.KNOCK_DECAY * (u.stats.power_radius + 0.5 - 2.0))
	_check(u._muralha_t > 0.0, "Muralha: deveria ficar de pé")
	u._tick_muralha()
	_check(_perto(inim._knock.length(), v_esp, 0.05) and inim._knock.x > 0.0, "Muralha: empurrão até a borda esperado %.1f m/s, deu %.1f" % [v_esp, inim._knock.length()])
	u._muralha_t = 0.0
	u._power_active_t = 0.0
	# Kusarigama: Gancho a 7 m fere, prende e puxa até ~1,6 m.
	u.set_class(load("res://config/classes/kusarigama.tres"))
	u.aim_dir = dir
	limpa.call()
	poe.call(inim, 7.0)
	u._quick_cd = 0.0
	var saiu: bool = u._gancho()
	_check(saiu and inim.hp < inim.max_hp(), "Gancho: deveria acertar o inimigo a 7 m na mira")
	_check(inim._preso_t > 0.0 and not inim.maos_livres(), "Gancho: o alvo deveria ficar PRESO")
	var puxa: float = inim._knock.length_squared() / (2.0 * u.KNOCK_DECAY)
	_check(inim._knock.x < 0.0 and _perto(puxa, 7.0 - 1.6, 0.1), "Gancho: puxão deveria trazer até ~1,6 m (andou %.1f m)" % puxa)
	limpa.call()
	poe.call(inim, 7.0)
	inim.global_position += Vector3(0, 0, 4.0)  # fora da linha
	_check(not u._gancho() and _perto(inim.hp, inim.max_hp(), 0.01), "Gancho: fora da linha não deveria pegar")
	# Ciranda: pulso fere no anel e poupa o miolo.
	limpa.call()
	poe.call(inim, u.stats.power_radius * 0.8)
	u._pulso_ciranda()
	_check(inim.hp < inim.max_hp(), "Ciranda: deveria ferir no anel")
	limpa.call()
	poe.call(inim, 0.6)
	u._pulso_ciranda()
	_check(_perto(inim.hp, inim.max_hp(), 0.01), "Ciranda: colado (miolo) não deveria levar dano")
	limpa.call()
	inim.global_position = i0
	aliado.global_position = a0
	u.global_position = p0
	for x in [u, inim, aliado]:
		x.reset_physics_interpolation()
	u.power = 0.0
	u._quick_cd = 0.0
	u.set_class(cfg.villager)


## Empurrão: freia a KNOCK_DECAY m/s², logo |v| cai a/60 por quadro (d = v²/2a).
func _empurrao() -> void:
	var u = _alvo()
	if u == null:
		return
	var a: float = u.KNOCK_DECAY
	u._hitstop_t = 0.0
	u._knock = Vector3(8, 0, 0)
	await get_tree().physics_frame
	var v1: float = u._knock.length()
	await get_tree().physics_frame
	var v2: float = u._knock.length()
	var esperado := a / Engine.physics_ticks_per_second
	_check(_perto(v1 - v2, esperado, 0.05),
		"empurrão: freada por quadro esperada %.3f m/s, deu %.3f" % [esperado, v1 - v2])
	_check(_perto(8.0 * 8.0 / (2.0 * a), 0.8, 0.001), "KNOCK_DECAY mudou: 8 m/s deveria empurrar 0,8 m")
	u._knock = Vector3.ZERO


## Construtor do time do alvo (vira Construtor se preciso; com mãos livres).
func _lenhador():
	var u = _alvo()
	if u == null:
		return null
	if not u.lenhador():
		u.set_class(load("res://config/classes/construtor.tres"))
	u.drop_tora()
	u.carried_princess = null
	u._dodge_t = 0.0
	u._equip_t = 0.0
	u._spin_t = 0.0
	u._silence_t = 0.0
	return u


## Economia do Construtor: crescimento, rendimento, tora nos braços, entrega.
func _madeira() -> void:
	var cfg = get_node("/root/Config").cfg
	_check(not game.plantas.is_empty(), "nenhuma planta no mapa (tree_spots/bamboo_spots)")
	_check(game.pilhas.size() == 2, "esperadas 2 pilhas de madeira")
	var u = _lenhador()
	if game.plantas.is_empty() or u == null:
		return
	var arvore = null
	for p in game.plantas:
		if p.tipo == "arvore":
			arvore = p
			break
	_check(arvore != null, "nenhuma árvore no mapa")
	if arvore == null:
		return

	# Estágio sobe no tempo certo.
	arvore.set_estagio(0, false)
	arvore.avancar(cfg.arvore_tempo_estagio - 0.05)
	_check(arvore.estagio == 0, "árvore subiu de estágio antes do tempo")
	arvore.avancar(0.1)
	_check(arvore.estagio == 1, "árvore não subiu de estágio em arvore_tempo_estagio")
	arvore.avancar(cfg.arvore_tempo_estagio)
	_check(arvore.estagio == 2, "árvore não chegou a adulta em 2 estágios")

	# Adulta rende arvore_toras (1 por golpe) e volta a broto.
	var antes: int = game.toras.size()
	for i in cfg.arvore_toras:
		arvore.golpe(u)
	_check(game.toras.size() - antes == cfg.arvore_toras,
		"adulta: esperadas %d toras, saíram %d" % [cfg.arvore_toras, game.toras.size() - antes])
	_check(arvore.estagio == 0, "árvore não voltou a broto depois das toras")
	_check(not arvore.golpe(u), "broto não deveria render tora")
	# Jovem rende 1 e volta a broto.
	arvore.set_estagio(1, false)
	antes = game.toras.size()
	arvore.golpe(u)
	_check(game.toras.size() - antes == 1 and arvore.estagio == 0, "jovem deveria render 1 tora e voltar a broto")

	# Carregar: velocidade x tora_vel_mult e sem ataque.
	var v0: float = u.current_speed()
	var t = game.toras.back()
	t.pegar(u)
	_check(_perto(u.current_speed(), v0 * cfg.tora_vel_mult, 0.01),
		"tora: velocidade esperada %.2f, deu %.2f" % [v0 * cfg.tora_vel_mult, u.current_speed()])
	_check(not u.maos_livres(), "com tora nos braços não deveria atacar")
	# Apanhar derruba a tora.
	u.hp = u.max_hp()
	u.take_damage(1.0, null, Vector3.RIGHT)
	_check(u.carried_tora == null and t.no_chao(), "apanhar deveria derrubar a tora")
	# Entregar soma 1 ao estoque do time.
	t.pegar(u)
	var m0: int = game.madeira[u.team]
	game.entregar_tora(u)
	_check(game.madeira[u.team] == m0 + 1, "entregar a tora deveria somar 1 ao estoque")
	_check(u.carried_tora == null and u.maos_livres(), "depois de entregar as mãos ficam livres")


## Bug 2.5d: Bombardeiro/Armadilheiro (lenhadores) perto de planta cortam com o
## clique; longe dela, o ataque é o normal (bomba).
func _machadada() -> void:
	var u = _lenhador()
	if u == null:
		return
	var arvore = null
	for p in game.plantas:
		if p.tipo == "arvore":
			arvore = p
			break
	if arvore == null:
		return
	for id in ["bombardeiro", "armadilheiro"]:
		u.set_class(load("res://config/classes/%s.tres" % id))
		_check(u.lenhador(), "%s deveria ser lenhador" % id)
		arvore.set_estagio(2, false)
		u.global_position = arvore.global_position + Vector3(2.0, 0, 0)
		u.reset_physics_interpolation()
		u.aim_dir = Vector3.LEFT
		u._attack_cd = 0.0
		var antes: int = game.toras.size()
		u._attack()
		if u._windup_t > 0.0:
			u._attack_hit()
		_check(game.toras.size() - antes == 1, "%s: clique perto da árvore adulta deveria virar machadada" % id)
	# Longe da planta: Bombardeiro joga bomba (não corta).
	u.set_class(load("res://config/classes/bombardeiro.tres"))
	arvore.set_estagio(2, false)
	# Ponto a 8 m da árvore e longe de TODAS as plantas (o bosque depende do mapa).
	var longe: Vector3 = arvore.global_position + Vector3(8.0, 0, 0)
	for dir in [Vector3(8, 0, 0), Vector3(-8, 0, 0), Vector3(0, 0, -8), Vector3(0, 0, 8)]:
		var cand: Vector3 = arvore.global_position + dir
		var livre := true
		for p in game.plantas:
			if p.global_position.distance_to(cand) < 5.0:
				livre = false
		if livre:
			longe = cand
			break
	u.global_position = longe
	u.reset_physics_interpolation()
	_check(not u.clique_vira_machadada(Vector3.LEFT), "bombardeiro longe da árvore não deveria cortar")
	u.global_position = arvore.global_position + Vector3(2.0, 0, 0)
	_check(not u.clique_vira_machadada(Vector3.RIGHT), "bombardeiro de costas para a árvore não deveria cortar")
	u.reset_physics_interpolation()
	u.set_class(load("res://config/classes/construtor.tres"))


## Maquininha: fabrica 1 a cada maquina_intervalo, para no máximo, pegar tira 1.
func _maquina() -> void:
	var cfg = get_node("/root/Config").cfg
	_check(not game.hat_pads.is_empty(), "nenhuma maquininha de chapéu")
	if game.hat_pads.is_empty():
		return
	var pad = game.hat_pads[0]
	while pad.estoque < pad.estoque_max:
		pad.avancar(pad.intervalo)
	# O relógio pode ter sobra dos quadros que já rodaram (bot pegou chapéu
	# no começo): zera para medir o intervalo inteiro.
	pad._fab_t = 0.0
	var cheio: int = pad.estoque
	_check(cheio == cfg.maquina_estoque_max, "máquina deveria encher até maquina_estoque_max")
	pad.take()
	_check(pad.estoque == cheio - 1 and pad.available, "pegar chapéu deveria tirar 1 do estoque")
	pad.avancar(cfg.maquina_intervalo * pad.stats.chapeu_tempo_mult - 0.05)
	_check(pad.estoque == cheio - 1, "máquina fabricou antes do intervalo")
	pad.avancar(0.1)
	_check(pad.estoque == cheio, "máquina não fabricou no intervalo")
	pad.avancar(cfg.maquina_intervalo * 3.0)
	_check(pad.estoque == cheio, "máquina passou do estoque máximo")
	for i in cheio:
		pad.take()
	_check(pad.estoque == 0 and not pad.available, "estoque zero deveria deixar a máquina indisponível")
	pad.take()
	_check(pad.estoque == 0, "estoque não pode ficar negativo")


## Casa da classe (Ciclo 2.21): o tapete só escolhe com madeira (e gasta a
## 1ª), o caminho não troca depois, a obra consome madeira do estoque, não
## passa do que foi entregue e o estoque nunca fica negativo.
func _obra() -> void:
	var of = null
	for o in game.oficinas:
		if o.estado == 0 and o.caminho < 0:
			of = o
			break
	_check(of != null, "nenhuma casa sem caminho para testar")
	if of == null:
		return
	var team: int = of.team
	game.madeira[team] = 5
	_check(of.nivel == 1 and not of.escolher(1) and of.caminho == -1 and game.madeira[team] == 5,
		"Ciclo 2.22: no nível 1 a casa não escolhe o caminho")
	of.nivel = 2
	of.pad_base.subir_nivel()
	game.madeira[team] = 0
	_check(not of.escolher(1) and of.caminho == -1, "sem madeira o tapete não escolhe o caminho")
	game.madeira[team] = 2
	_check(of.escolher(1) and of.caminho == 1 and of.estado == 1 and of.madeira_entregue == 1 and game.madeira[team] == 1,
		"tapete: escolher deveria gastar a 1ª madeira e começar a obra")
	_check(not of.escolher(0) and of.caminho == 1, "caminho escolhido não deveria trocar")
	var e0: int = of.madeira_entregue
	_check(of.puxar_madeira(), "obra deveria puxar madeira com estoque 1")
	_check(game.madeira[team] == 0 and of.madeira_entregue == e0 + 1, "puxar deveria mover 1 do estoque para a obra")
	_check(not of.puxar_madeira() and game.madeira[team] == 0, "sem estoque a obra não puxa e o estoque não fica negativo")
	of.add_progress(1.0, null)
	_check(_perto(of.progresso, of.teto(), 0.001) and of.progresso < 1.0,
		"obra passou da madeira entregue: progresso %.2f, teto %.2f" % [of.progresso, of.teto()])
	var p0: float = of.progresso
	await get_tree().create_timer(0.3).timeout
	_check(of.progresso >= p0 - 1e-6, "obra perdeu progresso parada: %.2f -> %.2f" % [p0, of.progresso])
	_check(game.obra_do_time(team, game.arena.spawn_center[team]) == of, "Construtor deveria voltar para a obra começada do time")


## Casa pronta: vira a maquininha da classe evoluída no nível 2 e a
## barraquinha da classe base sobe para o nível 2 (intervalo e estoque de
## nível 2, +1 chapéu na hora); só uma vez.
func _nivel2() -> void:
	var cfg = get_node("/root/Config").cfg
	var of = null
	for o in game.oficinas:
		if o.estado == 1:
			of = o
			break
	_check(of != null, "nível 2: nenhuma casa em obra")
	if of == null:
		return
	var pad = of.pad_base
	_check(pad != null and not pad.aceita_madeira and game.hat_pads.has(pad), "barraquinha: deveria estar nos chapéus e sem obra própria")
	pad.take()
	var e0: int = pad.estoque + 1
	of.madeira_entregue = of.custo()
	of.add_progress(1.0, null)
	_check(of.estado == 2 and of.nivel == 3 and of.pad != null and of.pad.stats == of.caminhos()[of.caminho] and of.pad.nivel == 3,
		"casa pronta: deveria virar a maquininha de %s no nível 3" % of.caminhos()[of.caminho].id)
	_check(game.hat_pads.has(of.pad), "casa pronta: chapéu da casa deveria estar disponível")
	_check(pad.nivel == 3 and pad.estoque_max == cfg.maquina_n2_estoque + 1 \
			and _perto(pad.intervalo, cfg.maquina_n2_intervalo * cfg.mago_pad_intervalo_mult * pad.stats.chapeu_tempo_mult, 1e-4),
		"nível 3: barraquinha de %s deveria subir junto (nivel %d, max %d)" % [pad.stats.id, pad.nivel, pad.estoque_max])
	_check(pad.estoque == e0, "nível 3: barraquinha deveria ganhar 1 chapéu na hora (%d -> %d)" % [e0, pad.estoque])
	_check(not pad.subir_nivel() and not of.pad.subir_nivel(), "nível 2: não sobe duas vezes")
	_nivel2_madeira(of.team)


## Nível 2 com madeira (Ciclo 2.22): casa_nv2_custo madeiras sobem a
## barraquinha do bairro sozinha, sem caminho; sem estoque não sobe.
func _nivel2_madeira(team: int) -> void:
	var cfg = get_node("/root/Config").cfg
	var of = null
	for o in game.oficinas:
		if o.team == team and o.nivel == 1 and o.base.id != &"kitsune":
			of = o
			break
	if of == null:
		_check(false, "nível 2 (madeira): nenhuma casa no nível 1")
		return
	_check(of.pode_subir() and of.custo_nivel() == cfg.casa_nv2_custo, "nível 2 (madeira): barraquinha no Nv1 deveria aceitar madeira")
	game.madeira[team] = cfg.casa_nv2_custo - 1
	var ok := 0
	for i in cfg.casa_nv2_custo:
		if of.puxar_madeira_nivel():
			ok += 1
	_check(ok == cfg.casa_nv2_custo - 1 and of.nivel == 1 and game.madeira[team] == 0,
		"nível 2 (madeira): sem estoque não deveria subir (puxou %d, nível %d)" % [ok, of.nivel])
	game.madeira[team] = 1
	_check(of.puxar_madeira_nivel() and of.nivel == 2 and of.pad_base.nivel == 2 and of.estado == 0 and of.caminho == -1,
		"nível 2 (madeira): a última madeira deveria subir só a barraquinha")
	_check(of.pede_escolha() and not of.pode_subir(), "nível 2: a casa espera a escolha do caminho (sem madeira de nível)")
	_check(game.obra_do_time(team, of.global_position) != null, "nível 2: Construtor deveria ter uma escolha para fazer")


## Caminhos (Ciclo 2.21): um Construtor de pé no tapete, com madeira, escolhe
## o caminho da casa da Kitsune; pronta ela está no nível 2 e sobe com
## madeira até mago_nivel_max, dando bônus só para a classe do caminho.
func _caminho_magos() -> void:
	var cfg = get_node("/root/Config").cfg
	for t in 2:
		var a = null
		for of in game.oficinas:
			if of.team == t and of.caminho < 0 and of.base.id == &"kitsune":
				a = of
		if a == null:
			continue
		_check(a.tapete_sob(a.tapete_pos(0)) == 0 and a.tapete_sob(a.tapete_pos(1)) == 1 and a.tapete_sob(a.global_position) == -1,
			"caminho: tapetes nos lugares errados")
		# Construtor de verdade pisando no tapete da direita.
		var u = null
		for x in game.units:
			if x.team == t and x.alive and x != game.player and not x.carried_princess:
				u = x
				break
		_check(u != null, "caminho: faltou boneco para pisar no tapete")
		if u == null:
			return
		var antes = u.stats
		u.set_class(load("res://config/classes/construtor.tres"))
		u.global_position = a.tapete_pos(1)
		u.velocity = Vector3.ZERO
		u.drop_tora()
		if a.nivel < 2:
			game.madeira[t] = 3
			a._physics_process(a.ESCOLHA_T + 0.1)
			_check(a.caminho == -1, "caminho: no nível 1 o tapete não escolhe")
			a.madeira_nivel = 0
			a.nivel = 2
			a.pad_base.subir_nivel()
		game.madeira[t] = 0
		a._escolha(a.ESCOLHA_T + 0.1)
		_check(a.caminho == -1, "caminho: sem madeira pisar no tapete não escolhe")
		game.madeira[t] = 1
		a._escolha(0.1)
		_check(a.caminho == 1 and a.estado == 1 and game.madeira[t] == 0, "caminho: Construtor no tapete com madeira deveria escolher o da direita")
		u.set_class(antes)
		u.global_position = game.arena.spawn_center[t]
		u.reset_physics_interpolation()
		a.madeira_entregue = a.custo()
		a.add_progress(1.0, null)
		_check(a.estado == 2 and a.nivel == 3 and a.pad != null and a.pad_base.nivel == 3, "caminho: casa pronta deveria nascer no nível 3 junto com a barraquinha")
		var id: StringName = a.opcao().id
		_check(game.bonus_mago(t, id) == 1 and game.bonus_mago(t, a.base.id) == 1, "caminho: nível 3 dá 1 degrau de bônus para o caminho e para a base")
		var maxb: int = a.pad_base.estoque_max
		var max0: int = a.pad.estoque_max
		# Personagens 2.0: a Kitsune Luz/Sombria do time ganha caudas por nível.
		var vis = null
		var vis_antes = null
		for x in game.units:
			if x.team == t and x.alive and x != game.player:
				vis = x
				vis_antes = x.stats
				break
		if vis:
			vis.set_class(a.opcao())
			_check(vis._nivel_pecas == 3, "caudas: casa recém-pronta deveria dar o nível visual 3 (está %d)" % vis._nivel_pecas)
		var gasto := 0
		for c in cfg.mago_nivel_custo:
			gasto += c
		game.madeira[t] = gasto + 3
		var n := 0
		while a.puxar_madeira_nivel() and n < 100:
			n += 1
		_check(a.nivel == cfg.mago_nivel_max and n == gasto and game.madeira[t] == 3,
			"caminho: deveria subir ao nível %d com %d madeiras (nível %d, puxou %d)" % [cfg.mago_nivel_max, gasto, a.nivel, n])
		_check(not a.pode_subir() and game.bonus_mago(t, id) == cfg.mago_nivel_max - 2, "caminho: nível máximo com bônus de %d níveis" % (cfg.mago_nivel_max - 2))
		_check(a.pad.nivel == cfg.mago_nivel_max, "caminho: a casa deveria mostrar o telhado do nível %d" % cfg.mago_nivel_max)
		if vis:
			_check(vis._nivel_pecas == 5 and vis._pecas != null and vis._meshes.has(vis._pecas),
				"caudas: casa no nível máximo deveria dar as 5 caudas (está %d)" % vis._nivel_pecas)
			vis.set_class(vis_antes)
		_check(a.pad.estoque_max == max0 + cfg.mago_nivel_max - 3 and a.pad_base.estoque_max == maxb + cfg.mago_nivel_max - 3,
			"caminho: casa e barraquinha deveriam ganhar estoque juntas por nível")
		_check(a.pad_base.nivel == cfg.mago_nivel_max, "caminho: a barraquinha deveria subir junto até o %d" % cfg.mago_nivel_max)
		_check(game.bonus_mago(t, a.base.id) == cfg.mago_nivel_max - 2, "caminho: a classe base ganha o mesmo bônus por nível")
		_check(game.bonus_mago(t, a.caminhos()[0].id) == 0 and game.bonus_mago(1 - t, id) == 0, "caminho: bônus só para as classes e o time do bairro")
		for x in game.units:
			if x.team == t and x.alive and x.stats.id != id and x.stats.id != a.base.id:
				_check(_perto(x.damage_mult(), 1.0, 1e-4) or x._fury_t > 0.0 or x._dmg_boost_t > 0.0, "caminho: outra classe não ganha dano")
				break
		game.madeira[t] = 0
		return
	_check(false, "caminho: nenhuma casa da Kitsune sem caminho para testar")


## Alma de abate: matar um inimigo deixa a máscara do time de quem matou mais
## pesada em fat_per_cake · alma_por_abate (a alma chega voando em ~0,9 s).
func _alma() -> void:
	var cfg = get_node("/root/Config").cfg
	var vitima = null
	var matador = null
	for u in game.units:
		if u.alive and not u.is_player:
			if vitima == null:
				vitima = u
			elif matador == null and u.team != vitima.team:
				matador = u
	if vitima == null or matador == null:
		_check(false, "alma: faltou boneco para testar")
		return
	var mascara = game.princesses[matador.team]
	mascara.fatness = 0.0
	vitima._dodge_t = 0.0
	vitima._shield = 0.0
	vitima.take_damage(99999.0, matador, Vector3.RIGHT)
	_check(not vitima.alive, "alma: a vítima deveria morrer")
	await get_tree().create_timer(1.3).timeout
	var esperado: float = cfg.fat_per_cake * cfg.alma_por_abate
	# (tolerância para um abate de verdade no mesmo segundo)
	_check(mascara.fatness >= esperado - 0.005 and mascara.fatness <= esperado * 3.0 + 0.005,
		"alma: máscara deveria pesar %.3f, pesa %.3f" % [esperado, mascara.fatness])


## Ciclo 2.5e: muralha em ferradura (vãos fora da muralha) e torre que entra
## em alarme quando a máscara sai de casa.
func _ferradura() -> void:
	var ar = game.arena
	var m = ar.map
	if m.wall_arc_radius <= 0.0:
		return
	var runs: Array = ar.wall_arc_runs()
	_check(runs.size() == m.wall_arc_gaps.size(), "ferradura: um trecho de muralha entre cada par de vãos")
	var no_vao := false
	for r: Array in runs:
		for a in [0.0, m.wall_arc_gates[0]]:
			if a > r[0] + 0.5 and a < r[1] - 0.5:
				no_vao = true
	_check(not no_vao, "ferradura: saída larga e portão lateral sem muralha")
	for team in 2:
		var k: Node = ar.keep_node[team]
		var ap: AnimationPlayer = k.get_node_or_null("AnimationPlayer") if k else null
		_check(ap != null and ap.current_animation == "respirar", "torre %d respira parada" % team)
		ar.torre_alarme(team, true)
		_check(ap != null and ap.current_animation == "alarme", "torre %d entra em alarme" % team)
		ar.torre_alarme(team, false)


## Ciclo 2.20: toda peça do kit de magia nasce, anima e se libera sozinha
## (efeito que não some vaza nó e chamada de desenho a cada poder).
## Ciclo 2.24: todo personagem com poder tem assinatura PRÓPRIA (selo, verbo e
## peça); ninguém cai no selo genérico nem divide o desenho com outro.
func _assinaturas() -> void:
	var todos: Array[ClassStats] = []
	for c in Config.cfg.todas_classes():
		todos.append(c)
		for h in c.herois:
			if not todos.has(h):
				todos.append(h)
	var usados := {}
	for c in todos:
		if c.power == "nenhum":
			continue
		var d := Assinatura.de(c.id)
		_check(not d.is_empty(), "assinatura: %s não tem linha em Assinatura.DADOS" % c.id)
		if d.is_empty():
			continue
		var i := Assinatura.SELOS.find(c.id)
		_check(i >= 0 and not usados.has(i), "assinatura: %s sem selo próprio no atlas" % c.id)
		usados[i] = true
		_check(Assinatura.VERBO.has(d["verbo"]), "assinatura: verbo de %s não existe" % c.id)
		_check(Assinatura.PECAS.has(d["peca"]), "assinatura: peça de %s não existe no atlas" % c.id)
	_check(usados.size() >= 20, "assinatura: esperado 20 personagens com selo, há %d" % usados.size())
	var caixa := Node3D.new()
	game.add_child(caixa)
	caixa.global_position = Vector3(0, -30, 0)
	var antes := caixa.get_child_count()
	Assinatura.selo(caixa, caixa.global_position, &"onmyoji", 3.0, 0.4)
	Assinatura.figura(caixa, caixa.global_position, "oni", "brasa", Vector2(2, 2), 0.4)
	_check(caixa.get_child_count() == antes + 2, "assinatura: selo e figura deveriam nascer")
	caixa.queue_free()


func _magia() -> void:
	var caixa := Node3D.new()
	game.add_child(caixa)
	var o := Vector3(0, -30, 0)
	caixa.global_position = o
	var pecas := {
		"chama": func() -> void: Magia.chama(caixa, o, "raposa", 1.0, 3.0, 0.5),
		"onda": func() -> void: Magia.onda(caixa, o, "brasa", 2.0, 0.4),
		"estouro": func() -> void: Magia.estouro(caixa, o, "luz", 2.0, 0.4),
		"selo": func() -> void: Magia.selo(caixa, o, "sombra", 3.0, 0.6),
		"lanca": func() -> void: Magia.lanca(caixa, o, o + Vector3(3, 1, 0), "aco", 0.4, 0.3),
		"rachaduras": func() -> void: Magia.rachaduras(caixa, o, "brasa", 3.0, 6, 0.6),
		"bola": func() -> void: Magia.bola(caixa, o, "brasa", 1.5, 0.5),
		"anel_sobe": func() -> void: Magia.anel_sobe(caixa, o, "luz", 1.0, 2.0, 0.5),
		"vortice": func() -> void: Magia.vortice(caixa, "vento", 2.0, 3.0, 0.6),
		"clarao": func() -> void: Magia.clarao(caixa, o, Color.WHITE, 4.0, 0.2),
		"corte": func() -> void: Fx.slash(caixa, o, Vector3.FORWARD, 2.0, 120.0, Color.WHITE),
	}
	for nome: String in pecas:
		pecas[nome].call()
	_check(caixa.get_child_count() >= pecas.size() - 1, "magia: as peças do kit deveriam nascer (%d nós)" % caixa.get_child_count())
	var alvo := Node3D.new()
	caixa.add_child(alvo)
	var fita := Magia.fita(alvo, Vector3.ZERO, Vector3.UP, "aco", 0.2)
	_check(fita != null and fita.material_override is ShaderMaterial, "magia: a fita usa o material de energia")
	await get_tree().create_timer(1.6).timeout
	alvo.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var sobras: Array[String] = []
	for c in caixa.get_children():
		if not c.is_queued_for_deletion():
			sobras.append(c.get_class())
	_check(sobras.is_empty(), "magia: peças que não se liberaram: %s" % ", ".join(sobras))
	_check(FxPoder.ELEMENTO.has("redemoinho") and Magia.PALETAS.has("brasa"), "magia: tabela de elementos e paletas")
	for poder: String in FxPoder.ELEMENTO:
		var pal: String = FxPoder.ELEMENTO[poder][0]
		_check(pal == "" or Magia.PALETAS.has(pal), "magia: paleta '%s' do poder %s existe" % [pal, poder])
	caixa.queue_free()


## Ciclo 2.23: relógio (15 min no 2.24). No zero, mais pontos vence e igual empata;
## máscara fora do castelo estende a partida (prorrogação).
func _relogio() -> void:
	var cfg = get_node("/root/Config").cfg
	_check(cfg.tempo_limite > 0.0 and game.relogio_ligado(), "relógio: deveria estar ligado na partida normal")
	game.tempo_partida = cfg.tempo_limite - 30.0
	_check(_perto(game.tempo_restante(), 30.0, 0.01), "relógio: tempo restante errado")
	# Máscara na mão no zero: última corrida, sem fim.
	var p = game.princesses[0]
	var ladrao = null
	for u in game.units:
		if u.alive and u.team == 1 and not u.carried_princess:
			ladrao = u
			break
	game.score[0] = 1
	game.score[1] = 1
	game.tempo_partida = cfg.tempo_limite + 0.01
	# Ciclo 2.24: máscara caída no zero = prorrogação que espera ela voltar,
	# mesmo passando de prorrogacao_max; de volta ao pedestal, acaba.
	if p.state == p.State.HOME:
		game.score[0] = 2  # placar desigual: o fim da prorrogação encerra direto
		p.state = p.State.DROPPED
		game._relogio(0.016)
		_check(not game.game_over and game.prorrogacao >= 0.0, "relógio: máscara caída no zero deveria abrir a prorrogação")
		game._relogio(cfg.prorrogacao_max + 0.1)
		_check(not game.game_over, "relógio: com a máscara caída a prorrogação espera ela voltar")
		p.state = p.State.HOME
		game._relogio(0.016)
		_check(game.game_over, "relógio: máscara de volta no pedestal encerra a prorrogação")
		_check(game.vencedor == 0 and game.morte_subita < 0.0, "relógio: placar desigual não abre morte súbita")
		game.game_over = false
		game.vencedor = -9
		game.prorrogacao = -1.0
		game.score[0] = 1
	if ladrao and p.state == p.State.HOME:
		ladrao.pick_up_princess(p)
		game._relogio(0.016)
		_check(not game.game_over and game.prorrogacao >= 0.0, "relógio: máscara na mão no zero deveria abrir a última corrida")
		# Ciclo 2.25: última corrida estourada com placar igual = morte súbita,
		# com as duas máscaras leves e as almas sem pesar.
		for m in game.princesses:
			m.fatness = 0.6
		game._relogio(cfg.prorrogacao_max + 0.1)
		_check(not game.game_over and game.morte_subita >= 0.0, "relógio: placar igual no fim deveria abrir a morte súbita")
		_check(game.prorrogacao < 0.0, "morte súbita: a prorrogação deveria ter fechado")
		_check(game.princesses[0].fatness == 0.0 and game.princesses[1].fatness == 0.0, "morte súbita: as máscaras deveriam ficar leves")
		game.princesses[0].pesar_alma(1.0)
		_check(game.princesses[0].fatness == 0.0, "morte súbita: alma não deveria pesar")
		_check(_perto(game.morte_subita_resta(), cfg.morte_subita_tempo, 0.5), "morte súbita: relógio próprio errado")
		# Tempo dela estourado com a máscara na mão: espera, como a prorrogação.
		game._relogio(cfg.morte_subita_tempo + 0.1)
		_check(not game.game_over, "morte súbita: máscara na mão deveria segurar o fim")
		# Ninguém pontuou: vence quem tem mais pontos no placar do Tab.
		game.placar.somar(game.units[0], "abates", 50.0)
		var lider: int = game.units[0].team
		game._relogio(cfg.prorrogacao_max + 0.1)
		_check(game.game_over and game.vencedor == lider and game.decidido_no_placar,
			"morte súbita: sem ponto, deveria vencer o time com mais pontos no placar (deu %d)" % game.vencedor)
		# O primeiro ponto na morte súbita encerra, mesmo longe de score_to_win.
		game.game_over = false
		game.vencedor = -9
		game.decidido_no_placar = false
		game.score[0] = 0
		game.score[1] = 0
		if ladrao.carried_princess == null:
			ladrao.pick_up_princess(p)
		game._score_point(ladrao)
		_check(game.game_over and game.vencedor == ladrao.team and not game.decidido_no_placar,
			"morte súbita: o primeiro ponto deveria vencer")
	else:
		_check(false, "relógio: não deu para pôr a máscara na mão")
		game._relogio(0.016)
	_check(game.game_over, "relógio: no zero a partida deveria acabar")
	# A decisão em si (sem encerrar de novo): placar diferente no zero vence direto.
	game.score[0] = 2
	game.score[1] = 1
	game.game_over = false
	game.vencedor = -9
	game.morte_subita = -1.0
	game._fim_por_tempo()
	_check(game.vencedor == 0 and game.morte_subita < 0.0, "relógio: mais pontos no zero deveria vencer sem morte súbita")


## Ciclo 2.25 (menos empate): teto das almas, carregar mais rápido, escolta
## que soma por aliado e devolução mais demorada.
## 2.27c: a máscara nasce com peso_inicial, então o primeiro roubo já é lento.
func _mascara_pesada() -> void:
	var cfg = get_node("/root/Config").cfg
	_check(cfg.peso_inicial >= 0.2 and cfg.peso_inicial < cfg.alma_teto, "peso_inicial fora de [0,2, alma_teto)")
	for m in game.princesses:
		_check(m.fatness >= cfg.peso_inicial - 1e-4, "máscara deveria nascer com peso %.2f, tem %.3f" % [cfg.peso_inicial, m.fatness])
		_check(m._spirits.get_child_count() >= int(round(cfg.peso_inicial / cfg.fat_per_cake)), "máscara deveria nascer com os espíritos do peso inicial à vista")


func _menos_empate() -> void:
	var cfg = get_node("/root/Config").cfg
	_check(cfg.alma_por_abate <= 0.08, "alma de abate deveria pesar bem menos que os 0,15 de antes")
	_check(cfg.alma_teto > 0.0 and cfg.alma_teto < 1.0, "alma_teto fora de (0, 1)")
	var m = game.princesses[0]
	var guardado: float = m.fatness
	m.fatness = cfg.alma_teto - 0.001
	m.pesar_alma(1.0)
	_check(_perto(m.fatness, cfg.alma_teto, 1e-4), "alma: não deveria passar do teto (%.2f), foi a %.3f" % [cfg.alma_teto, m.fatness])
	m.pesar_alma(1.0)
	_check(_perto(m.fatness, cfg.alma_teto, 1e-4), "alma: no teto não pesa mais")
	if m.state == m.State.HOME:
		_check(m.feed() and m.fatness > cfg.alma_teto, "espírito entregue deveria passar do teto das almas")
	m.fatness = guardado
	m._apply_fatness()
	_check(cfg.princess_rescue_time >= 3.5, "devolver a máscara deveria demorar mais que os 3 s de antes")
	# Multikill em escadinha: 120 por abate, +50, +100, +150, +150...
	var pl = game.placar
	var esperado_b := [0.0, 0.0, 50.0, 100.0, 150.0, 150.0]
	for n in range(1, 6):
		_check(_perto(pl.bonus_degrau(n, cfg), esperado_b[n], 1e-4), "multikill: degrau %d deveria valer +%d" % [n, int(esperado_b[n])])
	var mk := RefCounted.new()
	var vitimas := []
	for i in 5:
		vitimas.append(RefCounted.new())
	var t0 := 5000.0
	pl.abate(vitimas[0], mk, t0)
	_check(pl.ultimo_degrau == 1, "multikill: primeiro abate é comum")
	pl.abate(vitimas[1], mk, t0 + cfg.multikill_janela - 0.5)
	_check(pl.ultimo_degrau == 2 and _perto(pl.ultimo_bonus, 50.0, 1e-4), "multikill: segundo abate na janela = duplo +50")
	pl.abate(vitimas[2], mk, t0 + 2.0 * cfg.multikill_janela - 1.0)
	_check(pl.ultimo_degrau == 3, "multikill: a janela conta a partir do último abate")
	pl.abate(vitimas[3], mk, t0 + 3.0 * cfg.multikill_janela + 1.0)
	_check(pl.ultimo_degrau == 1, "multikill: passou da janela, a corrente recomeça")
	pl.abate(mk, vitimas[4], t0 + 3.0 * cfg.multikill_janela + 1.5)
	pl.abate(vitimas[4], mk, t0 + 3.0 * cfg.multikill_janela + 2.0)
	_check(pl.ultimo_degrau == 1, "multikill: quem morre perde a corrente")
	_check(pl.nome_degrau(2) == "ABATE DUPLO" and pl.nome_degrau(3) == "ABATE TRIPLO" and pl.nome_degrau(5) == "MULTI ×5", "multikill: nomes dos degraus")
	_check(_perto(cfg.pts_abates, 120.0, 0.01), "abate deveria valer 120 no placar")
	# Heróis um pouco mais fortes, igual para todos.
	_check(cfg.heroi_vida_mult > 1.0 and cfg.heroi_dano_mult > 1.0 and cfg.heroi_recarga_mult < 1.0, "heróis: multiplicadores do Ciclo 2.25")
	for id in ["sumotori", "kappa", "yamabushi", "karasu_tengu", "mujina", "onmyoji", "tennin", "komuso", "ochimusha", "shishimai", "jorogumo", "kodama", "kaminari_kozo"]:
		_check(load("res://config/classes/%s.tres" % id).heroi, "%s deveria estar marcado como herói" % id)
	_check(not load("res://config/classes/guerreiro.tres").heroi, "Samurai não é herói")
	# Carregar e escolta: um ladrão do time 1 com 0, 1 e 3 aliados colados.
	var ladrao = null
	var aliados := []
	for u in game.units:
		if u.alive and not u.is_player and u.team == 1 and not u.carried_princess:
			if ladrao == null:
				ladrao = u
			elif aliados.size() < 3:
				aliados.append(u)
	if ladrao == null or aliados.size() < 3 or m.state != m.State.HOME:
		_check(false, "menos empate: faltou boneco ou máscara em casa para a escolta")
		return
	var pos: Array = [ladrao.global_position]
	for a in aliados:
		pos.append(a.global_position)
	var longe := Vector3(0, 0, 40)
	for u in game.units:
		if u.team == 1 and u != ladrao:
			u.set_meta("pos_teste", u.global_position)
			u.global_position = ladrao.global_position + longe + Vector3(randf() * 4.0, 0, 0)
	ladrao._boost_t = 0.0
	ladrao._slow_t = 0.0
	ladrao._sombra_t = 0.0
	ladrao._tiro_lento_t = 0.0
	var base: float = ladrao.current_speed()
	m.fatness = 0.5
	ladrao.pick_up_princess(m)
	ladrao._boost_t = 0.0
	var k: float = minf(ladrao.stats.carry_speed_mult + cfg.carregar_bonus, 1.0) * (1.0 - 0.5 * cfg.fat_slowdown)
	var mult_base := 1.0
	if ladrao.lenhador():
		mult_base = 1.0  # o bônus das casas já está em `base`
	_check(ladrao.escolta() == 0 and _perto(ladrao.current_speed(), base * k * mult_base, 0.02),
		"carregar sozinho: esperado %.2f, deu %.2f" % [base * k, ladrao.current_speed()])
	aliados[0].global_position = ladrao.global_position + Vector3(2, 0, 0)
	_check(ladrao.escolta() == 1 and _perto(ladrao.current_speed(), base * k * (1.0 + cfg.escolta_vel), 0.02),
		"escolta com 1 aliado: deveria dar +%.0f%%" % (cfg.escolta_vel * 100.0))
	aliados[1].global_position = ladrao.global_position + Vector3(-2, 0, 0)
	aliados[2].global_position = ladrao.global_position + Vector3(0, 0, 2)
	var tres: float = cfg.escolta_vel + cfg.escolta_vel_extra * 2.0
	_check(ladrao.escolta() == 3 and _perto(ladrao.current_speed(), base * k * (1.0 + tres), 0.02),
		"escolta com 3 aliados: deveria dar +%.0f%%, deu ×%.2f" % [tres * 100.0, ladrao.current_speed() / (base * k)])
	_check(aliados[0]._em_escolta(), "quem escolta também deveria andar mais rápido")
	ladrao.carried_princess = null
	m.return_home()
	m.fatness = guardado
	m._apply_fatness()
	for u in game.units:
		if u.has_meta("pos_teste"):
			u.global_position = u.get_meta("pos_teste")
			u.remove_meta("pos_teste")
			u.reset_physics_interpolation()


## Ciclo 2.23: escada do Nv6 (herói raro). Usa a casa da Kitsune que o
## _caminho_magos deixou no nível máximo.
func _heroi_nv6() -> void:
	var cfg = get_node("/root/Config").cfg
	var of = null
	for o in game.oficinas:
		if o.base.id == &"kitsune" and o.caminho >= 0 and o.estado == 2 and o.heroi < 0:
			of = o
			break
	_check(of != null, "Nv6: nenhuma casa da Kitsune pronta para testar")
	if of == null:
		return
	var t: int = of.team
	of.nivel = cfg.mago_nivel_max
	_check(of.herois().size() == 4 and of.pede_heroi() and not of.pode_subir(), "Nv6: casa no Nv5 com heróis pede a escolha e não sobe sozinha")
	var cons = null
	for o in game.oficinas:
		if o.team == t and o.base.id == &"construtor":
			cons = o
	if cons:
		var n0: int = cons.nivel
		var c0: int = cons.caminho
		var e0: int = cons.estado
		cons.nivel = cfg.mago_nivel_max
		cons.caminho = 0
		cons.estado = 2
		_check(not cons.pede_heroi() and cons.herois().is_empty(), "Nv6: bairro do Construtor (sem heróis) para no Nv5")
		cons.nivel = n0
		cons.caminho = c0
		cons.estado = e0
	game.madeira[t] = 0
	_check(not of.escolher_heroi(0), "Nv6: sem madeira não escolhe o herói")
	game.madeira[t] = cfg.heroi_custo + 3
	_check(of.escolher_heroi(2) and of.heroi == 2 and of.madeira_nivel == 1 and game.madeira[t] == cfg.heroi_custo + 2,
		"Nv6: escolher deveria gastar a 1ª madeira e fixar o herói")
	_check(not of.escolher_heroi(0) and of.heroi == 2, "Nv6: herói escolhido não troca")
	_check(of.pode_subir() and of.faltam_nivel() == cfg.heroi_custo - 1, "Nv6: o pavilhão pede o resto da madeira (faltam %d)" % of.faltam_nivel())
	var n := 0
	while of.puxar_madeira_nivel() and n < 50:
		n += 1
	_check(n == cfg.heroi_custo - 1 and of.heroi_pronto and of.nivel == cfg.mago_nivel_max + 1 and game.madeira[t] == 3,
		"Nv6: %d madeiras deveriam erguer o pavilhão (puxou %d, nível %d)" % [cfg.heroi_custo - 1, n, of.nivel])
	var pad = of.pad_heroi
	_check(pad != null and pad.raro and pad.estoque_max == 1 and pad.estoque == 1 and game.hat_pads.has(pad) and pad.stats == of.heroi_cls(),
		"Nv6: pavilhão pronto cria o chapéu raro com estoque 1")
	var h = of.heroi_cls()
	_check(game.bonus_mago(t, h.id) == cfg.heroi_bonus_niveis and game.bonus_mago(t, of.base.id) == cfg.mago_nivel_max - 2
			and game.bonus_mago(t, of.opcao().id) == cfg.mago_nivel_max - 2, "Nv6: herói com bônus %d, base e caminho com %d" % [cfg.heroi_bonus_niveis, cfg.mago_nivel_max - 2])
	# Raro não fabrica por tempo.
	pad.take()
	pad.avancar(60.0)
	_check(pad.estoque == 0, "Nv6: o chapéu do herói não fabrica sozinho")
	# Quem veste é o herói; caído continua; renascer como aldeão faz o chapéu voltar.
	var u = null
	for x in game.units:
		if x.team == t and x.alive and not x.is_player and not x.carried_princess:
			u = x
			break
	if u == null:
		_check(false, "Nv6: faltou boneco para vestir o herói")
		return
	var antes = u.stats
	u.set_class(h)
	of._tick_heroi(0.1)
	_check(of._retorno_t < 0.0, "Nv6: herói em campo, o chapéu não volta")
	u._die(null)
	of._tick_heroi(cfg.heroi_retorno + 1.0)
	_check(pad.estoque == 0, "Nv6: herói caído esperando reanimar ainda conta como em campo")
	u._respawn()
	of._tick_heroi(0.1)
	_check(pad.estoque == 0 and of._retorno_t > 0.0, "Nv6: renasceu aldeão, o altar começa a contar")
	of._tick_heroi(cfg.heroi_retorno)
	_check(pad.estoque == 1, "Nv6: o chapéu volta %.0f s depois que o herói sai de campo" % cfg.heroi_retorno)
	u.set_class(antes)
	# Bot espera o jogador do time pegar primeiro (fora do autoplay).
	var auto0: bool = game._autoplay
	var p0 = game.player
	game._autoplay = false
	if game.player == null or game.player.team != t:
		for x in game.units:
			if x.team == t:
				game.player = x
				break
	pad._livre_t = 0.0
	_check(game.heroi_reservado(pad, u if u != game.player else null) or u == game.player, "Nv6: bot espera %.0f s pelo jogador" % cfg.heroi_espera_jogador)
	pad._livre_t = cfg.heroi_espera_jogador + 0.1
	_check(not game.heroi_reservado(pad, u), "Nv6: depois da espera o bot pode pegar")
	game._autoplay = auto0
	game.player = p0


## Ciclo 2.23: o truque novo de cada herói (docs/direcao-ciclo-2.23-herois.md §10).
func _herois_regras() -> void:
	var cfg = get_node("/root/Config").cfg
	var a = null
	var b = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo:
			if a == null:
				a = u
			elif b == null and u.team != a.team:
				b = u
	if a == null or b == null:
		_check(false, "heróis: faltou boneco")
		return
	var c0 = a.stats
	var c1 = b.stats
	# Sem cérebro durante o teste: o bot desviaria do aviso de perigo do pouso.
	var cerebros := [a.brain, b.brain]
	a.brain = null
	b.brain = null
	var centro := Vector3(0, 0, 0)
	centro.y = game.arena.ground_y(0, 0)
	# Tira todo mundo de perto do teste.
	var guardados := {}
	for u in game.units:
		if u != a and u != b:
			guardados[u] = u.global_position
			if u.global_position.distance_to(centro) < 30.0:
				u.global_position = game.arena.spawn_center[u.team]
	var por := func(x, p: Vector3, olha: Vector3) -> void:
		x.global_position = p
		x.velocity = Vector3.ZERO
		x._knock = Vector3.ZERO
		x._dodge_t = 0.0
		x._blocking = false
		x._shield = 0.0
		x._intocavel_t = 0.0
		x.hp = x.max_hp()
		x._visual.rotation.y = atan2(olha.x, olha.z)
		x.aim_dir = olha
		x.reset_physics_interpolation()
	var dx := Vector3(1, 0, 0)
	b.set_class(load("res://config/classes/guerreiro.tres"))

	# Sumotori: Agarrão arremessa, solta a máscara e fere no pouso.
	a.set_class(load("res://config/classes/sumotori.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 1.8, -dx)
	var tinha = b.carried_princess
	b.carried_princess = null
	a._quick_cd = 0.0
	_check(a._usar_rapida() and b.em_voo, "Sumotori: Agarrão deveria levantar o alvo")
	var hp0: float = b.hp
	await get_tree().create_timer(cfg.agarrao_segura + 0.75).timeout
	_check(not b.em_voo and b.hp < hp0 and b.global_position.distance_to(centro) > 4.0,
		"Sumotori: alvo deveria pousar longe ferido (dist %.1f, dano %.1f)" % [b.global_position.distance_to(centro), hp0 - b.hp])
	# Dohyō: quem estava dentro não sai; de fora não entra.
	por.call(a, centro, dx)
	por.call(b, centro + dx * 2.0, -dx)
	a.super_carga = a.POWER_MAX
	_check(Herois.super_proprio(a) and a._dohyo_t > 0.0, "Sumotori: Dohyō deveria abrir o ringue")
	b.global_position = centro + dx * (cfg.dohyo_raio + 3.0)
	Herois._tick_dohyo(a)
	_check(b.global_position.distance_to(centro) <= cfg.dohyo_raio, "Sumotori: quem estava no ringue não sai (%.1f m)" % b.global_position.distance_to(centro))
	a.set_meta("dohyo_dentro", [])
	b.global_position = centro + dx * 1.0
	Herois._tick_dohyo(a)
	_check(b.global_position.distance_to(centro) >= cfg.dohyo_raio, "Sumotori: quem estava fora não entra no ringue")
	a._dohyo_t = 0.0

	# Kappa: casco reduz só por trás.
	a.set_class(load("res://config/classes/kappa.tres"))
	por.call(a, centro, dx)
	a.take_damage(20.0, b, -dx)  # vindo da frente (b na frente batendo para trás)
	var frente: float = a.max_hp() - a.hp
	a.hp = a.max_hp()
	a.take_damage(20.0, b, dx)  # vindo das costas
	var costas: float = a.max_hp() - a.hp
	_check(frente > 0.0 and costas < frente * 0.5,
		"Kappa: casco deveria reduzir só por trás (frente %.1f, costas %.1f)" % [frente, costas])

	# Yamabushi: Rajada troca dono e direção do projétil.
	a.set_class(load("res://config/classes/yamabushi.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 6.0, -dx)
	var p = game.spawn_projectile(b, centro + dx * 3.0 + Vector3(0, 1.2, 0), -dx, "shuriken")
	_check(Herois._rajada(a) and p.owner_unit == a and p.velocity.dot(dx) > 0.0, "Yamabushi: Rajada deveria devolver o tiro (dono e direção)")
	p.queue_free()

	# Karasu: intocável no ar e fere no raio do pouso.
	a.set_class(load("res://config/classes/karasu_tengu.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 6.0, -dx)
	a.aim_point = b.global_position
	_check(a._usar_rapida() and a.em_voo, "Karasu: Mergulho deveria subir")
	hp0 = a.hp
	a.take_damage(30.0, b, dx)
	_check(a.hp == hp0, "Karasu: no ar o Mergulho é intocável")
	var hb0: float = b.hp
	await get_tree().create_timer(1.0).timeout
	_check(not a.em_voo and b.hp < hb0, "Karasu: o pouso fere quem está no raio (dano %.1f)" % (hb0 - b.hp))
	# Cego desvia a mira do bot.
	por.call(a, centro, dx)
	b._cego_t = 1.0
	b.aim_dir = dx
	b._attack_cd = 0.0
	b._attack()
	_check(b.aim_dir.angle_to(dx) > 0.001, "Karasu: cego deveria desviar a mira do bot")
	b._cego_t = 0.0

	# Mujina: disfarce tira dos alvos e quebra no golpe.
	a.set_class(load("res://config/classes/mujina.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 2.0, -dx)
	_check(a._usar_rapida() and a._disfarce_t > 0.0 and a.na_sombra_para(b), "Mujina: rosto roubado tira a Mujina dos alvos inimigos")
	_check(a._disfarce_time == b.team, "Mujina: o rosto é do time do inimigo")
	a._attack_cd = 0.0
	a._attack()
	_check(a._disfarce_t <= 0.0 and not a.na_sombra_para(b), "Mujina: o golpe quebra o disfarce")

	# Andar forçado: Susto afasta, Hipnose aproxima.
	por.call(a, centro, dx)
	por.call(b, centro + dx * 3.0, -dx)
	Herois.forcar_andar(b, centro, 1.0, true)
	Herois.corpo_sem_cerebro(b)
	_check(b.move_intent.dot(dx) > 0.9 and not b.wants_attack, "andar forçado: Susto afasta")
	Herois.forcar_andar(b, centro, 1.0, false)
	b._forcado_afasta = false
	Herois.corpo_sem_cerebro(b)
	_check(b.move_intent.dot(-dx) > 0.9, "andar forçado: Hipnose aproxima")
	b._forcado_t = 0.0

	# Onmyoji: cada boneco engole um golpe; com 3, o Q lança os três.
	a.set_class(load("res://config/classes/onmyoji.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 8.0, -dx)
	for i in 3:
		Herois._dobrar(a)
	_check(a.shikigami == 3, "Onmyoji: três Q fazem três bonecos")
	a.take_damage(25.0, b, dx)
	_check(a.hp == a.max_hp() and a.shikigami == 2, "Onmyoji: o boneco engole o golpe inteiro")
	Herois._dobrar(a)
	var antes_n: int = get_tree().get_nodes_in_group("projeteis").size()
	Herois._dobrar(a)
	_check(a.shikigami == 0 and get_tree().get_nodes_in_group("projeteis").size() >= antes_n + 3, "Onmyoji: com 3 bonecos o Q lança os três")

	# Tennin: não é empurrada; o Laço levanta o caído com laco_vida.
	a.set_class(load("res://config/classes/tennin.tres"))
	por.call(a, centro, dx)
	a.take_damage(5.0, b, dx, 3.0, true)
	_check(a._knock.length() < 0.01, "Tennin: não é empurrada")
	var aliado = null
	for u in game.units:
		if u != a and u.team == a.team and u.alive and not u.is_player and not u.carried_princess:
			aliado = u
			break
	if aliado:
		var ac = aliado.stats
		aliado.global_position = centro + dx * 6.0
		aliado._die(null)
		_check(Herois._laco(a), "Tennin: Laço acha o aliado caído")
		await get_tree().create_timer(0.45).timeout
		_check(aliado.alive and aliado.hp >= aliado.max_hp() * cfg.laco_vida - 0.5, "Tennin: Laço levanta o caído com %.0f%%" % (cfg.laco_vida * 100))
		aliado.set_class(ac)
		aliado.global_position = guardados.get(aliado, game.arena.spawn_center[aliado.team])
	# Véu: intocável por veu_tempo.
	_check(Herois.super_proprio(a) and a._intocavel_t >= cfg.veu_tempo - 0.01, "Tennin: Véu deixa intocável por %.0f s" % cfg.veu_tempo)
	a._intocavel_t = 0.0

	# Komusō: Sono dorme quem fica no cone; dano acorda; interrompe com dano; Réquiem cala.
	a.set_class(load("res://config/classes/komuso.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 4.0, -dx)
	_check(Herois._sono(a) and a._canto_t > 0.0, "Komusō: Canção começa a tocar")
	Herois._tick_canto(a, a.stats.skill_duration + 0.01)
	_check(b._sono_t > 0.0 and not b.maos_livres(), "Komusō: quem ficou no cone dorme")
	b.take_damage(1.0, a, dx)
	_check(b._sono_t <= 0.0, "Komusō: dano acorda")
	Herois._sono(a)
	a.take_damage(1.0, b, -dx)
	_check(a._canto_t <= 0.0, "Komusō: dano interrompe a Canção")
	_check(Herois.super_proprio(a) and b._mudo_t >= cfg.requiem_tempo - 0.01, "Komusō: Réquiem cala por %.0f s" % cfg.requiem_tempo)
	b.power = b.POWER_MAX
	b.wants_power = true
	var pw: float = b.power
	b._physics_process(1.0 / 60.0)
	_check(b.power >= pw - 0.01, "Komusō: calado não solta o E")
	b._mudo_t = 0.0

	# Super de cada herói gasta a barra uma vez só (Ciclo 2.22, mesmo critério).
	for id in ["sumotori", "kappa", "yamabushi", "karasu_tengu", "mujina", "onmyoji", "tennin", "komuso", "ochimusha", "shishimai", "jorogumo", "kodama", "kaminari_kozo"]:
		var cls = load("res://config/classes/%s.tres" % id)
		a.set_class(cls)
		por.call(a, centro, dx)
		por.call(b, centro + dx * 3.0, -dx)
		a.super_carga = a.POWER_MAX
		a.wants_super = true
		var usos := 0
		for k in 5:
			var sc: float = a.super_carga
			if a.em_voo:
				break
			a._use_super()
			if sc >= a.POWER_MAX and a.super_carga < a.POWER_MAX:
				usos += 1
		_check(usos == 1, "%s: o R deveria sair uma vez só (saiu %d)" % [id, usos])
		await get_tree().create_timer(0.05).timeout
		var espera := 0
		while a.em_voo and espera < 40:  # Noite de Corvos: os mergulhos pousam
			await get_tree().create_timer(0.1).timeout
			espera += 1
	await get_tree().create_timer(1.2).timeout  # mergulhos em cadeia pousam
	a.brain = cerebros[0]
	b.brain = cerebros[1]
	a.set_class(c0)
	b.set_class(c1)
	for u in guardados:
		if is_instance_valid(u):
			u.global_position = guardados[u]
			u.reset_physics_interpolation()


## Heróis 2.27: Ochimusha (não cai de primeira, flechas como cargas), Shishimai
## (Sorte e Azar, Arrastão), Jorogumo (teia, fio, puxar, casulo) e as reações
## fogo/vento × teia.
func _herois_2_27() -> void:
	var cfg = get_node("/root/Config").cfg
	var a = null
	var b = null
	var c = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo:
			if a == null:
				a = u
			elif b == null and u.team != a.team:
				b = u
			elif c == null and u.team == a.team:
				c = u
	if a == null or b == null or c == null:
		_check(false, "heróis 2.27: faltou boneco")
		return
	var classes := [a.stats, b.stats, c.stats]
	var cerebros := [a.brain, b.brain, c.brain]
	a.brain = null
	b.brain = null
	c.brain = null
	var centro := Vector3(0, 0, 0)
	centro.y = game.arena.ground_y(0, 0)
	var guardados := {}
	for u in game.units:
		guardados[u] = u.global_position
		if u != a and u != b and u != c and u.global_position.distance_to(centro) < 30.0:
			u.global_position = game.arena.spawn_center[u.team]
	var por := func(x, p: Vector3, olha: Vector3) -> void:
		x.global_position = p
		x.velocity = Vector3.ZERO
		x._knock = Vector3.ZERO
		x._dodge_t = 0.0
		x._blocking = false
		x._shield = 0.0
		x._intocavel_t = 0.0
		x._preso_t = 0.0
		x._slow_t = 0.0
		x.hp = x.max_hp()
		x._visual.rotation.y = atan2(olha.x, olha.z)
		x.aim_dir = olha
		x.reset_physics_interpolation()
	var dx := Vector3(1, 0, 0)
	var dz := Vector3(0, 0, 1)
	b.set_class(load("res://config/classes/guerreiro.tres"))
	c.set_class(load("res://config/classes/guerreiro.tres"))
	por.call(c, centro + dz * 12.0, dx)

	# Ochimusha: o golpe mortal deixa 1 de vida e vira fantasma intocável.
	a.set_class(load("res://config/classes/ochimusha.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 2.0, -dx)
	a.take_damage(9999.0, b, dx)
	_check(a.alive and _perto(a.hp, 1.0, 0.01) and a._fantasma_t > 0.0, "Ochimusha: golpe mortal deixa 1 de vida e vira fantasma")
	a.take_damage(50.0, b, dx)
	_check(a.alive and _perto(a.hp, 1.0, 0.01), "Ochimusha: fantasma não apanha")
	Herois.abateu(a, b)
	_check(a._fantasma_t <= 0.0 and a.hp >= a.max_hp() * cfg.fantasma_volta - 0.5, "Ochimusha: abate no fantasma volta com %.0f%%" % (cfg.fantasma_volta * 100))
	a.take_damage(9999.0, b, dx)
	_check(not a.alive, "Ochimusha: só não cai uma vez por vida")
	a._voltar_a_vida()
	a.set_class(load("res://config/classes/ochimusha.tres"))
	por.call(a, centro, dx)
	a.take_damage(9999.0, b, dx)
	Herois._tick_2_27(a, cfg.fantasma_tempo + 0.1)
	_check(not a.alive, "Ochimusha: sem abate, cai no fim do fantasma")
	a._voltar_a_vida()
	a.set_class(load("res://config/classes/ochimusha.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 2.0, -dx)
	# Flecha Arrancada: as flechas nas costas são as cargas do Q.
	Herois._tick_2_27(a, 0.016)
	_check(a.cargas_q == a.stats.cargas_q and a.stats.cargas_q == 4, "Ochimusha: começa com 4 flechas (tem %d)" % a.cargas_q)
	var hp0: float = b.hp
	a._quick_cd = 0.0
	a.wants_quick = true
	a._physics_process(1.0 / 60.0)
	_check(a.cargas_q == 3 and b.hp < hp0 and b._slow_t > 0.0, "Ochimusha: Q gasta uma flecha, fere e deixa lento (cargas %d)" % a.cargas_q)
	a._quick_cd = 0.0
	b.global_position = centro - dx * 3.0  # atrás: ninguém no cone
	_check(not a._usar_rapida() and a.cargas_q == 3, "Ochimusha: sem ninguém na frente a flecha não sai")
	# Onibi: três fogos; cada um estoura no primeiro que encosta.
	por.call(b, centro + dx * 1.2, -dx)
	Herois._onibi(a)
	_check(a._onibi_n == cfg.onibi_n, "Ochimusha: Onibi acende %d fogos" % cfg.onibi_n)
	hp0 = b.hp
	a.set_meta("onibi_cd", 0.0)
	Herois._tick_onibi(a, 0.016)
	_check(a._onibi_n == cfg.onibi_n - 1 and b.hp < hp0 and b._forcado_t > 0.0, "Ochimusha: fogo estoura em quem encosta e assusta")
	Herois._fim_onibi(a)
	b._forcado_t = 0.0

	# Shishimai: Mordida no inimigo dá Azar (o próximo golpe dele erra).
	a.set_class(load("res://config/classes/shishimai.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 1.5, -dx)
	hp0 = b.hp
	_check(Herois._mordida(a) and b.hp < hp0 and b._azar_t > 0.0, "Shishimai: Mordida fere o inimigo e dá Azar")
	var ha: float = a.hp
	a.take_damage(20.0, b, dx)
	_check(_perto(a.hp, ha, 0.01) and b._azar_t <= 0.0, "Shishimai: com Azar o golpe erra (e o Azar acaba)")
	# Mordida no aliado: cura e Sorte (desvia o próximo e dobra o próximo dado).
	por.call(b, centro + dx * 9.0, -dx)
	por.call(c, centro + dx * 1.5, -dx)
	c.hp = c.max_hp() * 0.5
	var hc: float = c.hp
	_check(Herois._mordida(a) and c.hp > hc and c._sorte_partes == 3, "Shishimai: Mordida no aliado cura e dá Sorte")
	hc = c.hp
	c.take_damage(20.0, b, dx)
	_check(_perto(c.hp, hc, 0.01) and c._sorte_partes == 1, "Shishimai: Sorte desvia o próximo golpe levado")
	c._sorte_partes = 0
	var hb: float = b.hp
	b.take_damage(10.0, c, dx)
	var normal: float = hb - b.hp
	b.hp = b.max_hp()
	Herois.dar_sorte(c, cfg.sorte_tempo)
	b.take_damage(10.0, c, dx)
	var dobro: float = b.max_hp() - b.hp
	_check(normal > 0.0 and _perto(dobro, normal * 2.0, 0.05), "Shishimai: Sorte dobra o próximo golpe dado (%.1f → %.1f)" % [normal, dobro])
	c._sorte_partes = 0
	c._sorte_t = 0.0
	por.call(c, centro + dz * 12.0, dx)
	# Arrastão: leva o primeiro inimigo da frente e prende no fim.
	por.call(a, centro, dx)
	por.call(b, centro + dx * 2.0, -dx)
	hp0 = b.hp
	var b0: Vector3 = b.global_position
	Herois._arrastao(a)
	await get_tree().create_timer(0.75).timeout
	var andou: float = (b.global_position - b0).dot(dx)
	_check(andou > 3.0 and b.hp < hp0, "Shishimai: Arrastão leva o inimigo junto (%.1f m) e fere" % andou)
	_check(b._azar_t > 0.0, "Shishimai: quem foi arrastado fica com Azar")
	b._azar_t = 0.0

	# Jorogumo: o fio do básico gruda (lento acumulando) e o 3º tiro prende.
	a.set_class(load("res://config/classes/jorogumo.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 5.0, -dx)
	b.take_damage(4.0, a, dx, 1.0, false, "fio", 1)
	b.take_damage(4.0, a, dx, 1.0, false, "fio", 1)
	_check(b._fio_n == 2 and b._fio_dono == a and b._slow_t > 0.0 and b._preso_t <= 0.0, "Jorogumo: o fio gruda e acumula (%d)" % b._fio_n)
	b.take_damage(4.0, a, dx, 1.0, false, "fio", 2)
	_check(b._preso_t > 0.0, "Jorogumo: o 3º tiro (Rede) prende")
	# Puxar os Fios: quem tem o fio dela vem para perto e fica preso.
	por.call(b, centro + dx * 7.0, -dx)
	b._fio_dono = a
	b._fio_t = 2.0
	Herois._puxar_fios(a)
	_check(b._knock.dot(-dx) > 1.0 and b._preso_t > 0.0, "Jorogumo: Puxar os Fios puxa e prende quem tem o fio dela")
	b._fio_t = 0.0
	b._fio_dono = null
	# Teia: prende quem pisa; fogo queima e vento rasga.
	por.call(b, centro + dx * 12.0, -dx)
	a.aim_point = centro + dx * 5.0
	var antes_t := get_tree().get_nodes_in_group("teias").size()
	_check(Herois._teia(a) and get_tree().get_nodes_in_group("teias").size() == antes_t + 1, "Jorogumo: Q tece uma teia")
	var teia = null
	for n in get_tree().get_nodes_in_group("teias"):
		if n.dona == a:
			teia = n
	if teia:
		por.call(b, Vector3(teia.global_position.x, centro.y, teia.global_position.z), -dx)
		await get_tree().create_timer(0.1).timeout
		_check(b._preso_t > 0.0 and b._fio_dono == a, "Jorogumo: quem pisa na teia fica preso")
		Reacoes.em(game, teia.global_position, 1.0, "fogo", b.team)
		_check(teia.indo, "reação: fogo queima a teia")
		a.aim_point = centro + dx * 5.0 + dz * 4.0
		Herois._teia(a)
		var t2 = null
		for n in get_tree().get_nodes_in_group("teias"):
			if n.dona == a and not n.indo:
				t2 = n
		_check(t2 != null, "Jorogumo: segunda teia")
		if t2:
			Reacoes.em(game, t2.global_position, 1.0, "vento", a.team)
			_check(not t2.indo, "reação: o próprio time não rasga a teia")
			Reacoes.em(game, t2.global_position, 1.0, "vento", b.team)
			_check(t2.indo, "reação: vento rasga a teia")
	for i in cfg.teia_max + 1:
		a.aim_point = centro + dz * (3.0 + i)
		Herois._teia(a)
	var vivas := 0
	for n in get_tree().get_nodes_in_group("teias"):
		if n.dona == a and not n.indo:
			vivas += 1
	_check(vivas == cfg.teia_max, "Jorogumo: no máximo %d teias (tem %d)" % [cfg.teia_max, vivas])
	for n in get_tree().get_nodes_in_group("teias"):
		if n.dona == a:
			n.sumir()
	# Casulo: segura o inimigo, a seda segura parte do dano e o aliado dele quebra.
	por.call(b, centro + dx * 3.0, -dx)
	_check(Herois._casulo(a) and b._casulo_t > 0.0 and not b.maos_livres(), "Jorogumo: Casulo enrola o inimigo perto")
	hb = b.hp
	b.take_damage(20.0, a, dx)
	var seda: float = hb - b.hp
	b.hp = b.max_hp()
	var vida: int = b._casulo_vida
	for i in vida:
		Herois.bater_casulo(b, b)
	_check(b._casulo_t <= 0.0, "Jorogumo: %d golpes de aliado soltam o casulo" % vida)
	b.take_damage(20.0, a, dx)
	var sem: float = b.max_hp() - b.hp
	_check(seda > 0.0 and _perto(seda, sem * cfg.casulo_dano, 0.05), "Jorogumo: o casulo segura parte do dano (%.1f de %.1f)" % [seda, sem])

	a.brain = cerebros[0]
	b.brain = cerebros[1]
	c.brain = cerebros[2]
	a.set_class(classes[0])
	b.set_class(classes[1])
	c.set_class(classes[2])
	for u in guardados:
		if is_instance_valid(u):
			u.global_position = guardados[u]
			u.reset_physics_interpolation()


## Heróis 2.27b: Kodama do Shinboku (sementes, Raízes, Bosque, Floresta) e
## Kaminari-kozō (carga, descarga em cadeia, Para-raios, Relâmpago, Tambores) e
## as reações (molhado conduz, fogo queima o bosque, árvore é para-raios).
func _herois_2_27b() -> void:
	var cfg = get_node("/root/Config").cfg
	var a = null
	var b = null
	var c = null
	var e = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo:
			if a == null:
				a = u
			elif b == null and u.team != a.team:
				b = u
			elif c == null and u.team == a.team:
				c = u
			elif e == null and b != null and u.team == b.team:
				e = u
	if a == null or b == null or c == null or e == null:
		_check(false, "heróis 2.27b: faltou boneco")
		return
	var lista := [a, b, c, e]
	var classes := []
	var cerebros := []
	for u in lista:
		classes.append(u.stats)
		cerebros.append(u.brain)
		u.brain = null
	var centro := Vector3(0, 0, 0)
	centro.y = game.arena.ground_y(0, 0)
	var guardados := {}
	for u in game.units:
		guardados[u] = u.global_position
		if not u in lista and u.global_position.distance_to(centro) < 35.0:
			u.global_position = game.arena.spawn_center[u.team]
	var por := func(x, p: Vector3, olha: Vector3) -> void:
		x.global_position = p
		x.velocity = Vector3.ZERO
		x._knock = Vector3.ZERO
		x._dodge_t = 0.0
		x._blocking = false
		x._shield = 0.0
		x._intocavel_t = 0.0
		x._preso_t = 0.0
		x._slow_t = 0.0
		x._molhado_t = 0.0
		x.hp = x.max_hp()
		x._visual.rotation.y = atan2(olha.x, olha.z)
		x.aim_dir = olha
		x.reset_physics_interpolation()
	var limpar := func() -> void:
		for n in get_tree().get_nodes_in_group("arvores_kodama"):
			n.remove_from_group("arvores_kodama")
			n.queue_free()
		for n in get_tree().get_nodes_in_group("para_raios"):
			n.remove_from_group("para_raios")
			n.queue_free()
	limpar.call()  # árvores e para-raios que sobraram dos testes de todos os heróis
	var dx := Vector3(1, 0, 0)
	var dz := Vector3(0, 0, 1)
	for u in [b, c, e]:
		u.set_class(load("res://config/classes/guerreiro.tres"))
	por.call(c, centro - dz * 14.0, dx)
	por.call(e, centro + dz * 16.0, dx)

	# --- Kodama ---
	a.set_class(load("res://config/classes/kodama.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 4.0, -dx)
	var hp0: float = b.hp
	_check(HeroisNatureza.raizes(a) and b.hp < hp0 and b._preso_t > 0.0, "Kodama: Raízes ferem e prendem quem está na linha")
	por.call(b, centro + dx * 4.0, -dx)
	b.take_damage(5.0, a, dx, 1.0, false, "semente", 1)
	_check(b._preso_t <= 0.0, "Kodama: semente comum não prende")
	b.take_damage(5.0, a, dx, 1.0, false, "semente", 2)
	_check(b._preso_t > 0.0, "Kodama: o 3º tiro (semente forte) brota e prende")
	# Bosque: três árvores que bloqueiam tiro e passagem e curam na sombra.
	por.call(b, centro + dx * 14.0, -dx)
	a.aim_point = centro + dx * 6.0
	HeroisNatureza.bosque(a)
	var arvores := []
	for n in get_tree().get_nodes_in_group("arvores_kodama"):
		if n.dono == a:
			arvores.append(n)
	_check(arvores.size() == cfg.bosque_n, "Kodama: Bosque faz %d árvores (fez %d)" % [cfg.bosque_n, arvores.size()])
	await get_tree().physics_frame
	await get_tree().physics_frame
	if arvores.size() > 0:
		var arv = arvores[0]
		var p0: Vector3 = arv.global_position + Vector3(0, 1.2, 0)
		var q := PhysicsRayQueryParameters3D.create(p0 - dz * 2.0, p0 + dz * 2.0, 1)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(q)
		_check(not hit.is_empty(), "Kodama: o tronco bloqueia tiro (raio no mundo bate)")
		por.call(c, arv.global_position + dz * 1.4, dx)
		c.hp = c.max_hp() * 0.5
		var hc: float = c.hp
		if c.has_meta("sombra_ms"):
			c.remove_meta("sombra_ms")
		arv._curar_sombra()
		_check(c.hp > hc, "Kodama: a sombra da árvore cura o aliado (%.0f → %.0f)" % [hc, c.hp])
		# Fogo do próprio time não queima; do outro vira tocha.
		Reacoes.em(game, arv.global_position, 1.0, "fogo", a.team)
		_check(arv._tocha_t <= 0.0, "reação: fogo do próprio time não queima a árvore")
		Reacoes.em(game, arv.global_position, 1.0, "fogo", b.team)
		_check(arv._tocha_t > 0.0, "reação: fogo do inimigo vira tocha")
		arv._tick_tocha(cfg.tocha_tempo + 0.1)
		_check(arv.indo, "Kodama: a tocha cai no fim")
		por.call(c, centro - dz * 14.0, dx)
	if arvores.size() > 1:
		var arv2 = arvores[1]
		var toras0: int = game.toras.size()
		var cortes := 0
		for i in cfg.arvore_golpes:
			var dir: Vector3 = (arv2.global_position - b.global_position)
			dir.y = 0
			por.call(b, arv2.global_position - dx * 1.2, dx)
			if HeroisNatureza.cortar_arvore(b, dx, 2.0, 120.0):
				cortes += 1
		_check(cortes == cfg.arvore_golpes and arv2.indo and game.toras.size() == toras0 + 1, "Kodama: o lenhador derruba em %d golpes e ganha 1 tora" % cfg.arvore_golpes)
	limpar.call()
	await get_tree().process_frame
	# Floresta Antiga: anel de gigantes; dentro, inimigo preso e aliado curado.
	por.call(a, centro, dx)
	por.call(b, centro + dx * 4.0, -dx)
	por.call(c, centro - dx * 4.0, dx)
	c.hp = c.max_hp() * 0.5
	var hc2: float = c.hp
	hp0 = b.hp
	_check(HeroisNatureza.floresta(a), "Kodama: Floresta Antiga sai")
	var gigantes := 0
	for n in get_tree().get_nodes_in_group("arvores_kodama"):
		if n.dono == a and n.grande:
			gigantes += 1
	_check(gigantes >= cfg.floresta_n - 3, "Kodama: o anel tem %d gigantes" % gigantes)
	HeroisNatureza._tick_floresta(a, 0.7)
	_check(b.hp < hp0 and b._preso_t > 0.0 and c.hp > hc2, "Kodama: a floresta prende e fere o inimigo e cura o aliado de dentro")
	a._floresta_t = 0.0
	limpar.call()
	await get_tree().process_frame

	# --- Kaminari-kozō ---
	a.set_class(load("res://config/classes/kaminari_kozo.tres"))
	por.call(a, centro, dx)
	por.call(b, centro + dx * 2.0, -dx)
	por.call(e, centro + dx * 2.0 + dz * 3.0, -dx)
	a.carga = 0.0
	HeroisNatureza.somar_carga(a, 1.0)
	_check(a.carga >= 1.0 and a.has_meta("carga_no"), "Kaminari-kozō: carga cheia acende o cabelo")
	hp0 = b.hp
	var he: float = e.hp
	b.take_damage(10.0, a, dx)
	_check(hp0 - b.hp >= 10.0 + cfg.descarga_dano * 0.9 and a.carga <= 0.0 and not a.has_meta("carga_no"), "Kaminari-kozō: o golpe com carga cheia descarrega (%.0f de dano)" % (hp0 - b.hp))
	_check(e.hp < he, "Kaminari-kozō: a descarga pula para o inimigo perto")
	# Molhado conduz: mais dano de raio e a descarga pula mais longe.
	por.call(b, centro + dx * 2.0, -dx)
	hp0 = b.hp
	b.take_damage(10.0, a, dx, 0.0, false, "trovao", 1)
	var seco: float = hp0 - b.hp
	b.hp = b.max_hp()
	b.take_damage(0.5, c, dx, 0.0, false, "agua", 1)
	_check(b._molhado_t > 0.0, "reação: a água molha")
	hp0 = b.hp
	b.take_damage(10.0, a, dx, 0.0, false, "trovao", 1)
	var molhado: float = hp0 - b.hp
	_check(_perto(molhado, seco * cfg.molhado_dano, 0.05), "reação: molhado leva %.0f%% do raio (%.1f → %.1f)" % [cfg.molhado_dano * 100, seco, molhado])
	por.call(e, centro + dx * 2.0 + dz * (cfg.descarga_raio + 2.0), -dx)
	b.hp = b.max_hp()
	b._molhado_t = cfg.molhado_tempo
	he = e.hp
	HeroisNatureza.somar_carga(a, 1.0)
	b.take_damage(5.0, a, dx)
	_check(e.hp < he, "reação: molhado, a descarga pula %.0f m" % (cfg.descarga_raio + 2.0))
	b._molhado_t = 0.0
	# Correr carrega.
	a.carga = 0.0
	a.velocity = dx * 7.0
	HeroisNatureza.tick(a, 1.0)
	_check(a.carga > 0.05, "Kaminari-kozō: correr junta carga (%.2f)" % a.carga)
	a.velocity = Vector3.ZERO
	a.carga = 0.0
	# Para-raios: crava onde mira, dá choque em volta e só pararaios_max por dono.
	por.call(b, centro + dx * 4.5, -dx)
	por.call(e, centro + dz * 16.0, dx)
	a.aim_point = centro + dx * 4.0
	_check(HeroisNatureza.para_raios(a), "Kaminari-kozō: Q crava um para-raios")
	var pr = null
	for n in get_tree().get_nodes_in_group("para_raios"):
		if n.dono == a:
			pr = n
	_check(pr != null, "Kaminari-kozō: o para-raios existe")
	if pr:
		hp0 = b.hp
		pr._physics_process(0.6)
		_check(b.hp < hp0, "Kaminari-kozō: o para-raios dá choque em quem está perto")
	for i in cfg.pararaios_max + 1:
		a.aim_point = centro + dz * (3.0 + i)
		HeroisNatureza.para_raios(a)
	var vivos := 0
	for n in get_tree().get_nodes_in_group("para_raios"):
		if n.dono == a and not n.indo:
			vivos += 1
	_check(vivos == cfg.pararaios_max, "Kaminari-kozō: no máximo %d para-raios (tem %d)" % [cfg.pararaios_max, vivos])
	limpar.call()
	await get_tree().process_frame
	# Relâmpago: salta em linha e fere quem está no caminho.
	por.call(a, centro, dx)
	por.call(b, centro + dx * 4.0 + dz * 0.4, -dx)
	hp0 = b.hp
	HeroisNatureza.relampago(a)
	var salto: float = (a.global_position - centro).dot(dx)
	_check(salto > cfg.relampago_dist * 0.8 and b.hp < hp0 and a.carga >= cfg.carga_relampago - 0.01, "Kaminari-kozō: Relâmpago salta %.1f m, fere no caminho e carrega" % salto)
	a.carga = 0.0
	HeroisNatureza.zerar(a)
	# Tambores: raio do céu no inimigo mais perto.
	por.call(a, centro, dx)
	por.call(b, centro + dx * 5.0, -dx)
	hp0 = b.hp
	HeroisNatureza.tambores(a)
	HeroisNatureza._tick_tambores(a, 0.2)
	_check(b.hp < hp0 and b._preso_t > 0.0, "Kaminari-kozō: Tambores derrubam um raio no inimigo")
	a._tambores_t = 0.0
	# Árvore do Kodama é para-raios: o raio cai nela (e ela pega fogo), não no alvo.
	var arv3 = HeroisNatureza.plantar(b, centro + dx * 5.0 + dz * 2.0, 6.0, false)
	por.call(b, centro + dx * 5.0, -dx)
	hp0 = b.hp
	HeroisNatureza.raio_do_ceu(a, b)
	_check(b.hp >= hp0 - 0.01 and arv3._tocha_t > 0.0, "reação: a árvore do Kodama pega o raio e vira tocha")
	limpar.call()
	await get_tree().process_frame

	for i in lista.size():
		var u = lista[i]
		u.brain = cerebros[i]
		u.set_class(classes[i])
		HeroisNatureza.zerar(u)
	for u in guardados:
		if is_instance_valid(u):
			u.global_position = guardados[u]
			u.reset_physics_interpolation()


## 2.25c: toda classe jogável tem som de poder próprio (nenhum repetido);
## caminhos e heróis têm super próprio; todos têm som de golpe final, exceto o
## Construtor (base corpo a corpo de martelo).
func _sons_proprios() -> void:
	var sfx := get_node("/root/Sfx")
	var vistos := {}
	for b: ClassStats in Config.cfg.hat_class_list:
		var lista: Array = [b]
		lista.append_array(b.caminhos)
		lista.append_array(b.herois)
		for c: ClassStats in lista:
			_check(sfx.has(c.som_poder), "%s: som_poder '%s' não carregou" % [c.display_name, c.som_poder])
			_check(not vistos.has(c.som_poder), "%s repete o som de poder de %s" % [c.display_name, vistos.get(c.som_poder, "")])
			vistos[c.som_poder] = c.display_name
			if c.attack_kind != "melee" or c != b:
				_check(sfx.has(c.som_golpe_final), "%s: som_golpe_final '%s' não carregou" % [c.display_name, c.som_golpe_final])
			if c != b:
				_check(sfx.has(c.som_super), "%s: som_super '%s' não carregou" % [c.display_name, c.som_super])


## Ciclo 2.28: multiplayer em lockstep (comando, código da sala, sorteio com
## semente, trocar de time, quem sai vira bot).
func _multiplayer() -> void:
	var c = Comando.new()
	c.botoes = Comando.ATAQUE | Comando.ESQUIVA | Comando.SEGURA_F
	c.move = Vector2(0.7071, -0.7071)
	c.mira = Vector2(-0.6, 0.8)
	c.ponto = Vector3(-61.234, 1.5, 33.21)
	c.alvo = 9
	c.acao = Comando.Acao.TROCAR_TIME
	var b: PackedByteArray = c.para_bytes()
	var q = Comando.de_bytes(b)
	_check(b.size() == 17, "rede: comando tem 17 bytes (tem %d)" % b.size())
	_check(q.para_bytes() == b, "rede: comando ida e volta pelos bytes é idêntico")
	_check(q.botoes == c.botoes and q.alvo == 9 and q.acao == Comando.Acao.TROCAR_TIME, "rede: botões, alvo e ação chegam iguais")
	_check(q.ponto.distance_to(c.ponto) < 0.01 and q.move.distance_to(c.move) < 0.01 and q.mira.distance_to(c.mira) < 0.001, "rede: movimento e mira chegam com erro < 1 cm")

	var cod: String = CodigoSala.gerar("189.45.201.7")
	_check(cod.length() == 9 and cod[4] == "-", "rede: código da sala no formato XXXX-XXXX (%s)" % cod)
	_check(CodigoSala.ler(cod, 24680).get("ip", "") == "189.45.201.7", "rede: o código volta para o IP")
	_check(CodigoSala.ler(cod.to_lower().replace("-", " "), 24680).get("ip", "") == "189.45.201.7", "rede: código aceita minúscula e espaço")
	_check(CodigoSala.ler("26.10.0.5:1234", 24680) == {"ip": "26.10.0.5", "porta": 1234}, "rede: aceita o IP do Radmin com porta")
	var errado := cod.substr(0, 8) + ("0" if cod[8] != "0" else "1")
	_check(CodigoSala.ler(errado, 24680).is_empty(), "rede: código com uma letra errada é recusado")
	_check(CodigoSala.ip_privado("100.70.1.2") and CodigoSala.ip_privado("192.168.0.9") and not CodigoSala.ip_privado("189.45.201.7"), "rede: reconhece CGNAT e rede local")
	# 2.28c: código sorteado + recados cifrados (só quem tem o código lê).
	var cod_novo := CodigoSala.novo()
	_check(CodigoSala.ler(cod_novo, 24680).get("codigo", "") == cod_novo.replace("-", ""), "rede: código sorteado é lido como código (%s)" % cod_novo)
	_check(not CodigoSala.ler("26.10.0.5", 24680).has("codigo"), "rede: IP digitado não vira código")
	var sa := Sinal.new()
	var sb := Sinal.new()
	var sc := Sinal.new()
	sa._chave = Sinal._sha("cdb1-chave:" + cod_novo); sa._chave_mac = Sinal._sha("cdb1-mac:" + cod_novo)
	sb._chave = sa._chave; sb._chave_mac = sa._chave_mac
	sc._chave = Sinal._sha("cdb1-chave:OUTRO"); sc._chave_mac = Sinal._sha("cdb1-mac:OUTRO")
	var txt := sa._cifrar("{\"t\":\"oi\",\"de\":42}".to_utf8_buffer())
	_check(sb._decifrar(txt).get_string_from_utf8() == "{\"t\":\"oi\",\"de\":42}", "rede: recado cifrado volta igual com o mesmo código")
	_check(sc._decifrar(txt).is_empty(), "rede: outro código não lê o recado")
	var adulterado := Marshalls.base64_to_raw(txt)
	adulterado[20] = adulterado[20] ^ 1
	_check(sb._decifrar(Marshalls.raw_to_base64(adulterado)).is_empty(), "rede: recado adulterado é ignorado")
	_check(not txt.contains("\"") and not txt.contains(":"), "rede: o quadro de recados só vê lixo (sem o JSON aberto)")
	sa.free(); sb.free(); sc.free()

	var estado = Sorte.rng.state
	Sorte.semear(42)
	var s1 := [Sorte.f(), Sorte.i(), Sorte.r(-3, 3)]
	Sorte.semear(42)
	var s2 := [Sorte.f(), Sorte.i(), Sorte.r(-3, 3)]
	Sorte.rng.state = estado
	_check(s1 == s2, "rede: mesma semente, mesmo sorteio das regras")

	# Um bot do azul vira "amigo" de mentira (peer 99) e troca de time.
	var u = null
	for x in game.units:
		if x.team == 0 and not x.is_player and x.alive and x.brain is BotBrain:
			u = x
			break
	if u == null:
		_check(false, "rede: sem bot azul para o teste de trocar de time")
		return
	var h0: Array = game.humanos_time.duplicate()
	var bot_velho = u.brain
	u.remove_child(bot_velho)
	bot_velho.queue_free()
	var rb = RedeBrain.new()
	rb.unit = u
	rb.game = game
	rb.peer = 99
	rb.nome = "Teste"
	u.add_child(rb)
	u.brain = rb
	u.humano = true
	game.humanos_time[0] += 1
	game.cerebros[99] = rb
	var cmd = Comando.new()
	cmd.move = Vector2(1, 0)
	cmd.botoes = Comando.ESQUIVA
	rb.receber(cmd)
	rb.tick(0.016)
	_check(u.wants_dodge and u.move_intent.x > 0.99, "rede: o cérebro de rede aplica o comando (dash e andar)")
	game.trocar_time(rb)
	var novo = rb.unit
	_check(novo != u and novo.team == 1 and novo.humano and novo.brain == rb, "rede: trocar de time assume um bot do vermelho")
	_check(not u.humano and u.brain is BotBrain, "rede: o boneco antigo vira bot")
	_check(game.humanos_time[0] == h0[0] and game.humanos_time[1] == h0[1] + 1, "rede: contagem de humanos por time acompanha a troca")
	_check(game.units.size() == 16 or game.sandbox, "rede: continua 8 contra 8 depois da troca")
	game.humano_saiu(99)
	_check(not novo.humano and novo.brain is BotBrain and not game.cerebros.has(99), "rede: quem sai vira bot")
	_check(game.humanos_time == h0, "rede: humanos por time voltam ao normal")


## Arena de chapéus (Ciclo 2.29): a lista do Tambor de Desafio e as fileiras.
func _arena_chapeus() -> void:
	var cfg = get_node("/root/Config").cfg
	var pool: Array = cfg.classes_arena()
	_check(not pool.has(cfg.villager), "arena: recruta fora do sorteio do tambor")
	for c in cfg.todas_classes():
		_check(pool.has(c), "arena: classe %s no sorteio do tambor" % c.id)
	var herois := 0
	for c in cfg.hat_classes():
		for h in c.caminhos:
			_check(pool.has(h), "arena: caminho %s no sorteio" % h.id)
		for h in c.herois:
			_check(pool.has(h), "arena: herói %s no sorteio" % h.id)
			herois += 1
	_check(herois == 13, "arena: 13 heróis raros no sorteio (tem %d)" % herois)
	var vistos := {}
	for c in pool:
		_check(not vistos.has(c.id), "arena: classe %s repetida no sorteio" % c.id)
		vistos[c.id] = true
	# Fileiras: cada uma centrada, com espaço entre vizinhos e avanços crescentes.
	var tams: Array[int] = [5, 8, 7, 6]
	var fileiras: Array = Game.fileiras_arena(tams)
	_check(fileiras.size() == 4, "arena: uma fileira por grupo")
	var avanco_ant := -1.0
	for f in fileiras.size():
		var linha: Array = fileiras[f]
		_check(linha.size() == tams[f], "arena: fileira %d com %d pads" % [f, tams[f]])
		var soma := 0.0
		for i in linha.size():
			soma += (linha[i] as Vector2).y
			if i > 0:
				_check((linha[i] as Vector2).y - (linha[i - 1] as Vector2).y >= 4.0, "arena: pads vizinhos a 4 m ou mais (fileira %d)" % f)
		_check(absf(soma) < 0.01, "arena: fileira %d centrada no eixo do portão" % f)
		_check((linha[0] as Vector2).x > avanco_ant, "arena: fileira %d mais à frente que a anterior" % f)
		avanco_ant = (linha[0] as Vector2).x
	# O nível da arena: base veste 1, caminho veste o máximo, herói um acima.
	var base: ClassStats = cfg.hat_classes()[0]
	_check(game._nivel_arena(base.id) == 1, "arena: classe base veste nível 1")
	if base.caminhos.size() > 0:
		_check(game._nivel_arena(base.caminhos[0].id) == cfg.mago_nivel_max, "arena: caminho veste o nível máximo")
	if base.herois.size() > 0:
		_check(game._nivel_arena(base.herois[0].id) == cfg.mago_nivel_max + 1, "arena: herói veste um nível acima do máximo")


## Ciclo 2.29b: tambores separados, recarga rápida só de quem testa, troca de
## chapéu encerra o poder antigo e golpe de toque mede até a borda do corpo.
func _poderes_2_29b() -> void:
	var cfg = get_node("/root/Config").cfg
	var herois_pool: Array = cfg.classes_arena_herois()
	for c in cfg.hat_classes():
		_check(not herois_pool.has(c), "2.29b: classe base %s fora do Tambor dos Heróis" % c.id)
	_check(herois_pool.size() == cfg.classes_arena().size() - cfg.hat_classes().size(), "2.29b: Tambor dos Heróis = caminhos + heróis")
	var u = _alvo()
	if u == null:
		return
	# O inimigo da arena não ganha recarga rápida (antes soltava poder sem parar).
	var era: bool = u.descartavel
	u.descartavel = true
	_check(not game.recarga_rapida(u), "2.29b: inimigo do tambor recarrega no ritmo normal")
	u.descartavel = era
	# Trocar de chapéu no meio da Ciranda: a corrente para e o Q novo sai.
	u.set_class(load("res://config/classes/kusarigama.tres"))
	u._ciranda_t = 5.0
	u._spin_t = 2.0
	u._fury_t = 2.0
	u.set_class(load("res://config/classes/kitsune_luz.tres"))
	_check(u._ciranda_t <= 0.0 and u._spin_t <= 0.0 and u._fury_t <= 0.0 and u.maos_livres(),
			"2.29b: trocar de chapéu encerra Ciranda/Redemoinho/Fúria da classe antiga")
	# Flecha Arrancada: inimigo alinhado a alcance + 0,5 m (encostando a borda) é achado.
	var inim = null
	for x in game.units:
		if x.alive and x.team != u.team and x != u:
			inim = x
			break
	if inim == null:
		return
	u.set_class(load("res://config/classes/ochimusha.tres"))
	var p0: Vector3 = u.global_position
	var q0: Vector3 = inim.global_position
	var dir := Vector3.RIGHT
	u.aim_dir = dir
	inim.global_position = p0 + dir * (cfg.flecha_alcance + 0.5)
	_check(Herois.alvo_toque(u, cfg.flecha_alcance, cfg.flecha_cone) == inim, "2.29b: Flecha Arrancada acha o inimigo alinhado na borda do alcance")
	inim.global_position = p0 + dir.rotated(Vector3.UP, deg_to_rad(cfg.flecha_cone * 0.5 - 5.0)) * cfg.flecha_alcance
	_check(Herois.alvo_toque(u, cfg.flecha_alcance, cfg.flecha_cone) == inim, "2.29b: Flecha Arrancada acha o inimigo meio de lado")
	inim.global_position = p0 - dir * 2.0
	_check(Herois.alvo_toque(u, cfg.flecha_alcance, cfg.flecha_cone) == null, "2.29b: Flecha Arrancada não acerta quem está atrás")
	inim.global_position = q0
	u.global_position = p0
	u.set_class(cfg.villager)
