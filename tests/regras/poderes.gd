extends "res://tests/lib/caso.gd"
## Testes de regra: poderes. Rodam pelo tests/regras.gd, na ordem de lá.

## Q do 2.4: Campo Minado põe power_duration minas; Fúria deixa o Ronin
## gigante e quase sem empurrão.
func _poderes_q() -> void:
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
	# 2.32: armadilha que some (venceu ou foi trocada) sai da regra na hora; só o
	# visual fica afundando no chão, fora dela.
	var uma = null
	for t in get_tree().get_nodes_in_group("traps"):
		if t.dono == u:
			uma = t
	if uma:
		var vis: Node = uma._vis
		uma.sair()
		_check(not uma.is_in_group("traps") and uma.is_queued_for_deletion(), "Trap.sair: deveria sair do grupo traps e ser apagada")
		_check(is_instance_valid(vis) and vis.get_parent() != uma, "Trap.sair: o visual deveria se soltar para afundar")
	for t in get_tree().get_nodes_in_group("traps"):
		if t.dono == u:
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
	u.yaw = atan2(-dir.x, -dir.z)
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


## Lote 2.7 (2026-11-06): Chi pelo tempo, Q mais curto, 3º tiro forte,
## Construtor sem variação e item perto da briga.
func _chi_tempo_e_tiro_forte() -> void:
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


## Ciclo 2.29b: tambores separados, recarga rápida só de quem testa, troca de
## chapéu encerra o poder antigo e golpe de toque mede até a borda do corpo.
func _poderes_revisados() -> void:
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
	inim.global_position = p0 + dir * (cfg.herois.flecha_alcance + 0.5)
	_check(Herois.alvo_toque(u, cfg.herois.flecha_alcance, cfg.herois.flecha_cone) == inim, "2.29b: Flecha Arrancada acha o inimigo alinhado na borda do alcance")
	inim.global_position = p0 + dir.rotated(Vector3.UP, deg_to_rad(cfg.herois.flecha_cone * 0.5 - 5.0)) * cfg.herois.flecha_alcance
	_check(Herois.alvo_toque(u, cfg.herois.flecha_alcance, cfg.herois.flecha_cone) == inim, "2.29b: Flecha Arrancada acha o inimigo meio de lado")
	inim.global_position = p0 - dir * 2.0
	_check(Herois.alvo_toque(u, cfg.herois.flecha_alcance, cfg.herois.flecha_cone) == null, "2.29b: Flecha Arrancada não acerta quem está atrás")
	inim.global_position = q0
	u.global_position = p0
	u.set_class(cfg.villager)


## NU-14 (revisão 2026-11-19): o poder sai por texto em 4 lugares (enum do
## ClassStats, Unit._usar_rapida/_use_power, Herois.rapida/poder/super_proprio e
## a IA em BotHerois). Valor do enum sem ramo = poder que não sai; ramo fora do
## enum = código morto ou .tres que o Inspector estraga; herói sem ramo na IA =
## bot que nunca usa aquele poder.
func _registro_poderes() -> void:
	var enum_q := _enum_de("skill")
	var enum_e := _enum_de("power")
	var q_unit := _ramos("res://scripts/actors/unit.gd", "func _usar_rapida(")
	var q_her := _ramos("res://scripts/actors/herois.gd", "static func rapida(")
	var e_unit := _ramos("res://scripts/actors/unit.gd", "func _use_power(")
	var e_her := _ramos("res://scripts/actors/herois.gd", "static func poder(")
	var r_her := _ramos("res://scripts/actors/herois.gd", "static func super_proprio(")
	var q_bot := _ramos("res://scripts/ai/bot_herois.gd", "static func rapida(")
	var e_bot := _ramos("res://scripts/ai/bot_herois.gd", "static func poder(")
	var r_bot := _ramos("res://scripts/ai/bot_herois.gd", "static func super_r(")
	_check(enum_q.size() > 10 and enum_e.size() > 10 and q_unit.size() >= 6 and q_her.size() >= 10 and e_unit.size() >= 10 \
			and e_her.size() >= 10 and r_her.size() >= 8 and r_bot.size() >= 8,
			"registro dos poderes: não achou os ramos (função renomeada? atualize _registro_poderes)")
	for v in enum_q:
		if v != "nenhum" and v != "bloqueio":
			_check(q_unit.has(v) or q_her.has(v), "Q %s está no enum do ClassStats mas nenhum ramo o solta" % v)
	for v in q_unit + q_her:
		_check(enum_q.has(v), "Q %s tem ramo mas não está no @export_enum de skill" % v)
	_check(_mesmos(Unit.RAPIDAS_BASE, q_unit), "Unit.RAPIDAS_BASE diferente dos ramos de _usar_rapida")
	_check(_mesmos(Herois.RAPIDAS, q_her), "Herois.RAPIDAS diferente dos ramos de Herois.rapida")
	for v in enum_e:
		if v != "nenhum":
			_check(e_unit.has(v) or e_her.has(v), "E %s está no enum do ClassStats mas nenhum ramo o solta" % v)
	for v in e_unit + e_her:
		_check(enum_e.has(v), "E %s tem ramo mas não está no @export_enum de power" % v)
	for base in cfg.hat_class_list:
		for h in base.herois:
			_check(q_her.has(h.skill) and q_bot.has(h.skill), "herói %s: Q %s sem ramo em Herois.rapida ou na IA" % [h.id, h.skill])
			_check(e_her.has(h.power) and e_bot.has(h.power), "herói %s: E %s sem ramo em Herois.poder ou na IA" % [h.id, h.power])
			if h.super_tipo == "proprio":
				_check(r_her.has(h.super_poder) and r_bot.has(h.super_poder), "herói %s: R %s sem ramo em Herois.super_proprio ou na IA" % [h.id, h.super_poder])


## Valores do @export_enum de um campo do ClassStats.
func _enum_de(campo: String) -> Array[String]:
	var out: Array[String] = []
	for p in ClassStats.new().get_property_list():
		if p.name == campo:
			for v in String(p.hint_string).split(","):
				out.append(v.get_slice(":", 0))
	return out


## Valores dos ramos do primeiro nível do `match` da função (linhas `\t\t"a", "b":`).
func _ramos(arquivo: String, cabeca: String) -> Array[String]:
	var txt := FileAccess.get_file_as_string(arquivo)
	var i := txt.find("\n" + cabeca)
	if i < 0:
		return []
	var fim := txt.length()
	for marca in ["\nfunc ", "\nstatic func "]:
		var j := txt.find(marca, i + 2)
		if j >= 0:
			fim = mini(fim, j)
	var out: Array[String] = []
	var re := RegEx.create_from_string('(?m)^\\t\\t((?:"[a-z_0-9]+"(?:, )?)+):')
	var aspas := RegEx.create_from_string('"([a-z_0-9]+)"')
	for m in re.search_all(txt.substr(i, fim - i)):
		for a in aspas.search_all(m.get_string(1)):
			out.append(a.get_string(1))
	return out


func _mesmos(a: Array, b: Array) -> bool:
	for x in a:
		if not b.has(x):
			return false
	for x in b:
		if not a.has(x):
			return false
	return true
