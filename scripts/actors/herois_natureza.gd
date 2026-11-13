class_name HeroisNatureza
extends RefCounted
## Heróis 2.27b: Kodama do Shinboku (Kitsune) e Kaminari-kozō (Ninja de
## Shuriken). Os ganchos de Herois (rapida, poder, super_proprio, tick e o dano
## chegando) chamam estas funções. Estados em vars da Unit (bloco "Heróis
## 2.27b"); números em GameConfig ("Heróis 2.27b"); efeitos em FxNatureza.
##
## Reações deles (quiz 3B): molhado (água do Kappa) conduz o raio (pula mais
## longe e fere mais); fogo queima o bosque (ArvoreKodama via Reacoes); árvore
## do Kodama é para-raios (raio que cai perto dela cai nela e ela pega fogo).

## Elementos de raio (o molhado conduz).
const RAIO := ["trovao", "descarga", "relampago", "tambor", "para_raios"]
## Não disparam a descarga (senão um raio puxaria outro sem fim).
const SEM_DESCARGA := ["descarga", "para_raios", "tambor"]


# --- Ganchos -----------------------------------------------------------------------

static func tick(u: Unit, delta: float) -> void:
	if u._molhado_t > 0.0:
		u._molhado_t -= delta
	if u.stats.carga_estatica and u.alive and u.carga < 1.0:
		# Triboelétrico: correr esfrega o ar e acumula carga (mais rápido, mais carga).
		var v := Vector2(u.velocity.x, u.velocity.z).length()
		if v > 2.0:
			somar_carga(u, Config.cfg.carga_correr * delta * minf(v / 6.0, 1.3))
	if u._tambores_t > 0.0:
		_tick_tambores(u, delta)
	if u._floresta_t > 0.0:
		_tick_floresta(u, delta)


static func zerar(u: Unit) -> void:
	u._molhado_t = 0.0
	u.carga = 0.0
	_marca_carga(u)
	u._tambores_t = 0.0
	u._floresta_t = 0.0


## Dano chegando em `u` (depois das regras do 2.27). Molha, faz brotar, conduz
## o raio e, se quem bate é o Kaminari-kozō com a carga cheia, descarrega.
static func apanhar(u: Unit, amount: float, attacker: Unit, elemento: String, nivel: int) -> float:
	var cfg := Config.cfg
	if elemento == "agua":
		if u._molhado_t <= 0.0:
			FxNatureza.molhado(u)
		u._molhado_t = cfg.molhado_tempo
	if elemento == "semente" and nivel >= 2 and attacker != null:
		u.prender(cfg.broto_preso)
		FxNatureza.broto(u)
	if elemento in RAIO and u._molhado_t > 0.0:
		amount *= cfg.molhado_dano
		FxNatureza.conduziu(u)
	if attacker != null and attacker != u and attacker.team != u.team and attacker.stats.carga_estatica \
			and attacker.carga >= 1.0 and not elemento in SEM_DESCARGA and amount > 0.0:
		attacker.carga = 0.0
		_marca_carga(attacker)
		amount += cfg.descarga_dano * attacker.damage_mult() * (cfg.molhado_dano if u._molhado_t > 0.0 else 1.0)
		u.prender(cfg.descarga_preso)
		FxNatureza.descarga(attacker, u)
		_cadeia(attacker, u)
	return amount


# --- Kaminari-kozō ------------------------------------------------------------------

static func somar_carga(u: Unit, x: float) -> void:
	if not u.stats.carga_estatica:
		return
	var antes := u.carga
	u.carga = clampf(u.carga + x, 0.0, 1.0)
	if antes < 1.0 and u.carga >= 1.0:
		_marca_carga(u)
		FxNatureza.carga_cheia(u)


## Cabelo faiscando enquanto a carga está cheia (um nó só, some na descarga).
static func _marca_carga(u: Unit) -> void:
	var quer := u.carga >= 1.0 and u.alive
	var tem := u.has_meta("carga_no") and is_instance_valid(u.get_meta("carga_no"))
	if quer == tem:
		return
	if tem:
		(u.get_meta("carga_no") as Node).queue_free()
		u.remove_meta("carga_no")
	if quer:
		u.set_meta("carga_no", FxNatureza.cabelo_faiscando(u))


