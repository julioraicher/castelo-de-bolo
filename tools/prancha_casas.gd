extends SceneTree
## Prancha das casas das classes (Ciclo 2.21): o pátio azul com um bairro em
## cada estado (tapetes com fantasmas, obra, pronta no nível 2, nível 4) e
## closes no ângulo da câmera do jogo. Roda o jogo de verdade:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_casas.gd -- DIR [--tema=N] [--autoplay]
## Salva DIR/patio.png e DIR/bairro_0..3.png. Sem tipos do jogo aqui.


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var saida: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(1280, 720)
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	for k in 30:
		await process_frame
	var g: Node = jogo if "oficinas" in jogo else jogo.find_child("Game", true, false)
	var azuis := []
	for of in g.oficinas:
		if of.team == 0:
			azuis.append(of)
	# 0: tapetes (fantasmas); 1: obra a 55 %; 2: pronta (nível 2); 3: nível 4.
	if azuis.size() >= 4:
		g.madeira[0] = 50
		azuis[1].escolher(0)
		azuis[1].madeira_entregue = 4
		azuis[1].add_progress(0.55, null)
		azuis[2].escolher(1)
		azuis[2].madeira_entregue = azuis[2].custo()
		azuis[2].add_progress(1.0, null)
		azuis[3].escolher(0)
		azuis[3].madeira_entregue = azuis[3].custo()
		azuis[3].add_progress(1.0, null)
		azuis[3].subir_nivel()
		azuis[3].subir_nivel()
		g.madeira[0] = 0
	for k in 90:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida.path_join("patio.png"))
	var cam := root.get_viewport().get_camera_3d()
	var cfg = root.get_node("/root/Config").cfg
	for i in azuis.size():
		var alvo: Vector3 = azuis[i].global_position + Vector3(0, 0, -0.6)
		cam.set_process(false)
		cam.set_physics_process(false)
		cam.global_position = alvo + cfg.camera_offset * 0.62
		cam.look_at(alvo + Vector3(0, 1.4, 0))
		for k in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(saida.path_join("bairro_%d.png" % i))
	quit()
