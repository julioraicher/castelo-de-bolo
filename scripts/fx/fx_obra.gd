class_name FxObra
extends RefCounted
## Efeitos do Predero (Herói 2.30): garrafa de cachaça, estilhaço de vidro,
## poça âmbar que brilha (e pega fogo), andaime de madeira com lona do time e a
## chuva de garrafas da Saideira. Só visual (randf pode); as regras moram em
## HeroisObra, PocaCachaca e Andaime. Malhas de madeira no material pintado do
## tema (FxNatureza._mat_cena), como a árvore do Kodama.

const VIDRO := Color(0.36, 0.72, 0.42)
const VIDRO_ESCURO := Color(0.18, 0.42, 0.24)
const CACHACA := Color(1.0, 0.76, 0.28)
const CACHACA_ESCURA := Color(0.62, 0.36, 0.08)
const ROLHA := Color(0.62, 0.42, 0.24)
const MADEIRA := Color(0.66, 0.48, 0.28)
const MADEIRA_ESCURA := Color(0.44, 0.3, 0.17)
const FALA := Color(1.0, 0.86, 0.32)
## s do lançamento do engradado até a 1ª garrafa da Saideira chegar ao chão.
const SAIDEIRA_VOO := 0.55
const QUEDA := 0.28  # s de queda de cada garrafa da Saideira

static var _malhas := {}
static var _mat_vidro: StandardMaterial3D
static var _mat_poca: StandardMaterial3D


static func _g(u: Unit) -> Node:
	return u.game


static func _shake(g: Node, pos: Vector3, forca: float) -> void:
	var game := g as Game
	if game and game.camera:
		game.camera.shake_at(pos, forca)


# --- Falas ----------------------------------------------------------------------------

static func fala(u: Unit, txt: String) -> void:
	Fx.damage_number(_g(u), u.global_position + Vector3(0, 0.6, 0), txt, FALA, 1.3)


# --- Garrafa ----------------------------------------------------------------------------

static func mat_vidro() -> StandardMaterial3D:
	if _mat_vidro == null:
		_mat_vidro = StandardMaterial3D.new()
		_mat_vidro.vertex_color_use_as_albedo = true
		_mat_vidro.vertex_color_is_srgb = true
		_mat_vidro.roughness = 0.12
		_mat_vidro.metallic_specular = 0.9
		_mat_vidro.rim_enabled = true
		_mat_vidro.rim = 0.6
		_mat_vidro.rim_tint = 0.2
	return _mat_vidro


## Garrafa de cachaça (≈0,5 m em pé, eixo +Y): corpo de vidro verde com o
## líquido âmbar aparecendo, rótulo na cor do time, gargalo e rolha.
## garrafao = o do Q: mais bojudo, com a palha trançada em volta.
static func malha_garrafa(cor_time: Color, garrafao := false) -> ArrayMesh:
	var chave := "garrafa_%s_%s" % [cor_time.to_html(), garrafao]
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.13 if not garrafao else 0.2
	# Fundo e corpo (o líquido aparece mais claro embaixo).
	FxNatureza._tubo(st, [Vector3(0, 0.0, 0), Vector3(0, 0.02, 0)], r * 0.6, r, VIDRO_ESCURO, VIDRO, 10)
	FxNatureza._tubo(st, [Vector3(0, 0.02, 0), Vector3(0, 0.16, 0)], r, r, CACHACA.lerp(VIDRO, 0.35), CACHACA.lerp(VIDRO, 0.45), 10)
	if garrafao:
		# Palha trançada: três anéis grossos de palha na barriga.
		for y in [0.06, 0.14, 0.22]:
			FxNatureza._tubo(st, [Vector3(0, y - 0.02, 0), Vector3(0, y + 0.02, 0)], r + 0.025, r + 0.025, Color(0.82, 0.66, 0.36), Color(0.7, 0.54, 0.28), 10)
		FxNatureza._tubo(st, [Vector3(0, 0.16, 0), Vector3(0, 0.3, 0)], r, r * 0.95, VIDRO, VIDRO, 10)
	else:
		# Rótulo na cor do time.
		FxNatureza._tubo(st, [Vector3(0, 0.16, 0), Vector3(0, 0.27, 0)], r + 0.006, r + 0.006, cor_time.lightened(0.15), cor_time, 10)
		FxNatureza._tubo(st, [Vector3(0, 0.27, 0), Vector3(0, 0.3, 0)], r, r, VIDRO, VIDRO, 10)
	var topo := 0.3
	FxNatureza._tubo(st, [Vector3(0, topo, 0), Vector3(0, topo + 0.08, 0), Vector3(0, topo + 0.12, 0)], r * 0.95, r * 0.32, VIDRO, VIDRO_ESCURO, 10)
	FxNatureza._tubo(st, [Vector3(0, topo + 0.12, 0), Vector3(0, topo + 0.24, 0)], r * 0.3, r * 0.28, VIDRO, VIDRO, 8)
	FxNatureza._tubo(st, [Vector3(0, topo + 0.24, 0), Vector3(0, topo + 0.3, 0)], r * 0.3, r * 0.26, ROLHA, ROLHA.darkened(0.2), 8)
	if garrafao:
		# Alça de palha.
		FxNatureza._tubo(st, [Vector3(r * 0.4, topo + 0.08, 0), Vector3(r * 1.1, topo + 0.04, 0), Vector3(r * 1.25, topo - 0.08, 0), Vector3(r + 0.02, topo - 0.14, 0)], 0.022, 0.022, Color(0.82, 0.66, 0.36), Color(0.7, 0.54, 0.28), 5)
	st.index()
	var m := st.commit()
	m.surface_set_material(0, mat_vidro())
	_malhas[chave] = m
	return m


