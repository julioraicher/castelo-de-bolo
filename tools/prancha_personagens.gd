extends SceneTree
## Prancha das classes: monta cada boneco por código (corpo KayKit + peças
## primitivas + shader toon com a cor do time) e salva duas imagens:
##   DIR/close_N.png  frente, 3/4 e costas de cada classe do mundo N
##   DIR/jogo_N.png   os mesmos bonecos na câmera do jogo, tamanho real
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
const FOGO := Color(1.0, 0.45, 0.08)

## Mundos candidatos: as mesmas 4 funções (guerreiro, atirador, mago, construtor).
## Cada classe: modelo base, partes visíveis do .glb, pose e a função das peças.
var MUNDOS := [
	{"nome": "Ninja", "classes": [
		{"nome": "Samurai", "glb": "Knight", "anim": "2H_Melee_Idle", "partes": ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Body", "Knight_Head", "Knight_LegLeft", "Knight_LegRight"], "pecas": "_samurai"},
		{"nome": "Ninja de shuriken", "glb": "Rogue_Hooded", "anim": "1H_Ranged_Aiming", "partes": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head_Hooded", "Rogue_LegLeft", "Rogue_LegRight"], "pecas": "_ninja"},
		{"nome": "Monge de chi", "glb": "Mage", "anim": "Spellcasting", "partes": ["Mage_ArmLeft", "Mage_ArmRight", "Mage_Body", "Mage_Head", "Mage_LegLeft", "Mage_LegRight"], "pecas": "_monge"},
		{"nome": "Armadilheiro", "glb": "Barbarian", "anim": "Idle", "partes": ["Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_Body", "Barbarian_Head", "Barbarian_LegLeft", "Barbarian_LegRight"], "pecas": "_armadilheiro"},
	]},
	{"nome": "Festival Infernal", "classes": [
		{"nome": "Guitarrista", "glb": "Knight", "anim": "2H_Melee_Idle", "partes": ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Body", "Knight_Head", "Knight_LegLeft", "Knight_LegRight"], "pecas": "_guitarrista"},
		{"nome": "Pirotécnico", "glb": "Rogue", "anim": "2H_Ranged_Aiming", "partes": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head", "Rogue_LegLeft", "Rogue_LegRight"], "pecas": "_pirotecnico"},
		{"nome": "Vocalista", "glb": "Mage", "anim": "Spellcast_Raise", "partes": ["Mage_ArmLeft", "Mage_ArmRight", "Mage_Body", "Mage_Head", "Mage_LegLeft", "Mage_LegRight"], "pecas": "_vocalista"},
		{"nome": "Roadie", "glb": "Barbarian", "anim": "Idle", "partes": ["Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_Body", "Barbarian_Head", "Barbarian_LegLeft", "Barbarian_LegRight"], "pecas": "_roadie"},
	]},
	{"nome": "Cavaleiros Malditos", "classes": [
		{"nome": "Cavaleiro maldito", "glb": "Knight", "anim": "Blocking", "partes": ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Body", "Knight_Head", "Knight_LegLeft", "Knight_LegRight", "Knight_Helmet", "Spike_Shield", "1H_Sword"], "pecas": "_cavaleiro_maldito"},
		{"nome": "Caçador de besta", "glb": "Rogue_Hooded", "anim": "2H_Ranged_Aiming", "partes": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head_Hooded", "Rogue_LegLeft", "Rogue_LegRight", "2H_Crossbow"], "pecas": "_cacador"},
		{"nome": "Necromante", "glb": "Mage", "anim": "Spellcasting", "partes": ["Mage_ArmLeft", "Mage_ArmRight", "Mage_Body", "Mage_Head", "Mage_LegLeft", "Mage_LegRight", "Mage_Hat", "2H_Staff"], "pecas": "_necromante"},
		{"nome": "Ferreiro", "glb": "Barbarian", "anim": "Idle", "partes": ["Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_Body", "Barbarian_Head", "Barbarian_LegLeft", "Barbarian_LegRight"], "pecas": "_ferreiro"},
	]},
]

## Quais mundos entram na prancha (índice em MUNDOS) e a escala da cabeça de cada
## fileira. Passe na linha de comando: -- DIR 0:1.0,0:0.85
var fileiras := [[0, 1.0], [1, 1.0], [2, 1.0]]

var dir := "user://prancha"
var cena: Node3D
var cam: Camera3D

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	if args.size() > 1:
		fileiras = []
		for f in args[1].split(","):
			fileiras.append([int(f.get_slice(":", 0)), float(f.get_slice(":", 1))])
	DirAccess.make_dir_recursive_absolute(dir)
	_montar()

func _montar() -> void:
	root.size = Vector2i(1600, 900)
	cena = Node3D.new()
	root.add_child(cena)
	_ambiente()
	var angulos := [0.0, -PI * 0.3, PI]
	for w in fileiras.size():
		var classes: Array = MUNDOS[fileiras[w][0]].classes
		var cabeca: float = fileiras[w][1]
		# Fileira de close: cada classe 3 vezes (frente, 3/4, costas).
		for c in classes.size():
			for v in 3:
				var b := _boneco(classes[c], AZUL, cabeca)
				b.position = Vector3(w * 100 + (c - 1.5) * 4.1 + (v - 1) * 1.3, 0, 0)
				b.rotation.y = angulos[v]
		# Grupo azul x vermelho para a câmera do jogo.
		for c in classes.size():
			for t in 2:
				var b := _boneco(classes[c], AZUL if t == 0 else VERMELHO, cabeca)
				b.position = Vector3(1000 + w * 100 + (c - 1.5) * 3.2, 0, (t - 0.5) * 4.0)
				b.rotation.y = PI if t == 1 else 0.0
	cam = Camera3D.new()
	cena.add_child(cam)
	await _quadros(8)
	for w in fileiras.size():
		cam.fov = 30
		cam.position = Vector3(w * 100, 2.2, 20.5)
		cam.look_at(Vector3(w * 100, 1.1, 0))
		await _salvar("close_%d.png" % w)
		# câmera do jogo: offset (0, 21, 19), FOV 42
		cam.fov = 42
		cam.position = Vector3(1000 + w * 100, 21, 19)
		cam.look_at(Vector3(1000 + w * 100, 0, 0))
		await _salvar("jogo_%d.png" % w)
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
	for x in [0.0, 100.0, 200.0, 1000.0, 1100.0, 1200.0]:
		var chao := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(60, 30)
		chao.mesh = pm
		chao.position.x = x
		chao.material_override = _plano(Color(0.02, 0.022, 0.045))
		cena.add_child(chao)

func _boneco(info: Dictionary, time: Color, cabeca := 1.0) -> Node3D:
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
	sk.set_bone_pose_scale(sk.find_bone("head"), Vector3.ONE * cabeca)
	call(info.pecas, sk, time)
	return n

# --- peças de cada classe -------------------------------------------------

func _samurai(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Kabuto: cúpula achatada + aba + chifres em lua crescente (neon)
	_peca(cab, _esfera(0.78, 0.5), Vector3(0, 0.7, -0.02), Vector3.ZERO, Vector3(1, 0.75, 1), _plano(time.darkened(0.1)))
	_peca(cab, _cilindro(0.66, 0.7, 0.08), Vector3(0, 0.55, -0.05), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.05, 0.05, 0.09)))
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

func _ninja(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Máscara sobre nariz e boca + faixa na testa com fitas soltas
	_peca(cab, _esfera(0.5, 0.3), Vector3(0, 0.38, 0.12), Vector3.ZERO, Vector3(1.0, 0.55, 0.95), _plano(Color(0.07, 0.07, 0.12)))
	_peca(cab, _cilindro(0.56, 0.56, 0.09), Vector3(0, 0.78, 0.0), Vector3(-6, 0, 0), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	for s in [-1, 1]:
		_peca(cab, _caixa(Vector3(0.08, 0.5, 0.03)), Vector3(0.12 * s, 0.55, -0.6), Vector3(55, 0, 15 * s), Vector3.ONE, _neon(time.lightened(0.25), 1.6))
	# Shuriken na mão e duas nas costas
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _shuriken(), Vector3(0, 0.15, 0.1), Vector3(90, 0, 0), Vector3.ONE * 1.3, _neon(CIANO, 2.0))
	var peito := _osso(sk, "chest")
	_peca(peito, _shuriken(), Vector3(0.22, 0.45, -0.45), Vector3(0, 0, 20), Vector3.ONE, _neon(CIANO, 1.5))
	_peca(peito, _shuriken(), Vector3(-0.22, 0.25, -0.45), Vector3(0, 0, -20), Vector3.ONE, _neon(CIANO, 1.5))

func _monge(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Kasa: chapéu de palha em cone largo e baixo (silhueta inconfundível de cima)
	_peca(cab, _cone(0.98, 0.4), Vector3(0, 1.02, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.62, 0.46, 0.24)))
	_peca(cab, _cilindro(0.5, 0.5, 0.06), Vector3(0, 0.86, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.2)))
	# Colar de contas no peito
	var peito := _osso(sk, "chest")
	for i in 12:
		var a := TAU * i / 12.0
		_peca(peito, _esfera(0.07, 0.07), Vector3(cos(a) * 0.4, 0.15 + sin(a) * 0.06, 0.12 + sin(a) * 0.28), Vector3.ZERO, Vector3.ONE, _plano(Color(0.35, 0.16, 0.1)))
	# Esferas de chi (fogo-fantasma) orbitando as mãos
	for lado in ["handslot.l", "handslot.r"]:
		_peca(_osso(sk, lado), _esfera(0.17, 0.17), Vector3(0, 0.15, 0.2), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 2.5))

func _armadilheiro(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Óculos de solda com lente de neon + bandana
	for s in [-1, 1]:
		_peca(cab, _cilindro(0.13, 0.13, 0.12), Vector3(0.2 * s, 0.62, 0.45), Vector3(90, 0, 0), Vector3.ONE, _neon(FANTASMA, 1.8))
	_peca(cab, _cilindro(0.58, 0.6, 0.12), Vector3(0, 0.66, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.3)))
	# Cesto de palha nas costas, cheio de estrepes, com lanterna verde pendurada
	var peito := _osso(sk, "chest")
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
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.3, 0.33, 0.12), Vector3(0, 0.1, 0.15), Vector3(90, 0, 0), Vector3.ONE, _plano(Color(0.12, 0.13, 0.18)))
	_peca(mao, _esfera(0.1, 0.1), Vector3(0, 0.1, 0.24), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 3.0))
	# Chave inglesa na outra mão
	var mao_l := _osso(sk, "handslot.l")
	_peca(mao_l, _caixa(Vector3(0.08, 0.7, 0.08)), Vector3(0, 0.3, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))
	_peca(mao_l, _caixa(Vector3(0.25, 0.1, 0.1)), Vector3(0, 0.68, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.65, 0.75)))

