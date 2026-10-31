class_name NinjaVisual
extends RefCounted
## Visual dos ninjas: corpo KayKit com shader toon na cor do time + peças
## (chapéus, armas, máscaras) montadas por código a partir de formas simples.
##
## Desempenho: as peças NÃO viram um nó por peça. Todas as peças de um estilo
## entram numa malha só, presa ao mesmo esqueleto do corpo (cada vértice com
## peso 1 no osso da peça). Resultado: 1 chamada de desenho para as peças
## comuns + 1 para as de neon, por personagem, em vez de ~15.
##
## Estilo novo: crie uma função com o nome do estilo (ex.: `_samurai`) que
## chama `_peca(osso, malha, posição, rotação em graus, escala, material)`,
## e ponha o nome em `estilo_ninja` no .tres da classe.

const TOON := preload("res://assets/shaders/toon_time.gdshader")
const OUTLINE := preload("res://assets/shaders/contorno.gdshader")

const CIANO := Color(0.2, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.25, 0.85)
const FANTASMA := Color(0.45, 1.0, 0.45)
const OURO := Color(1.0, 0.78, 0.3)
const FOGO := Color(1.0, 0.45, 0.08)
const KITSUNEBI := Color(1.0, 0.45, 0.75)  # fogo de raposa (rosa: ciano = Shuriken, roxo = Kitsune Sombria)

static var _pecas_cache := {}   # "estilo|r,g,b" -> ArrayMesh
static var _corpo_cache := {}   # "textura|time|contorno" -> ShaderMaterial
static var _neon_mat: StandardMaterial3D
static var _outline_mat: ShaderMaterial

var _skin: Skin
var _st_toon := SurfaceTool.new()
var _st_neon := SurfaceTool.new()
var _tem_toon := false
var _tem_neon := false


## Aplica o visual no modelo já instanciado (filho de Unit/_visual).
## `corpo` são as malhas visíveis do corpo (já juntadas por Unit).
static func aplicar(model: Node3D, corpo: Array[MeshInstance3D], estilo: String, time: Color, cabeca: float, contorno: bool, extremidades := 1.0) -> MeshInstance3D:
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if sk == null:
		return null
	# Neon pede cor de time saturada (o tema pode trazer tons pastel).
	time = Color.from_hsv(time.h, maxf(time.s, 0.82), maxf(time.v, 0.95))
	var skin: Skin = null
	for mi in corpo:
		var tex := _textura(mi)
		mi.mesh = _com_pose_de_repouso(mi.mesh)
		mi.material_override = _material_corpo(tex, time, contorno)
		if mi.skin and skin == null:
			skin = mi.skin
	if cabeca != 1.0 or extremidades != 1.0:
		var mod := EscalaOssos.new()
		mod.escalas = {"head": cabeca}
		for osso in ["hand.l", "hand.r"]:
			mod.escalas[osso] = extremidades
		if cabeca < 0.8:
			# Proporção ~3,5 cabeças (Ciclo 2.2): além da cabeça menor, pernas
			# 20% mais compridas (coxa e canela no eixo do osso); o pé desfaz o
			# esticão herdado e ganha o tamanho de `extremidades`.
			var perna := 1.2
			for lado in [".l", ".r"]:
				mod.escalas["upperleg" + lado] = Vector3(1.0, perna, 1.0)
				mod.escalas["lowerleg" + lado] = Vector3(1.0, perna, 1.0)
				mod.escalas["foot" + lado] = Vector3(extremidades, extremidades / (perna * perna), extremidades)
			mod.subir_quadril = (0.52 - 0.15) * (perna - 1.0)
		else:
			for osso in ["foot.l", "foot.r"]:
				mod.escalas[osso] = extremidades
		sk.add_child(mod)
	if estilo == "" or skin == null:
		return null
	var key := "%s|%s|%s" % [estilo, time.to_html(false), contorno]
	var mesh: ArrayMesh = _pecas_cache.get(key)
	if mesh == null:
		var nv := NinjaVisual.new()
		nv._skin = skin
		mesh = nv._montar(estilo, time, contorno)
		_pecas_cache[key] = mesh
	if mesh.get_surface_count() == 0:
		return null
	var pecas := MeshInstance3D.new()
	pecas.name = "PecasNinja"
	pecas.mesh = mesh
	pecas.skin = skin
	sk.add_child(pecas)
	pecas.skeleton = pecas.get_path_to(sk)
	return pecas


