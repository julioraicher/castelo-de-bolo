class_name FxPoder
extends RefCounted
## Assinatura visual de cada poder [Q]: nome do golpe no ar, selo no chão e um
## efeito próprio por poder. Só visual (dano, raio e tempo ficam em Unit).
## Barato para GPU integrada: poucas malhas grandes, cor aditiva sem luz,
## sem sombra, tudo some sozinho em menos de 2 s (ou ao fim do poder).


# --- Comum a todos ---------------------------------------------------------------

## Chamado no começo de qualquer poder.
static func lancar(u: Unit) -> void:
	var cor := u.stats.hat_color.lightened(0.35)
	_nome(u, cor)
	_sigilo(u.game, u.global_position, Color(u.stats.hat_color, 1.0), maxf(u.stats.power_radius, 2.5) if u.stats.power != "leque" else 3.0)


## Nome do golpe na fonte de pincel, sobe e some (estilo anime).
static func _nome(u: Unit, cor: Color) -> void:
	var l := Label3D.new()
	l.text = u.stats.power_name.to_upper() + "!"
	l.font = Estilo.TITULO
	l.font_size = 96 if u.is_player else 46  # bots: menor e mais curto, para não poluir a briga
	l.pixel_size = 0.011
	l.outline_size = 22 if u.is_player else 14
	l.outline_modulate = Color(cor.darkened(0.8), 0.95)
	l.modulate = cor
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	u.game.add_child(l)
	l.global_position = u.global_position + Vector3(0, 3.3, 0)
	l.scale = Vector3.ONE * 0.4
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector3.ONE, 0.08)
	tw.set_parallel()
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.0, 0.9).set_delay(0.3)
	var some := 0.8 if u.is_player else 0.45
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(some)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.4).set_delay(some)
	tw.chain().tween_callback(l.queue_free)


## Selo no chão: dois anéis e raios que giram e abrem.
static func _sigilo(game: Node, pos: Vector3, cor: Color, raio: float) -> void:
	var n := _no(game, pos + Vector3(0, 0.08, 0))
	var mat := _mat(Color(cor * 1.3, 0.85))
	for r in [raio, raio * 0.62]:
		var t := TorusMesh.new()
		t.inner_radius = r - 0.12
		t.outer_radius = r
		t.rings = 32
		t.ring_segments = 4
		var mi := _malha(n, t, mat)
		mi.scale = Vector3(1, 0.04, 1)
	for k in 8:
		var a := TAU * k / 8.0
		var b := BoxMesh.new()
		b.size = Vector3(0.1, 0.02, raio * 0.38)
		var mi := _malha(n, b, mat)
		mi.position = Vector3(sin(a), 0, cos(a)) * raio * 0.81
		mi.rotation.y = a
	n.scale = Vector3.ONE * 0.3
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "rotation:y", PI * 0.5, 1.0)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(n.queue_free)


# --- Um por poder ------------------------------------------------------------------

## Samurai: tornado dourado de anéis inclinados e rajadas que giram com ele.
static func redemoinho(u: Unit) -> void:
	var dur := u.stats.power_duration
	var r := u.stats.power_radius
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(n)
	var mat := _mat(Color(1.6, 1.2, 0.4, 0.55))
	for k in 3:
		var t := TorusMesh.new()
		t.inner_radius = r * (0.55 + 0.15 * k) - 0.15
		t.outer_radius = r * (0.55 + 0.15 * k)
		t.rings = 28
		t.ring_segments = 4
		var mi := _malha(n, t, mat)
		mi.position.y = 0.4 + k * 0.7
		mi.rotation = Vector3(deg_to_rad(10 - k * 8), 0, deg_to_rad(6 * (k - 1)))
		mi.scale = Vector3(1, 0.12, 1)
	for k in 6:
		var a := TAU * k / 6.0
		var b := BoxMesh.new()
		b.size = Vector3(0.07, 0.07, 1.8)
		var mi := _malha(n, b, _mat(Color(2.0, 1.8, 1.2, 0.8)))
		mi.position = Vector3(cos(a), 0, -sin(a)) * r * 0.8 + Vector3(0, 0.6 + (k % 3) * 0.6, 0)
		mi.rotation.y = a
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "rotation:y", -TAU * dur * 2.5, dur)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(maxf(dur - 0.3, 0.0))
	tw.chain().tween_callback(n.queue_free)
	_poeira(u.game, u.global_position, Color(0.85, 0.75, 0.55), 18)
	_succao(u, r * Config.cfg.redemoinho_puxa_raio, dur)


