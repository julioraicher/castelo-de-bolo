class_name BotHerois
extends RefCounted
## Bom senso dos bots com os heróis raros (Ciclo 2.23): quando soltar o Q, o E
## e o R de cada herói. Chamado pelos ramos padrão de BotBrain._should_use_*.
## Pode mexer em aim_dir/aim_point da Unit (mira do poder).


static func rapida(b: BotBrain) -> bool:
	var u := b.unit
	var me := u.global_position
	var alvo := b._target
	var alvo_ok := alvo != null and alvo.alive and not u.carried_princess
	var d := me.distance_to(alvo.global_position) if alvo_ok else INF
	match u.stats.skill:
		"agarrao":
			if not alvo_ok or d > u.stats.skill_radius:
				return false
			_mirar(u, alvo.global_position)
			# Arremessa para longe da própria máscara (ou na direção de casa se carrega).
			var casa := b.game.arena.princess_spot[u.team]
			var para_fora := (alvo.global_position - casa)
			para_fora.y = 0
			u.aim_dir = (u.aim_dir * 0.5 + para_fora.normalized() * 0.5).normalized()
			# o cone do Agarrão precisa do alvo na frente: mira volta para ele
			if rad_to_deg(u.aim_dir.angle_to((alvo.global_position - me).normalized())) > 30.0:
				_mirar(u, alvo.global_position)
			return Sorte.f() < 0.7
		"rasteira":
			if alvo_ok and d > 3.0 and d < u.stats.skill_radius + 1.5:
				_mirar(u, alvo.global_position)
				return alvo.stats.attack_kind != "melee" or Sorte.f() < 0.4
			return false
		"rajada":
			if _projetil_vindo(b) or (alvo_ok and d < 4.0):
				if alvo_ok:
					_mirar(u, alvo.global_position)
				return true
			return false
		"mergulho":
			var presa := _presa_isolada(b, 5.0, u.stats.skill_radius)
			if presa:
				u.aim_point = presa.global_position
				_mirar(u, presa.global_position)
				return true
			return false
		"roubar_rosto":
			# Antes de entrar no pátio inimigo ou ir na máscara: rosto de quem está perto.
			if alvo_ok and d < u.stats.skill_radius:
				var casa_inimiga := b.game.arena.princess_spot[1 - u.team]
				return me.distance_to(casa_inimiga) < 45.0 or Sorte.f() < 0.3
			return false
		"dobrar":
			if u.shikigami < Config.cfg.shikigami_max:
				return b._nearest_enemy(7.0) == null or u.shikigami == 0
			return alvo_ok and (alvo.hp_ratio() < 0.5 or Sorte.f() < 0.3)
		"laco":
			if b.game.reanimar:
				for c in b.game.units:
					if c.team == u.team and not c.alive and b.game.reanimar.pode_reanimar(c) \
							and c.global_position.distance_to(me) < u.stats.skill_radius:
						return true
			for o in b.game.units:
				if o != u and o.alive and o.team == u.team and o.hp_ratio() < 0.35 \
						and o.global_position.distance_to(me) > 4.0 and o.global_position.distance_to(me) < u.stats.skill_radius:
					return true
			return false
		"sono":
			if alvo_ok and d < u.stats.skill_radius * 0.8 and b._count(1 - u.team, alvo.global_position, 3.0) >= 2:
				_mirar(u, alvo.global_position)
				return b._nearest_enemy(2.5) == null  # parado tocando: não com alguém colado
			return false
		"flecha_arrancada":  # Ochimusha: cada carga é uma flecha; só gasta com alguém no cone
			if alvo_ok and d <= Config.cfg.flecha_alcance + 0.3:
				_mirar(u, alvo.global_position)
				return true
			return false
		"mordida":  # Shishimai: aliado ferido ganha Sorte; senão morde o inimigo da frente
			for o in b.game.units:
				if o != u and o.alive and o.team == u.team and o.hp_ratio() < 0.55 \
						and o.global_position.distance_to(me) < Config.cfg.mordida_alcance:
					_mirar(u, o.global_position)
					return true
			if alvo_ok and d < Config.cfg.mordida_alcance:
				_mirar(u, alvo.global_position)
				return Sorte.f() < 0.7
			return false
		"teia":  # Jorogumo: teia na frente de quem vem (ou de quem leva a máscara)
			if alvo_ok and d < u.stats.skill_radius and d > 2.0:
				var adiante := alvo.global_position + Vector3(alvo.velocity.x, 0, alvo.velocity.z) * 0.6
				_mirar(u, adiante)
				return alvo.carried_princess != null or Sorte.f() < 0.55
			return false
		"raizes":  # Kodama: a linha de raízes onde pega dois, ou quem leva a máscara
			var comp := Config.cfg.raizes_comp
			if alvo_ok and d < comp + 0.5:
				_mirar(u, alvo.global_position)
				return _alinhados(b, alvo.global_position - me, comp, Config.cfg.raizes_larg) >= 2 or alvo.carried_princess != null or Sorte.f() < 0.6
			return false
		"para_raios":  # Kaminari-kozō: crava no meio de quem ele vai bater
			if alvo_ok and d < u.stats.skill_radius + 3.0:
				_mirar(u, alvo.global_position)
				return b._count(1 - u.team, alvo.global_position, Config.cfg.pararaios_raio + 1.0) >= 2 or Sorte.f() < 0.5
			return false
		"poca":  # Predero: poça no pé de quem leva a máscara, de quem foge ou no meio do bolo
			if not alvo_ok or d > u.stats.skill_radius + 1.0:
				return false
			var adiante := alvo.global_position + Vector3(alvo.velocity.x, 0, alvo.velocity.z) * 0.5
			_mirar(u, adiante)
			if alvo.carried_princess != null:
				return true
			return b._count(1 - u.team, alvo.global_position, Config.cfg.poca_raio) >= 2 or Sorte.f() < 0.45
	return false