static var _repouso_cache := {}   # Mesh -> Mesh com CUSTOM0


## Copia a malha guardando a posição de repouso de cada vértice em CUSTOM0.
## As marcas de poder (toon_time.gdshader) são desenhadas nessa posição, então
## ficam grudadas no corpo quando o boneco anima (em VERTEX elas "nadariam").
static func _com_pose_de_repouso(mesh: Mesh) -> Mesh:
	if mesh == null or not mesh is ArrayMesh:
		return mesh
	if _repouso_cache.has(mesh):
		return _repouso_cache[mesh]
	var novo := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var c0 := PackedFloat32Array()
		c0.resize(vs.size() * 4)
		for i in vs.size():
			c0[i * 4] = vs[i].x
			c0[i * 4 + 1] = vs[i].y
			c0[i * 4 + 2] = vs[i].z
			c0[i * 4 + 3] = 1.0
		arr[Mesh.ARRAY_CUSTOM0] = c0
		var flags: int = mesh.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		flags |= Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
		novo.add_surface_from_arrays(mesh.surface_get_primitive_type(s), arr, [], {}, flags)
		novo.surface_set_material(s, mesh.surface_get_material(s))
	_repouso_cache[mesh] = novo
	return novo


static func _textura(mi: MeshInstance3D) -> Texture2D:
	var m := mi.mesh.surface_get_material(0) if mi.mesh else null
	if m is StandardMaterial3D:
		return (m as StandardMaterial3D).albedo_texture
	var am := mi.get_active_material(0)
	if am is StandardMaterial3D:
		return (am as StandardMaterial3D).albedo_texture
	return null


static func _material_corpo(tex: Texture2D, time: Color, contorno: bool) -> ShaderMaterial:
	var key := "%s|%s|%s" % [tex.resource_path if tex else "", time.to_html(false), contorno]
	var m: ShaderMaterial = _corpo_cache.get(key)
	if m == null:
		m = ShaderMaterial.new()
		m.shader = TOON
		m.set_shader_parameter("textura", tex)
		m.set_shader_parameter("cor_time", time)
		m.set_shader_parameter("usar_marcas", true)
		if contorno:
			m.next_pass = _contorno()
		_corpo_cache[key] = m
	return m


static func _contorno() -> ShaderMaterial:
	if _outline_mat == null:
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = OUTLINE
	return _outline_mat


func _montar(estilo: String, time: Color, contorno: bool) -> ArrayMesh:
	for st in [_st_toon, _st_neon]:
		st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if has_method(estilo):
		call(estilo, time)
	var mesh := ArrayMesh.new()
	if _tem_toon:
		_st_toon.commit(mesh)
		var m := ShaderMaterial.new()
		m.shader = TOON
		m.set_shader_parameter("usar_cor_vertice", true)
		m.set_shader_parameter("cor_time", time)
		if contorno:
			m.next_pass = _contorno()
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	if _tem_neon:
		_st_neon.commit(mesh)
		if _neon_mat == null:
			_neon_mat = StandardMaterial3D.new()
			_neon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_neon_mat.vertex_color_use_as_albedo = true
			_neon_mat.vertex_color_is_srgb = true
			_neon_mat.albedo_color = Color(2.0, 2.0, 2.0)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _neon_mat)
	return mesh


## Índice do osso na pele (binds do KayKit são por nome).
func _bind(osso: String) -> int:
	for i in _skin.get_bind_count():
		if _skin.get_bind_name(i) == osso:
			return i
	return 0


