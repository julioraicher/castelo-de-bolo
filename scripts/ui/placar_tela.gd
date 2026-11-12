class_name PlacarTela
extends CanvasLayer
## Placar estilo Battlefield (Ciclo 2.16). Segurando Tab: os dois times lado
## a lado, do mais pontuado para o menos, com o jogo rodando atrás borrado e
## escuro (placar_fundo.gdshader). No fim da partida fica aberto sozinho, com
## "Vitória!"/"Derrota..." em cima. Dados e pesos: Placar + game_config.tres.

const FUNDO := preload("res://assets/shaders/placar_fundo.gdshader")

## Colunas: [título, largura, campo]. Campo "pontos" vem da conta; "_masc"
## soma capturas + roubos + resgates (o que se fez com as máscaras).
const COLUNAS := [
	["#", 28, "_pos"], ["Nome", 78, "nome"], ["Classe", 120, "_classe"], ["Pontos", 64, "pontos"],
	["Abates", 58, "abates"], ["Assist.", 58, "assist"], ["Reanim.", 56, "reanimar"], ["Mortes", 58, "mortes"], ["Dano", 50, "dano"],
	["Almas", 50, "almas"], ["Toras", 46, "madeira"], ["Obra", 46, "obra_s"], ["Másc.", 46, "_masc"],
]
const ALTURA_LINHA := 32

var game: Game
var _fundo: ColorRect
var _titulo: Label
var _sub: Label
var _rodape: Label
var _cabeca_time: Array[Label] = []
var _total_time: Array[Label] = []
## [time][linha] -> {painel, celulas: Array[Label], cor: ColorRect}
var _linhas := [[], []]
var _fim := false
var _venceu := false
var _empate := false
var _atualizar_t := 0.0
var _corpo: Control  # tudo do placar: encolhe se não couber na janela


func setup(g: Game) -> void:
	game = g
	layer = 5  # acima do HUD (1), abaixo dos menus (10)
	visible = false
	_montar()


func _montar() -> void:
	_fundo = ColorRect.new()
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = FUNDO
	_fundo.material = m
	add_child(_fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	centro.add_child(v)
	_corpo = v
	_titulo = Estilo.titulo("PLACAR", 54, Estilo.OURO)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_titulo)
	_sub = Estilo.rotulo("", Estilo.T_GRANDE, Estilo.TEXTO, Estilo.NUMERO)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_sub)
	var orn := Estilo.ornamento(520.0)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(orn)
	var times := HBoxContainer.new()
	times.add_theme_constant_override("separation", 18)
	v.add_child(times)
	var n := maxi(Config.cfg.units_per_team, 1)
	for t in 2:
		times.add_child(_montar_time(t, n))
	_rodape = Estilo.rotulo("", Estilo.T_MIN, Estilo.TEXTO_FRACO)
	_rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_rodape)


func _montar_time(t: int, n: int) -> Control:
	var cor := Estilo.AZUL if t == Config.TEAM_BLUE else Estilo.VERMELHO
	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", Estilo.placa(Color(Estilo.LACA, 0.82), cor.darkened(0.15)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	caixa.add_child(v)
	# Faixa do time: nome à esquerda, total de pontos à direita
	var faixa := HBoxContainer.new()
	var nome := Estilo.rotulo("TIME " + Config.TEAM_NAMES[t].to_upper(), Estilo.T_GRANDE, cor, Estilo.TITULO)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	faixa.add_child(nome)
	_cabeca_time.append(nome)
	var total := Estilo.rotulo("", Estilo.T_GRANDE, Estilo.TEXTO, Estilo.NUMERO)
	faixa.add_child(total)
	_total_time.append(total)
	v.add_child(faixa)
	# Cabeçalho das colunas
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 0)
	for c in COLUNAS:
		var l := Estilo.rotulo(c[0], Estilo.T_MIN, Estilo.TEXTO_FRACO, Estilo.FORTE)
		_celula(l, c)
		cab.add_child(l)
	v.add_child(cab)
	for i in n:
		var linha := _montar_linha()
		v.add_child(linha.painel)
		_linhas[t].append(linha)
	return caixa


