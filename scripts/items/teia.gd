class_name Teia
extends Node3D
## Teia da Jorogumo (Q, Heróis 2.27): fica no chão GameConfig.teia_tempo s.
## Inimigo que pisa fica preso teia_preso s (a mesma teia espera teia_espera s
## para prender a mesma pessoa de novo; quem está no dash passa). A dona em
## cima corre teia_vel ×. Fogo queima e vento rasga (Reacoes).
## Visual (FxHerois.malha_teia): raios e espiral de seda numa malha só, tecida
## do centro para fora ao nascer, com gotas de orvalho na cor do time.

var dona: Unit
var time := 0
var raio := 2.1
var nasceu := 0
var indo := false
var _game: Game
var _vida := 10.0
var _espera := {}  # Unit -> s até esta teia poder prender de novo


func setup(game: Game, p_dona: Unit, pos: Vector3) -> void:
	_game = game
	dona = p_dona
	time = p_dona.team
	raio = Config.cfg.teia_raio
	_vida = Config.cfg.teia_tempo
	nasceu = Sorte.ms()
	add_to_group("teias")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_position = pos + Vector3(0, 0.05, 0)
	rotation.y = Sorte.f() * TAU
	FxHerois.malha_teia(self, raio, Config.team_color(time))
	scale = Vector3(0.1, 1, 0.1)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(self, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FxHerois.teia_nasce(game, global_position, raio)


func _physics_process(delta: float) -> void:
	if indo:
		return
	_vida -= delta
	if _vida <= 0.0 or not is_instance_valid(dona):
		sumir()
		return
	for k in _espera.keys():
		_espera[k] -= delta
		if _espera[k] <= 0.0:
			_espera.erase(k)
	var cfg := Config.cfg
	for u in _game.units:
		if not u.alive or u.em_voo:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 1.2:
			continue
		d.y = 0
		if d.length() > raio:
			continue
		if u == dona:
			u._teia_t = 0.15
			continue
		if u.team == time or u._dodge_t > 0.0 or _espera.has(u):
			continue
		_espera[u] = cfg.teia_espera
		u.prender(cfg.teia_preso)
		u._fio_dono = dona
		u._fio_t = maxf(u._fio_t, cfg.teia_preso + 0.6)
		FxHerois.teia_prende(u)


## Some sozinha (tempo, troca por uma nova): os fios afrouxam e afundam.
func sumir() -> void:
	if indo:
		return
	indo = true
	remove_from_group("teias")
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(self, "scale", Vector3(1.15, 0.1, 1.15), 0.35)
	tw.tween_callback(queue_free)


## Fogo: a seda pega fogo de fora para dentro e vira cinza.
func queimar() -> void:
	if indo:
		return
	FxHerois.teia_queima(_game, global_position, raio)
	sumir()


## Vento: os fios arrebentam e voam.
func rasgar() -> void:
	if indo:
		return
	FxHerois.teia_rasga(_game, global_position, raio)
	sumir()
