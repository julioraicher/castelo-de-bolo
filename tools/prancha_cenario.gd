extends SceneTree
## Prancha de propostas de cenário (só para pitaco; nada disso entra no jogo).
## Monta o mesmo pedaço de mapa (canto do castelo, caminho, portal torii,
## ponte sobre um canal e borda de árvores) em 3 climas e salva, por clima:
##   DIR/cen_N_jogo.png  câmera do jogo (mesma altura e fov)
##   DIR/cen_N_baixo.png câmera baixa, para ver o clima
## Uso (xvfb no servidor):
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_cenario.gd -- DIR

const AZUL := Color(0.16, 0.45, 1.0)
const VERMELHO := Color(1.0, 0.16, 0.1)

## Cada clima é só uma paleta + quais enfeites aparecem.
var climas := [
	{
		"nome": "A Vila Neon",
		"ceu": Color(0.02, 0.02, 0.07), "horizonte": Color(0.25, 0.06, 0.3),
		"amb": Color(0.5, 0.45, 0.75), "amb_e": 0.45,
		"lua": Color(0.75, 0.8, 1.0), "lua_e": 0.55, "contra": Color(1.0, 0.25, 0.85), "contra_e": 0.5,
		"nevoa": Color(0.18, 0.05, 0.25), "nevoa_d": 0.012,
		"chao": Color(0.07, 0.07, 0.11), "caminho": Color(0.16, 0.16, 0.22), "agua": Color(0.1, 0.35, 0.6),
		"parede": Color(0.85, 0.82, 0.78), "telhado": Color(0.12, 0.12, 0.18), "madeira": Color(0.25, 0.12, 0.1),
		"torii": Color(1.0, 0.15, 0.45), "torii_neon": true,
		"lanterna": Color(1.0, 0.35, 0.2), "neon": [Color(1.0, 0.2, 0.85), Color(0.2, 0.95, 1.0)],
		"arvore": "sakura", "folha": Color(1.0, 0.45, 0.8), "placas": true, "oni": false,
	},
	{
		"nome": "B Templo ao Luar",
		"ceu": Color(0.04, 0.07, 0.18), "horizonte": Color(0.2, 0.3, 0.5),
		"amb": Color(0.55, 0.65, 0.9), "amb_e": 0.6,
		"lua": Color(0.8, 0.88, 1.0), "lua_e": 1.0, "contra": Color(1.0, 0.6, 0.35), "contra_e": 0.25,
		"nevoa": Color(0.15, 0.2, 0.35), "nevoa_d": 0.008,
		"chao": Color(0.16, 0.24, 0.2), "caminho": Color(0.36, 0.36, 0.4), "agua": Color(0.15, 0.3, 0.55),
		"parede": Color(0.92, 0.9, 0.85), "telhado": Color(0.18, 0.22, 0.3), "madeira": Color(0.35, 0.2, 0.12),
		"torii": Color(0.85, 0.18, 0.1), "torii_neon": false,
		"lanterna": Color(1.0, 0.65, 0.25), "neon": [Color(1.0, 0.7, 0.3), Color(1.0, 0.55, 0.2)],
		"arvore": "sakura", "folha": Color(1.0, 0.7, 0.82), "placas": false, "oni": false,
	},
	{
		"nome": "C Floresta Oni",
		"ceu": Color(0.03, 0.01, 0.05), "horizonte": Color(0.12, 0.04, 0.16),
		"amb": Color(0.45, 0.35, 0.6), "amb_e": 0.4,
		"lua": Color(0.55, 1.0, 0.75), "lua_e": 0.45, "contra": Color(0.6, 0.2, 1.0), "contra_e": 0.45,
		"nevoa": Color(0.2, 0.08, 0.28), "nevoa_d": 0.022,
		"chao": Color(0.07, 0.06, 0.08), "caminho": Color(0.15, 0.12, 0.16), "agua": Color(0.25, 0.7, 0.45),
		"parede": Color(0.4, 0.38, 0.42), "telhado": Color(0.08, 0.06, 0.1), "madeira": Color(0.15, 0.1, 0.1),
		"torii": Color(0.3, 0.05, 0.1), "torii_neon": false,
		"lanterna": Color(0.3, 1.0, 0.6), "neon": [Color(0.35, 1.0, 0.55), Color(0.65, 0.3, 1.0)],
		"arvore": "bambu", "folha": Color(0.1, 0.3, 0.2), "placas": false, "oni": true,
	},
]

var dir := "user://prancha_cenario"
var cena: Node3D
var cam: Camera3D
var _mats := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	_rodar()


