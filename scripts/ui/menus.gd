class_name Menus
extends CanvasLayer
## Tela inicial ("Como jogar") e menu de pausa (Esc) com as abas
## Controles e Configurações. Roda mesmo com o jogo pausado
## (process_mode = ALWAYS); o resto da árvore congela.

signal started

const BG := Color(0.07, 0.05, 0.14, 0.86)
const ACCENT := Color(1.0, 0.55, 0.78)
const GOLD := Color(1.0, 0.85, 0.35)

var _start_panel: Control
var _pause_panel: Control
var _tabs: TabContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_panel = _build_start()
	add_child(_start_panel)
	_pause_panel = _build_pause()
	_pause_panel.visible = false
	add_child(_pause_panel)


func show_start() -> void:
	_start_panel.visible = true
	get_tree().paused = true


func is_open() -> bool:
	return _start_panel.visible or _pause_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if _start_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_begin()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _begin() -> void:
	_start_panel.visible = false
	get_tree().paused = false
	started.emit()


func _toggle_pause() -> void:
	_pause_panel.visible = not _pause_panel.visible
	get_tree().paused = _pause_panel.visible
	if not _pause_panel.visible:
		Settings.save()


# --- Construção das telas -----------------------------------------------------

func _build_start() -> Control:
	var root := _backdrop()
	var box := _card(root, Vector2(760, 0))
	box.add_child(_title("Castelo de Bolo", 64, ACCENT))
	box.add_child(_text("Dois castelos, uma princesa em cada. Invada o castelo vermelho, pegue a princesa deles e traga-a até o pedestal do seu castelo. Proteja a sua!", 20))
	var tips := VBoxContainer.new()
	tips.add_theme_constant_override("separation", 4)
	for tip in [
		"Pise num chapéu do seu pátio para virar Guerreiro, Arqueiro ou Clérigo.",
		"Leve bolos até a SUA princesa: gorda, ela fica pesada para o inimigo carregar.",
		"Quem morre volta como aldeão. Primeiro a 3 resgates vence.",
	]:
		tips.add_child(_text("•  " + tip, 18, Color(1, 1, 1, 0.85)))
	box.add_child(tips)
	box.add_child(_controls_grid())
	var play := _button("Jogar  (Enter)")
	play.pressed.connect(_begin)
	box.add_child(play)
	play.call_deferred("grab_focus")
	return root


func _build_pause() -> Control:
	var root := _backdrop()
	var box := _card(root, Vector2(700, 0))
	box.add_child(_title("Pausado", 48, GOLD))
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
	var resume := _button("Continuar  (Esc)")
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


func _controls_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	for pair in Config.CONTROLS:
		grid.add_child(_text(pair[0], 19, GOLD, false))
		grid.add_child(_text(pair[1], 19, Color.WHITE, false))
	return grid


func _settings_form() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)

	grid.add_child(_text("Volume da música", 19, Color.WHITE, false))
	grid.add_child(_slider(Settings.music_volume, func(v: float):
		Settings.music_volume = v
		Settings.apply()))
	grid.add_child(_text("Volume dos efeitos", 19, Color.WHITE, false))
	grid.add_child(_slider(Settings.sfx_volume, func(v: float):
		Settings.sfx_volume = v
		Settings.apply()
		Sfx.play_ui("pickup")))

	grid.add_child(_text("Dificuldade dos inimigos", 19, Color.WHITE, false))
	var diff := OptionButton.new()
	for d in Settings.DIFFICULTIES:
		diff.add_item(d)
	diff.selected = Settings.difficulty
	diff.item_selected.connect(func(i: int):
		Settings.difficulty = i
		Settings.apply())
	grid.add_child(diff)

	grid.add_child(_text("Qualidade gráfica", 19, Color.WHITE, false))
	var qual := OptionButton.new()
	for q in Settings.QUALITIES:
		qual.add_item(q)
	qual.selected = Settings.quality
	qual.item_selected.connect(func(i: int):
		Settings.quality = i
		Settings.apply())
	grid.add_child(qual)
	grid.add_child(_text("Mostrar FPS", 19, Color.WHITE, false))
	grid.add_child(_check(Settings.show_fps, func(on: bool):
		Settings.show_fps = on
		Settings.apply()))

	if OS.get_name() != "Web":
		grid.add_child(_text("Tela cheia", 19, Color.WHITE, false))
		grid.add_child(_check(Settings.fullscreen, func(on: bool):
			Settings.fullscreen = on
			Settings.apply()))
	grid.add_child(_text("Tremor da câmera", 19, Color.WHITE, false))
	grid.add_child(_check(Settings.camera_shake, func(on: bool):
		Settings.camera_shake = on
		Settings.apply()))
	grid.add_child(_text("Números de dano", 19, Color.WHITE, false))
	grid.add_child(_check(Settings.damage_numbers, func(on: bool):
		Settings.damage_numbers = on
		Settings.apply()))
	return grid


# --- Peças de interface -------------------------------------------------------

func _backdrop() -> Control:
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.55)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	return root


func _card(parent: Control, min_size: Vector2) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Color(ACCENT, 0.6)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	return box


func _title(text: String, size: int, color: Color) -> Label:
	var l := _text(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.label_settings.outline_size = 10
	return l


## wrap = false em grades: Label com quebra de linha tem largura mínima zero
## e o GridContainer o espreme até virar uma letra por linha.
func _text(text: String, size: int, color := Color.WHITE, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 4
	ls.outline_color = Color(0, 0, 0, 0.7)
	l.label_settings = ls
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
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
