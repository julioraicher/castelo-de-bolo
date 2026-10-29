extends SceneTree
## Prancha das classes: monta cada boneco por código (corpo KayKit + peças
## primitivas + shader toon com a cor do time) e salva duas imagens:
##   DIR/prancha_close.png  frente, 3/4 e costas de cada classe
##   DIR/prancha_jogo.png   os mesmos bonecos na câmera do jogo, tamanho real
## Uso (precisa de janela; no servidor, xvfb):
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_personagens.gd -- DIR

const TOON := preload("res://assets/shaders/toon_time.gdshader")
const OUTLINE := preload("res://assets/shaders/contorno.gdshader")

const AZUL := Color(0.16, 0.45, 1.0)
const VERMELHO := Color(1.0, 0.16, 0.1)
const CIANO := Color(0.2, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.25, 0.85)
const FANTASMA := Color(0.45, 1.0, 0.45)
const OURO := Color(1.0, 0.78, 0.3)

## Cada classe: modelo base, partes visíveis, animação da pose e peças extras.
var CLASSES := [
	{"nome": "Samurai", "glb": "Knight", "anim": "2H_Melee_Idle", "partes": ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Body", "Knight_Head", "Knight_LegLeft", "Knight_LegRight"]},
	{"nome": "Ninja de shuriken", "glb": "Rogue_Hooded", "anim": "1H_Ranged_Aiming", "partes": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head_Hooded", "Rogue_LegLeft", "Rogue_LegRight"]},
	{"nome": "Monge de chi", "glb": "Mage", "anim": "Spellcasting", "partes": ["Mage_ArmLeft", "Mage_ArmRight", "Mage_Body", "Mage_Head", "Mage_LegLeft", "Mage_LegRight"]},
	{"nome": "Armadilheiro", "glb": "Barbarian", "anim": "Idle", "partes": ["Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_Body", "Barbarian_Head", "Barbarian_LegLeft", "Barbarian_LegRight"]},
]

var dir := "user://prancha"
var cena: Node3D
var cam: Camera3D

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	_montar()

func _montar() -> void:
	root.size = Vector2i(1600, 900)
	cena = Node3D.new()
	root.add_child(cena)
	_ambiente()
	# Fileira de close: cada classe aparece 3 vezes (frente, 3/4, costas).
	var angulos := [0.0, -PI * 0.3, PI]
	for c in CLASSES.size():
		for v in 3:
			var b := _boneco(CLASSES[c], AZUL if v != 1 else AZUL)
			b.position = Vector3((c - 1.5) * 4.1 + (v - 1) * 1.3, 0, 0)
			b.rotation.y = angulos[v]
	# Grupo misto para a câmera do jogo, longe da fileira.
	for c in CLASSES.size():
		for t in 2:
			var b := _boneco(CLASSES[c], AZUL if t == 0 else VERMELHO)
			b.position = Vector3(200 + (c - 1.5) * 3.2, 0, (t - 0.5) * 4.0)
			b.rotation.y = PI if t == 1 else 0.0
	cam = Camera3D.new()
	cena.add_child(cam)
	await _quadros(8)
	# 1) close: câmera baixa, de frente para a fileira
	cam.fov = 30
	cam.position = Vector3(0, 2.2, 20.5)
	cam.look_at(Vector3(0, 1.1, 0))
	await _salvar("prancha_close.png")
	# 2) câmera do jogo: offset (0, 21, 19), FOV 42
	cam.fov = 42
	cam.position = Vector3(200, 21, 19)
	cam.look_at(Vector3(200, 0, 0))
	await _salvar("prancha_jogo.png")
	quit()

func _quadros(n: int) -> void:
	for i in n:
		await process_frame

func _salvar(nome: String) -> void:
	await _quadros(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(nome))
	print("salvo ", dir.path_join(nome))

func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.014, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.45, 0.6)
	env.ambient_light_energy = 0.35
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	# Lua fria + contraluz magenta (neon da cidade)
	var lua := DirectionalLight3D.new()
	lua.light_color = Color(1.0, 0.95, 0.9)
	lua.light_energy = 1.0
	lua.rotation_degrees = Vector3(-50, 30, 0)
	cena.add_child(lua)
	var neon := DirectionalLight3D.new()
	neon.light_color = MAGENTA
	neon.light_energy = 0.45
	neon.rotation_degrees = Vector3(-15, 200, 0)
	cena.add_child(neon)
	# Chão de pedra escura, com uma faixa de neon como referência de escala
	for x in [0.0, 200.0]:
		var chao := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(60, 30)
		chao.mesh = pm
		chao.position.x = x
		chao.material_override = _plano(Color(0.02, 0.022, 0.045))
		cena.add_child(chao)

func _boneco(info: Dictionary, time: Color) -> Node3D:
	var n: Node3D = load("res://assets/characters/%s.glb" % info.glb).instantiate()
	cena.add_child(n)
	var mat := ShaderMaterial.new()
	mat.shader = TOON
	mat.set_shader_parameter("cor_time", time)
	var cont := ShaderMaterial.new()
	cont.shader = OUTLINE
	mat.next_pass = cont
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visible = mi.name in info.partes
		if mi.visible:
			var tex := (mi.get_active_material(0) as StandardMaterial3D).albedo_texture
			var m := mat.duplicate() as ShaderMaterial
			m.set_shader_parameter("textura", tex)
			m.next_pass = cont
			mi.material_override = m
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play(info.anim)
	ap.seek(0.3, true)
	ap.pause()
	call("_pecas_" + info.glb.to_lower(), sk, time)
	return n

# --- peças de cada classe -------------------------------------------------

func _pecas_knight(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Kabuto: cúpula achatada + aba + chifres em lua crescente (neon)
	_peca(cab, _esfera(0.78, 0.5), Vector3(0, 0.7, -0.02), Vector3.ZERO, Vector3(1, 0.75, 1), _plano(Color(0.05, 0.05, 0.09)))
	_peca(cab, _cilindro(0.66, 0.7, 0.08), Vector3(0, 0.55, -0.05), Vector3(-8, 0, 0), Vector3.ONE, _plano(time))
	for s in [-1, 1]:
		_peca(cab, _cone(0.1, 0.7), Vector3(0.28 * s, 1.0, 0.25), Vector3(-25, 0, -35 * s), Vector3.ONE, _neon(OURO))
	# Ombreiras quadradas (sode)
	for lado in ["upperarm.l", "upperarm.r"]:
		_peca(_osso(sk, lado), _caixa(Vector3(0.42, 0.12, 0.5)), Vector3(0, 0.12, 0), Vector3(0, 0, 0), Vector3.ONE, _plano(time.darkened(0.2)))
	# Katana: lâmina com fio de neon, guarda e cabo
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _caixa(Vector3(0.05, 1.5, 0.12)), Vector3(0, 0.95, 0), Vector3.ZERO, Vector3.ONE, _neon(CIANO, 2.2))
	_peca(mao, _cilindro(0.13, 0.13, 0.04), Vector3(0, 0.2, 0), Vector3.ZERO, Vector3.ONE, _plano(OURO.darkened(0.3)))
	_peca(mao, _cilindro(0.05, 0.05, 0.35), Vector3(0, 0.0, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.1, 0.1, 0.12)))

