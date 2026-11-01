class_name FxProjetil
extends RefCounted
## Efeitos de lançamento, rastro, impacto e reação (direção em
## docs/direcao-efeitos.md). Seis camadas por projétil: cor, forma, rastro,
## impacto, reação do alvo (só visual) e som.
##
## Custo: TUDO aqui é CPUParticles3D com malha e material em cache (uma
## draw call por sistema, nenhum material novo no meio da luta, nenhum tween).
## O sumiço vem da rampa de cor (alfa → 0) e o crescimento da curva de escala,
## então até o "decalque" no chão e o clarão em cruz são partículas.
## Orçamento por frequência (custo ∝ Σ disparos/s × partículas por disparo):
##   nível 1 (ataque básico): rastro ≤ 8 partículas vivas, impacto pequeno
##   nível 2 (Q, tiro carregado): rastro completo, impacto próprio, reação
##   nível 3 (E): tudo, com marca no chão e som cheio
## Na qualidade Mínima o rastro desliga e os impactos caem pela metade.

const COR_METAL := Color(0.78, 0.86, 0.95)
const COR_CIANO := Color(0.35, 1.0, 1.0)
const COR_OURO := Color(1.0, 0.68, 0.12)
const COR_RAPOSA := Color(0.95, 0.2, 0.6)
const COR_VAZIO := Color(0.55, 0.2, 1.0)
const COR_TINTA := Color(0.09, 0.03, 0.14)

static var _cache := {}


static func rastro_ligado() -> bool:
	return Settings.quality > 0


static func _qtd(n: int) -> int:
	return n if Settings.quality > 0 else maxi(1, n / 2)


# --- Recursos em cache ----------------------------------------------------------

static func _c(key: String, maker: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]


## Brilho redondo: centro cheio, borda some (gaussiana aproximada em 3 paradas).
static func tex_brilho() -> Texture2D:
	return _c("tex_brilho", func() -> Texture2D:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.18, 0.5, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		return t)


## Imagem procedural: f(u, v) -> Color, em 0..1. Feita uma vez por tipo.
static func _img(size: int, f: Callable) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			img.set_pixel(x, y, f.call((x + 0.5) / size, (y + 0.5) / size))
	return ImageTexture.create_from_image(img)


static var _ruido: FastNoiseLite

static func _n(u: float, v: float, freq := 6.0) -> float:
	if _ruido == null:
		_ruido = FastNoiseLite.new()
		_ruido.seed = 7
	return _ruido.get_noise_2d(u * freq * 20.0, v * freq * 20.0) * 0.5 + 0.5


## Fumaça: bolha com borda irregular (ruído na distância ao centro).
static func tex_fumaca() -> Texture2D:
	return _c("tex_fumaca", func() -> Texture2D:
		return _img(48, func(u: float, v: float) -> Color:
			var d := Vector2(u - 0.5, v - 0.5).length() * 2.0
			var borda := 0.75 + 0.35 * (_n(u, v, 1.0) - 0.5)
			var a := clampf((borda - d) / 0.35, 0.0, 1.0)
			var sombra := 0.75 + 0.25 * (1.0 - v)  # luz de cima
			return Color(sombra, sombra, sombra, a * a)))


## Marca no chão: mancha de pincel (sumi-e) com respingos; branca, tingida pela cor.
static func tex_mancha() -> Texture2D:
	return _c("tex_mancha", func() -> Texture2D:
		return _img(96, func(u: float, v: float) -> Color:
			var p := Vector2(u - 0.5, v - 0.5)
			var ang := atan2(p.y, p.x)
			var d := p.length() * 2.0
			var borda := 0.62 + 0.22 * _n(cos(ang) * 0.3 + 0.5, sin(ang) * 0.3 + 0.5, 0.9) + 0.1 * sin(ang * 7.0)
			var a := clampf((borda - d) / 0.12, 0.0, 1.0)
			a *= 0.55 + 0.45 * _n(u, v, 3.0)
			# Respingos soltos em volta.
			if d > borda and d < 0.98 and _n(u * 3.0, v * 3.0, 4.0) > 0.78:
				a = 0.8
			return Color(1, 1, 1, a)))