static func poder(b: BotBrain) -> bool:
	var u := b.unit
	var me := u.global_position
	var r := u.stats.power_radius
	var alvo := b._target
	var alvo_ok := alvo != null and alvo.alive
	match u.stats.power:
		"pisao_grande":
			return b._count(1 - u.team, me, r * 0.85) >= 2 or (alvo_ok and alvo.carried_princess != null and me.distance_to(alvo.global_position) < r)
		"jato":
			if not alvo_ok or me.distance_to(alvo.global_position) > minf(r, 12.0):
				return false
			_mirar(u, alvo.global_position)
			return _alinhados(b, alvo.global_position - me, minf(r, 12.0), 1.4) >= 2 or alvo.carried_princess != null
		"redemoinho_longe", "revoada":
			var alcance := u.stats.attack_range * 1.1 if u.stats.power == "redemoinho_longe" else 8.0
			if not alvo_ok or me.distance_to(alvo.global_position) > alcance:
				return false
			u.aim_point = alvo.global_position
			return b._count(1 - u.team, alvo.global_position, r) >= 2 or alvo.carried_princess != null
		"susto":
			if not alvo_ok or me.distance_to(alvo.global_position) > r * 0.8:
				return false
			_mirar(u, alvo.global_position)
			return b._count(1 - u.team, me, r) >= 2 or u.hp_ratio() < 0.4
		"grou":
			if not alvo_ok or me.distance_to(alvo.global_position) > r:
				return false
			_mirar(u, alvo.global_position)
			var feridos := 0
			for o in b.game.units:
				if o.alive and o.team == u.team and o != u and o.hp_ratio() < 0.7:
					var to := o.global_position - me
					to.y = 0
					var ao_longo := to.dot(u.aim_dir)
					if ao_longo > 0.0 and ao_longo < r and (to - u.aim_dir * ao_longo).length() < 1.5:
						feridos += 1
			return feridos >= 1 or _alinhados(b, alvo.global_position - me, r, 1.2) >= 2
		"danca":
			var feridos := 0
			for o in b.game.units:
				if o.alive and o.team == u.team and o.hp_ratio() < 0.7 and o.global_position.distance_to(me) <= r:
					feridos += 1
			return feridos >= 2 or b._count(1 - u.team, me, r * 0.7) >= 2
		"hipnose":
			if b._count(1 - u.team, me, r) < 2:
				return false
			# Combina com aliado de área (Pisão, Fúria, Redemoinho) perto dele.
			for o in b.game.units:
				if o.alive and o.team == u.team and o != u and o.global_position.distance_to(me) < 6.0 and o.stats.attack_kind == "melee":
					return true
			return Sorte.f() < 0.3
		"onibi":  # fogos girando em volta: só vale com gente encostando
			return b._count(1 - u.team, me, 3.5) >= 2 or (alvo_ok and me.distance_to(alvo.global_position) < 3.0 and u.hp_ratio() < 0.6)
		"arrastao":  # leva um inimigo: melhor ainda se ele leva a máscara
			if not alvo_ok:
				return false
			var da := me.distance_to(alvo.global_position)
			if da < 1.5 or da > Config.cfg.arrastao_dist * 0.8:
				return false
			_mirar(u, alvo.global_position)
			return alvo.carried_princess != null or Sorte.f() < 0.55
		"puxar_fios":  # puxa quem está preso nos fios dela (ou um bolo de gente perto)
			var presos := 0
			for o in b.game.units:
				if o.alive and o.team != u.team and o._fio_t > 0.0 and o._fio_dono == u \
						and o.global_position.distance_to(me) < Config.cfg.puxar_raio:
					presos += 1
			return presos >= 1 or b._count(1 - u.team, me, Config.cfg.puxar_raio * 0.5) >= 2
		"bosque":  # árvores: entre ele e quem persegue a máscara, ou sombra para os feridos
			var cfg := Config.cfg
			var perseguidor := b._nearest_enemy(10.0)
			if u.carried_princess and perseguidor:
				u.aim_point = me.lerp(perseguidor.global_position, 0.5)
				return true
			var feridos := 0
			for o in b.game.units:
				if o.alive and o.team == u.team and o.hp_ratio() < 0.6 and o.global_position.distance_to(me) < 6.0:
					feridos += 1
			if feridos >= 2:
				u.aim_point = me + u.aim_dir * 2.5
				return true
			if alvo_ok and me.distance_to(alvo.global_position) < cfg.bosque_dist and alvo.carried_princess != null:
				u.aim_point = alvo.global_position + Vector3(alvo.velocity.x, 0, alvo.velocity.z) * 0.8
				return true
			return alvo_ok and me.distance_to(alvo.global_position) < 6.0 and Sorte.f() < 0.3
		"relampago":  # atravessa quem está na frente; ferido, foge para casa num raio
			var cfg := Config.cfg
			if u.hp_ratio() < 0.35 and b._nearest_enemy(5.0) != null:
				_mirar(u, b.game.arena.princess_spot[u.team])
				return true
			if u.carried_princess:
				_mirar(u, b.game.arena.princess_spot[u.team])
				return true
			if alvo_ok and me.distance_to(alvo.global_position) < cfg.relampago_dist:
				_mirar(u, alvo.global_position)
				return _alinhados(b, alvo.global_position - me, cfg.relampago_dist, cfg.relampago_larg) >= 2 or alvo.hp_ratio() < 0.4 or Sorte.f() < 0.4
			return false
		"andaime":  # Predero: cobertura contra quem atira de longe, ou entre a máscara e quem persegue
			var perseguidor := b._nearest_enemy(10.0)
			if u.carried_princess and perseguidor:
				_mirar(u, perseguidor.global_position)
				return true
			for o in b.game.units:
				if o.alive and o.team != u.team and o.stats.attack_kind != "melee" and not o.em_voo:
					var dd := o.global_position.distance_to(me)
					if dd > 5.0 and dd < 14.0:
						_mirar(u, o.global_position)
						return u.hp_ratio() < 0.7 or b._count(u.team, me, 4.0) >= 2 or Sorte.f() < 0.35
			return false
	return false