# --- Festival Infernal ----------------------------------------------------

func _guitarrista(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Moicano de espetos em neon de fogo
	for i in 5:
		_peca(cab, _cone(0.15, 0.7), Vector3(0, 1.1, 0.4 - i * 0.2), Vector3(-10 + i * 12, 0, 0), Vector3.ONE, _neon(FOGO, 2.0))
	# Ombreiras com espetos
	for lado in ["upperarm.l", "upperarm.r"]:
		var o := _osso(sk, lado)
		_peca(o, _esfera(0.25, 0.18), Vector3(0, 0.1, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.06, 0.06, 0.08)))
		_peca(o, _cone(0.07, 0.3), Vector3(0, 0.3, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.7, 0.72, 0.8)))
	# Guitarra Flying-V usada como machado: corpo em V, braço e cordas de neon
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.05, 0.05, 1.0), Vector3(0, 0.45, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.08, 0.06, 0.06)))
	for s in [-1, 1]:
		_peca(mao, _caixa(Vector3(0.22, 0.75, 0.08)), Vector3(0.18 * s, 1.15, 0), Vector3(0, 0, -28 * s), Vector3.ONE, _plano(time.darkened(0.1)))
	_peca(mao, _caixa(Vector3(0.02, 1.0, 0.1)), Vector3(0, 0.6, 0.03), Vector3.ZERO, Vector3.ONE, _neon(MAGENTA, 2.2))

