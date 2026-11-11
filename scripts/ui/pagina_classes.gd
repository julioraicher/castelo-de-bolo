class_name PaginaClasses
extends HBoxContainer
## Seção "Classes" do menu: lista à esquerda, ficha da classe à direita com
## clipe (3 golpes, Q, E e R gravados por ClipeCenas em
## assets/tutorial/classe_<id>/), nome, epíteto, papel, origem, barras de vida,
## velocidade e dano, a identidade da classe (`descricao` do .tres) e o que
## fazem Q, E e R.
##
## Medidas (área de conteúdo do menu = 940 x 560): lista 216 + 16 de vão, ficha
## 708. Tudo que tem largura fixa na ficha soma menos que isso, o resto quebra
## linha; a ficha fica numa rolagem vertical para nunca escapar da moldura. Tudo vem dos .tres de config/classes e das
## listas do game_config: classe nova = ficha nova, sem código.

const CLIPE_FPS := 7.5
const CLIPE_TAM := Vector2(320, 180)
const LISTA_LARG := 216.0

## O que cada habilidade (enum `skill` do ClassStats) faz, em uma linha.
const RAPIDA := {
	"investida": "Corte em avanço: atravessa quem estiver na frente.",
	"pisao": "Onda curta que arremessa quem está perto.",
	"tiro_carregado": "Tiro cheio que atravessa os inimigos em linha.",
	"cura": "Cura quem estiver em volta.",
	"armadilha": "Estrepes no chão: dano e lentidão em quem pisa.",
	"bloqueio": "Bloqueio reforçado por alguns segundos.",
	"corrida": "Arrancada curta.",
}
## O que cada poder de Chi (enum `power`) faz.
const PODER := {
	"redemoinho": "Gira com a lâmina: dano e empurrão em volta.",
	"furia": "Mais força e vida por alguns segundos.",
	"leque": "Leque de shurikens à frente.",
	"chuva_de_flechas": "Flechas caem numa área à frente.",
	"bencao": "Cura e escudo nos aliados perto.",
	"selo": "Inimigos em volta ficam sem atacar.",
	"coluna_fogo": "Colunas de fogo-raposa onde você mira.",
	"mutirao": "Adianta a obra perto de você.",
	"campo_minado": "Minas em volta.",
	"bombardeio": "Bombas caem numa área.",
}

var _ficha: VBoxContainer
var _clipe: TutorialClipe
var _clipe_moldura: PanelContainer
var _nome: Label
var _epiteto: Label
var _descricao: Label
var _papel: Label
var _barras: Dictionary = {}   # "vida" -> ProgressBar
var _valores: Dictionary = {}  # "vida" -> Label
var _poderes: VBoxContainer
var _atual: ClassStats
var _ativo := false
var _max := {"vida": 1.0, "velocidade": 1.0, "dano": 1.0}


## Todas as classes jogáveis: cada classe do pátio seguida dos seus dois caminhos.
static func lista() -> Array[ClassStats]:
	var out: Array[ClassStats] = []
	for b in Config.cfg.hat_classes():
		if b and b not in out:
			out.append(b)
		for e in b.caminhos:
			if e and e not in out:
				out.append(e)
	return out


static func nome_super(s: ClassStats) -> String:
	if s.super_nome != "":
		return s.super_nome
	return "Super " + s.power_name if s.power_name != "" else "–"


static func origem(s: ClassStats) -> String:
	if s.classe_base != &"":
		return "caminho %s (nível 3 da casa, %d madeiras)" % [s.caminho_nome if s.caminho_nome != "" else s.display_name, Config.cfg.oficina_custo_madeira]
	return "pátio (barraquinha)"


