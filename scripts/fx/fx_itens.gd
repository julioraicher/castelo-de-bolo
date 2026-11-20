class_name FxItens
extends RefCounted
## Peças pequenas do chão no padrão do princípio 13 (Ciclo 2.32, lote D da
## caça aos bugs): o espírito solto (hitodama), os 5 itens e as armadilhas do
## Construtor. Objeto = uma ArrayMesh com cor por vértice no material pintado do
## cenário (MalhaPintada.material); energia = shader do kit Magia. Peça parada
## custa uma chamada por material: objeto, energia e anel do chão.
## Malhas guardadas por chave: a mesma malha serve a todas as cópias.

const PAL_HITODAMA := [Color(0.93, 1.0, 0.95), Color(0.42, 1.0, 0.7), Color(0.06, 0.55, 0.45)]
const PAL_ITEM := {
	"pocao": [Color(1.0, 0.95, 0.96), Color(1.0, 0.45, 0.56), Color(0.74, 0.1, 0.26)],
	"escudo": [Color(0.92, 1.0, 1.0), Color(0.4, 0.86, 1.0), Color(0.08, 0.4, 0.85)],
	"velocidade": [Color(1.0, 1.0, 0.92), Color(1.0, 0.88, 0.35), Color(0.85, 0.52, 0.08)],
	"dano": [Color(1.0, 0.93, 0.86), Color(1.0, 0.32, 0.18), Color(0.72, 0.05, 0.05)],
	"medidor": [Color(1.0, 0.92, 1.0), Color(0.8, 0.45, 1.0), Color(0.38, 0.1, 0.72)],
}
## Peça que espirra quando o item é pego (Assinatura.pecas).
const PECA_ITEM := {"pocao": "gota", "escudo": "lasca", "velocidade": "nuvem", "dano": "faisca", "medidor": "papel"}
const SOM_ITEM := {"pocao": "item_pocao", "escudo": "item_escudo", "velocidade": "item_velocidade", "dano": "item_dano", "medidor": "item_medidor"}

const LACA := Color(0.72, 0.1, 0.16)
const OURO := Color(0.95, 0.74, 0.3)
const MADEIRA := Color(0.66, 0.48, 0.28)
const MADEIRA_ESCURA := Color(0.42, 0.28, 0.16)
const PAPEL := Color(0.95, 0.91, 0.8)
const FERRO := Color(0.3, 0.31, 0.35)
const FERRO_CLARO := Color(0.62, 0.64, 0.7)
const ACO := Color(0.8, 0.83, 0.9)
const BARRO := Color(0.64, 0.38, 0.22)
const BARRO_ESCURO := Color(0.42, 0.24, 0.14)
const TERRA := Color(0.36, 0.28, 0.19)
const BAMBU := Color(0.66, 0.64, 0.34)
const FOLHA := Color(0.36, 0.44, 0.18)

static var _malhas := {}
static var _mats := {}


# --- Anel do chão ---------------------------------------------------------------------

## Anel de energia no chão embaixo da peça (substitui o toro chapado). Material
## guardado por paleta e jeito: todas as cópias dividem o mesmo.
## o: voltas (quantos rasgos), forca (0 liso .. 1 tracejado), banda, alfa, gira.
static func anel_chao(pai: Node3D, pal: Variant, raio: float, o: Dictionary = {}) -> MeshInstance3D:
	var chave := "anel|%s|%s" % [str(pal), str(o)]
	var m: ShaderMaterial = _mats.get(chave)
	if m == null:
		# Onde a máscara é 0 o ruído sozinho ainda passaria de 0 (a = m + (n-½)·f):
		# um pouco de `corroi` limpa o miolo e deixa só o anel.
		var f: float = o.get("forca", 0.7)
		m = Magia.mat(pal, {
			"escala": Vector2(o.get("voltas", 6.0), 0.5), "rola": Vector2(o.get("gira", 0.04), 0.0),
			"forca": f, "base": 1.0, "topo": 1.0, "corroi": 0.5 * f / (1.0 + 0.5 * f) + 0.04,
			"banda": o.get("banda", 0.11), "centro": 0.86, "tinta": 0.1, "alfa": o.get("alfa", 0.85),
		})
		_mats[chave] = m
	var mi := FxBase.malha(pai, Magia.disco(32), m)
	mi.name = "Anel"
	mi.position.y = o.get("y", 0.06)
	mi.scale = Vector3(raio, 1.0, raio)
	return mi


# --- Hitodama (espírito solto) --------------------------------------------------------

