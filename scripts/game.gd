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
var torretas: Array[Torreta] = []
var catapultas: Array[Catapulta] = []     # [time]; vazio no mapa sem catapulta_spot
var catapulta_alvo := Vector3.INF         # onde o jogador vai cair (minimapa)
var catapulta_alvo_time := -1
var torreta_estilo := ""  # --torreta=a|b|c (pranchas); vazio = game_config.torreta_estilo
## Economia do Construtor (Ciclo 2.3): plantas, toras soltas/carregadas,
## pilha de cada castelo e o estoque de madeira de cada time.
var plantas: Array[Planta] = []
var toras: Array[Tora] = []
var pilhas: Array[Pilha] = []
var madeira := [0, 0]
## Caminho dos magos de cada time: -1 = ainda não escolheu; senão o índice em
## GameConfig.magos_opostos. classe/nivel servem o bônus do Unit sem varrer.
var caminho := [-1, -1]
var caminho_classe: Array[StringName] = [&"", &""]
var caminho_nivel := [0, 0]
var _caminho_avisado := false
var score := [0, 0]
var abates_jogador := 0  # HUD (canto superior esquerdo)
var quedas_jogador := 0
var player: Unit
var player_brain: PlayerBrain
## Guia do ciclo da madeira (seta/marcador) e minimapa do canto.
var guia: GuiaConstrutor
var minimapa: Minimapa
## Cursor de mira do jogador (ponta de hardware + enfeites + marcas no chão).
var mira: Mira
var game_over := false

var _cake_t := 2.0
var _pickup_t := 8.0
var _time := 0.0

# Modo de desenvolvimento (linha de comando, depois de "--"):
#   --autoplay          o jogador também é controlado pela IA
#   --shots=<pasta>     salva prints em alguns momentos e fecha o jogo
#   --variacoes         bots começam com todas as variações (teste visual/poderes)
#   --variacoes=N       idem, girando as classes N posições (cada classe pega outro papel)
#   --equilibrio        imprime "ABATE <vítima> <matador>" (ids de classe) a cada morte;
#                       tools/sonda_equilibrio.sh soma isso em 8 partidas
#   --poderes           medidor de todo mundo enche a cada 4 s (vitrine de poderes)
#   --tema=N            usa o tema N de GameConfig.themes (prints de cada tema)
#   --mapa=N            usa o mapa N de GameConfig.maps
#   --vista=mapa|alto|patio  câmera parada vendo o mapa todo / o castelo de cima /
#                       o pátio azul no ângulo da câmera do jogo (prints)
#   --vista=px,py,pz,ax,ay,az  câmera parada em p olhando para a (prints)
#   --print-poder[=s]   com --shots: os prints saem s segundos (0,15) depois de cada poder do jogador
#   --mira              com --shots: mostra a mira do jogador no print (segue a mira do bot)
#   --classe=<nome>     o jogador começa nessa classe (config/classes/<nome>.tres), para prints
#   --filme=<pasta>     roteiro fixo com o jogador (golpe, dash, pulo, pancada,
#                       morte) salvando um quadro a cada 2: prancha de animação
#   --pisca=<pasta>     câmera do jogo sobre a praça do pátio azul andando 1 cm por
#                       quadro (PISCA_PASSO=m no ambiente muda): salva pisca.jpg com os
#                       pixels que mudaram de um quadro para o outro em vermelho e
#                       imprime quantos (chão piscando: z-fighting, desenho fino demais)
#   --perf=N            mede o desempenho na qualidade N (0-3): a cada 5 s imprime
#                       ms de CPU por quadro, draw calls, triângulos e objetos
#   --menu=inicio|pausa com --autoplay: abre essa tela por cima da partida, sem
#                       pausar (prints da interface)
#   --testes            roda os testes de regra (tests/regras.gd) e sai com 0/1
#   --qa-mapa=<pasta>   QA automático do mapa (tests/qa_mapa.gd): qa_mapa.txt
#   --vitrine=<pasta>   com --classe: câmera parada, 3 alvos, o jogador faz 3 ataques,
#                       o Q e o E; salva 1 PNG a cada 3 quadros (GIF antes/depois)
#                       (até 30 linhas) e, com tela, qa_mapa.jpg; implica --autoplay
# Ex.: godot --path . -- --autoplay --shots=/tmp/prints
var _autoplay := false
## Modo teste (sandbox): só o jogador no mapa, todas as oficinas prontas e,
## nelas, [F] troca a classe (comuns) ou sobe o nível (magos); torretas de pé,
## catapultas prontas e Q/E/R/catapulta recarregando rápido (grupo "Modo teste"
## do game_config). REGRA: feature nova na main entra aqui disponível. Liga com
## --sandbox, com "?sandbox" no endereço da versão web ou pelo botão da tela
## inicial (sandbox_pedido sobrevive ao reload da cena).
static var sandbox_pedido := false
## Time do jogador (Config.TEAM_BLUE/RED): escolhido na tela inicial, vale
## para a partida normal e o modo teste (--time=vermelho, "?time=vermelho" na web).
static var time_pedido := Config.TEAM_BLUE
var time_jogador := Config.TEAM_BLUE
var sandbox := false
var _montando_sandbox := false
var _variacoes := false
var _variacoes_giro := 0
var _equilibrio := false
## --equilibrio: por classe, dano causado, cura dada e segundos vivo (RESUMO a cada 60 s).
var _eq: Dictionary = {}
var _eq_t := 0.0
var _letreiros_t := 0.0
var _poderes := false
var _poderes_t := 2.0
var _shots_dir := ""
var _mira_print := false
var _menu_print := ""
var _clipe_dir := ""  # --clipe=DIR --cena=NOME [--clipe-n=N]: grava um clipe do "Como jogar" (ClipeCenas)
var _clipe_max := 40
var _clipe_cena := ""
var _tutorial_dir := ""  # --tutorial=DIR: print de cada aba do "Como jogar" e sai
var _vista := ""
var _print_poder := false
var _print_atraso := 0.15
var _classe_jogador := ""
var _perf := false
var _filme_dir := ""
var _pisca_dir := ""
var _pisca_f := 0
var _pisca_imgs: Array[Image] = []
var _filme_f := -1
var _filme_y := 0.0
var _vitrine_dir := ""
var _vitrine_f := -1
var _vitrine_p0 := Vector3.ZERO
var _vitrine_alvos: Array[Unit] = []
var _hud_t := 0.0
var _perf_acc := {}
var _perf_n := 0
var _perf_t := 0.0
var _perf_t0 := 0
var _testes := false  # --testes: roda tests/regras.gd e sai
var _qa_dir := ""
var _shot_times: Array[float] = [4.0, 15.0, 30.0, 50.0, 75.0]

const BOT_ROLES := [BotBrain.Role.ATTACK, BotBrain.Role.DEFEND, BotBrain.Role.ATTACK, BotBrain.Role.CAKE,
		BotBrain.Role.ATTACK, BotBrain.Role.DEFEND, BotBrain.Role.ATTACK, BotBrain.Role.ATTACK]


