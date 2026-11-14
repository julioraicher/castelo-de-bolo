class_name Magia
extends RefCounted
## Kit de magia (Ciclo 2.20): as peças que tiram o "cone seco" dos poderes.
## Ideia: a malha continua barata (tubo, disco, quad, fita) e a vida vem de
## (1) ruído rolando por dentro com a borda se desfazendo (`magia_energia`),
## (2) selo que se escreve no chão (`magia_selo`), (3) fita de rastro (`Fita`),
## (4) três atos: `carga` (suga), estouro (`chama`, `onda`, `clarao`) e resto
## (`brasas`, marca no chão do FxProjetil).
## Mistura normal com filete de tinta, não aditiva: aditivo estoura em branco
## no chão claro do dia. Cada efeito = 1 chamada de desenho e some sozinho.
## Na qualidade Mínima as peças de enfeite (brasas, carga, luz) desligam.

const SH_ENERGIA := preload("res://assets/shaders/magia_energia.gdshader")
const SH_SELO := preload("res://assets/shaders/magia_selo.gdshader")
static var _sh_atras: Shader  # mesma energia, só as faces de trás (aura que não tapa o boneco)
const TINTA := Color(0.09, 0.03, 0.14)

## Paletas: [núcleo, meio, borda]. O filete de tinta é o mesmo em todas.
const PALETAS := {
	"raposa": [Color(0.92, 1.0, 1.0), Color(0.35, 0.85, 1.0), Color(0.1, 0.42, 0.95)],
	"luz": [Color(1.0, 1.0, 0.92), Color(1.0, 0.86, 0.4), Color(0.95, 0.55, 0.12)],
	"sombra": [Color(1.0, 0.9, 1.0), Color(0.78, 0.42, 1.0), Color(0.36, 0.1, 0.72)],
	"brasa": [Color(1.0, 0.97, 0.75), Color(1.0, 0.62, 0.12), Color(0.86, 0.14, 0.06)],
	"vento": [Color(1.0, 1.0, 1.0), Color(0.98, 0.93, 0.72), Color(0.82, 0.66, 0.32)],
	"aco": [Color(1.0, 1.0, 1.0), Color(0.9, 0.97, 1.0), Color(0.6, 0.8, 1.0)],
	"veneno": [Color(0.95, 1.0, 0.8), Color(0.55, 0.95, 0.3), Color(0.12, 0.55, 0.2)],
	"raposa_rosa": [Color(1.0, 0.92, 0.97), Color(1.0, 0.45, 0.75), Color(0.75, 0.12, 0.5)],
	"cura": [Color(0.94, 1.0, 0.94), Color(0.5, 1.0, 0.65), Color(0.12, 0.62, 0.4)],
	"fumaca": [Color(0.8, 0.78, 0.8), Color(0.56, 0.53, 0.58), Color(0.36, 0.33, 0.42)],
	"nevoa": [Color(0.92, 0.9, 1.0), Color(0.68, 0.62, 0.88), Color(0.44, 0.38, 0.64)],
	# Heróis raros (Ciclo 2.23)
	"agua": [Color(0.92, 1.0, 1.0), Color(0.4, 0.82, 1.0), Color(0.08, 0.36, 0.75)],
	"sal": [Color(1.0, 1.0, 0.97), Color(0.96, 0.9, 0.76), Color(0.72, 0.6, 0.42)],
	"papel": [Color(1.0, 1.0, 0.96), Color(0.98, 0.93, 0.8), Color(0.85, 0.3, 0.25)],
	"pena": [Color(0.85, 0.8, 1.0), Color(0.45, 0.35, 0.75), Color(0.14, 0.1, 0.25)],
	"som": [Color(0.94, 1.0, 1.0), Color(0.5, 0.95, 0.86), Color(0.12, 0.5, 0.55)],
	"celeste": [Color(1.0, 0.98, 0.95), Color(1.0, 0.76, 0.84), Color(0.85, 0.55, 0.3)],
	# Heróis 2.27
	"fantasma": [Color(0.92, 0.98, 1.0), Color(0.55, 0.78, 1.0), Color(0.16, 0.28, 0.66)],
	"festa": [Color(1.0, 0.98, 0.88), Color(1.0, 0.78, 0.3), Color(0.86, 0.16, 0.18)],
	"seda": [Color(1.0, 1.0, 1.0), Color(0.9, 0.88, 0.97), Color(0.55, 0.47, 0.68)],
	"bosque": [Color(0.95, 1.0, 0.85), Color(0.55, 0.88, 0.35), Color(0.24, 0.42, 0.14)],
	"raio": [Color(1.0, 1.0, 1.0), Color(0.62, 0.82, 1.0), Color(0.38, 0.3, 0.95)],
	"cachaca": [Color(1.0, 0.99, 0.86), Color(1.0, 0.8, 0.32), Color(0.66, 0.38, 0.08)],
}

