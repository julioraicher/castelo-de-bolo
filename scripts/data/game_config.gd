class_name GameConfig
extends Resource
## Regras gerais da partida. Edite res://config/game_config.tres no Inspector.

@export_group("Partida")
@export var units_per_team := 8
@export var score_to_win := 3
@export var respawn_time := 6.0

@export_group("Princesa e bolo")
## Quanto cada bolo engorda a princesa (0 = magra, 1 = gordíssima).
@export_range(0.0, 1.0) var fat_per_cake := 0.1
## Fração da velocidade perdida pelo carregador quando a princesa está no peso máximo.
@export_range(0.0, 0.95) var fat_slowdown := 0.45
## Segundos até a princesa largada no chão voltar sozinha para casa.
@export var princess_return_time := 15.0
@export var cake_spawn_interval := 5.0
@export var max_cakes := 6

@export_group("Chapéus")
@export var hat_respawn_time := 6.0

@export_group("Classes")
@export var villager: ClassStats
@export var warrior: ClassStats
@export var archer: ClassStats
@export var cleric: ClassStats

@export_group("Câmera")
@export var camera_offset := Vector3(0, 21, 19)
@export var camera_fov := 42.0
@export var camera_smooth := 7.0
## Quanto a câmera se adianta na direção do mouse.
@export var camera_lead := 4.0

@export_group("Bots")
## Atraso de reação dos bots (s). Maior = mais fácil.
@export var bot_think_interval := 0.25
@export var bot_aggro_radius := 13.0


func hat_classes() -> Array[ClassStats]:
	return [warrior, archer, cleric]
