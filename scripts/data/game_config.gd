class_name GameConfig
extends Resource
## Regras gerais da partida. Edite res://config/game_config.tres no Inspector.

@export_group("Partida")
@export var units_per_team := 8
@export var score_to_win := 3
@export var respawn_time := 7.0
## Morrer custa mais caro conforme a partida avança: o renascer ganha
## +respawn_cresce s por minuto de jogo, até respawn_max. No fim travado
## (tudo upado), quedas abrem janelas para o time unido roubar a máscara.
## No modo teste não cresce (lá a espera só atrapalha).
@export var respawn_cresce := 0.75
@export var respawn_max := 13.0
## Ciclo 2.23: relógio regressivo no topo da tela (s; 0 = sem relógio). No
## zero, vence quem tem mais pontos de máscara; igual = empate. Ciclo 2.24
## (Julio): 15 min, e se alguma máscara está fora do castelo no zero (na mão de
## alguém ou caída no chão) a partida segue em PRORROGAÇÃO até ela ser entregue
## ou voltar. Na mão, no máximo prorrogacao_max s; caída, espera ela voltar
## sozinha (princess_return_time). Modo teste não tem relógio.
@export var tempo_limite := 900.0
@export var prorrogacao_max := 60.0
## Ciclo 2.25 (Julio: "muito empate"): relógio (e prorrogação) acabando
## empatado abre a MORTE SÚBITA: as duas máscaras ficam leves (peso 0, e as
## almas param de pesar), o primeiro ponto vence. Passados estes segundos sem
## ponto (mais a espera de uma máscara fora, como na prorrogação), vence o time
## com mais pontos no placar do Tab. 0 = sem morte súbita (empate direto).
@export var morte_subita_tempo := 120.0

@export_group("Princesa e bolo")
## Quanto cada bolo engorda a princesa (0 = magra, 1 = gordíssima).
@export_range(0.0, 1.0) var fat_per_cake := 0.1
## Fração da velocidade perdida pelo carregador quando a princesa está no peso máximo.
## Ciclo 2.25: 0,45 → 0,38 (os espíritos entregues ainda enchem a máscara até 1).
@export_range(0.0, 0.95) var fat_slowdown := 0.38
## Peso com que a máscara nasce (2.27c, Julio: "tomei 3 pontos logo no começo").
## 0,3 = três espíritos já presos: o primeiro roubo anda ~11% mais devagar.
## Some na morte súbita (zerar_peso) como qualquer outro peso.
@export_range(0.0, 1.0) var peso_inicial := 0.3
## Segundos até a princesa largada no chão voltar sozinha para casa.
@export var princess_return_time := 15.0
## Segundos ao lado da máscara caída para devolvê-la (parado se tiver inimigo
## a até princess_contest_radius m: dá tempo de um aliado do ladrão retomá-la).
@export var princess_rescue_time := 4.0
@export var princess_contest_radius := 4.0
## Dano que quem carrega a máscara inimiga leva (a máscara protege). Sem isso,
## o ladrão morria a ~15 m do pedestal, cercado por quem renasce ali.
@export var carrier_damage_mult := 0.37
## Arrancada ao pegar a máscara (velocidade x mult por time segundos).
@export var steal_boost_mult := 1.35
@export var steal_boost_time := 3.0
## Alma de abate: cada inimigo eliminado manda esta fração de um espírito
## (fat_per_cake) direto para a máscara do time de quem matou. 0 desliga.
## Ciclo 2.25: era 0,15 e, com ~85 abates por time, as duas máscaras batiam no
## peso máximo aos 10 min sem ninguém querer. Agora 0,05 (20 abates = um
## espírito) e as almas só enchem até alma_teto; dali para cima, só espírito
## entregue de propósito.
@export_range(0.0, 1.0) var alma_por_abate := 0.05
@export_range(0.0, 1.0) var alma_teto := 0.75
## Ciclo 2.25: soma no "carregar" (ClassStats.carry_speed_mult) de toda classe.
@export var carregar_bonus := 0.10
@export var cake_spawn_interval := 5.0
@export var max_cakes := 6

