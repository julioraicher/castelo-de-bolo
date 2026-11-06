extends SceneTree
## Piloto do item 7 da revisão (2026-11-06): roupa na cor da CLASSE e o time
## numa faixa (cinto, punhos, gola) + chapéu + aro. Prancha "atual x piloto"
## na câmera do jogo e de perto. Nada muda no jogo: o uniform usar_cor_classe
## do toon_time.gdshader só é ligado aqui.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 \
##   --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_cor_classe.gd -- DIR

const AZUL := Color(0.16, 0.45, 1.0)
const VERMELHO := Color(1.0, 0.16, 0.1)
const CLASSES := ["guerreiro", "arqueiro", "kitsune", "construtor", "ronin_oni", "arqueiro_yumi", "kitsune_luz", "kitsune_sombria"]
const COR_CLASSE := {
	"guerreiro": Color(0.34, 0.35, 0.4),       # aço grafite
	"arqueiro": Color(0.16, 0.15, 0.24),       # índigo-noite
	"kitsune": Color(0.88, 0.84, 0.8),         # branco de santuário
	"construtor": Color(0.5, 0.35, 0.2),       # couro e madeira
	"ronin_oni": Color(0.17, 0.15, 0.15),      # carvão
	"arqueiro_yumi": Color(0.32, 0.42, 0.24),  # musgo
	"kitsune_luz": Color(0.92, 0.82, 0.55),    # creme dourado
	"kitsune_sombria": Color(0.3, 0.2, 0.36),  # ameixa
}

var dir := "user://prancha_cor"
var cena: Node3D
var cam: Camera3D


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	_montar.call_deferred()


func _montar() -> void:
	root.size = Vector2i(1600, 900)
	cena = Node3D.new()
	root.add_child(cena)
	_ambiente()
	for c in CLASSES.size():
		var cls: Resource = load("res://config/classes/%s.tres" % CLASSES[c])
		for piloto in 2:
			for t in 2:
				var b := _boneco(cls, AZUL if t == 0 else VERMELHO, piloto == 1, CLASSES[c])
				# x: classe; z: atual (fundo) x piloto (frente); time lado a lado
				b.position = Vector3((c - 3.5) * 3.4 + (t - 0.5) * 1.4, 0, (piloto - 0.5) * 6.0)
	cam = Camera3D.new()
	cena.add_child(cam)
	for i in 8:
		await process_frame
	cam.fov = 48
	cam.position = Vector3(0, 26, 24)
	cam.look_at(Vector3(0, 0, 0))
	await _salvar("cor_classe_jogo.png")
	cam.fov = 34
	cam.position = Vector3(0, 6, 25)
	cam.look_at(Vector3(0, 0.8, 3.0))
	await _salvar("cor_classe_perto.png")
	quit()


func _salvar(nome: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(nome))
	print("salvo ", dir.path_join(nome))


func _boneco(cls: Resource, time: Color, piloto: bool, id: String) -> Node3D:
	var n: Node3D = cls.model.instantiate()
	cena.add_child(n)
	var corpo: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visible = mi.name in cls.visible_meshes
		if mi.visible:
			corpo.append(mi)
	NinjaVisual.aplicar(n, corpo, cls.estilo_ninja, time, cls.escala_cabeca, true)
	n.scale = Vector3.ONE * cls.escala_modelo
	if piloto:
		# O corpo usa material_override (NinjaVisual._material_corpo, em cache):
		# duplica para não pintar os bonecos "atuais" que dividem o material.
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi.material_override as ShaderMaterial
			if m and m.get_shader_parameter("textura") != null:
				var d: ShaderMaterial = m.duplicate()
				d.set_shader_parameter("usar_cor_classe", true)
				d.set_shader_parameter("cor_classe", COR_CLASSE[id])
				mi.material_override = d
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play(cls.anim_idle)
	ap.seek(0.3, true)
	ap.pause()
	return n


func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.52, 0.65)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_energy = 1.1
	sol.rotation_degrees = Vector3(-50, 30, 0)
	cena.add_child(sol)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 30)
	chao.mesh = pm
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(0.22, 0.3, 0.16)  # grama escura, como no mapa
	chao.material_override = mc
	cena.add_child(chao)
