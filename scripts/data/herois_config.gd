class_name HeroisConfig
extends Resource
## Números dos poderes dos heróis raros (Nv6): Q, E e R de cada um. Revisão 3a
## (NU-16): moravam no GameConfig. Arquivo: config/herois_regras.tres (ligado em
## game_config.tres > herois); no código, Config.cfg.herois.<campo>. O que vale
## para todo herói (custo, volta do chapéu, multiplicadores de vida, dano e
## recarga) continua no GameConfig, grupo "Heróis raros".

@export_group("Komusō: nota teleguiada (Ciclo 2.25)")
## Nota do Komusō teleguiada (Ciclo 2.25): procura alvo neste cone (graus),
## vira nota_vira rad/s atrás dele (o talismã do Onmyoji vira 7) e balança de
## lado nota_balanco rad/s.
@export var nota_cone := 40.0
@export var nota_vira := 2.6
@export var nota_balanco := 2.2

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
@export var flecha_cone := 100.0
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

@export_group("Herói 2.30: Predero")
## Garrafada (ataque; o raio do estilhaço é explosao_raio no .tres): s de
## "encachaçado" em quem leva (fogo fere encachacado_fogo × mais nele).
@export var encachacado_tempo := 4.0
@export var encachacado_fogo := 1.5
## Garrafa que estoura dentro de uma poça do dono: o estilhaço cobre a poça
## inteira (raio da poça) com garrafa_poca_mult × o dano.
@export var garrafa_poca_mult := 0.8
## Poça de Cachaça (Q): raio, s no chão, quantas por dono e atrito de quem pisa
## (aceleração da caminhada × poca_atrito: derrapa) e s que dura depois de sair.
@export var poca_raio := 2.6
@export var poca_tempo := 8.0
@export var poca_max := 2
@export var poca_atrito := 0.12
@export var poca_derrapa := 0.6
## Poça acesa (qualquer fogo encosta): s queimando, dano/s em quem é inimigo do dono.
@export var poca_fogo_tempo := 3.0
@export var poca_fogo_dano := 14.0
## Andaime Expresso (E): largura e altura da cobertura (bloqueia passagem e
## tiros), distância da frente do Predero, s de pé e golpes de machado até cair.
@export var andaime_larg := 4.0
@export var andaime_alt := 2.6
@export var andaime_dist := 2.2
@export var andaime_tempo := 7.0
@export var andaime_golpes := 3
## Saideira (R): garrafas que chovem, raio da chuva em volta da mira, distância
## máxima da mira, dano de cada uma e s entre elas; a última vem acesa (palito)
## e põe fogo em todas as poças do dono no raio.
@export var saideira_n := 8
@export var saideira_raio := 4.5
@export var saideira_dist := 11.0
@export var saideira_dano := 14.0
@export var saideira_cada := 0.14
## Árvore do Kodama é para-raios: raio que cai a até N m dela cai nela.
@export var arvore_pararaios := 4.0