## Perfil da gota: (raio, altura, desvio para trás) em v (0 base .. 1 ponta).
static func _perfil_gota(v: float) -> Vector3:
	const ABRE := 0.62  # quanto da bola (em π) antes da cauda
	if v <= 0.5:
		var th := v / 0.5 * PI * ABRE
		return Vector3(sin(th), 1.0 - cos(th), 0.0)
	var t := (v - 0.5) / 0.5
	var r0 := sin(PI * ABRE)
	var y0 := 1.0 - cos(PI * ABRE)
	return Vector3(r0 * pow(1.0 - t, 1.5), y0 + t * 2.1, -0.6 * t * t)


## Gota de fogo-fátuo: bola de raio 1 embaixo e a cauda que sobe afinando e se
## curva para trás (-z), altura ≈ 3,5. U dá a volta, V sobe: o shader de
## energia rasga a ponta da cauda e o núcleo fica claro embaixo.
static func malha_gota() -> ArrayMesh:
	if _malhas.has("gota"):
		return _malhas["gota"]
	var st := MalhaPintada.novo()
	const SEG := 14
	const ANEIS := 14
	var linhas := []
	for j in ANEIS + 1:
		var v := float(j) / ANEIS
		var p := _perfil_gota(v)
		var e := 0.02
		var dp := _perfil_gota(minf(v + e, 1.0)) - _perfil_gota(maxf(v - e, 0.0))
		var linha := []
		for i in SEG + 1:
			var u := float(i) / SEG
			var dir := Vector3(cos(u * TAU), 0, sin(u * TAU))
			var nrm := (dir * dp.y - Vector3.UP * dp.x).normalized()
			if v <= 0.001:
				nrm = Vector3.DOWN
			linha.append([Vector3(0, p.y, p.z) + dir * p.x, nrm, Vector2(u, v)])
		linhas.append(linha)
	for j in ANEIS:
		for i in SEG:
			for k: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var q: Array = linhas[j + k.y][i + k.x]
				st.set_normal(q[1])
				st.set_uv(q[2])
				st.add_vertex(q[0])
	var m := st.commit()
	_malhas["gota"] = m
	return m


## Material da chama parada (3 variações de semente, divididas entre todas).
static func mat_hitodama(i: int, pal: Variant = PAL_HITODAMA) -> ShaderMaterial:
	var chave := "hito|%s|%d" % [str(pal), i % 3]
	if not _mats.has(chave):
		var m := _mat_chama(pal)
		m.set_shader_parameter("semente", 1.3 + 2.1 * (i % 3))
		_mats[chave] = m
	return _mats[chave]


static func _mat_chama(pal: Variant) -> ShaderMaterial:
	return Magia.mat(pal, {
		"escala": Vector2(2.0, 1.1), "rola": Vector2(0.05, -1.15), "forca": 0.85,
		"base": 1.08, "topo": -0.1, "fresnel": 0.55, "ondula": 0.07, "tinta": 0.06,
	})


## Chama (gota) de tamanho `r` (raio da bola) dentro de `pai`.
static func chama(pai: Node3D, r: float, m: Material) -> MeshInstance3D:
	var mi := FxBase.malha(pai, malha_gota(), m)
	mi.name = "Chama"
	mi.scale = Vector3.ONE * r
	return mi


## Visual do espírito (também o que vai na cabeça de quem carrega, o que voa
## para a máscara e os que orbitam a máscara). `orbitas` = duas chaminhas
## girando em volta (só o do chão: a raiz ganha o filho "Orbita" para girar).
static func hitodama(s := 1.0, orbitas := false) -> Node3D:
	var root := Node3D.new()
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var i := randi()
	chama(root, 0.42 * s, mat_hitodama(i))
	if orbitas and Magia.enfeite():
		var orb := Node3D.new()
		orb.name = "Orbita"
		orb.position.y = 0.42 * s
		root.add_child(orb)
		for k in 2:
			var c := chama(orb, 0.09 * s, mat_hitodama(i + 1 + k))
			var a := PI * k
			c.position = Vector3(cos(a) * 0.72 * s, 0.12 * s * (1 - 2 * k), sin(a) * 0.72 * s)
	return root


## Espírito pego: a chama estica para cima e se rasga, brasas e um anel verde.
## O que vai na cabeça de quem pegou dá um pulo (Unit.pulso_espirito).
static func hitodama_pego(g: Node, pos: Vector3) -> void:
	Magia.chama(g, pos + Vector3(0, 0.1, 0), PAL_HITODAMA, 0.45, 2.2, 0.45, {"segura": 0.15, "giro": 0.8})
	Magia.onda(g, pos, PAL_HITODAMA, 1.6, 0.4, {"banda": 0.16})
	Magia.brasas(g, pos, PAL_HITODAMA[1], 8, 0.4, 0.9)
	Sfx.play("hitodama_pega", pos, 0.1)


