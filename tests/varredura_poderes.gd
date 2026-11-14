extends Node
## Varredura de poderes (Ciclo 2.29b): para cada classe com chapéu (bases,
## caminhos e heróis), usa Q, E e R com um inimigo parado e ALINHADO na frente
## (perto, a 2,2 m, e longe, a 6 m) e mede o que aconteceu. Roda na Arena:
##   godot --headless --path . --fixed-fps 60 -- --autoplay --varredura-poderes
## Imprime uma linha VARREDURA por classe e poder e, no fim, os suspeitos:
## poder que não saiu (recarga não andou) ou que não fez nada (sem dano, cura,
## escudo nem efeito no inimigo). Sai 0 sem suspeito; 1 com.

var game  # Game (sem tipo: script carregado em tempo de execução)
const ESPERA := 3.0
## Poderes que, com só um inimigo parado na frente e sem aliado, não mostram
## nada no alvo DE PROPÓSITO (conferidos no código na 2.29b). Poder novo que
## caia aqui precisa de um motivo; senão é suspeito.
const POR_DESENHO := {
	"kitsune Q": "cura aliados feridos (não há)",
	"kitsune_luz Q": "cura aliados feridos (não há)",
	"kitsune_luz R": "Bênção gigante: escudo/cura no time",
	"armadilheiro Q": "mina no chão: só fere quem pisa",
	"sumotori R": "Dohyō: anel que prende, o dano vem dos golpes",
	"ochimusha E": "Onibi: chamas em volta estouram a menos de 2 m",
	"shishimai R": "Festa da Vila: levanta aliados caídos",
	"onmyoji Q": "dobra um shikigami (vira munição do E)",
	"tennin Q": "puxa um aliado distante (não há)",
	"tennin R": "Véu Celeste: aliados intocáveis",
	"kodama E": "Bosque Sagrado: árvores que bloqueiam e curam",
	"predero E": "Andaime Expresso: cobertura que bloqueia passagem e tiro",
}
## Distância do inimigo "perto" (pode vir de --varredura-perto=N para testar alcance).
var DIST_PERTO := 2.2
var _suspeitos: Array[String] = []


func _ready() -> void:
	await get_tree().create_timer(0.6).timeout
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--varredura-perto="):
			DIST_PERTO = float(arg.trim_prefix("--varredura-perto="))
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
	print("VARREDURA FIM: %d suspeitos" % _suspeitos.size())
	for s in _suspeitos:
		print("SUSPEITO ", s)
	get_tree().quit(0 if _suspeitos.is_empty() else 1)


