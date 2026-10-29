class_name Projectile
extends Node3D
## Flecha ou magia. Move em linha reta (integração explícita: x += v·dt) e
## testa colisão com inimigos (distância) e com o cenário (raio entre a
## posição antiga e a nova, para não "atravessar" paredes em alta velocidade).

const LIFETIME := 1.4
const HIT_RADIUS := 0.85

var owner_unit: Unit
var velocity := Vector3.ZERO
var damage := 10.0
var _life := LIFETIME
var _game: Game


func setup(game: Game, shooter: Unit, origin: Vector3, dir: Vector3, kind: String) -> void:
	_game = game
	owner_unit = shooter
	position = origin
	velocity = dir.normalized() * shooter.stats.projectile_speed
	damage = shooter.stats.damage
	var mi := MeshInstance3D.new()
	if kind == "arrow":
		var shaft := CylinderMesh.new()
		shaft.top_radius = 0.04
		shaft.bottom_radius = 0.04
		shaft.height = 0.9
		mi.mesh = shaft
		mi.material_override = Fx.lit(Color(0.55, 0.38, 0.2))
		mi.rotation_degrees.x = 90
	else:
		var orb := SphereMesh.new()
		orb.radius = 0.28
		orb.height = 0.56
		mi.mesh = orb
		var m := Fx.unshaded(Color(0.75, 0.6, 1.0))
		mi.material_override = m
		var light := OmniLight3D.new()
		light.light_color = Color(0.7, 0.5, 1.0)
		light.omni_range = 4.0
		light.light_energy = 1.5
		add_child(light)
	add_child(mi)


func _ready() -> void:
	look_at(global_position + velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	var from := global_position
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		Fx.burst(_game, to, Color(0.8, 0.7, 0.5), 6, 3.0)
		queue_free()
		return
	global_position = to
	for u in _game.units:
		if u.alive and u.team != owner_unit.team:
			var d := u.global_position + Vector3(0, 1.1, 0) - global_position
			if d.length() < HIT_RADIUS + 0.4:
				u.take_damage(damage, owner_unit, velocity.normalized())
				queue_free()
				return
