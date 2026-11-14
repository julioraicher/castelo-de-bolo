class_name HeroisObra
extends RefCounted
## Herói 2.30: Predero, o único herói raro do Construtor (o nome errado é de
## propósito: é assim que está escrito na placa da obra). Os ganchos de Herois
## (rapida, poder, super_proprio, tick, dano chegando, zerar) chamam estas
## funções. Estados em vars da Unit (bloco "Herói 2.30"); números em GameConfig
## ("Herói 2.30: Predero"); efeitos em FxObra.
##
## Kit "Mestre de obra" (quiz 2026-11-14):
##   ataque  Garrafada: garrafa de cachaça em arco (Projectile "garrafa"); o
##           vidro estoura em estilhaço e deixa quem leva "encachaçado".
##   Q       Poça de Cachaça: o garrafão vira poça; inimigo que pisa perde o
##           atrito e derrapa. Qualquer fogo que encosta acende a poça.
##   E       Andaime Expresso: cobertura de madeira que bloqueia passagem e tiro.
##   R       Saideira: chuva de garrafas na mira; a última vem acesa e põe fogo
##           nas poças dele.
## Física da derrapada: a caminhada acelera com a = μ·g; na poça μ cai para
## poca_atrito × o normal, então virar ou frear leva ~1/poca_atrito × mais.

## Frases da obra (só visual: randf pode).
const FRASES_E := ["Ó O AÇO!", "CIMENTO NELES!", "TÁ NO PRUMO!"]
const FRASES_ENTRADA := ["Ó O AÇO!", "BORA, PEÃO!", "HOJE TEM GARRAFADA!"]


# --- Ganchos -------------------------------------------------------------------------

static func tick(u: Unit, delta: float) -> void:
	if u._derrapa_t > 0.0:
		u._derrapa_t -= delta
	if u._encachacado_t > 0.0:
		u._encachacado_t -= delta
	if u._saideira_t > 0.0:
		_tick_saideira(u, delta)
	if u.stats.id == &"predero" and u.alive and not u.has_meta("predero_falou"):
		u.set_meta("predero_falou", true)
		FxObra.fala(u, FRASES_ENTRADA[randi() % FRASES_ENTRADA.size()])


static func zerar(u: Unit) -> void:
	u._derrapa_t = 0.0
	u._encachacado_t = 0.0
	u._saideira_t = 0.0
	u._saideira_n = 0
	if u.has_meta("predero_falou"):
		u.remove_meta("predero_falou")


## Dano chegando em `u`: garrafa encachaça; fogo em quem está encachaçado arde mais.
static func apanhar(u: Unit, amount: float, _attacker: Unit, elemento: String, _nivel: int) -> float:
	var cfg := Config.cfg
	if elemento == "garrafa":
		if u._encachacado_t <= 0.0:
			FxObra.encachacado(u)
		u._encachacado_t = cfg.encachacado_tempo
	elif u._encachacado_t > 0.0 and Reacoes.tipo(elemento) == "fogo" and amount > 0.0:
		amount *= cfg.encachacado_fogo
		FxObra.arde(u)
	return amount


# --- Garrafada (ataque) ------------------------------------------------------------------

## Poça do dono que cobre `at` (a garrafa que cai nela espalha o estilhaço). null se não houver.
static func poca_em(dono: Unit, at: Vector3) -> PocaCachaca:
	for n in dono.get_tree().get_nodes_in_group("pocas_cachaca"):
		var p := n as PocaCachaca
		if p and p.dono == dono and p.ativa() and p.cobre(at, 0.3):
			return p
	return null


# --- Poça de Cachaça (Q) -----------------------------------------------------------------