func _ready() -> void:
	Engine.time_scale = 1.0  # reinício no meio de uma câmera lenta
	randomize()
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg == "--sandbox":
			sandbox_pedido = true
		elif arg.begins_with("--time="):
			time_pedido = Config.TEAM_RED if arg.trim_prefix("--time=").begins_with("v") else Config.TEAM_BLUE
		elif arg == "--variacoes":
			_variacoes = true
		elif arg.begins_with("--variacoes="):
			_variacoes = true
			_variacoes_giro = int(arg.trim_prefix("--variacoes="))
		elif arg == "--equilibrio":
			_equilibrio = true
		elif arg == "--poderes":
			_poderes = true
		elif arg.begins_with("--perf="):
			_perf = true
			Settings.auto_quality = false
			Settings.quality = int(arg.trim_prefix("--perf="))
		elif arg.begins_with("--print-poder"):
			_print_poder = true
			if arg.contains("="):
				_print_atraso = float(arg.get_slice("=", 1))
		elif arg == "--mira":
			_mira_print = true
		elif arg.begins_with("--classe="):
			_classe_jogador = arg.trim_prefix("--classe=")
		elif arg.begins_with("--torreta="):
			torreta_estilo = arg.trim_prefix("--torreta=")
		elif arg.begins_with("--filme="):
			_filme_dir = arg.trim_prefix("--filme=")
		elif arg.begins_with("--pisca="):
			_pisca_dir = arg.trim_prefix("--pisca=")
			Settings.auto_quality = false
		elif arg.begins_with("--vitrine="):
			_vitrine_dir = arg.trim_prefix("--vitrine=")
			Settings.auto_quality = false  # o xvfb é lento: sem isso cairia para a Mínima
			Settings.quality = 2
		elif arg.begins_with("--clipe="):
			_clipe_dir = arg.trim_prefix("--clipe=")
		elif arg.begins_with("--cena="):
			_clipe_cena = arg.trim_prefix("--cena=")
		elif arg.begins_with("--clipe-n="):
			_clipe_max = int(arg.trim_prefix("--clipe-n="))
		elif arg.begins_with("--tutorial="):
			_tutorial_dir = arg.trim_prefix("--tutorial=")
		elif arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg.begins_with("--menu="):
			_menu_print = arg.trim_prefix("--menu=")
		elif arg.begins_with("--vista="):
			_vista = arg.trim_prefix("--vista=")
		elif arg.begins_with("--mapa="):
			Settings.mapa = int(arg.trim_prefix("--mapa="))
		elif arg.begins_with("--tema="):
			Settings.theme = int(arg.trim_prefix("--tema="))
		elif arg == "--testes":
			_testes = true
		elif arg.begins_with("--qa-mapa="):
			_qa_dir = arg.trim_prefix("--qa-mapa=")
			_autoplay = true
	if OS.has_feature("web"):
		var busca := str(JavaScriptBridge.eval("window.location.search", true))
		if busca.contains("sandbox"):
			sandbox_pedido = true
		if busca.contains("time=vermelho"):
			time_pedido = Config.TEAM_RED
	sandbox = sandbox_pedido
	time_jogador = time_pedido
	if _print_poder:
		_shot_times = [1e9, 1e9, 1e9, 1e9, 1e9, 1e9]  # quem marca a hora é o poder
	arena = Arena.new()
	arena.name = "Arena"
	arena.leve = sandbox
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
		# Terrenos de oficina: começam com opções diferentes, sorteadas. Os
		# magos opostos ganham terrenos fixos, um de cada lado do castelo.
		var magos := Config.cfg.magos_opostos
		var com_caminho: bool = magos.size() == 2 and arena.mago_spots[team].size() >= 2
		var opts: Array[ClassStats] = Config.cfg.oficina_classes.duplicate()
		if not com_caminho:
			for m in magos:
				if not opts.has(m):
					opts.append(m)
		var n_opts := opts.size()
		if n_opts > 0:
			var order := range(n_opts)
			order.shuffle()
			for i in arena.oficina_spots[team].size():
				var of := Oficina.new()
				add_child(of)
				of.setup(self, team, arena.oficina_spots[team][i], order[i % n_opts], opts)
				oficinas.append(of)
		if com_caminho:
			for i in 2:
				var of := Oficina.new()
				add_child(of)
				of.setup(self, team, arena.mago_spots[team][i], i, magos, i)
				oficinas.append(of)
		for tp in arena.torreta_spots[team]:
			var tor := Torreta.new()
			add_child(tor)
			tor.setup(self, team, tp)
			torretas.append(tor)
		if arena.catapulta_spot[team] != Vector3.INF:
			var cat := Catapulta.new()
			add_child(cat)
			cat.setup(self, team, arena.catapulta_spot[team])
			catapultas.append(cat)
		_montar_economia(team)

	_registrar_modelos()

	var cfg := Config.cfg
	var start_classes: Array[ClassStats] = cfg.bot_start_classes if not cfg.bot_start_classes.is_empty() else [cfg.villager]
	if _variacoes:
		start_classes = cfg.hat_classes() + cfg.oficina_classes + cfg.magos_opostos
	for team in 2:
		for i in cfg.units_per_team:
			var is_player := team == time_jogador and i == 0
			if sandbox and not is_player:
				continue  # modo teste: sem bots
			var u := Unit.new()
			u.name = "%s_%d" % [Config.TEAM_NAMES[team], i]
			add_child(u)
			var cls: ClassStats = cfg.villager if is_player else start_classes[(i + _variacoes_giro) % start_classes.size()]
			if is_player and _classe_jogador != "":
				cls = load("res://config/classes/%s.tres" % _classe_jogador)
			u.setup(self, team, is_player, cls)
			u.global_position = arena.random_spawn(team, units)
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
			var cx := -arena.map.castle_distance
			camera.fov = 42
			camera.position = Vector3(cx, 0, 0) + Vector3(0, 21, 19) * 1.55
			camera.look_at(Vector3(cx, 0, 0))
		elif _vista == "torreta" and not torretas.is_empty():  # a 1ª torreta azul, com a câmera do jogo
			var tp: Vector3 = torretas[0].global_position
			camera.fov = 42
			camera.position = tp + Config.cfg.camera_offset * 0.55
			camera.look_at(tp + Vector3(0, 1.2, 0))
		elif _vista.count(",") == 5:  # --vista=px,py,pz,ax,ay,az: câmera em p olhando para a
			var v := _vista.split_floats(",")
			camera.fov = 42
			camera.position = Vector3(v[0], v[1], v[2])
			camera.look_at(Vector3(v[3], v[4], v[5]))
		else:
			camera.fov = 45
			camera.position = Vector3(-22, 22, 26)
			camera.look_at(Vector3(-40, 2, 0))

	if _testes:
		var t: Node = load("res://tests/regras.gd").new()
		t.set("game", self)
		add_child(t)
	if _qa_dir != "":
		var qa: Node = load("res://tests/qa_mapa.gd").new()
		qa.set("game", self)
		qa.set("dir", _qa_dir)
		add_child(qa)

	hud = Hud.new()
	add_child(hud)
	# Minimapa no canto inferior direito, acima da linha de ajuda.
	minimapa = Minimapa.new()
	hud.add_child(minimapa)
	minimapa.setup(self)
	minimapa.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	minimapa.offset_top -= 34.0
	minimapa.offset_bottom -= 34.0
	minimapa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	minimapa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	mira = Mira.new()
	add_child(mira)
	mira.setup(self)
	mira.para_print = _mira_print
	guia = GuiaConstrutor.new()
	add_child(guia)
	guia.setup(self)
	var auto_q := AutoQuality.new()
	auto_q.hud = hud
	if _vista != "":
		hud.visible = false
	add_child(auto_q)
	if sandbox:
		_montar_sandbox()
	var menus := Menus.new()
	add_child(menus)
	menus.started.connect(_on_started)
	if _autoplay:
		_on_started()
		if _menu_print != "":
			menus.mostrar_para_print(_menu_print)
	else:
		menus.show_start()
	if _tutorial_dir != "":
		_prints_tutorial.call_deferred(menus)
	if _clipe_dir != "":
		var cc := ClipeCenas.new()
		cc.game = self
		cc.dir = _clipe_dir
		cc.cena = _clipe_cena
		cc.max_quadros = _clipe_max
		add_child(cc)


