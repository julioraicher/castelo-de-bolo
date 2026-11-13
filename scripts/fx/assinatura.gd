class_name Assinatura
extends RefCounted
## Assinatura visual de cada personagem (Ciclo 2.24): o que faz o poder de um
## não parecer o do outro. Quatro peças, todas tiradas dos atlas de campo de
## distância de `tools/assinaturas/` (1 chamada de desenho cada, somem sozinhas):
##  - `selo`: o desenho do personagem no chão, com SILHUETA própria (nem todo
##    selo é um círculo) e VERBO próprio de aparecer (pincel, carimbo, ondas,
##    mordida, queima, espiral, névoa, risco). O brilho em volta é a cor do time.
##  - `figura`: desenho em pé, de frente para a câmera (máscara oni, sino, olho,
##    asas...). É o que abre o R.
##  - `pecas`: partículas com forma (pena, folha, sal, talismã, nota...).
##  - `hanko`: o carimbo vermelho com o emblema ao lado do nome do golpe.
## Quem chama: `FxPoder.lancar` (E), `Unit._use_super` (R) e o Q (`toque_q`).
## Tamanhos (quiz 4C): E 15% maior que antes, R maior que tudo.
## Só visual: dano, raio e tempo continuam em Unit/Herois.

const SH_SELO := preload("res://assets/shaders/assinatura_selo.gdshader")
const SH_PECA := preload("res://assets/shaders/assinatura_peca.gdshader")
const SH_EMBLEMA := preload("res://assets/shaders/assinatura_emblema.gdshader")
const ATLAS := preload("res://assets/fx/assinaturas/selos.png")
const ATLAS_PECAS := preload("res://assets/fx/assinaturas/pecas.png")
const COLS := 7   # atlas dos selos e figuras: 7 x 7 (25 selos + 21 figuras)
const PCOLS := 5  # atlas das peças: 5 x 5 (22 peças)
## Ordem das células: a mesma de tools/assinaturas/desenhos.js.
const SELOS: Array[StringName] = [&"guerreiro", &"ronin_oni", &"sohei", &"arqueiro", &"arqueiro_yumi", &"kusarigama", &"kitsune", &"kitsune_luz", &"kitsune_sombria", &"construtor", &"armadilheiro", &"bombardeiro", &"sumotori", &"kappa", &"yamabushi", &"karasu_tengu", &"mujina", &"onmyoji", &"tennin", &"komuso", &"ochimusha", &"shishimai", &"jorogumo", &"kodama", &"kaminari_kozo"]
const FIGURAS: Array[String] = ["pincelada", "oni", "sino", "sombra", "olho", "raposa", "olhos", "andaime", "explosao", "leque", "asas", "rosto", "grou", "nota", "halo", "shide", "caidos", "leao", "aranha", "arvore", "tambores"]
const PECAS: Array[String] = ["pena", "folha", "papel", "nota", "conta", "gota", "sal", "petala", "caco", "estrepe", "estrela", "elo", "shuriken", "chama", "lasca", "grou", "cinza", "confete", "fio", "nuvem", "semente", "faisca"]

const RAIO_R := 7.0     # selo do super: maior que qualquer selo de E
const HANKO_COR := Color(0.82, 0.13, 0.1)
const PAPEL := Color(1.0, 0.96, 0.86)

## Verbos: [revela (volta, raio, ruído, esquerda→direita), de fora para dentro, tempo de escrita].
const VERBO := {
	"pincel": [Vector4(1.0, 0.0, 0.12, 0.0), false, 0.24],
	"carimbo": [Vector4(0.0, 0.0, 1.0, 0.0), false, 0.06],
	"ondas": [Vector4(0.0, 1.0, 0.1, 0.0), false, 0.3],
	"morde": [Vector4(0.0, 1.0, 0.1, 0.0), true, 0.2],
	"queima": [Vector4(0.0, 0.6, 0.5, 0.0), false, 0.32],
	"espiral": [Vector4(0.45, 1.0, 0.0, 0.0), false, 0.32],
	"nevoa": [Vector4(0.0, 0.0, 1.0, 0.0), false, 0.35],
	"risco": [Vector4(0.0, 0.0, 0.1, 1.0), false, 0.22],
	"racha": [Vector4(0.0, 0.25, 0.85, 0.0), true, 0.14],   # Ochimusha: aparece aos pedaços, de fora para dentro
	"estala": [Vector4(0.0, 1.0, 0.3, 0.0), false, 0.1],    # Shishimai: estalo do centro para fora
	"tece": [Vector4(0.7, 0.6, 0.0, 0.0), false, 0.4],      # Jorogumo: girando, como fio enrolando
}

