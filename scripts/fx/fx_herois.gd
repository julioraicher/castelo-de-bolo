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


# --- Heróis 2.27: peças comuns --------------------------------------------------------
# Ochimusha fogo-fantasma azul e cinzas; Shishimai festa (dourado, vermelho,
# confete); Jorogumo seda (branco perolado, lilás) com orvalho na cor do time.

const FANTASMA := Color(0.55, 0.78, 1.0)
const SEDA := Color(0.95, 0.94, 1.0)
const FESTA := Color(1.0, 0.78, 0.3)
const AZAR := Color(0.5, 0.32, 0.72)

static var _quads := {}


## Peça do atlas parada (não partícula) na cor `cor`: quad com cor de vértice e
## o material da peça (1 chamada). Para marcas e fogos que seguem o boneco.
static func peca_fixa(pai: Node3D, pos: Vector3, tipo: String, cor: Color, tam: float) -> MeshInstance3D:
	var chave := "%s|%s" % [tipo, cor.to_html()]
	if not _quads.has(chave):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cantos := [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]
		for i in [0, 1, 2, 0, 2, 3]:
			var c: Vector2 = cantos[i]
			st.set_color(cor)
			st.set_uv(Vector2(c.x + 0.5, 0.5 - c.y))
			st.add_vertex(Vector3(c.x, c.y, 0))
		var m := st.commit()
		m.surface_set_material(0, Assinatura._malha_peca(tipo, 0.0).material)
		_quads[chave] = m
	var mi := MeshInstance3D.new()
	mi.mesh = _quads[chave]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 1.0
	mi.position = pos
	mi.scale = Vector3.ONE * tam
	pai.add_child(mi)
	return mi


# --- Ochimusha -------------------------------------------------------------------

static func fantasma(u: Unit, t: float) -> void:
	var g := _g(u)
	var at := u.global_position
	Magia.bola(g, at + Vector3(0, 1.1, 0), "fantasma", 1.4, 0.45)
	Magia.onda(g, at, "fantasma", 2.8, 0.5, {"banda": 0.14})
	Assinatura.pecas(g, at + Vector3(0, 1.2, 0), "cinza", FANTASMA, 14, {"mov": "sobe"})
	Magia.aura_brasas(u, FANTASMA, t, 10, 0.6)
	Fx.damage_number(g, at + Vector3(0, 0.8, 0), "NÃO CAIU!", Color(0.72, 0.88, 1.0))


static func fantasma_volta(u: Unit) -> void:
	var g := _g(u)
	var at := u.global_position
	Magia.estouro(g, at + Vector3(0, 1.1, 0), "fantasma", 1.6, 0.35)
	Magia.anel_sobe(g, at, "fantasma", 1.2, 2.6, 0.7)
	Assinatura.pecas(g, at + Vector3(0, 1.0, 0), "cinza", FANTASMA, 10)
	Fx.damage_number(g, at + Vector3(0, 0.8, 0), "VOLTOU!", Color(0.8, 0.93, 1.0))


static func fantasma_cai(u: Unit) -> void:
	var g := _g(u)
	var at := u.global_position
	Assinatura.pecas(g, at + Vector3(0, 1.1, 0), "cinza", FANTASMA, 18, {"mov": "sobe", "esfera": 0.8})
	FxProjetil.fumaca(g, at + Vector3(0, 1.0, 0), Color(0.5, 0.6, 0.8, 0.7), 8, 1.2, 0.9, 1.4)


## Corte do Eco: o risco fica no chão, azul, até cortar de novo.
static func eco_marca(u: Unit, at: Vector3, dir: Vector3, alcance: float, atraso: float) -> void:
	var g := _g(u)
	var lado := dir.cross(Vector3.UP)
	var y := Vector3(0, 0.1, 0)
	Magia.lanca(g, at + y + dir * 0.5 - lado * alcance * 0.35, at + y + dir * alcance + lado * alcance * 0.3, "fantasma", 0.28, atraso + 0.15, {"cresce": 0.08, "corre": 2.0})
	FxProjetil.marca_chao(g, at + dir * alcance * 0.6, Color(0.1, 0.12, 0.22, 0.45), 0.7, atraso + 0.6)