## --tutorial=DIR: fotografa cada seção do menu (tela inicial, Controles,
## Configurações, Classes e cada aba do Como jogar) e sai.
func _prints_tutorial(menus: Menus) -> void:
	menus.mostrar_para_print("inicio")
	var n := 0
	for secao in ["jogar", "controles", "config", "classes"]:
		menus._mostrar(secao)
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/menu_%d_%s.jpg" % [_tutorial_dir, n, secao], 0.85)
		n += 1
	# Uma ficha por classe (barras, textos e quadros de cada uma).
	menus._mostrar("classes")
	for s in PaginaClasses.lista():
		menus._classes._mostrar(s)
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/classe_%s.jpg" % [_tutorial_dir, s.id], 0.85)
	menus._mostrar("como_jogar")
	var tabs: TabContainer = menus._tutorial._tabs
	for i in tabs.get_tab_count():
		tabs.current_tab = i
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/tutorial_%d.jpg" % [_tutorial_dir, i], 0.85)
	get_tree().quit()


## Modo teste: todas as oficinas do time azul prontas (as duas dos magos
## também, sem selo) e todas as maquininhas no nível 2.
func _montar_sandbox() -> void:
	_montando_sandbox = true
	_caminho_avisado = true
	for of in oficinas:
		if of.team == time_jogador:
			of.concluir_ja()
	for pad in hat_pads:
		if pad.team == time_jogador:
			pad.subir_nivel()
	# Torretas dos dois lados de pé: a inimiga serve de treino de escudo.
	for t in torretas:
		t.concluir_ja()
	_montando_sandbox = false


func _on_started() -> void:
	if sandbox:
		hud.show_big("MODO TESTE\nTudo pronto e recarregando rápido (Q, E, R, catapulta).\nNas oficinas, F troca a classe ou sobe o nível.", Color(1, 0.9, 0.5), 4.5)
		Sfx.start_music()
		return
	var inimiga := "vermelha" if time_jogador == Config.TEAM_BLUE else "azul"
	hud.show_big("Roube a Máscara Oni %s!\nTraga-a para o seu castelo." % inimiga, Color(1, 0.9, 0.5), 3.5)
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


## Começo calmo (inicio_calmo s): bots ficam na própria metade.
func inicio_calmo() -> bool:
	return _time < Config.cfg.inicio_calmo


func _physics_process(delta: float) -> void:
	_time += delta
	if _shots_dir != "" and not _shot_times.is_empty() and _time >= _shot_times[0]:
		_take_shot()
	if _filme_dir != "" and _time >= 3.0:
		_filme()
	if _pisca_dir != "" and _time >= 1.0:
		_pisca()
	if _vitrine_dir != "" and _time >= 1.0:
		_vitrine()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if game_over:
		return
	_spawn_cakes(delta)
	_spawn_pickups(delta)
	if _equilibrio:
		for u in units:
			if u.alive:
				eq_somar(u.stats.id, "vivo", delta)
		_eq_t += delta
		if _eq_t >= 60.0:
			_eq_t = 0.0
			for id in _eq:
				var e: Dictionary = _eq[id]
				print("RESUMO %s %.0f %.0f %.0f" % [id, e.get("dano", 0.0), e.get("cura", 0.0), e.get("vivo", 0.0)])
	_letreiros_t -= delta
	if _letreiros_t <= 0.0:
		_letreiros_t = 0.15
		_letreiros_perto()
	if _poderes:
		_poderes_t -= delta
		if _poderes_t <= 0.0:
			_poderes_t = 4.0
			for u in units:
				u.fill_power()
	if sandbox:
		# Modo teste: Chi e Super enchem rápido para testar E e R toda hora.
		for u in units:
			u.add_power(Config.cfg.power_regen * (Config.cfg.sandbox_chi_mult - 1.0) * delta)
			u.add_super(Unit.POWER_MAX / maxf(Config.cfg.sandbox_super_s, 0.5) * delta)
	_rules()
	# O HUD não precisa de 60 atualizações por segundo: 20 Hz bastam ao olho
	# e cada atualização mexe em vários textos e barras.
	_hud_t -= delta
	if _hud_t <= 0.0:
		_hud_t = 0.05
		hud.update_state(self)
		minimapa.alvo_guia = guia.alvo


func _log(msg: String) -> void:
	if _autoplay:
		print(msg)


## --filme: o jogador (sem cérebro) faz um roteiro fixo, de lado para a
## câmera, e cada 2 quadros vira um PNG.
## --pisca=DIR: mede o "chão piscando". Com a câmera andando 1 cm por quadro
## (~0,3 px na tela), só bordas e desenhos mais finos que ~3 px mudam de cor de um
## quadro para o outro: é o que o olho vê como piscar/tremer ao andar (desenho
## abaixo de Nyquist, ou faces no mesmo plano brigando na profundidade).
func _pisca() -> void:
	var foco := arena.to_world(Config.TEAM_BLUE, -4.0, 0.0)
	if _pisca_f == 0:
		player.brain = null
		player.move_intent = Vector3.ZERO
		player.visible = false
		hud.visible = false
		mira.visible = false
		camera.set_process(false)
		camera.set_physics_process(false)
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		camera.fov = Config.cfg.camera_fov
	var passo := float(OS.get_environment("PISCA_PASSO")) if OS.has_environment("PISCA_PASSO") else 0.01
	camera.global_position = foco + Config.cfg.camera_offset + Vector3(passo * _pisca_f, 0, 0)
	camera.look_at(foco)
	if _pisca_f >= 5:  # os primeiros quadros ainda trocam de câmera e escondem a interface
		_pisca_imgs.append(get_viewport().get_texture().get_image())
	_pisca_f += 1
	if _pisca_imgs.size() < 6:
		return
	var base: Image = _pisca_imgs[0].duplicate()
	var w := base.get_width()
	var h := base.get_height()
	var mudou := 0
	var marca := Image.create(w, h, false, Image.FORMAT_L8)
	for i in range(1, _pisca_imgs.size()):
		var ant: Image = _pisca_imgs[i - 1]
		var img: Image = _pisca_imgs[i]
		for y in h:
			for x in w:
				if marca.get_pixel(x, y).r > 0.5:
					continue
				var a := ant.get_pixel(x, y)
				var b := img.get_pixel(x, y)
				if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
					marca.set_pixel(x, y, Color.WHITE)
					mudou += 1
	for y in h:
		for x in w:
			if marca.get_pixel(x, y).r > 0.5:
				base.set_pixel(x, y, Color(1, 0.1, 0.1))
	DirAccess.make_dir_recursive_absolute(_pisca_dir)
	base.save_jpg(_pisca_dir.path_join("pisca.jpg"), 0.85)
	if OS.has_environment("PISCA_TUDO"):
		for i in _pisca_imgs.size():
			_pisca_imgs[i].save_png(_pisca_dir.path_join("pisca_%d.png" % i))
	print("PISCA: %d pixels de %d mudaram com a câmera andando %.0f mm por quadro (%.2f%%)" % [mudou, w * h, passo * 1000, 100.0 * mudou / (w * h)])
	get_tree().quit()


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


