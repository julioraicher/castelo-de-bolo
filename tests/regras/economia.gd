extends "res://tests/lib/caso.gd"
## Testes de regra: economia. Rodam pelo tests/regras.gd, na ordem de lá.

## Economia do Construtor: crescimento, rendimento, tora nos braços, entrega.
func _madeira() -> void:
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


## Torretas: dano do virote, escudo segura torreta_bloqueio, escudo na hora
## devolve o virote, e a torreta derrubada volta a terreno vazio.
func _torretas() -> void:
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