## Projétil "garrafa" (FxProjetil.montar): a garrafa deitada no sentido do voo,
## girando de ponta-cabeça, pingando cachaça. Devolve o nó que gira.
static func montar_garrafa(p: Node3D, time_cor: Color, rastro: bool) -> Node3D:
	var gira := Node3D.new()
	p.add_child(gira)
	var mi := MeshInstance3D.new()
	mi.mesh = malha_garrafa(time_cor)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, -0.28, 0)
	var eixo := Node3D.new()
	eixo.rotation_degrees.x = 90  # deitada ao longo do voo
	gira.add_child(eixo)
	eixo.add_child(mi)
	FxProjetil.brilho_fixo(p, Vector3(0, 0.05, 0), Color(CACHACA, 0.45), 0.45, false)
	if rastro:  # gotas de cachaça soltas pelo caminho
		var r := FxProjetil.ps(p, Vector3.ZERO, FxProjetil._gota(), CACHACA, 5, 0.45, {"one_shot": false, "esfera": 0.1,
				"dir": Vector3.DOWN, "spread": 30.0, "v0": 0.3, "v1": 1.0, "g": Vector3(0, -9, 0), "s0": 0.7, "s1": 1.0, "local_pos": true})
		r.local_coords = false
	return gira


## Impacto no corpo (FxProjetil.impacto "garrafa"): cacos e respingo.
static func impacto(g: Node, at: Vector3, dir: Vector3, k: float) -> void:
	Assinatura.pecas(g, at, "caco", VIDRO.lightened(0.3), int(5 * k), {"tam": 0.6})
	FxProjetil.ps(g, at, FxProjetil._gota(), CACHACA, int(6 * k), 0.5, {"dir": -dir + Vector3.UP, "spread": 60.0,
			"v0": 2.0, "v1": 4.5, "g": Vector3(0, -12, 0), "s0": 0.8, "s1": 1.2})
	FxProjetil.brilho(g, at, Color(1.0, 0.95, 0.8, 0.8), 0.8 * k, 0.1)


