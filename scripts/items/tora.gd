class_name Tora
extends Node3D
## Tora (ou vara de bambu): sai da planta cortada, fica no chão até um
## Construtor encostar (de qualquer time) e vai nos braços dele até a pilha do
## castelo. Quem carrega anda a `tora_vel_mult` e não ataca; se apanhar, a
## tora cai. No chão, some depois de `tora_tempo_chao` s.

var carrier: Unit = null

var _game: Game
var _chao_t := 0.0
var _t := randf() * TAU
var _visual: Node3D


func setup(game: Game, pos: Vector3) -> void:
	_game = game
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # segue o carregador em _process
	var th := game.arena.theme
	_visual = th.tora_model.instantiate() if th.tora_model else make_visual()
	add_child(_visual)
	rotation.y = randf() * TAU


static func make_visual() -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = Fx.cached("tora_malha", func():
		var c := CylinderMesh.new()
		c.top_radius = 0.2
		c.bottom_radius = 0.2
		c.height = 1.3
		c.radial_segments = 7
		return c)
	mi.material_override = Fx.cached("tora_mat", func(): return Fx.lit(Color(0.55, 0.36, 0.2)))
	mi.rotation.z = PI / 2
	root.add_child(mi)
	for s in [-1, 1]:
		var anel := MeshInstance3D.new()
		anel.mesh = Fx.cached("tora_ponta", func():
			var c := CylinderMesh.new()
			c.top_radius = 0.17
			c.bottom_radius = 0.17
			c.height = 0.02
			c.radial_segments = 7
			return c)
		anel.material_override = Fx.cached("tora_miolo", func(): return Fx.lit(Color(0.85, 0.7, 0.45)))
		anel.rotation.z = PI / 2
		anel.position.x = 0.655 * s
		root.add_child(anel)
	return root


func no_chao() -> bool:
	return carrier == null


func pegar(u: Unit) -> void:
	carrier = u
	u.carried_tora = self
	_chao_t = 0.0
	Sfx.play("pickup", global_position, 0.1)


## Cai do carregador (apanhou, morreu, pegou a máscara).
func largar() -> void:
	if carrier == null:
		return
	var p := carrier.global_position
	carrier.carried_tora = null
	carrier = null
	global_position = p + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6))
	rotation = Vector3(0, randf() * TAU, 0)


func _process(delta: float) -> void:
	_t += delta
	if carrier:
		# Nos braços, atravessada na frente do peito.
		var xf := carrier.get_global_transform_interpolated()
		var frente := carrier.aim_dir if carrier.aim_dir.length() > 0.1 else Vector3.FORWARD
		global_position = xf.origin + Vector3(0, 1.25, 0) + frente.normalized() * 0.45
		rotation = Vector3(0, atan2(-frente.z, frente.x) + PI / 2, 0)
		return
	_visual.position.y = 0.15 + absf(sin(_t * 3.0)) * 0.08


func _physics_process(delta: float) -> void:
	if carrier:
		return
	_chao_t += delta
	if _chao_t >= Config.cfg.tora_tempo_chao:
		_game.toras.erase(self)
		queue_free()
