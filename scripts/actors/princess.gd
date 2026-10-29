class_name Princess
extends Node3D
## O tesouro de um time (tema ninja: a Máscara Oni do clã; o nome Princess
## ficou no código desde o protótipo). Fica no pedestal do próprio castelo até
## um inimigo carregá-la. Cada espírito preso nela aumenta `fatness` (0..1):
## a máscara pesa mais e quem a carrega fica mais lento.

signal state_changed(princess: Princess)

enum State { HOME, CARRIED, DROPPED }


var team := 0
var state := State.HOME
var fatness := 0.0
var carrier: Unit = null
var home: Vector3

var _game: Game
var _visual: Node3D
var _drop_t := 0.0
## Progresso do resgate (0..GameConfig.princess_rescue_time) quando um aliado fica ao lado dela caída.
var rescue_progress := 0.0
var _beacon: MeshInstance3D


func setup(game: Game, p_team: int, p_home: Vector3) -> void:
	_game = game
	team = p_team
	home = p_home
	global_position = home
	_visual = Node3D.new()
	add_child(_visual)
	_mask = _make_mask(Config.team_color(team))
	_mask.position.y = 1.6
	_visual.add_child(_mask)
	_spirits = Node3D.new()
	_spirits.position.y = 1.6
	_visual.add_child(_spirits)
	# Facho de luz vertical na cor do time: dá para achar a máscara de longe.
	_beacon = MeshInstance3D.new()
	var beam := CylinderMesh.new()
	beam.top_radius = 0.25
	beam.bottom_radius = 0.6
	beam.height = 30.0
	_beacon.mesh = beam
	_beacon.material_override = Fx.unshaded(Color(Config.team_color(team).lightened(0.3), 0.18), true)
	_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beacon.position.y = 15.0
	_beacon.visible = false
	add_child(_beacon)
	_apply_fatness()


var _mask: Node3D
var _spirits: Node3D
var _t := 0.0


## Máscara Oni do clã: rosto na cor do time, chifres de osso, olhos de ouro e presas.
func _make_mask(col: Color) -> Node3D:
	var root := Node3D.new()
	var face := Fx.lit(col.darkened(0.35), 0.4)
	var bone := Fx.lit(Color(0.92, 0.88, 0.75), 0.5)
	var gold := Fx.unshaded(Color(2.0, 1.5, 0.5))
	_part(root, _sphere(0.75, 0.62), Vector3.ZERO, Vector3.ZERO, face, Vector3(1.0, 1.05, 0.62))
	_part(root, _sphere(0.22, 0.2), Vector3(0, -0.05, 0.45), Vector3.ZERO, face)  # nariz
	_part(root, BoxMesh.new(), Vector3(0, 0.38, 0.4), Vector3(-10, 0, 0), Fx.lit(Color(0.08, 0.06, 0.08)), Vector3(0.9, 0.12, 0.12))  # sobrancelha
	for s in [-1, 1]:
		_part(root, _cone(0.16, 0.8), Vector3(0.45 * s, 0.85, 0.0), Vector3(-10, 0, -28 * s), bone)
		_part(root, _sphere(0.11, 0.08), Vector3(0.26 * s, 0.2, 0.42), Vector3.ZERO, gold)
		_part(root, _cone(0.07, 0.22), Vector3(0.22 * s, -0.42, 0.38), Vector3(180, 0, 0), bone)
	return root


func _part(root: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3, mat: Material, esc := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = esc
	root.add_child(mi)


func _sphere(r: float, h: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h * 2.0
	m.radial_segments = 14
	m.rings = 7
	return m


func _cone(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 8
	return m


func _physics_process(delta: float) -> void:
	match state:
		State.CARRIED:
			if carrier == null or not carrier.alive:
				drop(global_position)
			else:
				global_position = carrier.global_position + Vector3(0, 1.4, 0)
				_visual.rotation.y = carrier.get_node("Visual").rotation.y
		State.DROPPED:
			_drop_t -= delta
			rescue_progress = maxf(rescue_progress - delta * 0.5, 0.0)
			if _drop_t <= 0.0:
				return_home()
		State.HOME:
			_visual.rotation.y += delta * 0.3
	_t += delta
	_mask.position.y = 1.6 + sin(_t * 2.0) * 0.12 if state != State.CARRIED else 1.0
	_spirits.position.y = _mask.position.y
	_spirits.rotation.y += delta * 2.2


func can_be_taken() -> bool:
	return state != State.CARRIED


func pick_up(unit: Unit) -> void:
	carrier = unit
	state = State.CARRIED
	global_position = unit.global_position + Vector3(0, 1.4, 0)
	reset_physics_interpolation()  # teleporte: não "deslizar" do pedestal até o carregador
	_beacon.visible = true
	state_changed.emit(self)


func drop(at: Vector3) -> void:
	carrier = null
	state = State.DROPPED
	_drop_t = Config.cfg.princess_return_time
	rescue_progress = 0.0
	var p := _game.arena.clamp_to_arena(at)
	p.y = _game.arena.ground_y(p.x, p.z, at.y + 0.5)
	global_position = p
	reset_physics_interpolation()
	_visual.rotation.y = 0
	_beacon.visible = true
	state_changed.emit(self)


func rescue(delta: float) -> void:
	rescue_progress += delta * 1.5  # compensa o decaimento em _physics_process
	if rescue_progress >= Config.cfg.princess_rescue_time:
		return_home()


func return_home() -> void:
	rescue_progress = 0.0
	if carrier:
		carrier.carried_princess = null
	carrier = null
	state = State.HOME
	global_position = home
	reset_physics_interpolation()
	_beacon.visible = false
	Fx.ring(_game, home, Config.team_color(team), 3.0)
	state_changed.emit(self)


## Prende mais um espírito na máscara. Retorna false se já está no peso máximo.
func feed() -> bool:
	if fatness >= 1.0:
		return false
	fatness = minf(fatness + Config.cfg.fat_per_cake, 1.0)
	_apply_fatness()
	Fx.burst(_game, global_position + Vector3(0, 1.6, 0), Color(0.5, 1.0, 0.6), 18, 6.0)
	Fx.ring(_game, global_position, Color(0.5, 1.0, 0.6, 0.8), 2.5)
	Sfx.play("magic", global_position)
	state_changed.emit(self)
	return true


## Peso visível: um espírito orbitando por "carga" e a máscara crescendo.
func _apply_fatness() -> void:
	for c in _spirits.get_children():
		c.queue_free()
	var n := int(round(fatness / maxf(Config.cfg.fat_per_cake, 0.01)))
	for i in n:
		var a := TAU * i / maxf(n, 1)
		var w := Cake.make_visual(0.55)
		w.position = Vector3(cos(a) * 1.25, 0.2 * sin(a * 3.0), sin(a) * 1.25)
		_spirits.add_child(w)
	var k := 1.0 + fatness * 0.6
	var tw := create_tween()
	tw.tween_property(_mask, "scale", Vector3.ONE * k, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func state_text() -> String:
	match state:
		State.HOME:
			return "no castelo"
		State.CARRIED:
			return "ROUBADA!"
		_:
			return "caída no chão"