static var _cache := {}


static func _c(key: String, maker: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]


static func enfeite() -> bool:
	return Settings.quality > 0


static func paleta(nome: Variant) -> Array:
	if nome is Array:
		return nome
	return PALETAS.get(nome, PALETAS["raposa"])


## Paleta a partir de uma cor qualquer (cor do time, cor do chapéu).
static func paleta_de(cor: Color) -> Array:
	var c := Color(cor, 1.0)
	return [c.lerp(Color.WHITE, 0.85), c.lerp(Color.WHITE, 0.25), c.darkened(0.35)]


# --- Recursos ---------------------------------------------------------------------

## Ruído de valor que emenda nas bordas (2 oitavas), 128². Feito uma vez.
static func tex_ruido() -> Texture2D:
	return _c("ruido", func() -> Texture2D:
		var n := 128
		var rng := RandomNumberGenerator.new()
		rng.seed = 20
		var img := Image.create(n, n, false, Image.FORMAT_R8)
		var grades := []
		for per: int in [6, 13]:
			var g := PackedFloat32Array()
			g.resize(per * per)
			for i in per * per:
				g[i] = rng.randf()
			grades.append([per, g])
		for y in n:
			for x in n:
				var v := 0.0
				var peso := 0.62
				for gr: Array in grades:
					var per: int = gr[0]
					var g: PackedFloat32Array = gr[1]
					var fx := float(x) / n * per
					var fy := float(y) / n * per
					var x0 := int(fx) % per
					var y0 := int(fy) % per
					var x1 := (x0 + 1) % per
					var y1 := (y0 + 1) % per
					var tx := smoothstep(0.0, 1.0, fx - int(fx))
					var ty := smoothstep(0.0, 1.0, fy - int(fy))
					v += peso * lerpf(lerpf(g[y0 * per + x0], g[y0 * per + x1], tx), lerpf(g[y1 * per + x0], g[y1 * per + x1], tx), ty)
					peso = 0.38
				img.set_pixel(x, y, Color(v, v, v))
		# Estica para usar a faixa toda (0..1): o ruído de valor fica entre ~0,2 e 0,8.
		var lo := 1.0
		var hi := 0.0
		for y in n:
			for x in n:
				var v := img.get_pixel(x, y).r
				lo = minf(lo, v)
				hi = maxf(hi, v)
		for y in n:
			for x in n:
				var v := (img.get_pixel(x, y).r - lo) / maxf(hi - lo, 0.01)
				img.set_pixel(x, y, Color(v, v, v))
		img.generate_mipmaps()
		return ImageTexture.create_from_image(img))


## Material de energia novo (um por efeito, para animar `corroi`; o Shader é
## um só, então não compila nada no meio da luta).
static func mat(pal: Variant, o: Dictionary = {}) -> ShaderMaterial:
	var p := paleta(pal)
	var m := ShaderMaterial.new()
	m.shader = SH_ENERGIA
	if o.get("atras", false):
		if _sh_atras == null:
			_sh_atras = Shader.new()
			_sh_atras.code = SH_ENERGIA.code.replace("cull_disabled", "cull_front")
		m.shader = _sh_atras
	m.set_shader_parameter("ruido", tex_ruido())
	m.set_shader_parameter("cor_nucleo", p[0])
	m.set_shader_parameter("cor_meio", p[1])
	m.set_shader_parameter("cor_borda", p[2])
	m.set_shader_parameter("cor_tinta", TINTA)
	m.set_shader_parameter("semente", randf() * 7.0)
	for k: String in o:
		if k != "atras":
			m.set_shader_parameter(k, o[k])
	return m