## Junta a malha `mesh`, posta no espaço do osso, à malha de peças.
func _peca(osso: String, mesh: Mesh, pos: Vector3, rot: Vector3, esc: Vector3, mat: Dictionary) -> void:
	var b := _bind(osso)
	# Pele: final = pose_do_osso · bind · v. Queremos final = pose_do_osso · T · v,
	# então v_malha = bind⁻¹ · T · v.
	var basis := Basis.from_euler(rot * PI / 180.0, EULER_ORDER_YXZ) * Basis.from_scale(esc)
	var t := _skin.get_bind_pose(b).affine_inverse() * Transform3D(basis, pos)
	var nb := t.basis.inverse().transposed()
	var neon: bool = mat.neon
	var st := _st_neon if neon else _st_toon
	if neon:
		_tem_neon = true
	else:
		_tem_toon = true
	var cor: Color = mat.cor
	var ossos := PackedInt32Array([b, 0, 0, 0])
	var pesos := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var norms = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		var ordem: PackedInt32Array = idx if idx != null else PackedInt32Array(range(verts.size()))
		for i in ordem:
			st.set_color(cor)
			if norms != null and (norms as PackedVector3Array).size() > i:
				st.set_normal((nb * (norms as PackedVector3Array)[i]).normalized())
			st.set_bones(ossos)
			st.set_weights(pesos)
			st.add_vertex(t * verts[i])


func _plano(c: Color) -> Dictionary:
	return {"cor": c, "neon": false}


func _neon(c: Color, _forca := 1.8) -> Dictionary:
	return {"cor": c, "neon": true}


# --- Estilos ------------------------------------------------------------------

func _recruta(time: Color) -> void:
	# Faixa simples na testa: o recruta ainda não escolheu um papel.
	_peca("head", _cilindro(0.56, 0.56, 0.09), Vector3(0, 0.75, 0.0), Vector3(-6, 0, 0), Vector3.ONE, _plano(Color(0.92, 0.9, 0.85)))

func _samurai(time: Color) -> void:
	var cab := "head"
	# Kabuto: cúpula achatada + aba + chifres em lua crescente (neon)
	_peca(cab, _esfera(0.78, 0.5), Vector3(0, 0.7, -0.02), Vector3.ZERO, Vector3(1, 0.75, 1), _plano(time.darkened(0.1)))
	_peca(cab, _cilindro(0.66, 0.7, 0.08), Vector3(0, 0.55, -0.05), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.05, 0.05, 0.09)))
	for s in [-1, 1]:
		_peca(cab, _cone(0.1, 0.7), Vector3(0.28 * s, 1.0, 0.25), Vector3(-25, 0, -35 * s), Vector3.ONE, _neon(OURO))
	# Ombreiras quadradas (sode)
	for lado in ["upperarm.l", "upperarm.r"]:
		_peca(lado, _caixa(Vector3(0.42, 0.12, 0.5)), Vector3(0, 0.12, 0), Vector3(0, 0, 0), Vector3.ONE, _plano(time.darkened(0.2)))
	# Katana: lâmina com fio de neon, guarda e cabo
	var mao := "handslot.r"
	_peca(mao, _caixa(Vector3(0.05, 1.5, 0.12)), Vector3(0, 0.95, 0), Vector3.ZERO, Vector3.ONE, _neon(CIANO, 2.2))
	_peca(mao, _cilindro(0.13, 0.13, 0.04), Vector3(0, 0.2, 0), Vector3.ZERO, Vector3.ONE, _plano(OURO.darkened(0.3)))
	_peca(mao, _cilindro(0.05, 0.05, 0.35), Vector3(0, 0.0, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.1, 0.1, 0.12)))


