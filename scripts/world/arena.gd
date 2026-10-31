class_name Arena
extends Node3D
## Monta o mapa por código: chão, luz, castelos, muralhas, obstáculos e a
## malha de navegação (o "mapa de caminhos" que os bots usam para andar).
##
## O QUE construir vem de dois arquivos de dados:
##   - MapLayout (config/mapas/*.tres): tamanhos, posições, objetos.
##   - ThemeConfig (config/temas/*.tres): luz, cores e quais modelos usar.
## Este script só sabe COMO montar. Mudar o visual ou o mapa = editar os .tres.
##
## Sistema de coordenadas: o eixo X liga os dois castelos. O time Azul fica em
## X negativo e o Vermelho em X positivo. Cada castelo é descrito em
## coordenadas LOCAIS (lx, lz), em que +lx aponta para o inimigo; to_world()
## converte para o mundo. Assim os dois castelos são espelhos um do outro.

var map: MapLayout
var theme: ThemeConfig

## Posições úteis que o resto do jogo consulta.
var princess_spot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var hat_spots: Array = [[], []]          # [time] -> lista de Vector3
var oficina_spots: Array = [[], []]      # [time] -> lista de Vector3
var mago_spots: Array = [[], []]         # [time] -> [cima, baixo] (Vector3)
var tree_spots: Array = [[], []]         # [time] -> lista de Vector3 (bosque seguro)
var bamboo_spots: Array = [[], []]       # [time] -> bambus do lado desse castelo (mundo)
var pilha_spot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var spawn_center: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var gate_spot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]

var _nav: NavigationRegion3D


func build() -> void:
	map = Config.map()
	theme = Config.theme()
	_build_environment()
	_nav = NavigationRegion3D.new()
	_nav.name = "Navegacao"
	add_child(_nav)
	_build_ground()
	for team in [Config.TEAM_BLUE, Config.TEAM_RED]:
		_build_castle(team)
	_build_middle()
	_build_borders()
	_build_decor()
	_build_particles()
	_bake_navigation()
	_batch_static_meshes()
	_registrar_contornos.call_deferred()


## Acha os contornos de tinta que sobraram fora dos pedaços juntados (MultiMesh,
## peças animadas) e aplica a qualidade atual neles e no enfeite.
func _registrar_contornos() -> void:
	registrar_contornos(self)


## O mesmo para um modelo criado fora da Arena ou depois dela (maquininha,
## planta que cresce, tora, pilha): sem isso o contorno fica ligado em toda
## qualidade. Os materiais do .scn são compartilhados, então basta uma vez.
func registrar_contornos(raiz: Node) -> void:
	for n in raiz.find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh = null
		if n is MeshInstance3D:
			mesh = n.mesh
		elif n is MultiMeshInstance3D and n.multimesh:
			mesh = n.multimesh.mesh
		if mesh:
			for s in mesh.get_surface_count():
				_mesclavel(mesh.surface_get_material(s))
	_apply_quality()


## Converte coordenadas locais do castelo de `team` para o mundo.
func to_world(team: int, lx: float, lz: float, y := 0.0) -> Vector3:
	var f := 1.0 if team == Config.TEAM_BLUE else -1.0
	return Vector3(-map.castle_distance * f + lx * f, y, lz)


## Direção (no mundo) que aponta do castelo de `team` para o inimigo.
func forward(team: int) -> Vector3:
	return Vector3.RIGHT if team == Config.TEAM_BLUE else Vector3.LEFT


func random_spawn(team: int) -> Vector3:
	return to_world(team, randf_range(map.spawn_min.x, map.spawn_max.x), randf_range(map.spawn_min.y, map.spawn_max.y))


## Ponto livre no chão do meio do mapa (espíritos e itens). Evita telhados,
## colinas e água: só aceita pontos no nível do chão, sem nada em cima.
func random_cake_spot() -> Vector3:
	var p := Vector3.ZERO
	for i in 16:
		p = Vector3(randf_range(-map.cake_area.x, map.cake_area.x), 0.0, randf_range(-map.cake_area.y, map.cake_area.y))
		if ground_y(p.x, p.z) < 0.3:
			return p
	return p


