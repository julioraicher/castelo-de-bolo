class_name Menus
extends CanvasLayer
## Tela inicial ("Como jogar") e menu de pausa (Esc) com as abas
## Controles e Configurações. Roda mesmo com o jogo pausado
## (process_mode = ALWAYS); o resto da árvore congela.

signal started

const BG := Color(Estilo.LACA, 0.97)
const ACCENT := Estilo.OURO
const GOLD := Estilo.OURO

var _start_panel: Control
var _pause_panel: Control
var _tabs: TabContainer
var _started := false  # fica falso no modo teste (--autoplay), que não deve pausar sozinho


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_panel = _build_start()
	_start_panel.visible = false  # só aparece via show_start() (no modo teste não)
	add_child(_start_panel)
	_pause_panel = _build_pause()
	_pause_panel.visible = false
	add_child(_pause_panel)


func show_start() -> void:
	_start_panel.visible = true
	get_tree().paused = true


## Só para prints (--menu=inicio|pausa): mostra a tela sem pausar o jogo.
func mostrar_para_print(qual: String) -> void:
	(_start_panel if qual == "inicio" else _pause_panel).visible = true


func is_open() -> bool:
	return _start_panel.visible or _pause_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		Settings.toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if _start_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_begin()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


## Se o jogo perder o foco (outro app, aviso do Windows, saiu da tela cheia),
## pausa na hora: ninguém morre enquanto você está fora.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not is_open() and _started and not get_tree().paused:
		_toggle_pause()


func _begin() -> void:
	_start_panel.visible = false
	get_tree().paused = false
	_started = true
	started.emit()


func _toggle_pause() -> void:
	_pause_panel.visible = not _pause_panel.visible
	get_tree().paused = _pause_panel.visible
	if not _pause_panel.visible:
		Settings.save()


# --- Construção das telas -----------------------------------------------------

func _build_start() -> Control:
	var root := _backdrop()
	var box := _card(root, Vector2(900, 0))
	var cabeca := VBoxContainer.new()
	cabeca.add_theme_constant_override("separation", 2)
	cabeca.add_child(Estilo.titulo("Castelo de Bolo", 72, ACCENT))
	cabeca.add_child(Estilo.ornamento(420.0))
	var sub := Estilo.rotulo("A GUERRA DA MÁSCARA ONI", 24, Estilo.TEXTO, Estilo.espacada(Estilo.NUMERO, 4))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cabeca.add_child(sub)
	box.add_child(cabeca)
	var intro := _text("Dois clãs, uma Máscara Oni em cada castelo. Roube a máscara inimiga e leve-a até o pedestal do seu castelo. E não deixe levarem a sua.", 20, Estilo.TEXTO)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(intro)
	var nomes: PackedStringArray = []
	for c in Config.cfg.hat_class_list:
		nomes.append(c.display_name)
	var lista := ", ".join(nomes.slice(0, -1)) + " ou " + nomes[-1] if nomes.size() > 1 else ", ".join(nomes)
	var dicas := HBoxContainer.new()
	dicas.add_theme_constant_override("separation", 12)
	for tip in [
		["katana", GOLD, "Chapéus", "No pátio, aperte F perto de um chapéu: %s. O Construtor corta madeira e ergue oficinas com classes novas." % lista],
		["espirito", Estilo.FANTASMA, "Espíritos", "Leve as chamas verdes até a SUA máscara. Cheia de espíritos, ela pesa e o inimigo anda devagar com ela."],
		["mascara", Estilo.AZUL, "Resgate", "Quem cai volta como recruta. Itens no chão ajudam na briga. Vence quem fizer %d resgates primeiro." % Config.cfg.score_to_win],
	]:
		dicas.add_child(_dica(tip[0], tip[1], tip[2], tip[3]))
	box.add_child(dicas)
	box.add_child(_controls_grid(2))
	var play := _button("JOGAR   ·   Enter")
	play.custom_minimum_size = Vector2(300, 58)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_begin)
	box.add_child(play)
	play.call_deferred("grab_focus")
	return root


## Cartão de dica da tela inicial: ícone, título e texto curto.
func _dica(icone: String, cor: Color, titulo: String, texto: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.placa(Estilo.LACA_CLARA, Color(Estilo.OURO, 0.6), 8))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 0)
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


func _build_pause() -> Control:
	var root := _backdrop()
	var box := _card(root, Vector2(700, 0))
	box.add_child(Estilo.titulo("Pausado", 64, GOLD))
	box.add_child(Estilo.ornamento(300.0))
	_tabs = TabContainer.new()
	_tabs.custom_minimum_size = Vector2(0, 360)
	box.add_child(_tabs)
	var controls := MarginContainer.new()
	controls.name = "Controles"
	_margins(controls, 16)
	controls.add_child(_controls_grid())
	_tabs.add_child(controls)
	var settings := MarginContainer.new()
	settings.name = "Configurações"
	_margins(settings, 16)
	settings.add_child(_settings_form())
	_tabs.add_child(settings)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var resume := _button("Continuar   ·   Esc")
	resume.pressed.connect(_toggle_pause)
	row.add_child(resume)
	var restart := _button("Reiniciar partida")
	restart.pressed.connect(func():
		Settings.save()
		get_tree().paused = false
		get_tree().reload_current_scene())
	row.add_child(restart)
	if OS.get_name() != "Web":
		var quit := _button("Sair do jogo")
		quit.pressed.connect(func():
			Settings.save()
			get_tree().quit())
		row.add_child(quit)
	box.add_child(row)
	return root


