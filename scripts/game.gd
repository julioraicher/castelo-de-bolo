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
## Aviso grande da escolha de caminho (uma vez, no primeiro bairro visitado).
var _caminho_avisado := false
var score := [0, 0]
var abates_jogador := 0  # HUD (canto superior esquerdo)
var quedas_jogador := 0
var player: Unit
var player_brain: PlayerBrain
## Guia do ciclo da madeira (seta/marcador) e minimapa do canto.
var guia: GuiaConstrutor
var minimapa: Minimapa
## Placar estilo Battlefield (Tab): estatística e pontos de cada boneco.
var placar: Placar
## Reanimar aliados caídos (Ciclo 2.18): regra + chama de espírito.
var reanimar: Reanimar
var placar_tela: PlacarTela
var placar_print := false
## Tempo de partida mostrado no placar (para no fim; `_time` segue para efeitos).
var tempo_partida := 0.0
## Ciclo 2.23: prorrogação (s já passados; -1 = não começou)
## e o resultado do fim (time vencedor; -1 = empate).
var prorrogacao := -1.0
## Ciclo 2.25: morte súbita (s já passados; -1 = não começou) e se o fim saiu
## pelos pontos do placar do Tab (ninguém pontuou nem na morte súbita).
var morte_subita := -1.0
var decidido_no_placar := false
var vencedor := -1
var _tique_s := -1
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
#   --com-herois        com --variacoes: os heróis raros também começam em campo
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
#                       (com --classe=<nome>, filma essa classe; senão o Samurai)
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
## --com-herois (com --variacoes): os 8 heróis raros entram na lista de partida
## (sonda de equilíbrio do Ciclo 2.23), espalhados pelos dois times.
var _com_herois := false
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
var _perf_censo := true
## --perf: microssegundos gastos por seção neste quadro (Unit soma aqui).
var perf_secoes := {}
var _testes := false  # --testes: roda tests/regras.gd e sai
var _prancha_rean_dir := ""  # --prancha-reanimar=DIR: fotos da reanimação (prancha)
var _qa_dir := ""
var _shot_times: Array[float] = [4.0, 15.0, 30.0, 50.0, 75.0]

## Painel da escolha do caminho: só abre (e fica aberto) sem inimigo a esta distância.
const ESCOLHA_BRIGA_R := 9.0
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
		elif arg == "--com-herois":
			_com_herois = true
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
		elif arg == "--placar":
			placar_print = true  # prints: placar (Tab) sempre aberto
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
		elif arg.begins_with("--prancha-reanimar="):
			_prancha_rean_dir = arg.trim_prefix("--prancha-reanimar=")
			sandbox_pedido = true
			_autoplay = true
			Settings.auto_quality = false
			Settings.quality = 2
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
		# Um bairro por classe do pátio (Ciclo 2.21): barraquinha da classe base,
		# tapetes dos dois caminhos e a casa que vira um deles. Classe sem
		# caminhos fica só com a maquininha.
		var hats := Config.cfg.hat_classes()
		for i in hats.size():
			var pos: Vector3 = arena.hat_spots[team][i]
			if hats[i].caminhos.size() >= 2:
				var of := Oficina.new()
				add_child(of)
				of.setup(self, team, pos, hats[i])
				oficinas.append(of)
			else:
				var pad := HatPad.new()
				add_child(pad)
				pad.setup(team, hats[i], pos)
				hat_pads.append(pad)
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
		start_classes = cfg.todas_classes()
		if _com_herois:
			for b in cfg.hat_classes():
				for h in b.herois:
					if h not in start_classes:
						start_classes.append(h)
	placar = Placar.new(cfg)
	reanimar = Reanimar.new(self)
	for team in 2:
		for i in cfg.units_per_team:
			var is_player := team == time_jogador and i == 0
			if sandbox and not is_player:
				continue  # modo teste: sem bots
			var u := Unit.new()
			u.name = "%s_%d" % [Config.TEAM_NAMES[team], i]
			add_child(u)
			var k := i + _variacoes_giro
			if _com_herois:  # 20 classes, 8 por time: cada partida pega outra fatia
				k = i + _variacoes_giro * cfg.units_per_team + team * 4
			var cls: ClassStats = cfg.villager if is_player else start_classes[k % start_classes.size()]
			if is_player and _classe_jogador != "":
				cls = load("res://config/classes/%s.tres" % _classe_jogador)
			u.setup(self, team, is_player, cls)
			u.global_position = arena.random_spawn(team, units)
			u.reset_physics_interpolation()
			u.died.connect(_on_unit_died)
			placar.registrar(u, team, i, is_player)
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
	placar_tela = PlacarTela.new()
	add_child(placar_tela)
	placar_tela.setup(self)
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
	if _prancha_rean_dir != "":
		_prancha_reanimar.call_deferred()
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


## Modo teste: todas as casas do time do jogador prontas (no primeiro
## caminho; [F] sobe o nível e, no máximo, troca o caminho) e as
## barraquinhas no nível 2.
func _montar_sandbox() -> void:
	_montando_sandbox = true
	# Ciclo 2.22: casas do zero (barraquinhas no Nv1, madeira infinita, obra
	# sandbox_obra_mult × mais rápida); a escolha do caminho vale (F5 = outra).
	# Torretas dos dois lados de pé: a inimiga serve de treino de escudo.
	for t in torretas:
		t.concluir_ja()
	_montando_sandbox = false
	_aliado_de_treino()


## Modo teste: um aliado sem cérebro, caído na frente do portão, para treinar
## a reanimação (Reanimar.treino: não renasce sozinho e cai de novo 4 s
## depois de levantar).
func _aliado_de_treino() -> void:
	var u := Unit.new()
	u.name = "%s_treino" % Config.TEAM_NAMES[time_jogador]
	add_child(u)
	u.setup(self, time_jogador, false, load("res://config/classes/guerreiro.tres"))
	u.global_position = arena.gate_spot[time_jogador] + arena.forward(time_jogador) * 13.0
	u.reset_physics_interpolation()
	u.died.connect(_on_unit_died)
	placar.registrar(u, time_jogador, 1, false)
	units.append(u)
	reanimar.treino(u)


