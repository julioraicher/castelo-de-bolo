class_name Lobby
extends VBoxContainer
## Seção "Com amigos" do menu (Ciclo 2.28, quiz 3A): sem sala, cria ou entra
## (código, IP ou a lista da rede local); na sala, duas colunas azul ×
## vermelho com 8 vagas cada. Vaga vazia = bot. Clique numa vaga para ir
## para ela; o anfitrião (★) clica num amigo e depois numa vaga para movê-lo.
## Visual só com Estilo.* (mesma placa dos outros menus).

const VERDE := Color(0.55, 0.95, 0.6)

var _corpo: VBoxContainer
var _aviso: Label
var _nome: LineEdit
var _codigo: LineEdit
var _lista_lan: VBoxContainer
var _sel := -1  # anfitrião: amigo escolhido para mover
var _ativo := false
var _tit: Label


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_tit = Estilo.rotulo("JOGAR COM AMIGOS", 26, Estilo.TEXTO, Estilo.espacada(Estilo.NUMERO, 4))
	_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tit)
	_corpo = VBoxContainer.new()
	_corpo.add_theme_constant_override("separation", 10)
	_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_corpo)
	_aviso = _texto("", Estilo.T_PEQUENO, Estilo.OURO_CLARO)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_aviso)
	Rede.sala_mudou.connect(_montar)
	Rede.salas_lan_mudaram.connect(_montar_lan)
	Rede.aviso.connect(_on_aviso)
	_montar()


func _on_aviso(t: String, c: Color) -> void:
	_aviso.text = t
	_aviso.label_settings.font_color = c


## Menus avisa quando a seção abre/fecha (a lista da rede local só escuta aberta).
func ativo(sim: bool) -> void:
	_ativo = sim
	Rede.escutar_lan(sim and not Rede.online and OS.get_name() != "Web")
	if sim:
		_montar()


func _montar() -> void:
	if not is_inside_tree():
		return
	for c in _corpo.get_children():
		c.queue_free()
	_lista_lan = null
	_tit.visible = not (Rede.online and not Rede.jogadores().is_empty())
	if OS.get_name() == "Web":
		_corpo.add_child(_texto("No navegador não dá para abrir nem entrar em sala (o navegador proíbe). Baixe o .exe da \"ultima-versao\" no GitHub para jogar com amigos.", Estilo.T_TEXTO, Estilo.TEXTO))
		return
	if Rede.online and not Rede.jogadores().is_empty():
		_montar_sala()
	elif Rede.online:
		_corpo.add_child(_texto("Conectando...", Estilo.T_MEDIO, Estilo.TEXTO))
		_corpo.add_child(_botao("Cancelar", func(): Rede.sair()))
	else:
		_montar_entrada()


# --- Sem sala ---------------------------------------------------------------------

