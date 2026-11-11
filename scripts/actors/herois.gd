class_name Herois
extends RefCounted
## Regras dos heróis raros do Nv6 (Ciclo 2.23, docs/direcao-ciclo-2.23-herois.md §4).
## Funções estáticas que recebem a Unit: o unit.gd só chama os ganchos
## (`rapida`, `poder`, `super_proprio`, `tick`, `ao_apanhar`, `corpo_sem_cerebro`,
## `trocou_classe`, `limpar`). Estados ficam em vars da Unit (bloco "Heróis
## raros"); números em ClassStats (o .tres do herói) e em GameConfig (grupo
## "Heróis raros: regras"). Efeitos visuais em FxHerois.
##
## Herói futuro sem truque novo = só dados. Truque novo = um ramo aqui.

## Q dos heróis que moram aqui (Unit.tem_rapida).
const RAPIDAS := ["agarrao", "rasteira", "rajada", "mergulho", "roubar_rosto", "dobrar", "laco", "sono"]


# --- Ganchos chamados pela Unit -------------------------------------------------

## Q do herói. false = não saiu (a recarga curta, se houver, é posta aqui).
static func rapida(u: Unit) -> bool:
	match u.stats.skill:
		"agarrao":
			return _agarrao(u)
		"rasteira":
			return _rasteira(u)
		"rajada":
			return _rajada(u)
		"mergulho":
			return _mergulho(u)
		"roubar_rosto":
			return _roubar_rosto(u)
		"dobrar":
			return _dobrar(u)
		"laco":
			return _laco(u)
		"sono":
			return _sono(u)
	return false


## E do herói (o medidor já foi gasto pela Unit).
static func poder(u: Unit) -> void:
	var cfg := Config.cfg
	match u.stats.power:
		"pisao_grande":
			_pisao_grande(u)
		"jato":
			_jato(u)
		"redemoinho_longe", "revoada":
			var to := u.aim_point - u.global_position
			to.y = 0
			var alcance := u.stats.attack_range * 1.1 if u.stats.power == "redemoinho_longe" else 8.0
			var centro := chao_valido(u, u.global_position + to.limit_length(alcance))
			var fx := AreaEffect.new()
			u.game.add_child(fx)
			var kind := "redemoinho" if u.stats.power == "redemoinho_longe" else "revoada"
			fx.setup(u.game, u, centro, kind, u.stats.power_radius, u.stats.power_value * cfg.dano_poder_mult * u.damage_mult(), u.stats.power_duration)
			u._power_active_t = u.stats.power_duration
			u._play_upper("Spellcast_Shoot" if kind == "redemoinho" else "Throw", 1.3)
		"susto":
			_susto(u)
		"grou":
			u._play_upper("Spellcast_Shoot", 1.3)
			_grou(u, _dir_mira(u))
		"danca":
			u._danca_t = u.stats.power_duration
			u._danca_tick = 0.0
			u._power_active_t = u.stats.power_duration
			u._play_once("2H_Melee_Attack_Spinning", 0.6)
			FxHerois.danca(u, u.stats.power_radius, u.stats.power_duration)
		"hipnose":
			_hipnose(u)


## R dos heróis com super_tipo "proprio". false = não saiu (devolve a barra).
static func super_proprio(u: Unit) -> bool:
	var cfg := Config.cfg
	match u.stats.super_poder:
		"dohyo":
			u._dohyo_t = cfg.dohyo_tempo
			u._dohyo_pos = u.global_position
			var dentro: Array = []
			for o in _inimigos(u, u.global_position, cfg.dohyo_raio):
				dentro.append(o)
			u.set_meta("dohyo_dentro", dentro)
			u._play_once("2H_Melee_Attack_Chop", 0.5)
			u._mola(-6.0, 0.0)
			u.game.camera.shake_at(u.global_position, 0.5)
			FxHerois.dohyo(u, cfg.dohyo_raio, cfg.dohyo_tempo)
			return true
		"mergulho3":
			var alvos := _mais_perto(u, cfg.mergulho3_raio, cfg.mergulho3_alvos)
			if alvos.is_empty():
				return false
			_cadeia_corvos(u, alvos, 0)
			return true
		"mil_grous":
			u._play_upper("Spellcast_Raise", 1.2)
			var base := _dir_mira(u)
			var n := cfg.mil_grous_n
			for i in n:
				var a := deg_to_rad(lerpf(-cfg.mil_grous_graus * 0.5, cfg.mil_grous_graus * 0.5, float(i) / maxf(n - 1, 1)))
				_grou(u, base.rotated(Vector3.UP, a))
			return true
		"veu":
			u._play_upper("Spellcast_Raise", 1.2)
			FxHerois.veu(u, cfg.veu_raio)
			for o in u.game.units:
				if o.alive and o.team == u.team and o.global_position.distance_to(u.global_position) <= cfg.veu_raio:
					o._intocavel_t = maxf(o._intocavel_t, cfg.veu_tempo)
					FxHerois.veu_em(o, cfg.veu_tempo)
			return true
		"requiem":
			u._play_upper("Spellcast_Long", 1.0)
			FxHerois.requiem(u, cfg.requiem_raio)
			for o in _inimigos(u, u.global_position, cfg.requiem_raio):
				o._mudo_t = maxf(o._mudo_t, cfg.requiem_tempo)
				o._cancel_skill()
				o._spin_t = 0.0
				Fx.damage_number(u.game, o.global_position + Vector3(0, 0.5, 0), "SILÊNCIO", Color(0.6, 0.95, 0.9))
			return true
	return false


