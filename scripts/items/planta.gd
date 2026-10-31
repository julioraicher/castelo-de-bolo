class_name Planta
extends Node3D
## Árvore ou bambu que o Construtor corta. Três estágios (broto, jovem,
## adulta), um a cada `arvore_tempo_estagio`/`bambu_tempo_estagio` s.
## Cada golpe numa adulta solta 1 tora; quando as toras acabam ela volta a
## broto. Uma jovem rende 1 e também volta a broto (cortar cedo é desperdício).
## Broto não rende nada.
##
## Oferta de um bosque: N plantas · rendimento / (2 · tempo_estágio).

enum Estagio { BROTO, JOVEM, ADULTA }

## Altura relativa de cada estágio nas formas provisórias.
const ESCALA := [0.35, 0.65, 1.0]

var tipo := "arvore"   # "arvore" ou "bambu"
var lado := 0          # castelo de onde vem a posição (bosque seguro do time)
var estagio := Estagio.ADULTA
var restantes := 0     # toras que ainda saem da adulta
## Bot que escolheu esta planta (para dois aliados não cortarem a mesma).
var cortador: Unit = null

var _game: Game
var _t := 0.0
var _visual: Node3D
var _cenas: Array[PackedScene] = []


func setup(game: Game, p_tipo: String, p_lado: int, pos: Vector3) -> void:
	_game = game
	tipo = p_tipo
	lado = p_lado
	position = pos
	rotation.y = randf() * TAU
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # cresce por tween
	var th := game.arena.theme
	_cenas = th.arvore_estagios if tipo == "arvore" else th.bambu_estagios
	set_estagio(Estagio.ADULTA, false)


func tempo_estagio() -> float:
	return Config.cfg.arvore_tempo_estagio if tipo == "arvore" else Config.cfg.bambu_tempo_estagio


func rendimento() -> int:
	return Config.cfg.arvore_toras if tipo == "arvore" else Config.cfg.bambu_varas


func adulta() -> bool:
	return estagio == Estagio.ADULTA


func _physics_process(delta: float) -> void:
	if not _game.game_over:
		avancar(delta)


## Relógio do crescimento (separado do _physics_process para os testes).
func avancar(delta: float) -> void:
	if estagio == Estagio.ADULTA:
		return
	_t += delta
	if _t >= tempo_estagio():
		_t -= tempo_estagio()
		set_estagio(estagio + 1)


func set_estagio(e: int, anima := true) -> void:
	estagio = e
	if e == Estagio.ADULTA:
		restantes = rendimento()
	if e == Estagio.BROTO:
		_t = 0.0
	_montar_visual(anima)


## Um golpe de Construtor. Devolve true se saiu tora.
func golpe(by: Unit) -> bool:
	if estagio == Estagio.BROTO:
		return false
	var dir := (global_position - by.global_position) if by else Vector3.RIGHT
	dir.y = 0
	_game.soltar_tora(global_position + Vector3(0, 0.4, 0), -dir.normalized() if dir.length() > 0.01 else Vector3.RIGHT)
	Fx.burst(_game, global_position + Vector3(0, 1.2, 0), Color(0.7, 0.5, 0.25), 8, 4.0)
	Sfx.play("hit", global_position, 0.15)
	if estagio == Estagio.ADULTA:
		restantes -= 1
		if restantes > 0:
			_tremer()
			return true
	set_estagio(Estagio.BROTO)
	return true


func _tremer() -> void:
	if _visual == null:
		return
	var tw := _visual.create_tween()
	tw.tween_property(_visual, "rotation:z", 0.12, 0.05)
	tw.tween_property(_visual, "rotation:z", -0.08, 0.08)
	tw.tween_property(_visual, "rotation:z", 0.0, 0.1)


## Modelo do tema (ThemeConfig.arvore_estagios/bambu_estagios) ou forma
## provisória. Ao crescer, "estica e encolhe" (tween com passo de volta).
func _montar_visual(anima: bool) -> void:
	if _visual:
		_visual.queue_free()
	if _cenas.size() >= 3 and _cenas[estagio]:
		_visual = _cenas[estagio].instantiate()
	else:
		_visual = _provisoria()
	add_child(_visual)
	if anima:
		_visual.scale = Vector3(1.3, 0.4, 1.3)
		_visual.create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.45) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _provisoria() -> Node3D:
	var root := Node3D.new()
	var s: float = ESCALA[estagio]
	if tipo == "arvore":
		var tronco := MeshInstance3D.new()
		tronco.mesh = Fx.cached("planta_tronco", func():
			var c := CylinderMesh.new()
			c.top_radius = 0.22
			c.bottom_radius = 0.32
			c.height = 1.0
			c.radial_segments = 7
			return c)
		tronco.material_override = Fx.cached("planta_madeira", func(): return Fx.lit(Color(0.42, 0.28, 0.16)))
		tronco.scale = Vector3(s, 2.2 * s, s)
		tronco.position.y = 1.1 * s
		root.add_child(tronco)
		var copa := MeshInstance3D.new()
		copa.mesh = Fx.cached("planta_copa", func():
			var sp := SphereMesh.new()
			sp.radius = 1.0
			sp.height = 1.6
			sp.radial_segments = 8
			sp.rings = 4
			return sp)
		copa.material_override = Fx.cached("planta_folha", func(): return Fx.lit(Color(0.2, 0.45, 0.2)))
		copa.scale = Vector3.ONE * 1.5 * s
		copa.position.y = 2.6 * s
		root.add_child(copa)
	else:
		for i in 3:
			var vara := MeshInstance3D.new()
			vara.mesh = Fx.cached("planta_vara", func():
				var c := CylinderMesh.new()
				c.top_radius = 0.08
				c.bottom_radius = 0.1
				c.height = 1.0
				c.radial_segments = 6
				return c)
			vara.material_override = Fx.cached("planta_bambu", func(): return Fx.lit(Color(0.45, 0.65, 0.25)))
			var h := (3.2 + i * 0.6) * s
			vara.scale = Vector3(1, h, 1)
			var a := TAU * i / 3.0
			vara.position = Vector3(cos(a) * 0.3, h / 2.0, sin(a) * 0.3)
			vara.rotation.z = (i - 1) * 0.08
			root.add_child(vara)
	return root