func _testar(p, cls, poder: String) -> void:
	var t: int = game.time_jogador
	var fr: Vector3 = game.arena.forward(t)
	# Chão plano ao lado das fileiras de chapéus (longe do rio, que fica em |x| < 9).
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
	var perto = _boneco(1 - t, base + fr * DIST_PERTO)
	var longe = _boneco(1 - t, base + fr * 6.0)
	for i in 3:
		await get_tree().physics_frame
	p.aim_dir = fr
	p.aim_point = longe.global_position if poder == "E" else perto.global_position
	p.aim_unit = perto
	var linha: Dictionary = game.placar.linha(p)
	var dano0: float = linha.get("dano", 0.0)
	var cura0: float = linha.get("cura", 0.0)
	var hp_p0: float = perto.hp
	var hp_l0: float = longe.hp
	var escudo0: float = p._shield
	var usou := false
	match poder:
		"Q":
			if not p.tem_rapida():
				_limpar([perto, longe])
				return
			p.wants_quick = true
		"E":
			p.fill_power()
			p.wants_power = true
		"R":
			p.super_carga = p.POWER_MAX
			p.wants_super = true
	var efeito := false
	var f := 0
	while f < int(ESPERA * 60.0):
		await get_tree().physics_frame
		f += 1
		p.aim_dir = fr
		if f == 2:
			match poder:
				# Recarga cheia = saiu; as falhas ("NINGUÉM PERTO") põem só um pedaço.
				"Q": usou = p._quick_cd >= p.quick_cooldown() * 0.9 or p.cargas_q < cls.cargas_q
				"E": usou = p.power < p.POWER_MAX * 0.5
				"R": usou = p.super_carga < p.POWER_MAX * 0.5
		for b in [perto, longe]:
			if is_instance_valid(b) and (b._slow_t > 0.0 or b._preso_t > 0.0 or b._forcado_t > 0.0 or b._mudo_t > 0.0 or b._sono_t > 0.0 or b._silence_t > 0.0 or b._knock.length() > 1.0 or b._derrapa_t > 0.0 or b._encachacado_t > 0.0):
				efeito = true
	var dano: float = float(linha.get("dano", 0.0)) - dano0
	var cura: float = float(linha.get("cura", 0.0)) - cura0
	var hp_perdido := 0.0
	if is_instance_valid(perto):
		hp_perdido += maxf(hp_p0 - perto.hp, 0.0) if perto.alive else hp_p0
	if is_instance_valid(longe):
		hp_perdido += maxf(hp_l0 - longe.hp, 0.0) if longe.alive else hp_l0
	var escudo: bool = p._shield > escudo0 + 0.1
	var fez: bool = dano > 0.5 or hp_perdido > 0.5 or cura > 0.5 or escudo or efeito or _efeito_proprio(p)
	var nome := "%s %s (%s)" % [cls.id, poder, _nome_poder(cls, poder)]
	print("VARREDURA %-40s usou=%s dano=%.0f hp=%.0f cura=%.0f escudo=%s efeito=%s" % [nome, usou, dano, hp_perdido, cura, escudo, efeito])
	# Feriu o alvo = saiu (o dano devolve Chi no mesmo quadro: o medidor engana).
	if dano > 0.5 or hp_perdido > 0.5:
		usou = true
	var motivo: String = POR_DESENHO.get("%s %s" % [cls.id, poder], "")
	if motivo != "":
		print("  por desenho: ", motivo)
	elif not usou:
		print("  estado: pronto=%s maos=%s guarda=%s mudo=%.1f equip=%.1f ciranda=%.1f spin=%.1f dodge=%.1f cd=%.2f" % [
			p.quick_ready(), p.maos_livres(), p._blocking, p._mudo_t, p._equip_t, p._ciranda_t, p._spin_t, p._dodge_t, p._quick_cd])
		_suspeitos.append(nome + ": não saiu com o inimigo alinhado na frente")
	elif not fez:
		_suspeitos.append(nome + ": saiu mas não fez nada visível no alvo")
	_limpar([perto, longe])
	# Deixa o que o poder criou (minas, árvore, teia) acabar longe do próximo teste.
	p._spin_t = 0.0
	p._fury_t = 0.0
	for i in 20:
		await get_tree().physics_frame


## Efeito em si mesmo que não aparece no alvo (corrida, disfarce, voo, sombra).
func _efeito_proprio(p) -> bool:
	return p._boost_t > 0.0 or p._disfarce_t > 0.0 or p.em_voo or p._sombra_t > 0.0 or p._spin_t > 0.0 or p._fury_t > 0.0


func _nome_poder(cls, poder: String) -> String:
	match poder:
		"Q": return cls.skill_name if cls.skill_name != "" else cls.skill
		"E": return cls.power_name
	return "super"


func _boneco(team: int, pos: Vector3):
	var u = load("res://scripts/actors/unit.gd").new()
	u.name = "Varredura_%d" % randi()
	u.descartavel = true
	game.add_child(u)
	u.setup(game, team, false, load("res://config/classes/guerreiro.tres"))
	u.global_position = pos
	u.reset_physics_interpolation()
	game.units.append(u)
	return u


func _limpar(lista: Array) -> void:
	for u in lista:
		if is_instance_valid(u):
			game.units.erase(u)
			game.reanimar.esquecer(u)
			u.queue_free()