static func eco_corte(u: Unit, at: Vector3, dir: Vector3, alcance: float, arco: float) -> void:
	var g := _g(u)
	Fx.slash(g, at + Vector3(0, 1.0, 0), dir, alcance + 0.4, minf(arco, 160.0), FANTASMA, 88.0, true)
	Assinatura.pecas(g, at + dir * alcance * 0.6 + Vector3(0, 1.0, 0), "cinza", FANTASMA, 8)
	Sfx.play("corte_critico", at, 0.08, 0.75)


static func flecha(u: Unit, alvo: Unit, dn: Vector3) -> void:
	var g := _g(u)
	var de := u.global_position + Vector3(0, 1.7, 0) - u._facing() * 0.35
	var ate := alvo.global_position + Vector3(0, 1.2, 0)
	Magia.lanca(g, de, ate, "fantasma", 0.22, 0.25, {"cresce": 0.06, "corre": 8.0})
	FxProjetil.faiscas(g, ate, Color(0.8, 0.9, 1.0), 6, 5.0, -dn + Vector3.UP * 0.5, 50.0, 0.2)
	Magia.estouro(g, ate, "fantasma", 0.7, 0.2)


static func onibi_nasce(u: Unit) -> void:
	var g := _g(u)
	Magia.estouro(g, u.global_position + Vector3(0, 1.3, 0), "fantasma", 1.4, 0.3)
	Sfx.play("ochimusha_onibi", u.global_position, 0.05)


## Fogos-fantasma girando (um nó: peças "chama" com brilho e brasas soltas).
static func onibi(u: Unit, n: int, raio: float) -> Node3D:
	var no := Node3D.new()
	no.name = "Onibi"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(no)
	no.position = Vector3(0, 1.25, 0)
	for i in n:
		var a := TAU * i / maxf(n, 1)
		var p := Vector3(cos(a), 0.15 * sin(a * 2.0), sin(a)) * raio
		FxProjetil.brilho_fixo(no, p, Color(0.35, 0.6, 1.0, 0.85), 0.9, false)
		peca_fixa(no, p + Vector3(0, 0.05, 0), "chama", Color(0.62, 0.84, 1.0), 0.55)
		if Magia.enfeite():
			FxProjetil.ps(no, p, FxProjetil.quad("brilho", FxProjetil.tex_brilho(), false), FANTASMA, 6, 0.45,
					{"one_shot": false, "local_pos": true, "esfera": 0.12, "dir": Vector3.UP, "spread": 25.0, "v0": 0.6, "v1": 1.4, "s0": 0.1, "s1": 0.2, "rampa": "nasce"})
	var tw := no.create_tween().set_loops()
	tw.tween_property(no, "rotation:y", TAU, 1.6).from(0.0)
	return no


static func onibi_estoura(g: Node, at: Vector3) -> void:
	Magia.bola(g, at, "fantasma", 1.1, 0.35)
	Magia.brasas(g, at, FANTASMA, 10, 0.6, 0.9)
	Assinatura.pecas(g, at, "cinza", FANTASMA, 6)
	Sfx.play("ochimusha_onibi", at, 0.1, 1.3, -3.0)


static func onibi_some(u: Unit) -> void:
	FxProjetil.fumaca(_g(u), u.global_position + Vector3(0, 1.3, 0), Color(0.5, 0.65, 0.9, 0.6), 5, 0.9, 0.6, 1.2)


