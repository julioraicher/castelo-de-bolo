extends SceneTree
## Prancha de peças do cenário: monta cada peça por código, numera e salva um print.
## Uso (precisa de janela; aqui via xvfb):
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --resolution 1600x900 \
##     --rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_cenario.gd -- --out=prancha.png

const NIGHT := Color(0.05, 0.06, 0.14)
const WOOD := Color(0.30, 0.17, 0.14)
const WOOD_DARK := Color(0.18, 0.10, 0.10)
const PLASTER := Color(0.78, 0.74, 0.70)
const ROOF := Color(0.24, 0.30, 0.46)
const STONE := Color(0.42, 0.44, 0.50)
const CYAN := Color(0.2, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.2, 0.75)
const GHOST := Color(0.35, 1.0, 0.45)
const TEAM := Color(0.25, 0.5, 1.0)

var _tris := 0
var _out := "prancha.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
	var root3d := Node3D.new()
	root.add_child(root3d)
	_environment(root3d)

	var pieces := [
		["Templo (castelo)", _temple],
		["Torre de vigia", _watchtower],
		["Muralha", _wall],
		["Portão torii", _torii],
		["Casa (meio)", _house],
		["Lanterna de papel", _paper_lantern],
		["Lanterna de pedra", _stone_lantern],
		["Letreiro neon", _neon_sign],
		["Pedestal da Máscara", _pedestal],
		["Pinheiro", _pine],
	]
	var report := []
	for i in pieces.size():
		var holder := Node3D.new()
		var col := i % 5
		var row := i / 5
		holder.position = Vector3((col - 2) * 9.5, 0, (row - 0.5) * 11.0)
		root3d.add_child(holder)
		_tris = 0
		pieces[i][1].call(holder)
		var lbl := Label3D.new()
		lbl.text = "%d  %s" % [i + 1, pieces[i][0]]
		lbl.font_size = 64
		lbl.outline_size = 18
		lbl.pixel_size = 0.012
		lbl.width = 1000
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, 0.2, 4.2)
		holder.add_child(lbl)
		report.append("%d %s: %d tris" % [i + 1, pieces[i][0], _tris])
	print("\n".join(report))

	# Câmera com o mesmo ângulo do jogo (offset 0,21,19; FOV 42), só mais longe.
	var cam := Camera3D.new()
	cam.fov = 42
	root3d.add_child(cam)
	cam.look_at_from_position(Vector3(0, 21, 19) * 1.6 + Vector3(0, 0, 1), Vector3(0, 0, 1))
	_shoot.call_deferred()


func _shoot() -> void:
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png(_out)
	print("salvo: ", _out)
	quit()


# --- Ambiente: noite azul-marinho, glow para o neon --------------------------

func _environment(parent: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = NIGHT
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.7)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.8, 0.85, 1.0)
	moon.light_energy = 1.2
	moon.rotation_degrees = Vector3(-50, 140, 0)
	moon.shadow_enabled = true
	parent.add_child(moon)
	# Chão: pedra escura de rua.
	var ground := _box(parent, Vector3(120, 0.2, 80), Vector3(0, -0.1, 0), Color(0.12, 0.13, 0.2))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# --- Peças --------------------------------------------------------------------

## 1. Templo de três andares no lugar do castelo. Faixas na cor do time.
func _temple(p: Node3D) -> void:
	_box(p, Vector3(7, 0.8, 7), Vector3(0, 0.4, 0), STONE)
	var sizes := [5.6, 4.2, 3.0]
	var y := 0.8
	for i in 3:
		var s: float = sizes[i]
		_box(p, Vector3(s, 1.6, s), Vector3(0, y + 0.8, 0), PLASTER if i == 0 else WOOD)
		_box(p, Vector3(s + 0.06, 0.25, s + 0.06), Vector3(0, y + 1.45, 0), TEAM)
		_roof(p, s + 1.8, 1.6, y + 1.6)
		y += 2.5
	_cyl(p, 0.08, 0.08, 1.4, Vector3(0, y + 0.3, 0), Color(0.9, 0.75, 0.3), 6)
	_glow_box(p, Vector3(1.2, 0.9, 0.1), Vector3(0, 1.8, 2.82), Color(1.0, 0.7, 0.3), 2.5)