## Espírito preso na máscara: suspiro de faíscas subindo e dois anéis.
## `forte` = entregue na mão (feed); fraco = alma de abate chegando.
static func hitodama_preso(g: Node, pos: Vector3, forte := true) -> void:
	var alto := pos + Vector3(0, 1.4, 0)
	Magia.estouro(g, alto, PAL_HITODAMA, 1.1 if forte else 0.6, 0.4)
	Magia.anel_sobe(g, pos + Vector3(0, 0.2, 0), PAL_HITODAMA, 1.6 if forte else 1.0, 2.2, 0.9)
	Magia.brasas(g, alto, PAL_HITODAMA[0], 14 if forte else 6, 0.6, 1.4)
	if forte:
		Magia.anel_sobe(g, pos + Vector3(0, 0.2, 0), PAL_HITODAMA, 1.2, 1.6, 0.8, 0.12)
		Magia.onda(g, pos, PAL_HITODAMA, 2.8, 0.5)
	Sfx.play("hitodama_preso", pos, 0.06, 1.0 if forte else 1.25, 0.0 if forte else -6.0)


# --- Itens no chão ------------------------------------------------------------------

## Malha pintada do item (≈0,6 m, origem no meio do objeto).
static func malha_item(kind: String) -> ArrayMesh:
	var chave := "item_" + kind
	if _malhas.has(chave):
		return _malhas[chave]
	var m: ArrayMesh
	match kind:
		"pocao":
			m = _malha_cabaca()
		"escudo":
			m = _malha_leque()
		"velocidade":
			m = _malha_geta()
		"dano":
			m = _malha_kunais()
		_:
			m = _malha_pergaminho()
	_malhas[chave] = m
	return m


## Poção: cabaça (hyōtan) laqueada de vermelho com cordão dourado na cintura,
## rolha e uma etiqueta de papel pendurada.
static func _malha_cabaca() -> ArrayMesh:
	var st := MalhaPintada.novo()
	MalhaPintada.bola(st, Vector3(0, -0.1, 0), 0.22, Vector3(1, 0.92, 1), LACA, 0.0, 0.55, 12, 7)
	MalhaPintada.bola(st, Vector3(0, 0.16, 0), 0.14, Vector3(1, 1.05, 1), LACA.lightened(0.12), 0.0, 0.7, 10, 6)
	MalhaPintada.corda(st, Vector3(0, 0.05, 0), 0.1, 0.024, OURO, 14, 5)
	MalhaPintada.tubo(st, [Vector3(0, 0.27, 0), Vector3(0, 0.32, 0)], 0.055, 0.05, LACA.darkened(0.2), LACA, 8)
	MalhaPintada.tubo(st, [Vector3(0, 0.31, 0), Vector3(0, 0.4, 0)], 0.06, 0.05, MADEIRA, MADEIRA.lightened(0.15), 8)
	# Borla do cordão e a etiqueta.
	MalhaPintada.tubo(st, [Vector3(0.09, 0.05, 0.05), Vector3(0.13, -0.02, 0.09), Vector3(0.14, -0.12, 0.1)], 0.014, 0.01, OURO, OURO.darkened(0.2), 4)
	var sub := MalhaPintada.novo()
	MalhaPintada.placa(sub, [Vector2(-0.045, -0.07), Vector2(0.045, -0.07), Vector2(0.045, 0.07), Vector2(-0.045, 0.07)], 0.008, PAPEL, PAPEL.darkened(0.15))
	MalhaPintada.placa(sub, [Vector2(-0.025, -0.04), Vector2(0.025, -0.04), Vector2(0.025, 0.03), Vector2(-0.025, 0.03)], 0.012, Color(0.8, 0.12, 0.12), Color(0.6, 0.1, 0.1))
	st.append_from(sub.commit(), 0, Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.BACK, 0.12), Vector3(0.15, -0.18, 0.11)))
	return MalhaPintada.fim(st)


