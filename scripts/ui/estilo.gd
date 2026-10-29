class_name Estilo
extends RefCounted
## Identidade visual da interface (Clãs de Neon): fontes, cores e peças
## reaproveitadas pelo HUD e pelos menus. Tudo estático: Estilo.rotulo(...).
## Fontes livres (OFL) em assets/fonts: Shojumaru (títulos, pincel japonês)
## e Chakra Petch (texto, cara de painel neon).

const TITULO := preload("res://assets/fonts/Shojumaru-Regular.ttf")
const CORPO := preload("res://assets/fonts/ChakraPetch-Medium.ttf")
const FORTE := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

const NOITE := Color(0.035, 0.03, 0.08)
const PAINEL := Color(0.055, 0.045, 0.12, 0.9)
const CIANO := Color(0.3, 0.95, 1.0)
const MAGENTA := Color(1.0, 0.32, 0.7)
const OURO := Color(1.0, 0.82, 0.36)
const FANTASMA := Color(0.45, 1.0, 0.62)  # fogo-fantasma (espíritos, chi pronto)
const PERIGO := Color(1.0, 0.36, 0.36)
const TEXTO := Color(0.94, 0.93, 1.0)
const TEXTO_FRACO := Color(0.72, 0.7, 0.86)

## Inclinação dos painéis e botões: dá o ar de "corte de lâmina".
const INCLINA := Vector2(0.22, 0.0)

static var _tema: Theme


static func rotulo(text: String, size: int, color := TEXTO, fonte: Font = CORPO, contorno := -1) -> Label:
	var l := Label.new()
	l.text = text
	l.label_settings = ajustes(size, color, fonte, contorno)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func ajustes(size: int, color := TEXTO, fonte: Font = CORPO, contorno := -1) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = fonte
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = contorno if contorno >= 0 else maxi(4, size / 6)
	ls.outline_color = Color(0.02, 0.01, 0.05, 0.9)
	ls.shadow_size = 3
	ls.shadow_color = Color(0, 0, 0, 0.45)
	ls.shadow_offset = Vector2(0, 2)
	return ls


## Título com brilho neon: contorno grosso escuro + "aura" colorida na sombra.
static func titulo(text: String, size: int, color: Color) -> Label:
	var l := rotulo(text, size, color, TITULO, maxi(8, size / 7))
	l.label_settings.outline_color = color.darkened(0.78)
	l.label_settings.shadow_color = Color(color, 0.55)
	l.label_settings.shadow_size = maxi(8, size / 5)
	l.label_settings.shadow_offset = Vector2.ZERO
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Painel escuro com borda neon. `inclinado` corta as laterais em diagonal.
static func painel(borda: Color, inclinado := false, fundo := PAINEL, raio := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.border_color = borda
	sb.set_border_width_all(2)
	sb.border_width_bottom = 3
	sb.set_corner_radius_all(raio)
	sb.shadow_color = Color(borda, 0.22)
	sb.shadow_size = 8
	sb.anti_aliasing = true
	if inclinado:
		sb.skew = INCLINA
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


## Tecla desenhada (ex.: [E]) para dicas e lista de controles.
static func tecla(text: String, size := 18) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.11, 0.22, 0.95)
	sb.border_color = OURO
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # não esticar em linha alta
	p.add_child(rotulo(text, size, OURO, FORTE, 0))
	return p


## Barra (vida, chi, peso) com fundo escuro e brilho na cor do preenchimento.
static func barra(color: Color, tamanho: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 100.0
	b.custom_minimum_size = tamanho
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.02, 0.05, 0.8)
	bg.border_color = Color(color, 0.45)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	bg.skew = INCLINA
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(3)
	fg.skew = INCLINA
	fg.shadow_color = Color(color, 0.5)
	fg.shadow_size = 5
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


static func cor_barra(b: ProgressBar, color: Color) -> void:
	var fg: StyleBoxFlat = b.get_theme_stylebox("fill")
	fg.bg_color = color
	fg.shadow_color = Color(color, 0.5)


