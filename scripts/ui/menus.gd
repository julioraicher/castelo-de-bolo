class_name Menus
extends CanvasLayer
## Menu do jogo: uma placa só, com navegação à esquerda e o conteúdo à
## direita, como um menu de jogo de verdade. As mesmas seções servem na tela
## inicial (Jogar, Como jogar, Classes, Controles, Configurações) e na pausa
## (Continuar e Reiniciar no lugar de Jogar). Roda com o jogo pausado
## (process_mode = ALWAYS); o resto da árvore congela.
## Visual só com Estilo.* (identidade "Festival sombrio").

signal started

const BG := Color(Estilo.LACA, 0.97)
const CONTEUDO := Vector2(940, 560)

## Depois de trocar modo/time na tela inicial a cena recarrega; com isto
## ligado a partida já começa sem passar pela tela inicial de novo.
static var pular_inicio := false
## Volta da partida online (ou o anfitrião caiu): abre direto na sala.
static var abrir_sala := false

var _painel: Control
var _titulo: Label
var _nav: VBoxContainer
var _conteudo: Control
var _secoes: Dictionary = {}       # nome -> Control
var _botoes_nav: Dictionary = {}   # nome -> Button
var _tutorial: Tutorial
var _classes: PaginaClasses
var _lobby: Lobby
var _modo := "inicio"              # inicio | pausa
var _started := false  # fica falso no modo teste (--autoplay), que não deve pausar sozinho
var _time_escolhido := Config.TEAM_BLUE
var _modo_escolhido := 0  # 0 normal, 1 modo teste, 2 arena de chapéus
var _btn_jogar: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var g := get_parent() as Game
	_time_escolhido = g.time_jogador if g else Config.TEAM_BLUE
	_modo_escolhido = _modo_do_jogo(g)
	_painel = _build()
	_painel.visible = false
	add_child(_painel)


func show_start() -> void:
	if abrir_sala:
		abrir_sala = false
		_abrir("inicio", "amigos")
		return
	if pular_inicio:
		pular_inicio = false
		_begin()
		return
	_abrir("inicio", "jogar")
	if not Settings.tutorial_visto:
		_mostrar("como_jogar")


## Só para prints (--menu=inicio|pausa): mostra a tela sem pausar o jogo.
func mostrar_para_print(qual: String) -> void:
	_modo = qual
	_montar_nav()
	_titulo.text = "Castelo de Bolo" if qual == "inicio" else "Pausado"
	_mostrar("jogar" if qual == "inicio" else "controles")
	_painel.visible = true


func is_open() -> bool:
	return _painel.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		Settings.toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if _painel.visible:
		if _modo == "inicio":
			if event.is_action_pressed("ui_accept") and _btn_jogar and not _btn_jogar.has_focus():
				_begin()
			elif event.is_action_pressed("ui_cancel") and _secao_atual() != "jogar":
				_mostrar("jogar")
				get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			_fechar()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		_abrir("pausa", "controles")
		get_viewport().set_input_as_handled()


## Se o jogo perder o foco (outro app, aviso do Windows, saiu da tela cheia),
## pausa na hora: ninguém morre enquanto você está fora.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not is_open() and _started and not get_tree().paused and not Rede.em_partida:
		_abrir("pausa", "controles")


func _abrir(modo: String, secao: String) -> void:
	_modo = modo
	_titulo.text = "Castelo de Bolo" if modo == "inicio" else "Pausado"
	_montar_nav()
	_mostrar(secao)
	_painel.visible = true
	if not Rede.em_partida:  # online o jogo dos outros não para: o menu fica por cima
		get_tree().paused = true


func _fechar() -> void:
	_painel.visible = false
	if not Rede.em_partida:
		get_tree().paused = false
	Settings.save()
	if not Settings.tutorial_visto:
		Settings.tutorial_visto = true
		Settings.save()


func _begin() -> void:
	# Modo ou time diferentes do que está montado: recarrega a cena já jogando.
	var g := get_parent() as Game
	if g and (_modo_do_jogo(g) != _modo_escolhido or g.time_jogador != _time_escolhido):
		Game.sandbox_pedido = _modo_escolhido == 1
		Game.arena_pedido = _modo_escolhido == 2
		Game.time_pedido = _time_escolhido
		pular_inicio = true
		Settings.save()
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	if not Settings.tutorial_visto:
		Settings.tutorial_visto = true
		Settings.save()
	_painel.visible = false
	get_tree().paused = false
	_started = true
	started.emit()


