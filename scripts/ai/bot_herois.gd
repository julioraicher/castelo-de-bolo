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
			return randf() < 0.7
		"rasteira":
			if alvo_ok and d > 3.0 and d < u.stats.skill_radius + 1.5:
				_mirar(u, alvo.global_position)
				return alvo.stats.attack_kind != "melee" or randf() < 0.4
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
				return me.distance_to(casa_inimiga) < 45.0 or randf() < 0.3
			return false
		"dobrar":
			if u.shikigami < Config.cfg.shikigami_max:
				return b._nearest_enemy(7.0) == null or u.shikigami == 0
			return alvo_ok and (alvo.hp_ratio() < 0.5 or randf() < 0.3)
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
			return randf() < 0.3
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
	return false


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
