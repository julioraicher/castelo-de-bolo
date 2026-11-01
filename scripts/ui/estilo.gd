class_name Estilo
extends RefCounted
## Identidade da interface: "Festival sombrio" (docs/identidade-interface.md).
## Uma vibe só no jogo inteiro: menus, HUD, avisos, tutorial e letreiros 3D.
## Tudo estático: Estilo.rotulo(...). Nada de cor ou fonte solta fora daqui.
##
## Por que traço grosso com contorno escuro: numa briga vista de cima o texto
## fica sobre um fundo que muda a cada quadro. O contorno escuro garante um
## salto de luminância entre letra e fundo em qualquer pixel; letra fina some.
##
## Fontes livres (OFL) em assets/fonts:
##   Lilita One   (TITULO = NUMERO = LETREIRO): títulos, avisos, números,
##                botões, letreiros 3D. Sempre com contorno grosso de TINTA.
##   Nunito Black (CORPO = FORTE): texto, dicas, menus, tutorial.
## Os nomes antigos (TITULO, FORTE, NUMERO, CORPO) continuam valendo, para não
## quebrar quem já usa; FORTE e CORPO agora são a mesma fonte.
## Escala de tamanhos (px na tela-base 1600x900): use as constantes T_*.
## Nada abaixo de T_MIN: no navegador em tela pequena some.

const LILITA := preload("res://assets/fonts/LilitaOne-Regular.ttf")
const NUNITO := preload("res://assets/fonts/Nunito-Black.ttf")
const TITULO := LILITA
const NUMERO := LILITA
const LETREIRO := LILITA  # Label3D no mundo
const FORTE := NUNITO
const CORPO := NUNITO

const T_GIGANTE := 110  # fim de partida
const T_GRANDE := 28    # nome da classe, placar secundário
const T_MEDIO := 22     # botões, dicas, cabeçalhos de cartão
const T_TEXTO := 20     # texto corrido
const T_PEQUENO := 17   # rótulos de apoio
const T_MIN := 15

# Paleta: ouro (destaque), cor do time e laca escura. Mais nenhuma cor de
# interface. FANTASMA é cor do jogo (espíritos), não de moldura.
const LACA := Color("1b1420")          # placas e molduras
const LACA_CLARA := Color("2a2030")    # cartão dentro de placa
const OURO := Color("e2b553")          # borda, destaque, interativo
const OURO_CLARO := Color("f3d48a")    # topo do botão
const OURO_ESCURO := Color("d39a2a")   # base do botão
const TINTA := Color("1a1020")         # contorno e sombra sólida
const AZUL := Color("6fb0ff")          # time azul
const VERMELHO := Color("ff6a5f")      # time vermelho / perigo
const TEXTO := Color("fff1d6")         # letra clara (papel quente)
const TEXTO_FRACO := Color("c8b494")   # apoio
const TEXTO_BOTAO := Color("2b1606")   # letra escura sobre ouro
const FANTASMA := Color(0.45, 1.0, 0.62)  # espíritos, Chi pronto (cor do jogo)
const PAINEL := Color(LACA, 0.93)
# Nomes antigos, apontando para a paleta nova.
const CIANO := AZUL
const PERIGO := VERMELHO
const MAGENTA := AZUL

## Inclinação dos painéis e botões (0 = reto).
const INCLINA := Vector2(0.0, 0.0)
## Raio dos cantos de placas e botões.
const RAIO := 10
## Queda da sombra sólida (px): a placa parece uma peça física apoiada.
const SOMBRA := 4

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
	var grossa := _base(fonte) == LILITA
	# Lilita: contorno grosso (~1/6 da letra). Nunito: fino (~1/10).
	ls.outline_size = contorno if contorno >= 0 else (maxi(4, size / 6) if grossa else maxi(3, size / 10))
	ls.outline_color = TINTA
	# Sombra sólida para baixo (não borrada): a letra "sai" da tela.
	ls.shadow_color = Color(TINTA, 0.9)
	ls.shadow_size = ls.outline_size
	ls.shadow_offset = Vector2(0, clampi(size / 12, 2, 4))
	if not grossa:
		ls.line_spacing = -size * 0.22  # Nunito tem entrelinha alta: aperta o parágrafo
	return ls


static func _base(f: Font) -> Font:
	return f.base_font if f is FontVariation else f