## Altura do chão (ou do que estiver em cima dele) em (x, z), procurando de
## `from_y` para baixo. Mapas com muralhas, pontes e colinas não são planos.
func ground_y(x: float, z: float, from_y := 30.0) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, -5.0, z), Config.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if not hit.is_empty() else 0.0


func clamp_to_arena(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -map.half_width + 2, map.half_width - 2), p.y, clampf(p.z, -map.half_depth + 2, map.half_depth - 2))


# --- Ambiente -----------------------------------------------------------------

var _sun: DirectionalLight3D
var _static_models: Array[Node3D] = []
var _env: Environment


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	_sun = sun
	sun.name = "Sol"
	sun.rotation_degrees = theme.sun_rotation_deg
	sun.light_color = theme.sun_color
	sun.light_energy = theme.sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = theme.sky_top
	sky_mat.sky_horizon_color = theme.sky_horizon
	sky_mat.ground_horizon_color = theme.ground_horizon
	sky_mat.ground_bottom_color = theme.ground_bottom
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = theme.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = theme.glow_intensity
	env.glow_bloom = 0.05
	env.ssao_enabled = true          # ignorado no navegador (renderizador Compatibility)
	env.ssao_intensity = 1.2
	env.adjustment_enabled = true
	env.adjustment_saturation = theme.saturation
	env.adjustment_contrast = theme.contrast
	env.fog_enabled = theme.fog_enabled
	env.fog_light_color = theme.fog_color
	env.fog_density = theme.fog_density
	env.fog_sky_affect = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_env = env
	_apply_quality()
	Settings.changed.connect(_apply_quality)


## Qualidade gráfica (Esc > Configurações). O que mais pesa no navegador são
## as sombras: com 4 divisões (PSSM) cada objeto é desenhado até 4 vezes a
## mais no mapa de sombra.
func _apply_quality() -> void:
	if _particles:
		_particles.visible = Settings.quality >= 2
	# Contorno de tinta do cenário só na Alta: ele redesenha cada construção
	# (dobra triângulos e chamadas de desenho). Enfeite: 100% / 60% / 35%.
	for mat: ShaderMaterial in _contornos:
		mat.next_pass = _contornos[mat] if Settings.quality >= 3 else null
	var fracao := 1.0 if Settings.quality >= 3 else (0.6 if Settings.quality == 2 else 0.35)
	for mm in _enfeites:
		mm.visible_instance_count = int(mm.instance_count * fracao)
	match Settings.quality:
		0, 1:  # Mínima, Baixa (a diferença está na resolução 3D, em Settings)
			_sun.shadow_enabled = false
			_env.glow_enabled = false
		2:  # Média
			_sun.shadow_enabled = true
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			_sun.directional_shadow_max_distance = 55.0
			_env.glow_enabled = false  # brilho custa vários passes de desfoque em tela cheia
		_:  # Alta
			_sun.shadow_enabled = true
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			_sun.directional_shadow_max_distance = 80.0
			_env.glow_enabled = theme.glow_intensity > 0.0


func _build_ground() -> void:
	# Corpo estático do chão (a navegação é gerada a partir dele).
	var body := StaticBody3D.new()
	body.name = "Chao"
	body.collision_layer = Config.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(map.half_width * 2 + 40, 1.0, map.half_depth * 2 + 40)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	_nav.add_child(body)

	var grass := PlaneMesh.new()
	grass.size = Vector2(map.half_width * 2 + 120, map.half_depth * 2 + 120)
	var mi := MeshInstance3D.new()
	mi.mesh = grass
	# Chão pintado: grama em manchas e a estrada de terra ligando os dois portões
	# (borda irregular desenhada no próprio shader).
	var chao := ShaderMaterial.new()
	chao.shader = preload("res://assets/shaders/chao_pintado.gdshader")
	chao.set_shader_parameter("grama_escura", theme.grass_dark)
	chao.set_shader_parameter("grama_clara", theme.grass_light)
	chao.set_shader_parameter("terra_escura", theme.road_dark)
	chao.set_shader_parameter("terra_clara", theme.road_light)
	chao.set_shader_parameter("rua_z", 0.0)
	chao.set_shader_parameter("rua_meia", map.road_width / 2.0)
	chao.set_shader_parameter("rua_x_max", map.castle_distance - 5.0)
	chao.set_shader_parameter("trilha_z", map.trail_z)
	chao.set_shader_parameter("trilha_meia", map.trail_width / 2.0 if map.trail_z > 0.0 else 0.0)
	chao.set_shader_parameter("trilha_x_max", map.trail_x_max)
	mi.material_override = chao
	add_child(mi)