func _rodar() -> void:
	root.size = Vector2i(1600, 900)
	for i in climas.size():
		cena = Node3D.new()
		root.add_child(cena)
		_mats.clear()
		var p: Dictionary = climas[i]
		_ambiente(p)
		_mapa(p)
		_bonecos()
		cam = Camera3D.new()
		cena.add_child(cam)
		await _quadros(6)
		cam.fov = 42
		cam.position = Vector3(-8, 21, 17)
		cam.look_at(Vector3(-8, 1, -2))
		await _salvar("cen_%d_jogo.png" % i)
		cam.fov = 50
		cam.position = Vector3(5, 3.0, 6.5)
		cam.look_at(Vector3(-12, 4.0, -5))
		await _salvar("cen_%d_baixo.png" % i)
		cena.queue_free()
		await _quadros(2)
	quit()


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _salvar(nome: String) -> void:
	await _quadros(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(nome))
	print("salvo ", dir.path_join(nome))


func _ambiente(p: Dictionary) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = p.ceu
	sm.sky_horizon_color = p.horizonte
	sm.ground_horizon_color = p.horizonte
	sm.ground_bottom_color = p.ceu
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = p.amb
	env.ambient_light_energy = p.amb_e
	env.fog_enabled = true
	env.fog_light_color = p.nevoa
	env.fog_density = p.nevoa_d
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.04
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	cena.add_child(we)
	var lua := DirectionalLight3D.new()
	lua.light_color = p.lua
	lua.light_energy = p.lua_e
	lua.rotation_degrees = Vector3(-55, 25, 0)
	lua.shadow_enabled = true
	cena.add_child(lua)
	var contra := DirectionalLight3D.new()
	contra.light_color = p.contra
	contra.light_energy = p.contra_e
	contra.rotation_degrees = Vector3(-20, 200, 0)
	cena.add_child(contra)
	# Lua grande no fundo.
	_obj(_esf(5.0), Vector3(30, 26, -70), _brilho(p.lua * 1.4))


func _mapa(p: Dictionary) -> void:
	# Chão escuro + caminho de lajotas + canal com ponte.
	_obj(_caixa(Vector3(90, 0.2, 60)), Vector3(0, -0.1, 0), _cor(p.chao))
	for x in range(-16, 22, 2):
		for z in [-1.0, 1.0]:
			var j := 0.15 * sin(x * 3.1 + z)
			_obj(_caixa(Vector3(1.85, 0.08, 1.85)), Vector3(x + j, 0.04, z + j), _cor(p.caminho.lightened(0.06 * fmod(abs(x * 7.0 + z), 3.0))))
	_obj(_caixa(Vector3(3.2, 0.1, 60)), Vector3(7, 0.0, 0), _brilho(p.agua * 0.9, 0.85))
	_ponte(p, Vector3(7, 0, 0))
	_castelo(p, Vector3(-17, 0, -7))
	_torii(p, Vector3(-4, 0, 0))
	# Lanternas de pedra (toro) nos lados do caminho, e varal de lanternas de papel.
	for x in [-9.0, -1.0, 12.0]:
		for z in [-2.6, 2.6]:
			_toro(p, Vector3(x, 0, z))
	_varal(p, Vector3(-12, 0, 3.5), Vector3(2, 0, 3.5))
	# Muro de madeira do castelo + placas de neon (só na vila).
	for z in range(-14, -3, 2):
		_obj(_caixa(Vector3(0.5, 2.2, 2.0)), Vector3(-9.5, 1.1, z), _cor(p.madeira))
		_obj(_caixa(Vector3(0.7, 0.2, 2.1)), Vector3(-9.5, 2.3, z), _cor(p.telhado))
	if p.placas:
		_placa(p.neon[0], Vector3(-9.1, 2.6, -7), 0.0)
		_placa(p.neon[1], Vector3(1.5, 0, -6), 1.0)
		_placa(p.neon[0], Vector3(14, 0, -5), 1.0)
		_casinha(p, Vector3(2.5, 0, -9))
		_casinha(p, Vector3(15, 0, -9))
	if p.oni:
		_estatua_oni(p, Vector3(-1, 0, -4))
		_estatua_oni(p, Vector3(-1, 0, 4))
		for i in 7:
			_obj(_esf(0.25), Vector3(-10 + i * 4.0, 1.4 + 0.5 * sin(i * 2.0), -4.5 + 9.0 * fmod(i * 0.37, 1.0)), _brilho(p.neon[i % 2] * 2.0))
	# Borda de árvores (sakura ou bambu) atrás e na frente.
	for i in 26:
		var x := -26.0 + i * 2.2 + sin(i * 1.7) * 0.8
		_arvore(p, Vector3(x, 0, -15.5 + sin(i * 2.3) * 1.5))
		if i % 2 == 0 and x > -8:
			_arvore(p, Vector3(x + 1.0, 0, 10.5 + cos(i * 1.3) * 1.2))
	# Montanhas em silhueta.
	for i in 6:
		var m := _cone(14.0 + 4.0 * (i % 3), 16.0 + 6.0 * (i % 2), 5)
		_obj(m, Vector3(-45 + i * 18, 0, -48 - (i % 2) * 8), _cor(p.ceu.lightened(0.08)))