## Título: Lilita One, contorno grosso de tinta e sombra sólida embaixo.
static func titulo(text: String, size: int, color: Color) -> Label:
	var l := rotulo(text, size, color, TITULO, maxi(8, size / 6))
	l.label_settings.shadow_offset = Vector2(0, clampi(size / 14, 3, 7))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Aviso grande (meio-alto da tela): CAIXA ALTA, mesmo traço do título.
static func aviso(text: String, size: int, color: Color) -> Label:
	var l := titulo(text.to_upper(), size, color)
	l.label_settings.font = espacada(LILITA, 2)  # contorno grosso encosta as letras
	l.label_settings.line_spacing = -size * 0.1
	return l


## Filete dourado com losango no meio, embaixo de títulos.
static func ornamento(largura := 360.0, cor := OURO) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(largura, 14)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var w := c.size.x
		var y := c.size.y * 0.5
		var m := w * 0.5
		c.draw_polyline_colors(PackedVector2Array([Vector2(0, y), Vector2(m - 14, y)]), PackedColorArray([Color(cor, 0.0), Color(cor, 0.9)]), 2.0, true)
		c.draw_polyline_colors(PackedVector2Array([Vector2(m + 14, y), Vector2(w, y)]), PackedColorArray([Color(cor, 0.9), Color(cor, 0.0)]), 2.0, true)
		c.draw_colored_polygon(PackedVector2Array([Vector2(m, y - 7), Vector2(m + 8, y), Vector2(m, y + 7), Vector2(m - 8, y)]), TINTA)
		c.draw_colored_polygon(PackedVector2Array([Vector2(m, y - 5), Vector2(m + 6, y), Vector2(m, y + 5), Vector2(m - 6, y)]), cor))
	return c


## Placa: laca escura, borda de ouro de 2 px, cantos arredondados e sombra
## sólida embaixo, como uma peça física. A peça padrão de toda moldura.
static func placa(fundo := PAINEL, borda := OURO, raio := RAIO) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.border_color = borda
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(raio)
	sb.shadow_color = Color(TINTA, 0.85)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, SOMBRA)
	sb.anti_aliasing = true
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


## Compatibilidade: painel(borda, inclinado, fundo, raio) vira uma placa.
static func painel(borda: Color, inclinado := false, fundo := PAINEL, raio := 4) -> StyleBoxFlat:
	var sb := placa(fundo, borda, maxi(raio, RAIO))
	if inclinado:
		sb.skew = INCLINA
	return sb


## Botão de ouro (degradê de cima para baixo, contorno de tinta, sombra
## sólida). Para Button fora do tema: b.add_theme_stylebox_override("normal", ...).
static func botao_ouro(estado := "normal") -> StyleBox:
	var sb := PlacaOuro.new()
	match estado:
		"hover":
			sb.cima = OURO_CLARO.lightened(0.25)
			sb.baixo = OURO.lightened(0.1)
		"pressed":
			sb.cima = OURO_ESCURO
			sb.baixo = OURO
			sb.sombra = 1.0
			sb.afunda = 3.0
		"disabled":
			sb.cima = Color(0.55, 0.5, 0.42)
			sb.baixo = Color(0.4, 0.36, 0.3)
	return sb


