class_name Projectile
extends Node3D
## Flecha ou magia. Integração explícita (v += g·dt; x += v·dt) e teste de
## colisão com inimigos (distância) e com o cenário (raio entre a posição
## antiga e a nova, para não "atravessar" paredes em alta velocidade).
## A flecha faz parábola: sai com a componente vertical que a faz cruzar a
## altura do peito do alvo exatamente na distância mirada.

const LIFETIME := 1.4
const HIT_RADIUS := 0.7
const GRAVITY := 12.0  # m/s² (menor que 9,8·escala real: arco legível sem ficar lento)
const TARGET_HEIGHT := 1.1  # altura do peito

var owner_unit: Unit
var velocity := Vector3.ZERO
var damage := 10.0
var gravity := 0.0
var _life := LIFETIME
var _game: Game
## Tiro carregado no máximo: quantos inimigos ainda atravessa (0 = para no
## primeiro) e multiplicador do raio da bomba.
var perfura := 0
var raio_mult := 1.0
## 3º tiro da Kitsune: explode como bomba onde bater (ou no fim do voo).
var explode_final := false
var _acertados: Array[Unit] = []
## Trovão do Kaminari-kozō: quem ficou perto da bola levou o choque de raspão.
var _chocados: Array[Unit] = []
var _origem := Vector3.ZERO
## Heróis raros (Ciclo 2.23): talismã que segue o alvo (Onmyoji), grou que
## cura aliados que atravessa e tiro devolvido pela Rajada do Yamabushi.
var segue: Unit = null
## Quanto o projétil vira atrás de `segue` (rad/s) e o zigue-zague dele (rad/s
## de oscilação lateral; 0 = reto). Ciclo 2.25: a nota do Komusō segue torto.
var vira := VIRA_SEGUE
var torto := 0.0
var cura := 0.0
var _curados: Array[Unit] = []
const VIRA_SEGUE := 7.0  # rad/s que o talismã consegue virar atrás do alvo


func setup(game: Game, shooter: Unit, origin: Vector3, dir: Vector3, p_kind: String) -> void:
	_game = game
	owner_unit = shooter
	position = origin
	_origem = origin
	velocity = dir.normalized() * shooter.stats.projectile_speed
	damage = shooter.stats.damage * shooter.damage_mult()
	kind = {"arrow": "flecha", "magic": "magia"}.get(p_kind, p_kind)
	match kind:
		"vento":
			perfura = 1  # lâmina de vento atravessa 2 alvos
		"nota":
			perfura = 99  # a nota atravessa todo mundo
	# Leque/Chuva soltam vários de uma vez: um som só por rajada.
	var agora := Time.get_ticks_msec()
	if agora - int(shooter.get_meta("som_t", -1000)) > 60:
		shooter.set_meta("som_t", agora)
		Sfx.play(SOM_LANCAR.get(kind, "shoot"), origin, 0.1)


## Som ao lançar e ao acertar, por projétil (gerados por tools/gerar_sons.py).
const SOM_LANCAR := {"flecha": "shoot", "shuriken": "lancar_metal", "bomba": "pavio", "fogo": "fogo", "chi": "luz", "magia": "sombra",
	"vento": "magia_vento", "nota": "flauta", "talisma": "papel", "grou": "papel", "fio": "seda",
	"semente": "kodama_semente", "trovao": "kaminari_trovao"}
const SOM_ACERTO := {"flecha": "flecha_chao", "shuriken": "tinido", "bomba": "explosao", "fogo": "brasa", "chi": "sino", "magia": "implosao",
	"vento": "magia_vento", "nota": "sino", "talisma": "magia_selo", "grou": "magia_selo",
	"fio": "seda_gruda", "onibi": "ochimusha_onibi", "mordida": "shishimai_mordida",
	"semente": "kodama_brota", "trovao": "kaminari_choque"}
var nivel := 1  # 2 = tiro carregado (rastro e impacto maiores)
var kind := "flecha"
var _spin: Node3D


## Carga máxima: flecha/shuriken atravessa carga_perfura inimigos e fica maior
## e mais brilhante; bomba explode carga_raio_bomba × maior.
## Vida do projétil para voar `d` m na velocidade atual.
func alcance_vida(d: float) -> void:
	_life = d / maxf(velocity.length(), 0.1)


