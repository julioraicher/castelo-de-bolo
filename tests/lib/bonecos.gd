extends RefCounted
## Bonecos descartáveis dos testes (revisão 2026-11-19, TS-04): antes cada teste
## (regras, varredura de poderes, varredura de aliados) tinha a sua cópia.
##   const Bonecos = preload("res://tests/lib/bonecos.gd")
##   var u = Bonecos.criar(game, time, pos, "Varredura")
##   Bonecos.limpar(game, [u, ...])

static var _n := 0


## Guerreiro descartável do `team` em `pos`, já na lista do jogo. `morte`: liga o
## sinal de morte ao jogo (placar, reanimar), como um soldado de verdade.
static func criar(game, team: int, pos: Vector3, prefixo := "Boneco", morte := false,
		classe := "res://config/classes/guerreiro.tres") -> Unit:
	_n += 1
	var u := Unit.new()
	u.name = "%s_%d" % [prefixo, _n]
	u.descartavel = true
	game.add_child(u)
	u.setup(game, team, false, load(classe))
	u.global_position = pos
	u.reset_physics_interpolation()
	if morte:
		u.died.connect(game._on_unit_died)
	game.units.append(u)
	return u


## Tira os bonecos do jogo (lista de unidades, do reanimar e da árvore).
static func limpar(game, lista: Array) -> void:
	for u in lista:
		if is_instance_valid(u):
			game.units.erase(u)
			game.reanimar.esquecer(u)
			u.queue_free()
