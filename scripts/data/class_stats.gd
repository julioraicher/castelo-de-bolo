class_name ClassStats
extends Resource
## Atributos de uma classe (o "chapéu" que a unidade está usando).
## Cada classe é um arquivo .tres em res://config/classes/. Abra no Godot e
## mude os números pelo Inspector: não precisa programar.

@export var id: StringName = &"aldeao"
@export var display_name := "Aldeão"

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
@export_enum("elmo", "capuz", "chapeu_pontudo") var hat_style := "elmo"

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
