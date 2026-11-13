class_name ArvoreKodama
extends Node3D
## Árvore do Kodama (Heróis 2.27b): nasce do Bosque (E, três juntas) ou da
## Floresta Antiga (R, anel de gigantes). Tronco sólido no LAYER_WORLD: bloqueia
## passagem e tiros. A sombra cura os aliados do dono (bosque_cura/s, uma vez
## por segundo por boneco, mesmo embaixo de várias). Lenhador corta: em
## arvore_golpes golpes solta 1 tora e cai. Fogo (Reacoes) vira tocha
## tocha_tempo s, fere quem é do time dela perto e cai. Raio que cai perto
## dela cai nela (HeroisNatureza.arvore_para_raios).
## Visual (FxNatureza.arvore): a árvore adulta do tema com a corda shimenawa,
## os papéis shide e o musgo na cor do time.

var dono: Unit
var time := 0
var grande := false
var indo := false
var _game: Game
var _vida := 12.0
var _golpes := 2
var _tocha_t := 0.0
var _tocha_tick := 0.0
var _tocha_no: Node3D
var _cura_t := 0.6
var _corpo: StaticBody3D
var _visual: Node3D
var _escala := 1.0


func setup(game: Game, p_dono: Unit, pos: Vector3, tempo: float, p_grande: bool) -> void:
	_game = game
	dono = p_dono
	time = p_dono.team
	grande = p_grande
	_vida = tempo
	_golpes = Config.cfg.arvore_golpes * (2 if grande else 1)
	_escala = 1.7 if grande else 1.0
	add_to_group("arvores_kodama")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_position = pos
	rotation.y = randf() * TAU
	_corpo = StaticBody3D.new()
	_corpo.collision_layer = Config.LAYER_WORLD
	_corpo.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = raio_tronco()
	sh.height = 3.2 * _escala
	cs.shape = sh
	cs.position.y = sh.height * 0.5
	_corpo.add_child(cs)
	add_child(_corpo)
	_visual = FxNatureza.arvore(self, Config.team_color(time), grande)
	_visual.scale = Vector3(0.25, 0.05, 0.25) * _escala
	var tw := _visual.create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE * _escala, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FxNatureza.arvore_nasce(game, global_position, _escala)


## Floresta: as árvores do anel nascem uma depois da outra.
func atraso_nascer(t: float) -> void:
	if t <= 0.0 or _visual == null:
		return
	_visual.visible = false
	var tw := create_tween()
	tw.tween_interval(t)
	tw.tween_callback(func() -> void: _visual.visible = true)


func raio_tronco() -> float:
	return 0.45 * (1.7 if grande else 1.0)


## Ponto do alto da copa (onde o raio bate).
func topo() -> Vector3:
	return global_position + Vector3(0, 3.6 * _escala, 0)


func _physics_process(delta: float) -> void:
	if indo:
		return
	_vida -= delta
	if _tocha_t > 0.0:
		_tick_tocha(delta)
		return
	if _vida <= 0.0:
		cair()
		return
	_cura_t -= delta
	if _cura_t <= 0.0 and not grande:  # a Floresta cura pelo anel inteiro (HeroisNatureza)
		_cura_t = 1.0
		_curar_sombra()


func _curar_sombra() -> void:
	var cfg := Config.cfg
	var agora := Time.get_ticks_msec()
	for u in _game.units:
		if not u.alive or u.team != time or u.em_voo:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 2.0:
			continue
		d.y = 0
		if d.length() > cfg.bosque_sombra:
			continue
		if int(u.get_meta("sombra_ms", 0)) > agora:
			continue  # já curou nesta volta por outra árvore
		u.set_meta("sombra_ms", agora + 900)
		if u.heal(cfg.bosque_cura, dono if is_instance_valid(dono) else null) > 0.0:
			FxNatureza.sombra_cura(u)


## Golpe de lenhador. Devolve true quando cai (e solta a tora).
func golpe(by: Unit) -> bool:
	if indo:
		return false
	_golpes -= 1
	FxNatureza.arvore_golpe(self, by)
	if _golpes > 0:
		return false
	var dir := global_position - by.global_position
	dir.y = 0
	_game.soltar_tora(global_position + Vector3(0, 0.4, 0), -dir.normalized() if dir.length() > 0.01 else Vector3.RIGHT)
	cair()
	return true


## Fogo de quem é do time `time_fogo` (Reacoes): vira tocha e cai.
func queimar(time_fogo: int) -> void:
	if indo or _tocha_t > 0.0 or time_fogo == time:
		return
	_tocha_t = Config.cfg.tocha_tempo
	_tocha_tick = 0.0
	_tocha_no = FxNatureza.tocha(self, _escala, _tocha_t)


func _tick_tocha(delta: float) -> void:
	var cfg := Config.cfg
	_tocha_t -= delta
	_tocha_tick -= delta
	if _tocha_tick <= 0.0:
		_tocha_tick = 0.5
		for u in _game.units:
			if not u.alive or u.team != time or u.em_voo:
				continue
			var d := u.global_position - global_position
			d.y = 0
			if d.length() <= cfg.tocha_raio * _escala:
				u.take_damage(cfg.tocha_dano * 0.5, null, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.2, false, "brasa", 1)
	if _tocha_t <= 0.0:
		cair(true)


## Some: tomba para um lado (queimada: vira cinza) e libera a passagem na hora.
func cair(queimada := false) -> void:
	if indo:
		return
	indo = true
	remove_from_group("arvores_kodama")
	if _corpo:
		_corpo.queue_free()
		_corpo = null
	FxNatureza.arvore_cai(self, queimada, _escala)
	var lado := randf() * TAU
	var tw := create_tween().set_parallel(true)
	if _visual:
		tw.tween_property(_visual, "rotation", Vector3(cos(lado) * 1.3, 0, sin(lado) * 1.3), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(_visual, "scale", Vector3.ONE * _escala * 0.2, 0.55).set_delay(0.25)
	tw.chain().tween_callback(queue_free)
