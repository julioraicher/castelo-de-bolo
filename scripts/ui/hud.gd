class_name Hud
extends CanvasLayer
## Interface da partida (peças em Estilo/Icone; fontes e tamanhos lá): placar
## com losangos, estado das duas máscaras, cartão do jogador (retrato do papel,
## vida, Chi), dica com tecla desenhada, mensagens grandes e tela de fim.
## "Festival sombrio": HUD cheio, mas tudo preso nas bordas. O centro da tela
## é da briga e dos efeitos: nada fica lá, nem o aviso grande (vai para cima).

var _placar: Array[Label] = []
## Ciclo 2.23: relógio regressivo no meio do placar (no lugar do "VS").
var _relogio: Label
var _relogio_meta: Label
var _pips: Array = [[], []]  # Icone losango por time
var _chips: Array[PanelContainer] = []
var _chip_estado: Array[Label] = []
var _chip_dono: Array[Label] = []
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
var _super_row: HBoxContainer
var _super_bar: ProgressBar
var _super_key: Control
var _super_label: Label
var _quick_row: HBoxContainer
var _quick_bar: ProgressBar
var _quick_label: Label
var _madeira_label: Label
var _madeira_visto := -1
var _carregando_label: Label  # "CARREGANDO 1/1" com tora nos braços
var _hint_box: PanelContainer
var _hint_a: Label
var _hint_key: PanelContainer
var _hint_b: Label
var _big: Label
var _multi: Label
var _multi_pts: Label
var _multi_tw: Tween
var _cat_box: VBoxContainer
var _cat_bar: ProgressBar
var _rean_box: VBoxContainer
var _rean_txt: Label
var _rean_bar: ProgressBar
var _rean_cor := Color(0, 0, 0, 0)
var _fps: Label
var _abates: Label
var _quedas: Label
var _flash: ColorRect
var _machucado: TextureRect  # borda vermelha com vida baixa
var _golpe: TextureRect  # borda vermelha rápida do golpe forte (Ciclo 2.26)
var _hp_rastro: ProgressBar  # branco atrás da vida: quanto o golpe tirou
var _end_panel: Control
var _end_title: Label
var _end_score: Label
var _big_tween: Tween
var _meu_time := 0
var _score := [0, 0]
## Painel da escolha do caminho (Ciclo 2.22): dois botões, abre com [F] no
## bairro de uma casa no Nv2. Quem confirma é o clique (ou 1/2 no teclado).
var _escolha: PanelContainer
var _escolha_titulo: Label
var _escolha_botoes: Array[Button] = []
var _escolha_of: Oficina
var _escolha_cb: Callable
var _escolha_rodape: Label
var _escolha_n := 2


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_placar(root)
	_build_jogador(root)
	_build_dica(root)

	# Ajuda (canto superior direito; o inferior direito é do minimapa).
	var help := HBoxContainer.new()
	help.add_theme_constant_override("separation", 8)
	help.add_child(Estilo.tecla("Esc", Estilo.T_MIN + 1))
	help.add_child(Estilo.rotulo("pausa e controles", Estilo.T_MIN + 1, Estilo.TEXTO, Estilo.CORPO))
	root.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	help.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# Canto superior esquerdo: abates e quedas do jogador, FPS embaixo.
	var canto := VBoxContainer.new()
	canto.add_theme_constant_override("separation", 6)
	canto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(canto)
	canto.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	var kd := PanelContainer.new()
	kd.add_theme_stylebox_override("panel", Estilo.placa())
	kd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canto.add_child(kd)
	var kd_h := HBoxContainer.new()
	kd_h.add_theme_constant_override("separation", 8)
	kd.add_child(kd_h)
	kd_h.add_child(Icone.novo("katana", Estilo.OURO, 22))
	_abates = Estilo.rotulo("0", Estilo.T_GRANDE, Estilo.TEXTO, Estilo.NUMERO)
	kd_h.add_child(_abates)
	kd_h.add_child(Estilo.rotulo("abates", Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.CORPO))
	var sep := Estilo.rotulo("·", Estilo.T_GRANDE, Estilo.OURO, Estilo.NUMERO)
	kd_h.add_child(sep)
	_quedas = Estilo.rotulo("0", Estilo.T_GRANDE, Estilo.TEXTO, Estilo.NUMERO)
	kd_h.add_child(_quedas)
	kd_h.add_child(Estilo.rotulo("quedas", Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.CORPO))
	for l in kd_h.get_children():
		if l is Label:
			(l as Label).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Contador de FPS (Esc > Configurações > Mostrar FPS).
	_fps = Estilo.rotulo("", Estilo.T_PEQUENO, Estilo.OURO, Estilo.NUMERO)
	canto.add_child(_fps)

	# Mensagem grande: faixa de cima, logo abaixo do placar (o centro é da briga).
	_big = Estilo.aviso("", 50, Estilo.TEXTO)
	_big.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_big.custom_minimum_size = Vector2(1100, 140)
	_big.position = Vector2(-550, 96)
	_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_big.pivot_offset = Vector2(550, 70)
	_big.modulate.a = 0.0
	root.add_child(_big)
	# Letreiro do multikill (Ciclo 2.25, quiz: "letreiro dourado"): embaixo do
	# relógio, só para quem fez. Brilho = sombra dourada larga atrás da letra.
	_multi = Estilo.aviso("", 54, Estilo.OURO_CLARO)
	_multi.label_settings.shadow_color = Color(Estilo.OURO, 0.55)
	_multi.label_settings.shadow_size = 18
	_multi.label_settings.shadow_offset = Vector2.ZERO
	_multi.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_multi.custom_minimum_size = Vector2(800, 70)
	_multi.position = Vector2(-400, 250)
	_multi.pivot_offset = Vector2(400, 35)
	_multi.modulate.a = 0.0
	_multi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_multi)
	_multi_pts = Estilo.aviso("", 26, Estilo.TEXTO)
	_multi_pts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_multi_pts.custom_minimum_size = Vector2(400, 34)
	_multi_pts.position = Vector2(-200, 316)
	_multi_pts.modulate.a = 0.0
	_multi_pts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_multi_pts)

	# Borda "machucado": gradiente radial (centro limpo, cantos vermelho-escuro).
	# Uma textura 256² esticada na tela: custo ~zero, até no navegador.
	var grad := Gradient.new()
	grad.set_color(0, Color(0.55, 0.0, 0.02, 0.0))
	grad.set_color(1, Color(0.45, 0.0, 0.0, 0.9))
	grad.add_point(0.55, Color(0.55, 0.0, 0.02, 0.0))
	grad.add_point(0.8, Color(0.6, 0.02, 0.02, 0.35))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	_machucado = TextureRect.new()
	_machucado.texture = tex
	_machucado.set_anchors_preset(Control.PRESET_FULL_RECT)
	_machucado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_machucado.stretch_mode = TextureRect.STRETCH_SCALE
	_machucado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_machucado.modulate.a = 0.0
	root.add_child(_machucado)
	root.move_child(_machucado, 0)  # embaixo do resto do HUD
	# Golpe forte: a mesma ideia, mais fina e mais viva, só por 0,35 s.
	var g2 := Gradient.new()
	g2.set_color(0, Color(0.9, 0.05, 0.03, 0.0))
	g2.set_color(1, Color(0.8, 0.0, 0.0, 1.0))
	g2.add_point(0.62, Color(0.9, 0.05, 0.03, 0.0))
	g2.add_point(0.85, Color(0.95, 0.1, 0.05, 0.55))
	var tex2 := GradientTexture2D.new()
	tex2.gradient = g2
	tex2.fill = GradientTexture2D.FILL_RADIAL
	tex2.fill_from = Vector2(0.5, 0.5)
	tex2.fill_to = Vector2(1.0, 1.0)
	tex2.width = 256
	tex2.height = 256
	_golpe = TextureRect.new()
	_golpe.texture = tex2
	_golpe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_golpe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_golpe.stretch_mode = TextureRect.STRETCH_SCALE
	_golpe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_golpe.modulate.a = 0.0
	root.add_child(_golpe)
	root.move_child(_golpe, 1)

	# Clarão da tela inteira (poder do jogador). Só um ColorRect: custo ~zero.
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	root.add_child(_flash)

	_build_escolha(root)
	_build_fim(root)


