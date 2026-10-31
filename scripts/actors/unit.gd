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
const LOOPING_ANIMS := ["Idle", "Running_A", "Running_B", "Walking_A", "Walking_B", "Sit_Floor_Idle", "Cheer", "2H_Melee_Idle", "Spellcasting", "1H_Ranged_Aiming", "2H_Melee_Attack_Spinning"]

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
var wants_attack := false
var wants_block := false
var wants_quick := false  # Q: habilidade rápida (recarga curta)
var wants_power := false  # E: poder de Chi (medidor cheio)
var wants_dodge := false

## Medidor de Glacê (0 a POWER_MAX). Cheio = poder do Q liberado.
var power := 0.0

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
var _launch_vy := 0.0
var _calm_t := 0.0              # s desde a última vez que bateu ou apanhou (regeneração)           # impulso para cima pendente (Fúria, explosões, golpe final)
var _move_vel := Vector3.ZERO   # velocidade da caminhada/esquiva
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
var _aim_line: MeshInstance3D
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
var _trap_cd := 0.0
var _quick_cd := 0.0  # recarga do Q
var _escudo_def: MeshInstance3D  # arco na frente enquanto defende
var _silence_t := 0.0   # Selo do Onmyoji: sem ataque, botão direito nem poder
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
var _carga_vista := -1.0  # último poder_carga mandado ao material
var _morte_t := -1.0  # s desde a morte (pulinho cômico); < 0 = vivo
## Construindo uma oficina (marcado pela Oficina a cada quadro).
var building_t := 0.0

static var _flash_mat: StandardMaterial3D
static var _merged_body := {}  # caminho do .tres da classe -> ArrayMesh do corpo
static var _upper_libs := {}  # caminho do modelo -> AnimationLibrary filtrada
static var _shield_res: Array = []  # [malha, material] compartilhados da bolha de escudo


func setup(p_game: Game, p_team: int, p_is_player: bool, start_class: ClassStats) -> void:
	game = p_game
	team = p_team
	is_player = p_is_player
	collision_layer = Config.LAYER_UNITS
	collision_mask = Config.LAYER_WORLD
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
	stats = new_stats
	if not lenhador():
		drop_tora()
	hp = max_hp()  # trocar de chapéu cura por completo
	if _model:
		_model.queue_free()
	_model = stats.model.instantiate()
	_visual.add_child(_model)
	_meshes.clear()
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.visible = stats.visible_meshes.has(mi.name)
		if mi.visible:
			_meshes.append(mi)
		if mi.name == stats.cape_mesh:
			var mat := mi.get_active_material(0).duplicate() as StandardMaterial3D
			if mat:
				mat.albedo_color = Config.team_color(team).lightened(0.15)
				mi.material_override = mat
	_merge_body_parts()
	if stats.estilo_ninja != "" or stats.escala_cabeca != 1.0:
		var pecas := NinjaVisual.aplicar(_model, _meshes, stats.estilo_ninja, Config.team_color(team), stats.escala_cabeca, Settings.quality >= 2, stats.escala_extremidades)
		if pecas:
			_meshes.append(pecas)
	_model.scale = Vector3.ONE * stats.escala_modelo
	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for a in LOOPING_ANIMS + [stats.anim_idle, stats.anim_run]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_setup_upper_player()
	_current_anim = ""
	_play(stats.anim_idle)
	_update_hp_bar()
	for mi in _meshes:
		mi.set_instance_shader_parameter("cor_poder", stats.hat_color)
	_carga_vista = -1.0
	class_changed.emit(self)


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


## Pode atacar/usar habilidade agora (sem máscara nem tora nos braços, fora
## do dash, do chapéu, do Redemoinho e do Selo).
func maos_livres() -> bool:
	return not carried_princess and not carried_tora and _dodge_t <= 0.0 and _equip_t <= 0.0 \
			and _spin_t <= 0.0 and _silence_t <= 0.0


## Corta madeira (Construtor e variações: quem tem velocidade_obra).
func lenhador() -> bool:
	return stats.velocidade_obra > 0.0


func drop_tora() -> void:
	if carried_tora:
		carried_tora.largar()


func is_busy_carrying() -> bool:
	return carried_princess != null


func hp_ratio() -> float:
	return hp / max_hp()


