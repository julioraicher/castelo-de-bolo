class_name Tutorial
extends VBoxContainer
## Página "Como jogar": abas Objetivo, Classes, Madeira, Casinhas e níveis,
## Luz e Sombra. Cada aba tem um clipe curto gravado do jogo (quadros JPG em
## assets/tutorial/<aba>/00.jpg, 01.jpg...), carregado só quando a aba abre
## (o navegador é fraco). Sem quadros, a aba mostra só o texto.
## Visual só com Estilo.* (identidade "Festival sombrio"); números vêm do
## game_config, então mudar um custo lá atualiza o texto aqui.

const CLIPE_FPS := 10.0
const CLIPE_TAM := Vector2(420, 236)

var _tabs: TabContainer
var _clipes: Dictionary = {}  # aba -> TutorialClipe


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_tabs = TabContainer.new()
	_tabs.custom_minimum_size = Vector2(0, 480)
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	var cfg = Config.cfg
	_aba("Objetivo", "objetivo", [
		["mascara", Estilo.cor_time(0), "Roube a máscara",
			"Cada clã guarda uma Máscara Oni no pedestal do castelo. Pegue a máscara inimiga (F) e leve até o pedestal do SEU castelo. Primeiro a %d pontos vence." % cfg.score_to_win],
		["espirito", Estilo.FANTASMA, "Espíritos pesam",
			"Chamas verdes aparecem no meio do mapa. Leve até a sua máscara: ela pesa e o ladrão inimigo anda devagar com ela. Cada abate também manda um espírito."],
		["chi", Estilo.AZUL, "Chi e poder",
			"Bater, apanhar, abater e entregar espírito enchem o Chi (barra rosa). Cheio, aperte E. A Q é a habilidade rápida da classe (barra dourada)."],
		["recruta", Estilo.TEXTO_FRACO, "Caiu? Recomeça",
			"Quem morre volta em poucos segundos como Recruta, no seu castelo. Pegue um chapéu no pátio para virar uma classe de novo."],
	])
	_aba_classes()
	_aba("Madeira", "madeira", [
		["martelo", Estilo.OURO, "1. Corte",
			"Só o Construtor e as variações dele (Armadilheiro, Bombardeiro) cortam. Siga a seta dourada até uma árvore ou bambu crescido e clique colado nela. O Bombardeiro também corta: perto da planta o clique vira machadada; longe, joga bomba."],
		["martelo", Estilo.OURO, "2. Pegue",
			"Cada golpe solta uma tora (árvore adulta rende %d; bambu, %d). Passe por cima dela e ela vem para os braços. Você leva 1 por vez: o HUD mostra CARREGANDO 1/1 e você anda %d%% mais devagar, sem atacar." % [cfg.arvore_toras, cfg.bambu_varas, roundi((1.0 - cfg.tora_vel_mult) * 100.0)]],
		["martelo", Estilo.OURO, "3. Entregue",
			"Leve a tora até o depósito do seu castelo (placa com a tora e o anel no chão). Ela soma 1 em \"Madeira do time\", embaixo à esquerda. Apanhar derruba a tora no chão."],
		["martelo", Estilo.OURO, "4. Construa",
			"Fique perto de um terreno do pátio: a obra puxa a madeira do time e sobe enquanto houver Construtor ali (mais Construtores = mais rápido). Saiu, a obra fica guardada. A árvore cortada volta a broto e cresce de novo (%d s por estágio)." % roundi(cfg.arvore_tempo_estagio)],
	])
	_aba("Casinhas e níveis", "casinhas", [
		["katana", Estilo.OURO, "Maquininhas do pátio",
			"Cada maquininha fabrica um chapéu a cada %d s, até %d guardados. Chegue perto e aperte F para trocar de classe." % [roundi(cfg.maquina_intervalo), cfg.maquina_estoque_max]],
		["martelo", Estilo.OURO, "Oficinas (%d madeiras)" % cfg.oficina_custo_madeira,
			"Os terrenos vazios viram oficinas de classes novas: Ronin Oni, Arqueiro Yumi, Armadilheiro ou Bombardeiro. Perto do terreno, F troca qual classe construir (antes da obra começar)."],
		["losango", Estilo.OURO, "Nível 2 da maquininha",
			"A maquininha sobe para o nível 2 quando a oficina da variação dela fica pronta (ex.: Ronin Oni sobe a do Samurai) ou com %d madeiras de um Construtor. Nível 2: até %d chapéus, um a cada %d s." % [cfg.maquina_n2_custo, cfg.maquina_n2_estoque, roundi(cfg.maquina_n2_intervalo)]],
	])
	var custos: PackedStringArray = []
	for c in cfg.mago_nivel_custo:
		custos.append(str(c))
	_aba("Luz e Sombra", "luz_sombra", [
		["chi", Estilo.OURO, "Kitsune da Luz (em cima)",
			"Cura e protege. Q: Cura da Luz. E: Bênção da Raposa (cura + escudo nos aliados)."],
		["chi", Estilo.AZUL, "Kitsune Sombria (embaixo)",
			"Ataca de longe. Q: Orbe Perfurante. E: Selo Sombrio (inimigos sem atacar)."],
		["losango", Estilo.VERMELHO, "Escolha um caminho",
			"Os dois terrenos de mago ficam em lados opostos do pátio. A primeira madeira num deles SELA o outro até o fim da partida."],
		["losango", Estilo.FANTASMA, "Níveis 2 a %d" % cfg.mago_nivel_max,
			"Pronta, a oficina já nasce no nível 2. Mais madeira sobe os níveis (%s madeiras). Cada nível: +%d%% de dano e vida, Chi mais rápido e a maquininha fabrica mais." % [", ".join(custos), roundi(cfg.mago_bonus_dano * 100.0)]],
	])
	_tabs.tab_changed.connect(_ao_trocar)
	_ao_trocar(_tabs.current_tab)