## Rajada do Leque: o tiro passa a ser de `novo_dono` e volta em `dir`.
func rebater(novo_dono: Unit, dir: Vector3) -> void:
	owner_unit = novo_dono
	var v := maxf(Vector3(velocity.x, 0, velocity.z).length(), 18.0) * 1.15
	velocity = dir.normalized() * v
	gravity = 0.0
	segue = null
	torto = 0.0
	_acertados.clear()
	_chocados.clear()
	_origem = global_position
	_life = maxf(_life, 1.0)
	if velocity.length_squared() > 1e-6:
		look_at(global_position + velocity, Vector3.UP)
	FxProjetil.brilho(_game, global_position, Color(1.0, 0.8, 0.45), 1.2, 0.18)


func carregar() -> void:
	nivel = 2
	FxProjetil.carregar(self, kind)
	if kind == "bomba":
		raio_mult = Config.cfg.carga_raio_bomba
		scale = Vector3.ONE * 1.4
	else:
		perfura = Config.cfg.carga_perfura
		scale = Vector3.ONE * 1.7


func _ready() -> void:
	# Forma, cor e rastro de cada projétil: FxProjetil (docs/direcao-efeitos.md).
	# Aqui (já na árvore): o rastro em coordenadas do mundo lê a posição global.
	_spin = FxProjetil.montar(self, kind, Config.team_color(owner_unit.team))
	if velocity.length_squared() > 1e-6:  # look_at falha com alvo na mesma posição
		look_at(global_position + velocity, Vector3.UP)


## Balística: com velocidade horizontal v e distância d, o tempo de voo é
## t = d/v. Para cair Δh = h0 − h_alvo nesse tempo sob gravidade g:
## vy0 = g·t/2 − Δh/t.
func aim_ballistic(distance: float, chao_alvo := 0.0) -> void:
	gravity = GRAVITY
	var vh := Vector3(velocity.x, 0, velocity.z).length()
	var t := distance / maxf(vh, 0.1)
	var alvo := chao_alvo + (0.0 if kind == "bomba" else TARGET_HEIGHT)
	velocity.y = GRAVITY * t * 0.5 - (position.y - alvo) / t
	_life = maxf(_life, t * 1.6)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		if explode_final:
			_explode(global_position)
		_fim()
		return
	var from := global_position
	if segue and is_instance_valid(segue) and segue.alive and not segue.em_voo:
		# Vira a velocidade na direção do alvo com taxa limitada (dá para esquivar).
		var quer := (segue.global_position + Vector3(0, TARGET_HEIGHT, 0) - from).normalized()
		var v := velocity.length()
		var atual := velocity / maxf(v, 0.01)
		var ang := atual.angle_to(quer)
		if ang > 0.001:
			velocity = atual.slerp(quer, minf(vira * delta / ang, 1.0)) * v
			if velocity.length_squared() > 1e-6:
				look_at(from + velocity, Vector3.UP)
	if torto > 0.0:
		# Balanço de nota musical: a direção oscila de lado; com `segue` a curva
		# fecha no alvo assim mesmo, mas tarde e torta (dá para desviar).
		velocity = velocity.rotated(Vector3.UP, sin(_life * 9.0) * torto * delta)
	velocity.y -= gravity * delta
	var to := from + velocity * delta
	if _spin:
		_spin.rotate_object_local(Vector3.FORWARD, delta * (25.0 if kind == "shuriken" else 9.0))
	if to.y <= -1.0:  # segurança: o chão é colisor, o raio abaixo já pega
		if kind == "bomba" or explode_final:
			_explode(Vector3(to.x, 0.0, to.z))
		else:
			_bateu(Vector3(to.x, 0.1, to.z))
		_fim()
		return
	var query := PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if kind == "bomba" or explode_final:
			_explode(from)
		else:
			_bateu(hit.position)
		_fim()
		return
	global_position = to
	if gravity > 0.0 and velocity.length_squared() > 1e-6:
		look_at(to + velocity, Vector3.UP)
	for t in _game.torretas:
		if t.team != owner_unit.team and t.encosta(global_position, 0.3):
			if kind == "bomba" or explode_final:
				_explode(global_position)
			t.take_hit(damage, owner_unit.team)
			_bateu(global_position)
			_fim()
			return
	if cura > 0.0:
		for u in _game.units:
			if u.alive and u.team == owner_unit.team and u != owner_unit and not _curados.has(u) \
					and Vector2(u.global_position.x - global_position.x, u.global_position.z - global_position.z).length() < HIT_RADIUS + 0.4:
				_curados.append(u)
				u.heal(cura, owner_unit)
				FxProjetil.brilho(_game, u.global_position + Vector3(0, 1.2, 0), Color(0.6, 1.0, 0.7), 1.0, 0.25)
	for u in _game.units:
		if u._casulo_t > 0.0 and u.alive and u.team == owner_unit.team and u != owner_unit:
			# Casulo da Jorogumo: tiro de aliado bate no casulo e ajuda a soltar.
			var dc := u.global_position - global_position
			var dyc := -dc.y
			dc.y = 0
			if dc.length() < HIT_RADIUS and dyc > -0.2 and dyc < 2.1:
				Herois.bater_casulo(u, owner_unit)
				if kind == "bomba" or explode_final:
					_explode(global_position)
				else:
					_bateu(global_position)
				_fim()
				return
			continue
		if u.alive and u.team != owner_unit.team and not u.em_voo:  # quem voa na catapulta: o tiro passa
			# Cápsula do boneco (0,7 m de raio somando o projétil, dos pés até 2,1 m).
			# Antes era uma esfera de 1,25 m no peito: um corredor de 2,5 m de
			# largura, por isso flecha "na sorte" acertava tanto.
			var d := u.global_position - global_position
			var dy := -d.y
			d.y = 0
			if kind == "trovao" and d.length() >= HIT_RADIUS and d.length() < HIT_RADIUS + 0.9 \
					and dy > -0.2 and dy < 2.1 and not _chocados.has(u):
				# Raspão do trovão: a bola solta uma faísca em quem passa perto.
				_chocados.append(u)
				FxNatureza.raio(_game, global_position, u.global_position + Vector3(0, 1.1, 0), 0.15)
				u.take_damage(damage * 0.25 * queda(), owner_unit, velocity.normalized(), 0.0, false, "trovao", 1)
				continue
			if d.length() < HIT_RADIUS and dy > -0.2 and dy < 2.1 and not _acertados.has(u):
				if kind == "bomba" or explode_final:
					_explode(global_position)
				else:
					u.take_damage(damage * queda(), owner_unit, velocity.normalized(), 1.0, false, kind, nivel)
					Reacoes.em(_game, u.global_position, 0.8, kind, owner_unit.team)
					if perfura > 0:
						perfura -= 1
						damage *= 0.8
						_acertados.append(u)
						continue
				_fim()
				return