## 2. Torre de vigia de madeira com lanterna no topo.
func _watchtower(p: Node3D) -> void:
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_box(p, Vector3(0.35, 6, 0.35), Vector3(x, 3, z), WOOD_DARK)
	_box(p, Vector3(2.8, 0.3, 2.8), Vector3(0, 5.6, 0), WOOD)
	_box(p, Vector3(2.8, 0.9, 0.15), Vector3(0, 6.2, 1.35), TEAM)
	_roof(p, 3.6, 1.5, 6.8)
	_paper(p, Vector3(0, 6.1, 0), 0.45, Color(1.0, 0.35, 0.2))


## 3. Módulo de muralha: base de pedra, parede de reboco e telhadinho.
func _wall(p: Node3D) -> void:
	_box(p, Vector3(6, 1.0, 1.4), Vector3(0, 0.5, 0), STONE)
	_box(p, Vector3(6, 1.6, 1.0), Vector3(0, 1.8, 0), PLASTER)
	_box(p, Vector3(6, 0.2, 1.02), Vector3(0, 2.4, 0), TEAM)
	_roof(p, 6.6, 0.9, 2.5, 1.8)


## 4. Portão torii com faixa de neon ciano.
func _torii(p: Node3D) -> void:
	for x in [-2.0, 2.0]:
		_cyl(p, 0.3, 0.35, 5, Vector3(x, 2.5, 0), Color(0.75, 0.12, 0.1), 8)
	_box(p, Vector3(6.2, 0.45, 0.6), Vector3(0, 5.1, 0), Color(0.75, 0.12, 0.1))
	_box(p, Vector3(6.8, 0.3, 0.7), Vector3(0, 5.5, 0), WOOD_DARK)
	_box(p, Vector3(4.6, 0.3, 0.35), Vector3(0, 4.2, 0), Color(0.75, 0.12, 0.1))
	_glow_box(p, Vector3(4.4, 0.1, 0.1), Vector3(0, 4.0, 0.25), CYAN, 3.0)


## 5. Casa de rua (machiya) para o meio do mapa: janela acesa e placa neon.
func _house(p: Node3D) -> void:
	_box(p, Vector3(5, 2.4, 3.6), Vector3(0, 1.2, 0), WOOD)
	_box(p, Vector3(5.02, 0.9, 3.62), Vector3(0, 0.45, 0), WOOD_DARK)
	_roof(p, 6.0, 1.4, 2.4, 4.6)
	_glow_box(p, Vector3(1.4, 0.8, 0.05), Vector3(-1.2, 1.4, 1.82), Color(1.0, 0.75, 0.4), 2.0)
	_glow_box(p, Vector3(0.6, 1.6, 0.08), Vector3(2.0, 2.0, 1.9), MAGENTA, 3.0)


## 6. Lanterna de papel pendurada num poste.
func _paper_lantern(p: Node3D) -> void:
	_box(p, Vector3(0.2, 3.4, 0.2), Vector3(0, 1.7, 0), WOOD_DARK)
	_box(p, Vector3(1.3, 0.15, 0.15), Vector3(0.55, 3.3, 0), WOOD_DARK)
	_paper(p, Vector3(1.0, 2.7, 0), 0.5, Color(1.0, 0.3, 0.2))


## 7. Lanterna de pedra (tōrō) com luz verde-fantasma.
func _stone_lantern(p: Node3D) -> void:
	_cyl(p, 0.7, 0.8, 0.3, Vector3(0, 0.15, 0), STONE, 6)
	_cyl(p, 0.2, 0.25, 1.2, Vector3(0, 0.9, 0), STONE, 6)
	_cyl(p, 0.55, 0.45, 0.25, Vector3(0, 1.6, 0), STONE, 6)
	_glow_box(p, Vector3(0.6, 0.55, 0.6), Vector3(0, 2.0, 0), GHOST, 3.0)
	_cyl(p, 0.0, 0.9, 0.6, Vector3(0, 2.55, 0), STONE, 6)


## 8. Letreiro vertical de neon (placa escura com moldura brilhante).
func _neon_sign(p: Node3D) -> void:
	_box(p, Vector3(0.25, 4.2, 0.25), Vector3(-0.8, 2.1, 0), WOOD_DARK)
	_box(p, Vector3(1.3, 3.0, 0.2), Vector3(0, 2.8, 0), Color(0.08, 0.06, 0.12))
	_glow_box(p, Vector3(1.4, 0.1, 0.1), Vector3(0, 4.3, 0.12), MAGENTA, 3.0)
	_glow_box(p, Vector3(1.4, 0.1, 0.1), Vector3(0, 1.3, 0.12), MAGENTA, 3.0)
	for i in 3:
		_glow_box(p, Vector3(0.6, 0.45, 0.06), Vector3(0, 1.9 + i * 0.85, 0.12), CYAN, 3.0)


