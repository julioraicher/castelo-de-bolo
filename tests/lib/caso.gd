extends Node
## Base dos testes de regra por sistema (tests/regras/*.gd; revisão 2026-11-19, TS-03/04/05).
## O runner (tests/regras.gd) cria um de cada, preenche game/cfg e chama os testes na
## ordem dele; cada _check vai para o placar do runner.
## Sem tipo em game/cfg: os testes leem campos à vontade (como antes da divisão).

var game: Game
var cfg  # GameConfig (Config.cfg)
var _runner  # tests/regras.gd

const Bonecos = preload("res://tests/lib/bonecos.gd")


func _check(ok: bool, nome: String) -> void:
	_runner._check(ok, nome)


func _perto(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


## Primeiro bot vivo (não o jogador).
func _alvo():
	for u in game.units:
		if u.alive and not u.is_player:
			return u
	return null


## Construtor do time do alvo (vira Construtor se preciso; com mãos livres).
func _lenhador():
	var u = _alvo()
	if u == null:
		return null
	if not u.lenhador():
		u.set_class(load("res://config/classes/construtor.tres"))
	u.drop_tora()
	u.carried_princess = null
	u._dodge_t = 0.0
	u._equip_t = 0.0
	u._spin_t = 0.0
	u._silence_t = 0.0
	return u


## Boneco descartável registrado no placar (some no fim do teste que o criou).
func _boneco_placar(team: int, pos: Vector3, indice: int) -> Unit:
	var u := Bonecos.criar(game, team, pos, "Placar", true)
	game.placar.registrar(u, team, indice, false)
	return u


## Estados com tempo da Unit que um teste zera antes de pôr o boneco no lugar.
const TIMERS := ["_dodge_t", "_intocavel_t", "_preso_t", "_slow_t", "_equip_t", "_spin_t",
		"_silence_t", "_ciranda_t", "_sono_t", "_forcado_t", "_canto_t", "_casulo_t", "_mudo_t",
		"_hitstop_t", "_molhado_t"]


## Põe o boneco em p olhando para `olha`, parado, com vida cheia e sem nenhum estado
## (antes eram 4 cópias divergentes deste lambda dentro dos testes de heróis).
func _por(x, p: Vector3, olha: Vector3) -> void:
	x.global_position = p
	x.velocity = Vector3.ZERO
	x._move_vel = Vector3.ZERO
	x._knock = Vector3.ZERO
	x._blocking = false
	x._shield = 0.0
	for campo in TIMERS:
		x.set(campo, 0.0)
	x.move_intent = Vector3.ZERO
	HeroisObra.zerar(x)
	x.hp = x.max_hp()
	x._visual.rotation.y = atan2(olha.x, olha.z)
	x.aim_dir = olha
	x.reset_physics_interpolation()


## Tira do mundo todos os nós dos grupos (teia, árvores, poças...) que um teste criou.
func _limpar_grupos(grupos: Array) -> void:
	for grupo in grupos:
		for n in get_tree().get_nodes_in_group(grupo):
			n.remove_from_group(grupo)
			n.queue_free()