func _ninja(time: Color) -> void:
	var cab := "head"
	# Máscara sobre nariz e boca + faixa na testa com fitas soltas
	_peca(cab, _esfera(0.5, 0.3), Vector3(0, 0.38, 0.12), Vector3.ZERO, Vector3(1.0, 0.55, 0.95), _plano(Color(0.07, 0.07, 0.12)))
	_peca(cab, _cilindro(0.56, 0.56, 0.09), Vector3(0, 0.78, 0.0), Vector3(-6, 0, 0), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	for s in [-1, 1]:
		_peca(cab, _caixa(Vector3(0.08, 0.5, 0.03)), Vector3(0.12 * s, 0.55, -0.6), Vector3(55, 0, 15 * s), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	# Shuriken na mão e duas nas costas
	var mao := "handslot.r"
	_peca(mao, _shuriken(), Vector3(0, 0.15, 0.1), Vector3(90, 0, 0), Vector3.ONE * 1.3, _neon(CIANO, 2.0))
	var peito := "chest"
	_peca(peito, _shuriken(), Vector3(0.22, 0.45, -0.45), Vector3(0, 0, 20), Vector3.ONE, _neon(CIANO, 1.5))
	_peca(peito, _shuriken(), Vector3(-0.22, 0.25, -0.45), Vector3(0, 0, -20), Vector3.ONE, _neon(CIANO, 1.5))


func _armadilheiro(time: Color) -> void:
	var cab := "head"
	# Óculos de solda com lente de neon + bandana
	for s in [-1, 1]:
		_peca(cab, _cilindro(0.13, 0.13, 0.12), Vector3(0.2 * s, 0.62, 0.45), Vector3(90, 0, 0), Vector3.ONE, _neon(FANTASMA, 1.8))
	_peca(cab, _cilindro(0.58, 0.6, 0.12), Vector3(0, 0.66, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.3)))
	# Cesto de palha nas costas, cheio de estrepes, com lanterna verde pendurada
	var peito := "chest"
	_peca(peito, _cilindro(0.42, 0.3, 0.8), Vector3(0, 0.45, -0.55), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.6, 0.45, 0.22)))
	for y in [0.2, 0.45, 0.7]:
		_peca(peito, _cilindro(0.39 + y * 0.05, 0.37 + y * 0.05, 0.05), Vector3(0, y + 0.02, -0.55), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.38, 0.26, 0.12)))
	for i in 5:
		var a := TAU * i / 5.0
		_peca(peito, _cone(0.06, 0.4), Vector3(cos(a) * 0.22, 0.98, -0.6 + sin(a) * 0.22), Vector3(sin(a) * 25, 0, -cos(a) * 25), Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))
	_peca(peito, _cilindro(0.015, 0.015, 0.25), Vector3(0.45, 0.6, -0.5), Vector3.ZERO, Vector3.ONE, _plano(Color(0.1, 0.1, 0.12)))
	_peca(peito, _caixa(Vector3(0.18, 0.24, 0.18)), Vector3(0.45, 0.38, -0.5), Vector3.ZERO, Vector3.ONE, _plano(Color(0.1, 0.1, 0.12)))
	_peca(peito, _esfera(0.09, 0.1), Vector3(0.45, 0.38, -0.5), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 3.0))
	# Mina na mão: disco escuro com luz verde no centro
	var mao := "handslot.r"
	_peca(mao, _cilindro(0.3, 0.33, 0.12), Vector3(0, 0.1, 0.15), Vector3(90, 0, 0), Vector3.ONE, _plano(Color(0.12, 0.13, 0.18)))
	_peca(mao, _esfera(0.1, 0.1), Vector3(0, 0.1, 0.24), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 3.0))
	# Chave inglesa na outra mão
	var mao_l := "handslot.l"
	_peca(mao_l, _caixa(Vector3(0.08, 0.7, 0.08)), Vector3(0, 0.3, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))
	_peca(mao_l, _caixa(Vector3(0.25, 0.1, 0.1)), Vector3(0, 0.68, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))


