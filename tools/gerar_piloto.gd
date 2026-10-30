extends "res://tools/gerar_mapa_rio.gd"
## Piloto do Ciclo 2.2 (docs/direcao-ciclo-2.2.md, seção 9, rodada 1): a casa
## comum da vila e a lanterna de pedra no nível máximo, com o material pintado
## (assets/shaders/pintura.gdshader). Gera, para o tema de dia e o Crepúsculo:
##   assets/ninja/<tema>/casa_piloto.scn e lanterna_piloto.scn
##   godot --headless --path . -s tools/gerar_piloto.gd
## O que muda em relação às peças antigas (só caixas e cilindros retos):
##   - quinas chanfradas (_bloco), paredes levemente tortas (deformação por cisalhamento);
##   - telhado como superfície curva (_superficie): perfil côncavo, meio cedendo,
##     pontas viradas para cima e espessura;
##   - oclusão pintada assada em COLOR.a (chão, frestas, embaixo do beiral);
##   - vento: peso por vértice em UV.x (cortina, roupas, folhas, lanternas).

const SHADER := preload("res://assets/shaders/pintura.gdshader")
const CONTORNO := preload("res://assets/shaders/contorno.gdshader")

## Paletas do piloto: "dia" é a do Festival ao Sol; "crepusculo" entra em
## TEMAS (gerar_cenario_ninja.gd) na rodada 2, quando o mapa inteiro for gerado.
var PALETAS := {
	"dia": TEMAS["dia"].merged({
		"sombra": Color(0.36, 0.42, 0.72), "forca_sombra": 0.16, "borda": Color(1.0, 0.9, 0.65), "tinta": Color(0.16, 0.08, 0.05), "reboco": Color(0.95, 0.86, 0.72),
	}, true),
	"crepusculo": {
		"pedra": Color(0.55, 0.5, 0.52), "pedra2": Color(0.4, 0.37, 0.42), "musgo": Color(0.27, 0.38, 0.2),
		"madeira": Color(0.3, 0.17, 0.12), "madeira2": Color(0.55, 0.33, 0.2), "reboco": Color(0.86, 0.78, 0.68),
		"telhado": Color(0.36, 0.27, 0.34), "folha": Color(0.22, 0.4, 0.2), "folha2": Color(0.36, 0.5, 0.24),
		"tronco": Color(0.3, 0.2, 0.16), "bambu": Color(0.36, 0.52, 0.26), "capim": Color(0.26, 0.42, 0.18),
		"capim2": Color(0.4, 0.48, 0.22), "torii": Color(0.7, 0.14, 0.1), "chao_folha": Color(0.85, 0.45, 0.16),
		"chao_folha2": Color(0.7, 0.25, 0.2), "agua": Color(0.16, 0.22, 0.36), "corda": Color(0.75, 0.62, 0.42),
		"montanha": Color(0.2, 0.18, 0.3), "neve": Color(0.75, 0.7, 0.8),
		"luz1": Color(1.0, 0.68, 0.3), "luz2": Color(1.0, 0.42, 0.22), "papel": Color(1.0, 0.78, 0.45),
		"ouro": Color(1.0, 0.75, 0.32), "branco": Color(0.92, 0.88, 0.84),
		"arvore": "sakura",
		"sombra": Color(0.38, 0.3, 0.68), "forca_sombra": 0.42, "borda": Color(1.0, 0.6, 0.32), "tinta": Color(0.06, 0.03, 0.06),
	},
}
const CORVO := Color(0.07, 0.06, 0.09)

var U := [PackedVector2Array(), PackedVector2Array()]
var _ao := 1.0       # oclusão pintada dos próximos vértices (1 = aberto)
var _vento := 0.0    # peso de vento dos próximos vértices
var _tipo := 0       # desenho do material (UV.y): 0 liso, 1 tábuas, 2 telhas, 3 pedras, 4 reboco
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	for tema in PALETAS:
		P = PALETAS[tema]
		_dir = "res://assets/ninja/" + tema
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
		_rng.seed = 7
		_casa_piloto(); _salvar("casa_piloto")
		_rng.seed = 11
		_lanterna_piloto(); _salvar("lanterna_piloto")
	print("triângulos: ", _tris)
	quit()


# --- Construtor: cor por vértice + oclusão (COLOR.a) + vento (UV.x) -------------

func _prim(mesh: PrimitiveMesh, pos: Vector3, rot_deg: Vector3, esc: Vector3, cor: Color, brilho: bool) -> void:
	super(mesh, pos, rot_deg, esc, cor, brilho)
	_sincronizar()


func _tri(a: Vector3, b: Vector3, c: Vector3, cor: Color, fora: Vector3, brilho := false) -> void:
	super(a, b, c, cor, fora, brilho)
	_sincronizar()


