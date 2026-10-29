class_name Pickup
extends Node3D
## Item no chão (power-up). Quem encosta pega na hora:
##   pocao      -> cura parte da vida
##   escudo     -> bolha que absorve dano
##   velocidade -> corre mais por alguns segundos
##   dano       -> dano multiplicado por alguns segundos
##   medidor    -> enche o medidor do poder na hora
## Números em game_config.tres > Itens no chão.

const KINDS := ["pocao", "escudo", "velocidade", "dano", "medidor"]
const COLORS := {"pocao": Color(1.0, 0.3, 0.4), "escudo": Color(0.35, 0.85, 1.0), "velocidade": Color(1.0, 0.85, 0.2),
		"dano": Color(1.0, 0.15, 0.1), "medidor": Color(0.85, 0.4, 1.0)}
const NAMES := {"pocao": "Poção", "escudo": "Escudo", "velocidade": "Velocidade", "dano": "Dano dobrado", "medidor": "Poder cheio"}

var kind := "pocao"
var _visual: Node3D
var _t := randf() * TAU


func setup(p_kind: String, pos: Vector3) -> void:
	kind = p_kind
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado em _process
	var col: Color = COLORS[kind]
	_visual = Node3D.new()
	add_child(_visual)
	var body := MeshInstance3D.new()
	match kind:
		"pocao":
			var sp := SphereMesh.new()
			sp.radius = 0.38
			sp.height = 0.76
			body.mesh = sp
			var neck := MeshInstance3D.new()
			var n := CylinderMesh.new()
			n.top_radius = 0.1
			n.bottom_radius = 0.12
			n.height = 0.28
			neck.mesh = n
			neck.material_override = Fx.lit(Color(0.9, 0.9, 0.95), 0.2)
			neck.position.y = 0.45
			_visual.add_child(neck)
		"escudo":
			var c := CylinderMesh.new()
			c.top_radius = 0.48
			c.bottom_radius = 0.48
			c.height = 0.12
			body.mesh = c
			body.rotation_degrees.x = 90
		"dano":
			# Kunai cruzadas
			var k := BoxMesh.new()
			k.size = Vector3(0.12, 0.9, 0.05)
			body.mesh = k
			body.rotation_degrees.z = 35
			var k2 := MeshInstance3D.new()
			k2.mesh = k
			k2.rotation_degrees.z = -35
			k2.material_override = Fx.unshaded(Color(1.0, 0.15, 0.1) * 1.6)
			_visual.add_child(k2)
		"medidor":
			# Chama-fantasma (hitodama): esfera + ponta
			var sp := SphereMesh.new()
			sp.radius = 0.32
			sp.height = 0.64
			body.mesh = sp
			var tip := MeshInstance3D.new()
			var tc := CylinderMesh.new()
			tc.top_radius = 0.0
			tc.bottom_radius = 0.28
			tc.height = 0.55
			tip.mesh = tc
			tip.position.y = 0.4
			tip.material_override = Fx.unshaded(Color(0.85, 0.4, 1.0) * 1.5)
			_visual.add_child(tip)
		_:
			var p := CylinderMesh.new()  # prisma de 3 lados: um "raio"
			p.top_radius = 0.0
			p.bottom_radius = 0.35
			p.height = 0.9
			p.radial_segments = 3
			body.mesh = p
			body.rotation_degrees.z = 25
	var mat := Fx.unshaded(col * 1.5)
	body.material_override = mat
	_visual.add_child(body)
	var glow := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.75
	ring.outer_radius = 0.95
	glow.mesh = ring
	glow.scale = Vector3(1, 0.05, 1)
	glow.position.y = 0.05
	glow.material_override = Fx.unshaded(Color(col, 0.7), true)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glow)
	scale = Vector3.ONE * 0.01
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * 2.0
	_visual.position.y = 0.9 + sin(_t * 3.0) * 0.15


## Aplica o efeito em quem pegou.
func apply_to(u: Unit) -> void:
	var cfg := Config.cfg
	match kind:
		"pocao":
			u.heal(u.max_hp() * cfg.pickup_heal)
		"escudo":
			u.give_shield(cfg.pickup_shield, cfg.pickup_shield_time)
		"velocidade":
			u.give_boost(cfg.pickup_speed_mult, cfg.pickup_speed_time)
		"dano":
			u.give_damage_boost(cfg.pickup_damage_time)
		"medidor":
			u.fill_power()
	u.play_gesture("Interact", 1.8)
	Fx.burst(u.game, global_position + Vector3(0, 0.9, 0), COLORS[kind], 14, 6.0)
	Fx.ring(u.game, u.global_position, Color(COLORS[kind], 0.8), 2.0)
	Sfx.play("power_ready", global_position, 0.05)
	if u.is_player:
		u.game.hud.show_big(NAMES[kind] + "!", COLORS[kind], 1.0)
