class_name Cake
extends Node3D
## Espírito solto no mapa (hitodama, chama-fantasma; o nome Cake ficou do
## protótipo). Quem encosta pega; levando até a própria máscara, ele fica
## preso nela e a deixa mais pesada para o inimigo carregar.


static var _mats: Array = []


static func make_visual(s := 1.0) -> Node3D:
	if _mats.is_empty():
		_mats = [Fx.unshaded(Color(0.45, 1.6, 0.7)), Fx.unshaded(Color(1.4, 2.0, 1.5))]
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.42 * s
	sp.height = 0.84 * s
	sp.radial_segments = 10
	sp.rings = 5
	body.mesh = sp
	body.material_override = _mats[0]
	body.position.y = 0.4 * s
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(body)
	var tail := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.36 * s
	c.height = 0.75 * s
	c.radial_segments = 8
	tail.mesh = c
	tail.material_override = _mats[0]
	tail.position.y = 0.95 * s
	tail.rotation_degrees.z = 18
	tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tail)
	var core := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.2 * s
	cs.height = 0.4 * s
	core.mesh = cs
	core.material_override = _mats[1]
	core.position = Vector3(0, 0.45 * s, 0.25 * s)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	return root


var _visual: Node3D
var _t := randf() * TAU


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado em _process
	_visual = make_visual(1.0)
	add_child(_visual)
	var glow := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.0
	glow.mesh = ring
	glow.scale = Vector3(1, 0.05, 1)
	glow.position.y = 0.05
	glow.material_override = Fx.unshaded(Color(0.5, 1.0, 0.6, 0.6), true)
	add_child(glow)
	scale = Vector3.ONE * 0.01
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * 1.5
	_visual.position.y = 0.25 + sin(_t * 3.0) * 0.12
