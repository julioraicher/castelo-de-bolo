class_name PlayerBrain
extends Node
## Converte teclado + mouse em intenções para a Unit do jogador.
## WASD anda, o mouse mira, clique esquerdo ataca, direito defende (segurar),
## Q = habilidade rápida, E = poder de Chi, Espaço esquiva, F interage.

var unit: Unit
var game: Game
var interact_pressed := false


func tick(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# A câmera olha para -Z sem girar, então "cima" na tela = -Z no mundo.
	unit.move_intent = Vector3(input.x, 0, input.y)
	var aim_point := game.camera.mouse_ground_point()
	var to := aim_point - unit.global_position
	to.y = 0
	if to.length() > 0.2:
		unit.aim_dir = to.normalized()
	unit.aim_point = aim_point
	# Clicou em cima de um inimigo? O tiro vai nele, em qualquer altura.
	unit.aim_unit = game.camera.mira_unidade
	unit.wants_attack = Input.is_action_pressed("attack")
	# Enfeite do cursor sai antes do corpo gastar o poder/recarga.
	if game.mira:
		if Input.is_action_just_pressed("attack"):
			game.mira.evento("atk", unit.alive)
		if Input.is_action_just_pressed("quick") and unit.tem_rapida():
			game.mira.evento("q", unit.quick_ready())
		if Input.is_action_just_pressed("power"):
			game.mira.evento("e", unit.power_ready())
	unit.wants_block = Input.is_action_pressed("block")
	if Input.is_action_just_pressed("quick"):
		unit.wants_quick = true
	if Input.is_action_just_pressed("power"):
		unit.wants_power = true
	if Input.is_action_just_pressed("super"):
		unit.wants_super = true
	if Input.is_action_just_pressed("dodge"):
		unit.wants_dodge = true
	interact_pressed = Input.is_action_just_pressed("interact")
	unit.wants_interact = interact_pressed
	unit.wants_reanimar = Input.is_action_pressed("interact")
	# Painel da escolha do caminho aberto: o clique é do botão, não do golpe.
	if game.hud and game.hud.escolha_aberta():
		unit.wants_attack = false
		unit.wants_block = false


## Partida online (Ciclo 2.28): lê teclado e mouse para um Comando em vez de
## mexer no corpo. Quem aplica é o RedeBrain, no quadro + atraso, em todos os
## PCs. Os toques (Q, E, R, dash, F) a Rede junta à parte, para não perder
## aperto enquanto o quadro espera a rede.
func amostrar(c: Comando) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	c.move = input
	var ponto := game.camera.mouse_ground_point()
	var to := ponto - unit.global_position
	to.y = 0
	if to.length() > 0.2:
		var d := to.normalized()
		c.mira = Vector2(d.x, d.z)
	c.ponto = ponto
	c.alvo = game.units.find(game.camera.mira_unidade) if game.camera.mira_unidade else -1
	if Input.is_action_pressed("attack"):
		c.botoes |= Comando.ATAQUE
	if Input.is_action_pressed("block"):
		c.botoes |= Comando.DEFESA
	if Input.is_action_pressed("interact"):
		c.botoes |= Comando.SEGURA_F
	if game.mira:
		if Input.is_action_just_pressed("attack"):
			game.mira.evento("atk", unit.alive)
		if Input.is_action_just_pressed("quick") and unit.tem_rapida():
			game.mira.evento("q", unit.quick_ready())
		if Input.is_action_just_pressed("power"):
			game.mira.evento("e", unit.power_ready())
	if game.hud and game.hud.escolha_aberta():
		c.botoes &= ~(Comando.ATAQUE | Comando.DEFESA)
