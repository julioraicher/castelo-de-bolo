extends Node
## Varredura com ALIADOS (auditoria 2026-11-15, local): para cada classe e poder,
## monta: aliado ferido (40%) ao lado, aliado caído atrás, aliado longe (12 m),
## inimigo perto e longe na frente. Mede o que muda nos aliados e no próprio.

var game
const ESPERA := 3.0
var _linhas: Array[String] = []


func _ready() -> void:
	await get_tree().create_timer(0.6).timeout
	var p = game.player
	if p.brain:
		p.remove_child(p.brain)
		p.brain.queue_free()
		p.brain = null
	var cfg = get_node("/root/Config").cfg
	var so := OS.get_environment("VARREDURA_SO").split(",", false)
	for cls in cfg.classes_arena():
		if not so.is_empty() and not so.has(String(cls.id)):
			continue
		for poder in ["Q", "E", "R"]:
			await _testar(p, cls, poder)
	print("ALIADOS FIM")
	get_tree().quit(0)


func _testar(p, cls, poder: String) -> void:
	var t: int = game.time_jogador
	var fr: Vector3 = game.arena.forward(t)
	var lado: Vector3 = Vector3.UP.cross(fr).normalized()
	var base: Vector3 = game.arena.gate_spot[t] + fr * 10.0 + lado * 24.0
	if not p.alive:
		p.levantar_reanimado()
	p.set_class(cls)
	p.global_position = base
	p.reset_physics_interpolation()
	p.hp = p.max_hp() * 0.5
	p._quick_cd = 0.0
	p.cargas_q = cls.cargas_q
	p.power = 0.0
	p.super_carga = 0.0
	p.move_intent = Vector3.ZERO
	p.aim_dir = fr
	p.look_at(p.global_position - fr)
	var ferido = _boneco(t, base + lado * 2.0)
	var caido = _boneco(t, base - fr * 2.5)
	var distante = _boneco(t, base - lado * 12.0)
	var perto = _boneco(1 - t, base + fr * 2.2)
	var longe = _boneco(1 - t, base + fr * 6.0)
	for i in 3:
		await get_tree().physics_frame
	ferido.hp = ferido.max_hp() * 0.4
	caido._die(null)
	caido._respawn_t = 30.0
	var hp_eu0: float = p.hp
	var hp_f0: float = ferido.hp
	var sh_f0: float = ferido._shield
	var pos_d0: Vector3 = distante.global_position
	var pos_p0: Vector3 = perto.global_position
	p.aim_dir = fr
	p.aim_point = longe.global_position if poder == "E" else perto.global_position
	p.aim_unit = perto
	match poder:
		"Q":
			if not p.tem_rapida():
				_limpar([ferido, caido, distante, perto, longe])
				return
			p.wants_quick = true
		"E":
			p.fill_power()
			p.wants_power = true
		"R":
			p.super_carga = p.POWER_MAX
			p.wants_super = true
	var f := 0
	var buff_aliado := ""
	var hp_f_min: float = hp_f0
	var levantou := false
	var travou := false
	while f < int(ESPERA * 60.0):
		await get_tree().physics_frame
		f += 1
		p.aim_dir = fr
		if is_instance_valid(ferido):
			hp_f_min = minf(hp_f_min, ferido.hp)
			for k in ["_boost_t", "_intocavel_t", "_fury_t", "_dmg_boost_t", "_shield_t", "_slow_t", "_preso_t", "_forcado_t", "_sono_t", "_mudo_t", "_silence_t", "_derrapa_t", "_encachacado_t", "_casulo_t", "_cego_t"]:
				if float(ferido.get(k)) > 0.0 and not buff_aliado.contains(k):
					buff_aliado += k + " "
		if is_instance_valid(caido) and caido.alive:
			levantou = true
	# Travou = depois de 3 s ainda preso num estado que não deixa agir.
	travou = p._spin_t > 0.5 or p._canto_t > 0.5 or p.em_voo or p._windup_t > 0.5 or p._equip_t > 0.5
	var nome := "%s %s" % [cls.id, poder]
	var hp_f: float = ferido.hp if is_instance_valid(ferido) else -1.0
	print("ALIADOS %-24s eu_hp=%+.0f ferido_hp=%+.0f (min %+.0f) escudo_f=%+.0f levantou=%s distante_moveu=%.1f inimigo_moveu=%.1f travou=%s buffs_f=[%s]" % [
		nome, p.hp - hp_eu0, hp_f - hp_f0, hp_f_min - hp_f0,
		(ferido._shield - sh_f0) if is_instance_valid(ferido) else 0.0,
		levantou,
		distante.global_position.distance_to(pos_d0) if is_instance_valid(distante) else -1.0,
		perto.global_position.distance_to(pos_p0) if is_instance_valid(perto) else -1.0,
		travou, buff_aliado.strip_edges()])
	_limpar([ferido, caido, distante, perto, longe])
	p._spin_t = 0.0
	p._fury_t = 0.0
	for i in 30:
		await get_tree().physics_frame


func _boneco(team: int, pos: Vector3):
	var u = load("res://scripts/actors/unit.gd").new()
	u.name = "Aliados_%d" % randi()
	u.descartavel = true
	game.add_child(u)
	u.setup(game, team, false, load("res://config/classes/guerreiro.tres"))
	u.global_position = pos
	u.reset_physics_interpolation()
	u.died.connect(game._on_unit_died)
	game.units.append(u)
	return u


func _limpar(lista: Array) -> void:
	for u in lista:
		if is_instance_valid(u):
			game.units.erase(u)
			game.reanimar.esquecer(u)
			u.queue_free()
