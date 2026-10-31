class_name BotBrain
extends Node
## Inteligência dos bots: uma lista de prioridades reavaliada a cada
## `bot_think_interval` segundos (não a cada quadro, o que também dá um
## "tempo de reação" humano). Entre uma decisão e outra o bot só segue o
## caminho e ataca o alvo escolhido.
##
## Prioridades (a primeira que se aplica vence):
##  1. Carregando a princesa inimiga -> voltar para casa.
##  2. Carregando bolo -> levar para a própria princesa.
##  3. Recruta -> pegar um chapéu no castelo.
##  4. Própria princesa sequestrada -> perseguir quem a leva / buscá-la no chão.
##  5. Construtor (lenhador, Ciclo 2.3): tora nos braços -> pilha; obra
##     pendente com madeira no estoque -> construir; tora solta perto ->
##     pegar; senão cortar a adulta mais perto que nenhum aliado está
##     cortando, preferindo o bosque seguro. Inimigo a 5 m: larga a tarefa.
##  6. Item no chão bem perto e ninguém colado -> desviar para pegar.
##  7. Aliado carregando a princesa inimiga (até 45 m) -> escoltar: só briga
##     com quem chega a 8 m dele.
##  8. Inimigo perto -> lutar.
##  9. Papel: ATAQUE vai buscar a princesa inimiga, DEFESA guarda o portão,
##     CONFEITEIRO busca bolos.
##
## Tática de luta (_tatica, a cada TATICA_INTERVALO s): dash para fechar
## distância, fugir com pouca vida, recuar o atirador, sair do combo de quem
## está batendo, correr com a tora; Samurai/Ronin seguram o bloqueio contra
## quem está golpeando de frente. As chances valem para todos; a dificuldade
## só muda o ritmo das checagens dos inimigos (bot_reaction_mult).

enum Role { ATTACK, DEFEND, CAKE }

var unit: Unit
var game: Game
var role := Role.ATTACK

var _think_t := randf() * 0.3
var _goal := Vector3.ZERO
var _target: Unit = null
var _last_nav_goal := Vector3.INF
var _nav_t := 0.0
var _wander := Vector3.ZERO
# Preso: alvo do outro lado de uma muralha sem caminho. Se em 3 s quis andar
# mas saiu menos de 1,5 m do lugar, ignora o alvo e dá uma volta por 2 s.
var _stuck_check_t := 3.0
var _stuck_from := Vector3.INF
var _unstuck_t := 0.0
var _unstuck_goal := Vector3.ZERO
var _parado_n := 0
## Planta que este bot está cortando (o _combat mira nela e golpeia).
var _planta: Planta = null
var _tatica_t := randf() * 0.2
var _bloqueio_t := 0.0  # segurando o bloqueio por mais estes segundos

const TATICA_INTERVALO := 0.2


func tick(delta: float) -> void:
	_think_t -= delta
	if _think_t <= 0.0:
		_think_t = Config.cfg.bot_think_interval
		if unit.team != Config.TEAM_BLUE:
			_think_t *= Settings.bot_reaction_mult()  # dificuldade só afeta os inimigos
		_think()
	_steer(delta)
	_combat()
	_tatica(delta)
	_check_stuck(delta)