## Um por personagem. pal: paleta do kit Magia (nome ou [núcleo, meio, borda]);
## verbo: como o selo aparece; peca/peca_cor: a partícula dele; giro: voltas/s
## do selo; pulso: ondas correndo no traço; flash: cor do clarão de tela no R.
const DADOS := {
	&"guerreiro": {"pal": [Color(1, 1, 1), Color(1.0, 0.88, 0.5), Color(0.78, 0.5, 0.16)], "verbo": "pincel", "peca": "lasca", "peca_cor": Color(0.95, 0.97, 1.0), "giro": 0.04},
	&"ronin_oni": {"pal": "brasa", "verbo": "queima", "peca": "caco", "peca_cor": Color(1.0, 0.5, 0.15), "giro": 0.0},
	&"sohei": {"pal": [Color(1.0, 0.98, 0.86), Color(0.96, 0.8, 0.4), Color(0.2, 0.62, 0.55)], "verbo": "ondas", "peca": "conta", "peca_cor": Color(1.0, 0.88, 0.5), "giro": 0.05},
	&"arqueiro": {"pal": [Color(1, 1, 1), Color(0.45, 0.95, 1.0), Color(0.1, 0.5, 0.75)], "verbo": "carimbo", "peca": "shuriken", "peca_cor": Color(0.82, 0.97, 1.0), "giro": 0.55},
	&"arqueiro_yumi": {"pal": [Color(1.0, 1.0, 0.92), Color(1.0, 0.84, 0.45), Color(0.6, 0.38, 0.15)], "verbo": "morde", "peca": "lasca", "peca_cor": Color(1.0, 0.9, 0.6), "giro": 0.0, "flash": Color(0.06, 0.04, 0.12)},
	&"kusarigama": {"pal": [Color(1, 1, 1), Color(0.64, 0.7, 1.0), Color(0.25, 0.3, 0.8)], "verbo": "pincel", "peca": "elo", "peca_cor": Color(0.82, 0.87, 1.0), "giro": 0.3},
	&"kitsune": {"pal": "raposa_rosa", "alfa": 0.82, "verbo": "carimbo", "peca": "chama", "peca_cor": Color(1.0, 0.58, 0.82), "giro": 0.0},
	&"kitsune_luz": {"pal": "luz", "verbo": "ondas", "peca": "petala", "peca_cor": Color(1.0, 0.9, 0.55), "giro": 0.06},
	&"kitsune_sombria": {"pal": "sombra", "verbo": "morde", "peca": "chama", "peca_cor": Color(0.72, 0.42, 1.0), "giro": -0.05},
	&"construtor": {"pal": [Color(1.0, 1.0, 0.9), Color(1.0, 0.74, 0.32), Color(0.75, 0.4, 0.1)], "verbo": "risco", "peca": "lasca", "peca_cor": Color(0.88, 0.62, 0.32), "giro": 0.0},
	&"armadilheiro": {"pal": "veneno", "verbo": "morde", "peca": "estrepe", "peca_cor": Color(0.78, 0.96, 0.62), "giro": 0.0},
	&"bombardeiro": {"pal": [Color(1.0, 0.98, 0.8), Color(1.0, 0.6, 0.15), Color(0.8, 0.15, 0.05)], "verbo": "morde", "peca": "estrela", "peca_cor": Color(1.0, 0.78, 0.3), "giro": 0.0},
	&"sumotori": {"pal": "sal", "traco": Color(0.93, 0.74, 0.36), "verbo": "carimbo", "peca": "sal", "peca_cor": Color(1.0, 1.0, 0.96), "giro": 0.0},
	&"kappa": {"pal": "agua", "verbo": "ondas", "peca": "gota", "peca_cor": Color(0.62, 0.9, 1.0), "giro": 0.03, "pulso": 1.0},
	&"yamabushi": {"pal": [Color(1.0, 0.96, 0.8), Color(1.0, 0.6, 0.2), Color(0.8, 0.15, 0.1)], "verbo": "espiral", "peca": "folha", "peca_cor": Color(1.0, 0.45, 0.15), "giro": 0.3},
	&"karasu_tengu": {"pal": "pena", "traco": Color(0.5, 0.4, 0.85), "verbo": "espiral", "peca": "pena", "peca_cor": Color(0.44, 0.36, 0.74), "giro": -0.28, "flash": Color(0.08, 0.05, 0.16)},
	&"mujina": {"pal": "nevoa", "traco": Color(0.7, 0.56, 0.95), "verbo": "nevoa", "peca": "caco", "peca_cor": Color(0.92, 0.88, 1.0), "giro": 0.0},
	&"onmyoji": {"pal": "papel", "traco": Color(0.88, 0.26, 0.2), "verbo": "pincel", "peca": "papel", "peca_cor": Color(1.0, 0.97, 0.88), "giro": 0.05},
	&"tennin": {"pal": "celeste", "verbo": "espiral", "peca": "petala", "peca_cor": Color(1.0, 0.76, 0.86), "giro": 0.2},
	&"komuso": {"pal": "som", "verbo": "ondas", "peca": "nota", "peca_cor": Color(0.72, 1.0, 0.93), "giro": 0.0, "pulso": 1.0},
	&"ochimusha": {"pal": "fantasma", "verbo": "racha", "peca": "cinza", "peca_cor": Color(0.62, 0.8, 1.0), "giro": -0.03, "flash": Color(0.04, 0.06, 0.14)},
	&"shishimai": {"pal": "festa", "traco": Color(0.86, 0.16, 0.18), "verbo": "estala", "peca": "confete", "peca_cor": Color(1.0, 0.82, 0.3), "giro": 0.12},
	&"jorogumo": {"pal": "seda", "traco": Color(0.62, 0.2, 0.38), "verbo": "tece", "peca": "fio", "peca_cor": Color(0.96, 0.94, 1.0), "giro": 0.08},
}

## Jeitos de a peça se mexer (chaves do FxProjetil.ps + gira, vira, tam).
const MOVS := {
	"espirra": {"spread": 55.0, "v0": 4.0, "v1": 8.5, "g": Vector3(0, -17, 0), "s0": 0.8, "s1": 1.35, "vida": 0.95, "gira": 520.0, "esfera": 0.4},
	"cai": {"spread": 75.0, "v0": 2.2, "v1": 5.5, "g": Vector3(0, -3.4, 0), "amort": 2.4, "s0": 0.85, "s1": 1.4, "vida": 1.7, "gira": 150.0, "vira": 2.5, "esfera": 0.6},
	"sobe": {"spread": 35.0, "v0": 1.0, "v1": 2.8, "g": Vector3(0, 1.1, 0), "amort": 0.6, "s0": 0.75, "s1": 1.25, "vida": 1.4, "gira": 50.0, "rampa": "nasce", "esfera": 0.7},
}
const MOV := {"pena": "cai", "folha": "cai", "papel": "cai", "petala": "cai", "nota": "sobe", "conta": "sobe", "chama": "sobe", "grou": "sobe", "cinza": "sobe", "confete": "cai", "fio": "cai", "nuvem": "sobe", "semente": "cai", "faisca": "espirra"}

static var _cache := {}
static var _sh_frente: Shader  # mesmo selo, sem teste de profundidade (hanko junto do nome)


# --- Consulta ---------------------------------------------------------------------

static func _id(quem: Variant) -> StringName:
	if quem is Unit:
		return (quem as Unit).stats.id
	return StringName(str(quem))


## Dados do personagem ({} = sem assinatura: usa o selo genérico do kit).
static func de(quem: Variant) -> Dictionary:
	return DADOS.get(_id(quem), {})


static func paleta(quem: Variant) -> Array:
	var d := de(quem)
	if d.is_empty():
		return Magia.paleta_de((quem as Unit).stats.hat_color) if quem is Unit else Magia.paleta("luz")
	return Magia.paleta(d["pal"])


## Cor do personagem para letreiro e clarão de tela.
static func cor(quem: Variant) -> Color:
	var c: Color = paleta(quem)[1]
	return c


static func cor_flash(quem: Variant) -> Color:
	var d := de(quem)
	var c: Color = d.get("flash", cor(quem))
	return c


# --- Peças ------------------------------------------------------------------------

static func _celula(i: int, cols: int) -> Vector4:
	var s := 1.0 / cols
	return Vector4((i % cols) * s, (i / cols) * s, s, s)