## Escudo: leque de guerra (gunbai) de laca escura com borda dourada, o
## emblema janome (olho de serpente) azul e o cabo de madeira com borla.
static func _malha_leque() -> ArrayMesh:
	var st := MalhaPintada.novo()
	var pa := []
	for i in 13:
		var a := deg_to_rad(-48.0 + 276.0 * i / 12.0)
		pa.append(Vector2(0, 0.08) + Vector2(cos(a), sin(a)) * 0.25)
	pa.append(Vector2(-0.055, -0.22))
	pa.append(Vector2(0.055, -0.22))
	var borda := []
	for p: Vector2 in pa:
		borda.append(Vector2(0, 0.08) + (p - Vector2(0, 0.08)) * 1.1)
	MalhaPintada.placa(st, borda, 0.025, OURO, OURO.darkened(0.25))
	var sub := MalhaPintada.novo()
	MalhaPintada.placa(sub, pa, 0.04, Color(0.13, 0.1, 0.15), Color(0.08, 0.06, 0.1))
	MalhaPintada.placa(sub, MalhaPintada.circulo(Vector2(0, 0.08), 0.13), 0.05, Color(0.32, 0.74, 1.0), Color(0.2, 0.5, 0.8))
	MalhaPintada.placa(sub, MalhaPintada.circulo(Vector2(0, 0.08), 0.085), 0.056, Color(0.13, 0.1, 0.15), Color(0.08, 0.06, 0.1))
	MalhaPintada.placa(sub, MalhaPintada.circulo(Vector2(0, 0.08), 0.04, 10), 0.062, Color(0.85, 0.95, 1.0), Color(0.5, 0.7, 0.9))
	st.append_from(sub.commit(), 0, Transform3D.IDENTITY)
	MalhaPintada.tubo(st, [Vector3(0, -0.2, 0), Vector3(0, -0.5, 0)], 0.026, 0.022, MADEIRA, MADEIRA_ESCURA, 6)
	MalhaPintada.tubo(st, [Vector3(0, -0.5, 0), Vector3(0, -0.53, 0)], 0.034, 0.03, OURO, OURO.darkened(0.2), 6)
	MalhaPintada.tubo(st, [Vector3(0, -0.53, 0), Vector3(0.03, -0.6, 0.02), Vector3(0.05, -0.68, 0.03)], 0.014, 0.008, Color(0.85, 0.15, 0.15), Color(0.6, 0.08, 0.08), 4)
	return MalhaPintada.fim(st)


## Velocidade: tamanca geta de madeira clara com dois dentes e a tira (hanao)
## amarela, deitada (frente = -z).
static func _malha_geta() -> ArrayMesh:
	var st := MalhaPintada.novo()
	var pts := []
	for i in 16:
		var a := TAU * i / 16.0
		var p := Vector2(cos(a) * 0.12, sin(a) * 0.23)
		p.x = clampf(p.x * 1.25, -0.11, 0.11)  # quase retângulo de cantos redondos
		p.y = clampf(p.y * 1.15, -0.22, 0.22)
		pts.append(p)
	var sub := MalhaPintada.novo()
	MalhaPintada.placa(sub, pts, 0.045, MADEIRA.lightened(0.18), MADEIRA)
	st.append_from(sub.commit(), 0, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.02, 0)))
	for z in [-0.12, 0.11]:
		MalhaPintada.caixa(st, Vector3(0, -0.04, z), Vector3(0.1, 0.045, 0.022), Basis.IDENTITY, MADEIRA_ESCURA, 0.0, Vector2(0.6, 0.85))
	var tira := Color(1.0, 0.8, 0.2)
	var furo := Vector3(0, 0.05, -0.15)
	for s in [-1.0, 1.0]:
		MalhaPintada.tubo(st, [furo, Vector3(0.04 * s, 0.11, -0.08), Vector3(0.08 * s, 0.1, 0.0), Vector3(0.1 * s, 0.05, 0.05)], 0.02, 0.018, tira, tira.darkened(0.2), 5)
	MalhaPintada.bola(st, furo + Vector3(0, 0.01, 0), 0.03, Vector3(1, 0.7, 1), Color(0.85, 0.2, 0.15), 0.0, 0.7, 6, 3)
	return MalhaPintada.fim(st)


## Uma kunai em pé (ponta em +y): lâmina de folha, cabo com cordão vermelho e
## o aro no pé.
static func _kunai() -> ArrayMesh:
	var st := MalhaPintada.novo()
	MalhaPintada.placa(st, [Vector2(0, 0.32), Vector2(0.055, 0.12), Vector2(0.03, 0.0), Vector2(-0.03, 0.0), Vector2(-0.055, 0.12)], 0.018, ACO, FERRO_CLARO)
	MalhaPintada.tubo(st, [Vector3(0, 0.12, 0), Vector3(0, 0.3, 0)], 0.013, 0.004, FERRO_CLARO.darkened(0.2), FERRO_CLARO.darkened(0.2), 4)
	MalhaPintada.tubo(st, [Vector3(0, 0.0, 0), Vector3(0, -0.15, 0)], 0.019, 0.017, Color(0.7, 0.1, 0.1), Color(0.55, 0.08, 0.08), 6)
	for y in [-0.03, -0.075, -0.12]:
		MalhaPintada.tubo(st, [Vector3(0, y - 0.008, 0), Vector3(0, y + 0.008, 0)], 0.023, 0.023, Color(0.42, 0.05, 0.06), Color(0.42, 0.05, 0.06), 6)
	MalhaPintada.aro(st, Vector3(0, -0.2, 0), 0.045, 0.011, FERRO)
	return st.commit()