## Q: o garrafão voa até a mira (até skill_radius m) e vira poça. Até poca_max
## por dono: a mais velha seca.
static func poca(u: Unit) -> bool:
	var cfg := Config.cfg
	var to := u.aim_point - u.global_position
	to.y = 0
	if to.length() < 1.5:
		to = Herois._dir_mira(u) * 3.0
	var at := Herois.chao_valido(u, Herois.sem_parede(u, u.global_position, u.global_position + to.limit_length(u.stats.skill_radius)))
	var minhas: Array = []
	for n in u.get_tree().get_nodes_in_group("pocas_cachaca"):
		var p := n as PocaCachaca
		if p and p.dono == u and not p.indo and not p.pequena:
			minhas.append(p)
	minhas.sort_custom(func(a: PocaCachaca, b: PocaCachaca) -> bool: return a.nasceu < b.nasceu)
	while minhas.size() >= cfg.poca_max:
		(minhas.pop_front() as PocaCachaca).secar()
	var voo := clampf(Vector2(at.x - u.global_position.x, at.z - u.global_position.z).length() / 18.0, 0.15, 0.45)
	criar_poca(u, at, cfg.poca_raio, cfg.poca_tempo, voo, false)
	u._play_upper("Throw", 1.5)
	FxObra.garrafao(u, at, voo)
	return true


static func criar_poca(u: Unit, at: Vector3, raio: float, tempo: float, atraso: float, pequena: bool) -> PocaCachaca:
	var p := PocaCachaca.new()
	u.game.add_child(p)
	p.setup(u.game, u, at, raio, tempo, atraso, pequena)
	return p


## Quem pisa na poça (chamado pela PocaCachaca a cada quadro).
static func pisou(o: Unit, dono: Unit) -> void:
	var cfg := Config.cfg
	var novo := o._derrapa_t <= 0.0
	o._derrapa_t = maxf(o._derrapa_t, cfg.poca_derrapa)
	o._encachacado_t = maxf(o._encachacado_t, cfg.poca_derrapa + 0.4)
	if novo and o.velocity.length() > 2.0 and Sorte.ms() - int(o.get_meta("escorregou_ms", -5000)) > 2500:
		o.set_meta("escorregou_ms", Sorte.ms())
		FxObra.escorregou(o, dono)


# --- Andaime Expresso (E) ----------------------------------------------------------------

static func andaime(u: Unit) -> void:
	var cfg := Config.cfg
	var dir := Herois._dir_mira(u)
	var at := Herois.chao_valido(u, Herois.sem_parede(u, u.global_position, u.global_position + dir * cfg.andaime_dist))
	var a := Andaime.new()
	u.game.add_child(a)
	a.setup(u.game, u, at, dir)
	_abrir_espaco(u, a, at, dir)
	u._play_upper("Interact", 1.6)
	u._mola(-3.0, 0.0)
	u._power_active_t = 0.6
	FxObra.fala(u, FRASES_E[randi() % FRASES_E.size()])


## Quem estava onde o andaime nasceu é empurrado para fora (para o lado de que
## veio: o inimigo vai para longe do Predero, o aliado para perto).
static func _abrir_espaco(u: Unit, a: Andaime, at: Vector3, dir: Vector3) -> void:
	var cfg := Config.cfg
	var lado := Vector3.UP.cross(dir).normalized()
	for o in u.game.units:
		if not o.alive or o.em_voo:
			continue
		var d := o.global_position - at
		if absf(d.y) > 2.0:
			continue
		var frente := d.dot(dir)
		if absf(d.dot(lado)) > cfg.andaime_larg * 0.5 + 0.5 or absf(frente) > a.meia_prof() + 0.7:
			continue
		var sinal := 1.0 if o.team != u.team else -1.0
		if absf(frente) > 0.05 and o.team != u.team:
			sinal = signf(frente)
		o.global_position += dir * sinal * (a.meia_prof() + 0.8 - absf(frente))
		o.reset_physics_interpolation()
		o._knock = dir * sinal * 4.0


