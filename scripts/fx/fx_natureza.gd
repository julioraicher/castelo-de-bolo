class_name FxNatureza
extends RefCounted
## Efeitos dos heróis 2.27b (regras em HeroisNatureza, ArvoreKodama, ParaRaios).
## Kodama do Shinboku: madeira, folha e musgo; a árvore dele é a do santuário
## (tronco torcido, nuvens de copa podadas em camadas, corda shimenawa com os
## papéis shide) e a copa de fora pega a cor do time. Kaminari-kozō: raio em
## zigue-zague (uma malha por raio, paleta "raio" do kit Magia), estalo e nuvem.
## Peças de madeira/cobre usam o material pintado do tema (o mesmo da árvore
## adulta da economia): luz, sombra, vento e raio X iguais aos do cenário.

const FOLHA := Color(0.55, 0.88, 0.35)
const TERRA := Color(0.42, 0.32, 0.2, 0.8)
const RAIO_COR := Color(0.62, 0.82, 1.0)
const AGUA := Color(0.45, 0.85, 1.0)
const CASCA := Color(0.42, 0.27, 0.16)
const CASCA_ESCURA := Color(0.3, 0.19, 0.12)
const RAIZ := Color(0.66, 0.48, 0.3)  # raiz nova, clara: lê no chão de terra e no escuro
const COPA := Color(0.2, 0.4, 0.19)
const COPA2 := Color(0.3, 0.5, 0.22)
const CORDA := Color(0.92, 0.82, 0.55)
const PAPEL := Color(0.98, 0.97, 0.92)
const COBRE := Color(0.78, 0.45, 0.25)
const COBRE_ESCURO := Color(0.45, 0.24, 0.14)

static var _mats_cena := {}
static var _malhas := {}


static func _g(u: Unit) -> Node:
	return u.game


static func _shake(g: Node, pos: Vector3, forca: float) -> void:
	var game := g as Game
	if game and game.camera:
		game.camera.shake_at(pos, forca)


# --- Material e malhas pintadas ------------------------------------------------------

## Material pintado do tema (achado na árvore adulta da economia). Sem tema:
## material comum com cor de vértice.
static func _mat_cena(g: Node) -> Material:
	var game := g as Game
	var th: ThemeConfig = game.arena.theme if game and game.arena else null
	var chave := th.resource_path if th else "_"
	if _mats_cena.has(chave):
		return _mats_cena[chave]
	var m: Material = null
	if th and th.arvore_estagios.size() >= 3 and th.arvore_estagios[2]:
		var tmp := th.arvore_estagios[2].instantiate()
		m = _achar_pintura(tmp)
		tmp.free()
	if m == null:
		var sm := StandardMaterial3D.new()
		sm.vertex_color_use_as_albedo = true
		sm.vertex_color_is_srgb = true
		sm.roughness = 0.9
		m = sm
	_mats_cena[chave] = m
	return m


static func _achar_pintura(n: Node) -> Material:
	var mi := n as MeshInstance3D
	if mi and mi.mesh:
		for s in mi.mesh.get_surface_count():
			var mm := mi.mesh.surface_get_material(s)
			if mm is ShaderMaterial and (mm as ShaderMaterial).shader == Arena.PINTURA:
				return mm
	for c in n.get_children():
		var r := _achar_pintura(c)
		if r:
			return r
	return null


## Um vértice no formato do pintura.gdshader: COLOR.a = oclusão, UV.x = vento.
static func _v(st: SurfaceTool, p: Vector3, nrm: Vector3, cor: Color, ao: float, vento: float) -> void:
	st.set_color(Color(cor.r, cor.g, cor.b, ao))
	st.set_uv(Vector2(vento, 0.0))
	st.set_normal(nrm)
	st.add_vertex(p)


## Triângulo virado para `fora` (Godot desenha a frente no sentido horário visto
## de fora; a malha do cenário descarta a face de trás).
static func _tri(st: SurfaceTool, a: Array, b: Array, c: Array, fora: Vector3) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	if (pb - pa).cross(pc - pa).dot(fora) > 0.0:
		var t := b
		b = c
		c = t
	for v: Array in [a, b, c]:
		_v(st, v[0], v[1], v[2], v[3], v[4])


## Tubo que afina ao longo de `pts` (galho, raiz, tronco, baqueta).
static func _tubo(st: SurfaceTool, pts: Array, r0: float, r1: float, cor0: Color, cor1: Color, lados := 6,
		vento := Vector2.ZERO, ao := Vector2(0.65, 1.0)) -> void:
	var n := pts.size()
	var aneis := []
	for i in n:
		var t := float(i) / float(n - 1)
		var p: Vector3 = pts[i]
		var d: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var a := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var b := d.cross(a).normalized()
		var r := lerpf(r0, r1, t)
		var cor := cor0.lerp(cor1, t)
		var anel := []
		for j in lados + 1:
			var ang := TAU * j / lados
			var nrm := (a * cos(ang) + b * sin(ang)).normalized()
			anel.append([p + nrm * r, nrm, cor, lerpf(ao.x, ao.y, t), lerpf(vento.x, vento.y, t)])
		aneis.append(anel)
	for i in n - 1:
		for j in lados:
			var q0: Array = aneis[i][j]
			var q1: Array = aneis[i][j + 1]
			var q2: Array = aneis[i + 1][j + 1]
			var q3: Array = aneis[i + 1][j]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			_tri(st, q0, q1, q2, fora)
			_tri(st, q0, q2, q3, fora)
	# Tampa da ponta (raiz/galho cortado não fica oco).
	var ponta: Vector3 = pts[n - 1]
	var dp: Vector3 = (pts[n - 1] - pts[n - 2]).normalized()
	for j in lados:
		var a: Array = aneis[n - 1][j]
		var b: Array = aneis[n - 1][j + 1]
		_tri(st, [ponta, dp, cor1, ao.y, vento.y], a, b, dp)