## Garrafa estourou no chão (ataque, garrafão do 3º tiro, Saideira).
## forte = garrafão/última da Saideira; na_poca = correu pela poça inteira.
static func estilhaco(g: Node, at: Vector3, r: float, forte := false, na_poca := false) -> void:
	var chao := at + Vector3(0, 0.15, 0)
	Magia.onda(g, chao, "cachaca", r * (1.1 if na_poca else 0.9), 0.38, {"banda": 0.16 if na_poca else 0.2})
	Magia.estouro(g, at + Vector3(0, 0.3, 0), [Color(1.0, 1.0, 0.95), Color(0.75, 1.0, 0.8), VIDRO_ESCURO], r * 0.55, 0.22, {"forca": 0.8})
	Assinatura.pecas(g, at + Vector3(0, 0.5, 0), "caco", VIDRO.lightened(0.35), 9 if forte else 6, {"tam": 0.8 if forte else 0.65})
	FxProjetil.ps(g, at + Vector3(0, 0.3, 0), FxProjetil._gota(), CACHACA, 10 if forte else 7, 0.6, {"dir": Vector3.UP, "spread": 70.0,
			"v0": 3.0, "v1": 6.0, "g": Vector3(0, -14, 0), "s0": 0.8, "s1": 1.4})
	FxProjetil.marca_chao(g, at, Color(CACHACA_ESCURA, 0.45), r * 0.7, 2.5)
	if na_poca:
		FxProjetil.faiscas(g, chao, Color(0.9, 1.0, 0.92), 10, 7.0, Vector3.UP, 85.0, 0.16)
		Fx.damage_number(g, at, "ESPALHOU!", FALA, 0.8)
	Sfx.play("garrafa_quebra", at, 0.12, 0.85 if forte else 1.0, 0.0 if forte else -2.0)
	_shake(g, at, 0.3 if forte else 0.18)


## Levou garrafada: "HIC!" e a cachaça escorrendo enquanto dura.
static func encachacado(u: Unit) -> void:
	var g := _g(u)
	Fx.damage_number(g, u.global_position + Vector3(0, 0.9, 0), "HIC!", CACHACA, 0.7)
	if not Magia.enfeite():
		return
	var p := FxProjetil.ps(u, Vector3(0, 1.5, 0), FxProjetil._gota(), CACHACA, 5, 0.5, {"one_shot": false, "local_pos": true,
			"esfera": 0.35, "dir": Vector3.DOWN, "spread": 10.0, "v0": 0.3, "v1": 0.9, "g": Vector3(0, -9, 0), "s0": 0.6, "s1": 0.9})
	p.local_coords = false
	var tw := p.create_tween().set_loops()
	tw.tween_interval(0.25)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(u) or not u.alive or u._encachacado_t <= 0.0:
			p.emitting = false
			tw.kill()
			var fim := p.create_tween()
			fim.tween_interval(0.6)
			fim.tween_callback(p.queue_free))


## Fogo em quem está encachaçado: labareda curta e "ARDEU!".
static func arde(u: Unit) -> void:
	if Sorte.ms() - int(u.get_meta("ardeu_ms", -5000)) < 900:
		return
	u.set_meta("ardeu_ms", Sorte.ms())
	var g := _g(u)
	Magia.chama(g, u.global_position + Vector3(0, 0.2, 0), "brasa", 0.7, 1.8, 0.45, {"segura": 0.4})
	Fx.damage_number(g, u.global_position + Vector3(0, 1.0, 0), "ARDEU!", Color(1.0, 0.55, 0.2), 0.8)


static func escorregou(o: Unit, _dono: Unit) -> void:
	var g := _g(o)
	Fx.damage_number(g, o.global_position + Vector3(0, 0.6, 0), "ESCORREGOU!", CACHACA, 0.8)
	FxProjetil.ps(g, o.global_position + Vector3(0, 0.1, 0), FxProjetil._gota(), CACHACA, 6, 0.45, {"dir": Vector3.UP, "spread": 60.0,
			"v0": 1.5, "v1": 3.0, "g": Vector3(0, -12, 0), "s0": 0.7, "s1": 1.0})
	Sfx.play("poca_splash", o.global_position, 0.15, 1.3, -6.0)


# --- Poça ----------------------------------------------------------------------------------

static func mat_poca() -> StandardMaterial3D:
	if _mat_poca == null:
		_mat_poca = StandardMaterial3D.new()
		_mat_poca.vertex_color_use_as_albedo = true
		_mat_poca.vertex_color_is_srgb = true
		_mat_poca.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Sem luz: o reflexo especular do céu lavava o âmbar para cinza. A poça
		# brilha pela própria cor (miolo claro, borda escura) como a tinta do tema.
		_mat_poca.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_poca.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_poca.render_priority = -1
	return _mat_poca


