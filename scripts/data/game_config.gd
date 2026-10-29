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

@export_group("Poder (medidor de Glacê, 0 a 100)")
## Fontes do medidor: dG/dt = a·(dano causado) + b·(dano sofrido) + eventos − G/τ.
@export var power_per_damage := 0.3
@export var power_per_damage_taken := 0.15
@export var power_per_kill := 15.0
@export var power_per_cake := 25.0
@export var power_per_capture := 40.0
## Depois de tantos segundos sem lutar, o medidor (se não estiver cheio) vaza
## com constante de tempo τ: G(t) = G0·e^(−t/τ).
@export var power_leak_delay := 10.0
@export var power_leak_tau := 60.0
## Fração do medidor mantida ao morrer.
@export_range(0.0, 1.0) var power_keep_on_death := 0.5

@export_group("Itens no chão")
## Um item novo a cada tantos segundos, até o máximo, na área do meio.
@export var pickup_interval := 15.0
@export var max_pickups := 3
## Poção: fração da vida máxima curada.
@export var pickup_heal := 0.5
@export var pickup_shield := 40.0
@export var pickup_shield_time := 8.0
@export var pickup_speed_mult := 1.35
@export var pickup_speed_time := 6.0

@export_group("Sensação do combate")
## Congelamento de atacante e alvo num golpe corpo a corpo (s).
@export var hitstop_time := 0.06

@export_group("Chapéus")
@export var hat_respawn_time := 6.0

@export_group("Classes")
## Classe de quem nasce/renasce sem chapéu.
@export var villager: ClassStats
## Chapéus do pátio, na ordem de MapLayout.hat_spots. Classe nova: copie um
## .tres de config/classes/, mude os campos e adicione nesta lista.
@export var hat_class_list: Array[ClassStats] = []
## Classes com que os bots começam a partida (em ciclo).
@export var bot_start_classes: Array[ClassStats] = []

@export_group("Mundo")
## Temas disponíveis (Esc > Configurações > Tema). O primeiro é o padrão.
@export var themes: Array[ThemeConfig] = []
@export var map: MapLayout

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
	return hat_class_list
