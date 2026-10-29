class_name HatPad
extends Node3D
## Pedestal de chapéu no castelo. Pegar o chapéu troca a classe da unidade.
## Depois de pego, um chapéu novo aparece após `hat_respawn_time` segundos.

var team := 0
var stats: ClassStats
var available := true

var _hat: Node3D
var _respawn_t := 0.0
var _t := randf() * TAU


func setup(p_team: int, p_stats: ClassStats, pos: Vector3) -> void:
	team = p_team
	stats = p_stats
	position = pos
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.2
	cyl.height = 0.5
	base.mesh = cyl
	base.material_override = Fx.lit(Color(0.55, 0.55, 0.6))
	base.position.y = 0.25
	add_child(base)
	var label := Label3D.new()
	label.text = stats.display_name
	label.font_size = 48
	label.pixel_size = 0.012
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.6
	label.modulate = stats.hat_color.lightened(0.3)
	add_child(label)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # chapéu animado em _process
	_hat = make_hat(stats.id, stats.hat_color)
	_hat.position.y = 1.2
	add_child(_hat)


func _process(delta: float) -> void:
	_t += delta
	_hat.rotation.y += delta * 1.8
	_hat.position.y = 1.2 + sin(_t * 2.5) * 0.15
	if not available:
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			available = true
			_hat.visible = true
			_hat.scale = Vector3.ONE * 0.01
			create_tween().tween_property(_hat, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Posição do chapéu flutuante no mundo (de onde ele "sai" ao ser pego).
func hat_world_position() -> Vector3:
	return _hat.global_position


func take() -> ClassStats:
	available = false
	_hat.visible = false
	_respawn_t = Config.cfg.hat_respawn_time
	return stats


## Chapéus montados com formas simples: elmo, capuz e chapéu de clérigo.
static func make_hat(id: StringName, color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := Fx.lit(color, 0.4)
	match id:
		&"guerreiro":
			mat.metallic = 0.7
			var dome := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 0.7
			sp.is_hemisphere = true
			dome.mesh = sp
			dome.material_override = mat
			root.add_child(dome)
			var plume := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.05
			pc.bottom_radius = 0.12
			pc.height = 0.5
			plume.mesh = pc
			plume.material_override = Fx.lit(Color(0.9, 0.15, 0.15))
			plume.position = Vector3(0, 0.55, -0.1)
			plume.rotation_degrees.x = -25
			root.add_child(plume)
		&"arqueiro":
			var hood := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.55
			cone.height = 0.7
			hood.mesh = cone
			hood.material_override = mat
			hood.rotation_degrees.x = -20
			root.add_child(hood)
			var feather := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.06, 0.6, 0.15)
			feather.mesh = box
			feather.material_override = Fx.lit(Color(0.95, 0.85, 0.3))
			feather.position = Vector3(0.35, 0.25, 0)
			feather.rotation_degrees.z = -30
			root.add_child(feather)
		_:
			var brim := MeshInstance3D.new()
			var b := CylinderMesh.new()
			b.top_radius = 0.75
			b.bottom_radius = 0.75
			b.height = 0.06
			brim.mesh = b
			brim.material_override = mat
			root.add_child(brim)
			var top := MeshInstance3D.new()
			var t := CylinderMesh.new()
			t.top_radius = 0.0
			t.bottom_radius = 0.42
			t.height = 1.0
			top.mesh = t
			top.material_override = mat
			top.position.y = 0.5
			root.add_child(top)
			var band := MeshInstance3D.new()
			var bd := CylinderMesh.new()
			bd.top_radius = 0.4
			bd.bottom_radius = 0.43
			bd.height = 0.12
			band.mesh = bd
			band.material_override = Fx.lit(Color(1.0, 0.8, 0.25), 0.3)
			band.position.y = 0.1
			root.add_child(band)
	return root
