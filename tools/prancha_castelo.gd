extends "res://tools/gerar_cenario_ninja.gd"
## Prancha do castelo novo (Torre da Máscara) e do pátio em ferradura, para o
## pitaco do Julio ANTES de produzir. Roda o jogo de verdade, esconde o castelo
## antigo e põe as peças novas (feitas aqui por código) no castelo azul.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/prancha_castelo.gd -- DIR --vista=patio --autoplay [--tema=N]
## Salva DIR/<tema>_{planta,jogo,torre}.png. Sem tipos do jogo aqui.

const CD := 60.0                 # castle_distance do mapa
const CF := Vector2(2, 0)         # centro da ferradura (coordenadas locais)
const R := 22.0                  # raio da muralha (linha do meio)
const BOCA := 42.0               # meia-abertura da saída larga (graus)
const LADO := 100.0              # ângulo dos portões laterais
const KEEP := Vector2(-18.5, 0)  # Torre da Máscara, no fundo do arco
const ALT_MURO := 3.2

# Pátio novo (locais). Ordem dos chapéus = hat_class_list (cima, baixo, cima, baixo).
const HATS := [Vector2(-5.95, -12.72), Vector2(-5.95, 12.72), Vector2(-10.72, -7.95), Vector2(-10.72, 7.95)]
const OFICINAS := [Vector2(7.99, -14.83), Vector2(7.99, 14.83)]
const MAGOS := [Vector2(14.26, -10.28), Vector2(14.26, 10.28)]  # [0] Luz (cima), [1] Sombra (baixo)
const MASCARA := Vector2(-9.5, 0)
const PILHA := Vector2(3.0, 10.0)
const ARVORES := [Vector2(-1.0, 27.5), Vector2(4.5, 28.5)]

var _tema := "dia"
var _saida := ""


func _gerar_tudo() -> bool:
	return false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0]
	var nomes := ["dia", "crepusculo", "oni", "luar"]
	for a in args:
		if a.begins_with("--tema="):
			_tema = nomes[int(a.trim_prefix("--tema="))]
	P = TEMAS[_tema]
	_dir = "prancha_" + _tema
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar.call_deferred()


## Esconde o castelo antigo e põe os terrenos nos lugares novos (só na memória).
func _preparar_mapa() -> void:
	var cfg: Resource = root.get_node("/root/Config").cfg
	var m: Resource = cfg.maps[0]
	m.tower_spots = PackedVector2Array()
	m.courtyard_props.clear()
	m.hat_spots = PackedVector2Array(HATS)
	m.oficina_spots = PackedVector2Array(OFICINAS)
	m.mago_spots = PackedVector2Array(MAGOS)
	m.princess_spot = MASCARA
	m.pilha_spot = PILHA
	m.tree_spots = PackedVector2Array(ARVORES)
	m.keep_collider_size = Vector3(0.1, 0.1, 0.1)
	for th in cfg.themes:
		th.keep_scale = 0.0001
		th.wall_scale = 0.0001


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	_preparar_mapa()
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	for k in 20:
		await process_frame
	var g: Node = jogo if "oficinas" in jogo else jogo.find_child("Game", true, false)
	var raiz := Node3D.new()
	raiz.name = "CasteloNovo"
	raiz.position = Vector3(-CD, 0, 0)
	g.add_child(raiz)
	_montar(raiz)
	for of in g.oficinas:
		if of.team == 0 and of.estado != 2:
			of.add_progress(1.0, null)
	for k in 80:
		await process_frame
	for c in g.find_children("*", "CanvasLayer", true, false):
		c.visible = false
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var base := Vector3(-CD, 0, 0)
	# 1) Planta (de cima, ortográfica).
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 56.0
	cam.position = base + Vector3(CF.x - 2, 60, 0.01)
	cam.look_at(base + Vector3(CF.x - 2, 0, 0), Vector3(0, 0, -1))
	await _foto("planta")
	# 2) Ângulo do jogo, um pouco mais alto para caber a ferradura.
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	var alvo := base + Vector3(-2, 0, 1)
	cam.position = alvo + Vector3(0, 21, 19) * 1.55
	cam.look_at(alvo)
	await _foto("jogo")
	# 3) A torre vista de dentro do pátio.
	cam.position = base + Vector3(6, 2.4, -10)
	cam.look_at(base + Vector3(KEEP.x, 8.0, 1.0))
	await _foto("torre")
	quit()


