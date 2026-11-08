class_name MalhaUnica
extends RefCounted
## Junta as MeshInstance3D paradas debaixo de um nó numa malha só (Ciclo 2.17).
##
## Por quê: cada MeshInstance3D é pelo menos uma chamada de desenho por passe
## (cor, sombra por divisão, contorno). Um chapéu de 17 peças numa maquininha
## custava 17 chamadas e 17 sombras; oito maquininhas, 136. Num PC com placa
## integrada e no navegador, o custo por chamada (CPU do driver) pesa mais do
## que os triângulos. Juntar as peças que não se mexem sozinhas corta isso sem
## mudar um pixel.
##
## Como: para cada superfície, o material em uso vira uma "chave". Materiais
## StandardMaterial3D que só diferem na cor base (albedo) viram UM material com
## a cor gravada no vértice (`vertex_color_use_as_albedo`), desde que a cor
## caiba em 0..1 (a cor do vértice é guardada em 8 bits; cores HDR de brilho
## ficam em superfície própria). ShaderMaterial só junta com ele mesmo, e todos
## os canais da malha (UV2, CUSTOM, cor) são copiados como estão: o
## `pintura.gdshader` lê UV, UV2 e COLOR.a. A posição de cada peça relativa a
## `raiz` é gravada nos vértices.
##
## Canais ausentes ganham o valor padrão que a GPU já usaria (cor branca, UV e
## UV2 zero, tangente +X): assim duas peças do mesmo material juntam mesmo que
## uma tenha UV2 e a outra não. Dois ShaderMaterial com o mesmo shader e os
## mesmos parâmetros também juntam (o shader não pode ter `instance uniform`:
## o valor por instância se perderia). Rugosidade e metálico são arredondados
## a 0,5 na chave: no toon a diferença entre 0,4 e 0,6 não se vê.
##
## Limites: não junta peças com esqueleto (skin), nem as que estão dentro de
## um nó listado em `manter` (as que se mexem: braço da catapulta, telhado que
## cai).