## Tubo de raio 1 na base, `r_topo` em cima, altura 1, sem tampas.
## U dá a volta (0..1), V sobe (0 no chão, 1 no topo). `barriga` engorda o meio.
static func tubo(r_topo := 0.2, barriga := 0.0, seg := 20, aneis := 6) -> ArrayMesh:
	return _c("tubo_%.2f_%.2f_%d_%d" % [r_topo, barriga, seg, aneis], func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in aneis:
			for i in seg:
				for q: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
					var u := float(i + q.x) / seg
					var v := float(j + q.y) / aneis
					var r := lerpf(1.0, r_topo, v) + barriga * sin(v * PI)
					st.set_normal(Vector3(cos(u * TAU), 0, sin(u * TAU)))
					st.set_uv(Vector2(u, v))
					st.add_vertex(Vector3(cos(u * TAU) * r, v, sin(u * TAU) * r))
		return st.commit())


## Disco deitado de raio 1: U dá a volta, V vai do centro (0) à borda (1).
static func disco(seg := 24) -> ArrayMesh:
	return _c("disco_%d" % seg, func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in seg:
			var u0 := float(i) / seg
			var u1 := float(i + 1) / seg
			st.set_uv(Vector2(u0, 0.0))
			st.add_vertex(Vector3.ZERO)
			st.set_uv(Vector2(u1, 1.0))
			st.add_vertex(Vector3(cos(u1 * TAU), 0, sin(u1 * TAU)))
			st.set_uv(Vector2(u0, 1.0))
			st.add_vertex(Vector3(cos(u0 * TAU), 0, sin(u0 * TAU)))
		return st.commit())


## Cúpula (meia esfera de raio 1): V = 0 na borda do chão, 1 no topo.
static func cupula(seg := 16, aneis := 5) -> ArrayMesh:
	return _c("cupula_%d_%d" % [seg, aneis], func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in aneis:
			for i in seg:
				for q: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
					var u := float(i + q.x) / seg
					var v := float(j + q.y) / aneis
					var el := v * PI * 0.5
					var pv := Vector3(cos(u * TAU) * cos(el), sin(el), sin(u * TAU) * cos(el))
					st.set_normal(pv)
					st.set_uv(Vector2(u, v))
					st.add_vertex(pv)
		return st.commit())


static func _quad_chao() -> PlaneMesh:
	return _c("quad_chao", func() -> PlaneMesh:
		var p := PlaneMesh.new()
		p.size = Vector2(2, 2)
		return p)


