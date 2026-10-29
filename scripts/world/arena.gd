class_name Arena
extends Node3D
## Monta o mapa por código: chão, luz, castelos, muralhas, obstáculos e a
## malha de navegação (o "mapa de caminhos" que os bots usam para andar).
##
## Sistema de coordenadas: o eixo X liga os dois castelos. O time Azul fica em
## X negativo e o Vermelho em X positivo. Cada castelo é descrito em
## coordenadas LOCAIS (lx, lz), em que +lx aponta para o inimigo; to_world()
## converte para o mundo. Assim os dois castelos são espelhos um do outro.

const CASTLE_DISTANCE := 48.0
const HALF_W := 68.0
const HALF_D := 36.0
const MED := "res://assets/medieval/"

## Posições úteis que o resto do jogo consulta.
var princess_spot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var hat_spots: Array = [[], []]          # [time] -> lista de Vector3
var spawn_center: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var gate_spot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]

var _nav: NavigationRegion3D


func build() -> void:
	_build_environment()
	_nav = NavigationRegion3D.new()
	_nav.name = "Navegacao"
	add_child(_nav)
	_build_ground()
	for team in [Config.TEAM_BLUE, Config.TEAM_RED]:
		_build_castle(team)
	_build_middle()
	_build_borders()
	_bake_navigation()


## Converte coordenadas locais do castelo de `team` para o mundo.
func to_world(team: int, lx: float, lz: float, y := 0.0) -> Vector3:
	var f := 1.0 if team == Config.TEAM_BLUE else -1.0
	return Vector3(-CASTLE_DISTANCE * f + lx * f, y, lz)


## Direção (no mundo) que aponta do castelo de `team` para o inimigo.
func forward(team: int) -> Vector3:
	return Vector3.RIGHT if team == Config.TEAM_BLUE else Vector3.LEFT


func random_spawn(team: int) -> Vector3:
	return to_world(team, randf_range(-1.0, 6.0), randf_range(-5.0, 5.0))


func random_cake_spot() -> Vector3:
	return Vector3(randf_range(-26.0, 26.0), 0.0, randf_range(-28.0, 28.0))


func clamp_to_arena(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -HALF_W + 2, HALF_W - 2), p.y, clampf(p.z, -HALF_D + 2, HALF_D - 2))


# --- Ambiente -----------------------------------------------------------------

var _sun: DirectionalLight3D
var _env: Environment


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	_sun = sun
	sun.name = "Sol"
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.6, 0.95)
	sky_mat.sky_horizon_color = Color(0.75, 0.88, 0.98)
	sky_mat.ground_horizon_color = Color(0.6, 0.75, 0.55)
	sky_mat.ground_bottom_color = Color(0.3, 0.45, 0.25)
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.05
	env.ssao_enabled = true          # ignorado no navegador (renderizador Compatibility)
	env.ssao_intensity = 1.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.05
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
	match Settings.quality:
		0:  # Baixa
			_sun.shadow_enabled = false
			_env.glow_enabled = false
		1:  # Média
			_sun.shadow_enabled = true
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			_sun.directional_shadow_max_distance = 55.0
			_env.glow_enabled = true
		_:  # Alta
			_sun.shadow_enabled = true
			_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			_sun.directional_shadow_max_distance = 80.0
			_env.glow_enabled = true


func _build_ground() -> void:
	# Corpo estático do chão (a navegação é gerada a partir dele).
	var body := StaticBody3D.new()
	body.name = "Chao"
	body.collision_layer = Config.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(HALF_W * 2 + 40, 1.0, HALF_D * 2 + 40)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	_nav.add_child(body)

	var grass := PlaneMesh.new()
	grass.size = Vector2(HALF_W * 2 + 120, HALF_D * 2 + 120)
	var mi := MeshInstance3D.new()
	mi.mesh = grass
	mi.material_override = _noise_material(Color(0.27, 0.48, 0.2), Color(0.4, 0.6, 0.25), 26.0)
	add_child(mi)

	# Estrada de terra ligando os dois portões.
	var road := PlaneMesh.new()
	road.size = Vector2(CASTLE_DISTANCE * 2 - 10, 7.0)
	var rmi := MeshInstance3D.new()
	rmi.mesh = road
	rmi.position.y = 0.02
	rmi.material_override = _noise_material(Color(0.62, 0.48, 0.3), Color(0.72, 0.58, 0.38), 8.0)
	add_child(rmi)


func _noise_material(dark: Color, light: Color, tiling: float) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	var grad := Gradient.new()
	grad.set_color(0, dark)
	grad.set_color(1, light)
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.color_ramp = grad
	tex.width = 256
	tex.height = 256
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(tiling, tiling, 1)
	mat.roughness = 1.0
	return mat


# --- Castelos -----------------------------------------------------------------

