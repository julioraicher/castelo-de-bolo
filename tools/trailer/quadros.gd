extends SceneTree
## Quadros-chave do trailer: roda a partida de verdade (bots), congela e
## fotografa com câmera de cinema (baixa, perto, sem HUD).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/trailer/quadros.gd -- DIR --autoplay --tema=1 --perf=3
## Salva DIR/NN_nome.png. Sem tipos do jogo aqui (compila antes dos autoloads).

var g: Node
var cam: Camera3D
var saida := ""


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	saida = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(1280, 720)
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	g = jogo if "units" in jogo else jogo.find_child("Game", true, false)
	for k in 900:  # ~15 s de partida: bots espalhados, brigas no meio
		await process_frame
	for u in g.units:
		u.power = 1.0  # marcas e olhos acesos
	for k in 10:
		await process_frame
	paused = true
	if g.hud:
		g.hud.visible = false
	cam = root.get_viewport().get_camera_3d()
	cam.process_mode = Node.PROCESS_MODE_ALWAYS
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam.fov = 38.0

	var mask_az: Vector3 = g.princesses[0].global_position
	var mask_vm: Vector3 = g.princesses[1].global_position
	var meio := (mask_az + mask_vm) * 0.5
	var lado := (mask_vm - mask_az).normalized()
	var lateral := lado.cross(Vector3.UP)

	# 01 máscara de perto, de baixo
	await _foto("01_mascara", mask_vm + lateral * 2.6 - lado * 1.2 + Vector3(0, 0.7, 0), mask_vm + Vector3(0, 1.0, 0))
	# 02 castelo vermelho de baixo, enorme
	await _foto("02_castelo", mask_vm - lado * 20.0 + Vector3(0, 1.2, 0), mask_vm + Vector3(0, 6.0, 0), 50.0)
	# 03 vila e rio: plano aberto baixo
	await _foto("03_vila", meio + lateral * 26.0 + Vector3(0, 4.0, 0), meio + Vector3(0, 1.0, 0), 55.0)
	# 04 ninja azul de perto
	var az := _mais_perto(meio, 0)
	if az:
		var p: Vector3 = az.global_position
		var f: Vector3 = -az.global_transform.basis.z
		await _foto("04_ninja_azul", p + f * 2.2 + Vector3(0, 1.0, 0), p + Vector3(0, 1.1, 0), 34.0)
	# 05 ninja vermelho de baixo, ameaçador
	var vm := _mais_perto(meio, 1)
	if vm:
		var p: Vector3 = vm.global_position
		var f: Vector3 = -vm.global_transform.basis.z
		await _foto("05_ninja_vermelho", p + f * 2.6 + Vector3(0, 0.4, 0), p + Vector3(0, 1.4, 0), 40.0)
	# 06 briga: o par azul x vermelho mais próximo
	var par := _briga()
	if par:
		var c: Vector3 = (par[0].global_position + par[1].global_position) * 0.5
		var d: Vector3 = (par[1].global_position - par[0].global_position).normalized()
		await _foto("06_briga", c + d.cross(Vector3.UP) * 4.0 + Vector3(0, 1.2, 0), c + Vector3(0, 0.9, 0), 42.0)
	# 07 exército: muitos de um time vistos de trás do castelo
	await _foto("07_exercito", mask_az + lado * 3.0 + Vector3(0, 2.0, 0), meio + Vector3(0, 0.5, 0), 45.0)
	quit()


func _foto(nome: String, de: Vector3, para: Vector3, fov := 38.0) -> void:
	cam.fov = fov
	cam.global_position = de
	cam.look_at(para)
	for k in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida.path_join(nome + ".png"))
	print("quadro ", nome)


func _mais_perto(alvo: Vector3, time: int) -> Node3D:
	var melhor: Node3D = null
	var dm := INF
	for u in g.units:
		if u.team == time and u.alive:
			var d: float = u.global_position.distance_to(alvo)
			if d < dm:
				dm = d
				melhor = u
	return melhor


func _briga() -> Array:
	var melhor := []
	var dm := INF
	for a in g.units:
		for b in g.units:
			if a.team == 0 and b.team == 1 and a.alive and b.alive:
				var d: float = a.global_position.distance_to(b.global_position)
				if d < dm and d > 0.6:
					dm = d
					melhor = [a, b]
	return melhor