## Golpe forte no jogador (Ciclo 2.26): borda vermelha que acende e some em
## ~0,35 s; k 0..1 = força. A borda puxa um pouco para o lado de onde veio o
## golpe (dir = de quem bateu para o jogador, no mundo; câmera olha para -z).
func golpe_forte(k: float, dir := Vector3.ZERO) -> void:
	if _golpe == null:
		return
	var tela := Vector2(dir.x, dir.z) * 0.04 * k  # centro foge do golpe: o lado de onde veio fica mais vermelho
	_golpe.pivot_offset = _golpe.size * 0.5
	_golpe.scale = Vector2.ONE * (1.06 + 0.04 * k)
	_golpe.position = _golpe.size * tela
	_golpe.modulate.a = maxf(_golpe.modulate.a, 0.45 + 0.5 * k)
	var tw := _golpe.create_tween()
	tw.tween_property(_golpe, "modulate:a", 0.0, 0.35 + 0.15 * k).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(_golpe, "position", Vector2.ZERO, 0.35)


## Clarão rápido na tela (cor com alfa inicial), some em dur segundos.
func flash(color: Color, dur := 0.25) -> void:
	_flash.color = color
	var tw := _flash.create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur).set_ease(Tween.EASE_OUT)


# --- Montagem -------------------------------------------------------------------