## No meio de um golpe (antecipação ou animação): para os bots lerem o combo.
func atacando() -> bool:
	return _attack_t > 0.0 or _windup_t > 0.0


func dash_pronto() -> bool:
	return _dodge_cd <= 0.0 and _dodge_t <= 0.0 and not carried_princess


## Vida máxima de verdade: a da classe vezes GameConfig.vida_mult.
func max_hp() -> float:
	return stats.max_hp * Config.cfg.vida_mult


func current_speed() -> float:
	var s := stats.move_speed
	if carried_princess:
		s *= stats.carry_speed_mult * (1.0 - carried_princess.fatness * Config.cfg.fat_slowdown)
	if lenhador():
		# Cada casinha erguida pelo time deixa a linha do Construtor mais rápida.
		s *= 1.0 + Config.cfg.construtor_vel_por_oficina * game.oficinas_prontas(team)
	if carried_tora:
		s *= Config.cfg.tora_vel_mult
	if _boost_t > 0.0:
		s *= _boost_mult
	if _slow_t > 0.0:
		s *= _slow_mult
	return s


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
	power = minf(power + amount, POWER_MAX)
	_power_idle = 0.0
	if is_player and not was_ready and power >= POWER_MAX and stats.power != "nenhum":
		Sfx.play_ui("power_ready")
		game.hud.show_big("Chi cheio! [Q] %s" % stats.power_name, Color(1, 0.75, 0.9), 1.4)