static func papel(s: ClassStats) -> String:
	if s.velocidade_obra > 0.0:
		return "Economia: corta madeira, ergue casas e torretas"
	match s.attack_kind:
		"ranged":
			return "De longe: mantém distância e atira"
		"healer":
			return "Apoio: cura e fica atrás dos guerreiros"
	return "Linha de frente: combo de 3 golpes"


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var classes := lista()
	for s in classes:
		_max["vida"] = maxf(_max["vida"], s.max_hp)
		_max["velocidade"] = maxf(_max["velocidade"], s.move_speed)
		_max["dano"] = maxf(_max["dano"], _dps(s))

	# Lista da esquerda.
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.custom_minimum_size = Vector2(LISTA_LARG, 0)
	add_child(rolagem)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(col)
	var grupo := ButtonGroup.new()
	var origem_ant := ""
	for s in classes:
		var o := origem(s)
		if o != origem_ant:
			origem_ant = o
			var cab := Estilo.rotulo(o.to_upper(), Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.espacada(Estilo.NUMERO, 1))
			cab.clip_text = true  # "OFICINA (N MADEIRAS)" não empurra a lista
			col.add_child(cab)
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = grupo
		b.custom_minimum_size = Vector2(0, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = s.display_name
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_constant_override("h_separation", 8)
		# Letra escura de botão (legível no ouro) e bolinha na cor da classe:
		# a cor da classe direto na letra sumia nas claras (Kitsune da Luz).
		b.icon = _bolinha(s.hat_color)
		b.pressed.connect(func(): _mostrar(s))
		col.add_child(b)
		if s == classes[0]:
			b.button_pressed = true

	# Ficha da direita.
	var rol_ficha := ScrollContainer.new()
	rol_ficha.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rol_ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(rol_ficha)
	_ficha = VBoxContainer.new()
	_ficha.add_theme_constant_override("separation", 8)
	_ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol_ficha.add_child(_ficha)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	_ficha.add_child(topo)
	_clipe_moldura = PanelContainer.new()
	var msb := Estilo.placa(Estilo.TINTA, Color(Estilo.OURO, 0.7), 8)
	msb.set_content_margin_all(4)
	_clipe_moldura.add_theme_stylebox_override("panel", msb)
	_clipe_moldura.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	topo.add_child(_clipe_moldura)
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 4)
	lado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(lado)
	_nome = Estilo.rotulo("", Estilo.T_GRANDE, Estilo.OURO, Estilo.TITULO)
	lado.add_child(_nome)
	_epiteto = Estilo.rotulo("", Estilo.T_PEQUENO, Estilo.OURO_CLARO, Estilo.CORPO)
	lado.add_child(_epiteto)
	_papel = Estilo.rotulo("", Estilo.T_MIN, Estilo.TEXTO_FRACO)
	_papel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lado.add_child(_papel)
	var vao := Control.new()
	vao.custom_minimum_size = Vector2(0, 4)
	lado.add_child(vao)
	for k in ["vida", "velocidade", "dano"]:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 8)
		var r := Estilo.rotulo(k.to_upper(), Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.espacada(Estilo.NUMERO, 1))
		r.custom_minimum_size = Vector2(98, 0)
		linha.add_child(r)
		# A barra estica no que sobrar da linha (antes era fixa e empurrava o
		# número para fora da moldura).
		var barra := Estilo.barra(Estilo.OURO, Vector2(80, 12))
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(barra)
		_barras[k] = barra
		var v := Estilo.rotulo("", Estilo.T_MIN, Estilo.TEXTO, Estilo.NUMERO)
		v.custom_minimum_size = Vector2(96, 0)
		linha.add_child(v)
		_valores[k] = v
		lado.add_child(linha)
	_descricao = Estilo.rotulo("", Estilo.T_MIN + 1, Estilo.TEXTO)
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha.add_child(_descricao)
	_poderes = VBoxContainer.new()
	_poderes.add_theme_constant_override("separation", 5)
	_ficha.add_child(_poderes)
	_mostrar(classes[0])


func ativo(sim: bool) -> void:
	_ativo = sim
	if _clipe:
		_clipe.tocar(sim)


## Dano por segundo do ataque normal (o combo e os poderes ficam fora).
static func _dps(s: ClassStats) -> float:
	return s.damage / maxf(s.attack_cooldown, 0.1)