static func super_r(b: BotBrain) -> bool:
	var u := b.unit
	var me := u.global_position
	var cfg := Config.cfg
	match u.stats.super_poder:
		"dohyo":
			return b._count(1 - u.team, me, cfg.dohyo_raio * 0.8) >= 2 and b._count(u.team, me, cfg.dohyo_raio) >= 2
		"mergulho3":
			return b._count(1 - u.team, me, cfg.mergulho3_raio) >= 2
		"mil_grous":
			var alvo := b._target
			if alvo == null or not alvo.alive or me.distance_to(alvo.global_position) > u.stats.power_radius:
				return false
			_mirar(u, alvo.global_position)
			return b._count(1 - u.team, alvo.global_position, 5.0) >= 2
		"veu":
			var fracos := 0
			for o in b.game.units:
				if o.alive and o.team == u.team and o.hp_ratio() < 0.5 and o.global_position.distance_to(me) <= cfg.veu_raio:
					fracos += 1
			return fracos >= 3
		"requiem":
			return b._count(1 - u.team, me, cfg.requiem_raio) >= 3
		"carga_caidos":  # a linha de fantasmas: mira onde cabem dois ou mais
			var alvo := b._target
			if alvo == null or not alvo.alive or me.distance_to(alvo.global_position) > cfg.caidos_comp:
				return false
			_mirar(u, alvo.global_position)
			return _alinhados(b, alvo.global_position - me, cfg.caidos_comp, cfg.caidos_larg * 0.5) >= 2 or alvo.carried_princess != null
		"festa_vila":  # leão gigante: briga grande ou aliado caído para levantar
			var caidos := 0
			if b.game.reanimar:
				for c in b.game.units:
					if c.team == u.team and not c.alive and b.game.reanimar.pode_reanimar(c) and c.global_position.distance_to(me) < 6.0:
						caidos += 1
			return b._count(1 - u.team, me, 6.0) >= 2 and (caidos >= 1 or b._count(u.team, me, cfg.festa_sorte_raio) >= 2)
		"casulo":
			return b._count(1 - u.team, me, cfg.casulo_raio) >= 2
		"floresta":  # anel de gigantes: briga grande em volta ou o time ferido junto
			var feridos := 0
			for o in b.game.units:
				if o.alive and o.team == u.team and o.hp_ratio() < 0.6 and o.global_position.distance_to(me) < cfg.floresta_raio * 0.8:
					feridos += 1
			return b._count(1 - u.team, me, cfg.floresta_raio * 0.7) >= 2 or (feridos >= 2 and b._count(1 - u.team, me, cfg.floresta_raio) >= 1)
		"tambores":
			return b._count(1 - u.team, me, cfg.tambores_raio) >= 2
		"saideira":  # chuva de garrafas onde o bolo inimigo está (melhor ainda com poça dele lá)
			var alvo := b._target
			if alvo == null or not alvo.alive or me.distance_to(alvo.global_position) > cfg.saideira_dist:
				return false
			_mirar(u, alvo.global_position)
			var n := b._count(1 - u.team, alvo.global_position, cfg.saideira_raio)
			return n >= 2 or (n >= 1 and HeroisObra.poca_em(u, alvo.global_position) != null)
	return false