# --- Castelos -----------------------------------------------------------------

func _build_castle(team: int) -> void:
	var face := 0.0 if team == Config.TEAM_BLUE else PI
	var m := map

	# Torre principal (keep) atrás da princesa.
	var kp := m.keep_position
	_model_path(theme.model_path(theme.keep_model, team), to_world(team, kp.x, kp.y), theme.keep_scale, face - PI / 2)
	_box_collider(to_world(team, kp.x, kp.y, m.keep_collider_size.y / 2.0), m.keep_collider_size)

	# Muralhas: fundo, laterais e frente com portão (vão em |lz| < gate_half_width).
	var back := m.wall_back
	var front := m.wall_front
	var w := m.wall_half_width
	_wall(team, Vector2(back, -w), Vector2(back, w))
	_wall(team, Vector2(back, -w), Vector2(front, -w))
	_wall(team, Vector2(back, w), Vector2(front, w))
	_wall(team, Vector2(front, -w), Vector2(front, -m.gate_half_width))
	_wall(team, Vector2(front, m.gate_half_width), Vector2(front, w))

	# Torres com bandeiras.
	for c in m.tower_spots:
		var p := to_world(team, c.x, c.y)
		_model_path(theme.model_path(m.tower_model if m.tower_model != "" else theme.tower_model, team), p, theme.tower_scale, face)
		_cylinder_collider(p, m.tower_collider_radius, 8.0)
		var fh := m.flag_height if m.flag_height >= 0.0 else theme.flag_height
		_model_path(theme.model_path(theme.flag_model, team), p + Vector3(0, fh, 0), theme.flag_scale, face)

	# Objetos do pátio (barris, caixas, tenda...).
	for prop in m.courtyard_props:
		for lp in prop.positions():
			_place_prop(prop, to_world(team, lp.x, lp.z), face)

	# Pedestal da princesa: tapete na cor do time.
	princess_spot[team] = to_world(team, m.princess_spot.x, m.princess_spot.y)
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = m.pedestal_radius
	cyl.bottom_radius = m.pedestal_radius + 0.2
	cyl.height = 0.3
	ped.mesh = cyl
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Config.team_color(team).lerp(theme.pedestal_neutral, 0.45)
	ped.material_override = pm
	ped.position = princess_spot[team] + Vector3(0, 0.15, 0)
	add_child(ped)

	var spots := []
	for hs in m.hat_spots:
		spots.append(to_world(team, hs.x, hs.y))
	hat_spots[team] = spots
	var ofs := []
	for os in m.oficina_spots:
		ofs.append(to_world(team, os.x, os.y))
	oficina_spots[team] = ofs
	var mgs := []
	for ms in m.mago_spots:
		mgs.append(to_world(team, ms.x, ms.y))
	mago_spots[team] = mgs
	var arv := []
	for p in m.tree_spots:
		arv.append(to_world(team, p.x, p.y))
	tree_spots[team] = arv
	# Bambu está no mundo: cada castelo fica com os do seu lado do rio.
	var bam := []
	for p in m.bamboo_spots:
		if (p.x < 0.0) == (team == Config.TEAM_BLUE):
			bam.append(Vector3(p.x, 0, p.y))
	bamboo_spots[team] = bam
	pilha_spot[team] = to_world(team, m.pilha_spot.x, m.pilha_spot.y)
	spawn_center[team] = to_world(team, (m.spawn_min.x + m.spawn_max.x) / 2.0, 0.0)
	gate_spot[team] = to_world(team, front + m.gate_guard_distance, 0.0)