## Lenhador de outro time golpeando: o andaime mais perto no arco leva a machadada.
static func cortar_andaime(by: Unit, dir: Vector3, alcance: float, arco: float) -> bool:
	var melhor: Andaime = null
	var dist := alcance + 0.5
	for n in by.get_tree().get_nodes_in_group("andaimes"):
		var a := n as Andaime
		if a == null or a.indo or a.time == by.team:
			continue
		var to := a.global_position - by.global_position
		to.y = 0
		var d := maxf(to.length() - Config.cfg.andaime_larg * 0.5, 0.0)
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


# --- Saideira (R) ------------------------------------------------------------------------

static func saideira(u: Unit) -> bool:
	var cfg := Config.cfg
	var to := u.aim_point - u.global_position
	to.y = 0
	if to.length() < 2.0:
		to = Herois._dir_mira(u) * 5.0
	var centro := Herois.chao_valido(u, Herois.sem_parede(u, u.global_position, u.global_position + to.limit_length(cfg.saideira_dist)))
	# Onde cada garrafa cai: espiral de fora para dentro, a última (acesa) no meio.
	var pts: Array[Vector3] = []
	var a0 := Sorte.f() * TAU
	for i in cfg.saideira_n:
		if i == cfg.saideira_n - 1:
			pts.append(centro)
			continue
		var k := float(i) / maxf(cfg.saideira_n - 1, 1)
		var a := a0 + i * 2.4
		var r := cfg.saideira_raio * lerpf(0.95, 0.35, k) * (0.85 + 0.3 * Sorte.f())
		pts.append(Herois.chao_valido(u, centro + Vector3(cos(a), 0, sin(a)) * r))
	u.set_meta("saideira_pts", pts)
	u._saideira_centro = centro
	u._saideira_n = 0
	u._saideira_tick = FxObra.SAIDEIRA_VOO
	u._saideira_t = FxObra.SAIDEIRA_VOO + cfg.saideira_cada * cfg.saideira_n + 0.2
	u._play_upper("Throw", 1.2)
	u._mola(4.0, 6.0)
	FxObra.saideira(u, centro, pts, cfg.saideira_cada)
	return true


static func _tick_saideira(u: Unit, delta: float) -> void:
	var cfg := Config.cfg
	u._saideira_t -= delta
	u._saideira_tick -= delta
	var pts: Array = u.get_meta("saideira_pts", [])
	while u._saideira_tick <= 0.0 and u._saideira_n < pts.size():
		u._saideira_tick += cfg.saideira_cada
		var at: Vector3 = pts[u._saideira_n]
		var ultima := u._saideira_n == pts.size() - 1
		u._saideira_n += 1
		_garrafa_cai(u, at, ultima)
	if u._saideira_t <= 0.0 or u._saideira_n >= pts.size():
		u._saideira_t = 0.0


## Uma garrafa da Saideira chegando no chão: estilhaço, pocinha e, na última,
## o palito aceso que põe fogo nas poças do dono em volta.
static func _garrafa_cai(u: Unit, at: Vector3, ultima: bool) -> void:
	var cfg := Config.cfg
	var r := u.stats.explosao_raio * (1.4 if ultima else 1.0)
	FxObra.estilhaco(u.game, at, r, ultima)
	var dano := cfg.saideira_dano * u.damage_mult()
	for o in Herois._inimigos(u, at, r):
		var d := o.global_position - at
		d.y = 0
		var f := 1.0 - 0.4 * d.length() / r
		o.take_damage(dano * f, u, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.6 * f, false, "garrafa", 2)
	if not ultima:
		criar_poca(u, at, cfg.poca_raio * 0.6, cfg.poca_tempo * 0.6, 0.0, true)
		return
	Reacoes.em(u.game, at, cfg.saideira_raio + 1.0, "brasa", u.team)
	for n in u.get_tree().get_nodes_in_group("pocas_cachaca"):
		var p := n as PocaCachaca
		if p and p.dono == u and not p.indo and p.global_position.distance_to(at) <= cfg.saideira_raio + p.raio:
			p.acender()
	FxObra.fala(u, "Ó O FOGO!")
