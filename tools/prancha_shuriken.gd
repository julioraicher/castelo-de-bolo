extends SceneTree
## Prancha da shuriken do Ninja Shuriken: projétil parado de perto (chão claro e
## escuro) e o boneco de frente e de costas, no jogo de verdade (modo teste).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_shuriken.gd -- DIR --sandbox --classe=arqueiro
## Salva DIR/q_*.png. Sem tipos do jogo por nome (compila antes dos autoloads).

var _saida := ""
var g: Node
var cam: Camera3D


func _init() -> void:
	_rodar.call_deferred()


func _esperar(n: int) -> void:
	for k in n:
		await process_frame


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_saida.path_join("q_%s.png" % nome))


func _rodar() -> void:
	_saida = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	root.size = Vector2i(1280, 720)
	root.get_node("/root/Settings").auto_quality = false
	var fx: GDScript = load("res://scripts/fx/fx_projetil.gd")
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
	await _esperar(300)  # passa a proteção de quem acabou de nascer
	cam = root.get_viewport().get_camera_3d()
	cam.set_process(false)
	cam.set_physics_process(false)
	var pl: Node3D = g.player
	pl.set_physics_process(false)
	var base: Vector3 = pl.global_position
	var fr: Vector3 = g.arena.forward(pl.team)
	var lado := fr.cross(Vector3.UP).normalized()
	# Projétil parado: um no chão do jogo, outro sobre um chão escuro (noite/sombra).
	var alvo := base + fr * 6.0
	alvo.y = g.arena.ground_y(alvo.x, alvo.z)
	var escuro := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.1, 1.1)
	escuro.mesh = pm
	var me := StandardMaterial3D.new()
	me.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	me.albedo_color = Color(0.09, 0.08, 0.1)
	escuro.material_override = me
	g.add_child(escuro)
	escuro.global_position = alvo + lado * 0.55 + Vector3(0, 0.02, 0)
	for k in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = fx.malha_shuriken()
		mi.material_override = fx.mat_solido()
		g.add_child(mi)
		mi.global_position = alvo + lado * (0.55 if k == 1 else -0.55) + Vector3(0, 0.05, 0)
		mi.rotation_degrees = Vector3(90, 15, 0)
		mi.scale = Vector3.ONE * 1.3
	cam.fov = 30.0
	cam.global_position = alvo + Vector3(0, 3.2, 0) - fr * 1.6
	cam.look_at(alvo)
	await _esperar(10)
	await _foto("projetil")
	# Boneco: frente e costas, de perto.
	for vista in [["frente", 1.0], ["costas", -1.0]]:
		var olhar: Vector3 = pl.global_position + Vector3(0, 1.0, 0)
		var dirc: Vector3 = (-pl.global_basis.z).normalized() * vista[1]
		cam.fov = 30.0
		cam.global_position = olhar + dirc * 4.2 + lado * 1.2 + Vector3(0, 1.0, 0)
		cam.look_at(olhar)
		await _esperar(10)
		await _foto(vista[0])
	quit()
