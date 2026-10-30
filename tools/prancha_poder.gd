extends SceneTree
## Prancha da rodada 3 do Ciclo 2.2: proporção nova (~3,5 cabeças, mãos e pés
## maiores) e marcas de poder acendendo com o medidor. Colunas: antes (cabeça
## 0,8), carga 0, carga 0,6 e pronto (1,0). Fileiras: as classes pedidas.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_poder.gd -- SAIDA.png [classes]

const AZUL := Color(0.16, 0.45, 1.0)
const COLUNAS := [["antes", 0.0], ["apagado", 0.0], ["carregando", 0.6], ["pronto", 1.0]]

var classes := ["guerreiro", "arqueiro", "monge", "construtor"]
var cena: Node3D


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0]
	if args.size() > 1:
		classes = Array(args[1].split(","))
	root.size = Vector2i(1600, 900)
	cena = Node3D.new()
	root.add_child(cena)
	_ambiente()
	for f in classes.size():
		var cls: Resource = load("res://config/classes/%s.tres" % classes[f])
		for c in COLUNAS.size():
			var antes: bool = COLUNAS[c][0] == "antes"
			var b := _boneco(cls, 0.8 if antes else cls.escala_cabeca, 1.0 if antes else cls.escala_extremidades, COLUNAS[c][1])
			b.position = Vector3((f * COLUNAS.size() + c - (classes.size() * COLUNAS.size() - 1) / 2.0) * 1.45 + (f - (classes.size() - 1) / 2.0) * 0.9, 0, 0)
			b.rotation.y = -0.45
	var cam := Camera3D.new()
	cam.fov = 30
	cena.add_child(cam)
	cam.position = Vector3(0, 3.0, 29.0)
	cam.look_at(Vector3(0, 1.0, 0))
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida)
	quit()


func _boneco(cls: Resource, cabeca: float, ext: float, carga: float) -> Node3D:
	var n: Node3D = cls.model.instantiate()
	cena.add_child(n)
	var corpo: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visible = mi.name in cls.visible_meshes
		if mi.visible:
			corpo.append(mi)
	NinjaVisual.aplicar(n, corpo, cls.estilo_ninja, AZUL, cabeca, true, ext)
	n.scale = Vector3.ONE * cls.escala_modelo
	for gi: GeometryInstance3D in n.find_children("*", "GeometryInstance3D", true, false):
		gi.set_instance_shader_parameter("poder_carga", carga)
		gi.set_instance_shader_parameter("cor_poder", cls.hat_color)
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play(cls.anim_idle)
	ap.seek(0.3, true)
	ap.pause()
	return n


func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.07, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.55, 0.7)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_hdr_threshold = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.75, 0.5)
	sol.light_energy = 1.1
	sol.rotation_degrees = Vector3(-35, 30, 0)
	sol.shadow_enabled = true
	cena.add_child(sol)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 30)
	chao.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.2, 0.24)
	chao.material_override = m
	cena.add_child(chao)