## Castelo japonês (tenshu): base de pedra inclinada, 3 andares com telhados
## que se abrem para fora e beiral na cor do time.
func _castelo(p: Dictionary, at: Vector3) -> void:
	_obj(_cone(7.5, 6.5, 4, 3.0), at + Vector3(0, 1.5, 0), _cor(Color(0.28, 0.27, 0.3)), 45)
	var larg := 7.5
	var y := 3.0
	for andar in 3:
		var h := 2.4 - andar * 0.3
		_obj(_caixa(Vector3(larg, h, larg * 0.85)), at + Vector3(0, y + h / 2, 0), _cor(p.parede))
		for s in [-1, 1]:
			_obj(_caixa(Vector3(0.25, h, 0.1)), at + Vector3(larg * 0.25 * s, y + h / 2, larg * 0.43), _cor(p.madeira))
		_obj(_cone(0.1, larg * 0.85, 4, 1.6), at + Vector3(0, y + h + 0.8, 0), _cor(p.telhado), 45)
		_obj(_caixa(Vector3(larg * 1.18, 0.12, larg * 1.05)), at + Vector3(0, y + h + 0.05, 0), _brilho(AZUL * 1.3))
		y += h + 1.2
		larg *= 0.72
	_obj(_cone(0.0, 0.25, 4, 1.0), at + Vector3(0, y + 0.3, 0), _brilho(Color(1.0, 0.8, 0.3) * 1.5))


func _torii(p: Dictionary, at: Vector3) -> void:
	var m: Material = _brilho(p.torii * 1.6) if p.torii_neon else _cor(p.torii)
	for z in [-2.4, 2.4]:
		_obj(_cil(0.22, 0.25, 5.0), at + Vector3(0, 2.5, z), m)
	_obj(_caixa(Vector3(0.5, 0.35, 6.6)), at + Vector3(0, 5.1, 0), m)
	_obj(_caixa(Vector3(0.6, 0.25, 7.4)), at + Vector3(0, 5.45, 0), _cor(p.telhado))
	_obj(_caixa(Vector3(0.3, 0.25, 5.4)), at + Vector3(0, 4.2, 0), m)
	if p.oni:  # portal quebrado, torto
		cena.get_child(cena.get_child_count() - 3).rotation_degrees.x = 8


func _toro(p: Dictionary, at: Vector3) -> void:
	var pedra := _cor(Color(0.35, 0.34, 0.38))
	_obj(_cil(0.35, 0.45, 0.3), at + Vector3(0, 0.15, 0), pedra)
	_obj(_cil(0.15, 0.15, 0.7), at + Vector3(0, 0.65, 0), pedra)
	_obj(_caixa(Vector3(0.55, 0.45, 0.55)), at + Vector3(0, 1.2, 0), _brilho(p.lanterna * 1.8))
	_obj(_cone(0.05, 0.6, 4, 0.35), at + Vector3(0, 1.6, 0), pedra, 45)


func _varal(p: Dictionary, a: Vector3, b: Vector3) -> void:
	var n := 8
	for i in n:
		var t := (i + 0.5) / n
		var pos := a.lerp(b, t) + Vector3(0, 3.6 - sin(t * PI) * 0.6, 0)
		var lan := _obj(_esf(0.28), pos, _brilho(p.lanterna * 1.6))
		lan.scale = Vector3(1, 1.35, 1)
	for e in [a, b]:
		_obj(_cil(0.1, 0.1, 3.8), e + Vector3(0, 1.9, 0), _cor(p.madeira))


func _placa(c: Color, at: Vector3, poste: float) -> void:
	if poste > 0:
		_obj(_cil(0.1, 0.1, 3.5), at + Vector3(0, 1.75, 0), _cor(Color(0.1, 0.1, 0.12)))
		at.y = 3.4
	_obj(_caixa(Vector3(0.15, 2.2, 0.8)), at, _cor(Color(0.05, 0.05, 0.08)))
	for k in 3:
		_obj(_caixa(Vector3(0.18, 0.12, 0.5 - 0.1 * (k % 2))), at + Vector3(0.02, 0.6 - k * 0.55, 0), _brilho(c * 2.2))
	_obj(_caixa(Vector3(0.2, 2.3, 0.06)), at + Vector3(0, 0, 0.42), _brilho(c * 1.6))