func _pirotecnico(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Máscara de gás: focinho e dois filtros + óculos de lente laranja
	_peca(cab, _cilindro(0.16, 0.22, 0.25), Vector3(0, 0.35, 0.45), Vector3(80, 0, 0), Vector3.ONE, _plano(Color(0.08, 0.08, 0.1)))
	for s in [-1, 1]:
		_peca(cab, _cilindro(0.1, 0.1, 0.16), Vector3(0.28 * s, 0.3, 0.38), Vector3(70, 0, 40 * s), Vector3.ONE, _plano(Color(0.5, 0.5, 0.55)))
		_peca(cab, _cilindro(0.13, 0.13, 0.08), Vector3(0.2 * s, 0.68, 0.46), Vector3(90, 0, 0), Vector3.ONE, _neon(FOGO, 2.0))
	_peca(cab, _cilindro(0.56, 0.58, 0.1), Vector3(0, 0.68, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.08, 0.08, 0.1)))
	# Lança-fogos no ombro com a boca em brasa
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.17, 0.17, 1.3), Vector3(0, 0.3, 0.1), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.3)))
	_peca(mao, _cilindro(0.13, 0.13, 0.05), Vector3(0, 0.96, 0.1), Vector3.ZERO, Vector3.ONE, _neon(FOGO, 2.6))
	# Cartucheira de rojões no peito
	var peito := _osso(sk, "chest")
	for i in 5:
		_peca(peito, _cilindro(0.045, 0.045, 0.22), Vector3(-0.3 + i * 0.15, 0.35 - i * 0.05, 0.42), Vector3(0, 0, 30), Vector3.ONE, _neon([FOGO, MAGENTA, CIANO][i % 3], 1.6))