## Bolota achatada (pedaço de copa, musgo, nó).
static func _bola(st: SurfaceTool, c: Vector3, r: float, esc: Vector3, cor: Color, vento := 0.0,
		ao_baixo := 0.6, seg := 7, aneis := 4) -> void:
	var pts := []
	for j in aneis + 1:
		var el := -PI * 0.5 + PI * j / aneis
		var linha := []
		for i in seg + 1:
			var az := TAU * i / seg
			var nrm := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
			var ao := lerpf(ao_baixo, 1.0, clampf(nrm.y * 0.5 + 0.5, 0.0, 1.0))
			linha.append([c + nrm * esc * r, (nrm / esc).normalized(), cor, ao, vento])
		pts.append(linha)
	for j in aneis:
		for i in seg:
			var q0: Array = pts[j][i]
			var q1: Array = pts[j][i + 1]
			var q2: Array = pts[j + 1][i + 1]
			var q3: Array = pts[j + 1][i]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			_tri(st, q0, q1, q2, fora)
			_tri(st, q0, q2, q3, fora)


## Corda torcida (shimenawa): toro com dois fios em espiral.
static func _corda(st: SurfaceTool, c: Vector3, raio: float, grossura: float, cor: Color, seg := 18, lados := 6) -> void:
	var pts := []
	for i in seg + 1:
		var u := TAU * i / seg
		var centro := c + Vector3(cos(u), 0, sin(u)) * raio
		var radial := Vector3(cos(u), 0, sin(u))
		var linha := []
		for j in lados + 1:
			var v := TAU * j / lados
			var torce := 1.0 + 0.28 * sin(v * 2.0 + u * 9.0)  # os dois fios enrolados
			var nrm := (radial * cos(v) + Vector3.UP * sin(v)).normalized()
			var escuro := 0.82 + 0.18 * sin(v * 2.0 + u * 9.0)
			linha.append([centro + nrm * grossura * torce, nrm, cor * Color(escuro, escuro, escuro), 0.85 + 0.15 * nrm.y, 0.0])
		pts.append(linha)
	for i in seg:
		for j in lados:
			var q0: Array = pts[i][j]
			var q1: Array = pts[i + 1][j]
			var q2: Array = pts[i + 1][j + 1]
			var q3: Array = pts[i][j + 1]
			var fora: Vector3 = (q0[1] + q1[1] + q2[1] + q3[1]) * 0.25
			_tri(st, q0, q1, q2, fora)
			_tri(st, q0, q2, q3, fora)


## Papel shide: tira em zigue-zague pendurada (as duas faces).
static func _shide(st: SurfaceTool, topo: Vector3, para_fora: Vector3, comp: float, larg: float, vento: float) -> void:
	var lado := para_fora.cross(Vector3.UP).normalized()
	var degraus := 4
	var h := comp / degraus
	for k in degraus:
		var desvio := lado * larg * (0.5 if k % 2 == 0 else -0.5)
		var a := topo + Vector3(0, -h * k, 0) + desvio * 0.6
		var b := topo + Vector3(0, -h * (k + 1), 0) - desvio * 0.6
		var c0 := a - lado * larg * 0.5
		var c1 := a + lado * larg * 0.5
		var c2 := b + lado * larg * 0.5
		var c3 := b - lado * larg * 0.5
		var vk := vento * (0.4 + 0.6 * float(k + 1) / degraus)
		for nrm: Vector3 in [para_fora, -para_fora]:
			var q := [[c0, nrm, PAPEL, 1.0, vk], [c1, nrm, PAPEL, 1.0, vk], [c2, nrm, PAPEL, 0.92, vk], [c3, nrm, PAPEL, 0.92, vk]]
			_tri(st, q[0], q[1], q[2], nrm)
			_tri(st, q[0], q[2], q[3], nrm)


# --- Kodama: a árvore do santuário ------------------------------------------------------

