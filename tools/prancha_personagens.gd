extends SceneTree
## Prancha das classes do jogo: monta cada boneco igual ao jogo (NinjaVisual +
## o .tres da classe) e salva, para cada fileira de 4 classes:
##   DIR/close_N.png  frente, 3/4 e costas
##   DIR/jogo_N.png   azul x vermelho na câmera do jogo, tamanho real
## Uso (precisa de janela; no servidor, xvfb):
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_personagens.gd -- DIR
## Fileiras próprias: -- DIR guerreiro,arqueiro,monge,construtor ronin_oni,...

const AZUL := Color(0.16, 0.45, 1.0)
const VERMELHO := Color(1.0, 0.16, 0.1)
const MAGENTA := Color(1.0, 0.25, 0.85)

var fileiras := [
	["guerreiro", "arqueiro", "monge", "construtor"],
	["ronin_oni", "arqueiro_yumi", "onmyoji", "mestre_polvora"],
	["lamina_dupla", "bombas_fumaca", "kitsune", "carpinteiro"],
]

var dir := "user://prancha"
var cena: Node3D
var cam: Camera3D


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	if args.size() > 1:
		fileiras = []
		for f in args.slice(1):
			fileiras.append(Array(f.split(",")))
	DirAccess.make_dir_recursive_absolute(dir)
	_montar()


func _montar() -> void:
	root.size = Vector2i(1600, 900)
	cena = Node3D.new()
	root.add_child(cena)
	_ambiente()
	var angulos := [0.0, -PI * 0.3, PI]
	for w in fileiras.size():
		var classes: Array = fileiras[w]
		for c in classes.size():
			var cls: Resource = load("res://config/classes/%s.tres" % classes[c])
			for v in 3:
				var b := _boneco(cls, AZUL)
				b.position = Vector3(w * 100 + (c - 1.5) * 4.1 + (v - 1) * 1.3, 0, 0)
				b.rotation.y = angulos[v]
			for t in 2:
				var b := _boneco(cls, AZUL if t == 0 else VERMELHO)
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
	for x in [0.0, 100.0, 200.0, 300.0, 1000.0, 1100.0, 1200.0, 1300.0]:
		var chao := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(60, 30)
		chao.mesh = pm
		chao.position.x = x
		chao.material_override = Fx_plano(Color(0.02, 0.022, 0.045))
		cena.add_child(chao)

func _boneco(cls: Resource, time: Color) -> Node3D:
	var n: Node3D = cls.model.instantiate()
	cena.add_child(n)
	var corpo: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visible = mi.name in cls.visible_meshes
		if mi.visible:
			corpo.append(mi)
	NinjaVisual.aplicar(n, corpo, cls.estilo_ninja, time, cls.escala_cabeca, true)
	n.scale = Vector3.ONE * cls.escala_modelo
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play(cls.anim_attack if cls.attack_kind != "melee" else cls.anim_idle)
	ap.seek(0.3, true)
	ap.pause()
	return n


func Fx_plano(c: Color) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
