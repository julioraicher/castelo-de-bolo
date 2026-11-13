class_name RedeBrain
extends Node
## Cérebro de um jogador humano na partida online (Ciclo 2.28). Não lê
## teclado: aplica o Comando que chegou pela rede para este quadro. Todo PC
## tem um RedeBrain para CADA humano, inclusive o seu (o seu comando volta
## com o mesmo atraso dos outros: é isso que mantém os PCs iguais).
## Princípio 4: só preenche intenções; o corpo (Unit) executa.

var unit: Unit
var game: Game
var peer := 0  # id de rede do dono
var nome := ""

var _cmd := Comando.new()
## Botões de um toque acumulados até o corpo ler (o hitstop pula o cérebro
## por alguns quadros; sem isto o dash apertado nesse instante sumiria).
var _pendente := 0


## Chamado pela Rede no começo de cada quadro, em todos os PCs.
func receber(c: Comando) -> void:
	_cmd = c
	_pendente |= c.botoes & (Comando.RAPIDA | Comando.PODER | Comando.SUPER | Comando.ESQUIVA | Comando.INTERAGE)


func tick(_delta: float) -> void:
	var c := _cmd
	unit.move_intent = Vector3(c.move.x, 0.0, c.move.y)
	if c.mira.length_squared() > 0.0001:
		unit.aim_dir = Vector3(c.mira.x, 0.0, c.mira.y).normalized()
	unit.aim_point = c.ponto
	unit.aim_unit = game.units[c.alvo] if c.alvo >= 0 and c.alvo < game.units.size() else null
	unit.wants_attack = c.tem(Comando.ATAQUE)
	unit.wants_block = c.tem(Comando.DEFESA)
	unit.wants_reanimar = c.tem(Comando.SEGURA_F)
	if _pendente & Comando.RAPIDA:
		unit.wants_quick = true
	if _pendente & Comando.PODER:
		unit.wants_power = true
	if _pendente & Comando.SUPER:
		unit.wants_super = true
	if _pendente & Comando.ESQUIVA:
		unit.wants_dodge = true
	unit.wants_interact = _pendente & Comando.INTERAGE != 0
	_pendente = 0