func _build_placar(root: Control) -> void:
	# Uma faixa só, colada no topo: máscara azul | placar azul | VS | placar
	# vermelho | máscara vermelha. Antes eram duas linhas descendo pela tela.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 10)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var chips: Array[PanelContainer] = [_chip(0), _chip(1)]
	row.add_child(chips[0])
	for team in 2:
		if team == 1:
			var meio := VBoxContainer.new()
			meio.alignment = BoxContainer.ALIGNMENT_CENTER
			meio.add_theme_constant_override("separation", -4)
			var vs := Estilo.rotulo("VS", 30, Estilo.OURO, Estilo.NUMERO)
			vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vs.custom_minimum_size = Vector2(86, 0)
			meio.add_child(vs)
			_relogio = vs
			var meta := Estilo.rotulo("até %d" % Config.cfg.score_to_win, Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.CORPO)
			meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			meio.add_child(meta)
			_relogio_meta = meta
			row.add_child(meio)
		row.add_child(_placa(team))
	row.add_child(chips[1])


## Placa de um time: nome + losangos de pontos + número grande.
func _placa(team: int) -> PanelContainer:
	var c := Estilo.cor_time(team)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.placa(Color(c.darkened(0.72), 0.95)))
	p.custom_minimum_size = Vector2(200, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
	p.add_child(h)
	var nome := VBoxContainer.new()
	nome.alignment = BoxContainer.ALIGNMENT_CENTER
	nome.add_theme_constant_override("separation", 2)
	var titulo := Estilo.rotulo(Config.TEAM_NAMES[team].to_upper(), 24, c, Estilo.NUMERO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if team == 0 else HORIZONTAL_ALIGNMENT_LEFT
	nome.add_child(titulo)
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
	pips.add_theme_constant_override("separation", 3)
	for k in Config.cfg.score_to_win:
		var i := Icone.novo("losango", c, 16)
		i.cheio = false
		pips.add_child(i)
		_pips[team].append(i)
	nome.add_child(pips)
	var num := Estilo.titulo("0", 54, Estilo.TEXTO)
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
	var c := Estilo.cor_time(team)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.placa())
	p.custom_minimum_size = Vector2(250, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(Icone.novo("mascara", c, 34))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var dono := Estilo.rotulo("", Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.espacada(Estilo.CORPO, 2), 3)
	dono.name = "Dono"
	v.add_child(dono)
	_chip_dono.append(dono)
	var estado := Estilo.rotulo("", 20, Estilo.TEXTO, Estilo.NUMERO)
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
	card.add_theme_stylebox_override("panel", Estilo.placa())
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
	_class_label = Estilo.rotulo("Recruta", Estilo.T_GRANDE + 2, Estilo.TEXTO, Estilo.TITULO)
	v.add_child(_class_label)
	_status_label = Estilo.rotulo("", Estilo.T_PEQUENO + 1, Estilo.FANTASMA, Estilo.NUMERO)
	v.add_child(_status_label)
	# Rastro (Ciclo 2.26): uma barra branca por baixo; a de vida vai por cima
	# com fundo vazio, então o branco aparece só no pedaço que o golpe tirou.
	_hp_rastro = Estilo.barra(Color(1.0, 0.96, 0.88), Vector2(300, 22))
	v.add_child(_hp_rastro)
	_hp_bar = Estilo.barra(Estilo.AZUL, Vector2(300, 22))
	_hp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_rastro.add_child(_hp_bar)
	_hp_text = Estilo.rotulo("", 17, Estilo.TEXTO, Estilo.NUMERO, 4)
	_hp_text.label_settings.shadow_offset = Vector2(0, 1)
	_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_text)
	var chi_row := HBoxContainer.new()
	chi_row.add_theme_constant_override("separation", 8)
	v.add_child(chi_row)
	# Medidor de Chi: enche lutando; cheio libera o poder no E.
	_power_bar = Estilo.barra(Estilo.FANTASMA, Vector2(170, 10))
	_power_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chi_row.add_child(_power_bar)
	_power_key = Estilo.tecla("E", Estilo.T_PEQUENO + 2)
	chi_row.add_child(_power_key)
	_power_label = Estilo.rotulo("", Estilo.T_PEQUENO, Estilo.TEXTO, Estilo.NUMERO)
	chi_row.add_child(_power_label)
	# Super (R): barra dourada que só enche jogando bem.
	_super_row = HBoxContainer.new()
	_super_row.add_theme_constant_override("separation", 8)
	v.add_child(_super_row)
	_super_bar = Estilo.barra(Estilo.OURO, Vector2(170, 10))
	_super_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_super_row.add_child(_super_bar)
	_super_key = Estilo.tecla("R", Estilo.T_PEQUENO + 2)
	_super_row.add_child(_super_key)
	_super_label = Estilo.rotulo("", Estilo.T_PEQUENO, Estilo.TEXTO, Estilo.NUMERO)
	_super_row.add_child(_super_label)
	# Habilidade rápida (Q): barra de recarga + nome / segundos que faltam.
	_quick_row = HBoxContainer.new()
	_quick_row.add_theme_constant_override("separation", 8)
	v.add_child(_quick_row)
	_quick_bar = Estilo.barra(Estilo.OURO, Vector2(170, 8))
	_quick_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_quick_row.add_child(_quick_bar)
	_quick_row.add_child(Estilo.tecla("Q", Estilo.T_PEQUENO + 2))
	_quick_label = Estilo.rotulo("", Estilo.T_PEQUENO, Estilo.OURO, Estilo.NUMERO)
	_quick_row.add_child(_quick_label)

	# Estoque de madeira do time (o que o Construtor trouxe para o depósito).
	var mad_row := HBoxContainer.new()
	mad_row.add_theme_constant_override("separation", 6)
	v.add_child(mad_row)
	var ic := TextureRect.new()
	ic.texture = preload("res://assets/ui/icone_tora.png")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(26, 20)
	mad_row.add_child(ic)
	_madeira_label = Estilo.rotulo("", Estilo.T_PEQUENO, Estilo.OURO, Estilo.NUMERO)
	mad_row.add_child(_madeira_label)
	_madeira_label.pivot_offset = Vector2(0, 10)
	_carregando_label = Estilo.rotulo("CARREGANDO 1/1", Estilo.T_PEQUENO, Estilo.TEXTO, Estilo.NUMERO)
	_carregando_label.visible = false
	mad_row.add_child(_carregando_label)

	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_dica(root: Control) -> void:
	_hint_box = PanelContainer.new()
	_hint_box.add_theme_stylebox_override("panel", Estilo.placa())
	_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hint_box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	_hint_box.add_child(h)
	_hint_a = Estilo.rotulo("", Estilo.T_MEDIO + 1, Estilo.TEXTO, Estilo.CORPO)
	_hint_key = Estilo.tecla("F", Estilo.T_MEDIO - 1)
	_hint_b = Estilo.rotulo("", Estilo.T_MEDIO + 1, Estilo.TEXTO, Estilo.CORPO)
	h.add_child(_hint_a)
	h.add_child(_hint_key)
	h.add_child(_hint_b)
	_hint_box.visible = false
	_hint_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 22)
	_hint_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_box.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_escolha(root: Control) -> void:
	_escolha = PanelContainer.new()
	_escolha.add_theme_stylebox_override("panel", Estilo.placa(Color(Estilo.LACA, 0.96), Estilo.OURO, 14))
	_escolha.visible = false
	root.add_child(_escolha)
	var m := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 14)
	_escolha.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	_escolha_titulo = Estilo.rotulo("", Estilo.T_GRANDE, Estilo.OURO, Estilo.TITULO)
	_escolha_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_escolha_titulo)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	for i in 4:  # Ciclo 2.23: até 4 opções (caminhos = 2, heróis = 2 ou 3)
		var b := Button.new()
		b.custom_minimum_size = Vector2(330, 176)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_escolheu.bind(i))
		h.add_child(b)
		_escolha_botoes.append(b)
	var rodape := HBoxContainer.new()
	rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	rodape.add_theme_constant_override("separation", 8)
	_escolha_rodape = Estilo.rotulo("Clique num caminho (ou 1 / 2). O outro fica selado até o fim.", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, Estilo.CORPO)
	rodape.add_child(_escolha_rodape)
	rodape.add_child(Estilo.tecla("F", Estilo.T_PEQUENO))
	rodape.add_child(Estilo.rotulo("fecha", Estilo.T_PEQUENO, Estilo.TEXTO, Estilo.CORPO))
	v.add_child(rodape)
	_escolha.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 96)
	_escolha.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_escolha.grow_vertical = Control.GROW_DIRECTION_BEGIN


