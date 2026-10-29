extends SceneTree
## Prancha das peças prontas (.scn) de um tema, uma imagem por peça.
## Uso (xvfb no servidor):
##   xvfb-run -a -s "-screen 0 800x600x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_pecas.gd -- DIR tema peca1 peca2 ...
## Salva DIR/peca_NN.png; a montagem com números é feita fora (tools/montar_prancha.py).

func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0]
	var tema: String = args[1]
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(800, 600)
	for i in range(2, args.size()):
		var cena := Node3D.new()
		root.add_child(cena)
		_luz(cena)
		var ps: PackedScene = load("res://assets/ninja/%s/%s.scn" % [tema, args[i]])
		var no: Node3D = ps.instantiate()
		cena.add_child(no)
		var mi: MeshInstance3D = no.get_node("Malha")
		var bb := mi.get_aabb()
		var centro := bb.get_center()
		var raio := bb.size.length() * 0.5
		var cam := Camera3D.new()
		cam.fov = 40
		cena.add_child(cam)
		cam.position = centro + Vector3(0.55, 0.55, 0.8).normalized() * raio * 2.5
		cam.look_at(centro)
		for k in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(saida.path_join("peca_%02d.png" % (i - 1)))
		cena.queue_free()
		await process_frame
	quit()


func _luz(cena: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.05, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.8)
	env.ambient_light_energy = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(0.8, 0.85, 1.0)
	sol.light_energy = 1.2
	sol.rotation_degrees = Vector3(-50, 35, 0)
	sol.shadow_enabled = true
	cena.add_child(sol)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	chao.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.17, 0.15, 0.22)
	chao.material_override = m
	cena.add_child(chao)