## Por quadro (dentro de Unit._tick_buffs): contadores dos estados e áreas.
static func tick(u: Unit, delta: float) -> void:
	if u._forcado_t > 0.0:
		u._forcado_t -= delta
	if u._cego_t > 0.0:
		u._cego_t -= delta
	if u._mudo_t > 0.0:
		u._mudo_t -= delta
		if fmod(u._mudo_t, 0.5) < delta:
			FxHerois.nota_muda(u)
	if u._sono_t > 0.0:
		u._sono_t -= delta
		if fmod(u._sono_t, 0.6) < delta:
			Fx.damage_number(u.game, u.global_position + Vector3(0.3, 1.2, 0), "z", Color(0.75, 0.9, 1.0), 0.6)
		if u._sono_t <= 0.0:
			acordar(u)
	if u._disfarce_t > 0.0:
		u._disfarce_t -= delta
		if u._disfarce_t <= 0.0:
			tirar_rosto(u)
	if u._canto_t > 0.0:
		_tick_canto(u, delta)
	if u._dohyo_t > 0.0:
		u._dohyo_t -= delta
		_tick_dohyo(u)
	if u._danca_t > 0.0:
		u._danca_t -= delta
		u._danca_tick -= delta
		if u._danca_tick <= 0.0:
			u._danca_tick = 0.5
			_pulso_danca(u)


## Dano chegando (antes do bloqueio e do escudo). Devolve o dano que fica;
## < 0 = o golpe foi engolido inteiro (boneco de papel).
static func ao_apanhar(u: Unit, amount: float, attacker: Unit, dir: Vector3, _melee: bool) -> float:
	if amount <= 0.0:
		return amount
	if u.shikigami > 0 and attacker != null:
		u.shikigami -= 1
		atualizar_shikigami(u)
		FxHerois.shikigami_rasga(u)
		Sfx.play("papel", u.global_position, 0.1)
		return -1.0
	if u.stats.casco > 0.0 and attacker != null and dir.length_squared() > 1e-4:
		# Pelas costas: o golpe vem de mais de 110° do rosto (facing·(−dir) < cos 110°).
		var d := Vector3(dir.x, 0, dir.z).normalized()
		if u._facing().dot(-d) < -0.342:
			amount *= 1.0 - u.stats.casco
			FxHerois.casco(u, d)
	if u._sono_t > 0.0:
		acordar(u)
	if u._canto_t > 0.0:
		u._canto_t = 0.0
		u._canto_alvos.clear()
		u._stop_upper("Spellcasting")
		Fx.damage_number(u.game, u.global_position + Vector3(0, 0.6, 0), "INTERROMPIDO", Color(0.9, 0.9, 0.9), 0.7)
	if u._disfarce_t > 0.0:
		tirar_rosto(u)
	return amount


## Andar forçado ou dormindo: o corpo ignora o que o cérebro pediu.
static func corpo_sem_cerebro(u: Unit) -> void:
	u.wants_attack = false
	u.wants_quick = false
	u.wants_power = false
	u.wants_super = false
	u.wants_block = false
	u.wants_dodge = false
	if u._sono_t > 0.0:
		u.move_intent = Vector3.ZERO
		return
	var d := u.global_position - u._forcado_de if u._forcado_afasta else u._forcado_de - u.global_position
	d.y = 0
	if not u._forcado_afasta and d.length() < 1.4:
		d = Vector3.ZERO  # chegou colado em quem chama
	u.move_intent = d.normalized() if d.length() > 0.01 else Vector3.ZERO
	if u.move_intent != Vector3.ZERO:
		u.aim_dir = u.move_intent