## Malha da árvore (uma chamada de desenho). A copa de fora e o musgo pegam a
## cor do time; tronco torcido, raízes que abraçam o chão, três nuvens de copa.
static func _malha_arvore(cor_time: Color) -> ArrayMesh:
	var chave := "arvore_" + cor_time.to_html()
	if _malhas.has(chave):
		return _malhas[chave]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2271
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var musgo := Color(0.26, 0.42, 0.18).lerp(cor_time, 0.55)
	var copa_time := COPA2.lerp(cor_time, 0.5)
	# Raízes: saem do tronco e mergulham no chão em volta.
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		var fora := Vector3(cos(a), 0, sin(a))
		var pts := [fora * 0.18 + Vector3(0, 0.55, 0), fora * 0.5 + Vector3(0, 0.3, 0), fora * 0.85 + Vector3(0, 0.08, 0), fora * 1.1 + Vector3(0, -0.08, 0)]
		_tubo(st, pts, 0.17, 0.05, CASCA, CASCA_ESCURA, 6, Vector2.ZERO, Vector2(0.75, 0.55))
		if k % 2 == 0:
			_bola(st, fora * 0.62 + Vector3(0, 0.26, 0), 0.2, Vector3(1.2, 0.45, 1.0), musgo, 0.0, 0.7, 6, 3)
	# Tronco torcido (S suave) que afina; galhos para cada nuvem de copa.
	var tronco := [Vector3(0, -0.05, 0), Vector3(0.05, 0.7, 0.02), Vector3(-0.06, 1.4, 0.04), Vector3(0.07, 2.1, -0.03), Vector3(0.0, 2.8, 0.0)]
	_tubo(st, tronco, 0.44, 0.2, CASCA_ESCURA, CASCA, 8, Vector2(0.0, 0.12), Vector2(0.55, 1.0))
	var nuvens := [[Vector3(0.75, 2.35, 0.2), 1.05], [Vector3(-0.7, 2.95, -0.25), 0.95], [Vector3(0.1, 3.55, 0.05), 0.8]]
	for nv: Array in nuvens:
		var c: Vector3 = nv[0]
		var base := Vector3(0.0, c.y - 0.75, 0.0)
		_tubo(st, [base, base.lerp(c, 0.5) + Vector3(0, 0.15, 0), c - Vector3(0, 0.15, 0)], 0.15, 0.07, CASCA, CASCA, 5, Vector2(0.1, 0.5), Vector2(0.8, 1.0))
	# Nuvens de copa (estilo podado do santuário): bolotas achatadas em anel;
	# as de fora na cor do time, as de dentro verde-escuro.
	for nv: Array in nuvens:
		var c: Vector3 = nv[0]
		var r: float = nv[1]
		_bola(st, c, r * 0.62, Vector3(1.0, 0.5, 1.0), COPA, 0.7, 0.55, 8, 4)
		var n := 6
		for i in n:
			var a := TAU * i / n + rng.randf() * 0.4
			var p := c + Vector3(cos(a) * r * 0.7, rng.randf_range(-0.06, 0.1), sin(a) * r * 0.7)
			_bola(st, p, r * rng.randf_range(0.36, 0.46), Vector3(1.0, 0.55, 1.0), copa_time if i % 2 == 0 else COPA2, 0.9, 0.5, 7, 4)
	_bola(st, Vector3(0.05, 4.0, 0.0), 0.42, Vector3(1.0, 0.75, 1.0), copa_time, 1.0, 0.6, 7, 4)
	# Shimenawa na altura do peito com quatro papéis shide pendurados.
	var y_corda := 1.15
	var r_corda := 0.4
	_corda(st, Vector3(0.0, y_corda, 0.03), r_corda, 0.075, CORDA)
	for k in 4:
		var a := TAU * k / 4.0 + 0.6
		var fora := Vector3(cos(a), 0, sin(a))
		_shide(st, Vector3(0, y_corda - 0.04, 0.03) + fora * (r_corda + 0.09), fora, 0.42, 0.11, 0.25)
	st.index()
	var m := st.commit()
	_malhas[chave] = m
	return m


## Visual da árvore do Kodama dentro de `pai` (nó que cresce e tomba).
static func arvore(pai: Node3D, cor_time: Color, _grande: bool) -> Node3D:
	var no := Node3D.new()
	no.name = "ArvoreKodama"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(no)
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_arvore(cor_time)
	mi.material_override = _mat_cena(pai.get_parent())
	no.add_child(mi)
	return no


static func arvore_nasce(g: Node, pos: Vector3, escala: float) -> void:
	FxProjetil.fumaca(g, pos + Vector3(0, 0.2, 0), TERRA, 5, 1.0 * escala, 0.7, 1.0)
	Assinatura.pecas(g, pos + Vector3(0, 1.0 * escala, 0), "semente", FOLHA, 6, {"tam": 0.8})
	FxProjetil.marca_chao(g, pos, Color(0.18, 0.12, 0.06, 0.5), 1.1 * escala, 3.0)
	if escala > 1.2:
		Magia.onda(g, pos, "bosque", 2.2 * escala, 0.45, {"banda": 0.18})


static func arvore_golpe(arv: Node3D, by: Unit) -> void:
	var g := arv.get_parent()
	var at := arv.global_position + Vector3(0, 0.9, 0)
	var dir := (at - by.global_position).normalized() if by else Vector3.UP
	FxProjetil.faiscas(g, at, Color(0.78, 0.6, 0.38), 8, 5.0, -dir + Vector3.UP * 0.6, 60.0, 0.22)
	Assinatura.pecas(g, at + Vector3(0, 1.8, 0), "semente", FOLHA, 4, {"tam": 0.6})
	Sfx.play("madeira_golpe", at, 0.15)
	var v := arv.get_child(arv.get_child_count() - 1) as Node3D
	for c in arv.get_children():
		if c.name == "ArvoreKodama":
			v = c
	if v:
		var tw := v.create_tween()
		tw.tween_property(v, "rotation:z", 0.08, 0.06)
		tw.tween_property(v, "rotation:z", -0.05, 0.08)
		tw.tween_property(v, "rotation:z", 0.0, 0.1)


## Fogo na copa: a árvore vira tocha. Devolve o nó (some com a árvore).
static func tocha(arv: Node3D, escala: float, t: float) -> Node3D:
	var g := arv.get_parent()
	var no := Node3D.new()
	no.name = "Tocha"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	arv.add_child(no)
	no.position = Vector3(0, 2.9 * escala, 0)
	Magia.chama(no, arv.global_position + Vector3(0, 1.6 * escala, 0), "brasa", 1.3 * escala, 2.8 * escala, t + 0.3, {"segura": 0.75, "giro": 1.2})
	Magia.aura_brasas(no, Color(1.0, 0.6, 0.2), t, 14, 1.1 * escala)
	FxProjetil.fumaca(g, arv.global_position + Vector3(0, 3.4 * escala, 0), Color(0.2, 0.17, 0.16, 0.7), 6, 1.4 * escala, 1.4, 1.6)
	Magia.clarao(g, arv.global_position, Color(1.0, 0.6, 0.25), 9.0, t, 2.0)
	Fx.damage_number(g, arv.global_position + Vector3(0, 2.0, 0), "PEGOU FOGO!", Color(1.0, 0.6, 0.25), 0.9)
	Sfx.play("fogo", arv.global_position, 0.1)
	return no


