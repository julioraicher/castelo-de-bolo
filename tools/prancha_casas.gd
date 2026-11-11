extends SceneTree
## Prancha das casas das classes (Ciclo 2.22): um bairro em cada degrau da
## escada (Nv1, Nv2 com o painel da escolha, Nv3 com a casa recém-pronta, Nv4,
## Nv5), em close no ângulo da câmera do jogo, mais o pátio inteiro no fim.
## Roda o jogo de verdade (de preferência no modo teste, sem bots):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_casas.gd -- DIR --sandbox [--base=kitsune] [--caminho=1]
## Salva DIR/nv1.png .. nv5.png, DIR/painel.png e DIR/patio.png. Sem tipos do jogo aqui.


func _init() -> void:
	_rodar.call_deferred()


func _foto(arq: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(arq)


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0]
	var base_id := "kitsune"
	var lado := 1
	for a in args:
		if a.begins_with("--base="):
			base_id = a.trim_prefix("--base=")
		elif a.begins_with("--caminho="):
			lado = int(a.trim_prefix("--caminho="))
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(1280, 720)
	root.get_node("/root/Settings").auto_quality = false  # o xvfb é lento: sem baixar a qualidade
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	for k in 30:
		await process_frame
	var g: Node = jogo if "oficinas" in jogo else jogo.find_child("Game", true, false)
	# Fecha a tela inicial (o jogo começa pausado nela).
	for m in g.get_children():
		if "_painel" in m and "_sandbox_escolhido" in m:
			m._painel.visible = false
	paused = false
	var of = null
	for o in g.oficinas:
		if o.team == g.player.team and String(o.base.id) == base_id:
			of = o
	if of == null:
		push_error("prancha: bairro %s não encontrado" % base_id)
		quit(1)
		return
	g.madeira[of.team] = 200
	var cam := root.get_viewport().get_camera_3d()
	var cfg = root.get_node("/root/Config").cfg
	cam.set_process(false)
	cam.set_physics_process(false)
	var alvo: Vector3 = of.global_position + Vector3(0, 0, -0.2)
	cam.global_position = alvo + cfg.camera_offset * 0.7
	cam.look_at(alvo + Vector3(0, 1.6, 0))
	# O jogador fica fora do quadro (não tampa a barraquinha).
	g.player.global_position = of.global_position + Vector3(0, 0, 14)
	g.player.reset_physics_interpolation()
	for k in 40:
		await process_frame
	await _foto(saida.path_join("nv1.png"))
	of.subir_nivel()
	for k in 70:
		await process_frame
	await _foto(saida.path_join("nv2.png"))
	# Painel da escolha, como o jogador vê ([F] no bairro, Construtor): o
	# jogador precisa estar no bairro, senão o painel fecha sozinho.
	g.player.global_position = of.global_position + Vector3(-4.2, 0, 2.6)
	g.player.reset_physics_interpolation()
	g.hud.abrir_escolha(of, func(_i): pass)
	for k in 6:
		await process_frame
	await _foto(saida.path_join("painel.png"))
	g.hud.fechar_escolha()
	g.player.global_position = of.global_position + Vector3(0, 0, 14)
	g.player.reset_physics_interpolation()
	of.escolher(lado)
	for k in 40:
		await process_frame
	of.madeira_entregue = of.custo()
	of.add_progress(1.0, null)
	for k in 80:
		await process_frame
	await _foto(saida.path_join("nv3.png"))
	of.subir_nivel()
	for k in 80:
		await process_frame
	await _foto(saida.path_join("nv4.png"))
	of.subir_nivel()
	for k in 80:
		await process_frame
	await _foto(saida.path_join("nv5.png"))
	quit()