## Vórtice do Redemoinho: anel de vento na borda da puxada que se fecha
## no Samurai (2 vezes), para ler "puxa" e não só "gira".
static func _succao(u: Unit, r_puxa: float, dur: float) -> void:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(n)
	var mat := _mat(Color(1.3, 1.15, 0.8, 0.0))
	var t := TorusMesh.new()
	t.inner_radius = r_puxa - 0.12
	t.outer_radius = r_puxa
	t.rings = 32
	t.ring_segments = 3
	var mi := _malha(n, t, mat)
	mi.position.y = 0.3
	mi.scale = Vector3(1, 0.1, 1)
	var meia := maxf(dur, 0.6) / 2.0
	var tw := n.create_tween()
	for k in 2:
		tw.tween_callback(func() -> void: n.scale = Vector3.ONE)
		tw.tween_property(mat, "albedo_color:a", 0.5, 0.08)
		tw.parallel().tween_property(n, "scale", Vector3(0.35, 1, 0.35), meia).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(n, "rotation:y", -TAU, meia)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.05)
	tw.tween_callback(n.queue_free)


## Armadilheiro (Campo Minado): cada mina sai voando da mão em arco até o
## seu lugar no anel e acende ao cair (luz verde + faíscas).
static func campo_minado(u: Unit, pontos: Array) -> void:
	var cor := u.stats.hat_color
	var g := u.game
	var origem := u.global_position + Vector3(0, 1.3, 0)
	for k in pontos.size():
		var alvo: Vector3 = pontos[k]
		var n := _no(g, origem)
		var s := SphereMesh.new()
		s.radius = 0.16
		s.height = 0.32
		s.radial_segments = 6
		s.rings = 3
		_malha(n, s, _mat(Color(cor * 1.8, 1.0)))
		var atraso := 0.04 * k
		var tw := n.create_tween()
		tw.tween_interval(atraso)
		tw.tween_method(func(f: float) -> void:
			n.global_position = origem.lerp(alvo, f) + Vector3(0, sin(f * PI) * 1.6, 0), 0.0, 1.0, 0.32)
		tw.tween_callback(func() -> void:
			_motas(g, alvo, cor, 6)
			n.queue_free())


