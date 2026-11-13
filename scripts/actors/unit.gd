class_name Unit
extends CharacterBody3D
## Um soldado (jogador ou bot). Quem decide O QUE fazer é o "cérebro"
## (PlayerBrain ou BotBrain); a Unit só executa: andar, atacar, esquivar,
## carregar coisas, tomar dano, morrer e renascer.
##
## O cérebro preenche, a cada quadro físico:
##   move_intent  -> direção desejada (Vector3 no plano XZ, comprimento 0..1)
##   aim_dir      -> para onde mirar
##   aim_point    -> ponto do chão mirado (poderes de área)
##   wants_attack / wants_block (segurado, botão direito) / wants_quick (Q) /
##   wants_power (E, poder de Chi) / wants_dodge

signal died(unit: Unit, killer: Unit)
signal class_changed(unit: Unit)

const TOON_FANTASMA := preload("res://assets/shaders/toon_fantasma.gdshader")
const BARRA_VIDA := preload("res://assets/shaders/barra_vida.gdshader")
static var _barra_cache := {}  # time -> material da barra de vida
const ACCEL := 70.0
const DODGE_SPEED := 17.0
const DODGE_TIME := 0.24
const DODGE_COOLDOWN := 0.9
const KNOCK_DECAY := 40.0  # m/s² de "freada" do empurrão: distância = v²/(2·KNOCK_DECAY)
const EQUIP_TIME := 0.75  # s para pegar o chapéu e pôr na cabeça (andando)
const COMBO_WINDOW := 0.5  # s depois do fim da recarga para o próximo golpe contar no combo
const POWER_MAX := 100.0
const SPIN_TICK := 0.25  # s entre pulsos de dano do Redemoinho
const BLOCK_COS := 0.5  # cos(60°): bloqueio cobre golpes até 60° da frente
## Ossos do tronco: a animação de pôr o chapéu toca só neles, então as pernas
## continuam correndo com a animação normal.
const UPPER_BONES := ["spine", "chest", "upperarm.l", "lowerarm.l", "wrist.l", "hand.l", "handslot.l", "upperarm.r", "lowerarm.r", "wrist.r", "hand.r", "handslot.r", "head"]
const LOOPING_ANIMS := ["Idle", "Running_A", "Running_B", "Walking_A", "Walking_B", "Sit_Floor_Idle", "Cheer", "2H_Melee_Idle", "Spellcasting", "1H_Ranged_Aiming", "2H_Melee_Attack_Spinning", "Walking_Backwards"]

var game: Game
var team := 0
var is_player := false
var brain: Node

var stats: ClassStats
var hp := 1.0
var alive := true
var carried_princess: Princess = null
var has_cake := false
## Tora nos braços (Construtor, Ciclo 2.3): anda a tora_vel_mult e não ataca.
var carried_tora: Tora = null

# Intenções preenchidas pelo cérebro.
var move_intent := Vector3.ZERO
var aim_dir := Vector3.FORWARD
var aim_point := Vector3.ZERO
## Inimigo exatamente sob o cursor (só o jogador): o tiro mira NELE,
## inclusive na vertical (atirar da ponte/muralha para baixo, e vice-versa).
var aim_unit: Unit = null
var wants_attack := false
var wants_block := false
var wants_quick := false  # Q: habilidade rápida (recarga curta)
var wants_power := false  # E: poder de Chi (medidor cheio)
var wants_super := false  # R: super (barra dourada cheia)
var wants_dodge := false
## [F] segurado: reanimar o aliado caído colado (Reanimar, Ciclo 2.18).
var wants_reanimar := false

# Reanimar (estado; a regra mora em Reanimar).
var reanimar_prog := 0.0     # caído: 0..1 do anel de reanimação (fica guardado)
var reanimador: Unit = null  # caído: quem está me reanimando agora
var reanimando: Unit = null  # vivo: o corpo que estou reanimando/arrastando
var desistiu := false        # caído: segurou [F] e vai renascer no castelo
var _intocavel_t := 0.0      # acabou de ser reanimado: não leva dano

## Medidor de Glacê (0 a POWER_MAX). Cheio = poder do Q liberado.
var power := 0.0
## Barra do super (0 a POWER_MAX): só enche jogando (dano, abates, itens,
## espíritos, captura), nunca com o tempo, e não cai ao morrer.
var super_carga := 0.0
var _super_t := 0.0  # super "maior" ativo: stats trocado por uma cópia ampliada
var _stats_normal: ClassStats = null
var _sombra_t := 0.0  # super "sombra": invisível
static var _fantasma_cache := {}  # material opaco -> versão translúcida (Passo da Sombra)

var nav_agent: NavigationAgent3D

var _visual: Node3D
var _model: Node3D
var _anim: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _current_anim := ""
var _anim_lock := 0.0
var _attack_cd := 0.0
var _heal_cd := 0.0
var _dodge_cd := 0.0
var _esquiva_t := 0.0  # recarga do aviso de esquiva perfeita (área acerta várias vezes)
var _dodge_t := 0.0
var _dodge_dir := Vector3.ZERO
var _knock := Vector3.ZERO      # velocidade do empurrão (separada da caminhada)
var _launch_vy := 0.0           # impulso para cima pendente (Fúria, explosões, golpe final)
var _calm_t := 0.0              # s desde a última vez que bateu ou apanhou (regeneração)
var _move_vel := Vector3.ZERO   # velocidade da caminhada/esquiva
var _tiro_lento_t := 0.0  # atirou há pouco: anda mais devagar (atirador_lento_*)
var _flash_t := 0.0
var _respawn_t := 0.0
var _hp_root: Node3D
var _hp_fill: MeshInstance3D
var _cake_visual: Node3D
var _player_marker: MeshInstance3D

var _equip_t := 0.0
var _equip_stats: ClassStats
var _equip_hat: Node3D
var _upper: AnimationPlayer  # segundo player, só para os ossos do tronco

var _attack_t := 0.0     # pose de ataque (vira para a mira, anda um pouco mais devagar)
var _combo_i := 0
var _combo_t := 0.0
var _hitstop_t := 0.0
var _blocking := false
var _block_t := 0.0  # há quanto tempo o bloqueio está erguido (contra-golpe)
var _charge_t := 0.0
var _power_idle := 0.0
var _power_active_t := 0.0  # enquanto o próprio poder age, ele não recarrega o medidor
var _spin_t := 0.0
var _spin_tick := 0.0
var _shield := 0.0
var _shield_t := 0.0
var _shield_mesh: MeshInstance3D
var _boost_t := 0.0
var _boost_mult := 1.0
var _boost_fx_t := 0.0
var _slow_t := 0.0
var _slow_mult := 1.0
var _quick_cd := 0.0  # recarga do Q
var _escudo_def: MeshInstance3D  # arco na frente enquanto defende
# Guarda que quebra (Ciclo 2.26): quanto a defesa já segurou (fração da vida
# máxima), há quanto tempo apanhou na defesa e por quanto tempo não defende.
var guarda := 0.0
var _guarda_calma := 0.0
var _guarda_trava_t := 0.0
# Rastro da barra de vida: fração que ainda aparece branca e a espera para descer.
var hp_rastro := 1.0
var _rastro_espera := 0.0
var _respingo_t := 0.0  # último respingo de tinta (um a cada 0,2 s por boneco)
var _silence_t := 0.0   # Selo do Onmyoji: sem ataque, botão direito nem poder
var _preso_t := 0.0     # Gancho da Kusarigama: preso na corrente (não anda, não ataca, não esquiva)
var _muralha_t := 0.0   # Muralha de Fé do Sohei: anel que empurra inimigos para fora
var _muralha_pos := Vector3.ZERO
var _ciranda_t := 0.0   # Ciranda de Aço da Kusarigama: corrente girando em volta
var _ciranda_tick := 0.0
var _fury_t := 0.0      # Fúria do Ronin: dano multiplicado
var _gigante := 1.0     # Fúria: o Ronin cresce (poder no corpo); volta a 1 suave
var _dmg_boost_t := 0.0 # item no chão "Dano dobrado"
var _lean := 0.0
# Corpo de desenho (animação exagerada por código, sem mexer nos clipes):
# duas molas amortecidas, uma de esticar/amassar na vertical e outra na
# frente. Golpes, dash, pulo e pancadas só dão "petelecos" de velocidade nelas.
var _sq := 0.0       # vertical: + estica, − amassa
var _sq_v := 0.0
var _st := 0.0       # para a frente (eixo z local do _visual, que gira com o rosto)
var _st_v := 0.0
var _tremor_t := 0.0
var _vy_antes := 0.0
var _no_chao := true
var _windup_t := 0.0  # antecipação: o golpe já começou, o dano ainda não saiu
var _golpe_mult := 1.0
var _golpe_final := false
var _golpe_machado := false  # este clique é machadada (lenhador de longe perto da planta)
var _carga_vista := -1.0  # último poder_carga mandado ao material
var _pecas: MeshInstance3D       # peças do NinjaVisual (refeitas quando o nível visual muda)
var pecas_longe := false         # LOD (Game._lod_bonecos): longe as peças somem
var _nivel_pecas := 1            # caudas da Kitsune Luz/Sombria = nível do mago
var _agito := 0.0                # balanço das peças: 1 no ataque/poder, -1 morto
var _agito_visto := 0.0
var _pose_dash: PoseDash         # braços para trás no dash "ninja"
var _fogo_dash_t := 0.0          # rastro de fogo-raposa enquanto a Kitsune está sumida
var _rolo := 0.0                 # ângulo da cambalhota (dash "rolar"/"rolamento"), 0 = sem rolo
var _rastro_dash_t := 0.0        # faíscas atrás do Bombardeiro no dash de pólvora
var _morte_t := -1.0  # s desde a morte (pulinho cômico); < 0 = vivo
## Construindo uma oficina (marcado pela Oficina a cada quadro).
var building_t := 0.0
var em_voo := false  # na catapulta ou voando: o corpo é da Catapulta, nada acerta

# --- Heróis raros (Ciclo 2.23): estados; as regras ficam em Herois -------------
var _forcado_t := 0.0       # andar forçado (Susto, Hipnose): o corpo ignora o cérebro
var _forcado_de := Vector3.ZERO
var _forcado_afasta := false
var _cego_t := 0.0          # Revoada: a mira do bot desvia; o jogador vê a vinheta
var _sono_t := 0.0          # Canção de Ninar: dormindo (acorda com dano)
var _mudo_t := 0.0          # Réquiem: sem Q, E e R (o golpe continua)
var _canto_t := 0.0         # Komusō tocando a flauta (parado, sem golpe)
var _canto_alvos: Array = []
var _disfarce_t := 0.0      # Mujina com o rosto de outro
var _disfarce_time := -1    # time do rosto roubado (só visual)
var shikigami := 0          # Onmyoji: bonecos de papel em volta (cada um engole um golpe)
var _shiki_no: Node3D
var _dohyo_t := 0.0         # Sumotori: ringue de sal
var _dohyo_pos := Vector3.ZERO
var _danca_t := 0.0         # Tennin: dança em volta dela
var _danca_tick := 0.0
var _ring: MeshInstance3D   # anel do time no chão (o disfarce troca a cor)

# --- Heróis 2.27 (Ochimusha, Shishimai, Jorogumo): estados; regras em Herois ----
var _fantasma_t := 0.0      # Ochimusha não caiu: 1 de vida, intocável, caçando um abate
var _nao_cai_usado := false # uma vez por vida
var _fantasma_quem: Unit = null  # quem deu o golpe (leva o abate se o tempo acabar)
var cargas_q := 0           # Q com cargas (flechas nas costas)
var _carga_q_t := 0.0
var _onibi_n := 0           # fogos-fantasma girando em volta
var _onibi_t := 0.0
var _onibi_no: Node3D
var _sorte_t := 0.0         # Shishimai: Sorte (bits em _sorte_partes: 1 golpe, 2 esquiva)
var _sorte_partes := 0
var _azar_t := 0.0          # Azar: o próximo golpe erra
var _festa_t := 0.0         # Festa da Vila: leão gigante
var _festa_tick := 0.0
var _fio_n := 0             # Jorogumo: fios grudados (cada um deixa mais lento)
var _fio_t := 0.0
var _fio_dono: Unit = null  # quem prendeu/deixou lento (Puxar os Fios só puxa os dela)
var _casulo_t := 0.0        # enrolado no casulo (aliados quebram batendo)
var _casulo_vida := 0
var _casulo_no: Node3D
var _teia_t := 0.0          # dona em cima da própria teia (corre mais)
var _arrastao_t := 0.0      # Shishimai avançando com um inimigo na boca
var _arrastao_dir := Vector3.ZERO
var _arrastao_alvo: Unit = null

static var _flash_mat: StandardMaterial3D
static var _merged_body := {}  # caminho do .tres da classe -> ArrayMesh do corpo
static var _upper_libs := {}  # caminho do modelo -> AnimationLibrary filtrada
static var _shield_res: Array = []  # [malha, material] compartilhados da bolha de escudo


func setup(p_game: Game, p_team: int, p_is_player: bool, start_class: ClassStats) -> void:
	game = p_game
	team = p_team
	is_player = p_is_player
	collision_layer = Config.LAYER_UNITS
	collision_mask = Config.LAYER_WORLD | Config.LAYER_PASSAGEM
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.6
	capsule.height = 2.2
	shape.shape = capsule
	shape.position.y = 1.1
	add_child(shape)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_build_team_ring()
	_build_hp_bar()
	_cake_visual = Cake.make_visual(0.45)
	_cake_visual.position = Vector3(0, 2.75, 0)
	_cake_visual.visible = false
	add_child(_cake_visual)
	if is_player:
		_build_player_marker()

	nav_agent = NavigationAgent3D.new()
	nav_agent.path_desired_distance = 1.2
	nav_agent.target_desired_distance = 1.0
	nav_agent.radius = 0.8
	add_child(nav_agent)

	if _flash_mat == null:
		_flash_mat = Fx.unshaded(Color(1, 1, 1, 0.75), true)
	set_class(start_class)


func set_class(new_stats: ClassStats) -> void:
	_super_t = 0.0
	guarda = 0.0
	_guarda_trava_t = 0.0
	_stats_normal = null
	if _sombra_t > 0.0:
		_fim_sombra()
	Herois.trocou_classe(self)
	stats = new_stats
	if not lenhador():
		drop_tora()
	hp = max_hp()  # trocar de chapéu cura por completo
	_montar_modelo(stats, team)
	_update_hp_bar()
	class_changed.emit(self)


## Corpo, peças e animação de `cls` na cor do time `cor_time`. Separado do
## set_class para o disfarce da Mujina (Ciclo 2.23) trocar só o visual.
func _montar_modelo(cls: ClassStats, cor_time: int) -> void:
	var cor := Config.team_color(cor_time)
	if _model:
		_model.queue_free()
	_mao_no = null
	_model = cls.model.instantiate()
	_visual.add_child(_model)
	_meshes.clear()
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.visible = cls.visible_meshes.has(mi.name)
		if mi.visible:
			_meshes.append(mi)
		if mi.name == cls.cape_mesh:
			var mat := mi.get_active_material(0).duplicate() as StandardMaterial3D
			if mat:
				mat.albedo_color = cor.lightened(0.15)
				mi.material_override = mat
	_merge_body_parts()
	_pecas = null
	_nivel_pecas = game.nivel_visual_mago(cor_time, cls.id) if game else 1
	if cls.estilo_ninja != "" or cls.escala_cabeca != 1.0:
		_pecas = NinjaVisual.aplicar(_model, _meshes, cls.estilo_ninja, cor, cls.escala_cabeca, Settings.quality >= 2, cls.escala_extremidades, _nivel_pecas, Settings.quality >= 3)
		if _pecas:
			_meshes.append(_pecas)
			_pecas.visible = not pecas_longe
	_pose_dash = null
	_rolo = 0.0
	if cls.dash_estilo == "ninja":
		var sk := _model.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk:
			_pose_dash = PoseDash.new()
			sk.add_child(_pose_dash)
	_model.scale = Vector3.ONE * cls.escala_modelo
	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for a in LOOPING_ANIMS + [stats.anim_idle, stats.anim_run]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_setup_upper_player()
	_current_anim = ""
	_play(stats.anim_idle)
	for mi in _meshes:
		mi.set_instance_shader_parameter("cor_poder", cls.hat_color)
	_carga_vista = -1.0
	_agito_visto = 99.0
	if _ring:
		var c := Config.team_color(cor_time)
		if is_player:
			c = c.lerp(Color(1, 1, 0.6), 0.45)
		_ring.material_override = Fx.unshaded(Color(c, 0.85), true)


## LOD (Ciclo 2.19): longe do jogador, as peças pequenas (armadura, cachecol,
## caudas) e o raio-X delas somem; corpo, chapéu e cor do time ficam. A essa
## distância um boneco tem poucos pixels e as peças custavam 2-4 chamadas de
## desenho cada (cor + raio-X + sombra).
func set_pecas_longe(longe: bool) -> void:
	if longe == pecas_longe:
		return
	pecas_longe = longe
	if _pecas:
		_pecas.visible = not longe