func _build_castle(team: int) -> void:
	var color := "blue" if team == Config.TEAM_BLUE else "red"
	var face := 0.0 if team == Config.TEAM_BLUE else PI

	# Torre principal (keep) atrás da princesa.
	_model("building_castle_%s.gltf" % color, to_world(team, -8.0, 0.0), 3.2, face - PI / 2)
	_box_collider(to_world(team, -8.0, 0.0, 3.0), Vector3(6.0, 6.0, 6.5))

	# Muralhas: fundo, laterais e frente com portão (vão em |lz| < 5).
	var back := -13.0
	var front := 11.0
	_wall(team, Vector2(back, -13), Vector2(back, 13))
	_wall(team, Vector2(back, -13), Vector2(front, -13))
	_wall(team, Vector2(back, 13), Vector2(front, 13))
	_wall(team, Vector2(front, -13), Vector2(front, -5))
	_wall(team, Vector2(front, 5), Vector2(front, 13))

	# Torres nos cantos e ao lado do portão, com bandeiras.
	for c in [Vector2(back, -13), Vector2(back, 13), Vector2(front, -13), Vector2(front, 13), Vector2(front, -5.5), Vector2(front, 5.5)]:
		var p := to_world(team, c.x, c.y)
		_model("building_tower_A_%s.gltf" % color, p, 3.2, face)
		_cylinder_collider(p, 1.8, 8.0)
		_model("flag_%s.gltf" % color, p + Vector3(0, 7.0, 0), 4.0, face)

	# Decoração do pátio.
	_model("barrel.gltf", to_world(team, -10.5, 10.5), 3.0, 0.3)
	_model("barrel.gltf", to_world(team, -9.5, 11.2), 3.0, 1.2)
	_model("crate_A_big.gltf", to_world(team, -10.8, -10.5), 3.0, 0.5)
	_model("tent.gltf", to_world(team, 7.5, -10.8), 3.5, face + PI / 2)

	# Pedestal da princesa: tapete na cor do time.
	princess_spot[team] = to_world(team, -1.0, 0.0)
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.7
	cyl.bottom_radius = 1.9
	cyl.height = 0.3
	ped.mesh = cyl
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Config.team_color(team).lerp(Color(0.5, 0.45, 0.5), 0.45)
	ped.material_override = pm
	ped.position = princess_spot[team] + Vector3(0, 0.15, 0)
	add_child(ped)

	hat_spots[team] = [to_world(team, 5.0, -8.5), to_world(team, 5.0, 8.5), to_world(team, -3.0, -8.5)]
	spawn_center[team] = to_world(team, 3.0, 0.0)
	gate_spot[team] = to_world(team, front + 3.0, 0.0)


func _wall(team: int, a: Vector2, b: Vector2) -> void:
	var wa := to_world(team, a.x, a.y)
	var wb := to_world(team, b.x, b.y)
	var dir := wb - wa
	var length := dir.length()
	var seg := 6.0  # comprimento de um módulo de muralha (2 m x escala 3)
	var count := int(ceil(length / seg))
	var angle := atan2(-dir.z, dir.x)
	for i in count:
		var t := (i + 0.5) / count
		var piece := _model("wall_straight.gltf", wa.lerp(wb, t), 3.0, angle)
		piece.scale.x = 3.0 * (length / count) / seg
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


# --- Meio do mapa e bordas ---------------------------------------------------

func _build_middle() -> void:
	for sx in [-1.0, 1.0]:
		var rp := Vector3(16.0 * sx, 0, 0)
		_model("rock_single_C.gltf", rp, 11.0, randf() * TAU)
		_cylinder_collider(rp, 1.7, 3.0)
		for sz in [-1.0, 1.0]:
			var tp := Vector3(26.0 * sx, 0, 19.0 * sz)
			_model("trees_A_large.gltf", tp, 3.4, randf() * TAU)
			_cylinder_collider(tp, 2.6, 4.0)
			var rp2 := Vector3(8.0 * sx, 0, 12.0 * sz)
			_model("rock_single_A.gltf", rp2, 9.0, randf() * TAU)
			_cylinder_collider(rp2, 1.2, 2.0)
	for sz in [-1.0, 1.0]:
		var cp := Vector3(0, 0, 24.0 * sz)
		_model("trees_B_large.gltf", cp, 3.6, randf() * TAU)
		_cylinder_collider(cp, 2.8, 4.0)


func _build_borders() -> void:
	# Paredes invisíveis nos limites.
	for side in [[Vector3(0, 2, -HALF_D - 1), Vector3(HALF_W * 2 + 4, 4, 2)],
			[Vector3(0, 2, HALF_D + 1), Vector3(HALF_W * 2 + 4, 4, 2)],
			[Vector3(-HALF_W - 1, 2, 0), Vector3(2, 4, HALF_D * 2 + 4)],
			[Vector3(HALF_W + 1, 2, 0), Vector3(2, 4, HALF_D * 2 + 4)]]:
		_box_collider(side[0], side[1])
	# Floresta e montanhas em volta, só decoração.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var deco := ["trees_A_large.gltf", "trees_B_large.gltf", "trees_A_medium.gltf", "hills_A_trees.gltf"]
	var x := -HALF_W - 6.0
	while x <= HALF_W + 6.0:
		for zs in [-1.0, 1.0]:
			var p := Vector3(x + rng.randf_range(-2, 2), 0, zs * (HALF_D + rng.randf_range(4, 9)))
			_model(deco[rng.randi() % deco.size()], p, rng.randf_range(3.0, 4.5), rng.randf() * TAU)
		x += 7.0
	var z := -HALF_D - 6.0
	while z <= HALF_D + 6.0:
		for xs in [-1.0, 1.0]:
			var p := Vector3(xs * (HALF_W + rng.randf_range(5, 10)), 0, z + rng.randf_range(-2, 2))
			var m := "mountain_A_grass_trees.gltf" if rng.randf() < 0.5 else "mountain_B_grass_trees.gltf"
			_model(m, p, rng.randf_range(4.0, 6.0), rng.randf() * TAU)
		z += 9.0


# --- Utilitários --------------------------------------------------------------

func _model(file: String, pos: Vector3, scale_factor: float, rot_y := 0.0) -> Node3D:
	var scene: PackedScene = load(MED + file)
	var node: Node3D = scene.instantiate()
	node.position = pos
	node.scale = Vector3.ONE * scale_factor
	node.rotation.y = rot_y
	add_child(node)
	return node


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
	nm.filter_baking_aabb = AABB(Vector3(-HALF_W, -1, -HALF_D), Vector3(HALF_W * 2, 6, HALF_D * 2))
	_nav.navigation_mesh = nm
	_nav.bake_navigation_mesh(false)