## Abre o painel com os dois caminhos da casa `of` (ou, com heroi = true, os
## heróis raros do Nv6, Ciclo 2.23); `cb(i)` recebe o escolhido.
func abrir_escolha(of: Oficina, cb: Callable, heroi := false) -> void:
	_escolha_of = of
	_escolha_cb = cb
	var cs: Array[ClassStats] = of.herois() if heroi else of.caminhos()
	_escolha_n = mini(cs.size(), _escolha_botoes.size())
	if heroi:
		_escolha_titulo.text = "Nível 6 de %s: escolha o herói raro" % of.base.display_name
		var teclas := " / ".join(range(1, _escolha_n + 1).map(func(k): return str(k)))
		_escolha_rodape.text = "Clique num herói (ou %s). Um chapéu só no pavilhão: volta 20 s depois que o herói sai de campo." % teclas
	else:
		_escolha_titulo.text = "Casa de %s: escolha o caminho" % of.base.display_name
		_escolha_rodape.text = "Clique num caminho (ou 1 / 2). O outro fica selado até o fim."
	for i in _escolha_botoes.size():
		_escolha_botoes[i].visible = i < _escolha_n
	for i in _escolha_n:
		var b := _escolha_botoes[i]
		b.custom_minimum_size = Vector2(300 if _escolha_n >= 3 else 330, 196 if heroi else 176)
		for c in b.get_children():
			c.queue_free()
		var cls: ClassStats = cs[i]
		var cor := cls.hat_color.lightened(0.15)
		b.add_theme_stylebox_override("normal", Estilo.placa(Color(Estilo.LACA, 0.95), cor.darkened(0.25), 12))
		b.add_theme_stylebox_override("hover", Estilo.placa(Color(cor.darkened(0.7), 0.97), cor, 12))
		b.add_theme_stylebox_override("pressed", Estilo.placa(Color(cor.darkened(0.55), 0.97), Estilo.OURO, 12))
		var mc := MarginContainer.new()
		mc.set_anchors_preset(Control.PRESET_FULL_RECT)
		mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for lado in ["left", "right", "top", "bottom"]:
			mc.add_theme_constant_override("margin_" + lado, 12)
		b.add_child(mc)
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_theme_constant_override("separation", 4)
		mc.add_child(col)
		var topo := HBoxContainer.new()
		topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		topo.add_theme_constant_override("separation", 8)
		topo.add_child(Estilo.tecla(str(i + 1), Estilo.T_PEQUENO))
		var nome := Estilo.rotulo(cls.display_name, Estilo.T_GRANDE, cor, Estilo.TITULO)
		topo.add_child(nome)
		col.add_child(topo)
		var linhas := [cls.caminho_nome.to_upper() if cls.caminho_nome != "" else "", cls.epiteto,
				"Q: %s" % cls.skill_name if cls.skill_name != "" else "",
				"E: %s" % cls.power_name if cls.power_name != "" else ""]
		if heroi:
			linhas = ["★ HERÓI RARO", cls.epiteto, cls.estilo_linha,
					"Q: %s  ·  E: %s" % [cls.skill_name, cls.power_name],
					"R: %s" % (cls.super_nome if cls.super_nome != "" else "Super " + cls.power_name)]
		for k in linhas.size():
			if linhas[k] == "":
				continue
			var l := Estilo.rotulo(linhas[k], Estilo.T_PEQUENO if k > 0 else Estilo.T_MIN, Estilo.TEXTO if k > 0 else cor, Estilo.CORPO)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = 270 if _escolha_n >= 3 else 300
			col.add_child(l)
		for n in [mc, col, topo] + col.get_children() + topo.get_children():
			if n is Control:
				(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escolha.visible = true


func fechar_escolha() -> void:
	_escolha.visible = false
	_escolha_of = null


func escolha_aberta() -> Oficina:
	return _escolha_of if _escolha.visible else null


func _escolheu(i: int) -> void:
	if not _escolha.visible:
		return
	var cb := _escolha_cb
	fechar_escolha()
	if cb.is_valid():
		cb.call(i)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _escolha.visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).keycode
	for i in _escolha_n:
		if k == KEY_1 + i or k == KEY_KP_1 + i:
			_escolheu(i)
			get_viewport().set_input_as_handled()
			return