## Nível visual das peças (caudas da Kitsune Luz/Sombria = nível do mago dela).
func _nivel_visual() -> int:
	return game.nivel_visual_mago(team, stats.id) if game and stats else 1


## O mago do time subiu de nível: refaz só a malha de peças (mais caudas, halo
## e coroa maiores), sem trocar de classe nem curar.
func atualizar_nivel_visual() -> void:
	var n := _nivel_visual()
	if _model == null or _pecas == null or n == _nivel_pecas:
		return
	var sk := _pecas.get_parent() as Skeleton3D
	var novo := NinjaVisual.pecas(sk, _pecas.skin, stats.estilo_ninja, NinjaVisual.cor_neon(Config.team_color(team)), Settings.quality >= 2, n, Settings.quality >= 3)
	if novo == null:
		return
	_meshes.erase(_pecas)
	_pecas.queue_free()
	_pecas = novo
	_meshes.append(novo)
	novo.visible = not pecas_longe
	_nivel_pecas = n
	novo.set_instance_shader_parameter("cor_poder", stats.hat_color)
	_carga_vista = -1.0
	_agito_visto = 99.0
	_tick_aura()


# --- Chapéu: pegar e pôr na cabeça --------------------------------------------

func is_equipping() -> bool:
	return _equip_t > 0.0


## Começa a troca de classe: o chapéu sai do pedestal, sobe acima da cabeça e
## desce nela enquanto os braços fazem o gesto. A classe só muda no fim.
func start_equip(new_stats: ClassStats, from_world: Vector3) -> void:
	_cancel_equip()
	_equip_stats = new_stats
	_equip_t = EQUIP_TIME
	_equip_hat = HatPad.make_hat(new_stats.hat_style, new_stats.hat_color)
	_equip_hat.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	add_child(_equip_hat)
	_equip_hat.global_position = from_world
	_equip_hat.scale = Vector3.ONE * 0.8
	var tw := _equip_hat.create_tween()
	tw.tween_property(_equip_hat, "position", Vector3(0, 3.4, 0), EQUIP_TIME * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_equip_hat, "rotation:y", TAU, EQUIP_TIME * 0.6)
	tw.tween_property(_equip_hat, "position", Vector3(0, 2.3, 0), EQUIP_TIME * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var raise := _upper_anim("Spellcast_Raise")
	if raise != "":
		_upper.play(raise, 0.1, _upper.get_animation(raise).length / EQUIP_TIME)
	Sfx.play("pickup", global_position)


func _finish_equip() -> void:
	var new_stats := _equip_stats
	_cancel_equip()
	if new_stats == null or not alive:
		return
	set_class(new_stats)
	Fx.ring(game, global_position, new_stats.hat_color, 2.5)
	Sfx.play("hat", global_position)


func _cancel_equip() -> void:
	_equip_t = 0.0
	_equip_stats = null
	if is_instance_valid(_equip_hat):
		_equip_hat.queue_free()
	_equip_hat = null
	if _upper:
		_upper.stop()


## Cria um segundo AnimationPlayer com cópias das animações filtradas para os
## ossos do tronco. Ele roda depois do principal e sobrescreve só esses ossos.
func _setup_upper_player() -> void:
	var key: String = stats.model.resource_path
	var lib: AnimationLibrary = _upper_libs.get(key)
	if lib == null:
		lib = AnimationLibrary.new()
		_upper_libs[key] = lib
	_upper = AnimationPlayer.new()
	_upper.name = "TroncoPlayer"
	_anim.get_parent().add_child(_upper)
	_upper.root_node = _upper.get_path_to(_anim.get_node(_anim.root_node))
	_upper.add_animation_library("tronco", lib)


## Nome "tronco/<anim>" da cópia filtrada (criada na primeira vez que é pedida).
func _upper_anim(anim_name: String, loop := false) -> String:
	if _upper == null or not _anim.has_animation(anim_name):
		return ""
	var lib := _upper.get_animation_library("tronco")
	if not lib.has_animation(anim_name):
		var a := _anim.get_animation(anim_name).duplicate() as Animation
		a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
		for t in range(a.get_track_count() - 1, -1, -1):
			var bone := str(a.track_get_path(t).get_concatenated_subnames())
			if not UPPER_BONES.has(bone):
				a.remove_track(t)
		lib.add_animation(anim_name, a)
	return "tronco/" + anim_name


## Toca uma animação só no tronco: as pernas continuam correndo.
func _play_upper(anim_name: String, speed := 1.0, loop := false) -> void:
	var key := _upper_anim(anim_name, loop)
	if key == "":
		return
	if loop and _upper.is_playing() and _upper.current_animation == key:
		return
	_upper.play(key, 0.05, speed)
	if not loop:
		_upper.seek(0.0, true)


func _stop_upper(anim_name: String) -> void:
	if _upper and _upper.current_animation == "tronco/" + anim_name:
		_upper.stop()


# --- Desempenho ---------------------------------------------------------------

## Os personagens KayKit vêm com o corpo em 6 malhas (braços, pernas, tronco,
## cabeça) que usam o mesmo esqueleto e o mesmo material. Juntá-las numa malha
## só troca 6 chamadas de desenho por 1, por personagem e por passe de sombra.
func _merge_body_parts() -> void:
	var parts: Array[MeshInstance3D] = []
	for mi in _meshes:
		if mi.skin != null and mi.material_override == null and mi.get_parent() is Skeleton3D:
			parts.append(mi)
	if parts.size() < 2:
		return
	for mi in parts:
		if mi.skin != parts[0].skin or mi.mesh.get_surface_count() != 1:
			return
	var key := stats.resource_path
	var merged: ArrayMesh = _merged_body.get(key)
	if merged == null:
		merged = _merge_meshes(parts)
		if merged == null:
			return
		_merged_body[key] = merged
	parts[0].mesh = merged
	for i in range(1, parts.size()):
		parts[i].visible = false
		_meshes.erase(parts[i])


static func _merge_meshes(parts: Array[MeshInstance3D]) -> ArrayMesh:
	var fmt: int = parts[0].mesh.surface_get_format(0)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var offset := 0
	for mi in parts:
		var a := mi.mesh.surface_get_arrays(0)
		if a[Mesh.ARRAY_INDEX] == null:
			return null
		for k in Mesh.ARRAY_MAX:
			if (a[k] == null) != (out[k] == null) and offset > 0:
				return null  # formatos diferentes: não dá para juntar
			if a[k] == null:
				continue
			var arr = a[k]
			if k == Mesh.ARRAY_INDEX:
				arr = arr.duplicate()
				for i in arr.size():
					arr[i] += offset
			if out[k] == null:
				out[k] = arr.duplicate()
			else:
				out[k].append_array(arr)
		offset += a[Mesh.ARRAY_VERTEX].size()
	var mesh := ArrayMesh.new()
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS else 0
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out, [], {}, flags)
	mesh.surface_set_material(0, parts[0].mesh.surface_get_material(0))
	return mesh


func is_villager() -> bool:
	return stats == Config.cfg.villager


## Kitsunes (aprendiz e os caminhos Luz/Sombria): reanimam mais rápido.
func eh_mago() -> bool:
	return stats != null and (stats.id == &"kitsune" or stats.classe_base == &"kitsune")


## Começou a reanimar (Reanimar.comecar): larga golpe/carga pela metade.
func comecar_reanimar() -> void:
	_windup_t = 0.0
	_cancel_skill()
	_blocking = false
	_anim_lock = 0.0


## Parou de reanimar: solta a pose de puxar.
func parar_reanimar() -> void:
	_stop_upper("Use_Item")
	_current_anim = ""


## Pode atacar/usar habilidade agora (sem máscara nem tora nos braços, fora
## do dash, do chapéu, do Redemoinho e do Selo).
func maos_livres() -> bool:
	return not carried_princess and not carried_tora and _dodge_t <= 0.0 and _equip_t <= 0.0 \
			and _spin_t <= 0.0 and _silence_t <= 0.0 and _preso_t <= 0.0 and _ciranda_t <= 0.0 \
			and _sono_t <= 0.0 and _forcado_t <= 0.0 and _canto_t <= 0.0 and _casulo_t <= 0.0


## Corta madeira (Construtor e variações: quem tem velocidade_obra).
func lenhador() -> bool:
	return stats.velocidade_obra > 0.0


## Alcance da machadada (corte de planta). Quem ataca de longe (Bombardeiro)
## usa o alcance do Construtor: perto da planta, o clique vira machadada.
const MACHADO_ALCANCE := 2.6
const MACHADO_ARCO := 120.0
func alcance_corte() -> float:
	return stats.attack_range if stats.attack_kind == "melee" else MACHADO_ALCANCE


## O próximo clique corta planta em vez do ataque normal? Só para lenhador que
## não é corpo a corpo (o corpo a corpo já corta dentro do próprio golpe).
func clique_vira_machadada(dir: Vector3) -> bool:
	return lenhador() and stats.attack_kind != "melee" \
			and game.planta_no_alcance(self, dir, MACHADO_ALCANCE + 0.6, MACHADO_ARCO) != null


func drop_tora() -> void:
	if carried_tora:
		carried_tora.largar()


func hp_ratio() -> float:
	return hp / max_hp()


## No meio de um golpe (antecipação ou animação): para os bots lerem o combo.
func atacando() -> bool:
	return _attack_t > 0.0 or _windup_t > 0.0


func dash_pronto() -> bool:
	return _dodge_cd <= 0.0 and _dodge_t <= 0.0 and not carried_princess


## Vida máxima de verdade: a da classe vezes GameConfig.vida_mult.
func max_hp() -> float:
	return stats.max_hp * Config.cfg.vida_mult * (1.0 + Config.cfg.mago_bonus_vida * _nivel_mago()) \
			* (Config.cfg.heroi_vida_mult if stats.heroi else 1.0)


## Níveis acima do 2 do caminho dos magos, se este soldado é o mago escolhido.
func _nivel_mago() -> int:
	return game.bonus_mago(team, stats.id) if game and stats else 0


## Aliados vivos colados em quem carrega a máscara (até escolta_max).
func escolta() -> int:
	if carried_princess == null or game == null:
		return 0
	var n := 0
	var r2 := Config.cfg.escolta_raio * Config.cfg.escolta_raio
	for o in game.units:
		if o != self and o.alive and o.team == team and o.global_position.distance_squared_to(global_position) <= r2:
			n += 1
	return mini(n, Config.cfg.escolta_max)


## Fração de velocidade que a escolta dá a quem carrega: o primeiro aliado
## vale escolta_vel, cada um a mais soma escolta_vel_extra (Ciclo 2.25).
func escolta_bonus() -> float:
	var n := escolta()
	return 0.0 if n == 0 else Config.cfg.escolta_vel + Config.cfg.escolta_vel_extra * (n - 1)


func current_speed() -> float:
	var s := stats.move_speed
	if carried_princess:
		var cfg := Config.cfg
		s *= minf(stats.carry_speed_mult + cfg.carregar_bonus, 1.0) * (1.0 - carried_princess.fatness * cfg.fat_slowdown)
	if lenhador():
		# Cada casinha erguida pelo time deixa a linha do Construtor mais rápida.
		s *= 1.0 + Config.cfg.construtor_vel_por_oficina * game.oficinas_prontas(team)
	if carried_tora:
		s *= Config.cfg.tora_vel_mult
	if _boost_t > 0.0:
		s *= _boost_mult
	if _slow_t > 0.0:
		s *= _slow_mult
	if _sombra_t > 0.0:
		s *= Config.cfg.sombra_vel
	if _preso_t > 0.0:
		s *= 0.1
	if _sono_t > 0.0 or _canto_t > 0.0 or _casulo_t > 0.0:
		s = 0.0
	if _teia_t > 0.0:
		s *= Config.cfg.teia_vel
	if _ciranda_t > 0.0:
		s *= Config.cfg.ciranda_vel_mult
	if _tiro_lento_t > 0.0:
		s *= Config.cfg.atirador_lento_mult
	if game:
		if carried_princess:
			s *= 1.0 + escolta_bonus()
		elif _em_escolta():
			s *= 1.0 + Config.cfg.escolta_vel
	return s


## Golpe pelas costas ou pelo lado (ClassStats.dano_costas): o alvo não está
## de frente para quem bate. to = de quem bate para o alvo; de frente,
## facing·to ≈ −1; de lado ≈ 0; de costas ≈ +1. Limite −0,25 (~105°).
func mult_costas(other: Unit, to: Vector3) -> float:
	if stats.dano_costas <= 0.0 or to.length_squared() < 1e-6:
		return 1.0
	return 1.0 + stats.dano_costas if other._facing().dot(to.normalized()) > -0.25 else 1.0


## Escolta: carregando a máscara com um aliado perto, ou perto do aliado que
## carrega. Junta o time em volta do carregador (o ponto vem de grupo).
func _em_escolta() -> bool:
	if carried_princess:
		return escolta() > 0
	var r2 := Config.cfg.escolta_raio * Config.cfg.escolta_raio
	var p: Princess = game.princesses[1 - team] if game.princesses.size() == 2 else null
	return p != null and p.carrier != null and p.carrier != self and p.carrier.team == team \
			and p.carrier.global_position.distance_squared_to(global_position) < r2


func power_ready() -> bool:
	return power >= POWER_MAX and stats.power != "nenhum"


## Carga do tiro (0 a 1).
func charge_ratio() -> float:
	return clampf(_charge_t / maxf(stats.charge_time, 0.01), 0.0, 1.0)


## Soma ao medidor de Glacê. Enquanto o próprio poder age, nada entra
## (senão o Redemoinho se recarregaria sozinho).
func add_power(amount: float) -> void:
	if amount <= 0.0 or _power_active_t > 0.0 or not alive:
		return
	var was_ready := power >= POWER_MAX
	if stats.heroi:
		amount /= maxf(Config.cfg.heroi_recarga_mult, 0.1)
	power = minf(power + amount * (1.0 + Config.cfg.mago_bonus_chi * _nivel_mago()), POWER_MAX)
	_power_idle = 0.0
	if is_player and not was_ready and power >= POWER_MAX and stats.power != "nenhum":
		Sfx.play_ui("power_ready")
		game.hud.show_big("Chi cheio! E: %s" % stats.power_name, Color(1, 0.75, 0.9), 1.4)