func _ronin_oni(time: Color) -> void:
	var cab := "head"
	# Máscara oni vermelho-escura com chifres de osso e presas
	_peca(cab, _esfera(0.5, 0.4), Vector3(0, 0.5, 0.25), Vector3.ZERO, Vector3(1.0, 0.9, 0.7), _plano(Color(0.55, 0.06, 0.08)))
	for s in [-1, 1]:
		_peca(cab, _cone(0.1, 0.5), Vector3(0.3 * s, 1.0, 0.15), Vector3(0, 0, -25 * s), Vector3.ONE, _plano(Color(0.92, 0.88, 0.75)))
		_peca(cab, _cone(0.05, 0.16), Vector3(0.15 * s, 0.28, 0.58), Vector3(180, 0, 0), Vector3.ONE, _plano(Color(0.95, 0.93, 0.85)))
		_peca(cab, _esfera(0.06, 0.04), Vector3(0.17 * s, 0.62, 0.6), Vector3.ZERO, Vector3.ONE, _neon(OURO, 2.5))
	# Juba selvagem
	for i in 6:
		var a := PI * (0.15 + 0.7 * i / 5.0)
		_peca(cab, _cone(0.14, 0.5), Vector3(cos(a) * 0.5, 0.75 + sin(a) * 0.15, -0.3), Vector3(-60, 0, -cos(a) * 70), Vector3.ONE, _plano(Color(0.06, 0.05, 0.08)))
	# Kanabo: clava grossa com cravos
	var mao := "handslot.r"
	_peca(mao, _cilindro(0.17, 0.07, 1.4), Vector3(0, 0.75, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.12, 0.1, 0.1)))
	for i in 6:
		var a := TAU * i / 6.0
		_peca(mao, _cone(0.04, 0.12), Vector3(cos(a) * 0.15, 0.9 + (i % 2) * 0.3, sin(a) * 0.15), Vector3(sin(a) * 90, 0, -cos(a) * 90), Vector3.ONE, _neon(OURO, 1.4))


func _arqueiro_yumi(time: Color) -> void:
	var cab := "head"
	_peca(cab, _cilindro(0.56, 0.56, 0.09), Vector3(0, 0.78, 0.0), Vector3(-6, 0, 0), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	# Yumi: arco alto e assimétrico (três segmentos) com corda de neon
	var mao := "handslot.l"
	_peca(mao, _caixa(Vector3(0.06, 1.3, 0.06)), Vector3(0, 0.55, 0.1), Vector3(0, 0, -12), Vector3.ONE, _plano(Color(0.15, 0.1, 0.08)))
	_peca(mao, _caixa(Vector3(0.06, 0.8, 0.06)), Vector3(0, -0.45, 0.1), Vector3(0, 0, 14), Vector3.ONE, _plano(Color(0.15, 0.1, 0.08)))
	_peca(mao, _caixa(Vector3(0.015, 2.1, 0.015)), Vector3(0.2, 0.15, 0.1), Vector3.ZERO, Vector3.ONE, _neon(CIANO, 2.0))
	# Aljava nas costas com penas na cor do time
	var peito := "chest"
	_peca(peito, _cilindro(0.16, 0.13, 0.85), Vector3(0.15, 0.45, -0.45), Vector3(0, 0, -25), Vector3.ONE, _plano(Color(0.15, 0.1, 0.08)))
	for i in 3:
		_peca(peito, _cone(0.06, 0.2), Vector3(0.32 + i * 0.06, 0.92 - i * 0.03, -0.45), Vector3(0, 0, -25), Vector3.ONE, _neon(time.lightened(0.3), 1.4))


func _polvora(time: Color) -> void:
	var cab := "head"
	for s in [-1, 1]:
		_peca(cab, _cilindro(0.13, 0.13, 0.12), Vector3(0.2 * s, 0.62, 0.45), Vector3(90, 0, 0), Vector3.ONE, _neon(FOGO, 1.8))
	_peca(cab, _cilindro(0.58, 0.6, 0.12), Vector3(0, 0.66, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.3)))
	# Barril de pólvora nas costas com cintas e pavio aceso
	var peito := "chest"
	_peca(peito, _cilindro(0.38, 0.38, 0.85), Vector3(0, 0.45, -0.55), Vector3.ZERO, Vector3.ONE, _plano(Color(0.42, 0.26, 0.13)))
	for y in [0.15, 0.75]:
		_peca(peito, _cilindro(0.4, 0.4, 0.06), Vector3(0, y, -0.55), Vector3.ZERO, Vector3.ONE, _plano(Color(0.15, 0.15, 0.18)))
	_peca(peito, _cilindro(0.02, 0.02, 0.3), Vector3(0, 0.98, -0.55), Vector3(0, 0, 20), Vector3.ONE, _plano(Color(0.2, 0.2, 0.2)))
	_peca(peito, _esfera(0.07, 0.07), Vector3(0.05, 1.12, -0.55), Vector3.ZERO, Vector3.ONE, _neon(FOGO, 3.0))
	# Bomba redonda na mão
	var mao := "handslot.r"
	_peca(mao, _esfera(0.25, 0.25), Vector3(0, 0.2, 0.15), Vector3.ZERO, Vector3.ONE, _plano(Color(0.06, 0.06, 0.09)))
	_peca(mao, _esfera(0.06, 0.06), Vector3(0, 0.5, 0.15), Vector3.ZERO, Vector3.ONE, _neon(FOGO, 3.0))


