class_name Cake
extends Node3D
## Bolo no chão. Quem encosta pega; levando até a própria princesa, ela come
## e engorda.


static func make_visual(s := 1.0) -> Node3D:
	var root := Node3D.new()
	var sponge := MeshInstance3D.new()
	var c1 := CylinderMesh.new()
	c1.top_radius = 0.6 * s
	c1.bottom_radius = 0.6 * s
	c1.height = 0.45 * s
	sponge.mesh = c1
	sponge.material_override = Fx.lit(Color(0.96, 0.82, 0.6))
	sponge.position.y = 0.22 * s
	root.add_child(sponge)
	var icing := MeshInstance3D.new()
	var c2 := CylinderMesh.new()
	c2.top_radius = 0.64 * s
	c2.bottom_radius = 0.64 * s
	c2.height = 0.14 * s
	icing.mesh = c2
	icing.material_override = Fx.lit(Color(1.0, 0.5, 0.72), 0.3)
	icing.position.y = 0.5 * s
	root.add_child(icing)
	var cherry := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.12 * s
	sp.height = 0.24 * s
	cherry.mesh = sp
	cherry.material_override = Fx.lit(Color(0.85, 0.05, 0.15), 0.2)
	cherry.position.y = 0.66 * s
	root.add_child(cherry)
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
	glow.material_override = Fx.unshaded(Color(1, 0.6, 0.8, 0.7), true)
	add_child(glow)
	scale = Vector3.ONE * 0.01
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * 1.5
	_visual.position.y = 0.25 + sin(_t * 3.0) * 0.12