## Ronin Oni: cúpula de choque vermelha, labareda e pedras voando; aura de fogo
## enquanto a fúria dura.
static func furia(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	var r := u.stats.power_radius
	var cupula := _no(g, p)
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 6
	var mat := _mat(Color(1.8, 0.25, 0.1, 0.6))
	_malha(cupula, s, mat)
	cupula.scale = Vector3.ONE * 0.4
	var tw := cupula.create_tween().set_parallel()
	tw.tween_property(cupula, "scale", Vector3(r, r * 0.6, r), 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(cupula.queue_free)
	_labareda(g, p, Color(1.8, 0.35, 0.1, 0.7), 1.4, 6.0, 0.6)
	_detritos(g, p, Color(0.35, 0.3, 0.32), 16)
	# Aura: cone de fogo preso no Ronin, tremulando.
	var aura := Node3D.new()
	aura.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(aura)
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.75
	c.height = 2.8
	c.radial_segments = 8
	c.cap_bottom = false
	var amat := _mat(Color(1.6, 0.2, 0.08, 0.35))
	var mi := _malha(aura, c, amat)
	mi.position.y = 1.3
	var dur := u.stats.power_duration
	var pulso := aura.create_tween().set_loops(int(dur / 0.24) + 1)
	pulso.tween_property(mi, "scale", Vector3(1.15, 1.2, 1.15), 0.12)
	pulso.tween_property(mi, "scale", Vector3(0.9, 0.95, 0.9), 0.12)
	var fim := aura.create_tween()
	fim.tween_interval(dur)
	fim.tween_property(amat, "albedo_color:a", 0.0, 0.3)
	fim.tween_callback(aura.queue_free)


## Lâmina Dupla: sombras do ninja pelo caminho, X de corte no fim e, um
## instante depois, o "corte atrasado" em quem foi atravessado.
static func corte_relampago(u: Unit, de: Vector3, ate: Vector3, atingidos: Array) -> void:
	var g := u.game
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.7
	cap.radial_segments = 8
	cap.rings = 2
	for k in 5:
		var t := (k + 0.5) / 5.0
		var n := _no(g, de.lerp(ate, t) + Vector3(0, 0.9, 0))
		var mat := _mat(Color(0.4, 1.6, 2.0, 0.5))
		_malha(n, cap, mat)
		var tw := n.create_tween()
		tw.tween_interval(0.05 * k)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
		tw.tween_callback(n.queue_free)
	var dir := (ate - de).normalized()
	Fx.slash(g, ate + Vector3(0, 1.0, 0), dir, 2.6, 160.0, Color(0.5, 1.0, 1.0), 55.0, true)
	Fx.slash(g, ate + Vector3(0, 1.0, 0), dir, 2.6, 160.0, Color(0.5, 1.0, 1.0), -55.0, true)
	var timer := g.get_tree().create_timer(0.28, false)
	timer.timeout.connect(func():
		Fx.beam(g, de + Vector3(0, 1.0, 0), ate + Vector3(0, 1.0, 0), Color(1.0, 1.0, 1.0), 0.12, 0.25)
		for alvo in atingidos:
			if is_instance_valid(alvo):
				var q: Vector3 = alvo.global_position + Vector3(0, 1.0, 0)
				Fx.beam(g, q - dir * 1.4 + Vector3(0, 0.6, 0), q + dir * 1.4 - Vector3(0, 0.6, 0), Color(0.7, 1.0, 1.0), 0.18, 0.3)
				Fx.burst(g, q, Color(0.6, 1.0, 1.0), 10, 7.0))


## Ninja de Shuriken: leque de luz na frente e uma shuriken gigante girando.
static func leque(u: Unit, dir: Vector3) -> void:
	var g := u.game
	Fx.slash(g, u.global_position + Vector3(0, 1.1, 0), dir, 7.0, maxf(u.stats.power_radius, 40.0), Color(0.4, 1.0, 1.0), 0.0, true)
	var n := _no(g, u.global_position + Vector3(0, 2.6, 0) + dir * 0.6)
	var mat := _mat(Color(0.5, 1.8, 2.0, 0.9))
	for k in 2:
		var b := BoxMesh.new()
		b.size = Vector3(1.6, 0.05, 0.35)
		var mi := _malha(n, b, mat)
		mi.rotation.y = k * PI / 2
	for k in 4:
		var b := BoxMesh.new()
		b.size = Vector3(0.55, 0.05, 0.55)
		var mi := _malha(n, b, mat)
		mi.rotation.y = PI / 4
		mi.position = Vector3(cos(k * PI / 2), 0, sin(k * PI / 2)) * 0.45
		mi.scale = Vector3(0.6, 1, 0.6)
	n.rotation.x = deg_to_rad(-60)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "rotation:y", TAU * 3.0, 0.6)
	tw.tween_property(n, "scale", Vector3.ONE * 1.6, 0.6)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(0.3)
	tw.chain().tween_callback(n.queue_free)


## Arqueiro Yumi: rajada de luz para o céu e a mira desenhada no alvo.
static func chuva(u: Unit, alvo: Vector3, r: float) -> void:
	var g := u.game
	var p := u.global_position + Vector3(0, 1.6, 0)
	for k in 5:
		var off := Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		Fx.beam(g, p + off * 0.3, p + off + Vector3(0, 14.0, 0), Color(1.0, 0.9, 0.5), 0.09, 0.45)
	var cor := Config.team_color(u.team).lightened(0.3)
	var n := _no(g, alvo + Vector3(0, 0.1, 0))
	var mat := _mat(Color(cor * 1.6, 0.9))
	for k in 4:
		var b := BoxMesh.new()
		b.size = Vector3(0.12, 0.02, r * 0.7)
		var mi := _malha(n, b, mat)
		mi.rotation.y = k * PI / 2
		mi.position = Vector3(sin(k * PI / 2), 0, cos(k * PI / 2)) * r * 0.75
	var t := TorusMesh.new()
	t.inner_radius = r * 0.3
	t.outer_radius = r * 0.3 + 0.12
	_malha(n, t, mat).scale = Vector3(1, 0.04, 1)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "rotation:y", PI / 2, ArrowRain.WARN)
	tw.tween_property(n, "scale", Vector3.ONE * 0.7, ArrowRain.WARN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(n.queue_free)


## Monge de Chi: lótus dourada abrindo no chão.
static func bencao(u: Unit) -> void:
	var g := u.game
	var n := _no(g, u.global_position + Vector3(0, 0.1, 0))
	var mat := _mat(Color(1.8, 1.5, 0.7, 0.7))
	var petalas: Array[MeshInstance3D] = []
	for k in 10:
		var a := TAU * k / 10.0
		var pivo := Node3D.new()
		pivo.rotation.y = a
		n.add_child(pivo)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 0.25
		s.radial_segments = 8
		s.rings = 3
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3(0.8, 1, 2.2)
		mi.position = Vector3(0, 0, 0.9)
		pivo.add_child(mi)
		petalas.append(mi)
	n.scale = Vector3.ONE * 0.2
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE * 1.6, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for mi in petalas:
		tw.tween_property(mi, "rotation:x", deg_to_rad(-45), 0.45)
	tw.tween_property(n, "rotation:y", PI / 3, 1.2)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(n.queue_free)


## Em cada aliado curado/protegido: brilho subindo (cor do poder).
static func em_aliado(alvo: Unit, cor: Color) -> void:
	var g := alvo.game
	_motas(g, alvo.global_position, cor, 10)
	Fx.ring(g, alvo.global_position, Color(cor, 0.8), 1.4)


## Armadilheiro: aliados ganham rastro de vento enquanto a corrida dura.
static func rastro(alvo: Unit, cor: Color, dur: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 0.35
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 10.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3.ZERO
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.3, 0.6, 0.3)
	var b := BoxMesh.new()
	b.size = Vector3(0.05, 0.05, 0.7)
	b.material = _mat(Color(cor * 1.6, 0.7))
	p.mesh = b
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.position.y = 0.9
	alvo.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func(): p.emitting = false)
	tw.tween_interval(0.4)
	tw.tween_callback(p.queue_free)