func _sincronizar() -> void:
	for s in 2:
		while U[s].size() < V[s].size():
			var i: int = U[s].size()
			U[s].append(Vector2(_vento, _tipo))
			var c: Color = C[s][i]
			c.a = _ao
			C[s][i] = c


## Marca onde a malha está, para mexer só no que vier depois (_vento_pendurado).
func _marca() -> Array:
	return [V[0].size(), V[1].size()]


## Vento de coisa pendurada: 0 no ponto de apoio (y = topo) até 1 a `comp` abaixo.
func _vento_pendurado(m: Array, topo: float, comp: float, forca := 1.0) -> void:
	for s in 2:
		for i in range(m[s], V[s].size()):
			U[s][i].x = clampf((topo - V[s][i].y) / comp, 0.0, 1.0) * forca


## Vento de planta: 0 na base (y = base) até 1 a `comp` acima.
func _vento_planta(m: Array, base: float, comp: float) -> void:
	for s in 2:
		for i in range(m[s], V[s].size()):
			U[s][i].x = clampf((V[s][i].y - base) / comp, 0.0, 1.0)


## Escurece o que já foi desenhado numa faixa de altura (embaixo do beiral):
## fator 1 em y0 até `fator` em y1, só dentro do retângulo |x| < mx, |z - cz| < mz.
func _sombra_faixa(y0: float, y1: float, fator: float, mx: float, mz: float, cz := 0.0) -> void:
	for i in V[0].size():
		var v: Vector3 = V[0][i]
		if v.y < y0 or v.y > y1 + 0.02 or absf(v.x) > mx or absf(v.z - cz) > mz:
			continue
		var c: Color = C[0][i]
		c.a *= lerpf(1.0, fator, clampf((v.y - y0) / (y1 - y0), 0.0, 1.0))
		C[0][i] = c


func _malha() -> ArrayMesh:
	# Oclusão de contato: tudo escurece perto do chão (a peça "senta" no terreno).
	for i in V[0].size():
		var c: Color = C[0][i]
		c.a *= lerpf(0.55, 1.0, smoothstep(0.0, 0.9, V[0][i].y))
		C[0][i] = c
	var mesh := ArrayMesh.new()
	_ultima_tris = 0
	for s in 2:
		if V[s].is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V[s]
		arr[Mesh.ARRAY_NORMAL] = N[s]
		arr[Mesh.ARRAY_COLOR] = C[s]
		arr[Mesh.ARRAY_TEX_UV] = U[s]
		arr[Mesh.ARRAY_INDEX] = I[s]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _mat(true) if s == 1 else _mat_pintura())
		_ultima_tris += I[s].size() / 3
	for s in 2:
		V[s] = PackedVector3Array()
		N[s] = PackedVector3Array()
		C[s] = PackedColorArray()
		U[s] = PackedVector2Array()
		I[s] = PackedInt32Array()
	_ao = 1.0
	_vento = 0.0
	_tipo = 0
	return mesh


func _mat_pintura() -> ShaderMaterial:
	var k := _dir + "pintura"
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("cor_sombra", P.sombra)
	m.set_shader_parameter("forca_sombra", P.forca_sombra)
	m.set_shader_parameter("cor_borda", P.borda)
	# Contorno de tinta igual ao dos bonecos (casca invertida), mais fino.
	var c := ShaderMaterial.new()
	c.shader = CONTORNO
	c.set_shader_parameter("espessura", 0.03)
	c.set_shader_parameter("cor", P.tinta)
	m.next_pass = c
	_mats[k] = m
	return m


# --- Formas novas -------------------------------------------------------------

## Caixa com quinas chanfradas (44 triângulos). `torcer` deforma os pontos no
## espaço local antes de girar/posicionar (paredes tortas, tábuas cedendo).
func _bloco(size: Vector3, pos: Vector3, basis: Basis, cor: Color, chanfro := 0.06, torcer := Callable()) -> void:
	var h := size / 2.0
	var c := minf(chanfro, minf(h.x, minf(h.y, h.z)) * 0.9)
	var pts := {}
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var s := Vector3(sx, sy, sz)
				for eixo in 3:
					var q := (h - Vector3(c, c, c)) * s
					q[eixo] = h[eixo] * s[eixo]
					if torcer.is_valid():
						q = torcer.call(q)
					pts[Vector3i(sx, sy, sz) * 4 + Vector3i(eixo, 0, 0)] = basis * q + pos
	var meio := pos
	var P_ := func(sx: int, sy: int, sz: int, eixo: int) -> Vector3:
		return pts[Vector3i(sx, sy, sz) * 4 + Vector3i(eixo, 0, 0)]
	var ordem := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
	for eixo in 3:
		var e1 := (eixo + 1) % 3
		var e2 := (eixo + 2) % 3
		for s in [-1, 1]:
			var q := []
			for o in ordem:
				var v := Vector3i.ZERO
				v[eixo] = s
				v[e1] = o.x
				v[e2] = o.y
				q.append(P_.call(v.x, v.y, v.z, eixo))
			var centro: Vector3 = (q[0] + q[2]) / 2.0
			_quad(q[0], q[1], q[2], q[3], cor, centro - meio)
		# Arestas ao longo de `eixo`.
		for o in ordem:
			var a := Vector3i.ZERO
			a[eixo] = -1
			a[e1] = o.x
			a[e2] = o.y
			var b := a
			b[eixo] = 1
			var q0: Vector3 = P_.call(a.x, a.y, a.z, e1)
			var q1: Vector3 = P_.call(b.x, b.y, b.z, e1)
			var q2: Vector3 = P_.call(b.x, b.y, b.z, e2)
			var q3: Vector3 = P_.call(a.x, a.y, a.z, e2)
			_quad(q0, q1, q2, q3, cor.darkened(0.04), (q0 + q2) / 2.0 - meio)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var a0: Vector3 = P_.call(sx, sy, sz, 0)
				var a1: Vector3 = P_.call(sx, sy, sz, 1)
				var a2: Vector3 = P_.call(sx, sy, sz, 2)
				_tri(a0, a1, a2, cor.darkened(0.04), (a0 + a1 + a2) / 3.0 - meio)