# --- Loop principal -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not alive:
		# Quem morre no ar cai (sem isso o corpo ficava parado no ar).
		if not is_on_floor():
			velocity = Vector3(0, velocity.y - 30.0 * delta, 0)
			move_and_slide()
		_tick_corpo(delta, Vector3.ZERO)
		_tick_aura()
		_respawn_t -= delta * (game.reanimar.ritmo(self) if game.reanimar else 1.0)
		if _respawn_t <= 0.0:
			_respawn()
		return

	if em_voo:
		# A catapulta move o corpo (Catapulta._physics_process); as recargas
		# seguem correndo no ar (antes congelavam os 2,4 s do voo).
		_attack_cd = maxf(_attack_cd - delta, 0.0)
		_heal_cd = maxf(_heal_cd - delta, 0.0)
		_dodge_cd = maxf(_dodge_cd - delta, 0.0)
		_quick_cd = maxf(_quick_cd - delta, 0.0)
		_tick_power(delta)
		_tick_guarda(delta)
		return
	_tick_rastro(delta)
	_tick_guarda(delta)

	# Hitstop: no impacto de um golpe, atacante e alvo congelam por ~60 ms.
	# É o Δt do contato (J = F·Δt) ficando visível; o empurrão sai depois.
	if _hitstop_t > 0.0:
		_hitstop_t -= delta
		if _hitstop_t <= 0.0:
			_set_anim_speed(1.0)
		_tick_corpo(delta, Vector3.ZERO, true)  # a pose congela, o tremor não
		return

	if brain and brain.has_method("tick"):
		var t0 := Time.get_ticks_usec() if game._perf else 0
		brain.tick(delta)
		if game._perf:
			game.perf_secoes["cerebro"] = game.perf_secoes.get("cerebro", 0) + Time.get_ticks_usec() - t0
	if _forcado_t > 0.0 or _sono_t > 0.0 or _casulo_t > 0.0:
		Herois.corpo_sem_cerebro(self)

	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_heal_cd = maxf(_heal_cd - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_attack_t = maxf(_attack_t - delta, 0.0)
	_combo_t = maxf(_combo_t - delta, 0.0)
	_power_active_t = maxf(_power_active_t - delta, 0.0)
	if _intocavel_t > 0.0:
		_intocavel_t -= delta
		if Engine.get_physics_frames() % 6 == 0:
			Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.85, 0.45), 2, 1.2)
	_tick_power(delta)
	_tick_buffs(delta)

	if wants_dodge and _dodge_cd <= 0.0 and not carried_princess and _spin_t <= 0.0 and _ciranda_t <= 0.0 and _preso_t <= 0.0 and _sono_t <= 0.0 and _canto_t <= 0.0 and _casulo_t <= 0.0:
		_start_dodge()
	wants_dodge = false

	if _pose_dash:
		_pose_dash.peso = move_toward(_pose_dash.peso, 1.0 if _dodge_t > 0.0 else 0.0, delta * 9.0)
	if _fogo_dash_t > 0.0:
		_fogo_dash_t -= delta
		if Engine.get_physics_frames() % 3 == 0:
			var cor := Color(1.0, 0.85, 0.4) if stats.estilo_ninja == "_kitsune_luz" else (Color(0.65, 0.3, 1.0) if stats.estilo_ninja == "_kitsune_sombria" else stats.hat_color)
			Fx.burst(game, global_position + Vector3(0, 0.9, 0), cor, 3, 1.2)
	if _rastro_dash_t > 0.0:
		_rastro_dash_t -= delta
		if Engine.get_physics_frames() % 2 == 0:
			Fx.burst(game, global_position + Vector3(0, 0.5, 0) - _dodge_dir * 0.4, Color(1.0, 0.6, 0.2), 2, 1.8)
	if _dodge_t > 0.0:
		_dodge_t -= delta
		_move_vel = _dodge_dir * DODGE_SPEED
		if _dodge_t <= 0.0:
			_mola(-5.0, -4.0)  # "pouso" do dash: amassa e devolve o esticão
			_fim_dash()
	else:
		var speed := current_speed()
		if reanimando:
			# Kitsune abençoa parada; o resto arrasta o corpo devagar.
			speed *= 0.0 if eh_mago() else Config.cfg.reanimar_arrasto_vel
		elif _spin_t > 0.0:
			speed *= 0.75
		elif _anim_lock > 0.0:
			speed *= 0.55  # levando golpe
		elif _blocking:
			speed *= 0.5
		elif _charge_t > 0.0:
			speed *= 0.6
		elif _attack_t > 0.0:
			speed *= 0.8  # o golpe sai do tronco: dá para bater correndo
		var target := move_intent.limit_length(1.0) * speed + _separation() * 3.0
		_move_vel = _move_vel.move_toward(target, ACCEL * delta)
	# O empurrão entra só na velocidade final. Antes ele era somado à própria
	# velocidade do quadro anterior, ou seja, integrado de novo a cada quadro:
	# um golpe de guerreiro jogava o alvo ~45 m em vez de ~1 m.
	var horizontal := _move_vel + _knock
	_knock = _knock.move_toward(Vector3.ZERO, KNOCK_DECAY * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if _launch_vy > 0.0:
		velocity.y = _launch_vy  # lançado: sobe com v0 e cai com g = 30 m/s²
		_mola(minf(_launch_vy, 8.0), 0.0)  # sai do chão esticado
		_launch_vy = 0.0
	else:
		velocity.y = 0.0 if is_on_floor() else velocity.y - 30.0 * delta
	_vy_antes = velocity.y
	var t1 := Time.get_ticks_usec() if game._perf else 0
	move_and_slide()
	if game._perf:
		game.perf_secoes["fisica_corpo"] = game.perf_secoes.get("fisica_corpo", 0) + Time.get_ticks_usec() - t1
	# Pouso: amassa proporcional à velocidade de queda (o "impulso" do chão).
	var no_chao := is_on_floor()
	if no_chao and not _no_chao and _vy_antes < -2.0:
		_mola(-minf(-_vy_antes * 0.6, 8.0), 0.0)
	_no_chao = no_chao
	global_position = game.arena.clamp_to_arena(global_position)

	_face(delta)
	if _equip_t > 0.0:
		_equip_t -= delta
		if _equip_t <= 0.0:
			_finish_equip()
	var free_hands := maos_livres()
	_update_skill(delta, free_hands)
	if wants_power:
		wants_power = false
		if _silence_t <= 0.0 and _mudo_t <= 0.0 and _sono_t <= 0.0 and _forcado_t <= 0.0:
			_use_power()
	if wants_super:
		wants_super = false
		if _silence_t <= 0.0 and _mudo_t <= 0.0 and _sono_t <= 0.0 and _forcado_t <= 0.0:
			_use_super()
	_tick_super(delta)
	if _windup_t > 0.0:
		_windup_t -= delta
		if _windup_t <= 0.0:
			if free_hands:
				_attack_hit()
	elif wants_attack and _attack_cd <= 0.0 and free_hands and not _blocking and _charge_t <= 0.0 and reanimando == null:
		_attack()
	var t2 := Time.get_ticks_usec() if game._perf else 0
	_animate(horizontal)
	_tick_corpo(delta, horizontal)
	_tick_aura()
	if game._perf:
		game.perf_secoes["animacao"] = game.perf_secoes.get("animacao", 0) + Time.get_ticks_usec() - t2
	_update_flash(delta)
	_cake_visual.visible = has_cake
	if has_cake:
		_cake_visual.rotation.y += delta * 2.0


func _face(delta: float) -> void:
	var look := Vector3.ZERO
	if _dodge_t > 0.0:
		look = _dodge_dir
	elif reanimando and is_instance_valid(reanimando):
		look = reanimando.global_position - global_position
		look.y = 0.0
	elif is_player or _anim_lock > 0.0 or _attack_t > 0.0 or _blocking or _charge_t > 0.0 or wants_attack:
		look = aim_dir
	elif move_intent.length() > 0.1:
		look = move_intent
	if look.length() > 0.01:
		var target_yaw := atan2(look.x, look.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, 1.0 - exp(-18.0 * delta))


func _separation() -> Vector3:
	# Empurrãozinho entre aliados para não se amontoarem no mesmo ponto.
	var push := Vector3.ZERO
	for other in game.units:
		if other == self or not other.alive or other.team != team:
			continue
		var d := global_position - other.global_position
		d.y = 0
		var dist := d.length()
		if dist < 1.5 and dist > 0.001:
			push += d / dist * (1.5 - dist)
	return push


# --- Ações --------------------------------------------------------------------

func _start_dodge() -> void:
	_dodge_dir = move_intent.normalized() if move_intent.length() > 0.1 else aim_dir.normalized()
	_dodge_t = DODGE_TIME
	_dodge_cd = DODGE_COOLDOWN
	_cancel_skill()
	if _upper:
		_upper.stop()
	Sfx.play("dodge", global_position)
	_windup_t = 0.0  # o dash cancela um golpe que ainda não saiu
	# Personalidade do dash (ClassStats.dash_estilo): só o visual muda.
	match stats.dash_estilo:
		"ninja":
			_play_once("Running_B", DODGE_TIME + 0.1, 1.8)
			_mola(-1.0, 10.0)
		"chama", "fantasma":
			_play_once("Dodge_Forward", DODGE_TIME + 0.1)
			_fogo_dash(true)
		"rolar", "rolamento":
			# Cambalhota de verdade: o corpo gira 360° em _animate (_rolo).
			_play_once("Jump_Idle", DODGE_TIME + 0.1)
			_rolo = 0.001
			_mola(-2.5 if stats.dash_estilo == "rolar" else -1.2, 4.0)
		"polvora":
			# Bombardeiro: estouro de pólvora atrás, vai de foguete inclinado para trás.
			_play_once("Jump_Idle", DODGE_TIME + 0.1)
			_mola(-1.0, -6.0)
			Fx.burst(game, global_position + Vector3(0, 0.6, 0) - _dodge_dir * 0.5, Color(1.0, 0.55, 0.15), 14, 5.0)
			Fx.burst(game, global_position + Vector3(0, 0.6, 0) - _dodge_dir * 0.5, Color(0.35, 0.33, 0.3), 8, 2.5)
			_rastro_dash_t = DODGE_TIME
		"tropeco":
			# Construtor carrega tralha demais: dispara quase caindo para a frente.
			_play_once("Running_B", DODGE_TIME + 0.1, 2.2)
			_mola(-2.0, 14.0)
		_:
			_play_once("Dodge_Forward", DODGE_TIME + 0.1)
			_mola(-1.5, 8.0)  # esticão na direção do dash
	if stats.dash_peca:
		Herois.dash_peca(self, true)


## Pouso do dash por personalidade.
func _fim_dash() -> void:
	_rastro_dash_t = 0.0
	if stats.dash_peca:
		Herois.dash_peca(self, false)
	match stats.dash_estilo:
		"chama", "fantasma":
			_fogo_dash(false)
		"rolar":
			# Tanque caindo do rolamento: amassa mais, levanta pó e treme o chão.
			_mola(-6.0, 0.0)
			Fx.burst(game, global_position + Vector3(0, 0.2, 0), Color(0.62, 0.55, 0.45), 12, 3.5)
			if game and game.camera and self == game.player:
				game.camera.shake_at(global_position, 0.18)
		"rolamento":
			# Levanta da cambalhota com um pulinho curto e um tufo de poeira.
			_mola(-3.5, -3.0)
			Fx.burst(game, global_position + Vector3(0, 0.2, 0), Color(0.62, 0.55, 0.45), 6, 2.2)
		"tropeco":
			# Quase cai: amassa forte e solta um "uf" de poeira para a frente.
			_mola(-5.0, 6.0)
			Fx.burst(game, global_position + Vector3(0, 0.25, 0) + _dodge_dir * 0.4, Color(0.62, 0.55, 0.45), 8, 2.5)


## Kitsune no dash: o corpo vira um lampejo de fogo-raposa e reaparece no fim.
## Só esconde o modelo (o _visual continua com o Passo da Sombra e o chapéu).
func _fogo_dash(sumir: bool) -> void:
	if _model == null:
		return
	var cor := stats.hat_color.lightened(0.2)
	if stats.dash_estilo == "fantasma":
		cor = Color(0.55, 0.78, 1.0)  # Ochimusha: desfaz em cinza azul e volta
	if stats.estilo_ninja == "_kitsune_luz":
		cor = Color(1.0, 0.85, 0.4)
	elif stats.estilo_ninja == "_kitsune_sombria":
		cor = Color(0.65, 0.3, 1.0)
	Fx.burst(game, global_position + Vector3(0, 1.0, 0), cor, 16 if sumir else 10, 4.5 if sumir else 3.0)
	_model.visible = not sumir
	_fogo_dash_t = DODGE_TIME if sumir else 0.0


func _attack() -> void:
	_attack_cd = stats.attack_cooldown
	_agito = 1.0
	var anim := stats.anim_attack
	var mult := 1.0
	var finisher := false
	var combo := stats.combo_anims
	_golpe_machado = clique_vira_machadada(aim_dir.normalized())
	if _golpe_machado:
		anim = "1H_Melee_Attack_Chop"
		_attack_cd = 0.7
		combo = []
	if combo.size() > 0:
		_combo_i = (_combo_i + 1) % combo.size() if _combo_t > 0.0 else 0
		anim = combo[_combo_i]
		finisher = _combo_i == combo.size() - 1
		if finisher:
			mult = stats.combo_finisher_mult
			_attack_cd *= 1.2
		else:
			_attack_cd *= 0.85
		_combo_t = _attack_cd + COMBO_WINDOW
	elif stats.combo_tiros > 0 and stats.attack_kind != "melee":
		# Tiro: 1, 2 e o 3º é o forte (leque de shurikens ou bola que explode).
		_combo_i = (_combo_i + 1) % stats.combo_tiros if _combo_t > 0.0 else 0
		finisher = _combo_i == stats.combo_tiros - 1
		if finisher:
			mult = stats.combo_finisher_mult
			_attack_cd *= 1.3
		_combo_t = _attack_cd + COMBO_WINDOW
	_attack_t = minf(_attack_cd, 0.45)
	_play_upper(anim, 1.35)
	if _cego_t > 0.0 and not is_player:
		aim_dir = aim_dir.rotated(Vector3.UP, deg_to_rad(randf_range(-35.0, 35.0)))
	if _disfarce_t > 0.0:
		mult *= Config.cfg.mujina_golpe_mult  # golpe saindo do rosto roubado
		finisher = true
		Herois.tirar_rosto(self)
	if _sombra_t > 0.0:
		# Golpe de surpresa saindo da sombra.
		mult *= Config.cfg.sombra_golpe_mult
		finisher = true
		_fim_sombra()
	_golpe_mult = mult
	_golpe_final = finisher
	# Antecipação: o corpo encolhe e recua um instante antes do dano sair
	# (≤ 50 ms, para o controle não ficar "mole").
	_windup_t = Config.cfg.antecipacao_golpe if _exagero() > 0.0 else 0.0
	_mola(-3.0, -3.5)
	if _windup_t <= 0.0:
		_attack_hit()


## O golpe sai de fato (depois da antecipação): dano, projétil, efeitos.
func _attack_hit() -> void:
	_windup_t = 0.0
	var mult := _golpe_mult
	var finisher := _golpe_final
	var combo := stats.combo_anims
	var forte := 1.4 if finisher else 1.0
	_mola(2.0 * forte, 7.0 * forte)  # estica para a frente no golpe
	var dir := aim_dir.normalized()
	if _golpe_machado:
		_golpe_machado = false
		Sfx.play("swing", global_position, 0.12)
		Fx.slash(game, global_position + Vector3(0, 1.0, 0), dir, MACHADO_ALCANCE + 0.3, MACHADO_ARCO, Color(1, 1, 1), 0.0, false)
		if game.golpear_plantas(self, dir, MACHADO_ALCANCE + 0.6, MACHADO_ARCO):
			hitstop(Config.cfg.hitstop_time)
			if is_player:
				game.camera.add_trauma(0.25)
				game.camera.kick(dir, 0.3)
		return
	match stats.attack_kind:
		"melee":
			Sfx.play("swing", global_position, 0.12, 0.85 if finisher else 1.0)
			if finisher and Sfx.has(stats.som_golpe_final):
				Sfx.play(stats.som_golpe_final, global_position, 0.05)
			# Golpes alternam a inclinação do corte; o último é maior e dourado.
			var tilt := 0.0 if combo.size() == 0 else (22.0 if _combo_i % 2 == 0 else -22.0)
			var col := Color(1.0, 0.78, 0.25) if finisher else Color(1, 1, 1)
			var reach := stats.attack_range + (0.9 if finisher else 0.3)
			# O golpe final do combo desce na vertical: mais dano, faixa estreita
			# à frente (arco × final_arco_mult) e um pouco mais de alcance.
			var arco := stats.attack_arc_deg
			var alcance := stats.attack_range + 0.6
			var giro := finisher and stats.final_giro
			if giro:
				# Kusarigama: o último elo gira a corrente em volta do corpo (360°),
				# um pouco mais curto que a estocada reta.
				arco = 360.0
				alcance = stats.attack_range * 0.8 + 0.6
				Fx.slash(game, global_position + Vector3(0, 0.9, 0), dir, alcance, 360.0, col, 0.0, true)
				FxPoder.giro_corrente(self, alcance)
			elif finisher and combo.size() > 0:
				arco *= Config.cfg.final_arco_mult
				alcance += 0.5
				Fx.slash(game, global_position + Vector3(0, 1.1, 0) + dir * 0.3, dir, reach + 0.4, 150.0, col, 88.0, true)
				FxProjetil.marca_chao(game, global_position + dir * (stats.attack_range * 0.8), Color(0.15, 0.1, 0.05, 0.45), 1.0, 1.2)
			else:
				Fx.slash(game, global_position + Vector3(0, 1.0, 0), dir, reach, stats.attack_arc_deg + (30.0 if finisher else 0.0), col, tilt, finisher)
			FxPoder.fita_lamina(self, finisher)
			var hit_any := false
			if finisher and stats.eco_corte > 0.0 and combo.size() > 0:
				Herois.eco(self, dir, alcance, arco, stats.damage * mult * damage_mult() * stats.eco_corte)
			for other in game.units:
				if other.alive and other.team == team and other._casulo_t > 0.0 and other != self:
					var tc := other.global_position - global_position
					tc.y = 0
					if tc.length() <= alcance + 0.3:
						Herois.bater_casulo(other, self)
						hit_any = true
					continue
				if not other.alive or other.team == team:
					continue
				var to := other.global_position - global_position
				if absf(to.y) > 1.8:  # um em cima da muralha, outro embaixo
					continue
				to.y = 0
				if to.length() > alcance:
					continue
				if to.length() > 0.8 and rad_to_deg(dir.angle_to(to.normalized())) > arco / 2.0:
					continue
				# Sohei: a lâmina da naginata fica na ponta. Colado demais, o cabo só
				# empurra (sem dano); o golpe final, de cima para baixo, acerta perto.
				if stats.alcance_min > 0.0 and to.length() < stats.alcance_min and not (finisher and combo.size() > 0):
					var dir_emp := to.normalized() if to.length() > 0.1 else dir
					other._knock = dir_emp * stats.knockback * 0.7
					Fx.burst(game, other.global_position + Vector3(0, 1.0, 0), Color(0.85, 0.8, 0.7), 4, 3.0)
					hit_any = true
					continue
				var costas := mult_costas(other, to)
				if costas > 1.0:
					Fx.burst(game, other.global_position + Vector3(0, 1.3, 0), Color(1, 0.85, 0.35), 6, 4.0)
					Sfx.play("corte_critico", other.global_position, 0.06)
				other.take_damage(stats.damage * mult * damage_mult() * costas, self, to.normalized(), mult, true)
				if finisher:
					other.launch(3.5)  # golpe final tira o alvo do chão
				hit_any = true
			if lenhador() and game.golpear_plantas(self, dir, stats.attack_range + 0.6, stats.attack_arc_deg):
				hit_any = true
			if game.golpear_torretas(self, dir, alcance, arco, stats.damage * mult * damage_mult()):
				hit_any = true
			if hit_any:
				hitstop(Config.cfg.hitstop_time * (1.6 if finisher else 1.0))
				if is_player:
					game.camera.add_trauma(0.4 if finisher else 0.25)
					game.camera.kick(dir, 0.6 if finisher else 0.3)
					if finisher:
						game.camera.punch_fov(2.5)
		"ranged":
			if finisher and stats.projetil == "shuriken":
				_leque_final()
			else:
				var p := _shoot_arrow(mult, 1.0)
				if finisher and p:
					_poder_visual(p)
					if Sfx.has(stats.som_golpe_final):
						Sfx.play(stats.som_golpe_final, global_position, 0.05)
		"healer":
			var clicado := _mira_valida()
			var alvo := clicado if clicado else _aim_assist(dir)
			var to_a := Vector3.ZERO
			if alvo:
				to_a = alvo.global_position - global_position
				to_a.y = 0
				dir = to_a.normalized() if (clicado and to_a.length() > 0.2) else _assisted_dir(dir, alvo)
			var p := game.spawn_projectile(self, global_position + Vector3(0, 1.6, 0) + dir * 0.9, dir, stats.projetil)
			# A bola reta também desce/sobe até o peito do alvo (ponte, muralha).
			var alvo_y := (alvo.global_position.y if alvo else aim_point.y) + Projectile.TARGET_HEIGHT
			var d_reta := to_a.length() if alvo else clampf(Vector2(aim_point.x - global_position.x, aim_point.z - global_position.z).length(), 6.0, stats.attack_range * 1.4)
			p.velocity.y = (alvo_y - p.position.y) / maxf(d_reta / p.velocity.length(), 0.1)
			if finisher:
				# 3º tiro: bola maior que explode onde bater (dano em área).
				p.damage *= mult
				p.explode_final = true
				_poder_visual(p)
				_mola(3.0, 9.0)
				if Sfx.has(stats.som_golpe_final):
					Sfx.play(stats.som_golpe_final, global_position, 0.05)


## 3º tiro do Ninja: leque de shurikens (cada uma com o dano do golpe final).
func _leque_final() -> void:
	var cfg := Config.cfg
	var base := aim_dir.normalized()
	var alvo := _aim_assist(base)
	if alvo:
		base = _assisted_dir(base, alvo)
	var ps := _leque(maxi(cfg.final_leque_n, 1), cfg.final_leque_graus, stats.combo_finisher_mult, 1.05, base)
	if not ps.is_empty():
		_poder_visual(ps[ps.size() / 2])
	if Sfx.has(stats.som_golpe_final):
		Sfx.play(stats.som_golpe_final, global_position, 0.05)
	Fx.burst(game, global_position + Vector3(0, 1.4, 0) + base, Color(0.4, 1.0, 1.0), 8, 5.0)
	_mola(3.0, 8.0)


## Assistência de mira leve, só para o jogador: o inimigo mais alinhado com a
## mira, dentro de um cone de AIM_ASSIST_DEG e do alcance. Bots já têm a mira
## deles (com erro de propósito).
const AIM_ASSIST_DEG := 7.0
const AIM_ASSIST_PULL := 0.6

func _aim_assist(dir: Vector3) -> Unit:
	if not is_player:
		return null
	var best: Unit = null
	var best_ang := deg_to_rad(AIM_ASSIST_DEG)
	for other in game.units:
		if not other.alive or other.team == team:
			continue
		var to := other.global_position - global_position
		# Até a altura da muralha (3,2 m): agora o tiro desce/sobe até o alvo.
		if absf(to.y) > 4.0:
			continue
		to.y = 0
		if to.length() > stats.attack_range * 1.4 or to.length() < 0.5:
			continue
		var ang := dir.angle_to(to.normalized())
		if ang < best_ang:
			best_ang = ang
			best = other
	return best


## Gira a mira AIM_ASSIST_PULL (60%) do caminho até o alvo: perto do centro
## quase não muda nada; errar por 7° vira errar por ~3°, que ainda pode errar.
func _assisted_dir(dir: Vector3, alvo: Unit) -> Vector3:
	var to := alvo.global_position - global_position
	to.y = 0
	var ang := dir.signed_angle_to(to.normalized(), Vector3.UP)
	return dir.rotated(Vector3.UP, ang * AIM_ASSIST_PULL).normalized()


## Ciclo 2.25 (Julio: "algo que segue mais o inimigo mas pode errar ainda,
## tipo um míssil teleguiado que faz curva torto e depois se desfaz"): a nota
## do Komusō é lenta e fácil de desviar; agora curva devagar atrás do alvo,
## balançando de lado, e some no fim do alcance. Dano por nota não muda.
func _nota_teleguiada(p: Projectile, alvo: Unit) -> void:
	p.torto = Config.cfg.nota_balanco
	if alvo:
		p.segue = alvo
		p.vira = Config.cfg.nota_vira


## Inimigo vivo mais alinhado com `dir`, dentro de `graus` e do alcance.
func _alvo_no_cone(dir: Vector3, graus: float) -> Unit:
	var best: Unit = null
	var best_ang := deg_to_rad(graus * 0.5)
	for o in game.units:
		if not o.alive or o.team == team or o.em_voo:
			continue
		var to := o.global_position - global_position
		to.y = 0
		if to.length() > stats.attack_range * 1.2 or to.length() < 0.5:
			continue
		var ang := dir.angle_to(to.normalized())
		if ang < best_ang:
			best_ang = ang
			best = o
	return best


## Projéteis que voam retos (sem parábola).
const RETOS := ["shuriken", "vento", "nota", "talisma", "grou", "fio"]

func _shoot_arrow(dmg_mult: float, speed_mult: float, dir_override := Vector3.ZERO) -> Projectile:
	var dir := aim_dir.normalized() if dir_override == Vector3.ZERO else dir_override
	var to := aim_point - global_position
	to.y = 0
	# Clicar em cima de um inimigo mira nele por inteiro (direção, distância e
	# altura); senão, a assistência leve gira parte do caminho até o mais perto.
	var clicado := _mira_valida() if dir_override == Vector3.ZERO else null
	var mirado := clicado if clicado else (_aim_assist(dir) if dir_override == Vector3.ZERO else null)
	if mirado:
		to = mirado.global_position - global_position
		to.y = 0
		dir = to.normalized() if (clicado and to.length() > 0.2) else _assisted_dir(dir, mirado)
	var p := game.spawn_projectile(self, global_position + Vector3(0, 1.4, 0) + dir * 0.9, dir, stats.projetil)
	p.damage *= dmg_mult
	if stats.projetil == "nota":
		_nota_teleguiada(p, mirado if mirado else _alvo_no_cone(dir, Config.cfg.nota_cone))
	_tiro_lento_t = Config.cfg.atirador_lento_t
	p.velocity *= speed_mult
	var dist := clampf(to.length(), 6.0 if stats.projetil != "bomba" else 3.0, stats.attack_range * 1.4 * speed_mult)
	# Altura do ALVO (não a do atirador): da ponte/muralha o tiro desce junto.
	var chao_alvo := mirado.global_position.y if mirado else aim_point.y
	if stats.projetil in RETOS:
		# Reto, cruzando a altura do peito do alvo na distância mirada.
		p.velocity.y = (chao_alvo + Projectile.TARGET_HEIGHT - p.position.y) / maxf(dist / p.velocity.length(), 0.1)
	else:
		if mirado == null:
			# Sem alvo clicado: cai no chão de verdade sob o cursor (sem contar
			# travas invisíveis de passagem).
			var alvo := global_position + to.normalized() * dist
			chao_alvo = game.arena.ground_y(alvo.x, alvo.z, maxf(global_position.y, aim_point.y) + 3.0, Config.LAYER_WORLD)
		p.aim_ballistic(dist, chao_alvo)
	return p


## O inimigo clicado, se ainda vale como alvo (vivo e dentro do alcance longo).
func _mira_valida() -> Unit:
	if not is_player or aim_unit == null or not is_instance_valid(aim_unit) or not aim_unit.alive:
		return null
	var to := aim_unit.global_position - global_position
	to.y = 0
	return aim_unit if to.length() <= stats.attack_range * 1.4 else null


## Projétil de poder (Leque): rastro e impacto de nível 2, sem mudar o dano.
func _poder_visual(p: Projectile) -> void:
	if p:
		p.nivel = 2
		FxProjetil.carregar(p, p.kind)


## Multiplicador de dano de buffs (Fúria, item de dano).
func damage_mult() -> float:
	var m := 1.0
	if _fury_t > 0.0:
		m *= 1.8
	if _dmg_boost_t > 0.0:
		m *= Config.cfg.pickup_damage_mult
	if _dohyo_t > 0.0 and global_position.distance_to(_dohyo_pos) <= Config.cfg.dohyo_raio:
		m *= 1.0 + Config.cfg.dohyo_dano
	if stats.heroi:
		m *= Config.cfg.heroi_dano_mult
	return m * (1.0 + Config.cfg.mago_bonus_dano * _nivel_mago())


## Selo: sem atacar, sem botão direito e sem poder por t segundos.
func silence(t: float) -> void:
	_silence_t = maxf(_silence_t, t)
	_cancel_skill()
	Fx.damage_number(game, global_position + Vector3(0, 0.5, 0), "SELADO", Color(0.7, 0.95, 1.0))


func give_damage_boost(t: float) -> void:
	_dmg_boost_t = maxf(_dmg_boost_t, t)


func fill_power() -> void:
	power = 0.0
	_power_active_t = 0.0
	add_power(POWER_MAX)


## Joga para cima com velocidade vy (m/s). Altura máxima h = vy²/2g: com
## g = 30, vy = 7 sobe ~0,8 m e fica ~0,47 s no ar.
func launch(vy: float) -> void:
	if alive and _dodge_t <= 0.0:
		_launch_vy = maxf(_launch_vy, vy)


## Congela animação e movimento por t segundos (hitstop).
func hitstop(t: float) -> void:
	_hitstop_t = maxf(_hitstop_t, t)
	_set_anim_speed(0.0)


func _set_anim_speed(s: float) -> void:
	if _anim:
		_anim.speed_scale = s
	if _upper:
		_upper.speed_scale = s


# --- Botão direito = defesa (todas as classes); Q = habilidade rápida -----------

func _update_skill(delta: float, free_hands: bool) -> void:
	_block_t += delta
	_quick_cd = maxf(_quick_cd - delta, 0.0)
	var held := wants_block and free_hands and reanimando == null and _guarda_trava_t <= 0.0
	if held != _blocking:
		_blocking = held
		if held:
			_block_t = 0.0
			_play_upper("Blocking", 1.0, true)
			_mola(-2.0, -1.5)  # agacha um pouco atrás da guarda
		else:
			_stop_upper("Blocking")
	_tick_escudo_def(delta)
	if wants_quick:
		wants_quick = false
		if quick_ready() and free_hands and not _blocking and _mudo_t <= 0.0:
			if _usar_rapida():
				Assinatura.toque_q(self)
				_quick_cd = quick_cooldown()
				if stats.cargas_q > 0:  # flechas nas costas: gasta uma, a recarga é por carga
					cargas_q -= 1
					_quick_cd = 0.35


func tem_rapida() -> bool:
	return stats.skill in ["cura", "tiro_carregado", "armadilha", "investida", "pisao", "corrida", "varrida", "gancho"] \
			or Herois.RAPIDAS.has(stats.skill)


func quick_cooldown() -> float:
	var m := Config.cfg.rapida_cooldown_mult
	if stats.heroi:
		m *= Config.cfg.heroi_recarga_mult
	if game and game.sandbox:
		m *= Config.cfg.sandbox_q_mult  # modo teste: Q toda hora
	match stats.skill:
		"cura":
			return stats.heal_cooldown * m
		"armadilha":
			return stats.trap_cooldown * m
	return stats.skill_cooldown * m


func quick_ready() -> bool:
	if stats.cargas_q > 0:
		return tem_rapida() and cargas_q > 0 and _quick_cd <= 0.0
	return tem_rapida() and _quick_cd <= 0.0


## 0 = acabou de usar, 1 = pronto.
func quick_ratio() -> float:
	if stats.cargas_q > 0 and cargas_q <= 0:
		return clampf(_carga_q_t / maxf(quick_cooldown(), 0.01), 0.0, 1.0)
	return 1.0 - clampf(_quick_cd / maxf(quick_cooldown(), 0.01), 0.0, 1.0)


## Nó que segue a mão da arma (osso handslot.r), criado na primeira vez: a
## fita da lâmina se prende nele. Some junto com o modelo ao trocar de classe.
var _mao_no: BoneAttachment3D

func mao_da_arma() -> Node3D:
	if _mao_no == null or not is_instance_valid(_mao_no):
		_mao_no = null
		if _model == null:
			return null
		var sk := _model.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk == null or sk.find_bone("handslot.r") < 0:
			return null
		_mao_no = BoneAttachment3D.new()
		_mao_no.bone_name = "handslot.r"
		sk.add_child(_mao_no)
	return _mao_no


func quick_restante() -> float:
	if stats.cargas_q > 0 and cargas_q <= 0:  # sem flecha: espera a próxima carga
		return maxf(quick_cooldown() - _carga_q_t, _quick_cd)
	return _quick_cd


## Solta o Q da classe. Devolve false se não saiu (recarga não começa).
func _usar_rapida() -> bool:
	match stats.skill:
		"cura":
			_heal()
		"armadilha":
			_place_trap()
		"tiro_carregado":
			_fire_charged(1.0)
		"investida":
			_corte_relampago(stats.skill_radius, stats.skill_value * damage_mult(), false)
		"pisao":
			_pisao()
		"varrida":
			_varrida()
		"gancho":
			return _gancho()
		"corrida":
			_play_upper("Cheer", 1.6)
			Fx.ring(game, global_position, Color(1, 0.8, 0.3, 0.9), stats.skill_radius)
			Assinatura.selo(game, global_position, self, minf(stats.skill_radius, 5.0), 0.8, {"escrita": 0.15, "giro": 0.6})
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.skill_radius:
					other.give_boost(stats.skill_value, stats.skill_duration)
					FxPoder.rastro(other, Color(1, 0.8, 0.3), stats.skill_duration)
		_:
			return Herois.rapida(self)
	return true


## Ronin Oni (Q): pisão curto. Mesma física da Fúria em escala menor:
## onda radial, dano cai até a metade na borda, arremessa um pouco.
func _pisao() -> void:
	_play_once("2H_Melee_Attack_Chop", 0.35)
	_mola(-6.0, 0.0)
	Fx.cracks(game, global_position, Color(1.0, 0.35, 0.15), stats.skill_radius)
	Fx.ring(game, global_position, Color(1.0, 0.4, 0.2, 0.9), stats.skill_radius)
	Fx.burst(game, global_position + Vector3(0, 0.4, 0), Color(0.75, 0.6, 0.45), 16, 6.0)
	FxPoder.q_pisao(self)
	Sfx.play("hit", global_position, 0.1)
	Sfx.play("magia_estouro", global_position, 0.06, 1.1, -3.0)
	game.camera.shake_at(global_position, 0.4)
	var acertou := false
	for other in game.units:
		if not other.alive or other.team == team:
			continue
		var d := other.global_position - global_position
		if absf(d.y) > 1.8:
			continue
		d.y = 0
		if d.length() <= stats.skill_radius:
			var f := 1.0 - 0.5 * d.length() / stats.skill_radius
			other.take_damage(stats.skill_value * damage_mult() * f, self, d.normalized() if d.length() > 0.1 else _facing(), 1.4, true, "terra", 2)
			other.launch(4.5 * f)
			acertou = true
	if acertou:
		hitstop(Config.cfg.hitstop_time * 1.3)


## Sohei (Q): a naginata varre ~300° em volta. Só a LÂMINA corta: dano na
## faixa [alcance_min, skill_radius]; quem está colado leva o cabo (empurrão).
## Aliados perto ganham escudo (a fé dele protege quem luta junto).
func _varrida() -> void:
	_play_once("2H_Melee_Attack_Spinning", 0.45)
	_mola(-3.0, 4.0)
	var r := stats.skill_radius
	var fr := Vector3(aim_dir.x, 0, aim_dir.z)
	fr = fr.normalized() if fr.length() > 0.1 else _facing()
	FxPoder.q_varrida(self, r)
	Sfx.play("swing", global_position, 0.1, 0.8)
	var acertou := false
	for other in game.units:
		if not other.alive:
			continue
		var d := other.global_position - global_position
		if absf(d.y) > 1.8:
			continue
		d.y = 0
		var dist := d.length()
		if other.team == team:
			if other != self and dist <= Config.cfg.varrida_aliados_raio:
				other.give_shield(Config.cfg.varrida_escudo, Config.cfg.varrida_escudo_t)
				FxPoder.em_aliado(other, stats.hat_color.lightened(0.3), self)
			continue
		if dist > r + 0.3:
			continue
		var dn := d / dist if dist > 0.1 else fr
		if dist > 1.0 and rad_to_deg(fr.angle_to(dn)) > 150.0:
			continue  # as costas ficam abertas (o giro não fecha)
		if dist < stats.alcance_min:
			other._knock = dn * 9.0
			continue
		other.take_damage(stats.skill_value * damage_mult(), self, dn, 1.1, true)
		acertou = true
	give_shield(Config.cfg.varrida_escudo * 0.5, Config.cfg.varrida_escudo_t)
	if acertou:
		hitstop(Config.cfg.hitstop_time)
		if is_player:
			game.camera.add_trauma(0.3)


## Kusarigama (Q): lança o peso na linha da mira; o primeiro inimigo nela
## (até skill_radius) leva o dano, fica PRESO e é puxado até ~1,6 m.
## Puxão: empurrão inicial v0 = sqrt(2·a·d) com a = KNOCK_DECAY, o mesmo
## atrito que freia todo empurrão, então ele para exatamente na distância d.
## Sem ninguém na linha, a corrente vai e volta e o Q não gasta (recarga curta).
func _gancho() -> bool:
	var dir := aim_dir.normalized()
	dir.y = 0
	if dir.length() < 0.1:
		dir = _facing()
	dir = dir.normalized()
	var alvo: Unit = null
	var melhor := INF
	for other in game.units:
		if not other.alive or other.team == team:
			continue
		var to := other.global_position - global_position
		if absf(to.y) > 1.8:
			continue
		to.y = 0
		var ao_longo := to.dot(dir)
		if ao_longo < 0.3 or ao_longo > stats.skill_radius:
			continue
		var lado := (to - dir * ao_longo).length()
		if lado > 1.1 + 0.08 * ao_longo:  # o peso abre um pouco com a distância
			continue
		if ao_longo < melhor:
			melhor = ao_longo
			alvo = other
	_play_upper("Throw", 1.6)
	var ponta := alvo.global_position if alvo else global_position + dir * stats.skill_radius
	FxPoder.q_gancho(self, ponta, alvo != null)
	Sfx.play("swing", global_position, 0.08, 0.7)
	if alvo == null:
		_quick_cd = quick_cooldown() * 0.35  # errou: volta logo
		return false
	var to_a := alvo.global_position - global_position
	to_a.y = 0
	var dist := to_a.length()
	alvo.take_damage(stats.skill_value * damage_mult(), self, -to_a.normalized(), 0.0, true)
	if alvo.alive:
		var puxa := maxf(dist - 1.6, 0.0)
		alvo._knock = -to_a.normalized() * minf(sqrt(2.0 * KNOCK_DECAY * puxa), Config.cfg.gancho_vel)
		alvo.prender(Config.cfg.gancho_atordoa)
	if is_player:
		game.camera.add_trauma(0.25)
		game.camera.kick(dir, 0.4)
	return true


## Preso (corrente da Kusarigama): quase parado, sem atacar, sem esquivar.
func prender(t: float) -> void:
	_preso_t = maxf(_preso_t, t)
	_cancel_skill()
	if _dodge_t > 0.0:
		_dodge_t = 0.0
		_fim_dash()
	Fx.damage_number(game, global_position + Vector3(0, 0.5, 0), "PRESO", Color(0.75, 0.8, 1.0))


## Arco translúcido na cor do time na frente do corpo enquanto defende:
## lê "estou de guarda" de longe, para qualquer classe (nem todas têm escudo).
func _tick_escudo_def(delta: float) -> void:
	if _escudo_def == null:
		if not _blocking:
			return
		_escudo_def = MeshInstance3D.new()
		var m := CylinderMesh.new()
		m.top_radius = 1.0
		m.bottom_radius = 1.0
		m.height = 1.5
		m.radial_segments = 16
		m.rings = 1
		m.cap_top = false
		m.cap_bottom = false
		_escudo_def.mesh = m
		var mat := Fx.unshaded(Color(Config.team_color(team).lightened(0.45), 0.0), true)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_escudo_def.material_override = mat
		_escudo_def.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_escudo_def.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		# Só a metade da frente: achata em z e empurra para a frente.
		_escudo_def.scale = Vector3(0.9, 1.0, 0.45)
		_escudo_def.position = Vector3(0, 1.0, 0.55)
		_visual.add_child(_escudo_def)
	var mat2 := _escudo_def.material_override as StandardMaterial3D
	var alvo := 0.0
	if _blocking:
		# Janela do contra-golpe: brilha mais forte (dá para aprender o tempo).
		alvo = 0.6 if _block_t <= Config.cfg.parry_janela else 0.3
	# Guarda gasta (Ciclo 2.26): o arco esquenta para laranja-vermelho e fica
	# mais opaco perto de quebrar, e treme no fim; dá para ler dos dois lados.
	var g := clampf(guarda / maxf(Config.cfg.guarda_limite, 0.01), 0.0, 1.0)
	var base := Config.team_color(team).lightened(0.45)
	var cor := base.lerp(Color(1.0, 0.35, 0.12), smoothstep(0.25, 1.0, g))
	alvo = minf(alvo + 0.3 * g, 0.85) if _blocking else alvo
	mat2.albedo_color = Color(cor, move_toward(mat2.albedo_color.a, alvo, delta * 3.0))
	if g > 0.7 and _blocking:
		var tr := (g - 0.7) * 0.12
		_escudo_def.position = Vector3(randf_range(-tr, tr), 1.0, 0.55 + randf_range(-tr, tr))
	else:
		_escudo_def.position = Vector3(0, 1.0, 0.55)
	_escudo_def.visible = mat2.albedo_color.a > 0.01


## Estrepes nos pés; passou do limite, a mais antiga do mesmo dono some.
func _place_trap() -> void:
	var mine: Array[Node] = []
	for t in get_tree().get_nodes_in_group("traps"):
		if t.owner_unit == self and not t.is_queued_for_deletion() and not t.has_meta("do_poder"):
			mine.append(t)
	while mine.size() >= stats.trap_max:
		mine.pop_front().queue_free()
	var trap := Trap.new()
	game.add_child(trap)
	trap.setup(game, self, global_position - _facing() * 0.8)
	_play_upper("Interact", 1.6)
	Sfx.play("pickup", global_position, 0.1)
	FxPoder.q_armadilha(self, trap.global_position)


func apply_slow(mult: float, duration: float) -> void:
	_slow_mult = mult
	_slow_t = maxf(_slow_t, duration)
	Fx.burst(game, global_position + Vector3(0, 0.4, 0), Color(0.6, 0.6, 0.7), 6, 2.0)


func _fire_charged(c := -1.0) -> void:
	if c < 0.0:
		c = charge_ratio()
	_cancel_skill()
	_attack_cd = stats.attack_cooldown
	_attack_t = 0.3
	_play_upper("1H_Ranged_Shoot", 1.4)
	var p := _shoot_arrow(1.0 + (stats.charge_damage_mult - 1.0) * c, 1.0 + 0.5 * c)
	if c >= 1.0 and p:
		p.carregar()  # atravessa inimigos / bomba maior
	if c >= 1.0:
		Fx.burst(game, global_position + Vector3(0, 1.4, 0) + aim_dir * 1.2, Color(1, 0.85, 0.4), 10, 6.0)
		FxPoder.q_tiro(self, aim_dir.normalized())
		if is_player:
			game.camera.add_trauma(0.15)


func _cancel_skill() -> void:
	if _escudo_def:
		(_escudo_def.material_override as StandardMaterial3D).albedo_color.a = 0.0
		_escudo_def.visible = false
	if _blocking:
		_blocking = false
		_stop_upper("Blocking")
	if _charge_t > 0.0:
		_charge_t = 0.0
		_stop_upper("1H_Ranged_Aiming")


func _heal() -> void:
	_heal_cd = stats.heal_cooldown
	_play_upper("Spellcast_Raise", 1.3)
	Sfx.play("heal", global_position)
	Fx.ring(game, global_position, Color(0.5, 1.0, 0.6, 0.7), stats.heal_radius)
	FxPoder.q_cura(self)
	var healed := 0.0
	for other in game.units:
		if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.heal_radius:
			var quanto := stats.heal_amount * Config.cfg.vida_mult
			if other == self:
				quanto *= Config.cfg.cura_propria_mult
			var ganho := other.heal(quanto, self)
			healed += ganho
			if ganho > 0.0 and other != self:
				FxPoder.fio_cura(self, other)
	add_power(healed * Config.cfg.power_per_damage)


## Cura e devolve quanto curou de fato.
func heal(amount: float, quem: Unit = null) -> float:
	if hp >= max_hp() or not alive:
		return 0.0
	var before := hp
	hp = minf(hp + amount, max_hp())
	if quem and game and game._equilibrio:
		game.eq_somar(quem.stats.id, "cura", hp - before)
	if quem and quem != self and game and game.placar:
		game.placar.somar(quem, "cura", hp - before)
	if is_player or (quem and quem.is_player):  # só a cura que você deu ou levou
		Fx.damage_number(game, global_position, "+%d" % int(hp - before), Color(0.5, 1, 0.55))
	_update_hp_bar()
	return hp - before


## dir = direção do golpe (de quem bate para quem apanha).
## elemento: o que bateu ("shuriken", "fogo", "bomba", ...; vazio = golpe
## comum), para o impacto e a marca no corpo (FxProjetil). nivel 2 = Q.
func take_damage(amount: float, attacker: Unit, dir: Vector3, knock_mult := 1.0, melee := false, elemento := "", nivel := 1) -> void:
	if not alive or em_voo:
		return
	if _intocavel_t > 0.0 and amount > 0.0:
		return  # acabou de ser reanimado
	if _dodge_t > 0.0:
		if attacker and amount > 0.0:
			_esquiva_perfeita(attacker)
		return
	amount = Herois.ao_apanhar(self, amount, attacker, dir, melee, elemento, nivel)
	if amount < 0.0:
		return  # boneco de papel engoliu o golpe
	if stats.knock_imune:
		knock_mult = 0.0
	if attacker and attacker.team != game.time_jogador:
		amount *= Settings.bot_damage_mult()
	if carried_princess:
		amount *= Config.cfg.carrier_damage_mult
	# Bloqueio: vale para golpes que chegam pela frente (até 60° do rosto).
	var blocked := _blocking and _guarda_trava_t <= 0.0 and _facing().dot(-dir) > BLOCK_COS
	if blocked and melee and attacker and attacker.alive and _block_t <= Config.cfg.parry_janela:
		_contra_golpe(attacker, dir)
		return
	var quebrou := false
	if blocked:
		quebrou = _gastar_guarda(amount, melee, elemento)
		# Contra torreta o escudo segura quase tudo (vale para qualquer classe).
		amount *= 1.0 - (Config.cfg.torreta_bloqueio if elemento == "torreta" else stats.block_reduction)
		knock_mult *= 0.3
	if amount > 0.0 and hp_rastro <= hp_ratio() + 0.001:
		hp_rastro = hp_ratio()  # o branco começa onde a vida estava
	if amount > 0.0:
		_rastro_espera = Config.cfg.rastro_espera
	if _shield > 0.0:
		var absorbed := minf(_shield, amount)
		_shield -= absorbed
		amount -= absorbed
	hp -= amount
	if attacker and game and game._equilibrio and attacker.team != team:
		game.eq_somar(attacker.stats.id, "dano", minf(amount, hp + amount))
	if attacker and game and game.placar and attacker.team != team:
		game.placar.dano(self, attacker, minf(amount, hp + amount), game._time)
	_calm_t = 0.0
	if carried_tora and amount > 0.0:
		drop_tora()  # apanhou: a tora cai (qualquer Construtor pega, até o inimigo)
	if attacker:
		attacker._calm_t = 0.0
		attacker.add_power(amount * Config.cfg.power_per_damage)
		attacker.add_super(amount * Config.cfg.super_por_dano)
	add_power(amount * Config.cfg.power_per_damage_taken)
	if _fury_t > 0.0:
		knock_mult *= 0.2  # gigante: quase não é empurrado
	_knock = dir * (attacker.stats.knockback if attacker else 4.0) * knock_mult
	var forte := knock_mult > 1.0
	_flash_t = 0.14 if forte else 0.1
	_mola(-5.0 if forte else -3.0, -3.0 if forte else -1.5)
	_tremor_t = 0.22 if forte else 0.15
	# Número de dano: cada jogador vê só o dano que deu e o que levou
	# (amarelo = seu golpe, vermelho = você apanhou, azul = bloqueado).
	var do_jogador := attacker != null and attacker.is_player
	if do_jogador or is_player:
		var col := Color(1, 0.9, 0.3) if do_jogador else Color(1, 0.45, 0.4)
		if blocked:
			col = Color(0.6, 0.8, 1.0)
		Fx.damage_number(game, global_position, str(int(amount)), col, 0.6 if blocked else maxf(knock_mult, 1.0), dir)
	if quebrou:
		_quebrar_guarda(attacker, dir)
	elif blocked:
		Fx.burst(game, global_position + Vector3(0, 1.3, 0) - dir * 0.6, Color(0.8, 0.9, 1.0), 10, 6.0)
		Sfx.play("block", global_position, 0.1)
		_play_upper("Block_Hit", 1.5)
		if melee and attacker and attacker.alive:
			# Bateu no escudo: quem golpeou quica para trás e os dois travam um
			# instante (o "clang"). Impulso de volta ~ metade do empurrão normal.
			attacker._knock = -dir * attacker.stats.knockback * 0.5
			attacker.hitstop(Config.cfg.hitstop_time * 0.7)
			attacker._mola(-2.0, -3.0)
	if not blocked:
		_impacto(attacker, dir, forte, melee, elemento, nivel)
		if amount > 0.0 and is_on_floor() and _respingo_t <= 0.0:
			_respingo_t = 0.2
			Respingo.em(game, global_position, dir, Config.team_color(team), clampf(amount / max_hp() * 5.0, 0.45, 1.0))
		# Golpe forte soa mais grave (mais "massa"); acerto de longe, mais agudo.
		Sfx.play("hit", global_position, 0.08, 0.82 if forte else (1.12 if not melee else 1.0), (2.0 if forte else 0.0) - (4.0 if elemento != "" else 0.0))
		if Projectile.SOM_ACERTO.has(elemento) and elemento != "bomba":
			Sfx.play(Projectile.SOM_ACERTO[elemento], global_position, 0.1)
	if melee:
		hitstop(Config.cfg.hitstop_time * (1.6 if knock_mult > 1.0 else 1.0))
	elif attacker and attacker.is_player and amount > 0.0:
		# Tiro do jogador acertou: micro-pausa no alvo e um toque na câmera,
		# senão o acerto de longe parece não ter peso.
		hitstop(Config.cfg.hitstop_time * 0.5)
		game.camera.add_trauma(0.08)
	if is_player:
		game.camera.add_trauma(0.2 if blocked else 0.45)
		game.camera.kick(dir, 0.15 if blocked else 0.35)
		# Golpe forte: borda vermelha rápida (separada da de vida baixa).
		var frac := amount / max_hp()
		if not blocked and game.hud and (frac >= Config.cfg.golpe_forte_frac or (forte and frac > 0.05)):
			game.hud.golpe_forte(clampf(frac / (Config.cfg.golpe_forte_frac * 2.0), 0.4, 1.0), dir)
	_update_hp_bar()
	if hp <= 0.0 and not Herois.nao_cai(self, attacker):
		_die(attacker)
	elif _anim_lock <= 0.0 and not blocked and _spin_t <= 0.0 and hp > 0.0:
		_play_once("Hit_A" if randf() < 0.5 else "Hit_B", 0.25)


## Impacto no corpo: faísca de corte no golpe corpo a corpo, o efeito do
## elemento no tiro (estilhaço, cruz de luz, implosão...) e a marca no corpo.
func _impacto(attacker: Unit, dir: Vector3, forte: bool, melee: bool, elemento: String, nivel: int) -> void:
	var at := global_position + Vector3(0, 1.2, 0)
	if elemento == "" or elemento == "corte":
		var cor := Color(1.0, 0.85, 0.45)
		if attacker:
			cor = cor.lerp(attacker.stats.hat_color, 0.3)
		FxProjetil.faisca_corte(game, at - dir * 0.3, dir, cor if not forte else Color(1.0, 0.55, 0.15), forte)
		return
	if elemento == "bomba":
		FxProjetil.faiscas(game, at, Color(1.0, 0.7, 0.3), 4, 5.0, dir + Vector3.UP, 60.0)
	else:
		FxProjetil.impacto(game, at - dir * 0.3, elemento, dir, nivel)
	if elemento in ["flecha", "shuriken"]:
		FxProjetil.cravar(self, at + Vector3(randf_range(-0.15, 0.15), randf_range(-0.2, 0.15), 0), dir, elemento, 0.9)
	FxProjetil.marca_corpo(self, elemento)


## Esquiva perfeita: um golpe passou por dentro do dash. O dash continua
## igual (pedido do Julio); só ganha recompensa e aviso: Chi, "ESQUIVA!",
## rastro e, para o jogador, um instante de câmera lenta.
## Leque: segunda onda 0,25 s depois, nos vãos da primeira.
func _leque_onda2(n: int, base: Vector3) -> void:
	await get_tree().create_timer(0.25).timeout
	if not alive or not is_inside_tree():
		return
	_play_upper("Throw", 1.8)
	for p in _leque(maxi(n - 1, 1), stats.power_radius, _mult_poder(), 1.2, base, true):
		_poder_visual(p)


## Leque de n tiros abrindo `graus` no total em volta de `base`. entre = a 2ª
## onda do Leque, que sai nos vãos da primeira.
func _leque(n: int, graus: float, dmg_mult: float, vel_mult: float, base: Vector3, entre := false) -> Array[Projectile]:
	var out: Array[Projectile] = []
	for i in n:
		var t := (float(i) + (0.5 if entre else 0.0)) / maxf(n - 1, 1)
		var ang := deg_to_rad(lerpf(-graus, graus, t) * 0.5)
		var p := _shoot_arrow(dmg_mult, vel_mult, base.rotated(Vector3.UP, ang))
		if p:
			out.append(p)
	return out


## Dano de um projétil de poder (power_value) como múltiplo do dano normal.
func _mult_poder() -> float:
	return stats.power_value * Config.cfg.dano_poder_mult / maxf(stats.damage, 0.1)


## Bombardeiro: fila de explosões de pólvora até a mira; a última deixa fumaça.
func _bombardeio() -> void:
	_play_upper("Throw", 1.6)
	var dir := aim_point - global_position
	dir.y = 0
	var alcance := clampf(dir.length(), 5.0, stats.attack_range * 1.2)
	dir = dir.normalized() if dir.length() > 0.1 else _facing()
	var n := maxi(int(stats.power_duration), 1)
	var pontos: Array[Vector3] = []
	for i in n:
		var p := global_position + dir * lerpf(2.5, alcance, float(i) / maxf(n - 1, 1))
		p.y = game.arena.ground_y(p.x, p.z, global_position.y + 3.0)
		pontos.append(p)
	FxPoder.aviso_bombardeio(game, pontos, stats.power_radius, Config.cfg.bombardeio_intervalo)  # pavio
	_power_active_t = Config.cfg.bombardeio_intervalo * n
	for i in n:
		await get_tree().create_timer(Config.cfg.bombardeio_intervalo).timeout
		if not is_inside_tree():
			return
		_explosao(pontos[i], stats.power_value * Config.cfg.dano_poder_mult, stats.power_radius)
	var fumaca := AreaEffect.new()
	game.add_child(fumaca)
	fumaca.setup(game, self, pontos[n - 1], "nuvem", stats.power_radius * 1.6, 5.0, Config.cfg.bombardeio_fumaca)
	FxPoder.nuvem(game, pontos[n - 1], stats.power_radius * 1.6)


## Explosão de pólvora (mesma conta da bomba: 100% no centro, 50% na borda).
func _explosao(at: Vector3, dano: float, r: float) -> void:
	Fx.burst(game, at + Vector3(0, 0.6, 0), Color(1.0, 0.6, 0.2), 18, 8.0)
	Fx.burst(game, at + Vector3(0, 0.4, 0), Color(0.6, 0.6, 0.7), 10, 3.0)
	Fx.ring(game, at, Color(1.0, 0.55, 0.15, 0.9), r)
	FxPoder.explosao_polvora(game, at, r)
	Reacoes.em(game, at, r, "bomba", team)
	Sfx.play("hit", at, 0.15)
	game.camera.shake_at(at, 0.45)
	for u in game.units:
		if not u.alive or u.team == team:
			continue
		var d := u.global_position - at
		if absf(d.y) > 2.5:
			continue
		d.y = 0
		if d.length() <= r:
			var f := 1.0 - 0.5 * d.length() / r
			u.take_damage(dano * f, self, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, f, false, "bomba", 3)
			u.launch(5.0 * f)


func _esquiva_perfeita(attacker: Unit) -> void:
	var agora := Time.get_ticks_msec() / 1000.0
	if agora - _esquiva_t < 0.6:
		return
	_esquiva_t = agora
	add_power(Config.cfg.chi_esquiva)
	# O texto só quando o jogador está na jogada: bot contra bot já tem
	# número de dano demais na tela.
	if is_player or attacker.is_player:
		Fx.damage_number(game, global_position + Vector3(0, 0.5, 0), "ESQUIVA!", Color(0.55, 1.0, 1.0))
	Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(0.55, 1.0, 1.0), 10, 4.0)
	Sfx.play("dodge", global_position, 0.2)
	if is_player:
		game.slowmo(0.45, 0.22)


