class_name FxHerois
extends RefCounted
## Efeitos dos heróis raros (Ciclo 2.23), no kit `Magia` (docs/direcao-efeitos.md
## §8): pico forte ~0,3 s e um resto discreto; cada peça é 1 chamada de desenho
## e some sozinha. Só visual: dano, raio e tempo ficam em Herois.
## Elementos: Sumotori sal/terra, Kappa água, Yamabushi vento, Karasu pena,
## Mujina fumaça roxa, Onmyoji papel, Tennin celeste, Komusō som.

const SAL := Color(0.97, 0.95, 0.9)
const AGUA := Color(0.45, 0.85, 1.0)
const PENA := Color(0.16, 0.12, 0.24)
const PAPEL := Color(0.98, 0.96, 0.88)
const CELESTE := Color(1.0, 0.78, 0.85)
const SOM := Color(0.55, 0.95, 0.88)
const ROXO := Color(0.72, 0.45, 0.95)


static func _g(u: Unit) -> Node:
	return u.game


# --- Sumotori --------------------------------------------------------------------

static func agarrao(u: Unit, alvo: Unit) -> void:
	var g := _g(u)
	var p := alvo.global_position + Vector3(0, 1.0, 0)
	Magia.estouro(g, p, "sal", 0.9, 0.25)
	FxProjetil.faiscas(g, p, SAL, 8, 5.0, Vector3.UP, 120.0, 0.2)
	Fx.damage_number(g, alvo.global_position + Vector3(0, 0.6, 0), "AGARRADO!", Color(1.0, 0.9, 0.6))


static func agarrao_vazio(u: Unit, dir: Vector3) -> void:
	Fx.slash(_g(u), u.global_position + Vector3(0, 1.0, 0), dir, 2.6, 70.0, SAL, 0.0, false)


static func pouso_pesado(g: Node, at: Vector3, r: float) -> void:
	Magia.onda(g, at, "sal", r * 1.3, 0.4, {"banda": 0.18})
	Magia.rachaduras(g, at, "brasa", r, 7, 1.0)
	FxProjetil.fumaca(g, at + Vector3(0, 0.3, 0), Color(0.75, 0.68, 0.58, 0.8), 8, 1.4, 0.9, 1.0)
	FxProjetil.marca_chao(g, at, Color(0.2, 0.15, 0.1, 0.5), r * 0.8, 2.5)


static func pisao_grande(u: Unit, r: float) -> void:
	var g := _g(u)
	var at := u.global_position
	Magia.onda(g, at, "sal", r * 1.15, 0.5, {"banda": 0.2, "gira": 0.4})
	Magia.onda(g, at, "brasa", r * 0.7, 0.35, {"banda": 0.12})
	Magia.rachaduras(g, at, "brasa", r * 0.9, 10, 1.4)
	Magia.brasas(g, at, SAL, 14, r * 0.6, 1.2)
	FxProjetil.fumaca(g, at + Vector3(0, 0.3, 0), Color(0.75, 0.68, 0.58, 0.8), 10, 1.8, 1.0, 1.2)
	Sfx.play("explosao", at, 0.05, 0.7, -2.0)


## Ringue de sal: círculo de sal no chão, corda shimenawa (anel) e grãos subindo.
static func dohyo(u: Unit, r: float, dur: float) -> void:
	var g := _g(u)
	var at := u.global_position
	Assinatura.selo(g, at, u, r * 1.18, dur, {"escrita": 0.08})  # a corda fica na borda do ringue
	Magia.onda(g, at, "sal", r, 0.5, {"r0": 0.2, "banda": 0.06})
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(n)
	n.global_position = at
	var anel := TorusMesh.new()
	anel.inner_radius = r - 0.12
	anel.outer_radius = r + 0.12
	anel.rings = 40
	anel.ring_segments = 6
	var pecas: Array = [[anel, Transform3D(Basis.from_scale(Vector3(1, 0.6, 1)), Vector3(0, 0.15, 0))]]
	var fita := BoxMesh.new()
	fita.size = Vector3(0.12, 0.45, 0.03)
	for i in 12:
		var a := TAU * i / 12.0
		pecas.append([fita, Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * r, -0.05, sin(a) * r))])
	var mat := Fx.unshaded(Color(0.98, 0.95, 0.86))
	Fx.montar_pecas(n, pecas, mat)
	n.scale = Vector3(0.3, 1, 0.3)
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(dur - 0.55, 0.1))
	tw.tween_property(n, "scale", Vector3(1, 0.01, 1), 0.3)
	tw.tween_callback(n.queue_free)
	Magia.brasas(g, at, SAL, 20, r, dur * 0.4)


