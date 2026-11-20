extends "res://tests/lib/caso.gd"
## Testes de regra: itens do chão e preferências salvas (revisão 2026-11-19, TS-06:
## os 5 itens e o salvar/carregar das Configurações não tinham nenhum _check).


## Os 5 itens do chão (Pickup.apply_to): poção cura, escudo protege, velocidade
## acelera, dano dobra o golpe e o medidor enche o Chi.
func _itens() -> void:
	var u = _alvo()
	_check(u != null, "itens: faltou boneco")
	if u == null:
		return
	var pk := Pickup.new()
	game.add_child(pk)
	pk.setup("pocao", u.global_position + Vector3(0, 0, 30))
	# Poção: cura uma fração da vida máxima (até o cheio).
	u.hp = u.max_hp() * 0.2
	pk.kind = "pocao"
	pk.apply_to(u)
	_check(_perto(u.hp, minf(u.max_hp() * (0.2 + cfg.pickup_heal), u.max_hp()), 0.5),
			"itens: poção deveria curar %.0f%% da vida" % (cfg.pickup_heal * 100.0))
	# Escudo: valor do config (acompanha vida_mult) pelo tempo do config.
	u._shield = 0.0
	pk.kind = "escudo"
	pk.apply_to(u)
	_check(_perto(u._shield, cfg.pickup_shield * cfg.vida_mult, 0.01) and _perto(u._shield_t, cfg.pickup_shield_time, 0.01),
			"itens: escudo deveria dar %.0f por %.0f s" % [cfg.pickup_shield * cfg.vida_mult, cfg.pickup_shield_time])
	# Velocidade: anda mais rápido enquanto dura.
	u._boost_t = 0.0
	var v0: float = u.current_speed()
	pk.kind = "velocidade"
	pk.apply_to(u)
	_check(_perto(u._boost_t, cfg.pickup_speed_time, 0.01) and u.current_speed() > v0 * (cfg.pickup_speed_mult - 0.01),
			"itens: velocidade deveria multiplicar a corrida por %.2f" % cfg.pickup_speed_mult)
	u._boost_t = 0.0
	# Dano: multiplica o dano do golpe enquanto dura.
	u._dmg_boost_t = 0.0
	var m0: float = u.damage_mult()
	pk.kind = "dano"
	pk.apply_to(u)
	_check(_perto(u.damage_mult(), m0 * cfg.pickup_damage_mult, 0.01) and _perto(u._dmg_boost_t, cfg.pickup_damage_time, 0.01),
			"itens: dano deveria multiplicar por %.1f por %.0f s" % [cfg.pickup_damage_mult, cfg.pickup_damage_time])
	u._dmg_boost_t = 0.0
	# Medidor: Chi cheio na hora (só para quem tem poder de Chi).
	if u.stats.power != "nenhum":
		u.power = 0.0
		pk.kind = "medidor"
		pk.apply_to(u)
		_check(u.power >= u.POWER_MAX - 0.01, "itens: chama de chi deveria encher o medidor")
	_check(Pickup.NAMES.size() == 5, "itens: deveriam ser 5 tipos (poção, escudo, velocidade, dano, medidor)")
	pk.queue_free()
	u._shield = 0.0
	u.hp = u.max_hp()


## Configurações (caça 2026-11-19, UI-05): mudar agenda a gravação (0,4 s), fechar a
## janela com a gravação pendente grava, e o que foi gravado volta ao carregar.
## Guarda e devolve o arquivo do jogador.
func _configuracoes_salvas() -> void:
	var st = get_node("/root/Settings")
	var caminho: String = st.PATH
	var tinha := FileAccess.file_exists(caminho)
	var original := FileAccess.get_file_as_bytes(caminho) if tinha else PackedByteArray()
	var vol0: float = st.sfx_volume
	var novo := 0.37 if not _perto(vol0, 0.37, 0.001) else 0.41
	st.sfx_volume = novo
	st.apply()
	_check(not st._salvar_t.is_stopped(), "configurações: mudar deveria agendar a gravação")
	st._notification(NOTIFICATION_WM_CLOSE_REQUEST)
	_check(st._salvar_t.is_stopped(), "configurações: fechar a janela deveria gravar o que estava pendente")
	var f := ConfigFile.new()
	_check(f.load(caminho) == OK and _perto(float(f.get_value("jogo", "sfx_volume", -1.0)), novo, 0.001),
			"configurações: o arquivo deveria ter o volume novo depois de fechar")
	st.sfx_volume = vol0
	st._load()
	_check(_perto(st.sfx_volume, novo, 0.001), "configurações: carregar deveria trazer o que foi gravado")
	# Devolve tudo como estava (memória e arquivo).
	st.sfx_volume = vol0
	st.apply()
	st._salvar_t.stop()
	if tinha:
		var w := FileAccess.open(caminho, FileAccess.WRITE)
		w.store_buffer(original)
		w.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