## --vitrine: o mesmo roteiro para qualquer classe (3 ataques, Q, E) com
## câmera fixa e alvos parados que não morrem. Rodar no commit antigo e no
## novo dá o GIF antes/depois de cada poder.
func _vitrine() -> void:
	_vitrine_f += 1
	var f := _vitrine_f
	var p := player
	var frente := Vector3(1, 0, 0)
	var corpo := p.stats.attack_kind == "melee"
	if f == 0:
		_vitrine_p0 = Vector3(-24, 0, 0)
		_vitrine_p0.y = arena.ground_y(_vitrine_p0.x, _vitrine_p0.z, 10.0)
		hud.visible = false
		camera.set_process(false)
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		camera.fov = 42
		var aliado: Unit = null
		for u in units:
			if u == p:
				continue
			if u.team != p.team and _vitrine_alvos.size() < 3:
				u.brain = null
				_vitrine_alvos.append(u)
			elif u.team == p.team and aliado == null:
				aliado = u  # aliado ferido (cura, bênção, corrida)
			else:
				u.process_mode = Node.PROCESS_MODE_DISABLED
				u.global_position = Vector3(0, -40, 0)
				u.visible = false
		aliado.brain = null
		_vitrine_alvos.append(aliado)
		p.brain = null
	if f == 0 or f == 150 or f == 290:
		p.global_position = _vitrine_p0
		p.reset_physics_interpolation()
		var perto := 2.2 if corpo else 8.0
		var lugares := [Vector3(perto, 0, -0.9), Vector3(perto + 0.6, 0, 1.0), Vector3(perto + 2.0, 0, 0.1), Vector3(-1.6, 0, 1.8)]
		for i in _vitrine_alvos.size():
			var u := _vitrine_alvos[i]
			u.global_position = _vitrine_p0 + lugares[i]
			u.reset_physics_interpolation()
			u.move_intent = Vector3.ZERO
			u.aim_dir = -frente if i < 3 else frente
	var foco := _vitrine_p0 + frente * (1.6 if corpo else 4.6)
	camera.global_position = foco + Vector3(0, 6.2, 8.0)
	camera.look_at(foco + Vector3(0, 0.8, 0))
	p.move_intent = Vector3.ZERO
	p.aim_dir = frente
	p.aim_point = _vitrine_p0 + frente * (3.0 if corpo else 9.0)
	for i in _vitrine_alvos.size():
		var u := _vitrine_alvos[i]
		if not u.alive:
			continue
		u.hp = maxf(u.hp, u.max_hp() * (0.5 if i == 3 else 0.6))
		if i == 3 and f < 150:
			u.hp = u.max_hp() * 0.4
	match f:
		20, 70, 120:  # 50 quadros: cabe a recarga de qualquer classe e o combo não zera
			p.wants_attack = true
		21, 71, 121:
			p.wants_attack = false
		165:
			p.wants_quick = true
		300:
			p.fill_power()
			p.wants_power = true
		470:  # depois do E acabar (o Redemoinho segura o super enquanto gira)
			p.super_carga = p.POWER_MAX
			p.wants_super = true
		600:
			p.wants_attack = p.stats.super_tipo == "sombra"  # golpe saindo da sombra
		601:
			p.wants_attack = false
		700:
			get_tree().quit()

	if f % 3 == 0 and f >= 6:
		get_viewport().get_texture().get_image().save_png("%s/f_%03d.png" % [_vitrine_dir, f / 3])


func _take_shot() -> void:
	var t: float = _shot_times.pop_front()
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/shot_%03d.png" % [_shots_dir, int(t)])
	if _shot_times.is_empty():
		get_tree().quit()


# --- Regras -------------------------------------------------------------------

