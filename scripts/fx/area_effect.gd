class_name AreaEffect
extends Node3D
## Poderes de área dos ninjas, num círculo do chão:
##   nuvem       (Bombas de Fumaça) inimigos dentro ficam lentos e levam dano em pulsos
##   selo        (Onmyoji) talismãs fecham o círculo: dano e SELO (sem atacar/poder)
##   coluna_fogo (Kitsune) colunas de fogo-raposa queimam em pulsos
## Visual barato: poucas malhas grandes, emissivas, animadas à mão.

const PULSE := 0.5

var _game: Game
var _owner: Unit
var _kind := "nuvem"
var _radius := 4.0
var _value := 5.0
var _duration := 3.0
var _t := 0.0
var _pulse_t := 0.0
var _parts: Array[MeshInstance3D] = []
var _mat: StandardMaterial3D


func setup(game: Game, owner_unit: Unit, center: Vector3, kind: String, radius: float, value: float, duration: float) -> void:
	_game = game
	_owner = owner_unit
	_kind = kind
	_radius = radius
	_value = value
	_duration = duration
	global_position = center
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado à mão
	var col := _color()
	_disc(col)
	match kind:
		"nuvem":
			_mat = Fx.unshaded(Color(0.55, 0.52, 0.68, 0.55), true)
			for i in 7:
				var a := TAU * i / 7.0
				var r := radius * (0.25 + 0.45 * (i % 3) / 2.0)
				_part(_sphere(radius * 0.42), Vector3(cos(a) * r, 0.8 + (i % 2) * 0.5, sin(a) * r), _mat)
			_part(_sphere(radius * 0.5), Vector3(0, 1.2, 0), _mat)
			Sfx.play("hit", center, 0.1)
		"selo":
			# Talismãs em pé formando o círculo + anel de raio.
			_mat = Fx.unshaded(Color(1.6, 1.7, 2.0))
			var card := BoxMesh.new()
			card.size = Vector3(0.35, 0.8, 0.02)
			for i in 10:
				var a := TAU * i / 10.0
				var mi := _part(card, Vector3(cos(a) * radius, 0.6, sin(a) * radius), _mat)
				mi.rotation.y = -a + PI / 2
			for i in 10:
				var a0 := TAU * i / 10.0
				var a1 := TAU * (i + 1) / 10.0
				Fx.zap(game, center + Vector3(cos(a0) * radius, 0.6, sin(a0) * radius), center + Vector3(cos(a1) * radius, 0.6, sin(a1) * radius), Color(0.6, 0.9, 1.0), 3)
			Sfx.play("magic", center)
			_apply_seal()
		"coluna_fogo":
			_mat = Fx.unshaded(Color(0.3, 1.4, 2.0, 0.75), true)
			_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.2
			cyl.bottom_radius = 0.9
			cyl.height = 4.5
			cyl.radial_segments = 8
			cyl.cap_top = false
			for i in 3:
				var a := TAU * i / 3.0
				_part(cyl, Vector3(cos(a), 0, sin(a)) * radius * 0.5 + Vector3(0, 2.2, 0), _mat)
			Sfx.play("magic", center)
	scale = Vector3(0.2, 1, 0.2)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _color() -> Color:
	match _kind:
		"nuvem":
			return Color(0.6, 0.55, 0.8)
		"selo":
			return Color(0.6, 0.9, 1.0)
	return Color(0.3, 0.95, 1.0)


func _physics_process(delta: float) -> void:
	_t += delta
	for i in _parts.size():
		var p := _parts[i]
		if _kind == "coluna_fogo":
			p.scale = Vector3(1.0 + 0.2 * sin(_t * 14.0 + i), 1.0 + 0.15 * sin(_t * 9.0 + i * 2.0), 1.0 + 0.2 * sin(_t * 14.0 + i))
			p.rotation.y += delta * 3.0
		elif _kind == "nuvem":
			p.position.y += sin(_t * 2.0 + i) * delta * 0.3
	if _kind == "selo":
		if _t > 1.0:
			queue_free()
		return
	_pulse_t -= delta
	if _pulse_t <= 0.0:
		_pulse_t = PULSE
		for u in _game.units:
			if not u.alive or u.team == _owner.team:
				continue
			var d := u.global_position - global_position
			if absf(d.y) > 2.5:
				continue
			d.y = 0
			if d.length() <= _radius:
				u.take_damage(_value, _owner, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.15)
				if _kind == "nuvem":
					u.apply_slow(0.55, PULSE + 0.1)
		if _kind == "coluna_fogo":
			Fx.burst(_game, global_position + Vector3(0, 1.0, 0), Color(0.4, 1.0, 1.0), 10, 6.0)
	if _t >= _duration:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.3)
		tw.tween_callback(queue_free)
		set_physics_process(false)


func _apply_seal() -> void:
	for u in _game.units:
		if not u.alive or u.team == _owner.team:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 2.5:
			continue
		d.y = 0
		if d.length() <= _radius:
			u.take_damage(_value, _owner, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.2)
			u.silence(_duration)


func _disc(col: Color) -> void:
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = _radius
	cyl.bottom_radius = _radius
	cyl.height = 0.04
	cyl.radial_segments = 24
	disc.mesh = cyl
	disc.position.y = 0.05
	disc.material_override = Fx.unshaded(Color(col, 0.25), true)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = _radius - 0.15
	torus.outer_radius = _radius
	ring.mesh = torus
	ring.scale = Vector3(1, 0.05, 1)
	ring.position.y = 0.07
	ring.material_override = Fx.unshaded(Color(col * 1.6, 0.9), true)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _part(mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_parts.append(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 1.6
	s.radial_segments = 10
	s.rings = 5
	return s
