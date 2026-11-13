class_name BrainPancada
extends Node
## Modo teste (Ciclo 2.26): Samurai inimigo de treino na frente do portão.
## Ciclo fixo para treinar a porrada: defende 4 s (quebre a guarda dele),
## bate 2,5 s se você estiver perto (sinta o golpe forte), fica parado 2,5 s
## (veja o respingo e o rastro da barra). Sem apanhar por 3 s, cura tudo; se
## cair, renasce no mesmo lugar.

const DEFENDE := 4.0
const ATACA := 2.5
const PARADO := 2.5

var unit: Unit
var game: Game
var casa := Vector3.ZERO
var _t := 0.0


func tick(delta: float) -> void:
	_t = fmod(_t + delta, DEFENDE + ATACA + PARADO)
	unit.move_intent = Vector3.ZERO
	unit.wants_attack = false
	unit.wants_block = false
	unit.wants_dodge = false
	var alvo := game.player
	var to := Vector3.ZERO
	if alvo and alvo.alive:
		to = alvo.global_position - unit.global_position
		to.y = 0.0
	if to.length() > 0.1 and to.length() < 12.0:
		unit.aim_dir = to.normalized()
	# Renasceu no castelo inimigo: volta para o ponto de treino.
	if unit.global_position.distance_to(casa) > 6.0:
		unit.global_position = casa
		unit.velocity = Vector3.ZERO
		unit.reset_physics_interpolation()
	if unit._calm_t > 3.0 and unit.hp < unit.max_hp():
		unit.hp = unit.max_hp()
		unit._update_hp_bar()
	if _t < DEFENDE:
		unit.wants_block = to.length() < 8.0
	elif _t < DEFENDE + ATACA:
		if to.length() < 6.0 and to.length() > unit.stats.attack_range * 0.8:
			unit.move_intent = to.normalized()
		unit.wants_attack = to.length() <= unit.stats.attack_range + 0.3