## Começo de set_class: o que era da classe anterior acaba.
static func trocou_classe(u: Unit) -> void:
	if u._disfarce_t > 0.0:
		u._disfarce_t = 0.0
		_barra_do_time(u, u.team)
	u._disfarce_time = -1
	u.shikigami = 0
	atualizar_shikigami(u)
	u._dohyo_t = 0.0
	u._danca_t = 0.0
	u._canto_t = 0.0


## Morte: todos os estados zeram (o rosto roubado cai junto).
static func limpar(u: Unit) -> void:
	if u._disfarce_t > 0.0:
		tirar_rosto(u)
	u._forcado_t = 0.0
	u._cego_t = 0.0
	u._sono_t = 0.0
	u._mudo_t = 0.0
	u._canto_t = 0.0
	u._canto_alvos.clear()
	u._dohyo_t = 0.0
	u._danca_t = 0.0
	u.shikigami = 0
	atualizar_shikigami(u)


# --- Estados compartilhados -------------------------------------------------------

## Andar forçado (§4.9): por t s o alvo anda para longe (afasta) ou para perto
## de `origem`, sem golpe nem poder. Quem carrega a máscara e herói em Super
## não são afetados.
static func forcar_andar(o: Unit, origem: Vector3, t: float, afasta: bool) -> bool:
	if not o.alive or o.em_voo or o.carried_princess or o._super_t > 0.0 or o._sombra_t > 0.0:
		return false
	o._forcado_t = maxf(o._forcado_t, t)
	o._forcado_de = origem
	o._forcado_afasta = afasta
	o._cancel_skill()
	o._windup_t = 0.0
	return true


## Dormir (Canção de Ninar): parado, sem nada; acorda com dano ou no fim.
static func dormir(o: Unit, t: float) -> void:
	if not o.alive or o.em_voo:
		return
	o._sono_t = maxf(o._sono_t, t * (0.5 if o.carried_princess else 1.0))
	o._cancel_skill()
	o._windup_t = 0.0
	o._play_once("Lie_Idle" if o._anim and o._anim.has_animation("Lie_Idle") else "Idle", o._sono_t)
	Fx.damage_number(o.game, o.global_position + Vector3(0, 0.6, 0), "ZZZ", Color(0.75, 0.9, 1.0))
	FxHerois.sono_em(o)


static func acordar(u: Unit) -> void:
	if u._sono_t <= 0.0 and u._anim_lock <= 0.0:
		return
	u._sono_t = 0.0
	u._anim_lock = 0.0
	if u.alive:
		u._play_once("Lie_StandUp", 0.4, 1.8)


# --- Sumotori -------------------------------------------------------------------

## Q Agarrão: pega o primeiro inimigo no cone curto e arremessa na mira, em arco.
static func _agarrao(u: Unit) -> bool:
	var cfg := Config.cfg
	var dir := _dir_mira(u)
	var alvo: Unit = null
	var melhor := INF
	for o in _inimigos(u, u.global_position, u.stats.skill_radius, dir, 70.0):
		if o._dodge_t > 0.0 or o.em_voo:
			continue
		var d := o.global_position.distance_to(u.global_position)
		if d < melhor:
			melhor = d
			alvo = o
	u._play_upper("Interact", 1.8)
	if alvo == null:
		u._quick_cd = u.quick_cooldown() * 0.25  # errou: volta logo
		FxHerois.agarrao_vazio(u, dir)
		return false
	if alvo.carried_princess:
		alvo.drop_princess()  # quem carrega a máscara solta ao ser agarrado
	alvo.drop_tora()
	alvo._cancel_skill()
	alvo._canto_t = 0.0
	var destino := u.global_position + dir * u.stats.skill_duration
	destino = sem_parede(u, u.global_position, destino)
	destino = chao_valido(u, destino)
	var dano := u.stats.skill_value * u.damage_mult()
	FxHerois.agarrao(u, alvo)
	Sfx.play("swing", u.global_position, 0.1, 0.7)
	var tw := u.create_tween()
	tw.tween_interval(cfg.agarrao_segura)
	tw.tween_callback(func() -> void:
		if is_instance_valid(u) and u.alive:
			u._play_upper("Throw", 1.4)
			u._mola(2.0, 8.0))
	VooHeroi.lancar(u.game, alvo, alvo.global_position, destino, 0.55, 2.8,
			func() -> void: _pouso_agarrao(u, alvo, destino, dano, dir), u, cfg.agarrao_segura)
	if u.is_player:
		u.game.camera.add_trauma(0.25)
	return true