static func _no(parent: Node, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(n)
	n.global_position = pos
	return n


static func _malha(parent: Node3D, mesh: Mesh, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Anima um uniforme do material.
static func _anim(tw: Tween, m: ShaderMaterial, nome: String, de: float, ate: float, dur: float) -> MethodTweener:
	m.set_shader_parameter(nome, de)
	return tw.tween_method(func(v: float) -> void: m.set_shader_parameter(nome, v), de, ate, dur)


# --- Peças ------------------------------------------------------------------------

## Labareda/coluna: nasce do chão num pulo, lambe e se desfaz de cima para
## baixo. o: r_topo, barriga, giro (voltas), rola, escala, forca, segura (fração
## da vida inteira antes de corroer).
static func chama(g: Node, pos: Vector3, pal: Variant, raio: float, altura: float, vida: float, o: Dictionary = {}) -> Node3D:
	var n := _no(g, pos)
	var m := mat(pal, {
		"escala": o.get("escala", Vector2(3.0, 0.5)),
		"rola": o.get("rola", Vector2(0.12, -1.3)),
		"forca": o.get("forca", 1.1),
		"base": o.get("base", 0.8), "topo": o.get("topo", -0.2), "atras": o.get("atras", false),
		"ondula": o.get("ondula", 0.1), "fresnel": o.get("fresnel", 0.75),
	})
	_malha(n, tubo(o.get("r_topo", 0.25), o.get("barriga", 0.12)), m)
	n.scale = Vector3(raio * 0.5, altura * 0.08, raio * 0.5)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3(raio, altura, raio), minf(0.16, vida * 0.3)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(n, "rotation:y", TAU * o.get("giro", 0.4), vida)
	var segura: float = o.get("segura", 0.35)
	_anim(tw, m, "corroi", 0.0, 1.0, vida * (1.0 - segura)).set_delay(vida * segura).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(n.queue_free)
	return n


## Onda de choque no chão: faixa de energia que abre até `raio` e se rasga.
static func onda(g: Node, pos: Vector3, pal: Variant, raio: float, vida := 0.45, o: Dictionary = {}) -> Node3D:
	var n := _no(g, pos + Vector3(0, o.get("y", 0.12), 0))
	var m := mat(pal, {
		"escala": Vector2(o.get("voltas", 4.0), 0.6), "rola": Vector2(o.get("gira", 0.0), -0.9),
		"forca": o.get("forca", 0.7), "base": 0.85, "topo": 0.85,
		"banda": o.get("banda", 0.22), "centro": 0.76,
		"tinta": o.get("tinta", 0.07 * clampf(3.0 / maxf(raio, 0.1), 0.4, 1.0)),
	})
	_malha(n, disco(), m)
	var r0: float = o.get("r0", 0.15)
	n.scale = Vector3(raio * r0, 1, raio * r0)
	var tw := n.create_tween().set_parallel()
	var sc := tw.tween_property(n, "scale", Vector3(raio, 1, raio), vida)
	if o.get("linear", false):
		sc.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		sc.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var segura: float = o.get("segura", 0.3)
	_anim(tw, m, "corroi", 0.0, 1.0, vida * (1.0 - segura)).set_delay(vida * segura)
	tw.chain().tween_callback(n.queue_free)
	return n


## Cúpula de energia que incha e se rasga (estouro, grito, escudo quebrando).
static func estouro(g: Node, pos: Vector3, pal: Variant, raio: float, vida := 0.4, o: Dictionary = {}) -> Node3D:
	var n := _no(g, pos)
	var m := mat(pal, {
		"escala": Vector2(3.0, 1.0), "rola": Vector2(0.0, -1.2 if o.get("sobe", true) else 0.6),
		"forca": o.get("forca", 1.0), "base": o.get("base", 0.75), "topo": o.get("topo", 0.6), "fresnel": 0.7,
	})
	_malha(n, cupula(), m)
	n.scale = Vector3.ONE * raio * 0.25
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE * raio, vida).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_anim(tw, m, "corroi", 0.2, 1.0, vida * 0.9).set_delay(vida * 0.1)
	tw.chain().tween_callback(n.queue_free)
	return n


## Selo que se escreve no chão. o: pontas, petalas, escrita (s), giro, aceso_em
## (s depois de escrito, acende o miolo). Devolve o nó; o selo fica `dur` s.
static func selo(g: Node, pos: Vector3, pal: Variant, raio: float, dur: float, o: Dictionary = {}) -> Node3D:
	var p := paleta(pal)
	var n := _no(g, pos + Vector3(0, 0.09, 0))
	var m := ShaderMaterial.new()
	m.shader = SH_SELO
	m.set_shader_parameter("ruido", tex_ruido())
	m.set_shader_parameter("cor", p[1])
	m.set_shader_parameter("cor_nucleo", p[0])
	m.set_shader_parameter("cor_tinta", TINTA)
	m.set_shader_parameter("pontas", o.get("pontas", 5))
	m.set_shader_parameter("petalas", o.get("petalas", 0))
	m.set_shader_parameter("giro", o.get("giro", 0.06))
	m.set_shader_parameter("semente", randf())
	m.set_shader_parameter("fino", clampf(3.2 / maxf(raio, 0.1), 0.3, 1.0))
	_malha(n, _quad_chao(), m)
	n.scale = Vector3(raio, 1, raio)
	var escrita: float = minf(o.get("escrita", 0.45), dur * 0.6)
	var tw := n.create_tween().set_parallel()
	_anim(tw, m, "escreve", 0.0, 1.0, escrita)
	_anim(tw, m, "aceso", 0.0, 1.0, 0.12).set_delay(escrita)
	_anim(tw, m, "corroi", 0.0, 1.0, 0.45).set_delay(maxf(dur - 0.45, escrita))
	tw.chain().tween_callback(n.queue_free)
	return n


## Vórtice preso a `pai` (tornado, aura): tubo com faixas de vento girando.
## Fica `dur` s e se desfaz. o: r_topo (> 1 abre em funil), altura, gira, y.
static func vortice(pai: Node3D, pal: Variant, raio: float, altura: float, dur: float, o: Dictionary = {}) -> Node3D:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(n)
	n.position.y = o.get("y", 0.1)
	var m := mat(pal, {
		"escala": o.get("escala", Vector2(1.0, 3.2)), "rola": Vector2(o.get("gira", 1.6), o.get("sobe", -0.35)),
		"forca": o.get("forca", 1.5), "base": o.get("base", 0.2), "topo": o.get("topo", 0.08), "tinta": o.get("tinta", 0.04),
		"teto": 4.0, "ondula": 0.05, "alfa": o.get("alfa", 1.0),
	})
	_malha(n, tubo(o.get("r_topo", 1.9), 0.0, 16, 4), m)
	n.scale = Vector3(raio * 0.4, altura * 0.3, raio * 0.4)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3(raio, altura, raio), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_anim(tw, m, "corroi", 0.0, 1.0, 0.35).set_delay(maxf(dur - 0.35, 0.0))
	tw.chain().tween_callback(n.queue_free)
	return n


## Anel de energia que sobe (subir de nível, captura, bênção): faixa num tubo.
static func anel_sobe(g: Node, pos: Vector3, pal: Variant, raio: float, sobe: float, vida := 1.0, atraso := 0.0) -> void:
	var n := _no(g, pos)
	var m := mat(pal, {"escala": Vector2(3.0, 0.5), "rola": Vector2(0.4, 0.0), "forca": 0.6, "base": 0.85, "topo": 0.85, "banda": 0.5, "centro": 0.5, "corroi": 1.0})
	_malha(n, tubo(1.0, 0.0, 20, 1), m)
	n.scale = Vector3(raio, raio * 0.22, raio)
	var tw := n.create_tween()
	tw.tween_interval(atraso)
	tw.tween_callback(func() -> void: m.set_shader_parameter("corroi", 0.0))
	tw.set_parallel()
	tw.tween_property(n, "global_position:y", pos.y + sobe, vida).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(n, "scale", Vector3(raio * 0.6, raio * 0.22, raio * 0.6), vida)
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("corroi", v), 0.0, 1.0, vida * 0.5).set_delay(vida * 0.5)
	tw.chain().tween_callback(n.queue_free)


