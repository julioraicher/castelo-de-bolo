class_name Estilo
extends RefCounted
## Identidade visual da interface: fontes, cores e peças reaproveitadas pelo
## HUD e pelos menus. Tudo estático: Estilo.rotulo(...).
## Ciclo 2.4 ("tela mais moderna"): vidro escuro com cantos arredondados,
## borda fina, sombra macia e destaque dourado.
## Ciclo 2.4n ("letras encorpadas"): saiu a Chakra Petch (cara de painel neon,
## sobra dos Clãs de Neon). Fontes livres (OFL) em assets/fonts:
##   TITULO  Shojumaru: pincel japonês. Só títulos curtos (nome do jogo,
##           Pausado, Vitória, nome da classe, nome do golpe). Nunca frase.
##   FORTE   Barlow Condensed Bold: botões, rótulos, dicas, avisos.
##   NUMERO  Barlow Condensed ExtraBold: placar, contadores e avisos grandes.
##   CORPO   Barlow Semi Condensed Medium: texto corrido.
## Escala de tamanhos (px na tela-base 1600x900): use as constantes T_*.
## Nada abaixo de T_MIN: no navegador em tela pequena some.

const TITULO := preload("res://assets/fonts/Shojumaru-Regular.ttf")
const CORPO := preload("res://assets/fonts/BarlowSemiCondensed-Medium.ttf")
const FORTE := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
const NUMERO := preload("res://assets/fonts/BarlowCondensed-ExtraBold.ttf")

const T_GIGANTE := 110  # fim de partida
const T_TITULO := 56    # título de tela / aviso grande
const T_GRANDE := 28    # nome da classe, placar secundário
const T_MEDIO := 22     # botões, dicas, cabeçalhos de cartão
const T_TEXTO := 20     # texto corrido
const T_PEQUENO := 17   # rótulos de apoio
const T_MIN := 15

const NOITE := Color(0.035, 0.03, 0.08)
const PAINEL := Color(0.045, 0.04, 0.055, 0.74)
const CIANO := Color(0.45, 0.88, 0.95)  # aliado / ligado (menos neon)
const MAGENTA := Color(1.0, 0.32, 0.7)
const OURO := Color(1.0, 0.82, 0.36)
const FANTASMA := Color(0.45, 1.0, 0.62)  # fogo-fantasma (espíritos, chi pronto)
const PERIGO := Color(1.0, 0.36, 0.36)
const TEXTO := Color(0.97, 0.93, 0.85)       # papel de arroz (antes branco-azulado neon)
const TEXTO_FRACO := Color(0.78, 0.72, 0.63)  # tinta lavada
const TINTA := Color(0.05, 0.035, 0.03)       # contorno: tinta sumi, não preto-azulado

## Inclinação dos painéis e botões (0 = reto; era 0,22 no "corte de lâmina").
const INCLINA := Vector2(0.0, 0.0)
## Raio dos cantos: painéis e botões arredondados.
const RAIO := 10

static var _tema: Theme
static var _espacadas := {}


## Versão da fonte com espaço extra entre letras (subtítulos e rótulos em
## caixa alta: "A GUERRA DA MÁSCARA ONI", "SUA MÁSCARA").
static func espacada(fonte: Font, px := 3) -> FontVariation:
	var k := "%s:%d" % [fonte.resource_path, px]
	if not _espacadas.has(k):
		var fv := FontVariation.new()
		fv.base_font = fonte
		fv.spacing_glyph = px
		_espacadas[k] = fv
	return _espacadas[k]


static func rotulo(text: String, size: int, color := TEXTO, fonte: Font = CORPO, contorno := -1) -> Label:
	var l := Label.new()
	l.text = text
	l.label_settings = ajustes(size, color, fonte, contorno)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func ajustes(size: int, color := TEXTO, fonte: Font = CORPO, contorno := -1) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = fonte
	ls.font_size = maxi(size, T_MIN)
	ls.font_color = color
	ls.outline_size = contorno if contorno >= 0 else maxi(3, size / 8)
	ls.outline_color = Color(TINTA, 0.9)
	ls.shadow_size = 4
	ls.shadow_color = Color(0, 0, 0, 0.35)
	ls.shadow_offset = Vector2(0, 2)
	return ls


