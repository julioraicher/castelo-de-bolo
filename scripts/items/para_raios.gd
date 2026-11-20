class_name ParaRaios
extends PecaDoMundo
## Para-raios do Kaminari-kozō (Q, Heróis 2.27b): baqueta de cobre cravada no
## chão por pararaios_tempo s (até pararaios_max por dono). A cada
## pararaios_cada s dá choque em quem é do outro time a até pararaios_raio m.
## Puxa os raios do dono: na descarga (HeroisNatureza._cadeia) e no alvo dos
## Tambores do Trovão. Visual: FxNatureza.para_raios (cobre, ponta na cor do
## time, faíscas em volta).

var _tick := 0.5


func setup(game: Game, p_dono: Unit, pos: Vector3) -> void:
	_iniciar(game, p_dono, &"para_raios", Config.cfg.herois.pararaios_tempo, pos)
	FxNatureza.para_raios(self, Config.team_color(time))


func topo() -> Vector3:
	return global_position + Vector3(0, 1.6, 0)


func _physics_process(delta: float) -> void:
	if indo:
		return
	_vida -= delta
	if _vida <= 0.0 or not is_instance_valid(dono):
		sair()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = Config.cfg.herois.pararaios_cada
	_choque(Config.cfg.herois.pararaios_dano * dono.damage_mult(), "para_raios")


## Choque em todos do outro time a até pararaios_raio m.
func _choque(dano: float, elemento: String) -> int:
	var n := 0
	for u in _game.units:
		if not u.alive or u.team == time or u.em_voo:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 2.0:
			continue
		d.y = 0
		if d.length() > Config.cfg.herois.pararaios_raio:
			continue
		FxNatureza.raio(_game, topo(), u.global_position + Vector3(0, 1.1, 0), 0.25)
		u.take_damage(dano, dono, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.1, false, elemento, 2)
		n += 1
	if n > 0:
		Sfx.play("kaminari_choque", global_position, 0.1, 1.0, -4.0)
	else:
		FxNatureza.para_raios_ocioso(self)
	return n


## Descarga do dono chegou aqui: estoura em volta (um raio do céu na baqueta).
func descarregar(dano: float) -> void:
	if indo:
		return
	FxNatureza.raio_ceu(_game, global_position)
	_choque(dano, "descarga")


func sair() -> void:
	if not _saindo():
		return
	var tw := _tween_fisica()
	tw.tween_property(self, "scale", Vector3(0.2, 0.05, 0.2), 0.25)
	tw.tween_callback(queue_free)
