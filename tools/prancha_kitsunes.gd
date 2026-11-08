extends SceneTree
## Prancha das Kitsunes (Personagens 2.0): aprendiz + Luz e Sombria nos níveis
## 2 a 5, de frente e de costas, mais a mesma Kitsune parada/atacando/morta
## (agito 0, 1, -1) e o tamanho real na câmera do jogo. Salva PNGs em DIR.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 \
##   --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_kitsunes.gd -- DIR

const AZUL := Color(0.16, 0.45, 1.0)
const VERMELHO := Color(1.0, 0.16, 0.1)

var dir := "user://prancha_kitsunes"
var cena: Node3D
var cam: Camera3D

const LINHA := [["kitsune", 1], ["kitsune_luz", 2], ["kitsune_luz", 3], ["kitsune_luz", 4], ["kitsune_luz", 5],
		["kitsune_sombria", 2], ["kitsune_sombria", 3], ["kitsune_sombria", 4], ["kitsune_sombria", 5]]


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
	# Fileiras de frente (z=0) e de costas (x+100)
	for v in 2:
		for i in LINHA.size():
			var b := _boneco(LINHA[i][0], LINHA[i][1], AZUL, 0.0)
			b.position = Vector3(v * 100 + (i - 4) * 1.75, 0, 0)
			b.rotation.y = -0.35 if v == 0 else PI * 0.82
	# Parada, ataque, morte (Sombria 5 e Luz 3)
	var estados := [0.0, 1.0, -1.0]
	for k in 3:
		for j in 2:
			var b := _boneco("kitsune_sombria" if j == 0 else "kitsune_luz", 5 if j == 0 else 3, VERMELHO if j == 0 else AZUL, estados[k])
			b.position = Vector3(200 + (k - 1) * 4.2 + (j - 0.5) * 1.8, 0, 0)
			b.rotation.y = PI * 0.8
	# Câmera do jogo: aprendiz, Luz 5, Sombria 5 (azul x vermelho)
	var jogo := [["kitsune", 1], ["kitsune_luz", 5], ["kitsune_sombria", 5]]
	for i in 3:
		for t in 2:
			var b := _boneco(jogo[i][0], jogo[i][1], AZUL if t == 0 else VERMELHO, 0.0)
			b.position = Vector3(300 + (i - 1) * 3.2, 0, (t - 0.5) * 4.0)
			b.rotation.y = PI if t == 1 else 0.0
	# Dash por personalidade (de lado): Samurai e Ninja inclinados com os braços
	# para trás (PoseDash), Ronin no meio da cambalhota, Samurai antigo.
	var dashes := [["guerreiro", "ninja"], ["arqueiro", "ninja"], ["ronin_oni", "rolar"], ["guerreiro", ""]]
	for i in dashes.size():
		var b := _dash(dashes[i][0], dashes[i][1])
		b.position = Vector3(400 + (i - 1.5) * 2.6, 0, 0)
	for b in cena.get_children():
		if b.has_meta("rotulo"):
			(b.get_meta("rotulo") as Label3D).position = b.position + Vector3(0, 0.02, 0.9)
	cam = Camera3D.new()
	cena.add_child(cam)
	await _quadros(10)
	for v in 2:
		cam.fov = 36
		cam.position = Vector3(v * 100, 2.4, 14.5)
		cam.look_at(Vector3(v * 100, 1.1, 0))
		await _salvar("linha_%d.png" % v)
	cam.fov = 30
	cam.position = Vector3(200, 2.6, 15.0)
	cam.look_at(Vector3(200, 1.1, 0))
	await _salvar("estados.png")
	cam.fov = 30
	cam.position = Vector3(400, 2.0, 15.0)
	cam.look_at(Vector3(400, 0.9, 0))
	await _salvar("dash.png")
	cam.fov = 42
	cam.position = Vector3(300, 21, 19)
	cam.look_at(Vector3(300, 0, 0))
	await _salvar("jogo.png")
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
	env.background_color = Color(0.07, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.55, 0.6)
	env.ambient_light_energy = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.9, 0.78)
	sol.light_energy = 1.1
	sol.rotation_degrees = Vector3(-50, 30, 0)
	cena.add_child(sol)
	var contra := DirectionalLight3D.new()
	contra.light_color = Color(0.6, 0.5, 1.0)
	contra.light_energy = 0.4
	contra.rotation_degrees = Vector3(-15, 200, 0)
	cena.add_child(contra)
	for x in [0.0, 100.0, 200.0, 300.0, 400.0]:
		var chao := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(60, 30)
		chao.mesh = pm
		chao.position.x = x
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.14, 0.12)
		chao.material_override = m
		cena.add_child(chao)