func _vocalista(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Cabelão armado (juba) escuro com pontas de neon
	_peca(cab, _esfera(0.72, 0.55), Vector3(0, 0.8, -0.12), Vector3.ZERO, Vector3(1.1, 0.9, 1.0), _plano(Color(0.06, 0.05, 0.1)))
	for i in 6:
		var a := TAU * i / 6.0
		_peca(cab, _cone(0.12, 0.45), Vector3(cos(a) * 0.55, 1.1, -0.15 + sin(a) * 0.4), Vector3(sin(a) * 40, 0, -cos(a) * 40), Vector3.ONE, _plano(Color(0.06, 0.05, 0.1)))
	# Pedestal de microfone como cajado + ondas de som
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.035, 0.035, 1.8), Vector3(0, 0.3, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.7, 0.72, 0.8)))
	_peca(mao, _esfera(0.13, 0.17), Vector3(0, 1.25, 0), Vector3.ZERO, Vector3.ONE, _neon(CIANO, 2.0))
	var mao_l := _osso(sk, "handslot.l")
	for i in 2:
		var t := TorusMesh.new()
		t.inner_radius = 0.2 + i * 0.18
		t.outer_radius = 0.25 + i * 0.18
		t.rings = 16
		_peca(mao_l, t, Vector3(0, 0.2, 0.3), Vector3(90, 0, 0), Vector3.ONE, _neon(MAGENTA, 2.0))

func _roadie(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Boné com aba + fone de comunicação
	_peca(cab, _esfera(0.6, 0.35), Vector3(0, 0.72, 0), Vector3.ZERO, Vector3(1, 0.7, 1), _plano(Color(0.07, 0.07, 0.1)))
	_peca(cab, _caixa(Vector3(0.6, 0.05, 0.4)), Vector3(0, 0.66, 0.55), Vector3(-8, 0, 0), Vector3.ONE, _plano(Color(0.07, 0.07, 0.1)))
	_peca(cab, _cilindro(0.12, 0.12, 0.1), Vector3(0.6, 0.5, 0), Vector3(0, 0, 90), Vector3.ONE, _neon(FOGO, 1.6))
	# Case de turnê nas costas (cantoneiras de metal) + rolo de cabo
	var peito := _osso(sk, "chest")
	_peca(peito, _caixa(Vector3(0.8, 0.9, 0.42)), Vector3(0, 0.45, -0.52), Vector3.ZERO, Vector3.ONE, _plano(Color(0.08, 0.08, 0.1)))
	for x in [-1, 1]:
		for y in [-1, 1]:
			_peca(peito, _caixa(Vector3(0.12, 0.12, 0.45)), Vector3(0.38 * x, 0.45 + 0.42 * y, -0.52), Vector3.ZERO, Vector3.ONE, _plano(Color(0.65, 0.68, 0.75)))
	var cabo := TorusMesh.new()
	cabo.inner_radius = 0.22
	cabo.outer_radius = 0.32
	_peca(_osso(sk, "upperarm.l"), cabo, Vector3(0, 0.1, 0), Vector3(0, 0, 90), Vector3.ONE, _plano(Color(0.9, 0.55, 0.1)))
	# Martelo na mão
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.04, 0.04, 0.7), Vector3(0, 0.25, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.3, 0.2, 0.12)))
	_peca(mao, _caixa(Vector3(0.35, 0.16, 0.16)), Vector3(0, 0.6, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.6, 0.62, 0.7)))