## pares = quantos "tecla + o que faz" por linha (2 na tela inicial: cabe sem rolar).
func _controls_grid(pares := 1) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2 * pares
	grid.add_theme_constant_override("h_separation", 18 if pares > 1 else 24)
	grid.add_theme_constant_override("v_separation", 8)
	for pair in Config.CONTROLS:
		var teclas := HBoxContainer.new()
		teclas.add_theme_constant_override("separation", 6)
		var partes: PackedStringArray = pair[0].split(" ou ")
		for k in partes.size():
			if k > 0:
				teclas.add_child(Estilo.rotulo("ou", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO))
			teclas.add_child(Estilo.tecla(partes[k], Estilo.T_PEQUENO + 1))
		grid.add_child(teclas)
		var o_que := _text(pair[1], Estilo.T_TEXTO - (3 if pares > 1 else 1), Estilo.TEXTO, true)
		o_que.custom_minimum_size = Vector2(500 if pares == 1 else 290, 0)
		grid.add_child(o_que)
	return grid


func _settings_form() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)

	grid.add_child(_text("Volume da música", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_slider(Settings.music_volume, func(v: float):
		Settings.music_volume = v
		Settings.apply()))
	grid.add_child(_text("Volume dos efeitos", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_slider(Settings.sfx_volume, func(v: float):
		Settings.sfx_volume = v
		Settings.apply()
		Sfx.play_ui("pickup")))

	grid.add_child(_text("Dificuldade dos inimigos", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	var diff := OptionButton.new()
	for d in Settings.DIFFICULTIES:
		diff.add_item(d)
	diff.selected = Settings.difficulty
	diff.item_selected.connect(func(i: int):
		Settings.difficulty = i
		Settings.apply())
	grid.add_child(diff)

	if Config.cfg.themes.size() > 1:
		grid.add_child(_text("Tema do mapa", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
		var th := OptionButton.new()
		for t in Config.cfg.themes:
			th.add_item(t.display_name)
		th.selected = Settings.theme
		th.item_selected.connect(func(i: int):
			Settings.theme = i
			Settings.save()
			get_tree().paused = false
			get_tree().reload_current_scene())  # o mapa é montado de novo com o tema
		grid.add_child(th)

	if Config.cfg.maps.size() > 1:
		grid.add_child(_text("Mapa", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
		var mp := OptionButton.new()
		for m in Config.cfg.maps:
			mp.add_item(m.display_name)
		mp.selected = clampi(Settings.mapa, 0, Config.cfg.maps.size() - 1)
		mp.item_selected.connect(func(i: int):
			Settings.mapa = i
			Settings.save()
			get_tree().paused = false
			get_tree().reload_current_scene())
		grid.add_child(mp)

	grid.add_child(_text("Qualidade gráfica", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	var qual := OptionButton.new()
	for q in Settings.QUALITIES:
		qual.add_item(q)
	qual.selected = Settings.quality
	qual.item_selected.connect(func(i: int):
		Settings.quality = i
		Settings.apply())
	Settings.changed.connect(func(): qual.selected = Settings.quality)  # AutoQuality pode mudar
	grid.add_child(qual)
	grid.add_child(_text("Qualidade automática", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_check(Settings.auto_quality, func(on: bool):
		Settings.auto_quality = on
		Settings.apply()))
	grid.add_child(_text("Mostrar FPS", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_check(Settings.show_fps, func(on: bool):
		Settings.show_fps = on
		Settings.apply()))

	grid.add_child(_text("Tela cheia  (F)", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, func(on: bool):
		Settings.set_fullscreen(on)))
	grid.add_child(_text("Tremor da câmera", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_check(Settings.camera_shake, func(on: bool):
		Settings.camera_shake = on
		Settings.apply()))
	grid.add_child(_text("Números de dano", Estilo.T_TEXTO + 1, Estilo.TEXTO, false))
	grid.add_child(_check(Settings.damage_numbers, func(on: bool):
		Settings.damage_numbers = on
		Settings.apply()))
	return grid


# --- Peças de interface -------------------------------------------------------

func _backdrop() -> Control:
	var root := ColorRect.new()
	root.color = Color(Estilo.TINTA, 0.6)
	root.theme = Estilo.tema()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	return root


func _card(parent: Control, min_size: Vector2) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	var sb := Estilo.placa(BG, ACCENT, 14)
	sb.set_border_width_all(3)
	sb.shadow_offset = Vector2(0, 8)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 20
	sb.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return box


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


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 52)
	return b


func _slider(value: float, on_change: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(260, 28)
	s.value_changed.connect(on_change)
	return s


## CheckButton (chave liga/desliga): o quadradinho do CheckBox desmarcado
## quase some no fundo escuro do painel.
func _check(value: bool, on_toggle: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.button_pressed = value
	c.toggled.connect(on_toggle)
	return c


func _margins(m: MarginContainer, px: int) -> void:
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, px)