func _pecas_rogue_hooded(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Máscara sobre nariz e boca + faixa na testa com fitas soltas
	_peca(cab, _esfera(0.5, 0.3), Vector3(0, 0.38, 0.12), Vector3.ZERO, Vector3(1.0, 0.55, 0.95), _plano(Color(0.07, 0.07, 0.12)))
	_peca(cab, _cilindro(0.56, 0.56, 0.09), Vector3(0, 0.78, 0.0), Vector3(-6, 0, 0), Vector3.ONE, _neon(MAGENTA, 1.6))
	for s in [-1, 1]:
		_peca(cab, _caixa(Vector3(0.08, 0.5, 0.03)), Vector3(0.12 * s, 0.55, -0.6), Vector3(55, 0, 15 * s), Vector3.ONE, _neon(MAGENTA, 1.6))
	# Shuriken na mão e duas nas costas
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _shuriken(), Vector3(0, 0.15, 0.1), Vector3(90, 0, 0), Vector3.ONE * 1.3, _neon(CIANO, 2.0))
	var peito := _osso(sk, "chest")
	_peca(peito, _shuriken(), Vector3(0.22, 0.45, -0.45), Vector3(0, 0, 20), Vector3.ONE, _neon(CIANO, 1.5))
	_peca(peito, _shuriken(), Vector3(-0.22, 0.25, -0.45), Vector3(0, 0, -20), Vector3.ONE, _neon(CIANO, 1.5))