## Lança/feixe de energia entre dois pontos: dois quads em cruz, o ruído corre
## ao longo do feixe. `cresce` > 0: o feixe nasce de `de` e chega em `ate`.
static func lanca(g: Node, de: Vector3, ate: Vector3, pal: Variant, larg := 0.3, vida := 0.35, o: Dictionary = {}) -> void:
	var d := ate - de
	var comp := d.length()
	if comp < 0.05:
		return
	var n := _no(g, de)
	n.look_at(ate, Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT)
	var m := mat(pal, {
		"escala": Vector2(1.0, maxf(comp * 0.25, 1.0)), "rola": Vector2(0.0, -o.get("corre", 3.0)),
		"forca": o.get("forca", 0.8), "base": 0.95, "topo": 0.95, "lados": 1.0, "tinta": o.get("tinta", 0.06),
	})
	_malha(n, _cruz(), m)
	n.scale = Vector3(larg, larg, comp)
	var tw := n.create_tween().set_parallel()
	var cresce: float = o.get("cresce", 0.0)
	if cresce > 0.0:
		n.scale.z = 0.05
		tw.tween_property(n, "scale:z", comp, cresce).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale:x", larg * 0.3, vida).set_ease(Tween.EASE_IN)
	tw.tween_property(n, "scale:y", larg * 0.3, vida).set_ease(Tween.EASE_IN)
	_anim(tw, m, "corroi", 0.0, 1.0, vida * 0.6).set_delay(vida * 0.4)
	tw.chain().tween_callback(n.queue_free)