## StyleBox desenhado à mão: StyleBoxFlat não faz degradê. Um polígono de
## cantos arredondados com cor por vértice (a GPU interpola o degradê),
## sombra deslocada e contorno. Custo: 3 chamadas de desenho por botão.
class PlacaOuro extends StyleBox:
	var cima := Color("f3d48a")
	var baixo := Color("d39a2a")
	var borda := Color("1a1020")
	var raio := 10.0
	var sombra := 4.0
	var afunda := 0.0  # apertado: desce o corpo e encolhe a sombra

	func _init() -> void:
		content_margin_left = 24
		content_margin_right = 24
		content_margin_top = 6
		content_margin_bottom = 10

	func _draw(to: RID, rect: Rect2) -> void:
		rect.position.y += afunda
		var pts := _arredondado(rect, raio)
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(0, sombra))
		RenderingServer.canvas_item_add_polygon(to, sh, PackedColorArray([Color(borda, 0.9)]))
		var cores := PackedColorArray()
		for p in pts:
			cores.append(cima.lerp(baixo, clampf((p.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
		RenderingServer.canvas_item_add_polygon(to, pts, cores)
		# Brilho fino no topo (luz de cima) e contorno de tinta.
		var brilho := _arredondado(rect.grow(-3.0), maxf(raio - 3.0, 2.0))
		var topo := PackedVector2Array()
		for p in brilho:
			if p.y < rect.position.y + raio:
				topo.append(p)
		if topo.size() > 1:
			RenderingServer.canvas_item_add_polyline(to, topo, PackedColorArray([Color(1, 1, 1, 0.45)]), 1.5, true)
		var fecha := pts.duplicate()
		fecha.append(pts[0])
		RenderingServer.canvas_item_add_polyline(to, fecha, PackedColorArray([borda]), 2.0, true)

	static func _arredondado(r: Rect2, rr: float) -> PackedVector2Array:
		rr = minf(rr, minf(r.size.x, r.size.y) * 0.5)
		var pts := PackedVector2Array()
		var centros := [
			Vector2(r.end.x - rr, r.position.y + rr), Vector2(r.end.x - rr, r.end.y - rr),
			Vector2(r.position.x + rr, r.end.y - rr), Vector2(r.position.x + rr, r.position.y + rr)]
		for k in 4:
			for i in 5:
				var ang := -PI * 0.5 + (k + i / 4.0) * PI * 0.5
				pts.append(centros[k] + Vector2(cos(ang), sin(ang)) * rr)
		return pts


## Tecla desenhada (ex.: [E]) para dicas e lista de controles: tecla clara,
## letra Lilita escura, base mais grossa (parece tecla de verdade).
static func tecla(text: String, size := 18) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TEXTO
	sb.border_color = TINTA
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # não esticar em linha alta
	var l := rotulo(text, size, TINTA, LILITA, 0)
	l.label_settings.shadow_size = 0
	l.label_settings.shadow_color = Color(0, 0, 0, 0)
	p.add_child(l)
	return p


## Barra (vida, chi, peso): trilho de laca com borda de tinta.
static func barra(color: Color, tamanho: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 100.0
	b.custom_minimum_size = tamanho
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := int(minf(tamanho.y / 2, 6))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(TINTA, 0.9)
	bg.border_color = Color(OURO_ESCURO, 0.55)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(r)
	bg.skew = INCLINA
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(r)
	fg.skew = INCLINA
	fg.border_color = Color(1, 1, 1, 0.3)  # fio claro em cima: volume
	fg.border_width_top = 2 if tamanho.y >= 12 else 0
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


static func cor_barra(b: ProgressBar, color: Color) -> void:
	var fg: StyleBoxFlat = b.get_theme_stylebox("fill")
	if fg.bg_color == color:
		return  # mudar o StyleBox redesenha a barra: só quando a cor muda
	fg.bg_color = color


## Cor do time na interface (azul/vermelho da paleta, não a do modelo 3D).
static func cor_time(team: int) -> Color:
	return AZUL if team == 0 else VERMELHO


## Letreiro 3D (Label3D): Lilita com contorno de tinta grosso, igual ao HUD.
static func letreiro(l: Label3D, size: int) -> void:
	l.font = LETREIRO
	l.font_size = size
	l.outline_size = maxi(10, size / 4)
	l.outline_modulate = TINTA


## Tema dos menus: botões de ouro, abas, listas, controles deslizantes.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = CORPO
	t.default_font_size = T_TEXTO

	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = TEXTO
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(RAIO + 3)
	focus.set_expand_margin_all(4)
	t.set_stylebox("normal", "Button", botao_ouro())
	t.set_stylebox("hover", "Button", botao_ouro("hover"))
	t.set_stylebox("pressed", "Button", botao_ouro("pressed"))
	t.set_stylebox("hover_pressed", "Button", botao_ouro("pressed"))
	t.set_stylebox("disabled", "Button", botao_ouro("disabled"))
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", TEXTO_BOTAO)
	t.set_color("font_disabled_color", "Button", Color(TEXTO_BOTAO, 0.6))
	t.set_font("font", "Button", LILITA)
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_outline_color", "Button", Color(1, 1, 1, 0.0))

	# OptionButton (escolhas nas configurações): placa de laca, borda de ouro.
	var op := placa(LACA_CLARA, Color(OURO, 0.7), 8)
	op.content_margin_left = 16
	op.content_margin_right = 16
	op.shadow_offset = Vector2(0, 3)
	var op_hover := placa(LACA_CLARA.lightened(0.08), OURO_CLARO, 8)
	op_hover.content_margin_left = 16
	op_hover.content_margin_right = 16
	op_hover.shadow_offset = Vector2(0, 3)
	t.set_stylebox("normal", "OptionButton", op)
	t.set_stylebox("hover", "OptionButton", op_hover)
	t.set_stylebox("pressed", "OptionButton", op_hover)
	t.set_stylebox("hover_pressed", "OptionButton", op_hover)
	t.set_stylebox("focus", "OptionButton", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "OptionButton", TEXTO)
	t.set_font("font", "OptionButton", NUNITO)
	t.set_font_size("font_size", "OptionButton", 19)
	t.set_color("icon_normal_color", "OptionButton", OURO)

	# CheckButton: sem caixa, só o interruptor (ícone padrão, tingido).
	var vazio := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(s, "CheckButton", vazio)
	t.set_color("icon_normal_color", "CheckButton", Color(1.4, 1.3, 1.2))  # desligado ainda visível
	t.set_color("icon_pressed_color", "CheckButton", OURO_CLARO)
	t.set_color("icon_hover_color", "CheckButton", OURO_CLARO)
	t.set_color("icon_hover_pressed_color", "CheckButton", OURO_CLARO)

	# Lista que abre no OptionButton.
	t.set_stylebox("panel", "PopupMenu", placa(Color(LACA, 0.98), OURO, 8))
	var pop_hover := StyleBoxFlat.new()
	pop_hover.bg_color = Color(OURO, 0.35)
	pop_hover.set_corner_radius_all(6)
	t.set_stylebox("hover", "PopupMenu", pop_hover)
	t.set_color("font_color", "PopupMenu", TEXTO)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_font("font", "PopupMenu", NUNITO)
	t.set_font_size("font_size", "PopupMenu", 18)

	# Abas: a escolhida é de ouro; as outras, laca com borda de ouro.
	var aba := placa(LACA_CLARA, Color(OURO, 0.55), 8)
	aba.shadow_size = 0
	aba.content_margin_left = 22
	aba.content_margin_right = 22
	aba.content_margin_top = 5
	aba.content_margin_bottom = 7
	var aba_sel := botao_ouro()
	aba_sel.sombra = 0.0
	aba_sel.raio = 8.0
	var aba_hover := aba.duplicate()
	aba_hover.border_color = OURO_CLARO
	t.set_stylebox("tab_unselected", "TabContainer", aba)
	t.set_stylebox("tab_selected", "TabContainer", aba_sel)
	t.set_stylebox("tab_hovered", "TabContainer", aba_hover)
	t.set_stylebox("tab_focus", "TabContainer", focus)
	var corpo := StyleBoxFlat.new()
	corpo.bg_color = Color(TINTA, 0.55)
	corpo.border_color = Color(OURO, 0.45)
	corpo.border_width_top = 2
	corpo.set_corner_radius_all(RAIO)
	t.set_stylebox("panel", "TabContainer", corpo)
	t.set_color("font_selected_color", "TabContainer", TEXTO_BOTAO)
	t.set_color("font_unselected_color", "TabContainer", TEXTO_FRACO)
	t.set_color("font_hovered_color", "TabContainer", TEXTO)
	t.set_font("font", "TabContainer", LILITA)
	t.set_font_size("font_size", "TabContainer", 22)

	# Controle deslizante: trilho de tinta e preenchimento de ouro.
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = TINTA
	trilho.border_color = Color(OURO_ESCURO, 0.5)
	trilho.set_border_width_all(1)
	trilho.set_corner_radius_all(4)
	trilho.content_margin_top = 4
	trilho.content_margin_bottom = 4
	var cheio := trilho.duplicate()
	cheio.bg_color = OURO
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", cheio)
	t.set_stylebox("grabber_area_highlight", "HSlider", cheio)

	t.set_font("font", "Label", CORPO)
	t.set_color("font_color", "Label", TEXTO)
	t.set_font("font", "TooltipLabel", CORPO)
	t.set_stylebox("panel", "TooltipPanel", placa(Color(LACA, 0.97), OURO, 6))
	_tema = t
	return t