# --- Loop principal -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not alive:
		# Quem morre no ar cai (sem isso o corpo ficava parado no ar).
		if not is_on_floor():
			velocity = Vector3(0, velocity.y - 30.0 * delta, 0)
			move_and_slide()
		_tick_corpo(delta, Vector3.ZERO)
		_tick_aura()
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn()
		return

	# Hitstop: no impacto de um golpe, atacante e alvo congelam por ~60 ms.
	# É o Δt do contato (J = F·Δt) ficando visível; o empurrão sai depois.
	if _hitstop_t > 0.0:
		_hitstop_t -= delta
		if _hitstop_t <= 0.0:
			_set_anim_speed(1.0)
		_tick_corpo(delta, Vector3.ZERO, true)  # a pose congela, o tremor não
		return

	if brain and brain.has_method("tick"):
		brain.tick(delta)

	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_heal_cd = maxf(_heal_cd - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	_attack_t = maxf(_attack_t - delta, 0.0)
	_combo_t = maxf(_combo_t - delta, 0.0)
	_power_active_t = maxf(_power_active_t - delta, 0.0)
	_tick_power(delta)
	_tick_buffs(delta)

	if wants_dodge and _dodge_cd <= 0.0 and not carried_princess and _spin_t <= 0.0:
		_start_dodge()
	wants_dodge = false

	if _dodge_t > 0.0:
		_dodge_t -= delta
		_move_vel = _dodge_dir * DODGE_SPEED
		if _dodge_t <= 0.0:
			_mola(-5.0, -4.0)  # "pouso" do dash: amassa e devolve o esticão
	else:
		var speed := current_speed()
		if _spin_t > 0.0:
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
	move_and_slide()
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
		if _silence_t <= 0.0:
			_use_power()
	if _windup_t > 0.0:
		_windup_t -= delta
		if _windup_t <= 0.0:
			if free_hands:
				_attack_hit()
	elif wants_attack and _attack_cd <= 0.0 and free_hands and not _blocking and _charge_t <= 0.0:
		_attack()
	_animate(horizontal)
	_tick_corpo(delta, horizontal)
	_tick_aura()
	_update_flash(delta)
	_cake_visual.visible = has_cake
	if has_cake:
		_cake_visual.rotation.y += delta * 2.0


func _face(delta: float) -> void:
	var look := Vector3.ZERO
	if _dodge_t > 0.0:
		look = _dodge_dir
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
	_play_once("Dodge_Forward", DODGE_TIME + 0.1)
	Sfx.play("dodge", global_position)
	_windup_t = 0.0  # o dash cancela um golpe que ainda não saiu
	_mola(-1.5, 8.0)  # esticão na direção do dash


func _attack() -> void:
	_attack_cd = stats.attack_cooldown
	var anim := stats.anim_attack
	var mult := 1.0
	var finisher := false
	var combo := stats.combo_anims
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
	_attack_t = minf(_attack_cd, 0.45)
	_play_upper(anim, 1.35)
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
	match stats.attack_kind:
		"melee":
			Sfx.play("swing", global_position, 0.12)
			# Golpes alternam a inclinação do corte; o último é maior e dourado.
			var tilt := 0.0 if combo.size() == 0 else (22.0 if _combo_i % 2 == 0 else -22.0)
			var col := Color(1.0, 0.78, 0.25) if finisher else Color(1, 1, 1)
			var reach := stats.attack_range + (0.9 if finisher else 0.3)
			Fx.slash(game, global_position + Vector3(0, 1.0, 0), dir, reach, stats.attack_arc_deg + (30.0 if finisher else 0.0), col, tilt, finisher)
			var hit_any := false
			for other in game.units:
				if not other.alive or other.team == team:
					continue
				var to := other.global_position - global_position
				if absf(to.y) > 1.8:  # um em cima da muralha, outro embaixo
					continue
				to.y = 0
				if to.length() > stats.attack_range + 0.6:
					continue
				if to.length() > 0.8 and rad_to_deg(dir.angle_to(to.normalized())) > stats.attack_arc_deg / 2.0:
					continue
				other.take_damage(stats.damage * mult * damage_mult(), self, to.normalized(), mult, true)
				if finisher:
					other.launch(3.5)  # golpe final tira o alvo do chão
				hit_any = true
			if lenhador() and game.golpear_plantas(self, dir, stats.attack_range + 0.6, stats.attack_arc_deg):
				hit_any = true
			if hit_any:
				hitstop(Config.cfg.hitstop_time * (1.6 if finisher else 1.0))
				if is_player:
					game.camera.add_trauma(0.4 if finisher else 0.25)
					game.camera.kick(dir, 0.6 if finisher else 0.3)
					if finisher:
						game.camera.punch_fov(2.5)
		"ranged":
			_shoot_arrow(1.0, 1.0)
		"healer":
			Sfx.play("magic", global_position)
			var alvo := _aim_assist(dir)
			if alvo:
				dir = _assisted_dir(dir, alvo)
			game.spawn_projectile(self, global_position + Vector3(0, 1.6, 0) + dir * 0.9, dir, stats.projetil)


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
		if absf(to.y) > 2.5:
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


func _shoot_arrow(dmg_mult: float, speed_mult: float, dir_override := Vector3.ZERO) -> Projectile:
	var dir := aim_dir.normalized() if dir_override == Vector3.ZERO else dir_override
	var to := aim_point - global_position
	to.y = 0
	var mirado := _aim_assist(dir) if dir_override == Vector3.ZERO else null
	if mirado:
		dir = _assisted_dir(dir, mirado)
		# O arco cai na distância do alvo (senão a flecha passa por cima).
		to = mirado.global_position - global_position
		to.y = 0
	Sfx.play("shoot", global_position)
	var p := game.spawn_projectile(self, global_position + Vector3(0, 1.4, 0) + dir * 0.9, dir, stats.projetil)
	p.damage *= dmg_mult
	p.velocity *= speed_mult
	var dist := clampf(to.length(), 6.0 if stats.projetil != "bomba" else 3.0, stats.attack_range * 1.4 * speed_mult)
	if stats.projetil == "shuriken":
		p.velocity.y = (global_position.y + Projectile.TARGET_HEIGHT - p.position.y) / maxf(dist / p.velocity.length(), 0.1)  # reto, na altura do peito
	else:
		var alvo := global_position + to.normalized() * dist
		p.aim_ballistic(dist, game.arena.ground_y(alvo.x, alvo.z, maxf(global_position.y, aim_point.y) + 3.0))
	return p


## Multiplicador de dano de buffs (Fúria, item de dano).
func damage_mult() -> float:
	var m := 1.0
	if _fury_t > 0.0:
		m *= 1.8
	if _dmg_boost_t > 0.0:
		m *= Config.cfg.pickup_damage_mult
	return m


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
	var held := wants_block and free_hands
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
		if quick_ready() and free_hands and not _blocking:
			if _usar_rapida():
				_quick_cd = quick_cooldown()


func tem_rapida() -> bool:
	return stats.skill in ["cura", "tiro_carregado", "armadilha", "investida", "pisao", "corrida"]


func quick_cooldown() -> float:
	match stats.skill:
		"cura":
			return stats.heal_cooldown
		"armadilha":
			return stats.trap_cooldown
	return stats.skill_cooldown


func quick_ready() -> bool:
	return tem_rapida() and _quick_cd <= 0.0


## 0 = acabou de usar, 1 = pronto.
func quick_ratio() -> float:
	return 1.0 - clampf(_quick_cd / maxf(quick_cooldown(), 0.01), 0.0, 1.0)


func quick_restante() -> float:
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
		"corrida":
			_play_upper("Cheer", 1.6)
			Fx.ring(game, global_position, Color(1, 0.8, 0.3, 0.9), stats.skill_radius)
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.skill_radius:
					other.give_boost(stats.skill_value, stats.skill_duration)
					FxPoder.rastro(other, Color(1, 0.8, 0.3), stats.skill_duration)
		_:
			return false
	return true


## Ronin Oni (Q): pisão curto. Mesma física da Fúria em escala menor:
## onda radial, dano cai até a metade na borda, arremessa um pouco.
func _pisao() -> void:
	_play_once("2H_Melee_Attack_Chop", 0.35)
	_mola(-6.0, 0.0)
	Fx.cracks(game, global_position, Color(1.0, 0.35, 0.15), stats.skill_radius)
	Fx.ring(game, global_position, Color(1.0, 0.4, 0.2, 0.9), stats.skill_radius)
	Fx.burst(game, global_position + Vector3(0, 0.4, 0), Color(0.75, 0.6, 0.45), 16, 6.0)
	Sfx.play("hit", global_position, 0.1)
	game.camera.shake_at(global_position, 0.35)
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
			other.take_damage(stats.skill_value * damage_mult() * f, self, d.normalized() if d.length() > 0.1 else _facing(), 1.4, true)
			other.launch(4.5 * f)
			acertou = true
	if acertou:
		hitstop(Config.cfg.hitstop_time * 1.3)


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
		alvo = 0.5 if _block_t <= Config.cfg.parry_janela else 0.22
	mat2.albedo_color.a = move_toward(mat2.albedo_color.a, alvo, delta * 3.0)
	_escudo_def.visible = mat2.albedo_color.a > 0.01


## Estrepes nos pés; passou do limite, a mais antiga do mesmo dono some.
func _place_trap() -> void:
	_trap_cd = stats.trap_cooldown
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
	if _aim_line:
		_aim_line.visible = false


## Linha de mira do tiro carregado: cresce até o alcance e fica dourada na carga máxima.
func _show_aim_line() -> void:
	if not is_player:
		return
	if _aim_line == null:
		_aim_line = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.02, 1.0)
		_aim_line.mesh = box
		_aim_line.material_override = Fx.unshaded(Color(1, 1, 1, 0.6), true)
		_aim_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual.add_child(_aim_line)
	var c := charge_ratio()
	var to := aim_point - global_position
	to.y = 0
	var length := clampf(to.length(), 6.0, stats.attack_range * 1.4 * (1.0 + 0.5 * c))
	_aim_line.visible = true
	_aim_line.scale = Vector3(1.0 + c, 1, length)
	_aim_line.position = Vector3(0, 0.15, length * 0.5)
	var mat := _aim_line.material_override as StandardMaterial3D
	mat.albedo_color = Color(1, 1, 1, 0.35).lerp(Color(1, 0.8, 0.25, 0.9), c)


