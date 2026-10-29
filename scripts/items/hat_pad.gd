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
	label.font = Estilo.FORTE
	label.font_size = 48
	label.pixel_size = 0.012
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.6
	label.modulate = stats.hat_color.lightened(0.3)
	add_child(label)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # chapéu animado em _process
	_hat = make_hat(stats.hat_style, stats.hat_color)
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


## Chapéus montados com formas simples: elmo, capuz, kasa e chapéu pontudo.
static func make_hat(style: String, color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := Fx.lit(color, 0.4)
	match style:
		"elmo":
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
		"kasa":
			# Chapéu de palha cônico (kasa), largo e baixo.
			var kasa := MeshInstance3D.new()
			var k := CylinderMesh.new()
			k.top_radius = 0.05
			k.bottom_radius = 0.8
			k.height = 0.4
			k.radial_segments = 12
			kasa.mesh = k
			kasa.material_override = mat
			root.add_child(kasa)
			var knot := MeshInstance3D.new()
			var kn := SphereMesh.new()
			kn.radius = 0.09
			kn.height = 0.18
			knot.mesh = kn
			knot.material_override = Fx.lit(Color(0.55, 0.3, 0.15))
			knot.position.y = 0.22
			root.add_child(knot)
		"kabuto":
			_add(root, _sph(0.5, 0.35), Vector3.ZERO, Vector3.ZERO, mat)
			_add(root, _cyl(0.62, 0.66, 0.06), Vector3(0, -0.05, 0), Vector3.ZERO, Fx.lit(Color(0.08, 0.08, 0.12)))
			for s in [-1, 1]:
				_add(root, _cyl(0.0, 0.08, 0.55), Vector3(0.22 * s, 0.4, 0.2), Vector3(-25, 0, -35 * s), Fx.unshaded(Color(1, 0.8, 0.3)))
		"faixa", "hachimaki":
			_add(root, _cyl(0.45, 0.45, 0.12), Vector3.ZERO, Vector3.ZERO, Fx.unshaded(color) if style == "faixa" else mat)
			for s in [-1, 1]:
				_add(root, BoxMesh.new(), Vector3(0.12 * s, -0.2, -0.5), Vector3(55, 0, 15 * s), mat, Vector3(0.08, 0.5, 0.03))
		"mascara_oni":
			_add(root, _sph(0.42, 0.36), Vector3.ZERO, Vector3.ZERO, Fx.lit(Color(0.6, 0.06, 0.08)), Vector3(1, 1, 0.7))
			for s in [-1, 1]:
				_add(root, _cyl(0.0, 0.09, 0.45), Vector3(0.25 * s, 0.4, 0), Vector3(0, 0, -25 * s), Fx.lit(Color(0.92, 0.88, 0.75)))
				_add(root, _sph(0.06, 0.05), Vector3(0.14 * s, 0.08, 0.28), Vector3.ZERO, Fx.unshaded(Color(1, 0.8, 0.3)))
		"eboshi":
			_add(root, _cyl(0.24, 0.36, 0.8), Vector3(0, 0.2, 0), Vector3(-12, 0, 0), Fx.lit(Color(0.05, 0.05, 0.08)), Vector3(1, 1, 0.7))
			for i in 3:
				var a := TAU * i / 3.0
				_add(root, BoxMesh.new(), Vector3(cos(a) * 0.6, 0.1, sin(a) * 0.6), Vector3(0, -rad_to_deg(a) + 90, 0), Fx.unshaded(Color(0.9, 0.95, 1.0)), Vector3(0.14, 0.3, 0.01))
		"orelhas":
			var white := Fx.lit(Color(0.95, 0.94, 0.9))
			_add(root, _sph(0.4, 0.34), Vector3.ZERO, Vector3.ZERO, white, Vector3(1, 1, 0.75))
			_add(root, _cyl(0.0, 0.14, 0.3), Vector3(0, -0.1, 0.32), Vector3(90, 0, 0), white)
			for s in [-1, 1]:
				_add(root, _cyl(0.0, 0.13, 0.35), Vector3(0.26 * s, 0.4, 0), Vector3(0, 0, -15 * s), white)
				_add(root, BoxMesh.new(), Vector3(0.15 * s, 0.1, 0.31), Vector3(0, 0, -20 * s), Fx.unshaded(Color(1, 0.15, 0.2)), Vector3(0.16, 0.04, 0.02))
			_add(root, _sph(0.12, 0.14), Vector3(0.6, 0.2, 0), Vector3.ZERO, Fx.unshaded(color))
		"cesto":
			_add(root, _cyl(0.42, 0.3, 0.6), Vector3.ZERO, Vector3.ZERO, Fx.lit(Color(0.6, 0.45, 0.22)))
			for i in 5:
				var a := TAU * i / 5.0
				_add(root, _cyl(0.0, 0.06, 0.4), Vector3(cos(a) * 0.2, 0.45, sin(a) * 0.2), Vector3(sin(a) * 25, 0, -cos(a) * 25), Fx.lit(Color(0.6, 0.65, 0.75)))
		"barril":
			_add(root, _cyl(0.38, 0.38, 0.75), Vector3.ZERO, Vector3.ZERO, Fx.lit(Color(0.42, 0.26, 0.13)))
			for y in [-0.25, 0.25]:
				_add(root, _cyl(0.4, 0.4, 0.06), Vector3(0, y, 0), Vector3.ZERO, Fx.lit(Color(0.15, 0.15, 0.18)))
			_add(root, _sph(0.08, 0.08), Vector3(0.05, 0.55, 0), Vector3.ZERO, Fx.unshaded(Color(1, 0.5, 0.1)))
		"capuz":
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


static func _add(root: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3, mat: Material, esc := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = esc
	root.add_child(mi)


static func _sph(r: float, h: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m


static func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 12
	m.rings = 1
	return m