## Olho do vazio (Kitsune Sombria): amêndoa clara, íris roxa, pupila em fenda.
static func tex_olho() -> Texture2D:
	return _c("tex_olho", func() -> Texture2D:
		return _img(48, func(u: float, v: float) -> Color:
			var x := (u - 0.5) * 2.0
			var y := (v - 0.5) * 2.0
			var amendoa := absf(y) < 0.62 * (1.0 - x * x)
			if not amendoa:
				var aura := clampf(1.0 - Vector2(x, y * 1.6).length(), 0.0, 1.0)
				return Color(0.6, 0.2, 1.0, aura * 0.6)
			var r := Vector2(x, y).length()
			if absf(x) < 0.1 and absf(y) < 0.5:
				return Color(0.02, 0.0, 0.04, 1.0)  # pupila
			if r < 0.48:
				return Color(0.75, 0.3, 1.0, 1.0).lerp(Color(1.0, 0.85, 1.0), clampf(0.48 - r, 0.0, 0.2) * 3.0)
			return Color(0.95, 0.9, 1.0, 1.0)))


## Fita do rastro: forte na cabeça (v = 0), some na cauda; bordas suaves.
static func tex_fita() -> Texture2D:
	return _c("tex_fita", func() -> Texture2D:
		return _img(32, func(u: float, v: float) -> Color:
			return Color(1, 1, 1, pow(1.0 - v, 1.6) * sin(PI * u))))


## Material de partícula: textura × cor do vértice (a cor e a rampa de cada
## sistema). Um por (textura, mistura, billboard): poucos shaders no jogo todo.
static func mat_sprite(tex: Texture2D, nome: String, aditivo := false, billboard := true) -> StandardMaterial3D:
	return _c("mat_%s_%s_%s" % [nome, aditivo, billboard], func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if aditivo else BaseMaterial3D.BLEND_MODE_MIX
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = tex
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.disable_fog = true
		if billboard:
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			m.billboard_keep_scale = true
		return m)


## Material sólido com cor no vértice (projéteis montados por _combinar).
static func mat_solido() -> StandardMaterial3D:
	return _c("mat_solido", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		return m)


## Malha de partícula: quadrado com o material (billboard) do tipo pedido.
static func quad(nome: String, tex: Texture2D, aditivo := false, tam := Vector2.ONE, billboard := true) -> Mesh:
	return _c("quad_%s_%s_%s_%s" % [nome, aditivo, tam, billboard], func() -> Mesh:
		var q: PrimitiveMesh
		if billboard:
			q = QuadMesh.new()
			(q as QuadMesh).size = tam
		else:
			q = PlaneMesh.new()  # deitado no chão
			(q as PlaneMesh).size = tam
		q.material = mat_sprite(tex, nome, aditivo, billboard)
		return q)


## Lasca/faísca comprida (alinha com a velocidade): caixa fina em y.
static func lasca(comp := 0.28, larg := 0.035) -> Mesh:
	return _c("lasca_%.2f_%.3f" % [comp, larg], func() -> Mesh:
		var b := BoxMesh.new()
		b.size = Vector3(larg, comp, larg * 0.5)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b.material = m
		return b)


static func anel() -> Mesh:
	return _c("anel", func() -> Mesh:
		var t := TorusMesh.new()
		t.inner_radius = 0.9
		t.outer_radius = 1.0
		t.rings = 24
		t.ring_segments = 3
		t.material = mat_sprite(null, "anel", false, false)
		return t)


static func _gradiente(paradas: Array) -> Gradient:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for p in paradas:
		offs.append(p[0])
		cols.append(p[1])
	g.offsets = offs
	g.colors = cols
	return g


## Rampas de cor (multiplicam a cor do sistema): some, pisca, nasce-e-some.
static func rampa(nome: String) -> Gradient:
	return _c("rampa_" + nome, func() -> Gradient:
		match nome:
			"pisca":
				return _gradiente([[0.0, Color(1, 1, 1, 0)], [0.15, Color(1, 1, 1, 1)], [0.3, Color(1, 1, 1, 0.15)], [0.45, Color(1, 1, 1, 1)], [0.65, Color(1, 1, 1, 0.1)], [0.8, Color(1, 1, 1, 0.8)], [1.0, Color(1, 1, 1, 0)]])
			"nasce":
				return _gradiente([[0.0, Color(1, 1, 1, 0)], [0.15, Color(1, 1, 1, 1)], [0.7, Color(1, 1, 1, 0.7)], [1.0, Color(1, 1, 1, 0)]])
			"lento":  # marcas no chão: fica e só some no fim
				return _gradiente([[0.0, Color(1, 1, 1, 0.95)], [0.75, Color(1, 1, 1, 0.8)], [1.0, Color(1, 1, 1, 0)]])
			"quente":  # brasa: branco -> cor -> escuro
				return _gradiente([[0.0, Color(2, 2, 2, 1)], [0.3, Color(1, 1, 1, 1)], [1.0, Color(0.3, 0.3, 0.3, 0)]])
		return _gradiente([[0.0, Color(1, 1, 1, 1)], [0.6, Color(1, 1, 1, 0.75)], [1.0, Color(1, 1, 1, 0)]]))