## Contra-golpe (bloqueio na hora certa): o golpe não entra, quem bateu fica
## atordoado e leva um corte de volta. dir = direção do golpe recebido.
## Guarda (Ciclo 2.26): soma o golpe que bateu na defesa; true = quebrou.
## Física: a defesa absorve impulso; golpe pesado (mais dano, mais massa)
## gasta mais, e um corpo grande (mais vida) aguenta mais golpes.
func _gastar_guarda(amount: float, melee: bool, elemento: String) -> bool:
	var cfg := Config.cfg
	if elemento == "torreta" or amount <= 0.0 or cfg.guarda_limite <= 0.0:
		return false
	guarda += amount / max_hp() * (1.0 if melee else cfg.guarda_tiro)
	_guarda_calma = 0.0
	return guarda >= cfg.guarda_limite


func _tick_guarda(delta: float) -> void:
	if _guarda_trava_t > 0.0:
		_guarda_trava_t -= delta
	if guarda <= 0.0:
		return
	_guarda_calma += delta
	if _guarda_calma >= Config.cfg.guarda_espera:
		guarda = maxf(guarda - Config.cfg.guarda_recupera * delta, 0.0)


## Guarda quebrou: a defesa cai, atordoa um instante e não volta logo.
func _quebrar_guarda(attacker: Unit, dir: Vector3) -> void:
	var cfg := Config.cfg
	guarda = 0.0
	_guarda_trava_t = cfg.guarda_trava
	_cancel_skill()
	_preso_t = maxf(_preso_t, cfg.guarda_atordoa)  # quase parado, sem atacar nem esquivar
	_attack_cd = maxf(_attack_cd, cfg.guarda_atordoa)
	_anim_lock = maxf(_anim_lock, cfg.guarda_atordoa)
	_windup_t = 0.0
	_play_once("Hit_B", cfg.guarda_atordoa)
	_mola(-6.0, -4.0)
	_tremor_t = 0.3
	hitstop(cfg.hitstop_time * 2.0)
	var p := global_position + Vector3(0, 1.2, 0) - dir * 0.55
	Fx.burst(game, p, Config.team_color(team).lightened(0.5), 18, 8.0)
	Fx.burst(game, p, Color(1.0, 0.45, 0.15), 10, 5.0)
	Fx.ring(game, global_position, Color(1.0, 0.5, 0.2, 0.85), 1.6)
	Fx.damage_number(game, global_position + Vector3(0, 0.6, 0), "GUARDA QUEBRADA!", Color(1.0, 0.55, 0.25), 1.7)
	Sfx.play("block", global_position, 0.05, 0.6, 3.0)
	Sfx.play("hit", global_position, 0.1, 0.75)
	if attacker:
		attacker.add_power(cfg.guarda_chi)
		attacker.hitstop(cfg.hitstop_time * 1.5)
		if attacker.is_player:
			game.camera.add_trauma(0.35)
	if is_player:
		game.camera.add_trauma(0.5)
		if game.hud:
			game.hud.golpe_forte(0.6, dir)