## Bloco reto alinhado aos eixos com rotação em graus (atalho de _bloco).
func _blocod(size: Vector3, pos: Vector3, rot: Vector3, cor: Color, chanfro := 0.06, torcer := Callable()) -> void:
	_bloco(size, pos, Basis.from_euler(rot * PI / 180.0), cor, chanfro, torcer)


## Viga chanfrada de `a` até `b` (postes tortos, cumeeiras, varal).
func _viga(a: Vector3, b: Vector3, esp: float, cor: Color, chanfro := 0.04) -> void:
	var d := b - a
	var cima := Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.FORWARD
	var basis := Basis.looking_at(d, cima)
	_bloco(Vector3(esp, esp, d.length()), (a + b) / 2.0, basis, cor, chanfro)


## Superfície com espessura a partir de uma função de altura y = f(x, z):
## telhados curvos. Topo em `cor`, fundo escuro e uma faixa na borda.
func _superficie(base: Vector3, f: Callable, x0: float, x1: float, z0: float, z1: float, nx: int, nz: int, esp: float, cor: Color, cor_borda: Color) -> void:
	var g := []
	for i in nx + 1:
		var linha := []
		for j in nz + 1:
			var x := lerpf(x0, x1, float(i) / nx)
			var z := lerpf(z0, z1, float(j) / nz)
			linha.append(base + Vector3(x, f.call(x, z), z))
		g.append(linha)
	var baixo := Vector3(0, -esp, 0)
	var ao_antes := _ao
	for i in nx:
		for j in nz:
			var a: Vector3 = g[i][j]
			var b: Vector3 = g[i + 1][j]
			var c: Vector3 = g[i + 1][j + 1]
			var d: Vector3 = g[i][j + 1]
			# Leve variação por telha-faixa: pincelada "na mão", não CG liso.
			var tom := cor.darkened(0.05 * float((i * 7 + j * 3) % 3))
			_tipo = 2
			_quad(a, b, c, d, tom, Vector3(0, 1, 0) + (a - base) * 0.05)
			_tipo = 0
			_ao = 0.45
			_quad(a + baixo, b + baixo, c + baixo, d + baixo, Color(0.12, 0.09, 0.1), Vector3(0, -1, 0))
			_ao = ao_antes
	# Faixa da borda (testeira de madeira).
	var borda := []
	for i in nx:
		borda.append([g[i][0], g[i + 1][0], Vector3(0, 0, -1)])
		borda.append([g[i][nz], g[i + 1][nz], Vector3(0, 0, 1)])
	for j in nz:
		borda.append([g[0][j], g[0][j + 1], Vector3(-1, 0, 0)])
		borda.append([g[nx][j], g[nx][j + 1], Vector3(1, 0, 0)])
	for e in borda:
		_quad(e[0], e[1], e[1] + baixo, e[0] + baixo, cor_borda, e[2])


## Altura do telhado de quatro águas japonês (cumeeira em x). Perfil côncavo
## (íngreme em cima, quase plano no beiral), meio da cumeeira cedendo e pontas
## do beiral viradas para cima.
func _altura_telhado(x: float, z: float, W: float, D: float, h: float, ceder: float, curva: float) -> float:
	var r := maxf(W - D, 0.0) / 2.0
	var fz := absf(z) / (D / 2.0)
	var fx := maxf(absf(x) - r, 0.0) / (D / 2.0)
	var fdist := clampf(maxf(fz, fx), 0.0, 1.0)
	var y := h * pow(1.0 - fdist, 1.6)
	y -= ceder * sin(PI * (x / W + 0.5)) * (1.0 - fdist * 0.6)
	var ax := absf(x) / (W / 2.0)
	y += curva * pow(ax * fz, 3.0) + curva * 0.25 * pow(fdist, 3.0)
	return y