func _wall(team: int, a: Vector2, b: Vector2) -> void:
	var wa := to_world(team, a.x, a.y)
	var wb := to_world(team, b.x, b.y)
	var dir := wb - wa
	var length := dir.length()
	var seg := theme.wall_module_length
	var count := int(ceil(length / seg))
	var angle := atan2(-dir.z, dir.x)
	for i in count:
		var t := (i + 0.5) / count
		var piece := _model_path(theme.model_path(map.wall_model if map.wall_model != "" else theme.wall_model), wa.lerp(wb, t), theme.wall_scale, angle)
		piece.scale.x = theme.wall_scale * (length / count) / seg
	if map.wall_height > 0.0:
		_wall_walk(team, wa, wb, angle, length)
		return
	var mid := (wa + wb) / 2.0 + Vector3(0, 2.0, 0)
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length + 2.0, 4.0, 2.2)
	shape.shape = box
	body.add_child(shape)
	body.position = mid
	body.rotation.y = angle
	_nav.add_child(body)


## Muralha com passarela: bloco maciço até `wall_height` (dá para andar em
## cima) e uma mureta do lado de fora. O modelo tem a mureta no +z local; se o
## lado de fora for o -z, ele é girado meia volta.
func _wall_walk(team: int, wa: Vector3, wb: Vector3, angle: float, length: float) -> void:
	var mid := (wa + wb) / 2.0
	var centro := to_world(team, (map.wall_back + map.wall_front) / 2.0, 0.0)
	var local_z := Vector3(sin(angle), 0, cos(angle))
	var fora := 1.0 if local_z.dot(mid - centro) > 0.0 else -1.0
	var pieces := _static_models.slice(_static_models.size() - int(ceil(length / theme.wall_module_length)))
	if fora < 0.0:
		for piece: Node3D in pieces:
			piece.rotation.y += PI
	var t := map.wall_thickness
	var blocos := [
		[Vector3(length + t, map.wall_height, t), mid + Vector3(0, map.wall_height / 2.0, 0)],
		[Vector3(length + t, map.wall_parapet, 0.4), mid + local_z * fora * (t / 2.0 - 0.2) + Vector3(0, map.wall_height + map.wall_parapet / 2.0, 0)],
	]
	for bl in blocos:
		var body := StaticBody3D.new()
		body.collision_layer = Config.LAYER_WORLD
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = bl[0]
		shape.shape = box
		body.add_child(shape)
		body.position = bl[1]
		body.rotation.y = angle
		_nav.add_child(body)


# --- Meio do mapa e bordas ---------------------------------------------------

func _build_middle() -> void:
	for prop in map.middle_props:
		for p in prop.positions():
			_place_prop(prop, p, 0.0)


func _place_prop(prop: MapProp, pos: Vector3, face: float) -> void:
	var rot := randf() * TAU if prop.rotation_deg < 0.0 else face + deg_to_rad(prop.rotation_deg)
	if prop.model != "":
		_model_path(theme.model_path(prop.model), pos, prop.scale, rot)
	if prop.collider == "cilindro":
		_cylinder_collider(pos, prop.collider_radius, prop.collider_height)
	elif prop.collider == "caixa":
		var b := Basis(Vector3.UP, rot)
		var body := StaticBody3D.new()
		body.collision_layer = Config.LAYER_WORLD
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = prop.collider_size
		shape.shape = box
		body.add_child(shape)
		body.transform = Transform3D(b * Basis.from_euler(prop.collider_rot * PI / 180.0), pos + b * prop.collider_offset)
		_nav.add_child(body)