## Dois quads em cruz ao longo de -Z (0 a -1), largura 1: U atravessa, V corre.
static func _cruz() -> ArrayMesh:
	return _c("cruz", func() -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for eixo: Vector3 in [Vector3.RIGHT, Vector3.UP]:
			var q := [[-0.5, 0.0], [0.5, 0.0], [0.5, 1.0], [-0.5, 0.0], [0.5, 1.0], [-0.5, 1.0]]
			for v: Array in q:
				st.set_uv(Vector2(v[0] + 0.5, v[1]))
				st.add_vertex(eixo * v[0] + Vector3(0, 0, -v[1]))
		return st.commit())


## Rachaduras de energia no chão saindo do centro (lava, gelo, luz): uma malha
## só para todas as fendas, cada uma um zigue-zague que afina na ponta.
static func rachaduras(g: Node, pos: Vector3, pal: Variant, raio: float, qtd := 9, vida := 1.3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in qtd:
		var a := TAU * i / qtd + randf_range(-0.22, 0.22)
		var comp := raio * randf_range(0.6, 1.0)
		var dir := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-dir.z, 0, dir.x)
		var pts: Array[Vector3] = [Vector3.ZERO]
		var passos := 4
		for k in range(1, passos + 1):
			pts.append(dir * comp * k / passos + lado * (randf_range(-0.35, 0.35) if k < passos else 0.0))
		for k in passos:
			var v0 := float(k) / passos
			var v1 := float(k + 1) / passos
			var w0 := lerpf(0.34, 0.05, v0)
			var w1 := lerpf(0.34, 0.05, v1)
			var a0 := pts[k] - lado * w0
			var b0 := pts[k] + lado * w0
			var a1 := pts[k + 1] - lado * w1
			var b1 := pts[k + 1] + lado * w1
			for q: Array in [[a0, 0.0, v0], [b0, 1.0, v0], [b1, 1.0, v1], [a0, 0.0, v0], [b1, 1.0, v1], [a1, 0.0, v1]]:
				st.set_uv(Vector2(q[1], q[2]))
				st.add_vertex(q[0])
	var n := _no(g, pos + Vector3(0, 0.07, 0))
	var m := mat(pal, {"escala": Vector2(1.0, 2.0), "rola": Vector2(0.0, -0.5), "forca": 0.45, "base": 0.95, "topo": 0.6, "lados": 0.9, "tinta": 0.1})
	_malha(n, st.commit(), m)
	n.scale = Vector3(0.2, 1, 0.2)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE, 0.12).set_ease(Tween.EASE_OUT)
	_anim(tw, m, "corroi", 0.0, 1.0, vida * 0.6).set_delay(vida * 0.4)
	tw.chain().tween_callback(n.queue_free)


## Bola de energia (bola de fogo, nuvem estilizada) que incha e se corrói.
static func bola(g: Node, pos: Vector3, pal: Variant, raio: float, vida := 0.5, o: Dictionary = {}) -> Node3D:
	var n := _no(g, pos)
	var m := mat(pal, {"escala": Vector2(2.0, 1.2), "rola": Vector2(0.1, o.get("sobe", 0.9)), "forca": o.get("forca", 1.0), "base": o.get("base", 0.55), "topo": o.get("topo", 0.7), "corroi": 0.15, "fresnel": 0.95})
	_malha(n, _esfera(), m)
	n.scale = Vector3.ONE * raio * 0.3
	var achata: float = o.get("achata", 0.75)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3(raio, raio * achata, raio), minf(0.18, vida * 0.4)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var segura: float = o.get("segura", 0.2)
	_anim(tw, m, "corroi", 0.15, 1.0, vida * (1.0 - segura)).set_delay(vida * segura)
	tw.chain().tween_callback(n.queue_free)
	return n


static func _esfera() -> SphereMesh:
	return _c("esfera", func() -> SphereMesh:
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 12
		s.rings = 6
		return s)


## Folhas/lascas girando em volta de `pai` e sendo puxadas (tufão, aura).
static func orbita(pai: Node3D, cor: Color, raio: float, dur: float, n := 12, altura := 1.2) -> void:
	if not enfeite():
		return
	var p := FxProjetil.ps(pai, Vector3(0, altura, 0), FxProjetil.lasca(0.3, 0.07), cor, n, 0.6, {
		"one_shot": false, "local": true, "local_pos": true, "radial": -raio * 4.0, "alinha": true, "rampa": "nasce", "s0": 0.6, "s1": 1.3,
		"g": Vector3(0, 2.5, 0),
	})
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = raio
	p.emission_ring_inner_radius = raio * 0.7
	p.emission_ring_height = altura
	p.tangential_accel_min = raio * 22.0
	p.tangential_accel_max = raio * 30.0
	var tw := p.create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func() -> void: p.emitting = false)
	tw.tween_interval(0.7)
	tw.tween_callback(p.queue_free)


