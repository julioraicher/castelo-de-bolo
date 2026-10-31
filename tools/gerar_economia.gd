extends "res://tools/gerar_cenario_ninja.gd"
## Modelos da Economia do Construtor (Ciclo 2.3), nos quatro temas:
##   arvore_e1/e2/e3, bambu_e1/e2/e3  plantas cortáveis nos 3 estágios
##   tora                             tora para carregar (centro na origem, eixo x)
##   pilha_toras                      pilha do castelo; nós Nivel_1..4 (3 toras cada) e Contador
##   maquina_chapeu                   maquininha: Prensa, Gira_engrenagem, Molde, Brilho,
##                                    Vapor, Enfeite, Estoque_1..4 e a animação "fabricar"
##   emblema_<classe>                 enfeite da frente da máquina (guerreiro, arqueiro, monge, construtor)
## Rode depois de tools/gerar_cenario_ninja.gd:
##   godot --headless --path . -s tools/gerar_economia.gd
## Tudo de frente para +z (a câmera do jogo olha de +z).

const FABRICAR := 2.0  # duração da animação "fabricar" (s)


func _gerar_tudo() -> bool:
	return false


func _init() -> void:
	for tema in TEMAS:
		P = TEMAS[tema]
		_dir = "res://assets/ninja/" + tema
		for e in 3:
			_arvore(e); _salvar("arvore_e%d" % (e + 1))
			_bambu_planta(e); _salvar("bambu_e%d" % (e + 1))
		_tora(Vector3.ZERO, 0.0); _salvar("tora")
		_pilha_toras(); _salvar("pilha_toras"); _completar("pilha_toras", false)
		_maquina(); _salvar("maquina_chapeu"); _completar("maquina_chapeu", true)
		for c in ["guerreiro", "arqueiro", "monge", "construtor"]:
			_emblema(c); _salvar("emblema_" + c)
	_ligar_temas()
	print("triângulos (último tema): ", _tris)
	quit()


# --- Plantas -----------------------------------------------------------------

