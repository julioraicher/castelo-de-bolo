extends SceneTree
## Prancha do lote D (Ciclo 2.32): espírito, os 5 itens e as armadilhas do
## Construtor, parados e em ação, no jogo de verdade (modo teste, mostruário).
##   xvfb-run -a -s "-screen 0 1600x1400x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_itens.gd -- DIR --sandbox
## Salva DIR/prancha_itens.jpg (e cada quadro em DIR/q_*.png). Sem tipos do
## jogo por nome aqui (o script compila antes dos autoloads).

var _saida := ""
var _quadros: Array = []  # [Image, legenda]
var g: Node
var cam: Camera3D
var FX: GDScript


func _init() -> void:
	_rodar.call_deferred()


func _esperar(n: int) -> void:
	for k in n:
		await process_frame


func _mirar(alvo: Vector3, dist := 3.4, alto := 2.2) -> void:
	cam.fov = 32.0
	cam.global_position = alvo + Vector3(0, alto, dist)
	cam.look_at(alvo)


func _foto(legenda: String, nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_saida.path_join("q_%s.png" % nome))
	var w := img.get_width()
	var h := img.get_height()
	var cw := int(h * 4.0 / 3.0)
	img = img.get_region(Rect2i((w - cw) / 2, 0, cw, h))
	img.resize(400, 300, Image.INTERPOLATE_LANCZOS)
	_quadros.append([img, legenda])


func _rodar() -> void:
	_saida = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	root.size = Vector2i(1280, 720)
	root.get_node("/root/Settings").auto_quality = false
	FX = load("res://scripts/fx/fx_itens.gd")
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	await _esperar(30)
	g = jogo if "oficinas" in jogo else jogo.find_child("Game", true, false)
	for m in g.get_children():
		if "_painel" in m and m.has_method("_begin"):
			m._painel.visible = false
			m._started = true
	paused = false
	g.hud.visible = false
	await _esperar(40)
	cam = root.get_viewport().get_camera_3d()
	cam.set_process(false)
	cam.set_physics_process(false)
	var slots: Array = g.modo_teste._mostruario
	var p0: Vector3 = slots[0][1]
	var fr: Vector3 = g.arena.forward(g.player.team)
	# O jogador e os bonecos de treino ficam longe do mostruário.
	g.player.global_position = p0 + fr * 12.0
	g.player.reset_physics_interpolation()
	await _esperar(20)
	var nomes := {"pocao": "Poção: cabaça", "escudo": "Escudo: leque de guerra", "velocidade": "Velocidade: geta",
			"dano": "Dano dobrado: kunais", "medidor": "Poder cheio: pergaminho", "espirito": "Espírito (hitodama)"}
	for s: Array in slots:
		var no: Node3D = s[2]
		_mirar(no.global_position + Vector3(0, 0.9, 0))
		await _esperar(12)
		await _foto(nomes[s[0]], s[0])
	# Fila inteira, no ângulo da câmera do jogo.
	var meio: Vector3 = (slots[0][1] + slots[5][1]) * 0.5
	cam.fov = 40.0
	cam.global_position = meio + root.get_node("/root/Config").cfg.camera_offset * 0.75
	cam.look_at(meio + Vector3(0, 0.6, 0))
	await _esperar(10)
	await _foto("Mostruário do modo teste", "fila")
	# Armadilhas (estrepes do Construtor, mina do Armadilheiro).
	var trap_gd: GDScript = load("res://scripts/items/trap.gd")
	var lado := Vector3.UP.cross(fr).normalized()
	var pt := meio - fr * 4.0
	pt.y = g.arena.ground_y(pt.x, pt.z, pt.y + 5.0)
	g.player.set_class(load("res://config/classes/construtor.tres"))
	var estrepes: Node3D = trap_gd.new()
	g.add_child(estrepes)
	estrepes.setup(g, g.player, pt - lado * 1.6)
	g.player.set_class(load("res://config/classes/armadilheiro.tres"))
	var mina: Node3D = trap_gd.new()
	g.add_child(mina)
	mina.setup(g, g.player, pt + lado * 1.6)
	await _esperar(4)
	_mirar(estrepes.global_position + Vector3(0, 0.15, 0), 3.0, 2.6)
	await _esperar(2)
	await _foto("Estrepes caindo (armar)", "estrepes_arma")
	await _esperar(30)
	await _foto("Estrepes: makibishi + fita do time", "estrepes")
	_mirar(mina.global_position + Vector3(0, 0.25, 0), 2.6, 2.0)
	await _esperar(8)
	await _foto("Mina: panela de pólvora", "mina")
	# Em ação (câmera lenta: o xvfb é lento e os efeitos duram décimos de s).
	Engine.time_scale = 0.2
	var esp: Node3D = slots[5][2]
	var pe := esp.global_position
	g.cakes.erase(esp)
	esp.queue_free()
	FX.hitodama_pego(g, pe)
	_mirar(pe + Vector3(0, 0.9, 0), 3.6, 2.2)
	await _esperar(9)
	await _foto("Espírito pego", "espirito_pego")
	var it: Node3D = slots[1][2]
	var pi := it.global_position + Vector3(0, 0.95, 0)
	g.pickups.erase(it)
	it.queue_free()
	FX.item_pego(g, pi, "escudo", null)
	_mirar(pi, 3.6, 1.8)
	await _esperar(5)
	await _foto("Item pego (escudo)", "item_pego")
	var pf := estrepes.global_position
	estrepes.queue_free()
	FX.estrepes_fisga(g, pf, Vector3.FORWARD)
	_mirar(pf + Vector3(0, 0.3, 0), 3.4, 2.4)
	await _esperar(5)
	await _foto("Estrepes pisados", "estrepes_fisga")
	var pm := mina.global_position
	mina._explode()
	mina.queue_free()
	_mirar(pm + Vector3(0, 0.6, 0), 5.5, 3.5)
	await _esperar(6)
	await _foto("Mina estourando", "mina_estoura")
	var masc: Node3D = g.princesses[g.player.team]
	FX.hitodama_preso(g, masc.global_position, true)
	_mirar(masc.global_position + Vector3(0, 1.6, 0), 6.0, 3.5)
	await _esperar(14)
	await _foto("Espírito preso na máscara", "preso")
	await _montar_prancha()
	quit()


func _montar_prancha() -> void:
	root.size = Vector2i(1600, 1320)
	var camada := CanvasLayer.new()
	camada.layer = 100
	root.add_child(camada)
	var fundo := ColorRect.new()
	fundo.color = Color(0.09, 0.08, 0.12)
	fundo.size = Vector2(1600, 1320)
	camada.add_child(fundo)
	var titulo := Label.new()
	titulo.text = "Ciclo 2.32 · lote D: espírito, itens e armadilhas (parado e em ação)"
	titulo.position = Vector2(20, 8)
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(0.95, 0.75, 0.3))
	camada.add_child(titulo)
	for i in _quadros.size():
		var q: Array = _quadros[i]
		var x := 0.0 + (i % 4) * 400
		var y := 46.0 + (i / 4) * 318
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(q[0])
		tr.position = Vector2(x, y)
		tr.size = Vector2(400, 300)
		camada.add_child(tr)
		var l := Label.new()
		l.text = q[1]
		l.position = Vector2(x + 8, y + 272)
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 6)
		camada.add_child(l)
	await _esperar(4)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_jpg(_saida.path_join("prancha_itens.jpg"), 0.85)
