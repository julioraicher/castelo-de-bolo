extends "res://tests/lib/caso.gd"
## Testes de regra: herois. Rodam pelo tests/regras.gd, na ordem de lá.

## Ciclo 2.23: escada do Nv6 (herói raro). Usa a casa da Kitsune que o
## _caminho_magos deixou no nível máximo.
func _heroi_nv6() -> void:
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
		_check(cons.pede_heroi() and cons.herois().size() == 1 and cons.herois()[0].id == &"predero", "Nv6: bairro do Construtor pede o Predero (o único herói dele)")
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
	var a = null
	var b = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo and not u.carried_tora and u.reanimando == null:
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
	var dx := Vector3(1, 0, 0)
	b.set_class(load("res://config/classes/guerreiro.tres"))

	# Sumotori: Agarrão arremessa, solta a máscara e fere no pouso.
	a.set_class(load("res://config/classes/sumotori.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 1.8, -dx)
	var tinha = b.carried_princess
	b.carried_princess = null
	a._quick_cd = 0.0
	_check(a._usar_rapida() and b.em_voo, "Sumotori: Agarrão deveria levantar o alvo")
	var hp0: float = b.hp
	await get_tree().create_timer(cfg.agarrao_segura + 0.75).timeout
	_check(not b.em_voo and b.hp < hp0 and b.global_position.distance_to(centro) > 4.0,
		"Sumotori: alvo deveria pousar longe ferido (dist %.1f, dano %.1f)" % [b.global_position.distance_to(centro), hp0 - b.hp])
	# Dohyō: quem estava dentro não sai; de fora não entra.
	_por(a, centro, dx)
	_por(b, centro + dx * 2.0, -dx)
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
	_por(a, centro, dx)
	a.take_damage(20.0, b, -dx)  # vindo da frente (b na frente batendo para trás)
	var frente: float = a.max_hp() - a.hp
	a.hp = a.max_hp()
	a.take_damage(20.0, b, dx)  # vindo das costas
	var costas: float = a.max_hp() - a.hp
	_check(frente > 0.0 and costas < frente * 0.5,
		"Kappa: casco deveria reduzir só por trás (frente %.1f, costas %.1f)" % [frente, costas])

	# Yamabushi: Rajada troca dono e direção do projétil.
	a.set_class(load("res://config/classes/yamabushi.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 6.0, -dx)
	var p = game.spawn_projectile(b, centro + dx * 3.0 + Vector3(0, 1.2, 0), -dx, "shuriken")
	_check(Herois._rajada(a) and p.owner_unit == a and p.velocity.dot(dx) > 0.0, "Yamabushi: Rajada deveria devolver o tiro (dono e direção)")
	p.queue_free()

	# Karasu: intocável no ar e fere no raio do pouso.
	a.set_class(load("res://config/classes/karasu_tengu.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 6.0, -dx)
	a.aim_point = b.global_position
	_check(a._usar_rapida() and a.em_voo, "Karasu: Mergulho deveria subir")
	hp0 = a.hp
	a.take_damage(30.0, b, dx)
	_check(a.hp == hp0, "Karasu: no ar o Mergulho é intocável")
	var hb0: float = b.hp
	await get_tree().create_timer(1.0).timeout
	_check(not a.em_voo and b.hp < hb0, "Karasu: o pouso fere quem está no raio (dano %.1f)" % (hb0 - b.hp))
	# Cego desvia a mira do bot.
	_por(a, centro, dx)
	b._cego_t = 1.0
	b.aim_dir = dx
	b._attack_cd = 0.0
	b._attack()
	_check(b.aim_dir.angle_to(dx) > 0.001, "Karasu: cego deveria desviar a mira do bot")
	b._cego_t = 0.0

	# Mujina: disfarce tira dos alvos e quebra no golpe.
	a.set_class(load("res://config/classes/mujina.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 2.0, -dx)
	_check(a._usar_rapida() and a._disfarce_t > 0.0 and a.na_sombra_para(b), "Mujina: rosto roubado tira a Mujina dos alvos inimigos")
	_check(a._disfarce_time == b.team, "Mujina: o rosto é do time do inimigo")
	a._attack_cd = 0.0
	a._attack()
	_check(a._disfarce_t <= 0.0 and not a.na_sombra_para(b), "Mujina: o golpe quebra o disfarce")

	# Andar forçado: Susto afasta, Hipnose aproxima.
	_por(a, centro, dx)
	_por(b, centro + dx * 3.0, -dx)
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
	_por(a, centro, dx)
	_por(b, centro + dx * 8.0, -dx)
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
	_por(a, centro, dx)
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
	_por(a, centro, dx)
	_por(b, centro + dx * 4.0, -dx)
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
	for id in ["sumotori", "kappa", "yamabushi", "karasu_tengu", "mujina", "onmyoji", "tennin", "komuso", "ochimusha", "shishimai", "jorogumo", "kodama", "kaminari_kozo", "predero"]:
		var cls = load("res://config/classes/%s.tres" % id)
		a.set_class(cls)
		_por(a, centro, dx)
		_por(b, centro + dx * 3.0, -dx)
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
func _herois_elementos() -> void:
	var a = null
	var b = null
	var c = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo and not u.carried_tora and u.reanimando == null:
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
	var dx := Vector3(1, 0, 0)
	var dz := Vector3(0, 0, 1)
	b.set_class(load("res://config/classes/guerreiro.tres"))
	c.set_class(load("res://config/classes/guerreiro.tres"))
	_por(c, centro + dz * 12.0, dx)

	# Ochimusha: o golpe mortal deixa 1 de vida e vira fantasma intocável.
	a.set_class(load("res://config/classes/ochimusha.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 2.0, -dx)
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
	_por(a, centro, dx)
	a.take_damage(9999.0, b, dx)
	Herois._tick_2_27(a, cfg.fantasma_tempo + 0.1)
	_check(not a.alive, "Ochimusha: sem abate, cai no fim do fantasma")
	a._voltar_a_vida()
	a.set_class(load("res://config/classes/ochimusha.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 2.0, -dx)
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
	_por(b, centro + dx * 1.2, -dx)
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
	_por(a, centro, dx)
	_por(b, centro + dx * 1.5, -dx)
	hp0 = b.hp
	_check(Herois._mordida(a) and b.hp < hp0 and b._azar_t > 0.0, "Shishimai: Mordida fere o inimigo e dá Azar")
	var ha: float = a.hp
	a.take_damage(20.0, b, dx)
	_check(_perto(a.hp, ha, 0.01) and b._azar_t <= 0.0, "Shishimai: com Azar o golpe erra (e o Azar acaba)")
	# Mordida no aliado: cura e Sorte (desvia o próximo e dobra o próximo dado).
	_por(b, centro + dx * 9.0, -dx)
	_por(c, centro + dx * 1.5, -dx)
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
	_por(c, centro + dz * 12.0, dx)
	# Arrastão: leva o primeiro inimigo da frente e prende no fim.
	_por(a, centro, dx)
	_por(b, centro + dx * 2.0, -dx)
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
	_por(a, centro, dx)
	_por(b, centro + dx * 5.0, -dx)
	b.take_damage(4.0, a, dx, 1.0, false, "fio", 1)
	b.take_damage(4.0, a, dx, 1.0, false, "fio", 1)
	_check(b._fio_n == 2 and b._fio_dono == a and b._slow_t > 0.0 and b._preso_t <= 0.0, "Jorogumo: o fio gruda e acumula (%d)" % b._fio_n)
	b.take_damage(4.0, a, dx, 1.0, false, "fio", 2)
	_check(b._preso_t > 0.0, "Jorogumo: o 3º tiro (Rede) prende")
	# Puxar os Fios: quem tem o fio dela vem para perto e fica preso.
	_por(b, centro + dx * 7.0, -dx)
	b._fio_dono = a
	b._fio_t = 2.0
	Herois._puxar_fios(a)
	_check(b._knock.dot(-dx) > 1.0 and b._preso_t > 0.0, "Jorogumo: Puxar os Fios puxa e prende quem tem o fio dela")
	b._fio_t = 0.0
	b._fio_dono = null
	# Teia: prende quem pisa; fogo queima e vento rasga.
	_por(b, centro + dx * 12.0, -dx)
	a.aim_point = centro + dx * 5.0
	var antes_t := get_tree().get_nodes_in_group("teias").size()
	_check(Herois._teia(a) and get_tree().get_nodes_in_group("teias").size() == antes_t + 1, "Jorogumo: Q tece uma teia")
	var teia = null
	for n in get_tree().get_nodes_in_group("teias"):
		if n.dona == a:
			teia = n
	if teia:
		_por(b, Vector3(teia.global_position.x, centro.y, teia.global_position.z), -dx)
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
	_por(b, centro + dx * 3.0, -dx)
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
func _herois_natureza() -> void:
	var a = null
	var b = null
	var c = null
	var e = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo and not u.carried_tora and u.reanimando == null:
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
	_por(c, centro - dz * 14.0, dx)
	_por(e, centro + dz * 16.0, dx)

	# --- Kodama ---
	a.set_class(load("res://config/classes/kodama.tres"))
	_por(a, centro, dx)
	_por(b, centro + dx * 4.0, -dx)
	var hp0: float = b.hp
	_check(HeroisNatureza.raizes(a) and b.hp < hp0 and b._preso_t > 0.0, "Kodama: Raízes ferem e prendem quem está na linha")
	_por(b, centro + dx * 4.0, -dx)
	b.take_damage(5.0, a, dx, 1.0, false, "semente", 1)
	_check(b._preso_t <= 0.0, "Kodama: semente comum não prende")
	b.take_damage(5.0, a, dx, 1.0, false, "semente", 2)
	_check(b._preso_t > 0.0, "Kodama: o 3º tiro (semente forte) brota e prende")
	# Bosque: três árvores que bloqueiam tiro e passagem e curam na sombra.
	_por(b, centro + dx * 14.0, -dx)
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
		_por(c, arv.global_position + dz * 1.4, dx)
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
		_por(c, centro - dz * 14.0, dx)
	if arvores.size() > 1:
		var arv2 = arvores[1]
		var toras0: int = game.toras.size()
		var cortes := 0
		for i in cfg.arvore_golpes:
			var dir: Vector3 = (arv2.global_position - b.global_position)
			dir.y = 0
			_por(b, arv2.global_position - dx * 1.2, dx)
			if HeroisNatureza.cortar_arvore(b, dx, 2.0, 120.0):
				cortes += 1
		_check(cortes == cfg.arvore_golpes and arv2.indo and game.toras.size() == toras0 + 1, "Kodama: o lenhador derruba em %d golpes e ganha 1 tora" % cfg.arvore_golpes)
	limpar.call()
	await get_tree().process_frame
	# Floresta Antiga: anel de gigantes; dentro, inimigo preso e aliado curado.
	_por(a, centro, dx)
	_por(b, centro + dx * 4.0, -dx)
	_por(c, centro - dx * 4.0, dx)
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
	_por(a, centro, dx)
	_por(b, centro + dx * 2.0, -dx)
	_por(e, centro + dx * 2.0 + dz * 3.0, -dx)
	a.carga = 0.0
	HeroisNatureza.somar_carga(a, 1.0)
	_check(a.carga >= 1.0 and a.has_meta("carga_no"), "Kaminari-kozō: carga cheia acende o cabelo")
	hp0 = b.hp
	var he: float = e.hp
	b.take_damage(10.0, a, dx)
	_check(hp0 - b.hp >= 10.0 + cfg.descarga_dano * 0.9 and a.carga <= 0.0 and not a.has_meta("carga_no"), "Kaminari-kozō: o golpe com carga cheia descarrega (%.0f de dano)" % (hp0 - b.hp))
	_check(e.hp < he, "Kaminari-kozō: a descarga pula para o inimigo perto")
	# Molhado conduz: mais dano de raio e a descarga pula mais longe.
	_por(b, centro + dx * 2.0, -dx)
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
	_por(e, centro + dx * 2.0 + dz * (cfg.descarga_raio + 2.0), -dx)
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
	_por(b, centro + dx * 4.5, -dx)
	_por(e, centro + dz * 16.0, dx)
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
	_por(a, centro, dx)
	_por(b, centro + dx * 4.0 + dz * 0.4, -dx)
	hp0 = b.hp
	HeroisNatureza.relampago(a)
	var salto: float = (a.global_position - centro).dot(dx)
	_check(salto > cfg.relampago_dist * 0.8 and b.hp < hp0 and a.carga >= cfg.carga_relampago - 0.01, "Kaminari-kozō: Relâmpago salta %.1f m, fere no caminho e carrega" % salto)
	a.carga = 0.0
	HeroisNatureza.zerar(a)
	# Tambores: raio do céu no inimigo mais perto.
	_por(a, centro, dx)
	_por(b, centro + dx * 5.0, -dx)
	hp0 = b.hp
	HeroisNatureza.tambores(a)
	HeroisNatureza._tick_tambores(a, 0.2)
	_check(b.hp < hp0 and b._preso_t > 0.0, "Kaminari-kozō: Tambores derrubam um raio no inimigo")
	a._tambores_t = 0.0
	# Árvore do Kodama é para-raios: o raio cai nela (e ela pega fogo), não no alvo.
	var arv3 = HeroisNatureza.plantar(b, centro + dx * 5.0 + dz * 2.0, 6.0, false)
	_por(b, centro + dx * 5.0, -dx)
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


## Herói 2.30: Predero (garrafa encachaça, poça derrapa e pega fogo, andaime
## bloqueia tiro e cai na machadada, Saideira chove garrafas e acende as poças).
func _predero() -> void:
	var a = null
	var b = null
	var c = null
	for u in game.units:
		if u.alive and not u.is_player and not u.carried_princess and not u.em_voo and not u.carried_tora and u.reanimando == null:
			if a == null:
				a = u
			elif b == null and u.team != a.team:
				b = u
			elif c == null and b != null and u.team == b.team:
				c = u
	if a == null or b == null or c == null:
		_check(false, "Predero: faltou boneco")
		return
	var lista := [a, b, c]
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
	var limpar := func() -> void:
		for grupo in ["pocas_cachaca", "andaimes"]:
			for n in get_tree().get_nodes_in_group(grupo):
				n.remove_from_group(grupo)
				n.queue_free()
	limpar.call()
	var dx := Vector3(1, 0, 0)
	var dz := Vector3(0, 0, 1)
	for u in [b, c]:
		u.set_class(load("res://config/classes/guerreiro.tres"))
	a.set_class(load("res://config/classes/predero.tres"))
	_check(a.stats.projetil == "garrafa" and a.stats.attack_kind == "ranged", "Predero: ataque é garrafa à distância")
	_por(a, centro, dx)
	_por(b, centro + dx * 4.0, -dx)
	_por(c, centro + dz * 16.0, dx)

	# Garrafada: quem leva fica encachaçado e o fogo arde mais nele.
	var hp0: float = b.hp
	b.take_damage(8.0, a, dx, 0.0, false, "garrafa", 1)
	_check(b.hp < hp0 and b._encachacado_t > 0.0, "Predero: a garrafa fere e encachaça")
	b._encachacado_t = 0.0
	b.hp = b.max_hp()
	hp0 = b.hp
	b.take_damage(10.0, c, dx, 0.0, false, "brasa", 1)
	var seco: float = hp0 - b.hp
	b.hp = b.max_hp()
	b._encachacado_t = cfg.encachacado_tempo
	hp0 = b.hp
	b.take_damage(10.0, c, dx, 0.0, false, "brasa", 1)
	var bebado: float = hp0 - b.hp
	_check(_perto(bebado, seco * cfg.encachacado_fogo, 0.05), "Predero: encachaçado leva %.0f%% do fogo (%.1f → %.1f)" % [cfg.encachacado_fogo * 100, seco, bebado])
	b._encachacado_t = 0.0
	# Projétil de verdade: a garrafa estoura no chão e fere em volta.
	_por(b, centro + dx * 6.0, -dx)
	hp0 = b.hp
	var pj := Projectile.new()
	pj.setup(game, a, b.global_position + Vector3(0, 0.3, 0), dx, "garrafa")
	game.add_child(pj)
	pj.global_position = b.global_position + Vector3(0, 0.4, 0)
	pj._explode(b.global_position)
	_check(b.hp < hp0 and b._encachacado_t > 0.0, "Predero: a garrafa estoura em estilhaço (área) e encachaça")
	if is_instance_valid(pj):
		pj.queue_free()

	# Poça (Q): nasce na mira, faz derrapar quem pisa, no máximo poca_max.
	_por(a, centro, dx)
	_por(b, centro + dx * 6.0, -dx)
	a.aim_point = centro + dx * 6.0
	_check(HeroisObra.poca(a), "Predero: Q joga o garrafão")
	var pocas := []
	for n in get_tree().get_nodes_in_group("pocas_cachaca"):
		if n.dono == a:
			pocas.append(n)
	_check(pocas.size() == 1, "Predero: Q faz uma poça (fez %d)" % pocas.size())
	if pocas.size() == 1:
		var poca = pocas[0]
		poca._physics_process(0.6)  # o garrafão chega no chão
		_check(poca.ativa() and poca.cobre(b.global_position), "Predero: a poça cai na mira")
		HeroisObra.pisou(b, a)
		_check(b._derrapa_t > 0.0 and b._encachacado_t > 0.0, "Predero: pisar na poça derrapa e encachaça")
		# Derrapar: a mesma vontade de andar acelera poca_atrito × menos (a = μ·g).
		b.move_intent = -dx
		b._move_vel = Vector3.ZERO
		await get_tree().physics_frame
		var v_poca: float = b._move_vel.length()
		b._derrapa_t = 0.0
		b._move_vel = Vector3.ZERO
		_por(b, centro + dx * 20.0, -dx)
		b.move_intent = -dx
		await get_tree().physics_frame
		var v_seco: float = b._move_vel.length()
		b.move_intent = Vector3.ZERO
		_check(v_seco > 0.0 and v_poca < v_seco * 0.5, "Predero: na poça acelera menos (%.2f vs %.2f m/s num quadro)" % [v_poca, v_seco])
		# Fogo de qualquer time acende; acesa queima o inimigo e evapora.
		_por(b, centro + dx * 6.0, -dx)
		Reacoes.em(game, poca.global_position, 1.0, "fogo", b.team)
		_check(poca.acesa(), "Predero: fogo (até do inimigo) acende a poça")
		hp0 = b.hp
		poca._physics_process(0.1)
		_check(b.hp < hp0, "Predero: a poça acesa queima o inimigo em cima")
		poca._physics_process(cfg.poca_fogo_tempo + 0.1)
		_check(poca.indo, "Predero: a poça acesa evapora no fim")
	for i in cfg.poca_max + 1:
		a.aim_point = centro + dz * (4.0 + i * 1.5)
		HeroisObra.poca(a)
	var vivas := 0
	for n in get_tree().get_nodes_in_group("pocas_cachaca"):
		if n.dono == a and not n.indo:
			vivas += 1
	_check(vivas == cfg.poca_max, "Predero: no máximo %d poças (tem %d)" % [cfg.poca_max, vivas])
	limpar.call()
	await get_tree().process_frame

	# Andaime (E): parede que bloqueia tiro; o lenhador inimigo desmonta.
	_por(a, centro, dx)
	_por(b, centro + dx * 12.0, -dx)
	HeroisObra.andaime(a)
	var andaime = null
	for n in get_tree().get_nodes_in_group("andaimes"):
		if n.dono == a:
			andaime = n
	_check(andaime != null, "Predero: E levanta o andaime")
	if andaime:
		await get_tree().physics_frame
		await get_tree().physics_frame
		var p0: Vector3 = andaime.global_position + Vector3(0, 1.2, 0)
		var q := PhysicsRayQueryParameters3D.create(p0 - dx * 2.0, p0 + dx * 2.0, 1)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(q)
		_check(not hit.is_empty(), "Predero: o andaime bloqueia tiro (raio no mundo bate)")
		var cortes := 0
		for i in cfg.andaime_golpes:
			_por(b, andaime.global_position + dx * 1.2, -dx)
			if HeroisObra.cortar_andaime(b, -dx, 2.0, 120.0):
				cortes += 1
		_check(cortes == cfg.andaime_golpes and andaime.indo, "Predero: o lenhador desmonta o andaime em %d golpes" % cfg.andaime_golpes)
	# Quem estava no lugar é empurrado para fora.
	limpar.call()
	await get_tree().process_frame
	_por(a, centro, dx)
	_por(b, centro + dx * cfg.andaime_dist, -dx)
	HeroisObra.andaime(a)
	var frente: float = (b.global_position - centro).dot(dx)
	_check(absf(frente - cfg.andaime_dist) > 0.3, "Predero: o andaime empurra quem estava no lugar")
	limpar.call()
	await get_tree().process_frame

	# Saideira (R): chuva de garrafas; a última vem acesa e põe fogo nas poças dele.
	_por(a, centro, dx)
	_por(b, centro + dx * 6.0, -dx)
	a.aim_point = centro + dx * 6.0
	HeroisObra.poca(a)
	for n in get_tree().get_nodes_in_group("pocas_cachaca"):
		n._physics_process(0.6)
	hp0 = b.hp
	_check(HeroisObra.saideira(a), "Predero: Saideira sai")
	HeroisObra.tick(a, FxObra.SAIDEIRA_VOO + cfg.saideira_cada * cfg.saideira_n + 0.1)
	_check(a._saideira_n == cfg.saideira_n and b.hp < hp0, "Predero: Saideira derruba %d garrafas e fere (caíram %d)" % [cfg.saideira_n, a._saideira_n])
	var acesas := 0
	var pequenas := 0
	for n in get_tree().get_nodes_in_group("pocas_cachaca"):
		if n.dono == a and n.acesa():
			acesas += 1
		if n.dono == a and n.pequena:
			pequenas += 1
	_check(acesas >= 1, "Predero: a garrafa acesa põe fogo nas poças dele (%d acesas)" % acesas)
	_check(pequenas >= 1, "Predero: as garrafas da Saideira deixam pocinhas")
	limpar.call()
	await get_tree().process_frame

	for i in lista.size():
		var u = lista[i]
		u.brain = cerebros[i]
		u.set_class(classes[i])
		HeroisObra.zerar(u)
	for u in guardados:
		if is_instance_valid(u):
			u.global_position = guardados[u]
			u.reset_physics_interpolation()


## TS-06 (revisão 2026-11-19): a IA dos heróis (BotHerois) não tinha teste; só a
## fumaça pegava erro de script. Cena fixa: herói bot, 3 inimigos juntos na frente
## (3 a 6 m) e um aliado ferido (30%) do lado, a 5 m (os de apoio cuidam dele). Todo herói tem de usar ALGUM poder (Q, E ou R)
## nessa cena, e quem vira a mira tem de virar para o grupo. A Sorte é guardada e
## devolvida (o resto dos testes não muda).
func _bots_herois() -> void:
	var centro := Vector3(0, 0, 18)
	centro.y = game.arena.ground_y(centro.x, centro.z)
	var guardados := {}
	for u in game.units:
		if u.global_position.distance_to(centro) < 30.0:
			guardados[u] = u.global_position
			u.global_position = game.arena.spawn_center[u.team]
	var estado := Sorte.rng.state
	var lado := Vector3(1, 0, 0)  # a mira começa de lado: dá para ver se o bot a virou
	var inimigos: Array = []
	for p in [Vector3(0, 0, -3), Vector3(0.8, 0, -4.5), Vector3(-0.8, 0, -6)]:
		inimigos.append(Bonecos.criar(game, 1, centro + p, "BotHeroiAlvo"))
	var aliado = Bonecos.criar(game, 0, centro + Vector3(-5, 0, 0.5), "BotHeroiAliado")
	var criados: Array = inimigos + [aliado]
	var nomes := ["Q", "E", "R"]
	for base in cfg.hat_class_list:
		for c in base.herois:
			var h = Bonecos.criar(game, 0, centro, "BotHeroi", false, c.resource_path)
			criados.append(h)
			var bot := BotBrain.new()
			bot.unit = h
			bot.game = game
			bot.parado = true
			h.add_child(bot)
			h.brain = bot
			var usos := [0, 0, 0]
			var tortos: Array[String] = []
			for qual in 3:
				for i in 20:
					for e in inimigos:
						_por(e, e.global_position, -lado)
					_por(h, centro, lado)
					aliado.hp = aliado.max_hp() * 0.3
					h.aim_point = centro + lado * 50.0
					bot._target = inimigos[0]
					if not _decide(qual, bot):
						continue
					usos[qual] += 1
					var dir: Vector3 = h.aim_dir
					dir.y = 0
					if dir.length() > 0.1 and rad_to_deg(dir.angle_to(lado)) > 5.0 \
							and rad_to_deg(dir.angle_to(inimigos[1].global_position - centro)) > 40.0:
						tortos.append("%s mira %.0f graus fora" % [nomes[qual], rad_to_deg(dir.angle_to(inimigos[1].global_position - centro))])
					if h.aim_point.distance_to(centro + lado * 50.0) > 0.1:
						var perto := INF
						for e in inimigos:
							perto = minf(perto, h.aim_point.distance_to(e.global_position))
						if perto > 2.5:
							tortos.append("%s ponto %.1f m longe do grupo" % [nomes[qual], perto])
			_check(usos[0] + usos[1] + usos[2] > 0, "bot herói %s não usa Q, E nem R com 3 inimigos juntos na frente" % c.id)
			_check(tortos.is_empty(), "bot herói %s solta o poder mirando fora do grupo: %s" % [c.id, tortos[0] if tortos else ""])
	Bonecos.limpar(game, criados)
	for u in guardados:
		if is_instance_valid(u):
			u.global_position = guardados[u]
			u.reset_physics_interpolation()
	Sorte.rng.state = estado


func _decide(qual: int, bot) -> bool:
	match qual:
		0:
			return BotHerois.rapida(bot)
		1:
			return BotHerois.poder(bot)
	return BotHerois.super_r(bot)
