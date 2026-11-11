extends SceneTree
## Gera os 8 heróis raros do Ciclo 2.23 (config/classes/<id>.tres) e liga cada
## um ao bairro (campo `herois` da classe base). Rodar depois de mudar números:
##   godot --headless --path . -s tools/gerar_herois.gd
## Herói futuro: uma entrada em HEROIS + o id na lista do bairro em BAIRROS +
## `NinjaVisual._<id>` + adorno/emblema (tools/gerar_casas.gd).
## Sem `class_name` do jogo aqui (o -s compila antes dos autoloads): o esquema
## vem pelo script, as classes por load().

const ESQUEMA := "res://scripts/data/class_stats.gd"

const MALHAS := {
	"Barbarian": ["Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_Body", "Barbarian_Head", "Barbarian_LegLeft", "Barbarian_LegRight"],
	"Rogue": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head", "Rogue_LegLeft", "Rogue_LegRight"],
	"Rogue_Hooded": ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Body", "Rogue_Head_Hooded", "Rogue_LegLeft", "Rogue_LegRight"],
	"Mage": ["Mage_ArmLeft", "Mage_ArmRight", "Mage_Body", "Mage_Head", "Mage_LegLeft", "Mage_LegRight"],
	"Knight": ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Body", "Knight_Head", "Knight_LegLeft", "Knight_LegRight"],
}

## Ordem = ordem dos botões no painel do Nv6.
const BAIRROS := {
	"guerreiro": ["sumotori", "kappa"],
	"arqueiro": ["yamabushi", "karasu_tengu", "mujina"],
	"kitsune": ["onmyoji", "tennin", "komuso"],
}