## Título de pincel: contorno grosso de tinta + aura colorida na sombra.
static func titulo(text: String, size: int, color: Color) -> Label:
	var l := rotulo(text, size, color, TITULO, maxi(8, size / 7))
	l.label_settings.outline_color = color.darkened(0.78)
	l.label_settings.shadow_color = Color(color, 0.55)
	l.label_settings.shadow_size = maxi(8, size / 5)
	l.label_settings.shadow_offset = Vector2.ZERO
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Aviso grande (meio da tela): letra larga e grossa, legível em frase de duas
## linhas (a Shojumaru embola). Contorno de tinta + aura na cor.
static func aviso(text: String, size: int, color: Color) -> Label:
	var l := rotulo(text.to_upper(), size, color, NUMERO, maxi(8, size / 6))
	l.label_settings.outline_color = Color(TINTA, 0.95)
	l.label_settings.shadow_color = Color(color, 0.45)
	l.label_settings.shadow_size = maxi(10, size / 4)
	l.label_settings.shadow_offset = Vector2.ZERO
	l.label_settings.line_spacing = -size * 0.12
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Filete dourado com losango no meio, embaixo de títulos (cara de pergaminho).
static func ornamento(largura := 360.0, cor := OURO) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(largura, 14)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var w := c.size.x
		var y := c.size.y * 0.5
		var m := w * 0.5
		c.draw_polyline_colors(PackedVector2Array([Vector2(0, y), Vector2(m - 14, y)]), PackedColorArray([Color(cor, 0.0), Color(cor, 0.85)]), 2.0, true)
		c.draw_polyline_colors(PackedVector2Array([Vector2(m + 14, y), Vector2(w, y)]), PackedColorArray([Color(cor, 0.85), Color(cor, 0.0)]), 2.0, true)
		c.draw_colored_polygon(PackedVector2Array([Vector2(m, y - 6), Vector2(m + 7, y), Vector2(m, y + 6), Vector2(m - 7, y)]), cor)
		c.draw_circle(Vector2(m - 11, y), 1.8, cor)
		c.draw_circle(Vector2(m + 11, y), 1.8, cor))
	return c