func _montar_entrada() -> void:
	Rede.escutar_lan(_ativo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	linha.add_child(_texto("Seu nome", Estilo.T_MEDIO, Estilo.OURO, false))
	_nome = LineEdit.new()
	_nome.text = Settings.nome_online if Settings.nome_online != "" else Rede.meu_nome
	_nome.max_length = 14
	_nome.custom_minimum_size = Vector2(260, 44)
	linha.add_child(_nome)
	_corpo.add_child(linha)

	var cartoes := HBoxContainer.new()
	cartoes.add_theme_constant_override("separation", 12)
	_corpo.add_child(cartoes)
	var criar := _cartao("CRIAR SALA", Estilo.OURO)
	criar.get_child(0).add_child(_texto("Você é o anfitrião: o jogo abre a porta do roteador e mostra um código para mandar no WhatsApp.", Estilo.T_PEQUENO, Estilo.TEXTO))
	var b_criar := _botao("Criar sala", func():
		_salvar_nome()
		Rede.hospedar(_nome_ok()))
	b_criar.custom_minimum_size = Vector2(0, 52)
	criar.get_child(0).add_child(b_criar)
	cartoes.add_child(criar)
	var entrar := _cartao("ENTRAR", Estilo.AZUL)
	entrar.get_child(0).add_child(_texto("Cole o código que o anfitrião mandou (ou o IP do Radmin VPN).", Estilo.T_PEQUENO, Estilo.TEXTO))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	_codigo = LineEdit.new()
	_codigo.placeholder_text = "K7QF-M9X2"
	_codigo.custom_minimum_size = Vector2(200, 52)
	_codigo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codigo.text_submitted.connect(func(_t: String): _entrar(_codigo.text))
	h.add_child(_codigo)
	h.add_child(_botao("Entrar", func(): _entrar(_codigo.text)))
	entrar.get_child(0).add_child(h)
	cartoes.add_child(entrar)

	_corpo.add_child(_texto("SALAS NA SUA REDE", Estilo.T_MEDIO, Estilo.OURO, false))
	_lista_lan = VBoxContainer.new()
	_lista_lan.add_theme_constant_override("separation", 6)
	_corpo.add_child(_lista_lan)
	_montar_lan()
	var teste := _botao("Sala de teste (abre 2 janelas neste PC)", func():
		_salvar_nome()
		Rede.sala_teste(_nome_ok()))
	_corpo.add_child(teste)
	_corpo.add_child(_texto("Amigo em outra casa e o código não conecta? Todos instalam o Radmin VPN (grátis), entram na mesma rede dele e usam o IP 26.x que aparece na sala. Quem cria a sala: quando o Windows perguntar do firewall, marque rede privada E pública.", Estilo.T_MIN, Estilo.TEXTO_FRACO))


func _montar_lan() -> void:
	if _lista_lan == null or not is_instance_valid(_lista_lan):
		return
	for c in _lista_lan.get_children():
		c.queue_free()
	if Rede.salas_lan.is_empty():
		_lista_lan.add_child(_texto("Nenhuma ainda (procurando...)", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, false))
		return
	for ip in Rede.salas_lan:
		var s: Dictionary = Rede.salas_lan[ip]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var t := _texto("Sala de %s  ·  %d/8  ·  %s" % [s.nome, s.n, ip], Estilo.T_TEXTO, Estilo.TEXTO, false)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		if s.versao != Rede.versao():
			h.add_child(_texto("versão diferente", Estilo.T_PEQUENO, Estilo.VERMELHO, false))
		else:
			h.add_child(_botao("Entrar", func(): _entrar(ip)))
		_lista_lan.add_child(h)


func _entrar(texto: String) -> void:
	_salvar_nome()
	Rede.entrar(_nome_ok(), texto)


func _nome_ok() -> String:
	var n := _nome.text.strip_edges() if _nome else ""
	return n if n != "" else Rede.meu_nome


func _salvar_nome() -> void:
	if _nome:
		Settings.nome_online = _nome.text.strip_edges()
		Settings.save()


# --- Na sala ------------------------------------------------------------------------

func _montar_sala() -> void:
	# Cabeçalho: quem é a sala e o código (esquerda), ajustes do anfitrião
	# (direita). Embaixo as duas colunas e a linha de sair/começar. Tudo cabe
	# na placa do menu em 1280x720 sem rolar.
	var dono: String = str(Rede.jogadores().get(1, {}).get("nome", "?"))
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	_corpo.add_child(topo)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	topo.add_child(v)
	v.add_child(_texto("Sala de %s" % dono, Estilo.T_GRANDE, Estilo.OURO, false))
	var direita := VBoxContainer.new()
	direita.add_theme_constant_override("separation", 6)
	direita.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.add_child(direita)
	if Rede.anfitriao:
		var cod := Rede.codigo_internet
		var linha := "Código: %s" % cod if cod != "" else "Código: (abrindo a porta...)" if Rede.upnp_texto.begins_with("Abrindo") else "Código da internet: indisponível"
		v.add_child(_texto(linha, Estilo.T_MEDIO, Estilo.TEXTO, false))
		if not Rede.codigos_lan.is_empty():
			var ips := PackedStringArray()
			for ip in Rede.codigos_lan:
				ips.append(ip)
			v.add_child(_texto("Mesma rede / Radmin: %s" % "  ·  ".join(ips), Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, false))
		if Rede.upnp_texto != "":
			v.add_child(_texto(Rede.upnp_texto, Estilo.T_MIN, Estilo.TEXTO_FRACO))
		var ajustes := HBoxContainer.new()
		ajustes.add_theme_constant_override("separation", 8)
		direita.add_child(ajustes)
		ajustes.add_child(_texto("Tempo", Estilo.T_PEQUENO, Estilo.OURO, false))
		var tempo := OptionButton.new()
		for m in [10, 15]:
			tempo.add_item("%d min" % m)
		tempo.selected = 0 if int(Rede.sala.get("tempo", 15)) == 10 else 1
		tempo.item_selected.connect(func(i: int): Rede.ajustar("tempo", [10, 15][i]))
		ajustes.add_child(tempo)
		ajustes.add_child(_texto("Bots", Estilo.T_PEQUENO, Estilo.OURO, false))
		var dif := OptionButton.new()
		for d in Settings.DIFFICULTIES:
			dif.add_item(d)
		dif.selected = int(Rede.sala.get("dificuldade", 1))
		dif.item_selected.connect(func(i: int): Rede.ajustar("dificuldade", i))
		ajustes.add_child(dif)
		var botoes := HBoxContainer.new()
		botoes.add_theme_constant_override("separation", 8)
		botoes.alignment = BoxContainer.ALIGNMENT_END
		direita.add_child(botoes)
		if cod != "":
			botoes.add_child(_botao("Copiar código", func():
				DisplayServer.clipboard_set(cod)
				_aviso.text = "Código copiado: cole no WhatsApp."))
		botoes.add_child(_botao("Embaralhar times", func(): Rede.embaralhar()))
	else:
		v.add_child(_texto("Clique numa vaga para ir para ela. Vaga vazia vira bot.", Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, false))
		direita.add_child(_texto("%d min  ·  bots %s" % [int(Rede.sala.get("tempo", 15)), Settings.DIFFICULTIES[int(Rede.sala.get("dificuldade", 1))]], Estilo.T_PEQUENO, Estilo.TEXTO_FRACO, false))

	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 14)
	_corpo.add_child(colunas)
	for t in 2:
		colunas.add_child(_coluna(t))

	var base := HBoxContainer.new()
	base.add_theme_constant_override("separation", 10)
	_corpo.add_child(base)
	var pior := 0
	for p in Rede.jogadores():
		pior = maxi(pior, int(Rede.jogadores()[p].get("ping", 0)))
	var quadros := clampi(ceili(pior / 16.667) + 1, 2, 9)
	var info := _texto("Atraso dos comandos: ~%d ms (rede local ≈ 33 ms). Quem cair vira bot." % roundi(quadros * 16.667), Estilo.T_MIN, Estilo.TEXTO_FRACO)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	base.add_child(info)
	base.add_child(_botao("Sair da sala", func(): Rede.sair()))
	if Rede.anfitriao:
		var ok := Rede.todos_prontos()
		var b := _botao("Começar" if ok else "Começar mesmo assim", func(): Rede.comecar())
		b.custom_minimum_size = Vector2(200, 46)
		base.add_child(b)
	else:
		var pronto := bool(Rede.eu().get("pronto", false))
		var b := _botao("Pronto ✔" if pronto else "Pronto", func(): Rede.pedir_pronto(not pronto))
		b.custom_minimum_size = Vector2(170, 46)
		base.add_child(b)


