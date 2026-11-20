class_name ModoTeste
extends RefCounted
## Modo teste (sandbox) e Arena de chapéus: o que só existe neles. Revisão 3a
## (NU-11): morava no game.gd. O Game cria um sempre (Game.modo_teste) e só
## chama montar_* quando o modo está ligado; fora deles as listas ficam vazias.
##  - Modo teste: torretas de pé, aliado caído de treino, Samurai de treino
##    (BrainPancada), herói de treino (BrainHeroiTreino), mostruário de itens e
##    as teclas [M] [L] [N] (regras()).
##  - Arena de chapéus (Ciclo 2.29): fileiras com o chapéu de toda classe e os
##    dois tambores que geram um inimigo na frente (gerar_inimigo_arena).

## Teto de inimigos gerados vivos ao mesmo tempo (PC fraco aguenta).
const ARENA_INIMIGOS_MAX := 6
## Mostruário (Ciclo 2.32): o item pego volta tantos segundos depois.
const MOSTRUARIO_VOLTA := 2.5

var game: Game
## Arena: [0] = Tambor de Desafio (classes base), [1] = Tambor dos Heróis (caminhos e heróis).
var botoes_arena: Array[BotaoArena] = []
## Arena: inimigos do tambor ainda em campo (Unit._respawn tira o que some).
var inimigos_arena: Array[Unit] = []
var _inimigo_arena_n := 0
## --arena-prova=N (QA): o tambor toca sozinho de N em N segundos.
var arena_prova := 0.0
var _arena_prova_t := 0.0
## Arena: nível que cada classe veste (base = 1, caminho = nível máximo do mago,
## herói = um acima). Montado na primeira consulta.
var _arena_niveis := {}
var _mostruario: Array = []  # [tipo ("espirito" ou item), posição, nó, espera]
var _teste_degrau := 1  # último degrau de multikill mostrado com [N]


func _init(g: Game) -> void:
	game = g


## Arena com --arena-prova=N: tambor sozinho (prova o sorteio, a briga e o sumiço).
func tick_arena_prova(delta: float) -> void:
	_arena_prova_t -= delta
	if _arena_prova_t <= 0.0:
		_arena_prova_t = arena_prova
		if inimigos_arena_vivos() < ARENA_INIMIGOS_MAX:
			gerar_inimigo_arena(_inimigo_arena_n % 2 == 1)


## Arena de chapéus (Ciclo 2.29): fileiras com o chapéu de cada classe na
## frente do portão do time do jogador (bases, depois caminhos, depois os
## heróis raros em duas fileiras) e o Tambor de Desafio no meio do caminho.
## O jogador nasce de frente para tudo.
func montar_arena_chapeus() -> void:
	var t := game.time_jogador
	var fr := game.arena.forward(t)
	var lado := Vector3.UP.cross(fr).normalized()
	var origem: Vector3 = game.arena.gate_spot[t]
	var bases := Config.cfg.hat_classes()
	var caminhos: Array[ClassStats] = []
	for c in Config.cfg.todas_classes():
		if c not in bases:
			caminhos.append(c)
	var herois: Array[ClassStats] = []
	for c in bases:
		for h in c.herois:
			if h not in herois:
				herois.append(h)
	var meio := ceili(herois.size() / 2.0)
	var fileiras: Array = [bases, caminhos, herois.slice(0, meio), herois.slice(meio)]
	var tams: Array[int] = []
	for f: Array in fileiras:
		tams.append(f.size())
	var posicoes := fileiras_arena(tams)
	for f in fileiras.size():
		for i in (fileiras[f] as Array).size():
			var pv: Vector2 = posicoes[f][i]
			var pad := HatPad.new()
			game.add_child(pad)
			pad.setup(t, fileiras[f][i], game.arena.clamp_to_arena(origem + fr * pv.x + lado * pv.y))
			game.hat_pads.append(pad)
	# Dois tambores, um de cada lado do caminho: o vermelho chama classe base
	# (briga simples), o dourado chama caminho ou herói raro.
	for k in 2:
		var b := BotaoArena.new()
		b.heroi = k == 1
		game.add_child(b)
		b.position = game.arena.clamp_to_arena(origem + fr * 3.0 + lado * (6.0 if k == 0 else -6.0))
		b.look_at(b.position - fr)  # baquetas para as fileiras, frente para quem chega
		botoes_arena.append(b)
	if game.player:
		game.player.global_position = game.arena.clamp_to_arena(origem + fr * 1.0)
		game.player.reset_physics_interpolation()


## Arena de chapéus: posições (avanço, lado) das fileiras de pads, cada uma
## centrada no eixo do portão. Separada para o teste de regra conferir.
## Números medidos no Rio das Lanternas: o portão fica a 21,5 m do castelo e
## o rio começa em |x| = 9; com primeira = 7 e entre = 5,75 a última fileira
## para a ~5 m da margem.
static func fileiras_arena(tamanhos: Array[int], espaco := 4.5, primeira := 7.0, entre := 5.75) -> Array:
	var out := []
	for f in tamanhos.size():
		var linha := []
		for i in tamanhos[f]:
			linha.append(Vector2(primeira + entre * f, (i - (tamanhos[f] - 1) * 0.5) * espaco))
		out.append(linha)
	return out


