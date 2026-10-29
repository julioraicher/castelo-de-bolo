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
	# A câmera se move em _process (a cada quadro da tela), então não deve ser
	# interpolada; ela segue a posição INTERPOLADA do alvo (ver _target_pos).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


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
	var target_pos := target.get_global_transform_interpolated().origin
	var lead := (mouse_ground_point() - target_pos)
	lead.y = 0
	var desired := target_pos + lead.limit_length(12.0) / 12.0 * cfg.camera_lead
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
	# Primeiro o que o mouse aponta de verdade (muralha, ponte, colina)...
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 300.0, Config.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		return hit.position
	# ...senão o plano do chão.
	if absf(dir.y) < 0.001:
		return target.global_position if target else Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