## Mancha de cachaça de raio 1 (escala no nó): contorno irregular de poça,
## miolo claro e brilhante, borda escura, um filete na cor do time por fora.
static func _malha_poca(cor_time: Color) -> ArrayMesh:
	var chave := "poca_" + cor_time.to_html()
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	var borda := []
	for i in n + 1:
		var a := TAU * i / n
		var rr := 1.0 + 0.1 * sin(a * 3.0 + 0.7) + 0.06 * sin(a * 7.0 + 1.9) + 0.04 * sin(a * 11.0)
		borda.append(Vector3(cos(a) * rr, 0, sin(a) * rr))
	var miolo := Color(1.0, 0.86, 0.45, 0.78)
	var meio := Color(CACHACA, 0.72)
	var fora := Color(CACHACA_ESCURA, 0.6)
	var filete := Color(cor_time.lightened(0.2), 0.85)
	for i in n:
		var b0: Vector3 = borda[i]
		var b1: Vector3 = borda[i + 1]
		# miolo → 70% (claro), 70% → borda (escuro), borda → filete do time
		var anel := [[Vector3.ZERO, Vector3.ZERO, miolo, miolo], [b0 * 0.7, b1 * 0.7, meio, meio], [b0, b1, fora, fora], [b0 * 1.06, b1 * 1.06, filete, filete]]
		for k in 3:
			var p0: Vector3 = anel[k][0]
			var p1: Vector3 = anel[k][1]
			var q0: Vector3 = anel[k + 1][0]
			var q1: Vector3 = anel[k + 1][1]
			var c0: Color = anel[k][2]
			var c1: Color = anel[k + 1][2]
			for v in [[p0, c0], [q1, c1], [q0, c1], [p0, c0], [p1, c0], [q1, c1]]:
				st.set_color(v[1])
				st.set_normal(Vector3.UP)
				st.add_vertex(v[0])
	var m := st.commit()
	m.surface_set_material(0, mat_poca())
	_malhas[chave] = m
	return m


## Visual da poça dentro de `pai` (o nó encolhe quando seca).
static func poca(pai: Node3D, raio: float, cor_time: Color) -> Node3D:
	var no := Node3D.new()
	no.name = "Poca"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(no)
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_poca(cor_time)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.05
	mi.scale = Vector3(raio, 1.0, raio)
	mi.rotation.y = randf() * TAU
	no.add_child(mi)
	if Magia.enfeite():  # bolhinhas subindo e estourando
		FxProjetil.ps(no, Vector3(0, 0.08, 0), FxProjetil._gota(), Color(1.0, 0.95, 0.75, 0.8), maxi(int(raio * 2.0), 2), 0.9, {"one_shot": false,
				"local_pos": true, "esfera": raio * 0.6, "flat": 0.9, "dir": Vector3.UP, "spread": 10.0, "v0": 0.1, "v1": 0.3,
				"s0": 0.5, "s1": 0.9, "curva": "estoura"})
	return no


static func poca_espalha(g: Node, pos: Vector3, raio: float, pequena: bool) -> void:
	Magia.onda(g, pos + Vector3(0, 0.1, 0), "cachaca", raio * 1.1, 0.35, {"banda": 0.18})
	FxProjetil.ps(g, pos + Vector3(0, 0.2, 0), FxProjetil._gota(), CACHACA, 6 if pequena else 12, 0.55, {"dir": Vector3.UP, "spread": 75.0,
			"v0": 2.5, "v1": 5.0, "g": Vector3(0, -14, 0), "s0": 0.8, "s1": 1.3})
	if not pequena:
		Assinatura.pecas(g, pos + Vector3(0, 0.5, 0), "caco", VIDRO.lightened(0.35), 7, {"tam": 0.75})
		Sfx.play("garrafa_quebra", pos, 0.1, 0.8, -1.0)
	Sfx.play("poca_splash", pos, 0.1, 1.0 if not pequena else 1.2, 0.0 if not pequena else -5.0)


