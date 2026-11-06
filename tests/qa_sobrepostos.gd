extends RefCounted
## QA de faces sobrepostas (z-fighting). Duas faces viradas para o mesmo lado,
## no mesmo plano (distância < DIST) e se cobrindo: o teste de profundidade não
## sabe qual vem na frente e o vencedor muda a cada pixel conforme a câmera anda
## (o "chão piscando" de 2026-11-06). Parada, a câmera congela um padrão qualquer.
##
## Por quê: a profundidade guardada é ~1/z quantizado. Com perto = 0,5 m e
## 24 bits, a 30 m o degrau é z²/(perto·2^24) ≈ 0,1 mm; faces a 0 mm empatam
## e o arredondamento da interpolação decide. Por isso DIST pequeno basta.
##
## Uso: qa_mapa.gd chama achar(game) e recebe [[centro, área m², nós], ...].

const DIST := 0.004      # m entre os planos
const AREA_MIN := 0.02   # m² somados numa célula para virar problema
const CELULA := 2.0      # m (grade no plano para comparar só vizinhos)
const CEL_RELATO := 3.0  # m (área somada por célula de relato)


static func _triangulos(game) -> Array:
	var units := {}
	for u in game.units:
		units[u] = true
	var tris := []  # [a, b, c, nome do nó] em coordenadas do mundo
	var nos: Array = game.find_children("*", "MeshInstance3D", true, false)
	nos.append_array(game.find_children("*", "MultiMeshInstance3D", true, false))
	for no in nos:
		if not no.is_visible_in_tree() or no.name.begins_with("Enfeite_"):
			continue
		var pai: Node = no
		var de_boneco := false
		while pai != null:
			if units.has(pai):
				de_boneco = true
				break
			pai = pai.get_parent()
		if de_boneco:
			continue
		var mesh: Mesh
		var xfs: Array[Transform3D] = []
		if no is MeshInstance3D:
			if no.skin != null:
				continue
			mesh = no.mesh
			xfs.append(no.global_transform)
		else:
			var mm: MultiMesh = no.multimesh
			if mm == null:
				continue
			mesh = mm.mesh
			var n := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			for i in n:
				xfs.append(no.global_transform * mm.get_instance_transform(i))
		if not (mesh is ArrayMesh) and not (mesh is PrimitiveMesh):
			continue
		for s in mesh.get_surface_count():
			if mesh is ArrayMesh and mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arr: Array = mesh.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var n_i := idx.size() if idx.size() > 0 else vs.size()
			for xf in xfs:
				var i := 0
				while i + 2 < n_i:
					if idx.size() > 0:
						tris.append([xf * vs[idx[i]], xf * vs[idx[i + 1]], xf * vs[idx[i + 2]], _nome(no)])
					else:
						tris.append([xf * vs[i], xf * vs[i + 1], xf * vs[i + 2], _nome(no)])
					i += 3
	return tris


static func achar(game) -> Array:
	var tris := _triangulos(game)
	# Plano de cada triângulo; balde por normal (1/8) e por distância (DIST * 5).
	var baldes := {}
	var dados := []  # [n, d, a, b, c, nome]
	for t in tris:
		var a: Vector3 = t[0]
		var cr: Vector3 = (t[1] - a).cross(t[2] - a)
		if cr.length() < 2e-4:  # área < 1 cm²: não pesa
			continue
		# Godot: frente é a volta horária vista de fora; a normal aponta para fora com -cr.
		var n := -cr.normalized()
		var d := n.dot(a)
		var k := [Vector3i((n * 8.0).round()), floori(d / (DIST * 5.0))]
		dados.append([n, d, a, t[1], t[2], t[3]])
		if not baldes.has(k):
			baldes[k] = []
		baldes[k].append(dados.size() - 1)
	var por_cel := {}  # Vector3i -> [soma de pontos * área, área]
	var vistos := {}
	for k in baldes:
		# Junta o balde vizinho em d (o par pode cair na fronteira).
		var lista: Array = baldes[k].duplicate()
		var viz := [k[0], k[1] + 1]
		if baldes.has(viz):
			lista.append_array(baldes[viz])
		if lista.size() < 2:
			continue
		var n0: Vector3 = dados[lista[0]][0]
		var u := n0.cross(Vector3.UP if absf(n0.y) < 0.9 else Vector3.RIGHT).normalized()
		var v := n0.cross(u)
		var grade := {}
		var poli := {}
		for i in lista:
			var t: Array = dados[i]
			var p := PackedVector2Array([Vector2(t[2].dot(u), t[2].dot(v)), Vector2(t[3].dot(u), t[3].dot(v)), Vector2(t[4].dot(u), t[4].dot(v))])
			poli[i] = p
			var lo := Vector2(minf(p[0].x, minf(p[1].x, p[2].x)), minf(p[0].y, minf(p[1].y, p[2].y)))
			var hi := Vector2(maxf(p[0].x, maxf(p[1].x, p[2].x)), maxf(p[0].y, maxf(p[1].y, p[2].y)))
			for gx in range(floori(lo.x / CELULA), floori(hi.x / CELULA) + 1):
				for gy in range(floori(lo.y / CELULA), floori(hi.y / CELULA) + 1):
					var g := Vector2i(gx, gy)
					if not grade.has(g):
						grade[g] = []
					grade[g].append(i)
		for g in grade:
			var cel: Array = grade[g]
			for x in cel.size():
				for y in range(x + 1, cel.size()):
					var i: int = cel[x]
					var j: int = cel[y]
					var par := Vector2i(mini(i, j), maxi(i, j))
					if vistos.has(par):
						continue
					vistos[par] = true
					var ti: Array = dados[i]
					var tj: Array = dados[j]
					if ti[0].dot(tj[0]) < 0.995 or absf(ti[1] - tj[1]) > DIST:
						continue
					var area := 0.0
					for q in Geometry2D.intersect_polygons(poli[i], poli[j]):
						area += _area(q)
					if area < 1e-3:
						continue
					var centro: Vector3 = (ti[2] + ti[3] + ti[4]) / 3.0
					var kc := Vector3i((centro / CEL_RELATO).floor())
					if not por_cel.has(kc):
						por_cel[kc] = [Vector3.ZERO, 0.0, "", 0.0]
					por_cel[kc][0] += centro * area
					por_cel[kc][1] += area
					if area > por_cel[kc][3]:  # nome do maior par da célula
						por_cel[kc][3] = area
						por_cel[kc][2] = "%s/%s" % [ti[5], tj[5]]
	var out := []
	for kc in por_cel:
		var c = por_cel[kc]
		if c[1] >= AREA_MIN:
			out.append([c[0] / c[1], c[1], c[2]])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out


static func _area(p: PackedVector2Array) -> float:
	var s := 0.0
	for i in p.size():
		s += p[i].cross(p[(i + 1) % p.size()])
	return absf(s) / 2.0


## Nome legível: o nó e o pai com nome próprio (os gerados chamam-se @MeshInstance3D@N).
static func _nome(no: Node) -> String:
	var n := no.name as String
	var pai := no.get_parent()
	while pai != null and (pai.name as String).begins_with("@"):
		pai = pai.get_parent()
	return "%s/%s" % [pai.name if pai else "", n] if n.begins_with("@") else n
