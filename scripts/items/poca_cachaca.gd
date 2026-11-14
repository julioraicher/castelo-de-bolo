class_name PocaCachaca
extends Node3D
## Poça de cachaça do Predero (Herói 2.30): nasce do Q (garrafão, até poca_max
## por dono) ou das garrafas da Saideira (pocinha, não conta no limite).
## Inimigo do dono que pisa derrapa (HeroisObra.pisou: atrito × poca_atrito) e
## fica encachaçado. Qualquer fogo que encosta (Reacoes, de qualquer time) acende:
## por poca_fogo_tempo s fere poca_fogo_dano/s quem é inimigo do dono e, no fim,
## a cachaça evapora. Garrafa do dono que cai nela espalha o estilhaço pela poça.
## Visual em FxObra.poca (mancha âmbar brilhando, bolhinhas; acesa: chamas).

var dono: Unit
var time := 0
var raio := 2.6
var pequena := false
var indo := false
var nasceu := 0
var _game: Game
var _vida := 8.0
var _atraso := 0.0
var _acesa_t := 0.0
var _fogo_tick := 0.0
var _visual: Node3D
var _fogo_no: Node3D


func setup(game: Game, p_dono: Unit, pos: Vector3, p_raio: float, tempo: float, atraso: float, p_pequena: bool) -> void:
	_game = game
	dono = p_dono
	time = p_dono.team
	raio = p_raio
	pequena = p_pequena
	_vida = tempo
	_atraso = atraso
	nasceu = Sorte.ms()
	add_to_group("pocas_cachaca")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_position = pos
	_visual = FxObra.poca(self, raio, Config.team_color(time))
	if _atraso > 0.0:
		_visual.visible = false
	else:
		_espalhou()


## Já no chão (o garrafão do Q ainda voa nos primeiros décimos).
func ativa() -> bool:
	return not indo and _atraso <= 0.0


func acesa() -> bool:
	return _acesa_t > 0.0


## `p` está em cima da poça (com folga `extra` m)?
func cobre(p: Vector3, extra := 0.0) -> bool:
	var d := p - global_position
	if absf(d.y) > 1.6:
		return false
	return Vector2(d.x, d.z).length() <= raio + extra


func _espalhou() -> void:
	if _visual:
		_visual.visible = true
	FxObra.poca_espalha(_game, global_position, raio, pequena)


func _physics_process(delta: float) -> void:
	if indo:
		return
	if _atraso > 0.0:
		_atraso -= delta
		if _atraso <= 0.0:
			_espalhou()
		return
	_vida -= delta
	if _acesa_t > 0.0:
		_tick_fogo(delta)
		return
	if _vida <= 0.0:
		secar()
		return
	var tem_dono := is_instance_valid(dono)
	for u in _game.units:
		if not u.alive or u.team == time or u.em_voo or not u.is_on_floor():
			continue
		if cobre(u.global_position, 0.2):
			HeroisObra.pisou(u, dono if tem_dono else null)


## Fogo encostou: queima poca_fogo_tempo s e evapora. Acende as vizinhas também
## (Reacoes com "brasa" no raio dela).
func acender() -> void:
	if indo or _acesa_t > 0.0 or _atraso > 0.0:
		return
	_acesa_t = Config.cfg.poca_fogo_tempo
	_fogo_tick = 0.0
	_fogo_no = FxObra.poca_acesa(self, raio, _acesa_t)
	Reacoes.em(_game, global_position, raio, "brasa", time)


func _tick_fogo(delta: float) -> void:
	var cfg := Config.cfg
	_acesa_t -= delta
	_fogo_tick -= delta
	if _fogo_tick <= 0.0:
		_fogo_tick = 0.5
		var quem: Unit = dono if is_instance_valid(dono) and dono.alive else null
		for u in _game.units:
			if not u.alive or u.team == time or u.em_voo:
				continue
			if not cobre(u.global_position, 0.3):
				continue
			var d := u.global_position - global_position
			d.y = 0
			u.take_damage(cfg.poca_fogo_dano * 0.5 * (dono.damage_mult() if quem else 1.0), quem,
					d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.2, false, "brasa", 1)
	if _acesa_t <= 0.0:
		secar(true)


## Acaba: seca (ou evapora queimada) e some.
func secar(queimada := false) -> void:
	if indo:
		return
	indo = true
	remove_from_group("pocas_cachaca")
	FxObra.poca_seca(self, raio, queimada)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if _visual:
		tw.tween_property(_visual, "scale", Vector3(0.2, 1.0, 0.2), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_interval(0.5)
	tw.tween_callback(queue_free)
