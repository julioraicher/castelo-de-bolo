class_name Game
extends Node3D
## Cérebro da partida: monta o mundo, cria as unidades, cuida das regras
## (pegar princesa, bolo e chapéus, marcar ponto, vitória) e atualiza o HUD.
## É o script da cena principal (scenes/main.tscn).

var arena: Arena
var camera: CameraRig
var hud: Hud
var units: Array[Unit] = []
var princesses: Array[Princess] = []
var hat_pads: Array[HatPad] = []
var cakes: Array[Cake] = []
var score := [0, 0]
var player: Unit
var player_brain: PlayerBrain
var game_over := false

var _cake_t := 2.0
var _time := 0.0

# Modo de desenvolvimento (linha de comando, depois de "--"):
#   --autoplay          o jogador também é controlado pela IA
#   --shots=<pasta>     salva prints em alguns momentos e fecha o jogo
# Ex.: godot --path . -- --autoplay --shots=/tmp/prints
var _autoplay := false
var _shots_dir := ""
var _shot_times: Array[float] = [4.0, 15.0, 30.0, 50.0, 75.0]

const BOT_ROLES := [BotBrain.Role.ATTACK, BotBrain.Role.DEFEND, BotBrain.Role.ATTACK, BotBrain.Role.CAKE,
		BotBrain.Role.ATTACK, BotBrain.Role.DEFEND, BotBrain.Role.ATTACK, BotBrain.Role.ATTACK]


func _ready() -> void:
	randomize()
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	arena = Arena.new()
	arena.name = "Arena"
	add_child(arena)
	arena.build()

	for team in 2:
		var p := Princess.new()
		p.name = "Princesa%s" % Config.TEAM_NAMES[team]
		add_child(p)
		p.setup(self, team, arena.princess_spot[team])
		p.state_changed.connect(_on_princess_changed)
		princesses.append(p)
		var hats := Config.cfg.hat_classes()
		for i in hats.size():
			var pad := HatPad.new()
			add_child(pad)
			pad.setup(team, hats[i], arena.hat_spots[team][i])
			hat_pads.append(pad)

	var cfg := Config.cfg
	var start_classes: Array[ClassStats] = [cfg.warrior, cfg.archer, cfg.cleric, cfg.villager]
	for team in 2:
		for i in cfg.units_per_team:
			var u := Unit.new()
			u.name = "%s_%d" % [Config.TEAM_NAMES[team], i]
			add_child(u)
			var is_player := team == Config.TEAM_BLUE and i == 0
			var cls: ClassStats = cfg.villager if is_player else start_classes[i % start_classes.size()]
			u.setup(self, team, is_player, cls)
			u.global_position = arena.random_spawn(team)
			u.reset_physics_interpolation()
			u.died.connect(_on_unit_died)
			if is_player:
				u.class_changed.connect(_on_player_class_changed)
			if is_player:
				player = u
			if is_player and not _autoplay:
				player_brain = PlayerBrain.new()
				player_brain.unit = u
				player_brain.game = self
				u.add_child(player_brain)
				u.brain = player_brain
			else:
				var bot := BotBrain.new()
				bot.unit = u
				bot.game = self
				bot.role = BOT_ROLES[i % BOT_ROLES.size()]
				u.add_child(bot)
				u.brain = bot
			units.append(u)

	camera = CameraRig.new()
	add_child(camera)
	camera.target = player
	camera.snap()

	hud = Hud.new()
	add_child(hud)
	var menus := Menus.new()
	add_child(menus)
	menus.started.connect(_on_started)
	if _autoplay:
		_on_started()
	else:
		menus.show_start()


func _on_started() -> void:
	hud.show_big("Resgate a princesa vermelha!\nTraga-a para o seu castelo.", Color(1, 0.9, 0.5), 3.5)
	Sfx.start_music()


func _physics_process(delta: float) -> void:
	_time += delta
	if _shots_dir != "" and not _shot_times.is_empty() and _time >= _shot_times[0]:
		_take_shot()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if game_over:
		return
	_spawn_cakes(delta)
	_rules()
	hud.update_state(self)


func _log(msg: String) -> void:
	if _autoplay:
		print(msg)


func _take_shot() -> void:
	var t: float = _shot_times.pop_front()
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/shot_%03d.png" % [_shots_dir, int(t)])
	if _shot_times.is_empty():
		get_tree().quit()


# --- Regras -------------------------------------------------------------------

