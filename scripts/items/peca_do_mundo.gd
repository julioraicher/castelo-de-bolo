class_name PecaDoMundo
extends Node3D
## Base das peças que um boneco põe no chão e que somem sozinhas: teia, para-raios,
## poça, andaime, árvore do Kodama, estrepes e mina (revisão 3b, IT-01/08/09/10).
## Todas faziam a mesma sequência à mão: guardar dono, time e a hora em que
## nasceram, entrar num grupo, desligar a interpolação, contar a vida e sair uma
## vez só. A filha chama _iniciar() no setup e responde só o que muda:
##   sair()          some (a filha toca o visual de saída depois de _saindo())
##   hash_estado()   o que entra no resumo da partida (SINC), além do comum

## Grupos das filhas (Game.hash_partes percorre nesta ordem).
const GRUPOS: Array[StringName] = [&"teias", &"para_raios", &"pocas_cachaca", &"andaimes", &"arvores_kodama", &"traps"]

var dono: Unit
var time := 0
## Sorte.ms() de quando nasceu: a mais antiga sai primeiro (limitar).
var nasceu := 0
## Já saindo (o visual de saída ainda toca): a regra não vê mais.
var indo := false
var _game: Game
var _vida := 0.0
var _grupo := &""


func _iniciar(game: Game, p_dono: Unit, grupo: StringName, vida: float, pos: Vector3) -> void:
	_game = game
	dono = p_dono
	time = p_dono.team
	_vida = vida
	_grupo = grupo
	nasceu = Sorte.ms()
	add_to_group(grupo)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_position = pos


## Dono ainda no jogo, ou null se já foi liberado (Arena: inimigo do tambor some).
func dono_valido() -> Unit:
	return dono if is_instance_valid(dono) else null


## Some (tempo, trocada por uma nova, quebrada). A filha troca o visual.
func sair() -> void:
	if _saindo():
		queue_free()


## Primeira chamada de saída: sai do grupo e devolve true; as outras, false.
func _saindo() -> bool:
	if indo:
		return false
	indo = true
	remove_from_group(_grupo)
	return true


## Tween que roda na física (o fim da peça é regra: libera a passagem, o grupo).
func _tween_fisica() -> Tween:
	return create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)


## Resumo para o SINC (Game.hash_partes): lugar, time, vida e o que a filha somar.
func hash_estado() -> int:
	return hash([global_position, time, _vida, indo])


## Peças de `dono` no `grupo` (vivas e, se dado, aceitas por `filtro`), da mais
## antiga para a mais nova; passou de `maximo - 1`, as mais antigas saem para
## caber a nova. Era escrito 4 vezes (estrepes, teia, para-raios, poça).
static func limitar(arvore: SceneTree, p_dono: Unit, grupo: StringName, maximo: int, filtro := Callable()) -> void:
	var minhas: Array[PecaDoMundo] = []
	for n in arvore.get_nodes_in_group(grupo):
		var p := n as PecaDoMundo
		if p and p.dono == p_dono and not p.indo and not p.is_queued_for_deletion() and (not filtro.is_valid() or filtro.call(p)):
			minhas.append(p)
	minhas.sort_custom(func(a: PecaDoMundo, b: PecaDoMundo) -> bool: return a.nasceu < b.nasceu)
	while minhas.size() >= maximo:
		minhas.pop_front().sair()