func _build_borders() -> void:
	var hw := map.half_width
	var hd := map.half_depth
	# Paredes invisíveis nos limites.
	for side in [[Vector3(0, 2, -hd - 1), Vector3(hw * 2 + 4, 4, 2)],
			[Vector3(0, 2, hd + 1), Vector3(hw * 2 + 4, 4, 2)],
			[Vector3(-hw - 1, 2, 0), Vector3(2, 4, hd * 2 + 4)],
			[Vector3(hw + 1, 2, 0), Vector3(2, 4, hd * 2 + 4)]]:
		_box_collider(side[0], side[1])
	# Floresta e montanhas em volta, só decoração (semente fixa: sempre igual).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var trees := theme.border_trees
	var x := -hw - 6.0
	while x <= hw + 6.0 and not trees.is_empty():
		for zs in [-1.0, 1.0]:
			var p := Vector3(x + rng.randf_range(-2, 2), 0, zs * (hd + rng.randf_range(4, 9)))
			_model_path(theme.model_path(trees[rng.randi() % trees.size()]), p, rng.randf_range(3.0, 4.5), rng.randf() * TAU)
		x += map.border_spacing
	var mountains := theme.border_mountains
	var z := -hd - 6.0
	while z <= hd + 6.0 and not mountains.is_empty():
		for xs in [-1.0, 1.0]:
			var p := Vector3(xs * (hw + rng.randf_range(5, 10)), 0, z + rng.randf_range(-2, 2))
			_model_path(theme.model_path(mountains[rng.randi() % mountains.size()]), p, rng.randf_range(4.0, 6.0), rng.randf() * TAU)
		z += map.border_spacing * 9.0 / 7.0


## Modelos feitos por código (cor por vértice, 2 materiais: fosco e brilho)
## viram poucas malhas grandes, uma por pedaço do mapa (para a câmera ainda
## poder descartar o que está fora da tela). Com isso o número de chamadas de
## desenho não cresce com a quantidade nem com a variedade de peças: cada
## pedaço custa 2 chamadas, tenha 10 ou 100 casas.
const CHUNK := 34.0


## Material que dá para juntar num pedaço só: cor por vértice (StandardMaterial)
## ou o material pintado do cenário (pintura.gdshader). Guarda o contorno de
## tinta (next_pass) para ligar/desligar pela qualidade.
func _mesclavel(mat: Material) -> bool:
	if mat is StandardMaterial3D:
		return (mat as StandardMaterial3D).vertex_color_use_as_albedo
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader == PINTURA:
		if mat.next_pass and not _contornos.has(mat):
			_contornos[mat] = mat.next_pass
		return true
	return false


## Cada .scn salva a própria cópia do material: junta as cópias iguais numa só
## (uma superfície por tipo de material em cada pedaço, não uma por modelo).
var _unicos := {}


func _material_unico(mat: Material) -> Material:
	var k := ""
	if mat is ShaderMaterial:
		k = "pintura%s%s" % [mat.next_pass != null, (mat as ShaderMaterial).get_shader_parameter("cor_sombra")]
	else:
		k = "padrao%d" % (mat as StandardMaterial3D).shading_mode
	if not _unicos.has(k):
		_unicos[k] = mat
	return _unicos[k]