## Castanheira (kuri) de corte: tronco grosso e copa redonda, diferente das
## árvores de enfeite. Adulta ganha o corte em cunha no tronco (onde o machado
## bate) e um ofuda aceso na corda: "pronta para cortar" se lê de longe.
func _arvore(e: int) -> void:
	_rng.seed = 40 + e
	var tr: Color = P.tronco
	if e == 0:
		# Muda amarrada numa estaca, com montinho de terra.
		_esfera(0.45, Vector3(0, 0.05, 0), Vector3(1, 0.3, 1), P.musgo.darkened(0.2), false, 7, 3)
		_cil(0.05, 0.08, 0.8, 5, Vector3(0, 0.4, 0), Vector3(0, 0, 4), tr)
		_viga(Vector3(0.2, 0.0, -0.1), Vector3(0.12, 0.95, -0.06), 0.06, P.madeira2)
		_cil(0.1, 0.1, 0.05, 6, Vector3(0.06, 0.55, -0.03), Vector3.ZERO, P.corda)
		var m := _marca()
		for k in 3:
			var a := TAU * k / 3.0
			_esfera(0.28, Vector3(cos(a) * 0.18, 0.85 + k * 0.08, sin(a) * 0.18), Vector3(1, 0.6, 1), P.folha2 if k % 2 else P.folha, false, 6, 3)
		_vento_planta(m, 0.5, 0.6, 1.0)
		return
	var h := 1.6 if e == 1 else 3.0          # altura do tronco
	var r := 0.16 if e == 1 else 0.42        # raio na base
	var copa := 1.0 if e == 1 else 2.0       # raio da copa
	# Raízes e tronco levemente torto.
	if e == 2:
		for k in 4:
			var a := TAU * k / 4.0 + 0.4
			_cil(0.05, 0.2, 0.9, 5, Vector3(cos(a) * 0.45, 0.15, sin(a) * 0.45), Vector3(sin(a) * 70, 0, -cos(a) * 70), tr.darkened(0.1))
	_cil(r * 0.7, r, h, 7, Vector3(0, h / 2, 0), Vector3(0, 0, 3), tr)
	if e == 2:
		# Galhos que seguram a copa.
		for s in [-1.0, 1.0]:
			_cil(0.08, 0.18, 1.6, 6, Vector3(s * 0.6, h - 0.1, 0.1), Vector3(0, 0, -45 * s), tr)
		# Corte em cunha virado para a câmera (madeira clara por dentro).
		_tipo = 1
		_blocod(Vector3(0.5, 0.26, 0.12), Vector3(0, 0.75, r - 0.02), Vector3(-12, 0, 0), P.madeira2.lightened(0.25), 0.02)
		_tipo = 0
		_blocod(Vector3(0.52, 0.04, 0.16), Vector3(0, 0.62, r), Vector3.ZERO, P.madeira2.lightened(0.1), 0.01)
		# Corda sagrada com o ofuda aceso.
		_toro(r * 0.86, r * 0.86 + 0.08, Vector3(0, 1.5, 0), Vector3(1, 0.6, 1), P.corda)
		_caixa(Vector3(0.14, 0.32, 0.02), Vector3(0.12, 1.25, r * 0.8 + 0.06), Vector3(0, 0, 6), P.papel, true)
	# Copa: bolas achatadas em volta de uma central; vento só nela.
	var m := _marca()
	var base_copa := h - 0.2
	var n := 5 if e == 1 else 8
	for k in n:
		var a := TAU * k / n + _rng.randf() * 0.4
		var rr := copa * (0.55 if k % 2 else 0.75)
		var cor: Color = P.folha if k % 2 else P.folha2
		_esfera(copa * 0.62, Vector3(cos(a) * rr, base_copa + copa * 0.35 + (k % 3) * 0.18, sin(a) * rr * 0.85), Vector3(1, 0.78, 1), cor, false, 7, 4)
	_esfera(copa * 0.8, Vector3(0, base_copa + copa * 0.75, 0), Vector3(1, 0.8, 1), P.folha2, false, 8, 4)
	if e == 2:
		# Ouriços de castanha: pontinhos claros na frente da copa.
		for k in 5:
			var a := -0.9 + k * 0.45
			_esfera(0.12, Vector3(sin(a) * copa * 1.05, base_copa + 0.6 + (k % 2) * 0.5, cos(a) * copa * 0.95), Vector3.ONE, P.chao_folha, false, 5, 3)
	_vento_planta(m, base_copa, copa * 1.6, 1.1)


## Moita de bambu de corte: broto (takenoko), jovem e adulto com folhas no alto.
## Adulto ganha a corda com ofuda, igual à árvore.
func _bambu_planta(e: int) -> void:
	_rng.seed = 60 + e
	_esfera(0.7 + e * 0.15, Vector3(0, 0.04, 0), Vector3(1, 0.22, 1), P.musgo.darkened(0.15), false, 7, 3)
	if e == 0:
		for k in 3:
			var p := Vector3(-0.3 + k * 0.3, 0, (k % 2) * 0.25 - 0.1)
			var hh := 0.45 + k * 0.12
			_cil(0.0, 0.14, hh, 6, p + Vector3(0, hh / 2, 0), Vector3(0, k * 30, (k - 1) * 8), P.tronco.lerp(P.bambu, 0.3))
			_cil(0.0, 0.07, 0.16, 4, p + Vector3(0, hh + 0.05, 0), Vector3(0, 0, (k - 1) * 8), P.folha2)
		return
	var n := 3 if e == 1 else 5
	var hmax := 2.6 if e == 1 else 5.6
	var m := _marca()
	for k in n:
		var a := TAU * k / n + 0.5
		var rr := 0.25 + (k % 2) * 0.2
		var base := Vector3(cos(a) * rr, 0, sin(a) * rr * 0.8)
		var hh := hmax * (0.75 + 0.25 * fmod(k * 0.618, 1.0))
		var rot := Vector3(sin(a) * 4, 0, -cos(a) * 5)
		_bambu(base, hh, rot)
		var b := Basis.from_euler(rot * PI / 180.0)
		var topo := base + b * Vector3(0, hh, 0)
		for j in (2 if e == 1 else 3):
			_esfera(0.4 + e * 0.12, topo + Vector3((j - 1) * 0.3, -0.3 - j * 0.45, (j % 2) * 0.2), Vector3(1.3, 0.35, 0.8), P.folha if j % 2 else P.folha2, false, 6, 3)
	_vento_planta(m, 0.6, hmax, 1.4)
	if e == 2:
		_toro(0.62, 0.7, Vector3(0, 1.3, 0), Vector3(1, 0.5, 0.85), P.corda)
		_caixa(Vector3(0.14, 0.32, 0.02), Vector3(0.1, 1.05, 0.62), Vector3(0, 0, -5), P.papel, true)