static func arvore_cai(arv: Node3D, queimada: bool, escala: float) -> void:
	var g := arv.get_parent()
	var at := arv.global_position
	FxProjetil.fumaca(g, at + Vector3(0, 0.3, 0), TERRA, 6, 1.0 * escala, 0.8, 0.8)
	if queimada:
		Assinatura.pecas(g, at + Vector3(0, 2.0 * escala, 0), "cinza", Color(0.3, 0.27, 0.28), 14, {"mov": "sobe", "esfera": 1.0 * escala})
		FxProjetil.marca_chao(g, at, Color(0.06, 0.04, 0.03, 0.6), 1.3 * escala, 4.0)
	else:
		Assinatura.pecas(g, at + Vector3(0, 2.6 * escala, 0), "semente", FOLHA, 10, {"esfera": 1.0 * escala})
	Sfx.play("kodama_cai", at, 0.1, 1.0 if escala < 1.2 else 0.8, -3.0)


# --- Kodama: raízes, bosque e floresta ---------------------------------------------------

## Tufo de raízes que sai do chão e se fecha (prende, broto, dash).
static func _malha_tufo() -> ArrayMesh:
	if _malhas.has("tufo"):
		return _malhas["tufo"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 5:
		var a := TAU * k / 5.0
		var fora := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-fora.z, 0, fora.x)
		var pts := [fora * 0.62 + Vector3(0, -0.15, 0), fora * 0.55 + Vector3(0, 0.35, 0) + lado * 0.12,
				fora * 0.34 + Vector3(0, 0.75, 0) + lado * 0.22, fora * 0.12 + Vector3(0, 1.0, 0) + lado * 0.18]
		_tubo(st, pts, 0.15, 0.035, RAIZ, RAIZ.lightened(0.18), 5, Vector2(0.0, 0.3), Vector2(0.8, 1.0))
		_bola(st, pts[3] + Vector3(0, 0.05, 0), 0.11, Vector3(1.4, 0.5, 0.8), COPA2.lightened(0.3) if k % 2 == 0 else FOLHA, 0.4, 0.85, 5, 3)
	st.index()
	_malhas["tufo"] = st.commit()
	return _malhas["tufo"]


static func _tufo(g: Node, at: Vector3, escala: float, dur: float) -> void:
	var no := Magia._no(g, at)
	no.rotation.y = randf() * TAU
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_tufo()
	mi.material_override = _mat_cena(g)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	no.add_child(mi)
	no.scale = Vector3(escala, 0.05, escala)
	var tw := no.create_tween()
	tw.tween_property(no, "scale", Vector3.ONE * escala, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(dur - 0.3, 0.05))
	tw.tween_property(no, "scale", Vector3(escala * 0.8, 0.02, escala * 0.8), 0.22).set_ease(Tween.EASE_IN)
	tw.tween_callback(no.queue_free)


## Q Raízes: a linha rompe o chão em sequência, do Kodama até a ponta.
static func raizes(u: Unit, de: Vector3, dir: Vector3, comp: float) -> void:
	var g := _g(u)
	var y := Vector3(0, 0.1, 0)
	Magia.lanca(g, de + y, de + y + dir * comp, "bosque", 1.0, 0.7, {"cresce": 0.22, "corre": 4.0, "forca": 0.7})
	var n := clampi(int(comp / 1.4), 3, 6)
	for i in n:
		var p := de + dir * comp * (float(i) + 0.8) / float(n)
		var atraso := 0.035 * i
		var tw := u.create_tween()
		tw.tween_interval(atraso)
		tw.tween_callback(func() -> void:
			if is_instance_valid(g):
				_tufo(g, p, 1.25, Config.cfg.raizes_preso)
				FxProjetil.fumaca(g, p + Vector3(0, 0.2, 0), TERRA, 2, 0.8, 0.5, 0.8))
	Assinatura.pecas(g, de + dir * comp * 0.5 + Vector3(0, 0.6, 0), "semente", FOLHA, 8, {"esfera": comp * 0.3})
	FxProjetil.marca_chao(g, de + dir * comp * 0.5, Color(0.18, 0.12, 0.06, 0.45), comp * 0.35, 1.8)
	_shake(g, de + dir * comp * 0.5, 0.18)
	Sfx.play("kodama_raizes", de, 0.05)


static func raiz_prende(o: Unit) -> void:
	_tufo(_g(o), o.global_position, 0.85, maxf(o._preso_t, 0.4))
	Assinatura.pecas(_g(o), o.global_position + Vector3(0, 0.6, 0), "semente", FOLHA, 4, {"tam": 0.6})


## 3º tiro do Kodama: a semente brota nos pés de quem acertou.
static func broto(u: Unit) -> void:
	var g := _g(u)
	_tufo(g, u.global_position, 0.7, Config.cfg.broto_preso + 0.1)
	Assinatura.pecas(g, u.global_position + Vector3(0, 0.5, 0), "semente", FOLHA, 6, {"tam": 0.7})
	Fx.damage_number(g, u.global_position + Vector3(0, 0.9, 0), "BROTOU!", FOLHA, 0.8)
	Sfx.play("kodama_brota", u.global_position, 0.1)