## Modo em que a partida montada está (índice do OptionButton da tela inicial).
func _modo_do_jogo(g: Game) -> int:
	if g == null:
		return 0
	return 2 if g.arena_chapeus else (1 if g.sandbox else 0)


func _secao_atual() -> String:
	for n in _secoes:
		if _secoes[n].visible:
			return n
	return ""


func _mostrar(nome: String) -> void:
	for n in _secoes:
		_secoes[n].visible = n == nome
	for n in _botoes_nav:
		var b: Button = _botoes_nav[n]
		b.disabled = n == nome
		b.modulate = Color(1, 1, 1, 1) if n != nome else Color(1.25, 1.2, 1.1, 1)
	_tutorial.ativo(nome == "como_jogar")
	_lobby.ativo(nome == "amigos")
	_classes.ativo(nome == "classes")
	if nome == "jogar" and _btn_jogar:
		_btn_jogar.call_deferred("grab_focus")


# --- Construção ---------------------------------------------------------------

func _build() -> Control:
	var root := _backdrop()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	var sb := Estilo.placa(BG, Estilo.OURO, 14)
	sb.set_border_width_all(3)
	sb.shadow_offset = Vector2(0, 8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 14
	sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	_titulo = Estilo.titulo("Castelo de Bolo", 60, Estilo.OURO)
	box.add_child(_titulo)
	box.add_child(Estilo.ornamento(420.0))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	box.add_child(h)
	_nav = VBoxContainer.new()
	_nav.add_theme_constant_override("separation", 8)
	_nav.custom_minimum_size = Vector2(236, 0)
	h.add_child(_nav)
	var moldura := PanelContainer.new()
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(Estilo.TINTA, 0.55)
	msb.border_color = Color(Estilo.OURO, 0.45)
	msb.set_border_width_all(2)
	msb.set_corner_radius_all(Estilo.RAIO)
	msb.set_content_margin_all(14)
	moldura.add_theme_stylebox_override("panel", msb)
	h.add_child(moldura)
	_conteudo = Control.new()
	_conteudo.custom_minimum_size = CONTEUDO
	moldura.add_child(_conteudo)

	_secoes["jogar"] = _secao_jogar()
	_lobby = Lobby.new()
	_secoes["amigos"] = _lobby
	_tutorial = Tutorial.new()
	_secoes["como_jogar"] = _tutorial
	_classes = PaginaClasses.new()
	_secoes["classes"] = _classes
	_secoes["controles"] = _secao_controles()
	_secoes["config"] = _secao_config()
	for n in _secoes:
		var c: Control = _secoes[n]
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.visible = false
		_conteudo.add_child(c)
	return root


## Botões da coluna da esquerda: dependem de ser tela inicial ou pausa.
func _montar_nav() -> void:
	for c in _nav.get_children():
		c.queue_free()
	_botoes_nav.clear()
	_btn_jogar = null
	if _modo == "inicio":
		_btn_jogar = _nav_botao("JOGAR", "", _begin)
		_btn_jogar.custom_minimum_size = Vector2(0, 64)
		_btn_jogar.add_theme_font_size_override("font_size", 32)
		_nav_botao("Começo", "jogar")
		_nav_botao("Com amigos", "amigos")
	elif Rede.em_partida:
		var cont := _nav_botao("Continuar", "", _fechar)
		cont.custom_minimum_size = Vector2(0, 64)
		cont.add_theme_font_size_override("font_size", 30)
		_nav_botao("Trocar de time", "", func():
			Rede.pedir_acao(Comando.Acao.TROCAR_TIME)
			_fechar())
		if Rede.anfitriao:
			_nav_botao("Voltar à sala (todos)", "", func(): Rede.voltar_para_sala())
		_nav_botao("Sair da partida", "", func():
			Rede.sair()
			get_tree().paused = false
			get_tree().reload_current_scene())
	else:
		var cont := _nav_botao("Continuar", "", _fechar)
		cont.custom_minimum_size = Vector2(0, 64)
		cont.add_theme_font_size_override("font_size", 30)
		_nav_botao("Reiniciar partida", "", func():
			Settings.save()
			get_tree().paused = false
			get_tree().reload_current_scene())
	_nav.add_child(Estilo.ornamento(160.0, Color(Estilo.OURO, 0.5)))
	_nav_botao("Como jogar", "como_jogar")
	_nav_botao("Classes", "classes")
	_nav_botao("Controles", "controles")
	_nav_botao("Configurações", "config")
	var sobra := Control.new()
	sobra.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_nav.add_child(sobra)
	if OS.get_name() != "Web":
		_nav_botao("Sair do jogo", "", func():
			Settings.save()
			get_tree().quit())
	var dica := Estilo.rotulo("Esc  volta" if _modo == "inicio" else "Esc  continua", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nav.add_child(dica)


func _nav_botao(texto: String, secao: String, acao := Callable()) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 50)
	if secao != "":
		b.pressed.connect(func(): _mostrar(secao))
		_botoes_nav[secao] = b
	else:
		b.pressed.connect(acao)
	_nav.add_child(b)
	return b


## Seção "Começo": o que é o jogo, modo e time, e as 3 dicas.
func _secao_jogar() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var sub := Estilo.rotulo("A GUERRA DA MÁSCARA ONI", 24, Estilo.TEXTO, Estilo.espacada(Estilo.NUMERO, 4))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var intro := _text("Dois clãs, uma Máscara Oni em cada castelo. Roube a máscara inimiga e leve-a até o pedestal do seu castelo. E não deixe levarem a sua.", 20, Estilo.TEXTO)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(intro)

	var nomes: PackedStringArray = []
	for c in Config.cfg.hat_class_list:
		nomes.append(c.display_name)
	var lista := ", ".join(nomes.slice(0, -1)) + " ou " + nomes[-1] if nomes.size() > 1 else ", ".join(nomes)
	var dicas := HBoxContainer.new()
	dicas.add_theme_constant_override("separation", 12)
	for tip in [
		["katana", Estilo.OURO, "Chapéus", "No pátio, aperte F perto de um chapéu: %s. Cada casa vira um de dois caminhos." % lista],
		["espirito", Estilo.FANTASMA, "Espíritos", "Leve as chamas verdes até a SUA máscara: pesada, o ladrão anda devagar com ela."],
		["mascara", Estilo.AZUL, "Resgate", "Quem cai pode ser reanimado por um aliado (segure F); senão volta como recruta. Vence quem fizer %d resgates primeiro." % Config.cfg.score_to_win],
	]:
		dicas.add_child(_dica(tip[0], tip[1], tip[2], tip[3]))
	v.add_child(dicas)

	# Modo e time: valem ao apertar JOGAR (a cena recarrega se mudar).
	var opcoes := PanelContainer.new()
	opcoes.add_theme_stylebox_override("panel", Estilo.placa(Estilo.LACA_CLARA, Color(Estilo.OURO, 0.6), 8))
	v.add_child(opcoes)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 24)
	grade.add_theme_constant_override("v_separation", 10)
	opcoes.add_child(grade)
	grade.add_child(_text("Partida", Estilo.T_MEDIO, Estilo.OURO, false))
	var modo := OptionButton.new()
	modo.add_item("Normal: 8 contra 8, com bots")
	modo.add_item("Modo teste: sem bots, tudo pronto e recarregando rápido")
	modo.add_item("Arena de chapéus: toda classe à mão e um tambor que gera inimigos")
	modo.selected = _modo_escolhido
	modo.item_selected.connect(func(i: int): _modo_escolhido = i)
	grade.add_child(modo)
	grade.add_child(_text("Seu time", Estilo.T_MEDIO, Estilo.OURO, false))
	var times := HBoxContainer.new()
	times.add_theme_constant_override("separation", 10)
	var grupo := ButtonGroup.new()
	for t in 2:
		var b := Button.new()
		b.text = Config.TEAM_NAMES[t]
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = t == _time_escolhido
		b.custom_minimum_size = Vector2(150, 44)
		b.add_theme_color_override("font_color", Estilo.cor_time(t).darkened(0.55))
		b.add_theme_color_override("font_pressed_color", Estilo.cor_time(t).darkened(0.65))
		b.add_theme_color_override("font_hover_color", Estilo.cor_time(t).darkened(0.55))
		b.pressed.connect(func(): _time_escolhido = t)
		times.add_child(b)
	var nota := _text("Jogar de Vermelho começa do outro lado do mapa.", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, false)
	times.add_child(nota)
	grade.add_child(times)

	var rodape := _text("JOGAR ou Enter para começar. Esc > Controles mostra as teclas a qualquer hora.", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rodape)
	return v