## Tora curta deitada no eixo x, centro em `c`: casca escura, pontas claras com
## anéis e uma amarra de corda.
func _tora(c: Vector3, giro_y: float, comp := 1.2, r := 0.2) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(giro_y))
	var rot := Vector3(0, giro_y, 90)
	_cil(r, r * 1.05, comp, 8, c, rot, P.tronco)
	for s in [-1.0, 1.0]:
		_cil(r * 0.92, r * 0.92, 0.03, 8, c + b * Vector3(s * comp / 2, 0, 0), rot, P.madeira2.lightened(0.3))
		_cil(r * 0.45, r * 0.45, 0.035, 6, c + b * Vector3(s * comp / 2, 0, 0), rot, P.madeira2)
	_cil(r * 1.08, r * 1.08, 0.07, 8, c + b * Vector3(comp * 0.22, 0, 0), rot, P.corda)


## Pilha do castelo: cavalete com duas estacas e 4 níveis de 3 toras. O jogo
## mostra Nivel_1..N conforme o estoque (3 toras por nível) e põe o número no
## nó Contador.
func _pilha_toras() -> void:
	_tipo = 1
	for s in [-1.0, 1.0]:
		_blocod(Vector3(0.2, 0.14, 1.3), Vector3(s * 0.5, 0.07, 0), Vector3.ZERO, P.madeira, 0.03)
		_viga(Vector3(s * 0.85, 0, 0), Vector3(s * 0.9, 1.6, 0.02), 0.14, P.madeira)
	_tipo = 0
	# Placa com o ícone de tora (o número fica em cima).
	_blocod(Vector3(0.7, 0.4, 0.06), Vector3(0, 0.3, 0.72), Vector3(-10, 0, 0), P.madeira2, 0.03)
	_cil(0.1, 0.1, 0.04, 8, Vector3(-0.15, 0.3, 0.76), Vector3(80, 0, 0), P.madeira2.lightened(0.35))
	for k in 4:
		var g := _inicio_peca()
		var y := 0.34 + k * 0.36
		for j in 3 - (k % 2):
			var x := (j - (1.0 if k % 2 == 0 else 0.5)) * 0.42
			_tora(Vector3(x, 0, 0), 90.0 + (j - 1) * 2.0, 1.15, 0.19)
		_fim_peca(g, "Nivel_%d" % (k + 1), Transform3D(Basis(), Vector3(0, y, 0)))
	_pecas_marcador("Contador", Vector3(0, 2.0, 0))


# --- Maquininha de chapéu ------------------------------------------------------

var _marcadores: Array = []  # [nome, posição]: Marker3D que entram no próximo _salvar


func _pecas_marcador(nome: String, pos: Vector3) -> void:
	_marcadores.append([nome, pos])