@export_group("Poder (medidor de Glacê, 0 a 100)")
## Fontes do medidor: dG/dt = a·(dano causado) + b·(dano sofrido) + eventos − G/τ.
@export var power_per_damage := 0.4
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
## Chi por segundo só de estar vivo (o E vem mesmo sem acertar ninguém).
## Sozinho enche em 100/power_regen s; com briga, bem antes. 0 desliga e
## volta o vazamento acima.
@export var power_regen := 3.0
## Multiplica a recarga de toda habilidade rápida (Q). 1,0 = número do .tres.
@export var rapida_cooldown_mult := 0.7

@export_group("Torretas (Construtor)")
## Torreta de defesa nos terrenos de MapLayout.torreta_spots. Obra como a das
## oficinas (madeira do time + Construtor perto). Vida × vida_mult.
@export var torreta_custo := 4
@export var torreta_obra := 8.0
@export var torreta_vida := 160.0
@export var torreta_dano := 9.0
@export var torreta_cadencia := 1.2
@export var torreta_alcance := 12.0
## Escudo (botão direito) segura esta fração do dano do virote (qualquer classe).
@export_range(0.0, 1.0) var torreta_bloqueio := 0.9
## Escudo virado para o virote: ele volta e acerta a torreta (torreta_dano × devolve, pouco).
@export var torreta_devolve := 1.5
## Estilo do modelo (tools/gerar_torretas.gd): a yagura, b santuário, c posto da raposa.
@export var torreta_estilo := "c"

@export_group("Catapulta")
## Catapulta na base (MapLayout.catapulta_spot): F sobe, F de novo lança; a
## barra de força vai e volta e marca onde cai (metade inimiga, até perto da
## muralha). Pouso em "meteoro de Chi": dano e empurrão em volta.
@export var catapulta_recarga := 12.0
@export var catapulta_voo := 2.4
@export var catapulta_dano := 14.0
@export var catapulta_raio := 3.5
## Queda mais curta (força 0) e mais longa (força 1), em m a partir do meio do
## mapa para o lado inimigo; a longa é limitada pela muralha inimiga menos a folga.
@export var catapulta_queda_min := 14.0
@export var catapulta_folga_muralha := 8.0
## Bots: chance (por decisão) de um atacante na base pegar a catapulta.
@export_range(0.0, 1.0) var catapulta_bots := 0.5

@export_group("Super (R)")
## Barra dourada, 0 a 100, que NÃO enche com o tempo: só jogando bem.
## Fontes: dano causado × super_por_dano, abate, item pego, espírito
## entregue na máscara e captura. Não perde nada ao morrer.
@export var super_por_dano := 0.12
@export var super_por_abate := 22.0
@export var super_por_item := 12.0
@export var super_por_espirito := 30.0
@export var super_por_captura := 50.0
## Super "maior": o poder E da classe em versão gigante.
@export var super_mult_raio := 1.6
@export var super_mult_valor := 2.0
@export var super_mult_duracao := 1.6
## Super "sombra" (Samurai): some por sombra_tempo s, anda sombra_vel × mais
## rápido e o primeiro golpe dá sombra_golpe_mult × dano (e encerra a sombra).
## Bots inimigos só enxergam quem está na sombra a até sombra_visto m.
@export var sombra_tempo := 3.5
@export var sombra_vel := 1.35
@export var sombra_golpe_mult := 2.5
@export var sombra_visto := 2.0
## Quanto o corpo some para o próprio time na sombra (0 = opaco, 1 = invisível).
@export_range(0.0, 1.0) var sombra_alfa := 0.6

@export_group("Combo (3º golpe)")
## Corpo a corpo: o golpe final é vertical e pega só esta fração do arco normal
## (mais dano, menos área). O dano vem de combo_finisher_mult da classe.
@export var final_arco_mult := 0.45
## Tiro: o golpe final do shuriken vira este número de shurikens em leque, com
## esta abertura total (graus). Cada um dá combo_finisher_mult × dano.
@export var final_leque_n := 3
@export var final_leque_graus := 28.0