func _coluna(t: int) -> PanelContainer:
	var cor := Estilo.cor_time(t)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", Estilo.placa(Estilo.LACA_CLARA, Color(cor, 0.7), 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var humanos := Rede.humanos_no_time(t)
	v.add_child(_texto("%s  ·  %d %s + %d bots" % [Config.TEAM_NAMES[t].to_upper(), humanos, "pessoa" if humanos == 1 else "pessoas", Rede.VAGAS - humanos], Estilo.T_MEDIO, cor, false))
	for i in Rede.VAGAS:
		var peer := Rede.peer_na_vaga(t, i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 28)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		if peer >= 0:
			var j: Dictionary = Rede.jogadores()[peer]
			var txt := "● %s%s" % [j.nome, " ★" if peer == 1 else ""]
			if peer == Rede.id():
				txt += "  (você)"
			if j.get("pronto", false) or peer == 1:
				txt += "   ✔"
			if peer != 1 and int(j.get("ping", 0)) > 0:
				txt += "   %d ms" % int(j.ping)
			b.text = txt
			b.add_theme_color_override("font_color", cor.darkened(0.6) if peer != _sel else Color.BLACK)
			if peer == _sel:
				b.modulate = Color(1.3, 1.3, 1.0)
		else:
			b.text = "    + bot"
			b.modulate = Color(1, 1, 1, 0.55)
		b.pressed.connect(_clicou.bind(t, i, peer))
		v.add_child(b)
	return p


func _clicou(t: int, i: int, peer: int) -> void:
	if Rede.anfitriao and peer >= 0 and peer != _sel:
		_sel = peer  # escolheu quem mover
		_montar()
		return
	if Rede.anfitriao and _sel >= 0:
		Rede.mover(_sel, t, i)
		_sel = -1
		return
	if peer < 0:
		Rede.pedir_vaga(t, i)


# --- Peças ----------------------------------------------------------------------------

func _cartao(titulo: String, cor: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", Estilo.placa(Estilo.LACA_CLARA, Color(cor, 0.7), 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(Estilo.rotulo(titulo, 24, cor, Estilo.NUMERO))
	return p


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(acao)
	return b


func _texto(text: String, size: int, color := Color.WHITE, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(200, 0)
	l.label_settings = Estilo.ajustes(size, color, Estilo.CORPO, 2)
	l.label_settings.shadow_color = Color(0, 0, 0, 0)
	return l
