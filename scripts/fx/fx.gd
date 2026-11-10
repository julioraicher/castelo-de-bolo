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
	FxProjetil.prewarm(parent, p)
	Magia.prewarm(parent, p)
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


## forca: 1 = golpe comum; > 1 = número maior e com mais "pop" (combo final,
## contra-golpe). dir: o número escorrega um pouco para onde o golpe empurrou.
static func damage_number(parent: Node, pos: Vector3, text: String, color: Color, forca := 1.0, dir := Vector3.ZERO) -> void:
	if not Settings.damage_numbers:
		return
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Estilo.TINTA
	label.outline_size = 16
	label.font = Estilo.NUMERO
	label.font_size = 64
	label.pixel_size = 0.0095 * clampf(0.85 + 0.2 * forca, 0.85, 1.35)  # um pouco menores (pedido do Julio)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	parent.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.4, 0.4), 2.6, 0)
	# "Pop": nasce grande e volta com sobra (TRANS_BACK), lê como impacto.
	label.scale = Vector3.ONE * (1.5 + 0.3 * forca)
	var tw := label.create_tween().set_parallel()
	tw.tween_property(label, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var fim := label.global_position + Vector3(0, 1.6, 0) + Vector3(dir.x, 0, dir.z).limit_length(1.0) * 0.6
	tw.tween_property(label, "global_position", fim, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)


## Estouro de faíscas: lascas esticadas pela velocidade (antes eram bolinhas).
static func burst(parent: Node, pos: Vector3, color: Color, amount := 14, speed := 6.0) -> void:
	FxProjetil.ps(parent, pos, FxProjetil.lasca(0.24, 0.05), Color(color, 1.0), amount, 0.45, {
		"dir": Vector3.UP, "spread": 70.0, "v0": speed * 0.5, "v1": speed, "g": Vector3(0, -14, 0),
		"alinha": true, "s0": 0.6, "s1": 1.2, "rampa": "quente" if color.v > 0.5 else "some",
	})


## Onda no chão: faixa de energia que abre até `radius` e se rasga (Magia).
static func ring(parent: Node, pos: Vector3, color: Color, radius: float) -> void:
	Magia.onda(parent, pos, Magia.paleta_de(color), radius, 0.42, {"y": 0.14})


## Rastro de um golpe: um setor de anel na direção dir, que some em 0,16 s.
## tilt inclina o corte (graus, em volta da direção do golpe); strong = maior.
static func slash(parent: Node, pos: Vector3, dir: Vector3, radius: float, arc_deg: float, color: Color, tilt := 0.0, strong := false) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _sector(radius, arc_deg)
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Corte de energia: fio claro perto da borda de fora, vento correndo ao
	# longo do arco e a cauda se rasgando (uma malha só; antes eram duas).
	var pal: Array = Magia.paleta("aco") if color.s < 0.15 else Magia.paleta_de(color)
	var mat := Magia.mat(pal, {
		"escala": Vector2(2.0, 0.7), "rola": Vector2(-3.0, 0.0), "forca": 0.7 if strong else 0.55,
		"base": 1.15, "topo": 1.15, "banda": 0.27 if strong else 0.2, "centro": 0.86, "tinta": 0.04,
	})
	mat.render_priority = 2
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos
	mi.rotation = Vector3(0, atan2(dir.x, dir.z), deg_to_rad(tilt))
	var sx := -1.0 if tilt < 0.0 else 1.0  # espelha: o rastro vem do outro lado
	var s0 := 0.8 if strong else 0.85
	var s1 := 1.12 if strong else 1.02
	mi.scale = Vector3(sx * s0, 1, s0)
	var vida := 0.3 if strong else 0.24
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(sx * s1, 1, s1), 0.16).set_ease(Tween.EASE_OUT)
	Magia._anim(tw, mat, "corroi", 0.0, 1.0, vida * 0.65).set_delay(vida * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)


static func _sector(radius: float, arc_deg: float, dentro := 0.35) -> ArrayMesh:
	var key := "%d_%d_%d" % [roundi(radius * 10.0), roundi(arc_deg), roundi(dentro * 100.0)]
	if _sector_cache.has(key):
		return _sector_cache[key]
	var segs := 20 if arc_deg < 200.0 else 32
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var half := deg_to_rad(arc_deg) * 0.5
	for i in segs + 1:
		var u := float(i) / segs
		var a := -half + 2.0 * half * u
		var d := Vector3(sin(a), 0, cos(a))
		# Mais forte na ponta da frente do corte e na borda de fora.
		var lead := 0.25 + 0.75 * u * u if arc_deg < 359.0 else 0.8
		verts.append(d * radius * dentro)
		cols.append(Color(1, 1, 1, lead))
		uvs.append(Vector2(u, 0.0))
		verts.append(d * radius)
		cols.append(Color(1, 1, 1, lead))
		uvs.append(Vector2(u, 1.0))
		if i < segs:
			var k := i * 2
			idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_sector_cache[key] = mesh
	return mesh


## Coluna de luz que sobe e some (Bênção do Monge), com anel no chão.
static func pillar(parent: Node, pos: Vector3, color: Color, radius: float) -> void:
	var ouro := color.r > 0.9 and color.g > 0.7 and color.b < 0.6
	var pal: Array = Magia.paleta("luz") if ouro else Magia.paleta_de(color)
	ring(parent, pos, color, radius)
	Magia.chama(parent, pos, pal, 1.15, 7.5, 0.8, {"r_topo": 0.7, "barriga": 0.0, "forca": 1.2, "base": 0.72, "topo": 0.05, "rola": Vector2(0.2, -2.2)})
	Magia.clarao(parent, pos, color, radius * 2.0 + 3.0)
	burst(parent, pos + Vector3(0, 1.5, 0), color, 24, 9.0)


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


## Marcação de interface no mundo (selo, emblema, mira): cada peça [Mesh,
## Transform3D] vira um MeshInstance3D sem sombra com o mesmo material.
static func montar_pecas(pai: Node3D, pecas: Array, mat: Material) -> void:
	# Numa malha só (Ciclo 2.19): as peças não se mexem entre si e dividem o
	# material, então o selo/emblema custa 1 chamada de desenho em vez de uma
	# por peça (medido: 48 só das torretas). O material segue compartilhado:
	# o dono pode animar a transparência dele que a malha acompanha.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in pecas:
		st.append_from(p[0], 0, p[1])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)


## Modelo gerado (pintura.gdshader + contorno de tinta no next_pass): abaixo da
## qualidade Alta, tira o contorno de cada superfície (cópia do material, o
## recurso original fica intacto para o próximo tema/partida).
static func tirar_contorno(raiz: Node) -> void:
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as ShaderMaterial
			if mat and mat.next_pass:
				var m: ShaderMaterial = mat.duplicate()
				m.next_pass = null
				mi.set_surface_override_material(s, m)


static func lit(color: Color, roughness := 0.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat


## Raio reto entre dois pontos (Corte Relâmpago, Selo): caixa fina que some.
static func beam(parent: Node, from: Vector3, to: Vector3, color: Color, width := 0.25, life := 0.35) -> void:
	Magia.lanca(parent, from, to, Magia.paleta_de(color), width * 2.2, life)


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
	var pal: Array = Magia.paleta("brasa") if color.r > 0.8 and color.b < 0.4 else Magia.paleta_de(color)
	Magia.rachaduras(parent, pos, pal, radius, count)
	ring(parent, pos, Color(color, 0.9), radius)
