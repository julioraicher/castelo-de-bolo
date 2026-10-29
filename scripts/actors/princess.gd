class_name Princess
extends Node3D
## A princesa de um time. Fica no pedestal do próprio castelo até um inimigo
## carregá-la. Cada bolo que ela come aumenta `fatness` (0..1), o que deixa
## quem a carrega mais lento.

signal state_changed(princess: Princess)

enum State { HOME, CARRIED, DROPPED }

const MODEL := preload("res://assets/characters/Rogue.glb")
const BODY_PARTS := ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_LegLeft", "Rogue_LegRight"]
const DRESS_COLOR := Color(1.0, 0.55, 0.78)

var team := 0
var state := State.HOME
var fatness := 0.0
var carrier: Unit = null
var home: Vector3

var _game: Game
var _visual: Node3D
var _anim: AnimationPlayer
var _drop_t := 0.0
## Progresso do resgate (0..RESCUE_TIME) quando um aliado fica ao lado dela caída.
var rescue_progress := 0.0
const RESCUE_TIME := 1.5
var _beacon: MeshInstance3D


func setup(game: Game, p_team: int, p_home: Vector3) -> void:
	_game = game
	team = p_team
	home = p_home
	global_position = home
	_visual = Node3D.new()
	add_child(_visual)
	var model: Node3D = MODEL.instantiate()
	_visual.add_child(model)
	var dress := Fx.lit(DRESS_COLOR, 0.5)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.visible = BODY_PARTS.has(mi.name) or mi.name == "Rogue_Head"
		if BODY_PARTS.has(mi.name):
			mi.material_override = dress
	# Saia (cone) e coroa feitas com formas simples.
	var skirt := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.42
	cone.bottom_radius = 0.95
	cone.height = 0.95
	skirt.mesh = cone
	skirt.material_override = dress
	skirt.position.y = 0.62
	_visual.add_child(skirt)
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	var crown := _make_crown()
	if skeleton:
		var attach := BoneAttachment3D.new()
		attach.bone_name = "head"
		skeleton.add_child(attach)
		attach.add_child(crown)
		crown.position = Vector3(0, 1.05, 0)
	else:
		crown.position.y = 2.3
		_visual.add_child(crown)
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for a in ["Idle", "Sit_Floor_Idle", "Cheer", "Lie_Idle"]:
		if _anim and _anim.has_animation(a):
			_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	_play("Idle")
	# Facho de luz vertical na cor do time: dá para achar a princesa de longe.
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


func _make_crown() -> Node3D:
	var crown := Node3D.new()
	var gold := Fx.lit(Color(1.0, 0.8, 0.2), 0.25)
	gold.metallic = 0.8
	var band := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.3
	cyl.height = 0.16
	band.mesh = cyl
	band.material_override = gold
	crown.add_child(band)
	for i in 5:
		var spike := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.08
		c.height = 0.2
		spike.mesh = c
		spike.material_override = gold
		var ang := TAU * i / 5.0
		spike.position = Vector3(cos(ang) * 0.29, 0.17, sin(ang) * 0.29)
		crown.add_child(spike)
	return crown


func _physics_process(delta: float) -> void:
	match state:
		State.CARRIED:
			if carrier == null or not carrier.alive:
				drop(global_position)
			else:
				global_position = carrier.global_position + Vector3(0, 2.2, 0)
				_visual.rotation.y = carrier.get_node("Visual").rotation.y + PI / 2
		State.DROPPED:
			_drop_t -= delta
			rescue_progress = maxf(rescue_progress - delta * 0.5, 0.0)
			if _drop_t <= 0.0:
				return_home()
		State.HOME:
			_visual.rotation.y += delta * 0.3


func can_be_taken() -> bool:
	return state != State.CARRIED


func pick_up(unit: Unit) -> void:
	carrier = unit
	state = State.CARRIED
	global_position = unit.global_position + Vector3(0, 2.2, 0)
	reset_physics_interpolation()  # teleporte: não "deslizar" do pedestal até o carregador
	_beacon.visible = true
	_play("Sit_Floor_Idle")
	state_changed.emit(self)


func drop(at: Vector3) -> void:
	carrier = null
	state = State.DROPPED
	_drop_t = Config.cfg.princess_return_time
	rescue_progress = 0.0
	global_position = _game.arena.clamp_to_arena(Vector3(at.x, 0, at.z))
	reset_physics_interpolation()
	_visual.rotation.y = 0
	_beacon.visible = true
	_play("Idle")
	state_changed.emit(self)


func rescue(delta: float) -> void:
	rescue_progress += delta * 1.5  # compensa o decaimento em _physics_process
	if rescue_progress >= RESCUE_TIME:
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
	_play("Idle")
	Fx.ring(_game, home, Config.team_color(team), 3.0)
	state_changed.emit(self)


## Alimenta a princesa. Retorna false se ela já está no peso máximo.
func feed() -> bool:
	if fatness >= 1.0:
		return false
	fatness = minf(fatness + Config.cfg.fat_per_cake, 1.0)
	_apply_fatness()
	_play("Cheer")
	Fx.burst(_game, global_position + Vector3(0, 1.5, 0), Color(1, 0.6, 0.8), 18, 6.0)
	Sfx.play("eat", global_position)
	get_tree().create_timer(1.2).timeout.connect(_back_to_idle)
	state_changed.emit(self)
	return true


func _back_to_idle() -> void:
	if state == State.HOME:
		_play("Idle")


func _apply_fatness() -> void:
	var w := 1.0 + fatness * 0.9
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(w * 1.15, 1.0 + fatness * 0.12, w * 1.15), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func state_text() -> String:
	match state:
		State.HOME:
			return "no castelo"
		State.CARRIED:
			return "SEQUESTRADA!"
		_:
			return "caída no chão"


func _play(anim_name: String) -> void:
	if _anim and _anim.has_animation(anim_name):
		_anim.play(anim_name, 0.2)