static func _pouso_agarrao(u: Unit, alvo: Unit, onde: Vector3, dano: float, dir: Vector3) -> void:
	var cfg := Config.cfg
	var g := alvo.game
	FxHerois.pouso_pesado(g, onde, cfg.agarrao_respingo_raio)
	Sfx.play("explosao", onde, 0.1, 1.4, -4.0)
	g.camera.shake_at(onde, 0.45)
	var quem: Unit = u if is_instance_valid(u) else null
	if alvo.alive:
		alvo.take_damage(dano, quem, dir, 0.3, true, "terra", 2)
		if alvo.alive:
			alvo.prender(cfg.agarrao_chao)
			alvo._play_once("Lie_StandUp", cfg.agarrao_chao, 1.2)
	if quem == null:
		return
	for o in _inimigos(quem, onde, cfg.agarrao_respingo_raio):
		if o == alvo:
			continue
		var d := o.global_position - onde
		d.y = 0
		o.take_damage(cfg.agarrao_respingo * quem.damage_mult(), quem, d.normalized() if d.length() > 0.1 else dir, 1.3, true, "terra", 2)


## E Pisão do Santuário: onda grande que derruba (preso power_duration s).
static func _pisao_grande(u: Unit) -> void:
	var r := u.stats.power_radius
	u._play_once("2H_Melee_Attack_Chop", 0.45)
	u._mola(-7.0, 0.0)
	FxHerois.pisao_grande(u, r)
	u.game.camera.shake_at(u.global_position, 0.6)
	var acertou := false
	for o in _inimigos(u, u.global_position, r):
		var d := o.global_position - u.global_position
		d.y = 0
		var f := 1.0 - 0.5 * d.length() / r
		o.take_damage(u.stats.power_value * Config.cfg.dano_poder_mult * u.damage_mult() * f, u, d.normalized() if d.length() > 0.1 else u._facing(), 1.2, true, "terra", 3)
		if o.alive:
			o.launch(5.0 * f)
			o.prender(u.stats.power_duration)
		acertou = true
	if acertou:
		u.hitstop(Config.cfg.hitstop_time * 1.5)


## R Dohyō: quem estava dentro não sai, quem estava fora não entra (aliados passam).
static func _tick_dohyo(u: Unit) -> void:
	var r := Config.cfg.dohyo_raio
	var dentro: Array = u.get_meta("dohyo_dentro", [])
	for o in u.game.units:
		if not o.alive or o.team == u.team or o.em_voo:
			continue
		var d := o.global_position - u._dohyo_pos
		if absf(d.y) > 2.0:
			continue
		d.y = 0
		var dist := d.length()
		var dn := d / dist if dist > 0.05 else Vector3.RIGHT
		if dentro.has(o):
			if dist > r - 0.5:
				o.global_position = u._dohyo_pos + dn * (r - 0.5) + Vector3(0, d.y, 0)
				o.global_position.y = u.global_position.y if absf(o.global_position.y - u.global_position.y) < 2.0 else o.global_position.y
				if o._knock.dot(dn) > 0.0:
					o._knock -= dn * o._knock.dot(dn)
				o.reset_physics_interpolation()
		elif dist < r + 0.5:
			var y := o.global_position.y
			o.global_position = u._dohyo_pos + dn * (r + 0.5)
			o.global_position.y = y
			if o._knock.dot(dn) < 0.0:
				o._knock -= dn * o._knock.dot(dn)
			o.reset_physics_interpolation()
	if u._dohyo_t <= 0.0:
		u.remove_meta("dohyo_dentro")


# --- Kappa ----------------------------------------------------------------------

## Q Rasteira do Rio: some numa poça, sai skill_radius m à frente e derruba
## o inimigo mais perto do ponto de saída.
static func _rasteira(u: Unit) -> bool:
	var dir := _dir_mira(u)
	var de := u.global_position
	var ate := sem_parede(u, de, de + dir * u.stats.skill_radius)
	ate = chao_valido(u, ate)
	FxHerois.poca(u.game, de)
	u.global_position = ate
	u.reset_physics_interpolation()
	FxHerois.poca(u.game, ate)
	Sfx.play("agua", ate, 0.1)
	u._play_once("Unarmed_Melee_Attack_Kick", 0.35)
	u._mola(-3.0, 5.0)
	var alvo: Unit = null
	var melhor := 2.4
	for o in _inimigos(u, ate, 2.4):
		var dd := o.global_position.distance_to(ate)
		if dd < melhor:
			melhor = dd
			alvo = o
	if alvo:
		var to := alvo.global_position - ate
		to.y = 0
		alvo.take_damage(u.stats.skill_value * u.damage_mult(), u, to.normalized() if to.length() > 0.1 else dir, 0.5, true, "agua", 2)
		if alvo.alive:
			alvo.prender(u.stats.skill_duration)
		u.hitstop(Config.cfg.hitstop_time)
	if u.is_player:
		u.game.camera.add_trauma(0.25)
	return true