func _rules() -> void:
	var hint := ""
	# Jogador na mão da catapulta: F lança (o corpo é da catapulta até cair).
	if player and player.em_voo and player_brain != null and player_brain.interact_pressed:
		for cat in catapultas:
			if cat.passageiro == player:
				cat.lancar()
	for u in units:
		if not u.alive or u.em_voo:
			continue
		var pos := u.global_position
		var wants_interact := u.is_player and player_brain != null and player_brain.interact_pressed

		# Catapulta do time: o jogador sobe com F; o bot que a reservou sobe e lança.
		var cat := catapulta_do_time(u.team)
		if cat and cat.pronta() and not u.carried_princess and pos.distance_to(cat.global_position) < Catapulta.ALCANCE_EMBARQUE:
			if u.is_player and not (u.brain is BotBrain):
				hint = "[F] subir na catapulta"
				if wants_interact:
					cat.embarcar(u)
					continue
			elif cat.reservado == u:
				cat.embarcar(u)
				cat.forca = randf_range(0.55, 0.95)
				cat.lancar()
				continue
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

		# Pegar a princesa inimiga: bots pegam sozinhos, o jogador aperta F.
		if not u.carried_princess and enemy_p.can_be_taken() and pos.distance_to(enemy_p.global_position) < 2.8:
			if u.is_player:
				hint = "[F] pegar a máscara!"
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
				u.add_super(Config.cfg.super_por_espirito)
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

		var dica_madeira := _regras_madeira(u)
		if u.is_player and dica_madeira != "":
			hint = dica_madeira

		# Itens no chão: qualquer um que encosta pega.
		for it in pickups:
			if pos.distance_to(it.global_position) < 1.6:
				it.apply_to(u)
				u.add_super(Config.cfg.super_por_item)
				pickups.erase(it)
				it.queue_free()
				break

		# Chapéus: recruta veste ao encostar; quem já tem classe troca com F.
		for pad in hat_pads:
			if pad.team != u.team or not pad.available or pad.stats == u.stats or u.is_equipping():
				continue
			if pos.distance_to(pad.global_position) < 2.0:
				if u.is_player:
					hint = "[F] pegar o chapéu de %s" % pad.stats.display_name
				# Jogador: só com F. Bots recrutas (e o jogador no modo teste) pegam sozinhos.
				var bot_pega := u.brain is BotBrain and u.is_villager() and not (pad.stats.velocidade_obra > 0.0 \
						and _bots_lenhadores(u.team, u) >= Config.cfg.bots_construtores_max)
				if wants_interact or bot_pega:
					var from: Vector3 = pad.hat_world_position()
					u.start_equip(pad.take(), from)
				break

	if sandbox:
		hint = _regras_sandbox(hint)

	# Oficina: o jogador troca a opção do terreno com F.
	if player.alive and not player.carried_princess and hint == "":
		var of := nearest_oficina(player.team, player.global_position, Oficina.BUILD_RADIUS + 0.5, true)
		if of:
			var builder := "fique aqui para construir" if player.stats.velocidade_obra > 0.0 else "precisa de um Construtor"
			if of.caminho >= 0:
				var outro := mago_oposto(of)
				var nome_outro := outro.nome_caminho() if outro else "outra"
				if of.comecada():
					hint = "Caminho da %s (%s): %d%%  ·  faltam %d madeiras  ·  %s" % [of.nome_caminho(), of.opcao().display_name, int(of.progresso * 100.0), of.faltam(), builder]
				else:
					hint = "Caminho da %s (%s): construir aqui sela a %s até o fim  ·  %s" % [of.nome_caminho(), of.opcao().display_name, nome_outro, builder]
			elif of.comecada():
				# Obra começada: mostra o progresso guardado; [F] não troca nem apaga nada.
				var falta := "  ·  faltam %d madeiras" % of.faltam() if of.faltam() > 0 else ""
				hint = "Obra de %s: %d%%%s  ·  %s" % [of.opcao().display_name, int(of.progresso * 100.0), falta, builder]
			else:
				hint = "[F] trocar oficina: %s  (%s)" % [of.opcao().display_name, builder]
				if player_brain != null and player_brain.interact_pressed:
					of.trocar_opcao()

	# Primeira vez perto de um terreno de mago: aviso grande da escolha.
	if player.alive and not _caminho_avisado and caminho[player.team] < 0:
		for of in oficinas:
			if of.team == player.team and of.caminho >= 0 and player.global_position.distance_to(of.global_position) < 7.0:
				_caminho_avisado = true
				var outro := mago_oposto(of)
				hud.show_big("Caminho da %s ou da %s\nConstruir um sela o outro" % [of.nome_caminho(), outro.nome_caminho() if outro else "?"],
					of.opcao().hat_color.lightened(0.35), 3.0)
				break

	# Perto da oficina do caminho (pronta) ou do terreno selado.
	if player.alive and hint == "":
		for of in oficinas:
			if of.team != player.team or of.caminho < 0 or player.global_position.distance_to(of.global_position) > Oficina.BUILD_RADIUS + 1.5:
				continue
			if of.selada:
				var esc := mago_oposto(of)
				hint = "Caminho selado: seu time seguiu a %s" % (esc.nome_caminho() if esc else "outro mago")
			elif of.pode_subir():
				hint = "Suba %s ao nível %d: faltam %d madeiras  ·  %s" % [of.opcao().display_name, of.nivel + 1, of.faltam_nivel(),
					"fique aqui" if player.lenhador() else "precisa de um Construtor"]
			elif of.estado == Oficina.Estado.PRONTA:
				hint = "%s no nível máximo (%d)" % [of.opcao().display_name, of.nivel]
			break

	# Construtor perto de uma maquininha nível 1: ela sobe com madeira.
	if player.alive and hint == "" and player.lenhador() and not player.carried_tora:
		for pad in hat_pads:
			if pad.team == player.team and pad.nivel == 1 and player.global_position.distance_to(pad.global_position) < HatPad.OBRA_RAIO:
				hint = "Nível 2 da maquininha de %s: faltam %d madeiras  ·  fique perto" % [pad.stats.display_name, pad.faltam_n2()]
				break

	# Perto de uma planta: diz quem corta e como (a madeira não é óbvia).
	if player.alive and hint == "" and not player.carried_tora and not player.carried_princess:
		for p in plantas:
			if p.estagio != Planta.Estagio.BROTO and player.global_position.distance_to(p.global_position) < 4.0:
				hint = "Golpeie [Clique] para cortar a árvore; a tora cai no chão" if player.lenhador() \
						else "Só a linha do Construtor (chapéu laranja) corta madeira"
				break

	# Construtor longe de tudo: o próximo passo do ciclo, junto com a seta dourada.
	if player.alive and hint == "" and guia.verbo != "":
		match guia.verbo:
			"CORTE":
				hint = "Siga a seta dourada até uma árvore e corte madeira"
			"PEGUE":
				hint = "Pegue a tora no chão: é só encostar"
			"CONSTRUA":
				hint = "Tem madeira no depósito: siga a seta e construa (oficina ou torreta)"

	if player.alive and player.carried_princess:
		hint = "Leve-a até o SEU castelo!  ([F] soltar)"
	elif player.has_cake:
		hint = "Leve o espírito até a sua máscara"
	hud.set_hint(hint)


## Modo teste: maquininhas repõem o chapéu em 1 s; perto da casa de uma
## oficina pronta, [F] troca a classe (comum) ou sobe o nível (mago).
func _regras_sandbox(hint: String) -> String:
	for pad in hat_pads:
		pad.intervalo = minf(pad.intervalo, 1.0)
	if hint != "" or not player.alive or player.carried_princess:
		return hint
	var aperta := player_brain != null and player_brain.interact_pressed
	for of in oficinas:
		if of.team != player.team or of.estado != Oficina.Estado.PRONTA \
				or player.global_position.distance_to(of.global_position) > Oficina.BUILD_RADIUS:
			continue
		if of.caminho >= 0:
			if of.nivel >= Config.cfg.mago_nivel_max:
				return "%s no nível máximo (%d)" % [of.opcao().display_name, of.nivel]
			if aperta:
				of.subir_nivel()
				caminho_classe[of.team] = of.opcao().id
				caminho_nivel[of.team] = of.nivel
			return "[F] subir %s para o nível %d" % [of.opcao().display_name, of.nivel + 1]
		if aperta:
			of.trocar_pronta()
		return "[F] trocar a oficina: %s" % of.opcao().display_name
	return hint


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
	u.add_super(Config.cfg.super_por_captura)
	u.play_cheer(1.2)
	p.return_home()
	score[u.team] += 1
	Sfx.play_ui("score")
	camera.add_trauma(0.3)
	Fx.burst(self, arena.princess_spot[u.team] + Vector3(0, 2, 0), Config.team_color(u.team).lightened(0.4), 40, 12.0)
	FxPoder.coluna_captura(self, arena.princess_spot[u.team], Config.team_color(u.team))
	Sfx.play("captura", arena.princess_spot[u.team], 0.0, 1.0, 4.0)
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
	var pos := arena.random_cake_spot()
	if randf() < Config.cfg.pickup_perto_da_briga:
		var perto: Variant = _spot_perto_da_briga()
		if perto != null:
			pos = perto
	var it := Pickup.new()
	add_child(it)
	it.setup(Pickup.KINDS.pick_random(), pos)
	pickups.append(it)


