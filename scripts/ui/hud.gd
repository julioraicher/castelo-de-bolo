class_name Hud
extends CanvasLayer
## Interface da partida (estilo Clãs de Neon, peças em Estilo/Icone): placar
## com losangos, estado das duas máscaras, cartão do jogador (retrato do papel,
## vida, Chi), dica com tecla desenhada, mensagens grandes e tela de fim.

var _placar: Array[Label] = []
var _pips: Array = [[], []]  # Icone losango por time
var _chips: Array[PanelContainer] = []
var _chip_estado: Array[Label] = []
var _peso: Array[ProgressBar] = []
var _retrato: PanelContainer
var _icone_papel: Icone
var _class_label: Label
var _status_label: Label
var _hp_bar: ProgressBar
var _hp_text: Label
var _power_bar: ProgressBar
var _power_key: Control
var _power_label: Label
var _hint_box: PanelContainer
var _hint_a: Label
var _hint_key: PanelContainer
var _hint_b: Label
var _big: Label
var _fps: Label
var _end_panel: Control
var _end_title: Label
var _end_score: Label
var _big_tween: Tween
var _meu_time := 0
var _score := [0, 0]


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_placar(root)
	_build_jogador(root)
	_build_dica(root)

	# Ajuda (canto inferior direito).
	var help := HBoxContainer.new()
	help.add_theme_constant_override("separation", 8)
	help.add_child(Estilo.tecla("Esc", 15))
	help.add_child(Estilo.rotulo("pausar · controles · configurações", 15, Estilo.TEXTO_FRACO))
	help.modulate.a = 0.8
	root.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 18)
	help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN

	# Contador de FPS (Esc > Configurações > Mostrar FPS).
	_fps = Estilo.rotulo("", 16, Estilo.OURO)
	_fps.position = Vector2(16, 12)
	root.add_child(_fps)

	# Mensagem grande (centro).
	_big = Estilo.titulo("", 50, Color.WHITE)
	_big.set_anchors_preset(Control.PRESET_CENTER)
	_big.custom_minimum_size = Vector2(1100, 140)
	_big.position = Vector2(-550, -230)
	_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_big.pivot_offset = Vector2(550, 70)
	_big.modulate.a = 0.0
	root.add_child(_big)

	_build_fim(root)


# --- Montagem -------------------------------------------------------------------

func _build_placar(root: Control) -> void:
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 12)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	top.add_child(row)
	for team in 2:
		if team == 1:
			var meio := VBoxContainer.new()
			meio.alignment = BoxContainer.ALIGNMENT_CENTER
			meio.add_theme_constant_override("separation", -4)
			var vs := Estilo.rotulo("VS", 22, Estilo.TEXTO, Estilo.FORTE)
			vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			meio.add_child(vs)
			var meta := Estilo.rotulo("%d resgates" % Config.cfg.score_to_win, 13, Estilo.TEXTO_FRACO)
			meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			meio.add_child(meta)
			row.add_child(meio)
		row.add_child(_placa(team))

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 12)
	top.add_child(chips)
	for team in 2:
		chips.add_child(_chip(team))


