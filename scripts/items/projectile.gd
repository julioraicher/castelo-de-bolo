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


func setup(game: Game, shooter: Unit, origin: Vector3, dir: Vector3, p_kind: String) -> void:
	_game = game
	owner_unit = shooter
	position = origin
	velocity = dir.normalized() * shooter.stats.projectile_speed
	damage = shooter.stats.damage * shooter.damage_mult()
	kind = {"arrow": "flecha", "magic": "magia"}.get(p_kind, p_kind)
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	match kind:
		"flecha":
			var shaft := CylinderMesh.new()
			shaft.top_radius = 0.04
			shaft.bottom_radius = 0.04
			shaft.height = 0.9
			mi.mesh = shaft
			mi.material_override = Fx.unshaded(Color(0.9, 0.95, 1.0))
			mi.rotation_degrees.x = 90
		"shuriken":
			mi.mesh = _star_mesh()
			mi.material_override = Fx.unshaded(Color(0.4, 1.6, 2.0))
			mi.rotation_degrees.x = 90
			_spin = mi
		"bomba":
			var sp := SphereMesh.new()
			sp.radius = 0.24
			sp.height = 0.48
			sp.radial_segments = 10
			sp.rings = 5
			mi.mesh = sp
			mi.material_override = Fx.lit(Color(0.08, 0.08, 0.12))
			var spark := MeshInstance3D.new()
			var ss := SphereMesh.new()
			ss.radius = 0.09
			ss.height = 0.18
			spark.mesh = ss
			spark.material_override = Fx.unshaded(Color(2.0, 1.0, 0.2))
			spark.position.y = 0.28
			add_child(spark)
		"talisma":
			var card := BoxMesh.new()
			card.size = Vector3(0.32, 0.02, 0.5)
			mi.mesh = card
			mi.material_override = Fx.unshaded(Color(1.6, 1.7, 1.9))
			_spin = mi
		_:
			var orb := SphereMesh.new()
			orb.radius = 0.28
			orb.height = 0.56
			orb.radial_segments = 10
			orb.rings = 5
			mi.mesh = orb
			var cols := {"magia": Color(1.2, 0.9, 2.0), "chi": Color(0.7, 2.0, 0.8), "fogo": Color(1.7, 0.9, 2.2)}
			mi.material_override = Fx.unshaded(cols.get(kind, Color(1.2, 0.9, 2.0)))
	add_child(mi)


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


func _ready() -> void:
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
		queue_free()
		return
	var from := global_position
	velocity.y -= gravity * delta
	var to := from + velocity * delta
	if _spin:
		_spin.rotate_object_local(Vector3.FORWARD if kind == "shuriken" else Vector3.UP, delta * 25.0)
	if to.y <= -1.0:  # segurança: o chão é colisor, o raio abaixo já pega
		if kind == "bomba":
			_explode(Vector3(to.x, 0.0, to.z))
		else:
			Fx.burst(_game, Vector3(to.x, 0.1, to.z), Color(0.8, 0.7, 0.5), 5, 2.5)
		queue_free()
		return
	var query := PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		if kind == "bomba":
			_explode(from)
		else:
			Fx.burst(_game, to, Color(0.8, 0.7, 0.5), 6, 3.0)
		queue_free()
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
			if d.length() < HIT_RADIUS and dy > -0.2 and dy < 2.1:
				if kind == "bomba":
					_explode(global_position)
				else:
					u.take_damage(damage, owner_unit, velocity.normalized())
				queue_free()
				return


## Bomba: dano em área, mais forte no centro (cai linearmente até 50% na borda).
func _explode(at: Vector3) -> void:
	var r := owner_unit.stats.explosao_raio
	Fx.burst(_game, at + Vector3(0, 0.6, 0), Color(1.0, 0.6, 0.2), 18, 8.0)
	Fx.burst(_game, at + Vector3(0, 0.4, 0), Color(0.6, 0.6, 0.7), 10, 3.0)
	Fx.ring(_game, at, Color(1.0, 0.55, 0.15, 0.9), r)
	Sfx.play("hit", at, 0.15)
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
			u.take_damage(damage * f, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, f)
			u.launch(5.0 * f)