## Dano dobrado: duas kunais cruzadas.
static func _malha_kunais() -> ArrayMesh:
	var k := _kunai()
	return MalhaUnica.pecas([
		[k, Transform3D(Basis(Vector3.BACK, 0.62), Vector3(0.0, 0.0, 0.012))],
		[k, Transform3D(Basis(Vector3.BACK, -0.62), Vector3(0.0, 0.0, -0.012))],
	])


## Poder cheio: pergaminho (makimono) de seda roxa meio aberto, a folha de
## papel pendurada com o selo e três pinceladas, varetas de madeira.
static func _malha_pergaminho() -> ArrayMesh:
	var st := MalhaPintada.novo()
	var seda := Color(0.48, 0.2, 0.72)
	MalhaPintada.tubo(st, [Vector3(-0.2, 0.08, 0), Vector3(0.2, 0.08, 0)], 0.065, 0.065, seda, seda.lightened(0.1), 10)
	MalhaPintada.tubo(st, [Vector3(-0.19, 0.08, 0), Vector3(-0.2, 0.08, 0)], 0.064, 0.064, seda, seda, 10)
	for s in [-1.0, 1.0]:
		MalhaPintada.tubo(st, [Vector3(0.2 * s, 0.08, 0), Vector3(0.25 * s, 0.08, 0)], 0.022, 0.022, MADEIRA_ESCURA, MADEIRA_ESCURA, 6)
		MalhaPintada.bola(st, Vector3(0.265 * s, 0.08, 0), 0.032, Vector3(1, 1, 1), OURO, 0.0, 0.7, 6, 3)
		MalhaPintada.tubo(st, [Vector3(0.17 * s, 0.08, 0), Vector3(0.185 * s, 0.08, 0)], 0.07, 0.07, OURO, OURO, 10)
	# Folha aberta pendurada e o que está escrito nela.
	MalhaPintada.caixa(st, Vector3(0, -0.12, 0.05), Vector3(0.16, 0.17, 0.006), Basis.IDENTITY, PAPEL, 0.0, Vector2(0.85, 1.0))
	var selo := MalhaPintada.novo()
	MalhaPintada.placa(selo, MalhaPintada.circulo(Vector2(0, -0.17), 0.065), 0.01, Color(0.55, 0.16, 0.8), Color(0.4, 0.1, 0.6))
	MalhaPintada.placa(selo, MalhaPintada.circulo(Vector2(0, -0.17), 0.035, 10), 0.016, Color(0.95, 0.85, 1.0), Color(0.6, 0.4, 0.8))
	st.append_from(selo.commit(), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.058)))
	for k in 3:
		var x := -0.11 + k * 0.03
		MalhaPintada.caixa(st, Vector3(x if k < 2 else 0.11, -0.04 - 0.01 * k, 0.058), Vector3(0.007, 0.06 - 0.012 * k, 0.003), Basis.IDENTITY, Color(0.1, 0.07, 0.1), 0.0, Vector2(1.0, 1.0))
	MalhaPintada.tubo(st, [Vector3(0.02, 0.02, 0.065), Vector3(0.05, -0.08, 0.08), Vector3(0.04, -0.2, 0.09)], 0.011, 0.008, OURO, seda, 4)
	return MalhaPintada.fim(st)