## Fogo na poça: labaredas espalhadas pela mancha e brasas. Devolve o nó.
static func poca_acesa(pai: Node3D, raio: float, t: float) -> Node3D:
	var g := pai.get_parent()
	var no := Node3D.new()
	no.name = "Fogo"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(no)
	var c := pai.global_position
	var n := clampi(int(raio * 2.0), 2, 6)
	Magia.chama(no, c, "brasa", raio * 0.75, 1.8, t + 0.2, {"segura": 0.8, "giro": 0.8, "r_topo": 0.5})
	for i in n:
		var a := TAU * i / n + randf() * 0.5
		var p := c + Vector3(cos(a), 0, sin(a)) * raio * randf_range(0.45, 0.8)
		Magia.chama(no, p, "brasa", 0.6, randf_range(1.0, 1.6), t + 0.2, {"segura": 0.8, "giro": 1.4})
	Magia.aura_brasas(no, Color(1.0, 0.62, 0.22), t, 12, raio * 0.7)
	Magia.onda(g, c + Vector3(0, 0.1, 0), "brasa", raio * 1.25, 0.4)
	Magia.clarao(g, c, Color(1.0, 0.6, 0.25), raio * 4.0, t, 2.0)
	Fx.damage_number(g, c + Vector3(0, 0.6, 0), "PEGOU FOGO!", Color(1.0, 0.6, 0.25), 1.0)
	Sfx.play("poca_fogo", c, 0.1)
	return no


static func poca_seca(pai: Node3D, raio: float, queimada: bool) -> void:
	var g := pai.get_parent()
	var c := pai.global_position
	if queimada:
		FxProjetil.fumaca(g, c + Vector3(0, 0.4, 0), Color(0.22, 0.19, 0.18, 0.6), 5, raio * 0.7, 1.2, 1.6)
		FxProjetil.marca_chao(g, c, Color(0.06, 0.04, 0.03, 0.55), raio * 0.8, 3.0)
	else:
		FxProjetil.fumaca(g, c + Vector3(0, 0.2, 0), Color(1.0, 0.95, 0.85, 0.35), 3, raio * 0.6, 0.9, 0.8)


## O garrafão do Q voando da mão até onde vira poça (`voo` s, em arco).
static func garrafao(u: Unit, at: Vector3, voo: float) -> void:
	var g := _g(u)
	var no := Node3D.new()
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(no)
	var de := u.global_position + Vector3(0, 1.6, 0)
	no.global_position = de
	var mi := MeshInstance3D.new()
	mi.mesh = malha_garrafa(Config.team_color(u.team), true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, -0.3, 0)
	no.add_child(mi)
	var altura := 1.5 + voo * 4.0
	var tw := no.create_tween()
	tw.tween_method(func(k: float) -> void:
		var p := de.lerp(at, k)
		p.y = lerpf(de.y, at.y, k) + 4.0 * altura * k * (1.0 - k)
		no.global_position = p
		no.rotation = Vector3(k * TAU * 1.2, 0, k * 2.0), 0.0, 1.0, voo)
	tw.tween_callback(no.queue_free)
	Sfx.play("garrafa_lancar", de, 0.1, 0.8)


# --- Andaime ---------------------------------------------------------------------------------

## Vértice no formato do pintura.gdshader: COLOR.a = oclusão, UV.x = vento,
## UV.y = desenho (1 = tábuas).
static func _v(st: SurfaceTool, p: Vector3, nrm: Vector3, cor: Color, ao: float, vento: float, desenho: float) -> void:
	st.set_color(Color(cor.r, cor.g, cor.b, ao))
	st.set_uv(Vector2(vento, desenho))
	st.set_normal(nrm)
	st.add_vertex(p)


## Caixa orientada (centro, meias-medidas, base) com as seis faces de fora.
static func _caixa(st: SurfaceTool, c: Vector3, meia: Vector3, b: Basis, cor: Color, desenho := 1.0, ao := Vector2(0.7, 1.0), vento := 0.0) -> void:
	var eixos := [b.x * meia.x, b.y * meia.y, b.z * meia.z]
	for f in 3:
		for s in [-1.0, 1.0]:
			var nrm: Vector3 = (eixos[f] as Vector3).normalized() * s
			var u: Vector3 = eixos[(f + 1) % 3]
			var w: Vector3 = eixos[(f + 2) % 3]
			var centro: Vector3 = c + eixos[f] * s
			var q := [centro - u - w, centro + u - w, centro + u + w, centro - u + w]
			# frente no sentido horário visto de fora (o pintado descarta o verso)
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(nrm) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for i in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = q[i]
				var alto := clampf((p.y - c.y + meia.y) / maxf(meia.y * 2.0, 0.01), 0.0, 1.0) if absf(b.y.y) > 0.5 else 0.5
				_v(st, p, nrm, cor, lerpf(ao.x, ao.y, alto), vento * (1.0 - alto), desenho)


