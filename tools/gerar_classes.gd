extends SceneTree
## Gera os .tres das classes ninja (3 variações por papel + Recruta).
## Os arquivos ficam editáveis no Inspector depois; este script só serve para
## recriar tudo de uma vez. Rodar:
##   godot --headless --path . -s tools/gerar_classes.gd

const CORPO := {
	"Knight": ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Body", "Knight_Head", "Knight_LegLeft", "Knight_LegRight"],
	"Rogue_Hooded": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head_Hooded", "Rogue_LegLeft", "Rogue_LegRight"],
	"Rogue": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head", "Rogue_LegLeft", "Rogue_LegRight"],
	"Mage": ["Mage_ArmLeft", "Mage_ArmRight", "Mage_Body", "Mage_Head", "Mage_LegLeft", "Mage_LegRight"],
	"Barbarian": ["Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_Body", "Barbarian_Head", "Barbarian_LegLeft", "Barbarian_LegRight"],
}

const CABECA := 0.8

## arquivo -> campos. "glb" escolhe o corpo; o resto vai direto para ClassStats.
var CLASSES := {
	"recruta": {"glb": "Barbarian", "display_name": "Recruta", "estilo_ninja": "_recruta", "hat_color": Color(0.9, 0.88, 0.8),
		"max_hp": 60.0, "move_speed": 7.0, "attack_kind": "melee", "damage": 7.0, "attack_range": 2.3, "attack_cooldown": 0.6,
		"knockback": 5.0, "carry_speed_mult": 0.95, "anim_attack": "Unarmed_Melee_Attack_Punch_A",
		"combo_anims": ["Unarmed_Melee_Attack_Punch_A", "Unarmed_Melee_Attack_Punch_B", "Unarmed_Melee_Attack_Kick"]},

	# --- Guerreiro ---
	"guerreiro": {"glb": "Knight", "display_name": "Samurai", "estilo_ninja": "_samurai", "hat_style": "kabuto", "hat_color": Color(1.0, 0.78, 0.3),
		"max_hp": 140.0, "move_speed": 6.2, "attack_kind": "melee", "damage": 22.0, "attack_range": 2.9, "attack_arc_deg": 130.0,
		"attack_cooldown": 0.75, "knockback": 8.0, "carry_speed_mult": 0.7, "anim_idle": "2H_Melee_Idle",
		"anim_attack": "2H_Melee_Attack_Slice",
		"combo_anims": ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Slice_Horizontal", "2H_Melee_Attack_Chop"],
		"skill": "bloqueio", "power": "redemoinho", "power_name": "Redemoinho", "power_radius": 3.2, "power_value": 12.0, "power_duration": 2.0},
	"ronin_oni": {"glb": "Barbarian", "display_name": "Ronin Oni", "estilo_ninja": "_ronin_oni", "hat_style": "mascara_oni", "hat_color": Color(0.85, 0.12, 0.12),
		"escala_modelo": 1.08, "max_hp": 175.0, "move_speed": 5.8, "attack_kind": "melee", "damage": 30.0, "attack_range": 3.1, "attack_arc_deg": 140.0,
		"attack_cooldown": 1.0, "knockback": 11.0, "carry_speed_mult": 0.75, "anim_idle": "2H_Melee_Idle", "anim_run": "Running_B",
		"anim_attack": "2H_Melee_Attack_Chop", "combo_anims": ["2H_Melee_Attack_Slice", "2H_Melee_Attack_Chop"], "combo_finisher_mult": 1.6,
		"skill": "bloqueio", "block_reduction": 0.6,
		"power": "furia", "power_name": "Fúria", "power_radius": 4.0, "power_value": 20.0, "power_duration": 6.0},
	"lamina_dupla": {"glb": "Rogue", "display_name": "Lâmina Dupla", "estilo_ninja": "_lamina_dupla", "hat_style": "faixa", "hat_color": Color(0.3, 0.95, 1.0),
		"escala_modelo": 0.97, "max_hp": 110.0, "move_speed": 7.2, "attack_kind": "melee", "damage": 12.0, "attack_range": 2.5, "attack_arc_deg": 120.0,
		"attack_cooldown": 0.42, "knockback": 4.5, "carry_speed_mult": 0.8,
		"anim_attack": "Dualwield_Melee_Attack_Slice",
		"combo_anims": ["Dualwield_Melee_Attack_Slice", "Dualwield_Melee_Attack_Chop", "Dualwield_Melee_Attack_Slice", "Dualwield_Melee_Attack_Stab"],
		"power": "corte_relampago", "power_name": "Corte Relâmpago", "power_radius": 9.0, "power_value": 35.0, "power_duration": 0.25},

	# --- Atirador ---
	"arqueiro": {"glb": "Rogue_Hooded", "display_name": "Ninja de Shuriken", "estilo_ninja": "_ninja", "hat_style": "capuz", "hat_color": Color(0.3, 0.95, 1.0),
		"max_hp": 80.0, "move_speed": 6.9, "attack_kind": "ranged", "projetil": "shuriken", "damage": 10.0, "attack_range": 15.0,
		"attack_cooldown": 0.5, "knockback": 3.0, "projectile_speed": 38.0, "carry_speed_mult": 0.75, "anim_attack": "Throw",
		"skill": "tiro_carregado", "charge_damage_mult": 2.0,
		"power": "leque", "power_name": "Leque de Shuriken", "power_radius": 70.0, "power_value": 14.0, "power_duration": 9.0},
	"arqueiro_yumi": {"glb": "Rogue_Hooded", "display_name": "Arqueiro Yumi", "estilo_ninja": "_arqueiro_yumi", "hat_style": "hachimaki", "hat_color": Color(0.6, 0.4, 0.2),
		"max_hp": 75.0, "move_speed": 6.5, "attack_kind": "ranged", "projetil": "flecha", "damage": 17.0, "attack_range": 20.0,
		"attack_cooldown": 0.95, "knockback": 4.0, "projectile_speed": 36.0, "carry_speed_mult": 0.75, "anim_attack": "2H_Ranged_Shoot",
		"skill": "tiro_carregado", "charge_damage_mult": 2.2, "charge_time": 1.2,
		"power": "chuva_de_flechas", "power_name": "Chuva de Flechas", "power_radius": 4.0, "power_value": 14.0, "power_duration": 3.0},
	"bombas_fumaca": {"glb": "Rogue", "display_name": "Bombas de Fumaça", "estilo_ninja": "_fumaca", "hat_style": "capuz", "hat_color": Color(0.7, 0.7, 0.85),
		"max_hp": 85.0, "move_speed": 6.6, "attack_kind": "ranged", "projetil": "bomba", "explosao_raio": 2.3, "damage": 14.0, "attack_range": 12.0,
		"attack_cooldown": 1.1, "knockback": 7.0, "projectile_speed": 18.0, "carry_speed_mult": 0.8, "anim_attack": "Throw",
		"power": "nuvem", "power_name": "Nuvem de Fumaça", "power_radius": 4.5, "power_value": 5.0, "power_duration": 5.0},

	# --- Mago ---
	"monge": {"glb": "Mage", "display_name": "Monge de Chi", "estilo_ninja": "_monge", "hat_style": "kasa", "hat_color": Color(0.62, 0.46, 0.24),
		"max_hp": 90.0, "move_speed": 6.4, "attack_kind": "healer", "projetil": "chi", "damage": 8.0, "attack_range": 14.0,
		"attack_cooldown": 0.8, "knockback": 3.0, "projectile_speed": 22.0, "carry_speed_mult": 0.75, "anim_idle": "Idle", "anim_attack": "Spellcast_Shoot",
		"skill": "cura", "heal_amount": 30.0, "heal_radius": 7.0, "heal_cooldown": 4.0,
		"power": "bencao", "power_name": "Bênção", "power_radius": 6.0, "power_value": 0.4, "power_duration": 5.0, "power_shield": 25.0},
	"onmyoji": {"glb": "Mage", "display_name": "Onmyoji", "estilo_ninja": "_onmyoji", "hat_style": "eboshi", "hat_color": Color(0.9, 0.95, 1.0),
		"max_hp": 85.0, "move_speed": 6.3, "attack_kind": "healer", "projetil": "talisma", "damage": 11.0, "attack_range": 15.0,
		"attack_cooldown": 0.9, "knockback": 3.0, "projectile_speed": 26.0, "carry_speed_mult": 0.75, "anim_attack": "Spellcast_Shoot",
		"skill": "cura", "heal_amount": 18.0, "heal_radius": 6.0, "heal_cooldown": 4.5,
		"power": "selo", "power_name": "Selo", "power_radius": 4.0, "power_value": 10.0, "power_duration": 2.5},
	"kitsune": {"glb": "Mage", "display_name": "Kitsune", "estilo_ninja": "_kitsune", "hat_style": "orelhas", "hat_color": Color(0.3, 0.95, 1.0),
		"escala_modelo": 0.96, "max_hp": 80.0, "move_speed": 6.8, "attack_kind": "healer", "projetil": "fogo", "damage": 12.0, "attack_range": 14.0,
		"attack_cooldown": 0.75, "knockback": 3.0, "projectile_speed": 24.0, "carry_speed_mult": 0.75, "anim_attack": "Spellcast_Shoot",
		"skill": "cura", "heal_amount": 15.0, "heal_radius": 6.0, "heal_cooldown": 5.0,
		"power": "coluna_fogo", "power_name": "Coluna de Fogo-Raposa", "power_radius": 3.5, "power_value": 9.0, "power_duration": 3.0},

	# --- Construtor: todos constroem; o resto é detalhe ---
	"construtor": {"glb": "Barbarian", "display_name": "Armadilheiro", "estilo_ninja": "_armadilheiro", "hat_style": "cesto", "hat_color": Color(1.0, 0.6, 0.2),
		"max_hp": 100.0, "move_speed": 6.6, "attack_kind": "melee", "damage": 12.0, "attack_range": 2.6, "attack_cooldown": 0.7,
		"knockback": 6.0, "carry_speed_mult": 0.85, "anim_attack": "1H_Melee_Attack_Chop", "velocidade_obra": 1.0,
		"skill": "armadilha", "trap_kind": "estrepes",
		"power": "corrida", "power_name": "Corrida", "power_radius": 6.0, "power_value": 1.4, "power_duration": 5.0},
	"mestre_polvora": {"glb": "Barbarian", "display_name": "Mestre da Pólvora", "estilo_ninja": "_polvora", "hat_style": "barril", "hat_color": Color(1.0, 0.45, 0.08),
		"max_hp": 100.0, "move_speed": 6.4, "attack_kind": "melee", "damage": 12.0, "attack_range": 2.6, "attack_cooldown": 0.75,
		"knockback": 7.0, "carry_speed_mult": 0.85, "anim_attack": "1H_Melee_Attack_Chop", "velocidade_obra": 1.3,
		"skill": "armadilha", "trap_kind": "mina", "trap_damage": 16.0, "trap_max": 2, "trap_cooldown": 5.0,
		"power": "reforco", "power_name": "Reforço", "power_radius": 6.0, "power_value": 30.0, "power_duration": 6.0},
	"carpinteiro": {"glb": "Knight", "display_name": "Carpinteiro", "estilo_ninja": "_carpinteiro", "hat_style": "hachimaki", "hat_color": Color(0.85, 0.65, 0.4),
		"max_hp": 110.0, "move_speed": 6.7, "attack_kind": "melee", "damage": 13.0, "attack_range": 2.7, "attack_cooldown": 0.8,
		"knockback": 7.0, "carry_speed_mult": 0.9, "anim_attack": "2H_Melee_Attack_Chop", "velocidade_obra": 2.0,
		"power": "mutirao", "power_name": "Mutirão", "power_radius": 8.0, "power_value": 0.35, "power_duration": 6.0},
}


func _init() -> void:
	var script := load("res://scripts/data/class_stats.gd")
	for nome in CLASSES:
		var d: Dictionary = CLASSES[nome]
		var path := "res://config/classes/%s.tres" % nome
		var novo: Resource = script.new()  # começa do padrão para não herdar campos velhos
		novo.id = StringName(nome)
		novo.escala_cabeca = CABECA
		novo.model = load("res://assets/characters/%s.glb" % d.glb)
		novo.visible_meshes = PackedStringArray(CORPO[d.glb])
		for k in d:
			if k == "glb":
				continue
			var v = d[k]
			if v is Array:
				v = PackedStringArray(v)
			novo.set(k, v)
		ResourceSaver.save(novo, path)
		print("salvo ", path)
	quit()
