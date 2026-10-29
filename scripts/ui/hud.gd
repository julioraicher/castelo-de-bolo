class_name Hud
extends CanvasLayer
## Interface: placar, estado das princesas, vida e classe do jogador, dicas e
## mensagens grandes. Montada por código para ficar tudo num arquivo só.

var _score_blue: Label
var _score_red: Label
var _princess_info: Array[Label] = []
var _fat_bars: Array[ProgressBar] = []
var _class_label: Label
var _hp_bar: ProgressBar
var _power_bar: ProgressBar
var _power_label: Label
var _hint: Label
var _big: Label
var _help: Label
var _fps: Label
var _end_panel: PanelContainer
var _end_label: Label
var _big_tween: Tween


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Placar (topo).
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.position = Vector2(-260, 14)
	top.custom_minimum_size = Vector2(520, 0)
	top.add_theme_constant_override("separation", 4)
	root.add_child(top)
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 18)
	top.add_child(score_row)
	_score_blue = _label("AZUL 0", 40, Config.team_color(0).lightened(0.3))
	score_row.add_child(_score_blue)
	score_row.add_child(_label("×", 32, Color(1, 1, 1, 0.8)))
	_score_red = _label("0 VERMELHO", 40, Config.team_color(1).lightened(0.3))
	score_row.add_child(_score_red)
	var goal := _label("primeiro a %d resgates vence" % Config.cfg.score_to_win, 16, Color(1, 1, 1, 0.75))
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(goal)
	for team in 2:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		top.add_child(row)
		var info := _label("", 18, Config.team_color(team).lightened(0.45))
		info.custom_minimum_size = Vector2(330, 0)
		row.add_child(info)
		_princess_info.append(info)
		var bar := _bar(Color(1, 0.55, 0.78))
		bar.custom_minimum_size = Vector2(110, 14)
		bar.tooltip_text = "Peso da princesa"
		row.add_child(bar)
		_fat_bars.append(bar)

	# Jogador (canto inferior esquerdo).
	var me := VBoxContainer.new()
	me.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	me.position = Vector2(24, -150)
	root.add_child(me)
	_class_label = _label("Recruta", 28, Color.WHITE)
	me.add_child(_class_label)
	_hp_bar = _bar(Config.team_color(0).lightened(0.2))
	_hp_bar.custom_minimum_size = Vector2(280, 22)
	me.add_child(_hp_bar)
	# Medidor de Glacê: enche lutando; cheio libera o poder no Q.
	_power_bar = _bar(Color(1, 0.62, 0.85))
	_power_bar.custom_minimum_size = Vector2(280, 12)
	me.add_child(_power_bar)
	_power_label = _label("", 17, Color(1, 0.8, 0.92))
	me.add_child(_power_label)

	# Dica de interação (centro inferior).
	_hint = _label("", 24, Color(1, 0.95, 0.6))
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position = Vector2(-300, -80)
	_hint.custom_minimum_size = Vector2(600, 0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	# Ajuda de controles (canto superior esquerdo).
	_help = _label("Esc: pausar · controles · configurações", 17, Color(1, 1, 1, 0.9))
	_help.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_help.position = Vector2(-380, -44)
	root.add_child(_help)

	# Contador de FPS (Esc > Configurações > Mostrar FPS).
	_fps = _label("", 17, Color(1, 1, 0.6))
	_fps.position = Vector2(16, 14)
	root.add_child(_fps)

	# Mensagem grande (centro).
	_big = _label("", 52, Color.WHITE)
	_big.set_anchors_preset(Control.PRESET_CENTER)
	_big.position = Vector2(-500, -170)
	_big.custom_minimum_size = Vector2(1000, 0)
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_big.modulate.a = 0.0
	root.add_child(_big)

	# Tela de fim de jogo.
	_end_panel = PanelContainer.new()
	_end_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.1, 0.7)
	_end_panel.add_theme_stylebox_override("panel", sb)
	_end_panel.visible = false
	root.add_child(_end_panel)
	_end_label = _label("", 72, Color.WHITE)
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end_panel.add_child(_end_label)


func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS · %.1f ms" % [Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1.0)]


func update_state(game: Game) -> void:
	_score_blue.text = "AZUL %d" % game.score[0]
	_score_red.text = "%d VERMELHO" % game.score[1]
	for team in 2:
		var p: Princess = game.princesses[team]
		var who := "Sua princesa" if team == game.player.team else "Princesa inimiga"
		_princess_info[team].text = "%s: %s" % [who, p.state_text()]
		_fat_bars[team].value = p.fatness * 100.0
	var u := game.player
	_class_label.text = u.stats.display_name if u.alive else "Renascendo..."
	_hp_bar.value = u.hp_ratio() * 100.0
	_power_bar.value = u.power
	if u.power_ready():
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		_power_bar.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.4, 1.6), pulse)
		_power_label.text = "[Q] %s!" % u.stats.power_name
	else:
		_power_bar.modulate = Color(1, 1, 1, 0.85)
		_power_label.text = "Glacê %d%%" % int(u.power) if u.stats.power != "nenhum" else ""
	if u.has_cake:
		_class_label.text += "  · levando bolo"
	if u.carried_princess:
		_class_label.text += "  · CARREGANDO A PRINCESA"


func set_hint(text: String) -> void:
	_hint.text = text


func show_big(text: String, color := Color.WHITE, duration := 2.2) -> void:
	_big.text = text
	_big.label_settings.font_color = color
	if _big_tween:
		_big_tween.kill()
	_big.modulate.a = 1.0
	_big.scale = Vector2.ONE
	_big_tween = create_tween()
	_big_tween.tween_interval(duration)
	_big_tween.tween_property(_big, "modulate:a", 0.0, 0.5)


func show_end(won: bool) -> void:
	_end_panel.visible = true
	_end_label.text = ("VITÓRIA!" if won else "DERROTA...") + "\n\n[R] jogar de novo"
	_end_label.label_settings.font_color = Color(1, 0.85, 0.3) if won else Color(1, 0.5, 0.5)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = maxi(4, size / 6)
	ls.outline_color = Color(0, 0, 0, 0.85)
	ls.shadow_size = 2
	ls.shadow_color = Color(0, 0, 0, 0.4)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 100.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b
