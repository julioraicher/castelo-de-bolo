extends "res://tests/lib/caso.gd"
## Testes de regra: sistema. Rodam pelo tests/regras.gd, na ordem de lá.

## Alta dinâmica (Ciclo 2.19): a escada de degraus desliga primeiro os ajustes
## da Alta (resolução 80% -> sem glow -> sem contorno), depois cai de nível, e
## para na Mínima. Também confere a casca de contorno do cenário e o FXAA.
func _alta_dinamica() -> void:
	# Caça aos bugs 2026-11-15: o FXAA do Viewport não existe no Compatibility;
	# a Alta usa o nosso (camada de tela). Liga na Alta, desliga nas outras.
	var st = get_node("/root/Settings")
	var q0: int = st.quality
	st.quality = 3
	st._apply_quality_viewport()
	_check(st._fxaa != null and st._fxaa.visible and st._fxaa.layer < 1, "Alta: FXAA próprio ligado e abaixo do HUD")
	_check(get_viewport().screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED, "Alta: sem o FXAA do Viewport (não existe no Compatibility)")
	st.quality = 2
	st._apply_quality_viewport()
	_check(st._fxaa == null or not st._fxaa.visible, "Média: FXAA desligado")
	st.quality = q0
	st._apply_quality_viewport()
	var aq = load("res://scripts/fx/auto_quality.gd")
	_check(aq.degrau(3, 0) == Vector2i(3, 1), "alta dinâmica: 1º degrau é resolução 80%")
	_check(aq.degrau(3, 1) == Vector2i(3, 2), "alta dinâmica: 2º degrau é sem glow")
	_check(aq.degrau(3, 2) == Vector2i(3, 3), "alta dinâmica: 3º degrau é sem contorno")
	_check(aq.degrau(3, 3) == Vector2i(2, 0), "alta dinâmica: depois cai para a Média")
	_check(aq.degrau(2, 0) == Vector2i(1, 0), "alta dinâmica: Média cai para a Baixa")
	_check(aq.degrau(0, 0) == Vector2i(0, 0), "alta dinâmica: para na Mínima")
	var settings = get_node("/root/Settings")
	_check(settings.ALTA_AJUSTES.size() == 4, "alta dinâmica: 4 estados de ajuste")
	var arena = game.arena
	_check(arena.get_node_or_null("CascaContorno") != null, "casca de contorno existe no cenário")
	var casca = arena.get_node_or_null("CascaContorno")
	if casca:
		_check(casca.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "casca não projeta sombra")
		_check(casca.visible == (settings.quality >= 3), "casca aparece só na Alta")
	# Nos pedaços do cenário, nenhum material de cor pode manter o next_pass:
	# o contorno deles agora é a casca (senão pagaria as 2 chamadas de novo).
	var dupla := false
	for mi in arena.get_children():
		if mi is MeshInstance3D and String(mi.name).begins_with("Cenario_"):
			for s in mi.mesh.get_surface_count():
				var m = mi.mesh.surface_get_material(s)
				if m and m.next_pass:
					dupla = true
	_check(not dupla, "pedaços do cenário sem next_pass (contorno só na casca)")