# --- Cavaleiros Malditos --------------------------------------------------

func _cavaleiro_maldito(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Olhos de fogo-fantasma na fresta do elmo + chifres tortos
	for s in [-1, 1]:
		_peca(cab, _esfera(0.07, 0.05), Vector3(0.17 * s, 0.6, 0.52), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 3.0))
		_peca(cab, _cone(0.1, 0.6), Vector3(0.42 * s, 1.0, 0), Vector3(0, 0, -50 * s), Vector3.ONE, _plano(Color(0.75, 0.72, 0.62)))
	# Chama verde saindo da espada
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _caixa(Vector3(0.04, 0.9, 0.16)), Vector3(0, 0.75, 0), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 1.8))

func _cacador(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Chapéu de caçador de abas largas sobre o capuz, com fivela
	_peca(cab, _cilindro(0.95, 0.95, 0.05), Vector3(0, 0.95, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.07, 0.06, 0.08)))
	_peca(cab, _cilindro(0.42, 0.5, 0.45), Vector3(0, 1.18, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.07, 0.06, 0.08)))
	_peca(cab, _caixa(Vector3(0.16, 0.12, 0.04)), Vector3(0, 1.0, 0.5), Vector3.ZERO, Vector3.ONE, _plano(OURO))
	# Virote verde carregado na besta
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _caixa(Vector3(0.04, 0.04, 0.9)), Vector3(0, 0.2, 0.25), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 2.2))

func _necromante(sk: Skeleton3D, time: Color) -> void:
	# Caveira no topo do cajado + duas almas flutuando
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _esfera(0.2, 0.2), Vector3(0, 1.45, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.9, 0.88, 0.8)))
	for s in [-1, 1]:
		_peca(mao, _esfera(0.05, 0.05), Vector3(0.07 * s, 1.47, 0.17), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 3.0))
	var peito := _osso(sk, "chest")
	for s in [-1, 1]:
		_peca(peito, _esfera(0.14, 0.2), Vector3(0.75 * s, 0.9, -0.2), Vector3.ZERO, Vector3.ONE, _neon(FANTASMA, 2.2))
		_peca(peito, _cone(0.12, 0.3), Vector3(0.75 * s, 0.65, -0.2), Vector3(180, 0, 0), Vector3.ONE, _neon(FANTASMA, 1.4))
	# Gola alta de ossos
	for i in 5:
		_peca(peito, _cone(0.06, 0.3), Vector3(-0.3 + i * 0.15, 0.85, -0.25), Vector3(-20, 0, (i - 2) * 15), Vector3.ONE, _plano(Color(0.85, 0.83, 0.75)))

func _ferreiro(sk: Skeleton3D, time: Color) -> void:
	var cab := _osso(sk, "head")
	# Bandana + óculos de forja
	_peca(cab, _cilindro(0.58, 0.6, 0.14), Vector3(0, 0.7, 0), Vector3.ZERO, Vector3.ONE, _plano(time.darkened(0.3)))
	for s in [-1, 1]:
		_peca(cab, _cilindro(0.12, 0.12, 0.1), Vector3(0.2 * s, 0.78, 0.45), Vector3(70, 0, 0), Vector3.ONE, _neon(FOGO, 1.4))
	# Avental de couro
	var peito := _osso(sk, "chest")
	_peca(peito, _caixa(Vector3(0.7, 0.9, 0.06)), Vector3(0, -0.05, 0.42), Vector3(-5, 0, 0), Vector3.ONE, _plano(Color(0.28, 0.17, 0.1)))
	# Martelo grande com a cabeça em brasa
	var mao := _osso(sk, "handslot.r")
	_peca(mao, _cilindro(0.05, 0.05, 1.0), Vector3(0, 0.35, 0), Vector3.ZERO, Vector3.ONE, _plano(Color(0.3, 0.2, 0.12)))
	_peca(mao, _caixa(Vector3(0.5, 0.28, 0.28)), Vector3(0, 0.9, 0), Vector3.ZERO, Vector3.ONE, _neon(FOGO, 1.5))

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
