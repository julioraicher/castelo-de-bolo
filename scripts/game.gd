class_name Game
extends Node3D
## Cérebro da partida: monta o mundo, cria as unidades, cuida das regras
## (pegar princesa, bolo, itens e chapéus, marcar ponto, vitória) e atualiza o HUD.
## É o script da cena principal (scenes/main.tscn).

var arena: Arena
var camera: CameraRig
var hud: Hud
var units: Array[Unit] = []
var princesses: Array[Princess] = []
var hat_pads: Array[HatPad] = []
var cakes: Array[Cake] = []
var pickups: Array[Pickup] = []
var oficinas: Array[Oficina] = []
var score := [0, 0]
var player: Unit
var player_brain: PlayerBrain
var game_over := false

var _cake_t := 2.0
var _pickup_t := 8.0
var _time := 0.0

# Modo de desenvolvimento (linha de comando, depois de "--"):
#   --autoplay          o jogador também é controlado pela IA
#   --shots=<pasta>     salva prints em alguns momentos e fecha o jogo
#   --variacoes         bots começam com todas as variações (teste visual/poderes)
#   --poderes           medidor de todo mundo enche a cada 4 s (vitrine de poderes)
#   --tema=N            usa o tema N de GameConfig.themes (prints de cada tema)
#   --mapa=N            usa o mapa N de GameConfig.maps
#   --vista=mapa|alto|patio  câmera parada vendo o mapa todo / o castelo de cima /
#                       o pátio azul no ângulo da câmera do jogo (prints)
#   --print-poder       com --shots: os prints saem logo depois de cada poder do jogador
#   --filme=<pasta>     roteiro fixo com o jogador (golpe, dash, pulo, pancada,
#                       morte) salvando um quadro a cada 2: prancha de animação
#   --perf=N            mede o desempenho na qualidade N (0-3): a cada 5 s imprime
#                       ms de CPU por quadro, draw calls, triângulos e objetos
#   --testes            roda os testes de regra (tests/regras.gd) e sai com 0/1
# Ex.: godot --path . -- --autoplay --shots=/tmp/prints
var _autoplay := false
var _variacoes := false
var _poderes := false
var _poderes_t := 2.0
var _shots_dir := ""
var _vista := ""
var _print_poder := false
var _perf := false
var _filme_dir := ""
var _filme_f := -1
var _filme_y := 0.0
var _hud_t := 0.0
var _perf_acc := {}
var _perf_n := 0
var _perf_t := 0.0
var _perf_t0 := 0
var _testes := false  # --testes: roda tests/regras.gd e sai
var _shot_times: Array[float] = [4.0, 15.0, 30.0, 50.0, 75.0]

const BOT_ROLES := [BotBrain.Role.ATTACK, BotBrain.Role.DEFEND, BotBrain.Role.ATTACK, BotBrain.Role.CAKE,
		BotBrain.Role.ATTACK, BotBrain.Role.DEFEND, BotBrain.Role.ATTACK, BotBrain.Role.ATTACK]