func _build_fim(root: Control) -> void:
	_end_panel = ColorRect.new()
	_end_panel.color = Color(Estilo.TINTA, 0.78)
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
	_end_title = Estilo.titulo("", Estilo.T_GIGANTE, Estilo.OURO)
	v.add_child(_end_title)
	v.add_child(Estilo.ornamento(460.0))
	_end_score = Estilo.rotulo("", 36, Estilo.TEXTO, Estilo.NUMERO)
	_end_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_end_score)
	var again := HBoxContainer.new()
	again.alignment = BoxContainer.ALIGNMENT_CENTER
	again.add_theme_constant_override("separation", 10)
	again.add_child(Estilo.tecla("R", 24))
	again.add_child(Estilo.rotulo("jogar de novo", 24, Estilo.TEXTO, Estilo.CORPO))
	v.add_child(again)


# --- Atualização ------------------------------------------------------------------

func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS · %.1f ms" % [Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1.0)]


## Relógio regressivo (Ciclo 2.23): "9:59"; no último minuto fica vermelho e
## pulsa; na prorrogação mostra "+0:12" e "PRORROGAÇÃO"; na morte súbita, o tempo
## dela e "MORTE SÚBITA". Sem relógio (modo teste) = "VS".
func _atualizar_relogio(game: Game, pulso: float) -> void:
	if _relogio == null:
		return
	var resta := game.tempo_restante()
	if resta == INF and game.morte_subita < 0.0:
		_relogio.text = "VS"
		_relogio_meta.text = "até %d" % Config.cfg.score_to_win
		return
	var cor := Estilo.OURO
	if game.morte_subita >= 0.0:
		var m := int(ceil(game.morte_subita_resta()))
		_relogio.text = "%d:%02d" % [m / 60, m % 60]
		_relogio_meta.text = "MORTE SÚBITA"
		cor = Estilo.PERIGO.lerp(Estilo.OURO_CLARO, pulso)
	elif game.prorrogacao >= 0.0:
		var p := int(game.prorrogacao)
		_relogio.text = "+%d:%02d" % [p / 60, p % 60]
		_relogio_meta.text = "PRORROGAÇÃO"
		cor = Estilo.PERIGO.lerp(Estilo.OURO_CLARO, pulso)
	else:
		var s := int(ceil(resta))
		_relogio.text = "%d:%02d" % [s / 60, s % 60]
		_relogio_meta.text = "até %d pontos" % Config.cfg.score_to_win
		if resta <= 60.0:
			cor = Estilo.PERIGO.lerp(Estilo.OURO_CLARO, pulso * 0.6)
	_cor_texto(_relogio, cor)


