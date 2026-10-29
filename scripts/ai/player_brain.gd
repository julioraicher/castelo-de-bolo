class_name PlayerBrain
extends Node
## Converte teclado + mouse em intenções para a Unit do jogador.
## WASD anda, o mouse mira, clique esquerdo ataca, direito (ou Q) usa o
## especial, Espaço esquiva, E interage.

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
	unit.wants_attack = Input.is_action_pressed("attack")
	unit.wants_special = Input.is_action_pressed("special")
	if Input.is_action_just_pressed("dodge"):
		unit.wants_dodge = true
	interact_pressed = Input.is_action_just_pressed("interact")
