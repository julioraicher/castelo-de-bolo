class_name ThemeConfig
extends Resource
## Clima visual do jogo: luz, céu, neblina, cores do chão e quais modelos 3D
## formam os castelos e a paisagem. Um arquivo por tema em res://config/temas/.
## Para criar um tema: duplique um .tres, mude os campos e adicione em
## game_config.tres > Mundo > themes. Ele aparece em Esc > Configurações > Tema.

@export var display_name := "Medieval"

@export_group("Times")
@export var team_colors: Array[Color] = [Color(0.22, 0.45, 1.0), Color(1.0, 0.25, 0.25)]
## Substitui "{cor}" nos nomes de modelos (ex.: building_castle_{cor}.gltf).
@export var team_model_suffix: PackedStringArray = ["blue", "red"]

@export_group("Luz e céu")
@export var sun_rotation_deg := Vector3(-52, -35, 0)
@export var sun_color := Color(1.0, 0.95, 0.85)
@export var sun_energy := 1.1
@export var sky_top := Color(0.35, 0.6, 0.95)
@export var sky_horizon := Color(0.75, 0.88, 0.98)
@export var ground_horizon := Color(0.6, 0.75, 0.55)
@export var ground_bottom := Color(0.3, 0.45, 0.25)
@export var ambient_energy := 0.55
@export var saturation := 1.12
@export var contrast := 1.05
@export var glow_intensity := 0.4

@export_group("Neblina")
@export var fog_enabled := false
@export var fog_color := Color(0.5, 0.5, 0.6)
@export var fog_density := 0.01

@export_group("Chão")
@export var grass_dark := Color(0.27, 0.48, 0.2)
@export var grass_light := Color(0.4, 0.6, 0.25)
@export var road_dark := Color(0.62, 0.48, 0.3)
@export var road_light := Color(0.72, 0.58, 0.38)
## Mistura da cor do time no tapete da princesa com esta cor neutra.
@export var pedestal_neutral := Color(0.5, 0.45, 0.5)

@export_group("Modelos")
@export_dir var models_dir := "res://assets/medieval"
@export var keep_model := "building_castle_{cor}.gltf"
@export var keep_scale := 3.2
@export var tower_model := "building_tower_A_{cor}.gltf"
@export var tower_scale := 3.2
@export var flag_model := "flag_{cor}.gltf"
@export var flag_scale := 4.0
## Altura da bandeira em cima da torre.
@export var flag_height := 7.0
## Casa da oficina pronta ({cor} = time). Vazio = casinha simples feita por código.
## Nós "Telhado" (cai quando a obra acaba) e "Gira_*" (engrenagens) são opcionais.
@export var oficina_model := ""
@export var wall_model := "wall_straight.gltf"
@export var wall_scale := 3.0
## Comprimento de um módulo de muralha já escalado (2 m x escala 3).
@export var wall_module_length := 6.0
## Paisagem fora da arena (só decoração, sem colisão).
@export var border_trees: PackedStringArray = ["trees_A_large.gltf", "trees_B_large.gltf", "trees_A_medium.gltf", "hills_A_trees.gltf"]
@export var border_mountains: PackedStringArray = ["mountain_A_grass_trees.gltf", "mountain_B_grass_trees.gltf"]

@export_group("Detalhes do chão")
## Enfeites espalhados pelo campo, sem colisão nem sombra: {"capim.scn": 400}.
## Posição sorteada com semente fixa (o mapa é sempre igual), fora da estrada e
## dos castelos. Cada modelo vira um MultiMesh: 1 chamada de desenho por tipo.
@export var decor_campo: Dictionary = {}
## Enfeites sobre a estrada (lajotas, folhas caídas...).
@export var decor_estrada: Dictionary = {}
## Partículas no ar pelo mapa: "" (nenhuma), "petalas" ou "fantasmas".
@export var particulas := ""

@export_group("Modelos")
## Troca modelos dos objetos do mapa neste tema: {"trees_A_large.gltf": "rock_single_A.gltf"}.
@export var model_swaps: Dictionary = {}


func model_path(file: String, team := -1) -> String:
	var f: String = model_swaps.get(file, file)
	if team >= 0:
		f = f.replace("{cor}", team_model_suffix[team])
	return models_dir.path_join(f)
