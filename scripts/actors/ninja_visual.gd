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
const OUTLINE := preload("res://assets/shaders/contorno_boneco.gdshader")
const RAIO_X := preload("res://assets/shaders/raio_x.gdshader")
const NEON := preload("res://assets/shaders/neon_pecas.gdshader")

const CIANO := Color(0.2, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.25, 0.85)
const FANTASMA := Color(0.45, 1.0, 0.45)
const OURO := Color(1.0, 0.78, 0.3)
const FOGO := Color(1.0, 0.45, 0.08)
const KITSUNEBI := Color(1.0, 0.45, 0.75)  # fogo de raposa (rosa: ciano = Shuriken, roxo = Kitsune Sombria)

static var _pecas_cache := {}   # "estilo|r,g,b" -> ArrayMesh
static var _corpo_cache := {}   # "textura|time|contorno" -> ShaderMaterial
static var _neon_mat: ShaderMaterial
static var _outline_mat: ShaderMaterial
static var _raio_x_cache := {}  # cor do time -> ShaderMaterial (silhueta atrás de parede)

var _skin: Skin
var _st_toon := SurfaceTool.new()
var _st_neon := SurfaceTool.new()
var _tem_toon := false
var _tem_neon := false
## Nível visual do estilo (Kitsune Luz/Sombria: 2-5 = número de caudas).
var _nivel := 1


## Neon pede cor de time saturada (o tema pode trazer tons pastel).
static func cor_neon(time: Color) -> Color:
	return Color.from_hsv(time.h, maxf(time.s, 0.82), maxf(time.v, 0.95))


## Aplica o visual no modelo já instanciado (filho de Unit/_visual).
## `corpo` são as malhas visíveis do corpo (já juntadas por Unit).
static func aplicar(model: Node3D, corpo: Array[MeshInstance3D], estilo: String, time: Color, cabeca: float, contorno: bool, extremidades := 1.0, nivel := 1, raio_x_pecas := true) -> MeshInstance3D:
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if sk == null:
		return null
	time = cor_neon(time)
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
	return pecas(sk, skin, estilo, time, contorno, nivel, raio_x_pecas)


## Só a malha de peças (sem mexer no corpo): serve para trocar o nível visual
## (caudas da Kitsune) sem refazer o boneco. `time` já saturado por aplicar.
## `raio_x`: as peças também acendem atrás de parede (passe raio_x.gdshader por
## superfície). O corpo sempre acende; nas peças é só na qualidade Alta (2.17):
## tira 1 chamada por boneco e a silhueta continua legível só pelo corpo.
static func pecas(sk: Skeleton3D, skin: Skin, estilo: String, time: Color, contorno: bool, nivel := 1, raio_x := true) -> MeshInstance3D:
	if estilo == "" or skin == null:
		return null
	var key := "%s|%s|%s|%d|%s" % [estilo, time.to_html(false), contorno, nivel, raio_x]
	var mesh: ArrayMesh = _pecas_cache.get(key)
	if mesh == null:
		var nv := NinjaVisual.new()
		nv._skin = skin
		nv._nivel = nivel
		mesh = nv._montar(estilo, time, contorno, raio_x)
		_pecas_cache[key] = mesh
	if mesh.get_surface_count() == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.name = "PecasNinja"
	mi.mesh = mesh
	mi.skin = skin
	sk.add_child(mi)
	mi.skeleton = mi.get_path_to(sk)
	# Caudas e fogo mexem no vertex shader: a caixa de corte precisa de folga.
	mi.extra_cull_margin = 0.5
	return mi


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
		m.next_pass = _raio_x(time, contorno)
		_corpo_cache[key] = m
	return m


static func _contorno() -> ShaderMaterial:
	if _outline_mat == null:
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = OUTLINE
	return _outline_mat


## Passe de raio X (raio_x.gdshader), seguido do contorno de tinta se houver.
static func _raio_x(time: Color, contorno: bool) -> ShaderMaterial:
	var key := "%s|%s" % [time.to_html(false), contorno]
	var m: ShaderMaterial = _raio_x_cache.get(key)
	if m == null:
		m = ShaderMaterial.new()
		m.shader = RAIO_X
		m.set_shader_parameter("cor_time", time)
		m.render_priority = 1  # depois dos outros transparentes: fica por cima
		if contorno:
			m.next_pass = _contorno()
		_raio_x_cache[key] = m
	return m


