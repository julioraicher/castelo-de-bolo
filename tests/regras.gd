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
	_dano()
	_contra_golpe()
	_carga()
	_poderes_q()
	_controles()
	await _empurrao()
	_madeira()
	_machadada()
	_maquina()
	await _obra()
	_nivel2()
	_caminho_magos()
	await _alma()
	_ferradura()
	_lote_2_7()
	_super()
	_torretas()
	_catapulta()
	_equilibrio_2_10()
	await _mira()
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
	for c in cfg.oficina_classes:
		_check(c.classe_base != &"construtor", "Construtor não deveria ter variação (%s)" % c.id)
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
	var classes: Array = cfg.hat_classes() + cfg.oficina_classes + cfg.magos_opostos
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
		u._use_super()
		_check(u.super_carga == 0.0, "super %s: não saiu" % c.id)
		if c.super_tipo == "sombra":
			_check(u._sombra_t > 0.0, "super sombra: deveria ficar invisível")
			if inimigo:
				var p0: Vector3 = u.global_position
				u.global_position = inimigo.global_position + Vector3(cfg.sombra_visto + 3.0, 0, 0)
				_check(u.na_sombra_para(inimigo), "super sombra: bot inimigo a %.0f m não deveria ver" % (cfg.sombra_visto + 3.0))
				u.global_position = p0
			u._fim_sombra()
		else:
			_check(_perto(u.stats.power_radius, c.power_radius * cfg.super_mult_raio, 0.01), "super %s: raio deveria crescer" % c.id)
			u._tick_super(999.0)
			_check(u.stats == c, "super %s: stats deveria voltar ao normal" % c.id)
		u.reset_physics_interpolation()


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


func _check(ok: bool, nome: String) -> void:
	_total += 1
	if not ok:
		_falhas.append(nome)


