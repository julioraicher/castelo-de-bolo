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
var _acertados: Array[Unit] = []


func setup(game: Game, shooter: Unit, origin: Vector3, dir: Vector3, p_kind: String) -> void:
	_game = game
	owner_unit = shooter
	position = origin
	velocity = dir.normalized() * shooter.stats.projectile_speed
	damage = shooter.stats.damage * shooter.damage_mult()
	kind = {"arrow": "flecha", "magic": "magia"}.get(p_kind, p_kind)
	# Leque/Chuva soltam vários de uma vez: um som só por rajada.
	var agora := Time.get_ticks_msec()
	if agora - int(shooter.get_meta("som_t", -1000)) > 60:
		shooter.set_meta("som_t", agora)
		Sfx.play(SOM_LANCAR.get(kind, "shoot"), origin, 0.1)


## Som ao lançar e ao acertar, por projétil (gerados por tools/gerar_sons.py).
const SOM_LANCAR := {"flecha": "shoot", "shuriken": "lancar_metal", "bomba": "pavio", "fogo": "fogo", "chi": "luz", "magia": "sombra"}
const SOM_ACERTO := {"flecha": "flecha_chao", "shuriken": "tinido", "bomba": "explosao", "fogo": "brasa", "chi": "sino", "magia": "implosao"}
var nivel := 1  # 2 = tiro carregado (rastro e impacto maiores)


static var _star: ArrayMesh
var kind := "flecha"
var _spin: Node3D


static func _star_mesh() -> ArrayMesh:
	if _star:
		return _star
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var a := TAU * i / 4.0
		var p := Vector3(cos(a), sin(a), 0) * 0.3
		var e := Vector3(cos(a + PI / 4), sin(a + PI / 4), 0) * 0.08
		var d := Vector3(cos(a - PI / 4), sin(a - PI / 4), 0) * 0.08
		for f in [[Vector3.ZERO, d, p], [Vector3.ZERO, p, e], [Vector3.ZERO, p, d], [Vector3.ZERO, e, p]]:
			for v in f:
				st.add_vertex(v)
	st.generate_normals()
	_star = st.commit()
	return _star


## Carga máxima: flecha/shuriken atravessa carga_perfura inimigos e fica maior
## e mais brilhante; bomba explode carga_raio_bomba × maior.
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
		_fim()
		return
	var from := global_position
	velocity.y -= gravity * delta
	var to := from + velocity * delta
	if _spin:
		_spin.rotate_object_local(Vector3.FORWARD, delta * (25.0 if kind == "shuriken" else 9.0))
	if to.y <= -1.0:  # segurança: o chão é colisor, o raio abaixo já pega
		if kind == "bomba":
			_explode(Vector3(to.x, 0.0, to.z))
		else:
			_bateu(Vector3(to.x, 0.1, to.z))
		_fim()
		return
	var query := PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if kind == "bomba":
			_explode(from)
		else:
			_bateu(hit.position)
		_fim()
		return
	global_position = to
	if gravity > 0.0 and velocity.length_squared() > 1e-6:
		look_at(to + velocity, Vector3.UP)
	for u in _game.units:
		if u.alive and u.team != owner_unit.team:
			# Cápsula do boneco (0,7 m de raio somando o projétil, dos pés até 2,1 m).
			# Antes era uma esfera de 1,25 m no peito: um corredor de 2,5 m de
			# largura, por isso flecha "na sorte" acertava tanto.
			var d := u.global_position - global_position
			var dy := -d.y
			d.y = 0
			if d.length() < HIT_RADIUS and dy > -0.2 and dy < 2.1 and not _acertados.has(u):
				if kind == "bomba":
					_explode(global_position)
				else:
					u.take_damage(damage, owner_unit, velocity.normalized(), 1.0, false, kind, nivel)
					if perfura > 0:
						perfura -= 1
						damage *= 0.8
						_acertados.append(u)
						continue
				_fim()
				return


## Bomba: dano em área, mais forte no centro (cai linearmente até 50% na borda).
func _explode(at: Vector3) -> void:
	var r := owner_unit.stats.explosao_raio * raio_mult
	FxProjetil.explosao(_game, at, r)
	FxProjetil.anel_chao(_game, at, Color(1.0, 0.55, 0.15, 0.8), r)
	Sfx.play("explosao", at, 0.1, 1.0 if nivel == 1 else 0.8)
	_game.camera.shake_at(at, 0.45)
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - at
		if absf(d.y) > 2.5:  # em cima da muralha / embaixo da ponte
			continue
		d.y = 0
		if d.length() <= r:
			var f := 1.0 - 0.5 * d.length() / r
			u.take_damage(damage * f, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, f, false, "bomba", nivel)
			u.launch(5.0 * f)


## Bateu no cenário (parede/chão): impacto do elemento e som.
func _bateu(at: Vector3) -> void:
	FxProjetil.impacto_cenario(_game, at, kind, velocity.normalized(), nivel)
	Sfx.play(SOM_ACERTO.get(kind, "hit"), at, 0.1, 1.0, -6.0)


## Some sem cortar o rastro: as partículas soltas terminam no mundo.
func _fim() -> void:
	FxProjetil.soltar_rastro(self, _game)
	queue_free()