func _montar(estilo: String, time: Color, contorno: bool, raio_x := true) -> ArrayMesh:
	for st in [_st_toon, _st_neon]:
		st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)
	if has_method(estilo):
		call(estilo, time)
	var mesh := ArrayMesh.new()
	if _tem_toon:
		_st_toon.commit(mesh)
		var m := ShaderMaterial.new()
		m.shader = TOON
		m.set_shader_parameter("usar_cor_vertice", true)
		m.set_shader_parameter("cor_time", time)
		m.next_pass = _raio_x(time, contorno) if raio_x else (_contorno() if contorno else null)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	if _tem_neon:
		_st_neon.commit(mesh)
		if _neon_mat == null:
			_neon_mat = ShaderMaterial.new()
			_neon_mat.shader = NEON
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
	# Balanço (balanco.gdshaderinc): Vector3(peso, fase, tipo). Nas malhas com
	# UV (caudas), o peso vezes UV.x: zero na base, cheio na ponta.
	var bal: Vector3 = mat.get("balanco", Vector3.ZERO)
	var ossos := PackedInt32Array([b, 0, 0, 0])
	var pesos := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var norms = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		var cores = arr[Mesh.ARRAY_COLOR] if mat.get("cor_vertice", false) else null
		var uvs = arr[Mesh.ARRAY_TEX_UV] if mat.get("peso_uv", false) else null
		var ordem: PackedInt32Array = idx if idx != null else PackedInt32Array(range(verts.size()))
		for i in ordem:
			st.set_color(cor * (cores as PackedColorArray)[i] if cores != null else cor)
			var peso := bal.x * ((uvs as PackedVector2Array)[i].x if uvs != null else 1.0)
			st.set_custom(1, Color(peso, bal.y, bal.z, 0.0))
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
	var laca := Color(0.08, 0.08, 0.14)
	# Kabuto: cúpula achatada + aba + chifres em lua crescente (neon)
	_peca(cab, _esfera(0.78, 0.5), Vector3(0, 0.7, -0.02), Vector3.ZERO, Vector3(1, 0.75, 1), _plano(time.darkened(0.1)))
	_peca(cab, _cilindro(0.66, 0.7, 0.08), Vector3(0, 0.55, -0.05), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.05, 0.05, 0.09)))
	for s in [-1, 1]:
		_peca(cab, _cone(0.1, 0.7), Vector3(0.28 * s, 1.0, 0.25), Vector3(-25, 0, -35 * s), Vector3.ONE, _neon(OURO))
	# Mon (brasão) do time na testa do elmo
	_peca(cab, _cilindro(0.11, 0.11, 0.04), Vector3(0, 0.66, 0.74), Vector3(72, 0, 0), Vector3.ONE, _neon(time.lightened(0.3), 1.6))
	# Shikoro: protetor de nuca em três lâminas, só atrás e dos lados (o rosto
	# fica livre), e fukigaeshi, as abas viradas para fora ao lado do rosto
	for i in 3:
		var y := 0.48 - i * 0.13
		var r := 0.7 + i * 0.07
		for a in [-55.0, 0.0, 55.0]:
			var ar := deg_to_rad(a)
			_peca(cab, _caixa(Vector3(0.62 + i * 0.04, 0.12, 0.06)), Vector3(sin(ar) * r, y, -cos(ar) * r * 0.85), Vector3(-22 - i * 6, a, 0), Vector3.ONE,
					_plano(laca.lightened(0.06) if i % 2 == 0 else time.darkened(0.45)))
	for s in [-1, 1]:
		_peca(cab, _caixa(Vector3(0.06, 0.26, 0.24)), Vector3(0.7 * s, 0.5, 0.18), Vector3(0, 30 * s, 12 * s), Vector3.ONE, _plano(time.darkened(0.15)))
	# Sode: ombreiras em duas lâminas, a de baixo mais larga
	for lado in ["upperarm.l", "upperarm.r"]:
		_peca(lado, _caixa(Vector3(0.42, 0.12, 0.5)), Vector3(0, 0.12, 0), Vector3(0, 0, 0), Vector3.ONE, _plano(time.darkened(0.2)))
		_peca(lado, _caixa(Vector3(0.46, 0.1, 0.54)), Vector3(0, 0.24, 0), Vector3(0, 0, 0), Vector3.ONE, _plano(laca))
		_peca(lado, _caixa(Vector3(0.47, 0.03, 0.55)), Vector3(0, 0.3, 0), Vector3(0, 0, 0), Vector3.ONE, _plano(OURO.darkened(0.3)))
	# Dō: peitoral de três faixas lamelares abaixo do pescoço (o rosto fica
	# livre: a cabeça começa ~0,25 acima do osso do peito), cordão dourado
	# entre as faixas e o brasão do time no peito
	var peito := "chest"
	for i in 3:
		var y := 0.1 - i * 0.18
		var r := 0.42 + i * 0.025
		_peca(peito, _cilindro(r, r + 0.025, 0.16), Vector3(0, y, -0.01), Vector3.ZERO, Vector3(1, 1, 0.9), _plano(laca if i > 0 else laca.lightened(0.12)))
		_peca(peito, _cilindro(r + 0.012, r + 0.012, 0.022), Vector3(0, y + 0.085, -0.01), Vector3.ZERO, Vector3(1, 1, 0.9), _plano(OURO.darkened(0.25)))
	_peca(peito, _cilindro(0.1, 0.1, 0.03), Vector3(0, 0.04, 0.39), Vector3(90, 0, 0), Vector3.ONE, _neon(time.lightened(0.3), 1.4))
	# Kusazuri: saiote de placas penduradas no quadril
	var quad := "hips"
	for i in 5:
		var a := -PI * 0.42 + PI * 0.84 * i / 4.0
		_peca(quad, _caixa(Vector3(0.26, 0.34, 0.045)), Vector3(sin(a) * 0.42, -0.12, cos(a) * 0.34 - 0.03), Vector3(10, rad_to_deg(a), 0), Vector3.ONE, _plano(laca))
		_peca(quad, _caixa(Vector3(0.27, 0.05, 0.05)), Vector3(sin(a) * 0.42, -0.28, cos(a) * 0.34 - 0.03), Vector3(10, rad_to_deg(a), 0), Vector3.ONE, _plano(OURO.darkened(0.3)))
	# Braçadeiras e caneleiras
	for lado in ["lowerarm.l", "lowerarm.r"]:
		_peca(lado, _cilindro(0.15, 0.17, 0.3), Vector3(0.16 * (1 if lado.ends_with(".l") else -1), 0, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(laca.lightened(0.08)))
	for lado in ["lowerleg.l", "lowerleg.r"]:
		_peca(lado, _caixa(Vector3(0.2, 0.3, 0.1)), Vector3(0, -0.05, 0.1), Vector3.ZERO, Vector3.ONE, _plano(laca))
	# Sashimono: bandeira do time nas costas, balançando com o vento/corrida
	_peca(peito, _cilindro(0.025, 0.025, 1.5), Vector3(0, 0.6, -0.42), Vector3(6, 0, 0), Vector3.ONE, _plano(Color(0.3, 0.2, 0.1)))
	_peca(peito, _fita(0.95, 0.5, time, time.lightened(0.25)), Vector3(0, 0.45, -0.47), Vector3(4, 0, 0), Vector3.ONE,
			{"cor": Color.WHITE, "neon": false, "cor_vertice": true, "peso_uv": true, "balanco": Vector3(0.5, 0.7, 0.0)})
	_peca(peito, _caixa(Vector3(0.5, 0.045, 0.045)), Vector3(0, 1.42, -0.47), Vector3(4, 0, 0), Vector3.ONE, _plano(Color(0.3, 0.2, 0.1)))
	# Katana: lâmina com fio de neon, guarda e cabo
	var mao := "handslot.r"
	_peca(mao, _caixa(Vector3(0.05, 1.5, 0.12)), Vector3(0, 0.95, 0), Vector3.ZERO, Vector3.ONE, _neon(CIANO, 2.2))
	_peca(mao, _cilindro(0.13, 0.13, 0.04), Vector3(0, 0.2, 0), Vector3.ZERO, Vector3.ONE, _plano(OURO.darkened(0.3)))
	_peca(mao, _cilindro(0.05, 0.05, 0.35), Vector3(0, 0.0, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.1, 0.1, 0.12)))
	# Saya (bainha) na cintura, do lado oposto
	_peca(quad, _cilindro(0.05, 0.06, 1.0), Vector3(-0.3, 0.1, -0.12), Vector3(75, 0, -60), Vector3.ONE, _plano(laca.lightened(0.05)))