const HEROIS := {
	"sumotori": {
		"display_name": "Sumotori", "epiteto": "O lutador do santuário", "modelo": "Barbarian",
		"descricao": "Campeão do ringue de sal do santuário da montanha. Desceu para a guerra porque ninguém mais aceitava lutar com ele. Agarra, gira e arremessa; dentro do ringue dele, ninguém sai e ninguém entra.",
		"estilo_linha": "Tanque de mão vazia: agarra, arremessa e prende no ringue.",
		"hat_style": "coque", "hat_color": Color(0.96, 0.86, 0.62), "estilo_ninja": "_sumotori",
		"escala_extremidades": 1.5, "escala_modelo": 1.18, "dash_estilo": "rolar",
		"max_hp": 215.0, "move_speed": 5.8, "attack_kind": "melee", "damage": 18.0, "attack_range": 2.6,
		"attack_arc_deg": 120.0, "attack_cooldown": 0.4, "knockback": 9.0,
		"combo_anims": ["Unarmed_Melee_Attack_Punch_A", "Unarmed_Melee_Attack_Punch_B", "Unarmed_Melee_Attack_Punch_A", "2H_Melee_Attack_Chop"],
		"combo_finisher_mult": 1.6, "block_reduction": 0.6,
		"skill": "agarrao", "skill_name": "Agarrão", "skill_cooldown": 7.0, "skill_value": 30.0, "skill_radius": 2.8, "skill_duration": 9.0,
		"power": "pisao_grande", "power_name": "Pisão do Santuário", "power_radius": 5.0, "power_value": 26.0, "power_duration": 0.9,
		"super_tipo": "proprio", "super_poder": "dohyo", "super_nome": "Dohyō",
		"anim_idle": "Unarmed_Idle", "anim_attack": "Unarmed_Melee_Attack_Punch_A",
	},
	"kappa": {
		"display_name": "Kappa do Rio", "epiteto": "O espírito do rio", "modelo": "Rogue",
		"descricao": "Espírito do rio que guarda o prato de água na cabeça como quem guarda a alma. Some numa poça e reaparece no pé do inimigo; pelas costas, o casco segura quase tudo.",
		"estilo_linha": "Briga de perto com casco nas costas e jato de água.",
		"hat_style": "prato", "hat_color": Color(0.35, 0.88, 0.78), "estilo_ninja": "_kappa",
		"escala_modelo": 0.92, "dash_estilo": "rolamento",
		"max_hp": 150.0, "move_speed": 7.0, "attack_kind": "melee", "damage": 13.0, "attack_range": 2.4,
		"attack_arc_deg": 120.0, "attack_cooldown": 0.45, "knockback": 5.0,
		"combo_anims": ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Slice_Horizontal", "Dualwield_Melee_Attack_Chop"],
		"combo_finisher_mult": 1.5, "casco": 0.6, "block_reduction": 0.6,
		"skill": "rasteira", "skill_name": "Rasteira do Rio", "skill_cooldown": 6.0, "skill_value": 16.0, "skill_radius": 6.0, "skill_duration": 0.8,
		"power": "jato", "power_name": "Jato d'Água", "power_radius": 12.0, "power_value": 24.0, "power_duration": 14.0,
		"super_tipo": "maior", "super_nome": "Enchente",
		"anim_attack": "1H_Melee_Attack_Slice_Diagonal",
	},
	"yamabushi": {
		"display_name": "Yamabushi do Leque", "epiteto": "O eremita tengu", "modelo": "Mage",
		"descricao": "Monge da montanha que aprendeu com os tengu a mandar no vento. Um abano do leque devolve flechas a quem atirou; outro abre um redemoinho onde ele quiser.",
		"estilo_linha": "Média distância: lâminas de vento e devolve tiros.",
		"hat_style": "tokin", "hat_color": Color(1.0, 0.55, 0.25), "estilo_ninja": "_yamabushi",
		"dash_estilo": "ninja",
		"max_hp": 105.0, "move_speed": 6.6, "attack_kind": "ranged", "damage": 14.0, "attack_range": 9.0,
		"attack_cooldown": 0.55, "knockback": 6.0, "projectile_speed": 26.0, "projetil": "vento",
		"combo_anims": [], "combo_finisher_mult": 1.0, "block_reduction": 0.5,
		"skill": "rajada", "skill_name": "Rajada do Leque", "skill_cooldown": 6.0, "skill_value": 8.0, "skill_radius": 7.0,
		"power": "redemoinho_longe", "power_name": "Redemoinho", "power_radius": 3.5, "power_value": 7.0, "power_duration": 3.0,
		"super_tipo": "maior", "super_nome": "Tufão",
		"anim_attack": "1H_Melee_Attack_Slice_Horizontal",
	},
	"karasu_tengu": {
		"display_name": "Karasu Tengu", "epiteto": "O corvo da montanha", "modelo": "Rogue_Hooded",
		"descricao": "Metade homem, metade corvo, dono do céu da montanha. Sobe sem ninguém ver e cai em cima de quem atira de longe. Onde ele passa, a revoada não deixa ver nada.",
		"estilo_linha": "Caça do alto: mergulha no cursor e cega com corvos.",
		"hat_style": "bico", "hat_color": Color(0.55, 0.48, 0.9), "estilo_ninja": "_karasu",
		"dash_estilo": "ninja",
		"max_hp": 95.0, "move_speed": 7.3, "attack_kind": "melee", "damage": 15.0, "attack_range": 2.6,
		"attack_arc_deg": 120.0, "attack_cooldown": 0.5, "knockback": 5.0, "dano_costas": 0.3,
		"combo_anims": ["Dualwield_Melee_Attack_Slice", "Dualwield_Melee_Attack_Stab", "Dualwield_Melee_Attack_Chop"],
		"combo_finisher_mult": 1.5, "block_reduction": 0.5, "explosao_raio": 2.6,
		"skill": "mergulho", "skill_name": "Mergulho", "skill_cooldown": 7.0, "skill_value": 32.0, "skill_radius": 11.0,
		"power": "revoada", "power_name": "Revoada", "power_radius": 4.5, "power_value": 4.0, "power_duration": 4.0,
		"super_tipo": "proprio", "super_poder": "mergulho3", "super_nome": "Noite de Corvos",
		"anim_attack": "Dualwield_Melee_Attack_Slice",
	},
	"mujina": {
		"display_name": "Mujina", "epiteto": "A sem rosto", "modelo": "Rogue",
		"descricao": "Ninguém sabe o rosto dela, porque ela não tem um. Toca num inimigo e passa a usar o dele: anda pelo pátio do outro time como se fosse de casa, até o primeiro golpe.",
		"estilo_linha": "Infiltração: rouba o rosto do inimigo e bate pelas costas.",
		"hat_style": "mascara_lisa", "hat_color": Color(0.72, 0.45, 0.95), "estilo_ninja": "_mujina",
		"dash_estilo": "ninja",
		"max_hp": 90.0, "move_speed": 7.2, "attack_kind": "melee", "damage": 13.0, "attack_range": 2.3,
		"attack_arc_deg": 110.0, "attack_cooldown": 0.45, "knockback": 4.0, "dano_costas": 1.0,
		"combo_anims": ["1H_Melee_Attack_Stab", "1H_Melee_Attack_Slice_Diagonal", "Dualwield_Melee_Attack_Stab"],
		"combo_finisher_mult": 1.5, "block_reduction": 0.5,
		"skill": "roubar_rosto", "skill_name": "Roubar Rosto", "skill_cooldown": 12.0, "skill_radius": 3.0, "skill_duration": 10.0,
		"power": "susto", "power_name": "Susto", "power_radius": 6.0, "power_value": 6.0, "power_duration": 1.5,
		"super_tipo": "sombra", "super_nome": "Passo sem Rosto",
		"anim_attack": "1H_Melee_Attack_Stab",
	},
	"onmyoji": {
		"display_name": "Onmyoji de Papel", "epiteto": "O dobrador de shikigami", "modelo": "Mage",
		"descricao": "Feiticeiro da corte que dobra espíritos de papel. Três bonecos giram em volta dele e engolem os golpes; dobrados de novo, viram talismãs que caçam o alvo sozinhos.",
		"estilo_linha": "Magia de papel: bonecos que protegem e grous que curam.",
		"hat_style": "eboshi", "hat_color": Color(0.98, 0.95, 0.82), "estilo_ninja": "_onmyoji",
		"dash_estilo": "chama",
		"max_hp": 95.0, "move_speed": 6.4, "attack_kind": "ranged", "damage": 11.0, "attack_range": 14.0,
		"attack_cooldown": 0.7, "knockback": 3.0, "projectile_speed": 26.0, "projetil": "talisma",
		"combo_anims": [], "combo_finisher_mult": 1.0, "block_reduction": 0.5,
		"skill": "dobrar", "skill_name": "Dobrar Shikigami", "skill_cooldown": 3.5, "skill_value": 14.0,
		"power": "grou", "power_name": "Grou de Papel", "power_radius": 18.0, "power_value": 22.0, "power_duration": 1.0,
		"heal_amount": 25.0,
		"super_tipo": "proprio", "super_poder": "mil_grous", "super_nome": "Mil Grous",
		"anim_attack": "Spellcast_Shoot",
	},
	"tennin": {
		"display_name": "Tennin do Manto", "epiteto": "A dançarina celeste", "modelo": "Mage",
		"descricao": "Desceu do céu atrás do manto de penas e ficou para cuidar do castelo. Flutua acima da briga, ninguém consegue empurrá-la, e o laço do manto puxa de volta quem caiu.",
		"estilo_linha": "Apoio que levanta caídos de longe e protege o time.",
		"hat_style": "halo", "hat_color": Color(1.0, 0.72, 0.78), "estilo_ninja": "_tennin",
		"escala_modelo": 0.98, "dash_estilo": "chama", "flutua": true, "knock_imune": true,
		"max_hp": 100.0, "move_speed": 6.8, "attack_kind": "melee", "damage": 12.0, "attack_range": 3.2,
		"attack_arc_deg": 360.0, "attack_cooldown": 0.7, "knockback": 4.0,
		"combo_anims": [], "combo_finisher_mult": 1.0, "block_reduction": 0.5,
		"skill": "laco", "skill_name": "Laço do Manto", "skill_cooldown": 10.0, "skill_value": 20.0, "skill_radius": 12.0,
		"power": "danca", "power_name": "Dança Celeste", "power_radius": 5.5, "power_value": 0.06, "power_duration": 4.0,
		"super_tipo": "proprio", "super_poder": "veu", "super_nome": "Véu Celeste",
		"anim_attack": "2H_Melee_Attack_Spin",
	},
	"komuso": {
		"display_name": "Komusō", "epiteto": "O monge sem rosto", "modelo": "Knight",
		"descricao": "Monge errante de cesto na cabeça que nunca mostra o rosto. A flauta dele faz dormir, puxa os inimigos para perto e, no fim, cala qualquer poder.",
		"estilo_linha": "Controle pelo som: sono, hipnose e silêncio.",
		"hat_style": "tengai", "hat_color": Color(0.55, 0.9, 0.85), "estilo_ninja": "_komuso",
		"dash_estilo": "rolar",
		"max_hp": 110.0, "move_speed": 6.2, "attack_kind": "ranged", "damage": 12.0, "attack_range": 12.0,
		"attack_cooldown": 0.65, "knockback": 3.0, "projectile_speed": 22.0, "projetil": "nota",
		"combo_anims": [], "combo_finisher_mult": 1.0, "block_reduction": 0.5,
		"skill": "sono", "skill_name": "Canção de Ninar", "skill_cooldown": 8.0, "skill_radius": 8.0, "skill_duration": 1.6,
		"power": "hipnose", "power_name": "Hipnose", "power_radius": 7.0, "power_value": 0.0, "power_duration": 2.0,
		"super_tipo": "proprio", "super_poder": "requiem", "super_nome": "Réquiem",
		"anim_attack": "1H_Ranged_Shoot",
	},
}