func _pecas_mage(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Kasa: chapéu de palha em cone largo e baixo (silhueta inconfundível de cima)
	_peca(cab, _cone(1.15, 0.45), Vector3(0, 1.05, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.62, 0.46, 0.24)))
	_peca(cab, _cilindro(0.5, 0.5, 0.06), Vector3(0, 0.86, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.2)))
	# Colar de contas no peito
	var peito := _osso(sk, "chest")
	for i in 12:
		var a := TAU * i / 12.0
		_peca(peito, _esfera(0.07, 0.07), Vector3(cos(a) * 0.4, 0.15 + sin(a) * 0.06, 0.12 + sin(a) * 0.28), Vector3.ZERO, Vector3.ONE, _plano(Color(0.35, 0.16, 0.1)))
	# Esferas de chi (fogo-fantasma) orbitando as mãos
	for lado in ["handslot.l", "handslot.r"]:
		_peca(_osso(sk, lado), _esfera(0.17, 0.17), Vector3(0, 0.15, 0.2), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 2.5))

func _pecas_barbarian(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Óculos de solda com lente de neon + bandana
	for s in [-1, 1]:
		_peca(cab, _cilindro(0.13, 0.13, 0.12), Vector3(0.2 * s, 0.62, 0.45), Vector3(90, 0, 0), Vector3.ONE, _neon(FANTASMA, 1.8))
	_peca(cab, _cilindro(0.58, 0.6, 0.12), Vector3(0, 0.66, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.3)))
	# Mochila de ferramentas com estrepes espetados
	var peito := _osso(sk, "chest")
	_peca(peito, _caixa(Vector3(0.75, 0.8, 0.4)), Vector3(0, 0.4, -0.5), Vector3.ZERO, Vector3.ONE, _plano(Color(0.3, 0.22, 0.16)))
	for i in 3:
		_peca(peito, _cone(0.07, 0.35), Vector3(-0.25 + 0.25 * i, 0.95, -0.5), Vector3(0, 0, (i - 1) * 20), Vector3.ONE, _plano(Color(0.55, 0.6, 0.7)))
	# Mina na mão: disco escuro com luz verde no centro
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.3, 0.33, 0.12), Vector3(0, 0.1, 0.15), Vector3(90, 0, 0), Vector3.ONE, _plano(Color(0.12, 0.13, 0.18)))
	_peca(mao, _esfera(0.1, 0.1), Vector3(0, 0.1, 0.24), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 3.0))
	# Chave inglesa na outra mão
	var mao_l := _osso(sk, "handslot.l")
	_peca(mao_l, _caixa(Vector3(0.08, 0.7, 0.08)), Vector3(0, 0.3, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))
	_peca(mao_l, _caixa(Vector3(0.25, 0.1, 0.1)), Vector3(0, 0.68, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))

# --- utilitários ----------------------------------------------------------

func _osso(sk: Skeleton3D, nome: String) -> BoneAttachment3D:
	var b := BoneAttachment3D.new()
	sk.add_child(b)
	b.bone_name = nome
	return b

func _peca(pai: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3, esc: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = esc
	pai.add_child(mi)

func _plano(c: Color) -> Material:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("cor_fixa", c)
	m.set_shader_parameter("usar_cor_fixa", true)
	var cont := ShaderMaterial.new()
	cont.shader = OUTLINE
	m.next_pass = cont
	return m

func _neon(c: Color, forca := 1.8) -> Material:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c * forca
	return m

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