func _ninja(time: Color) -> void:
	var cab := "head"
	# Máscara sobre nariz e boca + faixa na testa com fitas soltas
	_peca(cab, _esfera(0.5, 0.3), Vector3(0, 0.38, 0.12), Vector3.ZERO, Vector3(1.0, 0.55, 0.95), _plano(Color(0.07, 0.07, 0.12)))
	_peca(cab, _cilindro(0.56, 0.56, 0.09), Vector3(0, 0.78, 0.0), Vector3(-6, 0, 0), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	for s in [-1, 1]:
		_peca(cab, _caixa(Vector3(0.08, 0.5, 0.03)), Vector3(0.12 * s, 0.55, -0.6), Vector3(55, 0, 15 * s), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	var peito := "chest"
	# Cachecol: rolo no pescoço e ponta solta esvoaçando atrás
	var pano := time.darkened(0.35)
	_peca(peito, _cilindro(0.3, 0.34, 0.22), Vector3(0, 0.62, 0.02), Vector3(8, 0, 0), Vector3(1, 1, 0.85), _plano(pano))
	_peca(peito, _fita(0.85, 0.24, pano, time.lightened(0.1)), Vector3(0.1, 0.62, -0.3), Vector3(-35, 180, 12), Vector3.ONE,
			{"cor": Color.WHITE, "neon": false, "cor_vertice": true, "peso_uv": true, "balanco": Vector3(1.0, 0.3, 0.0)})
	# Bandoleira com shurikens de reserva atravessada no peito
	_peca(peito, _caixa(Vector3(0.16, 1.05, 0.06)), Vector3(0, 0.2, 0.22), Vector3(14, 0, 40), Vector3.ONE, _plano(Color(0.1, 0.1, 0.14)))
	for i in 3:
		var y := 0.42 - i * 0.3
		_peca(peito, _shuriken(), Vector3(-y * 0.75, y + 0.2, 0.3), Vector3(14, 0, 0), Vector3.ONE * 0.8, _neon(CIANO, 1.5))
	# Faixas de pano nos antebraços e canelas (menos quadrado de perto)
	for lado in [".l", ".r"]:
		_peca("lowerarm" + lado, _cilindro(0.14, 0.16, 0.26), Vector3(0.16 * (1 if lado == ".l" else -1), 0, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(pano.lightened(0.15)))
		_peca("lowerleg" + lado, _cilindro(0.17, 0.19, 0.26), Vector3(0, -0.02, 0.02), Vector3.ZERO, Vector3.ONE, _plano(pano.lightened(0.15)))
	# Cinto com bolsa de ferramentas de ninja
	_peca("hips", _cilindro(0.47, 0.47, 0.1), Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(1, 1, 0.8), _plano(Color(0.1, 0.1, 0.14)))
	_peca("hips", _caixa(Vector3(0.22, 0.2, 0.12)), Vector3(0.3, -0.04, -0.3), Vector3(0, 25, 0), Vector3.ONE, _plano(pano.darkened(0.2)))
	# Kunai no coldre da coxa direita
	_peca("upperleg.r", _cilindro(0.17, 0.17, 0.07), Vector3(0, 0.14, 0), Vector3.ZERO, Vector3(1, 1, 0.9), _plano(Color(0.1, 0.1, 0.14)))
	_peca("upperleg.r", _caixa(Vector3(0.08, 0.14, 0.05)), Vector3(-0.17, 0.2, 0.02), Vector3.ZERO, Vector3.ONE, _plano(Color(0.15, 0.12, 0.1)))
	_peca("upperleg.r", _cone(0.045, 0.2), Vector3(-0.17, 0.02, 0.02), Vector3(180, 0, 0), Vector3(1, 1, 0.35), _neon(CIANO, 1.5))
	# Shuriken na mão e duas nas costas
	var mao := "handslot.r"
	_peca(mao, _shuriken(), Vector3(0, 0.15, 0.1), Vector3(90, 0, 0), Vector3.ONE * 1.3, _neon(CIANO, 2.0))
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
	# Avental de couro e cinto com minas de reserva
	var quad := "hips"
	_peca(quad, _caixa(Vector3(0.5, 0.42, 0.06)), Vector3(0, -0.1, 0.33), Vector3(8, 0, 0), Vector3.ONE, _plano(Color(0.4, 0.28, 0.16)))
	_peca(quad, _cilindro(0.47, 0.47, 0.09), Vector3(0, 0.1, 0), Vector3.ZERO, Vector3(1, 1, 0.8), _plano(Color(0.14, 0.14, 0.18)))
	for sx in [-1, 1]:
		_peca(quad, _cilindro(0.11, 0.12, 0.07), Vector3(0.38 * sx, 0.02, 0.22), Vector3(75, 0, 0), Vector3.ONE, _plano(Color(0.12, 0.13, 0.18)))
		_peca(quad, _esfera(0.04, 0.04), Vector3(0.38 * sx, 0.02, 0.27), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 2.0))
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
	var peito := "chest"
	# Gola de pelo selvagem nos ombros (continua a juba)
	for i in 5:
		var a := PI * (0.1 + 0.8 * i / 4.0)
		_peca(peito, _cone(0.12, 0.38), Vector3(cos(a) * 0.5, 0.55, -0.22), Vector3(-50, 0, -cos(a) * 60), Vector3.ONE, _plano(Color(0.06, 0.05, 0.08)))
	# Ombreira gigante de placas com espigões só no braço da clava
	var ob := "upperarm.r"
	_peca(ob, _caixa(Vector3(0.5, 0.16, 0.56)), Vector3(-0.1, 0.16, 0), Vector3(0, 0, 12), Vector3.ONE, _plano(Color(0.14, 0.12, 0.12)))
	_peca(ob, _caixa(Vector3(0.42, 0.14, 0.48)), Vector3(-0.26, 0.3, 0), Vector3(0, 0, 24), Vector3.ONE, _plano(Color(0.2, 0.17, 0.16)))
	for i in 3:
		_peca(ob, _cone(0.05, 0.22), Vector3(-0.18 + i * 0.12, 0.34 - i * 0.05, 0.14 - i * 0.14), Vector3(0, 0, 15), Vector3.ONE, _plano(Color(0.92, 0.88, 0.75)))
	# Shimenawa: corda grossa de palha na cintura com dois shide (papéis em zigue-zague)
	var quad := "hips"
	# Duas voltas de corda torcida, justas na barriga (antes era um aro largo)
	_peca(quad, _anel(0.42, 0.065, 14), Vector3(0, 0.13, 0), Vector3(4, 0, 0), Vector3(1, 1, 0.9), _plano(Color(0.78, 0.65, 0.4)))
	_peca(quad, _anel(0.43, 0.05, 14), Vector3(0, 0.04, 0.01), Vector3(-3, 20, 0), Vector3(1, 1, 0.9), _plano(Color(0.62, 0.5, 0.3)))
	for sx in [-0.26, 0.28]:
		_peca(quad, _fita(0.42, 0.14, Color(0.95, 0.94, 0.9), Color(0.85, 0.84, 0.8), 4), Vector3(sx, 0.04, 0.4), Vector3(170, 0, 8 * signf(sx)), Vector3.ONE,
				{"cor": Color.WHITE, "neon": false, "cor_vertice": true, "peso_uv": true, "balanco": Vector3(0.7, 1.9 + sx, 0.0)})
	# Braçadeira cravejada no braço livre
	_peca("lowerarm.l", _cilindro(0.17, 0.19, 0.32), Vector3(0.16, 0, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.14, 0.12, 0.12)))
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
	# Ombreira alta de arqueira só no braço do arco (assimetria) e luva no braço da corda
	var ob := "upperarm.l"
	_peca(ob, _caixa(Vector3(0.38, 0.12, 0.46)), Vector3(0.06, 0.14, 0), Vector3(0, 0, -10), Vector3.ONE, _plano(time.darkened(0.25)))
	_peca(ob, _caixa(Vector3(0.32, 0.1, 0.4)), Vector3(0.2, 0.26, 0), Vector3(0, 0, -22), Vector3.ONE, _plano(time.darkened(0.1)))
	_peca("lowerarm.r", _cilindro(0.14, 0.16, 0.34), Vector3(-0.16, 0, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.15, 0.1, 0.08)))
	# Hakama: abas largas dos lados do quadril (silhueta de arqueira)
	var quad := "hips"
	for sx in [-1, 1]:
		_peca(quad, _caixa(Vector3(0.1, 0.42, 0.42)), Vector3(0.42 * sx, -0.16, 0), Vector3(0, 0, 9 * sx), Vector3.ONE, _plano(time.darkened(0.35)))
	_peca(quad, _cilindro(0.47, 0.47, 0.12), Vector3(0, 0.1, 0), Vector3.ZERO, Vector3(1, 1, 0.8), _plano(Color(0.9, 0.86, 0.75)))
	# Jingasa de palha pendurada nas costas
	_peca("chest", _cone(0.45, 0.22), Vector3(-0.2, 0.35, -0.42), Vector3(75, 0, -15), Vector3.ONE, _plano(Color(0.72, 0.58, 0.32)))
	# Aljava nas costas com penas na cor do time
	var peito := "chest"
	_peca(peito, _caixa(Vector3(0.14, 0.9, 0.07)), Vector3(0, 0.25, 0.24), Vector3(12, 0, -38), Vector3.ONE, _plano(Color(0.15, 0.1, 0.08)))
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
	# Bandoleira de bombinhas no peito e pavio de reserva na cintura
	_peca(peito, _caixa(Vector3(0.16, 1.05, 0.06)), Vector3(0, 0.2, 0.22), Vector3(14, 0, -40), Vector3.ONE, _plano(Color(0.2, 0.14, 0.1)))
	for i in 3:
		var y := 0.42 - i * 0.3
		_peca(peito, _esfera(0.1, 0.1), Vector3(y * 0.75, y + 0.2, 0.3), Vector3.ZERO, Vector3.ONE, _plano(Color(0.06, 0.06, 0.09)))
		_peca(peito, _esfera(0.03, 0.03), Vector3(y * 0.75, y + 0.32, 0.3), Vector3.ZERO, Vector3.ONE, _neon(FOGO, 2.0))
	_peca("hips", _cilindro(0.47, 0.47, 0.09), Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(1, 1, 0.8), _plano(Color(0.2, 0.14, 0.1)))
	_peca("hips", _fita(0.3, 0.06, Color(0.2, 0.2, 0.2), FOGO, 3), Vector3(0.35, 0.04, 0.3), Vector3(170, 0, 10), Vector3.ONE,
			{"cor": Color.WHITE, "neon": false, "cor_vertice": true, "peso_uv": true, "balanco": Vector3(0.8, 2.6, 2.0)})
	# Bomba redonda na mão
	var mao := "handslot.r"
	_peca(mao, _esfera(0.25, 0.25), Vector3(0, 0.2, 0.15), Vector3.ZERO, Vector3.ONE, _plano(Color(0.06, 0.06, 0.09)))
	_peca(mao, _esfera(0.06, 0.06), Vector3(0, 0.5, 0.15), Vector3.ZERO, Vector3.ONE, _neon(FOGO, 3.0))