## E Bosque: anel de seiva no chão; as árvores nascem por cima.
static func bosque(u: Unit, centro: Vector3) -> void:
	var g := _g(u)
	Magia.lanca(g, u.global_position + Vector3(0, 1.4, 0), centro + Vector3(0, 0.3, 0), "bosque", 0.3, 0.35, {"cresce": 0.12})
	Magia.onda(g, centro, "bosque", 3.4, 0.5, {"banda": 0.12, "gira": 0.4})
	Assinatura.pecas(g, centro + Vector3(0, 0.8, 0), "semente", FOLHA, 12, {"esfera": 1.6})
	_shake(g, centro, 0.2)
	Sfx.play("kodama_bosque", centro, 0.05)


## R Floresta Antiga: selo enorme e a terra rachando em verde.
static func floresta(u: Unit, c: Vector3, r: float) -> void:
	var g := _g(u)
	Magia.selo(g, c, "bosque", r, Config.cfg.floresta_tempo, {"pontas": 10, "petalas": 5, "escrita": 0.6, "giro": 0.03})
	Magia.rachaduras(g, c, "bosque", r * 0.9, 12, 1.4)
	Magia.onda(g, c, "bosque", r * 1.1, 0.7, {"banda": 0.08})
	Magia.chama(g, c, "bosque", 1.2, 4.0, 0.8, {"giro": 0.8, "segura": 0.3})
	Assinatura.pecas(g, c + Vector3(0, 4.0, 0), "semente", FOLHA, 30, {"esfera": r * 0.8, "mov": "cai", "vida": 2.2})
	Magia.clarao(g, c, Color(0.6, 1.0, 0.45), r * 1.4, 0.6, 3.0)
	Sfx.play("kodama_floresta", c, 0.03)


static func floresta_pulso(u: Unit, c: Vector3, r: float) -> void:
	var g := _g(u)
	Magia.onda(g, c, "bosque", r, 0.6, {"banda": 0.05, "r0": 0.85})
	Assinatura.pecas(g, c + Vector3(0, 4.0, 0), "semente", FOLHA, 10, {"esfera": r * 0.7, "mov": "cai"})
	Sfx.play("kodama_brota", c, 0.1, 0.8, -6.0)


## Sombra que cura (árvore do bosque ou anel da floresta).
static func sombra_cura(o: Unit) -> void:
	var g := _g(o)
	Assinatura.pecas(g, o.global_position + Vector3(0, 2.2, 0), "semente", FOLHA, 3, {"tam": 0.5, "mov": "cai"})
	FxProjetil.brilho(g, o.global_position + Vector3(0, 1.3, 0), Color(0.6, 1.0, 0.5, 0.6), 0.9, 0.25)


# --- Kaminari-kozō: o raio ---------------------------------------------------------------

## Pontos de um zigue-zague de a até b (pontas fixas).
static func _zigue(a: Vector3, b: Vector3, n: int, amp: float) -> Array:
	var d := b - a
	var e1 := d.cross(Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT).normalized()
	var e2 := d.cross(e1).normalized()
	var pts := [a]
	for i in range(1, n):
		var t := float(i) / n
		pts.append(a + d * t + e1 * randf_range(-amp, amp) + e2 * randf_range(-amp, amp) * 0.6)
	pts.append(b)
	return pts


## Fita em cruz ao longo dos pontos (U atravessa, V corre de 0 a 1).
static func _fita_raio(st: SurfaceTool, pts: Array, larg: float) -> void:
	var total := 0.0
	for i in pts.size() - 1:
		total += (pts[i + 1] - pts[i]).length()
	var corrido := 0.0
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := (b - a).normalized()
		var v0 := corrido / total
		corrido += (b - a).length()
		var v1 := corrido / total
		var w0 := larg * (0.55 + 0.45 * sin(v0 * PI))
		var w1 := larg * (0.55 + 0.45 * sin(v1 * PI))
		var e1 := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var e2 := d.cross(e1).normalized()
		for e: Vector3 in [e1, e2]:
			var q := [[a - e * w0 * 0.5, Vector2(0, v0)], [a + e * w0 * 0.5, Vector2(1, v0)], [b + e * w1 * 0.5, Vector2(1, v1)], [b - e * w1 * 0.5, Vector2(0, v1)]]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_uv(q[k][1])
				st.add_vertex(q[k][0])


## Um raio de `de` até `ate`: zigue-zague com um galho, pisca uma vez e se rasga.
static func raio(g: Node, de: Vector3, ate: Vector3, vida := 0.3, larg := 0.22) -> void:
	if g == null or not is_instance_valid(g):
		return
	var d := ate - de
	var comp := d.length()
	if comp < 0.1:
		return
	var n := Magia._no(g, de)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := _zigue(Vector3.ZERO, d, clampi(int(comp / 1.1), 3, 9), minf(comp * 0.1, 0.9))
	_fita_raio(st, pts, larg)
	if comp > 2.5:
		var i := pts.size() / 2
		var p: Vector3 = pts[i]
		var desvio := d.normalized().cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)
		_fita_raio(st, _zigue(p, p + (d.normalized() * 0.6 + desvio).normalized() * comp * 0.25, 3, comp * 0.04), larg * 0.55)
	var m := Magia.mat("raio", {"escala": Vector2(1.0, maxf(comp * 0.3, 1.0)), "rola": Vector2(0.0, -7.0), "forca": 0.5,
			"base": 1.0, "topo": 1.0, "lados": 1.0, "tinta": 0.1})
	var mi := Magia._malha(n, st.commit(), m)
	var tw := n.create_tween()
	tw.tween_interval(vida * 0.22)
	tw.tween_callback(func() -> void: mi.visible = false)
	tw.tween_interval(0.035)
	tw.tween_callback(func() -> void: mi.visible = true)
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("corroi", v), 0.0, 1.0, vida * 0.7)
	tw.tween_callback(n.queue_free)
	FxProjetil.brilho(g, ate, Color(0.7, 0.85, 1.0), 0.8 + larg * 2.0, 0.12)