@export_group("Itens no chão")
## Um item novo a cada tantos segundos, até o máximo, na área do meio.
@export_group("Vida e tempo para matar")
## TTK = vida / (DPS · taxa de acerto). vida_mult multiplica a vida de todas as
## classes e, junto, curas e escudos (que são números absolutos), para eles
## valerem a mesma fração da vida. 1,0 = números dos .tres de classe.
@export var vida_mult := 1.7
## Dano dos poderes do Q (todos), para eles não ficarem fracos com a vida maior.
@export var dano_poder_mult := 1.2
## Fora de combate (sem bater nem apanhar) por regen_delay s, cura
## regen_rate da vida máxima por segundo. Briga perdida não "vaza" para a próxima.
@export var regen_delay := 4.0
@export var regen_rate := 0.06
## O Q de cura vale esta fração quando cura o próprio curandeiro (2.25b):
## curandeiro cercado de aliados virava bola de vida difícil de derrubar.
@export var cura_propria_mult := 0.9
@export var pickup_interval := 9.0
@export var max_pickups := 5
## Chance de o item nascer perto de onde a briga está mais cheia (em vez de
## sorteado na área toda); cai a 3-7 m do bolo de gente.
@export_range(0.0, 1.0) var pickup_perto_da_briga := 0.65
## Abaixo desta fração de vida a tela ganha a borda vermelha (e a mira pulsa).
@export_range(0.0, 1.0) var vida_baixa_frac := 0.3
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
## Ciclo 2.25: 10 → 8,5 no game_config.tres (martelo 15% mais rápido).
@export var oficina_build_time := 10.0
## Madeira que uma casinha consome (Ciclo 2.21: a evolução da casa de uma classe). O Construtor perto da obra puxa 1 do
## estoque do time a cada oficina_puxar_intervalo s (dividido pela velocidade_obra);
## a obra não passa da fração de madeira já entregue.
@export var oficina_custo_madeira := 6
## Ritmo "escada" (Ciclo 2.21): cada casa que o time já escolheu deixa a
## próxima mais cara em tantas madeiras (6, 8, 10, 12 com degrau 2). A 1ª
## evolução sai cedo, a 4ª lá pelos 5 min de uma partida de ~10.
@export var oficina_custo_degrau := 2
@export var oficina_puxar_intervalo := 1.5

@export_group("Sensação do combate")
## Congelamento de atacante e alvo num golpe corpo a corpo (s).
@export var hitstop_time := 0.06
## Animação exagerada por código (estica e encolhe, quique, tremor, morte
## cômica): 0 = desliga, 1 = normal, 2 = desenho animado. Cada classe ainda
## multiplica pelo próprio ClassStats.exagero.
@export_range(0.0, 2.5, 0.05) var exagero_animacao := 1.4
## Antecipação do golpe (s): o corpo "carrega" antes do dano sair.
@export_range(0.0, 0.1, 0.005) var antecipacao_golpe := 0.05
## Rastro da barra de vida (Ciclo 2.26): a parte que o golpe tirou fica branca
## por rastro_espera s e depois desce a rastro_vel (fração da barra por s).
@export var rastro_espera := 0.45
@export var rastro_vel := 0.8
## Borda vermelha do golpe forte: o jogador levou pelo menos esta fração da
## vida máxima num golpe só (ou um golpe com empurrão forte).
@export_range(0.0, 1.0) var golpe_forte_frac := 0.15
## Respingo de tinta no chão onde o golpe acertou (cor do time de quem apanhou).
## Todos num MultiMesh só (1 chamada de desenho). 0 = desliga.
@export var respingo_max := 48
@export var respingo_vida := 2.0

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
## Esquiva perfeita (golpe que passa por dentro do dash): Chi ganho.
@export var chi_esquiva := 8.0
## Guarda que quebra (Ciclo 2.26): cada golpe que bate na defesa soma o dano
## (antes da redução) / vida máxima de quem defende. Somou guarda_limite =
## a guarda quebra: atordoa guarda_atordoa s e não defende por guarda_trava s.
## Golpe de longe soma × guarda_tiro; virote de torreta não soma.
## Depois de guarda_espera s sem apanhar, desce guarda_recupera por s.
@export var guarda_limite := 0.7
@export var guarda_tiro := 0.5
@export var guarda_espera := 1.0
@export var guarda_recupera := 0.35
@export var guarda_atordoa := 0.6
@export var guarda_trava := 1.2
## Chi para quem quebrou a guarda.
@export var guarda_chi := 10.0