func _merge_vertex_color_models() -> void:
	var chunks := {}  # Vector2i -> {Material: SurfaceTool}
	var giram: Array[MeshInstance3D] = []  # engrenagens, rodas d'água (ver pintura.gdshader)
	for root in _static_models:
		var mis := root.find_children("*", "MeshInstance3D", true, false)
		if mis.is_empty() or root.find_children("*", "AnimationPlayer", true, false).size() > 0:
			continue
		var ok := true
		for mi: MeshInstance3D in mis:
			if mi.mesh == null or mi.material_override != null or mi.skin != null:
				ok = false
				break
			for s in mi.mesh.get_surface_count():
				if not _mesclavel(mi.mesh.surface_get_material(s)):
					ok = false
		if not ok:
			continue
		var key := Vector2i(floori(root.global_position.x / CHUNK), floori(root.global_position.z / CHUNK))
		if not chunks.has(key):
			chunks[key] = {}
		for mi: MeshInstance3D in mis:
			if mi.name.begins_with("Gira_"):
				# Peça que gira no shader em volta da própria origem: fica de fora.
				var xf := mi.global_transform
				mi.get_parent().remove_child(mi)
				add_child(mi)
				mi.global_transform = xf
				giram.append(mi)
				continue
			for s in mi.mesh.get_surface_count():
				var mat := _material_unico(mi.mesh.surface_get_material(s))
				if not chunks[key].has(mat):
					var st := SurfaceTool.new()
					st.begin(Mesh.PRIMITIVE_TRIANGLES)
					chunks[key][mat] = st
				chunks[key][mat].append_from(mi.mesh, s, mi.global_transform)
		root.queue_free()
	for key in chunks:
		var mesh := ArrayMesh.new()
		for mat: Material in chunks[key]:
			chunks[key][mat].commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
		var mi := MeshInstance3D.new()
		mi.name = "Cenario_%d_%d" % [key.x, key.y]
		mi.mesh = mesh
		add_child(mi)
	# Peças iguais que giram: um MultiMesh por malha (uma chamada de desenho).
	var por_malha := {}
	for mi in giram:
		if not por_malha.has(mi.mesh):
			por_malha[mi.mesh] = []
		por_malha[mi.mesh].append(mi)
	for mesh: Mesh in por_malha:
		var lista: Array = por_malha[mesh]
		if lista.size() < 2:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, lista[i].global_transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
		for mi: MeshInstance3D in lista:
			mi.queue_free()


# --- Detalhes do chão e partículas ------------------------------------------

var _particles: CPUParticles3D
var _enfeites: Array[MultiMesh] = []
const PINTURA := preload("res://assets/shaders/pintura.gdshader")
var _contornos := {}  # material pintado -> contorno (next_pass), só na Alta


## Espalha os enfeites do tema (capim, pedrinhas, folhas, lajotas...). Sem
## colisão e sem sombra; um MultiMesh por modelo. Semente fixa: o mapa sai
## igual em toda partida.
func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var hw := map.half_width
	var hd := map.half_depth
	var cd := map.castle_distance
	var road := map.road_width / 2.0
	var blockers := []  # [Vector3, raio] dos objetos do meio, para não nascer capim dentro de pedra
	for prop in map.middle_props:
		for p in prop.positions():
			blockers.append([p, maxf(prop.collider_radius, 1.0) + 0.5])
	var by_model := {}  # caminho -> Array[Transform3D]
	for zi in 2:
		var zona: Dictionary = theme.decor_estrada if zi == 1 else theme.decor_campo
		var on_road := zi == 1
		for model: String in zona:
			var list: Array = by_model.get(model, [])
			var n: int = zona[model]
			var tries := 0
			while n > 0 and tries < 20000:
				tries += 1
				var p: Vector3
				if on_road:
					p = Vector3(rng.randf_range(-cd + 12, cd - 12), 0, rng.randf_range(-road + 0.4, road - 0.4))
				else:
					p = Vector3(rng.randf_range(-hw + 1, hw - 1), 0, rng.randf_range(-hd + 1, hd - 1))
					if absf(p.z) < road + 0.8 and absf(p.x) < cd - 8:
						continue
					if absf(p.x) > cd - map.wall_front - 1.5 and absf(p.x) < cd - map.wall_back + 1.5 and absf(p.z) < map.wall_half_width + 1.5:
						continue
					var hit := false
					for b in blockers:
						if Vector2(p.x - b[0].x, p.z - b[0].z).length() < b[1]:
							hit = true
							break
					if hit:
						continue
				if ground_y(p.x, p.z) > 0.3:  # rio, ponte, telhado, colina
					continue
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.75, 1.3))
				list.append(Transform3D(basis, p))
				n -= 1
			by_model[model] = list
	for model: String in by_model:
		var scene: PackedScene = load(theme.models_dir.path_join(model))
		var inst := scene.instantiate()
		var src: MeshInstance3D = inst if inst is MeshInstance3D else inst.find_children("*", "MeshInstance3D", true, false)[0]
		var xs: Array = by_model[model]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = src.mesh
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i] * src.transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Enfeite_" + model.get_basename()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_enfeites.append(mm)
		inst.free()