## Bombas de Fumaça: estouro roxo e bolas de fumaça arremessadas.
static func nuvem(g: Node, centro: Vector3, r: float) -> void:
	var n := _no(g, centro + Vector3(0, 0.8, 0))
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 12
	s.rings = 6
	var mat := _mat(Color(1.2, 0.6, 1.8, 0.7))
	_malha(n, s, mat)
	n.scale = Vector3.ONE * 0.3
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE * r * 0.9, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(n.queue_free)
	var bola := SphereMesh.new()
	bola.radius = 0.6
	bola.height = 1.0
	bola.radial_segments = 8
	bola.rings = 4
	for k in 8:
		var a := TAU * k / 8.0
		var b := _no(g, centro + Vector3(0, 0.6, 0))
		var bm := Fx.unshaded(Color(0.5, 0.45, 0.62, 0.8), true)
		_malha(b, bola, bm)
		var t2 := b.create_tween().set_parallel()
		t2.tween_property(b, "position", centro + Vector3(cos(a), 0, sin(a)) * r * 0.9 + Vector3(0, 0.5, 0), 0.4).set_ease(Tween.EASE_OUT)
		t2.tween_property(b, "scale", Vector3.ONE * 1.8, 0.6)
		t2.tween_property(bm, "albedo_color:a", 0.0, 0.5).set_delay(0.3)
		t2.chain().tween_callback(b.queue_free)