@export_group("Poderes Q (Ciclo 2.4)")
## Fúria do Ronin: cresce furia_escala × (e quase não é empurrado).
@export var furia_escala := 1.35
## Redemoinho: puxa inimigos até power_radius × redemoinho_puxa_raio,
## a redemoinho_puxa m/s (vórtice; o empurrão normal ainda vence).
@export var redemoinho_puxa := 4.5
## Chuva de Flechas (Yumi): no fim cai o "arremate", uma salva no centro
## (dano = dano do pulso × chuva_arremate_mult, raio = 60% do círculo, arremessa).
@export var chuva_arremate_mult := 2.5
## Bombardeio (Bombardeiro): N explosões em fila (power_duration = quantas,
## power_radius = raio de cada, power_value = dano de cada), uma a cada
## bombardeio_intervalo s; a última deixa fumaça por bombardeio_fumaca s.
@export var bombardeio_intervalo := 0.16
@export var bombardeio_fumaca := 4.0
@export var redemoinho_puxa_raio := 2.2

@export_group("Chapéus")
## Maquininha de chapéu: fabrica 1 a cada maquina_intervalo s até o estoque
## máximo e começa cheia. Fila: μ = 60/intervalo chapéus/min por máquina; com
## procura λ > μ o estoque S₀ acaba em S₀/(λ − μ) e alguém troca de classe.
@export var maquina_intervalo := 20.0
@export var maquina_estoque_max := 3
## Nível 2 da maquininha (Etapa 2: ainda sem uso no jogo).
@export var maquina_n2_custo := 8
@export var maquina_n2_intervalo := 12.0
@export var maquina_n2_estoque := 4

@export_group("Caminhos e níveis")
## Ciclo 2.21: cada classe do pátio (hat_class_list) tem UMA casa no pátio
## (MapLayout.hat_spots), que começa como barraquinha de chapéu. Os dois
## caminhos opostos dela (ClassStats.caminhos) ficam em tapetes dos lados: o
## Construtor escolhe um (painel no jogador, tapete nos bots) e sela o outro
## pela partida. A casa evoluída nasce no nível 3 (Ciclo 2.22, abaixo).
## (Os nomes "mago_*" ficaram do Ciclo 2.5, quando só a Kitsune tinha caminho.)
## Ciclo 2.22, a escada do bairro (uma por classe do pátio):
##   Nv1 → Nv2: só a barraquinha, com casa_nv2_custo madeiras;
##   Nv2 → Nv3: o Construtor escolhe o caminho no painel e ergue a casa
##              (oficina_custo_madeira + degrau); a casa nasce no Nv3 e a
##              barraquinha vai junto;
##   Nv3 → Nv5: uma subida leva as duas (mago_nivel_custo).
@export var mago_nivel_max := 5
@export var casa_nv2_custo := 4
## Madeira para subir do nível 3 ao 4 e do 4 ao 5 (barraquinha e casa juntas).
@export var mago_nivel_custo := PackedInt32Array([6, 9])
## Com a casa da classe abaixo deste nível, o Super (R) da classe fica travado.
@export var super_nivel_min := 2
## Bônus por nível acima do 2, para quem usa a classe base OU a do caminho
## (nível 5 = 3x): dano, vida máxima e ganho de Chi (Q mais frequente).
@export var mago_bonus_dano := 0.08
@export var mago_bonus_vida := 0.08
@export var mago_bonus_chi := 0.10
## Por nível acima do 2, barraquinha e casa ganham +1 de estoque e fabricam
## mais rápido (intervalo × isto).
@export var mago_pad_intervalo_mult := 0.85
## Os dois times veem o aviso quando um deles escolhe um caminho.
@export var caminho_aviso_inimigo := true