## Rastro branco da barra: segura um instante e desce até a vida atual.
func _tick_rastro(delta: float) -> void:
	var r := clampf(hp_ratio(), 0.0, 1.0)
	var antes := hp_rastro
	if hp_rastro <= r:
		hp_rastro = r
	elif _rastro_espera > 0.0:
		_rastro_espera -= delta
	else:
		hp_rastro = move_toward(hp_rastro, r, Config.cfg.rastro_vel * delta)
	if _respingo_t > 0.0:
		_respingo_t -= delta
	if hp_rastro != antes and _hp_fill:
		_hp_fill.set_instance_shader_parameter("rastro", hp_rastro)


func _contra_golpe(attacker: Unit, dir: Vector3) -> void:
	var cfg := Config.cfg
	_block_t = cfg.parry_janela + 1.0  # um contra-golpe por bloqueio
	attacker._attack_cd = maxf(attacker._attack_cd, cfg.parry_atordoa)
	attacker._anim_lock = maxf(attacker._anim_lock, cfg.parry_atordoa)
	attacker._windup_t = 0.0
	attacker._play_once("Hit_B", cfg.parry_atordoa)
	attacker.take_damage(stats.damage * damage_mult() * cfg.parry_mult, self, -dir, 1.8, false)
	hitstop(cfg.hitstop_time * 2.5)
	attacker.hitstop(cfg.hitstop_time * 2.5)
	add_power(stats.damage * cfg.power_per_damage)
	var p := global_position + Vector3(0, 1.4, 0) - dir * 0.7
	Fx.burst(game, p, Color(1.0, 0.95, 0.7), 22, 9.0)
	Fx.ring(game, global_position, Color(1.0, 0.9, 0.5, 0.9), 2.2)
	Fx.damage_number(game, global_position + Vector3(0, 0.6, 0), "CONTRA!", Color(1.0, 0.85, 0.3), 2.0)
	Sfx.play("block", global_position, 0.05)
	Sfx.play("hit", global_position, 0.1)
	_play_upper("Block_Hit", 1.8)
	if is_player or attacker.is_player:
		game.camera.add_trauma(0.4)