func _on_started() -> void:
	if sandbox:
		hud.show_big("MODO TESTE\nMadeira infinita: pegue o chapéu de Construtor e erga as casas do zero.\nQ, E, R e catapulta recarregam rápido. F5 recomeça (para a outra escolha).", Color(1, 0.9, 0.5), 5.0)
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
		if _perf_censo:
			_perf_censo = false
			_censo()
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


## --perf: uma vez, conta o que a cena desenha, agrupado pelo dono (classe do
## script do ancestral mais próximo com script): instâncias, superfícies,
## passes (next_pass) e quem projeta sombra. Serve para achar quem come as
## chamadas de desenho.
func _censo() -> void:
	var grupos := {}
	var fila: Array[Node] = [get_tree().root]
	while not fila.is_empty():
		var n: Node = fila.pop_back()
		fila.append_array(n.get_children())
		var gi := n as GeometryInstance3D
		if gi == null or not gi.is_visible_in_tree():
			continue
		var dono := n
		while dono and dono.get_script() == null:
			dono = dono.get_parent()
		var nome := "?"
		if dono:
			var scr: Script = dono.get_script()
			nome = scr.get_global_name() if scr.get_global_name() != "" else scr.resource_path.get_file()
		nome += "/" + n.get_class()
		var surfs := 1
		var passes := 0
		var mats: Array[Material] = []
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi := n as MeshInstance3D
			surfs = mi.mesh.get_surface_count()
			for si in surfs:
				mats.append(mi.get_active_material(si))
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
			var mm := (n as MultiMeshInstance3D).multimesh
			surfs = mm.mesh.get_surface_count()
			for si in surfs:
				mats.append(gi.material_override if gi.material_override else mm.mesh.surface_get_material(si))
		else:
			mats.append(gi.material_override)
		for m in mats:
			var mm: Material = gi.material_override if gi.material_override else m
			var k := 1
			while mm and mm.next_pass:
				k += 1
				mm = mm.next_pass
			passes += k
		var tris := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			tris = _tris_da_malha((n as MeshInstance3D).mesh)
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
			var mmx := (n as MultiMeshInstance3D).multimesh
			tris = _tris_da_malha(mmx.mesh) * (mmx.visible_instance_count if mmx.visible_instance_count >= 0 else mmx.instance_count)
		if nome.get_slice("/", 0) in OS.get_environment("CENSO_DETALHE").split(","):
			print("CENSO.  %-50s surf=%d passes=%d tris=%d sombra=%s" % [String(n.get_path()).right(60), surfs, passes, tris,
					gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
		var g: Dictionary = grupos.get(nome, {"inst": 0, "surf": 0, "passes": 0, "sombra": 0, "tris": 0})
		g.inst += 1
		g.surf += surfs
		g.passes += passes
		g.tris += tris * maxi(passes / maxi(surfs, 1), 1)
		g.sombra += surfs if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		grupos[nome] = g
	var chaves := grupos.keys()
	chaves.sort_custom(func(a, b): return grupos[a].passes > grupos[b].passes)
	print("CENSO (visíveis): dono/tipo  instâncias  superfícies  passes(=chamadas)  superfícies com sombra  mil tris×passes")
	for k in chaves:
		var g: Dictionary = grupos[k]
		print("CENSO %-44s %5d %5d %5d %5d %7.1f" % [k, g.inst, g.surf, g.passes, g.sombra, g.tris / 1000.0])


func _tris_da_malha(me: Mesh) -> int:
	var tris := 0
	for si in me.get_surface_count():
		var arr := me.surface_get_arrays(si)
		var idx = arr[Mesh.ARRAY_INDEX]
		tris += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return tris


## Começo calmo (inicio_calmo s): bots ficam na própria metade.
func inicio_calmo() -> bool:
	return _time < Config.cfg.inicio_calmo


## Zonas que vão levar um golpe (marca do Mergulho, Ciclo 2.23): os bots do
## outro time leem e às vezes saem (BotBrain._esquiva_projetil).
var perigos: Array = []

func perigo(pos: Vector3, raio: float, dur: float, time: int) -> void:
	var i := perigos.size() - 1
	while i >= 0:
		if perigos[i].ate < _time:
			perigos.remove_at(i)
		i -= 1
	perigos.append({"pos": pos, "raio": raio, "ate": _time + dur, "time": time, "visto": {}})


func _physics_process(delta: float) -> void:
	_time += delta
	if _perf:
		for k in perf_secoes:
			_perf_acc["us_" + k] = _perf_acc.get("us_" + k, 0.0) + perf_secoes[k]
			perf_secoes[k] = 0
	if not game_over:
		tempo_partida += delta  # relógio do placar: para no fim da partida
		_relogio(delta)
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
	if _autoplay and int(_time / 30.0) != int((_time - delta) / 30.0):
		_status_economia()
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
		_lod_bonecos()
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
	if _perf:
		var t0 := Time.get_ticks_usec()
		_rules()
		perf_secoes["regras"] = perf_secoes.get("regras", 0) + Time.get_ticks_usec() - t0
	else:
		_rules()
	reanimar.tick(delta)
	# O HUD não precisa de 60 atualizações por segundo: 20 Hz bastam ao olho
	# e cada atualização mexe em vários textos e barras.
	_hud_t -= delta
	if _hud_t <= 0.0:
		_hud_t = 0.05
		hud.update_state(self)
		minimapa.alvo_guia = guia.alvo


## --prancha-reanimar=DIR (modo teste, xvfb): o jogador sem cérebro reanima o
## aliado de treino num roteiro fixo e cada momento vira um JPG em DIR:
## caído esperando, arrastando, Kitsune abençoando, levantando, câmera do jogo.
func _prancha_reanimar() -> void:
	DirAccess.make_dir_recursive_absolute(_prancha_rean_dir)
	var c := reanimar.boneco_treino
	var p := player
	p.brain = null
	p.move_intent = Vector3.ZERO
	p.wants_attack = false
	p.wants_block = false
	var off0: Vector3 = Config.cfg.camera_offset
	Config.cfg.camera_offset = off0 * 0.42
	p.set_class(load("res://config/classes/guerreiro.tres"))
	p.global_position = c.global_position + Vector3(-1.3, 0, 0.5)
	p.reset_physics_interpolation()
	p.aim_dir = Vector3(1, 0, 0)
	camera.snap()
	var foto := func(nome: String) -> void:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("%s/%s.jpg" % [_prancha_rean_dir, nome], 0.88)
	await get_tree().create_timer(2.2).timeout
	await foto.call("1-caido-esperando")
	p.wants_reanimar = true
	await get_tree().create_timer(0.2).timeout
	p.move_intent = Vector3(-1, 0, -0.3).normalized()
	await get_tree().create_timer(1.2).timeout
	await foto.call("2-arrastando")
	await get_tree().create_timer(1.25).timeout
	p.move_intent = Vector3.ZERO
	var limite := 0
	while not c.alive and limite < 400:
		limite += 1
		await get_tree().physics_frame
	p.wants_reanimar = false
	await get_tree().create_timer(0.3).timeout
	await foto.call("4-levantando")
	limite = 0
	while c.alive and limite < 400:
		limite += 1
		await get_tree().physics_frame
	p.set_class(load("res://config/classes/kitsune_luz.tres"))
	p.global_position = c.global_position + Vector3(-1.2, 0, 0.6)
	p.reset_physics_interpolation()
	await get_tree().create_timer(1.2).timeout
	p.wants_reanimar = true
	await get_tree().create_timer(1.0).timeout
	await foto.call("3-kitsune-abencoando")
	Config.cfg.camera_offset = off0
	camera.snap()
	await get_tree().create_timer(0.25).timeout
	await foto.call("5-camera-do-jogo")
	get_tree().quit()


## Partida simulada: a cada 30 s, o ciclo da madeira de cada time (para
## acertar o ritmo das casas: tools/sonda_equilibrio.sh e o CHANGELOG).
func _status_economia() -> void:
	for team in 2:
		var lenh := 0
		var vivos := 0
		for u in units:
			if u.team == team and u.lenhador():
				lenh += 1
				vivos += 1 if u.alive else 0
		var adultas := 0
		for p in plantas:
			if p.adulta() and p.lado == team:
				adultas += 1
		var casas := PackedStringArray()
		for of in oficinas:
			if of.team == team:
				casas.append("%s%s" % [of.opcao().id if of.caminho >= 0 else of.base.id, ":%d" % of.nivel if of.estado == Oficina.Estado.PRONTA else ("~%d%%" % int(of.progresso * 100) if of.caminho >= 0 else "")])
		_log("status %s t=%.0fs madeira=%d construtores=%d/%d adultas=%d casas=[%s]" % [Config.TEAM_NAMES[team], _time, madeira[team], vivos, lenh, adultas, ", ".join(casas)])


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
		p.set_class(load("res://config/classes/%s.tres" % (_classe_jogador if _classe_jogador != "" else "guerreiro")))
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
	# VITRINE_LONGE=1: a câmera da partida (confere tamanho e leitura de longe).
	camera.global_position = foco + (Config.cfg.camera_offset if OS.get_environment("VITRINE_LONGE") != "" else Vector3(0, 6.2, 8.0))
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
		var wants_interact := u.is_player and player_brain != null and player_brain.interact_pressed \
				and not reanimar.segura_f(u)

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
				placar.somar(u, "roubos")
				u.has_cake = false
				continue

		# Devolver a própria princesa caída: ficar ao lado dela por um tempo,
		# sem inimigo perto (disputa: aí o resgate para).
		if own_p.state == Princess.State.DROPPED and pos.distance_to(own_p.global_position) < 2.5 \
				and not _contested(own_p):
			own_p.rescue(get_physics_process_delta_time())
			if own_p.state == Princess.State.HOME:
				placar.somar(u, "resgates")

		# Alimentar a própria princesa.
		if u.has_cake and own_p.state == Princess.State.HOME and pos.distance_to(own_p.global_position) < 4.0:
			if own_p.feed():
				u.has_cake = false
				placar.somar(u, "almas")
				u.add_power(Config.cfg.power_per_cake)
				u.add_super(Config.cfg.super_por_espirito)
				if u.is_player:
					hud.show_big("Espírito preso! Máscara mais pesada", Color(1, 0.6, 0.8), 1.2)

		# Pegar bolo (bots atacantes ignoram bolo para não se distraírem).
		var bot := u.brain as BotBrain
		var takes_cake := bot == null \
				or (bot.role != BotBrain.Role.ATTACK and own_p.fatness < 1.0)
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
		# A barraquinha e a casa do bairro ficam perto: vale a mais próxima.
		var pad: HatPad = null
		var pad_d := INF
		if not u.is_equipping():
			for pd in hat_pads:
				if pd.team != u.team or not pd.available or pd.stats == u.stats or heroi_reservado(pd, u):
					continue
				var d := pos.distance_to(pd.global_position)
				if d < pd.raio_pegar and d < pad_d:
					pad_d = d
					pad = pd
		if pad:
			if u.is_player:
				hint = "[F] pegar o chapéu de %s" % pad.stats.display_name
			# Jogador: só com F. Bots recrutas (e o jogador no modo teste) pegam sozinhos.
			var bot_pega := u.brain is BotBrain and u.is_villager() and not (pad.stats.velocidade_obra > 0.0 \
					and _bots_lenhadores(u.team, u) >= Config.cfg.bots_construtores_max)
			if wants_interact or bot_pega:
				var from: Vector3 = pad.hat_world_position()
				var cls := pad.take()
				u.start_equip(cls, from)
				if pad.raro:
					on_heroi_vestido(u, cls)

	if sandbox:
		hint = _regras_sandbox(hint)
	_vigiar_escolha()

	# Bairro da classe: tapetes (escolha do caminho), obra e níveis da casa.
	if player.alive and not player.carried_princess and hint == "":
		hint = _dica_casa()

	# Construtor perto de uma maquininha nível 1: ela sobe com madeira.
	if player.alive and hint == "" and player.lenhador() and not player.carried_tora:
		for pad in hat_pads:
			if pad.team == player.team and pad.nivel == 1 and pad.aceita_madeira and player.global_position.distance_to(pad.global_position) < HatPad.OBRA_RAIO:
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
				hint = "Tem madeira no depósito: siga a seta e construa (casa ou torreta)"

	if player.alive and player.reanimando == null and not player.carried_princess and player.carried_tora == null:
		var caido := reanimar.corpo_perto(player, Config.cfg.reanimar_raio)
		if caido:
			hint = "[F] segure para reanimar %s%s" % [caido.stats.display_name,
					"" if player.eh_mago() else "  ·  ande para arrastar"]
	if player.alive and player.carried_princess:
		hint = "Leve-a até o SEU castelo!  ([F] soltar)"
	elif player.has_cake:
		hint = "Leve o espírito até a sua máscara"
	hud.set_hint(hint)


## Tempo de renascer agora: cresce com o tempo de partida (respawn_cresce s
## por minuto, até respawn_max) para a morte pesar mais no fim de jogo.
func respawn_atual() -> float:
	if sandbox:
		return Config.cfg.respawn_time
	return minf(Config.cfg.respawn_time + Config.cfg.respawn_cresce * _time / 60.0,
			Config.cfg.respawn_max)


## Modo teste: maquininhas repõem o chapéu em 1 s (as casas sobem pela
## escada normal, com madeira infinita: Game.gastar_madeira).
func _regras_sandbox(hint: String) -> String:
	for pad in hat_pads:
		pad.intervalo = minf(pad.intervalo, 1.0)
	# Morte súbita sob demanda (Ciclo 2.25): o modo teste não tem relógio.
	if morte_subita < 0.0 and not game_over:
		if Input.is_action_just_pressed("teste_morte_subita"):
			abrir_morte_subita()
		elif hint == "" and player and player.alive:
			for p in princesses:
				if player.global_position.distance_to(p.home) < 9.0:
					hint = "Modo teste: [M] chama a morte súbita"
	return hint


## Obra e entrega de madeira das casas: mais rápidas no modo teste.
func mult_obra() -> float:
	return Config.cfg.sandbox_obra_mult if sandbox else 1.0


## Inimigo vivo a menos de r m de u (painel da escolha só fora da briga).
func inimigo_perto(u: Unit, r: float) -> bool:
	for o in units:
		if o.alive and o.team != u.team and o.global_position.distance_to(u.global_position) < r:
			return true
	return false


## Dica do bairro onde o jogador está (e o [F] que abre o painel da escolha).
func _dica_casa() -> String:
	var pos := player.global_position
	var construtor := player.lenhador()
	var precisa := "fique aqui para construir" if construtor else "precisa de um Construtor"
	var aperta := player_brain != null and player_brain.interact_pressed
	var aberta := hud.escolha_aberta() if hud else null
	for of in oficinas:
		if of.team != player.team or pos.distance_to(of.global_position) > Oficina.RAIO + 0.5:
			continue
		var cs := of.caminhos()
		match of.estado:
			Oficina.Estado.VAZIO:
				if of.nivel < 2:
					if not construtor:
						return "Barraquinha de %s no nível 1 (Super travado)  ·  um Construtor sobe ao 2" % of.base.display_name
					return "Suba a barraquinha de %s ao nível 2: faltam %d madeiras  ·  fique no bairro" % [of.base.display_name, of.faltam_nivel()]
				if cs.size() < 2:
					return ""
				if not construtor:
					return "%s no nível 2: um Construtor escolhe %s ou %s" % [of.base.display_name, cs[0].display_name, cs[1].display_name]
				if aberta == of:
					if aperta:
						hud.fechar_escolha()
					return ""
				if aperta:
					if inimigo_perto(player, ESCOLHA_BRIGA_R):
						hud.show_big("Saia da briga para escolher o caminho", Color(1, 0.6, 0.55), 1.4)
					elif madeira[player.team] <= 0:
						hud.show_big("Falta madeira no depósito para começar a casa", Color(1, 0.6, 0.55), 1.4)
					else:
						hud.abrir_escolha(of, _confirmar_escolha.bind(of))
						return ""
				if not _caminho_avisado and hud:
					_caminho_avisado = true
					hud.show_big("Nível 3 da casa de %s: escolha o caminho\n%s ou %s  ·  o outro fica selado até o fim" % [of.base.display_name, cs[0].display_name, cs[1].display_name],
						of.base.hat_color.lightened(0.35), 3.2)
				return "[F] escolher o caminho: %s ou %s" % [cs[0].display_name, cs[1].display_name]
			Oficina.Estado.OBRA:
				var falta := "  ·  faltam %d madeiras" % of.faltam() if of.faltam() > 0 else ""
				return "Casa de %s: %d%%%s  ·  %s" % [of.opcao().display_name, int(of.progresso * 100.0), falta, precisa]
			Oficina.Estado.PRONTA:
				if of.pede_heroi():
					var hs := " ou ".join(of.herois().map(func(c): return c.display_name))
					if not construtor:
						return "★ Nível 6: um Construtor escolhe o herói raro (%s)" % hs
					if aberta == of:
						if aperta:
							hud.fechar_escolha()
						return ""
					if aperta:
						if inimigo_perto(player, ESCOLHA_BRIGA_R):
							hud.show_big("Saia da briga para escolher o herói", Color(1, 0.6, 0.55), 1.4)
						elif not gastar_madeira_possivel(player.team, 1):
							hud.show_big("Falta madeira no depósito para começar o pavilhão", Color(1, 0.6, 0.55), 1.4)
						else:
							hud.abrir_escolha(of, _confirmar_heroi.bind(of), true)
							return ""
					return "[F] ★ escolher o herói raro do nível 6: %s  ·  %d madeiras" % [hs, Config.cfg.heroi_custo]
				if not construtor:
					return ""
				if of.heroi >= 0 and not of.heroi_pronto:
					return "Pavilhão de %s: faltam %d madeiras  ·  fique no bairro" % [of.heroi_cls().display_name, of.faltam_nivel()]
				if of.pode_subir():
					return "Nível %d de %s e %s: faltam %d madeiras  ·  fique no bairro" % [of.nivel + 1, of.base.display_name, of.opcao().display_name, of.faltam_nivel()]
				if of.heroi_pronto:
					return "%s, %s e ★ %s: bairro completo (Nv6)" % [of.base.display_name, of.opcao().display_name, of.heroi_cls().display_name]
				return "%s e %s no nível máximo (%d)" % [of.base.display_name, of.opcao().display_name, of.nivel]
	return ""


## Painel da escolha: o jogador clicou num caminho.
func _confirmar_escolha(i: int, of: Oficina) -> void:
	if not is_instance_valid(of) or not of.pede_escolha():
		return
	if not of.escolher(i):
		hud.show_big("Falta madeira no depósito para começar a casa", Color(1, 0.6, 0.55), 1.4)


## Painel dos heróis (Nv6): o jogador clicou num herói.
func _confirmar_heroi(i: int, of: Oficina) -> void:
	if not is_instance_valid(of) or not of.pede_heroi():
		return
	if not of.escolher_heroi(i):
		hud.show_big("Falta madeira no depósito para começar o pavilhão", Color(1, 0.6, 0.55), 1.4)


func gastar_madeira_possivel(team: int, n: int) -> bool:
	return sandbox or madeira[team] >= n


## O painel da escolha fecha sozinho se o jogador sai do bairro, entra na
## briga, cai, ou se um bot do time escolheu antes.
func _vigiar_escolha() -> void:
	var of := hud.escolha_aberta() if hud else null
	if of == null:
		return
	if not player.alive or not (of.pede_escolha() or of.pede_heroi()) or player.global_position.distance_to(of.global_position) > Oficina.RAIO + 1.5 \
			or inimigo_perto(player, ESCOLHA_BRIGA_R):
		hud.fechar_escolha()


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
	placar.somar(u, "capturas")
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
	if score[u.team] >= Config.cfg.score_to_win or morte_subita >= 0.0:
		encerrar(u.team)


## Fim da partida: time vencedor (0/1) ou -1 = empate. O placar de todos
## abre com Vitória/Derrota/Empate em cima e os bonecos param.
func encerrar(time_vencedor: int) -> void:
	if game_over:
		return
	game_over = true
	vencedor = time_vencedor
	_slowmo_id += 1
	Engine.time_scale = 1.0
	_log("fim: %s (%d x %d, t=%.0fs)" % ["empate" if time_vencedor < 0 else Config.TEAM_NAMES[time_vencedor], score[0], score[1], tempo_partida])
	if hud and player:
		hud.update_state(self)
	var mine := player != null and time_vencedor == player.team
	if placar_tela:
		placar_tela.fim(mine, time_vencedor < 0)
	Sfx.play_ui("score" if time_vencedor < 0 else ("win" if mine else "lose"))
	for other in units:
		if other.alive and other.team == time_vencedor:
			other.play_cheer()
		other.move_intent = Vector3.ZERO
		other.set_physics_process(false)


## Segundos que faltam no relógio (INF = partida sem relógio).
func tempo_restante() -> float:
	if not relogio_ligado():
		return INF
	return maxf(Config.cfg.tempo_limite - tempo_partida, 0.0)


func relogio_ligado() -> bool:
	return Config.cfg.tempo_limite > 0.0 and not sandbox and _vitrine_dir == "" and _clipe_dir == "" and _filme_dir == ""


func _mascara_em_maos() -> bool:
	for p in princesses:
		if p.state == Princess.State.CARRIED:
			return true
	return false


## Alguma máscara fora do pedestal (na mão ou caída esperando voltar)?
func _mascara_fora() -> bool:
	for p in princesses:
		if p.state != Princess.State.HOME:
			return true
	return false


func _mascara_caida() -> bool:
	for p in princesses:
		if p.state == Princess.State.DROPPED:
			return true
	return false


## Relógio (Ciclo 2.23, 15 min no 2.24): tique nos últimos 10 s; no zero,
## prorrogação enquanto alguma máscara estiver fora do castelo, senão o placar decide.
## Ciclo 2.25: placar igual abre a morte súbita em vez do empate.
func _relogio(delta: float) -> void:
	if morte_subita >= 0.0:  # antes do relogio_ligado: o modo teste a chama com [M]
		_relogio_morte_subita(delta)
		return
	if not relogio_ligado():
		return
	var resta := Config.cfg.tempo_limite - tempo_partida
	if resta > 0.0:
		_tique(resta)
		return
	if prorrogacao < 0.0:
		if _mascara_fora():
			prorrogacao = 0.0
			_log("prorrogacao (t=%.0fs)" % tempo_partida)
			if hud:
				hud.show_big("PRORROGAÇÃO!\nUma máscara está fora do castelo", Estilo.OURO, 2.6)
			Sfx.play_ui("alarm")
			return
		_fim_por_tempo()
		return
	prorrogacao += delta
	# Caída: espera voltar sozinha (é curto). Na mão: até prorrogacao_max.
	if not _mascara_fora() or (prorrogacao >= Config.cfg.prorrogacao_max and not _mascara_caida()):
		_fim_por_tempo()


func _tique(resta: float) -> void:
	var s := int(ceil(resta))
	if s <= 10 and s != _tique_s:
		_tique_s = s
		Sfx.play_ui("tinido")


func _fim_por_tempo() -> void:
	if score[0] != score[1]:
		if hud:
			hud.show_big("TEMPO!", Estilo.OURO, 2.4)
		encerrar(0 if score[0] > score[1] else 1)
	elif morte_subita < 0.0 and Config.cfg.morte_subita_tempo > 0.0:
		abrir_morte_subita()
	else:
		_fim_no_placar()


## Morte súbita (Ciclo 2.25): máscaras leves, o primeiro ponto vence
## (_score_point). Quem está com a máscara na mão segue com ela.
func abrir_morte_subita() -> void:
	if morte_subita >= 0.0 or game_over:
		return
	morte_subita = 0.0
	prorrogacao = -1.0
	_tique_s = -1
	for p in princesses:
		p.zerar_peso()
	_log("morte subita (t=%.0fs)" % tempo_partida)
	if hud:
		hud.show_big("MORTE SÚBITA!\nO primeiro ponto vence", Estilo.PERIGO, 3.2)
	Sfx.play_ui("alarm")
	Sfx.musica_tensa(true)
	if camera:
		camera.add_trauma(0.35)


## Segundos que faltam na morte súbita (INF = não está nela).
func morte_subita_resta() -> float:
	if morte_subita < 0.0:
		return INF
	return maxf(Config.cfg.morte_subita_tempo - morte_subita, 0.0)


## No zero da morte súbita vale a mesma espera da prorrogação: máscara fora do
## castelo segura o fim (na mão, até prorrogacao_max; caída, até voltar).
func _relogio_morte_subita(delta: float) -> void:
	morte_subita += delta
	var resta := Config.cfg.morte_subita_tempo - morte_subita
	if resta > 0.0:
		_tique(resta)
		return
	if _mascara_fora() and (-resta < Config.cfg.prorrogacao_max or _mascara_caida()):
		return
	_fim_no_placar()


## Ninguém pontuou nem na morte súbita: vence o time com mais pontos no placar
## do Tab (abates, obras, roubos...). Igual até nisso = empate.
func _fim_no_placar() -> void:
	var a := placar.total(0)
	var b := placar.total(1)
	var v := -1 if a == b else (0 if a > b else 1)
	decidido_no_placar = v >= 0
	_log("desempate no placar: %d x %d" % [a, b])
	if hud:
		hud.show_big("TEMPO! EMPATE" if v < 0 else "TEMPO!\n%s vence nos pontos" % Config.TEAM_NAMES[v], Estilo.OURO, 2.6)
	encerrar(v)


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
	placar.somar(u, "madeira")
	pilhas[u.team].atualizar(madeira[u.team])
	_log("madeira %s = %d (t=%.0fs)" % [Config.TEAM_NAMES[u.team], madeira[u.team], _time])
	Sfx.play("pickup", u.global_position, 0.05)
	Fx.burst(self, pilhas[u.team].global_position + Vector3(0, 1.0, 0), Color(0.9, 0.7, 0.4), 8, 3.0)
	if u.is_player:
		hud.show_big("+1 madeira  ·  depósito: %d" % madeira[u.team], Color(1, 0.8, 0.5), 0.9)


## Tira n do estoque do time. Sem estoque suficiente, não tira nada.
func gastar_madeira(team: int, n: int) -> bool:
	if sandbox:
		return true  # modo teste: madeira infinita
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
				placar.somar(u, "madeira")
				return ""
		return "Siga a seta: entregue a tora no DEPÓSITO do seu castelo (ícone de tora)"
	var t := nearest_tora_solta(pos, 1.6)
	if t and not u.is_equipping():
		t.pegar(u)
	return ""


# --- Consultas usadas pelos bots ----------------------------------------------

## Casa do time mais perto (só as em obra, se unbuilt_only: o Mutirão).
func nearest_oficina(team: int, from: Vector3, max_dist: float, unbuilt_only: bool) -> Oficina:
	var best: Oficina = null
	var best_d := max_dist
	for of in oficinas:
		if of.team != team or (unbuilt_only and of.estado != Oficina.Estado.OBRA):
			continue
		var d := from.distance_to(of.global_position)
		if d < best_d:
			best_d = d
			best = of
	return best


## Casa que o Construtor deve tocar: a obra mais adiantada do time (todos
## continuam de onde os outros pararam, sem espalhar madeira); sem obra, o
## bairro ainda sem caminho mais perto (o bot vai ao tapete e escolhe).
## com_foco (bots, Ciclo 2.23): com o bairro-foco já no Nv2+, os outros bairros
## esperam a escolha do caminho até o herói do foco sair.
func obra_do_time(team: int, from: Vector3, com_foco := false) -> Oficina:
	var best: Oficina = null
	var best_v := 0.0
	var vazio: Oficina = null
	var vazio_d := INF
	for of in oficinas:
		if of.team != team:
			continue
		if of.estado == Oficina.Estado.OBRA:
			var v := of.progresso + float(of.madeira_entregue) / maxf(of.custo(), 1)
			if best == null or v > best_v:
				best_v = v
				best = of
		elif of.pede_escolha():
			# Ciclo 2.23: bots levam o bairro-foco até o herói antes de abrir
			# os outros caminhos.
			var foco := foco_heroi(team) if com_foco else null
			if foco != null and foco != of and foco.nivel >= 2:
				continue
			var d := from.distance_to(of.global_position)
			if d < vazio_d:
				vazio_d = d
				vazio = of
	return best if best else vazio


## Terreno de torreta do time para o Construtor: a obra começada, senão o
## terreno vazio mais perto. null = todas de pé.
## Ciclo 2.12d: com uma torreta do time já de pé e o mago podendo subir de nível,
## terreno vazio espera (a madeira vai para o mago antes de reerguer a outra).
func torreta_para_obra(team: int, from: Vector3) -> Torreta:
	var best: Torreta = null
	var espera := mago_para_subir(team, Vector3.INF, false, false) != null and torretas_de_pe(team) >= 1
	for t in torretas:
		if t.team != team or t.pronta() or (espera and t.madeira_entregue == 0):
			continue
		if best == null or t.madeira_entregue > best.madeira_entregue or (t.madeira_entregue == best.madeira_entregue \
				and from.distance_to(t.global_position) < from.distance_to(best.global_position)):
			best = t
	return best


func torretas_de_pe(team: int) -> int:
	var n := 0
	for t in torretas:
		if t.team == team and t.pronta():
			n += 1
	return n


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
## tem mais madeira posta, depois a mais perto. (Só as soltas: as barraquinhas
## dos bairros sobem junto com a casa.)
func maquina_para_n2(team: int, from: Vector3) -> HatPad:
	var best: HatPad = null
	for pad in hat_pads:
		if pad.team != team or pad.nivel >= 2 or not pad.aceita_madeira:
			continue
		if best == null or pad.madeira_n2 > best.madeira_n2 or (pad.madeira_n2 == best.madeira_n2 \
				and from.distance_to(pad.global_position) < from.distance_to(best.global_position)):
			best = pad
	return best


## Bairro do time com a barraquinha ainda no nível 1 (o que tem mais madeira
## posta, depois o mais perto). null = todas no 2 ou acima.
func barraca_nv1(team: int, from: Vector3) -> Oficina:
	var best: Oficina = null
	for of in oficinas:
		if of.team != team or of.estado != Oficina.Estado.VAZIO or of.nivel >= 2:
			continue
		if best == null or of.madeira_nivel > best.madeira_nivel or (of.madeira_nivel == best.madeira_nivel \
				and from.distance_to(of.global_position) < from.distance_to(best.global_position)):
			best = of
	return best


## Casa pronta abaixo do nível máximo para o Construtor subir: a que já tem
## mais madeira posta, depois a de nível mais alto (o time foca numa casa até
## o máximo, ~8 min de partida), depois a mais perto.
func mago_para_subir(team: int, from := Vector3.INF, com_foco := false, com_heroi := true) -> Oficina:
	var best: Oficina = null
	var best_k := -INF
	var foco := foco_heroi(team) if com_foco else null
	for of in oficinas:
		if of.team != team or not (of.pode_subir() or (com_heroi and of.pede_heroi())):
			continue
		# Ciclo 2.22: madeira já posta primeiro; depois as barraquinhas no Nv1
		# (abrem o bairro e liberam o R); depois a casa mais alta (o time foca
		# numa até o 5); a mais perto desempata.
		var k := 1000.0 * of.madeira_nivel + (500.0 if of.nivel < 2 else 10.0 * of.nivel)
		if of == foco and of.nivel >= 2:
			k += 300.0  # Ciclo 2.23: o bairro-foco sobe até o herói primeiro
		if from != Vector3.INF:
			k -= from.distance_to(of.global_position) * 0.01
		if best == null or k > best_k:
			best_k = k
			best = of
	return best


## Ciclo 2.23: bairro que os BOTS levam primeiro até o herói (sorteado por
## time na 1ª consulta, entre os que têm herois). null = sem foco / já pronto.
var _foco_heroi: Array = [null, null]
var _foco_sorteado := [false, false]


func foco_heroi(team: int) -> Oficina:
	if not _foco_sorteado[team]:
		_foco_sorteado[team] = true
		var cands: Array = []
		for of in oficinas:
			if of.team == team and not of.herois().is_empty():
				cands.append(of)
		if not cands.is_empty():
			_foco_heroi[team] = cands[randi() % cands.size()]
	var f: Oficina = _foco_heroi[team]
	if f == null or not is_instance_valid(f) or f.heroi_pronto:
		return null
	return f


## Herói escolhido no Nv5: aviso para os dois times.
func on_heroi_escolhido(of: Oficina) -> void:
	var h := of.heroi_cls()
	_log("heroi %s: %s -> %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.base.display_name, h.display_name, _time])
	if hud == null or player == null or _montando_sandbox:
		return
	if of.team == player.team:
		hud.show_big("★ Herói escolhido: %s!\nO pavilhão sobe com %d madeiras" % [h.display_name, Config.cfg.heroi_custo], Estilo.OURO_CLARO, 2.6)
	else:
		hud.show_big("O inimigo chamou o herói %s" % h.display_name, Color(1, 0.6, 0.55), 1.8)


func on_heroi_pronto(of: Oficina) -> void:
	var h := of.heroi_cls()
	_log("heroi pronto %s: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], h.display_name, _time])
	if hud == null or player == null or _montando_sandbox:
		return
	if of.team == player.team:
		hud.show_big("★ %s chegou ao pavilhão!\nUm chapéu só: quem pegar vira o herói" % h.display_name, Estilo.OURO_CLARO, 2.8)
	else:
		hud.show_big("O inimigo tem um herói: %s" % h.display_name, Color(1, 0.6, 0.55), 1.8)


## Nv5 com madeira para o herói: o quintal acende (aviso uma vez por bairro).
func on_heroi_disponivel(of: Oficina) -> void:
	if hud and player and of.team == player.team and not _montando_sandbox:
		hud.show_big("★ Herói raro disponível no bairro de %s\nUm Construtor sobe o nível 6" % of.base.display_name, Estilo.OURO_CLARO, 2.4)


## Alguém do time vestiu o herói (Game._rules, ao pegar o chapéu).
func on_heroi_vestido(u: Unit, cls: ClassStats) -> void:
	_log("heroi vestido %s: %s (t=%.0fs)" % [Config.TEAM_NAMES[u.team], cls.display_name, _time])
	if hud and player and u.team == player.team and not _montando_sandbox:
		var quem := "Você é" if u == player else "%s entrou na briga:" % ("Um aliado")
		hud.show_big("★ %s %s!" % [quem, cls.display_name], Estilo.OURO_CLARO, 2.0)


## Bots esperam o jogador pegar o chapéu do herói nos primeiros s no altar.
func heroi_reservado(pad: HatPad, quem: Unit) -> bool:
	return pad.raro and quem != null and not quem.is_player and player != null and player.team == pad.team \
			and not _autoplay and pad._livre_t < Config.cfg.heroi_espera_jogador


## Um Construtor escolheu o caminho de uma casa: aviso para os dois times.
func on_caminho_escolhido(of: Oficina) -> void:
	var cls := of.opcao()
	var outro: ClassStats = of.caminhos()[1 - of.caminho]
	_log("caminho %s: %s -> %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.base.display_name, cls.display_name, _time])
	if hud == null or player == null or _montando_sandbox:
		return
	if of.team == player.team:
		hud.show_big("Caminho escolhido: %s!\n%s fica selado até o fim" % [cls.display_name, outro.display_name],
			cls.hat_color.lightened(0.3), 2.6)
	elif Config.cfg.caminho_aviso_inimigo:
		hud.show_big("O inimigo escolheu %s (%s)" % [cls.display_name, of.base.display_name], Color(1, 0.6, 0.55), 1.8)


func on_mago_nivel(of: Oficina) -> void:
	for u in units:
		if u.team == of.team and u.stats and u.stats.classe_base == of.base.id:
			u.atualizar_nivel_visual()
	_log("casa %s nível %d: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.nivel, of.opcao().display_name if of.caminho >= 0 else of.base.display_name, _time])
	if hud and player and not _montando_sandbox:
		var nome := of.base.display_name if of.estado != Oficina.Estado.PRONTA else "%s e %s" % [of.base.display_name, of.opcao().display_name]
		if of.team == player.team:
			var extra := "\nSuper (R) liberado  ·  próximo: escolher o caminho" if of.nivel == 2 else ""
			if of.nivel == Config.cfg.mago_nivel_max and not of.herois().is_empty():
				extra = "\n★ Próximo: o herói raro do nível 6"
			hud.show_big("%s: nível %d/%d!%s" % [nome, of.nivel, Config.cfg.mago_nivel_max + (1 if not of.herois().is_empty() else 0), extra], of.cor_nivel(), 2.2)
		else:
			hud.show_big("O inimigo subiu %s para o nível %d" % [nome, of.nivel], Color(1, 0.6, 0.55), 1.6)


## Nível visual de um soldado dessa classe: o nível da casa do caminho (2 a
## mago_nivel_max; o máximo mostra tudo, 5 caudas na Kitsune). Classe evoluída
## sem casa pronta = 2; classe do pátio = 1.
func nivel_visual_mago(team: int, id: StringName) -> int:
	var evoluida := false
	for of in oficinas:
		if of.team != team:
			continue
		if of.heroi_pronto and of.heroi_cls().id == id:
			return 5
		if of.estado == Oficina.Estado.PRONTA and of.opcao().id == id:
			return 5 if of.nivel >= Config.cfg.mago_nivel_max else of.nivel
		for c in of.caminhos():
			if c.id == id:
				evoluida = true
	return 2 if evoluida else 1


## Níveis acima do 2 do bairro dessa classe (0 = sem bônus). Ciclo 2.22:
## vale para a classe base (barraquinha) e para a do caminho (casa).
func bonus_mago(team: int, id: StringName) -> int:
	if id == &"":
		return 0
	for of in oficinas:
		if of.team != team:
			continue
		if of.heroi_pronto and of.heroi_cls().id == id:
			return Config.cfg.heroi_bonus_niveis
		if of.base.id == id or (of.estado == Oficina.Estado.PRONTA and of.opcao().id == id):
			return maxi(mini(of.nivel, Config.cfg.mago_nivel_max) - 2, 0)
	return 0


## Nível do bairro da classe (base ou caminho); 0 = classe sem casa no pátio.
func nivel_casa(team: int, id: StringName) -> int:
	for of in oficinas:
		if of.team != team:
			continue
		if of.heroi_pronto and of.heroi_cls().id == id:
			return of.nivel
		if of.base.id == id or (of.caminho >= 0 and of.opcao().id == id):
			return mini(of.nivel, Config.cfg.mago_nivel_max)
	return 0


## Super (R) travado: a casa da classe ainda abaixo de super_nivel_min (Ciclo
## 2.22). Fora de partida (vitrine, clipes, prints) nunca trava.
func super_travado(team: int, id: StringName) -> bool:
	if _vitrine_dir != "" or _clipe_dir != "" or _poderes:
		return false
	var n := nivel_casa(team, id)
	return n > 0 and n < Config.cfg.super_nivel_min


func on_oficina_pronta(of: Oficina) -> void:
	_log("casa %s pronta: %s (t=%.0fs)" % [Config.TEAM_NAMES[of.team], of.opcao().display_name, _time])
	for u in units:
		if u.team == of.team and u.stats and u.stats.id == of.opcao().id:
			u.atualizar_nivel_visual()
	if _montando_sandbox or hud == null or player == null:
		return
	if of.team == player.team:
		hud.show_big("Casa pronta: %s!\n%s e %s no nível 3" % [of.opcao().display_name, of.base.display_name, of.opcao().display_name], of.opcao().hat_color.lightened(0.3), 2.4)
	else:
		hud.show_big("O inimigo liberou %s" % of.opcao().display_name, Color(1, 0.6, 0.55), 1.6)


## Chapéu com estoque mais perto. Para bots (quem != null), o de Construtor
## só vale enquanto o time tem menos de bots_construtores_max bots lenhadores.
func nearest_free_hat(team: int, from: Vector3, quem: Unit = null) -> HatPad:
	var best: HatPad = null
	var best_d := INF
	var sem_lenhador := quem != null and _bots_lenhadores(team, quem) >= Config.cfg.bots_construtores_max
	for pad in hat_pads:
		if pad.team == team and pad.available and not (sem_lenhador and pad.stats.velocidade_obra > 0.0) and not heroi_reservado(pad, quem):
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
## LOD dos soldados (Ciclo 2.19): longe do jogador as peças 3D pequenas somem
## (Unit.set_pecas_longe). Histerese de 4 m para a fronteira não piscar.
func _lod_bonecos() -> void:
	if player == null:
		return
	var foco := player.global_position
	for u in units:
		var d := Vector2(u.global_position.x - foco.x, u.global_position.z - foco.z).length()
		u.set_pecas_longe(d > (16.0 if u.pecas_longe else 20.0))


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
	reanimar.ao_cair(u)
	if killer and killer.team != u.team:
		_alma_de_abate(u, killer.team)
	var assist := placar.abate(u, killer if killer and killer.team != u.team else null, _time)
	if player in assist:
		Fx.damage_number(self, player.global_position + Vector3(0, 0.6, 0), "ASSISTÊNCIA +%d" % int(Config.cfg.pts_assist), Color(0.6, 0.9, 1.0))
	if u == player:
		quedas_jogador += 1
	elif killer == player and u.team != player.team:
		abates_jogador += 1
	if u == player:
		hud.show_big("Você caiu!" if reanimar.pode_reanimar(u) else "Você caiu! Voltando como recruta...", Color(1, 0.6, 0.6), 1.8)
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
	_log("mascara %s -> %s [%d] (t=%.0fs, peso=%.2f)" % [Config.TEAM_NAMES[p.team], p.state_text(), p.state, _time, p.fatness])
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