func _rules() -> void:
	var hint := ""
	for u in units:
		if not u.alive:
			continue
		var pos := u.global_position
		var wants_interact := u.is_player and player_brain != null and player_brain.interact_pressed
		var enemy_p := princesses[1 - u.team]
		var own_p := princesses[u.team]

		# Marcar ponto: chegar ao próprio pedestal carregando a princesa inimiga.
		if u.carried_princess and pos.distance_to(arena.princess_spot[u.team]) < 4.5:
			_score_point(u)
			return

		# Soltar a princesa de propósito (só o jogador).
		if u.carried_princess and wants_interact:
			u.drop_princess()
			continue

		# Pegar a princesa inimiga: bots pegam sozinhos, o jogador aperta E.
		if not u.carried_princess and enemy_p.can_be_taken() and pos.distance_to(enemy_p.global_position) < 2.8:
			if u.is_player:
				hint = "[E] pegar a princesa!"
			if not u.is_player or wants_interact:
				u.pick_up_princess(enemy_p)
				u.has_cake = false
				continue

		# Devolver a própria princesa caída: ficar ao lado dela por um tempo.
		if own_p.state == Princess.State.DROPPED and pos.distance_to(own_p.global_position) < 2.5:
			own_p.rescue(get_physics_process_delta_time())

		# Alimentar a própria princesa.
		if u.has_cake and own_p.state == Princess.State.HOME and pos.distance_to(own_p.global_position) < 4.0:
			if own_p.feed():
				u.has_cake = false
				if u.is_player:
					hud.show_big("Nhac! Princesa mais pesada", Color(1, 0.6, 0.8), 1.2)

		# Pegar bolo (bots atacantes ignoram bolo para não se distraírem).
		var bot := u.brain as BotBrain
		var takes_cake := bot == null or bot.role != BotBrain.Role.ATTACK
		if takes_cake and not u.has_cake and not u.carried_princess:
			for c in cakes:
				if pos.distance_to(c.global_position) < 1.8:
					u.has_cake = true
					cakes.erase(c)
					Fx.burst(self, c.global_position + Vector3(0, 0.6, 0), Color(1, 0.6, 0.8), 10, 4.0)
					Sfx.play("pickup", c.global_position)
					c.queue_free()
					break

		# Chapéus: aldeão veste ao encostar; quem já tem classe troca com E.
		for pad in hat_pads:
			if pad.team != u.team or not pad.available or pad.stats == u.stats or u.is_equipping():
				continue
			if pos.distance_to(pad.global_position) < 2.0:
				if u.is_player:
					hint = "[E] pegar o chapéu de %s" % pad.stats.display_name
				# Jogador: só com E. Bots aldeões (e o jogador no modo teste) pegam sozinhos.
				if wants_interact or (u.brain is BotBrain and u.is_villager()):
					var from: Vector3 = pad.hat_world_position()
					u.start_equip(pad.take(), from)
				break

	if player.alive and player.carried_princess:
		hint = "Leve-a até o SEU castelo!  ([E] soltar)"
	elif player.has_cake:
		hint = "Leve o bolo até a sua princesa"
	hud.set_hint(hint)


func _score_point(u: Unit) -> void:
	_log("PONTO %s (t=%.0fs)" % [Config.TEAM_NAMES[u.team], _time])
	var p := u.carried_princess
	u.carried_princess = null
	p.return_home()
	score[u.team] += 1
	Sfx.play_ui("score")
	camera.add_trauma(0.3)
	Fx.burst(self, arena.princess_spot[u.team] + Vector3(0, 2, 0), Config.team_color(u.team).lightened(0.4), 40, 12.0)
	var mine := u.team == player.team
	hud.show_big("PONTO DO %s!" % Config.TEAM_NAMES[u.team].to_upper(), Config.team_color(u.team).lightened(0.4))
	if score[u.team] >= Config.cfg.score_to_win:
		game_over = true
		hud.update_state(self)
		hud.show_end(mine)
		Sfx.play_ui("win" if mine else "lose")
		for other in units:
			if other.alive and other.team == u.team:
				other.play_cheer()
			other.move_intent = Vector3.ZERO
			other.set_physics_process(false)


func _spawn_cakes(delta: float) -> void:
	_cake_t -= delta
	if _cake_t > 0.0 or cakes.size() >= Config.cfg.max_cakes:
		return
	_cake_t = Config.cfg.cake_spawn_interval
	var c := Cake.new()
	add_child(c)
	c.global_position = arena.random_cake_spot()
	cakes.append(c)


# --- Consultas usadas pelos bots ----------------------------------------------

func nearest_free_hat(team: int, from: Vector3) -> HatPad:
	var best: HatPad = null
	var best_d := INF
	for pad in hat_pads:
		if pad.team == team and pad.available:
			var d := from.distance_to(pad.global_position)
			if d < best_d:
				best_d = d
				best = pad
	return best


func nearest_cake(from: Vector3) -> Cake:
	var best: Cake = null
	var best_d := INF
	for c in cakes:
		var d := from.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func spawn_projectile(shooter: Unit, origin: Vector3, dir: Vector3, kind: String) -> void:
	var p := Projectile.new()
	p.setup(self, shooter, origin, dir, kind)
	add_child(p)


# --- Eventos ------------------------------------------------------------------

func _on_player_class_changed(u: Unit) -> void:
	if not u.is_villager():
		hud.show_big("Agora você é %s!" % u.stats.display_name, u.stats.hat_color.lightened(0.3), 1.3)


func _on_unit_died(u: Unit, killer: Unit) -> void:
	if u == player:
		hud.show_big("Você caiu! Renascendo como aldeão...", Color(1, 0.6, 0.6), 1.8)
	elif killer == player:
		Fx.burst(self, u.global_position + Vector3(0, 1, 0), Color(1, 0.9, 0.3), 16, 7.0)


func _on_princess_changed(p: Princess) -> void:
	_log("princesa %s -> %s [%d] (t=%.0fs)" % [Config.TEAM_NAMES[p.team], p.state_text(), p.state, _time])
	if game_over:
		return
	var ours := p.team == player.team
	if p.state == Princess.State.CARRIED:
		if ours:
			hud.show_big("Sua princesa foi sequestrada!", Color(1, 0.45, 0.45), 2.0)
			Sfx.play_ui("alarm")
		elif p.carrier != player:
			hud.show_big("Um aliado pegou a princesa inimiga!", Color(0.6, 0.85, 1.0), 1.6)