## Andaime de raio: largura `larg`, altura `alt`, frente = +z do nó. Postes,
## travessas, cruzes de travamento, a plataforma com balde e garrafa em cima e
## a lona na cor do time (a barra de baixo balança no vento).
static func _malha_andaime(larg: float, alt: float, cor_time: Color) -> ArrayMesh:
	var chave := "andaime_%.2f_%.2f_%s" % [larg, alt, cor_time.to_html()]
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var I := Basis.IDENTITY
	var m := larg * 0.5
	var lona := cor_time.darkened(0.15)
	# Postes (um torto, é obra) e os pés de tábua.
	for i in 3:
		var x := lerpf(-m + 0.12, m - 0.12, i / 2.0)
		var torto := Basis(Vector3.FORWARD, 0.04 if i == 2 else 0.0)
		_caixa(st, Vector3(x, alt * 0.5, 0.0), Vector3(0.07, alt * 0.5 + 0.1, 0.07), torto, MADEIRA_ESCURA, 1.0, Vector2(0.55, 1.0))
		_caixa(st, Vector3(x, 0.04, 0.0), Vector3(0.18, 0.04, 0.22), I, MADEIRA_ESCURA.darkened(0.15), 1.0, Vector2(0.5, 0.7))
	# Travessas na frente e atrás, em dois andares.
	for y in [alt * 0.45, alt - 0.05]:
		for z in [-0.12, 0.12]:
			_caixa(st, Vector3(0, y, z), Vector3(m, 0.05, 0.03), I, MADEIRA, 1.0, Vector2(0.8, 1.0))
	# Cruzes de travamento atrás (X em cada vão).
	for k in 2:
		var cx := lerpf(-m + 0.12, 0.0, 0.5) if k == 0 else lerpf(0.0, m - 0.12, 0.5)
		var vao := (m - 0.12)
		var diag := sqrt(vao * vao + alt * 0.45 * alt * 0.45) * 0.5
		var ang := atan2(alt * 0.45, vao)
		for s in [-1.0, 1.0]:
			_caixa(st, Vector3(cx, alt * 0.225, -0.16), Vector3(diag, 0.035, 0.02), Basis(Vector3.BACK, ang * s), MADEIRA.darkened(0.1), 1.0, Vector2(0.6, 0.9))
	# Plataforma de tábuas no topo, um pouco funda, e o guarda-corpo.
	for k in 3:
		_caixa(st, Vector3(0, alt + 0.02, -0.2 + k * 0.2), Vector3(m + 0.15, 0.03, 0.09), Basis(Vector3.RIGHT, 0.02 * (k - 1)), MADEIRA.lightened(0.05 * k), 1.0, Vector2(0.85, 1.0))
	# Balde de massa e a garrafa (claro) esquecidos lá em cima.
	FxNatureza._tubo(st, [Vector3(-m * 0.55, alt + 0.05, -0.05), Vector3(-m * 0.55, alt + 0.33, -0.05)], 0.15, 0.19, Color(0.55, 0.57, 0.6), Color(0.68, 0.7, 0.72), 8)
	FxNatureza._bola(st, Vector3(-m * 0.55, alt + 0.33, -0.05), 0.16, Vector3(1.0, 0.25, 1.0), Color(0.78, 0.76, 0.7))
	FxNatureza._tubo(st, [Vector3(m * 0.6, alt + 0.05, -0.1), Vector3(m * 0.6, alt + 0.33, -0.1), Vector3(m * 0.6, alt + 0.5, -0.1)], 0.1, 0.03, VIDRO, VIDRO_ESCURO, 7)
	# Lona do time na frente (fina, com volume para ler dos dois lados), com
	# a barra de baixo solta no vento.
	_caixa(st, Vector3(0, alt * 0.6, 0.16), Vector3(m - 0.08, alt * 0.33, 0.015), I, lona, 0.0, Vector2(0.75, 1.0), 0.5)
	# Faixa listrada (amarela e preta) de obra em cima da lona.
	for k in 8:
		var x := lerpf(-m + 0.3, m - 0.3, k / 7.0)
		_caixa(st, Vector3(x, alt * 0.93, 0.19), Vector3(m / 8.0 - 0.02, 0.06, 0.01), Basis(Vector3.BACK, 0.4), Color(1.0, 0.82, 0.18) if k % 2 == 0 else Color(0.1, 0.09, 0.08), 0.0, Vector2(0.9, 1.0))
	st.index()
	var mm := st.commit()
	_malhas[chave] = mm
	return mm


