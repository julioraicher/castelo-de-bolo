extends SceneTree
## Prancha da casa comum + lanterna de pedra (piloto do Ciclo 2.2), nas luzes
## de dois temas (a luz vem do próprio .tres, como no jogo).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_piloto.gd -- DIR
## Salva DIR/<tema>_<vista>.png; a montagem com legendas é tools/montar_piloto.py.

const TEMAS := ["dia", "crepusculo"]
## [nome, casa, lanterna, direção da câmera (do alvo para a câmera), distância, fov]
const VISTAS := [
	["jogo", "casa_a", "lanterna_pedra", Vector3(0, 21, 19), 15.5, 42.0],
	["frente", "casa_a", "lanterna_pedra", Vector3(0.55, 0.32, 1.0), 13.0, 40.0],
	["fundos", "casa_a", "lanterna_pedra", Vector3(-0.7, 0.45, -1.0), 13.0, 40.0],
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
			var pasta: String = tema
			_peca(cena, pasta, v[1], Vector3.ZERO)
			_peca(cena, pasta, v[2], Vector3(3.7, 0, 3.4))
			_entorno(cena)
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
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/chao_pintado.gdshader")
	m.set_shader_parameter("grama_escura", t.grass_dark)
	m.set_shader_parameter("grama_clara", t.grass_light)
	m.set_shader_parameter("terra_escura", t.road_dark)
	m.set_shader_parameter("terra_clara", t.road_light)
	chao.material_override = m
	cena.add_child(chao)


## "Vazio": enfeite espalhado em volta (o espalhador MultiMesh da rodada 2 fará
## isso no mapa inteiro). Semente fixa; fora da casa, da lanterna e da estrada.
func _entorno(cena: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var tipos := {"capim.scn": 260, "flores.scn": 50, "flores_b.scn": 40, "pedrinhas.scn": 30, "broto.scn": 30, "folhas.scn": 25}
	for nome in tipos:
		var malha: Mesh = ((load("res://assets/ninja/dia/" + nome) as PackedScene).instantiate().get_node("Malha") as MeshInstance3D).mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malha
		var pts := []
		while pts.size() < tipos[nome]:
			var p := Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-12, 10))
			if absf(p.x) < 3.4 and absf(p.z) < 3.6:
				continue
			if p.distance_to(Vector3(3.7, 0, 3.4)) < 1.1 or absf(p.z - 5.6) < 1.9:
				continue
			# Mais denso encostado na casa (onde a vassoura não chega).
			if Vector2(p.x, p.z).length() > 7.0 and rng.randf() < 0.45:
				continue
			pts.append(p)
		mm.instance_count = pts.size()
		for k in pts.size():
			var e := rng.randf_range(0.7, 1.3)
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e, e, e)), pts[k]))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cena.add_child(mi)
	for a in [["arvore_grande.scn", Vector3(-8.5, 0, 3.0), 1.1], ["arvore_media.scn", Vector3(7.5, 0, -4.5), 1.0], ["cerca.scn", Vector3(-5.5, 0, 2.5), 1.0]]:
		var no: Node3D = (load("res://assets/ninja/dia/" + a[0]) as PackedScene).instantiate()
		no.position = a[1]
		no.scale = Vector3.ONE * float(a[2])
		cena.add_child(no)