func _casinha(p: Dictionary, at: Vector3) -> void:
	_obj(_caixa(Vector3(4.0, 2.4, 3.0)), at + Vector3(0, 1.2, 0), _cor(p.madeira.lightened(0.15)))
	_obj(_caixa(Vector3(2.6, 1.2, 0.05)), at + Vector3(0, 1.1, 1.52), _brilho(Color(1.0, 0.8, 0.55) * 1.2))
	_obj(_cone(0.2, 3.4, 4, 1.4), at + Vector3(0, 3.1, 0), _cor(p.telhado), 45)
	_obj(_caixa(Vector3(3.0, 0.1, 0.1)), at + Vector3(0, 2.45, 1.6), _brilho(p.neon[1] * 2.0))


func _estatua_oni(p: Dictionary, at: Vector3) -> void:
	var pedra := _cor(Color(0.3, 0.28, 0.33))
	_obj(_caixa(Vector3(1.2, 0.6, 1.2)), at + Vector3(0, 0.3, 0), pedra)
	_obj(_esf(0.65), at + Vector3(0, 1.3, 0), pedra)
	for s in [-1, 1]:
		_obj(_cone(0.0, 0.15, 6, 0.6), at + Vector3(0.35 * s, 2.0, 0), _cor(Color(0.85, 0.8, 0.7)))
		_obj(_esf(0.1), at + Vector3(0.22 * s, 1.4, 0.55), _brilho(p.neon[0] * 2.5))


func _ponte(p: Dictionary, at: Vector3) -> void:
	for i in 7:
		var t := (i - 3) / 3.0
		_obj(_caixa(Vector3(0.75, 0.15, 3.2)), at + Vector3(t * 2.4, 0.6 * (1.0 - t * t) + 0.1, 0), _cor(p.torii.darkened(0.2)))
	for z in [-1.6, 1.6]:
		_obj(_caixa(Vector3(5.0, 0.12, 0.12)), at + Vector3(0, 1.3, z), _cor(p.torii))


func _arvore(p: Dictionary, at: Vector3) -> void:
	if p.arvore == "bambu":
		for k in 4:
			var o := Vector3(sin(k * 2.4) * 0.6, 0, cos(k * 2.4) * 0.6)
			var h := 6.0 + k * 1.2
			var b := _obj(_cil(0.1, 0.12, h), at + o + Vector3(0, h / 2, 0), _cor(Color(0.2, 0.42, 0.25)))
			b.rotation_degrees.z = sin(k * 1.9 + at.x) * 6
		_obj(_esf(1.4), at + Vector3(0, 6.5, 0), _cor(p.folha))
		return
	_obj(_cil(0.18, 0.28, 2.4), at + Vector3(0, 1.2, 0), _cor(Color(0.22, 0.12, 0.12)))
	for k in 3:
		var o := Vector3(sin(k * 2.1) * 0.8, 2.6 + (k % 2) * 0.5, cos(k * 2.1) * 0.8)
		var f := _obj(_esf(1.1 - 0.15 * k), at + o, _cor(p.folha))
		f.scale = Vector3(1, 0.75, 1)


func _bonecos() -> void:
	var cls := ["guerreiro", "arqueiro", "kitsune", "ronin_oni"]
	var pos := [Vector3(-6, 0, 1), Vector3(-2, 0, -1.5), Vector3(1.5, 0, 1.2), Vector3(4, 0, -0.8)]
	for i in cls.size():
		var c: Resource = load("res://config/classes/%s.tres" % cls[i])
		var n: Node3D = c.model.instantiate()
		cena.add_child(n)
		var corpo: Array[MeshInstance3D] = []
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			mi.visible = mi.name in c.visible_meshes
			if mi.visible:
				corpo.append(mi)
		NinjaVisual.aplicar(n, corpo, c.estilo_ninja, AZUL if i < 2 else VERMELHO, c.escala_cabeca, true)
		n.scale = Vector3.ONE * c.escala_modelo
		n.position = pos[i]
		n.rotation.y = PI / 2 if i < 2 else -PI / 2
		var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
		ap.play(c.anim_attack)
		ap.seek(0.25, true)
		ap.pause()


# --- formas e materiais -------------------------------------------------------

func _obj(mesh: Mesh, pos: Vector3, mat: Material, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees.y = rot_y
	cena.add_child(mi)
	return mi


func _cor(c: Color) -> Material:
	var k := "c" + c.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		_mats[k] = m
	return _mats[k]


func _brilho(c: Color, alfa := 1.0) -> Material:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, alfa)
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _caixa(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


func _esf(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 10
	s.rings = 6
	return s


func _cil(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 8
	return c


func _cone(top: float, bottom: float, lados: int, h := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h if h > 0 else bottom * 1.1
	c.radial_segments = lados
	return c