func _kitsune(time: Color) -> void:
	_raposa(Color(0.95, 0.94, 0.9), Color(1.0, 0.15, 0.2), KITSUNEBI, 4)


## Opostos do Ciclo 2.4 (Jogabilidade; o Visual pode refinar): mesma raposa,
## máscara e fogo trocados. Luz = máscara branca, marcas e chamas douradas
## (6 chamas); Sombria = máscara negra, marcas e chamas roxas.
func _kitsune_luz(time: Color) -> void:
	_raposa(Color(1.0, 0.98, 0.92), Color(1.0, 0.75, 0.2), Color(1.0, 0.85, 0.35), 6)


func _kitsune_sombria(time: Color) -> void:
	_raposa(Color(0.12, 0.1, 0.16), Color(0.75, 0.3, 1.0), Color(0.6, 0.25, 1.0), 4)


func _raposa(mascara: Color, marca: Color, fogo: Color, chamas: int) -> void:
	var cab := "head"
	# Máscara de raposa com marcas e orelhas
	_peca(cab, _esfera(0.45, 0.38), Vector3(0, 0.55, 0.3), Vector3.ZERO, Vector3(1, 1, 0.75), _plano(mascara))
	_peca(cab, _cone(0.16, 0.35), Vector3(0, 0.45, 0.65), Vector3(90, 0, 0), Vector3.ONE, _plano(mascara))
	for s in [-1, 1]:
		_peca(cab, _cone(0.15, 0.4), Vector3(0.3 * s, 1.05, 0.15), Vector3(0, 0, -15 * s), Vector3.ONE, _plano(mascara))
		_peca(cab, _caixa(Vector3(0.18, 0.04, 0.02)), Vector3(0.17 * s, 0.68, 0.64), Vector3(0, 0, -20 * s), Vector3.ONE, _neon(marca, 1.6))
	# Fogo de raposa (kitsunebi): chamas orbitando
	var peito := "chest"
	for i in chamas:
		var a := TAU * i / chamas + 0.4
		var p := Vector3(cos(a) * 0.8, 0.7 + 0.2 * (i % 2), sin(a) * 0.8)
		_peca(peito, _esfera(0.12, 0.14), p, Vector3.ZERO, Vector3.ONE, _neon(fogo, 2.4))
		_peca(peito, _cone(0.1, 0.3), p + Vector3(0, 0.2, 0), Vector3.ZERO, Vector3.ONE, _neon(fogo, 1.6))