## Pétalas caindo (Templo ao Luar) ou fogo-fantasma subindo (Floresta Oni).
func _build_particles() -> void:
	if theme.particulas == "":
		return
	var p := CPUParticles3D.new()
	p.name = "ParticulasDoAr"
	p.amount = 220
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(map.half_width, 3.0, map.half_depth)
	p.position.y = 4.0
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = mat
	p.mesh = quad
	p.direction = Vector3(1, 0, 0.3)
	p.spread = 30.0
	if theme.particulas == "petalas":
		quad.size = Vector2(0.16, 0.11)
		p.gravity = Vector3(0, -0.35, 0)
		p.initial_velocity_min = 0.4
		p.initial_velocity_max = 1.0
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -90.0
		p.angular_velocity_max = 90.0
		p.color = Color(1.0, 0.78, 0.88, 0.95)
	else:
		quad.size = Vector2(0.14, 0.14)
		p.gravity = Vector3(0, 0.12, 0)
		p.initial_velocity_min = 0.1
		p.initial_velocity_max = 0.4
		var g := Gradient.new()
		g.set_color(0, Color(0.4, 1.6, 0.9, 0.0))
		g.add_point(0.2, Color(0.4, 1.6, 0.9, 1.0))
		g.add_point(0.8, Color(0.8, 0.5, 1.8, 0.9))
		g.set_color(g.get_point_count() - 1, Color(0.8, 0.5, 1.8, 0.0))
		p.color_ramp = g
	add_child(p)
	_particles = p
	_particles.visible = Settings.quality >= 2


# --- Utilitários --------------------------------------------------------------

func _model_path(path: String, pos: Vector3, scale_factor: float, rot_y := 0.0) -> Node3D:
	var scene: PackedScene = load(path)
	var node: Node3D = scene.instantiate()
	node.position = pos
	node.scale = Vector3.ONE * scale_factor
	node.rotation.y = rot_y
	add_child(node)
	_static_models.append(node)
	return node


## Junta cópias da mesma malha (árvores, pedras, muros...) num MultiMesh:
## uma chamada de desenho por tipo de malha em vez de uma por cópia. No
## navegador (WebGL) é o custo de cada chamada que mais pesa, não o número
## de triângulos.
func _batch_static_meshes() -> void:
	_merge_vertex_color_models()
	var groups := {}  # Mesh -> Array[MeshInstance3D]
	for root in _static_models:
		if not is_instance_valid(root) or root.is_queued_for_deletion():
			continue
		if root.find_children("*", "AnimationPlayer", true, false).size() > 0:
			continue
		for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh == null or mi.skin != null or mi.material_override != null:
				continue
			if not groups.has(mi.mesh):
				groups[mi.mesh] = []
			groups[mi.mesh].append(mi)
	for mesh: Mesh in groups:
		var list: Array = groups[mesh]
		if list.size() < 2:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i].global_transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
		for mi: MeshInstance3D in list:
			mi.queue_free()


func _box_collider(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	_nav.add_child(body)


func _cylinder_collider(base: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	body.add_child(shape)
	body.position = base + Vector3(0, height / 2.0, 0)
	_nav.add_child(body)


func _bake_navigation() -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = Config.LAYER_WORLD
	nm.agent_radius = 1.0
	nm.agent_height = 2.25
	nm.agent_max_climb = 0.5
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.filter_baking_aabb = AABB(Vector3(-map.half_width - 2, -1, -map.half_depth - 2), Vector3(map.half_width * 2 + 4, 14, map.half_depth * 2 + 4))
	_nav.navigation_mesh = nm
	_nav.bake_navigation_mesh(false)