## Dash e bloqueio (ver cabeçalho). Roda depois do _steer/_combat e pode
## trocar o move_intent deste quadro para dar a direção do dash.
func _tatica(delta: float) -> void:
	_bloqueio_t = maxf(_bloqueio_t - delta, 0.0)
	if _bloqueio_t > 0.0:
		unit.wants_skill = true
		unit.wants_attack = false
	_tatica_t -= delta
	if _tatica_t > 0.0 or not unit.alive:
		return
	_tatica_t = TATICA_INTERVALO * (Settings.bot_reaction_mult() if unit.team != Config.TEAM_BLUE else 1.0)
	var me := unit.global_position
	var perto := _nearest_enemy(6.0)
	# Bloqueio: inimigo de corpo a corpo golpeando de frente, a até 3 m.
	if unit.stats.skill == "bloqueio" and perto and perto.atacando() and perto.stats.attack_kind == "melee" \
			and me.distance_to(perto.global_position) < perto.stats.attack_range + 0.8 and randf() < 0.35:
		_bloqueio_t = 0.45
		var to := perto.global_position - me
		to.y = 0
		unit.aim_dir = to.normalized()
		unit.wants_skill = true
		unit.wants_attack = false
		return
	if not unit.dash_pronto():
		return
	var dir := Vector3.ZERO
	if unit.carried_tora and perto and me.distance_to(perto.global_position) < 4.5 and randf() < 0.5:
		dir = unit.move_intent  # foge para o depósito
	elif perto and unit.hp_ratio() < 0.35 and me.distance_to(perto.global_position) < 3.5 and randf() < 0.5:
		dir = me - perto.global_position  # pouca vida: sai da briga
	elif perto and perto.atacando() and perto.stats.attack_kind == "melee" \
			and me.distance_to(perto.global_position) < perto.stats.attack_range + 0.5 and randf() < 0.3:
		var de := me - perto.global_position
		de.y = 0
		dir = de.normalized().rotated(Vector3.UP, PI / 2 * (1.0 if randf() < 0.5 else -1.0)) + de.normalized() * 0.4
	elif _target and _target.alive and not unit.carried_princess:
		var to := _target.global_position - me
		to.y = 0
		var d := to.length()
		if unit.stats.attack_kind == "melee" and d > 4.0 and d < 8.0 and randf() < 0.25:
			dir = to  # fecha a distância
		elif unit.stats.attack_kind != "melee" and d < unit.stats.attack_range * 0.3 and randf() < 0.35:
			dir = -to  # atirador encurralado: recua
	dir.y = 0
	if dir.length() > 0.1:
		unit.move_intent = dir.normalized()
		unit.wants_dodge = true


func _check_stuck(delta: float) -> void:
	_unstuck_t = maxf(_unstuck_t - delta, 0.0)
	_stuck_check_t -= delta
	if _stuck_check_t > 0.0:
		return
	_stuck_check_t = 3.0
	var me := unit.global_position
	var moved := me.distance_to(_stuck_from) if _stuck_from != Vector3.INF else 99.0
	_stuck_from = me
	var far := (_target.global_position if _target and _target.alive else _goal).distance_to(me) > 5.0
	# Parado de vez (< 0,3 m em 3 s, duas vezes seguidas) mesmo perto do
	# objetivo: ele está num lugar sem caminho (em cima da muralha, dentro de
	# um colisor). O QA do mapa achou bots assim nos pátios do Rio.
	var quer := unit.move_intent.length() > 0.1 and unit.alive
	_parado_n = _parado_n + 1 if quer and moved < 0.3 else 0
	if quer and not unit.carried_princess and ((moved < 1.5 and far) or _parado_n >= 2):
		_parado_n = 0
		_unstuck_t = 2.0
		_unstuck_goal = me + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		_target = null