# --- Kappa ---------------------------------------------------------------------

static func poca(g: Node, at: Vector3) -> void:
	Magia.onda(g, at, "agua", 1.8, 0.4, {"banda": 0.3})
	FxProjetil.ps(g, at + Vector3(0, 0.2, 0), FxProjetil._gota(), AGUA, FxProjetil._qtd(12), 0.5,
			{"dir": Vector3.UP, "spread": 35.0, "v0": 3.0, "v1": 6.0, "g": Vector3(0, -16, 0), "s0": 0.6, "s1": 1.1, "alinha": true})
	FxProjetil.marca_chao(g, at, Color(0.2, 0.45, 0.6, 0.45), 1.2, 1.5)


static func jato(u: Unit, de: Vector3, ate: Vector3, larg: float) -> void:
	var g := _g(u)
	var y := Vector3(0, 1.1, 0)
	Magia.lanca(g, de + y, ate + y, "agua", larg * 1.2, 0.45, {"cresce": 0.12, "corre": 6.0, "forca": 1.1})
	Magia.lanca(g, de + y, ate + y, [Color(1, 1, 1), AGUA, Color(0.1, 0.4, 0.8)], larg * 0.5, 0.35, {"cresce": 0.1, "corre": 9.0})
	poca(g, ate)
	FxProjetil.ps(g, ate + y, FxProjetil._gota(), AGUA, FxProjetil._qtd(16), 0.6,
			{"dir": (ate - de).normalized() + Vector3.UP * 0.6, "spread": 50.0, "v0": 4.0, "v1": 8.0, "g": Vector3(0, -16, 0), "s0": 0.7, "s1": 1.2, "alinha": true})
	Sfx.play("agua", de, 0.05)


static func casco(u: Unit, dir: Vector3) -> void:
	var g := _g(u)
	var p := u.global_position + Vector3(0, 1.1, 0) - dir * 0.5
	FxProjetil.faiscas(g, p, Color(0.8, 1.0, 0.85), 6, 5.0, -dir + Vector3.UP * 0.5, 60.0, 0.18)
	Magia.estouro(g, p, "agua", 0.7, 0.2)
	Sfx.play("block", u.global_position, 0.1, 1.3, -3.0)
	if u.is_player:
		Fx.damage_number(g, u.global_position + Vector3(0, 0.4, 0), "CASCO", Color(0.6, 1.0, 0.8), 0.7)


# --- Yamabushi -------------------------------------------------------------------

static func rajada(u: Unit, dir: Vector3, r: float) -> void:
	var g := _g(u)
	var de := u.global_position + Vector3(0, 1.1, 0)
	Fx.slash(g, de, dir, r, Config.cfg.rajada_cone, Color(1.0, 0.9, 0.7), 0.0, true)
	for k in [-1.0, 0.0, 1.0]:
		var d := dir.rotated(Vector3.UP, deg_to_rad(k * Config.cfg.rajada_cone * 0.33))
		Magia.lanca(g, de + d * 0.6, de + d * r, "vento", 0.7, 0.3, {"cresce": 0.1, "corre": 7.0})
	Magia.orbita(u, Color(1.0, 0.75, 0.45), 1.2, 0.3, 8)


static func redemoinho_area(n: Node3D, r: float, dur: float) -> void:
	Magia.vortice(n, "vento", r * 0.55, 3.2, dur, {"r_topo": 1.9, "gira": 2.4})
	Magia.vortice(n, [Color(1, 1, 1), Color(1.0, 0.75, 0.45), Color(0.8, 0.4, 0.15)], r * 0.3, 2.2, dur, {"r_topo": 1.5, "gira": -3.0, "forca": 1.6, "base": 0.15, "topo": 0.02})
	Magia.orbita(n, Color(1.0, 0.85, 0.6), r * 0.8, dur, 14)


# --- Karasu Tengu ---------------------------------------------------------------

static func marca_mergulho(g: Node, at: Vector3, r: float, tempo: float, cor_time: Color) -> void:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(n)
	n.global_position = at
	MarcaChao.criar(n, "chuva", r, Color(0.35, 0.25, 0.55), cor_time, tempo)
	var tw := n.create_tween()
	tw.tween_interval(tempo + 0.05)
	tw.tween_callback(n.queue_free)


