extends "res://tests/lib/caso.gd"
## Testes de regra: combate. Rodam pelo tests/regras.gd, na ordem de lá.

## Dano, carregador, esquiva, escudo e cura.
func _dano() -> void:
	var u = _alvo()
	_check(u != null, "nenhum boneco vivo para testar")
	if u == null:
		return
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


## Dash por personalidade: só valores conhecidos (o resto cairia no padrão calado).
func _dash_estilos() -> void:
	for c in cfg.todas_classes():
		_check(c.dash_estilo in ["", "rolar", "rolamento", "ninja", "chama", "polvora", "tropeco"], "dash: estilo desconhecido em %s: '%s'" % [c.id, c.dash_estilo])
