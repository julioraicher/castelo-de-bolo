class_name Fx
extends RefCounted
## Efeitos visuais pequenos e reutilizáveis ("game feel"): números de dano,
## faíscas de impacto, anel de cura, rastro de golpe. Funções estáticas: Fx.damage_number(...).

static var _sector_cache := {}  # "raio_arco" -> ArrayMesh do rastro de golpe
static var _cache := {}  # malhas de partícula já prontas (com material), por tipo + cor


## Recurso reaproveitado: cria uma vez com maker e devolve o mesmo nas próximas.
## Partículas não animam o material, então todas as do mesmo tipo e cor podem
## dividir malha e material (menos alocação e nenhum shader novo no meio da luta).
static func cached(key: String, maker: Callable) -> Resource:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]


## Esquenta os shaders dos efeitos: desenha cada tipo uma vez, escondido
## embaixo do chão, no começo da partida. No navegador (WebGL) cada material
## novo compila um shader na primeira vez que aparece, e isso travava o jogo
## por um instante no primeiro golpe, no primeiro poder etc.
static func prewarm(parent: Node, pos: Vector3) -> void:
	var p := pos + Vector3(0, -6.0, 0)
	burst(parent, p, Color(1, 0.85, 0.5), 2, 1.0)
	ring(parent, p, Color(1, 1, 1, 0.5), 1.0)
	slash(parent, p, Vector3.FORWARD, 2.0, 120.0, Color.WHITE)
	pillar(parent, p, Color(1, 0.9, 0.5), 1.0)
	beam(parent, p, p + Vector3(1, 0, 0), Color(0.6, 1, 1))
	var bolha := MeshInstance3D.new()
	bolha.mesh = SphereMesh.new()
	bolha.material_override = bubble(Color(1, 0.85, 0.4))
	parent.add_child(bolha)
	bolha.global_position = p
	parent.get_tree().create_timer(0.5).timeout.connect(bolha.queue_free)


static func damage_number(parent: Node, pos: Vector3, text: String, color: Color) -> void:
	if not Settings.damage_numbers:
		return
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.outline_size = 10
	label.font = Estilo.NUMERO
	label.font_size = 64
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	parent.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.4, 0.4), 2.6, 0)
	var tw := label.create_tween().set_parallel()
	tw.tween_property(label, "global_position:y", label.global_position.y + 1.6, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)


static func burst(parent: Node, pos: Vector3, color: Color, amount := 14, speed := 6.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.mesh = cached("burst" + color.to_html(), func() -> Mesh:
		var mesh := SphereMesh.new()
		mesh.radius = 0.09
		mesh.height = 0.18
		mesh.radial_segments = 6
		mesh.rings = 3
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material = mat
		return mesh)
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func ring(parent: Node, pos: Vector3, color: Color, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	mi.mesh = torus
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.3, 0)
	mi.scale = Vector3.ONE * 0.3
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3.ONE * radius, 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(mi.queue_free)


## Rastro de um golpe: um setor de anel na direção dir, que some em 0,16 s.
## tilt inclina o corte (graus, em volta da direção do golpe); strong = maior.
static func slash(parent: Node, pos: Vector3, dir: Vector3, radius: float, arc_deg: float, color: Color, tilt := 0.0, strong := false) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _sector(radius, arc_deg)
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true  # o rastro fica por cima dos bonecos
	mat.render_priority = 2
	mat.albedo_color = Color(color, 0.95 if strong else 0.8)
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos
	mi.rotation = Vector3(0, atan2(dir.x, dir.z), deg_to_rad(tilt))
	if tilt < 0.0:
		mi.scale.x = -1.0  # espelha: o rastro vem do outro lado
	var s0 := 0.8 if strong else 0.85
	var s1 := 1.12 if strong else 1.02
	mi.scale = Vector3(signf(mi.scale.x) * s0, 1, s0)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(signf(mi.scale.x) * s1, 1, s1), 0.16).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2 if strong else 0.16).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)