@export_group("Heróis raros (Ciclo 2.23)")
## Madeira do Pavilhão do Herói (Nv5 → Nv6; a 1ª entra na escolha).
@export var heroi_custo := 7
## Segundos para o chapéu do herói voltar ao altar depois que ele sai de campo
## (renasce como aldeão ou troca de chapéu; caído esperando reanimar não conta).
@export var heroi_retorno := 20.0
## Ciclo 2.25 (Julio: "um pouquinho mais apelões, sem exagero"): vida e dano
## de todo herói vezes isto, e Q e Chi do E recarregando em heroi_recarga_mult
## do tempo (0,85 = 15% mais rápido). Soma com heroi_bonus_niveis.
@export var heroi_vida_mult := 1.10
@export var heroi_dano_mult := 1.10
@export var heroi_recarga_mult := 0.85
## Nota do Komusō teleguiada (Ciclo 2.25): procura alvo neste cone (graus),
## vira nota_vira rad/s atrás dele (o talismã do Onmyoji vira 7) e balança de
## lado nota_balanco rad/s.
@export var nota_cone := 40.0
@export var nota_vira := 2.6
@export var nota_balanco := 2.2
@export var sandbox_heroi_retorno := 3.0
## Bots não pegam o chapéu do herói nos primeiros s em que ele está no altar,
## para o jogador do time ter a vez.
@export var heroi_espera_jogador := 8.0
## Níveis de bônus (dano/vida/Chi de mago_bonus_*) de quem veste o herói. A
## base e o caminho param no Nv5 (3 níveis); o herói é "um pouco mais upado".
@export var heroi_bonus_niveis := 4

@export_group("Heróis raros: regras (Ciclo 2.23)")
## Sumotori, Agarrão (Q): s segurando antes de arremessar, s no chão depois do
## pouso, dano e raio do respingo em quem está perto do pouso.
@export var agarrao_segura := 0.35
@export var agarrao_chao := 0.6
@export var agarrao_respingo := 14.0
@export var agarrao_respingo_raio := 2.2
## Sumotori, Dohyō (R): ringue de sal. Quem estava dentro não sai, quem estava
## fora não entra; o Sumotori bate dohyo_dano a mais dentro dele.
@export var dohyo_raio := 6.0
@export var dohyo_tempo := 6.0
@export var dohyo_dano := 0.2
## Yamabushi, Rajada (Q): cone em graus e empurrão (m/s).
@export var rajada_cone := 70.0
@export var rajada_empurrao := 16.0
## Karasu Tengu, Noite de Corvos (R): quantos mergulhos e até onde procura.
@export var mergulho3_alvos := 3
@export var mergulho3_raio := 16.0
## Mujina: multiplicador do golpe que sai do rosto roubado.
@export var mujina_golpe_mult := 1.5
## Onmyoji: bonecos de papel no máximo; Mil Grous (R): grous e abertura.
@export var shikigami_max := 3
@export var mil_grous_n := 5
@export var mil_grous_graus := 50.0
## Tennin: vida de quem o Laço levanta (fração); Véu (R): raio e tempo intocável.
@export var laco_vida := 0.4
@export var veu_raio := 14.0
@export var veu_tempo := 3.0
## Komusō, Réquiem (R): raio e tempo sem Q, E e R.
@export var requiem_raio := 16.0
@export var requiem_tempo := 4.0