## Prensa de bambu e madeira (karakuri): mesa com o molde no meio, prensa
## pendurada na trave, engrenagem grande do lado direito (a manivela da prensa),
## chaminé de bambu à esquerda (vapor) e a prateleira dos chapéus prontos na
## frente. Placa redonda no alto da trave: o enfeite da classe vai ali.
## ~2,2 x 1,4 m de chão, 2,7 m de altura.
func _maquina() -> void:
	_rng.seed = 77
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	var ferro := Color(0.2, 0.18, 0.19)
	var ym := 0.95  # tampo da mesa
	# Base de pedra.
	_tipo = 3
	_blocod(Vector3(2.2, 0.22, 1.4), Vector3(0, 0.11, 0), Vector3.ZERO, P.pedra2, 0.06)
	_tipo = 1
	# Mesa com tampo grosso e pés.
	_blocod(Vector3(1.3, 0.14, 0.9), Vector3(0, ym - 0.07, 0), Vector3.ZERO, mad2, 0.04)
	for x in [-0.55, 0.55]:
		for z in [-0.35, 0.35]:
			_blocod(Vector3(0.12, ym - 0.22, 0.12), Vector3(x, 0.22 + (ym - 0.36) / 2, z), Vector3.ZERO, mad, 0.02)
	_tipo = 0
	# Molde: prato de ferro com aro na cor da corda (o chapéu nasce em cima).
	_cil(0.42, 0.46, 0.08, 12, Vector3(0, ym + 0.04, 0.05), Vector3.ZERO, ferro)
	_cil(0.47, 0.47, 0.04, 12, Vector3(0, ym + 0.08, 0.05), Vector3.ZERO, P.corda.darkened(0.2))
	# Pórtico: dois postes de bambu grosso e a trave de madeira.
	var yt := 2.3
	for x in [-0.85, 0.85]:
		_viga(Vector3(x, 0.2, -0.1), Vector3(x * 0.96, yt + 0.1, -0.1), 0.16, P.bambu)
		for k in 3:
			_cil(0.11, 0.11, 0.05, 6, Vector3(x * (0.99 - k * 0.012), 0.7 + k * 0.6, -0.1), Vector3.ZERO, P.bambu.darkened(0.25))
	_tipo = 1
	_blocod(Vector3(2.0, 0.2, 0.26), Vector3(0, yt + 0.1, -0.1), Vector3(0, 0, 0.8), mad, 0.05)
	_tipo = 0
	# Placa redonda do enfeite, presa na trave e inclinada para a câmera.
	_cil(0.34, 0.34, 0.07, 14, Vector3(0, yt + 0.42, 0.05), Vector3(78, 0, 0), Color(0.1, 0.08, 0.12))
	_cil(0.38, 0.38, 0.04, 14, Vector3(0, yt + 0.42, 0.02), Vector3(78, 0, 0), P.ouro.darkened(0.35))
	_pecas_marcador("Enfeite", Vector3(0, yt + 0.43, 0.1))
	# Guia da prensa (dois trilhos de ferro) e o cabo que sobe para a roldana.
	for x in [-0.32, 0.32]:
		_viga(Vector3(x, ym + 0.1, -0.12), Vector3(x, yt, -0.12), 0.05, ferro)
	_cil(0.1, 0.1, 0.12, 8, Vector3(0, yt - 0.02, 0.06), Vector3(90, 0, 0), ferro)
	# Prensa (nó à parte, desce na animação): bloco pesado com cinta e alça.
	var g := _inicio_peca()
	_tipo = 1
	_blocod(Vector3(0.7, 0.36, 0.56), Vector3.ZERO, Vector3.ZERO, P.pedra2.darkened(0.2), 0.05)
	_tipo = 0
	_blocod(Vector3(0.74, 0.07, 0.6), Vector3(0, -0.1, 0), Vector3.ZERO, ferro, 0.02)
	_cil(0.3, 0.36, 0.08, 10, Vector3(0, -0.21, 0), Vector3.ZERO, ferro)
	_viga(Vector3(0, 0.17, 0), Vector3(0, 0.55, 0), 0.04, P.corda)
	_fim_peca(g, "Prensa", Transform3D(Basis(), Vector3(0, 1.75, 0.05)))
	# Engrenagem grande à direita, na face da frente: gira devagar sempre.
	var c1 := Vector3(1.08, 1.25, 0.12)
	_cil(0.06, 0.06, 0.3, 6, c1 - Vector3(0, 0, 0.12), Vector3(90, 0, 0), ferro)
	_viga(Vector3(0.88, 1.25, -0.05), c1 - Vector3(0, 0, 0.1), 0.1, mad)
	g = _inicio_peca()
	_engrenagem(12, 0.24, 0.1, mad2, 0.0)
	_viga(Vector3(0, 0, 0.1), Vector3(0.36, 0, 0.1), 0.07, ferro, 0.02)
	_cil(0.04, 0.04, 0.22, 6, Vector3(0.36, 0, 0.2), Vector3(90, 0, 0), mad2.lightened(0.15))
	_fim_peca(g, "Gira_engrenagem", Transform3D(Basis(), c1), Vector2(1.2, 0.0))
	# Fole e chaminé de bambu à esquerda (o vapor sai do topo).
	_blocod(Vector3(0.4, 0.5, 0.5), Vector3(-1.0, 0.47, 0.05), Vector3(0, 0, 4), mad, 0.05)
	_cil(0.2, 0.24, 0.3, 8, Vector3(-1.0, 0.85, 0.05), Vector3.ZERO, ferro)
	_viga(Vector3(-1.0, 0.95, 0.05), Vector3(-1.02, 2.0, 0.0), 0.15, P.bambu.darkened(0.1))
	_cil(0.12, 0.09, 0.12, 8, Vector3(-1.02, 2.04, 0.0), Vector3.ZERO, ferro)
	_pecas_marcador("Vapor", Vector3(-1.02, 2.15, 0.0))
	# Prateleira dos chapéus prontos: degrau baixo na frente, com 4 lugares.
	_tipo = 1
	_blocod(Vector3(1.9, 0.08, 0.36), Vector3(0, 0.42, 0.88), Vector3.ZERO, mad2.lightened(0.05), 0.03)
	for x in [-0.88, 0.88]:
		_blocod(Vector3(0.1, 0.2, 0.3), Vector3(x, 0.31, 0.88), Vector3.ZERO, mad, 0.02)
	_tipo = 0
	for k in 4:
		_pecas_marcador("Estoque_%d" % (k + 1), Vector3(-0.7 + k * 0.47, 0.47, 0.9))
	_pecas_marcador("Molde", Vector3(0, ym + 0.1, 0.05))
	# Lanterna de papel pendurada na ponta esquerda da trave.
	var m := _marca()
	_caixa(Vector3(0.02, 0.3, 0.02), Vector3(-0.98, yt - 0.05, 0.12), Vector3.ZERO, P.corda)
	_esfera(0.15, Vector3(-0.98, yt - 0.28, 0.12), Vector3(1, 1.3, 1), P.papel, true, 7, 4)
	_vento_pendurado(m, yt + 0.1, 0.5, 0.8)