## Kitsunes (Personagens 2.0, 2026-11-08). A aprendiz (nível 1) é simples:
## uma cauda, máscara de raposa branca e lisa, sem fogo em volta. A Luz e a
## Sombria usam o MESMO modelo evoluído, com uma cauda por nível do mago (2-5);
## muda a paleta, o que flutua na cabeça e o jeito do fogo:
##   Luz: anel dourado liso atrás da cabeça, fogo que boia calmo (serena).
##   Sombria: coroa roxa de raios em ziguezague, olhos acesos, fogo tremido
##   (predadora).
func _kitsune(time: Color) -> void:
	var branco := Color(0.96, 0.95, 0.91)
	_mascara(branco, Color(0.85, 0.3, 0.3), Color(0.08, 0.06, 0.08), false)
	_caudas(1, Color(0.95, 0.5, 0.18), branco, time)


func _kitsune_luz(time: Color) -> void:
	var n := clampi(_nivel, 2, 5)
	var ouro := Color(1.0, 0.8, 0.32)
	_mascara(Color(1.0, 0.98, 0.93), ouro, ouro, true)
	_caudas(n, Color(0.97, 0.95, 0.9), Color(1.0, 0.78, 0.3), time)
	# Halo (kōhai): anel liso atrás da cabeça, cresce com o nível.
	var r := 0.62 + 0.06 * (n - 2)
	_peca("head", _anel(r, 0.05, 32), Vector3(0, 0.72, -0.42), Vector3(90, 0, 0), Vector3.ONE, _neon_bal(ouro, Vector3(0.4, 0.0, 1.0)))
	_peca("head", _anel(r * 0.84, 0.018, 32), Vector3(0, 0.72, -0.44), Vector3(90, 0, 0), Vector3.ONE, _neon_bal(Color(1, 0.97, 0.85), Vector3(0.4, 0.0, 1.0)))
	_fogo_raposa(n, Color(1.0, 0.85, 0.4), 1.0)