@export_group("Heróis 2.27: Ochimusha, Shishimai, Jorogumo")
## Ochimusha, Não cai de primeira: s como fantasma (1 de vida, intocável) e a
## vida com que volta se fizer um abate nesse tempo. Uma vez por vida.
@export var fantasma_tempo := 3.0
@export var fantasma_volta := 0.35
## Corte do Eco: s até o risco no chão cortar de novo.
@export var eco_atraso := 0.6
## Flecha Arrancada (Q): alcance, cone (graus), lentidão (multiplicador) e tempo.
@export var flecha_alcance := 3.2
@export var flecha_cone := 80.0
@export var flecha_lenta := 0.6
@export var flecha_lenta_t := 2.0
## Onibi (E): fogos girando, raio da órbita e de toque, susto (s correndo de medo).
@export var onibi_n := 3
@export var onibi_orbita := 1.3
@export var onibi_toque := 2.0
@export var onibi_susto := 0.6
## Carga dos Caídos (R): fantasmas, comprimento, largura da faixa, dano e s até o fim.
@export var caidos_n := 4
@export var caidos_comp := 12.0
@export var caidos_larg := 3.4
@export var caidos_dano := 34.0
@export var caidos_tempo := 0.7
## Shishimai: Sorte (próximo golpe dobrado + próximo que levar desvia) e Azar
## (próximo golpe erra), em s; cura da Mordida em aliado (fração da vida).
@export var sorte_tempo := 8.0
@export var azar_tempo := 6.0
@export var mordida_cura := 0.15
@export var mordida_alcance := 3.2
## Arrastão (E): metros levando o inimigo na boca e s preso no fim.
@export var arrastao_dist := 8.0
@export var arrastao_preso := 0.6
## Festa da Vila (R): s de leão gigante, escala, raio da mordida que levanta
## caído, raio e intervalo da Sorte para os aliados.
@export var festa_tempo := 7.0
@export var festa_escala := 1.45
@export var festa_levanta := 3.0
@export var festa_sorte_raio := 8.0
@export var festa_sorte_cada := 2.0
## Jorogumo, fio de seda: cada acerto deixa fio_lento mais lento (até fio_max
## vezes) por fio_tempo s; o 3º tiro (Rede) prende rede_preso s.
@export var fio_lento := 0.1
@export var fio_max := 3
@export var fio_tempo := 2.5
@export var rede_preso := 1.0
## Teia (Q): raio, s no chão, quantas por dona, s preso de quem pisa, espera
## até a mesma teia prender a mesma pessoa de novo e velocidade da dona em cima.
@export var teia_raio := 2.1
@export var teia_tempo := 10.0
@export var teia_max := 3
@export var teia_preso := 1.0
@export var teia_espera := 2.5
@export var teia_vel := 1.4
## Puxar os Fios (E): raio, metros puxados e s preso.
@export var puxar_raio := 10.0
@export var puxar_dist := 3.0
@export var puxar_preso := 0.8
## Casulo (R): raio, quantos, s enrolado, golpes de aliado para quebrar e
## quanto do dano passa pela seda.
@export var casulo_raio := 6.0
@export var casulo_n := 3
@export var casulo_tempo := 4.0
@export var casulo_golpes := 3
@export var casulo_dano := 0.5

@export_group("Heróis 2.27b: Kodama, Kaminari-kozō")
## Kodama, Broto (3º tiro de sementes): s preso.
@export var broto_preso := 0.5
## Raízes (Q): comprimento e largura da linha, s preso.
@export var raizes_comp := 8.0
@export var raizes_larg := 1.1
@export var raizes_preso := 1.0
## Bosque (E): árvores, s de vida, distância máxima da mira, raio da sombra que
## cura aliados (vida/s) e vida da árvore (golpes de machado até cair).
@export var bosque_n := 3
@export var bosque_tempo := 12.0
@export var bosque_dist := 9.0
@export var bosque_sombra := 3.2
@export var bosque_cura := 8.0
@export var arvore_golpes := 2
## Fogo no bosque: a árvore vira tocha tocha_tempo s (fere tocha_dano/s quem é do
## time dela a até tocha_raio m) e cai.
@export var tocha_tempo := 2.0
@export var tocha_dano := 10.0
@export var tocha_raio := 2.2
## Floresta Antiga (R): raio do anel, árvores, s, raízes a cada N s (s preso e
## dano nos inimigos de dentro) e cura dos aliados de dentro (vida/s).
@export var floresta_raio := 10.0
@export var floresta_n := 10
@export var floresta_tempo := 8.0
@export var floresta_cada := 2.0
@export var floresta_preso := 1.0
@export var floresta_dano := 8.0
@export var floresta_cura := 7.0
## Kaminari-kozō, carga estática (0 a 1): por s correndo, por dash e pelo
## Relâmpago. Cheia: o próximo acerto descarrega (dano, alcance entre um e
## outro, quantos e s atordoado).
@export var carga_correr := 0.16
@export var carga_dash := 0.35
@export var carga_relampago := 0.5
@export var descarga_dano := 16.0
@export var descarga_raio := 5.0
@export var descarga_n := 3
@export var descarga_preso := 0.4
## Molhado (água do Kappa): s; o raio pula molhado_alcance × mais longe e fere
## molhado_dano × mais em quem está molhado.
@export var molhado_tempo := 4.0
@export var molhado_alcance := 2.0
@export var molhado_dano := 1.5
## Para-raios (Q): s cravado, quantos, raio do choque, intervalo, dano e de
## quantos m ele puxa a descarga do dono.
@export var pararaios_tempo := 6.0
@export var pararaios_max := 2
@export var pararaios_raio := 3.0
@export var pararaios_cada := 1.0
@export var pararaios_dano := 6.0
@export var pararaios_puxa := 9.0
## Relâmpago (E): metros do salto e largura do caminho que fere.
@export var relampago_dist := 9.0
@export var relampago_larg := 1.3
## Tambores do Trovão (R): s, intervalo entre raios, alcance, dano e s atordoado.
@export var tambores_tempo := 6.0
@export var tambores_cada := 0.5
@export var tambores_raio := 10.0
@export var tambores_dano := 14.0
@export var tambores_preso := 0.25
## Árvore do Kodama é para-raios: raio que cai a até N m dela cai nela.
@export var arvore_pararaios := 4.0