## Ciclo 2.28: multiplayer em lockstep (comando, código da sala, sorteio com
## semente, trocar de time, quem sai vira bot).
func _multiplayer() -> void:
	var c = Comando.new()
	c.botoes = Comando.ATAQUE | Comando.ESQUIVA | Comando.SEGURA_F
	c.move = Vector2(0.7071, -0.7071)
	c.mira = Vector2(-0.6, 0.8)
	c.ponto = Vector3(-61.234, 1.5, 33.21)
	c.alvo = 9
	c.acao = Comando.Acao.TROCAR_TIME
	var b: PackedByteArray = c.para_bytes()
	var q = Comando.de_bytes(b)
	_check(b.size() == 17, "rede: comando tem 17 bytes (tem %d)" % b.size())
	_check(q.para_bytes() == b, "rede: comando ida e volta pelos bytes é idêntico")
	_check(q.botoes == c.botoes and q.alvo == 9 and q.acao == Comando.Acao.TROCAR_TIME, "rede: botões, alvo e ação chegam iguais")
	_check(q.ponto.distance_to(c.ponto) < 0.01 and q.move.distance_to(c.move) < 0.01 and q.mira.distance_to(c.mira) < 0.001, "rede: movimento e mira chegam com erro < 1 cm")

	var cod: String = CodigoSala.gerar("189.45.201.7")
	_check(cod.length() == 9 and cod[4] == "-", "rede: código da sala no formato XXXX-XXXX (%s)" % cod)
	_check(CodigoSala.ler(cod, 24680).get("ip", "") == "189.45.201.7", "rede: o código volta para o IP")
	_check(CodigoSala.ler(cod.to_lower().replace("-", " "), 24680).get("ip", "") == "189.45.201.7", "rede: código aceita minúscula e espaço")
	_check(CodigoSala.ler("26.10.0.5:1234", 24680) == {"ip": "26.10.0.5", "porta": 1234}, "rede: aceita o IP do Radmin com porta")
	var errado := cod.substr(0, 8) + ("0" if cod[8] != "0" else "1")
	_check(CodigoSala.ler(errado, 24680).is_empty(), "rede: código com uma letra errada é recusado")
	_check(CodigoSala.ip_privado("100.70.1.2") and CodigoSala.ip_privado("192.168.0.9") and not CodigoSala.ip_privado("189.45.201.7"), "rede: reconhece CGNAT e rede local")
	# 2.28c: código sorteado + recados cifrados (só quem tem o código lê).
	var cod_novo := CodigoSala.novo()
	_check(CodigoSala.ler(cod_novo, 24680).get("codigo", "") == cod_novo.replace("-", ""), "rede: código sorteado é lido como código (%s)" % cod_novo)
	_check(not CodigoSala.ler("26.10.0.5", 24680).has("codigo"), "rede: IP digitado não vira código")
	var sa := Sinal.new()
	var sb := Sinal.new()
	var sc := Sinal.new()
	sa._chave = Sinal._sha("cdb1-chave:" + cod_novo); sa._chave_mac = Sinal._sha("cdb1-mac:" + cod_novo)
	sb._chave = sa._chave; sb._chave_mac = sa._chave_mac
	sc._chave = Sinal._sha("cdb1-chave:OUTRO"); sc._chave_mac = Sinal._sha("cdb1-mac:OUTRO")
	var txt := sa._cifrar("{\"t\":\"oi\",\"de\":42}".to_utf8_buffer())
	_check(sb._decifrar(txt).get_string_from_utf8() == "{\"t\":\"oi\",\"de\":42}", "rede: recado cifrado volta igual com o mesmo código")
	_check(sc._decifrar(txt).is_empty(), "rede: outro código não lê o recado")
	var adulterado := Marshalls.base64_to_raw(txt)
	adulterado[20] = adulterado[20] ^ 1
	_check(sb._decifrar(Marshalls.raw_to_base64(adulterado)).is_empty(), "rede: recado adulterado é ignorado")
	_check(not txt.contains("\"") and not txt.contains(":"), "rede: o quadro de recados só vê lixo (sem o JSON aberto)")
	sa.free(); sb.free(); sc.free()

	var estado = Sorte.rng.state
	Sorte.semear(42)
	var s1 := [Sorte.f(), Sorte.i(), Sorte.r(-3, 3)]
	Sorte.semear(42)
	var s2 := [Sorte.f(), Sorte.i(), Sorte.r(-3, 3)]
	Sorte.rng.state = estado
	_check(s1 == s2, "rede: mesma semente, mesmo sorteio das regras")

	# Um bot do azul vira "amigo" de mentira (peer 99) e troca de time.
	var u = null
	for x in game.units:
		if x.team == 0 and not x.is_player and x.alive and x.brain is BotBrain:
			u = x
			break
	if u == null:
		_check(false, "rede: sem bot azul para o teste de trocar de time")
		return
	var h0: Array = game.humanos_time.duplicate()
	var bot_velho = u.brain
	u.remove_child(bot_velho)
	bot_velho.queue_free()
	var rb = RedeBrain.new()
	rb.unit = u
	rb.game = game
	rb.peer = 99
	rb.nome = "Teste"
	u.add_child(rb)
	u.brain = rb
	u.humano = true
	game.humanos_time[0] += 1
	game.cerebros[99] = rb
	var cmd = Comando.new()
	cmd.move = Vector2(1, 0)
	cmd.botoes = Comando.ESQUIVA
	rb.receber(cmd)
	rb.tick(0.016)
	_check(u.wants_dodge and u.move_intent.x > 0.99, "rede: o cérebro de rede aplica o comando (dash e andar)")
	game.trocar_time(rb)
	var novo = rb.unit
	_check(novo != u and novo.team == 1 and novo.humano and novo.brain == rb, "rede: trocar de time assume um bot do vermelho")
	_check(not u.humano and u.brain is BotBrain, "rede: o boneco antigo vira bot")
	_check(game.humanos_time[0] == h0[0] and game.humanos_time[1] == h0[1] + 1, "rede: contagem de humanos por time acompanha a troca")
	_check(game.units.size() == 16 or game.sandbox, "rede: continua 8 contra 8 depois da troca")
	# Ciclo 2.28d: tiro de humano congela o alvo um instante (regra). Antes só
	# valia se quem atirou era o jogador DESTE PC, e a partida online se separava.
	var alvo = null
	for v in game.units:
		if v.alive and v.team != novo.team and not v.humano:
			alvo = v
			break
	if alvo:
		alvo._intocavel_t = 0.0
		alvo._dodge_t = 0.0
		alvo._blocking = false
		alvo._hitstop_t = 0.0
		alvo.take_damage(1.0, novo, Vector3.RIGHT)
		_check(not novo.is_player and alvo._hitstop_t > 0.0, "rede: tiro do humano de outro PC também congela o alvo (igual em todos os PCs)")
	game.humano_saiu(99)
	_check(not novo.humano and novo.brain is BotBrain and not game.cerebros.has(99), "rede: quem sai vira bot")
	_check(game.caidos.has("Teste") and game.dica_fim() == "", "rede: quem caiu fica anotado (a linha só aparece online)")
	_check(game.humanos_time == h0, "rede: humanos por time voltam ao normal")