## Cartão de dica: ícone, título e texto curto.
func _dica(icone: String, cor: Color, titulo: String, texto: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.placa(Estilo.LACA_CLARA, Color(Estilo.OURO, 0.6), 8))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(Icone.novo(icone, cor, 30))
	h.add_child(Estilo.rotulo(titulo.to_upper(), 24, cor, Estilo.NUMERO))
	v.add_child(h)
	var t := _text(texto, 17, Estilo.TEXTO)
	t.custom_minimum_size = Vector2(240, 0)
	v.add_child(t)
	return p


func _secao_controles() -> Control:
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	rolagem.add_child(v)
	v.add_child(_controls_grid())
	v.add_child(Estilo.ornamento(300.0, Color(Estilo.OURO, 0.5)))
	v.add_child(Estilo.rotulo("Q, E E R DE CADA CLASSE", Estilo.T_PEQUENO, Estilo.OURO, Estilo.espacada(Estilo.NUMERO, 3)))
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 18)
	grade.add_theme_constant_override("v_separation", 6)
	for cab in ["Classe", "Q  rápida", "E  Chi", "R  super"]:
		grade.add_child(Estilo.rotulo(cab, Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, Estilo.NUMERO))
	for s in PaginaClasses.lista():
		grade.add_child(_text(s.display_name, Estilo.T_PEQUENO, s.hat_color.lightened(0.3), false))
		grade.add_child(_text(s.skill_name if s.skill_name != "" else "–", Estilo.T_PEQUENO, Estilo.TEXTO, false))
		grade.add_child(_text(s.power_name if s.power_name != "" else "–", Estilo.T_PEQUENO, Estilo.TEXTO, false))
		grade.add_child(_text(PaginaClasses.nome_super(s), Estilo.T_PEQUENO, Estilo.TEXTO, false))
	v.add_child(grade)
	return rolagem