func _foto(nome: String) -> void:
	for k in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_saida.path_join("%s_%s.png" % [_tema, nome]))


# --- Montagem -----------------------------------------------------------------

func _local(a_graus: float, r: float) -> Vector3:
	var a := deg_to_rad(a_graus)
	return Vector3(CF.x + r * cos(a), 0, CF.y + r * sin(a))


func _cena(path: String, pai: Node3D, pos: Vector3, rot_y: float, esc := 1.0) -> Node3D:
	var n: Node3D = (load("res://assets/ninja/%s/%s" % [_tema, path]) as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * esc
	pai.add_child(n)
	return n


func _montar(raiz: Node3D) -> void:
	var azul := TIMES["azul"]
	# Muralha em arco: trechos de [a0, a1] graus, módulos de até 14°, pilar em cada junta.
	_pilar(); var pilar := _no("pilar")
	var trechos := [[BOCA, LADO - 16.0], [LADO + 16.0, 166.0]]
	for s in [1.0, -1.0]:
		for tr in trechos:
			var a0: float = tr[0] * s
			var a1: float = tr[1] * s
			var n := int(ceil(absf(a1 - a0) / 14.0))
			for i in n:
				var am := lerpf(a0, a1, (i + 0.5) / n)
				var corda := 2.0 * R * sin(deg_to_rad(absf(a1 - a0) / n) / 2.0)
				var mod := _cena("muralha.scn", raiz, _local(am, R), PI / 2 - deg_to_rad(am))
				mod.scale.x = corda / 6.0
			for i in n + 1:
				if i % 2 == 1 and i != n:
					continue
				var aj := lerpf(a0, a1, float(i) / n)
				var p := pilar.duplicate() as Node3D
				p.position = _local(aj, R)
				p.rotation.y = -deg_to_rad(aj)
				raiz.add_child(p)
		# Portão lateral e torres da saída larga.
		_cena("portao.scn", raiz, _local(LADO * s, R), -deg_to_rad(LADO * s))
		var tb := _cena("torre_alta_azul.scn", raiz, _local(BOCA * s, R + 0.4), 0.0)
		_cena("bandeira_azul.scn", tb, Vector3(0, 8.0, 0), 0.0)
	pilar.free()
	# Torre da Máscara.
	_torre_mascara(azul)
	var torre := _no("torre_mascara")
	torre.position = Vector3(KEEP.x, 0, KEEP.y)
	raiz.add_child(torre)
	for z in [-3.2, 3.2]:
		_cena("bandeira_azul.scn", raiz, Vector3(KEEP.x + 4.6, 4.0, z), 0.0, 1.3)
	# Chão do pátio: praça de pedra, trilhas para as saídas e o anel das casinhas.
	_praca()
	var chao := _no("praca")
	chao.position = Vector3(CF.x, 0, CF.y)
	raiz.add_child(chao)
	# Luzes (no crepúsculo elas mandam; de dia quase não aparecem).
	var luzes := [[Vector3(KEEP.x + 5.2, 7.6, 0), azul, 9.0, 2.2], [Vector3(KEEP.x + 5.8, 1.6, -2.6), Color(1, 0.6, 0.25), 7.0, 1.6], [Vector3(KEEP.x + 5.8, 1.6, 2.6), Color(1, 0.6, 0.25), 7.0, 1.6]]
	for s in [1.0, -1.0]:
		luzes.append([_local(LADO * s, R - 3.0) + Vector3(0, 3.2, 0), Color(1, 0.75, 0.4), 7.0, 1.2])
		luzes.append([_local(BOCA * s, R - 3.0) + Vector3(0, 3.5, 0), Color(1, 0.75, 0.4), 7.0, 1.2])
	for l in luzes:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.omni_range = l[2]
		o.light_energy = l[3] * (1.0 if _tema != "dia" else 0.5)
		raiz.add_child(o)


## Fecha o que foi desenhado num nó (como _salvar, mas sem gravar arquivo).
func _no(nome: String) -> Node3D:
	_contorno = true
	var root3 := Node3D.new()
	root3.name = nome
	var mi := MeshInstance3D.new()
	mi.mesh = _malha()
	root3.add_child(mi)
	for pc in _pecas:
		var no := MeshInstance3D.new()
		no.name = String(pc[0]).get_file()
		no.mesh = pc[1]
		no.transform = pc[2]
		root3.add_child(no)
	_pecas.clear()
	return root3


# --- Peças novas ----------------------------------------------------------------

## Pilar redondo de pedra entre dois módulos de muralha (esconde a junta do arco),
## com chapéu de telha e lanterna virada para dentro (-x local = centro).
func _pilar() -> void:
	_cil(1.45, 1.75, ALT_MURO + 1.6, 8, Vector3(0, (ALT_MURO + 1.6) / 2, 0), Vector3.ZERO, P.pedra)
	for k in 3:
		_cil(1.72 - k * 0.08, 1.74 - k * 0.08, 0.06, 8, Vector3(0, 0.6 + k * 1.2, 0), Vector3.ZERO, P.pedra2)
	_cil(1.55, 1.55, 0.2, 8, Vector3(0, ALT_MURO + 1.7, 0), Vector3.ZERO, P.madeira)
	_cil(0.2, 1.8, 0.8, 8, Vector3(0, ALT_MURO + 2.2, 0), Vector3.ZERO, P.telhado.darkened(0.25))
	_esfera(0.16, Vector3(0, ALT_MURO + 2.7, 0), Vector3.ONE, P.ouro, true)
	_lanterna_papel(Vector3(-1.6, ALT_MURO - 0.2, 0), P.papel, 0.24)


## Torre da Máscara: base de pedra inclinada, 3 andares altos e estreitos,
## a máscara Oni gigante na frente (+x), portão, braseiros e lanternas.
## Olhos, lanternas e chamas são peças à parte (para animar no jogo).
func _torre_mascara(time: Color) -> void:
	var telha: Color = P.telhado.lerp(time, 0.35)
	var escuro := Color(0.07, 0.06, 0.08)
	# Base (ishigaki) 8 m embaixo, 7 m em cima, 4,4 m de altura.
	_cil(4.95, 5.66, 4.4, 4, Vector3(0, 2.2, 0), Vector3(0, 45, 0), P.pedra)
	for k in 5:
		_cil(5.6 - k * 0.15, 5.63 - k * 0.15, 0.06, 4, Vector3(0, 0.45 + k * 0.85, 0), Vector3(0, 45, 0), P.pedra2)
	for k in 6:  # musgo nas juntas
		var ang := k * 1.05
		_esfera(0.5, Vector3(cos(ang) * 4.3, 0.4, sin(ang) * 4.3), Vector3(1.4, 0.5, 1.0), P.musgo)
	# Andares: [largura, altura, y0].
	var andares := [[6.6, 4.6, 4.4], [5.0, 3.6, 10.0], [3.6, 2.8, 14.8]]
	var tetos := [[8.6, 1.9, 0.9], [6.8, 1.6, 0.75], [5.2, 2.4, 0.6]]
	for i in 3:
		var a: Array = andares[i]
		var w: float = a[0]
		var h: float = a[1]
		var y0: float = a[2]
		_caixa(Vector3(w, h, w), Vector3(0, y0 + h / 2, 0), Vector3.ZERO, P.reboco)
		_caixa(Vector3(w + 0.08, 0.28, w + 0.08), Vector3(0, y0 + 0.14, 0), Vector3.ZERO, P.madeira)
		_caixa(Vector3(w + 0.08, 0.2, w + 0.08), Vector3(0, y0 + h - 0.1, 0), Vector3.ZERO, P.madeira)
		for s in [-1, 1]:  # pilares de madeira nas quinas
			for q in [-1, 1]:
				_caixa(Vector3(0.3, h, 0.3), Vector3(s * w / 2, y0 + h / 2, q * w / 2), Vector3.ZERO, P.madeira)
		# Janelas acesas nas laterais e atrás (na frente do 1º andar fica a máscara).
		for k in range(-1, 2):
			if i == 2 and k != 0:
				continue
			for s in [-1, 1]:
				_caixa(Vector3(0.6, 0.8, 0.06), Vector3(k * w * 0.28, y0 + h * 0.62, s * (w / 2 + 0.03)), Vector3.ZERO, P.papel, true)
			_caixa(Vector3(0.06, 0.8, 0.6), Vector3(-(w / 2 + 0.03), y0 + h * 0.62, k * w * 0.28), Vector3.ZERO, P.papel, true)
			if i > 0:
				_caixa(Vector3(0.06, 0.8, 0.6), Vector3(w / 2 + 0.03, y0 + h * 0.62, k * w * 0.28), Vector3.ZERO, P.papel, true)
		var t: Array = tetos[i]
		_telhado(Vector3(0, y0 + h, 0), t[0], t[0], t[1], telha, t[2])
		var lb: float = t[0] + 2 * t[2]
		for q in [-1, 1]:  # friso na cor do time na ponta do beiral
			_caixa(Vector3(lb, 0.1, 0.1), Vector3(0, y0 + h + 0.08, q * lb / 2), Vector3.ZERO, time * 1.2, true)
			_caixa(Vector3(0.1, 0.1, lb), Vector3(q * lb / 2, y0 + h + 0.08, 0), Vector3.ZERO, time * 1.2, true)
	# Frontão curvo (karahafu) sobre a máscara, com borda dourada.
	var yf := 9.0
	_tri(Vector3(4.4, yf, -2.6), Vector3(4.4, yf, 2.6), Vector3(3.6, yf + 2.2, 0), telha, Vector3(1, 0.3, 0))
	_viga(Vector3(4.45, yf + 0.05, -2.7), Vector3(3.65, yf + 2.25, 0), 0.14, P.ouro)
	_viga(Vector3(4.45, yf + 0.05, 2.7), Vector3(3.65, yf + 2.25, 0), 0.14, P.ouro)
	_caixa(Vector3(0.3, 0.3, 5.6), Vector3(4.4, yf - 0.05, 0), Vector3.ZERO, P.madeira)
	# Shachi dourados no topo.
	var topo: float = 14.8 + 2.8 + 2.4
	for s in [-1, 1]:
		_cil(0.0, 0.22, 0.75, 6, Vector3(0, topo + 0.3, s * 0.75), Vector3(s * 25, 0, 0), P.ouro, true)
	# Máscara Oni (frente do 1º andar): rosto laqueado, chifres, presas.
	var mx := 3.45
	var rosto := Color(0.55, 0.08, 0.07)
	_esfera(1.0, Vector3(mx, 6.7, 0), Vector3(0.9, 2.5, 2.2), rosto, false, 12, 8)
	for s in [-1, 1]:
		# Sobrancelhas em V (bravo): ponta de dentro baixa.
		_caixa(Vector3(0.55, 0.42, 1.9), Vector3(mx + 0.62, 7.95, s * 0.95), Vector3(s * -24, 0, 0), escuro)
		# Chifres grossos saindo das têmporas, para cima e para fora.
		_cil(0.0, 0.55, 3.0, 8, Vector3(mx + 0.1, 9.3, s * 1.9), Vector3(s * -32, 0, 10), Color(0.95, 0.9, 0.76))
		_cil(0.62, 0.62, 0.3, 8, Vector3(mx + 0.2, 8.15, s * 1.45), Vector3(s * -32, 0, 10), P.ouro, true)
		# Bochechas e mandíbula salientes.
		_esfera(0.7, Vector3(mx + 0.45, 5.9, s * 1.25), Vector3(0.8, 1.0, 0.9), rosto.lightened(0.06), false, 8, 5)
		# Presas: grandes de cima (para baixo) e pequenas de baixo.
		_cil(0.0, 0.2, 1.0, 5, Vector3(mx + 0.82, 4.75, s * 0.85), Vector3(0, 0, 180), P.branco)
		_cil(0.0, 0.14, 0.6, 5, Vector3(mx + 0.82, 4.3, s * 0.4), Vector3.ZERO, P.branco)
		# Juba escura dos lados do rosto.
		_esfera(0.9, Vector3(mx - 0.5, 6.4, s * 2.3), Vector3(0.6, 2.0, 0.6), escuro.lightened(0.05), false, 7, 5)
	_caixa(Vector3(0.4, 0.9, 2.6), Vector3(mx + 0.62, 4.75, 0), Vector3.ZERO, Color(0.18, 0.02, 0.03))  # boca
	_caixa(Vector3(0.42, 0.14, 2.7), Vector3(mx + 0.66, 5.2, 0), Vector3.ZERO, P.branco)                 # dentes
	_caixa(Vector3(0.6, 0.8, 0.8), Vector3(mx + 0.85, 6.55, 0), Vector3.ZERO, rosto.darkened(0.2))     # nariz
	_esfera(0.32, Vector3(mx + 0.75, 8.55, 0), Vector3.ONE, P.ouro, true)                              # joia da testa
	_cil(0.0, 0.25, 0.7, 6, Vector3(mx + 0.6, 9.0, 0), Vector3(0, 0, -10), P.ouro, true)               # chifrinho do meio
	var g := _inicio_peca()
	for s in [-1, 1]:
		_esfera(0.42, Vector3(0, 0, s * 0.9), Vector3(0.5, 0.6, 1.1), time.lerp(Color(1, 0.95, 0.5), 0.25) * 1.3, true, 10, 6)
	_fim_peca(g, "Olhos", Transform3D(Basis(), Vector3(mx + 0.72, 7.35, 0)))
	# Portão da torre (embaixo da máscara) e braseiros dos dois lados.
	_caixa(Vector3(0.6, 3.4, 3.6), Vector3(5.1, 1.7, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.3, 2.7, 2.6), Vector3(5.42, 1.35, 0), Vector3.ZERO, escuro.lightened(0.08))
	for zz in [-0.9, 0.0, 0.9]:
		for yy in [0.6, 1.4, 2.2]:
			_esfera(0.08, Vector3(5.58, yy, zz), Vector3.ONE, P.ouro, true, 5, 3)
	for s in [-1, 1]:
		var b := Vector3(5.8, 0, s * 2.6)
		_cil(0.28, 0.4, 1.0, 8, b + Vector3(0, 0.5, 0), Vector3.ZERO, P.pedra2)
		_cil(0.55, 0.3, 0.35, 8, b + Vector3(0, 1.15, 0), Vector3.ZERO, Color(0.2, 0.18, 0.18))
		g = _inicio_peca()
		_cil(0.0, 0.42, 0.9, 6, Vector3(0, 0.45, 0), Vector3.ZERO, P.luz2 * 1.1, true)
		_cil(0.0, 0.25, 0.7, 5, Vector3(0.06, 0.55, 0.04), Vector3.ZERO, P.luz1 * 1.15, true)
		_fim_peca(g, "Chama_%d" % (s + 1), Transform3D(Basis(), b + Vector3(0, 1.3, 0)))
	# Lanternas penduradas nas quinas do 1º e 2º telhado (balançam no jogo).
	for i in 2:
		var w2: float = [8.6, 6.8][i] / 2.0 + 0.3
		var yl: float = [8.5, 13.1][i]
		for s in [-1, 1]:
			for q in [-1, 1]:
				g = _inicio_peca()
				_cil(0.02, 0.02, 0.7, 4, Vector3(0, -0.35, 0), Vector3.ZERO, escuro)
				_lanterna_papel(Vector3(0, -0.95, 0), P.papel if (s + q) != 0 else time.lerp(P.papel, 0.4), 0.3)
				_fim_peca(g, "Lanterna_%d_%d_%d" % [i, s + 1, q + 1], Transform3D(Basis(), Vector3(s * w2, yl, q * w2)))
	# Escadinha de pedra até o portão.
	for k in 3:
		_caixa(Vector3(0.6, 0.18 * (3 - k), 4.2), Vector3(5.6 + k * 0.55, 0.09 * (3 - k), 0), Vector3.ZERO, P.pedra2)


## Chão do pátio (centro da ferradura na origem): praça redonda, trilhas de pedra
## para a saída larga e os portões laterais, e a calçada do anel das casinhas.
func _praca() -> void:
	var laje: Color = P.pedra.lerp(P.reboco, 0.25)
	_cil(7.5, 7.5, 0.06, 28, Vector3(-4, 0.03, 0), Vector3.ZERO, laje)
	_cil(7.6, 7.6, 0.04, 28, Vector3(-4, 0.02, 0), Vector3.ZERO, P.pedra2)
	_cil(1.2, 1.2, 0.08, 16, Vector3(-4, 0.05, 0), Vector3.ZERO, P.ouro)
	# Trilhas (lajes soltas) do centro às saídas.
	for alvo in [Vector3(22, 0, 0), Vector3(-2.5, 0, 21), Vector3(-2.5, 0, -21)]:
		var de := Vector3(-4, 0, 0)
		var n := 14
		for k in n:
			var p: Vector3 = de.lerp(alvo, (k + 2.0) / (n + 2))
			var ang := atan2(-(alvo - de).z, (alvo - de).x)
			_caixa(Vector3(1.0, 0.06, 3.0), p + Vector3(0, 0.03, 0), Vector3(0, rad_to_deg(ang), 0), laje.darkened(0.04 * (k % 2)))
	# Calçada do anel (onde ficam as casinhas), em lajotas.
	for a in range(-170, 171, 6):
		if absf(a) < 38:
			continue
		var r := 15.5
		var ar := deg_to_rad(a)
		_caixa(Vector3(2.8, 0.05, 1.5), Vector3(r * cos(ar), 0.025, r * sin(ar)), Vector3(0, -a + 90, 0), laje.darkened(0.06 * (a / 6 % 2)))


# --- Ferramentas copiadas de gerar_mapa_rio.gd (ele não tem guarda no _init) ---

func _telhado(base: Vector3, w: float, d: float, h: float, cor: Color, beiral := 0.6) -> void:
	var r := maxf(w - d, 0.2) / 2.0
	var c0 := [Vector3(-w / 2, 0, -d / 2), Vector3(w / 2, 0, -d / 2), Vector3(w / 2, 0, d / 2), Vector3(-w / 2, 0, d / 2)]
	var topo := [Vector3(-r, h, 0), Vector3(r, h, 0)]
	var o := base
	_quad(o + c0[3], o + c0[2], o + topo[1], o + topo[0], cor, Vector3(0, 1, 1))
	_quad(o + c0[0], o + c0[1], o + topo[1], o + topo[0], cor, Vector3(0, 1, -1))
	_tri(o + c0[1], o + c0[2], o + topo[1], cor.darkened(0.08), Vector3(1, 1, 0))
	_tri(o + c0[0], o + c0[3], o + topo[0], cor.darkened(0.08), Vector3(-1, 1, 0))
	var e := beiral
	var c1 := [Vector3(-w / 2 - e, 0.12, -d / 2 - e), Vector3(w / 2 + e, 0.12, -d / 2 - e), Vector3(w / 2 + e, 0.12, d / 2 + e), Vector3(-w / 2 - e, 0.12, d / 2 + e)]
	for k in 4:
		var k2 := (k + 1) % 4
		var mid: Vector3 = (c0[k] + c0[k2]) / 2.0
		_quad(o + c0[k], o + c0[k2], o + c1[k2], o + c1[k], cor.lightened(0.06), Vector3(mid.x, 2.0, mid.z))
		_quad(o + c0[k] - Vector3(0, 0.08, 0), o + c0[k2] - Vector3(0, 0.08, 0), o + c1[k2] - Vector3(0, 0.02, 0), o + c1[k] - Vector3(0, 0.02, 0), Color(0.08, 0.07, 0.09), Vector3(0, -1, 0))
	_caixa(Vector3(2 * r + 0.3, 0.18, 0.3), o + Vector3(0, h + 0.05, 0), Vector3.ZERO, cor.darkened(0.3))


func _lanterna_papel(pos: Vector3, cor: Color, r := 0.22) -> void:
	_cil(0.02, 0.02, 0.3, 4, pos + Vector3(0, r * 1.3 + 0.15, 0), Vector3.ZERO, Color(0.1, 0.1, 0.1))
	_esfera(r, pos, Vector3(1, 1.35, 1), cor, true, 8, 5)
	_cil(r * 0.6, r * 0.6, 0.06, 8, pos + Vector3(0, r * 1.3, 0), Vector3.ZERO, Color(0.12, 0.1, 0.1))
	_cil(r * 0.6, r * 0.6, 0.06, 8, pos - Vector3(0, r * 1.3, 0), Vector3.ZERO, Color(0.12, 0.1, 0.1))
