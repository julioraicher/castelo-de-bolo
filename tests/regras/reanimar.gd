extends "res://tests/lib/caso.gd"
## Testes de regra: reanimar. Rodam pelo tests/regras.gd, na ordem de lá.

func _reanimar() -> void:
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


## Reanimar (Ciclo 2.18): o caído levanta com a classe que tinha, metade da
## vida e intocável; o canal não para com dano; Kitsune mais rápida; time
## todo caído não reanima; quem puxa arrasta o corpo na corda.
## Ciclo 2.34: finalizar herói caído ([F] colado por finalizar_tempo s) nega o
## Reanimar e paga Chi/super/pontos; personalidade de toda classe é válida.
func _finalizar() -> void:
	var f = game.finalizar
	var r = game.reanimar
	_check(f != null, "finalizar: game.finalizar não existe")
	if f == null:
		return
	_check(cfg.finalizar_tempo > 0.0 and cfg.finalizar_tempo < cfg.reanimar_tempo, "finalizar: deveria ser mais rápido que reanimar")
	# Personalidade: todo personagem do jogo tem uma válida (recruta é neutro) e
	# as animações dela existem no esqueleto.
	var P = load("res://scripts/actors/personalidade.gd")
	var anims := {}
	var modelo = load("res://assets/characters/Knight.glb").instantiate()
	var ap = modelo.find_child("AnimationPlayer", true, false)
	for nome in ap.get_animation_list():
		anims[nome] = true
	modelo.free()
	for arq in DirAccess.get_files_at("res://config/classes"):
		if not arq.ends_with(".tres"):
			continue
		var cls = load("res://config/classes/" + arq)
		if cls.id == &"recruta":
			continue
		_check(P.DADOS.has(cls.personalidade), "personalidade: %s sem personalidade válida (%s)" % [cls.id, cls.personalidade])
	for k in P.DADOS:
		var d: Dictionary = P.DADOS[k]
		for campo in ["canal", "golpe"]:
			_check(anims.has(d[campo]), "personalidade %s: animação %s não existe" % [k, d[campo]])
		_check(String(d.get("verbo", "")) != "", "personalidade %s: sem verbo" % k)
	var a = null
	var h = null
	var aliado = null
	for u in game.units:
		if not u.alive or u.is_player or u.carried_princess or u.carried_tora or u == r.boneco_treino:
			continue
		if a == null:
			a = u
		elif u.team != a.team and h == null:
			h = u
		elif h != null and u.team == h.team and aliado == null:
			aliado = u
	if a == null or h == null or aliado == null:
		_check(false, "finalizar: faltou boneco")
		return
	a.set_class(load("res://config/classes/guerreiro.tres"))
	aliado.set_class(load("res://config/classes/arqueiro.tres"))
	# Classe comum caída: não dá para finalizar.
	h.set_class(load("res://config/classes/arqueiro.tres"))
	for u in [a, h, aliado]:
		u._dodge_t = 0.0
		u._equip_t = 0.0
		u._blocking = false
		u._shield = 0.0
		u._intocavel_t = 0.0
		u.hp = u.max_hp()
	h.take_damage(h.hp + 50.0, a, Vector3.RIGHT)
	_check(not h.alive and not f.pode_finalizar(h), "finalizar: classe comum não deveria ser finalizável")
	h._respawn()
	# Herói caído: finalizável e ainda reanimável (a corrida).
	h.set_class(load("res://config/classes/sumotori.tres"))
	h._nao_cai_usado = true
	h.hp = h.max_hp()
	h._intocavel_t = 0.0
	h.take_damage(h.hp + 50.0, a, Vector3.RIGHT)
	_check(not h.alive, "finalizar: o herói do teste não caiu")
	_check(f.pode_finalizar(h) and r.pode_reanimar(h), "finalizar: herói recém-caído deveria ser finalizável e reanimável")
	# Longe não começa.
	a.global_position = h.global_position + Vector3(cfg.finalizar_raio + 1.5, 0, 0)
	a.wants_reanimar = true
	f.tick(0.05)
	_check(a.finalizando == null, "finalizar: longe do corpo não deveria começar")
	# Colado começa; o aliado dele começa a reanimar ao mesmo tempo.
	a.global_position = h.global_position + Vector3(1.0, 0, 0)
	aliado.global_position = h.global_position + Vector3(-1.0, 0, 0)
	aliado.wants_reanimar = true
	f.tick(0.05)
	r.tick(0.05)
	_check(a.finalizando == h and h.finalizador == a, "finalizar: segurar F colado deveria começar")
	_check(a.reanimando == null, "finalizar: quem finaliza não deveria reanimar junto")
	_check(aliado.reanimando == h, "finalizar: o aliado deveria conseguir disputar reanimando")
	# Soltar o F para.
	a.wants_reanimar = false
	f.tick(0.05)
	_check(a.finalizando == null and h.finalizador == null and a.finalizar_prog == 0.0, "finalizar: soltar F deveria parar")
	var chi0: float = a.power
	var sup0: float = a.super_carga
	var pts0: float = game.placar.linha(a).get("finalizar", 0.0)
	a.power = 0.0
	chi0 = 0.0
	a.super_carga = 0.0
	sup0 = 0.0
	for i in int(ceil(cfg.finalizar_tempo / 0.05)) + 3:
		if h.finalizado:
			break
		a.wants_reanimar = true
		aliado.wants_reanimar = true
		f.tick(0.05)
		r.tick(0.05)
	Engine.time_scale = 1.0
	a._hitstop_t = 0.0  # o golpe da finalização congela e trava a animação: não vazar para os próximos testes
	a._anim_lock = 0.0
	_check(h.finalizado and not h.alive, "finalizar: deveria finalizar em finalizar_tempo s")
	_check(not r.pode_reanimar(h) and aliado.reanimando == null, "finalizar: finalizado não pode mais ser reanimado")
	_check(not f.pode_finalizar(h), "finalizar: não finaliza duas vezes")
	_check(r.ritmo(h) == 1.0, "finalizar: finalizado deveria esperar no ritmo normal")
	_check(a.finalizando == null, "finalizar: o canal deveria acabar")
	_check(a.power >= chi0 + cfg.finalizar_chi - 0.01, "finalizar: deveria dar Chi")
	_check(a.super_carga > sup0, "finalizar: deveria dar super")
	_check(game.placar.linha(a).get("finalizar", 0.0) == pts0 + 1.0, "finalizar: placar não contou")
	for i in 40:
		aliado.wants_reanimar = true
		r.tick(0.1)
	_check(not h.alive, "finalizar: aliado não deveria levantar o finalizado")
	a.wants_reanimar = false
	aliado.wants_reanimar = false
	h._respawn()
	_check(h.alive and not h.finalizado and h.finalizador == null, "finalizar: renascer deveria limpar o estado")
