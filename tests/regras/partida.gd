extends "res://tests/lib/caso.gd"
## Testes de regra: partida. Rodam pelo tests/regras.gd, na ordem de lá.

## Ciclo 2.25 (menos empate): teto das almas, carregar mais rápido, escolta
## que soma por aliado e devolução mais demorada.
## 2.27c: a máscara nasce com peso_inicial, então o primeiro roubo já é lento.
func _mascara_pesada() -> void:
	_check(cfg.peso_inicial >= 0.2 and cfg.peso_inicial < cfg.alma_teto, "peso_inicial fora de [0,2, alma_teto)")
	for m in game.princesses:
		_check(m.fatness >= cfg.peso_inicial - 1e-4, "máscara deveria nascer com peso %.2f, tem %.3f" % [cfg.peso_inicial, m.fatness])
		_check(m._spirits.get_child_count() >= int(round(cfg.peso_inicial / cfg.fat_per_cake)), "máscara deveria nascer com os espíritos do peso inicial à vista")


## Alma de abate: matar um inimigo deixa a máscara do time de quem matou mais
## pesada em fat_per_cake · alma_por_abate (a alma chega voando em ~0,9 s).
func _alma() -> void:
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


## Ciclo 2.10: atirar deixa lento, Samurai pelas costas, queda do shuriken,
## escolta da máscara.
func _equilibrio_classes() -> void:
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
	b.yaw = atan2(1.0, 0.0)  # b olha para +x
	_check(_perto(a.mult_costas(b, Vector3(-1, 0, 0)), 1.0, 1e-4), "Samurai de frente: sem bônus")
	_check(_perto(a.mult_costas(b, Vector3(1, 0, 0)), 1.0 + sam.dano_costas, 1e-4), "Samurai pelas costas: com bônus")
	_check(_perto(a.mult_costas(b, Vector3(0, 0, 1)), 1.0 + sam.dano_costas, 1e-4), "Samurai pelo lado: com bônus")
	var ronin = load("res://config/classes/ronin_oni.tres")
	var ninja = load("res://config/classes/arqueiro.tres")
	_check(ronin.move_speed < sam.move_speed and ninja.move_speed > sam.move_speed, "velocidades: Ninja > Samurai > Ronin")
	_check(ronin.max_hp > sam.max_hp and sam.max_hp > ninja.max_hp, "vidas: Ronin > Samurai > Ninja")


func _menos_empate() -> void:
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
	for id in ["sumotori", "kappa", "yamabushi", "karasu_tengu", "mujina", "onmyoji", "tennin", "komuso", "ochimusha", "shishimai", "jorogumo", "kodama", "kaminari_kozo", "predero"]:
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


## Placar (Tab, Ciclo 2.16): todo boneco tem linha, todo campo tem peso
## no game_config, a conta é Σ campo × peso e o abate dá abate/assistência/morte.
func _placar() -> void:
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
	# Bonecos novos num canto quieto (caça aos bugs 2026-11-15): com bots da
	# partida o alvo às vezes estava intocável/no voo e não morria (1 em 5).
	var t: int = game.time_jogador
	var base: Vector3 = game.arena.gate_spot[t] + game.arena.forward(t) * 10.0 + Vector3.UP.cross(game.arena.forward(t)).normalized() * 24.0
	var b = _boneco_placar(1 - t, base, 97)
	var a = _boneco_placar(t, base + Vector3(2, 0, 0), 98)
	var c = _boneco_placar(t, base + Vector3(-2, 0, 0), 99)
	await get_tree().physics_frame
	var la: Dictionary = pl.linha(a).duplicate()
	var lb: Dictionary = pl.linha(b).duplicate()
	var lc: Dictionary = pl.linha(c).duplicate()
	b.take_damage(5.0, c, Vector3.RIGHT)
	b.take_damage(b.hp + 10.0, a, Vector3.RIGHT)
	_check(not b.alive, "placar: o alvo do teste não morreu")
	_check(pl.linha(a).abates == la.abates + 1, "placar: quem matou não ganhou o abate")
	_check(pl.linha(c).assist == lc.assist + 1, "placar: quem ajudou não ganhou a assistência")
	_check(pl.linha(a).assist == la.assist, "placar: quem matou não ganha assistência junto")
	_check(pl.linha(b).mortes == lb.mortes + 1, "placar: quem caiu não ganhou a morte")
	_check(pl.linha(c).dano >= lc.dano + 5.0 - 0.01, "placar: dano de quem ajudou não contou")
	for u in [a, b, c]:
		pl._linhas.erase(u)
		pl._danos.erase(u)
		pl._corrente.erase(u)
		game.units.erase(u)
		if is_instance_valid(u):
			game.reanimar.esquecer(u)
			u.queue_free()


## Ciclo 2.23: relógio (15 min no 2.24, 20 no 2.31). No zero, mais pontos vence
## e igual empata; máscara fora que decide estende a partida (prorrogação).
func _relogio() -> void:
	_check(cfg.tempo_limite > 0.0 and game.relogio_ligado(), "relógio: deveria estar ligado na partida normal")
	game.tempo_partida = cfg.tempo_limite - 30.0
	_check(_perto(game.tempo_restante(), 30.0, 0.01), "relógio: tempo restante errado")
	# Ciclo 2.31: último minuto = as duas máscaras leves; espírito e alma não pesam.
	_check(cfg.tempo_limite == 1200.0, "relógio: a partida deveria ter 20 min (Julio, 2.31)")
	game.tempo_partida = cfg.tempo_limite - cfg.ultimo_minuto_leve - 1.0
	game._relogio(0.016)
	_check(not game.mascaras_leves, "último minuto: abriu cedo demais")
	for m in game.princesses:
		m.fatness = 0.5
	game.tempo_partida = cfg.tempo_limite - cfg.ultimo_minuto_leve + 1.0
	game._relogio(0.016)
	_check(game.mascaras_leves and game.princesses[0].fatness == 0.0 and game.princesses[1].fatness == 0.0,
		"último minuto: as máscaras deveriam perder todo o peso")
	game.princesses[1].pesar_alma(1.0)
	_check(game.princesses[1].fatness == 0.0, "último minuto: alma não deveria pesar")
	if game.princesses[1].state == Princess.State.HOME:
		_check(game.princesses[1].feed() and game.princesses[1].fatness == 0.0, "último minuto: espírito entra mas não pesa")
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
	# Ciclo 2.31: máscara fora que não muda o resultado (ladrão 2 atrás) não segura.
	if p.state == p.State.HOME:
		game.score[0] = 3
		p.state = p.State.DROPPED
		game._relogio(0.016)
		_check(game.game_over and game.vencedor == 0 and game.prorrogacao < 0.0,
			"relógio: máscara fora que não empata nem vira não deveria abrir prorrogação")
		p.state = p.State.HOME
		game.game_over = false
		game.vencedor = -9
		game.prorrogacao = -1.0
		game.score[0] = 1
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