## Arena de chapéus: [F] no tambor. Nasce um inimigo de classe sorteada
## (qualquer uma, heróis inclusive) a 6 m na direção da mira do jogador.
## Ele briga (BotBrain ATTACK) e, quando a espera de renascer acaba, some
## em vez de voltar (Unit.descartavel).
func gerar_inimigo_arena(heroi := false) -> void:
	var pool := Config.cfg.classes_arena_herois() if heroi else Config.cfg.hat_classes()
	var cls: ClassStats = pool[Sorte.i() % pool.size()]
	var inimigo := 1 - game.time_jogador
	var dir: Vector3 = game.player.aim_dir
	dir.y = 0.0
	if dir.length() < 0.1:
		dir = game.arena.forward(game.time_jogador)
	dir = dir.normalized()
	var pos := game.arena.clamp_to_arena(game.player.global_position + dir * 6.0)
	var u := Unit.new()
	_inimigo_arena_n += 1
	u.name = "%s_arena_%d" % [Config.TEAM_NAMES[inimigo], _inimigo_arena_n]
	u.descartavel = true
	game.add_child(u)
	u.setup(game, inimigo, false, cls)
	u.global_position = pos
	u.reset_physics_interpolation()
	var bot := BotBrain.new()
	bot.unit = u
	bot.game = game
	bot.role = BotBrain.Role.ATTACK
	u.add_child(bot)
	u.brain = bot
	u.died.connect(game._on_unit_died)
	game.units.append(u)
	inimigos_arena.append(u)
	game._log("arena inimigo %s (%d em campo, t=%.0fs)" % [cls.id, inimigos_arena_vivos(), game._time])
	var b := botoes_arena[1 if heroi else 0] if botoes_arena.size() == 2 else null
	if b:
		b.acionar()
	Fx.pillar(game, pos, Config.team_color(inimigo), 2.2)
	Fx.burst(game, pos + Vector3(0, 1.2, 0), Config.team_color(inimigo).lightened(0.3), 18, 6.0)
	Sfx.play("renascer", pos, 0.04)
	if game.hud:
		game.hud.show_big("DUELO: %s!" % cls.display_name, Config.team_color(inimigo).lightened(0.35), 1.4)


func nivel_arena(id: StringName) -> int:
	if _arena_niveis.is_empty():
		for c in Config.cfg.hat_class_list:
			_arena_niveis[c.id] = 1
			for e in c.caminhos:
				_arena_niveis[e.id] = Config.cfg.mago_nivel_max
			for h in c.herois:
				_arena_niveis[h.id] = Config.cfg.mago_nivel_max + 1
	return int(_arena_niveis.get(id, 1))


## Inimigos do tambor ainda em campo (vivos ou caídos esperando sumir).
func inimigos_arena_vivos() -> int:
	var n := 0
	for u in inimigos_arena:
		if is_instance_valid(u):
			n += 1
	return n


## Modo teste: todas as casas do time do jogador prontas (no primeiro
## caminho; [F] sobe o nível e, no máximo, troca o caminho) e as
## barraquinhas no nível 2.
func montar_sandbox() -> void:
	game._montando_sandbox = true
	# Ciclo 2.22: casas do zero (barraquinhas no Nv1, madeira infinita, obra
	# sandbox_obra_mult × mais rápida); a escolha do caminho vale (F5 = outra).
	# Torretas dos dois lados de pé: a inimiga serve de treino de escudo.
	for t in game.torretas:
		t.concluir_ja()
	game._montando_sandbox = false
	_aliado_de_treino()
	_inimigo_de_treino()
	_heroi_de_treino()
	_montar_mostruario()


func _montar_mostruario() -> void:
	var fr := game.arena.forward(game.time_jogador)
	var lado := Vector3.UP.cross(fr).normalized()
	var base: Vector3 = game.arena.gate_spot[game.time_jogador] + fr * 9.0
	var tipos: Array = Pickup.KINDS.duplicate()
	tipos.append("espirito")
	for i in tipos.size():
		_mostruario.append([tipos[i], base + lado * (i - 2.5) * 2.4, null, 0.0])


func _tick_mostruario(delta: float) -> void:
	for slot: Array in _mostruario:
		var no: Variant = slot[2]  # pode já ter sido apagado (pego)
		if is_instance_valid(no) and not (no as Node).is_queued_for_deletion() \
				and (game.pickups.has(no) if slot[0] != "espirito" else game.cakes.has(no)):
			continue
		slot[3] -= delta
		if slot[3] > 0.0:
			continue
		slot[3] = MOSTRUARIO_VOLTA
		var p: Vector3 = slot[1]
		p.y = game.arena.ground_y(p.x, p.z, p.y + 5.0)  # aqui a física já está de pé
		slot[1] = p
		if slot[0] == "espirito":
			var c := Cake.new()
			game.add_child(c)
			c.global_position = slot[1]
			game.cakes.append(c)
			slot[2] = c
		else:
			var it := Pickup.new()
			game.add_child(it)
			it.setup(slot[0], slot[1])
			game.pickups.append(it)
			slot[2] = it


