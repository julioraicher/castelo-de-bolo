class_name Unit
extends CharacterBody3D
## Um soldado (jogador ou bot). Quem decide O QUE fazer é o "cérebro"
## (PlayerBrain ou BotBrain); a Unit só executa: andar, atacar, esquivar,
## carregar coisas, tomar dano, morrer e renascer.
##
## O cérebro preenche, a cada quadro físico:
##   move_intent  -> direção desejada (Vector3 no plano XZ, comprimento 0..1)
##   aim_dir      -> para onde mirar
##   wants_attack / wants_special / wants_dodge

signal died(unit: Unit, killer: Unit)
signal class_changed(unit: Unit)

const ACCEL := 70.0
const DODGE_SPEED := 17.0
const DODGE_TIME := 0.24
const DODGE_COOLDOWN := 0.9
const KNOCK_DECAY := 40.0  # m/s² de "freada" do empurrão: distância = v²/(2·KNOCK_DECAY)
const EQUIP_TIME := 0.75  # s para pegar o chapéu e pôr na cabeça (andando)
## Ossos do tronco: a animação de pôr o chapéu toca só neles, então as pernas
## continuam correndo com a animação normal.
const UPPER_BONES := ["spine", "chest", "upperarm.l", "lowerarm.l", "wrist.l", "hand.l", "handslot.l", "upperarm.r", "lowerarm.r", "wrist.r", "hand.r", "handslot.r", "head"]
const LOOPING_ANIMS := ["Idle", "Running_A", "Running_B", "Walking_A", "Walking_B", "Sit_Floor_Idle", "Cheer", "2H_Melee_Idle", "Spellcasting", "1H_Ranged_Aiming"]

var game: Game
var team := 0
var is_player := false
var brain: Node

var stats: ClassStats
var hp := 1.0
var alive := true
var carried_princess: Princess = null
var has_cake := false

# Intenções preenchidas pelo cérebro.
var move_intent := Vector3.ZERO
var aim_dir := Vector3.FORWARD
var wants_attack := false
var wants_special := false
var wants_dodge := false

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
var _dodge_t := 0.0
var _dodge_dir := Vector3.ZERO
var _knock := Vector3.ZERO      # velocidade do empurrão (separada da caminhada)
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

static var _flash_mat: StandardMaterial3D
static var _merged_body := {}  # caminho do .tres da classe -> ArrayMesh do corpo
static var _upper_libs := {}  # caminho do modelo -> AnimationLibrary filtrada


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
	hp = stats.max_hp  # trocar de chapéu cura por completo
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
	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for a in LOOPING_ANIMS + [stats.anim_idle, stats.anim_run]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_setup_upper_player()
	_current_anim = ""
	_play(stats.anim_idle)
	_update_hp_bar()
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
	if _upper and _upper.has_animation("tronco/Spellcast_Raise"):
		_upper.play("tronco/Spellcast_Raise", 0.1, _upper.get_animation("tronco/Spellcast_Raise").length / EQUIP_TIME)
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
		for anim_name in ["Spellcast_Raise"]:
			if not _anim.has_animation(anim_name):
				continue
			var a := _anim.get_animation(anim_name).duplicate() as Animation
			a.loop_mode = Animation.LOOP_NONE
			for t in range(a.get_track_count() - 1, -1, -1):
				var bone := str(a.track_get_path(t).get_concatenated_subnames())
				if not UPPER_BONES.has(bone):
					a.remove_track(t)
			lib.add_animation(anim_name, a)
		_upper_libs[key] = lib
	_upper = AnimationPlayer.new()
	_upper.name = "TroncoPlayer"
	_anim.get_parent().add_child(_upper)
	_upper.root_node = _upper.get_path_to(_anim.get_node(_anim.root_node))
	_upper.add_animation_library("tronco", lib)


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


func is_busy_carrying() -> bool:
	return carried_princess != null


func hp_ratio() -> float:
	return hp / stats.max_hp


func current_speed() -> float:
	var s := stats.move_speed
	if carried_princess:
		s *= stats.carry_speed_mult * (1.0 - carried_princess.fatness * Config.cfg.fat_slowdown)
	return s