func _kitsune_sombria(time: Color) -> void:
	var n := clampi(_nivel, 2, 5)
	var roxo := Color(0.68, 0.28, 1.0)
	_mascara(Color(0.1, 0.08, 0.13), roxo, roxo, true)
	# Olhos acesos: fendas puxadas para cima, na cor da sombra.
	for s in [-1, 1]:
		_peca("head", _caixa(Vector3(0.16, 0.045, 0.03)), Vector3(0.15 * s, 0.64, 0.66), Vector3(0, 0, 22 * s), Vector3.ONE, _neon(Color(0.85, 0.5, 1.0)))
	_caudas(n, Color(0.2, 0.13, 0.28), roxo, time)
	# Coroa de raios: tira em ziguezague sobre a cabeça, mais alta a cada nível.
	var h := 0.22 + 0.05 * (n - 2)
	_peca("head", _coroa(0.4, h, 7 + n), Vector3(0, 0.98, 0.0), Vector3(-8, 0, 0), Vector3.ONE, _neon_bal(roxo, Vector3(0.6, 1.3, 2.0)))
	_peca("head", _anel(0.42, 0.05, 20), Vector3(0, 0.98, 0.0), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.06, 0.04, 0.08)))
	_fogo_raposa(n, Color(0.62, 0.25, 1.0), 2.0)