## Energia de cada item (o "brilho" que diz o que ele faz). Devolve a malha e o
## material novo (anima `corroi` quando é pego).
static func energia_item(pai: Node3D, kind: String) -> MeshInstance3D:
	var pal: Array = PAL_ITEM[kind]
	var mi: MeshInstance3D
	match kind:
		"pocao":
			# Vapor rosado saindo da rolha.
			mi = FxBase.malha(pai, malha_gota(), _mat_chama(pal))
			mi.scale = Vector3.ONE * 0.075
			mi.position = Vector3(0, 0.38, 0)
		"escudo":
			# Aro de guarda girando atrás do leque.
			mi = FxBase.malha(pai, Magia.disco(32), Magia.mat(pal, {"escala": Vector2(5.0, 0.5), "rola": Vector2(0.25, 0.0), "forca": 0.6,
					"base": 0.95, "topo": 0.95, "banda": 0.13, "centro": 0.84, "tinta": 0.09}))
			mi.rotation.x = PI * 0.5
			mi.position = Vector3(0, 0.08, -0.05)
			mi.scale = Vector3.ONE * 0.4
		"velocidade":
			# Redemoinho de vento em volta da tamanca.
			mi = FxBase.malha(pai, Magia.tubo(1.0, 0.0, 20, 2), Magia.mat(pal, {"escala": Vector2(2.0, 1.0), "rola": Vector2(1.3, 0.0), "forca": 1.1,
					"base": 0.9, "topo": 0.9, "banda": 0.32, "centro": 0.5, "tinta": 0.08, "teto": 1.5}))
			mi.scale = Vector3(0.36, 0.3, 0.36)
			mi.position = Vector3(0, -0.12, 0)
			mi.rotation.z = 0.25
		"dano":
			# Talho em X atrás das kunais (o rastro do corte).
			mi = FxBase.malha(pai, _malha_talho(), Magia.mat(pal, {"escala": Vector2(2.0, 1.0), "rola": Vector2(-1.6, 0.0), "forca": 0.8,
					"base": 1.0, "topo": 1.0, "banda": 0.5, "centro": 0.5, "lados": 1.0, "tinta": 0.08}))
			mi.position = Vector3(0, 0.05, -0.05)
		_:
			# Três chaminhas de chi dançando em cima do rolo.
			mi = FxBase.malha(pai, _malha_tres_chamas(), _mat_chama(pal))
			mi.position = Vector3(0, 0.13, 0)
	mi.name = "Energia"
	return mi


## Dois quads cruzados em X no plano XY (U ao longo do talho, V de lado a lado).
static func _malha_talho() -> ArrayMesh:
	if _malhas.has("talho"):
		return _malhas["talho"]
	var st := MalhaPintada.novo()
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.BACK, 0.62 * s)
		var c := [Vector3(-0.42, -0.06, 0), Vector3(0.42, -0.06, 0), Vector3(0.42, 0.06, 0), Vector3(-0.42, 0.06, 0)]
		var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.BACK)
			st.set_uv(uv[i])
			st.add_vertex(b * (c[i] as Vector3) + Vector3(0, 0, 0.004 * s))
	var m := st.commit()
	_malhas["talho"] = m
	return m


static func _malha_tres_chamas() -> ArrayMesh:
	if _malhas.has("tres_chamas"):
		return _malhas["tres_chamas"]
	var g := malha_gota()
	var m := MalhaUnica.pecas([
		[g, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.05), Vector3(-0.12, 0, 0))],
		[g, Transform3D(Basis(Vector3.UP, 1.4).scaled(Vector3.ONE * 0.065), Vector3(0, 0.01, 0))],
		[g, Transform3D(Basis(Vector3.UP, 2.6).scaled(Vector3.ONE * 0.05), Vector3(0.12, 0, 0))],
	])
	_malhas["tres_chamas"] = m
	return m


## O item caiu do céu e assentou no chão.
static func item_assenta(g: Node, pos: Vector3, kind: String) -> void:
	if not is_instance_valid(g):
		return
	Magia.onda(g, pos, PAL_ITEM[kind], 1.4, 0.35, {"banda": 0.18})
	Sfx.play("item_cai", pos, 0.1, 1.0, -4.0)


## Item pego: o objeto se desfaz em energia na cor dele, espirra a peça do
## tema (gota, lasca, nuvem, faísca, papel) e um anel sobe em quem pegou.
static func item_pego(g: Node, pos: Vector3, kind: String, u: Unit) -> void:
	var pal: Array = PAL_ITEM[kind]
	Magia.estouro(g, pos, pal, 0.9, 0.3)
	Assinatura.pecas(g, pos, PECA_ITEM[kind], (pal[1] as Color).lightened(0.2), 8, {"tam": 0.8})
	if is_instance_valid(u):
		Magia.anel_sobe(g, u.global_position + Vector3(0, 0.15, 0), pal, 1.0, 1.8, 0.7)
		Magia.brasas(g, u.global_position + Vector3(0, 0.6, 0), pal[0], 6, 0.4, 0.9)
	Sfx.play(SOM_ITEM[kind], pos, 0.05)


# --- Armadilhas do Construtor ----------------------------------------------------------

## Um makibishi: quatro pontas de ferro (tetraedro) com uma sempre para cima.
static func _makibishi(st: SurfaceTool, c: Vector3, giro: float, tam := 0.11) -> void:
	var dirs := [Vector3.UP]
	var cs := -1.0 / 3.0
	var sn := sqrt(1.0 - cs * cs)
	for k in 3:
		var a := giro + TAU * k / 3.0
		dirs.append(Vector3(cos(a) * sn, cs, sin(a) * sn))
	for d: Vector3 in dirs:
		MalhaPintada.tubo(st, [c, c + d * tam], 0.022, 0.002, FERRO, FERRO_CLARO, 4)


