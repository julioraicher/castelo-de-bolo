class_name CameraRig
extends Camera3D
## Câmera 3/4 que segue o jogador com suavização exponencial e tremor
## ("screen shake") proporcional ao quadrado do trauma, mais um "coice"
## direcional (mola amortecida) e um soco de zoom (FOV) nos golpes fortes.

var target: Node3D
var _trauma := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0
var _focus := Vector3.ZERO
# Coice: oscilador harmônico amortecido x'' = −ω²x − 2ζωx' (ζ < 1: passa um
# pouco do ponto e volta, como um tranco de verdade).
const KICK_OMEGA := 38.0
const KICK_ZETA := 0.45
var _kick_x := Vector3.ZERO
var _kick_v := Vector3.ZERO
var _fov_punch := 0.0


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


## Coice na direção dir (do golpe): dá um "impulso" na mola da câmera.
func kick(dir: Vector3, strength: float) -> void:
	if not Settings.camera_shake:
		return
	dir.y = 0
	_kick_v += dir.normalized() * strength * 6.0


## Zoom rápido para dentro (graus de FOV) que volta sozinho.
func punch_fov(deg: float) -> void:
	if not Settings.camera_shake:
		return
	_fov_punch = maxf(_fov_punch, deg)


## Tremor de algo que aconteceu em pos (explosão, poder de bot): cai com a
## distância como 1/(1 + (d/8)²), parecido com a intensidade de uma onda.
func shake_at(pos: Vector3, amount: float) -> void:
	if target == null:
		return
	var d := pos.distance_to(target.global_position) / 8.0
	if d < 4.0:
		add_trauma(amount / (1.0 + d * d))


func _process(delta: float) -> void:
	if target == null:
		return
	# A câmera usa o tempo real: o tranco não fica em câmera lenta junto com o jogo.
	delta = delta / maxf(Engine.time_scale, 0.05)
	_t += delta
	# Euler semi-implícito só é estável com ω·dt < 2: a 10 FPS (dt = 0,1 s,
	# ω·dt = 3,8) a mola explodia. Por isso integra em passos de até 8 ms.
	var steps := clampi(ceili(delta / 0.008), 1, 25)
	var h := minf(delta, 0.2) / steps
	for i in steps:
		var acc := -KICK_OMEGA * KICK_OMEGA * _kick_x - 2.0 * KICK_ZETA * KICK_OMEGA * _kick_v
		_kick_v += acc * h
		_kick_x += _kick_v * h
	_kick_x = _kick_x.limit_length(1.5)
	_fov_punch = move_toward(_fov_punch, 0.0, delta * 30.0)
	fov = Config.cfg.camera_fov - _fov_punch
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
	offset += _kick_x
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
