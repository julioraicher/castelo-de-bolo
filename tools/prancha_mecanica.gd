extends "res://tools/prancha_piloto.gd"
## Piloto "casas que funcionam": casa com roda d'água e oficina de chapéus
## (engrenagens, manivela, martelo, pilão), na luz dos temas.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 30 \
##     -s tools/prancha_mecanica.gd -- DIR [filme]
## Salva DIR/<tema>_<vista>.png; com "filme", em vez disso DIR/filme/f_NNN.png
## (3 s por vista a 30 quadros por segundo) para montar o vídeo com ffmpeg.

var _quadro := 0

const PECAS := [["casa_moinho", Vector3(-3.2, 0, 0)], ["oficina_azul", Vector3(5.6, 0, 0.6)]]
const VISTAS_M := [
	["jogo", Vector3(0, 21, 19), 19.0, 42.0, Vector3(1.0, 1.0, 0.8)],
	["casa", Vector3(0.25, 0.3, 1.0), 9.5, 40.0, Vector3(-1.6, 1.6, 1.2)],
	["oficina", Vector3(-0.2, 0.35, 1.0), 6.5, 40.0, Vector3(5.6, 1.6, 1.0)],
]


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0]
	var filme := args.size() > 1 and args[1] == "filme"
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(960, 720)
	for tema in (["dia"] if filme else TEMAS):
		var cfg: Resource = load("res://config/temas/%s.tres" % tema)
		var cena := Node3D.new()
		root.add_child(cena)
		_ambiente(cena, cfg)
		for p in PECAS:
			_peca(cena, tema, p[0], p[1])
		_entorno_m(cena)
		var cam := Camera3D.new()
		cena.add_child(cam)
		for v in VISTAS_M:
			cam.fov = v[3]
			var alvo: Vector3 = v[4]
			cam.position = alvo + (v[1] as Vector3).normalized() * float(v[2])
			cam.look_at(alvo)
			if filme:
				root.size = Vector2i(1280, 720)
				DirAccess.make_dir_recursive_absolute(saida.path_join("filme"))
				for f in 90:
					await process_frame
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(saida.path_join("filme/f_%03d.png" % _quadro))
					_quadro += 1
				continue
			for k in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(saida.path_join("%s_%s.png" % [tema, v[0]]))
		cena.queue_free()
		await process_frame
	quit()


func _entorno_m(cena: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for nome in ["capim.scn", "flores.scn", "pedrinhas.scn"]:
		var malha: Mesh = ((load("res://assets/ninja/dia/" + nome) as PackedScene).instantiate().get_node("Malha") as MeshInstance3D).mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malha
		var pts := []
		while pts.size() < (220 if nome == "capim.scn" else 40):
			var p := Vector3(rng.randf_range(-12, 14), 0, rng.randf_range(-9, 9))
			if (p.x > -6.5 and p.x < 2.4 and absf(p.z) < 4.5) or (absf(p.x - 5.6) < 2.6 and absf(p.z - 0.6) < 2.6):
				continue
			pts.append(p)
		mm.instance_count = pts.size()
		for k in pts.size():
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), pts[k]))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cena.add_child(mi)