func _init() -> void:
	var esquema: Script = load(ESQUEMA)
	var feitos := {}
	for id in HEROIS:
		var d: Dictionary = HEROIS[id]
		var c: Resource = esquema.new()
		c.id = StringName(id)
		c.model = load("res://assets/characters/%s.glb" % d.modelo)
		c.visible_meshes = PackedStringArray(MALHAS[d.modelo])
		c.escala_cabeca = 0.58
		c.escala_extremidades = 1.3
		c.chapeu_tempo_mult = 1.0
		for k in d:
			if k == "modelo":
				continue
			var v = d[k]
			if k == "combo_anims":
				v = PackedStringArray(v)
			c.set(k, v)
		for base in BAIRROS:
			if id in BAIRROS[base]:
				c.classe_base = StringName(base)
		var caminho := "res://config/classes/%s.tres" % id
		c.resource_path = caminho
		var err := ResourceSaver.save(c, caminho)
		print("%s -> %s" % [caminho, "ok" if err == OK else str(err)])
		feitos[id] = load(caminho)
	for base in BAIRROS:
		var caminho := "res://config/classes/%s.tres" % base
		var b: Resource = load(caminho)
		var lista: Array = b.get("herois")
		lista.clear()
		for id in BAIRROS[base]:
			lista.append(feitos[id])
		var err := ResourceSaver.save(b, caminho)
		print("%s herois=%s -> %s" % [caminho, BAIRROS[base], "ok" if err == OK else str(err)])
	quit()