func _facing() -> Vector3:
	return Vector3(sin(_visual.rotation.y), 0, cos(_visual.rotation.y))


func _die(killer: Unit) -> void:
	alive = false
	hp = 0.0
	_windup_t = 0.0
	if _model and (_fogo_dash_t > 0.0 or not _model.visible):
		_fogo_dash_t = 0.0
		_model.visible = true  # morreu no meio do dash da Kitsune
	if _rolo > 0.0 and _model:  # morreu no meio da cambalhota
		_rolo = 0.0
		_model.rotation.x = 0.0
		_model.position = Vector3.ZERO
	_morte_t = 0.0 if _exagero() > 0.0 else -1.0
	_mola(7.0, 0.0)  # "boing": estica antes do pulinho
	_cancel_equip()
	_cancel_skill()
	_end_buffs()
	_hitstop_t = 0.0
	_set_anim_speed(1.0)
	if _upper:
		_upper.stop()
	if carried_princess:
		carried_princess.drop(global_position)
		carried_princess = null
	drop_tora()
	has_cake = false
	collision_layer = 0
	velocity = Vector3.ZERO
	_hp_root.visible = false
	_play("Death_A" if randf() < 0.5 else "Death_B", 0.1)
	_respawn_t = game.respawn_atual()
	Sfx.play("death", global_position)
	if killer and killer != self:
		killer.add_power(Config.cfg.power_per_kill)
		killer.add_super(Config.cfg.super_por_abate)
		Herois.abateu(killer, self)
	power *= Config.cfg.power_keep_on_death
	if _sombra_t > 0.0:
		_fim_sombra()
	died.emit(self, killer)


func _respawn() -> void:
	_voltar_a_vida()
	global_position = game.arena.random_spawn(team, game.units)
	reset_physics_interpolation()  # teleporte: sem rastro interpolado até o castelo
	set_class(Config.cfg.villager)  # quem morre perde o chapéu
	Fx.ring(game, global_position, Config.team_color(team), 2.0)
	Sfx.play("renascer", global_position, 0.04)
	_play_once("Lie_StandUp", 0.7)


## Reanimado por um aliado (Reanimar, Ciclo 2.18): levanta onde está, com a
## classe e o chapéu que tinha, reanimar_vida da vida e intocável um instante.
func levantar_reanimado() -> void:
	_voltar_a_vida()
	hp = max_hp() * Config.cfg.reanimar_vida
	_intocavel_t = Config.cfg.reanimar_intocavel
	_play_once("Lie_StandUp", 0.7, 1.3)
	_mola(5.0, 0.0)  # sai do chão num esticão


## O que renascer e ser reanimado têm em comum.
func _voltar_a_vida() -> void:
	alive = true
	collision_layer = Config.LAYER_UNITS
	reanimar_prog = 0.0
	reanimador = null
	desistiu = false
	velocity = Vector3.ZERO
	_knock = Vector3.ZERO
	_move_vel = Vector3.ZERO
	_morte_t = -1.0
	_sq = 0.0
	_sq_v = 0.0
	_st = 0.0
	_st_v = 0.0
	_tremor_t = 0.0
	_visual.position = Vector3.ZERO
	_visual.scale = Vector3.ONE
	_gigante = 1.0


# --- Poder do Q (medidor de Glacê) --------------------------------------------

## Vazamento do medidor depois de um tempo sem lutar: dG/dt = −G/τ.
func _tick_power(delta: float) -> void:
	var cfg := Config.cfg
	if cfg.power_regen > 0.0:
		# Enche sozinho com o tempo: o E vem mesmo sem acertar ninguém
		# (briga só adianta). Sem vazamento nesse modo.
		if power < POWER_MAX and stats.power != "nenhum":
			var idle := _power_idle
			add_power(cfg.power_regen * delta)
			_power_idle = idle + delta
		else:
			_power_idle += delta
		return
	_power_idle += delta
	if _power_idle > cfg.power_leak_delay and power < POWER_MAX:
		power = maxf(power - power / cfg.power_leak_tau * delta, 0.0)


# --- Super (R) -------------------------------------------------------------------

func super_ready() -> bool:
	return super_carga >= POWER_MAX and stats.power != "nenhum" and not super_travado()


## Ciclo 2.22: com a casa da classe no nível 1, o R ainda não está liberado
## (sobe para o 2 e libera). Classes sem casa no pátio não travam.
func super_travado() -> bool:
	return game != null and stats != null and game.super_travado(team, stats.id)


func super_nome() -> String:
	return stats.super_nome if stats.super_nome != "" else "Super " + stats.power_name


func add_super(amount: float) -> void:
	if amount <= 0.0 or not alive or _super_t > 0.0 or _sombra_t > 0.0 or stats.power == "nenhum":
		return
	var was_ready := super_carga >= POWER_MAX
	super_carga = minf(super_carga + amount, POWER_MAX)
	if is_player and not was_ready and super_carga >= POWER_MAX:
		Sfx.play_ui("power_ready")
		game.hud.show_big("SUPER pronto! R: %s" % super_nome(), Color(1.0, 0.82, 0.3), 1.6)


## Invisível para os bots inimigos (a mais de sombra_visto m)?
func na_sombra_para(quem: Unit) -> bool:
	if _disfarce_t > 0.0 and quem.team != team:
		return true  # Mujina com o rosto de um deles: os bots não a veem como inimiga
	return _sombra_t > 0.0 and quem.team != team \
		and quem.global_position.distance_to(global_position) > Config.cfg.sombra_visto


