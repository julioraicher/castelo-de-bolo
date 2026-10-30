extends SceneTree
## Prancha do piloto do Ciclo 2.2: casa + lanterna antigas × novas, nas luzes
## de dois temas (a luz vem do próprio .tres, como no jogo).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_piloto.gd -- DIR
## Salva DIR/<tema>_<vista>.png; a montagem com legendas é tools/montar_piloto.py.

const TEMAS := ["dia", "crepusculo"]
## [nome, casa, lanterna, direção da câmera (do alvo para a câmera), distância, fov]
const VISTAS := [
	["antes", "casa_a", "lanterna_pedra", Vector3(0, 21, 19), 15.5, 42.0],
	["jogo", "casa_piloto", "lanterna_piloto", Vector3(0, 21, 19), 15.5, 42.0],
	["frente", "casa_piloto", "lanterna_piloto", Vector3(0.55, 0.32, 1.0), 13.0, 40.0],
	["fundos", "casa_piloto", "lanterna_piloto", Vector3(-0.7, 0.45, -1.0), 13.0, 40.0],
]


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var saida: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(saida)
	root.size = Vector2i(960, 720)
	for tema in TEMAS:
		var cfg: Resource = load("res://config/temas/%s.tres" % tema)
		for v in VISTAS:
			var cena := Node3D.new()
			root.add_child(cena)
			_ambiente(cena, cfg)
			# As peças antigas só existem no tema de dia: mesma forma, luz do tema.
			var pasta: String = tema if (v[1] as String).ends_with("piloto") else "dia"
			_peca(cena, pasta, v[1], Vector3.ZERO)
			_peca(cena, pasta, v[2], Vector3(3.7, 0, 3.4))
			var cam := Camera3D.new()
			cam.fov = v[5]
			cena.add_child(cam)
			var alvo := Vector3(0.6, 2.0, 0.6)
			cam.position = alvo + (v[3] as Vector3).normalized() * float(v[4])
			cam.look_at(alvo)
			for k in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(saida.path_join("%s_%s.png" % [tema, v[0]]))
			cena.queue_free()
			await process_frame
	quit()


func _peca(cena: Node3D, pasta: String, nome: String, pos: Vector3) -> void:
	var no: Node3D = (load("res://assets/ninja/%s/%s.scn" % [pasta, nome]) as PackedScene).instantiate()
	no.position = pos
	cena.add_child(no)


## Mesmo céu/sol/neblina que Arena._build_environment monta a partir do tema.
func _ambiente(cena: Node3D, t: Resource) -> void:
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = t.sun_rotation_deg
	sol.light_color = t.sun_color
	sol.light_energy = t.sun_energy
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 40.0
	cena.add_child(sol)
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = t.sky_top
	ceu.sky_horizon_color = t.sky_horizon
	ceu.ground_horizon_color = t.ground_horizon
	ceu.ground_bottom_color = t.ground_bottom
	var sky := Sky.new()
	sky.sky_material = ceu
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = t.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = t.glow_intensity
	env.glow_bloom = 0.05
	env.adjustment_enabled = true
	env.adjustment_saturation = t.saturation
	env.adjustment_contrast = t.contrast
	env.fog_enabled = t.fog_enabled
	env.fog_light_color = t.fog_color
	env.fog_density = t.fog_density
	env.fog_sky_affect = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	chao.mesh = pm
	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	var grad := Gradient.new()
	grad.set_color(0, t.grass_dark)
	grad.set_color(1, t.grass_light)
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.color_ramp = grad
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(30, 30, 1)
	m.roughness = 1.0
	chao.material_override = m
	cena.add_child(chao)
	# Caminho de terra na frente da casa.
	var rua := MeshInstance3D.new()
	var rm := PlaneMesh.new()
	rm.size = Vector2(30, 3.2)
	rua.mesh = rm
	rua.position = Vector3(0, 0.01, 5.6)
	var mr := StandardMaterial3D.new()
	mr.albedo_color = t.road_dark.lerp(t.road_light, 0.5)
	mr.roughness = 1.0
	rua.material_override = mr
	cena.add_child(rua)