## Asas abertas no ar: duas fitas de pena saindo dos ombros + penas soltas.
static func asas(u: Unit, tempo: float) -> void:
	var pal := [Color(0.6, 0.5, 0.9), Color(0.28, 0.2, 0.45), PENA]
	for s in [-1.0, 1.0]:
		Magia.fita(u, Vector3(0.35 * s, 1.5, -0.1), Vector3(1.6 * s, 1.9, -0.5), pal, tempo, {"pontos": 10, "forca": 0.6})
	FxProjetil.ps(_g(u), u.global_position + Vector3(0, 1.2, 0), FxProjetil.lasca(0.3, 0.09), PENA, FxProjetil._qtd(10), 0.8,
			{"esfera": 0.6, "dir": Vector3.UP, "spread": 80.0, "v0": 1.0, "v1": 3.0, "g": Vector3(0, -2, 0), "s0": 0.8, "s1": 1.3, "ang1": 360.0})


static func impacto_mergulho(g: Node, at: Vector3, r: float) -> void:
	Magia.onda(g, at, [Color(0.85, 0.8, 1.0), Color(0.5, 0.38, 0.8), PENA], r * 1.3, 0.4, {"banda": 0.2})
	Magia.estouro(g, at + Vector3(0, 0.3, 0), "sombra", r * 0.7, 0.3)
	FxProjetil.ps(g, at + Vector3(0, 0.6, 0), FxProjetil.lasca(0.32, 0.09), PENA, FxProjetil._qtd(16), 1.0,
			{"esfera": 0.5, "dir": Vector3.UP, "spread": 70.0, "v0": 3.0, "v1": 6.0, "g": Vector3(0, -4, 0), "s0": 0.8, "s1": 1.4, "ang1": 360.0})
	FxProjetil.marca_chao(g, at, Color(0.08, 0.05, 0.12, 0.55), r * 0.7, 2.0)


static func revoada_area(n: Node3D, r: float, dur: float) -> void:
	Magia.vortice(n, [Color(0.55, 0.45, 0.8), Color(0.22, 0.16, 0.35), PENA], r * 0.75, 2.6, dur, {"r_topo": 1.3, "gira": 1.2, "alfa": 0.75, "base": 0.3, "topo": 0.1})
	if Magia.enfeite():
		var p := FxProjetil.ps(n, Vector3(0, 1.4, 0), FxProjetil.lasca(0.34, 0.1), PENA, 18, 0.9, {
			"one_shot": false, "local": true, "local_pos": true, "radial": -r * 3.0, "alinha": true, "rampa": "nasce", "s0": 0.9, "s1": 1.5, "g": Vector3(0, 1.0, 0)})
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		p.emission_ring_axis = Vector3.UP
		p.emission_ring_radius = r
		p.emission_ring_inner_radius = r * 0.5
		p.emission_ring_height = 1.6
		p.tangential_accel_min = r * 14.0
		p.tangential_accel_max = r * 20.0
		var tw := p.create_tween()
		tw.tween_interval(dur)
		tw.tween_callback(func() -> void: p.emitting = false)


# --- Mujina ---------------------------------------------------------------------

static func rosto(u: Unit, alvo: Unit) -> void:
	var g := _g(u)
	Magia.bola(g, u.global_position + Vector3(0, 1.2, 0), "sombra", 1.3, 0.45)
	FxProjetil.fumaca(g, u.global_position + Vector3(0, 1.0, 0), Color(0.35, 0.2, 0.5, 0.85), 10, 1.4, 0.8, 1.0)
	Magia.lanca(g, alvo.global_position + Vector3(0, 1.5, 0), u.global_position + Vector3(0, 1.5, 0), "sombra", 0.35, 0.3, {"cresce": 0.1})


static func rosto_cai(u: Unit) -> void:
	var g := _g(u)
	FxProjetil.fumaca(g, u.global_position + Vector3(0, 1.0, 0), Color(0.35, 0.2, 0.5, 0.85), 8, 1.2, 0.7, 1.0)
	Magia.estouro(g, u.global_position + Vector3(0, 1.0, 0), "sombra", 1.0, 0.3)


static func susto(u: Unit, dir: Vector3, r: float) -> void:
	var g := _g(u)
	Fx.slash(g, u.global_position + Vector3(0, 1.2, 0), dir, r, 90.0, ROXO, 0.0, true)
	Magia.onda(g, u.global_position, "sombra", r, 0.35, {"banda": 0.15})
	FxProjetil.ps(g, u.global_position + Vector3(0, 1.6, 0) + dir * 0.5, FxProjetil.quad("olho", FxProjetil.tex_olho(), false, Vector2(0.5, 0.5)), Color(0.9, 0.75, 1.0), FxProjetil._qtd(6), 0.6,
			{"dir": dir + Vector3.UP * 0.2, "spread": 40.0, "v0": 4.0, "v1": 7.0, "s0": 1.0, "s1": 1.6})
	Sfx.play("sombra_poder", u.global_position, 0.05)