func _heal() -> void:
	_heal_cd = stats.heal_cooldown
	_play_upper("Spellcast_Raise", 1.3)
	Sfx.play("heal", global_position)
	Fx.ring(game, global_position, Color(0.5, 1.0, 0.6, 0.7), stats.heal_radius)
	var healed := 0.0
	for other in game.units:
		if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.heal_radius:
			healed += other.heal(stats.heal_amount * Config.cfg.vida_mult)
	add_power(healed * Config.cfg.power_per_damage)


## Cura e devolve quanto curou de fato.
func heal(amount: float) -> float:
	if hp >= max_hp() or not alive:
		return 0.0
	var before := hp
	hp = minf(hp + amount, max_hp())
	Fx.damage_number(game, global_position, "+%d" % int(hp - before), Color(0.5, 1, 0.55))
	_update_hp_bar()
	return hp - before


## dir = direção do golpe (de quem bate para quem apanha).
func take_damage(amount: float, attacker: Unit, dir: Vector3, knock_mult := 1.0, melee := false) -> void:
	if not alive:
		return
	if _dodge_t > 0.0:
		if attacker and amount > 0.0:
			_esquiva_perfeita(attacker)
		return
	if attacker and attacker.team != Config.TEAM_BLUE:
		amount *= Settings.bot_damage_mult()
	if carried_princess:
		amount *= Config.cfg.carrier_damage_mult
	# Bloqueio: vale para golpes que chegam pela frente (até 60° do rosto).
	var blocked := _blocking and _facing().dot(-dir) > BLOCK_COS
	if blocked and melee and attacker and attacker.alive and _block_t <= Config.cfg.parry_janela:
		_contra_golpe(attacker, dir)
		return
	if blocked:
		amount *= 1.0 - stats.block_reduction
		knock_mult *= 0.3
	if _shield > 0.0:
		var absorbed := minf(_shield, amount)
		_shield -= absorbed
		amount -= absorbed
	hp -= amount
	_calm_t = 0.0
	if carried_tora and amount > 0.0:
		drop_tora()  # apanhou: a tora cai (qualquer Construtor pega, até o inimigo)
	if attacker:
		attacker._calm_t = 0.0
		attacker.add_power(amount * Config.cfg.power_per_damage)
	add_power(amount * Config.cfg.power_per_damage_taken)
	if _fury_t > 0.0:
		knock_mult *= 0.2  # gigante: quase não é empurrado
	_knock = dir * (attacker.stats.knockback if attacker else 4.0) * knock_mult
	_flash_t = 0.1
	var forte := knock_mult > 1.0
	_mola(-5.0 if forte else -3.0, -3.0 if forte else -1.5)
	_tremor_t = 0.22 if forte else 0.15
	var col := Color(1, 0.9, 0.3) if attacker and attacker.is_player else Color(1, 1, 1)
	if blocked:
		col = Color(0.6, 0.8, 1.0)
	Fx.damage_number(game, global_position, str(int(amount)), col)
	if blocked:
		Fx.burst(game, global_position + Vector3(0, 1.3, 0) - dir * 0.6, Color(0.8, 0.9, 1.0), 10, 6.0)
		Sfx.play("block", global_position, 0.1)
		_play_upper("Block_Hit", 1.5)
	else:
		Fx.burst(game, global_position + Vector3(0, 1.2, 0), Color(1, 0.85, 0.5), 8 if knock_mult <= 1.0 else 14, 5.0 * maxf(knock_mult, 1.0))
		Sfx.play("hit", global_position)
	if melee:
		hitstop(Config.cfg.hitstop_time * (1.6 if knock_mult > 1.0 else 1.0))
	if is_player:
		game.camera.add_trauma(0.2 if blocked else 0.45)
		game.camera.kick(dir, 0.15 if blocked else 0.35)
	_update_hp_bar()
	if hp <= 0.0:
		_die(attacker)
	elif _anim_lock <= 0.0 and not blocked and _spin_t <= 0.0:
		_play_once("Hit_A" if randf() < 0.5 else "Hit_B", 0.25)