## 9. Pedestal da Máscara Oni: degraus de pedra, anel de fogo-fantasma, máscara.
func _pedestal(p: Node3D) -> void:
	_cyl(p, 2.4, 2.6, 0.3, Vector3(0, 0.15, 0), STONE, 8)
	_cyl(p, 1.7, 1.9, 0.3, Vector3(0, 0.45, 0), Color(0.3, 0.3, 0.38), 8)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.85
	tm.outer_radius = 2.05
	tm.rings = 16
	tm.ring_segments = 4
	ring.mesh = tm
	ring.position = Vector3(0, 0.62, 0)
	ring.material_override = _glow_mat(GHOST, 2.5)
	p.add_child(ring)
	_count(tm)
	# Máscara: rosto vermelho, chifres e olhos brilhando (marcador; o modelo
	# final vem da frente de personagens).
	var face := _sphere(p, 0.8, Vector3(0, 1.6, 0), Color(0.8, 0.1, 0.12))
	face.scale = Vector3(1, 1.15, 0.55)
	for x in [-0.45, 0.45]:
		var horn := _cyl(p, 0.0, 0.18, 0.7, Vector3(x, 2.5, 0), Color(0.95, 0.9, 0.8), 6)
		horn.rotation_degrees.z = -x * 40
		_glow_box(p, Vector3(0.25, 0.12, 0.05), Vector3(x * 0.7, 1.75, 0.45), Color(1, 0.9, 0.3), 3.0)


## 10. Pinheiro escuro (3 cones), para bordas e pátios.
func _pine(p: Node3D) -> void:
	_cyl(p, 0.2, 0.3, 1.2, Vector3(0, 0.6, 0), WOOD_DARK, 6)
	for i in 3:
		_cyl(p, 0.0, 1.8 - i * 0.45, 1.6, Vector3(0, 1.8 + i * 1.0, 0), Color(0.08, 0.22, 0.2), 7)


# --- Primitivas ---------------------------------------------------------------

## Telhado de quatro águas: cumeeira no sentido do comprimento, quatro panos
## inclinados e um beiral escuro na borda (6 triângulos + caixa do beiral).
func _roof(p: Node3D, width: float, height: float, y: float, depth := -1.0) -> MeshInstance3D:
	var d := width if depth < 0.0 else depth
	var hx := width / 2.0
	var hz := d / 2.0
	var ridge := maxf(hx - hz, 0.08 * width)
	var c0 := Vector3(-hx, 0, -hz)
	var c1 := Vector3(hx, 0, -hz)
	var c2 := Vector3(hx, 0, hz)
	var c3 := Vector3(-hx, 0, hz)
	var r1 := Vector3(-ridge, height, 0)
	var r2 := Vector3(ridge, height, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[c3, r2, c2], [c3, r1, r2], [c1, r1, c0], [c1, r2, r1], [c2, r2, c1], [c0, r1, c3]]:
		var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
		if n.y < 0.0:
			n = -n
		for v in tri:
			st.set_normal(n)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = Vector3(0, y, 0)
	mi.material_override = _mat(ROOF)
	p.add_child(mi)
	_tris += 6
	_box(p, Vector3(ridge * 2.0 + 0.3, 0.22, 0.22), Vector3(0, y + height, 0), WOOD_DARK)
	_box(p, Vector3(width, 0.18, d), Vector3(0, y + 0.02, 0), WOOD_DARK)
	return mi


func _paper(p: Node3D, pos: Vector3, r: float, c: Color) -> void:
	var s := _sphere(p, r, pos, c)
	s.scale = Vector3(1, 1.3, 1)
	s.material_override = _glow_mat(c, 2.2)


func _box(p: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _add(p, bm, pos, _mat(c))


func _glow_box(p: Node3D, size: Vector3, pos: Vector3, c: Color, energy: float) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := _add(p, bm, pos, _glow_mat(c, energy))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _cyl(p: Node3D, top: float, bottom: float, h: float, pos: Vector3, c: Color, seg := 8) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	return _add(p, cm, pos, _mat(c))


func _sphere(p: Node3D, r: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = 10
	sm.rings = 6
	return _add(p, sm, pos, _mat(c))


func _add(p: Node3D, mesh: PrimitiveMesh, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = m
	p.add_child(mi)
	_count(mesh)
	return mi


func _count(mesh: Mesh) -> void:
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		_tris += idx.size() / 3 if idx.size() > 0 else verts.size() / 3


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