func _celula(l: Label, c: Array) -> void:
	l.custom_minimum_size = Vector2(c[1], 0)
	l.clip_text = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if c[2] in ["nome", "_classe"] else HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _montar_linha() -> Dictionary:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(0, ALTURA_LINHA)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	painel.add_child(h)
	var celulas: Array[Label] = []
	var cor_classe: ColorRect = null
	for c in COLUNAS:
		if c[2] == "_classe":
			# Quadradinho na cor do chapéu da classe + nome da classe
			var hc := HBoxContainer.new()
			hc.custom_minimum_size = Vector2(c[1], 0)
			hc.add_theme_constant_override("separation", 6)
			cor_classe = ColorRect.new()
			cor_classe.custom_minimum_size = Vector2(10, 10)
			cor_classe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hc.add_child(cor_classe)
			var l := Estilo.rotulo("", Estilo.T_MIN, Estilo.TEXTO, Estilo.CORPO)
			_celula(l, [c[0], c[1] - 16, c[2]])
			hc.add_child(l)
			celulas.append(l)
			h.add_child(hc)
			continue
		var fonte: Font = Estilo.NUMERO if c[2] == "pontos" else Estilo.CORPO
		var l := Estilo.rotulo("", Estilo.T_PEQUENO if c[2] in ["pontos", "nome"] else Estilo.T_MIN, Estilo.TEXTO, fonte)
		_celula(l, c)
		celulas.append(l)
		h.add_child(l)
	return {"painel": painel, "celulas": celulas, "cor": cor_classe}


# --- Atualização ------------------------------------------------------------------

## Fim da partida: o placar fica aberto com o resultado em cima.
func fim(venceu: bool, empate := false) -> void:
	_fim = true
	_venceu = venceu
	_empate = empate
	_abrir()


func _process(delta: float) -> void:
	if game == null:
		return
	var quer := _fim or game.placar_print or (Input.is_action_pressed("placar") and not get_tree().paused)
	if quer and not visible:
		_abrir()
	elif not quer and visible:
		visible = false
	if not visible:
		return
	_caber()
	_atualizar_t -= delta
	if _atualizar_t <= 0.0:
		_atualizar_t = 0.25
		_preencher()


## Os dois times lado a lado passam de 1.600 px; numa janela mais estreita (ou
## com outra proporção) a borda cortava a última coluna. Encolhe por igual,
## pelo centro, até caber com uma margem.
func _caber() -> void:
	var tam := _corpo.size
	if tam.x <= 0.0 or tam.y <= 0.0:
		return
	var vp := get_viewport().get_visible_rect().size
	var s := minf(1.0, minf((vp.x - 40.0) / tam.x, (vp.y - 24.0) / tam.y))
	_corpo.pivot_offset = tam * 0.5
	_corpo.scale = Vector2(s, s)


func _abrir() -> void:
	visible = true
	_atualizar_t = 0.0
	_preencher()
	for f in get_children():
		if f is CanvasItem:
			(f as CanvasItem).modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(f, "modulate:a", 1.0, 0.12)


