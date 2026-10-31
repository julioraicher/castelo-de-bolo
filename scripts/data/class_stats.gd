class_name ClassStats
extends Resource
## Atributos de uma classe (o "chapéu" que a unidade está usando).
## Cada classe é um arquivo .tres em res://config/classes/. Abra no Godot e
## mude os números pelo Inspector: não precisa programar.

@export var id: StringName = &"recruta"
@export var display_name := "Recruta"

@export_group("Visual")
## Modelo 3D animado (KayKit). O mesmo modelo traz várias armas e chapéus;
## só as partes listadas em visible_meshes aparecem.
@export var model: PackedScene
@export var visible_meshes: PackedStringArray = []
## Nome da malha da capa, que é pintada com a cor do time.
@export var cape_mesh := ""
## Cor do chapéu exibido no pedestal do castelo.
@export var hat_color := Color.WHITE
## Formato do chapéu do pedestal (HatPad.make_hat).
@export_enum("elmo", "capuz", "chapeu_pontudo", "kasa", "kabuto", "faixa", "mascara_oni", "eboshi", "orelhas", "cesto", "barril", "hachimaki") var hat_style := "elmo"
## Visual ninja (NinjaVisual): nome da função que monta as peças (ex.: "_samurai").
## Vazio = modelo KayKit original, só com a capa na cor do time.
@export var estilo_ninja := ""
## Escala da cabeça (1 = KayKit original; menor = proporção mais realista).
@export var escala_cabeca := 1.0
## Escala de mãos e pés (golpe e passo leem de longe; Ciclo 2.2).
@export var escala_extremidades := 1.0
## Escala do boneco inteiro (Ronin maior, Kitsune mais miúda).
@export var escala_modelo := 1.0
## Multiplicador da animação exagerada desta classe (GameConfig.exagero_animacao).
## Pesados (Ronin) amassam menos; leves (Kitsune) mais.
@export var exagero := 1.0

@export_group("Atributos")
@export var max_hp := 60.0
@export var move_speed := 6.5
## melee = golpe em cone; ranged = dispara projétil; healer = dispara magia e cura aliados.
@export_enum("melee", "ranged", "healer") var attack_kind := "melee"
@export var damage := 8.0
@export var attack_range := 2.4
## Abertura do golpe corpo a corpo, em graus.
@export var attack_arc_deg := 110.0
@export var attack_cooldown := 0.8
## Velocidade do empurrão no alvo (m/s). Distância empurrada = v²/80 (8 -> 0,8 m).
@export var knockback := 6.0
@export var projectile_speed := 30.0
## Visual e comportamento do projétil: bomba cai em parábola e explode em área.
@export_enum("flecha", "magia", "shuriken", "bomba", "talisma", "fogo", "chi") var projetil := "flecha"
## Bomba: raio da explosão (m).
@export var explosao_raio := 2.2
@export_group("Combo")
## Animações do combo corpo a corpo, em ordem (golpes seguidos em até
## COMBO_WINDOW s). Vazio = sempre anim_attack.
@export var combo_anims: PackedStringArray = []
## O último golpe do combo multiplica dano e empurrão por este valor.
@export var combo_finisher_mult := 1.4

@export_group("Botão direito")
## cura = cura aliados em volta; bloqueio = segure para defender pela frente;
## tiro_carregado = segure para carregar e solte para atirar;
## armadilha = solta estrepes no chão (Construtor).
@export_enum("nenhum", "cura", "bloqueio", "tiro_carregado", "armadilha") var skill := "nenhum"
## Fração do dano bloqueada (golpes de até 60° da frente).
@export_range(0.0, 1.0) var block_reduction := 0.7
## Segundos para carga máxima do tiro.
@export var charge_time := 1.0
## Dano na carga máxima (multiplicador). A velocidade da flecha sobe até 1,5x.
@export var charge_damage_mult := 2.0
## Estrepes: dano em quem pisa, lentidão (multiplicador de velocidade) e tempo.
@export var trap_damage := 15.0
@export var trap_slow := 0.5
@export var trap_slow_time := 2.0
@export var trap_cooldown := 4.0
## Quantas armadilhas do mesmo dono podem existir ao mesmo tempo.
@export var trap_max := 3
## estrepes = fura e deixa lento; mina = explode e empurra.
@export_enum("estrepes", "mina") var trap_kind := "estrepes"

@export_group("Construção")
## Velocidade de obra nas oficinas (0 = não constrói; Construtor 1 a 2).
@export var velocidade_obra := 0.0

@export_group("Poder (Q)")
## Poder especial, liberado quando o medidor de Glacê enche.
@export_enum("nenhum", "redemoinho", "chuva_de_flechas", "bencao", "corrida", "furia", "corte_relampago", "leque", "nuvem", "selo", "coluna_fogo", "reforco", "mutirao") var power := "nenhum"
@export var power_name := ""
## Raio de efeito (m).
@export var power_radius := 3.0
## redemoinho/chuva_de_flechas: dano por pulso; bencao: fração da vida curada;
## corrida: multiplicador de velocidade.
@export var power_value := 10.0
## Duração (s) do efeito.
@export var power_duration := 2.0
## bencao: escudo que absorve dano, por aliado.
@export var power_shield := 0.0

@export_group("Cura (clérigo)")
@export var heal_amount := 0.0
@export var heal_radius := 0.0
@export var heal_cooldown := 4.0
@export_group("Princesa")
## Multiplicador de velocidade ao carregar a princesa (antes do peso do bolo).
@export var carry_speed_mult := 0.75

@export_group("Animações")
@export var anim_idle := "Idle"
@export var anim_run := "Running_A"
@export var anim_attack := "1H_Melee_Attack_Chop"
