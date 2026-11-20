class_name MalhaPintada
extends RefCounted
## Malhas no formato do pintura.gdshader (revisão 3c, FX-15/16): o material
## pintado do tema e os construtores que FxNatureza, FxObra e FxItens escreviam
## cada um do seu jeito (e chamavam os `_` privados um do outro).
## Vértice: COLOR.rgb = cor, COLOR.a = oclusão, UV.x = vento, UV.y = desenho
## (0 = liso, 1 = tábuas). Os construtores recebem a SurfaceTool já aberta.

static var _mats := {}


# --- Material ----------------------------------------------------------------------------

## Material pintado do tema (achado na árvore adulta da economia). Sem tema:
## material comum com cor de vértice.
static func material(g: Node) -> Material:
	var game := g as Game
	var th: ThemeConfig = game.arena.theme if game and game.arena else null
	var chave := th.resource_path if th else "_"
	if _mats.has(chave):
		return _mats[chave]
	var m: Material = null
	if th and th.arvore_estagios.size() >= 3 and th.arvore_estagios[2]:
		var tmp := th.arvore_estagios[2].instantiate()
		m = _achar_pintura(tmp)
		tmp.free()
	if m == null:
		var sm := StandardMaterial3D.new()
		sm.vertex_color_use_as_albedo = true
		sm.vertex_color_is_srgb = true
		sm.roughness = 0.9
		m = sm
	_mats[chave] = m
	return m


static func _achar_pintura(n: Node) -> Material:
	var mi := n as MeshInstance3D
	if mi and mi.mesh:
		for s in mi.mesh.get_surface_count():
			var mm := mi.mesh.surface_get_material(s)
			if mm is ShaderMaterial and (mm as ShaderMaterial).shader == Arena.PINTURA:
				return mm
	for c in n.get_children():
		var r := _achar_pintura(c)
		if r:
			return r
	return null


# --- Vértice e triângulo ---------------------------------------------------------------------

## Um vértice: COLOR.a = oclusão, UV.x = vento, UV.y = desenho (1 = tábuas).
static func vertice(st: SurfaceTool, p: Vector3, nrm: Vector3, cor: Color, ao: float, vento: float, desenho := 0.0) -> void:
	st.set_color(Color(cor.r, cor.g, cor.b, ao))
	st.set_uv(Vector2(vento, desenho))
	st.set_normal(nrm)
	st.add_vertex(p)


## Triângulo virado para `fora` (Godot desenha a frente no sentido horário visto
## de fora; a malha do cenário descarta a face de trás).
static func tri(st: SurfaceTool, a: Array, b: Array, c: Array, fora: Vector3) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	if (pb - pa).cross(pc - pa).dot(fora) > 0.0:
		var t := b
		b = c
		c = t
	for q: Array in [a, b, c]:
		vertice(st, q[0], q[1], q[2], q[3], q[4])


# --- Peças ---------------------------------------------------------------------------------------

## Tubo que afina ao longo de `pts` (galho, raiz, tronco, baqueta).
static func tubo(st: SurfaceTool, pts: Array, r0: float, r1: float, cor0: Color, cor1: Color, lados := 6,
		vento := Vector2.ZERO, ao := Vector2(0.65, 1.0)) -> void:
	var n := pts.size()
	var aneis := []
	for i in n:
		var t := float(i) / float(n - 1)
		var p: Vector3 = pts[i]
		var d: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var a := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var b := d.cross(a).normalized()
		var r := lerpf(r0, r1, t)
		var cor := cor0.lerp(cor1, t)
		var anel := []
		for j in lados + 1:
			var ang := TAU * j / lados
			var nrm := (a * cos(ang) + b * sin(ang)).normalized()
			anel.append([p + nrm * r, nrm, cor, lerpf(ao.x, ao.y, t), lerpf(vento.x, vento.y, t)])
		aneis.append(anel)
	for i in n - 1:
		for j in lados:
			var q0: Array = aneis[i][j]
			var q1: Array = aneis[i][j + 1]
			var q2: Array = aneis[i + 1][j + 1]
			var q3: Array = aneis[i + 1][j]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			tri(st, q0, q1, q2, fora)
			tri(st, q0, q2, q3, fora)
	# Tampa da ponta (raiz/galho cortado não fica oco).
	var ponta: Vector3 = pts[n - 1]
	var dp: Vector3 = (pts[n - 1] - pts[n - 2]).normalized()
	for j in lados:
		var a: Array = aneis[n - 1][j]
		var b: Array = aneis[n - 1][j + 1]
		tri(st, [ponta, dp, cor1, ao.y, vento.y], a, b, dp)


## Bolota achatada (pedaço de copa, musgo, nó).
static func bola(st: SurfaceTool, c: Vector3, r: float, esc: Vector3, cor: Color, vento := 0.0,
		ao_baixo := 0.6, seg := 7, aneis := 4) -> void:
	var pts := []
	for j in aneis + 1:
		var el := -PI * 0.5 + PI * j / aneis
		var linha := []
		for i in seg + 1:
			var az := TAU * i / seg
			var nrm := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
			var ao := lerpf(ao_baixo, 1.0, clampf(nrm.y * 0.5 + 0.5, 0.0, 1.0))
			linha.append([c + nrm * esc * r, (nrm / esc).normalized(), cor, ao, vento])
		pts.append(linha)
	for j in aneis:
		for i in seg:
			var q0: Array = pts[j][i]
			var q1: Array = pts[j][i + 1]
			var q2: Array = pts[j + 1][i + 1]
			var q3: Array = pts[j + 1][i]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			tri(st, q0, q1, q2, fora)
			tri(st, q0, q2, q3, fora)