## Grade "tecla + o que faz", uma dupla por linha.
func _controls_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 7)
	for pair in Config.CONTROLS:
		var teclas := HBoxContainer.new()
		teclas.add_theme_constant_override("separation", 6)
		var partes: PackedStringArray = pair[0].split(" ou ")
		for k in partes.size():
			if k > 0:
				teclas.add_child(Estilo.rotulo("ou", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO))
			teclas.add_child(Estilo.tecla(partes[k], Estilo.T_PEQUENO + 1))
		grid.add_child(teclas)
		var o_que := _text(pair[1], Estilo.T_TEXTO - 1, Estilo.TEXTO, true)
		o_que.custom_minimum_size = Vector2(640, 0)
		grid.add_child(o_que)
	return grid


## Configurações em três grupos: Som, Vídeo e Partida.
func _secao_config() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	var esq := VBoxContainer.new()
	esq.add_theme_constant_override("separation", 16)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(esq)
	var dir := VBoxContainer.new()
	dir.add_theme_constant_override("separation", 16)
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dir)

	var som := _grupo(esq, "Som")
	_linha(som, "Música", _slider(Settings.music_volume, func(v: float):
		Settings.music_volume = v
		Settings.apply()))
	_linha(som, "Efeitos", _slider(Settings.sfx_volume, func(v: float):
		Settings.sfx_volume = v
		Settings.apply()
		Sfx.play_ui("pickup")))

	var video := _grupo(esq, "Vídeo")
	var qual := OptionButton.new()
	for q in Settings.QUALITIES:
		qual.add_item(q)
	qual.selected = Settings.quality
	qual.item_selected.connect(func(i: int):
		Settings.quality = i
		Settings.alta_ajuste = 0  # escolha manual zera a Alta dinâmica (ela mede de novo)
		Settings.apply())
	_linha(video, "Qualidade gráfica", qual)
	# O que a Alta dinâmica já desligou para segurar 30 FPS (só aparece na Alta).
	var ajuste := Label.new()
	ajuste.add_theme_font_size_override("font_size", 13)
	ajuste.modulate = Color(1, 1, 1, 0.6)
	video.add_child(ajuste)
	var mostra_ajuste := func():
		qual.selected = Settings.quality  # AutoQuality pode mudar
		ajuste.visible = Settings.quality == 3
		ajuste.text = "Alta dinâmica: " + Settings.ALTA_AJUSTES[Settings.alta_ajuste]
	Settings.changed.connect(mostra_ajuste)
	mostra_ajuste.call()
	_linha(video, "Baixar sozinho se travar", _check(Settings.auto_quality, func(on: bool):
		Settings.auto_quality = on
		Settings.apply()))
	_linha(video, "Tela cheia  (F11)", _check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, func(on: bool):
		Settings.set_fullscreen(on)))
	_linha(video, "Mostrar FPS", _check(Settings.show_fps, func(on: bool):
		Settings.show_fps = on
		Settings.apply()))

	var partida := _grupo(dir, "Partida")
	var diff := OptionButton.new()
	for d in Settings.DIFFICULTIES:
		diff.add_item(d)
	diff.selected = Settings.difficulty
	diff.item_selected.connect(func(i: int):
		Settings.difficulty = i
		Settings.apply())
	_linha(partida, "Dificuldade dos bots", diff)
	if Config.cfg.themes.size() > 1 and not Rede.em_partida:  # online: tema e mapa são os do anfitrião (recarregar aqui separava a partida)
		var th := OptionButton.new()
		for t in Config.cfg.themes:
			th.add_item(t.display_name)
		th.selected = Settings.theme
		th.item_selected.connect(func(i: int):
			Settings.theme = i
			Settings.save()
			get_tree().paused = false
			get_tree().reload_current_scene())  # o mapa é montado de novo com o tema
		_linha(partida, "Tema do mapa", th)
	if Config.cfg.maps.size() > 1 and not Rede.em_partida:
		var mp := OptionButton.new()
		for m in Config.cfg.maps:
			mp.add_item(m.display_name)
		mp.selected = clampi(Settings.mapa, 0, Config.cfg.maps.size() - 1)
		mp.item_selected.connect(func(i: int):
			Settings.mapa = i
			Settings.save()
			get_tree().paused = false
			get_tree().reload_current_scene())
		_linha(partida, "Mapa", mp)
	_linha(partida, "Tremor da câmera", _check(Settings.camera_shake, func(on: bool):
		Settings.camera_shake = on
		Settings.apply()))
	_linha(partida, "Números de dano", _check(Settings.damage_numbers, func(on: bool):
		Settings.damage_numbers = on
		Settings.apply()))
	_linha(partida, "Abrir Como jogar ao iniciar", _check(not Settings.tutorial_visto, func(on: bool):
		Settings.tutorial_visto = not on
		Settings.save()))
	var nota := _text("Tema e mapa recomeçam a partida. As escolhas ficam salvas.", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO)
	dir.add_child(nota)
	return h