## Arena de chapéus (Ciclo 2.29): a lista do Tambor de Desafio e as fileiras.
func _arena_chapeus() -> void:
	var pool: Array = cfg.classes_arena()
	_check(not pool.has(cfg.villager), "arena: recruta fora do sorteio do tambor")
	for c in cfg.todas_classes():
		_check(pool.has(c), "arena: classe %s no sorteio do tambor" % c.id)
	var herois := 0
	for c in cfg.hat_classes():
		for h in c.caminhos:
			_check(pool.has(h), "arena: caminho %s no sorteio" % h.id)
		for h in c.herois:
			_check(pool.has(h), "arena: herói %s no sorteio" % h.id)
			herois += 1
	_check(herois == 14, "arena: 14 heróis raros no sorteio (tem %d)" % herois)
	var vistos := {}
	for c in pool:
		_check(not vistos.has(c.id), "arena: classe %s repetida no sorteio" % c.id)
		vistos[c.id] = true
	# Fileiras: cada uma centrada, com espaço entre vizinhos e avanços crescentes.
	var tams: Array[int] = [5, 8, 7, 6]
	var fileiras: Array = ModoTeste.fileiras_arena(tams)
	_check(fileiras.size() == 4, "arena: uma fileira por grupo")
	var avanco_ant := -1.0
	for f in fileiras.size():
		var linha: Array = fileiras[f]
		_check(linha.size() == tams[f], "arena: fileira %d com %d pads" % [f, tams[f]])
		var soma := 0.0
		for i in linha.size():
			soma += (linha[i] as Vector2).y
			if i > 0:
				_check((linha[i] as Vector2).y - (linha[i - 1] as Vector2).y >= 4.0, "arena: pads vizinhos a 4 m ou mais (fileira %d)" % f)
		_check(absf(soma) < 0.01, "arena: fileira %d centrada no eixo do portão" % f)
		_check((linha[0] as Vector2).x > avanco_ant, "arena: fileira %d mais à frente que a anterior" % f)
		avanco_ant = (linha[0] as Vector2).x
	# O nível da arena: base veste 1, caminho veste o máximo, herói um acima.
	var base: ClassStats = cfg.hat_classes()[0]
	_check(game.modo_teste.nivel_arena(base.id) == 1, "arena: classe base veste nível 1")
	if base.caminhos.size() > 0:
		_check(game.modo_teste.nivel_arena(base.caminhos[0].id) == cfg.mago_nivel_max, "arena: caminho veste o nível máximo")
	if base.herois.size() > 0:
		_check(game.modo_teste.nivel_arena(base.herois[0].id) == cfg.mago_nivel_max + 1, "arena: herói veste um nível acima do máximo")