## Máscara de raposa: rosto, focinho, orelhas com miolo colorido e fendas dos
## olhos. `marcas` = traços acesos nas bochechas (só as evoluídas).
func _mascara(cor: Color, miolo: Color, olho: Color, marcas: bool) -> void:
	var cab := "head"
	_peca(cab, _esfera(0.45, 0.38), Vector3(0, 0.55, 0.3), Vector3.ZERO, Vector3(1, 1, 0.75), _plano(cor))
	_peca(cab, _cone(0.16, 0.35), Vector3(0, 0.45, 0.65), Vector3(90, 0, 0), Vector3.ONE, _plano(cor))
	_peca(cab, _esfera(0.05, 0.04), Vector3(0, 0.45, 0.83), Vector3.ZERO, Vector3.ONE, _plano(Color(0.08, 0.06, 0.08)))
	for s in [-1, 1]:
		_peca(cab, _cone(0.16, 0.42), Vector3(0.3 * s, 1.05, 0.15), Vector3(0, 0, -15 * s), Vector3(1, 1, 0.55), _plano(cor))
		_peca(cab, _cone(0.09, 0.26), Vector3(0.29 * s, 1.0, 0.21), Vector3(0, 0, -15 * s), Vector3(1, 1, 0.3), _plano(miolo))
		if not marcas:
			_peca(cab, _caixa(Vector3(0.14, 0.035, 0.03)), Vector3(0.15 * s, 0.64, 0.64), Vector3(0, 0, 18 * s), Vector3.ONE, _plano(olho))
		else:
			_peca(cab, _caixa(Vector3(0.18, 0.04, 0.02)), Vector3(0.2 * s, 0.5, 0.6), Vector3(0, 0, -20 * s), Vector3.ONE, _neon(miolo, 1.6))