## Carga dos Caídos: n samurais-fantasma em fila avançam pela faixa.
static func carga_caidos(u: Unit, de: Vector3, dir: Vector3, comp: float, larg: float, tempo: float, n: int) -> void:
	var g := _g(u)
	var lado := dir.cross(Vector3.UP).normalized()
	var y := Vector3(0, 0.12, 0)
	Magia.lanca(g, de + y, de + y + dir * comp, "fantasma", larg * 0.9, tempo + 0.25, {"cresce": 0.1, "corre": 3.0, "forca": 0.8})
	for i in n:
		var off := lerpf(-larg * 0.42, larg * 0.42, float(i) / maxf(n - 1, 1))
		var atraso := 0.05 * absf(float(i) - (n - 1) * 0.5)
		var p0 := de + lado * off + Vector3(0, 1.2, 0)
		var f := Assinatura.figura(g, p0, "caidos", "fantasma", Vector2(1.9, 2.5), tempo + 0.35, {"verbo": "nevoa", "escrita": 0.08, "alfa": 0.85})
		var tw := f.create_tween()
		tw.tween_interval(atraso)
		tw.tween_property(f, "global_position", p0 + dir * comp, tempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if Magia.enfeite():
			var r := FxProjetil.ps(f, Vector3(0, -0.6, 0), Assinatura._malha_peca("cinza", 0.0), FANTASMA, 10, 0.6,
					{"one_shot": false, "local_pos": true, "esfera": 0.4, "dir": Vector3.UP, "spread": 30.0, "v0": 0.5, "v1": 1.5, "s0": 0.6, "s1": 1.0})
			r.local_coords = false
	FxProjetil.marca_chao(g, de + dir * comp * 0.5, Color(0.08, 0.1, 0.2, 0.4), larg * 0.5, 2.0)
	Sfx.play("ochimusha_caidos", de, 0.03)


# --- Shishimai -------------------------------------------------------------------

static func mordida(u: Unit, alvo: Unit, aliado: bool) -> void:
	var g := _g(u)
	var at := alvo.global_position + Vector3(0, 1.1, 0)
	Magia.estouro(g, at, "cura" if aliado else "festa", 0.9, 0.25)
	Assinatura.pecas(g, at, "confete", FESTA if aliado else Color(1.0, 0.35, 0.3), 8, {"tam": 0.7})
	Sfx.play("shishimai_mordida", at, 0.08)


static func mordida_vazia(u: Unit, dir: Vector3) -> void:
	Fx.slash(_g(u), u.global_position + Vector3(0, 1.1, 0), dir, 2.2, 60.0, Color(1.0, 0.75, 0.35), 0.0, false)
	Sfx.play("shishimai_mordida", u.global_position, 0.08, 1.2, -6.0)


static func sorte_em(o: Unit) -> void:
	var g := _g(o)
	Magia.estouro(g, o.global_position + Vector3(0, 1.7, 0), "festa", 0.8, 0.25)
	Assinatura.pecas(g, o.global_position + Vector3(0, 1.8, 0), "confete", FESTA, 6, {"tam": 0.6})
	Fx.damage_number(g, o.global_position + Vector3(0, 0.9, 0), "SORTE", Color(1.0, 0.85, 0.35), 0.8)


static func azar_em(o: Unit) -> void:
	var g := _g(o)
	FxProjetil.fumaca(g, o.global_position + Vector3(0, 2.2, 0), Color(0.3, 0.2, 0.42, 0.75), 4, 0.8, 0.7, 0.4)
	Fx.damage_number(g, o.global_position + Vector3(0, 0.9, 0), "AZAR", Color(0.72, 0.5, 1.0), 0.8)


## Marca sobre a cabeça: estrela dourada (Sorte) ou nuvem roxa (Azar), balançando.
static func marca_sorte(u: Unit, tipo: String) -> Node3D:
	var no := Node3D.new()
	no.name = "MarcaSorte"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(no)
	no.position = Vector3(0, 2.75, 0)
	var sorte := tipo == "sorte"
	FxProjetil.brilho_fixo(no, Vector3.ZERO, Color(1.0, 0.8, 0.3, 0.6) if sorte else Color(0.3, 0.15, 0.45, 0.6), 0.8, false)
	peca_fixa(no, Vector3.ZERO, "estrela" if sorte else "nuvem", FESTA if sorte else AZAR, 0.42)
	var tw := no.create_tween().set_loops()
	tw.tween_property(no, "position:y", 2.9, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(no, "position:y", 2.75, 0.5).set_trans(Tween.TRANS_SINE)
	return no


static func errou(quem: Unit, alvo: Unit) -> void:
	var g := _g(quem)
	Fx.damage_number(g, alvo.global_position + Vector3(0, 0.7, 0), "ERROU!", Color(0.75, 0.55, 1.0), 0.9)
	FxProjetil.fumaca(g, quem.global_position + Vector3(0, 2.3, 0), Color(0.3, 0.2, 0.42, 0.8), 4, 0.7, 0.6, 0.3)


static func sorte_desvia(u: Unit) -> void:
	var g := _g(u)
	Fx.damage_number(g, u.global_position + Vector3(0, 0.7, 0), "SORTE!", Color(1.0, 0.85, 0.35), 0.9)
	Assinatura.pecas(g, u.global_position + Vector3(0, 1.3, 0), "confete", FESTA, 8, {"tam": 0.6})
	Sfx.play("shishimai_sino", u.global_position, 0.1)


static func sorte_dobra(quem: Unit, alvo: Unit) -> void:
	var g := _g(quem)
	Magia.estouro(g, alvo.global_position + Vector3(0, 1.2, 0), "festa", 1.1, 0.25)
	Fx.damage_number(g, alvo.global_position + Vector3(0, 1.0, 0), "SORTE ×2", Color(1.0, 0.85, 0.35), 1.0)


static func arrastao(u: Unit, t: float) -> void:
	var g := _g(u)
	Magia.fita(u, Vector3(-0.3, 1.6, 0.2), Vector3(0.3, 1.6, 0.2), "festa", t + 0.2, {"pontos": 10})
	FxProjetil.fumaca(g, u.global_position + Vector3(0, 0.3, 0), Color(0.7, 0.62, 0.5, 0.7), 6, 1.0, 0.6, 0.6)
	Sfx.play("shishimai_taiko", u.global_position, 0.05)


static func arrastao_pega(u: Unit, o: Unit) -> void:
	var g := _g(u)
	Magia.estouro(g, o.global_position + Vector3(0, 1.1, 0), "festa", 1.0, 0.25)
	Fx.damage_number(g, o.global_position + Vector3(0, 0.7, 0), "NA BOCA!", Color(1.0, 0.7, 0.35))
	Sfx.play("shishimai_mordida", o.global_position, 0.05, 0.9)


static func arrastao_fim(u: Unit) -> void:
	var g := _g(u)
	Magia.onda(g, u.global_position, "festa", 2.0, 0.35, {"banda": 0.2})
	FxProjetil.fumaca(g, u.global_position + Vector3(0, 0.3, 0), Color(0.7, 0.62, 0.5, 0.7), 8, 1.2, 0.7, 0.8)


static func festa(u: Unit, t: float) -> void:
	var g := _g(u)
	Magia.onda(g, u.global_position, "festa", 4.0, 0.6, {"banda": 0.1, "gira": 0.5})
	Assinatura.pecas(g, u.global_position + Vector3(0, 2.4, 0), "confete", FESTA, 30, {"spread": 70.0, "v0": 5.0, "v1": 9.0, "g": Vector3(0, -6, 0), "vida": 1.8})
	Magia.aura_brasas(u, FESTA, t, 12, 0.9)
	Sfx.play("shishimai_festa", u.global_position, 0.03)


static func festa_pulso(u: Unit, r: float) -> void:
	var g := _g(u)
	Magia.onda(g, u.global_position, "festa", r, 0.5, {"banda": 0.06})
	Assinatura.pecas(g, u.global_position + Vector3(0, 2.6, 0), "confete", FESTA, 10, {"tam": 0.7})
	Sfx.play("shishimai_sino", u.global_position, 0.1, 1.0, -4.0)


static func festa_levanta(u: Unit, c: Unit) -> void:
	var g := _g(u)
	Magia.anel_sobe(g, c.global_position, "festa", 1.0, 2.4, 0.7)
	Fx.damage_number(g, c.global_position + Vector3(0, 0.8, 0), "LEVANTA!", Color(1.0, 0.85, 0.4))


# --- Jorogumo --------------------------------------------------------------------

static var _mat_teia: StandardMaterial3D


## Teia no chão: raios, espiral com barriga entre os raios e gotas de orvalho na
## cor do time. Uma malha (cor de vértice), feita no nó `pai` (deitada em y = 0).
static func malha_teia(pai: Node3D, raio: float, cor_time: Color) -> MeshInstance3D:
	if _mat_teia == null:
		_mat_teia = StandardMaterial3D.new()
		_mat_teia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_teia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_teia.vertex_color_use_as_albedo = true
		_mat_teia.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_teia.render_priority = 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 9
	var angs: Array[float] = []
	for i in n:
		angs.append(TAU * i / n + randf_range(-0.12, 0.12))
	var fio := Color(0.96, 0.95, 1.0, 0.9)
	var sombra := Color(0.12, 0.06, 0.18, 0.55)
	# Filete escuro por baixo e o fio claro por cima: lê no chão claro e no escuro.
	for camada in 2:
		var cor := sombra if camada == 0 else fio
		var larg := 0.075 if camada == 0 else 0.04
		var y := 0.0 if camada == 0 else 0.01
		for a in angs:
			var ponta := Vector3(cos(a), 0, sin(a)) * raio * randf_range(0.92, 1.05)
			_traco(st, Vector3(0, y, 0), ponta + Vector3(0, y, 0), larg, cor)
		var voltas := 6
		for k in voltas:
			var r0 := raio * (0.2 + 0.78 * k / float(voltas - 1))
			for i in n:
				var a0 := angs[i]
				var a1 := angs[(i + 1) % n] + (TAU if i == n - 1 else 0.0)
				var p0 := Vector3(cos(a0), 0, sin(a0)) * r0
				var p1 := Vector3(cos(a1), 0, sin(a1)) * r0
				var meio := (p0 + p1) * 0.5 * 0.9  # o fio cede para o centro
				_traco(st, p0 + Vector3(0, y, 0), meio + Vector3(0, y, 0), larg * 0.8, cor)
				_traco(st, meio + Vector3(0, y, 0), p1 + Vector3(0, y, 0), larg * 0.8, cor)
	var orvalho := Color(cor_time.lightened(0.35), 1.0)
	for i in 10:
		var a := angs[randi() % n]
		var r := raio * randf_range(0.3, 0.95)
		var c := Vector3(cos(a) * r, 0.02, sin(a) * r)
		var s := randf_range(0.06, 0.1)
		for tri in [[Vector3(-s, 0, 0), Vector3(0, 0, -s), Vector3(s, 0, 0)], [Vector3(-s, 0, 0), Vector3(s, 0, 0), Vector3(0, 0, s)]]:
			for v in tri:
				st.set_color(orvalho)
				st.add_vertex(c + v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat_teia
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi


## Um fio reto deitado (quad de largura `larg`) entre a e b.
static func _traco(st: SurfaceTool, a: Vector3, b: Vector3, larg: float, cor: Color) -> void:
	var d := b - a
	d.y = 0
	if d.length() < 0.001:
		return
	var l := Vector3(-d.z, 0, d.x).normalized() * larg * 0.5
	for v in [a - l, a + l, b + l, a - l, b + l, b - l]:
		st.set_color(cor)
		st.add_vertex(v)


static func teia_lanca(u: Unit, at: Vector3) -> void:
	var g := _g(u)
	Magia.lanca(g, u.global_position + Vector3(0, 1.4, 0), at + Vector3(0, 0.2, 0), "seda", 0.14, 0.25, {"cresce": 0.05})
	Sfx.play("jorogumo_teia", u.global_position, 0.05)


static func teia_nasce(g: Node, at: Vector3, r: float) -> void:
	Magia.onda(g, at, "seda", r * 1.1, 0.35, {"banda": 0.15})
	Assinatura.pecas(g, at + Vector3(0, 0.4, 0), "fio", SEDA, 6, {"tam": 0.7})


static func teia_prende(o: Unit) -> void:
	var g := _g(o)
	_teia_pe(o, Config.cfg.teia_preso)
	Assinatura.pecas(g, o.global_position + Vector3(0, 0.8, 0), "fio", SEDA, 6, {"tam": 0.7})
	Sfx.play("seda_gruda", o.global_position, 0.1)


## Rede (3º fio): a teia pequena gruda nos pés.
static func rede(o: Unit) -> void:
	_teia_pe(o, Config.cfg.rede_preso)
	Fx.damage_number(_g(o), o.global_position + Vector3(0, 1.0, 0), "REDE!", Color(0.92, 0.9, 1.0), 0.8)


static func _teia_pe(o: Unit, t: float) -> void:
	var g := _g(o)
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(n)
	n.global_position = o.global_position + Vector3(0, 0.06, 0)
	malha_teia(n, 0.9, Color(0.9, 0.85, 1.0))
	n.scale = Vector3(0.2, 1, 0.2)
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(t - 0.3, 0.1))
	tw.tween_property(n, "scale", Vector3(1.2, 1, 1.2) * 0.01, 0.2)
	tw.tween_callback(n.queue_free)


static func teia_queima(g: Node, at: Vector3, r: float) -> void:
	Magia.chama(g, at, "brasa", r * 0.7, 1.4, 0.7, {"segura": 0.2})
	Magia.brasas(g, at, Color(1.0, 0.6, 0.2), 14, r * 0.7, 1.2)
	Assinatura.pecas(g, at + Vector3(0, 0.5, 0), "cinza", Color(0.35, 0.3, 0.32), 10, {"mov": "sobe"})
	FxProjetil.marca_chao(g, at, Color(0.08, 0.05, 0.04, 0.5), r * 0.8, 2.5)
	Sfx.play("brasa", at, 0.1)
	Fx.damage_number(g, at + Vector3(0, 1.0, 0), "QUEIMOU", Color(1.0, 0.6, 0.25), 0.7)


static func teia_rasga(g: Node, at: Vector3, r: float) -> void:
	Magia.onda(g, at, "vento", r * 1.2, 0.35, {"banda": 0.2, "gira": 0.8})
	Assinatura.pecas(g, at + Vector3(0, 0.5, 0), "fio", SEDA, 14, {"tang": 18.0, "anel": r * 0.5, "v0": 3.0, "v1": 6.0})
	Sfx.play("magia_vento", at, 0.1)
	Fx.damage_number(g, at + Vector3(0, 1.0, 0), "RASGOU", Color(1.0, 0.95, 0.8), 0.7)


static func puxar(u: Unit, alvos: Array[Unit], r: float) -> void:
	var g := _g(u)
	var mao := u.global_position + Vector3(0, 1.4, 0)
	Magia.onda(g, u.global_position, "seda", r * 0.45, 0.4, {"banda": 0.1, "gira": -0.6})
	for o in alvos:
		Magia.lanca(g, mao, o.global_position + Vector3(0, 1.1, 0), "seda", 0.12, 0.4, {"cresce": 0.05, "corre": -6.0})
		Assinatura.pecas(g, o.global_position + Vector3(0, 1.0, 0), "fio", SEDA, 4, {"tam": 0.6})
	Sfx.play("jorogumo_fios", u.global_position, 0.05)


static func casulo_lanca(u: Unit, alvos: Array) -> void:
	var g := _g(u)
	for o in alvos:
		Magia.lanca(g, u.global_position + Vector3(0, 1.4, 0), (o as Unit).global_position + Vector3(0, 1.0, 0), "seda", 0.2, 0.35, {"cresce": 0.08})
	Sfx.play("jorogumo_casulo", u.global_position, 0.03)


static var _malha_casulo: ArrayMesh
static var _mat_casulo: StandardMaterial3D


## Casulo em volta do corpo: fuso de seda com faixas enroladas em diagonal
## (cor de vértice: claro por cima, lilás embaixo) e fios na cor do time.
static func casulo(o: Unit, dona: Unit) -> Node3D:
	if _malha_casulo == null:
		_malha_casulo = _fazer_casulo()
		_mat_casulo = StandardMaterial3D.new()
		_mat_casulo.vertex_color_use_as_albedo = true
		_mat_casulo.roughness = 0.9
		_mat_casulo.rim_enabled = true
		_mat_casulo.rim = 0.6
		_mat_casulo.rim_tint = 0.3
	var no := Node3D.new()
	no.name = "Casulo"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	o.add_child(no)
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_casulo
	mi.material_override = _mat_casulo
	no.add_child(mi)
	var fios := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cor := Config.team_color(dona.team) if dona else Color.WHITE
	for k in 3:
		var a := TAU * k / 3.0
		var p0 := Vector3(cos(a) * 0.62, 0.35 + k * 0.5, sin(a) * 0.62)
		var p1 := Vector3(cos(a + 1.4) * 0.6, 0.85 + k * 0.45, sin(a + 1.4) * 0.6)
		var l := Vector3(0, 0.03, 0)
		for v in [p0 - l, p0 + l, p1 + l, p0 - l, p1 + l, p1 - l]:
			st.set_color(cor)
			st.add_vertex(v)
	fios.mesh = st.commit()
	fios.material_override = Fx.unshaded(Color.WHITE)
	(fios.material_override as BaseMaterial3D).vertex_color_use_as_albedo = true
	(fios.material_override as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	no.add_child(fios)
	no.scale = Vector3(1.0, 0.15, 1.0)
	var tw := no.create_tween()
	tw.tween_property(no, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bal := no.create_tween().set_loops()
	bal.tween_property(no, "rotation:z", 0.06, 0.18).set_trans(Tween.TRANS_SINE)
	bal.tween_property(no, "rotation:z", -0.06, 0.18).set_trans(Tween.TRANS_SINE)
	return no


static func _fazer_casulo() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aneis := 14
	var lados := 12
	var altura := 2.1
	var pts := []
	for i in aneis + 1:
		var t := float(i) / aneis
		var r := sin(t * PI) * 0.62 + 0.04
		var linha := []
		for j in lados + 1:
			var a := TAU * j / lados
			# Faixas de seda: o raio sobe e desce numa espiral (enrolado em diagonal).
			var faixa := 0.5 + 0.5 * sin(a * 2.0 + t * 26.0)
			var rr := r * (1.0 + 0.07 * faixa)
			linha.append([Vector3(cos(a) * rr, t * altura, sin(a) * rr), faixa, t])
		pts.append(linha)
	for i in aneis:
		for j in lados:
			var q := [pts[i][j], pts[i][j + 1], pts[i + 1][j + 1], pts[i + 1][j]]
			for idx in [0, 2, 1, 0, 3, 2]:
				var v: Array = q[idx]
				var p: Vector3 = v[0]
				var faixa: float = v[1]
				var t: float = v[2]
				var claro := Color(0.97, 0.95, 1.0).lerp(Color(0.66, 0.6, 0.78), (1.0 - t) * 0.6)
				st.set_color(claro.lerp(Color(0.8, 0.76, 0.9), (1.0 - faixa) * 0.5))
				st.set_normal(Vector3(p.x, 0.0, p.z).normalized())
				st.add_vertex(p)
	return st.commit()


static func casulo_bate(o: Unit) -> void:
	Assinatura.pecas(_g(o), o.global_position + Vector3(0, 1.1, 0), "fio", SEDA, 5, {"tam": 0.6})
	Sfx.play("seda_gruda", o.global_position, 0.1, 1.3)
	if o._casulo_vida > 0:
		Fx.damage_number(_g(o), o.global_position + Vector3(0, 1.0, 0), "%d" % o._casulo_vida, SEDA, 0.6)


static func casulo_quebra(o: Unit) -> void:
	var g := _g(o)
	Magia.estouro(g, o.global_position + Vector3(0, 1.0, 0), "seda", 1.3, 0.3)
	Assinatura.pecas(g, o.global_position + Vector3(0, 1.0, 0), "fio", SEDA, 14)
	Sfx.play("seda", o.global_position, 0.1, 0.8)