## Onde a briga está mais cheia: o soldado (fora dos castelos) com mais gente
## dos dois times a até 9 m. O item cai a 3-7 m dele, em chão baixo e longe de
## outro item. null = ninguém brigando ou sem chão bom.
func _spot_perto_da_briga() -> Variant:
	var best: Unit = null
	var best_n := 2
	for u in units:
		if not u.alive or _perto_de_castelo(u.global_position):
			continue
		var n := 0
		for o in units:
			if o.alive and o.global_position.distance_to(u.global_position) < 9.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best == null:
		return null
	for i in 10:
		var a := randf() * TAU
		var p := best.global_position + Vector3(cos(a), 0.0, sin(a)) * randf_range(3.0, 7.0)
		p.y = 0.0
		if arena.ground_y(p.x, p.z) >= 0.3 or _perto_de_castelo(p):
			continue
		if nearest_pickup(p, 4.0) != null:
			continue
		return p
	return null


func _perto_de_castelo(p: Vector3) -> bool:
	for c in arena.spawn_center:
		if Vector2(p.x - c.x, p.z - c.z).length() < 22.0:
			return true
	return false


func nearest_pickup(from: Vector3, max_dist: float) -> Pickup:
	var best: Pickup = null
	var best_d := max_dist
	for it in pickups:
		var d := from.distance_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	return best


# --- Economia do Construtor ---------------------------------------------------

## Pilha de madeira, árvores do bosque seguro e bambus do meio de um castelo.
func _montar_economia(team: int) -> void:
	var pilha := Pilha.new()
	pilha.name = "Pilha%s" % Config.TEAM_NAMES[team]
	add_child(pilha)
	pilha.setup(self, team, arena.pilha_spot[team])
	pilhas.append(pilha)
	for spot in arena.tree_spots[team]:
		_nova_planta("arvore", team, spot)
	for spot in arena.bamboo_spots[team]:
		_nova_planta("bambu", team, spot)


## Contorno de tinta só na qualidade Alta também nos modelos da economia
## (maquininha, pilha, plantas em todos os estágios, tora), que nascem fora da
## Arena. Os materiais de cada .scn são compartilhados: registrar uma vez basta.
func _registrar_modelos() -> void:
	var th := arena.theme
	var tmp := Node3D.new()
	add_child(tmp)
	for cena in th.arvore_estagios + th.bambu_estagios + [th.tora_model]:
		if cena:
			tmp.add_child(cena.instantiate())
	arena.registrar_contornos(self)
	tmp.queue_free()


func _nova_planta(tipo: String, team: int, pos: Vector3) -> Planta:
	var p := Planta.new()
	add_child(p)
	p.setup(self, tipo, team, pos)
	plantas.append(p)
	return p