## Leque de `n` caudas presas no quadril, com a faixa do time na raiz.
func _caudas(n: int, base: Color, ponta: Color, time: Color) -> void:
	var quad := "hips"
	var raiz := Vector3(0, 0.2, -0.28)
	var malha := _cauda_malha(1.3 if n == 1 else 1.38, 0.25 if n == 1 else 0.21, base, ponta)
	var abre := 0.0 if n == 1 else minf(24.0 * (n - 1), 100.0)
	for i in n:
		var ang := 0.0 if n == 1 else lerpf(-abre * 0.5, abre * 0.5, float(i) / (n - 1))
		# As de fora deitam mais (leque); fases diferentes: não balançam juntas.
		var tomb := -absf(ang) * 0.12
		_peca(quad, malha, raiz, Vector3(tomb, ang * 0.25, ang), Vector3.ONE,
				{"cor": Color.WHITE, "neon": false, "cor_vertice": true, "peso_uv": true,
				"balanco": Vector3(1.0, i * 2.1, 0.0)})
	_peca(quad, _anel(0.14, 0.05, 12), raiz + Vector3(0, 0.02, -0.02), Vector3(70, 0, 0), Vector3.ONE, _plano(time))


## Fogo de raposa (kitsunebi) orbitando o peito: `n` chamas; tipo 1 calmo, 2 tremido.
func _fogo_raposa(n: int, cor: Color, tipo: float) -> void:
	var peito := "chest"
	var chama := _chama(0.13, 0.42)
	var miolo := _chama(0.06, 0.24)
	for i in n:
		var a := TAU * i / n + 0.4
		var p := Vector3(cos(a) * 0.82, 0.7 + 0.18 * (i % 2), sin(a) * 0.82)
		var bal := Vector3(1.0, i * 1.7, tipo)
		_peca(peito, chama, p, Vector3.ZERO, Vector3.ONE, _neon_bal(cor, bal))
		_peca(peito, miolo, p + Vector3(0, 0.02, 0), Vector3.ZERO, Vector3.ONE, _neon_bal(cor.lerp(Color.WHITE, 0.65), bal))


func _neon_bal(c: Color, bal: Vector3) -> Dictionary:
	return {"cor": c, "neon": true, "balanco": bal}


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
	# Cinto de ferramentas com bolsas e toalha no ombro (tenugui)
	var quad := "hips"
	_peca(quad, _cilindro(0.47, 0.47, 0.1), Vector3(0, 0.06, 0), Vector3.ZERO, Vector3(1, 1, 0.8), _plano(Color(0.3, 0.2, 0.1)))
	for sx in [-1, 1]:
		_peca(quad, _caixa(Vector3(0.2, 0.22, 0.13)), Vector3(0.33 * sx, -0.08, 0.25), Vector3(0, -20 * sx, 0), Vector3.ONE, _plano(Color(0.5, 0.36, 0.2)))
	_peca(peito, _fita(0.5, 0.2, Color(0.35, 0.55, 0.75), Color(0.45, 0.65, 0.85), 4), Vector3(0.32, 0.55, 0.12), Vector3(160, 0, -20), Vector3.ONE,
			{"cor": Color.WHITE, "neon": false, "cor_vertice": true, "peso_uv": true, "balanco": Vector3(0.6, 0.9, 0.0)})
	# Lanterna de papel pendurada no cesto, na cor do time: a luz própria do
	# Construtor (ideia da revisão 2.9b), balançando como as chamas calmas
	_peca(peito, _caixa(Vector3(0.03, 0.18, 0.03)), Vector3(0.44, 0.0, -0.62), Vector3.ZERO, Vector3.ONE, _plano(Color(0.15, 0.12, 0.1)))
	_peca(peito, _esfera(0.15, 0.17), Vector3(0.44, -0.2, -0.62), Vector3.ZERO, Vector3.ONE, _neon_bal(time.lightened(0.35), Vector3(0.5, 0.4, 1.0)))
	for dy in [-0.06, 0.15]:
		_peca(peito, _cilindro(0.07, 0.07, 0.03), Vector3(0.44, -0.2 + dy - 0.045, -0.62), Vector3.ZERO, Vector3.ONE, _plano(Color(0.12, 0.1, 0.1)))
	# Martelo de carpinteiro pendurado no cinto
	_peca(quad, _cilindro(0.03, 0.03, 0.34), Vector3(-0.38, -0.12, 0.18), Vector3(0, 0, 8), Vector3.ONE, _plano(Color(0.55, 0.38, 0.2)))
	_peca(quad, _caixa(Vector3(0.08, 0.08, 0.22)), Vector3(-0.39, 0.06, 0.18), Vector3.ZERO, Vector3.ONE, _plano(Color(0.25, 0.25, 0.3)))
	# Joelheiras de quem vive ajoelhado em obra
	for lado in ["upperleg.l", "upperleg.r"]:
		_peca(lado, _esfera(0.16, 0.12), Vector3(0, -0.26, 0.12), Vector3.ZERO, Vector3.ONE, _plano(Color(0.5, 0.36, 0.2)))
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