## E Jato d'Água (R Enchente = o mesmo, maior): linha que atravessa todos.
static func _jato(u: Unit) -> void:
	var dir := _dir_mira(u)
	var grande := u._super_t > 0.0
	var de := u.global_position
	var ate := sem_parede(u, de, de + dir * minf(u.stats.power_radius, 22.0))
	var larg := 1.3 * (1.8 if grande else 1.0)
	var empurra := u.stats.power_duration * (2.0 if grande else 1.0)
	var dano := u.stats.power_value * Config.cfg.dano_poder_mult * u.damage_mult() * (2.0 if grande else 1.0) / maxf(Config.cfg.super_mult_valor if grande else 1.0, 0.01)
	u._play_upper("Spellcast_Shoot", 1.3)
	FxHerois.jato(u, de, ate, larg)
	var seg := ate - de
	for o in _inimigos(u, de, seg.length() + larg):
		var p := o.global_position
		var tt := clampf((p - de).dot(seg) / maxf(seg.length_squared(), 0.01), 0.0, 1.0)
		var q := de + seg * tt
		if Vector2(p.x - q.x, p.z - q.z).length() > larg:
			continue
		o.take_damage(dano, u, dir, 0.0, false, "agua", 3)
		if o.alive and not o.stats.knock_imune:
			o._knock = dir * empurra
	if u.is_player:
		u.game.camera.add_trauma(0.35)
		u.game.camera.kick(dir, 0.4)


# --- Yamabushi ------------------------------------------------------------------

## Q Rajada do Leque: cone de vento que empurra e DEVOLVE projéteis inimigos.
static func _rajada(u: Unit) -> bool:
	var cfg := Config.cfg
	var dir := _dir_mira(u)
	var r := u.stats.skill_radius
	u._play_upper("1H_Melee_Attack_Slice_Horizontal", 1.6)
	u._mola(1.0, 6.0)
	FxHerois.rajada(u, dir, r)
	Sfx.play("swing", u.global_position, 0.1, 0.6)
	for o in _inimigos(u, u.global_position, r, dir, cfg.rajada_cone):
		var d := o.global_position - u.global_position
		d.y = 0
		var dn := d.normalized() if d.length() > 0.1 else dir
		o.take_damage(u.stats.skill_value * u.damage_mult(), u, dn, 0.0, false, "vento", 2)
		if o.alive and not o.stats.knock_imune:
			o._knock = dn * cfg.rajada_empurrao
	var devolvidos := 0
	for n in u.get_tree().get_nodes_in_group("projeteis"):
		var p := n as Projectile
		if p == null or p.is_queued_for_deletion() or not is_instance_valid(p.owner_unit) or p.owner_unit.team == u.team:
			continue
		var d := p.global_position - u.global_position
		d.y = 0
		if d.length() > r + 1.0:
			continue
		if d.length() > 0.6 and rad_to_deg(dir.angle_to(d.normalized())) > cfg.rajada_cone * 0.5:
			continue
		var volta := (dir * 0.6 + d.normalized() * 0.4).normalized() if d.length() > 0.6 else dir
		p.rebater(u, volta)
		devolvidos += 1
	if devolvidos > 0:
		Fx.damage_number(u.game, u.global_position + Vector3(0, 0.8, 0), "DEVOLVEU!" if devolvidos == 1 else "DEVOLVEU %d!" % devolvidos, Color(1.0, 0.75, 0.4))
		Sfx.play("tinido", u.global_position, 0.1)
	if u.is_player:
		u.game.camera.add_trauma(0.2)
	return true


# --- Karasu Tengu -----------------------------------------------------------------

## Q Mergulho: sobe (intocável) e cai no cursor, até skill_radius m.
static func _mergulho(u: Unit) -> bool:
	var to := u.aim_point - u.global_position
	to.y = 0
	if to.length() < 2.0:
		to = _dir_mira(u) * 4.0
	var p1 := chao_valido(u, u.global_position + to.limit_length(u.stats.skill_radius))
	mergulhar(u, p1, u.stats.skill_value * u.damage_mult(), u.stats.explosao_raio, 0.8, Callable())
	return true


