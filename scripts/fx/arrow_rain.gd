class_name ArrowRain
extends Node3D
## Poder do Arqueiro: marca um círculo no chão e, depois de um aviso de WARN s,
## faz chover flechas nele. O dano vem em pulsos (a cada PULSE s) em todo
## inimigo dentro do círculo; as flechas são só visuais, desenhadas numa
## MultiMesh (uma chamada de desenho para todas).

const WARN := 0.8
const PULSE := 0.5
const SPAWN_EVERY := 0.05
const DROP_HEIGHT := 11.0
const FALL_SPEED := 32.0
const MAX_ARROWS := 16

var _game: Game
var _shooter: Unit
var _radius := 4.0
var _damage := 10.0
var _duration := 3.0
var _t := 0.0
var _pulse_t := 0.0
var _spawn_t := 0.0
var _arrows: Array[Vector3] = []
var _mm: MultiMesh
var _marker_mat: StandardMaterial3D


func setup(game: Game, shooter: Unit, center: Vector3, radius: float, damage: float, duration: float) -> void:
	_game = game
	_shooter = shooter
	_radius = radius
	_damage = damage
	_duration = duration
	global_position = center
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado à mão

	# Marca no chão: disco translúcido + anel na cor do time.
	var col := Config.team_color(shooter.team)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.04
	cyl.radial_segments = 32
	cyl.rings = 1
	disc.mesh = cyl
	_marker_mat = Fx.unshaded(Color(col, 0.2), true)
	disc.material_override = _marker_mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position.y = 0.06
	add_child(disc)
	Fx.ring(game, center, Color(col, 0.9), radius)

	var arrow := CylinderMesh.new()
	arrow.top_radius = 0.07
	arrow.bottom_radius = 0.02
	arrow.height = 1.5
	arrow.radial_segments = 5
	arrow.rings = 1
	arrow.material = Fx.unshaded(Config.team_color(shooter.team).lightened(0.55))
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = arrow
	_mm.instance_count = MAX_ARROWS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t < WARN:
		_marker_mat.albedo_color.a = 0.12 + 0.15 * absf(sin(_t * 18.0))  # pisca: "saia daqui!"
		return
	var raining := _t < WARN + _duration
	if raining:
		_marker_mat.albedo_color.a = 0.25
		_spawn_t -= delta
		while _spawn_t <= 0.0 and _arrows.size() < MAX_ARROWS:
			_spawn_t += SPAWN_EVERY
			var r := _radius * sqrt(randf())  # √u: pontos uniformes no disco, não amontoados no centro
			var a := randf() * TAU
			_arrows.append(Vector3(r * cos(a), DROP_HEIGHT + randf() * 3.0, r * sin(a)))
		_pulse_t -= delta
		if _pulse_t <= 0.0:
			_pulse_t = PULSE
			_hit_inside()
			Sfx.play("shoot", global_position, 0.25)
	else:
		_marker_mat.albedo_color.a = maxf(_marker_mat.albedo_color.a - delta, 0.0)
		if _arrows.is_empty():
			queue_free()
			return

	# Flechas caindo (só visual).
	var i := 0
	while i < _arrows.size():
		_arrows[i].y -= FALL_SPEED * delta
		if _arrows[i].y <= 0.3:
			_arrows.remove_at(i)
		else:
			i += 1
	_mm.visible_instance_count = _arrows.size()
	for k in _arrows.size():
		_mm.set_instance_transform(k, Transform3D(Basis(Vector3.RIGHT, 0.15), _arrows[k]))


func _hit_inside() -> void:
	for u in _game.units:
		if not u.alive or u.team == _shooter.team:
			continue
		var d := u.global_position - global_position
		d.y = 0
		if d.length() <= _radius + 0.5:
			u.take_damage(_damage, _shooter, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.3)