# --- Casa comum da vila (piloto) ----------------------------------------------

## Machiya de 2 andares, mesma pegada da casa_a (5 x 4,5 m, frente em +z) para
## poder trocá-la no mapa: proporção gorda (telhado grande, porta baixa),
## tudo um pouco torto e o kit de entorno (barril, lenha, vaso, varal, lanternas).
func _casa_piloto() -> void:
	var w := 5.0
	var d := 4.5
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	# Alicerce: pedras irregulares em volta de uma laje.
	_tipo = 3
	_blocod(Vector3(w + 0.1, 0.26, d + 0.1), Vector3(0, 0.13, 0), Vector3.ZERO, P.pedra2, 0.05)
	for lado in 4:
		var comp := w if lado < 2 else d
		var x := -comp / 2.0
		while x < comp / 2.0 - 0.1:
			var lw := minf(_rng.randf_range(0.45, 0.85), comp / 2.0 - x)
			var cen := Vector3(x + lw / 2.0, 0.17, (d / 2.0 + 0.08) * (1 if lado == 0 else -1))
			if lado >= 2:
				cen = Vector3((w / 2.0 + 0.08) * (1 if lado == 2 else -1), 0.17, x + lw / 2.0)
			var tam := Vector3(lw - 0.04, _rng.randf_range(0.3, 0.4), 0.32)
			if lado >= 2:
				tam = Vector3(0.32, tam.y, lw - 0.04)
			var tom: Color = P.pedra.lerp(P.pedra2, _rng.randf()).lerp(P.musgo, 0.25 if _rng.randf() < 0.25 else 0.0)
			_blocod(tam, cen, Vector3(0, _rng.randf_range(-4, 4), _rng.randf_range(-3, 3)), tom, 0.08)
			x += lw
	# Térreo: 3 faixas de tábuas (o shader desenha 3 tábuas de 26 cm em cada),
	# cada faixa um pouco fora de esquadro (parede torta).
	_tipo = 1
	var y := 0.26
	var k := 0
	while y < 2.5:
		var tw := 0.78
		var desloc := 0.04 * float(k)  # a parede inteira tomba para a direita
		var tom := mad2.darkened(0.06 * float(k % 2) + _rng.randf_range(0.0, 0.05))
		_blocod(Vector3(w - 0.1, tw, d - 0.1), Vector3(desloc, y + tw / 2.0, 0), Vector3(0, 0, _rng.randf_range(-0.6, 0.6)), tom, 0.05)
		y += tw
		k += 1
	var topo_terreo := y
	_tipo = 0
	# Postes de canto e da frente, grossos e tortos.
	for p in [Vector2(-w / 2, d / 2), Vector2(w / 2, d / 2), Vector2(-w / 2, -d / 2), Vector2(w / 2, -d / 2), Vector2(-0.45, d / 2), Vector2(0.75, d / 2)]:
		var torto := Vector3(_rng.randf_range(-0.06, 0.1), 0, _rng.randf_range(-0.04, 0.04))
		_viga(Vector3(p.x, 0.28, p.y), Vector3(p.x, topo_terreo + 0.1, p.y) + torto, 0.26, mad, 0.05)
	# Viga da frente cedendo no meio.
	var meio_viga := Vector3(0.1, topo_terreo - 0.06, d / 2 + 0.05)
	_viga(Vector3(-w / 2 - 0.15, topo_terreo + 0.04, d / 2 + 0.05), meio_viga, 0.24, mad)
	_viga(meio_viga, Vector3(w / 2 + 0.2, topo_terreo + 0.05, d / 2 + 0.05), 0.24, mad)
	# Porta baixa com cortina noren (vento).
	_ao = 0.35
	_blocod(Vector3(1.0, 1.55, 0.08), Vector3(-1.45, 0.3 + 0.78, d / 2 - 0.0), Vector3.ZERO, Color(0.1, 0.07, 0.07), 0.02)
	_ao = 1.0
	_viga(Vector3(-2.02, 1.9, d / 2 + 0.08), Vector3(-0.88, 1.88, d / 2 + 0.08), 0.14, mad)
	var m := _marca()
	for j in 3:
		_blocod(Vector3(0.34, 0.62, 0.025), Vector3(-1.8 + j * 0.36, 1.53, d / 2 + 0.13), Vector3(0, 0, (j - 1) * 2.0), P.torii.lerp(P.madeira, 0.15 * j), 0.01)
	_vento_pendurado(m, 1.84, 0.62, 1.4)
	# Janela de papel acesa (aproveita o shoji das peças antigas).
	_shoji(Vector3(1.55, 1.4, d / 2 + 0.02), 1.5, 1.2, 1, P.papel)
	_blocod(Vector3(1.75, 0.1, 0.22), Vector3(1.55, 0.74, d / 2 + 0.1), Vector3.ZERO, mad, 0.03)
	_sombra_faixa(1.6, topo_terreo + 0.1, 0.62, w / 2 + 0.25, d / 2 + 0.3)
	# Aba de telhado do térreo (hisashi), cedendo no meio e virando nas pontas.
	var aba_w := w + 0.6
	var aba_d := 1.25
	var f_aba := func(x: float, z: float) -> float:
		var u := z / aba_d
		return -0.42 * u - 0.07 * sin(PI * (x / aba_w + 0.5)) * (0.4 + u) + 0.18 * pow(absf(x) / (aba_w / 2.0), 4.0) * u
	var base_aba := Vector3(0, topo_terreo + 0.22, d / 2 - 0.05)
	_superficie(base_aba, f_aba, -aba_w / 2, aba_w / 2, 0.0, aba_d, 10, 3, 0.1, P.telhado, mad)
	# Lanternas de papel penduradas nas pontas da aba (balançam).
	for s in [-1.0, 1.0]:
		var lp := Vector3(s * (w / 2 + 0.05), topo_terreo - 0.35, d / 2 + 0.95)
		m = _marca()
		_lanterna_papel(lp, P.luz2 if s < 0 else P.papel, 0.2)
		_vento_pendurado(m, lp.y + 0.5, 0.9, 0.9)
	# Segundo andar: reboco em 3 faixas, tombando para o outro lado.
	_tipo = 4
	var w2 := w - 0.35
	var d2 := d - 0.9
	var z2 := -0.35
	var y2 := topo_terreo + 0.05
	for j in 3:
		var hj := 0.62
		_blocod(Vector3(w2, hj, d2), Vector3(-0.015 * j, y2 + hj * (j + 0.5), z2), Vector3.ZERO, P.reboco.darkened(0.03 * j), 0.03)
	var topo2 := y2 + 1.86
	_tipo = 0
	for p in [Vector2(-w2 / 2, z2 + d2 / 2), Vector2(w2 / 2, z2 + d2 / 2), Vector2(-w2 / 2, z2 - d2 / 2), Vector2(w2 / 2, z2 - d2 / 2)]:
		_viga(Vector3(p.x, y2, p.y), Vector3(p.x - 0.05, topo2 + 0.05, p.y), 0.2, mad, 0.04)
	_viga(Vector3(-w2 / 2 - 0.1, y2 + 0.06, z2 + d2 / 2 + 0.04), Vector3(w2 / 2 + 0.1, y2 + 0.04, z2 + d2 / 2 + 0.04), 0.18, mad)
	# Treliça mushiko com luz por trás.
	_blocod(Vector3(3.2, 0.85, 0.03), Vector3(0, y2 + 0.95, z2 + d2 / 2 + 0.01), Vector3.ZERO, P.madeira.darkened(0.3), 0.01)
	_caixa(Vector3(3.0, 0.75, 0.02), Vector3(0, y2 + 0.95, z2 + d2 / 2 + 0.03), Vector3.ZERO, P.papel.darkened(0.1), true)
	for j in 8:
		_blocod(Vector3(0.08, 0.85, 0.08), Vector3(-1.4 + j * 0.4, y2 + 0.95, z2 + d2 / 2 + 0.07), Vector3.ZERO, mad, 0.02)
	_sombra_faixa(y2 + 1.1, topo2 + 0.06, 0.55, w2 / 2 + 0.2, d2 / 2 + 0.2, z2)
	# Telhado principal: grande (beiral de 0,85 m), curvo e cedendo.
	var W := w2 + 1.7
	var D := d2 + 1.7
	var hT := 1.35
	var f_tel := func(x: float, z: float) -> float:
		return _altura_telhado(x, z, W, D, hT, 0.16, 0.2)
	var base_tel := Vector3(0, topo2 + 0.1, z2)
	_superficie(base_tel, f_tel, -W / 2, W / 2, -D / 2, D / 2, 16, 10, 0.16, P.telhado, mad)
	var r := (W - D) / 2.0
	# Cumeeira (segue o meio cedido) com onigawara erguidas nas pontas.
	var crista := []
	for j in 7:
		var x := lerpf(-r - 0.1, r + 0.1, float(j) / 6.0)
		crista.append(base_tel + Vector3(x, f_tel.call(x, 0.0) + 0.1, 0))
	for j in 6:
		_viga(crista[j], crista[j + 1], 0.24, P.telhado.darkened(0.35), 0.06)
	for s in [-1.0, 1.0]:
		var ponta: Vector3 = crista[0] if s < 0 else crista[6]
		_blocod(Vector3(0.3, 0.55, 0.42), ponta + Vector3(s * 0.05, 0.18, 0), Vector3(0, 0, -s * 14.0), P.telhado.darkened(0.4), 0.1)
		# Espigões das quinas descendo até as pontas viradas.
		for t in [-1.0, 1.0]:
			var a := Vector3(s * (r + 0.05), 0, 0)
			var linha := []
			for j in 5:
				var u := float(j) / 4.0
				var px := lerpf(a.x, s * (W / 2 - 0.1), u)
				var pz := lerpf(0.0, t * (D / 2 - 0.1), u)
				linha.append(base_tel + Vector3(px, f_tel.call(px, pz) + 0.08, pz))
			for j in 4:
				_viga(linha[j], linha[j + 1], 0.14, P.telhado.darkened(0.3), 0.05)
	# Corvo na cumeeira (tom sombrio).
	var cv: Vector3 = crista[4] + Vector3(0, 0.22, 0)
	_esfera(0.2, cv, Vector3(1.5, 0.95, 0.9), CORVO, false, 8, 5)
	_esfera(0.12, cv + Vector3(0.24, 0.13, 0.02), Vector3.ONE, CORVO, false, 7, 4)
	_cil(0.0, 0.05, 0.16, 4, cv + Vector3(0.38, 0.12, 0.02), Vector3(0, 0, 90), Color(0.25, 0.22, 0.2))
	_blocod(Vector3(0.3, 0.05, 0.16), cv + Vector3(-0.32, -0.02, 0), Vector3(0, 0, 18), CORVO, 0.02)
	_esfera(0.025, cv + Vector3(0.31, 0.16, 0.1), Vector3.ONE, P.luz1, true, 4, 2)
	# Placa de madeira pendurada na lateral (+x).
	_viga(Vector3(w / 2 + 0.05, 2.25, d / 2 - 0.4), Vector3(w / 2 + 0.75, 2.25, d / 2 - 0.4), 0.1, mad)
	m = _marca()
	_blocod(Vector3(0.06, 0.95, 0.55), Vector3(w / 2 + 0.62, 1.68, d / 2 - 0.4), Vector3.ZERO, mad2.lightened(0.1), 0.03)
	_esfera(0.17, Vector3(w / 2 + 0.66, 1.75, d / 2 - 0.4), Vector3(0.25, 1, 1), P.torii, false, 8, 4)
	_vento_pendurado(m, 2.2, 1.0, 0.5)
	_kit_casa(w, d, topo_terreo)
	_aldeao(Vector3(0.2, 0, d / 2 + 1.25), 25.0, P.luz2.darkened(0.4), "varrer")