## Estrepes: tabuinha de bambu meio enterrada com makibishi espalhados, folhas
## por cima e a estaca com a fita do time (aliado sabe de quem é).
static func malha_estrepes(cor_time: Color, variacao: int) -> ArrayMesh:
	var chave := "estrepes_%s_%d" % [cor_time.to_html(), variacao]
	if _malhas.has(chave):
		return _malhas[chave]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7100 + variacao
	var st := MalhaPintada.novo()
	var giro := rng.randf() * TAU
	var eixo := Vector3(cos(giro), 0, sin(giro))
	var lado := Vector3(-eixo.z, 0, eixo.x)
	# Tabuinha: quatro varas de bambu, uma ponta enterrada.
	for k in 4:
		var o := lado * (k - 1.5) * 0.075
		var a := o - eixo * 0.42 + Vector3(0, -0.02, 0)
		var b := o + eixo * 0.42 + Vector3(0, 0.05, 0)
		MalhaPintada.tubo(st, [a, b], 0.036, 0.034, BAMBU.darkened(0.12 * (k % 2)), BAMBU.lightened(0.08), 6, Vector2.ZERO, Vector2(0.55, 0.9))
		for t in [0.3, 0.72]:
			var p := a.lerp(b, t)
			MalhaPintada.tubo(st, [p - eixo * 0.008, p + eixo * 0.008], 0.039, 0.039, BAMBU.darkened(0.3), BAMBU.darkened(0.3), 6)
	# Makibishi: três na tábua, quatro no chão em volta.
	for k in 7:
		var p: Vector3
		if k < 3:
			p = eixo * (k - 1) * 0.26 + lado * rng.randf_range(-0.08, 0.08) + Vector3(0, 0.07 + (k - 1) * 0.01 + 0.037, 0)
		else:
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.45, 0.9)
			p = Vector3(cos(a) * r, 0.037, sin(a) * r)
		_makibishi(st, p, rng.randf() * TAU)
	# Folhas jogadas por cima (balançam no vento do pintado).
	for k in 3:
		var a := rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.1, 0.5) + Vector3(0, 0.09, 0)
		MalhaPintada.bola(st, p, 0.11, Vector3(1.0, 0.12, 0.45), FOLHA.lerp(Color(0.55, 0.42, 0.18), rng.randf()), 0.35, 0.75, 6, 2)
	# Estaca com a fita do time.
	var e := eixo * 0.55 + lado * 0.22
	MalhaPintada.tubo(st, [e, e + Vector3(0, 0.42, 0)], 0.022, 0.016, BAMBU.darkened(0.2), BAMBU, 5)
	MalhaPintada.caixa(st, e + Vector3(0.07, 0.34, 0), Vector3(0.07, 0.04, 0.008), Basis(Vector3.BACK, -0.25), cor_time, 0.0, Vector2(0.8, 1.0), 0.6)
	MalhaPintada.caixa(st, e + Vector3(0.05, 0.24, 0), Vector3(0.012, 0.07, 0.006), Basis(Vector3.BACK, 0.1), PAPEL, 0.0, Vector2(0.8, 1.0), 0.5)
	var m := MalhaPintada.fim(st)
	_malhas[chave] = m
	return m


## Mina: panela de pólvora (horokudama) de barro meio enterrada, corda do time
## na barriga, selo de papel colado, tampa e o estopim. Brasa é peça à parte.
static func malha_mina(cor_time: Color) -> ArrayMesh:
	var chave := "mina_" + cor_time.to_html()
	if _malhas.has(chave):
		return _malhas[chave]
	var st := MalhaPintada.novo()
	MalhaPintada.bola(st, Vector3(0, 0.14, 0), 0.25, Vector3(1, 0.82, 1), BARRO, 0.0, 0.45, 12, 7)
	MalhaPintada.corda(st, Vector3(0, 0.17, 0), 0.245, 0.024, cor_time, 18, 5)
	MalhaPintada.tubo(st, [Vector3(0, 0.3, 0), Vector3(0, 0.37, 0)], 0.09, 0.08, BARRO_ESCURO, BARRO, 10)
	MalhaPintada.bola(st, Vector3(0, 0.37, 0), 0.085, Vector3(1, 0.4, 1), BARRO_ESCURO.darkened(0.2), 0.0, 0.8, 8, 3)
	MalhaPintada.caixa(st, Vector3(0, 0.07, 0.238), Vector3(0.062, 0.06, 0.006), Basis(Vector3.RIGHT, 0.35), PAPEL, 0.0, Vector2(0.8, 1.0))
	MalhaPintada.caixa(st, Vector3(0, 0.08, 0.246), Vector3(0.026, 0.026, 0.004), Basis(Vector3.RIGHT, 0.35), Color(0.82, 0.12, 0.1), 0.0, Vector2(0.8, 1.0))
	MalhaPintada.tubo(st, [Vector3(0, 0.4, 0), Vector3(0.04, 0.47, 0), Vector3(0.1, 0.51, 0), Vector3(0.15, 0.5, 0)], 0.014, 0.011, Color(0.22, 0.16, 0.1), Color(0.3, 0.22, 0.14), 4)
	# Torrões de terra em volta (de quem acabou de enterrar).
	for k in 5:
		var a := TAU * k / 5.0 + 0.4
		MalhaPintada.bola(st, Vector3(cos(a), 0, sin(a)) * 0.3 + Vector3(0, 0.01, 0), 0.09, Vector3(1, 0.45, 0.8), TERRA.lightened(0.05 * (k % 2)), 0.0, 0.6, 6, 3)
	var m := MalhaPintada.fim(st)
	_malhas[chave] = m
	return m