func update_state(game: Game) -> void:
	var u := game.player
	_meu_time = u.team
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	_atualizar_relogio(game, pulso)
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
		var dono := _chip_dono[team]
		dono.text = "SUA MÁSCARA" if minha else "MÁSCARA INIMIGA"
		var txt := ""
		var cor := Estilo.TEXTO
		match p.state:
			Princess.State.HOME:
				txt = "No castelo" if minha else "No castelo deles"
				cor = Estilo.TEXTO_FRACO
			Princess.State.CARRIED:
				txt = "ROUBADA!" if minha else "Com o seu time!"
				cor = Estilo.PERIGO if minha else Estilo.CIANO
			_:
				txt = "Caída no chão!"
				cor = Estilo.OURO
		_chip_estado[team].text = txt
		_cor_texto(_chip_estado[team], cor)
		_chips[team].modulate = Color(1, 1, 1).lerp(Color(1.5, 1.3, 1.3), pulso) if p.state == Princess.State.CARRIED else Color.WHITE
		_peso[team].value = p.fatness * 100.0

	# Cartão do jogador.
	var time_cor := Estilo.cor_time(u.team)
	if _abates.text != str(game.abates_jogador):
		_abates.text = str(game.abates_jogador)
	if _quedas.text != str(game.quedas_jogador):
		_quedas.text = str(game.quedas_jogador)
	var disco: StyleBoxFlat = _retrato.get_theme_stylebox("panel")
	if disco.bg_color != u.stats.hat_color.darkened(0.55):  # mexer no StyleBox redesenha o painel
		disco.bg_color = u.stats.hat_color.darkened(0.55)
		disco.border_color = Estilo.OURO
	_icone_papel.mudar(Icone.do_papel(u.stats), u.stats.hat_color.lightened(0.35))
	_class_label.text = u.stats.display_name if u.alive else ("Caído" if game.reanimar and game.reanimar.pode_reanimar(u) else "Renascendo...")
	var ratio := u.hp_ratio()
	_hp_bar.value = ratio * 100.0
	_hp_rastro.value = maxf(u.hp_rastro, ratio) * 100.0 if u.alive else 0.0
	_hp_text.text = "%d / %d" % [ceili(u.hp), int(u.max_hp())] if u.alive else ""
	var baixa := Config.cfg.vida_baixa_frac
	Estilo.cor_barra(_hp_bar, time_cor if ratio > baixa else Estilo.PERIGO.lerp(Color.WHITE, pulso * 0.4))
	# Borda vermelha: cresce conforme a vida cai abaixo de vida_baixa_frac e
	# pulsa como batimento (mais rápido quanto menos vida).
	var alvo := 0.0
	if u.alive and ratio < baixa:
		var k := 1.0 - ratio / maxf(baixa, 0.01)
		var bat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * (0.006 + 0.008 * k))
		alvo = 0.45 + 0.4 * k + 0.15 * bat
	_machucado.modulate.a = move_toward(_machucado.modulate.a, alvo, 0.08)
	_power_bar.value = u.power
	var tem_poder := u.stats.power != "nenhum"
	_power_bar.visible = tem_poder
	if u.power_ready():
		_power_bar.modulate = Color(1, 1, 1).lerp(Color(1.7, 1.5, 1.7), pulso)
		_power_key.visible = true
		_power_key.modulate = Color.WHITE
		_power_label.text = u.stats.power_name + "!"
		_cor_texto(_power_label, Estilo.FANTASMA)
	else:
		_power_bar.modulate = Color(1, 1, 1, 0.85)
		_power_key.visible = tem_poder
		_power_key.modulate = Color(1, 1, 1, 0.4)  # apagada: mostra qual tecla, sem chamar
		_power_label.text = "Chi %d%%" % int(u.power) if tem_poder else ""
		_cor_texto(_power_label, Estilo.TEXTO)
	_super_row.visible = tem_poder
	_super_bar.value = u.super_carga
	if u.super_ready():
		_super_bar.modulate = Color(1, 1, 1).lerp(Color(1.8, 1.6, 1.1), pulso)
		_super_key.modulate = Color.WHITE
		_super_label.text = u.super_nome() + "!"
		_cor_texto(_super_label, Estilo.OURO)
	else:
		_super_bar.modulate = Color(1, 1, 1, 0.85)
		_super_key.modulate = Color(1, 1, 1, 0.4)
		if u.super_travado():
			# Ciclo 2.22: casa da classe no Nv1 = R travado (a barra enche igual).
			_super_label.text = "Super travado: casa no Nv1"
			_cor_texto(_super_label, Estilo.TEXTO_FRACO)
		else:
			_super_label.text = "Super %d%%" % int(u.super_carga)
			_cor_texto(_super_label, Estilo.TEXTO)
	_quick_row.visible = u.tem_rapida()
	if _quick_row.visible:
		_quick_bar.value = u.quick_ratio() * 100.0
		if u.quick_ready():
			_quick_label.text = u.stats.skill_name.to_upper()
			_quick_row.modulate = Color.WHITE
		else:
			_quick_label.text = "%.1f s" % u.quick_restante()
			_quick_row.modulate = Color(1, 1, 1, 0.6)
	var mad: int = game.madeira[u.team] if u.team < game.madeira.size() else 0
	if mad != _madeira_visto:
		if mad > _madeira_visto and _madeira_visto >= 0:
			_madeira_label.scale = Vector2.ONE * 1.3
			_madeira_label.create_tween().tween_property(_madeira_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		_madeira_visto = mad
		_madeira_label.text = "Madeira do time: ∞ (modo teste)" if game.sandbox else "Madeira do time: %d" % mad
	var com_tora := u.carried_tora != null
	if com_tora != _carregando_label.visible:
		_carregando_label.visible = com_tora
		if com_tora:
			_carregando_label.pivot_offset = Vector2(0, 10)
			_carregando_label.scale = Vector2.ONE * 1.3
			_carregando_label.create_tween().tween_property(_carregando_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if u.carried_tora:
		_status_label.text = "LEVE A TORA AO DEPÓSITO"
		_cor_texto(_status_label, Estilo.OURO)
	elif u.carried_princess:
		var esc := u.escolta_bonus()
		_status_label.text = "LEVE A MÁSCARA PARA CASA" if esc <= 0.0 \
				else "LEVE A MÁSCARA PARA CASA  ·  ESCOLTA +%d%%" % int(round(esc * 100.0))
		_cor_texto(_status_label, Estilo.OURO)
	elif u.has_cake:
		_status_label.text = "LEVE O ESPÍRITO À SUA MÁSCARA"
		_cor_texto(_status_label, Estilo.FANTASMA)
	else:
		_status_label.text = ""
	_status_label.visible = _status_label.text != ""


## Trocar a cor do LabelSettings refaz o texto do Label; só troca se mudou.
func _cor_texto(l: Label, cor: Color) -> void:
	if l.label_settings.font_color != cor:
		l.label_settings.font_color = cor


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


## Barra de força da catapulta (0..1) no centro, embaixo do aviso; < 0 esconde.
func catapulta_forca(frac: float) -> void:
	if _cat_box == null:
		_cat_box = VBoxContainer.new()
		_cat_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_cat_box.position = Vector2(-150, -150)
		_cat_box.custom_minimum_size = Vector2(300, 0)
		_cat_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cat_box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(_cat_box)
		var r := Estilo.rotulo("FORÇA  ·  [F] lançar", Estilo.T_PEQUENO + 2, Estilo.OURO, Estilo.LETREIRO)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cat_box.add_child(r)
		_cat_bar = Estilo.barra(Estilo.OURO, Vector2(300, 16))
		_cat_box.add_child(_cat_bar)
	_cat_box.visible = frac >= 0.0
	if frac >= 0.0:
		_cat_bar.value = frac * 100.0
		Estilo.cor_barra(_cat_bar, Estilo.OURO.lerp(Color(1, 0.35, 0.2), frac))


## Barra da reanimação (Ciclo 2.18), acima do aviso: caído (espera/sendo
## reanimado) ou reanimando alguém. frac < 0 esconde.
func reanimar_barra(frac: float, texto: String, cor: Color) -> void:
	if _rean_box == null:
		if frac < 0.0:
			return
		_rean_box = VBoxContainer.new()
		_rean_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_rean_box.position = Vector2(-200, -205)
		_rean_box.custom_minimum_size = Vector2(400, 0)
		_rean_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rean_box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(_rean_box)
		_rean_txt = Estilo.rotulo("", Estilo.T_PEQUENO + 2, Estilo.OURO, Estilo.LETREIRO)
		_rean_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rean_box.add_child(_rean_txt)
		_rean_bar = Estilo.barra(Estilo.OURO, Vector2(400, 14))
		_rean_box.add_child(_rean_bar)
	_rean_box.visible = frac >= 0.0
	if frac < 0.0:
		return
	if _rean_txt.text != texto:
		_rean_txt.text = texto
	_rean_bar.value = clampf(frac, 0.0, 1.0) * 100.0
	if _rean_cor != cor:
		_rean_cor = cor
		Estilo.cor_barra(_rean_bar, cor)
		_cor_texto(_rean_txt, cor)


## Multikill do jogador: o letreiro bate grande e assenta; cada degrau sai um
## pouco maior. Some em ~1,5 s.
func multikill(nome: String, bonus: int, degrau: int) -> void:
	_multi.text = nome + "!"
	_multi_pts.text = "+%d pts" % bonus
	if _multi_tw:
		_multi_tw.kill()
	var alvo := Vector2.ONE * (1.0 + 0.08 * mini(degrau - 2, 3))
	_multi.scale = alvo * 1.8
	_multi.modulate.a = 1.0
	_multi_pts.modulate.a = 0.0
	_multi_tw = create_tween()
	_multi_tw.tween_property(_multi, "scale", alvo, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_multi_tw.parallel().tween_property(_multi_pts, "modulate:a", 1.0, 0.18).set_delay(0.08)
	_multi_tw.tween_interval(1.1)
	_multi_tw.tween_property(_multi, "modulate:a", 0.0, 0.35)
	_multi_tw.parallel().tween_property(_multi_pts, "modulate:a", 0.0, 0.35)


func show_big(text: String, color := Color.WHITE, duration := 2.2) -> void:
	_big.text = text.to_upper()
	var ls := _big.label_settings
	ls.font_color = color
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
	_end_title.text = "Vitória!" if won else "Derrota..."
	_end_title.label_settings.font_color = cor
	_end_score.text = "AZUL   %d  ×  %d   VERMELHO" % [_score[0], _score[1]]