## Depois de salvo: Marker3D e, na máquina, brilho do molde, vapor e a animação "fabricar".
## Prensa desce (0,25-0,45 s), molde brilha (0,45-1,1 s), chapéu sai do
## molde com estica e encolhe (0,8-1,2 s) e o vapor sopra (0,45 s).
func _completar(nome: String, maquina: bool) -> void:
	var caminho := _dir.path_join(nome + ".scn")
	var raiz: Node3D = (load(caminho) as PackedScene).instantiate()
	var marc := {}
	for mk in _marcadores:
		var no := Marker3D.new()
		no.name = mk[0]
		no.position = mk[1]
		no.gizmo_extents = 0.15
		raiz.add_child(no)
		no.owner = raiz
		marc[mk[0]] = no
	_marcadores.clear()
	if maquina:
		_efeitos_maquina(raiz, marc)
	var ps := PackedScene.new()
	ps.pack(raiz)
	ResourceSaver.save(ps, caminho)
	raiz.free()


func _efeitos_maquina(raiz: Node3D, marc: Dictionary) -> void:
	# Brilho: anel aceso em volta do molde (só aparece na animação).
	var brilho := MeshInstance3D.new()
	brilho.name = "Brilho"
	var anel := TorusMesh.new()
	anel.inner_radius = 0.4
	anel.outer_radius = 0.52
	anel.rings = 16
	anel.ring_segments = 4
	brilho.mesh = anel
	var mb := StandardMaterial3D.new()
	mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mb.albedo_color = Color(P.luz1.r * 2.2, P.luz1.g * 2.0, P.luz1.b * 1.6)
	brilho.material_override = mb
	brilho.position = marc["Molde"].position
	brilho.scale = Vector3(1, 0.4, 1)
	brilho.visible = false
	brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(brilho)
	brilho.owner = raiz
	# Vapor: baforada curta (one_shot), poucas partículas grandes.
	var vapor := CPUParticles3D.new()
	vapor.name = "Vapor"
	vapor.position = marc["Vapor"].position
	marc["Vapor"].free()
	vapor.emitting = false
	vapor.one_shot = true
	vapor.amount = 8
	vapor.lifetime = 1.1
	vapor.explosiveness = 0.7
	vapor.direction = Vector3(0.2, 1, 0)
	vapor.spread = 18.0
	vapor.initial_velocity_min = 1.2
	vapor.initial_velocity_max = 1.8
	vapor.gravity = Vector3(0.3, 0.6, 0)
	vapor.damping_min = 1.0
	vapor.damping_max = 1.5
	vapor.scale_amount_min = 0.6
	vapor.scale_amount_max = 1.0
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.3))
	curva.add_point(Vector2(0.4, 1.0))
	curva.add_point(Vector2(1, 1.4))
	vapor.scale_amount_curve = curva
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1, 1, 1, 0.7))
	rampa.set_color(1, Color(1, 1, 1, 0.0))
	vapor.color_ramp = rampa
	var bola := SphereMesh.new()
	bola.radius = 0.18
	bola.height = 0.36
	bola.radial_segments = 6
	bola.rings = 3
	var mv := StandardMaterial3D.new()
	mv.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mv.vertex_color_use_as_albedo = true
	mv.albedo_color = P.branco.lerp(P.sombra, 0.15)
	bola.material = mv
	vapor.mesh = bola
	vapor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(vapor)
	vapor.owner = raiz
	# Animação.
	var prensa: Node3D = raiz.get_node("Prensa")
	var p0 := prensa.position
	var molde: Node3D = marc["Molde"]
	var y0 := molde.position.y
	var an := Animation.new()
	an.length = FABRICAR
	var t := an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Prensa:position")
	for k in [[0.0, 0.0], [0.25, 0.12], [0.42, -0.6], [0.5, -0.55], [0.8, -0.58], [1.4, 0.0], [FABRICAR, 0.0]]:
		an.track_insert_key(t, k[0], p0 + Vector3(0, k[1], 0))
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Brilho:visible")
	an.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	an.track_insert_key(t, 0.0, false)
	an.track_insert_key(t, 0.42, true)
	an.track_insert_key(t, 1.1, false)
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Brilho:scale")
	for k in [[0.42, 0.7], [0.6, 1.25], [0.9, 1.0], [1.1, 1.4]]:
		an.track_insert_key(t, k[0], Vector3(k[1], 0.4, k[1]))
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Molde:scale")
	for k in [[0.0, Vector3.ONE * 0.01], [0.8, Vector3.ONE * 0.01], [0.95, Vector3(0.8, 1.4, 0.8)], [1.08, Vector3(1.25, 0.8, 1.25)], [1.2, Vector3.ONE], [FABRICAR, Vector3.ONE]]:
		an.track_insert_key(t, k[0], k[1])
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Molde:position")
	for k in [[0.0, 0.0], [0.8, 0.0], [1.0, 0.35], [1.2, 0.05], [FABRICAR, 0.05]]:
		an.track_insert_key(t, k[0], Vector3(molde.position.x, y0 + k[1], molde.position.z))
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Vapor:emitting")
	an.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	an.track_insert_key(t, 0.0, false)
	an.track_insert_key(t, 0.45, true)
	var lib := AnimationLibrary.new()
	lib.add_animation("fabricar", an)
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	ap.add_animation_library("", lib)
	raiz.add_child(ap)
	ap.owner = raiz


