extends Node
## Testes de regra: conferem números do jogo que um bug pode quebrar sem
## erro de script (a fumaça do CI não pega). Rodam dentro de uma partida real:
##   godot --headless --path . -- --autoplay --testes --semente=1234
## Imprime "TESTES OK" ou cada falha e sai com código 1.
##
## Os testes moram em tests/regras/<sistema>.gd (base em tests/lib/caso.gd);
## este arquivo só chama na ORDEM abaixo, que importa (o estado da partida é um
## só: o peso da máscara vem antes de qualquer teste mexer nele, e o relógio,
## que encerra a partida, por último). Regra nova que importa = um _check no
## arquivo do sistema; teste novo = uma linha na ORDEM.

var game  # Game (sem tipo: o script é carregado em tempo de execução)
var _falhas: Array[String] = []
var _total := 0
var _erros  # contador_erros.gd: erro de script no meio de um teste também reprova
## Piso de checagens: se uma função de teste abortar no meio, o total cai.
## Baixe só quando tirar testes de propósito.
const MIN_CHECAGENS := 1400

## [arquivo em tests/regras/, função]. Teste com await espera sozinho.
const ORDEM := [
	["dados", "_dados"],
	["dados", "_glifos"],
	["partida", "_mascara_pesada"],
	["combate", "_dano"],
	["combate", "_contra_golpe"],
	["combate", "_guarda_quebra"],
	["combate", "_carga"],
	["poderes", "_poderes_q"],
	["poderes", "_sohei_kusarigama"],
	["combate", "_controles"],
	["combate", "_travas"],
	["combate", "_empurrao"],
	["economia", "_madeira"],
	["economia", "_machadada"],
	["economia", "_maquina"],
	["economia", "_obra"],
	["economia", "_nivel2"],
	["economia", "_caminho_magos"],
	["combate", "_dash_estilos"],
	["partida", "_alma"],
	["economia", "_ferradura"],
	["poderes", "_chi_tempo_e_tiro_forte"],
	["poderes", "_super"],
	["poderes", "_super_uma_vez"],
	["poderes", "_super_nivel1"],
	["economia", "_torretas"],
	["economia", "_catapulta"],
	["partida", "_equilibrio_classes"],
	["partida", "_respawn_cresce"],
	["partida", "_bolo_mascara_cheia"],
	["combate", "_mira"],
	["partida", "_placar"],
	["reanimar", "_reanimar"],
	["reanimar", "_finalizar"],
	["sistema", "_alta_dinamica"],
	["itens", "_itens"],
	["itens", "_configuracoes_salvas"],
	["poderes", "_magia"],
	["dados", "_assinaturas"],
	["herois", "_heroi_nv6"],
	["herois", "_herois_regras"],
	["herois", "_herois_elementos"],
	["herois", "_herois_natureza"],
	["herois", "_predero"],
	["herois", "_bots_herois"],
	["partida", "_menos_empate"],
	["sistema", "_multiplayer"],
	["sistema", "_arena_chapeus"],
	["sistema", "_pecas_do_mundo"],
	["poderes", "_poderes_revisados"],
	["poderes", "_registro_poderes"],
	["dados", "_rio_sem_ilha"],
	["dados", "_sons_proprios"],
	["partida", "_relogio"],
]


func _ready() -> void:
	_erros = load("res://tests/contador_erros.gd").instalar()
	# Espera a partida montar e os bonecos nascerem.
	await get_tree().create_timer(0.5).timeout
	_parar_bots()
	var cfg = get_node("/root/Config").cfg
	var casos := {}
	var tempo := {}
	for par in ORDEM:
		var arq: String = par[0]
		if not casos.has(arq):
			var c: Node = load("res://tests/regras/%s.gd" % arq).new()
			c.name = "Teste_" + arq
			c.set("game", game)
			c.set("cfg", cfg)
			c.set("_runner", self)
			add_child(c)
			casos[arq] = c
		var t0 := Time.get_ticks_msec()
		await casos[arq].call(par[1])
		tempo[arq] = tempo.get(arq, 0) + Time.get_ticks_msec() - t0
	if _erros.relatar("TESTES") > 0:
		_falhas.append("erro de script/motor durante os testes (veja ERRO DURANTE O TESTE acima)")
	if _total < MIN_CHECAGENS:
		_falhas.append("só %d checagens rodaram (piso %d): algum teste parou no meio" % [_total, MIN_CHECAGENS])
	var partes: Array[String] = []
	for arq in tempo:
		partes.append("%s %.1f s" % [arq, tempo[arq] / 1000.0])
	print("TESTES TEMPO: ", ", ".join(partes))
	print("TESTES: %d/%d ok" % [_total - _falhas.size(), _total])
	if _falhas.is_empty():
		print("TESTES OK")
	for f in _falhas:
		print("TESTE FALHOU: ", f)
	get_tree().quit(1 if not _falhas.is_empty() else 0)


func _check(ok: bool, nome: String) -> void:
	_total += 1
	if not ok:
		_falhas.append(nome)


## Bots parados durante os testes (revisão 2026-11-19, TS-02): com a IA parada
## (BotBrain.parado), o resto do mundo fica quieto e o resultado não depende de onde
## os bots andaram nem da semente. O cérebro continua lá (quem pergunta "é bot?" vê
## que é); teste que precisa da IA chama o cérebro direto.
const INTENCOES := ["wants_attack", "wants_block", "wants_quick", "wants_power", "wants_super",
		"wants_dodge", "wants_reanimar", "wants_interact"]


func _parar_bots() -> void:
	for u in game.units:
		if u.brain is BotBrain:
			u.brain.parado = true
		u.move_intent = Vector3.ZERO
		for w in INTENCOES:
			u.set(w, false)