static func curva(nome: String) -> Curve:
	return _c("curva_" + nome, func() -> Curve:
		var c := Curve.new()
		match nome:
			"cresce":
				c.add_point(Vector2(0, 0.25))
				c.add_point(Vector2(0.3, 0.85))
				c.add_point(Vector2(1, 1))
			"estoura":  # cresce rápido e afina
				c.add_point(Vector2(0, 0.2))
				c.add_point(Vector2(0.2, 1))
				c.add_point(Vector2(1, 0.6))
			"encolhe":
				c.add_point(Vector2(0, 1))
				c.add_point(Vector2(1, 0))
			"implode":
				c.add_point(Vector2(0, 1))
				c.add_point(Vector2(0.7, 0.35))
				c.add_point(Vector2(1, 0))
		return c)


# --- Sistema genérico ----------------------------------------------------------

## Um sistema de partículas configurado por dicionário (as chaves ausentes
## ficam no padrão). one_shot: some sozinho; senão é rastro (local_coords false).
static func ps(parent: Node, pos: Vector3, mesh: Mesh, cor: Color, n: int, vida: float, o: Dictionary = {}) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.mesh = mesh
	p.amount = maxi(n, 1)
	p.lifetime = vida
	p.color = cor
	p.color_ramp = rampa(o.get("rampa", "some"))
	p.one_shot = o.get("one_shot", true)
	p.explosiveness = o.get("explosao", 1.0 if p.one_shot else 0.0)
	p.local_coords = o.get("local", false)
	p.direction = o.get("dir", Vector3.UP)
	p.spread = o.get("spread", 180.0)
	p.flatness = o.get("flat", 0.0)
	p.initial_velocity_min = o.get("v0", 0.0)
	p.initial_velocity_max = o.get("v1", o.get("v0", 0.0))
	p.gravity = o.get("g", Vector3.ZERO)
	p.damping_min = o.get("amort", 0.0)
	p.damping_max = o.get("amort", 0.0)
	p.radial_accel_min = o.get("radial", 0.0)
	p.radial_accel_max = o.get("radial", 0.0)
	p.scale_amount_min = o.get("s0", 1.0)
	p.scale_amount_max = o.get("s1", o.get("s0", 1.0))
	p.angle_min = o.get("ang0", 0.0)
	p.angle_max = o.get("ang1", o.get("ang0", 0.0))
	if o.has("curva"):
		p.scale_amount_curve = curva(o["curva"])
	if o.has("esfera"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = o["esfera"]
	if o.get("alinha", false):
		p.particle_flag_align_y = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(p)
	if o.get("local_pos", false):
		p.position = pos  # preso ao pai (rastro do projétil, marca no corpo)
	else:
		p.global_position = pos
	p.emitting = true
	if p.one_shot:
		p.finished.connect(p.queue_free)
	return p


static func brilho(g: Node, pos: Vector3, cor: Color, tam: float, vida := 0.18, aditivo := false, curva_nome := "estoura") -> void:
	ps(g, pos, quad("brilho", tex_brilho(), aditivo), cor, 1, vida, {"s0": tam, "curva": curva_nome})


static func faiscas(g: Node, pos: Vector3, cor: Color, n: int, v: float, dir := Vector3.UP, spread := 70.0, comp := 0.28) -> void:
	ps(g, pos, lasca(comp), cor, _qtd(n), 0.3, {"dir": dir, "spread": spread, "v0": v * 0.5, "v1": v, "g": Vector3(0, -18, 0), "alinha": true, "rampa": "quente", "s0": 0.7, "s1": 1.2})


static func fumaca(g: Node, pos: Vector3, cor: Color, n: int, tam: float, vida := 0.8, subida := 1.5) -> void:
	ps(g, pos, quad("fumaca", tex_fumaca()), cor, _qtd(n), vida, {"esfera": tam * 0.4, "dir": Vector3.UP, "spread": 60.0, "v0": subida * 0.5, "v1": subida, "amort": 1.0, "s0": tam * 0.7, "s1": tam * 1.2, "curva": "cresce", "ang0": 0.0, "ang1": 360.0})


static func anel_chao(g: Node, pos: Vector3, cor: Color, raio: float, vida := 0.35) -> void:
	ps(g, pos + Vector3(0, 0.12, 0), anel(), cor, 1, vida, {"s0": raio, "curva": "cresce"})


## Marca no chão que fica uns segundos (decalque como partícula: sem tween).
static func marca_chao(g: Node, pos: Vector3, cor: Color, raio: float, vida := 2.0) -> void:
	ps(g, pos + Vector3(0, 0.05, 0), quad("mancha", tex_mancha(), false, Vector2.ONE, false), cor, 1, vida, {"s0": raio * 2.0, "rampa": "lento", "ang0": 0.0, "ang1": 360.0})


# --- Projéteis: forma --------------------------------------------------------------

## Junta malhas simples numa só, com cor por vértice: 1 draw call por projétil.
static func _combinar(partes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for parte in partes:
		var mesh: Mesh = parte[0]
		var xf: Transform3D = parte[1]
		var cor: Color = parte[2]
		var arr := mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			idx = PackedInt32Array(range(verts.size()))
		for i in idx:
			st.set_color(cor)
			st.add_vertex(xf * verts[i])
	return st.commit()


static func malha_flecha(cor_pena: Color) -> ArrayMesh:
	return _c("flecha" + cor_pena.to_html(), func() -> ArrayMesh:
		var haste := BoxMesh.new()
		haste.size = Vector3(0.045, 0.045, 1.0)
		var ponta := PrismMesh.new()
		ponta.size = Vector3(0.14, 0.24, 0.03)
		var pena := BoxMesh.new()
		pena.size = Vector3(0.2, 0.01, 0.22)
		var frente := Basis(Vector3.RIGHT, -PI / 2)  # prisma aponta em +y; deita para -z
		return _combinar([
			[haste, Transform3D(Basis(), Vector3(0, 0, 0.05)), Color(0.42, 0.27, 0.14)],
			[ponta, Transform3D(frente, Vector3(0, 0, -0.55)), Color(0.8, 0.85, 0.9)],
			[ponta, Transform3D(frente * Basis(Vector3.UP, PI / 2), Vector3(0, 0, -0.55)), Color(0.6, 0.65, 0.7)],
			[pena, Transform3D(Basis(), Vector3(0, 0, 0.45)), cor_pena],
			[pena, Transform3D(Basis(Vector3.FORWARD, PI / 2), Vector3(0, 0, 0.45)), cor_pena.darkened(0.25)],
		]))


## Shuriken de aço: lâminas claras, miolo escuro (lê como metal, não magia).
static func malha_shuriken() -> ArrayMesh:
	return _c("shuriken", func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 4:
			var a := TAU * i / 4.0
			var p := Vector3(cos(a), sin(a), 0) * 0.34
			var e := Vector3(cos(a + PI / 4), sin(a + PI / 4), 0) * 0.09
			var d := Vector3(cos(a - PI / 4), sin(a - PI / 4), 0) * 0.09
			for f in [[Vector3.ZERO, d, p], [Vector3.ZERO, p, e]]:
				st.set_color(Color(0.55, 0.6, 0.68))
				st.add_vertex(f[0])
				st.set_color(COR_METAL * 1.25)
				st.add_vertex(f[1])
				st.set_color(Color(1.6, 1.9, 2.0))  # fio da lâmina brilha
				st.add_vertex(f[2])
		return st.commit())


static func malha_lanca() -> ArrayMesh:
	return _c("lanca", func() -> ArrayMesh:
		# Losango comprido: 6 vértices (frente, trás e 4 em volta).
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var f := Vector3(0, 0, -0.75)
		var t := Vector3(0, 0, 0.55)
		var anel_v := [Vector3(0.11, 0, -0.1), Vector3(0, 0.11, -0.1), Vector3(-0.11, 0, -0.1), Vector3(0, -0.11, -0.1)]
		for i in 4:
			var a: Vector3 = anel_v[i]
			var b: Vector3 = anel_v[(i + 1) % 4]
			for tri in [[f, a, b], [t, b, a]]:
				st.set_color(Color(1.0, 0.97, 0.8))
				st.add_vertex(tri[0])
				st.set_color(Color(0.95, 0.55, 0.05))
				st.add_vertex(tri[1])
				st.add_vertex(tri[2])
		return st.commit())


static func malha_bola(cor: Color, r: float) -> SphereMesh:
	return _c("bola%s%.2f" % [cor.to_html(), r], func() -> SphereMesh:
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2.0
		s.radial_segments = 10
		s.rings = 5
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = cor
		s.material = m
		return s)


## Monta a aparência do projétil no nó p (Projectile). Devolve o nó que gira.
static func montar(p: Node3D, kind: String, time_cor: Color) -> Node3D:
	var corpo := MeshInstance3D.new()
	corpo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corpo.name = "Corpo"
	var gira: Node3D = null
	var rastro := rastro_ligado()
	match kind:
		"flecha":
			corpo.mesh = malha_flecha(time_cor.lightened(0.35))
			corpo.material_override = mat_solido()
			p.add_child(corpo)
			if rastro:  # fita de vento fina
				_fita(p, Color(1, 1, 1, 0.45), 0.16, 1.8)
		"shuriken":
			corpo.mesh = malha_shuriken()
			corpo.material_override = mat_solido()
			corpo.rotation_degrees.x = 90
			p.add_child(corpo)
			gira = corpo
			if rastro:  # lascas de metal soltas pelo caminho
				ps(p, Vector3.ZERO, lasca(0.18, 0.025), COR_METAL * 1.3, 6, 0.22, {"one_shot": false, "dir": Vector3.UP, "spread": 180.0, "flat": 0.6, "v0": 1.5, "v1": 3.0, "alinha": true, "rampa": "quente", "local_pos": true})
				_fita(p, Color(COR_CIANO, 0.3), 0.12, 1.1)
		"bomba":
			corpo.mesh = malha_bola(Color(0.07, 0.07, 0.1), 0.24)
			p.add_child(corpo)
			var pavio := MeshInstance3D.new()
			pavio.mesh = malha_bola(Color(2.0, 1.1, 0.3), 0.07)
			pavio.position.y = 0.28
			p.add_child(pavio)
			brilho_fixo(p, Vector3(0, 0.3, 0), Color(1.0, 0.6, 0.2), 0.6)
			if rastro:  # faíscas do pavio + fumacinha
				ps(p, Vector3(0, 0.3, 0), lasca(0.12, 0.03), Color(1.0, 0.7, 0.25), 7, 0.25, {"one_shot": false, "local_pos": true, "dir": Vector3.UP, "spread": 60.0, "v0": 2.0, "v1": 4.0, "g": Vector3(0, -10, 0), "alinha": true, "rampa": "quente"})
				ps(p, Vector3(0, 0.3, 0), quad("fumaca", tex_fumaca()), Color(0.35, 0.33, 0.33, 0.7), 5, 0.6, {"one_shot": false, "local_pos": true, "dir": Vector3.UP, "spread": 20.0, "v0": 0.5, "v1": 1.0, "s0": 0.35, "s1": 0.55, "curva": "cresce", "ang1": 360.0})
		"fogo":
			# Três fogos-fátuos (kitsunebi) girando em volta do eixo do voo.
			gira = Node3D.new()
			p.add_child(gira)
			for i in 3:
				var a := TAU * i / 3.0
				brilho_fixo(gira, Vector3(cos(a), sin(a), 0) * 0.4, Color(COR_RAPOSA, 0.95), 0.8, false)
				brilho_fixo(gira, Vector3(cos(a), sin(a), 0) * 0.4, Color(1.0, 0.85, 0.95), 0.3, false)
			brilho_fixo(p, Vector3.ZERO, Color(0.45, 0.05, 0.3, 0.7), 0.45, false)
			corpo.free()
			if rastro:  # brasas rosas soltas
				ps(p, Vector3.ZERO, quad("brilho", tex_brilho()), COR_RAPOSA, 8, 0.35, {"one_shot": false, "esfera": 0.3, "dir": Vector3.UP, "spread": 30.0, "v0": 0.5, "v1": 1.5, "s0": 0.18, "s1": 0.32, "curva": "encolhe", "local_pos": true})
		"chi":
			# Lança dourada da Kitsune da Luz, com brilhos piscando no caminho.
			corpo.mesh = malha_lanca()
			corpo.material_override = mat_solido()
			p.add_child(corpo)
			brilho_fixo(p, Vector3(0, 0, -0.5), Color(COR_OURO, 0.8), 0.8, false)
			if rastro:
				ps(p, Vector3.ZERO, quad("brilho", tex_brilho()), COR_OURO, 8, 0.5, {"one_shot": false, "esfera": 0.25, "s0": 0.15, "s1": 0.3, "rampa": "pisca", "local_pos": true})
				_fita(p, Color(COR_OURO, 0.7), 0.2, 1.5)
		"magia":
			# Orbe do vazio (Kitsune Sombria): bola escura, aura roxa, um olho.
			corpo.mesh = malha_bola(COR_TINTA, 0.2)
			p.add_child(corpo)
			brilho_fixo(p, Vector3.ZERO, COR_VAZIO, 0.9)
			var olho := MeshInstance3D.new()
			olho.mesh = quad("olho", tex_olho(), false, Vector2(0.5, 0.5))
			olho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			olho.material_override = _mat_olho()
			olho.position = Vector3(0, 0.12, 0)
			p.add_child(olho)
			if rastro:  # fita de sombra (mistura normal: escurece em vez de clarear)
				_fita(p, Color(COR_TINTA, 0.75), 0.3, 1.6)
				ps(p, Vector3.ZERO, quad("fumaca", tex_fumaca()), Color(0.16, 0.06, 0.25, 0.8), 6, 0.4, {"one_shot": false, "esfera": 0.15, "s0": 0.35, "s1": 0.5, "curva": "encolhe", "ang1": 360.0, "local_pos": true})
		_:
			corpo.mesh = malha_bola(Color(1.2, 0.9, 2.0), 0.26)
			p.add_child(corpo)
	return gira


static func _mat_olho() -> StandardMaterial3D:
	return _c("mat_olho", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = tex_olho()
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.no_depth_test = true
		m.render_priority = 1
		return m)


## Brilho parado preso ao projétil (sem partícula): 1 quad billboard.
static func brilho_fixo(parent: Node3D, pos: Vector3, cor: Color, tam: float, aditivo := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = quad("brilho", tex_brilho(), aditivo)
	mi.material_override = _c("mat_fixo_%s_%s" % [cor.to_html(), aditivo], func() -> StandardMaterial3D:
		var m := mat_sprite(tex_brilho(), "brilho", aditivo).duplicate() as StandardMaterial3D
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.vertex_color_use_as_albedo = false
		m.albedo_color = cor
		return m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3.ONE * tam
	mi.position = pos
	parent.add_child(mi)
	return mi


## Fita do rastro: plano deitado atrás do projétil (o nó olha para a frente
## em -z, então a fita vai de z = 0 até z = comp).
static func _fita(p: Node3D, cor: Color, larg: float, comp: float, aditivo := false) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Fita"
	mi.mesh = _c("fita_mesh", func() -> PlaneMesh:
		var pm := PlaneMesh.new()
		pm.size = Vector2.ONE
		return pm)
	mi.material_override = _c("mat_fita_%s_%s" % [cor.to_html(), aditivo], func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if aditivo else BaseMaterial3D.BLEND_MODE_MIX
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.albedo_texture = tex_fita()
		m.albedo_color = cor
		return m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(larg, 1, comp)
	mi.position = Vector3(0, 0, comp * 0.5)
	p.add_child(mi)


## Tiro carregado (Q): fita maior e mais brilhante e um rastro extra.
static func carregar(p: Node3D, kind: String) -> void:
	for f in p.find_children("Fita", "MeshInstance3D", false, false):
		f.scale = Vector3(f.scale.x * 1.8, 1, f.scale.z * 1.7)
		f.position.z = f.scale.z * 0.5
	if not rastro_ligado():
		return
	var cor: Color = {"shuriken": COR_CIANO, "flecha": Color(1, 1, 1), "magia": COR_VAZIO, "chi": COR_OURO, "fogo": COR_RAPOSA, "bomba": Color(1.0, 0.6, 0.2)}.get(kind, Color.WHITE)
	ps(p, Vector3.ZERO, quad("brilho", tex_brilho()), cor, 12, 0.35, {"one_shot": false, "esfera": 0.2, "s0": 0.3, "s1": 0.55, "curva": "encolhe", "local_pos": true})
	if kind != "bomba" and kind != "magia":
		_fita(p, Color(cor, 0.5), 0.5, 2.6, true)


## Quando o projétil some, o rastro solto fica no mundo e termina de sumir.
static func soltar_rastro(p: Node3D, g: Node) -> void:
	for c in p.get_children():
		if c is CPUParticles3D and not c.one_shot:
			var xf: Transform3D = c.global_transform
			p.remove_child(c)
			g.add_child(c)
			c.global_transform = xf
			c.emitting = false
			var tw := c.create_tween()
			tw.tween_interval(c.lifetime + 0.05)
			tw.tween_callback(c.queue_free)


# --- Impactos -----------------------------------------------------------------------

## Projétil bateu em parede ou chão (nivel 2 = carregado).
static func impacto_cenario(g: Node, at: Vector3, kind: String, dir: Vector3, nivel := 1) -> void:
	match kind:
		"flecha":
			fumaca(g, at, Color(0.55, 0.47, 0.36, 0.8), 3, 0.5, 0.5, 0.8)
			marca_chao(g, Vector3(at.x, at.y - 0.05, at.z), Color(0.2, 0.15, 0.1, 0.55), 0.35, 2.0)
			cravar(g, at, dir, "flecha", 2.0)
		"shuriken":
			faiscas(g, at, Color(1.0, 0.9, 0.6), 5, 5.0, -dir + Vector3.UP, 60.0, 0.16)
			cravar(g, at, dir, "shuriken", 1.5)
		_:
			impacto(g, at, kind, dir, nivel)


## Impacto no corpo ou no chão: cada elemento com o seu. dir = sentido do tiro.
static func impacto(g: Node, at: Vector3, kind: String, dir: Vector3, nivel := 1) -> void:
	var k := 1.0 if nivel <= 1 else 1.6
	match kind:
		"shuriken":  # estilhaço de metal
			faiscas(g, at, COR_METAL * 1.4, int(6 * k), 7.0, dir + Vector3.UP * 0.4, 50.0, 0.2)
			brilho(g, at, Color(0.7, 1.0, 1.0), 0.9 * k, 0.12)
		"flecha":  # poeira e lascas de madeira
			faiscas(g, at, Color(0.9, 0.8, 0.6), int(4 * k), 5.0, -dir + Vector3.UP, 60.0, 0.16)
			brilho(g, at, Color(1, 1, 1, 0.8), 0.7 * k, 0.1)
		"fogo":  # faíscas + anel
			faiscas(g, at, Color(1.0, 0.45, 0.8), int(7 * k), 6.0, Vector3.UP, 80.0, 0.22)
			brilho(g, at, COR_RAPOSA, 1.4 * k, 0.22)
			anel_chao(g, Vector3(at.x, at.y - 1.0, at.z), Color(COR_RAPOSA, 0.8), 1.1 * k)
		"chi":  # cruz de luz
			cruz(g, at, COR_OURO, 1.6 * k)
			ps(g, at, quad("brilho", tex_brilho()), COR_OURO, _qtd(int(6 * k)), 0.5, {"esfera": 0.5, "v0": 1.0, "v1": 2.0, "s0": 0.15, "s1": 0.3, "rampa": "pisca"})
		"magia":  # implosão: a sombra se fecha no ponto e estala
			ps(g, at, quad("fumaca", tex_fumaca()), Color(0.12, 0.04, 0.2, 0.85), 1, 0.28, {"s0": 2.2 * k, "curva": "implode"})
			ps(g, at, quad("brilho", tex_brilho()), COR_VAZIO, _qtd(int(8 * k)), 0.28, {"esfera": 1.3 * k, "radial": -28.0, "s0": 0.2, "s1": 0.35})
			# O estalo sai 0,24 s depois; o tween morre junto com o nó (sem
			# chamar nada solto se a partida acabar antes).
			var tw := g.create_tween()
			tw.tween_interval(0.24)
			tw.tween_callback(brilho.bind(g, at, COR_VAZIO, 1.2 * k, 0.16))
		"bomba":
			explosao(g, at, 2.0 * k)
		"terra":  # pisão/fúria: poeira e pedrinhas
			fumaca(g, at + Vector3(0, -0.8, 0), Color(0.5, 0.42, 0.32, 0.8), 3, 0.7, 0.6, 1.0)
			faiscas(g, at, Color(1.0, 0.45, 0.2), int(4 * k), 6.0, dir + Vector3.UP, 50.0, 0.22)


## Explosão de bomba comum: bola de fogo, fumaça escura subindo, estilhaços
## e a marca de queimado que fica uns 2 s.
static func explosao(g: Node, at: Vector3, r: float) -> void:
	brilho(g, at + Vector3(0, 0.7, 0), Color(1.0, 0.45, 0.1, 0.95), r * 1.5, 0.28, false)
	brilho(g, at + Vector3(0, 0.7, 0), Color(1.0, 0.9, 0.5), r * 0.8, 0.14)
	fumaca(g, at + Vector3(0, 0.6, 0), Color(0.24, 0.21, 0.2, 0.6), 7, r * 0.9, 1.1, 2.2)
	faiscas(g, at + Vector3(0, 0.3, 0), Color(1.0, 0.75, 0.3), 8, 9.0, Vector3.UP, 75.0, 0.3)
	marca_chao(g, at, Color(0.06, 0.05, 0.05, 0.75), r * 0.8, 2.2)


## Clarão em cruz (Luz): uma barra em pé e outra deitada, viradas para a câmera.
static func cruz(g: Node, at: Vector3, cor: Color, tam: float) -> void:
	ps(g, at, quad("raio_v", tex_brilho(), false, Vector2(0.18, 1.0)), cor, 1, 0.3, {"s0": tam * 1.6, "curva": "estoura"})
	ps(g, at, quad("raio_h", tex_brilho(), false, Vector2(1.0, 0.18)), cor, 1, 0.3, {"s0": tam * 1.2, "curva": "estoura"})
	brilho(g, at, Color(1.0, 0.95, 0.75), tam * 0.5, 0.15)


## Faísca do golpe corpo a corpo: risco de luz no ângulo do corte + fagulhas.
static func faisca_corte(g: Node, at: Vector3, dir: Vector3, cor: Color, forte := false) -> void:
	var k := 1.4 if forte else 1.0
	# O corpo de quem apanha pisca branco: faísca branca some nele. Por isso
	# fagulhas de aço quente (laranja) e respingos de tinta escura (contraste).
	ps(g, at, quad("risco", tex_brilho(), false, Vector2(1.0, 0.12)), cor, 1, 0.16, {"s0": 1.7 * k, "curva": "estoura", "ang0": -50.0, "ang1": 50.0})
	faiscas(g, at, Color(1.0, 0.55, 0.12), int(5 * k), 7.0 * k, dir + Vector3.UP * 0.5, 45.0, 0.24)
	if Settings.quality > 0:
		ps(g, at, _gota(), Color(0.16, 0.02, 0.06, 0.95), int(4 * k), 0.45, {"dir": dir + Vector3.UP * 0.8, "spread": 35.0, "v0": 3.0, "v1": 5.5, "g": Vector3(0, -16, 0), "s0": 0.7, "s1": 1.4})


static func _gota() -> Mesh:
	return _c("gota", func() -> Mesh:
		var s := SphereMesh.new()
		s.radius = 0.06
		s.height = 0.16
		s.radial_segments = 6
		s.rings = 3
		s.material = mat_sprite(null, "gota", false, false)
		return s)


# --- Reação do alvo (só visual, ~1 s) --------------------------------------------

## A marca do elemento no corpo: brasa, tinta escorrendo, brilho.
## Um efeito por boneco: o novo troca o antigo (nada acumula na briga).
static func marca_corpo(u: Node3D, kind: String) -> void:
	if Settings.quality <= 0:
		return
	var cor: Color
	var o := {"one_shot": false, "esfera": 0.35, "local_pos": true}
	var n := 5
	var vida := 0.5
	var mesh: Mesh = quad("brilho", tex_brilho())
	match kind:
		"fogo", "bomba":  # brasa subindo
			cor = COR_RAPOSA if kind == "fogo" else Color(1.0, 0.5, 0.15)
			o.merge({"dir": Vector3.UP, "spread": 25.0, "v0": 0.8, "v1": 1.8, "s0": 0.12, "s1": 0.22, "rampa": "quente"})
		"magia", "selo":  # tinta escorrendo
			cor = Color(0.1, 0.03, 0.16, 0.95)
			mesh = _gota()
			o.merge({"g": Vector3(0, -5, 0), "s0": 0.8, "s1": 1.3, "rampa": "some"})
			vida = 0.6
		"chi":  # brilho
			cor = COR_OURO
			o.merge({"s0": 0.12, "s1": 0.25, "rampa": "pisca"})
			n = 4
		_:
			return
	var antiga: Node = u.get_node_or_null("MarcaCorpo")
	if antiga:
		antiga.queue_free()
		antiga.name = "MarcaVelha"
	var p := ps(u, Vector3(0, 1.2, 0), mesh, cor, n, vida, o)
	p.name = "MarcaCorpo"
	var tw := p.create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(p.set_emitting.bind(false))
	tw.tween_interval(vida)
	tw.tween_callback(p.queue_free)


## Flecha/shuriken cravada (no corpo ou no chão) por alguns segundos.
static func cravar(parent: Node3D, at: Vector3, dir: Vector3, kind: String, vida: float) -> void:
	if Settings.quality <= 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = malha_shuriken() if kind == "shuriken" else malha_flecha(Color(0.85, 0.85, 0.8))
	mi.material_override = mat_solido()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(mi)
	var d := dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	mi.global_position = at - d * (0.3 if kind == "flecha" else 0.0)
	if absf(d.y) < 0.99:
		mi.look_at(mi.global_position + d, Vector3.UP)
	if kind == "shuriken":
		mi.rotate_object_local(Vector3.RIGHT, PI / 2)
		mi.scale = Vector3.ONE * 0.8
	var tw := mi.create_tween()
	tw.tween_interval(vida)
	tw.tween_callback(mi.queue_free)


## Esquenta os materiais daqui (no navegador cada shader novo compila na
## primeira vez que aparece e travava o primeiro tiro de cada tipo).
static func prewarm(parent: Node, pos: Vector3) -> void:
	for kind in ["flecha", "shuriken", "bomba", "fogo", "chi", "magia"]:
		var n := Node3D.new()
		parent.add_child(n)
		n.global_position = pos
		montar(n, kind, Color(0.3, 0.5, 1.0))
		carregar(n, kind)
		impacto(parent, pos, kind, Vector3.FORWARD, 2)
		parent.get_tree().create_timer(0.5).timeout.connect(n.queue_free)
	faisca_corte(parent, pos, Vector3.FORWARD, Color.WHITE)
	marca_chao(parent, pos, Color(0, 0, 0, 0.5), 1.0, 0.3)
	anel_chao(parent, pos, Color.WHITE, 1.0)
	cravar(parent, pos, Vector3.FORWARD, "flecha", 0.3)
