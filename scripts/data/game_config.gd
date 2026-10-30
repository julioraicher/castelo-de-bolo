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
## Segundos ao lado da máscara caída para devolvê-la (parado se tiver inimigo
## a até princess_contest_radius m: dá tempo de um aliado do ladrão retomá-la).
@export var princess_rescue_time := 3.0
@export var princess_contest_radius := 4.0
## Dano que quem carrega a máscara inimiga leva (a máscara protege). Sem isso,
## o ladrão morria a ~15 m do pedestal, cercado por quem renasce ali.
@export var carrier_damage_mult := 0.5
## Arrancada ao pegar a máscara (velocidade x mult por time segundos).
@export var steal_boost_mult := 1.35
@export var steal_boost_time := 3.0
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
@export_group("Vida e tempo para matar")
## TTK = vida / (DPS · taxa de acerto). vida_mult multiplica a vida de todas as
## classes e, junto, curas e escudos (que são números absolutos), para eles
## valerem a mesma fração da vida. 1,0 = números dos .tres de classe.
@export var vida_mult := 1.4
## Dano dos poderes do Q (todos), para eles não ficarem fracos com a vida maior.
@export var dano_poder_mult := 1.2
## Fora de combate (sem bater nem apanhar) por regen_delay s, cura
## regen_rate da vida máxima por segundo. Briga perdida não "vaza" para a próxima.
@export var regen_delay := 4.0
@export var regen_rate := 0.06
@export var pickup_interval := 15.0
@export var max_pickups := 3
## Poção: fração da vida máxima curada.
@export var pickup_heal := 0.5
@export var pickup_shield := 40.0
@export var pickup_shield_time := 8.0
@export var pickup_speed_mult := 1.35
@export var pickup_speed_time := 6.0
## Dano dobrado: multiplicador e duração.
@export var pickup_damage_mult := 2.0
@export var pickup_damage_time := 6.0

@export_group("Oficinas")
## Segundos de obra de um Construtor com velocidade_obra = 1.
@export var oficina_build_time := 20.0
## Variações que o time pode escolher nas oficinas (o pedestal do pátio dá a variação A).
@export var oficina_classes: Array[ClassStats] = []

@export_group("Sensação do combate")
## Congelamento de atacante e alvo num golpe corpo a corpo (s).
@export var hitstop_time := 0.06
## Animação exagerada por código (estica e encolhe, quique, tremor, morte
## cômica): 0 = desliga, 1 = normal, 2 = desenho animado. Cada classe ainda
## multiplica pelo próprio ClassStats.exagero.
@export_range(0.0, 2.5, 0.05) var exagero_animacao := 1.4
## Antecipação do golpe (s): o corpo "carrega" antes do dano sair.
@export_range(0.0, 0.1, 0.005) var antecipacao_golpe := 0.05

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
## Mapa padrão (usado se `maps` estiver vazia).
@export var map: MapLayout
## Mapas disponíveis (Esc > Configurações > Mapa). O primeiro é o padrão.
@export var maps: Array[MapLayout] = []

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