## Onmyoji: estrela de cinco pontas de luz e pilares nos vértices.
static func selo(g: Node, centro: Vector3, r: float) -> void:
	var pts: Array[Vector3] = []
	for k in 5:
		var a := TAU * k / 5.0 - PI / 2
		pts.append(centro + Vector3(cos(a), 0.12, sin(a)) * r * 0.85)
	for k in 5:
		Fx.beam(g, pts[k], pts[(k + 2) % 5], Color(0.7, 0.9, 1.0), 0.16, 1.0)
	var c := CylinderMesh.new()
	c.top_radius = 0.12
	c.bottom_radius = 0.2
	c.height = 4.0
	c.radial_segments = 6
	for p in pts:
		var n := _no(g, p + Vector3(0, 2.0, 0))
		var mat := _mat(Color(0.8, 1.2, 2.0, 0.8))
		_malha(n, c, mat)
		n.scale = Vector3(1, 0.1, 1)
		var tw := n.create_tween()
		tw.tween_property(n, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.6).set_delay(0.3)
		tw.tween_callback(n.queue_free)


## Kitsune: erupção de fogo-raposa e orbes girando em volta das colunas.
static func coluna_fogo(g: Node, centro: Vector3, r: float, dur: float, cor := Color(0.25, 0.9, 1.25)) -> void:
	_labareda(g, centro, Color(cor.r * 1.6, cor.g * 1.6, cor.b * 1.6, 0.75), r * 0.55, 8.0, 0.7)
	var n := _no(g, centro + Vector3(0, 1.4, 0))
	var s := SphereMesh.new()
	s.radius = 0.28
	s.height = 0.56
	s.radial_segments = 8
	s.rings = 4
	var mat := _mat(Color(cor.r * 1.6, cor.g * 1.6, cor.b * 1.6, 0.95).lerp(Color(2, 2, 2, 0.95), 0.35))
	for k in 6:
		var a := TAU * k / 6.0
		var mi := _malha(n, s, mat)
		mi.position = Vector3(cos(a), sin(a * 2.0) * 0.4, sin(a)) * r * 0.75
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "rotation:y", TAU * dur * 0.8, dur)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(maxf(dur - 0.3, 0.0))
	tw.chain().tween_callback(n.queue_free)


## Carpinteiro: feixe de trabalho até a oficina e faíscas douradas nela.
static func mutirao(u: Unit, oficina: Node3D) -> void:
	var g := u.game
	var alvo := oficina.global_position
	Fx.beam(g, u.global_position + Vector3(0, 1.2, 0), alvo + Vector3(0, 1.5, 0), Color(1.0, 0.8, 0.35), 0.3, 0.7)
	_motas(g, alvo, Color(1.0, 0.85, 0.35), 24)
	_detritos(g, alvo + Vector3(0, 1.0, 0), Color(0.6, 0.4, 0.25), 10)