## Entorno da casa: o que faz ela parecer habitada.
func _kit_casa(w: float, d: float, topo_terreo: float) -> void:
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	# Barril de chuva na quina da frente, com calha de bambu.
	var bp := Vector3(w / 2 + 0.42, 0, d / 2 + 0.15)
	_cil(0.3, 0.26, 0.3, 10, bp + Vector3(0, 0.15, 0), Vector3.ZERO, mad2)
	_cil(0.27, 0.3, 0.32, 10, bp + Vector3(0, 0.46, 0), Vector3(0, 18, 0), mad2.darkened(0.05))
	for yy in [0.12, 0.62]:
		_cil(0.31, 0.31, 0.06, 10, bp + Vector3(0, yy, 0), Vector3.ZERO, Color(0.18, 0.14, 0.12))
	_cil(0.25, 0.25, 0.02, 10, bp + Vector3(0, 0.6, 0), Vector3.ZERO, P.agua.lightened(0.15), true)
	_viga(Vector3(w / 2 + 0.05, topo_terreo + 0.1, d / 2 + 0.15), bp + Vector3(0, 0.75, 0), 0.08, P.bambu, 0.02)
	# Lenha empilhada na lateral (-x) com uma tábua de cobertura.
	var lx := -w / 2 - 0.42
	for fila in 4:
		for j in 5 - fila % 2:
			var z := -1.3 + j * 0.27 + (0.13 if fila % 2 else 0.0)
			var lp := Vector3(lx + _rng.randf_range(-0.04, 0.04), 0.13 + fila * 0.23, z)
			_cil(0.11, 0.11, 0.62, 6, lp, Vector3(0, 0, 90), mad2.darkened(_rng.randf_range(0.0, 0.15)))
			_cil(0.085, 0.085, 0.01, 6, lp + Vector3(0.31, 0, 0), Vector3(0, 0, 90), mad2.lightened(0.35))
	_blocod(Vector3(0.9, 0.06, 1.7), Vector3(lx, 1.12, -0.85), Vector3(0, 0, 10), mad, 0.02)
	_blocod(Vector3(0.12, 0.2, 0.12), Vector3(lx + 0.15, 0.05, 0.1), Vector3(0, 30, 0), mad2, 0.02)  # toco
	# Vaso de barro com planta ao lado da porta (folhas no vento).
	var vp := Vector3(-0.55, 0, d / 2 + 0.45)
	_cil(0.2, 0.15, 0.38, 9, vp + Vector3(0, 0.19, 0), Vector3.ZERO, Color(0.6, 0.32, 0.2))
	_cil(0.22, 0.22, 0.06, 9, vp + Vector3(0, 0.38, 0), Vector3.ZERO, Color(0.52, 0.27, 0.17))
	var m := _marca()
	for j in 6:
		var ang := j * TAU / 6.0 + 0.3
		var dir := Vector3(cos(ang), 0, sin(ang))
		_esfera(0.2, vp + Vector3(0, 0.58, 0) + dir * 0.13, Vector3(0.5, 1.0, 0.28), P.folha.lerp(P.folha2, float(j % 2)), false, 6, 3)
	_esfera(0.16, vp + Vector3(0, 0.75, 0), Vector3(0.7, 1.0, 0.7), P.folha2, false, 6, 3)
	_vento_planta(m, 0.42, 0.5)
	# Banquinho e baldes.
	_blocod(Vector3(1.0, 0.08, 0.35), Vector3(0.95, 0.45, d / 2 + 0.55), Vector3(0, -4, 0), mad2, 0.02)
	for x in [0.6, 1.3]:
		_blocod(Vector3(0.08, 0.42, 0.3), Vector3(x, 0.21, d / 2 + 0.55), Vector3(0, -4, 0), mad, 0.02)
	_cil(0.14, 0.12, 0.24, 8, Vector3(1.2, 0.61, d / 2 + 0.55), Vector3.ZERO, mad2.lightened(0.1))
	# Fundos: porta baixa, janelinha e varal com roupas (vento).
	var zf := -d / 2 - 0.05
	_ao = 0.35
	_blocod(Vector3(0.85, 1.45, 0.06), Vector3(-1.2, 1.02, zf), Vector3.ZERO, Color(0.1, 0.07, 0.07), 0.02)
	_ao = 1.0
	_viga(Vector3(-1.7, 1.8, zf - 0.05), Vector3(-0.7, 1.78, zf - 0.05), 0.12, mad)
	_shoji(Vector3(1.2, 1.5, zf - 0.02), 1.0, 0.7, -1, P.papel)
	var zv := zf - 1.0
	var pa := Vector3(-w / 2 + 0.2, 0, zv)
	var pb := Vector3(w / 2 - 0.3, 0, zv - 0.2)
	_viga(pa, pa + Vector3(-0.05, 1.85, 0), 0.1, mad, 0.02)
	_viga(pb, pb + Vector3(0.06, 1.8, 0), 0.1, mad, 0.02)
	_viga(pa + Vector3(-0.05, 1.75, 0), pb + Vector3(0.06, 1.7, 0), 0.025, P.corda, 0.005)
	var cores := [P.luz2, P.branco, P.torii, P.telhado.lightened(0.3), P.agua.lightened(0.3)]
	for j in 5:
		var t := (j + 0.6) / 5.6
		var top := (pa + Vector3(-0.05, 1.75, 0)).lerp(pb + Vector3(0.06, 1.7, 0), t) - Vector3(0, 0.08 * sin(PI * t), 0)
		var alt := 0.55 if j % 2 else 0.75
		m = _marca()
		_blocod(Vector3(0.48, alt, 0.03), top - Vector3(0, alt / 2.0, 0), Vector3(0, -2.3, (j - 2) * 2.0), cores[j], 0.01)
		_vento_pendurado(m, top.y, alt, 1.3)
	# Pedras de pisar até a porta da frente.
	for j in 3:
		_blocod(Vector3(0.55, 0.1, 0.42), Vector3(-1.45 + j * 0.12, 0.04, d / 2 + 0.75 + j * 0.62), Vector3(0, j * 17.0, 0), P.pedra.lightened(0.05), 0.05)