func _think() -> void:
	_target = null
	if _unstuck_t > 0.0:
		_goal = _unstuck_goal
		return
	var arena := game.arena
	var me := unit.global_position
	var enemy_team := 1 - unit.team
	var my_princess := game.princesses[unit.team]
	var their_princess := game.princesses[enemy_team]

	if unit.carried_princess:
		_goal = arena.princess_spot[unit.team]
		return
	if unit.has_cake and my_princess.state == Princess.State.HOME:
		_goal = my_princess.global_position
		return
	if unit.is_villager():
		var pad := game.nearest_free_hat(unit.team, me, unit)
		if pad and (role != Role.CAKE or randf() < 0.5):
			_goal = pad.global_position
			_target = _nearest_enemy(5.0)
			return

	if my_princess.state == Princess.State.CARRIED:
		var carrier := my_princess.carrier
		if role == Role.DEFEND or me.distance_to(carrier.global_position) < 30.0:
			_goal = carrier.global_position
			_target = carrier
			return
	elif my_princess.state == Princess.State.DROPPED and me.distance_to(my_princess.global_position) < 35.0:
		_goal = my_princess.global_position
		_target = _nearest_enemy(6.0)
		return

	if unit.lenhador() and _lenhador(me):
		return

	# Item no chão a poucos passos: vale o desvio se não tem inimigo colado.
	var item := game.nearest_pickup(me, 10.0)
	if item and _nearest_enemy(5.0) == null and (item.kind != "pocao" or unit.hp_ratio() < 0.8):
		_goal = item.global_position
		return

	# Máscara inimiga caída por perto: retomar antes que a devolvam (revezamento).
	if their_princess.state == Princess.State.DROPPED and role != Role.DEFEND \
			and me.distance_to(their_princess.global_position) < 30.0:
		_goal = their_princess.global_position
		_target = _nearest_enemy(3.0)
		return

	# Aliado levando a máscara inimiga: atacantes viram guarda-costas. Brigam
	# só com quem chega perto dele (8 m) e senão andam ao lado dele.
	if their_princess.state == Princess.State.CARRIED and their_princess.carrier.team == unit.team \
			and role != Role.DEFEND and their_princess.carrier != unit:
		var c := their_princess.carrier
		if me.distance_to(c.global_position) < 45.0:
			_target = _nearest_enemy_to(c.global_position, 8.0)
			if _target:
				_goal = _target.global_position
				return
			if randf() < 0.2:
				_wander = Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
			_goal = c.global_position + _wander
			return

	var aggro := Config.cfg.bot_aggro_radius
	if role == Role.DEFEND:
		aggro *= 1.3
	elif role == Role.ATTACK:
		aggro *= 0.45  # atacante foca na princesa e só briga com quem está colado
	_target = _nearest_enemy(aggro)
	if _target:
		_goal = _target.global_position
		return

	if their_princess.state == Princess.State.CARRIED and their_princess.carrier.team == unit.team and role != Role.DEFEND:
		var c := their_princess.carrier
		_goal = c.global_position + _wander
		if randf() < 0.2:
			_wander = Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		return

	match role:
		Role.ATTACK:
			_goal = their_princess.global_position
		Role.DEFEND:
			if randf() < 0.15 or _wander == Vector3.ZERO:
				_wander = Vector3(randf_range(-6, 2), 0, randf_range(-7, 7))
			_goal = arena.gate_spot[unit.team] + _wander * Vector3(arena.forward(unit.team).x, 1, 1)
		Role.CAKE:
			var cake := game.nearest_cake(me)
			if cake and not unit.has_cake:
				_goal = cake.global_position
			else:
				_goal = arena.gate_spot[unit.team]


## Ciclo de trabalho do Construtor. true = já escolheu o que fazer.
func _lenhador(me: Vector3) -> bool:
	_set_planta(null)
	var perigo := _nearest_enemy(5.0)
	if unit.carried_tora:
		# Com a tora nos braços não dá para bater: segue para a pilha (foge).
		_goal = game.pilhas[unit.team].global_position
		return true
	if perigo:
		return false  # larga a tarefa e briga (prioridades de combate abaixo)
	# Obra pendente e madeira no estoque para terminá-la: construir.
	var of := game.obra_do_time(unit.team, me)
	var falta := of.faltam() if of else 0
	if of and ((falta > 0 and game.madeira[unit.team] >= falta) or (falta == 0 and of.progresso < 1.0)):
		_goal = of.global_position + (me - of.global_position).normalized() * 1.2
		return true
	# Oficinas prontas: a madeira sobe as maquininhas para o nível 2.
	var maq: HatPad = game.maquina_para_n2(unit.team, me) if of == null else null
	if maq and game.madeira[unit.team] >= mini(maq.faltam_n2(), 2):
		var lado := me - maq.global_position
		lado.y = 0
		_goal = maq.global_position + (lado.normalized() if lado.length() > 0.1 else Vector3.BACK) * 1.8
		return true
	var tora := game.nearest_tora_solta(me, 30.0)
	if tora:
		_goal = tora.global_position
		return true
	var p := _escolher_planta(me)
	if p:
		_set_planta(p)
		var lado := me - p.global_position
		lado.y = 0
		_goal = p.global_position + (lado.normalized() if lado.length() > 0.1 else Vector3.RIGHT) * 1.4
		return true
	return false


func _set_planta(p: Planta) -> void:
	if _planta and _planta.cortador == unit:
		_planta.cortador = null
	_planta = p
	if p:
		p.cortador = unit


