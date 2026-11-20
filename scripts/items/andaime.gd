class_name Andaime
extends PecaDoMundo
## Andaime Expresso do Predero (Herói 2.30, E): uma parede de andaime de madeira
## com lona na cor do time, de pé na frente dele por andaime_tempo s. Corpo
## sólido no LAYER_WORLD: bloqueia passagem e tiros (como a árvore do Kodama).
## Lenhador de outro time desmonta em andaime_golpes machadadas (e não ganha
## tora: é madeira de obra, já tem dono). Visual em FxObra.andaime.

var _golpes := 3
var _corpo: StaticBody3D
var _visual: Node3D
const PROF := 0.7  # espessura do corpo sólido (m)


func setup(game: Game, p_dono: Unit, pos: Vector3, frente: Vector3) -> void:
	var cfg := Config.cfg
	_golpes = cfg.herois.andaime_golpes
	_iniciar(game, p_dono, &"andaimes", cfg.herois.andaime_tempo, pos)
	# A lona fica virada para quem atira: frente do nó = sentido da mira.
	look_at(pos + frente, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)
	_corpo = StaticBody3D.new()
	_corpo.collision_layer = Config.LAYER_WORLD
	_corpo.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(cfg.herois.andaime_larg, cfg.herois.andaime_alt, PROF)
	cs.shape = sh
	cs.position.y = cfg.herois.andaime_alt * 0.5
	_corpo.add_child(cs)
	add_child(_corpo)
	_visual = FxObra.andaime(self, cfg.herois.andaime_larg, cfg.herois.andaime_alt, Config.team_color(time))
	_visual.scale = Vector3(1.0, 0.05, 1.0)
	var tw := _visual.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FxObra.andaime_sobe(game, global_position, cfg.herois.andaime_larg, global_basis.x)


func meia_prof() -> float:
	return PROF * 0.5


func _physics_process(delta: float) -> void:
	if indo:
		return
	_vida -= delta
	if _vida <= 0.0:
		sair()


## Machadada de lenhador (HeroisObra.cortar_andaime). true = desmontou.
func golpe(by: Unit) -> bool:
	if indo:
		return false
	_golpes -= 1
	FxObra.andaime_golpe(self, by)
	if _golpes > 0:
		return false
	sair()
	return true


func sair() -> void:
	if not _saindo():
		return
	if _corpo:
		_corpo.queue_free()
		_corpo = null
	FxObra.andaime_cai(_game, global_position, Config.cfg.herois.andaime_larg, global_basis.x)
	var tw := _tween_fisica().set_parallel(true)
	if _visual:
		tw.tween_property(_visual, "rotation:x", -1.35, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(_visual, "scale", Vector3(1.0, 0.3, 1.0), 0.45).set_delay(0.3)
	tw.chain().tween_callback(queue_free)