func _boneco(id: String, nivel: int, time: Color, agito: float) -> Node3D:
	var cls: Resource = load("res://config/classes/%s.tres" % id)
	var n: Node3D = cls.model.instantiate()
	cena.add_child(n)
	var corpo: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visible = mi.name in cls.visible_meshes
		if mi.visible:
			corpo.append(mi)
	var pecas: MeshInstance3D = NinjaVisual.aplicar(n, corpo, cls.estilo_ninja, time, cls.escala_cabeca, true, cls.escala_extremidades, nivel)
	if pecas:
		pecas.set_instance_shader_parameter("agito", agito)
		pecas.set_instance_shader_parameter("poder_carga", 0.6)
	for mi in corpo:
		mi.set_instance_shader_parameter("cor_poder", cls.hat_color)
	n.scale = Vector3.ONE * cls.escala_modelo
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	var anim: String = cls.anim_idle
	if agito > 0.5:
		anim = cls.anim_attack
	elif agito < -0.5:
		anim = "Death_A"
	ap.play(anim)
	ap.seek(0.3 if agito >= 0.0 else 1.2, true)
	ap.pause()
	var rotulo := Label3D.new()
	rotulo.text = "%s %d" % [{"kitsune": "Aprendiz", "kitsune_luz": "Luz", "kitsune_sombria": "Sombria"}[id], nivel]
	if agito != 0.0:
		rotulo.text = "ataque" if agito > 0.0 else "morte"
	rotulo.font_size = 40
	rotulo.pixel_size = 0.004
	rotulo.position = Vector3(0, -0.15, 0.6)
	rotulo.rotation.x = -0.3
	rotulo.modulate = Color(0.95, 0.9, 0.8)
	cena.add_child(rotulo)
	n.set_meta("rotulo", rotulo)
	return n


func _dash(id: String, estilo: String) -> Node3D:
	var cls: Resource = load("res://config/classes/%s.tres" % id)
	var n: Node3D = cls.model.instantiate()
	cena.add_child(n)
	var corpo: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visible = mi.name in cls.visible_meshes
		if mi.visible:
			corpo.append(mi)
	NinjaVisual.aplicar(n, corpo, cls.estilo_ninja, AZUL, cls.escala_cabeca, true, cls.escala_extremidades)
	n.scale = Vector3.ONE * cls.escala_modelo
	n.rotation.y = -PI * 0.5  # correndo para a esquerda da tela
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	if estilo == "ninja":
		var pd := PoseDash.new()
		pd.peso = 1.0
		n.find_child("Skeleton3D", true, false).add_child(pd)
		ap.play("Running_B")
		ap.seek(0.25, true)
		n.rotation.x = 0.0
		n.rotate_object_local(Vector3.RIGHT, 0.6)
	else:
		ap.play("Dodge_Forward")
		ap.seek(0.3 if estilo == "rolar" else 0.15, true)
		n.rotate_object_local(Vector3.RIGHT, 0.35)
	ap.pause()
	var rotulo := Label3D.new()
	rotulo.text = {"ninja": "corrida ninja", "rolar": "Ronin rola", "": "antes"}[estilo] + "\n" + str(cls.display_name)
	rotulo.font_size = 40
	rotulo.pixel_size = 0.004
	rotulo.rotation.x = -0.3
	rotulo.modulate = Color(0.95, 0.9, 0.8)
	cena.add_child(rotulo)
	n.set_meta("rotulo", rotulo)
	return n