static func _sector(radius: float, arc_deg: float) -> ArrayMesh:
	var key := "%d_%d" % [roundi(radius * 10.0), roundi(arc_deg)]
	if _sector_cache.has(key):
		return _sector_cache[key]
	var segs := 20 if arc_deg < 200.0 else 32
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var half := deg_to_rad(arc_deg) * 0.5
	for i in segs + 1:
		var u := float(i) / segs
		var a := -half + 2.0 * half * u
		var d := Vector3(sin(a), 0, cos(a))
		# Mais forte na ponta da frente do corte e na borda de fora.
		var lead := 0.25 + 0.75 * u * u if arc_deg < 359.0 else 0.8
		verts.append(d * radius * 0.35)
		cols.append(Color(1, 1, 1, 0.0))
		verts.append(d * radius)
		cols.append(Color(1, 1, 1, lead))
		if i < segs:
			var k := i * 2
			idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_sector_cache[key] = mesh
	return mesh


## Coluna de luz que sobe e some (Bênção do Monge), com anel no chão.
static func pillar(parent: Node, pos: Vector3, color: Color, radius: float) -> void:
	ring(parent, pos, Color(color, 0.9), radius)
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.6
	cyl.height = 9.0
	cyl.cap_top = false
	cyl.cap_bottom = false
	mi.mesh = cyl
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := unshaded(Color(color, 0.55), true)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 4.5, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(1.4, 1, 1.4), 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.7).set_delay(0.15)
	tw.chain().tween_callback(mi.queue_free)
	burst(parent, pos + Vector3(0, 1.5, 0), color, 24, 9.0)


## Bolha de escudo: brilha na borda e é quase invisível no meio (efeito
## Fresnel: quanto mais rasante o olhar, 1 − N·V maior).
static var _bubble_shader: Shader

static func bubble(color: Color) -> ShaderMaterial:
	if _bubble_shader == null:  # um Shader só para todos: compila uma vez
		_bubble_shader = Shader.new()
		_bubble_shader.code = _BUBBLE_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _bubble_shader
	mat.set_shader_parameter("tint", color)
	return mat


const _BUBBLE_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
uniform vec4 tint : source_color;
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	ALBEDO = tint.rgb;
	ALPHA = clamp(0.08 + rim * 0.9, 0.0, 1.0);
}
"""


static func unshaded(color: Color, transparent := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func lit(color: Color, roughness := 0.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat


## Raio reto entre dois pontos (Corte Relâmpago, Selo): caixa fina que some.
static func beam(parent: Node, from: Vector3, to: Vector3, color: Color, width := 0.25, life := 0.35) -> void:
	var d := to - from
	if d.length() < 0.05:
		return
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, width * 0.6, d.length())
	mi.mesh = box
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := unshaded(Color(color * 2.0, 0.95), true)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = from + d * 0.5
	mi.look_at(to, Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(0.1, 0.1, 1.0), life).set_ease(Tween.EASE_IN)
	tw.tween_property(mat, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(mi.queue_free)


## Choque elétrico: zigue-zague de raios curtos entre dois pontos.
static func zap(parent: Node, from: Vector3, to: Vector3, color: Color, segments := 5) -> void:
	var prev := from
	for i in range(1, segments + 1):
		var p := from.lerp(to, float(i) / segments)
		if i < segments:
			p += Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), randf_range(-0.5, 0.5))
		beam(parent, prev, p, color, 0.09, 0.22)
		prev = p


## Rachaduras brilhando no chão, saindo do centro (Fúria do Ronin).
static func cracks(parent: Node, pos: Vector3, color: Color, radius: float, count := 9) -> void:
	for i in count:
		var a := TAU * i / count + randf_range(-0.2, 0.2)
		var r := radius * randf_range(0.6, 1.0)
		var mid := pos + Vector3(cos(a), 0, sin(a)) * r * 0.5 + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		var end := pos + Vector3(cos(a), 0, sin(a)) * r
		for seg in [[pos, mid], [mid, end]]:
			beam(parent, seg[0] + Vector3(0, 0.06, 0), seg[1] + Vector3(0, 0.06, 0), color, 0.22, 1.1)
	ring(parent, pos, Color(color, 0.9), radius)