static func _mat(i: int, pal: Array, verbo: String, o: Dictionary) -> ShaderMaterial:
	var v: Array = VERBO.get(verbo, VERBO["pincel"])
	var m := ShaderMaterial.new()
	m.shader = SH_SELO
	m.set_shader_parameter("atlas", ATLAS)
	m.set_shader_parameter("ruido", Magia.tex_ruido())
	m.set_shader_parameter("celula", _celula(i, COLS))
	m.set_shader_parameter("cor", o.get("traco", pal[1]))
	m.set_shader_parameter("cor_nucleo", pal[0])
	m.set_shader_parameter("fino", clampf(2.6 / maxf(o.get("metros", 2.6), 0.1), 0.3, 1.0))
	m.set_shader_parameter("cor_tinta", o.get("tinta", Magia.TINTA))
	m.set_shader_parameter("cor_halo", o.get("halo", pal[2]))
	m.set_shader_parameter("revela", v[0])
	m.set_shader_parameter("inverte", 1.0 if v[1] else 0.0)
	m.set_shader_parameter("giro", o.get("giro", 0.0))
	m.set_shader_parameter("rot", o.get("rot", 0.0))
	m.set_shader_parameter("pulso", o.get("pulso", 0.0))
	m.set_shader_parameter("em_pe", o.get("em_pe", 0.0))
	m.set_shader_parameter("alfa", o.get("alfa", 1.0))
	m.set_shader_parameter("semente", randf())
	return m


static func _quad_pe() -> QuadMesh:
	if not _cache.has("quad_pe"):
		var q := QuadMesh.new()
		q.size = Vector2(2, 2)
		_cache["quad_pe"] = q
	return _cache["quad_pe"]


## Material da malha de um nó devolvido por `selo`/`figura` (para animar `rot`...).
static func mat_de(n: Node3D) -> ShaderMaterial:
	return (n.get_child(0) as MeshInstance3D).material_override as ShaderMaterial


## Escreve, acende, fica e corrói: a vida comum de selo e figura.
static func _vida(n: Node3D, m: ShaderMaterial, escrita: float, dur: float) -> Tween:
	var tw := n.create_tween().set_parallel()
	Magia._anim(tw, m, "escreve", 0.0, 1.0, escrita)
	Magia._anim(tw, m, "aceso", 0.0, 1.0, 0.12).set_delay(escrita)
	Magia._anim(tw, m, "corroi", 0.0, 1.0, 0.45).set_delay(maxf(dur - 0.45, escrita))
	tw.chain().tween_callback(n.queue_free)
	return tw


## O selo do personagem no chão. `quem`: Unit (o brilho sai na cor do time) ou
## o id da classe. o: verbo, escrita, giro, halo. Sem assinatura = selo do kit.
static func selo(g: Node, pos: Vector3, quem: Variant, raio: float, dur: float, o: Dictionary = {}) -> Node3D:
	var d := de(quem)
	if d.is_empty():
		return Magia.selo(g, pos, paleta(quem), raio, dur, {"escrita": 0.18, "giro": 0.1})
	var oo := {"giro": d.get("giro", 0.05), "pulso": d.get("pulso", 0.0)}
	if quem is Unit:
		oo["halo"] = Config.team_color((quem as Unit).team).lightened(0.2)
	if d.has("traco"):
		oo["traco"] = d["traco"]
	if d.has("alfa"):  # desenho cheio (a pata): um pouco translúcido para não tapar o chão
		oo["alfa"] = d["alfa"]
	oo["metros"] = raio
	oo.merge(o, true)
	var verbo: String = oo.get("verbo", d["verbo"])
	var n := Magia._no(g, pos + Vector3(0, 0.09, 0))
	var m := _mat(SELOS.find(_id(quem)), Magia.paleta(d["pal"]), verbo, oo)
	Magia._malha(n, Magia._quad_chao(), m)
	var escrita: float = minf(oo.get("escrita", VERBO[verbo][2]), dur * 0.6)
	n.scale = Vector3(raio, 1, raio)
	var tw := _vida(n, m, escrita, dur)
	if verbo == "carimbo":  # bate no chão: chega grande e assenta
		n.scale = Vector3(raio * 1.4, 1, raio * 1.4)
		tw.tween_property(n, "scale", Vector3(raio, 1, raio), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif verbo == "morde":  # fecha de fora para dentro
		n.scale = Vector3(raio * 1.22, 1, raio * 1.22)
		tw.tween_property(n, "scale", Vector3(raio, 1, raio), escrita).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return n


## Figura em pé, de frente para a câmera (`deitada`: no plano do chão), com
## `tam` em metros. o: verbo, escrita, rot, deitada, halo.
static func figura(g: Node, pos: Vector3, nome: String, pal: Variant, tam: Vector2, dur: float, o: Dictionary = {}) -> Node3D:
	var deitada: bool = o.get("deitada", false)
	var verbo: String = o.get("verbo", "nevoa")
	var oo := o.duplicate()
	oo["em_pe"] = 0.0 if deitada else 1.0
	oo["metros"] = maxf(tam.x, tam.y) * 0.5
	var n := Magia._no(g, pos)
	var m := _mat(SELOS.size() + FIGURAS.find(nome), Magia.paleta(pal), verbo, oo)
	var mi := Magia._malha(n, Magia._quad_chao() if deitada else _quad_pe(), m)
	mi.extra_cull_margin = maxf(tam.x, tam.y)
	n.scale = Vector3(tam.x * 0.5, 1, tam.y * 0.5) if deitada else Vector3(tam.x * 0.5, tam.y * 0.5, 1)
	_vida(n, m, minf(o.get("escrita", VERBO[verbo][2]), dur * 0.6), dur)
	return n


static func _malha_peca(tipo: String, vira: float) -> QuadMesh:
	var chave := "peca_%s_%.1f" % [tipo, vira]
	if not _cache.has(chave):
		var m := ShaderMaterial.new()
		m.shader = SH_PECA
		m.set_shader_parameter("atlas", ATLAS_PECAS)
		m.set_shader_parameter("celula", _celula(maxi(PECAS.find(tipo), 0), PCOLS))
		m.set_shader_parameter("cor_tinta", Magia.TINTA)
		m.set_shader_parameter("vira", vira)
		var q := QuadMesh.new()
		q.size = Vector2(0.38, 0.38)
		q.material = m
		_cache[chave] = q
	return _cache[chave]


## Estouro de `n` peças com forma. o: mov ("espirra", "cai", "sobe") e qualquer
## chave do FxProjetil.ps; tam (escala), gira (graus/s), vira (tombos), tang
## (aceleração de lado: redemoinho). Enfeite: desliga na qualidade Mínima.
static func pecas(g: Node, pos: Vector3, tipo: String, cor_p: Color, n: int, o: Dictionary = {}) -> CPUParticles3D:
	if not Magia.enfeite() or tipo == "":
		return null
	var mov: String = o.get("mov", MOV.get(tipo, "espirra"))
	var c: Dictionary = MOVS[mov].duplicate()
	c.merge(o, true)
	var tam: float = c.get("tam", 1.0)
	c["s0"] = c["s0"] * tam
	c["s1"] = c["s1"] * tam
	var vida: float = c["vida"]
	var p := FxProjetil.ps(g, pos, _malha_peca(tipo, c.get("vira", 0.0)), cor_p, FxProjetil._qtd(n), vida, c)
	p.angle_min = -180.0
	p.angle_max = 180.0
	var gira: float = c.get("gira", 200.0)
	p.angular_velocity_min = -gira
	p.angular_velocity_max = gira
	if c.has("tang"):
		var tang: float = c["tang"]
		p.tangential_accel_min = tang * 0.7
		p.tangential_accel_max = tang
	if c.has("anel"):  # nasce num anel deitado de raio `anel`
		var anel: float = c["anel"]
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		p.emission_ring_axis = Vector3.UP
		p.emission_ring_radius = anel
		p.emission_ring_inner_radius = anel * 0.8
		p.emission_ring_height = 0.3
	return p


## Carimbo vermelho com o emblema, colado no fim do nome do golpe (Label3D).
static func hanko(l: Label3D, u: Unit) -> void:
	if de(u).is_empty():
		return
	if _sh_frente == null:
		_sh_frente = Shader.new()
		_sh_frente.code = SH_SELO.code.replace("depth_draw_never,", "depth_draw_never, depth_test_disabled,")
	var m := _mat(SELOS.find(_id(u)), [PAPEL, HANKO_COR, HANKO_COR], "carimbo", {"em_pe": 1.0})
	m.shader = _sh_frente
	m.set_shader_parameter("hanko", 1.0)
	m.render_priority = 4
	var larg := l.font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.font_size).x * l.pixel_size
	var cam := l.get_viewport().get_camera_3d()
	var lado := cam.global_transform.basis.x if cam != null else Vector3.RIGHT
	var cima := cam.global_transform.basis.y if cam != null else Vector3.UP
	var tam := l.font_size * l.pixel_size * 0.78
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	l.add_child(n)
	n.position = lado * (larg * 0.5 + tam * 0.95) - cima * tam * 0.2
	var mi := Magia._malha(n, _quad_pe(), m)
	mi.extra_cull_margin = 4.0
	m.set_shader_parameter("rot", -0.14)
	m.set_shader_parameter("escreve", 0.0)
	n.scale = Vector3.ONE * tam * 1.2
	var tw := n.create_tween()
	tw.tween_interval(0.16)  # o nome aparece, o carimbo bate depois
	tw.tween_callback(func() -> void: m.set_shader_parameter("escreve", 1.0))
	tw.tween_property(n, "scale", Vector3.ONE * tam * 0.5, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5 if u.is_player else 0.2)
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("corroi", v), 0.0, 1.0, 0.4)