## Um mergulho: marca no chão (contra-jogo), sobe e cai; dano + empurrão no raio.
static func mergulhar(u: Unit, p1: Vector3, dano: float, raio: float, tempo: float, depois: Callable) -> void:
	var g := u.game
	FxHerois.marca_mergulho(g, p1, raio, tempo, Config.team_color(u.team))
	g.perigo(p1, raio + 0.6, tempo, u.team)
	FxHerois.asas(u, tempo)
	Sfx.play("grasnido", u.global_position, 0.1)
	VooHeroi.lancar(g, u, u.global_position, p1, tempo, 5.5, func() -> void:
		FxHerois.impacto_mergulho(g, p1, raio)
		Sfx.play("explosao", p1, 0.1, 1.5, -6.0)
		g.camera.shake_at(p1, 0.35)
		if u.alive:
			u._play_once("Dualwield_Melee_Attack_Chop", 0.3)
			for o in _inimigos(u, p1, raio):
				var d := o.global_position - p1
				d.y = 0
				o.take_damage(dano, u, d.normalized() if d.length() > 0.1 else u._facing(), 1.4, true, "pena", 2)
		if depois.is_valid():
			depois.call())


## R Noite de Corvos: um mergulho em cada um dos mais perto, em sequência.
static func _cadeia_corvos(u: Unit, alvos: Array, i: int) -> void:
	if i >= alvos.size() or not is_instance_valid(u) or not u.alive or u.stats.super_poder != "mergulho3":
		return
	var a: Unit = alvos[i]
	var p := a.global_position if is_instance_valid(a) and a.alive else u.global_position + u._facing() * 3.0
	var p1 := chao_valido(u, p)
	mergulhar(u, p1, u.stats.skill_value * 1.15 * u.damage_mult(), u.stats.explosao_raio * 1.1, 0.55,
			func() -> void: _cadeia_corvos(u, alvos, i + 1))


# --- Mujina ---------------------------------------------------------------------

## Q Roubar Rosto: toca um inimigo perto e fica com a classe e a cor do time dele.
static func _roubar_rosto(u: Unit) -> bool:
	var alvo: Unit = null
	var melhor := u.stats.skill_radius
	for o in _inimigos(u, u.global_position, u.stats.skill_radius):
		var d := o.global_position.distance_to(u.global_position)
		if d <= melhor:
			melhor = d
			alvo = o
	if alvo == null:
		u._quick_cd = u.quick_cooldown() * 0.15
		Fx.damage_number(u.game, u.global_position + Vector3(0, 0.6, 0), "NINGUÉM PERTO", Color(0.8, 0.7, 1.0), 0.6)
		return false
	u._play_upper("Interact", 1.8)
	FxHerois.rosto(u, alvo)
	Sfx.play("sombra", u.global_position, 0.1)
	u._disfarce_t = u.stats.skill_duration
	u._disfarce_time = alvo.team
	u._montar_modelo(alvo.stats, alvo.team)
	_barra_do_time(u, alvo.team)
	if u.is_player:
		u.game.hud.show_big("Rosto de %s: os inimigos não te veem até você golpear" % alvo.stats.display_name, Color(0.8, 0.6, 1.0), 1.6)
	return true


static func tirar_rosto(u: Unit) -> void:
	if u._disfarce_time < 0 and u._disfarce_t <= 0.0:
		return
	u._disfarce_t = 0.0
	u._disfarce_time = -1
	if u.stats:
		u._montar_modelo(u.stats, u.team)
	_barra_do_time(u, u.team)
	if u.game:
		FxHerois.rosto_cai(u)
		Sfx.play("sombra_sai", u.global_position, 0.05)


static func _barra_do_time(u: Unit, t: int) -> void:
	var m = Unit._barra_cache.get("barra|%d" % t)
	if m and u._hp_fill:
		u._hp_fill.material_override = m


## E Susto: cone de 90° na frente; quem está nele foge dela sem atacar.
static func _susto(u: Unit) -> void:
	var dir := _dir_mira(u)
	u._play_upper("Spellcast_Raise", 1.5)
	FxHerois.susto(u, dir, u.stats.power_radius)
	for o in _inimigos(u, u.global_position, u.stats.power_radius, dir, 90.0):
		var d := o.global_position - u.global_position
		d.y = 0
		o.take_damage(u.stats.power_value * u.damage_mult(), u, d.normalized() if d.length() > 0.1 else dir, 0.4, false, "sombra", 3)
		if forcar_andar(o, u.global_position, u.stats.power_duration, true):
			Fx.damage_number(u.game, o.global_position + Vector3(0, 0.6, 0), "SUSTO!", Color(0.85, 0.6, 1.0))


# --- Onmyoji --------------------------------------------------------------------