## Descarga em cadeia: do primeiro atingido salta para o inimigo mais perto
## ainda não atingido (até descarga_n, a até descarga_raio m; molhado: o dobro).
## Os para-raios do dono a até pararaios_puxa m também descarregam.
static func _cadeia(k: Unit, primeiro: Unit) -> void:
	var cfg := Config.cfg
	var atingidos: Array[Unit] = [primeiro]
	var de := primeiro
	var dano := cfg.descarga_dano * k.damage_mult() * 0.8
	for i in cfg.descarga_n:
		var alcance := cfg.descarga_raio * (cfg.molhado_alcance if de._molhado_t > 0.0 else 1.0)
		var prox: Unit = null
		var melhor := alcance
		for o in Herois._inimigos(k, de.global_position, alcance):
			if atingidos.has(o):
				continue
			var d := o.global_position.distance_to(de.global_position)
			if d < melhor:
				melhor = d
				prox = o
		if prox == null:
			break
		var arv := arvore_para_raios(k, prox.global_position)
		if arv:  # a árvore do Kodama pega o raio no caminho
			FxNatureza.raio(k.game, de.global_position + Vector3(0, 1.2, 0), arv.topo(), 0.5)
			arv.queimar(k.team)
			break
		FxNatureza.raio(k.game, de.global_position + Vector3(0, 1.2, 0), prox.global_position + Vector3(0, 1.2, 0), 0.4)
		var dir := prox.global_position - de.global_position
		dir.y = 0
		prox.take_damage(dano, k, dir.normalized() if dir.length() > 0.1 else Vector3.FORWARD, 0.3, false, "descarga", 3)
		if prox.alive:
			prox.prender(cfg.descarga_preso)
		atingidos.append(prox)
		de = prox
	for n in k.get_tree().get_nodes_in_group("para_raios"):
		var pr := n as ParaRaios
		if pr and pr.dono == k and not pr.indo and pr.global_position.distance_to(k.global_position) <= cfg.pararaios_puxa:
			pr.descarregar(dano)


## Árvore do Kodama de outro time a até arvore_pararaios m de `pos` (o raio de
## `k` cai nela). null se não houver.
static func arvore_para_raios(k: Unit, pos: Vector3) -> ArvoreKodama:
	var melhor: ArvoreKodama = null
	var dist := Config.cfg.arvore_pararaios
	for n in k.get_tree().get_nodes_in_group("arvores_kodama"):
		var a := n as ArvoreKodama
		if a == null or a.indo or a.time == k.team:
			continue
		var d := Vector2(a.global_position.x - pos.x, a.global_position.z - pos.z).length()
		if d <= dist:
			dist = d
			melhor = a
	return melhor


## Q Para-raios: crava uma baqueta de cobre onde mira (até skill_radius m). Até
## pararaios_max por dono: o mais velho some.
static func para_raios(u: Unit) -> bool:
	var cfg := Config.cfg
	var to := u.aim_point - u.global_position
	to.y = 0
	if to.length() < 1.0:
		to = Herois._dir_mira(u) * 2.0
	var at := Herois.chao_valido(u, Herois.sem_parede(u, u.global_position, u.global_position + to.limit_length(u.stats.skill_radius)))
	var meus: Array = []
	for n in u.get_tree().get_nodes_in_group("para_raios"):
		var pr := n as ParaRaios
		if pr and pr.dono == u and not pr.indo:
			meus.append(pr)
	meus.sort_custom(func(a: ParaRaios, b: ParaRaios) -> bool: return a.nasceu < b.nasceu)
	while meus.size() >= cfg.pararaios_max:
		(meus.pop_front() as ParaRaios).sumir()
	var pr := ParaRaios.new()
	u.game.add_child(pr)
	pr.setup(u.game, u, at)
	u._play_upper("Throw", 1.6)
	FxNatureza.para_raios_lanca(u, at)
	return true


## E Relâmpago: vira raio e salta relampago_dist m em linha (para antes da
## parede); quem está no caminho leva o dano. Enche carga_relampago da carga.
static func relampago(u: Unit) -> void:
	var cfg := Config.cfg
	var dir := Herois._dir_mira(u)
	var de := u.global_position
	var ate := Herois.chao_valido(u, Herois.sem_parede(u, de, de + dir * cfg.relampago_dist))
	if Vector2(ate.x - de.x, ate.z - de.z).length() < 1.0:
		ate = de
	FxNatureza.relampago(u, de, ate)
	if u.carried_princess:
		u.drop_princess()
	u.global_position = ate
	u.velocity = Vector3.ZERO
	u._knock = Vector3.ZERO
	u.reset_physics_interpolation()
	u._intocavel_t = maxf(u._intocavel_t, 0.15)
	var seg := ate - de
	seg.y = 0
	var dano := u.stats.power_value * cfg.dano_poder_mult * u.damage_mult()
	for o in Herois._inimigos(u, de + seg * 0.5, seg.length() * 0.5 + cfg.relampago_larg + 0.5):
		var p := o.global_position - de
		p.y = 0
		var tt := clampf(p.dot(seg) / maxf(seg.length_squared(), 0.01), 0.0, 1.0)
		if (p - seg * tt).length() > cfg.relampago_larg:
			continue
		o.take_damage(dano, u, dir, 0.6, false, "relampago", 3)
	somar_carga(u, cfg.carga_relampago)