func soltar_tora(pos: Vector3, dir: Vector3) -> Tora:
	var t := Tora.new()
	add_child(t)
	t.setup(self, pos)
	toras.append(t)
	# Pula para fora da planta (onde o Construtor está).
	var alvo := pos + dir * 1.2
	alvo.y = pos.y - 0.4
	t.create_tween().tween_property(t, "global_position", alvo, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return t


## Golpe de Construtor: acerta as plantas no arco do golpe (a mais perto).
func golpear_plantas(u: Unit, dir: Vector3, alcance: float, arco_deg: float) -> bool:
	var melhor := planta_no_alcance(u, dir, alcance, arco_deg)
	if melhor == null:
		return false
	return melhor.golpe(u)


## Planta cortável (jovem ou adulta) mais perto, dentro do alcance e do arco.
func planta_no_alcance(u: Unit, dir: Vector3, alcance: float, arco_deg: float) -> Planta:
	var melhor: Planta = null
	var melhor_d := alcance
	for p in plantas:
		var to := p.global_position - u.global_position
		to.y = 0
		var d := to.length()
		if d > melhor_d or p.estagio == Planta.Estagio.BROTO:
			continue
		if d > 0.8 and rad_to_deg(dir.angle_to(to.normalized())) > arco_deg / 2.0:
			continue
		melhor = p
		melhor_d = d
	return melhor


func entregar_tora(u: Unit) -> void:
	var t := u.carried_tora
	if t == null:
		return
	u.carried_tora = null
	toras.erase(t)
	# A tora voa num arco e cai dentro do armazém (o "buraco" da base).
	t.carrier = null
	t.set_process(false)
	t.set_physics_process(false)
	var de := t.global_position
	var ate := pilhas[u.team].global_position + Vector3(0, 0.8, 0)
	var tw := t.create_tween()
	tw.tween_method(func(k: float):
		t.global_position = de.lerp(ate, k) + Vector3(0, sin(k * PI) * 2.0, 0)
		t.rotation.z = k * TAU, 0.0, 1.0, 0.35)
	tw.tween_callback(t.queue_free)
	madeira[u.team] += 1
	pilhas[u.team].atualizar(madeira[u.team])
	_log("madeira %s = %d (t=%.0fs)" % [Config.TEAM_NAMES[u.team], madeira[u.team], _time])
	Sfx.play("pickup", u.global_position, 0.05)
	Fx.burst(self, pilhas[u.team].global_position + Vector3(0, 1.0, 0), Color(0.9, 0.7, 0.4), 8, 3.0)
	if u.is_player:
		hud.show_big("+1 madeira  ·  depósito: %d" % madeira[u.team], Color(1, 0.8, 0.5), 0.9)


## Tira n do estoque do time. Sem estoque suficiente, não tira nada.
func gastar_madeira(team: int, n: int) -> bool:
	if madeira[team] < n:
		return false
	madeira[team] -= n
	if team < pilhas.size():
		pilhas[team].atualizar(madeira[team])
	return true


func nearest_tora_solta(from: Vector3, max_dist: float) -> Tora:
	var best: Tora = null
	var best_d := max_dist
	for t in toras:
		if t.no_chao():
			var d := from.distance_to(t.global_position)
			if d < best_d:
				best_d = d
				best = t
	return best


## Regras da madeira por boneco: pegar tora solta e entregar na pilha.
func _regras_madeira(u: Unit) -> String:
	if not u.lenhador() or u.carried_princess:
		return ""
	var pos := u.global_position
	if u.carried_tora:
		if pos.distance_to(pilhas[u.team].global_position) < Config.cfg.pilha_raio:
			entregar_tora(u)
			return ""
		# A tora também serve direto numa torreta do time que ainda falta madeira.
		for tor in torretas:
			if tor.team == u.team and tor.faltam() > 0 and pos.distance_to(tor.global_position) < Torreta.RAIO_OBRA:
				tor.receber_tora(u)
				return ""
		return "Siga a seta: entregue a tora no DEPÓSITO do seu castelo (ícone de tora)"
	var t := nearest_tora_solta(pos, 1.6)
	if t and not u.is_equipping():
		t.pegar(u)
	return ""


# --- Consultas usadas pelos bots ----------------------------------------------

## Oficina do time mais perto (só as não prontas, se unbuilt_only).
func nearest_oficina(team: int, from: Vector3, max_dist: float, unbuilt_only: bool) -> Oficina:
	var best: Oficina = null
	var best_d := max_dist
	for of in oficinas:
		if of.team != team or of.selada or (unbuilt_only and of.estado == Oficina.Estado.PRONTA):
			continue
		var d := from.distance_to(of.global_position)
		if d < best_d:
			best_d = d
			best = of
	return best


## Obra que o Construtor deve tocar: a começada mais adiantada do time (todos
## continuam de onde os outros pararam, sem espalhar madeira em vários
## terrenos); sem obra começada, o terreno vazio mais perto.
func obra_do_time(team: int, from: Vector3) -> Oficina:
	var best: Oficina = null
	var best_v := 0.0
	for of in oficinas:
		if of.team != team or of.selada or of.estado == Oficina.Estado.PRONTA or not of.comecada():
			continue
		var v := of.progresso + float(of.madeira_entregue) / maxf(of.custo(), 1)
		if best == null or v > best_v:
			best_v = v
			best = of
	return best if best else nearest_oficina(team, from, 1e9, true)


## Terreno de torreta do time para o Construtor: a obra começada, senão o
## terreno vazio mais perto. null = todas de pé.
func torreta_para_obra(team: int, from: Vector3) -> Torreta:
	var best: Torreta = null
	for t in torretas:
		if t.team != team or t.pronta():
			continue
		if best == null or t.madeira_entregue > best.madeira_entregue or (t.madeira_entregue == best.madeira_entregue \
				and from.distance_to(t.global_position) < from.distance_to(best.global_position)):
			best = t
	return best


## A torreta que o Construtor deve erguer agora, ou null: só depois da 1ª
## oficina, entre uma obra e outra (nunca larga uma oficina começada, `of` =
## obra_do_time), e só se há o que fazer lá: madeira no estoque para puxar ou
## madeira já entregue que a obra ainda não alcançou (Ciclo 2.12: antes o
## Construtor ficava parado na torreta com a obra travada no teto, sem estoque).
## Vale para os bots (BotBrain._lenhador) e para a seta-guia do jogador (GuiaConstrutor).
func torreta_para_construir(team: int, from: Vector3, of: Oficina) -> Torreta:
	var tor := torreta_para_obra(team, from)
	if tor == null or not (of == null or (not of.comecada() and oficinas_prontas(team) >= 1)):
		return null
	var teto := float(tor.madeira_entregue) / maxf(tor.custo(), 1)
	return tor if madeira[team] >= 1 or tor.progresso < teto - 1e-4 else null


func catapulta_do_time(team: int) -> Catapulta:
	for c in catapultas:
		if c.team == team:
			return c
	return null


## Catapulta para um bot atacante: a do time, pronta e livre (ou já reservada
## por ele). Sorteia uma vez por decisão (catapulta_bots).
func catapulta_para_bot(u: Unit) -> Catapulta:
	var cat := catapulta_do_time(u.team)
	if cat == null or not cat.pronta():
		return null
	if cat.reservado == u:
		cat.reserva_t = _time
		return cat
	# Reserva de outro bot vale enquanto ele renova (a cada decisão); se ele
	# mudou de ideia ou morreu, libera.
	if cat.reservado and cat.reservado.alive and _time - cat.reserva_t < 4.0:
		return null
	if u.global_position.distance_to(cat.global_position) > 22.0 or randf() > Config.cfg.catapulta_bots:
		return null
	# Lançar = ir roubar: só com a máscara inimiga em casa (revisão 2026-11-06).
	if princesses.size() == 2 and princesses[1 - u.team].state != Princess.State.HOME:
		return null
	cat.reservado = u
	cat.reserva_t = _time
	return cat


## Torreta inimiga de pé mais perto de `from` (até r). Bots vão derrubá-la.
func torreta_inimiga_perto(team: int, from: Vector3, r: float) -> Torreta:
	var best: Torreta = null
	var best_d := r
	for t in torretas:
		if t.team == team or not t.pronta():
			continue
		var d := from.distance_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t
	return best


## Golpe corpo a corpo de u acerta torretas inimigas no alcance e no arco.
func golpear_torretas(u: Unit, dir: Vector3, alcance: float, arco_deg: float, dano: float) -> bool:
	var acertou := false
	for t in torretas:
		if t.team == u.team or not t.pronta():
			continue
		var to := t.global_position - u.global_position
		to.y = 0
		if to.length() > alcance + Torreta.RAIO_CORPO:
			continue
		if to.length() > 1.2 and rad_to_deg(dir.angle_to(to.normalized())) > arco_deg / 2.0:
			continue
		t.take_hit(dano, u.team)
		acertou = true
	return acertou


## Maquininha nível 1 do time para o Construtor subir com madeira: a que já
## tem mais madeira posta, depois a mais perto.
func maquina_para_n2(team: int, from: Vector3) -> HatPad:
	var best: HatPad = null
	for pad in hat_pads:
		if pad.team != team or pad.nivel >= 2:
			continue
		if best == null or pad.madeira_n2 > best.madeira_n2 or (pad.madeira_n2 == best.madeira_n2 \
				and from.distance_to(pad.global_position) < from.distance_to(best.global_position)):
			best = pad
	return best


## Oficina de mago pronta abaixo do nível máximo, para o Construtor subir.
func mago_para_subir(team: int) -> Oficina:
	for of in oficinas:
		if of.team == team and of.pode_subir():
			return of
	return null


## O outro terreno de mago do mesmo time (null em terreno comum).
func mago_oposto(of: Oficina) -> Oficina:
	if of.caminho < 0:
		return null
	for o in oficinas:
		if o != of and o.team == of.team and o.caminho >= 0:
			return o
	return null


## A primeira madeira (ou martelada) num terreno de mago escolhe o caminho
## do time: o terreno do outro lado é selado pelo resto da partida.
func on_obra_comecou(of: Oficina) -> void:
	if of.caminho < 0 or caminho[of.team] >= 0:
		return
	caminho[of.team] = of.caminho
	caminho_classe[of.team] = of.opcao().id
	var outro := mago_oposto(of)
	if outro:
		outro.selar()
	_log("caminho %s: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.opcao().display_name, _time])
	if hud and player and of.team == player.team:
		hud.show_big("Caminho da %s escolhido\n%s selada até o fim" % [of.nome_caminho(),
			outro.nome_caminho() if outro else "A outra"], of.opcao().hat_color.lightened(0.3), 2.6)


func on_mago_nivel(of: Oficina) -> void:
	caminho_nivel[of.team] = of.nivel
	_log("mago %s nível %d: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.nivel, of.opcao().display_name, _time])
	if hud and player:
		if of.team == player.team:
			hud.show_big("%s: nível %d/%d!" % [of.opcao().display_name, of.nivel, Config.cfg.mago_nivel_max], of.opcao().hat_color.lightened(0.3), 2.2)
		else:
			hud.show_big("O inimigo subiu %s para o nível %d" % [of.opcao().display_name, of.nivel], Color(1, 0.6, 0.55), 1.6)


## Níveis acima do 2 do mago do caminho, para um soldado dessa classe (0 = sem bônus).
func bonus_mago(team: int, id: StringName) -> int:
	if id == &"" or caminho_classe[team] != id:
		return 0
	return maxi(caminho_nivel[team] - 2, 0)


func on_oficina_pronta(of: Oficina) -> void:
	if of.caminho >= 0:
		caminho_nivel[of.team] = of.nivel
	_log("oficina %s pronta: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.opcao().display_name, _time])
	# A maquininha da classe de origem sobe para o nível 2 (Ronin Oni -> Samurai).
	var base := of.opcao().classe_base
	for pad in hat_pads:
		if base != &"" and pad.team == of.team and pad.stats.id == base and pad.subir_nivel():
			_log("maquininha %s nível 2: %s" % [Config.TEAM_NAMES[of.team], pad.stats.display_name])
			if of.team == player.team and not _montando_sandbox:
				hud.show_big("Oficina pronta: %s!\nMaquininha de %s no nível 2" % [of.opcao().display_name, pad.stats.display_name], of.opcao().hat_color.lightened(0.3), 2.4)
				return
	if _montando_sandbox:
		return
	if of.team == player.team:
		hud.show_big("Oficina pronta: %s!" % of.opcao().display_name, of.opcao().hat_color.lightened(0.3), 2.0)
	else:
		hud.show_big("O inimigo liberou %s" % of.opcao().display_name, Color(1, 0.6, 0.55), 1.6)


## Chapéu com estoque mais perto. Para bots (quem != null), o de Construtor
## só vale enquanto o time tem menos de bots_construtores_max bots lenhadores.
func nearest_free_hat(team: int, from: Vector3, quem: Unit = null) -> HatPad:
	var best: HatPad = null
	var best_d := INF
	var sem_lenhador := quem != null and _bots_lenhadores(team, quem) >= Config.cfg.bots_construtores_max
	for pad in hat_pads:
		if pad.team == team and pad.available and not (sem_lenhador and pad.stats.velocidade_obra > 0.0):
			var d := from.distance_to(pad.global_position)
			if d < best_d:
				best_d = d
				best = pad
	return best


func oficinas_prontas(team: int) -> int:
	var n := 0
	for of in oficinas:
		if of.team == team and of.estado == Oficina.Estado.PRONTA:
			n += 1
	return n


func _bots_lenhadores(team: int, fora: Unit) -> int:
	var n := 0
	for u in units:
		if u != fora and u.team == team and u.brain is BotBrain and u.lenhador():
			n += 1
	return n


func nearest_cake(from: Vector3) -> Cake:
	var best: Cake = null
	var best_d := INF
	for c in cakes:
		var d := from.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func eq_somar(id: StringName, campo: String, v: float) -> void:
	if not _eq.has(id):
		_eq[id] = {}
	_eq[id][campo] = _eq[id].get(campo, 0.0) + v


## Letreiros de estado (grupo "letreiro_perto": oficinas, maquininhas, depósito,
## torreta) somem de longe: opacos até 11 m do jogador, transparentes a 15 m.
## Os títulos grandes (TORRETA, caminho dos magos) ficam sempre: orientam.
func _letreiros_perto() -> void:
	if player == null:
		return
	var foco := player.global_position
	for n in get_tree().get_nodes_in_group("letreiro_perto"):
		var l := n as Label3D
		if l == null:
			continue
		var d := Vector2(l.global_position.x - foco.x, l.global_position.z - foco.z).length()
		l.transparency = clampf((d - 11.0) / 4.0, 0.0, 1.0)


func spawn_projectile(shooter: Unit, origin: Vector3, dir: Vector3, kind: String) -> Projectile:
	var p := Projectile.new()
	p.setup(self, shooter, origin, dir, kind)
	p.add_to_group("projeteis")  # bots olham para esquivar (BotBrain._esquiva_projetil)
	add_child(p)
	return p


# --- Eventos ------------------------------------------------------------------

func _on_player_class_changed(u: Unit) -> void:
	if u.lenhador():
		# Ciclo da madeira explicado na hora em que o jogador vira Construtor.
		hud.show_big("Você é %s!\nCorte árvores e leve as toras ao depósito" % u.stats.display_name, u.stats.hat_color.lightened(0.3), 2.6)
	elif not u.is_villager():
		hud.show_big("Agora você é %s!" % u.stats.display_name, u.stats.hat_color.lightened(0.3), 1.3)


func _on_unit_died(u: Unit, killer: Unit) -> void:
	if _equilibrio:
		print("ABATE %s %s" % [u.stats.id, killer.stats.id if killer else "nada"])
	if killer and killer.team != u.team:
		_alma_de_abate(u, killer.team)
	if u == player:
		quedas_jogador += 1
	elif killer == player and u.team != player.team:
		abates_jogador += 1
	if u == player:
		hud.show_big("Você caiu! Voltando como recruta...", Color(1, 0.6, 0.6), 1.8)
	elif killer == player:
		# Abate do jogador: o espírito sobe, a tela dá um tranco e o tempo engasga.
		Fx.burst(self, u.global_position + Vector3(0, 1, 0), Color(1, 0.9, 0.3), 16, 7.0)
		Fx.burst(self, u.global_position + Vector3(0, 1.6, 0), Color(0.4, 1.0, 1.0), 8, 4.0)
		camera.add_trauma(0.3)
		camera.punch_fov(3.0)
		slowmo(0.35, 0.12)


## A alma do abatido voa até a máscara do time de quem matou e a deixa mais
## pesada (Princess.pesar_alma). Ela pesa ao chegar, não no abate.
func _alma_de_abate(morto: Unit, team: int) -> void:
	var mascara := princesses[team]
	var alma := Cake.make_visual(0.45)
	alma.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(alma)
	var de := morto.global_position + Vector3(0, 1.4, 0)
	alma.global_position = de
	var tw := alma.create_tween()
	# Arco: sobe e cai na máscara (que pode estar andando no colo de alguém).
	tw.tween_method(func(k: float):
		var ate := mascara.global_position + Vector3(0, 1.6, 0)
		alma.global_position = de.lerp(ate, k) + Vector3(0, sin(k * PI) * 4.0, 0), 0.0, 1.0, 0.9) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		mascara.pesar_alma(Config.cfg.alma_por_abate)
		_log("alma -> mascara %s peso=%.2f (t=%.0fs)" % [Config.TEAM_NAMES[team], mascara.fatness, _time])
		alma.queue_free())


## Chamado quando o jogador usa o poder (para o print do --print-poder).
func on_player_power() -> void:
	if _print_poder and _shots_dir != "" and not _shot_times.is_empty():
		_shot_times[0] = _time + _print_atraso


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
	arena.torre_alarme(p.team, p.state != Princess.State.HOME)
	if game_over:
		return
	var ours := p.team == player.team
	if p.state == Princess.State.CARRIED:
		if ours:
			hud.show_big("Sua máscara foi roubada!", Color(1, 0.45, 0.45), 2.0)
			Sfx.play_ui("alarm")
		elif p.carrier != player:
			hud.show_big("Um aliado pegou a máscara inimiga!", Color(0.6, 0.85, 1.0), 1.6)