# --- Onmyoji --------------------------------------------------------------------

static func dobra(u: Unit) -> void:
	var g := _g(u)
	FxProjetil.ps(g, u.global_position + Vector3(0, 1.4, 0), FxProjetil._c("quad_papel", func() -> Mesh:
		var q := QuadMesh.new()
		q.size = Vector2(0.18, 0.24)
		return q), PAPEL, FxProjetil._qtd(8), 0.5, {"esfera": 0.4, "v0": 1.0, "v1": 2.5, "ang1": 360.0, "s0": 0.8, "s1": 1.2})
	Magia.estouro(g, u.global_position + Vector3(0, 1.3, 0), "papel", 0.8, 0.25)


static func shikigami_rasga(u: Unit) -> void:
	var g := _g(u)
	FxProjetil.ps(g, u.global_position + Vector3(0, 1.3, 0), FxProjetil.lasca(0.2, 0.12), PAPEL, FxProjetil._qtd(12), 0.7,
			{"esfera": 0.6, "v0": 2.0, "v1": 4.5, "g": Vector3(0, -4, 0), "ang1": 360.0, "s0": 0.8, "s1": 1.3})
	Magia.estouro(g, u.global_position + Vector3(0, 1.2, 0), "papel", 1.2, 0.25)
	Fx.damage_number(g, u.global_position + Vector3(0, 0.6, 0), "PAPEL!", PAPEL, 0.7)


static var _mat_papel: StandardMaterial3D

## Bonecos de papel girando em volta do Onmyoji (1 malha, 1 chamada).
static func bonecos(u: Unit, n: int) -> Node3D:
	var no := Node3D.new()
	no.name = "Shikigami"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(no)
	if _mat_papel == null:
		_mat_papel = StandardMaterial3D.new()
		_mat_papel.albedo_color = PAPEL
		_mat_papel.emission_enabled = true
		_mat_papel.emission = Color(1.0, 0.95, 0.8)
		_mat_papel.emission_energy_multiplier = 0.35
		_mat_papel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var corpo := BoxMesh.new()
	corpo.size = Vector3(0.3, 0.38, 0.025)
	var cab := CylinderMesh.new()
	cab.top_radius = 0.11
	cab.bottom_radius = 0.11
	cab.height = 0.025
	cab.radial_segments = 10
	var bracos := BoxMesh.new()
	bracos.size = Vector3(0.5, 0.07, 0.025)
	var pernas := BoxMesh.new()
	pernas.size = Vector3(0.08, 0.2, 0.025)
	var pecas: Array = []
	for i in n:
		var a := TAU * i / maxf(n, 1)
		var base := Transform3D(Basis(Vector3.UP, -a + PI * 0.5), Vector3(cos(a) * 1.05, 1.35, sin(a) * 1.05))
		pecas.append([corpo, base])
		pecas.append([cab, base * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.29, 0))])
		pecas.append([bracos, base * Transform3D(Basis(), Vector3(0, 0.1, 0))])
		for s in [-1, 1]:
			pecas.append([pernas, base * Transform3D(Basis(Vector3.BACK, 0.25 * s), Vector3(0.07 * s, -0.27, 0))])
	Fx.montar_pecas(no, pecas, _mat_papel)
	var tw := no.create_tween().set_loops()
	tw.tween_property(no, "rotation:y", TAU, 2.4).from(0.0)
	return no


# --- Tennin ---------------------------------------------------------------------

static func laco(u: Unit, alvo: Unit) -> void:
	var g := _g(u)
	var de := u.global_position + Vector3(0, 1.4, 0)
	var ate := alvo.global_position + Vector3(0, 0.6 if not alvo.alive else 1.2, 0)
	Magia.lanca(g, de, ate, "celeste", 0.45, 0.45, {"cresce": 0.12, "corre": 4.0})
	Magia.lanca(g, de, ate, [Color(1, 1, 1), Config.team_color(u.team).lightened(0.3), Config.team_color(u.team)], 0.18, 0.4, {"cresce": 0.1})
	Magia.estouro(g, ate, "celeste", 1.0, 0.3)


