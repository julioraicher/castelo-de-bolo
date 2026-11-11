class_name Tutorial
extends VBoxContainer
## Seção "Como jogar" do menu: abas Objetivo, Madeira, Oficinas, Torreta,
## Catapulta e Luz e Sombra. Cada aba tem um clipe grande gravado do jogo
## (quadros JPG em assets/tutorial/<pasta>/00.jpg..., cenas roteirizadas de
## ClipeCenas) e no máximo 3 cartões curtos ao lado. Os quadros só carregam
## quando a aba abre (o navegador é fraco). Sem quadros, a aba mostra só o texto.
## Visual só com Estilo.*; números vêm do game_config, então mudar um custo
## lá atualiza o texto aqui.

const CLIPE_FPS := 7.5
const CLIPE_TAM := Vector2(500, 281)

var _tabs: TabContainer
var _clipes: Dictionary = {}  # aba -> TutorialClipe
var _ativo := false


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	var cfg = Config.cfg
	_aba("Objetivo", "objetivo", [
		["mascara", Estilo.cor_time(0), "Roube a máscara",
			"A Máscara Oni inimiga fica no pedestal do castelo deles. Chegue perto, aperte F e leve até o SEU pedestal. Primeiro a %d pontos vence." % cfg.score_to_win],
		["espirito", Estilo.FANTASMA, "Espíritos pesam",
			"Chamas verdes nascem no meio do mapa. Leve até a sua máscara: cheia, ela pesa e o ladrão anda devagar."],
		["recruta", Estilo.TEXTO_FRACO, "Caiu? Recomeça",
			"Quem morre volta como Recruta no castelo. Pegue um chapéu no pátio para virar uma classe de novo."],
		["losango", Estilo.OURO, "Relógio de %d minutos" % roundi(cfg.tempo_limite / 60.0),
			"No zero, vence quem tem mais pontos; igual é empate. Se uma máscara estiver sendo levada, a partida segue até ela chegar, cair ou voltar (Última corrida, até %d s)." % roundi(cfg.prorrogacao_max)],
	])
	_aba("Madeira", "madeira", [
		["martelo", Estilo.OURO, "Só o Construtor corta",
			"Siga a seta dourada até uma árvore crescida e clique colado nela. Cada golpe solta uma tora (árvore rende %d, bambu %d)." % [cfg.arvore_toras, cfg.bambu_varas]],
		["martelo", Estilo.OURO, "Pegue e entregue",
			"Passe por cima da tora e ela vem nos braços (1 por vez, %d%% mais devagar). Leve ao DEPÓSITO do castelo: soma em \"Madeira do time\"." % roundi((1.0 - cfg.tora_vel_mult) * 100.0)],
		["martelo", Estilo.OURO, "Construa",
			"Fique perto de um terreno do pátio: a obra puxa a madeira do time e sobe enquanto houver Construtor ali. A árvore volta a crescer (%d s por estágio)." % roundi(cfg.arvore_tempo_estagio)],
	])
	_aba("Casas", "oficinas", [
		["katana", Estilo.OURO, "Barraquinha (níveis 1 e 2)",
			"Cada classe tem um bairro no pátio. A barraquinha fabrica o chapéu dela (F perto). No nível 1 o Super (R) da classe fica travado: um Construtor parado no bairro gasta %d madeiras e ela sobe ao 2." % cfg.casa_nv2_custo],
		["martelo", Estilo.OURO, "Nível 3: escolha o caminho",
			"No nível 2, o Construtor aperta F no bairro e clica num dos dois caminhos (fora da briga). A casa dele sobe atrás (%d madeiras, +%d por casa que o time já fez) e o outro fica SELADO até o fim." % [cfg.oficina_custo_madeira, cfg.oficina_custo_degrau]],
		["losango", Estilo.OURO, "Níveis 4 e 5: as duas juntas",
			"Pronta, a casa nasce no nível 3 junto com a barraquinha. Daí cada subida leva as duas: peça nova no telhado, +1 chapéu, fabricação mais rápida."],
	])
	_aba("Herói raro", "heroi", [
		["losango", Estilo.OURO_CLARO, "Nível 6: o herói do bairro",
			"Com o bairro no nível 5, o Construtor aperta F e escolhe um herói raro da classe (Samurai: Sumotori ou Kappa; Shuriken: Yamabushi, Karasu Tengu ou Mujina; Kitsune: Onmyoji, Tennin ou Komusō). O Construtor não tem herói."],
		["martelo", Estilo.OURO, "Pavilhão dourado (%d madeiras)" % cfg.heroi_custo,
			"Sobe no tapete do caminho, ao lado da casa. Com madeira no depósito, o tapete brilha e a estrela pisca no minimapa. Pronto, dá +1 nível de bônus para o bairro."],
		["katana", Estilo.OURO_CLARO, "Um chapéu só",
			"O pavilhão guarda um chapéu, que não é fabricado. Ele volta %d s depois que o herói sai de campo de vez (caído ainda conta como em campo)." % roundi(cfg.heroi_retorno)],
	])
	_aba("Torreta", "torreta", [
		["martelo", Estilo.OURO, "Posto da raposa (%d madeiras)" % cfg.torreta_custo,
			"Selo TORRETA no chão, na frente do castelo. Depois da 1ª casa, o Construtor leva madeira até lá e ergue uma besta encantada que atira no inimigo mais perto."],
		["shuriken", Estilo.AZUL, "O escudo devolve",
			"Defenda (botão direito) virado para o virote: ele volta e acerta a própria torreta. Para derrubar de vez, bata nela."],
	])
	_aba("Catapulta", "catapulta", [
		["mascara", Estilo.VERMELHO, "Suba com F",
			"Na base do seu castelo, F sobe na mão do Oni. A barra de força vai e volta; o ponto de queda aparece no chão e no minimapa."],
		["chi", Estilo.OURO, "Meteoro de Chi",
			"F de novo lança. Você voa sem levar dano e cai com dano e empurrão em volta (%d de dano, raio %.1f m)." % [roundi(cfg.catapulta_dano), cfg.catapulta_raio]],
	])
	var custos: PackedStringArray = []
	for c in cfg.mago_nivel_custo:
		custos.append(str(c))
	var linhas: Array = []
	for base in cfg.hat_classes():
		if base.caminhos.size() < 2:
			continue
		var a: ClassStats = base.caminhos[0]
		var b: ClassStats = base.caminhos[1]
		# Título curto (só a classe): com os dois nomes ele quebrava em 3 linhas
		# e o último cartão saía da moldura.
		linhas.append([Icone.do_papel(base), base.hat_color, base.display_name,
			"%s (%s, E: %s) ou %s (%s, E: %s)." % [a.display_name, a.caminho_nome, a.power_name, b.display_name, b.caminho_nome, b.power_name]])
	linhas.append(["losango", Estilo.VERMELHO, "Níveis 3 a %d" % cfg.mago_nivel_max,
		"Barraquinha e casa sobem juntas (%s madeiras): +%d%% de dano e vida por nível acima do 2." % [" e ".join(custos), roundi(cfg.mago_bonus_dano * 100.0)]])
	_aba("Caminhos", "luz_sombra", linhas)
	_tabs.tab_changed.connect(_ao_trocar)