## Aliado preso no Casulo de uma Jorogumo inimiga perto: o bot vai bater no
## casulo para soltá-lo (golpe e tiro de aliado quebram). Devolve true se
## assumiu o combate neste quadro.
static func soltar_aliado(b: BotBrain) -> bool:
	var u := b.unit
	if u.carried_princess or b._nearest_enemy(2.5) != null:
		return false
	var me := u.global_position
	var preso: Unit = null
	var melhor := 8.0
	for o in b.game.units:
		if o != u and o.alive and o.team == u.team and o._casulo_t > 0.0:
			var d := o.global_position.distance_to(me)
			if d < melhor:
				melhor = d
				preso = o
	if preso == null:
		return false
	_mirar(u, preso.global_position + Vector3(0, 1.0, 0))
	if melhor > u.stats.attack_range:
		u.move_intent = (preso.global_position - me).normalized()
		u.move_intent.y = 0
	else:
		u.wants_attack = true
	if u.stats.attack_kind != "melee" and melhor <= u.stats.attack_range:
		u.wants_attack = true
	return true


static func _mirar(u: Unit, p: Vector3) -> void:
	var to := p - u.global_position
	to.y = 0
	if to.length() > 0.05:
		u.aim_dir = to.normalized()
	u.aim_point = p


static func _projetil_vindo(b: BotBrain) -> bool:
	var me := b.unit.global_position
	for n in b.unit.get_tree().get_nodes_in_group("projeteis"):
		var p := n as Projectile
		if p == null or not is_instance_valid(p.owner_unit) or p.owner_unit.team == b.unit.team:
			continue
		var rel := me - p.global_position
		rel.y = 0
		if rel.length() < 7.0 and Vector3(p.velocity.x, 0, p.velocity.z).dot(rel) > 0.0:
			_mirar(b.unit, p.global_position)
			return true
	return false


## Atirador ou curandeiro inimigo a mais de `dmin` m, sem aliado dele colado.
static func _presa_isolada(b: BotBrain, dmin: float, dmax: float) -> Unit:
	var u := b.unit
	var me := u.global_position
	var melhor: Unit = null
	var nota := -INF
	for o in b.game.units:
		if not o.alive or o.team == u.team or o.na_sombra_para(u) or o.em_voo:
			continue
		var d := o.global_position.distance_to(me)
		if d < dmin or d > dmax:
			continue
		var v := 0.0
		if o.stats.attack_kind != "melee":
			v += 2.0
		if o.carried_princess:
			v += 3.0
		v -= b._count(o.team, o.global_position, 3.0) * 0.6
		if v > nota:
			nota = v
			melhor = o
	return melhor if nota >= 1.0 else null


## Quantos inimigos numa faixa de largura `larg` ao longo de `dir` até `comp` m.
static func _alinhados(b: BotBrain, dir: Vector3, comp: float, larg: float) -> int:
	var u := b.unit
	dir.y = 0
	dir = dir.normalized()
	var n := 0
	for o in b.game.units:
		if not o.alive or o.team == u.team:
			continue
		var to := o.global_position - u.global_position
		to.y = 0
		var ao_longo := to.dot(dir)
		if ao_longo > 0.0 and ao_longo < comp and (to - dir * ao_longo).length() < larg:
			n += 1
	return n