## Raio do céu num ponto do chão (Tambores, descarga num para-raios).
static func raio_ceu(g: Node, pos: Vector3) -> void:
	if g == null or not is_instance_valid(g):
		return
	var topo := pos + Vector3(randf_range(-1.2, 1.2), 13.0, randf_range(-1.2, 1.2))
	raio(g, topo, pos + Vector3(0, 0.05, 0), 0.32, 0.55)
	Magia.onda(g, pos, "raio", 1.9, 0.3, {"banda": 0.14})
	Magia.estouro(g, pos + Vector3(0, 0.3, 0), "raio", 1.1, 0.22)
	FxProjetil.faiscas(g, pos + Vector3(0, 0.3, 0), Color(0.78, 0.9, 1.0), 10, 8.0, Vector3.UP, 80.0, 0.22)
	FxProjetil.marca_chao(g, pos, Color(0.08, 0.07, 0.12, 0.55), 0.8, 2.5)
	Magia.clarao(g, pos, RAIO_COR, 10.0, 0.2, 4.0)
	_shake(g, pos, 0.22)
	Sfx.play("kaminari_trovao", pos, 0.12, 1.0, -3.0)


## 3º trovão do Kaminari-kozō estourando: raios curtos para todo lado.
static func trovao_estoura(g: Node, at: Vector3, r: float) -> void:
	Magia.estouro(g, at, "raio", r, 0.3)
	var chao := at - Vector3(0, 1.0, 0)
	var game := g as Game
	if game and game.arena:
		chao.y = game.arena.ground_y(at.x, at.z, at.y + 1.0, Config.LAYER_WORLD)
	Magia.onda(g, chao, "raio", r * 1.1, 0.35, {"banda": 0.12})
	for i in 4:
		var a := TAU * i / 4.0 + randf() * 0.8
		raio(g, at, at + Vector3(cos(a) * r, randf_range(-0.8, 0.3), sin(a) * r), 0.25, 0.16)
	FxProjetil.faiscas(g, at, Color(0.78, 0.9, 1.0), 12, 9.0, Vector3.UP, 180.0, 0.2)
	Magia.clarao(g, at, RAIO_COR, r * 3.0, 0.2, 3.0)


static func conduziu(o: Unit) -> void:
	var g := _g(o)
	FxProjetil.faiscas(g, o.global_position + Vector3(0, 1.0, 0), AGUA, 6, 5.0, Vector3.UP, 180.0, 0.2)
	Fx.damage_number(g, o.global_position + Vector3(0, 1.4, 0), "CONDUZIU!", AGUA, 0.7)


## Água do Kappa (ou qualquer "agua"): pinga enquanto está molhado.
static func molhado(u: Unit) -> void:
	var g := _g(u)
	Fx.damage_number(g, u.global_position + Vector3(0, 0.9, 0), "MOLHADO", AGUA, 0.7)
	if not Magia.enfeite():
		return
	var p := FxProjetil.ps(u, Vector3(0, 1.4, 0), FxProjetil._gota(), AGUA, 6, 0.5, {"one_shot": false, "local_pos": true,
			"esfera": 0.35, "dir": Vector3.DOWN, "spread": 10.0, "v0": 0.4, "v1": 1.0, "g": Vector3(0, -9, 0), "s0": 0.6, "s1": 0.9})
	p.local_coords = false
	var tw := p.create_tween().set_loops()
	tw.tween_interval(0.25)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(u) or not u.alive or u._molhado_t <= 0.0:
			p.emitting = false
			tw.kill()
			var fim := p.create_tween()
			fim.tween_interval(0.6)
			fim.tween_callback(p.queue_free))


## Carga cheia: estalo na cabeça e o cabelo começa a faiscar.
static func carga_cheia(u: Unit) -> void:
	var g := _g(u)
	Magia.estouro(g, u.global_position + Vector3(0, 1.9, 0), "raio", 1.0, 0.25)
	FxProjetil.faiscas(g, u.global_position + Vector3(0, 2.0, 0), Color(0.8, 0.92, 1.0), 8, 6.0, Vector3.UP, 70.0, 0.2)
	Fx.damage_number(g, u.global_position + Vector3(0, 1.2, 0), "CARREGADO!", Color(0.75, 0.88, 1.0), 0.8)
	Sfx.play("kaminari_carga", u.global_position, 0.05)


## Cabelo faiscando (um nó só na cabeça). HeroisNatureza tira na descarga.
static func cabelo_faiscando(u: Unit) -> Node:
	var no := Node3D.new()
	no.name = "CargaCheia"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(no)
	no.position = Vector3(0, 2.05, 0)
	var b := FxProjetil.brilho_fixo(no, Vector3.ZERO, Color(0.55, 0.78, 1.0, 0.75), 1.0)
	if Magia.enfeite():
		FxProjetil.ps(no, Vector3.ZERO, FxProjetil.lasca(0.24, 0.03), Color(0.85, 0.94, 1.0), 6, 0.16, {"one_shot": false, "local_pos": true,
				"esfera": 0.32, "dir": Vector3.UP, "spread": 180.0, "v0": 1.5, "v1": 3.5, "alinha": true, "rampa": "pisca", "s0": 0.6, "s1": 1.0})
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "scale", Vector3.ONE * 1.25, 0.07)
	tw.tween_property(b, "scale", Vector3.ONE * 0.8, 0.09)
	return no