func _use_super() -> void:
	if not super_ready() or not alive or carried_princess or _dodge_t > 0.0 or _equip_t > 0.0 or _spin_t > 0.0 or _ciranda_t > 0.0:
		return
	var cfg := Config.cfg
	super_carga = 0.0
	_agito = 1.0
	# Abertura do super: mais forte que a do E (tela na cor do personagem, tempo
	# quase para) e diferente para cada um (Assinatura.abrir_r, Ciclo 2.24).
	if is_player:
		game.camera.add_trauma(0.6)
		game.camera.punch_fov(7.0)
		game.hud.flash(Color(Assinatura.cor_flash(self), 0.35), 0.45)
		game.slowmo(0.18, 0.3)
		game.hud.show_big(super_nome() + "!", Assinatura.cor(self).lightened(0.25), 1.2)
	else:
		game.camera.shake_at(global_position, 0.35)
	FxPoder.abrir_super(self)
	Sfx.play("magia_estouro", global_position, 0.03, 0.85)
	if Sfx.has(stats.som_super):
		Sfx.play(stats.som_super, global_position, 0.02, 1.0, 2.0)
	else:
		Sfx.play("poder_boom", global_position, 0.04, 0.8)
	match stats.super_tipo:
		"proprio":
			if not Herois.super_proprio(self):
				super_carga = POWER_MAX  # não saiu (sem alvo): devolve a barra
				return
		"sombra":
			_sombra_t = cfg.sombra_tempo
			_aplicar_sombra(true)
			Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(0.15, 0.1, 0.25), 30, 6.0)
			Magia.bola(game, global_position + Vector3(0, 1.0, 0), "sombra", 1.8, 0.5)
			_play_once("Dodge_Forward", 0.3)
		_:
			# O poder E da classe em versão gigante: o stats vira uma cópia
			# ampliada enquanto o poder age (quem lê stats durante o efeito,
			# como o giro do Redemoinho, também vê os números grandes).
			_stats_normal = stats
			var s: ClassStats = stats.duplicate()
			s.power_radius *= cfg.super_mult_raio
			s.power_value *= cfg.super_mult_valor
			s.power_duration *= cfg.super_mult_duracao
			stats = s
			_super_t = s.power_duration + 1.5
			var p0 := power
			power = POWER_MAX
			_power_active_t = 0.0
			# Ciclo 2.22: antes o teste era "Chi > 0 depois = não saiu", mas o
			# Selo e a Fúria ferem no mesmo quadro e o dano devolve Chi; o Super
			# era "devolvido" e saía de novo a cada quadro (5 a 20 seguidos).
			if not _use_power():  # o poder não saiu (ocupado): devolve tudo
				stats = _stats_normal
				_stats_normal = null
				_super_t = 0.0
				super_carga = POWER_MAX
				power = p0
				return
			# O super não gasta o Chi do E; o Chi que o dano dele rendeu fica.
			power = minf(p0 + power, POWER_MAX)


func _tick_super(delta: float) -> void:
	if _super_t > 0.0:
		_super_t -= delta
		if _super_t <= 0.0 and _stats_normal:
			stats = _stats_normal
			_stats_normal = null
	if _sombra_t > 0.0:
		_sombra_t -= delta
		if _sombra_t <= 0.0:
			_fim_sombra()


## Esconde (ou mostra) o corpo para quem é do outro time do jogador: o inimigo
## vê só um vulto que some; o próprio time vê o corpo translúcido, de fantasma.
func _aplicar_sombra(sumir: bool, esconder := true) -> void:
	var inimigo_do_jogador := game.player != null and game.player.team != team
	# Aliado: corpo translúcido de fantasma. Troca o material de cada pedaço pela
	# versão translúcida (cache) e devolve no fim; sem sombra no chão enquanto dura.
	# (GeometryInstance3D.transparency não pega no Compatibility/WebGL com o toon.)
	for mi in _meshes:
		if sumir and not mi.has_meta("sombra_orig"):
			var orig := []
			if mi.material_override:
				orig.append(mi.material_override)
				mi.material_override = _fantasma_de(mi.material_override)
			else:
				for i in mi.get_surface_override_material_count():
					orig.append(mi.get_surface_override_material(i))
					mi.set_surface_override_material(i, _fantasma_de(mi.get_active_material(i)))
			mi.set_meta("sombra_orig", orig)
			mi.set_meta("sombra_cast", mi.cast_shadow)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif not sumir and mi.has_meta("sombra_orig"):
			var orig: Array = mi.get_meta("sombra_orig")
			if mi.material_override:
				mi.material_override = orig[0]
			else:
				for i in orig.size():
					mi.set_surface_override_material(i, orig[i])
			mi.cast_shadow = mi.get_meta("sombra_cast")
			mi.remove_meta("sombra_orig")
			mi.remove_meta("sombra_cast")
	if _visual:
		_visual.visible = not (sumir and inimigo_do_jogador and esconder)
	if _hp_root:
		_hp_root.visible = not (sumir and inimigo_do_jogador and esconder)


## Versão translúcida de um material do corpo: o toon troca de shader (mesmos
## parâmetros, sem contorno nem raio X); o neon e o resto ganham alfa.
static func _fantasma_de(m: Material) -> Material:
	if m == null:
		return null
	var f: Material = _fantasma_cache.get(m)
	if f:
		return f
	var alfa: float = Config.cfg.sombra_alfa
	if m is ShaderMaterial:
		var sm := m.duplicate() as ShaderMaterial
		sm.shader = TOON_FANTASMA
		sm.next_pass = null
		sm.set_shader_parameter("fantasma", alfa)
		f = sm
	elif m is BaseMaterial3D:
		var bm := m.duplicate() as BaseMaterial3D
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		bm.albedo_color.a *= 1.0 - alfa
		bm.next_pass = null
		f = bm
	else:
		f = m
	_fantasma_cache[m] = f
	return f


func _fim_sombra() -> void:
	_sombra_t = 0.0
	_aplicar_sombra(false)
	if game:
		Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(0.15, 0.1, 0.25), 18, 5.0)
		if alive:
			Sfx.play("sombra_sai", global_position, 0.05)


## true = o poder saiu (o Super usa isto para saber se devolve a barra).
func _use_power() -> bool:
	if not power_ready() or _dodge_t > 0.0 or _equip_t > 0.0 or _spin_t > 0.0 or _ciranda_t > 0.0:
		return false
	if carried_princess:
		return false
	power = 0.0
	_agito = 1.0
	_cancel_skill()
	var som_proprio := Sfx.has(stats.som_poder)
	if not som_proprio:
		Sfx.play("power", global_position, 0.03)
	if is_player:
		# "Super flash": clarão na cor do papel, zoom e o tempo quase para.
		game.camera.add_trauma(0.42)
		game.camera.punch_fov(4.5)
		game.hud.flash(Color(stats.hat_color.lightened(0.4), 0.22), 0.3)
		game.slowmo(0.3, 0.16)
		game.on_player_power()
	else:
		game.camera.shake_at(global_position, 0.25)
	FxPoder.lancar(self)
	Sfx.play(FxPoder.som_elemento(self), global_position, 0.05, 1.0, -2.0)
	# Nível 3 (E): marca no chão que fica e o som cheio (taiko + estrondo).
	FxProjetil.marca_chao(game, global_position, Color(stats.hat_color.darkened(0.7), 0.4), 1.8, 2.5)
	if som_proprio:
		Sfx.play(stats.som_poder, global_position, 0.03, 1.0, 2.5)
	else:
		Sfx.play("poder_boom", global_position, 0.04)
	match stats.power:
		"redemoinho":
			_spin_t = stats.power_duration
			_spin_tick = 0.0
			_power_active_t = stats.power_duration
			_play_once("2H_Melee_Attack_Spinning", stats.power_duration)
			Fx.ring(game, global_position, Color(1, 0.85, 0.4, 0.9), stats.power_radius * 1.4)
			FxPoder.redemoinho(self)
		"chuva_de_flechas":
			var to := aim_point - global_position
			to.y = 0
			var center := global_position + to.limit_length(stats.attack_range * 1.4)
			center.y = game.arena.ground_y(center.x, center.z, global_position.y + 3.0)
			var rain := ArrowRain.new()
			game.add_child(rain)
			rain.setup(game, self, center, stats.power_radius, stats.power_value * Config.cfg.dano_poder_mult, stats.power_duration)
			_power_active_t = ArrowRain.WARN + stats.power_duration
			_play_upper("1H_Ranged_Shoot", 1.0)
			Fx.burst(game, global_position + Vector3(0, 2.0, 0), Config.team_color(team).lightened(0.5), 16, 9.0)
			FxPoder.chuva(self, center, stats.power_radius)
		"bencao":
			_play_upper("Spellcast_Raise", 1.2)
			Fx.pillar(game, global_position, Color(1, 0.9, 0.5), stats.power_radius)
			FxPoder.bencao(self)
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.power_radius:
					FxPoder.em_aliado(other, Color(1, 0.9, 0.5), self)
					other.heal(other.max_hp() * stats.power_value, self)
					other.give_shield(stats.power_shield, stats.power_duration)
		"furia":
			# Ronin Oni: pancada no chão (onda de choque) e dano x1,8 por um tempo.
			_fury_t = stats.power_duration
			_play_once("2H_Melee_Attack_Chop", 0.45)
			Fx.cracks(game, global_position, Color(1.0, 0.12, 0.08), stats.power_radius)
			Fx.burst(game, global_position + Vector3(0, 0.5, 0), Color(1.0, 0.3, 0.1), 30, 10.0)
			FxPoder.furia(self)
			game.camera.shake_at(global_position, 0.6)
			var hit_any := false
			for other in game.units:
				if not other.alive or other.team == team:
					continue
				var d := other.global_position - global_position
				if absf(d.y) > 1.8:
					continue
				d.y = 0
				if d.length() <= stats.power_radius:
					other.take_damage(stats.power_value * Config.cfg.dano_poder_mult, self, d.normalized() if d.length() > 0.1 else _facing(), 1.6, true, "terra", 3)
					other.launch(7.0)  # a onda de choque arremessa
					hit_any = true
			if hit_any:
				hitstop(Config.cfg.hitstop_time * 1.5)
		"leque":
			# Ninja: leque de shurikens (power_value = dano de cada uma).
			_play_upper("Throw", 1.6)
			var n := int(stats.power_duration)
			var base := aim_dir.normalized()
			for p in _leque(n, stats.power_radius, _mult_poder(), 1.1, base):
				_poder_visual(p)
			Fx.burst(game, global_position + Vector3(0, 1.4, 0) + base, Color(0.4, 1.0, 1.0), 16, 8.0)
			FxPoder.leque(self, base)
			_leque_onda2(n, base)
		"muralha":
			# Sohei: anel de fé no chão onde ele está. Aliados dentro ganham
			# escudo e pressa; inimigos são empurrados para fora pela borda.
			_muralha_t = stats.power_duration
			_muralha_pos = global_position
			_power_active_t = stats.power_duration
			_play_upper("Spellcast_Raise", 1.2)
			_mola(-5.0, 0.0)
			FxPoder.muralha(self, stats.power_radius, stats.power_duration)
			game.camera.shake_at(global_position, 0.35)
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.power_radius:
					other.give_shield(stats.power_value, stats.power_duration)
					other.give_boost(Config.cfg.muralha_pressa, stats.power_duration)
					if other != self:
						FxPoder.em_aliado(other, stats.hat_color.lightened(0.3), self)
		"ciranda":
			# Kusarigama: a corrente gira em volta; pulsos de dano no anel
			# [r/2, r] (o peso bate longe, o cabo perto não corta).
			_ciranda_t = stats.power_duration
			_ciranda_tick = 0.0
			_power_active_t = stats.power_duration
			_play_once("2H_Melee_Attack_Spinning", stats.power_duration)
			FxPoder.ciranda(self, stats.power_radius, stats.power_duration)
		"selo", "coluna_fogo":
			var to := aim_point - global_position
			to.y = 0
			var center := global_position + to.limit_length(stats.attack_range)
			center.y = game.arena.ground_y(center.x, center.z, global_position.y + 3.0)
			var fx := AreaEffect.new()
			game.add_child(fx)
			fx.setup(game, self, center, stats.power, stats.power_radius, stats.power_value * Config.cfg.dano_poder_mult, stats.power_duration)
			_power_active_t = stats.power_duration
			_play_upper("Spellcast_Shoot", 1.2)
			match stats.power:
				"selo":
					FxPoder.selo(game, center, stats.power_radius)
				"coluna_fogo":
					FxPoder.coluna_fogo(game, center, stats.power_radius, stats.power_duration, stats.hat_color)
		"campo_minado":
			# Armadilheiro: anel de minas em volta (power_duration = quantas).
			_play_upper("Interact", 1.6)
			Fx.ring(game, global_position, Color(stats.hat_color, 0.9), stats.power_radius)
			var nm := int(stats.power_duration)
			var pontos: Array = []
			for i in nm:
				var a := TAU * i / nm
				var mina := Trap.new()
				game.add_child(mina)
				mina.set_meta("do_poder", true)  # não conta no trap_max do botão direito
				mina.setup(game, self, global_position + Vector3(cos(a), 0, sin(a)) * stats.power_radius)
				pontos.append(global_position + Vector3(cos(a), 0, sin(a)) * stats.power_radius)
			FxPoder.campo_minado(self, pontos)
			Sfx.play("pickup", global_position, 0.1)
		"bombardeio":
			_bombardeio()
		"mutirao":
			# Carpinteiro: adianta a obra mais próxima e acelera os aliados.
			_play_upper("Cheer", 1.5)
			Fx.ring(game, global_position, Color(1.0, 0.75, 0.35, 0.9), stats.power_radius)
			var of := game.nearest_oficina(team, global_position, stats.power_radius * 2.0, true)
			if of:
				of.add_progress(stats.power_value, self)
				FxPoder.mutirao(self, of)
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.power_radius:
					other.give_boost(1.25, stats.power_duration)
					FxPoder.rastro(other, Color(1.0, 0.75, 0.35), stats.power_duration)
		_:
			Herois.poder(self)
	return true


## Lâmina Dupla: atravessa até power_radius m na mira, cortando quem estiver
## perto da linha (distância ponto-segmento < 1,6 m).
func _corte_relampago(dist := -1.0, dano := -1.0, poder := true) -> void:
	if dist < 0.0:
		dist = stats.power_radius
	if dano < 0.0:
		dano = stats.power_value * Config.cfg.dano_poder_mult * damage_mult()
	var dir := aim_dir.normalized()
	var from := global_position
	var to := from + dir * dist
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1, 0), to + Vector3(0, 1, 0), Config.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		to = Vector3(hit.position.x, from.y, hit.position.z) - dir * 0.8
	to = game.arena.clamp_to_arena(to)
	var atingidos := []
	for other in game.units:
		if not other.alive or other.team == team:
			continue
		var p := other.global_position
		var seg := to - from
		var tt := clampf((p - from).dot(seg) / maxf(seg.length_squared(), 0.01), 0.0, 1.0)
		if p.distance_to(from + seg * tt) < 1.6:
			atingidos.append(other)
			other.take_damage(dano, self, dir, 1.2, true)
	global_position = to
	reset_physics_interpolation()
	FxPoder.q_investida(self, from, to)
	Fx.burst(game, from + Vector3(0, 1, 0), Color(0.4, 1.0, 1.0), 10, 6.0)
	Fx.burst(game, to + Vector3(0, 1, 0), Color(0.4, 1.0, 1.0), 14, 6.0)
	if poder:
		FxPoder.corte_relampago(self, from, to, atingidos)
	else:
		Sfx.play("swing", from, 0.1)
		_mola(0.0, 6.0)  # estica para a frente no avanço
	_play_once("Dualwield_Melee_Attack_Stab" if poder else "1H_Melee_Attack_Stab", 0.3)
	if is_player:
		game.camera.add_trauma(0.4 if poder else 0.25)


func give_shield(amount: float, duration: float) -> void:
	amount *= Config.cfg.vida_mult  # escudo acompanha a vida maior
	_shield = maxf(_shield, amount)
	_shield_t = duration
	if _shield_mesh == null:
		if _shield_res.is_empty():
			var sphere := SphereMesh.new()
			sphere.radius = 1.25
			sphere.height = 2.6
			sphere.radial_segments = 16
			sphere.rings = 8
			_shield_res = [sphere, Fx.bubble(Color(1.0, 0.85, 0.4))]
		_shield_mesh = MeshInstance3D.new()
		_shield_mesh.mesh = _shield_res[0]
		_shield_mesh.material_override = _shield_res[1]
		_shield_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_shield_mesh.position.y = 1.15
		add_child(_shield_mesh)
	_shield_mesh.visible = true


func give_boost(mult: float, duration: float) -> void:
	_boost_mult = mult
	_boost_t = duration


