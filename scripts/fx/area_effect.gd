class_name AreaEffect
extends Node3D
## Poderes de área dos ninjas, num círculo do chão:
##   nuvem       (fumaça do Bombardeio) inimigos dentro ficam lentos e levam dano em pulsos
##   selo        (Kitsune Sombria) talismãs fecham o círculo: dano e SELO (sem atacar/poder)
##   coluna_fogo (Kitsune) colunas de fogo-raposa queimam em pulsos
##   redemoinho  (Yamabushi, Ciclo 2.23) suga para o centro; o último pulso ergue
##   revoada     (Karasu Tengu, Ciclo 2.23) corvos: dano leve e cega quem está dentro
## Visual barato: poucas malhas grandes, emissivas, animadas à mão.

const PULSE := 0.5

var _game: Game
var _owner: Unit
var _kind := "nuvem"
var _radius := 4.0
var _value := 5.0
var _duration := 3.0
var _t := 0.0
var _pulse_t := 0.0
var _parts: Array[MeshInstance3D] = []
var _mat: StandardMaterial3D


func setup(game: Game, owner_unit: Unit, center: Vector3, kind: String, radius: float, value: float, duration: float) -> void:
	_game = game
	_owner = owner_unit
	_kind = kind
	_radius = radius
	_value = value
	_duration = duration
	global_position = center
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado à mão
	var col := _color()
	MarcaChao.criar(self, kind, radius, col, Config.team_color(owner_unit.team), duration if kind != "selo" else 1.0)
	match kind:
		"nuvem":
			# Névoa leve (Ciclo 2.20): dois véus de fiapos girando em sentidos
			# opostos (2 malhas; antes 8 esferas chapadas que tapavam a luta).
			# A borda da área quem mostra é a MarcaChao.
			Magia.vortice(self, "nevoa", radius * 0.6, 1.5, duration + 0.3, {"r_topo": 1.5, "gira": 0.4, "sobe": -0.12, "base": 0.25, "topo": 0.1, "alfa": 0.65, "tinta": 0.03})
			Magia.vortice(self, "nevoa", radius * 0.3, 2.4, duration + 0.3, {"r_topo": 1.4, "gira": -0.6, "sobe": -0.2, "base": 0.25, "topo": 0.06, "alfa": 0.65, "tinta": 0.03})
			Sfx.play("hit", center, 0.1)
		"selo":
			# Talismãs em pé formando o círculo + anel de raio.
			_mat = Fx.unshaded(col * 1.6)
			var card := BoxMesh.new()
			card.size = Vector3(0.35, 0.8, 0.02)
			for i in 10:
				var a := TAU * i / 10.0
				var mi := _part(card, Vector3(cos(a) * radius, 0.6, sin(a) * radius), _mat)
				mi.rotation.y = -a + PI / 2
			for i in 10:
				var a0 := TAU * i / 10.0
				var a1 := TAU * (i + 1) / 10.0
				Fx.zap(game, center + Vector3(cos(a0) * radius, 0.6, sin(a0) * radius), center + Vector3(cos(a1) * radius, 0.6, sin(a1) * radius), col, 3)
			Sfx.play("sombra", center)
			_apply_seal()
		"coluna_fogo":
			# Três labaredas de energia (Magia) que queimam enquanto o poder dura.
			var pal := Magia.paleta_de(col)  # cor do chapéu de quem lança
			for i in 3:
				var a := TAU * i / 3.0
				Magia.chama(self, center + Vector3(cos(a), 0, sin(a)) * radius * 0.5, pal, 0.5, 3.0, duration + 0.3, {"segura": 0.8, "giro": duration * 0.5, "r_topo": 0.3, "barriga": 0.22, "forca": 1.7, "base": 0.62, "topo": -0.5, "escala": Vector2(3.0, 0.4)})
			Sfx.play("fogo", center, 0.05, 0.8)
		"redemoinho":
			FxHerois.redemoinho_area(self, radius, duration)
			Sfx.play("magia_vento", center, 0.05, 0.8)
		"revoada":
			FxHerois.revoada_area(self, radius, duration)
			Sfx.play("grasnido", center, 0.05)
	scale = Vector3(0.2, 1, 0.2)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _color() -> Color:
	match _kind:
		"nuvem":
			return Color(0.6, 0.55, 0.8)
		"selo":
			# Cor do chapéu de quem lançou (Kitsune Sombria = roxo).
			return _owner.stats.hat_color.lightened(0.25) if _owner else Color(0.6, 0.9, 1.0)
		"coluna_fogo":
			# Fogo-raposa na cor do chapéu (Kitsune = rosa, Luz = dourado, Sombria = roxo).
			return _owner.stats.hat_color.lightened(0.15) if _owner else Color(0.3, 0.95, 1.0)
		"redemoinho":
			return Color(1.0, 0.78, 0.5)
		"revoada":
			return Color(0.3, 0.22, 0.42)
	return Color(0.3, 0.95, 1.0)


func _physics_process(delta: float) -> void:
	_t += delta
	for i in _parts.size():
		var p := _parts[i]
		if _kind == "coluna_fogo":
			p.scale = Vector3(1.0 + 0.2 * sin(_t * 14.0 + i), 1.0 + 0.15 * sin(_t * 9.0 + i * 2.0), 1.0 + 0.2 * sin(_t * 14.0 + i))
			p.rotation.y += delta * 3.0
	if _kind == "selo":
		if _t > 1.0:
			queue_free()
		return
	_pulse_t -= delta
	if _pulse_t <= 0.0:
		_pulse_t = PULSE
		Reacoes.em(_game, global_position, _radius, _kind, _owner.team)
		for u in _game.units:
			if not u.alive or u.team == _owner.team:
				continue
			var d := u.global_position - global_position
			if absf(d.y) > 2.5:
				continue
			d.y = 0
			if d.length() <= _radius:
				u.take_damage(_value, _owner, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.15 if _kind != "redemoinho" else 0.0, false,
						{"coluna_fogo": "fogo", "selo": "magia", "redemoinho": "vento", "revoada": "pena"}.get(_kind, "nuvem"), 3)
				if not u.alive:
					continue
				if _kind == "nuvem":
					u.apply_slow(0.55, PULSE + 0.1)
				elif _kind == "redemoinho":
					if _t + PULSE >= _duration:
						u.launch(7.0)  # o último pulso ergue
					elif d.length() > 0.8 and not u.carried_princess and not u.stats.knock_imune:
						u._knock = -d.normalized() * minf(sqrt(2.0 * Unit.KNOCK_DECAY * d.length() * 0.7), 9.0)
				elif _kind == "revoada":
					u._cego_t = maxf(u._cego_t, PULSE + 0.25)
					if u.is_player:
						_game.hud.flash(Color(0.04, 0.02, 0.07, 0.55), 0.45)
		if _kind == "coluna_fogo":
			Fx.burst(_game, global_position + Vector3(0, 1.0, 0), _color(), 10, 6.0)
	if _t >= _duration:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.3)
		tw.tween_callback(queue_free)
		set_physics_process(false)


func _apply_seal() -> void:
	for u in _game.units:
		if not u.alive or u.team == _owner.team:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 2.5:
			continue
		d.y = 0
		if d.length() <= _radius:
			u.take_damage(_value, _owner, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 0.2, false, "magia", 3)
			u.silence(_duration)


func _part(mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_parts.append(mi)
	return mi