func _perto(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


## Conteúdo: tudo que o game_config lista existe e tem números com sentido.
func _dados() -> void:
	var cfg = get_node("/root/Config").cfg
	var classes: Array = cfg.hat_classes() + cfg.oficina_classes
	classes.append(cfg.villager)
	for c in classes:
		_check(c != null, "classe nula no game_config")
		if c == null:
			continue
		_check(c.model != null, "classe %s sem modelo" % c.id)
		_check(c.max_hp > 0.0, "classe %s com vida <= 0" % c.id)
		_check(c.move_speed > 0.0, "classe %s com velocidade <= 0" % c.id)
	# Ficha do menu (seção Classes): toda classe jogável tem epíteto e identidade.
	for c in cfg.hat_classes() + cfg.oficina_classes + cfg.magos_opostos:
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
	var classes: Array = cfg.hat_classes() + cfg.oficina_classes
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
	pad.avancar(cfg.maquina_intervalo - 0.05)
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


## Obra: consome madeira do estoque, não passa do que foi entregue, estoque >= 0.
func _obra() -> void:
	var of = null
	for o in game.oficinas:
		if o.estado != 2:  # Oficina.Estado.PRONTA
			of = o
			break
	_check(of != null, "nenhuma oficina por construir para testar")
	if of == null:
		return
	var team: int = of.team
	game.madeira[team] = 1
	var e0: int = of.madeira_entregue
	_check(of.puxar_madeira(), "obra deveria puxar madeira com estoque 1")
	_check(game.madeira[team] == 0 and of.madeira_entregue == e0 + 1, "puxar deveria mover 1 do estoque para a obra")
	_check(not of.puxar_madeira() and game.madeira[team] == 0, "sem estoque a obra não puxa e o estoque não fica negativo")
	of.add_progress(1.0, null)
	_check(_perto(of.progresso, of.teto(), 0.001) and of.progresso < 1.0,
		"obra passou da madeira entregue: progresso %.2f, teto %.2f" % [of.progresso, of.teto()])
	# Progresso guardado: parar de construir não apaga, e [E] não troca a
	# opção de uma obra começada (antes zerava tudo).
	var p0: float = of.progresso
	var op0: int = of.opcao_i
	_check(not of.trocar_opcao(), "obra começada não deveria trocar de opção")
	_check(of.opcao_i == op0 and _perto(of.progresso, p0, 1e-6), "trocar a opção apagou a obra: %.2f -> %.2f" % [p0, of.progresso])
	await get_tree().create_timer(0.3).timeout
	_check(of.progresso >= p0 - 1e-6, "obra perdeu progresso parada: %.2f -> %.2f" % [p0, of.progresso])
	_check(game.obra_do_time(team, game.arena.spawn_center[team]) == of, "Construtor deveria voltar para a obra começada do time")


## Maquininha nível 2: oficina pronta sobe a maquininha da classe_base
## (intervalo e estoque de nível 2, +1 chapéu na hora); só uma vez.
func _nivel2() -> void:
	var cfg = get_node("/root/Config").cfg
	var lista = cfg.oficina_classes
	for of in game.oficinas:
		if of.estado == 2:
			continue
		for i in lista.size():
			for pad in game.hat_pads:
				if pad.team == of.team and pad.nivel == 1 and lista[i].classe_base != &"" and pad.stats.id == lista[i].classe_base:
					of.opcao_i = i
					pad.take()
					var e0: int = pad.estoque + 1
					of.madeira_entregue = of.custo()
					of.add_progress(1.0, null)
					_check(of.estado == 2, "nível 2: oficina deveria ficar pronta")
					_check(pad.nivel == 2 and pad.estoque_max == cfg.maquina_n2_estoque and _perto(pad.intervalo, cfg.maquina_n2_intervalo, 1e-4),
						"nível 2: maquininha de %s não subiu (nivel %d, max %d)" % [pad.stats.id, pad.nivel, pad.estoque_max])
					_check(pad.estoque == e0, "nível 2: deveria ganhar 1 chapéu na hora (%d -> %d)" % [e0, pad.estoque])
					_check(not pad.subir_nivel(), "nível 2: não sobe duas vezes")
					_nivel2_madeira(of.team)
					return
	_check(false, "nível 2: nenhuma oficina com classe_base para testar")


## Nível 2 com madeira: maquina_n2_custo madeiras do estoque sobem a máquina.
func _nivel2_madeira(team: int) -> void:
	var cfg = get_node("/root/Config").cfg
	var pad = null
	for p in game.hat_pads:
		if p.team == team and p.nivel == 1:
			pad = p
			break
	if pad == null:
		_check(false, "nível 2 (madeira): nenhuma máquina nível 1")
		return
	game.madeira[team] = cfg.maquina_n2_custo - 1
	var ok := 0
	for i in cfg.maquina_n2_custo:
		if pad.puxar_madeira_n2(game):
			ok += 1
	_check(ok == cfg.maquina_n2_custo - 1 and pad.nivel == 1 and game.madeira[team] == 0,
		"nível 2 (madeira): sem estoque não deveria subir (puxou %d, nível %d)" % [ok, pad.nivel])
	game.madeira[team] = 1
	_check(pad.puxar_madeira_n2(game) and pad.nivel == 2, "nível 2 (madeira): a última madeira deveria subir a máquina")


## Caminho dos magos: começar um terreno de mago sela o oposto do mesmo time;
## pronto ele está no nível 2 e sobe com madeira até mago_nivel_max, dando
## bônus só para a classe do caminho.
func _caminho_magos() -> void:
	var cfg = get_node("/root/Config").cfg
	for t in 2:
		if game.caminho[t] >= 0:
			continue
		var lotes := []
		for of in game.oficinas:
			if of.team == t and of.caminho >= 0:
				lotes.append(of)
		_check(lotes.size() == 2, "caminho: time %d deveria ter 2 terrenos de mago (tem %d)" % [t, lotes.size()])
		if lotes.size() != 2:
			return
		var a = lotes[0]
		var b = lotes[1]
		_check(a.opcao() != b.opcao() and not a.trocar_opcao(), "caminho: terrenos de mago são fixos e diferentes")
		game.madeira[t] = 1
		_check(a.puxar_madeira() and game.caminho[t] == a.caminho, "caminho: a primeira madeira deveria escolher o caminho")
		_check(b.selada and not a.selada, "caminho: o terreno oposto deveria ficar selado")
		game.madeira[t] = 5
		_check(not b.puxar_madeira() and game.madeira[t] == 5, "caminho: terreno selado não aceita madeira")
		b.add_progress(1.0, null)
		_check(b.progresso == 0.0 and b.estado == 0, "caminho: terreno selado não pode ser construído")
		_check(game.nearest_oficina(t, b.global_position, 1.0, true) != b, "caminho: bots não deveriam ir ao terreno selado")
		a.madeira_entregue = a.custo()
		a.add_progress(1.0, null)
		_check(a.estado == 2 and a.nivel == 2 and a.pad != null, "caminho: oficina pronta deveria estar no nível 2 com maquininha")
		var id: StringName = a.opcao().id
		_check(game.bonus_mago(t, id) == 0, "caminho: nível 2 ainda sem bônus")
		var max0: int = a.pad.estoque_max
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
		_check(a.pad.estoque_max == max0 + cfg.mago_nivel_max - 2, "caminho: maquininha deveria ganhar estoque por nível")
		_check(game.bonus_mago(t, b.opcao().id) == 0 and game.bonus_mago(1 - t, id) == 0, "caminho: bônus só para a classe e o time do caminho")
		for u in game.units:
			if u.team == t and u.alive and u.stats.id != id:
				_check(_perto(u.damage_mult(), 1.0, 1e-4) or u._fury_t > 0.0 or u._dmg_boost_t > 0.0, "caminho: outra classe não ganha dano")
				break
		game.madeira[t] = 0
		return
	_check(false, "caminho: nenhum time sem caminho para testar")


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