@export_group("Sohei e Kusarigama (Ciclo 2.21)")
## Varrida (Q do Sohei): aliados a até varrida_aliados_raio m ganham escudo.
@export var varrida_escudo := 22.0
@export var varrida_escudo_t := 3.0
@export var varrida_aliados_raio := 5.5
## Muralha de Fé (E do Sohei): pressa dos aliados dentro do círculo.
@export var muralha_pressa := 1.2
## Gancho (Q da Kusarigama): velocidade da corrente (m/s) e atordoamento de quem
## é puxado. O puxão usa o mesmo empurrão de todo golpe: d = v²/80, então para
## trazer o alvo de d metros a corrente dá v = √(80·d).
@export var gancho_vel := 34.0
@export var gancho_atordoa := 0.45
## Ciranda de Aço (E da Kusarigama): um pulso a cada ciranda_intervalo s; a
## corrente só corta da metade do raio para fora (o peso fica na ponta).
@export var ciranda_intervalo := 0.3
@export var ciranda_vel_mult := 0.8

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
## Começo calmo (s): nesse tempo os bots não invadem a metade inimiga; pegam
## chapéu, cortam madeira e se posicionam na própria metade.
@export var inicio_calmo := 30.0

@export_group("Modo teste (sandbox)")
## Tudo disponível e recarregando rápido para testar poderes sem bots
## (Game.sandbox). Chi enche power_regen × sandbox_chi_mult por segundo,
## o Super enche do zero em sandbox_super_s, o Q e a catapulta recarregam
## nesta fração do tempo normal.
@export var sandbox_chi_mult := 8.0
@export var sandbox_super_s := 6.0
@export var sandbox_q_mult := 0.25
@export var sandbox_catapulta_mult := 0.2
## Casas no modo teste: madeira infinita e obra/entrega de madeira tantas
## vezes mais rápidas (o resto da escada é igual à partida).
@export var sandbox_obra_mult := 3.0

@export_group("Equilíbrio 2.10")
## Atirar deixa lento: depois de cada tiro, atirador_lento_t s a
## atirador_lento_mult da velocidade. Corrida de perseguição: o corpo a corpo
## fecha a distância se v_perto > v_atirador × mult (6,8 > 7,1 × 0,8 = 5,7).
@export var atirador_lento_mult := 0.8
@export var atirador_lento_t := 0.4
## Escolta da máscara: quem carrega com um aliado a até escolta_raio m, e os
## aliados perto dele, andam (1 + escolta_vel) mais rápido. Ciclo 2.25: para
## quem carrega, cada aliado além do primeiro soma escolta_vel_extra, até
## escolta_max aliados (0,15 + 0,06 + 0,06 = +27% com três).
@export var escolta_raio := 6.0
@export var escolta_vel := 0.15
@export var escolta_vel_extra := 0.06
@export var escolta_max := 3
## Chance de um bot esquivar (dash) de um projétil que vai acertá-lo
## (a cada 0,2 s; bots inimigos: dividida pelo tempo de reação da dificuldade).
@export var bot_esquiva_projetil := 0.35