## Abre numa aba pelo nome (ex.: "Madeira").
func abrir(aba: String) -> void:
	for i in _tabs.get_tab_count():
		if _tabs.get_tab_title(i) == aba:
			_tabs.current_tab = i


## A seção está na tela? Só então o clipe da aba roda (e carrega).
func ativo(sim: bool) -> void:
	_ativo = sim
	_ao_trocar(_tabs.current_tab)


func _ao_trocar(i: int) -> void:
	for c in _clipes.values():
		c.tocar(false)
	var aba := _tabs.get_tab_control(i)
	if _ativo and aba and _clipes.has(aba.name):
		_clipes[aba.name].tocar(true)


## Aba padrão: clipe grande à esquerda, cartões (ícone, título, texto) à direita.
func _aba(titulo: String, pasta: String, cartoes: Array) -> void:
	var margem := MarginContainer.new()
	margem.name = titulo
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	margem.add_child(h)
	var clipe := TutorialClipe.novo("res://assets/tutorial/%s" % pasta, CLIPE_TAM, CLIPE_FPS)
	if clipe.tem_quadros():
		var moldura := PanelContainer.new()
		moldura.add_theme_stylebox_override("panel", Estilo.placa(Estilo.TINTA, Color(Estilo.OURO, 0.7), 8))
		moldura.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		moldura.add_child(clipe)
		h.add_child(moldura)
		_clipes[titulo] = clipe
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in cartoes:
		lista.add_child(_cartao(c[0], c[1], c[2], c[3]))
	# Rolagem: com muitos cartões (Caminhos) o último saía por baixo da moldura.
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lista)
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
	# O título quebra linha: "NINJA DE SHURIKEN: ARQUEIRO YUMI OU KUSARIGAMA"
	# empurrava o cartão para fora da moldura.
	var tt := Estilo.rotulo(titulo.to_upper(), Estilo.T_MEDIO, cor, Estilo.NUMERO)
	tt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tt.custom_minimum_size = Vector2(200, 0)
	h.add_child(tt)
	v.add_child(h)
	var t := Estilo.rotulo(texto, Estilo.T_PEQUENO, Estilo.TEXTO)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(300, 0)
	v.add_child(t)
	return p