## Bombardeiro: aviso com pavio em cada ponto. O anel encolhe até o centro no
## tempo exato da explosão, então dá para ler a ordem da fila e fugir.
static func aviso_bombardeio(g: Node, pontos: Array, r: float, intervalo: float) -> void:
	for i in pontos.size():
		var atraso := intervalo * (i + 1)
		var n := _no(g, pontos[i] + Vector3(0, 0.08, 0))
		# Mistura normal (não aditiva): aditivo laranja sobre grama vira amarelo.
		var mat := Fx.unshaded(Color(1.0, 0.4, 0.06, 0.8), true)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var t := TorusMesh.new()
		t.inner_radius = r - 0.12
		t.outer_radius = r
		_malha(n, t, mat).scale = Vector3(1, 0.05, 1)
		var faisca := SphereMesh.new()
		faisca.radius = 0.16
		faisca.height = 0.32
		faisca.radial_segments = 6
		faisca.rings = 3
		var fmat := _mat(Color(2.2, 1.3, 0.4, 1.0))
		var fi := _malha(n, faisca, fmat)
		fi.position = Vector3(0, 0.15, r)
		var tw := n.create_tween().set_parallel()
		tw.tween_property(n, "scale", Vector3(0.12, 1, 0.12), atraso).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "rotation:y", -TAU * (0.5 + i * 0.25), atraso)
		tw.tween_property(mat, "albedo_color", Color(1.0, 0.15, 0.05, 0.95), atraso)
		tw.chain().tween_callback(n.queue_free)


## Explosão de pólvora: bola de fogo que incha, coluna curta, fumaça escura,
## estilhaços e o chão queimado que fica uns segundos (lê onde caiu).
static func explosao_polvora(g: Node, at: Vector3, r: float) -> void:
	var n := _no(g, at + Vector3(0, 0.5, 0))
	var bola := SphereMesh.new()
	bola.radius = 1.0
	bola.height = 2.0
	bola.radial_segments = 10
	bola.rings = 5
	# Casca laranja opaca (mistura normal, lê laranja em qualquer chão) e
	# miolo aditivo amarelo menor: fogo com volume sem estourar para branco.
	var mat := Fx.unshaded(Color(1.0, 0.42, 0.08, 0.9), true)
	_malha(n, bola, mat)
	var miolo := _mat(Color(1.6, 1.1, 0.35, 1.0))
	_malha(n, bola, miolo).scale = Vector3.ONE * 0.6
	n.scale = Vector3.ONE * 0.3
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3(r * 0.8, r * 0.55, r * 0.8), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color", Color(0.25, 0.08, 0.04, 0.0), 0.45).set_delay(0.08)
	tw.tween_property(miolo, "albedo_color:a", 0.0, 0.25).set_delay(0.05)
	tw.chain().tween_callback(n.queue_free)
	_labareda(g, at, Color(1.0, 0.45, 0.08, 0.55), r * 0.45, 3.2, 0.45)
	_detritos(g, at, Color(0.22, 0.18, 0.16), 8)
	_poeira(g, at, Color(0.2, 0.18, 0.2), 10)
	# Mancha queimada: material normal (não aditivo), some em 4 s.
	var q := _no(g, at + Vector3(0, 0.04, 0))
	var disco := CylinderMesh.new()
	disco.top_radius = r * 0.75
	disco.bottom_radius = r * 0.75
	disco.height = 0.02
	disco.radial_segments = 14
	var qmat := Fx.unshaded(Color(0.05, 0.035, 0.03, 0.6), true)
	_malha(q, disco, qmat)
	q.rotation.y = randf() * TAU
	var tq := q.create_tween()
	tq.tween_property(qmat, "albedo_color:a", 0.0, 2.5).set_delay(1.5)
	tq.tween_callback(q.queue_free)


## Arremate da Chuva de Flechas: cinco lanças de luz caem juntas no centro e
## abrem um clarão em cruz na cor do time (`cor` = cor pura, sem clarear).
static func arremate_chuva(g: Node, centro: Vector3, r: float, cor: Color) -> void:
	for k in 5:
		var a := k * TAU / 5.0
		var p: Vector3 = centro + Vector3(cos(a), 0, sin(a)) * r * 0.35 if k > 0 else centro
		Fx.beam(g, p + Vector3(0, 12.0, 0), p + Vector3(0, 0.2, 0), cor, 0.18 if k == 0 else 0.1, 0.3)
	# Cor pura do time e alfa baixo: aditivo forte em chão claro estoura para
	# branco e vira um cone de gesso (visto no print do 2.4l).
	_labareda(g, centro, Color(cor, 0.45), r * 0.35, 3.0, 0.35)
	var n := _no(g, centro + Vector3(0, 0.1, 0))
	var mat := _mat(Color(cor * 1.3, 0.9))
	for k in 4:
		var b := BoxMesh.new()
		b.size = Vector3(0.22, 0.02, r * 1.6)
		_malha(n, b, mat).rotation.y = k * PI / 4
	n.scale = Vector3.ONE * 0.3
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.45).set_delay(0.1)
	tw.chain().tween_callback(n.queue_free)