func _preencher() -> void:
	var cfg := Config.cfg
	var placar := game.placar
	if _fim:
		_titulo.text = "Empate" if _empate else ("Vitória!" if _venceu else "Derrota...")
		_titulo.label_settings.font_color = Estilo.TEXTO if _empate else (Estilo.OURO if _venceu else Estilo.PERIGO)
	else:
		_titulo.text = "PLACAR"
		_titulo.label_settings.font_color = Estilo.OURO
	var seg := int(game.tempo_partida)
	var corrida := "  (última corrida)" if game.prorrogacao >= 0.0 else ""
	if game.decidido_no_placar:
		corrida = "  ·  decidido pelos pontos do placar"
	elif game.morte_subita >= 0.0:
		corrida = "  (morte súbita)"
	_sub.text = "AZUL  %d  ×  %d  VERMELHO      %d:%02d de partida%s" % [game.score[0], game.score[1], seg / 60, seg % 60, corrida]
	for t in 2:
		var linhas := placar.time(t)
		var total := 0
		for i in _linhas[t].size():
			var ln: Dictionary = _linhas[t][i]
			var painel: PanelContainer = ln.painel
			painel.visible = i < linhas.size()
			if not painel.visible:
				continue
			var l: Dictionary = linhas[i]
			total += int(l.pontos)
			_linha(ln, l, i, t)
		_total_time[t].text = "%s pts" % _milhar(total)
	var mb := cfg.multikill_bonus
	var multi := " · duplo +%s, triplo +%s, multi +%s" % [_n(mb[0]), _n(mb[1]), _n(mb[2])] if mb.size() >= 3 else ""
	_rodape.text = ("Pontos:  abate %s%s · assistência %s · alma %s · tora %s · obra %s/s · dano %s/pv · cura %s/pv · roubo %s · resgate %s · reanimar %s · captura %s" % [
		_n(cfg.pts_abates), multi, _n(cfg.pts_assist), _n(cfg.pts_almas), _n(cfg.pts_madeira), _n(cfg.pts_obra_s),
		_n(cfg.pts_dano), _n(cfg.pts_cura), _n(cfg.pts_roubos), _n(cfg.pts_resgates), _n(cfg.pts_reanimar), _n(cfg.pts_capturas)]) \
		+ ("      ·      F5 jogar de novo" if _fim else "      ·      solte o Tab para voltar")


func _linha(ln: Dictionary, l: Dictionary, i: int, t: int) -> void:
	var u: Unit = l.unit
	var vivo := is_instance_valid(u) and u.alive
	var jogador: bool = l.jogador
	var sb := StyleBoxFlat.new()
	var cor_time := Estilo.AZUL if t == Config.TEAM_BLUE else Estilo.VERMELHO
	sb.bg_color = Color(cor_time, 0.10 if i % 2 == 0 else 0.04)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 2
	if jogador:
		sb.bg_color = Color(Estilo.OURO, 0.22)
		sb.border_color = Estilo.OURO
		sb.set_border_width_all(2)
	(ln.painel as PanelContainer).add_theme_stylebox_override("panel", sb)
	var celulas: Array[Label] = ln.celulas
	var cor := Estilo.TEXTO if vivo else Estilo.TEXTO_FRACO
	for k in COLUNAS.size():
		var campo: String = COLUNAS[k][2]
		var txt := ""
		match campo:
			"_pos":
				txt = str(i + 1)
			"nome":
				txt = String(l.nome) + ("" if vivo else "  †")
			"_classe":
				txt = String(u.stats.display_name) if is_instance_valid(u) else ""
			"pontos":
				txt = _milhar(int(l.pontos))
			"obra_s":
				txt = "%ds" % int(l.obra_s) if l.obra_s >= 1.0 else "–"
			"_masc":
				var m := int(l.capturas + l.roubos + l.resgates)
				txt = str(m) if m > 0 else "–"
			_:
				var val := int(l.get(campo, 0.0))
				txt = str(val) if val != 0 or campo in ["abates", "mortes"] else "–"
		var lab := celulas[k]
		lab.text = txt
		lab.label_settings.font_color = Estilo.OURO if campo == "pontos" else (Estilo.OURO_CLARO if jogador and campo == "nome" else cor)
	if ln.cor and is_instance_valid(u):
		(ln.cor as ColorRect).color = u.stats.hat_color


func _n(x: float) -> String:
	if is_equal_approx(x, roundf(x)):
		return str(int(x))
	return ("%.2f" % x).rstrip("0").replace(".", ",")  # 0,25 / 0,4


func _milhar(x: int) -> String:
	var s := str(absi(x))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if x < 0 else "") + s + out