## Modo teste: um aliado sem cérebro, caído na frente do portão, para treinar
## a reanimação (Reanimar.treino: não renasce sozinho e cai de novo 4 s
## depois de levantar).
func _aliado_de_treino() -> void:
	var u := Unit.new()
	u.name = "%s_treino" % Config.TEAM_NAMES[game.time_jogador]
	game.add_child(u)
	u.setup(game, game.time_jogador, false, load("res://config/classes/guerreiro.tres"))
	u.global_position = game.arena.gate_spot[game.time_jogador] + game.arena.forward(game.time_jogador) * 13.0
	u.reset_physics_interpolation()
	u.died.connect(game._on_unit_died)
	game.placar.registrar(u, game.time_jogador, 1, false)
	game.units.append(u)
	game.reanimar.treino(u)


## Modo teste (Ciclo 2.26): Samurai inimigo de treino (BrainPancada) ao lado
## do aliado caído: defende, bate e fica parado em ciclo, para treinar a guarda
## que quebra, o rastro da barra, a borda do golpe forte e o respingo.
func _inimigo_de_treino() -> void:
	var inimigo := 1 - game.time_jogador
	var u := Unit.new()
	u.name = "%s_pancada" % Config.TEAM_NAMES[inimigo]
	game.add_child(u)
	u.setup(game, inimigo, false, load("res://config/classes/guerreiro.tres"))
	var fr := game.arena.forward(game.time_jogador)
	var lado := Vector3.UP.cross(fr).normalized()
	var casa: Vector3 = game.arena.gate_spot[game.time_jogador] + fr * 13.0 + lado * 5.0
	u.global_position = casa
	u.reset_physics_interpolation()
	var b := BrainPancada.new()
	b.unit = u
	b.game = game
	b.casa = casa
	u.add_child(b)
	u.brain = b
	u.died.connect(game._on_unit_died)
	game.placar.registrar(u, inimigo, 1, false)
	game.units.append(u)
	game.pancada = u


## Modo teste (Ciclo 2.34): herói inimigo machucado e parado do outro lado do
## Samurai de treino, para treinar a finalização (BrainHeroiTreino).
func _heroi_de_treino() -> void:
	var inimigo := 1 - game.time_jogador
	var u := Unit.new()
	u.name = "%s_heroi_treino" % Config.TEAM_NAMES[inimigo]
	game.add_child(u)
	u.setup(game, inimigo, false, load(BrainHeroiTreino.HEROIS[0]))
	var fr := game.arena.forward(game.time_jogador)
	var lado := Vector3.UP.cross(fr).normalized()
	var casa: Vector3 = game.arena.gate_spot[game.time_jogador] + fr * 13.0 - lado * 5.0
	u.global_position = casa
	u.reset_physics_interpolation()
	var b := BrainHeroiTreino.new()
	b.unit = u
	b.game = game
	b.casa = casa
	u.add_child(b)
	u.brain = b
	b.vestir()
	u.died.connect(game._on_unit_died)
	game.placar.registrar(u, inimigo, 1, false)
	game.units.append(u)
	game.heroi_treino = u


## Modo teste: maquininhas repõem o chapéu em 1 s (as casas sobem pela
## escada normal, com madeira infinita: Game.gastar_madeira).
func regras(hint: String) -> String:
	for pad in game.hat_pads:
		pad.intervalo = minf(pad.intervalo, 1.0)
	_tick_mostruario(game.get_physics_process_delta_time())
	# Ciclo 2.25: o modo teste não tem relógio nem inimigos. [M] chama a morte
	# súbita e [N] mostra o letreiro do multikill (duplo, triplo, multi ×4...).
	if Input.is_action_just_pressed("teste_multikill") and game.player:
		_teste_degrau = 2 if _teste_degrau >= 5 else _teste_degrau + 1
		game._multikill(game.player, _teste_degrau, Placar.bonus_degrau(_teste_degrau, Config.cfg))
	# Ciclo 2.31: [L] liga o relógio a 1:10 do fim (último minuto leve,
	# prorrogação e fim de verdade, como numa partida).
	if Input.is_action_just_pressed("teste_relogio") and not game._relogio_teste and not game.game_over:
		game._relogio_teste = true
		game.tempo_partida = Config.cfg.tempo_limite - 70.0
	if game.morte_subita < 0.0 and not game.game_over:
		if Input.is_action_just_pressed("teste_morte_subita"):
			game.abrir_morte_subita()
		elif hint == "" and game.player and game.player.alive:
			for p in game.princesses:
				if game.player.global_position.distance_to(p.home) < 9.0:
					hint = "Modo teste: [M] morte súbita  ·  [L] último minuto do relógio  ·  [N] letreiro do multikill"
	return hint