## Esquiva perfeita: um golpe passou por dentro do dash. O dash continua
## igual (pedido do Julio); só ganha recompensa e aviso: Chi, "ESQUIVA!",
## rastro e, para o jogador, um instante de câmera lenta.
## Leque: segunda onda 0,25 s depois, nos vãos da primeira.
func _leque_onda2(n: int, base: Vector3) -> void:
	await get_tree().create_timer(0.25).timeout
	if not alive or not is_inside_tree():
		return
	_play_upper("Throw", 1.8)
	for i in maxi(n - 1, 1):
		var t := (float(i) + 0.5) / maxf(n - 1, 1)
		var ang := deg_to_rad(lerpf(-stats.power_radius, stats.power_radius, t) * 0.5)
		_shoot_arrow(stats.power_value * Config.cfg.dano_poder_mult / maxf(stats.damage, 0.1), 1.2, base.rotated(Vector3.UP, ang))


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
			u.take_damage(dano * f, self, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, f)
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
	Fx.damage_number(game, global_position + Vector3(0, 0.6, 0), "CONTRA!", Color(1.0, 0.85, 0.3))
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
	_respawn_t = Config.cfg.respawn_time
	Sfx.play("death", global_position)
	if killer and killer != self:
		killer.add_power(Config.cfg.power_per_kill)
	power *= Config.cfg.power_keep_on_death
	died.emit(self, killer)