func _mostrar(s: ClassStats) -> void:
	_atual = s
	_nome.text = s.display_name
	_nome.label_settings.font_color = s.hat_color.lightened(0.25)
	_epiteto.text = s.epiteto
	_epiteto.visible = s.epiteto != ""
	_papel.text = "%s. Chapéu: %s." % [papel(s), origem(s)]
	_descricao.text = s.descricao
	_descricao.visible = s.descricao != ""
	var cfg := Config.cfg
	_barras["vida"].value = s.max_hp / _max["vida"] * 100.0
	_valores["vida"].text = str(roundi(s.max_hp * cfg.vida_mult))
	_barras["velocidade"].value = s.move_speed / _max["velocidade"] * 100.0
	_valores["velocidade"].text = "%.1f m/s" % s.move_speed
	_barras["dano"].value = _dps(s) / _max["dano"] * 100.0
	_valores["dano"].text = "%d/golpe" % roundi(s.damage)
	# Clipe da classe.
	if _clipe:
		_clipe.queue_free()
		_clipe = null
	var c := TutorialClipe.novo("res://assets/tutorial/classe_%s" % s.id, CLIPE_TAM, CLIPE_FPS)
	_clipe_moldura.visible = c.tem_quadros()
	if c.tem_quadros():
		_clipe = c
		_clipe_moldura.add_child(c)
		c.tocar(_ativo)
	# Q, E e R.
	for ch in _poderes.get_children():
		ch.queue_free()
	var linhas := []
	if s.skill != "nenhum":
		linhas.append(["Q", s.skill_name, RAPIDA.get(s.skill, ""), "recarga %.0f s" % (s.skill_cooldown * cfg.rapida_cooldown_mult) if s.skill != "armadilha" else "recarga %.0f s" % s.trap_cooldown])
	if s.power != "nenhum":
		linhas.append(["E", s.power_name, PODER.get(s.power, ""), "quando o Chi enche"])
		var super_txt := ""
		if s.super_tipo == "sombra":
			var tempo := ("%.1f" % cfg.sombra_tempo).replace(".", ",")
			var mult := ("%.1f" % cfg.sombra_golpe_mult).replace(".", ",")
			super_txt = "Some por %s s, anda mais rápido e o primeiro golpe dá ×%s." % [tempo, mult]
		else:
			super_txt = "%s em versão gigante: mais área, mais força e mais tempo." % s.power_name
		linhas.append(["R", nome_super(s), super_txt, "barra dourada cheia"])
	if s.attack_kind == "ranged":
		linhas.append(["Clique", "Tiro", "Segure para carregar: tiro mais forte. Atirar deixa lento por um instante.", ""])
	for l in linhas:
		_poderes.add_child(_linha_poder(l[0], l[1], l[2], l[3]))


func _linha_poder(tecla: String, nome: String, texto: String, nota: String) -> Control:
	var p := PanelContainer.new()
	var sb := Estilo.placa(Estilo.LACA_CLARA, Color(Estilo.OURO, 0.5), 8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var t := Estilo.tecla(tecla, Estilo.T_MIN)
	t.custom_minimum_size = Vector2(64, 0) if tecla.length() > 1 else Vector2(28, 0)
	(t.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	cab.add_child(Estilo.rotulo(nome, Estilo.T_PEQUENO + 1, Estilo.OURO, Estilo.NUMERO))
	if nota != "":
		var n := Estilo.rotulo(nota, Estilo.T_MIN, Estilo.TEXTO_FRACO)
		n.size_flags_vertical = Control.SIZE_SHRINK_END
		cab.add_child(n)
	v.add_child(cab)
	var d := Estilo.rotulo(texto, Estilo.T_MIN, Estilo.TEXTO)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return p


## Bolinha na cor da classe (ícone do botão da lista), com contorno de tinta.
static func _bolinha(cor: Color) -> ImageTexture:
	var n := 14
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) / 2.0
	for y in n:
		for x in n:
			var d := Vector2(x - c, y - c).length()
			if d <= c - 1.5:
				img.set_pixel(x, y, cor)
			elif d <= c + 0.5:
				img.set_pixel(x, y, Estilo.TINTA)
	return ImageTexture.create_from_image(img)
