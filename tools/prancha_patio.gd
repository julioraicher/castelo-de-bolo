extends SceneTree
## Print do pátio azul no ângulo da câmera do jogo, com as oficinas prontas
## (para ver se tudo fica à vista). Roda o jogo de verdade:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_patio.gd -- DIR --vista=patio --autoplay [--tema=N]
## --alvo=X,Z mira a câmera (mesmo ângulo) em outro ponto: DIR/alvo_X_Z.png.
## Salva DIR/patio.png. Sem tipos do jogo aqui (o script compila antes dos autoloads).


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var saida: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(1280, 720)
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	for k in 90:
		await process_frame
	var g: Node = jogo if "oficinas" in jogo else jogo.find_child("Game", true, false)
	var azuis := []
	for of in g.oficinas:
		if of.team == 0:
			azuis.append(of)
	for of in azuis:  # os bots costumam erguer as duas em ~12 s; aqui já nascem prontas
		if of.estado != 2:
			of.add_progress(1.0, null)
	for k in 60:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida.path_join("patio.png"))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--alvo="):
			var xz := a.trim_prefix("--alvo=").split(",")
			var alvo := Vector3(float(xz[0]), 0, float(xz[1]))
			var cam := root.get_viewport().get_camera_3d()
			cam.position = alvo + Vector3(0, 21, 19) * 1.0
			cam.look_at(alvo)
			for k in 20:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(saida.path_join("alvo_%s_%s.png" % [xz[0], xz[1]]))
	quit()