## Painel de vidro escuro: borda fina na cor de destaque (mais forte embaixo),
## cantos arredondados e sombra preta macia. `inclinado` usa INCLINA.
static func painel(borda: Color, inclinado := false, fundo := PAINEL, raio := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.border_color = Color(borda, minf(borda.a, 0.6))
	sb.set_border_width_all(1)
	sb.border_width_bottom = 2
	sb.set_corner_radius_all(maxi(raio, RAIO))
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
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
	var sb := StyleBoxFlat.new()  # tecla clara (keycap), letra escura
	sb.bg_color = Color(0.93, 0.9, 0.84, 0.96)
	sb.border_color = Color(0.55, 0.5, 0.45)
	sb.set_border_width_all(1)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # não esticar em linha alta
	var l := rotulo(text, size, Color(0.1, 0.08, 0.1), FORTE, 0)
	l.label_settings.shadow_size = 0  # sombra borrava a letra escura na tecla clara
	p.add_child(l)
	return p


## Barra (vida, chi, peso) com fundo escuro e brilho na cor do preenchimento.
static func barra(color: Color, tamanho: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 100.0
	b.custom_minimum_size = tamanho
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	bg.border_color = Color(1, 1, 1, 0.12)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(int(tamanho.y / 2))
	bg.skew = INCLINA
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(int(tamanho.y / 2))
	fg.skew = INCLINA
	fg.shadow_color = Color(color, 0.35)
	fg.shadow_size = 3
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


static func cor_barra(b: ProgressBar, color: Color) -> void:
	var fg: StyleBoxFlat = b.get_theme_stylebox("fill")
	if fg.bg_color == color:
		return  # mudar o StyleBox redesenha a barra: só quando a cor muda
	fg.bg_color = color
	fg.shadow_color = Color(color, 0.35)


## Tema dos menus: botões, abas, listas, controles deslizantes.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = CORPO
	t.default_font_size = T_TEXTO

	var normal := painel(Color(1, 1, 1, 0.22), true, Color(0.07, 0.06, 0.08, 0.88))
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	var hover := painel(OURO, true, Color(0.16, 0.12, 0.08, 0.95))
	hover.content_margin_left = 22
	hover.content_margin_right = 22
	hover.shadow_size = 14
	hover.shadow_color = Color(OURO, 0.25)
	var pressed := hover.duplicate()
	pressed.bg_color = Color(OURO, 0.4)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = OURO
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(RAIO)
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
	t.set_font_size("font_size", "Button", 23)
	t.set_font_size("font_size", "OptionButton", 19)

	# CheckButton: sem caixa, só o interruptor (ícone padrão, tingido).
	var vazio := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(s, "CheckButton", vazio)
	t.set_color("icon_normal_color", "CheckButton", Color(1.6, 1.5, 2.0))  # desligado ainda visível
	t.set_color("icon_pressed_color", "CheckButton", CIANO)
	t.set_color("icon_hover_color", "CheckButton", OURO)
	t.set_color("icon_hover_pressed_color", "CheckButton", OURO)

	# Lista que abre no OptionButton.
	var popup := painel(Color(1, 1, 1, 0.3), false, Color(0.06, 0.05, 0.07, 0.98))
	t.set_stylebox("panel", "PopupMenu", popup)
	var pop_hover := StyleBoxFlat.new()
	pop_hover.bg_color = Color(OURO, 0.3)
	pop_hover.set_corner_radius_all(6)
	t.set_stylebox("hover", "PopupMenu", pop_hover)
	t.set_color("font_color", "PopupMenu", TEXTO)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_font("font", "PopupMenu", CORPO)
	t.set_font_size("font_size", "PopupMenu", 18)

	# Abas.
	var aba := StyleBoxFlat.new()
	aba.bg_color = Color(0.07, 0.06, 0.08, 0.85)
	aba.set_corner_radius_all(8)
	aba.skew = INCLINA
	aba.content_margin_left = 22
	aba.content_margin_right = 22
	aba.content_margin_top = 6
	aba.content_margin_bottom = 6
	var aba_sel := aba.duplicate()
	aba_sel.bg_color = Color(0.16, 0.12, 0.08, 1.0)
	aba_sel.border_color = OURO
	aba_sel.border_width_bottom = 3
	var aba_hover := aba.duplicate()
	aba_hover.bg_color = Color(0.12, 0.1, 0.1, 1.0)
	t.set_stylebox("tab_unselected", "TabContainer", aba)
	t.set_stylebox("tab_selected", "TabContainer", aba_sel)
	t.set_stylebox("tab_hovered", "TabContainer", aba_hover)
	t.set_stylebox("tab_focus", "TabContainer", focus)
	var corpo := StyleBoxFlat.new()
	corpo.bg_color = Color(0.03, 0.025, 0.035, 0.6)
	corpo.border_color = Color(OURO, 0.3)
	corpo.border_width_top = 1
	corpo.set_corner_radius_all(RAIO)
	t.set_stylebox("panel", "TabContainer", corpo)
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", TEXTO_FRACO)
	t.set_color("font_hovered_color", "TabContainer", TEXTO)
	t.set_font("font", "TabContainer", FORTE)
	t.set_font_size("font_size", "TabContainer", 21)

	# Controle deslizante: trilho fino e preenchimento ciano.
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color(0.14, 0.12, 0.14)
	trilho.set_corner_radius_all(3)
	trilho.content_margin_top = 3
	trilho.content_margin_bottom = 3
	var cheio := trilho.duplicate()
	cheio.bg_color = OURO
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", cheio)
	t.set_stylebox("grabber_area_highlight", "HSlider", cheio)

	t.set_font("font", "Label", CORPO)
	t.set_color("font_color", "Label", TEXTO)
	t.set_font("font", "TooltipLabel", CORPO)
	_tema = t
	return t