## Redemoinho (pulsos de dano em volta), escudo e corrida perdendo o efeito.
func _tick_buffs(delta: float) -> void:
	if _spin_t > 0.0:
		_spin_t -= delta
		_spin_tick -= delta
		# Vórtice: puxa quem está perto para dentro do giro.
		for other in game.units:
			if not other.alive or other.team == team or other.carried_princess:
				continue
			var de := global_position - other.global_position
			de.y = 0
			var dist := de.length()
			if dist > 0.9 and dist <= stats.power_radius * Config.cfg.redemoinho_puxa_raio \
					and other._knock.length() < Config.cfg.redemoinho_puxa:
				other._knock = de / dist * Config.cfg.redemoinho_puxa
		if _spin_tick <= 0.0:
			_spin_tick = SPIN_TICK
			Fx.slash(game, global_position + Vector3(0, 0.9, 0), _facing(), stats.power_radius, 360.0, Color(1, 0.72, 0.2), 0.0, true)
			Sfx.play("swing", global_position, 0.2)
			for other in game.units:
				if not other.alive or other.team == team:
					continue
				var to := other.global_position - global_position
				to.y = 0
				if to.length() <= stats.power_radius + 0.4:
					other.take_damage(stats.power_value * Config.cfg.dano_poder_mult, self, to.normalized() if to.length() > 0.1 else _facing(), 0.8)
		if _spin_t <= 0.0:
			_anim_lock = 0.0
	if _shield_t > 0.0:
		_shield_t -= delta
		if _shield_t <= 0.0 or _shield <= 0.0:
			_shield = 0.0
			_shield_t = 0.0
			if _shield_mesh:
				_shield_mesh.visible = false
	if _slow_t > 0.0:
		_slow_t -= delta
	if _preso_t > 0.0:
		_preso_t -= delta
	if _muralha_t > 0.0:
		_muralha_t -= delta
		_tick_muralha()
	if _ciranda_t > 0.0:
		_ciranda_t -= delta
		_ciranda_tick -= delta
		if _ciranda_tick <= 0.0:
			_ciranda_tick = Config.cfg.ciranda_intervalo
			_pulso_ciranda()
		if _ciranda_t <= 0.0:
			_anim_lock = 0.0
	if _silence_t > 0.0:
		_silence_t -= delta
		if fmod(_silence_t, 0.4) < delta:
			Fx.zap(game, global_position + Vector3(-0.5, 2.3, 0), global_position + Vector3(0.5, 1.2, 0.2), Color(0.6, 0.9, 1.0), 3)
	if _fury_t > 0.0:
		_fury_t -= delta
		if fmod(_fury_t, 0.15) < delta:
			Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.15, 0.1), 3, 3.0)
	_tiro_lento_t = maxf(_tiro_lento_t - delta, 0.0)
	if _dmg_boost_t > 0.0:
		_dmg_boost_t -= delta
		if fmod(_dmg_boost_t, 0.25) < delta:
			Fx.burst(game, global_position + Vector3(0, 1.6, 0), Color(1.0, 0.35, 0.3), 2, 2.0)
	Herois.tick(self, delta)
	if building_t > 0.0 and game and game.placar:
		game.placar.somar(self, "obra_s", delta)
	building_t = maxf(building_t - delta, 0.0)
	# Regeneração fora de combate: dH/dt = r·Hmax depois de regen_delay s calmo.
	_calm_t += delta
	if _calm_t > Config.cfg.regen_delay and hp < max_hp():
		hp = minf(hp + Config.cfg.regen_rate * max_hp() * delta, max_hp())
		_update_hp_bar()
	if _boost_t > 0.0:
		_boost_t -= delta
		_boost_fx_t -= delta
		if _boost_fx_t <= 0.0 and _move_vel.length() > 2.0:
			_boost_fx_t = 0.12
			Fx.burst(game, global_position + Vector3(0, 0.2, 0), Color(1, 0.85, 0.4), 3, 2.0)


## Muralha de Fé: inimigo dentro do anel é jogado até a borda (+0,5 m).
## v0 = sqrt(2·a·s) com a = KNOCK_DECAY: o empurrão freia e para na borda.
func _tick_muralha() -> void:
	var r := stats.power_radius
	for other in game.units:
		if not other.alive or other.team == team or other.carried_princess:
			continue
		var d := other.global_position - _muralha_pos
		if absf(d.y) > 1.8:
			continue
		d.y = 0
		var dist := d.length()
		if dist >= r:
			continue
		var dn := d / dist if dist > 0.1 else Vector3.RIGHT
		var v := sqrt(2.0 * KNOCK_DECAY * (r + 0.5 - dist))
		if other._knock.dot(dn) < v * 0.8:
			other._knock = dn * v
			Fx.burst(game, other.global_position + Vector3(0, 1.0, 0), stats.hat_color.lightened(0.4), 5, 3.0)


func _pulso_ciranda() -> void:
	var r := stats.power_radius
	Fx.slash(game, global_position + Vector3(0, 0.8, 0), _facing(), r, 360.0, stats.hat_color.lightened(0.3), 0.0, false)
	Sfx.play("swing", global_position, 0.2, 1.2, -4.0)
	for other in game.units:
		if not other.alive or other.team == team:
			continue
		var d := other.global_position - global_position
		if absf(d.y) > 1.8:
			continue
		d.y = 0
		var dist := d.length()
		if dist < r * 0.45 or dist > r + 0.4:
			continue
		other.take_damage(stats.power_value * Config.cfg.dano_poder_mult, self, d / maxf(dist, 0.1), 0.7)


func _end_buffs() -> void:
	Herois.limpar(self)
	_fury_t = 0.0
	_silence_t = 0.0
	_preso_t = 0.0
	guarda = 0.0
	_guarda_trava_t = 0.0
	_muralha_t = 0.0
	_ciranda_t = 0.0
	_dmg_boost_t = 0.0
	building_t = 0.0
	_spin_t = 0.0
	_power_active_t = 0.0
	_boost_t = 0.0
	_slow_t = 0.0
	_shield = 0.0
	_shield_t = 0.0
	if _shield_mesh:
		_shield_mesh.visible = false


# --- Carregar princesa e bolo -------------------------------------------------

func pick_up_princess(p: Princess) -> void:
	drop_tora()
	carried_princess = p
	p.pick_up(self)
	Sfx.play("pickup", global_position)
	# Arrancada do roubo: alguns segundos mais rápido para sair do pátio.
	if Config.cfg.steal_boost_time > 0.0:
		give_boost(Config.cfg.steal_boost_mult, Config.cfg.steal_boost_time)


func drop_princess() -> void:
	if carried_princess:
		carried_princess.drop(global_position + aim_dir * 1.2)
		carried_princess = null


# --- Visual -------------------------------------------------------------------

func _animate(horizontal: Vector3) -> void:
	# Inclinação: o corpo tomba para a frente proporcional à velocidade
	# (como quem corre de verdade: o torque do atrito no pé pede o tronco à frente).
	var lean_target := clampf(horizontal.length() / 9.0, 0.0, 1.0) * 0.16
	if _dodge_t > 0.0:
		lean_target = 0.6 if stats.dash_estilo == "ninja" else 0.35
		if stats.dash_estilo == "tropeco":
			lean_target = 0.85  # quase de cara no chão
	# Cambalhota: o modelo gira 360° para a frente em volta do centro do corpo
	# (origem do nó fica nos pés: compensa a posição para o giro não "cavar" o chão).
	if _rolo > 0.0:
		if _dodge_t > 0.0:
			_rolo = TAU * (1.0 - _dodge_t / DODGE_TIME)
		else:
			_rolo = 0.0
			if _model:
				_model.position = Vector3.ZERO
	if _model and _rolo > 0.0:
		var h := 0.85 * stats.escala_modelo
		_model.rotation.x = _rolo
		_model.position = Vector3(0, h * (1.0 - cos(_rolo)), -h * sin(_rolo))
		return
	_lean = lerpf(_lean, lean_target, 1.0 - exp(-10.0 * get_physics_process_delta_time()))
	if _model:
		_model.rotation.x = _lean
	if _anim_lock > 0.0:
		return
	var moving := horizontal.length() > 0.8
	if reanimando:
		# Reanimando: a Kitsune canaliza a benção; o resto puxa de costas.
		if eh_mago():
			_play("Spellcasting")
		else:
			_play_upper("Use_Item", 1.0, true)
			_play(("Walking_Backwards" if _anim.has_animation("Walking_Backwards") else "Walking_B") if moving else "Idle")
		if _anim:
			_anim.speed_scale = 1.0
		return
	# Construindo: martela em loop (só o tronco, as pernas seguem livres).
	if building_t > 0.0 and not moving and _attack_t <= 0.0:
		_play_upper("1H_Melee_Attack_Chop", 0.9, true)
	elif _upper and _upper.current_animation == "tronco/1H_Melee_Attack_Chop" and _upper.get_current_animation_length() > 0.0 and building_t <= 0.0:
		_upper.stop()
	if carried_princess or carried_tora:
		_play("Walking_B" if moving else "Idle")
	else:
		_play(stats.anim_run if moving else stats.anim_idle)
	if _anim and moving:
		_anim.speed_scale = clampf(horizontal.length() / 6.0, 0.7, 1.4)
	elif _anim:
		_anim.speed_scale = 1.0


func _play(anim_name: String, blend := 0.15) -> void:
	if _anim == null or anim_name == _current_anim or not _anim.has_animation(anim_name):
		return
	_current_anim = anim_name
	_anim.play(anim_name, blend)


## Na mão da catapulta / voando: pose de salto, sem física própria.
func pose_voo(ligado: bool) -> void:
	velocity = Vector3.ZERO
	_knock = Vector3.ZERO
	_move_vel = Vector3.ZERO
	if ligado:
		_play("Jump_Idle", 0.1)
	else:
		_current_anim = ""


## Pouso do meteoro de Chi: levanta do chão e fica um instante parado.
func aterrissagem() -> void:
	_play_once("Lie_StandUp", 0.6)
	_tremor_t = 0.25


func _play_once(anim_name: String, lock: float, velocidade := 1.0) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	_current_anim = anim_name
	_anim.speed_scale = velocidade
	_anim.play(anim_name, 0.05)
	_anim.seek(0.0, true)
	_anim_lock = lock


func play_cheer(duration := 999.0) -> void:
	_play_once("Cheer", duration)


## Gesto curto só no tronco (pegar item, interagir).
func play_gesture(anim_name: String, speed := 1.5) -> void:
	_play_upper(anim_name, speed)


# --- Corpo de desenho ----------------------------------------------------------
# Cada mola é um oscilador amortecido x'' = −ω²(x − alvo) − 2ζω·x'.
# Com ω = 26 rad/s (~4 Hz) e ζ = 0,32 ela passa do ponto uma vez e meia e
# assenta em ~0,3 s: o "boing" de desenho. Um peteleco de velocidade v dá um
# pico de ~v/ω (v = 7 → ~27% de esticão).
const MOLA_W := 26.0
const MOLA_ZETA := 0.32
const MORTE_VY := 5.5   # pulinho da morte: sobe v²/2g ≈ 0,5 m
const MORTE_G := 30.0


## Liga o medidor do poder ao material (uniform poder_carga do toon). Só
## manda quando muda ~2%, para não mexer no material todo quadro.
func _tick_aura() -> void:
	_tick_agito()
	var c := clampf(power / POWER_MAX, 0.0, 1.0) if alive else 0.0
	if absf(c - _carga_vista) < 0.02 and not (c >= 1.0 and _carga_vista < 1.0):
		return
	_carga_vista = c
	for mi in _meshes:
		mi.set_instance_shader_parameter("poder_carga", c)


## Balanço das peças (balanco.gdshaderinc): caudas e fogo agitam no ataque e
## no poder, voltam ao repouso em ~0,5 s e caem/apagam na morte.
func _tick_agito() -> void:
	if _pecas == null:
		return
	if not alive:
		_agito = -1.0
	elif _agito > 0.0:
		_agito = maxf(_agito - get_physics_process_delta_time() * 2.0, 0.0)
	else:
		_agito = 0.0
	if absf(_agito - _agito_visto) < 0.04 and not (_agito == 0.0 and _agito_visto != 0.0):
		return
	_agito_visto = _agito
	_pecas.set_instance_shader_parameter("agito", _agito)


func _exagero() -> float:
	return Config.cfg.exagero_animacao * (stats.exagero if stats else 1.0)


## Peteleco nas molas: dv vertical (+ estica) e df para a frente.
func _mola(dv: float, df: float) -> void:
	var k := _exagero()
	_sq_v += dv * k
	_st_v += df * k


func _tick_corpo(delta: float, horizontal: Vector3, congelado := false) -> void:
	var k := _exagero()
	if k <= 0.0:
		return
	var off := Vector3.ZERO
	var alvo := 0.0
	# Quique ao andar: dois pulinhos por ciclo do clipe de corrida (um por
	# passo), em fase com o clipe para não "bater" com as pernas.
	var spd := horizontal.length()
	if alive and spd > 0.8 and _dodge_t <= 0.0 and _no_chao and _anim and _anim.current_animation != "":
		var ciclo := _anim.current_animation_length
		var fase := TAU * _anim.current_animation_position / ciclo if ciclo > 0.0 else 0.0
		var s := absf(sin(fase))
		var forca := clampf(spd / 6.0, 0.4, 1.2) * k
		off.y = s * 0.08 * forca
		alvo = (s - 0.5) * 0.07 * forca  # estica no alto do passo, amassa no apoio
	if not congelado:
		var w2 := MOLA_W * MOLA_W
		var c := 2.0 * MOLA_ZETA * MOLA_W
		# Euler semi-implícito: estável enquanto ω·Δt < 2 (aqui 0,43 a 60 Hz).
		_sq_v += (-w2 * (_sq - alvo) - c * _sq_v) * delta
		_sq += _sq_v * delta
		_st_v += (-w2 * _st - c * _st_v) * delta
		_st += _st_v * delta
	# Morte cômica: pulinho girando, cai e vira panqueca.
	if _morte_t >= 0.0:
		var t0 := _morte_t
		_morte_t += delta
		var voo := 2.0 * MORTE_VY / MORTE_G
		if _morte_t < voo:
			off.y += MORTE_VY * _morte_t - 0.5 * MORTE_G * _morte_t * _morte_t
			_visual.rotation.y += TAU / voo * delta  # uma volta inteira no ar
		elif t0 < voo:
			_mola(-10.0, 0.0)
			Fx.burst(game, global_position + Vector3(0, 0.3, 0), Color(0.75, 0.72, 0.7), 10, 3.0)
			Fx.burst(game, global_position + Vector3(0, 1.4, 0), Color(1.0, 0.9, 0.3), 5, 2.0)
	# Volume constante: V·F na vertical/frente, os outros eixos compensam
	# (sx·sy·sz = 1), como massa de modelar.
	var v := 1.0 + clampf(_sq, -0.45, 0.6)
	var f := 1.0 + clampf(_st, -0.35, 0.55)
	var alvo_g: float = Config.cfg.furia_escala if _fury_t > 0.0 else (Config.cfg.festa_escala if _festa_t > 0.0 else 1.0)
	_gigante = move_toward(_gigante, alvo_g, delta * 2.5)
	_visual.scale = Vector3(1.0 / sqrt(v * f), v / sqrt(f), f / sqrt(v)) * _gigante
	# Tremor de quem apanha: chacoalho aleatório que some em ~0,2 s.
	if _tremor_t > 0.0:
		_tremor_t -= delta
		var amp := 0.09 * k * clampf(_tremor_t / 0.2, 0.0, 1.0)
		off.x += randf_range(-amp, amp)
		off.z += randf_range(-amp, amp)
	if stats.flutua and alive:
		# Tennin: boia acima do chão com um balanço lento (o corpo de colisão não sobe).
		off.y += 0.28 + 0.07 * sin(Time.get_ticks_msec() * 0.0025 + get_instance_id() % 7)
	_visual.position = off


func _update_flash(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		for mi in _meshes:
			mi.material_overlay = _flash_mat if _flash_t > 0.0 else null


func _build_team_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7
	torus.outer_radius = 0.9 if not is_player else 1.0
	torus.rings = 24
	ring.mesh = torus
	ring.scale = Vector3(1, 0.05, 1)
	ring.position.y = 0.05
	var c := Config.team_color(team)
	if is_player:
		c = c.lerp(Color(1, 1, 0.6), 0.45)
	ring.material_override = Fx.unshaded(Color(c, 0.85), true)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	_ring = ring


func _build_hp_bar() -> void:
	_hp_root = Node3D.new()
	_hp_root.position = Vector3(-0.6, 2.75, 0)
	add_child(_hp_root)
	# Fundo e preenchimento num quad só (barra_vida.gdshader, Ciclo 2.17):
	# uma chamada de desenho por boneco em vez de duas.
	_hp_fill = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.2, 0.16)
	q.center_offset = Vector3(0.6, 0, 0)
	_hp_fill.mesh = q
	var key := "barra|%d" % team
	var fill_mat: ShaderMaterial = _barra_cache.get(key)
	if fill_mat == null:
		fill_mat = ShaderMaterial.new()
		fill_mat.shader = BARRA_VIDA
		fill_mat.set_shader_parameter("cor_cheia", Config.team_color(team).lightened(0.2))
		fill_mat.render_priority = 1
		_barra_cache[key] = fill_mat
	_hp_fill.material_override = fill_mat
	_hp_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hp_root.add_child(_hp_fill)


func _update_hp_bar() -> void:
	if _hp_fill == null:
		return
	var r := clampf(hp / max_hp(), 0.0, 1.0)
	_hp_fill.set_instance_shader_parameter("fracao", r)
	_hp_fill.set_instance_shader_parameter("rastro", maxf(hp_rastro, r))
	_hp_root.visible = alive and (r < 0.999 or is_player)


func _build_player_marker() -> void:
	_player_marker = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.28
	cone.bottom_radius = 0.0
	cone.height = 0.45
	_player_marker.mesh = cone
	_player_marker.material_override = Fx.unshaded(Color(1, 0.9, 0.3))
	_player_marker.position = Vector3(0, 3.35, 0)
	add_child(_player_marker)
	var tw := _player_marker.create_tween().set_loops()
	tw.tween_property(_player_marker, "position:y", 3.6, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_player_marker, "position:y", 3.35, 0.5).set_trans(Tween.TRANS_SINE)