const NOME := "MalhaUnica"
## Canais que toda superfície juntada passa a ter (preenchidos com o padrão).
const CANAIS_PADRAO := Mesh.ARRAY_FORMAT_COLOR | Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_TEX_UV2
const MASCARA_CUSTOM := (7 << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (7 << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
		| (7 << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) | (7 << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT)


## Junta e devolve a nova MeshInstance3D (filha direta de `raiz`), ou null se
## não havia o que juntar. As peças originais são apagadas.
static func juntar(raiz: Node3D, manter: Array = []) -> MeshInstance3D:
	var pecas: Array[MeshInstance3D] = []
	_coletar(raiz, manter, pecas)
	if pecas.size() < 2:
		return null
	var grupos := {}  # chave -> {mat, arr: Array (ARRAY_MAX), flags, n}
	var sombra := false
	for mi in pecas:
		if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			sombra = true
		var t := _relativa(mi, raiz)
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			var chave := _chave(mat)
			var albedo := chave.begins_with("albedo|")
			var fmt := _formato(mi.mesh, s)
			var presentes: int = (fmt & ((1 << Mesh.ARRAY_MAX) - 1)) | CANAIS_PADRAO
			if presentes & Mesh.ARRAY_FORMAT_NORMAL:
				presentes |= Mesh.ARRAY_FORMAT_TANGENT
			chave += "|%d|%d" % [presentes, fmt & MASCARA_CUSTOM]
			var g: Dictionary = grupos.get(chave, {})
			if g.is_empty():
				var arr := []
				arr.resize(Mesh.ARRAY_MAX)
				g = {"mat": _material_do_grupo(mat, albedo), "arr": arr, "flags": fmt & MASCARA_CUSTOM, "n": 0}
				grupos[chave] = g
			_despejar(g, mi.mesh, s, t, (mat as BaseMaterial3D).albedo_color if albedo else Color.WHITE, presentes)
	var malha := ArrayMesh.new()
	if OS.has_environment("MU_DEBUG"):
		print("MU %s/%s pecas=%d grupos=%d" % [raiz.get_parent().name if raiz.get_parent() else "", raiz.name, pecas.size(), grupos.size()])
		for chave in grupos:
			print("MU   ", chave.left(90), " n=", grupos[chave].n)
	for chave in grupos:
		var g: Dictionary = grupos[chave]
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, g.arr, [], {}, g.flags)
		malha.surface_set_material(malha.get_surface_count() - 1, g.mat)
	var mi := MeshInstance3D.new()
	mi.name = NOME
	mi.mesh = malha
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(mi)
	for p in pecas:
		p.get_parent().remove_child(p)
		p.free()
	return mi


## Nós que algum AnimationPlayer debaixo de `raiz` move: não podem ser juntados.
static func animados(raiz: Node) -> Array:
	var out := []
	for ap: AnimationPlayer in raiz.find_children("*", "AnimationPlayer", true, false):
		var base := ap.get_node_or_null(ap.root_node)
		if base == null:
			continue
		for nome in ap.get_animation_list():
			var an := ap.get_animation(nome)
			for t in an.get_track_count():
				var alvo := base.get_node_or_null(NodePath(String(an.track_get_path(t)).get_slice(":", 0)))
				if alvo and not alvo in out:
					out.append(alvo)
	return out


static func _coletar(n: Node, manter: Array, out: Array[MeshInstance3D]) -> void:
	for c in n.get_children():
		if c in manter:
			continue
		if c is Node3D and not (c as Node3D).visible:
			continue  # subárvore escondida: fica como está
		var mi := c as MeshInstance3D
		if mi and mi.mesh and mi.skin == null and mi.name != NOME \
				and mi.mesh.get_surface_count() > 0 and _juntavel(mi):
			out.append(mi)
		_coletar(c, manter, out)


## Só entra o que tem material conhecido (Standard ou Shader sem parâmetro por
## instância) e malha de triângulos.
static func _juntavel(mi: MeshInstance3D) -> bool:
	var am := mi.mesh as ArrayMesh
	for s in mi.mesh.get_surface_count():
		if am and am.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return false  # (PrimitiveMesh é sempre triângulos)
		var mat := mi.get_active_material(s)
		if mat == null or not (mat is BaseMaterial3D or mat is ShaderMaterial):
			return false
	return true


## Formato da superfície (bits ARRAY_FORMAT_*). PrimitiveMesh não tem
## surface_get_format: deduz pelos arrays presentes.
static func _formato(mesh: Mesh, s: int) -> int:
	var am := mesh as ArrayMesh
	if am:
		return am.surface_get_format(s)
	var arr := mesh.surface_get_arrays(s)
	var fmt := 0
	for k in Mesh.ARRAY_MAX:
		if arr[k] != null:
			fmt |= 1 << k
	return fmt


static func _relativa(n: Node3D, raiz: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var atual: Node = n
	while atual != null and atual != raiz:
		if atual is Node3D:
			t = (atual as Node3D).transform * t
		atual = atual.get_parent()
	return t


## Chave de agrupamento. Standard: tudo menos a cor base (que vai no vértice).
static func _chave(mat: Material) -> String:
	var bm := mat as BaseMaterial3D
	if bm == null:
		return _chave_shader(mat as ShaderMaterial)
	var c := bm.albedo_color
	var hdr := c.r > 1.0 or c.g > 1.0 or c.b > 1.0 or bm.albedo_texture != null or bm.vertex_color_use_as_albedo
	if hdr:
		return "res|" + str(mat.get_instance_id())
	return "albedo|%d|%d|%.1f|%.1f|%d|%s|%.2f|%d|%d|%d|%d|%d|%d|%d|%d" % [bm.shading_mode, bm.transparency,
			roundf(bm.metallic * 2.0) / 2.0, roundf(bm.roughness * 2.0) / 2.0,
			int(bm.emission_enabled), bm.emission.to_html(), bm.emission_energy_multiplier, bm.cull_mode, bm.billboard_mode,
			int(bm.no_depth_test), bm.next_pass.get_instance_id() if bm.next_pass else 0, bm.specular_mode, bm.diffuse_mode,
			int(c.a * 255), bm.render_priority]


## ShaderMaterial: mesmo shader + mesmos parâmetros = mesma chave, desde que
## o shader não tenha `instance uniform` (aí só junta com ele mesmo).
static func _chave_shader(sm: ShaderMaterial) -> String:
	if sm == null or sm.shader == null or sm.shader.code.contains("instance uniform"):
		return "res|" + str(sm.get_instance_id())
	var k := "sh|%d|%d|%d" % [sm.shader.get_instance_id(), sm.render_priority,
			sm.next_pass.get_instance_id() if sm.next_pass else 0]
	for u in sm.shader.get_shader_uniform_list():
		var nome: String = u.name
		k += "|%s=%s" % [nome, var_to_str(sm.get_shader_parameter(nome))]
	return k


static func _material_do_grupo(mat: Material, albedo: bool) -> Material:
	if not albedo:
		return mat
	var m := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
	m.albedo_color = Color(1, 1, 1, (mat as BaseMaterial3D).albedo_color.a)
	m.vertex_color_use_as_albedo = true
	return m


## Copia a superfície `s` para os arrays do grupo, com a posição relativa `t`
## gravada em vértice, normal e tangente, e a cor base multiplicada em COLOR.
## `presentes`: canais que o grupo tem; os que faltam na malha são preenchidos.
static func _despejar(g: Dictionary, mesh: Mesh, s: int, t: Transform3D, cor: Color, presentes: int) -> void:
	var arr := mesh.surface_get_arrays(s)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n := verts.size()
	var nb := t.basis.inverse().transposed()
	var out: Array = g.arr
	var base: int = g.n
	for k in Mesh.ARRAY_MAX:
		var a = arr[k]
		if a == null and presentes & (1 << k):
			a = _canal_padrao(k, n, cor)
		if a == null:
			continue
		match k:
			Mesh.ARRAY_VERTEX:
				var vs := PackedVector3Array()
				vs.resize(n)
				for i in n:
					vs[i] = t * verts[i]
				a = vs
			Mesh.ARRAY_NORMAL:
				var ns := PackedVector3Array()
				ns.resize(n)
				for i in n:
					ns[i] = (nb * (a as PackedVector3Array)[i]).normalized()
				a = ns
			Mesh.ARRAY_TANGENT:
				var tg := (a as PackedFloat32Array).duplicate()
				for i in n:
					var v := (t.basis * Vector3(tg[i * 4], tg[i * 4 + 1], tg[i * 4 + 2])).normalized()
					tg[i * 4] = v.x
					tg[i * 4 + 1] = v.y
					tg[i * 4 + 2] = v.z
				a = tg
			Mesh.ARRAY_COLOR:
				if cor != Color.WHITE:
					var cs := (a as PackedColorArray).duplicate()
					for i in n:
						cs[i] = cs[i] * cor
					a = cs
			Mesh.ARRAY_INDEX:
				var ix := (a as PackedInt32Array).duplicate()
				for i in ix.size():
					ix[i] += base
				a = ix
		if out[k] == null:
			out[k] = a.duplicate() if k != Mesh.ARRAY_VERTEX and k != Mesh.ARRAY_NORMAL and k != Mesh.ARRAY_INDEX else a
		else:
			out[k].append_array(a)
	if arr[Mesh.ARRAY_INDEX] == null:
		# Sem índice: cria um sequencial, para todo grupo acabar indexado.
		var ix := PackedInt32Array()
		ix.resize(n)
		for i in n:
			ix[i] = base + i
		if out[Mesh.ARRAY_INDEX] == null:
			out[Mesh.ARRAY_INDEX] = ix
		else:
			out[Mesh.ARRAY_INDEX].append_array(ix)
	g.n = base + n


## Valor padrão de um canal ausente (o mesmo que a GPU assume quando o
## atributo não existe), já pronto para `n` vértices.
static func _canal_padrao(k: int, n: int, cor: Color):
	match k:
		Mesh.ARRAY_COLOR:
			var cs := PackedColorArray()
			cs.resize(n)
			cs.fill(cor)
			return cs
		Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2:
			var uv := PackedVector2Array()
			uv.resize(n)
			return uv
		Mesh.ARRAY_TANGENT:
			var tg := PackedFloat32Array()
			tg.resize(n * 4)
			for i in n:
				tg[i * 4] = 1.0
				tg[i * 4 + 3] = 1.0
			return tg
	return null