## Adulta mais perto que nenhum aliado está cortando; o bosque seguro do
## próprio castelo vence enquanto tiver adulta (o meio é onde há briga).
func _escolher_planta(me: Vector3) -> Planta:
	var seguro: Planta = null
	var qualquer: Planta = null
	var d_seguro := INF
	var d_qualquer := INF
	for p in game.plantas:
		if not p.adulta():
			continue
		var c := p.cortador
		if c and c != unit and c.alive and c.team == unit.team and c.brain is BotBrain and c.brain._planta == p:
			continue
		var d := me.distance_to(p.global_position)
		if p.tipo == "arvore" and p.lado == unit.team and d < d_seguro:
			d_seguro = d
			seguro = p
		if d < d_qualquer:
			d_qualquer = d
			qualquer = p
	return seguro if seguro else qualquer


func _nearest_enemy(radius: float) -> Unit:
	var best: Unit = null
	var best_d := radius
	for u in game.units:
		if u.alive and u.team != unit.team:
			var d := u.global_position.distance_to(unit.global_position)
			# Quem carrega a princesa é alvo prioritário.
			if u.carried_princess:
				d *= 0.5
			if d < best_d:
				best_d = d
				best = u
	return best


func _nearest_enemy_to(at: Vector3, radius: float) -> Unit:
	var best: Unit = null
	var best_d := radius
	for u in game.units:
		if u.alive and u.team != unit.team:
			var d := u.global_position.distance_to(at)
			if d < best_d:
				best_d = d
				best = u
	return best


func _steer(delta: float) -> void:
	var me := unit.global_position
	var goal := _goal
	var stop_dist := 1.0
	if _target and _target.alive and not unit.carried_princess:
		goal = _target.global_position
		stop_dist = unit.stats.attack_range * (0.75 if unit.stats.attack_kind != "melee" else 0.6)
		if unit.stats.attack_kind != "melee" and me.distance_to(goal) < unit.stats.attack_range * 0.45:
			# Atirador recua quando o inimigo chega perto demais.
			unit.move_intent = (me - goal).normalized()
			return
	var to_goal := goal - me
	to_goal.y = 0
	if to_goal.length() <= stop_dist:
		unit.move_intent = Vector3.ZERO
		return
	_nav_t -= delta
	if _nav_t <= 0.0 or goal.distance_to(_last_nav_goal) > 2.0:
		unit.nav_agent.target_position = goal
		_last_nav_goal = goal
		_nav_t = 0.35
	var next := unit.nav_agent.get_next_path_position()
	var dir := next - me
	dir.y = 0
	if dir.length() < 0.1:
		dir = to_goal  # sem caminho ainda: vai reto
	unit.move_intent = dir.normalized()


func _combat() -> void:
	unit.wants_attack = false
	unit.wants_skill = false
	if unit.stats.skill == "cura" and _needs_heal():
		unit.wants_skill = true
	if unit.power_ready():
		unit.wants_power = _should_use_power()
	if unit.stats.skill == "armadilha" and _wants_trap():
		unit.wants_skill = true
	if _target == null or not _target.alive or unit.carried_princess:
		if _planta and _planta.adulta() and not unit.carried_tora:
			var to_p := _planta.global_position - unit.global_position
			to_p.y = 0
			if to_p.length() <= unit.stats.attack_range + 0.4:
				unit.aim_dir = to_p.normalized()
				unit.wants_attack = true
				return
		if unit.move_intent.length() > 0.1:
			unit.aim_dir = unit.move_intent.normalized()
		return
	var to := _target.global_position - unit.global_position
	to.y = 0
	var dist := to.length()
	var lead := Vector3.ZERO
	if unit.stats.attack_kind != "melee":
		# Mira um pouco à frente do alvo (tempo de voo do projétil) + erro humano.
		var flight := dist / unit.stats.projectile_speed
		lead = _target.velocity * flight * 0.8
		lead.y = 0
		to += lead
		to = to.rotated(Vector3.UP, randf_range(-0.08, 0.08))
	unit.aim_dir = to.normalized()
	unit.aim_point = _target.global_position + lead
	# Arqueiro de longe: segura o botão direito até a carga máxima e solta.
	if unit.stats.skill == "tiro_carregado" and dist > unit.stats.attack_range * 0.6 and dist <= unit.stats.attack_range:
		unit.wants_skill = unit.charge_ratio() < 1.0
		return
	if dist <= unit.stats.attack_range + 0.3:
		unit.wants_attack = true