## Enfeite da classe no plano XY (de frente para +z), ~0,5 m.
func _emblema(classe: String) -> void:
	var aco := Color(0.78, 0.8, 0.86)
	var ouro: Color = P.ouro
	match classe:
		"guerreiro":  # duas katanas cruzadas com tsuba
			for s in [-1.0, 1.0]:
				_blocod(Vector3(0.05, 0.56, 0.03), Vector3(s * 0.05, 0.06, 0), Vector3(0, 0, 38 * s), aco, 0.01)
				_blocod(Vector3(0.05, 0.18, 0.04), Vector3(s * 0.2, -0.2, 0.01), Vector3(0, 0, 38 * s), Color(0.12, 0.08, 0.1), 0.01)
				_cil(0.06, 0.06, 0.03, 8, Vector3(s * 0.14, -0.12, 0.03), Vector3(90, 0, 0), ouro)
		"arqueiro":  # shuriken de 4 pontas
			for k in 4:
				var a := TAU * k / 4.0 + PI / 4
				var dir := Vector3(cos(a), sin(a), 0)
				var lado := Vector3(-sin(a), cos(a), 0)
				for f in [1.0, -1.0]:
					var zf := Vector3(0, 0, 0.02 * f)
					if f > 0:
						_tri(lado * 0.08 + zf, dir * 0.3 + zf, -lado * 0.08 + zf, aco, Vector3(0, 0, 1))
					else:
						_tri(-lado * 0.08 + zf, dir * 0.3 + zf, lado * 0.08 + zf, aco.darkened(0.3), Vector3(0, 0, -1))
			_cil(0.07, 0.07, 0.06, 10, Vector3.ZERO, Vector3(90, 0, 0), ouro)
		"monge":  # lótus de chi: 6 pétalas e miolo aceso
			for k in 6:
				var a := TAU * k / 6.0 + PI / 2
				_esfera(0.11, Vector3(cos(a) * 0.15, sin(a) * 0.15, 0), Vector3(1.0, 0.55, 0.4), P.branco if k % 2 else P.chao_folha2, false, 6, 3)
			_esfera(0.08, Vector3(0, 0, 0.03), Vector3(1, 1, 0.6), ouro, false, 6, 3)
		"construtor":  # machado de lenhador
			_viga(Vector3(-0.16, -0.24, 0), Vector3(0.12, 0.26, 0), 0.06, P.madeira2)
			_blocod(Vector3(0.24, 0.17, 0.04), Vector3(0.0, 0.2, 0.01), Vector3(0, 0, -30), aco, 0.02)
			_blocod(Vector3(0.05, 0.2, 0.05), Vector3(-0.1, 0.27, 0.01), Vector3(0, 0, -30), aco.darkened(0.2), 0.01)
			_cil(0.035, 0.035, 0.06, 6, Vector3(-0.15, -0.22, 0), Vector3(0, 0, 30), Color(0.12, 0.08, 0.1))


## Liga os modelos nos temas, se o esquema já tiver os campos do contrato
## (o Diretor de Jogabilidade cria os campos; até lá, só salva os modelos).
func _ligar_temas() -> void:
	for tema in TEMAS:
		var caminho := "res://config/temas/%s.tres" % tema
		var t: Resource = load(caminho)
		if t == null or not ("maquina_model" in t):
			print("tema %s: campos da economia ainda não existem no ThemeConfig" % tema)
			continue
		var d := "res://assets/ninja/%s/" % tema
		var arv: Array[PackedScene] = []
		var bam: Array[PackedScene] = []
		for e in 3:
			arv.append(load(d + "arvore_e%d.scn" % (e + 1)))
			bam.append(load(d + "bambu_e%d.scn" % (e + 1)))
		t.arvore_estagios = arv
		t.bambu_estagios = bam
		t.maquina_model = load(d + "maquina_chapeu.scn")
		t.pilha_model = load(d + "pilha_toras.scn")
		t.tora_model = load(d + "tora.scn")
		ResourceSaver.save(t, caminho)
		print("tema %s: economia ligada" % tema)
