extends SceneTree
## Prancha dos pilotos de torreta: cada estilo (a, b, c) nos dois times, lado a
## lado, com a luz do tema. Uso (xvfb no servidor):
##   xvfb-run -a -s "-screen 0 900x600x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_torretas.gd -- DIR [tema] [a,b,c]
## Salva DIR/torreta_<estilo>.png; a montagem com letras é feita fora (PIL).

var _saida := "user://torretas"
var _tema := "oni"
var _estilos := ["a", "b", "c"]
var _cena: Node3D


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	if args.size() > 1:
		_tema = args[1]
	if args.size() > 2:
		_estilos = Array(args[2].split(","))
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar.call_deferred()


func _rodar() -> void:
	root.size = Vector2i(900, 600)
	for e in _estilos:
		_cena = Node3D.new()
		root.add_child(_cena)
		_luz()
		var ok := true
		for i in 2:
			var cor: String = ["azul", "vermelho"][i]
			var path := "res://assets/ninja/%s/torreta_%s_%s.scn" % [_tema, e, cor]
			if e == "catapulta":
				path = "res://assets/ninja/%s/catapulta_%s.scn" % [_tema, cor]
			if not ResourceLoader.exists(path):
				push_error("sem modelo " + path)
				ok = false
				continue
			var m: Node3D = (load(path) as PackedScene).instantiate()
			m.position = Vector3(-2.1 + i * 4.2, 0, 0)
			m.rotation.y = deg_to_rad(-28.0 + i * 16.0)
			var arma: Node3D = m.get_node_or_null("Arma")
			if arma:
				arma.rotation.y = deg_to_rad(35.0 - i * 60.0)
			var braco: Node3D = m.get_node_or_null("Braco")
			if braco:
				braco.rotation.x = deg_to_rad(-100.0 + i * 140.0)  # repouso / fim do golpe
			_cena.add_child(m)
		if not ok:
			_cena.queue_free()
			continue
		var cam := Camera3D.new()
		cam.fov = 34
		_cena.add_child(cam)
		var centro := Vector3(0, 1.75, 0)
		cam.position = centro + Vector3(0.25, 0.42, 1.0).normalized() * 11.5
		cam.look_at(centro)
		for k in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_saida.path_join("torreta_%s.png" % e))
		print("salvo ", e)
		_cena.queue_free()
		await process_frame
	quit()


## Luz de "noite de festival": céu escuro, luar frio e brilho nas peças acesas.
func _luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.05, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.75)
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_cena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(0.85, 0.8, 1.0)
	sol.light_energy = 1.3
	sol.rotation_degrees = Vector3(-48, 30, 0)
	sol.shadow_enabled = true
	_cena.add_child(sol)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	chao.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.13, 0.2)
	chao.material_override = m
	_cena.add_child(chao)
