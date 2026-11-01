extends SceneTree
## Prancha piloto da Economia do Construtor (Ciclo 2.3), tema Crepúsculo:
## plantas nos 3 estágios, maquininha em 4 quadros de "fabricar", casinha com
## o contador de madeira. Também gera o ícone de tora (assets/ui/icone_tora.png).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_economia.gd -- DIR [--icone]
## --maquinas [--n2]: cada maquininha de classe (nível 1 ou 2). --emblemas: só a fileira de enfeites das classes. --icone: só gera o ícone (rode antes do --import, o contador o pré-carrega).
## Salva DIR/plantas.png, DIR/maquina_N.png, DIR/contador.png; a montagem é tools/montar_economia.py.
## Sem tipos do jogo aqui (o script compila antes dos autoloads).

const TEMA := "crepusculo"
const PASTA := "res://assets/ninja/crepusculo/"


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0]
	DirAccess.make_dir_recursive_absolute(saida)
	await _icone()
	if args.has("--icone"):
		quit()
		return
	var cfg: Resource = load("res://config/temas/%s.tres" % TEMA)
	if args.has("--maquinas"):  # a maquininha de cada classe, no meio do "fabricar"
		root.size = Vector2i(420, 470)
		var hp0: Script = load("res://scripts/items/hat_pad.gd")
		for c in ["guerreiro", "arqueiro", "kitsune", "construtor"]:  # = MAQUINAS de gerar_economia.gd
			var arq := "res://config/classes/%s.tres" % c
			var st: Resource = load(arq if ResourceLoader.exists(arq) else "res://config/classes/kitsune.tres")
			var c0 := _cena(cfg)
			var mq := _peca(c0, "maquina_" + c, Vector3.ZERO)
			mq.get_node("Enfeite").add_child(_carregar("emblema_" + c))
			var ch: Node3D = hp0.make_hat(st.hat_style, st.hat_color)
			ch.scale = Vector3.ONE * 0.85
			mq.get_node("Molde").add_child(ch)
			for k in 2:
				var h: Node3D = hp0.make_hat(st.hat_style, st.hat_color)
				h.scale = Vector3.ONE * 0.62
				mq.get_node("Estoque_%d" % (k + 1)).add_child(h)
			var ap0: AnimationPlayer = mq.get_node("AnimationPlayer")
			ap0.play("fabricar")
			ap0.seek(1.0, true)
			ap0.pause()
			(mq.get_node("Vapor") as CPUParticles3D).emitting = true
			var n2 := args.has("--n2")  # nível 2: mostra as peças N2_*
			if n2:
				for f in mq.get_children():
					if f.name.begins_with("N2_"):
						f.visible = true
			for k in 14:
				await process_frame
			await _foto(c0, Vector3(0, 1.5, 0), Vector3(0.3, 0.45, 1), 7.6 if n2 else 7.0, 40.0, saida.path_join("maq%s_%s.png" % ["2" if n2 else "", c]))
		quit()
		return
	if args.has("--emblemas"):  # só os enfeites do elenco do Ciclo 2.4, lado a lado
		root.size = Vector2i(1280, 300)
		var c0 := _cena(cfg)
		var lista := ["guerreiro", "arqueiro", "kitsune", "ronin_oni", "arqueiro_yumi", "armadilheiro", "bombardeiro"]
		for k in lista.size():
			var e := _peca(c0, "emblema_" + lista[k], Vector3((k - 3) * 1.0, 1.0, 0))
			e.scale = Vector3.ONE * 1.4
		await _foto(c0, Vector3(0, 1.0, 0), Vector3(0, 0.15, 1), 6.2, 40.0, saida.path_join("emblemas.png"))
		quit()
		return
	# 1. Plantas: árvore e bambu, broto -> jovem -> adulta.
	root.size = Vector2i(1280, 440)
	var cena := _cena(cfg)
	var xs := [-10.0, -6.6, -2.2, 2.6, 5.6, 9.6]
	var nomes := ["arvore_e1", "arvore_e2", "arvore_e3", "bambu_e1", "bambu_e2", "bambu_e3"]
	for k in 6:
		_peca(cena, nomes[k], Vector3(xs[k], 0, 0))
	await _foto(cena, Vector3(0, 2.2, 0), Vector3(0, 0.3, 1), 17.5, 40.0, saida.path_join("plantas.png"))
	# 2. Maquininha em 4 momentos da animação.
	root.size = Vector2i(400, 460)
	var hp: Script = load("res://scripts/items/hat_pad.gd")
	var guerreiro: Resource = load("res://config/classes/guerreiro.tres")
	var tempos := [0.42, 0.62, 1.0, 1.95]
	for q in 4:
		cena = _cena(cfg)
		var maq := _peca(cena, "maquina_chapeu", Vector3.ZERO)
		maq.get_node("Enfeite").add_child(_carregar("emblema_guerreiro"))
		var chapeu: Node3D = hp.make_hat(guerreiro.hat_style, guerreiro.hat_color)
		chapeu.scale = Vector3.ONE * 0.85
		maq.get_node("Molde").add_child(chapeu)
		for k in (2 if q < 3 else 3):  # estoque: o chapéu recém-feito vai para a prateleira
			var h: Node3D = hp.make_hat(guerreiro.hat_style, guerreiro.hat_color)
			h.scale = Vector3.ONE * 0.62
			maq.get_node("Estoque_%d" % (k + 1)).add_child(h)
		if q == 3:
			chapeu.visible = false
		var ap: AnimationPlayer = maq.get_node("AnimationPlayer")
		ap.play("fabricar")
		ap.seek(tempos[q], true)
		ap.pause()
		if q >= 2:
			var v: CPUParticles3D = maq.get_node("Vapor")
			v.emitting = true
			for k in (14 if q == 2 else 40):
				await process_frame
		await _foto(cena, Vector3(0, 1.25, 0), Vector3(0.3, 0.5, 1), 6.3, 40.0, saida.path_join("maquina_%d.png" % (q + 1)))
	# 3. Casinha em obra com o contador: Construtor (grande) e outra classe sem estoque (pequeno).
	root.size = Vector2i(880, 460)
	cena = _cena(cfg)
	var cm: Script = load("res://scripts/ui/contador_madeira.gd")
	for s in [-1.0, 1.0]:
		var of := _peca(cena, "oficina_azul", Vector3(s * 3.0, 0, 0))
		of.get_node("Telhado").visible = false
		var c: Node3D = cm.new()
		cena.add_child(c)
		c.position = Vector3(s * 3.0, 4.0, 0.5)
		if s < 0:
			c.mostrar(4, 6, true, false)
		else:
			c.mostrar(4, 6, false, true)
	_peca(cena, "deposito_madeira", Vector3(-0.2, 0, 3.2))
	_peca(cena, "tora", Vector3(1.0, 0.2, 3.6)).rotation_degrees.y = 25
	for k in 20:
		await process_frame
	await _foto(cena, Vector3(0, 2.2, 0), Vector3(0, 0.95, 1), 12.0, 42.0, saida.path_join("contador.png"))
	quit()