## R Tambores do Trovão: tambores_tempo s; a cada tambores_cada s um raio cai no
## inimigo mais perto (a até tambores_raio m dele ou de um para-raios dele).
static func tambores(u: Unit) -> bool:
	u._tambores_t = Config.cfg.tambores_tempo
	u._tambores_tick = 0.15
	u._play_upper("Spellcast_Raise", 1.3)
	FxNatureza.tambores(u, Config.cfg.tambores_tempo)
	return true


static func _tick_tambores(u: Unit, delta: float) -> void:
	var cfg := Config.cfg
	u._tambores_t -= delta
	u._tambores_tick -= delta
	if u._tambores_tick > 0.0 or not u.alive:
		return
	u._tambores_tick = cfg.tambores_cada
	var alvo := _alvo_tambor(u)
	if alvo:
		raio_do_ceu(u, alvo)


static func _alvo_tambor(u: Unit) -> Unit:
	var cfg := Config.cfg
	var centros: Array[Vector3] = [u.global_position]
	for n in u.get_tree().get_nodes_in_group("para_raios"):
		var pr := n as ParaRaios
		if pr and pr.dono == u and not pr.indo:
			centros.append(pr.global_position)
	var melhor: Unit = null
	var dist := INF
	for c in centros:
		for o in Herois._inimigos(u, c, cfg.tambores_raio):
			if o.na_sombra_para(u):
				continue
			var d := o.global_position.distance_to(c)
			if d < dist:
				dist = d
				melhor = o
	return melhor


## Um raio do céu em `alvo` (a árvore do Kodama perto dele pega o raio antes).
## Molhado: o raio ainda pula para o inimigo mais perto dele.
static func raio_do_ceu(u: Unit, alvo: Unit) -> void:
	var cfg := Config.cfg
	var arv := arvore_para_raios(u, alvo.global_position)
	if arv:
		FxNatureza.raio_ceu(u.game, arv.topo() - Vector3(0, 1.2, 0))
		arv.queimar(u.team)
		return
	FxNatureza.raio_ceu(u.game, alvo.global_position)
	var dir := alvo.global_position - u.global_position
	dir.y = 0
	var molhado := alvo._molhado_t > 0.0
	alvo.take_damage(cfg.tambores_dano * u.damage_mult(), u, dir.normalized() if dir.length() > 0.1 else Vector3.FORWARD, 0.3, false, "tambor", 3)
	if alvo.alive:
		alvo.prender(cfg.tambores_preso)
	if molhado:
		var prox: Unit = null
		var melhor := cfg.descarga_raio * cfg.molhado_alcance
		for o in Herois._inimigos(u, alvo.global_position, melhor):
			if o == alvo:
				continue
			var d := o.global_position.distance_to(alvo.global_position)
			if d < melhor:
				melhor = d
				prox = o
		if prox:
			FxNatureza.raio(u.game, alvo.global_position + Vector3(0, 1.2, 0), prox.global_position + Vector3(0, 1.2, 0), 0.4)
			prox.take_damage(cfg.tambores_dano * u.damage_mult() * 0.7, u, dir, 0.2, false, "tambor", 3)


# --- Kodama do Shinboku -------------------------------------------------------------

## Q Raízes: uma linha de raízes de raizes_comp m sai do chão na mira; quem está
## nela leva o dano e fica preso.
static func raizes(u: Unit) -> bool:
	var cfg := Config.cfg
	var dir := Herois._dir_mira(u)
	var de := u.global_position
	var ate := Herois.sem_parede(u, de, de + dir * cfg.raizes_comp)
	var comp := maxf(Vector2(ate.x - de.x, ate.z - de.z).length(), 2.0)
	u._play_upper("Spellcast_Raise", 1.6)
	u._mola(-2.0, 0.0)
	FxNatureza.raizes(u, de, dir, comp)
	for o in Herois._inimigos(u, de + dir * comp * 0.5, comp * 0.5 + cfg.raizes_larg + 0.5):
		var p := o.global_position - de
		p.y = 0
		var ao_longo := p.dot(dir)
		if ao_longo < -0.5 or ao_longo > comp + 0.5 or (p - dir * ao_longo).length() > cfg.raizes_larg:
			continue
		o.take_damage(u.stats.skill_value * u.damage_mult(), u, dir, 0.0, false, "raiz", 2)
		if o.alive:
			o.prender(cfg.raizes_preso)
			FxNatureza.raiz_prende(o)
	return true