static func danca(u: Unit, r: float, dur: float) -> void:
	var g := _g(u)
	Assinatura.selo(g, u.global_position, u, r, dur, {"escrita": 0.3, "giro": 0.3})
	Magia.vortice(u, "celeste", r * 0.35, 2.0, dur, {"r_topo": 2.4, "gira": 1.4, "alfa": 0.7})
	Magia.aura_brasas(u, CELESTE, dur, 10, 1.2)
	Sfx.play("magia_luz", u.global_position, 0.05)


static func veu(u: Unit, r: float) -> void:
	var g := _g(u)
	Magia.onda(g, u.global_position, "celeste", r, 0.6, {"banda": 0.1, "gira": 0.6})
	Magia.anel_sobe(g, u.global_position, "celeste", 2.0, 3.0, 0.9)


static func veu_em(o: Unit, t: float) -> void:
	Magia.vortice(o, "celeste", 0.9, 2.4, t, {"r_topo": 1.0, "gira": 0.8, "alfa": 0.55, "base": 0.35, "topo": 0.3})


# --- Komusō ---------------------------------------------------------------------

static func canto(u: Unit, dir: Vector3, r: float, dur: float) -> void:
	var g := _g(u)
	for k in 3:
		var tw := u.create_tween()
		tw.tween_interval(k * dur / 3.0)
		tw.tween_callback(func() -> void:
			if is_instance_valid(u) and u._canto_t > 0.0:
				Fx.slash(g, u.global_position + Vector3(0, 1.4, 0), u._facing(), r, 60.0, SOM, 0.0, false)
				_notas(g, u.global_position + Vector3(0, 1.6, 0), u._facing(), 5))


static func canto_fim(u: Unit, dir: Vector3, r: float) -> void:
	var g := _g(u)
	Fx.slash(g, u.global_position + Vector3(0, 1.4, 0), dir, r, 60.0, Color(0.7, 0.85, 1.0), 0.0, true)
	Magia.onda(g, u.global_position + dir * r * 0.5, [Color(0.95, 1.0, 1.0), Color(0.55, 0.75, 1.0), Color(0.2, 0.3, 0.7)], r * 0.5, 0.5, {"banda": 0.15})


static func sono_em(o: Unit) -> void:
	Magia.estouro(_g(o), o.global_position + Vector3(0, 1.0, 0), [Color(0.95, 1.0, 1.0), Color(0.55, 0.75, 1.0), Color(0.2, 0.3, 0.7)], 1.0, 0.35)


static func hipnose(u: Unit, r: float) -> void:
	var g := _g(u)
	Assinatura.selo(g, u.global_position, u, r, 1.2, {"escrita": 0.2})
	Magia.onda(g, u.global_position, "som", r, 0.6, {"gira": 1.0, "banda": 0.08})
	Magia.onda(g, u.global_position, "som", r * 0.3, 0.6, {"r0": 3.3, "gira": -1.5, "banda": 0.08})
	_notas(g, u.global_position + Vector3(0, 1.6, 0), Vector3.FORWARD, 10, 180.0)
	Sfx.play("flauta", u.global_position, 0.05, 0.8)


static func hipnose_em(o: Unit, t: float) -> void:
	Magia.orbita(o, SOM, 0.7, t, 6, 2.2)


static func requiem(u: Unit, r: float) -> void:
	var g := _g(u)
	Magia.onda(g, u.global_position, "som", r, 0.8, {"banda": 0.06, "gira": 0.3})
	Magia.onda(g, u.global_position, [Color(0.9, 0.95, 1.0), Color(0.45, 0.5, 0.6), Color(0.15, 0.15, 0.22)], r * 0.6, 0.6, {"banda": 0.12})
	Magia.anel_sobe(g, u.global_position, "som", 1.6, 3.0, 0.9)
	_notas(g, u.global_position + Vector3(0, 2.0, 0), Vector3.FORWARD, 14, 180.0)
	Sfx.play("sino", u.global_position, 0.02, 0.6, 2.0)


static func nota_muda(o: Unit) -> void:
	Fx.damage_number(_g(o), o.global_position + Vector3(0, 1.4, 0), "♪̸", Color(0.6, 0.95, 0.9), 0.5)


static func _notas(g: Node, at: Vector3, dir: Vector3, n: int, spread := 30.0) -> void:
	if not Magia.enfeite():
		return
	FxProjetil.ps(g, at, FxProjetil.quad("brilho", FxProjetil.tex_brilho(), false), SOM, n, 0.9,
			{"dir": dir + Vector3.UP * 0.3, "spread": spread, "v0": 2.0, "v1": 4.0, "rampa": "pisca", "s0": 0.25, "s1": 0.45, "g": Vector3(0, 0.8, 0)})
