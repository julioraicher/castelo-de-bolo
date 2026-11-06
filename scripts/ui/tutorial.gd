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
	])
	_aba("Madeira", "madeira", [
		["martelo", Estilo.OURO, "Só o Construtor corta",
			"Siga a seta dourada até uma árvore crescida e clique colado nela. Cada golpe solta uma tora (árvore rende %d, bambu %d)." % [cfg.arvore_toras, cfg.bambu_varas]],
		["martelo", Estilo.OURO, "Pegue e entregue",
			"Passe por cima da tora e ela vem nos braços (1 por vez, %d%% mais devagar). Leve ao DEPÓSITO do castelo: soma em \"Madeira do time\"." % roundi((1.0 - cfg.tora_vel_mult) * 100.0)],
		["martelo", Estilo.OURO, "Construa",
			"Fique perto de um terreno do pátio: a obra puxa a madeira do time e sobe enquanto houver Construtor ali. A árvore volta a crescer (%d s por estágio)." % roundi(cfg.arvore_tempo_estagio)],
	])
	_aba("Oficinas", "oficinas", [
		["katana", Estilo.OURO, "Maquininhas do pátio",
			"Cada uma fabrica um chapéu a cada %d s (até %d). Chegue perto e aperte F para trocar de classe." % [roundi(cfg.maquina_intervalo), cfg.maquina_estoque_max]],
		["martelo", Estilo.OURO, "Oficinas (%d madeiras)" % cfg.oficina_custo_madeira,
			"Terrenos vazios viram oficinas de classes novas: Ronin Oni ou Arqueiro Yumi. Perto do terreno, F troca qual construir."],
		["losango", Estilo.OURO, "Nível 2",
			"A maquininha sobe de nível quando a oficina da variação dela fica pronta, ou com %d madeiras de um Construtor: até %d chapéus, um a cada %d s." % [cfg.maquina_n2_custo, cfg.maquina_n2_estoque, roundi(cfg.maquina_n2_intervalo)]],
	])
	_aba("Torreta", "torreta", [
		["martelo", Estilo.OURO, "Posto da raposa (%d madeiras)" % cfg.torreta_custo,
			"Selo TORRETA no chão, na frente do castelo. Depois da 1ª oficina, o Construtor leva madeira até lá e ergue uma besta encantada que atira no inimigo mais perto."],
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
	_aba("Luz e Sombra", "luz_sombra", [
		["chi", Estilo.OURO, "Kitsune da Luz",
			"Cura e protege. Q: Cura da Luz. E: Bênção da Raposa, cura mais escudo nos aliados."],
		["chi", Estilo.AZUL, "Kitsune Sombria",
			"Ataca de longe. Q: Orbe Perfurante. E: Selo Sombrio, inimigos em volta sem atacar."],
		["losango", Estilo.VERMELHO, "Um caminho só, até o nível %d" % cfg.mago_nivel_max,
			"Os dois terrenos ficam em lados opostos do pátio: a primeira madeira num deles SELA o outro. Mais madeira sobe os níveis (%s): +%d%% de dano e vida por nível." % [", ".join(custos), roundi(cfg.mago_bonus_dano * 100.0)]],
	])
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
	h.add_child(lista)
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
	t.custom_minimum_size = Vector2(300, 0)
	v.add_child(t)
	return p
