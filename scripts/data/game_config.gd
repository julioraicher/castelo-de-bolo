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
## Alma de abate: cada inimigo eliminado manda esta fração de um espírito
## (fat_per_cake) direto para a máscara do time de quem matou. 0,15 ≈ 7 abates
## valem um espírito entregue. 0 desliga.
@export_range(0.0, 1.0) var alma_por_abate := 0.15
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
## Segundos de obra de um Construtor com velocidade_obra = 1 (com madeira).
@export var oficina_build_time := 10.0
## Madeira que uma casinha consome. O Construtor perto da obra puxa 1 do
## estoque do time a cada oficina_puxar_intervalo s (dividido pela velocidade_obra);
## a obra não passa da fração de madeira já entregue.
@export var oficina_custo_madeira := 6
@export var oficina_puxar_intervalo := 1.5
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

@export_group("Botão direito (Ciclo 2.4)")
## Contra-golpe: bloqueio erguido há no máximo parry_janela s quando o golpe
## de perto chega = anula o dano, atordoa quem bateu por parry_atordoa s e
## devolve um corte de parry_mult × o dano de quem bloqueou.
@export var parry_janela := 0.3
@export var parry_atordoa := 0.8
@export var parry_mult := 1.5
## Tiro carregado no máximo: atravessa até carga_perfura inimigos (a cada um
## perde 20% do dano); bomba carregada explode carga_raio_bomba × maior.
@export var carga_perfura := 2
@export var carga_raio_bomba := 1.5

@export_group("Chapéus")
## (Antigo, sem uso desde o Ciclo 2.3: as maquininhas têm estoque.)
@export var hat_respawn_time := 6.0
## Maquininha de chapéu: fabrica 1 a cada maquina_intervalo s até o estoque
## máximo e começa cheia. Fila: μ = 60/intervalo chapéus/min por máquina; com
## procura λ > μ o estoque S₀ acaba em S₀/(λ − μ) e alguém troca de classe.
@export var maquina_intervalo := 20.0
@export var maquina_estoque_max := 3
## Nível 2 da maquininha (Etapa 2: ainda sem uso no jogo).
@export var maquina_n2_custo := 8
@export var maquina_n2_intervalo := 12.0
@export var maquina_n2_estoque := 4

@export_group("Economia do Construtor")
## Só quem tem velocidade_obra > 0 (Construtor e variações) corta e carrega.
## Estágios: broto -> jovem -> adulta, um a cada tempo_estagio s.
@export var arvore_tempo_estagio := 40.0
@export var bambu_tempo_estagio := 15.0
## Toras que uma árvore adulta rende (1 por golpe; no último volta a broto).
## Jovem rende 1 e também volta a broto: cortar cedo é desperdício.
@export var arvore_toras := 3
@export var bambu_varas := 2
## Velocidade de quem carrega uma tora (e não ataca; o dash vale).
@export_range(0.1, 1.0) var tora_vel_mult := 0.7
## Tora largada no chão some depois de tanto tempo.
@export var tora_tempo_chao := 40.0
## Distância da pilha do castelo para entregar.
@export var pilha_raio := 2.6
## Velocidade extra da linha do Construtor por casinha pronta do time (0,05 = +5%).
@export var construtor_vel_por_oficina := 0.05
## Bots Construtores por time (no máximo).
@export var bots_construtores_max := 2

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