func _respawn() -> void:
	alive = true
	collision_layer = Config.LAYER_UNITS
	global_position = game.arena.random_spawn(team)
	reset_physics_interpolation()  # teleporte: sem rastro interpolado até o castelo
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
	set_class(Config.cfg.villager)  # quem morre perde o chapéu
	Fx.ring(game, global_position, Config.team_color(team), 2.0)
	_play_once("Lie_StandUp", 0.7)


# --- Poder do Q (medidor de Glacê) --------------------------------------------

## Vazamento do medidor depois de um tempo sem lutar: dG/dt = −G/τ.
func _tick_power(delta: float) -> void:
	_power_idle += delta
	if _power_idle > Config.cfg.power_leak_delay and power < POWER_MAX:
		power = maxf(power - power / Config.cfg.power_leak_tau * delta, 0.0)


func _use_power() -> void:
	if not power_ready() or _dodge_t > 0.0 or _equip_t > 0.0 or _spin_t > 0.0:
		return
	if carried_princess and stats.power != "corrida":
		return
	power = 0.0
	_cancel_skill()
	Sfx.play("power", global_position, 0.03)
	if is_player:
		# "Super flash": clarão na cor do papel, zoom e o tempo quase para.
		game.camera.add_trauma(0.35)
		game.camera.punch_fov(4.0)
		game.hud.flash(Color(stats.hat_color.lightened(0.4), 0.22), 0.3)
		game.slowmo(0.3, 0.14)
		game.on_player_power()
	else:
		game.camera.shake_at(global_position, 0.2)
	FxPoder.lancar(self)
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
					FxPoder.em_aliado(other, Color(1, 0.9, 0.5))
					other.heal(other.max_hp() * stats.power_value)
					other.give_shield(stats.power_shield, stats.power_duration)
		"corrida":
			_play_upper("Cheer", 1.5)
			Fx.ring(game, global_position, Color(1, 0.8, 0.3, 0.9), stats.power_radius)
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.power_radius:
					other.give_boost(stats.power_value, stats.power_duration)
					FxPoder.rastro(other, Color(1, 0.8, 0.3), stats.power_duration)
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
					other.take_damage(stats.power_value * Config.cfg.dano_poder_mult, self, d.normalized() if d.length() > 0.1 else _facing(), 1.6, true)
					other.launch(7.0)  # a onda de choque arremessa
					hit_any = true
			if hit_any:
				hitstop(Config.cfg.hitstop_time * 1.5)
		"corte_relampago":
			_corte_relampago()
		"leque":
			# Ninja: leque de shurikens (power_value = dano de cada uma).
			_play_upper("Throw", 1.6)
			var n := int(stats.power_duration)
			var base := aim_dir.normalized()
			for i in n:
				var ang := deg_to_rad(lerpf(-stats.power_radius, stats.power_radius, float(i) / maxf(n - 1, 1)) * 0.5)
				_shoot_arrow(stats.power_value * Config.cfg.dano_poder_mult / maxf(stats.damage, 0.1), 1.1, base.rotated(Vector3.UP, ang))
			Fx.burst(game, global_position + Vector3(0, 1.4, 0) + base, Color(0.4, 1.0, 1.0), 16, 8.0)
			FxPoder.leque(self, base)
			_leque_onda2(n, base)
		"nuvem", "selo", "coluna_fogo":
			var to := aim_point - global_position
			to.y = 0
			var center := global_position + to.limit_length(stats.attack_range)
			center.y = game.arena.ground_y(center.x, center.z, global_position.y + 3.0)
			var fx := AreaEffect.new()
			game.add_child(fx)
			fx.setup(game, self, center, stats.power, stats.power_radius, stats.power_value * (Config.cfg.dano_poder_mult if stats.power != "nuvem" else 1.0), stats.power_duration)
			_power_active_t = stats.power_duration
			_play_upper("Spellcast_Shoot" if stats.power != "nuvem" else "Throw", 1.2)
			match stats.power:
				"nuvem":
					FxPoder.nuvem(game, center, stats.power_radius)
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
		"reforco":
			# Pólvora: escudo de tábuas nos aliados em volta (não fere ninguém).
			_play_upper("Cheer", 1.5)
			Fx.pillar(game, global_position, Color(1.0, 0.55, 0.15), stats.power_radius)
			for other in game.units:
				if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.power_radius:
					other.give_shield(stats.power_value, stats.power_duration)
					FxPoder.reforco_em(other)
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
	Fx.beam(game, from + Vector3(0, 1.0, 0), to + Vector3(0, 1.0, 0), Color(0.3, 0.95, 1.0), 0.5, 0.5)
	Fx.zap(game, from + Vector3(0, 1.4, 0), to + Vector3(0, 1.4, 0), Color(0.6, 1.0, 1.0), 6)
	Fx.burst(game, from + Vector3(0, 1, 0), Color(0.4, 1.0, 1.0), 14, 6.0)
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
	if _silence_t > 0.0:
		_silence_t -= delta
		if fmod(_silence_t, 0.4) < delta:
			Fx.zap(game, global_position + Vector3(-0.5, 2.3, 0), global_position + Vector3(0.5, 1.2, 0.2), Color(0.6, 0.9, 1.0), 3)
	if _fury_t > 0.0:
		_fury_t -= delta
		if fmod(_fury_t, 0.15) < delta:
			Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.15, 0.1), 3, 3.0)
	if _dmg_boost_t > 0.0:
		_dmg_boost_t -= delta
		if fmod(_dmg_boost_t, 0.25) < delta:
			Fx.burst(game, global_position + Vector3(0, 1.6, 0), Color(1.0, 0.35, 0.3), 2, 2.0)
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