## Brasas/faíscas contínuas subindo de `pai` enquanto um efeito dura (aura).
static func aura_brasas(pai: Node3D, cor: Color, dur: float, n := 8, raio := 0.5) -> void:
	if not enfeite():
		return
	var p := FxProjetil.ps(pai, Vector3(0, 0.9, 0), FxProjetil.quad("brilho", FxProjetil.tex_brilho(), false), cor, n, 0.7, {
		"one_shot": false, "local": false, "local_pos": true, "esfera": raio, "dir": Vector3.UP, "spread": 20.0,
		"v0": 1.2, "v1": 2.8, "rampa": "nasce", "s0": 0.1, "s1": 0.2,
	})
	var tw := p.create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func() -> void: p.emitting = false)
	tw.tween_interval(0.8)
	tw.tween_callback(p.queue_free)


## Ato 1: tudo é sugado para o ponto (faíscas vindas de fora) por `dur` s.
static func carga(g: Node, pos: Vector3, cor: Color, raio: float, dur: float, n := 14) -> void:
	if not enfeite():
		return
	FxProjetil.ps(g, pos, FxProjetil.lasca(0.34, 0.04), cor, n, dur, {
		"esfera": raio, "explosao": 0.55, "radial": -2.2 * raio / (dur * dur),
		"alinha": true, "rampa": "nasce", "s0": 0.7, "s1": 1.3,
	})


## Ato 3: brasas que sobem piscando depois do estouro.
static func brasas(g: Node, pos: Vector3, cor: Color, n: int, raio: float, vida := 1.3) -> void:
	if not enfeite():
		return
	FxProjetil.ps(g, pos + Vector3(0, 0.3, 0), FxProjetil.quad("brilho", FxProjetil.tex_brilho(), false), cor, n, vida, {
		"esfera": raio, "explosao": 0.7, "dir": Vector3.UP, "spread": 25.0, "v0": 0.8, "v1": 2.6,
		"g": Vector3(0, 0.6, 0), "rampa": "pisca", "s0": 0.1, "s1": 0.22,
	})


## Clarão que pinta chão e bonecos por um instante. Só na Alta (1 luz sem sombra).
static func clarao(g: Node, pos: Vector3, cor: Color, alcance: float, vida := 0.28, energia := 3.0) -> void:
	if Settings.quality < 3:
		return
	var l := OmniLight3D.new()
	l.light_color = cor
	l.light_energy = energia
	l.omni_range = alcance
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.light_specular = 0.0
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(l)
	l.global_position = pos + Vector3(0, 1.6, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, vida).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)


## Fita de rastro presa a `alvo` entre os pontos locais a e b. `dur` > 0 solta
## sozinha depois desse tempo; senão chame `soltar()` na fita devolvida.
static func fita(alvo: Node3D, a: Vector3, b: Vector3, pal: Variant, dur := 0.0, o: Dictionary = {}) -> Fita:
	var f := Fita.new()
	f.alvo = alvo
	f.a = a
	f.b = b
	f.pontos = o.get("pontos", 12)
	f.material_override = mat(pal, {
		"escala": Vector2(1.0, 1.4), "rola": Vector2(0.0, -2.0), "forca": o.get("forca", 0.7),
		"base": 0.9, "topo": 0.05, "lados": o.get("lados", 0.6), "tinta": o.get("tinta", 0.05),
	})
	alvo.add_child(f)
	if dur > 0.0:
		var tw := f.create_tween()
		tw.tween_interval(dur)
		tw.tween_callback(f.soltar)
	return f


## Compila os dois shaders no começo da partida (ver Fx.prewarm).
static func prewarm(parent: Node, pos: Vector3) -> void:
	chama(parent, pos, "raposa", 0.5, 0.5, 0.4)
	selo(parent, pos, "sombra", 0.5, 0.5)