## Cauda de raposa: tubo ao longo de uma curva que sai para trás e sobe
## enrolando; raio incha no meio e afina na ponta, com "mechas" (lóbulos) para
## parecer pelo pintado. Cor do vértice: base -> ponta. UV.x = 0 na raiz e 1 na
## ponta (peso do balanço). ~190 triângulos.
func _cauda_malha(comp: float, raio: float, base: Color, ponta: Color) -> Mesh:
	var aneis := 12
	var lados := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	var tans: Array[Vector3] = []
	var p := Vector3.ZERO
	for k in aneis + 1:
		var u := float(k) / aneis
		var th := deg_to_rad(lerpf(15.0, 135.0, pow(u, 1.1)))
		var t := Vector3(0, sin(th), -cos(th))
		pts.append(p)
		tans.append(t)
		p += t * comp / aneis
	var lado := Vector3.RIGHT
	for k in aneis + 1:
		var u := float(k) / aneis
		var t := tans[k]
		var nrm := t.cross(lado).normalized()
		var r := raio * pow(sin(PI * (0.15 + 0.85 * u)), 0.7)
		var cor := base.lerp(ponta, smoothstep(0.6, 0.86, u)) * lerpf(0.72, 1.0, smoothstep(0.0, 0.25, u))
		cor.a = 1.0
		for j in lados + 1:
			var phi := TAU * j / lados
			var mecha := 1.0 + 0.13 * sin(5.0 * phi + 9.0 * u)
			var d := lado * cos(phi) + nrm * sin(phi)
			st.set_color(cor)
			st.set_normal(d)
			st.set_uv(Vector2(u, 0))
			st.add_vertex(pts[k] + d * r * mecha)
	for k in aneis:
		for j in lados:
			var a := k * (lados + 1) + j
			var b := a + lados + 1
			for v in [a, b, a + 1, a + 1, b, b + 1]:
				st.add_index(v)
	return st.commit()


## Chama em gota (torno): base redonda, ponta fina levemente torta.
func _chama(r: float, h: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aneis := 7
	var lados := 8
	for k in aneis + 1:
		var u := float(k) / aneis
		var rr := r * (sin(u / 0.35 * PI * 0.5) if u < 0.35 else pow(1.0 - (u - 0.35) / 0.65, 1.3))
		var y := -0.25 * h + u * h
		var torto := Vector3(0.04 * sin(u * 4.0) * u, 0, 0)
		for j in lados + 1:
			var phi := TAU * j / lados
			var d := Vector3(cos(phi), 0, sin(phi))
			st.set_normal(d)
			st.add_vertex(d * rr + Vector3(0, y, 0) + torto)
	for k in aneis:
		for j in lados:
			var a := k * (lados + 1) + j
			var b := a + lados + 1
			for v in [a, a + 1, b, a + 1, b + 1, b]:
				st.add_index(v)
	return st.commit()


## Fita/pano: tira plana que sobe em +Y a partir da origem, com dupla face,
## UV.x = 0 na base e 1 na ponta (peso do balanço) e cor base -> ponta.
## Serve para bandeira (sashimono), cachecol, shide e panos pendurados.
func _fita(comp: float, larg: float, base: Color, ponta: Color, segs := 6) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in segs + 1:
		var u := float(k) / segs
		var cor := base.lerp(ponta, u)
		cor.a = 1.0
		for sx in [-0.5, 0.5]:
			st.set_color(cor)
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2(u, 0))
			st.add_vertex(Vector3(sx * larg, u * comp, 0))
	for k in segs:
		var a := k * 2
		for f in [[a, a + 1, a + 2], [a + 1, a + 3, a + 2], [a, a + 2, a + 1], [a + 1, a + 2, a + 3]]:
			for v in f:
				st.add_index(v)
	return st.commit()


## Anel (toro) deitado no plano XZ.
func _anel(r: float, grossura: float, lados: int) -> Mesh:
	var t := TorusMesh.new()
	t.inner_radius = r - grossura
	t.outer_radius = r + grossura
	t.rings = lados
	t.ring_segments = 6
	return t


## Coroa de raios: tira fechada cujo topo sobe e desce em ziguezague, com as
## duas faces (dá para ver por dentro de cima da câmera).
func _coroa(r: float, h: float, pontas: int) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pontas * 2
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var h0 := h if i % 2 == 0 else h * 0.3
		var h1 := h if (i + 1) % 2 == 0 else h * 0.3
		var p0 := Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := Vector3(cos(a1), 0, sin(a1)) * r
		# abre um pouco para fora em cima, como coroa
		var q0 := p0 * 1.18 + Vector3(0, h0, 0)
		var q1 := p1 * 1.18 + Vector3(0, h1, 0)
		var nrm := (p0 + p1).normalized()
		for face in [[p0, q0, p1, q0, q1, p1], [p0, p1, q0, q0, p1, q1]]:
			var sinal := 1.0 if face[1] == q0 and face[2] == p1 else -1.0
			for v in face:
				st.set_normal(nrm * sinal)
				st.add_vertex(v)
	return st.commit()


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