## Revisão 3b: peças do mundo com base comum e no resumo da partida (IT-06/08/10).
func _pecas_do_mundo() -> void:
	# Resumo: placar + uma parte por boneco + uma por tipo de estrutura, cada uma com nome.
	var partes: PackedInt64Array = game.hash_partes()
	_check(partes.size() == 1 + game.units.size() + Game.PARTES_MUNDO.size(),
			"SINC: %d pedaços (esperado placar + %d bonecos + %d tipos de peça)" % [partes.size(), game.units.size(), Game.PARTES_MUNDO.size()])
	_check(game.descrever_parte(game.units.size() + 1) == Game.PARTES_MUNDO[0], "SINC: o pedaço depois dos bonecos tem nome")
	_check(game.hash_partes() == partes, "SINC: o resumo não muda se nada mudou")
	if game.torretas.size() > 0:
		var t: Torreta = game.torretas[0]
		var hp0 := t.hp
		t.hp += 1.0
		var i := 1 + game.units.size() + 1  # torretas e catapultas
		_check(game.hash_partes()[i] != partes[i], "SINC: vida de torreta entra no resumo")
		t.hp = hp0
	# Todo grupo de PecaDoMundo vem de uma filha e entra no resumo.
	var u = _lenhador()
	if u == null:
		_check(false, "peças do mundo: faltou boneco")
		return
	var teia := Teia.new()
	game.add_child(teia)
	teia.setup(game, u, u.global_position + Vector3(30, 0, 0))
	_check(teia is PecaDoMundo and teia.is_in_group(&"teias") and PecaDoMundo.GRUPOS.has(&"teias"), "peças: teia é PecaDoMundo no grupo do resumo")
	_check(game.hash_partes()[1 + game.units.size() + 4] != partes[1 + game.units.size() + 4], "SINC: teia nova entra no resumo")
	teia.sair()
	_check(teia.indo and not teia.is_in_group(&"teias"), "peças: sair() tira do grupo na hora")
	teia.sair()  # a segunda vez não faz nada
	# limitar: a mais antiga sai primeiro, as outras ficam.
	PecaDoMundo.limitar(get_tree(), u, &"traps", 1)  # tira as que o boneco já tinha
	var velhas: Array = []
	for k in 3:
		var tr := Trap.new()
		game.add_child(tr)
		tr.setup(game, u, u.global_position + Vector3(30, 0, 3.0 * k))
		tr.nasceu = k  # ordem conhecida
		velhas.append(tr)
	PecaDoMundo.limitar(get_tree(), u, &"traps", 2)
	_check(velhas[0].indo and velhas[1].indo and not velhas[2].indo, "peças: limitar(2) deixa só a mais nova antes da próxima")
	for tr in velhas:
		if not tr.indo:
			tr.sair()
	# Golpe no arco: de frente vale, de costas não, encostado vale qualquer ângulo.
	var fr := Vector3(0, 0, 1)
	_check(Game.no_arco(fr, Vector3(0.2, 0, 2), 2.0, 90.0, 0.8), "arco: alvo na frente acerta")
	_check(not Game.no_arco(fr, Vector3(0, 0, -2), 2.0, 90.0, 0.8), "arco: alvo atrás não acerta")
	_check(Game.no_arco(fr, Vector3(0, 0, -0.5), 0.5, 90.0, 0.8), "arco: encostado acerta de qualquer lado")