## Emblema para a interface: material de carimbo para um ColorRect quadrado
## (null = personagem sem assinatura).
static func mat_emblema(id: StringName) -> ShaderMaterial:
	var i := SELOS.find(id)
	if i < 0:
		return null
	var m := ShaderMaterial.new()
	m.shader = SH_EMBLEMA
	m.set_shader_parameter("atlas", ATLAS)
	m.set_shader_parameter("celula", _celula(i, COLS))
	m.set_shader_parameter("cor", HANKO_COR)
	m.set_shader_parameter("papel", PAPEL)
	return m


# --- Ajudas das coreografias --------------------------------------------------------

static func _depois(dono: Node, t: float, f: Callable) -> void:
	var tw := dono.create_tween()
	tw.tween_interval(t)
	tw.tween_callback(f)


## Direção "para o fundo da tela" no chão: a figura fica atrás do boneco.
static func _fundo(g: Node, dist: float) -> Vector3:
	var cam := g.get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	var f := -cam.global_transform.basis.z
	f.y = 0.0
	return f.normalized() * dist if f.length() > 0.01 else Vector3.ZERO


static func _lado(g: Node) -> Vector3:
	var cam := g.get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.RIGHT
	var f := cam.global_transform.basis.x
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.RIGHT


static func _roda(i: int, n: int, raio: float, a0 := 0.0) -> Vector3:
	var a := TAU * i / n + a0
	return Vector3(cos(a), 0, sin(a)) * raio


# --- E: o selo e o gesto de cada um ---------------------------------------------------

