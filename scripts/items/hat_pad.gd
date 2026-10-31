class_name HatPad
extends Node3D
## Maquininha de chapéu no castelo (Ciclo 2.3). Pegar o chapéu troca a classe
## da unidade e tira 1 do estoque. A máquina fabrica 1 chapéu a cada
## `maquina_intervalo` s enquanto o estoque está abaixo de `maquina_estoque_max`,
## e começa cheia. Estoque zero = "acabou o seu favorito": joga de outra coisa.
##
## Modelo do tema (ThemeConfig.maquina_model): peças "Gira_*" giram enquanto
## fabrica (relógio do pintura.gdshader), o chapéu aparece no nó "Molde" e a
## animação "fabricar" toca quando um chapéu fica pronto. Sem modelo: pedestal.

var team := 0
var stats: ClassStats
var available := true
var estoque := 0
var estoque_max := 3
var intervalo := 20.0

var _hat: Node3D
var _hat_y := 1.2
var _fab_t := 0.0
var _t := randf() * TAU
var _label: Label3D
var _anim: AnimationPlayer
var _mats_gira: Array[ShaderMaterial] = []
var _relogio := 0.0


func setup(p_team: int, p_stats: ClassStats, pos: Vector3) -> void:
	team = p_team
	stats = p_stats
	position = pos
	estoque_max = Config.cfg.maquina_estoque_max
	intervalo = Config.cfg.maquina_intervalo
	estoque = estoque_max
	var molde: Node3D = self
	var th: ThemeConfig = Config.theme()
	if th.maquina_model:
		var m: Node3D = th.maquina_model.instantiate()
		add_child(m)
		# A máquina olha para o centro do pátio (o lado de onde se chega).
		m.rotation.y = 0.0 if team == Config.TEAM_BLUE else PI
		var no := m.find_child("Molde", true, false) as Node3D
		if no:
			molde = no
			_hat_y = 0.0
		_anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_preparar_gira(m)
	else:
		var base := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.0
		cyl.bottom_radius = 1.2
		cyl.height = 0.5
		base.mesh = cyl
		base.material_override = Fx.lit(Color(0.55, 0.55, 0.6))
		base.position.y = 0.25
		add_child(base)
	_label = Label3D.new()
	_label.font = Estilo.FORTE
	_label.font_size = 48
	_label.pixel_size = 0.012
	_label.outline_size = 10
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.6
	_label.modulate = stats.hat_color.lightened(0.3)
	add_child(_label)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # chapéu animado em _process
	_hat = make_hat(stats.hat_style, stats.hat_color)
	_hat.position.y = _hat_y
	molde.add_child(_hat)
	_atualizar()


## Peças "Gira_*" ganham material próprio: o relógio é desta máquina.
func _preparar_gira(m: Node3D) -> void:
	for mi: MeshInstance3D in m.find_children("Gira_*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as ShaderMaterial
			if mat == null:
				continue
			var c: ShaderMaterial = mat.duplicate()
			if mat.next_pass is ShaderMaterial:
				c.next_pass = mat.next_pass.duplicate()
				_mats_gira.append(c.next_pass)
			mi.set_surface_override_material(s, c)
			_mats_gira.append(c)


func _process(delta: float) -> void:
	_t += delta
	_hat.rotation.y += delta * 1.8
	_hat.position.y = _hat_y + sin(_t * 2.5) * 0.15
	if not _mats_gira.is_empty():
		_relogio += delta * (1.0 if estoque < estoque_max else 0.15)
		for m in _mats_gira:
			m.set_shader_parameter("relogio", _relogio)


func _physics_process(delta: float) -> void:
	avancar(delta)


## Relógio da fábrica (separado do _physics_process para os testes).
func avancar(delta: float) -> void:
	if estoque >= estoque_max:
		_fab_t = 0.0
		return
	_fab_t += delta
	if _fab_t >= intervalo:
		_fab_t -= intervalo
		estoque += 1
		_fabricou()
	_atualizar()


func _fabricou() -> void:
	if _anim and _anim.has_animation("fabricar"):
		_anim.stop()
		_anim.play("fabricar")
	if estoque == 1:
		_hat.visible = true
		_hat.scale = Vector3.ONE * 0.01
		create_tween().tween_property(_hat, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_inside_tree():
		Fx.burst(self, global_position + Vector3(0, 1.4, 0), Color(0.95, 0.95, 0.9), 6, 2.5)


func _atualizar() -> void:
	available = estoque > 0
	_hat.visible = available
	var txt := "%s  %d/%d" % [stats.display_name, estoque, estoque_max]
	if estoque < estoque_max:
		txt += "\n%ds" % ceili(intervalo - _fab_t)
	if _label.text != txt:
		_label.text = txt
	_label.modulate = stats.hat_color.lightened(0.3) if available else Color(0.7, 0.7, 0.7, 0.8)


## Posição do chapéu flutuante no mundo (de onde ele "sai" ao ser pego).
func hat_world_position() -> Vector3:
	return _hat.global_position


func take() -> ClassStats:
	estoque = maxi(estoque - 1, 0)
	_atualizar()
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