## Visual do andaime dentro de `pai` (nó que sobe e tomba). A placa da obra
## fica escrita na frente e no verso.
static func andaime(pai: Node3D, larg: float, alt: float, cor_time: Color) -> Node3D:
	var no := Node3D.new()
	no.name = "Andaime"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(no)
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_andaime(larg, alt, cor_time)
	mi.material_override = FxNatureza._mat_cena(pai.get_parent())
	no.add_child(mi)
	for k in 2:
		var l := Label3D.new()
		l.text = "OBRA DO PREDERO" if k == 0 else "CUIDADO: OBRA"
		l.font = Estilo.LETREIRO
		l.font_size = 48
		l.pixel_size = 0.006
		l.outline_size = 10
		l.modulate = Color(1.0, 0.95, 0.85)
		l.outline_modulate = Estilo.TINTA
		l.position = Vector3(0, alt * 0.62, 0.2 if k == 0 else -0.2)
		l.rotation.y = 0.0 if k == 0 else PI
		l.rotation.z = 0.05 if k == 0 else -0.04  # placa pintada à mão, torta
		no.add_child(l)
	return no


static func andaime_sobe(g: Node, pos: Vector3, larg: float, lado: Vector3) -> void:
	FxProjetil.fumaca(g, pos + Vector3(0, 0.3, 0), Color(0.62, 0.55, 0.45, 0.7), 6, larg * 0.35, 0.8, 1.0)
	for k in 3:
		var p := pos + lado * lerpf(-larg * 0.4, larg * 0.4, k / 2.0)
		Assinatura.pecas(g, p + Vector3(0, 1.0, 0), "lasca", MADEIRA.lightened(0.2), 3, {"tam": 0.7})
	Magia.onda(g, pos + Vector3(0, 0.1, 0), "vento", larg * 0.7, 0.35, {"banda": 0.14})
	Sfx.play("andaime_sobe", pos, 0.05)
	_shake(g, pos, 0.2)


static func andaime_golpe(a: Node3D, by: Unit) -> void:
	var g := a.get_parent()
	var at := a.global_position + Vector3(0, 1.0, 0)
	var dir := (at - by.global_position).normalized() if by else Vector3.UP
	FxProjetil.faiscas(g, at, MADEIRA.lightened(0.2), 8, 5.0, -dir + Vector3.UP * 0.6, 60.0, 0.22)
	Sfx.play("madeira_golpe", at, 0.15)
	for c in a.get_children():
		if c.name == "Andaime":
			var v := c as Node3D
			var tw := v.create_tween()
			tw.tween_property(v, "rotation:z", 0.06, 0.06)
			tw.tween_property(v, "rotation:z", -0.04, 0.08)
			tw.tween_property(v, "rotation:z", 0.0, 0.1)


static func andaime_cai(g: Node, pos: Vector3, larg: float, lado: Vector3) -> void:
	FxProjetil.fumaca(g, pos + Vector3(0, 0.4, 0), Color(0.62, 0.55, 0.45, 0.7), 7, larg * 0.4, 0.9, 0.8)
	for k in 3:
		var p := pos + lado * lerpf(-larg * 0.4, larg * 0.4, k / 2.0)
		Assinatura.pecas(g, p + Vector3(0, 1.2, 0), "lasca", MADEIRA, 4, {"tam": 0.8})
	Sfx.play("andaime_cai", pos, 0.1)


# --- Saideira -------------------------------------------------------------------------------