## Construtor (Ciclo 2.4): operário simples. Hachimaki, armação de carregar
## nas costas (shoiko) com duas toras e a marreta de madeira (kizuchi). Os
## ramos (Armadilheiro, Bombardeiro) herdam a faixa e ganham óculos + carga.
func _construtor(time: Color) -> void:
	var cab := "head"
	_peca(cab, _cilindro(0.57, 0.57, 0.1), Vector3(0, 0.74, 0), Vector3(-6, 0, 0), Vector3.ONE, _plano(Color(0.95, 0.93, 0.86)))
	_peca(cab, _esfera(0.11, 0.09), Vector3(0.12, 0.8, -0.56), Vector3.ZERO, Vector3.ONE, _plano(Color(0.95, 0.93, 0.86)))
	_peca(cab, _caixa(Vector3(0.07, 0.22, 0.03)), Vector3(0.2, 0.68, -0.58), Vector3(30, 0, -30), Vector3.ONE, _plano(Color(0.95, 0.93, 0.86)))
	var peito := "chest"
	var mad := Color(0.55, 0.38, 0.2)
	for s in [-1, 1]:
		_peca(peito, _caixa(Vector3(0.07, 1.15, 0.07)), Vector3(0.24 * s, 0.4, -0.5), Vector3(-6, 0, 0), Vector3.ONE, _plano(mad.darkened(0.2)))
	_peca(peito, _caixa(Vector3(0.6, 0.07, 0.3)), Vector3(0, -0.12, -0.6), Vector3.ZERO, Vector3.ONE, _plano(mad.darkened(0.2)))
	for i in 2:
		var y := 0.1 + i * 0.3
		_peca(peito, _cilindro(0.13, 0.13, 0.85), Vector3(0, y, -0.62), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.42, 0.27, 0.15)))
		for s in [-1, 1]:
			_peca(peito, _cilindro(0.11, 0.11, 0.02), Vector3(0.43 * s, y, -0.62), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.86, 0.7, 0.45)))
	_peca(peito, _caixa(Vector3(0.7, 0.05, 0.05)), Vector3(0, 0.3, -0.48), Vector3.ZERO, Vector3.ONE, _plano(Color(0.85, 0.75, 0.5)))
	var mao := "handslot.r"
	_peca(mao, _cilindro(0.045, 0.045, 0.95), Vector3(0, 0.4, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.45, 0.3, 0.15)))
	_peca(mao, _cilindro(0.2, 0.2, 0.5), Vector3(0, 0.92, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.7, 0.52, 0.3)))
	for s in [-1, 1]:
		_peca(mao, _cilindro(0.21, 0.21, 0.05), Vector3(0.23 * s, 0.92, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.15, 0.15, 0.18)))


# --- Formas ------------------------------------------------------------------

func _esfera(r: float, h: float) -> Mesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s

func _cilindro(r_topo: float, r_base: float, h: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = r_topo
	c.bottom_radius = r_base
	c.height = h
	c.radial_segments = 12
	c.rings = 1
	return c

func _cone(r: float, h: float) -> Mesh:
	return _cilindro(0.0, r, h)

func _caixa(t: Vector3) -> Mesh:
	var b := BoxMesh.new()
	b.size = t
	return b

func _shuriken() -> Mesh:
	# Estrela de 4 pontas plana: 4 triângulos em volta de um quadrado
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.22
	var m := 0.06
	for i in 4:
		var a := TAU * i / 4.0
		var p := Vector3(cos(a), sin(a), 0) * r
		var e := Vector3(cos(a + PI / 4), sin(a + PI / 4), 0) * m
		var d := Vector3(cos(a - PI / 4), sin(a - PI / 4), 0) * m
		for f in [[Vector3.ZERO, d, p], [Vector3.ZERO, p, e], [Vector3.ZERO, p, d], [Vector3.ZERO, e, p]]:
			for v in f:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()