@export_group("Reanimar (Ciclo 2.18)")
## Aliado caído fica no chão enquanto conta a espera de renascer (estilo
## Battlefield 6): um aliado vivo colado nele segura [F] por reanimar_tempo s
## e ele levanta ali, com a classe que tinha. Regra em scripts/reanimar.gd.
@export var reanimar_ligado := true
@export var reanimar_tempo := 3.0
## Distância (m) do corpo para começar a reanimar.
@export var reanimar_raio := 1.6
## Quem reanima (fora as Kitsunes) arrasta o corpo: anda a esta fração da
## velocidade, puxando-o numa "corda" de reanimar_corda m.
@export var reanimar_arrasto_vel := 0.45
@export var reanimar_corda := 1.1
## Kitsunes reanimam reanimar_mago_mult × mais rápido (paradas, abençoando),
## subindo até reanimar_mago_mult_max no nível máximo do caminho dos magos.
@export var reanimar_mago_mult := 1.5
@export var reanimar_mago_mult_max := 2.0
## Levanta com esta fração da vida e fica intocável por reanimar_intocavel s.
@export_range(0.05, 1.0) var reanimar_vida := 0.5
@export var reanimar_intocavel := 2.0
## Relógio de quem está caído esperando ajuda (< 1 = janela maior). Segurar
## [F] caído desiste e volta ao ritmo normal (renasce no castelo, recruta).
@export var reanimar_ritmo_espera := 0.65
## Desistir (segurar [F] caído; bot sem aliado perto desiste sozinho): renasce
## em reanimar_desistir_frac da espera da morte, nunca menos que
## reanimar_desistir_min s, menos o que a barra já correu caído (nunca mais
## que a espera normal; pode zerar). Bem mais rápido, mas ainda fora da briga.
@export_range(0.1, 1.0) var reanimar_desistir_frac := 0.5
@export var reanimar_desistir_min := 4.0
## Bot caído espera ajuda só com aliado vivo a até este raio (m); senão desiste.
@export var reanimar_bot_espera_raio := 20.0
## Bots vão reanimar quem caiu a até este raio (m); Kitsunes, o dobro.
@export var reanimar_bot_raio := 10.0


@export_group("Placar (Tab)")
## Pontos do placar estilo Battlefield (Tab, e no fim da partida): cada
## estatística do boneco vezes o peso daqui. O nome é sempre "pts_" + o campo
## de Placar.CAMPOS; mudar um número muda a conta e a legenda do placar.
@export var pts_abates := 120.0
## Multikill (Ciclo 2.25, quiz do Julio): abate até multikill_janela s depois do
## anterior continua a corrente. O 2º soma multikill_bonus[0] (duplo), o 3º
## [1] (triplo) e do 4º em diante o último valor a cada abate (multi). O campo
## "multi" do placar já guarda pontos, por isso o peso dele é 1.
@export var multikill_janela := 5.0
@export var multikill_bonus := PackedFloat32Array([50.0, 100.0, 150.0])
@export var pts_multi := 1.0
## Assistência: deu dano no abatido nos últimos assistencia_janela s e não
## foi quem matou.
@export var pts_assist := 50.0
@export var assistencia_janela := 8.0
@export var pts_mortes := 0.0
## Por ponto de vida tirado de inimigo / curado em aliado.
@export var pts_dano := 0.25
@export var pts_cura := 0.4
## Espírito levado até a própria máscara (deixa ela mais pesada).
@export var pts_almas := 40.0
## Tora entregue no depósito ou direto numa torreta.
@export var pts_madeira := 25.0
## Por segundo martelando obra (oficina, torreta, maquininha).
@export var pts_obra_s := 4.0
@export var pts_capturas := 500.0
## Pegar a máscara inimiga do pedestal ou do chão.
@export var pts_roubos := 100.0
## Devolver a própria máscara caída (quem estava ao lado quando ela voltou).
@export var pts_resgates := 75.0
## Aliado caído reanimado (Ciclo 2.18).
@export var pts_reanimar := 60.0


func hat_classes() -> Array[ClassStats]:
	return hat_class_list


## Arena de chapéus (Ciclo 2.29): todas as classes com chapéu, heróis raros
## inclusive, sem repetir. É o sorteio do Tambor de Desafio e a lista das
## fileiras de pads (o recruta fica de fora: ninguém pega chapéu de recruta).
func classes_arena() -> Array[ClassStats]:
	var out := todas_classes()
	for c in hat_class_list:
		for h in c.herois:
			if not out.has(h):
				out.append(h)
	return out


## Todas as classes jogáveis: as do pátio e, depois, os caminhos de cada uma
## (ClassStats.caminhos), sem repetir.
func todas_classes() -> Array[ClassStats]:
	var out: Array[ClassStats] = []
	for c in hat_class_list:
		out.append(c)
	for c in hat_class_list:
		for e in c.caminhos:
			if not out.has(e):
				out.append(e)
	return out
