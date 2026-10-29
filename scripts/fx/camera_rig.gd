class_name CameraRig
extends Camera3D
## Câmera 3/4 que segue o jogador com suavização exponencial e tremor
## ("screen shake") proporcional ao quadrado do trauma.

var target: Node3D
var _trauma := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0
var _focus := Vector3.ZERO


func _ready() -> void:
	fov = Config.cfg.camera_fov
	near = 0.5
	far = 300.0
	_noise.frequency = 2.0
	current = true


func snap() -> void:
	if target:
		_focus = target.global_position
		global_position = _focus + Config.cfg.camera_offset
		look_at(_focus + Vector3(0, 1, 0), Vector3.UP)


func add_trauma(amount: float) -> void:
	if not Settings.camera_shake:
		return
	_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if target == null:
		return
	_t += delta
	var cfg := Config.cfg
	# Adianta um pouco o foco na direção do mouse para ver mais à frente.
	var lead := (mouse_ground_point() - target.global_position)
	lead.y = 0
	var desired := target.global_position + lead.limit_length(12.0) / 12.0 * cfg.camera_lead
	# Suavização independente de FPS: 1 - e^(-k·dt).
	_focus = _focus.lerp(desired, 1.0 - exp(-cfg.camera_smooth * delta))
	var shake := _trauma * _trauma
	var offset := Vector3(_noise.get_noise_2d(_t * 40.0, 0.0), _noise.get_noise_2d(0.0, _t * 40.0), 0) * shake * 0.9
	global_position = _focus + cfg.camera_offset + offset
	look_at(_focus + Vector3(0, 1, 0) + offset, Vector3.UP)
	_trauma = maxf(_trauma - delta * 1.6, 0.0)


## Ponto do chão (plano y = 0) sob o cursor do mouse.
func mouse_ground_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := project_ray_origin(mouse)
	var dir := project_ray_normal(mouse)
	if absf(dir.y) < 0.001:
		return target.global_position if target else Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