## Abre numa aba pelo nome (ex.: "Madeira").
func abrir(aba: String) -> void:
	for i in _tabs.get_tab_count():
		if _tabs.get_tab_title(i) == aba:
			_tabs.current_tab = i


func _ao_trocar(i: int) -> void:
	for c in _clipes.values():
		c.tocar(false)
	var aba := _tabs.get_tab_control(i)
	if aba and _clipes.has(aba.name):
		_clipes[aba.name].tocar(true)


## Aba padrão: clipe à esquerda, cartões (ícone, título, texto) à direita.
func _aba(titulo: String, pasta: String, cartoes: Array) -> void:
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	for c in cartoes:
		lista.add_child(_cartao(c[0], c[1], c[2], c[3]))
	_montar(titulo, pasta, lista)


func _aba_classes() -> void:
	var cfg = Config.cfg
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	# 4 papéis: a classe do pátio e as variações das oficinas.
	var papeis := [
		["Guerreiro", "Linha de frente, combo de 3 golpes.", ["guerreiro", "ronin_oni"]],
		["Atirador", "De longe; segure o clique para carregar o tiro.", ["arqueiro", "arqueiro_yumi"]],
		["Mago", "Cura ou amaldiçoa; fica atrás dos guerreiros.", ["kitsune", "kitsune_luz", "kitsune_sombria"]],
		["Construtor", "Corta madeira, ergue oficinas. Q: Corrida. E: Mutirão.", ["construtor", "armadilheiro", "bombardeiro"]],
	]
	for p in papeis:
		var linhas: PackedStringArray = []
		for id in p[2]:
			var path := "res://config/classes/%s.tres" % id
			if not ResourceLoader.exists(path):
				continue
			var s: ClassStats = load(path)
			var origem := "pátio" if s in cfg.hat_class_list else "oficina"
			linhas.append("%s (%s)  ·  Q: %s" % [s.display_name, origem, s.skill_name])
		var primeira: ClassStats = load("res://config/classes/%s.tres" % p[2][0])
		grade.add_child(_cartao(Icone.do_papel(primeira), Estilo.cor_time(0), p[0],
				p[1] + "\n" + "\n".join(linhas)))
	_montar("Classes", "classes", grade)


func _montar(titulo: String, pasta: String, conteudo: Control) -> void:
	var margem := MarginContainer.new()
	margem.name = titulo
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 14)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	margem.add_child(h)
	var clipe := TutorialClipe.novo("res://assets/tutorial/%s" % pasta, CLIPE_TAM, CLIPE_FPS)
	if clipe.tem_quadros():
		h.add_child(clipe)
		_clipes[titulo] = clipe
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(conteudo)
	h.add_child(rolagem)
	_tabs.add_child(margem)


## Cartão: ícone e título em cima, texto corrido embaixo.
func _cartao(icone: String, cor: Color, titulo: String, texto: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.placa(Estilo.LACA_CLARA, Color(Estilo.OURO, 0.6), 8))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(Icone.novo(icone, cor, 26))
	h.add_child(Estilo.rotulo(titulo.to_upper(), Estilo.T_MEDIO, cor, Estilo.NUMERO))
	v.add_child(h)
	var t := Estilo.rotulo(texto, Estilo.T_PEQUENO, Estilo.TEXTO)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(260, 0)
	v.add_child(t)
	return p
