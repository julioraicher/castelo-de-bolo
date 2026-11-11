class_name VooHeroi
extends Node
## Um corpo no ar levado por um herói (Ciclo 2.23): o arremesso do Agarrão
## (Sumotori) e o Mergulho (Karasu Tengu). Mesma conta do voo da catapulta:
##   p(s) = lerp(p0, p1, s) + ŷ·4h·s(1−s),  s = t/T
## Enquanto voa, a Unit fica `em_voo` (intocável, o corpo é daqui). Com
## t < 0 o corpo fica preso na frente de `segura` (o Sumotori segurando).

var unit: Unit
var game: Game
var p0 := Vector3.ZERO
var p1 := Vector3.ZERO
var h := 3.0
var T := 0.6
var t := 0.0
var segura: Unit = null
var ao_pousar: Callable


static func lancar(g: Game, u: Unit, de: Vector3, ate: Vector3, tempo: float, altura: float, pousar: Callable, quem_segura: Unit = null, segura_t := 0.0) -> VooHeroi:
	var v := VooHeroi.new()
	v.game = g
	v.unit = u
	v.p0 = de
	v.p1 = ate
	v.T = maxf(tempo, 0.05)
	v.h = altura
	v.t = -segura_t
	v.segura = quem_segura
	v.ao_pousar = pousar
	u.em_voo = true
	u._cancel_skill()
	u._windup_t = 0.0
	u.pose_voo(true)
	u.global_position = de
	u.reset_physics_interpolation()
	g.add_child(v)
	return v


func _physics_process(delta: float) -> void:
	if not is_instance_valid(unit):
		queue_free()
		return
	t += delta
	if t < 0.0:
		if segura and is_instance_valid(segura) and segura.alive:
			p0 = segura.global_position + segura._facing() * 1.15 + Vector3(0, 0.7, 0)
		unit.global_position = p0
		return
	var s := minf(t / T, 1.0)
	unit.global_position = p0.lerp(p1, s) + Vector3(0, 4.0 * h * s * (1.0 - s), 0)
	if s >= 1.0 or game.game_over:
		_pousar()


func _pousar() -> void:
	set_physics_process(false)
	unit.em_voo = false
	unit.pose_voo(false)
	unit.global_position = p1
	unit.velocity = Vector3.ZERO
	unit.reset_physics_interpolation()
	if ao_pousar.is_valid():
		ao_pousar.call()
	queue_free()