# --- Loop principal -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not alive:
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn()
		return

	if brain and brain.has_method("tick"):
		brain.tick(delta)

	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_heal_cd = maxf(_heal_cd - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)

	if wants_dodge and _dodge_cd <= 0.0 and not carried_princess:
		_start_dodge()
	wants_dodge = false

	if _dodge_t > 0.0:
		_dodge_t -= delta
		_move_vel = _dodge_dir * DODGE_SPEED
	else:
		var speed := current_speed()
		if _anim_lock > 0.0:
			speed *= 0.55  # anda mais devagar enquanto ataca
		var target := move_intent.limit_length(1.0) * speed + _separation() * 3.0
		_move_vel = _move_vel.move_toward(target, ACCEL * delta)
	# O empurrão entra só na velocidade final. Antes ele era somado à própria
	# velocidade do quadro anterior, ou seja, integrado de novo a cada quadro:
	# um golpe de guerreiro jogava o alvo ~45 m em vez de ~1 m.
	var horizontal := _move_vel + _knock
	_knock = _knock.move_toward(Vector3.ZERO, KNOCK_DECAY * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 30.0 * delta
	move_and_slide()
	global_position = game.arena.clamp_to_arena(global_position)

	_face(delta)
	if _equip_t > 0.0:
		_equip_t -= delta
		if _equip_t <= 0.0:
			_finish_equip()
	if wants_attack and _attack_cd <= 0.0 and not carried_princess and _dodge_t <= 0.0 and _equip_t <= 0.0:
		_attack()
	if wants_special and stats.attack_kind == "healer" and _heal_cd <= 0.0 and not carried_princess:
		_heal()
	_animate(horizontal)
	_update_flash(delta)
	_cake_visual.visible = has_cake
	if has_cake:
		_cake_visual.rotation.y += delta * 2.0


func _face(delta: float) -> void:
	var look := Vector3.ZERO
	if _dodge_t > 0.0:
		look = _dodge_dir
	elif is_player or _anim_lock > 0.0 or wants_attack:
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
	_play_once("Dodge_Forward", DODGE_TIME + 0.1)
	Sfx.play("dodge", global_position)


func _attack() -> void:
	_attack_cd = stats.attack_cooldown
	_play_once(stats.anim_attack, 0.4)
	var dir := aim_dir.normalized()
	match stats.attack_kind:
		"melee":
			Sfx.play("swing", global_position)
			var hit_any := false
			for other in game.units:
				if not other.alive or other.team == team:
					continue
				var to := other.global_position - global_position
				to.y = 0
				if to.length() > stats.attack_range + 0.6:
					continue
				if to.length() > 0.8 and rad_to_deg(dir.angle_to(to.normalized())) > stats.attack_arc_deg / 2.0:
					continue
				other.take_damage(stats.damage, self, to.normalized())
				hit_any = true
			if hit_any and is_player:
				game.camera.add_trauma(0.25)
		"ranged":
			Sfx.play("shoot", global_position)
			game.spawn_projectile(self, global_position + Vector3(0, 1.4, 0) + dir * 0.9, dir, "arrow")
		"healer":
			Sfx.play("magic", global_position)
			game.spawn_projectile(self, global_position + Vector3(0, 1.6, 0) + dir * 0.9, dir, "magic")


func _heal() -> void:
	_heal_cd = stats.heal_cooldown
	_play_once("Spellcast_Raise", 0.5)
	Sfx.play("heal", global_position)
	Fx.ring(game, global_position, Color(0.5, 1.0, 0.6, 0.7), stats.heal_radius)
	for other in game.units:
		if other.alive and other.team == team and other.global_position.distance_to(global_position) <= stats.heal_radius:
			other.heal(stats.heal_amount)


func heal(amount: float) -> void:
	if hp >= stats.max_hp:
		return
	hp = minf(hp + amount, stats.max_hp)
	Fx.damage_number(game, global_position, "+%d" % int(amount), Color(0.5, 1, 0.55))
	_update_hp_bar()


func take_damage(amount: float, attacker: Unit, dir: Vector3) -> void:
	if not alive or _dodge_t > 0.0:
		return
	if attacker and attacker.team != Config.TEAM_BLUE:
		amount *= Settings.bot_damage_mult()
	hp -= amount
	_knock = dir * (attacker.stats.knockback if attacker else 4.0)
	_flash_t = 0.1
	Fx.damage_number(game, global_position, str(int(amount)), Color(1, 0.9, 0.3) if attacker and attacker.is_player else Color(1, 1, 1))
	Fx.burst(game, global_position + Vector3(0, 1.2, 0), Color(1, 0.85, 0.5), 8, 5.0)
	Sfx.play("hit", global_position)
	if is_player:
		game.camera.add_trauma(0.45)
	_update_hp_bar()
	if hp <= 0.0:
		_die(attacker)
	elif _anim_lock <= 0.0:
		_play_once("Hit_A", 0.25)


func _die(killer: Unit) -> void:
	alive = false
	hp = 0.0
	_cancel_equip()
	if carried_princess:
		carried_princess.drop(global_position)
		carried_princess = null
	has_cake = false
	collision_layer = 0
	velocity = Vector3.ZERO
	_hp_root.visible = false
	_play("Death_A", 0.1)
	_respawn_t = Config.cfg.respawn_time
	Sfx.play("death", global_position)
	died.emit(self, killer)


func _respawn() -> void:
	alive = true
	collision_layer = Config.LAYER_UNITS
	global_position = game.arena.random_spawn(team)
	reset_physics_interpolation()  # teleporte: sem rastro interpolado até o castelo
	velocity = Vector3.ZERO
	_knock = Vector3.ZERO
	_move_vel = Vector3.ZERO
	set_class(Config.cfg.villager)  # quem morre perde o chapéu
	Fx.ring(game, global_position, Config.team_color(team), 2.0)


# --- Carregar princesa e bolo -------------------------------------------------

func pick_up_princess(p: Princess) -> void:
	carried_princess = p
	p.pick_up(self)
	Sfx.play("pickup", global_position)


func drop_princess() -> void:
	if carried_princess:
		carried_princess.drop(global_position + aim_dir * 1.2)
		carried_princess = null


# --- Visual -------------------------------------------------------------------

func _animate(horizontal: Vector3) -> void:
	if _anim_lock > 0.0:
		return
	var moving := horizontal.length() > 0.8
	if carried_princess:
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


func play_cheer() -> void:
	_play_once("Cheer", 999.0)


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
	var r := clampf(hp / stats.max_hp, 0.0, 1.0)
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
