extends SceneTree
## Vista de cima do Rio das Lanternas com os pontos da Economia do Construtor
## (bosques, bambuzal, pilha, maquininhas) postos à mão, para conferir o mapa
## antes de o jogo usá-los. Roda o jogo de verdade:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_economia_mapa.gd -- DIR --autoplay --vista=mapa [--tema=N]
## Salva DIR/mapa.png e DIR/mapa.txt (rótulo x_tela y_tela por linha).
## Sem tipos do jogo aqui (o script compila antes dos autoloads).

const TREES := [Vector2(9.5, 21.0), Vector2(8.0, 25.0)]     # locais do castelo
const PILHA := Vector2(9.0, 7.4)                             # local do castelo
const BAMBUS := [Vector2(6.8, -16.2), Vector2(8.4, -16.9), Vector2(7.2, 16.4), Vector2(-6.8, -16.2), Vector2(-8.4, -16.9), Vector2(-7.2, 16.4)]
const HATS := [Vector2(7, -9.2), Vector2(7, 9.2), Vector2(2.5, -9.2), Vector2(2.5, 9.2)]
const OFICINAS := [Vector2(-3.5, -7.0), Vector2(-3.5, 7.0)]


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var saida: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(1280, 720)
	var ajustes: Node = root.get_node("/root/Settings")
	ajustes.set("auto_quality", false)
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	for k in 60:
		await process_frame
	var pasta := "res://assets/ninja/crepusculo/"
	var cena := Node3D.new()
	root.add_child(cena)
	var rotulos := []
	for team in 2:
		var f := 1.0 if team == 0 else -1.0
		var mundo := func(v: Vector2) -> Vector3: return Vector3(-48.0 * f + v.x * f, 0, v.y)
		for k in TREES.size():
			_por(cena, pasta + "arvore_e3.scn", mundo.call(TREES[k]))
		rotulos.append(["bosque", mundo.call(TREES[0].lerp(TREES[1], 0.5))])
		_por(cena, pasta + "deposito_madeira.scn", mundo.call(PILHA))
		rotulos.append(["pilha", mundo.call(PILHA)])
		for h in HATS:
			_por(cena, pasta + "maquina_chapeu.scn", mundo.call(h))
		rotulos.append(["maquinas", mundo.call(Vector2(4.75, -9.2))])
		rotulos.append(["oficinas", mundo.call(OFICINAS[0])])
	for b in BAMBUS:
		_por(cena, pasta + "bambu_e3.scn", Vector3(b.x, 0, b.y))
	rotulos.append(["bambu", Vector3(7.5, 0, -16.5)])
	rotulos.append(["bambu", Vector3(-7.5, 0, -16.5)])
	rotulos.append(["bambu", Vector3(7.2, 0, 16.4)])
	rotulos.append(["bambu", Vector3(-7.2, 0, 16.4)])
	var cam := root.get_viewport().get_camera_3d()
	var g: Node = jogo if "hud" in jogo else jogo.find_child("Game", true, false)
	g.hud.visible = false
	for k in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida.path_join("mapa.png"))
	var txt := FileAccess.open(saida.path_join("mapa.txt"), FileAccess.WRITE)
	for r in rotulos:
		# unproject devolve coordenadas da tela-base do projeto (esticada), não da imagem.
		var p := cam.unproject_position(r[1]) * Vector2(root.size) / root.get_visible_rect().size
		txt.store_line("%s %d %d" % [r[0], p.x, p.y])
	txt.close()
	quit()


func _por(cena: Node3D, caminho: String, pos: Vector3) -> void:
	var no: Node3D = (load(caminho) as PackedScene).instantiate()
	no.position = pos
	cena.add_child(no)
