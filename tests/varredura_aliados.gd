extends Node
## Varredura com ALIADOS (caça aos bugs 2026-11-15): a varredura de poderes
## (tests/varredura_poderes.gd) só põe inimigo, então não vê cura, escudo,
## reanimar nem puxão de aliado. Aqui cada Q, E e R sai com:
##   aliado ferido (40% da vida) a 2 m do lado, aliado caído 2,5 m atrás,
##   aliado com 60% a 8 m do outro lado, inimigo perto (2,2 m) e longe (6 m).
##   godot --headless --path . --fixed-fps 60 -- --autoplay --varredura-aliados
## Confere, para TODO poder: não fere aliado (fogo amigo) e não deixa o dono
## preso num estado (giro, canto, voo, preparo). E, para os poderes de apoio em
## ESPERADO, que o efeito chegou no aliado. Sai 0 sem falha; 1 com.
## Poder novo de apoio = linha em ESPERADO.

var game  # Game (sem tipo: script carregado em tempo de execução)
const ESPERA := 3.0
## "classe poder": o que tem de acontecer com os aliados.
##   cura   = um aliado ganha vida     escudo = o ferido ganha escudo
##   levanta = o caído levanta         puxa   = o aliado de pé chega mais perto
##   boost / intocavel = o ferido ganha esse estado
const ESPERADO := {
	"kitsune Q": ["cura"],
	"kitsune_luz Q": ["cura"],
	"kitsune_luz E": ["cura", "escudo"],
	"kitsune_luz R": ["cura", "escudo"],
	"construtor E": ["boost"],
	"construtor R": ["boost"],
	"sohei Q": ["escudo"],
	"sohei E": ["escudo"],
	"sohei R": ["escudo"],
	"shishimai R": ["levanta"],
	"tennin Q": ["levanta"],
	"tennin E": ["cura"],
	"tennin R": ["intocavel"],
	"kodama R": ["cura"],
}
## Rodam de novo SEM caído: o Laço da Tennin puxa o caído primeiro; sem ele,
## puxa um aliado de pé e cura.
const SEM_CAIDO := {
	"tennin Q": ["puxa", "cura"],
}
var _falhas: Array[String] = []


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
			var nome := "%s %s" % [cls.id, poder]
			await _testar(p, cls, poder, ESPERADO.get(nome, []), true)
			if SEM_CAIDO.has(nome):
				await _testar(p, cls, poder, SEM_CAIDO[nome], false)
	print("ALIADOS FIM: %d falhas" % _falhas.size())
	for f in _falhas:
		print("FALHA ", f)
	get_tree().quit(0 if _falhas.is_empty() else 1)


func _testar(p, cls, poder: String, espera: Array, com_caido: bool) -> void:
	var t: int = game.time_jogador
	var fr: Vector3 = game.arena.forward(t)
	var lado: Vector3 = Vector3.UP.cross(fr).normalized()
	var base: Vector3 = game.arena.gate_spot[t] + fr * 10.0 + lado * 24.0
	if not p.alive:
		p.levantar_reanimado()
	p.set_class(cls)
	p.global_position = base
	p.reset_physics_interpolation()
	p.hp = p.max_hp()
	p._quick_cd = 0.0
	p.cargas_q = cls.cargas_q
	p.power = 0.0
	p.super_carga = 0.0
	p.move_intent = Vector3.ZERO
	p.aim_dir = fr
	p.look_at(p.global_position - fr)
	var ferido = _boneco(t, base + lado * 2.0)
	var caido = _boneco(t, base - fr * 2.5) if com_caido else null
	var distante = _boneco(t, base - lado * 8.0)
	var perto = _boneco(1 - t, base + fr * 2.2)
	var longe = _boneco(1 - t, base + fr * 6.0)
	var todos := [ferido, caido, distante, perto, longe].filter(func(u): return u != null)
	for i in 3:
		await get_tree().physics_frame
	ferido.hp = ferido.max_hp() * 0.4
	distante.hp = distante.max_hp() * 0.6
	if caido:
		caido._die(null)
		caido._respawn_t = 30.0
	var hp_f0: float = ferido.hp
	var hp_d0: float = distante.hp
	var sh_f0: float = ferido._shield
	var dist_d0: float = distante.global_position.distance_to(p.global_position)
	p.aim_dir = fr
	p.aim_point = longe.global_position if poder == "E" else perto.global_position
	p.aim_unit = perto
	match poder:
		"Q":
			if not p.tem_rapida():
				_limpar(todos)
				return
			p.wants_quick = true
		"E":
			p.fill_power()
			p.wants_power = true
		"R":
			p.super_carga = p.POWER_MAX
			p.wants_super = true
	var hp_f_min: float = hp_f0
	var hp_d_min: float = hp_d0
	var cura := false
	var escudo := false
	var levantou := false
	var boost := false
	var intocavel := false
	var f := 0
	while f < int(ESPERA * 60.0):
		await get_tree().physics_frame
		f += 1
		p.aim_dir = fr
		if is_instance_valid(ferido):
			hp_f_min = minf(hp_f_min, ferido.hp)
			cura = cura or ferido.hp > hp_f0 + 0.5
			escudo = escudo or ferido._shield > sh_f0 + 0.1
			boost = boost or ferido._boost_t > 0.0
			intocavel = intocavel or ferido._intocavel_t > 0.0
		if is_instance_valid(distante):
			hp_d_min = minf(hp_d_min, distante.hp)
			cura = cura or distante.hp > hp_d0 + 0.5
		if caido and is_instance_valid(caido) and caido.alive:
			levantou = true
	var puxou: bool = is_instance_valid(distante) and distante.global_position.distance_to(p.global_position) < dist_d0 - 2.0
	var travou: bool = p._spin_t > 0.5 or p._canto_t > 0.5 or p.em_voo or p._windup_t > 0.5 or p._equip_t > 0.5
	var nome := "%s %s%s" % [cls.id, poder, "" if com_caido else " (sem caído)"]
	var tem := {"cura": cura, "escudo": escudo, "levanta": levantou, "puxa": puxou, "boost": boost, "intocavel": intocavel}
	var viu: Array[String] = []
	for k in tem:
		if tem[k]:
			viu.append(k)
	print("ALIADOS %-28s viu=[%s] fogo_amigo=%.0f travou=%s" % [nome, " ".join(viu), maxf(hp_f0 - hp_f_min, hp_d0 - hp_d_min), travou])
	if hp_f_min < hp_f0 - 0.5 or hp_d_min < hp_d0 - 0.5:
		_falhas.append(nome + ": feriu aliado (%.0f de vida)" % maxf(hp_f0 - hp_f_min, hp_d0 - hp_d_min))
	if travou:
		_falhas.append(nome + ": o dono ficou preso (giro %.1f, canto %.1f, voo %s, preparo %.1f, equip %.1f)" % [p._spin_t, p._canto_t, p.em_voo, p._windup_t, p._equip_t])
	for e in espera:
		if not tem.get(e, false):
			_falhas.append(nome + ": devia " + e + " e não fez")
	_limpar(todos)
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