## A descarga sai do Kaminari-kozō e cai em quem ele bateu.
static func descarga(k: Unit, alvo: Unit) -> void:
	var g := _g(k)
	raio(g, k.global_position + Vector3(0, 2.0, 0), alvo.global_position + Vector3(0, 1.1, 0), 0.35, 0.4)
	Magia.estouro(g, alvo.global_position + Vector3(0, 1.1, 0), "raio", 1.4, 0.28)
	Magia.onda(g, alvo.global_position, "raio", 2.4, 0.35, {"banda": 0.12})
	Assinatura.pecas(g, alvo.global_position + Vector3(0, 1.1, 0), "faisca", Color(0.8, 0.92, 1.0), 10)
	Magia.clarao(g, alvo.global_position, RAIO_COR, 9.0, 0.22, 4.0)
	Fx.damage_number(g, alvo.global_position + Vector3(0, 1.6, 0), "DESCARGA!", Color(0.75, 0.88, 1.0), 1.0)
	_shake(g, alvo.global_position, 0.3)
	Sfx.play("kaminari_trovao", alvo.global_position, 0.05)


# --- Kaminari-kozō: para-raios, relâmpago e tambores ---------------------------------

## Baqueta de cobre: haste com anéis, ponta de tridente e base de estaca.
static func _malha_para_raios(cor_time: Color) -> ArrayMesh:
	var chave := "pararaios_" + cor_time.to_html()
	if _malhas.has(chave):
		return _malhas[chave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tubo(st, [Vector3(0, -0.2, 0), Vector3(0, 0.8, 0), Vector3(0, 1.45, 0)], 0.07, 0.045, COBRE_ESCURO, COBRE, 6, Vector2.ZERO, Vector2(0.7, 1.0))
	for y: float in [0.35, 0.75, 1.15]:
		_bola(st, Vector3(0, y, 0), 0.1, Vector3(1.0, 0.35, 1.0), cor_time if y > 1.0 else COBRE.lightened(0.15), 0.0, 0.7, 7, 3)
	# Ponta de tridente (as três agulhas puxam o raio).
	for k in 3:
		var a := TAU * k / 3.0
		var lado := Vector3(cos(a), 0, sin(a))
		_tubo(st, [Vector3(0, 1.4, 0), lado * 0.12 + Vector3(0, 1.55, 0), lado * 0.1 + Vector3(0, 1.82, 0)], 0.03, 0.008, COBRE, COBRE.lightened(0.3), 4, Vector2.ZERO, Vector2(1.0, 1.0))
	_tubo(st, [Vector3(0, 1.4, 0), Vector3(0, 1.95, 0)], 0.035, 0.008, COBRE, COBRE.lightened(0.35), 5, Vector2.ZERO, Vector2(1.0, 1.0))
	# Base: três aletas cravadas e terra levantada.
	for k in 3:
		var a := TAU * k / 3.0 + 0.5
		var lado := Vector3(cos(a), 0, sin(a))
		_tubo(st, [Vector3(0, 0.25, 0), lado * 0.22 + Vector3(0, 0.05, 0), lado * 0.32 + Vector3(0, -0.1, 0)], 0.04, 0.015, COBRE_ESCURO, COBRE_ESCURO, 4)
	_bola(st, Vector3(0, -0.02, 0), 0.3, Vector3(1.0, 0.22, 1.0), Color(0.36, 0.28, 0.2), 0.0, 0.6, 7, 3)
	st.index()
	_malhas[chave] = st.commit()
	return _malhas[chave]


static func para_raios(pai: Node3D, cor: Color) -> void:
	var no := Node3D.new()
	no.name = "Baqueta"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(no)
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_para_raios(cor)
	mi.material_override = _mat_cena(pai.get_parent())
	no.add_child(mi)
	var luz := FxProjetil.brilho_fixo(no, Vector3(0, 1.85, 0), Color(cor.lightened(0.3), 0.85), 0.7)
	if Magia.enfeite():
		FxProjetil.ps(no, Vector3(0, 1.8, 0), FxProjetil.lasca(0.2, 0.025), Color(0.85, 0.94, 1.0), 3, 0.15, {"one_shot": false, "local_pos": true,
				"esfera": 0.15, "dir": Vector3.UP, "spread": 180.0, "v0": 1.0, "v1": 2.5, "alinha": true, "rampa": "pisca", "s0": 0.6, "s1": 1.0})
	# Crava: cai do alto, entra no chão e treme.
	no.position.y = 2.2
	var tw := no.create_tween()
	tw.tween_property(no, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(no, "rotation:z", 0.12, 0.05)
	tw.tween_property(no, "rotation:z", -0.07, 0.07)
	tw.tween_property(no, "rotation:z", 0.0, 0.08)
	var pisca := luz.create_tween().set_loops()
	pisca.tween_property(luz, "scale", Vector3.ONE * 0.95, 0.35).set_trans(Tween.TRANS_SINE)
	pisca.tween_property(luz, "scale", Vector3.ONE * 0.6, 0.35).set_trans(Tween.TRANS_SINE)


static func para_raios_lanca(u: Unit, at: Vector3) -> void:
	var g := _g(u)
	Magia.lanca(g, u.global_position + Vector3(0, 1.5, 0), at + Vector3(0, 1.0, 0), "raio", 0.14, 0.2, {"cresce": 0.08, "corre": 8.0})
	var tw := u.create_tween()
	tw.tween_interval(0.14)
	tw.tween_callback(func() -> void:
		if is_instance_valid(g):
			FxProjetil.fumaca(g, at + Vector3(0, 0.15, 0), TERRA, 4, 0.7, 0.5, 0.6)
			FxProjetil.faiscas(g, at + Vector3(0, 0.3, 0), Color(1.0, 0.75, 0.45), 8, 6.0, Vector3.UP, 70.0, 0.2)
			FxProjetil.marca_chao(g, at, Color(0.12, 0.09, 0.07, 0.5), 0.6, Config.cfg.pararaios_tempo)
			Sfx.play("kaminari_choque", at, 0.1, 0.8, -4.0))
	Sfx.play("lancar_metal", u.global_position, 0.1)


static func para_raios_ocioso(pr: Node3D) -> void:
	if Magia.enfeite():
		FxProjetil.faiscas(pr.get_parent(), pr.global_position + Vector3(0, 1.85, 0), Color(0.8, 0.92, 1.0), 2, 3.0, Vector3.UP, 120.0, 0.16)


## E Relâmpago: o corpo vira um raio deitado entre a saída e a chegada.
static func relampago(u: Unit, de: Vector3, ate: Vector3) -> void:
	var g := _g(u)
	var y := Vector3(0, 1.0, 0)
	raio(g, de + y, ate + y, 0.4, 0.7)
	raio(g, de + y * 0.6, ate + y * 1.2, 0.3, 0.3)
	Magia.estouro(g, de + y, "raio", 1.2, 0.25)
	Magia.estouro(g, ate + y, "raio", 1.6, 0.3)
	Magia.onda(g, ate, "raio", 2.6, 0.35, {"banda": 0.12})
	var meio := (de + ate) * 0.5
	var comp := Vector2(ate.x - de.x, ate.z - de.z).length()
	if comp > 1.0:
		FxProjetil.marca_chao(g, meio, Color(0.08, 0.07, 0.12, 0.45), comp * 0.5, 2.0)
	Assinatura.pecas(g, ate + y, "faisca", Color(0.8, 0.92, 1.0), 10)
	Magia.clarao(g, ate, RAIO_COR, 10.0, 0.22, 4.0)
	_shake(g, ate, 0.25)
	Sfx.play("kaminari_relampago", de, 0.05)


## R Tambores do Trovão: a nuvem de tempestade em cima dele por `t` s.
static func tambores(u: Unit, t: float) -> void:
	var g := _g(u)
	Magia.onda(g, u.global_position, "raio", Config.cfg.tambores_raio, 0.6, {"banda": 0.05, "gira": 0.6})
	Magia.estouro(g, u.global_position + Vector3(0, 1.2, 0), "raio", 2.0, 0.35)
	var no := Node3D.new()
	no.name = "NuvemTrovao"
	no.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	u.add_child(no)
	no.position = Vector3(0, 6.5, 0)
	Magia.bola(no, no.global_position, [Color(0.85, 0.89, 1.0), Color(0.36, 0.37, 0.54), Color(0.16, 0.14, 0.25)], 2.4, t, {"segura": 0.85, "achata": 0.4, "sobe": 0.3, "forca": 0.9})
	if Magia.enfeite():
		FxProjetil.ps(no, Vector3.ZERO, FxProjetil.quad("fumaca", FxProjetil.tex_fumaca()), Color(0.3, 0.3, 0.42, 0.8), 10, 1.2, {"one_shot": false,
				"local_pos": true, "esfera": 1.8, "dir": Vector3.UP, "spread": 90.0, "v0": 0.2, "v1": 0.6, "s0": 1.6, "s1": 2.6, "curva": "cresce"})
	var tw := no.create_tween()
	tw.tween_interval(t)
	tw.tween_callback(no.queue_free)
	Sfx.play("kaminari_tambor", u.global_position, 0.03)


# --- Dash (quiz 4B) ------------------------------------------------------------------

## Kodama afunda num tufo de raízes e brota adiante; Kaminari-kozō vira um risco de raio.
static func dash_heroi(u: Unit, sumir: bool) -> void:
	var g := _g(u)
	var at := u.global_position
	if u.stats.dash_estilo == "brota":
		FxProjetil.fumaca(g, at + Vector3(0, 0.2, 0), TERRA, 5, 0.9, 0.6, 0.8)
		FxProjetil.marca_chao(g, at, Color(0.18, 0.12, 0.06, 0.55), 0.7, 1.5)
		_tufo(g, at, 0.6, 0.35)
		if not sumir:
			Magia.onda(g, at, "bosque", 1.6, 0.35, {"banda": 0.18})
		Sfx.play("kodama_brota", at, 0.1, 1.25 if sumir else 1.0, -6.0)
		return
	if sumir:
		var ate := at + u._dodge_dir * Unit.DODGE_SPEED * Unit.DODGE_TIME
		raio(g, at + Vector3(0, 1.0, 0), ate + Vector3(0, 1.0, 0), 0.28, 0.4)
		Sfx.play("kaminari_choque", at, 0.1, 1.2, -4.0)
	Magia.estouro(g, at + Vector3(0, 1.0, 0), "raio", 1.0 if sumir else 1.3, 0.22)
	FxProjetil.faiscas(g, at + Vector3(0, 1.0, 0), Color(0.78, 0.9, 1.0), 8, 7.0, Vector3.UP, 160.0, 0.2)


static func dash_rastro(u: Unit) -> void:
	if not Magia.enfeite():
		return
	var g := _g(u)
	if u.stats.dash_estilo == "brota":
		FxProjetil.fumaca(g, u.global_position + Vector3(0, 0.15, 0), TERRA, 1, 0.6, 0.5, 0.4)
	else:
		FxProjetil.faiscas(g, u.global_position + Vector3(0, 1.0, 0), Color(0.8, 0.92, 1.0), 2, 4.0, Vector3.UP, 180.0, 0.18)