## Corda torcida (shimenawa): toro com dois fios em espiral.
static func corda(st: SurfaceTool, c: Vector3, raio: float, grossura: float, cor: Color, seg := 18, lados := 6) -> void:
	var pts := []
	for i in seg + 1:
		var u := TAU * i / seg
		var centro := c + Vector3(cos(u), 0, sin(u)) * raio
		var radial := Vector3(cos(u), 0, sin(u))
		var linha := []
		for j in lados + 1:
			var v := TAU * j / lados
			var torce := 1.0 + 0.28 * sin(v * 2.0 + u * 9.0)  # os dois fios enrolados
			var nrm := (radial * cos(v) + Vector3.UP * sin(v)).normalized()
			var escuro := 0.82 + 0.18 * sin(v * 2.0 + u * 9.0)
			linha.append([centro + nrm * grossura * torce, nrm, cor * Color(escuro, escuro, escuro), 0.85 + 0.15 * nrm.y, 0.0])
		pts.append(linha)
	for i in seg:
		for j in lados:
			var q0: Array = pts[i][j]
			var q1: Array = pts[i + 1][j]
			var q2: Array = pts[i + 1][j + 1]
			var q3: Array = pts[i][j + 1]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			tri(st, q0, q1, q2, fora)
			tri(st, q0, q2, q3, fora)


## Caixa orientada (centro, meias-medidas, base) com as seis faces de fora.
static func caixa(st: SurfaceTool, c: Vector3, meia: Vector3, b: Basis, cor: Color, desenho := 1.0, ao := Vector2(0.7, 1.0), vento := 0.0) -> void:
	var eixos := [b.x * meia.x, b.y * meia.y, b.z * meia.z]
	for f in 3:
		for s in [-1.0, 1.0]:
			var nrm: Vector3 = (eixos[f] as Vector3).normalized() * s
			var u: Vector3 = eixos[(f + 1) % 3]
			var w: Vector3 = eixos[(f + 2) % 3]
			var centro: Vector3 = c + eixos[f] * s
			var q := [centro - u - w, centro + u - w, centro + u + w, centro - u + w]
			# frente no sentido horário visto de fora (o pintado descarta o verso)
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(nrm) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for i in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = q[i]
				var alto := clampf((p.y - c.y + meia.y) / maxf(meia.y * 2.0, 0.01), 0.0, 1.0) if absf(b.y.y) > 0.5 else 0.5
				vertice(st, p, nrm, cor, lerpf(ao.x, ao.y, alto), vento * (1.0 - alto), desenho)


static func novo() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func fim(st: SurfaceTool) -> ArrayMesh:
	st.index()
	return st.commit()


## Placa: polígono convexo no plano XY (centro em z = 0) com `esp` de espessura,
## faces da frente/trás e laterais. Pintada (UV.y = 0, liso).
static func placa(st: SurfaceTool, pts: Array, esp: float, cor: Color, cor_lado: Color, ao := 0.9) -> void:
	var n := pts.size()
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	c /= n
	for s in [1.0, -1.0]:
		var z: float = esp * 0.5 * s
		var nrm := Vector3(0, 0, s)
		var meio := [Vector3(c.x, c.y, z), nrm, cor, ao, 0.0]
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			tri(st, meio, [Vector3(a.x, a.y, z), nrm, cor, ao, 0.0], [Vector3(b.x, b.y, z), nrm, cor, ao, 0.0], nrm)
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var d := (b - a).normalized()
		var nrm := Vector3(d.y, -d.x, 0)
		if nrm.dot(Vector3(a.x - c.x, a.y - c.y, 0)) < 0.0:
			nrm = -nrm
		var h := esp * 0.5
		var q0 := [Vector3(a.x, a.y, h), nrm, cor_lado, ao, 0.0]
		var q1 := [Vector3(b.x, b.y, h), nrm, cor_lado, ao, 0.0]
		var q2 := [Vector3(b.x, b.y, -h), nrm, cor_lado, ao, 0.0]
		var q3 := [Vector3(a.x, a.y, -h), nrm, cor_lado, ao, 0.0]
		tri(st, q0, q1, q2, nrm)
		tri(st, q0, q2, q3, nrm)


## Círculo de `lados` pontos (para _placa).
static func circulo(c: Vector2, r: float, lados := 14) -> Array:
	var pts := []
	for i in lados:
		var a := TAU * i / lados
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## Aro (toro) no plano XY de raio `r`, centro em c.
static func aro(st: SurfaceTool, c: Vector3, r: float, gross: float, cor: Color, seg := 12, lados := 5) -> void:
	var pts := []
	for i in seg + 1:
		var u := TAU * i / seg
		var radial := Vector3(cos(u), sin(u), 0)
		var linha := []
		for j in lados + 1:
			var v := TAU * j / lados
			var nrm := (radial * cos(v) + Vector3(0, 0, 1) * sin(v)).normalized()
			linha.append([c + radial * r + nrm * gross, nrm, cor, 0.9, 0.0])
		pts.append(linha)
	for i in seg:
		for j in lados:
			var q0: Array = pts[i][j]
			var q1: Array = pts[i + 1][j]
			var q2: Array = pts[i + 1][j + 1]
			var q3: Array = pts[i][j + 1]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			tri(st, q0, q1, q2, fora)
			tri(st, q0, q2, q3, fora)