func _grupo(pai: Control, titulo: String) -> GridContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pai.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	cab.add_child(Estilo.rotulo(titulo.to_upper(), Estilo.T_MEDIO, Estilo.OURO, Estilo.espacada(Estilo.NUMERO, 3)))
	var filete := Estilo.ornamento(120.0, Color(Estilo.OURO, 0.5))
	filete.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(filete)
	v.add_child(cab)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	return grid


func _linha(grid: GridContainer, rotulo: String, controle: Control) -> void:
	var l := _text(rotulo, Estilo.T_TEXTO, Estilo.TEXTO, false)
	l.custom_minimum_size = Vector2(230, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(l)
	if not controle is CheckButton:
		controle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(controle)


# --- Peças de interface -------------------------------------------------------

func _backdrop() -> Control:
	var root := ColorRect.new()
	root.color = Color(Estilo.TINTA, 0.6)
	root.theme = Estilo.tema()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	return root


## wrap = false em grades: Label com quebra de linha tem largura mínima zero
## e o GridContainer o espreme até virar uma letra por linha.
func _text(text: String, size: int, color := Color.WHITE, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.label_settings = Estilo.ajustes(size, color, Estilo.CORPO, 2)  # sobre placa: contorno fino
	l.label_settings.shadow_color = Color(0, 0, 0, 0)
	return l


func _slider(value: float, on_change: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(200, 28)
	s.value_changed.connect(on_change)
	return s


## CheckButton (chave liga/desliga): o quadradinho do CheckBox desmarcado
## quase some no fundo escuro do painel.
func _check(value: bool, on_toggle: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.button_pressed = value
	c.toggled.connect(on_toggle)
	return c