func _ready() -> void:
	Engine.time_scale = 1.0  # reinício no meio de uma câmera lenta
	randomize()
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg == "--variacoes":
			_variacoes = true
		elif arg == "--poderes":
			_poderes = true
		elif arg.begins_with("--perf="):
			_perf = true
			Settings.auto_quality = false
			Settings.quality = int(arg.trim_prefix("--perf="))
		elif arg == "--print-poder":
			_print_poder = true
		elif arg.begins_with("--filme="):
			_filme_dir = arg.trim_prefix("--filme=")
		elif arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg.begins_with("--vista="):
			_vista = arg.trim_prefix("--vista=")
		elif arg.begins_with("--mapa="):
			Settings.mapa = int(arg.trim_prefix("--mapa="))
		elif arg.begins_with("--tema="):
			Settings.theme = int(arg.trim_prefix("--tema="))
		elif arg == "--testes":
			_testes = true
	if _print_poder:
		_shot_times = [1e9, 1e9, 1e9, 1e9, 1e9, 1e9]  # quem marca a hora é o poder
	arena = Arena.new()
	arena.name = "Arena"
	add_child(arena)
	arena.build()

	for team in 2:
		var p := Princess.new()
		p.name = "Mascara%s" % Config.TEAM_NAMES[team]
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
		# Terrenos de oficina: começam com opções diferentes, sorteadas.
		var n_opts := Config.cfg.oficina_classes.size()
		if n_opts > 0:
			var order := range(n_opts)
			order.shuffle()
			for i in arena.oficina_spots[team].size():
				var of := Oficina.new()
				add_child(of)
				of.setup(self, team, arena.oficina_spots[team][i], order[i % n_opts])
				oficinas.append(of)

	var cfg := Config.cfg
	var start_classes: Array[ClassStats] = cfg.bot_start_classes if not cfg.bot_start_classes.is_empty() else [cfg.villager]
	if _variacoes:
		start_classes = cfg.hat_classes() + cfg.oficina_classes
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
	Fx.prewarm(self, player.global_position)
	if _vista != "":
		camera.set_process(false)
		camera.set_physics_process(false)
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		if _vista == "mapa":
			camera.fov = 50
			camera.position = Vector3(0, 95, 62)
			camera.look_at(Vector3(0, 0, 2))
		elif _vista == "patio":
			camera.fov = 42
			camera.position = Vector3(-50, 0, 0) + Vector3(0, 21, 19) * 1.55
			camera.look_at(Vector3(-50, 0, 0))
		else:
			camera.fov = 45
			camera.position = Vector3(-22, 22, 26)
			camera.look_at(Vector3(-40, 2, 0))

	if _testes:
		var t: Node = load("res://tests/regras.gd").new()
		t.set("game", self)
		add_child(t)

	hud = Hud.new()
	add_child(hud)
	var auto_q := AutoQuality.new()
	auto_q.hud = hud
	if _vista != "":
		hud.visible = false
	add_child(auto_q)
	var menus := Menus.new()
	add_child(menus)
	menus.started.connect(_on_started)
	if _autoplay:
		_on_started()
	else:
		menus.show_start()


func _on_started() -> void:
	hud.show_big("Roube a Máscara Oni vermelha!\nTraga-a para o seu castelo.", Color(1, 0.9, 0.5), 3.5)
	Sfx.start_music()


func _process(delta: float) -> void:
	if _perf:
		_measure(delta)