const PONTA_ESTOPIM := Vector3(0.15, 0.5, 0)


## Brasa do estopim (energia "brasa"): anima o tamanho no dono (Trap._process).
static func brasa(pai: Node3D) -> MeshInstance3D:
	var chave := "brasa_estopim"
	if not _mats.has(chave):
		_mats[chave] = Magia.mat("brasa", {"escala": Vector2(2.0, 1.0), "rola": Vector2(0.4, -1.5), "forca": 0.6, "base": 1.1, "topo": 0.6, "fresnel": 0.5})
	var mi := FxBase.malha(pai, malha_gota(), _mats[chave])
	mi.name = "Brasa"
	mi.position = PONTA_ESTOPIM
	mi.scale = Vector3.ONE * 0.035
	return mi


## Armadilha posta: poeira e lascas de terra (estrepes tinem no chão).
static func armadilha_arma(g: Node, pos: Vector3, mina: bool) -> void:
	FxProjetil.fumaca(g, pos + Vector3(0, 0.15, 0), Color(0.55, 0.47, 0.36, 0.55), 4, 0.5, 0.6, 0.6)
	if mina:
		Assinatura.pecas(g, pos + Vector3(0, 0.2, 0), "cinza", TERRA.lightened(0.2), 4, {"tam": 0.6})
	else:
		FxProjetil.faiscas(g, pos + Vector3(0, 0.1, 0), FERRO_CLARO.lightened(0.3), 5, 3.0, Vector3.UP, 70.0, 0.12)


## Estrepes pisados: os makibishi espirram, faísca de ferro e o anel do time
## pisca vermelho.
static func estrepes_fisga(g: Node, pos: Vector3, dir: Vector3) -> void:
	Assinatura.pecas(g, pos + Vector3(0, 0.25, 0), "estrepe", FERRO_CLARO.lightened(0.2), 7, {"tam": 0.6})
	FxProjetil.faiscas(g, pos + Vector3(0, 0.3, 0), Color(1.0, 0.85, 0.6), 8, 5.0, dir + Vector3.UP, 60.0, 0.16)
	Magia.onda(g, pos, "brasa", 1.3, 0.3, {"banda": 0.12})
	Sfx.play("estrepe_fisga", pos, 0.12)


## Mina explodindo: cacos de barro além da explosão de sempre.
static func mina_estoura(g: Node, pos: Vector3) -> void:
	Assinatura.pecas(g, pos + Vector3(0, 0.4, 0), "caco", BARRO.lightened(0.1), 10, {"tam": 0.9, "v1": 9.0})


## Armadilha que venceu (ou a mais antiga, trocada): afunda no chão soltando
## poeira; a mina apaga o estopim com um fiapo de fumaça. `v` já foi solto do
## dono e é apagado aqui.
static func armadilha_some(g: Node, v: Node3D, mina: bool) -> void:
	var pos := v.global_position
	FxProjetil.fumaca(g, pos + Vector3(0, 0.15, 0), Color(0.55, 0.5, 0.42, 0.5), 3, 0.45, 0.7, 0.5)
	if mina:
		FxProjetil.fumaca(g, v.global_transform * PONTA_ESTOPIM, Color(0.4, 0.38, 0.4, 0.6), 2, 0.2, 0.9, 1.2)
	var tw := v.create_tween().set_parallel()
	tw.tween_property(v, "position:y", v.position.y - 0.4, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(v, "scale", v.scale * Vector3(1.1, 0.5, 1.1), 0.7)
	tw.chain().tween_callback(v.queue_free)
	Sfx.play("armadilha_some", pos, 0.1, 1.0, -6.0)