## Bomba: dano em área, mais forte no centro (cai linearmente até 50% na borda).
## Queda do dano com a distância (ClassStats.queda_*): linear de 1 em
## queda_dist_ini até queda_dano_min no alcance.
func queda() -> float:
	return queda_em(Vector2(global_position.x - _origem.x, global_position.z - _origem.z).length())


func queda_em(d: float) -> float:
	var st := owner_unit.stats
	if st.queda_dist_ini <= 0.0:
		return 1.0
	var k := clampf((d - st.queda_dist_ini) / maxf(st.attack_range - st.queda_dist_ini, 0.1), 0.0, 1.0)
	return lerpf(1.0, st.queda_dano_min, k)


func _explode(at: Vector3) -> void:
	var r := owner_unit.stats.explosao_raio * raio_mult
	var trovao := kind == "trovao"
	if trovao:
		# 3º tiro do Kaminari-kozō: estoura em raios (não é fogo: não queima nada).
		FxNatureza.trovao_estoura(_game, at, r)
		Sfx.play("kaminari_trovao", at, 0.1, 1.0, -2.0)
	else:
		FxProjetil.explosao(_game, at, r)
		FxProjetil.anel_chao(_game, at, Color(1.0, 0.55, 0.15, 0.8), r)
		Reacoes.em(_game, at, r, "bomba", owner_unit.team)
		Sfx.play("explosao", at, 0.1, 1.0 if nivel == 1 else 0.8)
	_game.camera.shake_at(at, 0.3 if trovao else 0.45)
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - at
		if absf(d.y) > 2.5:  # em cima da muralha / embaixo da ponte
			continue
		d.y = 0
		if d.length() <= r:
			var f := 1.0 - 0.5 * d.length() / r
			u.take_damage(damage * f, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, f, false, kind, nivel)
			u.launch((2.0 if trovao else 5.0) * f)


## Bateu no cenário (parede/chão): impacto do elemento e som.
func _bateu(at: Vector3) -> void:
	FxProjetil.impacto_cenario(_game, at, kind, velocity.normalized(), nivel)
	Reacoes.em(_game, at, 0.8, kind, owner_unit.team)
	Sfx.play(SOM_ACERTO.get(kind, "hit"), at, 0.1, 1.0, -6.0)


## Some sem cortar o rastro: as partículas soltas terminam no mundo.
func _fim() -> void:
	FxProjetil.soltar_rastro(self, _game)
	queue_free()