## Quando vale gastar o medidor cheio. Os números aqui são o "bom senso" do bot.
func _should_use_power() -> bool:
	var me := unit.global_position
	var r := unit.stats.power_radius
	match unit.stats.power:
		"redemoinho":
			return _count(1 - unit.team, me, r + 0.3) >= 1
		"chuva_de_flechas":
			if _target == null or not _target.alive or me.distance_to(_target.global_position) > unit.stats.attack_range * 1.4:
				return false
			unit.aim_point = _target.global_position
			return _count(1 - unit.team, _target.global_position, r) >= 2 or _target.carried_princess != null
		"bencao":
			var hurt := 0
			for u in game.units:
				if u.alive and u.team == unit.team and u.hp_ratio() < 0.7 and u.global_position.distance_to(me) <= r:
					hurt += 1
			return hurt >= 3 or unit.hp_ratio() < 0.35
		"corrida":
			if unit.carried_princess:
				return true
			# Construtor: corre com a tora ou quando a planta/obra está longe.
			if unit.carried_tora or (unit.lenhador() and me.distance_to(_goal) > 30.0 and _nearest_enemy(12.0) == null):
				return true
			for u in game.units:
				if u.alive and u.team == unit.team and u.carried_princess and u.global_position.distance_to(me) <= r:
					return true
			var mine := game.princesses[unit.team]
			return mine.state == Princess.State.CARRIED and mine.carrier and me.distance_to(mine.carrier.global_position) < 25.0
		"furia":
			return _count(1 - unit.team, me, r) >= 2 or (_target != null and me.distance_to(_target.global_position) < 3.0)
		"corte_relampago":
			# Atravessa na direção do alvo se ele estiver no alcance do corte.
			return _target != null and _target.alive and me.distance_to(_target.global_position) < r * 0.9
		"leque":
			return _target != null and _target.alive and me.distance_to(_target.global_position) < unit.stats.attack_range
		"nuvem", "selo", "coluna_fogo":
			if _target == null or not _target.alive or me.distance_to(_target.global_position) > unit.stats.attack_range:
				return false
			unit.aim_point = _target.global_position
			return _count(1 - unit.team, _target.global_position, r) >= 2 or _target.carried_princess != null
		"bombardeio":
			if _target == null or not _target.alive or me.distance_to(_target.global_position) > unit.stats.attack_range * 1.2:
				return false
			unit.aim_point = _target.global_position
			return _count(1 - unit.team, _target.global_position, 4.0) >= 2 or _target.carried_princess != null
		"campo_minado":
			return _count(1 - unit.team, me, 7.0) >= 2 or (role == Role.DEFEND and unit.global_position.distance_to(game.arena.gate_spot[unit.team]) < 6.0)
		"reforco":
			return _count(unit.team, me, r) >= 3 and _count(1 - unit.team, me, 10.0) >= 2
		"mutirao":
			return game.nearest_oficina(unit.team, me, r * 2.0, true) != null
	return false


## Construtor: estrepes no caminho de quem vem (inimigo a até 7 m) ou, na
## defesa, espalhadas perto do portão. O recarga (trap_cooldown) limita o ritmo.
func _wants_trap() -> bool:
	if unit.carried_princess:
		return false
	if _target and _target.alive and unit.global_position.distance_to(_target.global_position) < 7.0:
		return true
	return role == Role.DEFEND and unit.global_position.distance_to(game.arena.gate_spot[unit.team]) < 8.0 and randf() < 0.02


func _count(team: int, at: Vector3, radius: float) -> int:
	var n := 0
	for u in game.units:
		if u.alive and u.team == team and u.global_position.distance_to(at) <= radius:
			n += 1
	return n


func _needs_heal() -> bool:
	for u in game.units:
		if u.alive and u.team == unit.team and u.hp_ratio() < 0.65 and u.global_position.distance_to(unit.global_position) < unit.stats.heal_radius:
			return true
	return false