## Abertura do Chi (E): o selo do personagem sob os pés, as peças dele e um
## gesto próprio. No super "E gigante" o selo do R já está no chão.
static func abrir_e(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	var d := de(u)
	var pal := paleta(u)
	var raio := clampf(maxf(u.stats.power_radius, 2.5) * 1.15, 3.2, 6.4)
	if u.stats.power in ["leque", "grou", "jato", "arrastao"]:
		raio = 3.6  # poder de linha: o raio do .tres é o alcance, não a área
	var no_super := u._super_t > 0.0
	# Quem desenha o próprio selo no poder (no alvo ou enquanto dura) não ganha outro.
	if not no_super and not u.stats.power in ["selo", "muralha", "danca", "hipnose"]:
		selo(g, p, u, raio, 1.3)
	if d.is_empty():
		return
	var peca: String = d["peca"]
	var pc: Color = d["peca_cor"]
	var alto := p + Vector3(0, 1.0, 0)
	match _id(u):
		&"guerreiro":
			figura(g, p + Vector3(0, 1.3, 0) + _fundo(g, 0.8), "pincelada", [Color(0.55, 0.5, 0.65), Color(0.1, 0.06, 0.14), Color(0.03, 0.02, 0.05)], Vector2(5.0, 1.5), 0.5, {"verbo": "risco", "escrita": 0.1, "alfa": 0.8})
			pecas(g, alto, peca, pc, 10, {"tam": 0.8})
		&"ronin_oni":
			Magia.rachaduras(g, p, pal, raio * 0.9, 7, 1.1)
			pecas(g, alto, peca, pc, 12, {"rampa": "quente"})
		&"sohei":
			Magia.onda(g, p, pal, raio * 1.15, 0.5, {"banda": 0.08})
			pecas(g, alto, peca, pc, 12, {"anel": raio * 0.5})
		&"arqueiro":
			FxProjetil.fumaca(g, alto, Color(0.6, 0.62, 0.68, 0.8), 6, 1.4, 0.7, 1.0)
			pecas(g, alto, peca, pc, 8)
		&"arqueiro_yumi":
			figura(g, p + Vector3(0, 3.2, 0), "olho", pal, Vector2(2.4, 2.4), 0.7, {"verbo": "ondas", "escrita": 0.12})
		&"kusarigama":
			pecas(g, alto, peca, pc, 12, {"anel": 1.2, "tang": 26.0, "g": Vector3(0, -6, 0), "spread": 20.0, "v0": 1.0, "v1": 2.5})
		&"kitsune":
			pecas(g, p + Vector3(0, 0.3, 0), peca, pc, 14, {"anel": raio * 0.55})
		&"kitsune_luz":
			Magia.anel_sobe(g, p + Vector3(0, 0.2, 0), pal, raio * 0.5, 3.0, 0.9)
			pecas(g, p + Vector3(0, 3.0, 0), peca, pc, 14, {"esfera": raio * 0.5, "spread": 180.0, "v0": 0.5, "v1": 1.5})
		&"kitsune_sombria":
			pecas(g, p + Vector3(0, 0.4, 0), peca, pc, 12, {"gira": 300.0})
		&"construtor":
			pecas(g, alto, peca, pc, 12)
			pecas(g, alto, "estrepe", Color(0.85, 0.87, 0.9), 6, {"tam": 0.6})
		&"armadilheiro":
			pecas(g, alto, peca, pc, 12, {"tam": 0.8})
		&"bombardeiro":
			pecas(g, alto, peca, pc, 10, {"rampa": "quente", "tam": 0.8})
		&"sumotori":  # o punhado de sal jogado para o alto antes do pisão
			var dir := (u.aim_dir.normalized() + Vector3.UP * 1.4).normalized()
			pecas(g, p + Vector3(0, 1.5, 0), peca, pc, 20, {"dir": dir, "spread": 28.0, "v0": 6.0, "v1": 10.0, "tam": 0.55, "g": Vector3(0, -14, 0)})
		&"kappa":
			Magia.onda(g, p, pal, raio * 1.1, 0.55, {"banda": 0.07})
			pecas(g, alto, peca, pc, 12, {"tam": 0.7})
		&"yamabushi":
			pecas(g, alto, peca, pc, 14, {"tang": 14.0, "anel": 1.4})
		&"karasu_tengu":
			pecas(g, alto, peca, pc, 14, {"v0": 3.5, "v1": 7.0})
		&"mujina":
			Magia.bola(g, alto, pal, 1.3, 0.45)
			pecas(g, p + Vector3(0, 1.8, 0), peca, pc, 8, {"mov": "cai", "vira": 0.0, "g": Vector3(0, -9, 0)})
		&"onmyoji":
			pecas(g, alto, peca, pc, 12, {"flat": 0.9, "spread": 180.0, "v0": 3.5, "v1": 6.0})
		&"tennin":
			Magia.anel_sobe(g, p + Vector3(0, 0.2, 0), pal, raio * 0.45, 3.2, 0.9)
			pecas(g, alto, peca, pc, 14, {"tang": 9.0, "g": Vector3(0, 0.6, 0)})
		&"komuso":
			Magia.onda(g, p, pal, raio * 1.1, 0.6, {"banda": 0.06, "segura": 0.6})
			pecas(g, p + Vector3(0, 1.6, 0), peca, pc, 10)
		&"ochimusha":  # três fogos-fátuos acendem em roda, um por um, e soltam cinza
			for k in 3:
				_depois(u, 0.07 * k, func() -> void:
					Magia.chama(g, p + _roda(k, 3, 1.9, 0.4), pal, 0.32, 1.5, 0.6, {"r_topo": 0.0, "barriga": 0.35}))
			pecas(g, alto, peca, pc, 12, {"anel": 1.6})
		&"shishimai":  # o sino do cinto estala e o confete voa para onde ele vai
			var frente := (Vector3(u.aim_dir.x, 0, u.aim_dir.z).normalized() + Vector3.UP * 0.7).normalized()
			pecas(g, alto, peca, pc, 16, {"mov": "espirra", "dir": frente, "spread": 35.0, "v0": 5.0, "v1": 9.0, "g": Vector3(0, -6, 0), "vida": 1.1})
			Magia.onda(g, p, pal, 3.0, 0.3, {"banda": 0.1})
		&"jorogumo":  # os fios brilham em roda antes do puxão
			pecas(g, p + Vector3(0, 0.8, 0), peca, pc, 14, {"anel": raio * 0.7, "tang": 10.0, "mov": "espirra", "v0": 0.4, "v1": 1.4, "g": Vector3(0, -1.5, 0), "vida": 1.0})
		_:
			pecas(g, alto, peca, pc, 10)


# --- R: a abertura de cada um ---------------------------------------------------------

## Abertura do super (R): maior que tudo e de um jeito só dele. O selo grande
## do personagem, a figura em pé e as peças; o poder em si vem depois (Unit).
static func abrir_r(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	var d := de(u)
	var pal := paleta(u)
	var c1: Color = pal[1]
	Magia.carga(g, p + Vector3(0, 1.2, 0), c1, 4.0, 0.22, 20)
	Magia.clarao(g, p, c1, 17.0, 0.45, 3.4)
	if d.is_empty():  # sem assinatura: abertura do kit, na cor do chapéu
		Magia.selo(g, p, pal, 5.5, 1.6, {"pontas": 8, "escrita": 0.2, "giro": 0.25})
		Magia.estouro(g, p, pal, 3.6, 0.4)
		Magia.brasas(g, p, c1, 14, 2.2, 1.4)
		return
	var peca: String = d["peca"]
	var pc: Color = d["peca_cor"]
	var alto := p + Vector3(0, 1.2, 0)
	var id := _id(u)
	if id != &"sumotori" and id != &"sohei":  # Dohyō e Muralha desenham o selo no tamanho da área
		selo(g, p, u, RAIO_R, 2.6, {"giro": 1.0} if id == &"kusarigama" else ({"escrita": 0.5} if id == &"bombardeiro" else {}))
	match id:
		&"guerreiro":  # Passo da Sombra: um risco de tinta atravessa a tela e ele some em fumaça
			var tinta := [Color(0.6, 0.55, 0.7), Color(0.08, 0.05, 0.12), Color(0.02, 0.01, 0.04)]
			figura(g, p + Vector3(0, 1.6, 0) + _fundo(g, 1.0), "pincelada", tinta, Vector2(13.0, 3.4), 0.9, {"verbo": "risco", "escrita": 0.13, "alfa": 0.85})
			_depois(u, 0.12, func() -> void:
				figura(g, p + Vector3(0, 1.1, 0) + _fundo(g, 0.6), "pincelada", pal, Vector2(11.0, 2.4), 0.6, {"verbo": "risco", "escrita": 0.1, "rot": 0.25}))
			FxProjetil.fumaca(g, alto, Color(0.1, 0.07, 0.14, 0.9), 12, 2.4, 1.1, 1.2)
			pecas(g, alto, peca, pc, 22)
			Magia.onda(g, p, "aco", 8.0, 0.4, {"banda": 0.08})
		&"ronin_oni":  # a máscara oni queima atrás dele e ruge
			var oni := figura(g, p + Vector3(0, 3.4, 0) + _fundo(g, 1.4), "oni", pal, Vector2(6.4, 6.4), 1.5, {"verbo": "queima", "escrita": 0.3})
			var tw := oni.create_tween()
			tw.tween_interval(0.32)
			tw.tween_property(oni, "scale", oni.scale * 1.22, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(oni, "scale", oni.scale, 0.3)
			_depois(u, 0.32, func() -> void:
				Magia.estouro(g, p, pal, 5.0, 0.45)
				Magia.onda(g, p, pal, 9.0, 0.5))
			Magia.rachaduras(g, p, pal, 8.0, 12, 1.8)
			pecas(g, alto, peca, pc, 28, {"rampa": "quente", "v1": 11.0, "tam": 1.2})
		&"sohei":  # o sino gigante cai e bate: três anéis de som
			var sino := figura(g, p + Vector3(0, 9.0, 0) + _fundo(g, 1.0), "sino", pal, Vector2(5.4, 5.4), 1.7, {"verbo": "carimbo", "escrita": 0.05})
			sino.create_tween().tween_property(sino, "global_position:y", p.y + 2.9, 0.26).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			for k in 3:
				_depois(u, 0.2 + 0.14 * k, func() -> void:
					Magia.onda(g, p, pal, 5.0 + 2.6 * k, 0.6, {"banda": 0.07, "segura": 0.5}))
			pecas(g, alto, peca, pc, 22, {"anel": 2.2})
		&"arqueiro":  # fumaça e três sombras dele
			FxProjetil.fumaca(g, alto, Color(0.55, 0.57, 0.64, 0.85), 14, 2.6, 1.0, 1.4)
			Magia.bola(g, alto, "fumaca", 2.4, 0.5)
			var sombra := [Color(0.5, 0.9, 1.0), Color(0.07, 0.12, 0.2), Color(0.1, 0.5, 0.75)]
			for k in 3:
				_depois(u, 0.07 * k, func() -> void:
					figura(g, p + Vector3(0, 1.5, 0) + _roda(k, 3, 3.0, 0.5), "sombra", sombra, Vector2(3.2, 3.2), 0.75, {"verbo": "nevoa", "escrita": 0.1}))
			pecas(g, alto, peca, pc, 18, {"v1": 11.0})
		&"arqueiro_yumi":  # o céu escurece e um olho de luz se abre
			var olho := figura(g, p + Vector3(0, 7.0, 0) + _fundo(g, 1.0), "olho", pal, Vector2(8.0, 8.0), 1.7, {"verbo": "ondas", "escrita": 0.2})
			var alvo := olho.scale
			olho.scale = Vector3(alvo.x, alvo.y * 0.06, 1)
			olho.create_tween().tween_property(olho, "scale", alvo, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_depois(u, 0.3, func() -> void:
				Magia.lanca(g, p + Vector3(0, 6.6, 0), p + Vector3(0, 0.2, 0), "luz", 0.7, 0.5, {"cresce": 0.1, "corre": 5.0})
				Magia.onda(g, p, pal, 6.0, 0.45))
			if Magia.enfeite():  # riscos de flecha caindo em volta
				FxProjetil.ps(g, p + Vector3(0, 6.0, 0), FxProjetil.lasca(0.9, 0.04), Color(1.0, 0.92, 0.65), 16, 0.6, {"esfera": 5.0, "explosao": 0.6, "dir": Vector3.DOWN, "spread": 4.0, "v0": 14.0, "v1": 20.0, "alinha": true, "rampa": "nasce"})
		&"kusarigama":  # a corrente gira e risca uma espiral de faíscas
			Magia.vortice(u, pal, 3.4, 1.3, 1.3, {"r_topo": 1.35, "gira": 3.2, "forca": 1.6})
			pecas(g, alto, peca, pc, 22, {"anel": 2.6, "tang": 34.0, "g": Vector3(0, -4, 0), "spread": 15.0, "v0": 1.0, "v1": 3.0, "vida": 1.2})
			FxProjetil.faiscas(g, alto, Color(1.0, 0.95, 0.7), 14, 9.0, Vector3.UP, 80.0)
			Magia.onda(g, p, pal, 8.0, 0.5, {"gira": 2.0, "banda": 0.06})
		&"kitsune":  # fogos-fátuos brotam em roda, um por um, e a raposa pisca
			for k in 7:
				_depois(u, 0.05 * k, func() -> void:
					Magia.chama(g, p + _roda(k, 7, 3.6), pal, 0.6, 2.6, 0.85, {"r_topo": 0.0, "barriga": 0.35}))
			figura(g, p + Vector3(0, 4.0, 0) + _fundo(g, 1.0), "raposa", pal, Vector2(3.6, 3.6), 1.1, {"verbo": "nevoa", "escrita": 0.18})
			pecas(g, p + Vector3(0, 0.4, 0), peca, pc, 22, {"anel": 3.6})
		&"kitsune_luz":  # o halo dourado desce e chovem pétalas
			var halo := figura(g, p + Vector3(0, 6.0, 0), "halo", pal, Vector2(5.0, 5.0), 1.8, {"deitada": true, "verbo": "ondas", "escrita": 0.2, "giro": 0.2})
			halo.create_tween().tween_property(halo, "global_position:y", p.y + 2.9, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			for k in 3:
				Magia.anel_sobe(g, p + Vector3(0, 0.2, 0), pal, 3.4, 4.5 + k, 1.1, 0.14 * k)
			pecas(g, p + Vector3(0, 5.0, 0), peca, pc, 28, {"esfera": 4.5, "spread": 180.0, "v0": 0.4, "v1": 1.6, "vida": 2.0})
		&"kitsune_sombria":  # olhos roxos se abrem no chão e as caudas de sombra varrem a roda
			for k in 5:
				_depois(u, 0.06 * k, func() -> void:
					var olhos := figura(g, p + Vector3(0, 0.14, 0) + _roda(k, 5, randf_range(2.6, 5.2), 0.7), "olhos", pal, Vector2(2.8, 2.8), 1.3, {"deitada": true, "verbo": "carimbo", "rot": randf_range(-0.5, 0.5)})
					var alvo := olhos.scale
					olhos.scale = Vector3(alvo.x, 1, alvo.z * 0.05)
					olhos.create_tween().tween_property(olhos, "scale", alvo, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
			Magia.vortice(u, pal, 5.0, 0.9, 1.2, {"r_topo": 1.2, "gira": 2.4, "forca": 1.7})
			pecas(g, p + Vector3(0, 0.4, 0), peca, pc, 20, {"anel": 3.0, "gira": 320.0})
		&"construtor":  # andaimes de luz sobem dos dois lados
			for s: float in [-1.0, 1.0]:
				var and_ := figura(g, p + _lado(g) * 2.9 * s + Vector3(0, -2.6, 0), "andaime", pal, Vector2(3.4, 6.0), 1.6, {"verbo": "ondas", "escrita": 0.25})
				and_.create_tween().tween_property(and_, "global_position:y", p.y + 2.9, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pecas(g, alto, peca, pc, 22, {"v1": 10.0})
			pecas(g, alto, "estrepe", Color(0.85, 0.87, 0.9), 12, {"tam": 0.6, "v1": 10.0})
			Magia.onda(g, p, pal, 7.5, 0.45)
		&"armadilheiro":  # o chão morde: a mandíbula fecha e os dentes sobem
			_depois(u, 0.18, func() -> void:
				for k in 8:
					Magia.chama(g, p + _roda(k, 8, 4.4), pal, 0.42, 2.8, 0.5, {"r_topo": 0.0, "barriga": 0.0, "giro": 0.0, "segura": 0.5})
				Magia.onda(g, p, pal, 7.5, 0.4, {"r0": 1.0, "banda": 0.1}))
			pecas(g, alto, peca, pc, 22, {"v1": 10.0})
			pecas(g, alto, "gota", Color(0.5, 0.95, 0.35), 12, {"tam": 0.6})
		&"bombardeiro":  # o pavio queima até o meio e estoura
			_depois(u, 0.5, func() -> void:
				var ex := figura(g, p + Vector3(0, 2.8, 0) + _fundo(g, 0.8), "explosao", pal, Vector2(7.0, 7.0), 0.7, {"verbo": "carimbo"})
				var alvo := ex.scale
				ex.scale = alvo * 0.35
				ex.create_tween().tween_property(ex, "scale", alvo, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				FxProjetil.explosao(g, p, 4.5)
				Magia.bola(g, p + Vector3(0, 1.2, 0), pal, 3.2, 0.5)
				pecas(g, alto, peca, pc, 24, {"rampa": "quente", "v1": 12.0, "tam": 1.2}))
			FxProjetil.faiscas(g, p + Vector3(0, 0.3, 0), Color(1.0, 0.9, 0.5), 10, 5.0, Vector3.UP, 60.0)
		&"sumotori":  # pisão shiko: nuvem de sal e os papéis shide caindo
			FxProjetil.fumaca(g, p + Vector3(0, 0.4, 0), Color(0.98, 0.96, 0.9, 0.85), 14, 3.0, 1.2, 0.8)
			pecas(g, p + Vector3(0, 0.6, 0), peca, pc, 36, {"spread": 40.0, "v0": 6.0, "v1": 12.0, "tam": 0.6, "esfera": 1.5})
			for k in 4:
				var sh := figura(g, p + _roda(k, 4, 4.6, 0.8) + Vector3(0, 4.4, 0), "shide", pal, Vector2(1.2, 2.4), 1.5, {"verbo": "risco", "escrita": 0.15})
				sh.create_tween().tween_property(sh, "global_position:y", p.y + 2.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			Magia.onda(g, p, pal, 9.0, 0.5, {"banda": 0.12})
		&"kappa":  # gêiser do prato e chuva em volta
			Magia.chama(g, p + Vector3(0, 1.5, 0), pal, 1.2, 7.5, 1.3, {"r_topo": 0.55, "segura": 0.5, "forca": 1.3})
			pecas(g, p + Vector3(0, 7.0, 0), peca, pc, 34, {"esfera": 5.0, "dir": Vector3.DOWN, "spread": 12.0, "v0": 6.0, "v1": 10.0, "gira": 0.0, "vida": 0.9, "tam": 0.75})
			for k in 2:
				_depois(u, 0.2 * k, func() -> void:
					Magia.onda(g, p, pal, 6.0 + 3.0 * k, 0.6, {"banda": 0.08}))
		&"yamabushi":  # o leque varre e levanta o redemoinho de folhas
			var leque := figura(g, p + Vector3(0, 3.2, 0) + _fundo(g, 1.0), "leque", pal, Vector2(5.2, 5.2), 0.95, {"verbo": "carimbo", "rot": -0.9})
			var ml := mat_de(leque)
			leque.create_tween().tween_method(func(v: float) -> void: ml.set_shader_parameter("rot", v), -0.9, 0.9, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
			var no := Magia._no(g, p)
			Magia.vortice(no, pal, 2.4, 4.6, 1.3, {"r_topo": 1.9, "gira": 2.2, "alfa": 0.8})
			no.create_tween().tween_callback(no.queue_free).set_delay(2.0)
			pecas(g, alto, peca, pc, 32, {"anel": 2.4, "tang": 30.0, "g": Vector3(0, 2.2, 0), "vida": 1.6})
		&"karasu_tengu":  # as asas se abrem e as penas explodem
			var asas := figura(g, p + Vector3(0, 2.6, 0) + _fundo(g, 0.9), "asas", pal, Vector2(9.5, 9.5), 1.1, {"verbo": "carimbo"})
			var alvo := asas.scale
			asas.scale = Vector3(alvo.x * 0.12, alvo.y, 1)
			asas.create_tween().tween_property(asas, "scale", alvo, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pecas(g, p + Vector3(0, 2.0, 0), peca, pc, 36, {"v0": 5.0, "v1": 10.0, "spread": 120.0, "vida": 2.0, "tam": 1.15})
			Magia.onda(g, p, pal, 8.0, 0.45, {"banda": 0.09})
		&"mujina":  # o rosto liso aparece, racha, e os cacos caem
			figura(g, p + Vector3(0, 3.8, 0) + _fundo(g, 1.0), "rosto", [Color(1, 1, 1), Color(0.95, 0.92, 1.0), Color(0.5, 0.4, 0.75)], Vector2(5.0, 5.0), 1.25, {"verbo": "nevoa", "escrita": 0.25})
			_depois(u, 0.85, func() -> void:
				pecas(g, p + Vector3(0, 3.6, 0), peca, pc, 26, {"spread": 100.0, "v0": 1.0, "v1": 4.0, "g": Vector3(0, -12, 0), "vida": 1.0}))
			Magia.bola(g, alto, pal, 2.6, 0.6)
		&"onmyoji":  # os talismãs abrem em leque e se dobram em grous
			pecas(g, alto, peca, pc, 24, {"flat": 0.9, "spread": 180.0, "v0": 5.0, "v1": 8.0, "amort": 5.0, "vida": 0.7, "g": Vector3.ZERO})
			_depois(u, 0.4, func() -> void:
				pecas(g, alto, "grou", Color(1.0, 0.98, 0.92), 16, {"anel": 3.4, "v0": 2.0, "v1": 4.5, "g": Vector3(0, 2.0, 0), "gira": 20.0, "tam": 1.3, "vida": 1.5})
				var grou := figura(g, p + Vector3(0, 2.4, 0) + _fundo(g, 1.0), "grou", pal, Vector2(5.0, 5.0), 1.2, {"verbo": "risco", "escrita": 0.16})
				grou.create_tween().tween_property(grou, "global_position:y", p.y + 5.6, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT))
		&"tennin":  # ela gira e as fitas desenham um véu
			var no := Magia._no(g, p)
			Magia.vortice(no, pal, 4.2, 4.8, 1.5, {"r_topo": 1.0, "gira": 1.2, "alfa": 0.6})
			no.create_tween().tween_callback(no.queue_free).set_delay(2.1)
			for k in 3:
				Magia.anel_sobe(g, p + Vector3(0, 0.2, 0), pal, 4.0, 4.0 + k, 1.1, 0.14 * k)
			pecas(g, alto, peca, pc, 30, {"anel": 3.0, "tang": 16.0, "g": Vector3(0, 1.4, 0), "vida": 1.8})
		&"komuso":  # a flauta toca e os anéis de som param no ar (silêncio)
			figura(g, p + Vector3(0, 3.8, 0) + _fundo(g, 1.0), "nota", pal, Vector2(3.6, 3.6), 1.3, {"verbo": "nevoa", "escrita": 0.18})
			for k in 3:
				_depois(u, 0.12 * k, func() -> void:
					Magia.onda(g, p, pal, 4.5 + 2.5 * k, 1.3, {"banda": 0.05, "segura": 0.85}))
			pecas(g, p + Vector3(0, 1.6, 0), peca, pc, 22, {"esfera": 2.5})
		&"ochimusha":  # o samurai caído se ergue atrás dele, o chão racha e a cinza sobe
			var caido := figura(g, p + Vector3(0, -1.6, 0) + _fundo(g, 1.3), "caidos", pal, Vector2(5.6, 7.0), 1.6, {"verbo": "nevoa", "escrita": 0.25, "alfa": 0.9})
			caido.create_tween().tween_property(caido, "global_position:y", p.y + 3.4, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Magia.rachaduras(g, p, pal, 7.5, 10, 1.6)
			_depois(u, 0.4, func() -> void:
				Magia.onda(g, p, pal, 8.5, 0.5, {"banda": 0.07}))
			pecas(g, p + Vector3(0, 0.5, 0), peca, pc, 30, {"esfera": 3.5, "vida": 2.0})
		&"shishimai":  # a cabeça do leão pula na frente, estala a boca, e chove confete
			var leao := figura(g, p + Vector3(0, 3.2, 0) + _fundo(g, 1.0), "leao", pal, Vector2(6.0, 6.0), 1.4, {"verbo": "estala"})
			var alvo := leao.scale
			leao.scale = alvo * 0.3
			var tw := leao.create_tween()
			tw.tween_property(leao, "scale", alvo * 1.1, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(leao, "scale", alvo * 0.94, 0.08)  # a boca fecha: nhac
			tw.tween_property(leao, "scale", alvo, 0.12)
			for k in 3:  # três batidas do taiko
				_depois(u, 0.18 * k, func() -> void:
					Magia.onda(g, p, pal, 4.0 + 2.4 * k, 0.45, {"banda": 0.08}))
			pecas(g, p + Vector3(0, 6.0, 0), peca, pc, 34, {"esfera": 4.5, "spread": 180.0, "v0": 0.4, "v1": 1.8, "vida": 2.2})
		&"jorogumo":  # a aranha desce pelo fio e a teia se fecha em volta
			var aranha := figura(g, p + Vector3(0, 9.0, 0) + _fundo(g, 1.0), "aranha", pal, Vector2(4.4, 4.4), 1.7, {"verbo": "tece", "escrita": 0.2})
			aranha.create_tween().tween_property(aranha, "global_position:y", p.y + 3.6, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			Magia.lanca(g, p + Vector3(0, 9.0, 0) + _fundo(g, 1.0), p + Vector3(0, 4.6, 0) + _fundo(g, 1.0), pal, 0.08, 1.2, {"cresce": 0.4})
			Magia.onda(g, p, pal, 7.0, 0.7, {"banda": 0.05, "gira": -1.2})
			pecas(g, p + Vector3(0, 4.0, 0), peca, pc, 24, {"esfera": 3.5, "vida": 1.8})
		_:
			pecas(g, alto, peca, pc, 20)


# --- Q: o toque ---------------------------------------------------------------------

## Q: o emblema bate pequeno sob os pés e solta umas poucas peças.
static func toque_q(u: Unit) -> void:
	var d := de(u)
	if d.is_empty() or not Magia.enfeite():
		return
	selo(u.game, u.global_position, u, 1.5, 0.6, {"verbo": "carimbo", "escrita": 0.05, "giro": 0.0})
	var pc: Color = d["peca_cor"]
	pecas(u.game, u.global_position + Vector3(0, 0.9, 0), d["peca"], pc, 5, {"tam": 0.8})


## Compila os shaders no começo da partida (ver Fx.prewarm).
static func prewarm(parent: Node, pos: Vector3) -> void:
	selo(parent, pos, &"guerreiro", 0.5, 0.5)
	figura(parent, pos, "oni", "brasa", Vector2(0.5, 0.5), 0.5)
	pecas(parent, pos, "pena", Color.WHITE, 2)
	pecas(parent, pos, "sal", Color.WHITE, 2)