func _end_buffs() -> void:
	_fury_t = 0.0
	_silence_t = 0.0
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
		lean_target = 0.35
	_lean = lerpf(_lean, lean_target, 1.0 - exp(-10.0 * get_physics_process_delta_time()))
	if _model:
		_model.rotation.x = _lean
	if _anim_lock > 0.0:
		return
	var moving := horizontal.length() > 0.8
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


func _play_once(anim_name: String, lock: float) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	_current_anim = anim_name
	_anim.speed_scale = 1.0
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
	var c := clampf(power / POWER_MAX, 0.0, 1.0) if alive else 0.0
	if absf(c - _carga_vista) < 0.02 and not (c >= 1.0 and _carga_vista < 1.0):
		return
	_carga_vista = c
	for mi in _meshes:
		mi.set_instance_shader_parameter("poder_carga", c)


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
	var alvo_g: float = Config.cfg.furia_escala if _fury_t > 0.0 else 1.0
	_gigante = move_toward(_gigante, alvo_g, delta * 2.5)
	_visual.scale = Vector3(1.0 / sqrt(v * f), v / sqrt(f), f / sqrt(v)) * _gigante
	# Tremor de quem apanha: chacoalho aleatório que some em ~0,2 s.
	if _tremor_t > 0.0:
		_tremor_t -= delta
		var amp := 0.09 * k * clampf(_tremor_t / 0.2, 0.0, 1.0)
		off.x += randf_range(-amp, amp)
		off.z += randf_range(-amp, amp)
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


func _build_hp_bar() -> void:
	_hp_root = Node3D.new()
	_hp_root.position = Vector3(-0.6, 2.75, 0)
	add_child(_hp_root)
	var bg := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.2, 0.16)
	q.center_offset = Vector3(0.6, 0, 0)
	bg.mesh = q
	var bg_mat := Fx.unshaded(Color(0, 0, 0, 0.6), true)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.no_depth_test = true
	bg.material_override = bg_mat
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hp_root.add_child(bg)
	_hp_fill = MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(1.2, 0.12)
	q2.center_offset = Vector3(0.6, 0, 0.01)
	_hp_fill.mesh = q2
	var fill_mat := Fx.unshaded(Config.team_color(team).lightened(0.2))
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.no_depth_test = true
	fill_mat.render_priority = 1
	# Sem isso o billboard troca a matriz inteira pela da câmera e descarta a
	# escala: _hp_fill.scale.x mudava, mas a barra continuava cheia na tela.
	fill_mat.billboard_keep_scale = true
	_hp_fill.material_override = fill_mat
	_hp_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hp_root.add_child(_hp_fill)


func _update_hp_bar() -> void:
	if _hp_fill == null:
		return
	var r := clampf(hp / max_hp(), 0.0, 1.0)
	_hp_fill.scale.x = maxf(r, 0.001)
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