## Q Dobrar: +1 boneco (até shikigami_max); com todos dobrados, o Q lança os
## bonecos como talismãs que caçam o inimigo mais fraco perto.
static func _dobrar(u: Unit) -> bool:
	var cfg := Config.cfg
	if u.shikigami < cfg.shikigami_max:
		u.shikigami += 1
		atualizar_shikigami(u)
		u._play_upper("Interact", 1.8)
		FxHerois.dobra(u)
		Sfx.play("papel", u.global_position, 0.1)
		return true
	var alvo: Unit = null
	var pior := INF
	for o in _inimigos(u, u.global_position, u.stats.attack_range * 1.3):
		if o.na_sombra_para(u):
			continue
		var v := o.hp_ratio() + o.global_position.distance_to(u.global_position) * 0.02
		if v < pior:
			pior = v
			alvo = o
	var base := _dir_mira(u)
	if alvo:
		var to := alvo.global_position - u.global_position
		to.y = 0
		base = to.normalized()
	u._play_upper("Spellcast_Shoot", 1.4)
	for i in u.shikigami:
		var dir := base.rotated(Vector3.UP, deg_to_rad(-30.0 + 30.0 * i))
		var p := u.game.spawn_projectile(u, u.global_position + Vector3(0, 1.5, 0) + dir * 0.8, dir, "talisma")
		p.damage = u.stats.skill_value * u.damage_mult()
		p.velocity = dir * 18.0
		p.segue = alvo
		p.nivel = 2
		FxProjetil.carregar(p, p.kind)
	u.shikigami = 0
	atualizar_shikigami(u)
	return true


## Bonecos de papel girando em volta (uma malha só, refeita quando a conta muda).
static func atualizar_shikigami(u: Unit) -> void:
	if u._shiki_no and is_instance_valid(u._shiki_no):
		u._shiki_no.queue_free()
	u._shiki_no = null
	if u.shikigami <= 0 or u.game == null:
		return
	u._shiki_no = FxHerois.bonecos(u, u.shikigami)


## Grou de papel: atravessa todos, fere inimigos e cura aliados no caminho.
static func _grou(u: Unit, dir: Vector3) -> void:
	var p := u.game.spawn_projectile(u, u.global_position + Vector3(0, 1.4, 0) + dir * 0.9, dir, "grou")
	p.velocity = dir * 20.0
	p.damage = u.stats.power_value * Config.cfg.dano_poder_mult * u.damage_mult()
	p.cura = u.stats.heal_amount * Config.cfg.vida_mult
	p.perfura = 99
	p.alcance_vida(minf(u.stats.power_radius, 26.0))
	p.nivel = 2


# --- Tennin ---------------------------------------------------------------------

## Q Laço do Manto: puxa um aliado CAÍDO até ela e levanta na hora; sem caído
## no alcance, puxa um aliado de pé e cura skill_value.
static func _laco(u: Unit) -> bool:
	var g := u.game
	var r := u.stats.skill_radius
	var caido: Unit = null
	var melhor := r
	if g.reanimar:
		for c in g.units:
			if c == u or c.team != u.team or c.alive or not g.reanimar.pode_reanimar(c):
				continue
			var d := c.global_position.distance_to(u.global_position)
			if d < melhor:
				melhor = d
				caido = c
	u._play_upper("Throw", 1.4)
	if caido:
		var perto := u.global_position + (caido.global_position - u.global_position).normalized() * 1.4
		perto = chao_valido(u, perto)
		FxHerois.laco(u, caido)
		Sfx.play("swing", u.global_position, 0.1, 0.8)
		var tw := caido.create_tween()
		tw.tween_property(caido, "global_position", perto, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			caido.reset_physics_interpolation()
			if g.reanimar.pode_reanimar(caido):
				g.reanimar.levantar(caido, u)
				caido.hp = maxf(caido.hp, caido.max_hp() * Config.cfg.laco_vida)
				caido._update_hp_bar())
		return true
	var aliado: Unit = null
	melhor = r
	for o in g.units:
		if o == u or not o.alive or o.team != u.team or o.em_voo:
			continue
		var d := o.global_position.distance_to(u.global_position)
		if d > 2.5 and d < melhor:
			melhor = d
			aliado = o
	if aliado == null:
		u._quick_cd = u.quick_cooldown() * 0.2
		return false
	FxHerois.laco(u, aliado)
	var de := u.global_position - aliado.global_position
	de.y = 0
	var puxa := maxf(de.length() - 1.6, 0.0)
	if not aliado.stats.knock_imune:
		aliado._knock = de.normalized() * minf(sqrt(2.0 * Unit.KNOCK_DECAY * puxa), 30.0)
	aliado.heal(u.stats.skill_value * Config.cfg.vida_mult, u)
	return true


## Dança: cura quem está perto dela e afasta os inimigos até a borda.
static func _pulso_danca(u: Unit) -> void:
	var r := u.stats.power_radius
	for o in u.game.units:
		if not o.alive or o.em_voo:
			continue
		var d := o.global_position - u.global_position
		if absf(d.y) > 1.8:
			continue
		d.y = 0
		var dist := d.length()
		if dist > r:
			continue
		if o.team == u.team:
			o.heal(o.max_hp() * u.stats.power_value, u)
		elif not o.carried_princess and not o.stats.knock_imune:
			var dn := d / dist if dist > 0.1 else Vector3.RIGHT
			var v := sqrt(2.0 * Unit.KNOCK_DECAY * (r + 0.5 - dist))
			if o._knock.dot(dn) < v * 0.8:
				o._knock = dn * v