## --perf: média por quadro dos monitores do motor, impressa a cada 10 s.
func _measure(delta: float) -> void:
	var keys := {
		"cpu_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"fisica_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"tris_mil": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0,
		"objetos": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"nos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
	for k in keys:
		_perf_acc[k] = _perf_acc.get(k, 0.0) + keys[k]
	_perf_n += 1
	_perf_t += delta
	if _perf_t >= 5.0:
		# FPS pelo relógio real (com --fixed-fps o delta é sempre 1/60).
		var real := (Time.get_ticks_usec() - _perf_t0) / 1e6
		_perf_t0 = Time.get_ticks_usec()
		var out := "PERF t=%d fps=%.1f" % [int(_time), _perf_n / real]
		for k in _perf_acc:
			out += " %s=%.1f" % [k, _perf_acc[k] / _perf_n]
		print(out)
		_perf_acc.clear()
		_perf_n = 0
		_perf_t = 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	if _shots_dir != "" and not _shot_times.is_empty() and _time >= _shot_times[0]:
		_take_shot()
	if _filme_dir != "" and _time >= 3.0:
		_filme()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if game_over:
		return
	_spawn_cakes(delta)
	_spawn_pickups(delta)
	if _poderes:
		_poderes_t -= delta
		if _poderes_t <= 0.0:
			_poderes_t = 4.0
			for u in units:
				u.fill_power()
	_rules()
	# O HUD não precisa de 60 atualizações por segundo: 20 Hz bastam ao olho
	# e cada atualização mexe em vários textos e barras.
	_hud_t -= delta
	if _hud_t <= 0.0:
		_hud_t = 0.05
		hud.update_state(self)


func _log(msg: String) -> void:
	if _autoplay:
		print(msg)


## --filme: o jogador (sem cérebro) faz um roteiro fixo, de lado para a
## câmera, e cada 2 quadros vira um PNG.
func _filme() -> void:
	_filme_f += 1
	var f := _filme_f
	var p := player
	var lado := Vector3(-1, 0, 0)
	if f == 0:
		p.brain = null
		p.move_intent = Vector3.ZERO
		p.aim_dir = lado
		p.set_class(load("res://config/classes/guerreiro.tres"))
		p.fill_power()
		# Câmera parada, baixa e de lado, perto do boneco.
		hud.visible = false
		camera.set_process(false)
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		camera.fov = 30
		camera.near = 6.5  # corta o que estiver entre a câmera e o boneco
		_filme_y = p.global_position.y
	# A câmera acompanha o boneco de lado só no chão (o pulo aparece), sem
	# suavizar, para comparar quadros.
	var foco := Vector3(p.global_position.x, _filme_y, p.global_position.z)
	camera.global_position = foco + Vector3(0, 3.5, 9.0)
	camera.look_at(foco + Vector3(0, 1.2, 0))

	match f:
		10:
			p._attack()
		50:
			p.move_intent = lado
			p._start_dodge()
		66:
			p.move_intent = Vector3.ZERO
		100:
			p.launch(9.0)
		160:
			p.take_damage(4.0, null, -lado, 1.5, true)
		200:
			p.take_damage(9999.0, null, -lado, 1.0, true)
		270:
			get_tree().quit()
	if f % 2 == 0:
		get_viewport().get_texture().get_image().save_png("%s/f_%03d.png" % [_filme_dir, f])


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
				hint = "[E] pegar a máscara!"
			if not u.is_player or wants_interact:
				u.pick_up_princess(enemy_p)
				u.has_cake = false
				continue

		# Devolver a própria princesa caída: ficar ao lado dela por um tempo,
		# sem inimigo perto (disputa: aí o resgate para).
		if own_p.state == Princess.State.DROPPED and pos.distance_to(own_p.global_position) < 2.5 \
				and not _contested(own_p):
			own_p.rescue(get_physics_process_delta_time())

		# Alimentar a própria princesa.
		if u.has_cake and own_p.state == Princess.State.HOME and pos.distance_to(own_p.global_position) < 4.0:
			if own_p.feed():
				u.has_cake = false
				u.add_power(Config.cfg.power_per_cake)
				if u.is_player:
					hud.show_big("Espírito preso! Máscara mais pesada", Color(1, 0.6, 0.8), 1.2)

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

		# Itens no chão: qualquer um que encosta pega.
		for it in pickups:
			if pos.distance_to(it.global_position) < 1.6:
				it.apply_to(u)
				pickups.erase(it)
				it.queue_free()
				break

		# Chapéus: recruta veste ao encostar; quem já tem classe troca com E.
		for pad in hat_pads:
			if pad.team != u.team or not pad.available or pad.stats == u.stats or u.is_equipping():
				continue
			if pos.distance_to(pad.global_position) < 2.0:
				if u.is_player:
					hint = "[E] pegar o chapéu de %s" % pad.stats.display_name
				# Jogador: só com E. Bots recrutas (e o jogador no modo teste) pegam sozinhos.
				if wants_interact or (u.brain is BotBrain and u.is_villager()):
					var from: Vector3 = pad.hat_world_position()
					u.start_equip(pad.take(), from)
				break

	# Oficina: o jogador troca a opção do terreno com E.
	if player.alive and not player.carried_princess and hint == "":
		var of := nearest_oficina(player.team, player.global_position, Oficina.BUILD_RADIUS + 0.5, true)
		if of:
			var builder := "  (fique aqui para construir)" if player.stats.velocidade_obra > 0.0 else "  (precisa de um Construtor)"
			hint = "[E] trocar oficina: %s%s" % [of.opcao().display_name, builder]
			if player_brain != null and player_brain.interact_pressed:
				of.trocar_opcao()

	if player.alive and player.carried_princess:
		hint = "Leve-a até o SEU castelo!  ([E] soltar)"
	elif player.has_cake:
		hint = "Leve o espírito até a sua máscara"
	hud.set_hint(hint)


## Máscara caída com alguém do time ladrão perto: ninguém a devolve.
func _contested(p: Princess) -> bool:
	for u in units:
		if u.alive and u.team != p.team and u.global_position.distance_to(p.global_position) < Config.cfg.princess_contest_radius:
			return true
	return false


func _score_point(u: Unit) -> void:
	_log("PONTO %s (t=%.0fs)" % [Config.TEAM_NAMES[u.team], _time])
	var p := u.carried_princess
	u.carried_princess = null
	u.add_power(Config.cfg.power_per_capture)
	u.play_cheer(1.2)
	p.return_home()
	score[u.team] += 1
	Sfx.play_ui("score")
	camera.add_trauma(0.3)
	Fx.burst(self, arena.princess_spot[u.team] + Vector3(0, 2, 0), Config.team_color(u.team).lightened(0.4), 40, 12.0)
	var mine := u.team == player.team
	hud.show_big("PONTO DO %s!" % Config.TEAM_NAMES[u.team].to_upper(), Config.team_color(u.team).lightened(0.4))
	if score[u.team] >= Config.cfg.score_to_win:
		game_over = true
		_slowmo_id += 1
		Engine.time_scale = 1.0
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


func _spawn_pickups(delta: float) -> void:
	_pickup_t -= delta
	if _pickup_t > 0.0 or pickups.size() >= Config.cfg.max_pickups:
		return
	_pickup_t = Config.cfg.pickup_interval
	var it := Pickup.new()
	add_child(it)
	it.setup(Pickup.KINDS.pick_random(), arena.random_cake_spot())
	pickups.append(it)


func nearest_pickup(from: Vector3, max_dist: float) -> Pickup:
	var best: Pickup = null
	var best_d := max_dist
	for it in pickups:
		var d := from.distance_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	return best


# --- Consultas usadas pelos bots ----------------------------------------------

## Oficina do time mais perto (só as não prontas, se unbuilt_only).
func nearest_oficina(team: int, from: Vector3, max_dist: float, unbuilt_only: bool) -> Oficina:
	var best: Oficina = null
	var best_d := max_dist
	for of in oficinas:
		if of.team != team or (unbuilt_only and of.estado == Oficina.Estado.PRONTA):
			continue
		var d := from.distance_to(of.global_position)
		if d < best_d:
			best_d = d
			best = of
	return best


func on_oficina_pronta(of: Oficina) -> void:
	_log("oficina %s pronta: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.opcao().display_name, _time])
	if of.team == player.team:
		hud.show_big("Oficina pronta: %s!" % of.opcao().display_name, of.opcao().hat_color.lightened(0.3), 2.0)
	else:
		hud.show_big("O inimigo liberou %s" % of.opcao().display_name, Color(1, 0.6, 0.55), 1.6)


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


func spawn_projectile(shooter: Unit, origin: Vector3, dir: Vector3, kind: String) -> Projectile:
	var p := Projectile.new()
	p.setup(self, shooter, origin, dir, kind)
	add_child(p)
	return p


# --- Eventos ------------------------------------------------------------------

func _on_player_class_changed(u: Unit) -> void:
	if not u.is_villager():
		hud.show_big("Agora você é %s!" % u.stats.display_name, u.stats.hat_color.lightened(0.3), 1.3)


func _on_unit_died(u: Unit, killer: Unit) -> void:
	if u == player:
		hud.show_big("Você caiu! Voltando como recruta...", Color(1, 0.6, 0.6), 1.8)
	elif killer == player:
		# Abate do jogador: o espírito sobe, a tela dá um tranco e o tempo engasga.
		Fx.burst(self, u.global_position + Vector3(0, 1, 0), Color(1, 0.9, 0.3), 16, 7.0)
		Fx.burst(self, u.global_position + Vector3(0, 1.6, 0), Color(0.4, 1.0, 1.0), 8, 4.0)
		camera.add_trauma(0.3)
		camera.punch_fov(3.0)
		slowmo(0.35, 0.12)


## Chamado quando o jogador usa o poder (para o print do --print-poder).
func on_player_power() -> void:
	if _print_poder and _shots_dir != "" and not _shot_times.is_empty():
		_shot_times[0] = _time + 0.15


var _slowmo_id := 0

## Câmera lenta curta: o jogo inteiro roda a "scale" da velocidade por
## real_time segundos de tempo real (não do tempo do jogo).
func slowmo(scale: float, real_time: float) -> void:
	if game_over:
		return
	_slowmo_id += 1
	var id := _slowmo_id
	Engine.time_scale = minf(Engine.time_scale, scale)
	await get_tree().create_timer(real_time, true, false, true).timeout
	if id == _slowmo_id:
		Engine.time_scale = 1.0


func _on_princess_changed(p: Princess) -> void:
	_log("mascara %s -> %s [%d] (t=%.0fs)" % [Config.TEAM_NAMES[p.team], p.state_text(), p.state, _time])
	if game_over:
		return
	var ours := p.team == player.team
	if p.state == Princess.State.CARRIED:
		if ours:
			hud.show_big("Sua máscara foi roubada!", Color(1, 0.45, 0.45), 2.0)
			Sfx.play_ui("alarm")
		elif p.carrier != player:
			hud.show_big("Um aliado pegou a máscara inimiga!", Color(0.6, 0.85, 1.0), 1.6)