## Ícone de tora com fundo transparente, renderizado do próprio modelo.
func _icone() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.68, 0.8)
	env.ambient_light_energy = 1.5
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, -30, 0)
	sol.light_energy = 2.2
	sol.light_color = Color(1.0, 0.88, 0.7)
	vp.add_child(sol)
	var tora: Node3D = (load("res://assets/ninja/dia/tora.scn") as PackedScene).instantiate()  # paleta clara: lê em cima do fundo escuro
	tora.rotation_degrees = Vector3(0, 38, 0)
	vp.add_child(tora)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.45
	vp.add_child(cam)
	cam.position = Vector3(0, 1.2, 2.4)
	cam.look_at(Vector3.ZERO)
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui"))
	img.save_png("res://assets/ui/icone_tora.png")
	vp.queue_free()
	await process_frame


func _carregar(nome: String) -> Node3D:
	return (load(PASTA + nome + ".scn") as PackedScene).instantiate()


func _peca(cena: Node3D, nome: String, pos: Vector3) -> Node3D:
	var no := _carregar(nome)
	no.position = pos
	cena.add_child(no)
	return no


func _foto(cena: Node3D, alvo: Vector3, dir: Vector3, dist: float, fov: float, arquivo: String) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cena.add_child(cam)
	cam.position = alvo + dir.normalized() * dist
	cam.look_at(alvo)
	cam.make_current()
	for k in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(arquivo)
	cena.queue_free()
	await process_frame


## Céu, sol, neblina e chão pintado do tema (como no jogo).
func _cena(t: Resource) -> Node3D:
	var cena := Node3D.new()
	root.add_child(cena)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = t.sun_rotation_deg
	sol.light_color = t.sun_color
	sol.light_energy = t.sun_energy
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 40.0
	cena.add_child(sol)
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = t.sky_top
	ceu.sky_horizon_color = t.sky_horizon
	ceu.ground_horizon_color = t.ground_horizon
	ceu.ground_bottom_color = t.ground_bottom
	var sky := Sky.new()
	sky.sky_material = ceu
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = t.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = t.glow_intensity
	env.glow_bloom = 0.05
	env.adjustment_enabled = true
	env.adjustment_saturation = t.saturation
	env.adjustment_contrast = t.contrast
	env.fog_enabled = t.fog_enabled
	env.fog_light_color = t.fog_color
	env.fog_density = t.fog_density
	env.fog_sky_affect = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	chao.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/chao_pintado.gdshader")
	m.set_shader_parameter("grama_escura", t.grass_dark)
	m.set_shader_parameter("grama_clara", t.grass_light)
	m.set_shader_parameter("terra_escura", t.road_dark)
	m.set_shader_parameter("terra_clara", t.road_light)
	chao.material_override = m
	cena.add_child(chao)
	return cena