# --- Komusō ---------------------------------------------------------------------

## Q Canção de Ninar: toca parado; quem fica no cone até o fim dorme.
static func _sono(u: Unit) -> bool:
	u._canto_t = u.stats.skill_duration
	u._canto_alvos.clear()
	u._play_upper("Spellcasting", 1.0, true)
	FxHerois.canto(u, _dir_mira(u), u.stats.skill_radius, u.stats.skill_duration)
	Sfx.play("flauta", u.global_position, 0.05)
	return true


static func _tick_canto(u: Unit, delta: float) -> void:
	var antes := u._canto_t
	u._canto_t -= delta
	var dir := u._facing()
	var r := u.stats.skill_radius
	if fmod(antes, 0.2) < delta:
		for o in _inimigos(u, u.global_position, r, dir, 60.0):
			o.apply_slow(0.5, 0.35)
	if u._canto_t <= 0.0:
		u._stop_upper("Spellcasting")
		var n := 0
		for o in _inimigos(u, u.global_position, r, dir, 60.0):
			dormir(o, u.stats.skill_duration)
			n += 1
		FxHerois.canto_fim(u, dir, r)
		if n > 0 and u.is_player:
			Fx.damage_number(u.game, u.global_position + Vector3(0, 0.8, 0), "DORMIRAM %d" % n, Color(0.75, 0.9, 1.0))


## E Hipnose: inimigos perto andam até ele por power_duration s, sem atacar.
static func _hipnose(u: Unit) -> void:
	u._play_upper("Spellcasting", 1.2)
	FxHerois.hipnose(u, u.stats.power_radius)
	for o in _inimigos(u, u.global_position, u.stats.power_radius):
		if forcar_andar(o, u.global_position, u.stats.power_duration, false):
			Fx.damage_number(u.game, o.global_position + Vector3(0, 0.6, 0), "HIPNOSE", Color(0.6, 0.95, 0.9))
			FxHerois.hipnose_em(o, u.stats.power_duration)


# --- Utilidades -----------------------------------------------------------------

static func _dir_mira(u: Unit) -> Vector3:
	var d := Vector3(u.aim_dir.x, 0, u.aim_dir.z)
	return d.normalized() if d.length() > 0.1 else u._facing()


## Inimigos vivos de `u` a até r de `centro` (opcional: cone de `graus` em `dir`).
static func _inimigos(u: Unit, centro: Vector3, r: float, dir := Vector3.ZERO, graus := 360.0) -> Array[Unit]:
	var lista: Array[Unit] = []
	for o in u.game.units:
		if not o.alive or o.team == u.team or o.em_voo:
			continue
		var d := o.global_position - centro
		if absf(d.y) > 1.8:
			continue
		d.y = 0
		var dist := d.length()
		if dist > r:
			continue
		if graus < 359.0 and dir != Vector3.ZERO and dist > 0.8 and rad_to_deg(dir.angle_to(d / dist)) > graus * 0.5:
			continue
		lista.append(o)
	return lista


static func _mais_perto(u: Unit, r: float, n: int) -> Array:
	var lista := _inimigos(u, u.global_position, r)
	lista.sort_custom(func(a: Unit, b: Unit) -> bool:
		return a.global_position.distance_squared_to(u.global_position) < b.global_position.distance_squared_to(u.global_position))
	return lista.slice(0, n)


## Encurta de→ate se uma parede estiver no caminho (para 0,8 m antes).
static func sem_parede(u: Unit, de: Vector3, ate: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(de + Vector3(0, 1, 0), ate + Vector3(0, 1, 0), Config.LAYER_WORLD)
	var hit := u.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var dir := (ate - de)
		dir.y = 0
		ate = Vector3(hit.position.x, de.y, hit.position.z) - dir.normalized() * 0.8
	return u.game.arena.clamp_to_arena(ate)


## Ponto de pouso em chão andável (malha de navegação), na altura do chão.
static func chao_valido(u: Unit, p: Vector3) -> Vector3:
	p = u.game.arena.clamp_to_arena(p)
	var mapa := u.get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(mapa) > 0:
		var q := NavigationServer3D.map_get_closest_point(mapa, p)
		if q.distance_to(p) < 12.0:
			p = q
	p.y = u.game.arena.ground_y(p.x, p.z, p.y + 3.0)
	return p
