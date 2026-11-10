extends SceneTree
## Bancada do kit de magia: chão claro, um boneco de referência e um efeito por
## vez, com quadros salvos em tempos fixos. Serve para calibrar forma e cor sem
## rodar a partida. Uso (xvfb):
##   xvfb-run -a -s "-screen 0 800x450x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/bancada_magia.gd -- DIR nome[,nome...]
## Salva DIR/<nome>_<i>.png. Nomes: ver `_efeito`.

const TEMPOS := [0.06, 0.16, 0.3, 0.5, 0.8, 1.2]
var _saida := "user://bancada"
var _nomes: Array = []
var _cena: Node3D


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	if args.size() > 1:
		_nomes = Array(args[1].split(","))
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar.call_deferred()


func _rodar() -> void:
	root.size = Vector2i(800, 450)
	var M = load("res://scripts/fx/magia.gd")
	var F = load("res://scripts/fx/fx.gd")
	var P = load("res://scripts/fx/fx_projetil.gd")
	root.get_node("/root/Settings").quality = 3
	for nome in _nomes:
		_cena = Node3D.new()
		root.add_child(_cena)
		_montar()
		await process_frame
		await process_frame
		_efeito(nome, M, F, P)
		var t0 := Time.get_ticks_msec()
		for i in TEMPOS.size():
			while (Time.get_ticks_msec() - t0) / 1000.0 < TEMPOS[i]:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%d.png" % [_saida, nome, i])
		_cena.queue_free()
		await process_frame
	quit()


func _montar() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.62, 0.38)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.environment.ambient_light_energy = 0.7
	_cena.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	_cena.add_child(sol)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	chao.mesh = pm
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.74, 0.72, 0.66)
	chao.material_override = cm
	_cena.add_child(chao)
	for x in [0.0, 3.2]:
		var b := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.45
		cap.height = 1.8
		b.mesh = cap
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.25, 0.45, 0.9) if x == 0.0 else Color(0.9, 0.3, 0.25)
		b.material_override = bm
		b.position = Vector3(x, 0.9, 0)
		b.name = "B%d" % int(x)
		_cena.add_child(b)
	var cam := Camera3D.new()
	cam.fov = 42
	_cena.add_child(cam)
	cam.position = Vector3(1.6, 6.2, 8.0)
	cam.look_at(Vector3(1.6, 0.8, 0))


func _efeito(nome: String, M, F, P) -> void:
	var g := _cena
	var o := Vector3.ZERO
	var b0: Node3D = _cena.get_node("B0")
	match nome:
		"chama": M.chama(g, o + Vector3(3.2, 0, 0), "raposa", 1.6, 6.0, 1.2)
		"chama_brasa": M.chama(g, o + Vector3(3.2, 0, 0), "brasa", 1.7, 6.0, 1.2)
		"onda": M.onda(g, o, "brasa", 5.0, 1.2)
		"estouro": M.estouro(g, o, "brasa", 4.0, 1.2)
		"selo": M.selo(g, o + Vector3(3.2, 0, 0), "sombra", 4.0, 1.3, {"escrita": 0.3})
		"selo_luz": M.selo(g, o, "luz", 4.0, 1.3, {"petalas": 8, "pontas": 0, "escrita": 0.3})
		"vortice":
			M.vortice(b0, "vento", 2.0, 3.4, 1.2, {"r_topo": 1.9, "gira": 1.9})
			M.vortice(b0, "aco", 1.2, 2.3, 1.2, {"r_topo": 1.5, "gira": -2.6, "forca": 1.6, "base": 0.15, "topo": 0.02, "y": 0.2})
		"aura":
			var a = M.chama(b0, o, "brasa", 1.15, 3.1, 1.3, {"segura": 0.8, "r_topo": 0.3, "forca": 1.2, "base": 0.7, "topo": -0.1, "giro": 0.0, "rola": Vector2(0.25, -1.9), "atras": true})
		"lanca": M.lanca(g, o + Vector3(0, 1.2, 0), o + Vector3(6, 1.2, 0), "aco", 0.5, 1.2)
		"lanca_ceu": M.lanca(g, o + Vector3(3.2, 12, 0), o + Vector3(3.2, 0.2, 0), "luz", 0.5, 1.2, {"cresce": 0.1})
		"rachaduras": M.rachaduras(g, o, "brasa", 4.5, 9, 1.3)
		"bola": M.bola(g, o + Vector3(3.2, 0.6, 0), "brasa", 2.6, 1.2)
		"fumaca": M.bola(g, o + Vector3(3.2, 1.2, 0), "fumaca", 2.0, 1.2, {"segura": 0.3, "sobe": 0.4, "base": 0.55, "topo": 0.75})
		"slash": 
			F.slash(g, o + Vector3(0, 1.0, 0), Vector3(1, 0, 0), 2.6, 120.0, Color(1, 1, 1), 22.0, false)
		"slash_forte": F.slash(g, o + Vector3(0, 1.0, 0), Vector3(1, 0, 0), 3.2, 150.0, Color(1.0, 0.78, 0.25), -22.0, true)
		"slash360": F.slash(g, o + Vector3(0, 0.9, 0), Vector3(1, 0, 0), 3.5, 360.0, Color(1, 0.72, 0.2), 0.0, true)
		"pillar": F.pillar(g, o, Color(1.0, 0.8, 0.3), 2.2)
		"ring": F.ring(g, o, Color(0.5, 1.0, 0.6, 0.7), 4.0)
		"anel_sobe": M.anel_sobe(g, o, "luz", 2.4, 4.0, 1.2)
		"burst": F.burst(g, o + Vector3(3.2, 1, 0), Color(1.0, 0.6, 0.2), 18, 8.0)
		"zap": F.zap(g, o + Vector3(0, 2.2, 0), o + Vector3(5, 1.0, 0), Color(0.6, 1.0, 1.0), 6)