## O engradado sobe girando até acima do centro, abre e as garrafas caem uma a
## uma em `pts` (a i-ésima chega em SAIDEIRA_VOO + i·cada s; a última acesa).
static func saideira(u: Unit, centro: Vector3, pts: Array, cada: float) -> void:
	var g := _g(u)
	var cor := Config.team_color(u.team)
	fala(u, "SAIDEIRA!")
	var topo := centro + Vector3(0, 6.5, 0)
	var de := u.global_position + Vector3(0, 1.8, 0)
	var caixa := Node3D.new()
	caixa.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(caixa)
	caixa.global_position = de
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_engradado(cor)
	mi.material_override = FxNatureza._mat_cena(g)
	caixa.add_child(mi)
	var subida := SAIDEIRA_VOO - QUEDA
	var tw := caixa.create_tween()
	tw.tween_method(func(k: float) -> void:
		var p := de.lerp(topo, k)
		p.y += 3.0 * k * (1.0 - k)
		caixa.global_position = p
		caixa.rotation = Vector3(k * 4.0, k * 6.0, 0), 0.0, 1.0, subida)
	tw.tween_callback(func() -> void:
		Magia.estouro(g, topo, "cachaca", 1.4, 0.3)
		Assinatura.pecas(g, topo, "lasca", MADEIRA.lightened(0.15), 8, {"tam": 0.8})
		caixa.queue_free())
	Magia.selo(g, centro, "cachaca", Config.cfg.saideira_raio, SAIDEIRA_VOO + cada * pts.size() + 0.3)
	Sfx.play("garrafa_lancar", de, 0.05, 0.7)
	for i in pts.size():
		var chega := SAIDEIRA_VOO + cada * i
		var at: Vector3 = pts[i]
		var ultima := i == pts.size() - 1
		var t0 := g.create_tween()
		t0.tween_interval(maxf(chega - QUEDA, 0.0))
		t0.tween_callback(_garrafa_caindo.bind(g, topo.lerp(at + Vector3(0, 6.5, 0), 0.6), at, cor, ultima))


static func _garrafa_caindo(g: Node, de: Vector3, at: Vector3, cor: Color, acesa: bool) -> void:
	if not is_instance_valid(g) or not g.is_inside_tree():
		return
	var no := Node3D.new()
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(no)
	no.global_position = de
	var mi := MeshInstance3D.new()
	mi.mesh = malha_garrafa(cor)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, -0.3, 0)
	no.add_child(mi)
	if acesa:  # palito de fósforo aceso na boca da garrafa
		Magia.chama(no, de + Vector3(0, 0.35, 0), "brasa", 0.35, 0.7, QUEDA + 0.1, {"segura": 0.9})
		FxProjetil.brilho_fixo(no, Vector3(0, 0.4, 0), Color(1.0, 0.6, 0.2), 0.9)
	var tw := no.create_tween()
	tw.tween_method(func(k: float) -> void:
		no.global_position = de.lerp(at, k * k)
		no.rotation = Vector3(PI + k * 2.5, k * 3.0, 0), 0.0, 1.0, QUEDA)
	tw.tween_callback(no.queue_free)


## Engradado de madeira com os gargalos aparecendo.
static func _malha_engradado(cor_time: Color) -> ArrayMesh:
	var chave := "engradado_" + cor_time.to_html()
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var I := Basis.IDENTITY
	for z in [-0.28, 0.28]:
		_caixa(st, Vector3(0, 0.0, z), Vector3(0.45, 0.2, 0.03), I, MADEIRA, 1.0)
	for x in [-0.43, 0.43]:
		_caixa(st, Vector3(x, 0.0, 0), Vector3(0.03, 0.2, 0.28), I, MADEIRA.darkened(0.1), 1.0)
	_caixa(st, Vector3(0, -0.18, 0), Vector3(0.45, 0.02, 0.3), I, MADEIRA_ESCURA, 1.0)
	_caixa(st, Vector3(0, 0.05, 0.315), Vector3(0.2, 0.06, 0.01), I, cor_time, 0.0)
	for i in 3:
		for j in 2:
			var p := Vector3(-0.27 + i * 0.27, 0.1, -0.13 + j * 0.26)
			FxNatureza._tubo(st, [p, p + Vector3(0, 0.25, 0), p + Vector3(0, 0.38, 0)], 0.09, 0.035, VIDRO, VIDRO_ESCURO, 6)
	st.index()
	var m := st.commit()
	_malhas[chave] = m
	return m
