class_name Trap
extends Node3D
## Armadilhas do Construtor:
##   estrepes (Armadilheiro): o primeiro inimigo que pisa leva dano e fica lento.
##   mina (Mestre da Pólvora): explode em área e empurra (sem lentidão).

const RADIUS := 1.4
const LIFETIME := 40.0

var owner_unit: Unit
var _game: Game
var _life := LIFETIME


func setup(game: Game, p_owner: Unit, pos: Vector3) -> void:
	_game = game
	owner_unit = p_owner
	add_to_group("traps")
	global_position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # parada; só aparece com tween
	_mina = p_owner.stats.trap_kind == "mina"
	if _mina:
		_build_mine()
	else:
		_build_spikes()
	# Anel fraco na cor do time: aliados enxergam onde está.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.12
	torus.outer_radius = RADIUS
	ring.mesh = torus
	ring.scale = Vector3(1, 0.04, 1)
	ring.position.y = 0.04
	ring.material_override = Fx.unshaded(Color(Config.team_color(p_owner.team), 0.45), true)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	scale = Vector3.ONE * 0.2
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


var _mina := false
var _blink: MeshInstance3D
var _blink_t := 0.0


func _build_mine() -> void:
	var disc := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.35
	c.bottom_radius = 0.42
	c.height = 0.14
	c.radial_segments = 10
	disc.mesh = c
	disc.position.y = 0.07
	disc.material_override = Fx.lit(Color(0.12, 0.12, 0.16))
	add_child(disc)
	_blink = MeshInstance3D.new()
	var b := SphereMesh.new()
	b.radius = 0.09
	b.height = 0.18
	_blink.mesh = b
	_blink.position.y = 0.17
	_blink.material_override = Fx.unshaded(Color(2.0, 0.8, 0.15))
	add_child(_blink)


func _build_spikes() -> void:
	var spike_mat := Fx.lit(Color(0.25, 0.25, 0.3), 0.4)
	spike_mat.metallic = 0.6
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.09
	cone.height = 0.32
	cone.radial_segments = 4
	cone.rings = 1
	for i in 7:
		var spike := MeshInstance3D.new()
		spike.mesh = cone
		spike.material_override = spike_mat
		var a := TAU * i / 7.0 + randf() * 0.5
		var r := 0.25 + randf() * 0.7
		spike.position = Vector3(cos(a) * r, 0.14, sin(a) * r)
		spike.rotation = Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(spike)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _blink:
		_blink_t += delta
		_blink.visible = fmod(_blink_t, 0.8) < 0.4
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 1.5:
			continue
		d.y = 0
		if d.length() <= RADIUS:
			var s := owner_unit.stats
			if _mina:
				_explode()
				queue_free()
				return
			u.take_damage(s.trap_damage, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.3)
			u.apply_slow(s.trap_slow, s.trap_slow_time)
			Fx.burst(_game, global_position + Vector3(0, 0.3, 0), Color(0.8, 0.8, 0.9), 10, 5.0)
			Sfx.play("block", global_position, 0.2)
			queue_free()
			return


func _explode() -> void:
	var r := RADIUS * 1.6
	Fx.burst(_game, global_position + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.2), 20, 8.0)
	Fx.ring(_game, global_position, Color(1.0, 0.55, 0.15, 0.9), r)
	Sfx.play("hit", global_position, 0.15)
	_game.camera.shake_at(global_position, 0.5)
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 1.5:
			continue
		d.y = 0
		if d.length() <= r:
			u.take_damage(owner_unit.stats.trap_damage, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 1.5)
			u.launch(6.0)