## Placa de um time: nome + losangos de pontos + número grande.
func _placa(team: int) -> PanelContainer:
	var c := Config.team_color(team)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.painel(c.lightened(0.25), true, Color(c.darkened(0.72), 0.92)))
	p.custom_minimum_size = Vector2(230, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
	p.add_child(h)
	var nome := VBoxContainer.new()
	nome.alignment = BoxContainer.ALIGNMENT_CENTER
	nome.add_theme_constant_override("separation", 2)
	var titulo := Estilo.rotulo(Config.TEAM_NAMES[team].to_upper(), 20, c.lightened(0.45), Estilo.FORTE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if team == 0 else HORIZONTAL_ALIGNMENT_LEFT
	nome.add_child(titulo)
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
	pips.add_theme_constant_override("separation", 3)
	for k in Config.cfg.score_to_win:
		var i := Icone.novo("losango", c.lightened(0.45), 16)
		i.cheio = false
		pips.add_child(i)
		_pips[team].append(i)
	nome.add_child(pips)
	var num := Estilo.titulo("0", 48, Color.WHITE)
	num.label_settings.font = Estilo.FORTE  # o zero da Shojumaru parece um redemoinho
	num.label_settings.shadow_color = Color(c.lightened(0.3), 0.7)
	num.custom_minimum_size = Vector2(44, 0)
	_placar.append(num)
	if team == 0:
		h.add_child(nome)
		h.add_child(num)
	else:
		h.add_child(num)
		h.add_child(nome)
	return p


## Estado da máscara de um time: ícone, frase e peso (espíritos presos).
func _chip(team: int) -> PanelContainer:
	var c := Config.team_color(team)
	var p := PanelContainer.new()
	var sb := Estilo.painel(Color(c.lightened(0.2), 0.7), false, Color(0.04, 0.035, 0.09, 0.78))
	sb.shadow_size = 4
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(290, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(Icone.novo("mascara", c.lightened(0.3), 34))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var dono := Estilo.rotulo("", 12, Estilo.TEXTO_FRACO, Estilo.FORTE, 3)
	dono.name = "Dono"
	v.add_child(dono)
	var estado := Estilo.rotulo("", 18, Estilo.TEXTO, Estilo.FORTE)
	v.add_child(estado)
	_chip_estado.append(estado)
	var peso_row := HBoxContainer.new()
	peso_row.add_theme_constant_override("separation", 6)
	peso_row.add_child(Icone.novo("espirito", Estilo.FANTASMA, 14))
	var peso := Estilo.barra(Estilo.FANTASMA, Vector2(110, 7))
	peso.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	peso.tooltip_text = "Peso da máscara (espíritos presos)"
	peso_row.add_child(peso)
	v.add_child(peso_row)
	_peso.append(peso)
	_chips.append(p)
	return p


func _build_jogador(root: Control) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilo.painel(Color(Estilo.CIANO, 0.55), true, Color(0.045, 0.04, 0.1, 0.82)))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	card.add_child(h)

	# Retrato: disco na cor do chapéu com o ícone do papel.
	_retrato = PanelContainer.new()
	_retrato.custom_minimum_size = Vector2(84, 84)
	_retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var disco := StyleBoxFlat.new()
	disco.set_corner_radius_all(42)
	disco.set_border_width_all(3)
	disco.anti_aliasing = true
	_retrato.add_theme_stylebox_override("panel", disco)
	h.add_child(_retrato)
	var centro := CenterContainer.new()
	_retrato.add_child(centro)
	_icone_papel = Icone.novo("recruta", Color.WHITE, 50)
	centro.add_child(_icone_papel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	h.add_child(v)
	_class_label = Estilo.rotulo("Recruta", 26, Color.WHITE, Estilo.TITULO, 6)
	v.add_child(_class_label)
	_status_label = Estilo.rotulo("", 15, Estilo.FANTASMA, Estilo.FORTE)
	v.add_child(_status_label)
	_hp_bar = Estilo.barra(Config.team_color(0).lightened(0.25), Vector2(300, 20))
	v.add_child(_hp_bar)
	_hp_text = Estilo.rotulo("", 14, Color.WHITE, Estilo.FORTE, 4)
	_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_text)
	var chi_row := HBoxContainer.new()
	chi_row.add_theme_constant_override("separation", 8)
	v.add_child(chi_row)
	# Medidor de Chi: enche lutando; cheio libera o poder no Q.
	_power_bar = Estilo.barra(Estilo.MAGENTA, Vector2(170, 10))
	_power_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chi_row.add_child(_power_bar)
	_power_key = Estilo.tecla("Q", 15)
	chi_row.add_child(_power_key)
	_power_label = Estilo.rotulo("", 15, Color(1, 0.8, 0.94), Estilo.FORTE)
	chi_row.add_child(_power_label)

	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_dica(root: Control) -> void:
	_hint_box = PanelContainer.new()
	var sb := Estilo.painel(Color(Estilo.OURO, 0.6), true, Color(0.05, 0.04, 0.1, 0.85))
	sb.shadow_size = 6
	_hint_box.add_theme_stylebox_override("panel", sb)
	_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hint_box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	_hint_box.add_child(h)
	_hint_a = Estilo.rotulo("", 21, Color(1, 0.95, 0.75), Estilo.FORTE)
	_hint_key = Estilo.tecla("E", 19)
	_hint_b = Estilo.rotulo("", 21, Color(1, 0.95, 0.75), Estilo.FORTE)
	h.add_child(_hint_a)
	h.add_child(_hint_key)
	h.add_child(_hint_b)
	_hint_box.visible = false
	_hint_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	_hint_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_box.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_fim(root: Control) -> void:
	_end_panel = ColorRect.new()
	_end_panel.color = Color(0.02, 0.01, 0.06, 0.72)
	_end_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_panel.visible = false
	root.add_child(_end_panel)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_panel.add_child(centro)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	centro.add_child(v)
	_end_title = Estilo.titulo("", 110, Estilo.OURO)
	v.add_child(_end_title)
	_end_score = Estilo.rotulo("", 30, Estilo.TEXTO, Estilo.FORTE)
	_end_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_end_score)
	var again := HBoxContainer.new()
	again.alignment = BoxContainer.ALIGNMENT_CENTER
	again.add_theme_constant_override("separation", 10)
	again.add_child(Estilo.tecla("R", 24))
	again.add_child(Estilo.rotulo("jogar de novo", 24, Estilo.TEXTO, Estilo.FORTE))
	v.add_child(again)


# --- Atualização ------------------------------------------------------------------

func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS · %.1f ms" % [Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1.0)]


func update_state(game: Game) -> void:
	var u := game.player
	_meu_time = u.team
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	for team in 2:
		_score[team] = game.score[team]
		_placar[team].text = str(game.score[team])
		for k in _pips[team].size():
			var pip: Icone = _pips[team][k]
			if pip.cheio != (k < game.score[team]):
				pip.cheio = k < game.score[team]
				pip.queue_redraw()
		var p: Princess = game.princesses[team]
		var minha := team == _meu_time
		var dono: Label = _chips[team].find_child("Dono", true, false)
		dono.text = "SUA MÁSCARA" if minha else "MÁSCARA INIMIGA"
		var txt := ""
		var cor := Estilo.TEXTO
		match p.state:
			Princess.State.HOME:
				txt = "segura no castelo" if minha else "no castelo deles"
				cor = Estilo.TEXTO_FRACO
			Princess.State.CARRIED:
				txt = "ROUBADA!" if minha else "com o seu time!"
				cor = Estilo.PERIGO if minha else Estilo.CIANO
			_:
				txt = "caída no chão"
				cor = Estilo.OURO
		_chip_estado[team].text = txt
		_chip_estado[team].label_settings.font_color = cor
		_chips[team].modulate = Color(1, 1, 1).lerp(Color(1.5, 1.3, 1.3), pulso) if p.state == Princess.State.CARRIED else Color.WHITE
		_peso[team].value = p.fatness * 100.0

	# Cartão do jogador.
	var time_cor := Config.team_color(u.team)
	var disco: StyleBoxFlat = _retrato.get_theme_stylebox("panel")
	disco.bg_color = u.stats.hat_color.darkened(0.55)
	disco.border_color = time_cor.lightened(0.3)
	_icone_papel.mudar(Icone.do_papel(u.stats), u.stats.hat_color.lightened(0.35))
	_class_label.text = u.stats.display_name if u.alive else "Renascendo..."
	var ratio := u.hp_ratio()
	_hp_bar.value = ratio * 100.0
	_hp_text.text = "%d / %d" % [ceili(u.hp), int(u.stats.max_hp)] if u.alive else ""
	Estilo.cor_barra(_hp_bar, time_cor.lightened(0.25) if ratio > 0.3 else Estilo.PERIGO.lerp(Color.WHITE, pulso * 0.4))
	_power_bar.value = u.power
	var tem_poder := u.stats.power != "nenhum"
	_power_bar.visible = tem_poder
	if u.power_ready():
		_power_bar.modulate = Color(1, 1, 1).lerp(Color(1.7, 1.5, 1.7), pulso)
		_power_key.visible = true
		_power_label.text = u.stats.power_name + "!"
		_power_label.label_settings.font_color = Estilo.FANTASMA
	else:
		_power_bar.modulate = Color(1, 1, 1, 0.85)
		_power_key.visible = false
		_power_label.text = "CHI %d%%" % int(u.power) if tem_poder else ""
		_power_label.label_settings.font_color = Color(1, 0.8, 0.94)
	if u.carried_princess:
		_status_label.text = "CARREGANDO A MÁSCARA"
		_status_label.label_settings.font_color = Estilo.OURO
	elif u.has_cake:
		_status_label.text = "levando um espírito"
		_status_label.label_settings.font_color = Estilo.FANTASMA
	else:
		_status_label.text = ""
	_status_label.visible = _status_label.text != ""


## Dica com tecla: o primeiro "[X]" do texto vira uma tecla desenhada.
func set_hint(text: String) -> void:
	_hint_box.visible = text != ""
	if text == "":
		return
	var a := text.find("[")
	var b := text.find("]", a)
	if a >= 0 and b > a:
		_hint_a.text = text.substr(0, a).strip_edges().trim_suffix("(").strip_edges()
		(_hint_key.get_child(0) as Label).text = text.substr(a + 1, b - a - 1)
		_hint_b.text = text.substr(b + 1).strip_edges().trim_suffix(")").strip_edges()
		_hint_key.visible = true
	else:
		_hint_a.text = text
		_hint_b.text = ""
		_hint_key.visible = false
	_hint_a.visible = _hint_a.text != ""
	_hint_b.visible = _hint_b.text != ""


func show_big(text: String, color := Color.WHITE, duration := 2.2) -> void:
	_big.text = text
	var ls := _big.label_settings
	ls.font_color = color
	ls.outline_color = color.darkened(0.8)
	ls.shadow_color = Color(color, 0.5)
	if _big_tween:
		_big_tween.kill()
	_big.modulate.a = 1.0
	_big.scale = Vector2(1.3, 1.3)
	_big_tween = create_tween()
	_big_tween.tween_property(_big, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_big_tween.tween_interval(duration)
	_big_tween.tween_property(_big, "modulate:a", 0.0, 0.5)


func show_end(won: bool) -> void:
	_end_panel.visible = true
	var cor := Estilo.OURO if won else Estilo.PERIGO
	_end_title.text = "VITÓRIA!" if won else "DERROTA..."
	_end_title.label_settings.font_color = cor
	_end_title.label_settings.outline_color = cor.darkened(0.8)
	_end_title.label_settings.shadow_color = Color(cor, 0.55)
	_end_score.text = "AZUL  %d  ×  %d  VERMELHO" % [_score[0], _score[1]]