# --- Economia e placar ------------------------------------------------------------

## Oficina sobe de nível: três anéis dourados sobem pela casa e o letreiro
## "NÍVEL N!" estoura em cima.
static func subir_nivel(g: Node, pos: Vector3, cor: Color, nivel: int) -> void:
	var ouro := Color(1.0, 0.82, 0.35)
	for i in 3:
		var n := _no(g, pos + Vector3(0, 0.3, 0))
		var t := TorusMesh.new()
		t.inner_radius = 2.2
		t.outer_radius = 2.45
		t.rings = 32
		t.ring_segments = 4
		var mat := Fx.unshaded(Color(ouro.lerp(cor, 0.25), 0.0), true)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := _malha(n, t, mat)
		mi.scale = Vector3(1, 0.08, 1)
		var tw := n.create_tween()
		tw.tween_interval(0.18 * i)
		tw.tween_property(mat, "albedo_color:a", 0.9, 0.08)
		tw.set_parallel()
		tw.tween_property(n, "global_position:y", pos.y + 4.5 + i * 0.6, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(n, "scale", Vector3.ONE * (0.55 - 0.08 * i), 1.1).set_ease(Tween.EASE_OUT)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_delay(0.6)
		tw.chain().tween_callback(n.queue_free)
	_motas(g, pos + Vector3(0, 1.0, 0), ouro, 16)
	var l := Label3D.new()
	l.text = "NÍVEL %d!" % nivel
	l.font = Estilo.TITULO
	l.font_size = 80
	l.pixel_size = 0.011
	l.outline_size = 20
	l.outline_modulate = Color(0.25, 0.12, 0.0, 0.95)
	l.modulate = ouro.lightened(0.2)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(l)
	l.global_position = pos + Vector3(0, 5.2, 0)
	l.scale = Vector3.ONE * 0.3
	var tl := l.create_tween()
	tl.tween_property(l, "scale", Vector3.ONE * 1.2, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tl.tween_property(l, "scale", Vector3.ONE, 0.1)
	tl.set_parallel()
	tl.tween_property(l, "global_position:y", l.global_position.y + 1.2, 1.4).set_delay(0.4)
	tl.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(1.2)
	tl.tween_property(l, "outline_modulate:a", 0.0, 0.5).set_delay(1.2)
	tl.chain().tween_callback(l.queue_free)


## Captura da máscara: coluna de luz no castelo de quem pontuou, visível de
## longe (sobe acima dos telhados), com anéis subindo e a marca no chão.
static func coluna_captura(g: Node, pos: Vector3, cor_time: Color) -> void:
	var claro := cor_time.lightened(0.45)
	for camada in [[2.2, 0.45, claro], [0.9, 0.8, Color(1.0, 0.95, 0.8)]]:
		var n := _no(g, pos)
		var c := CylinderMesh.new()
		c.top_radius = camada[0] * 0.7
		c.bottom_radius = camada[0]
		c.height = 40.0
		c.radial_segments = 16
		c.cap_top = false
		c.cap_bottom = false
		var mat := Fx.unshaded(Color(camada[2], camada[1]), true)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := _malha(n, c, mat)
		mi.position.y = 20.0
		n.scale = Vector3(0.1, 1, 0.1)
		var tw := n.create_tween().set_parallel()
		tw.tween_property(n, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(mat, "albedo_color:a", 0.0, 1.2).set_delay(1.6)
		tw.tween_property(n, "scale", Vector3(0.3, 1, 0.3), 1.2).set_delay(1.6)
		tw.chain().tween_callback(n.queue_free)
	for i in 4:
		var n := _no(g, pos + Vector3(0, 0.3, 0))
		var t := TorusMesh.new()
		t.inner_radius = 2.6
		t.outer_radius = 3.0
		t.rings = 32
		t.ring_segments = 4
		var mat := Fx.unshaded(Color(claro, 0.0), true)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := _malha(n, t, mat)
		mi.scale = Vector3(1, 0.06, 1)
		var tw := n.create_tween()
		tw.tween_interval(0.25 * i)
		tw.tween_property(mat, "albedo_color:a", 0.85, 0.08)
		tw.set_parallel()
		tw.tween_property(n, "global_position:y", pos.y + 14.0, 1.6).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "scale", Vector3.ONE * 0.4, 1.6)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.6).set_delay(1.0)
		tw.chain().tween_callback(n.queue_free)
	_motas(g, pos + Vector3(0, 0.5, 0), claro, 24)
	FxProjetil.marca_chao(g, pos, Color(claro, 0.5), 3.5, 3.0)


# --- Peças --------------------------------------------------------------------------

static func _mat(cor: Color) -> StandardMaterial3D:
	var m := Fx.unshaded(cor, true)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _no(parent: Node, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	parent.add_child(n)
	n.global_position = pos
	return n


static func _malha(parent: Node3D, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Coluna de fogo/luz que nasce do chão e some.
static func _labareda(g: Node, pos: Vector3, cor: Color, raio: float, altura: float, vida: float) -> void:
	var n := _no(g, pos)
	var c := CylinderMesh.new()
	c.top_radius = raio * 0.15
	c.bottom_radius = raio
	c.height = altura
	c.radial_segments = 10
	c.cap_top = false
	c.cap_bottom = false
	var mat := _mat(cor)
	var mi := _malha(n, c, mat)
	mi.position.y = altura / 2.0
	n.scale = Vector3(1, 0.05, 1)
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3(1.2, 1, 1.2), 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "rotation:y", PI, vida)
	tw.tween_property(mat, "albedo_color:a", 0.0, vida * 0.7).set_delay(vida * 0.3)
	tw.chain().tween_callback(n.queue_free)


## Pedaços (pedra/madeira) voando e caindo.
static func _detritos(g: Node, pos: Vector3, cor: Color, qtd: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = qtd
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 11.0
	p.gravity = Vector3(0, -26, 0)
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.mesh = Fx.cached("detrito" + cor.to_html(), func() -> Mesh:
		var b := BoxMesh.new()
		b.size = Vector3(0.22, 0.18, 0.2)
		b.material = Fx.lit(cor)
		return b)
	g.add_child(p)
	p.global_position = pos + Vector3(0, 0.2, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Pontinhos de luz subindo devagar.
static func _motas(g: Node, pos: Vector3, cor: Color, qtd: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = qtd
	p.lifetime = 1.0
	p.explosiveness = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.8
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3.ZERO
	p.mesh = Fx.cached("mota" + cor.to_html(), func() -> Mesh:
		var s := SphereMesh.new()
		s.radius = 0.07
		s.height = 0.14
		s.radial_segments = 4
		s.rings = 2
		s.material = _mat(Color(cor * 1.8, 1.0))
		return s)
	g.add_child(p)
	p.global_position = pos + Vector3(0, 0.6, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Poeira baixa em anel (giro do Samurai).
static func _poeira(g: Node, pos: Vector3, cor: Color, qtd: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = qtd
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector3(1, 0.2, 0)
	p.spread = 180.0
	p.flatness = 0.9
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 7.0
	p.damping_min = 6.0
	p.damping_max = 8.0
	p.gravity = Vector3.ZERO
	p.mesh = Fx.cached("poeira" + cor.to_html(), func() -> Mesh:
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.4
		s.radial_segments = 6
		s.rings = 3
		s.material = Fx.unshaded(Color(cor, 0.5), true)
		return s)
	g.add_child(p)
	p.global_position = pos + Vector3(0, 0.3, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)