## Tema dos menus: botões, abas, listas, controles deslizantes.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = CORPO
	t.default_font_size = 19

	var normal := painel(Color(CIANO, 0.55), true, Color(0.08, 0.07, 0.16, 0.95))
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	var hover := painel(MAGENTA, true, Color(0.17, 0.07, 0.2, 0.98))
	hover.content_margin_left = 22
	hover.content_margin_right = 22
	hover.shadow_size = 14
	hover.shadow_color = Color(MAGENTA, 0.4)
	var pressed := hover.duplicate()
	pressed.bg_color = Color(MAGENTA, 0.45)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = OURO
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(4)
	focus.skew = INCLINA
	focus.set_expand_margin_all(3)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("focus", type, focus)
		t.set_color("font_color", type, TEXTO)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, TEXTO)
		t.set_font("font", type, FORTE)
	t.set_font_size("font_size", "Button", 21)
	t.set_font_size("font_size", "OptionButton", 18)

	# CheckButton: sem caixa, só o interruptor (ícone padrão, tingido).
	var vazio := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(s, "CheckButton", vazio)
	t.set_color("icon_normal_color", "CheckButton", Color(1.6, 1.5, 2.0))  # desligado ainda visível
	t.set_color("icon_pressed_color", "CheckButton", CIANO)
	t.set_color("icon_hover_color", "CheckButton", MAGENTA)
	t.set_color("icon_hover_pressed_color", "CheckButton", MAGENTA)

	# Lista que abre no OptionButton.
	var popup := painel(CIANO, false, Color(0.05, 0.04, 0.11, 0.98))
	t.set_stylebox("panel", "PopupMenu", popup)
	var pop_hover := StyleBoxFlat.new()
	pop_hover.bg_color = Color(MAGENTA, 0.35)
	pop_hover.set_corner_radius_all(3)
	t.set_stylebox("hover", "PopupMenu", pop_hover)
	t.set_color("font_color", "PopupMenu", TEXTO)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_font("font", "PopupMenu", CORPO)
	t.set_font_size("font_size", "PopupMenu", 18)

	# Abas.
	var aba := StyleBoxFlat.new()
	aba.bg_color = Color(0.08, 0.07, 0.16, 0.9)
	aba.set_corner_radius_all(3)
	aba.skew = INCLINA
	aba.content_margin_left = 22
	aba.content_margin_right = 22
	aba.content_margin_top = 6
	aba.content_margin_bottom = 6
	var aba_sel := aba.duplicate()
	aba_sel.bg_color = Color(0.2, 0.08, 0.24, 1.0)
	aba_sel.border_color = MAGENTA
	aba_sel.border_width_bottom = 3
	var aba_hover := aba.duplicate()
	aba_hover.bg_color = Color(0.14, 0.1, 0.24, 1.0)
	t.set_stylebox("tab_unselected", "TabContainer", aba)
	t.set_stylebox("tab_selected", "TabContainer", aba_sel)
	t.set_stylebox("tab_hovered", "TabContainer", aba_hover)
	t.set_stylebox("tab_focus", "TabContainer", focus)
	var corpo := StyleBoxFlat.new()
	corpo.bg_color = Color(0.03, 0.025, 0.07, 0.6)
	corpo.border_color = Color(MAGENTA, 0.35)
	corpo.border_width_top = 2
	corpo.set_corner_radius_all(4)
	t.set_stylebox("panel", "TabContainer", corpo)
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", TEXTO_FRACO)
	t.set_color("font_hovered_color", "TabContainer", TEXTO)
	t.set_font("font", "TabContainer", FORTE)
	t.set_font_size("font_size", "TabContainer", 19)

	# Controle deslizante: trilho fino e preenchimento ciano.
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color(0.12, 0.1, 0.22)
	trilho.set_corner_radius_all(3)
	trilho.content_margin_top = 3
	trilho.content_margin_bottom = 3
	var cheio := trilho.duplicate()
	cheio.bg_color = CIANO
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", cheio)
	t.set_stylebox("grabber_area_highlight", "HSlider", cheio)

	t.set_font("font", "Label", CORPO)
	t.set_color("font_color", "Label", TEXTO)
	t.set_font("font", "TooltipLabel", CORPO)
	_tema = t
	return t
