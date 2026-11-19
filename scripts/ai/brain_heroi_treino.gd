class_name BrainHeroiTreino
extends Node
## Modo teste (Ciclo 2.34): herói inimigo de treino para a FINALIZAÇÃO. Fica
## parado na frente do portão, chega machucado (vida_inicial da vida) e não
## revida: derrube, segure [F] colado no corpo e veja o golpe da sua
## personalidade. Depois de renascer volta ao mesmo lugar como o próximo herói
## da lista (cada um cai de um jeito).

const HEROIS := ["res://config/classes/sumotori.tres", "res://config/classes/tennin.tres", "res://config/classes/jorogumo.tres", "res://config/classes/karasu_tengu.tres"]
const VIDA_INICIAL := 0.25

var unit: Unit
var game: Game
var casa := Vector3.ZERO
var _i := 0


func tick(_delta: float) -> void:
	unit.move_intent = Vector3.ZERO
	unit.wants_attack = false
	unit.wants_block = false
	unit.wants_dodge = false
	unit.wants_power = false
	unit.wants_super = false
	unit.wants_quick = false
	# Renasceu (recruta, no castelo inimigo): volta como o próximo herói.
	if not unit.stats.heroi or unit.global_position.distance_to(casa) > 6.0:
		if not unit.stats.heroi:
			_i = (_i + 1) % HEROIS.size()
			vestir()
		unit.global_position = casa
		unit.velocity = Vector3.ZERO
		unit.reset_physics_interpolation()
	var alvo := game.player
	if alvo and alvo.alive:
		var to := alvo.global_position - unit.global_position
		to.y = 0.0
		if to.length() > 0.1 and to.length() < 14.0:
			unit.aim_dir = to.normalized()


func vestir() -> void:
	unit.set_class(load(HEROIS[_i]))
	unit.hp = unit.max_hp() * VIDA_INICIAL
	unit._update_hp_bar()