# --- Lanterna de pedra (piloto) -----------------------------------------------

## Kasuga-dōrō: base sextavada, coluna com barriga, caixa de fogo acesa,
## chapéu sextavado com pontas viradas e joia no topo. Velha: inclinada,
## com musgo no chapéu e na base, pedrinhas e um tufo de capim no pé.
func _lanterna_piloto() -> void:
	var pedra: Color = P.pedra
	var p2: Color = P.pedra2
	var inc := Basis.from_euler(Vector3(deg_to_rad(2.5), 0, deg_to_rad(-2.0)))
	var ap := func(v: Vector3) -> Vector3:
		return inc * v
	# Base: degrau sextavado + pedras ao redor.
	_cil(0.62, 0.68, 0.18, 6, Vector3(0, 0.09, 0), Vector3.ZERO, p2)
	_cil(0.5, 0.56, 0.2, 6, ap.call(Vector3(0, 0.28, 0)), Vector3(2.5, 30, -2), pedra)
	# Coluna com barriga (3 trechos) e anéis.
	_cil(0.17, 0.2, 0.35, 8, ap.call(Vector3(0, 0.55, 0)), Vector3(2.5, 0, -2), pedra)
	_cil(0.2, 0.17, 0.35, 8, ap.call(Vector3(0, 0.9, 0)), Vector3(2.5, 0, -2), pedra)
	_cil(0.22, 0.22, 0.06, 8, ap.call(Vector3(0, 0.72, 0)), Vector3(2.5, 0, -2), p2)
	# Prato sob a caixa de fogo.
	_cil(0.42, 0.24, 0.16, 6, ap.call(Vector3(0, 1.15, 0)), Vector3(2.5, 30, -2), pedra)
	# Caixa de fogo: luz por dentro, 6 colunas de pedra e janelas recortadas.
	_cil(0.26, 0.26, 0.42, 6, ap.call(Vector3(0, 1.44, 0)), Vector3(2.5, 0, -2), P.papel, true)
	for j in 6:
		var a := j * TAU / 6.0
		var c := Vector3(cos(a), 0, sin(a)) * 0.29
		_bloco(Vector3(0.1, 0.44, 0.1), ap.call(Vector3(0, 1.44, 0) + c), inc * Basis(Vector3.UP, -a), pedra, 0.03)
	_cil(0.36, 0.33, 0.06, 6, ap.call(Vector3(0, 1.67, 0)), Vector3(2.5, 30, -2), p2)
	# Chapéu: superfície sextavada com perfil côncavo e pontas viradas.
	var topo: Vector3 = ap.call(Vector3(0, 2.02, 0))
	var anel := []
	var sub := 3
	for j in 6 * sub:
		var a := j * TAU / (6 * sub)
		var ponta := 1.0 if j % sub == 0 else 0.0
		var rr := 0.7 + 0.06 * ponta
		anel.append(ap.call(Vector3(cos(a) * rr, 1.72 + 0.14 * ponta, sin(a) * rr)))
	var meio := []
	for j in 6 * sub:
		var a := j * TAU / (6 * sub)
		meio.append(ap.call(Vector3(cos(a) * 0.36, 1.86, sin(a) * 0.36)))
	var n := anel.size()
	for j in n:
		var j2 := (j + 1) % n
		var fora: Vector3 = (anel[j] + anel[j2]) / 2.0 - topo + Vector3(0, 0.6, 0)
		var tom := pedra.darkened(0.04 * float(j % 2))
		_quad(anel[j], anel[j2], meio[j2], meio[j], tom, fora)
		_tri(meio[j], meio[j2], topo, tom.lightened(0.03), fora + Vector3(0, 0.5, 0))
		_ao = 0.45
		_tri(anel[j] - Vector3(0, 0.07, 0), anel[j2] - Vector3(0, 0.07, 0), ap.call(Vector3(0, 1.66, 0)), p2.darkened(0.3), Vector3(0, -1, 0))
		_ao = 1.0
		_quad(anel[j], anel[j2], anel[j2] - Vector3(0, 0.07, 0), anel[j] - Vector3(0, 0.07, 0), p2, fora - Vector3(0, 0.6, 0))
	# Joia (hōju) no topo.
	_cil(0.1, 0.13, 0.1, 8, topo + Vector3(0, 0.04, 0), Vector3.ZERO, p2)
	_esfera(0.13, topo + Vector3(0, 0.2, 0), Vector3(1, 1.1, 1), pedra, false, 8, 5)
	_cil(0.0, 0.05, 0.1, 6, topo + Vector3(0, 0.36, 0), Vector3.ZERO, pedra)
	# Musgo (manchas gordas, baixa frequência) no chapéu e na base.
	for j in 4:
		var a := _rng.randf() * TAU
		var pm: Vector3 = ap.call(Vector3(cos(a) * 0.45, 1.84, sin(a) * 0.45))
		_esfera(0.13, pm, Vector3(1.3, 0.25, 1.0), P.musgo.lerp(pedra, 0.55 + _rng.randf() * 0.2), false, 7, 3)
	for j in 3:
		var a := _rng.randf() * TAU
		_esfera(0.16, Vector3(cos(a) * 0.55, 0.2, sin(a) * 0.55), Vector3(1.3, 0.3, 1.0), P.musgo.lerp(p2, 0.3), false, 7, 3)
	# Pedrinhas e capim no pé.
	for j in 5:
		var a := _rng.randf() * TAU
		var pr := Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.75, 1.0)
		_esfera(_rng.randf_range(0.07, 0.13), pr + Vector3(0, 0.04, 0), Vector3(1.2, 0.7, 1.0), p2.lightened(_rng.randf() * 0.15), false, 6, 3)
	var m := _marca()
	for j in 7:
		var a := 0.6 + j * 0.25
		var base := Vector3(cos(a), 0, sin(a)) * 0.78
		_cil(0.0, 0.05, _rng.randf_range(0.3, 0.5), 3, base + Vector3(0, 0.18, 0), Vector3(_rng.randf_range(-20, 20), 0, _rng.randf_range(-20, 20)), P.capim.lerp(P.capim2, _rng.randf()))
	_vento_planta(m, 0.0, 0.45)
