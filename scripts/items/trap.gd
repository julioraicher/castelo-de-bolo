class_name Trap
extends Node3D
## Estrepes do Construtor: pontas espalhadas no chão. O primeiro inimigo que
## pisa (dentro de RADIUS) leva dano, fica lento por um tempo e a armadilha some.

const RADIUS := 1.4
const LIFETIME := 40.0

var owner_unit: Unit
var _game: Game
var _life := LIFETIME


func setup(game: Game, p_owner: Unit, pos: Vector3) -> void:
	_game = game
	owner_unit = p_owner
	add_to_group("traps")
	global_position = Vector3(pos.x, 0.0, pos.z)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # parada; só aparece com tween
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


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - global_position
		d.y = 0
		if d.length() <= RADIUS:
			var s := owner_unit.stats
			u.take_damage(s.trap_damage, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.3)
			u.apply_slow(s.trap_slow, s.trap_slow_time)
			Fx.burst(_game, global_position + Vector3(0, 0.3, 0), Color(0.8, 0.8, 0.9), 10, 5.0)
			Sfx.play("block", global_position, 0.2)
			queue_free()
			return