## E Bosque: bosque_n árvores nascem onde mira (até bosque_dist m) por
## bosque_tempo s. Bloqueiam passagem e tiros; a sombra cura os aliados.
static func bosque(u: Unit) -> void:
	var cfg := Config.cfg
	var to := u.aim_point - u.global_position
	to.y = 0
	if to.length() < 2.5:
		to = Herois._dir_mira(u) * 4.0
	var centro := Herois.chao_valido(u, Herois.sem_parede(u, u.global_position, u.global_position + to.limit_length(cfg.bosque_dist)))
	u._play_upper("Spellcast_Raise", 1.3)
	FxNatureza.bosque(u, centro)
	var a0 := Sorte.f() * TAU
	for i in cfg.bosque_n:
		var a := a0 + TAU * i / maxf(cfg.bosque_n, 1)
		var p := Herois.chao_valido(u, centro + Vector3(cos(a), 0, sin(a)) * 1.7)
		plantar(u, p, cfg.bosque_tempo, false)


## Uma árvore do Kodama em `p` (empurra para fora quem estiver no lugar).
static func plantar(u: Unit, p: Vector3, tempo: float, grande: bool) -> ArvoreKodama:
	var arv := ArvoreKodama.new()
	u.game.add_child(arv)
	arv.setup(u.game, u, p, tempo, grande)
	var r := arv.raio_tronco() + 0.5
	for o in u.game.units:
		if not o.alive or o.em_voo:
			continue
		var d := o.global_position - p
		d.y = 0
		if d.length() < r:
			var fora := d.normalized() if d.length() > 0.05 else Vector3.RIGHT
			o.global_position = Vector3(p.x, o.global_position.y, p.z) + fora * (r + 0.1)
			o.reset_physics_interpolation()
	return arv


## R Floresta Antiga: anel de floresta_n árvores gigantes de floresta_raio m em
## volta dele por floresta_tempo s. A cada floresta_cada s as raízes prendem os
## inimigos de dentro e os aliados de dentro recuperam vida.
static func floresta(u: Unit) -> bool:
	var cfg := Config.cfg
	var c := u.global_position
	u._floresta_t = cfg.floresta_tempo
	u._floresta_tick = 0.6
	u._floresta_centro = c
	u._play_upper("Spellcast_Long", 1.1)
	u._mola(-5.0, 0.0)
	u.game.camera.shake_at(c, 0.4)
	FxNatureza.floresta(u, c, cfg.floresta_raio)
	for i in cfg.floresta_n:
		var a := TAU * i / maxf(cfg.floresta_n, 1)
		var alvo := c + Vector3(cos(a), 0, sin(a)) * cfg.floresta_raio
		var p := Herois.sem_parede(u, c, alvo)
		if Vector2(p.x - alvo.x, p.z - alvo.z).length() > 1.5:
			continue  # parede no caminho: ali o anel é a própria parede
		var arv := plantar(u, Herois.chao_valido(u, p), cfg.floresta_tempo, true)
		arv.atraso_nascer(0.04 * i)
	return true


static func _tick_floresta(u: Unit, delta: float) -> void:
	var cfg := Config.cfg
	u._floresta_t -= delta
	u._floresta_tick -= delta
	if u._floresta_tick > 0.0 or u._floresta_t <= 0.0:
		return
	u._floresta_tick = cfg.floresta_cada
	var c := u._floresta_centro
	for o in u.game.units:
		if not o.alive or o.em_voo:
			continue
		var d := o.global_position - c
		d.y = 0
		if d.length() > cfg.floresta_raio - 0.3:
			continue
		if o.team == u.team:
			if o.heal(cfg.floresta_cura * cfg.floresta_cada, u) > 0.0:
				FxNatureza.sombra_cura(o)
		elif not o.na_sombra_para(u):
			o.take_damage(cfg.floresta_dano * u.damage_mult(), u, -d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.0, false, "raiz", 2)
			if o.alive:
				o.prender(cfg.floresta_preso)
				FxNatureza.raiz_prende(o)
	FxNatureza.floresta_pulso(u, c, cfg.floresta_raio)


## Construtor (qualquer lenhador) cortando: a árvore do Kodama mais perto no
## arco leva o golpe (arvore_golpes golpes = 1 tora e ela cai).
static func cortar_arvore(by: Unit, dir: Vector3, alcance: float, arco: float) -> bool:
	var melhor: ArvoreKodama = null
	var dist := alcance + 0.5
	for n in by.get_tree().get_nodes_in_group("arvores_kodama"):
		var a := n as ArvoreKodama
		if a == null or a.indo:
			continue
		var to := a.global_position - by.global_position
		to.y = 0
		var d := to.length() - a.raio_tronco()
		if d > dist:
			continue
		if d > 0.8 and rad_to_deg(dir.angle_to(to.normalized())) > arco * 0.5:
			continue
		dist = d
		melhor = a
	if melhor == null:
		return false
	melhor.golpe(by)
	return true
