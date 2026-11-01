extends "res://tools/gerar_cenario_ninja.gd"
## Modelos da Economia do Construtor (Ciclo 2.3), nos quatro temas:
##   arvore_e1/e2/e3, bambu_e1/e2/e3  plantas cortáveis nos 3 estágios
##   tora                             tora para carregar (centro na origem, eixo x)
##   maquina_chapeu                   maquininha: Prensa, Gira_engrenagem, Molde, Brilho,
##                                    Vapor, Enfeite, Estoque_1..4 e a animação "fabricar"
##   maquina_<classe>                 maquininha própria da classe (mesmos nós; ver MAQUINAS) + nível 2:
##                                    nós N2_* (escondidos) e a animação "subir_nivel"
##   emblema_<classe>                 enfeite da frente da máquina (nome do .tres da classe; armadilheiro e
##                                    bombardeiro = ramos do Construtor no Ciclo 2.4)
## Rode depois de tools/gerar_cenario_ninja.gd:
##   godot --headless --path . -s tools/gerar_economia.gd
## Tudo de frente para +z (a câmera do jogo olha de +z).

const FABRICAR := 2.0  # duração da animação "fabricar" (s)
## Maquininha própria de cada classe (nome do .tres): maquina_<classe>.scn, com os
## mesmos nós e a mesma animação da maquina_chapeu (que fica de reserva).
## Só as classes com maquininha no pátio (GameConfig.hat_class_list): o jogo
## nunca carrega as outras. Os desenhos de ronin_oni, arqueiro_yumi e das
## kitsunes luz/sombria continuam em _maquina_classe(): ponha o nome aqui se
## uma delas ganhar maquininha.
const MAQUINAS := ["guerreiro", "arqueiro", "kitsune", "construtor"]

var _cor_brilho := Color(-1, 0, 0)  # brilho do molde da próxima máquina (-1 = luz1 do tema)
var _cor_vapor := Color(-1, 0, 0)


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
		_deposito(); _salvar("deposito_madeira"); _completar("deposito_madeira", false)
		_maquina(); _salvar("maquina_chapeu"); _completar("maquina_chapeu", true)
		for c in MAQUINAS:
			_maquina_classe(c); _salvar("maquina_" + c); _completar("maquina_" + c, true)
		for c in ["guerreiro", "arqueiro", "construtor", "kitsune", "ronin_oni", "arqueiro_yumi", "armadilheiro", "bombardeiro", "kitsune_luz", "kitsune_sombria"]:
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
		_cerca_madura(1.25)
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
		_cerca_madura(1.35)


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


## Planta madura ("pode cortar"): 4 estacas baixas com corda e papéis
## acesos em volta da base. Lê de longe sem ser um círculo no chão.
func _cerca_madura(r: float) -> void:
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		_viga(p, p + Vector3(0, 0.55, 0), 0.08, P.madeira2)
		_caixa(Vector3(0.1, 0.16, 0.02), p + Vector3(0, 0.38, 0.06), Vector3(0, -rad_to_deg(a) + 90, 0), P.luz1, true)
		var q := Vector3(cos(a + PI / 2) * r, 0, sin(a + PI / 2) * r)
		_viga(p + Vector3(0, 0.48, 0), q + Vector3(0, 0.48, 0), 0.035, P.corda)


## Depósito de madeira do castelo (substitui a pilha): galpão de uma água
## sobre o cavalete de toras (Nivel_1..4 = estoque) e, na frente, a boca
## onde o Construtor joga a tora: moldura de vigas, fundo escuro, rampa e
## lanterna. Placa com a tora pintada; o número fica no nó Contador.
## ~2,6 x 2,2 m de chão.
func _deposito() -> void:
	_pilha_toras()
	var mad: Color = P.madeira
	_tipo = 3
	_blocod(Vector3(2.6, 0.16, 2.3), Vector3(0, 0.08, -0.1), Vector3.ZERO, P.pedra2, 0.05)
	_tipo = 0
	# Galpão: 4 postes e telhado de uma água inclinado para trás.
	for x in [-1.15, 1.15]:
		_viga(Vector3(x, 0.16, 0.75), Vector3(x, 2.35, 0.75), 0.15, mad)
		_viga(Vector3(x, 0.16, -0.95), Vector3(x, 1.95, -0.95), 0.15, mad)
	_viga(Vector3(-1.25, 2.35, 0.75), Vector3(1.25, 2.35, 0.75), 0.14, mad)
	_tipo = 2
	_blocod(Vector3(2.8, 0.1, 2.1), Vector3(0, 2.25, -0.1), Vector3(-11, 0, 0), P.telhado, 0.04)
	_tipo = 1
	_blocod(Vector3(2.3, 1.6, 0.08), Vector3(0, 0.95, -1.0), Vector3.ZERO, P.madeira2.darkened(0.15), 0.03)
	_tipo = 0
	# Boca de entrega na frente: buraco escuro com moldura e rampa de tábuas.
	var zb := 1.15
	_ao = 0.25
	_blocod(Vector3(1.1, 0.05, 0.7), Vector3(0, 0.17, zb), Vector3.ZERO, Color(0.05, 0.04, 0.05), 0.0)
	_ao = 1.0
	for s in [-1.0, 1.0]:
		_blocod(Vector3(0.14, 0.24, 0.86), Vector3(s * 0.62, 0.24, zb), Vector3.ZERO, mad, 0.03)
		_blocod(Vector3(1.38, 0.24, 0.14), Vector3(0, 0.24, zb + s * 0.43), Vector3.ZERO, mad, 0.03)
	_tipo = 1
	_blocod(Vector3(1.0, 0.06, 0.9), Vector3(0, 0.2, zb + 0.85), Vector3(-14, 0, 0), P.madeira2, 0.02)
	_tipo = 0
	# Lanterna no poste da frente e placa com a tora.
	var m := _marca()
	_caixa(Vector3(0.02, 0.3, 0.02), Vector3(1.15, 2.05, 0.95), Vector3.ZERO, P.corda)
	_esfera(0.15, Vector3(1.15, 1.82, 0.95), Vector3(1, 1.3, 1), P.papel, true, 7, 4)
	_vento_pendurado(m, 2.2, 0.5, 0.8)
	_blocod(Vector3(0.9, 0.42, 0.06), Vector3(0, 2.0, 0.82), Vector3(-8, 0, 0), P.madeira2.lightened(0.05), 0.03)
	_tora(Vector3(0, 2.0, 0.88), 0.0, 0.55, 0.11)


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


# --- Maquininhas por classe -------------------------------------------------------

const FERRO := Color(0.2, 0.18, 0.19)
const YM := 0.95  # tampo da mesa (igual em todas: o código só usa os nós)


## Parte comum: base, mesa, molde, prateleira de estoque e marcadores. Cada
## classe veste isso com pórtico, prensa, peça que gira e enfeites próprios.
func _maquina_base(cor_base: Color, cor_mesa: Color, cor_molde: Color) -> void:
	_tipo = 3
	_blocod(Vector3(2.3, 0.22, 1.5), Vector3(0, 0.11, 0), Vector3.ZERO, cor_base, 0.06)
	_tipo = 1
	_blocod(Vector3(1.3, 0.14, 0.9), Vector3(0, YM - 0.07, 0), Vector3.ZERO, cor_mesa, 0.04)
	for x in [-0.55, 0.55]:
		for z in [-0.35, 0.35]:
			_blocod(Vector3(0.12, YM - 0.22, 0.12), Vector3(x, 0.22 + (YM - 0.36) / 2, z), Vector3.ZERO, cor_mesa.darkened(0.3), 0.02)
	_blocod(Vector3(1.9, 0.08, 0.36), Vector3(0, 0.42, 0.9), Vector3.ZERO, cor_mesa.lightened(0.05), 0.03)
	for x in [-0.88, 0.88]:
		_blocod(Vector3(0.1, 0.2, 0.3), Vector3(x, 0.31, 0.9), Vector3.ZERO, cor_mesa.darkened(0.3), 0.02)
	_tipo = 0
	_cil(0.42, 0.46, 0.08, 12, Vector3(0, YM + 0.04, 0.05), Vector3.ZERO, FERRO)
	_cil(0.47, 0.47, 0.04, 12, Vector3(0, YM + 0.08, 0.05), Vector3.ZERO, cor_molde)
	for k in 4:
		_pecas_marcador("Estoque_%d" % (k + 1), Vector3(-0.7 + k * 0.47, 0.47, 0.92))
	_pecas_marcador("Molde", Vector3(0, YM + 0.1, 0.05))


## Placa redonda do enfeite em `pos`, inclinada para a câmera.
func _placa(pos: Vector3, fundo: Color, aro: Color, r := 0.34) -> void:
	_cil(r, r, 0.07, 14, pos, Vector3(78, 0, 0), fundo)
	_cil(r + 0.04, r + 0.04, 0.04, 14, pos - Vector3(0, 0, 0.03), Vector3(78, 0, 0), aro)
	_pecas_marcador("Enfeite", pos + Vector3(0, 0.01, 0.05))


## Prensa: o que for desenhado em `desenho` (em volta da origem) vira o nó que desce.
func _prensa(desenho: Callable, y := 1.75) -> void:
	var g := _inicio_peca()
	desenho.call()
	_viga(Vector3(0, 0.17, 0), Vector3(0, 0.55, 0), 0.04, P.corda)
	_fim_peca(g, "Prensa", Transform3D(Basis(), Vector3(0, y, 0.05)))


## Peça que gira (eixo z, de frente para a câmera), com mancal atrás.
func _gira(nome: String, centro: Vector3, vel: float, desenho: Callable) -> void:
	_cil(0.06, 0.06, 0.3, 6, centro - Vector3(0, 0, 0.12), Vector3(90, 0, 0), FERRO)
	var g := _inicio_peca()
	desenho.call()
	_fim_peca(g, nome, Transform3D(Basis(), centro), Vector2(vel, 0.0))


func _maquina_classe(c: String) -> void:
	_rng.seed = 80 + c.length()
	match c:
		"guerreiro": _maq_forja()
		"arqueiro": _maq_shuriken()
		"kitsune": _maq_raposa()
		"kitsune_luz": _maq_raposa("luz")
		"kitsune_sombria": _maq_raposa("sombria")
		"ronin_oni": _maq_oni()
		"arqueiro_yumi": _maq_yumi()
		"construtor": _maq_serraria()
	_nivel2()


## Nível 2 (sobe quando a oficina da classe fica pronta): peças N2_* que o
## HatPad mostra no nível 2 e a animação "subir_nivel" faz brotar. Leitura de
## longe, estilo "prédio melhorado": degrau de pedra com quinas de ouro, dois
## estandartes da cor da classe com lanterna acesa e uma coroa dourada no topo.
func _nivel2() -> void:
	var cor: Color = P.torii if _cor_brilho.r < 0 else _cor_brilho
	var pano := Color(cor.r * 0.75, cor.g * 0.75, cor.b * 0.75)
	var topo := 1.8
	for v in V[0]:
		topo = maxf(topo, v.y)
	var g := _inicio_peca()
	_tipo = 3
	_blocod(Vector3(2.8, 0.14, 2.0), Vector3(0, 0.07, 0.05), Vector3.ZERO, P.pedra2.darkened(0.1), 0.05)
	_tipo = 0
	for x in [-1.38, 1.38]:
		for z in [-0.93, 1.03]:
			_blocod(Vector3(0.2, 0.22, 0.2), Vector3(x, 0.11, z), Vector3.ZERO, P.ouro, 0.03)
	_fim_peca(g, "N2_Base", Transform3D())
	for lado in [-1.0, 1.0]:
		g = _inicio_peca()
		_viga(Vector3(0, 0, 0), Vector3(0, 2.9, 0), 0.07, Color(0.12, 0.09, 0.1))
		_viga(Vector3(0, 2.75, 0), Vector3(-lado * 0.5, 2.75, 0), 0.05, Color(0.12, 0.09, 0.1))
		var m := _marca()
		_blocod(Vector3(0.44, 1.35, 0.03), Vector3(-lado * 0.24, 2.05, 0), Vector3.ZERO, pano, 0.01)
		_blocod(Vector3(0.46, 0.1, 0.04), Vector3(-lado * 0.24, 2.66, 0), Vector3.ZERO, P.ouro, 0.01)
		_blocod(Vector3(0.12, 0.9, 0.04), Vector3(-lado * 0.24, 2.0, 0.01), Vector3.ZERO, P.ouro.lerp(pano, 0.35), 0.01)
		_vento_pendurado(m, 2.72, 1.4, 0.7)
		var m2 := _marca()
		_esfera(0.16, Vector3(0, 3.02, 0), Vector3(1, 1.25, 1), P.luz1, true, 8, 4)
		_cil(0.08, 0.08, 0.05, 6, Vector3(0, 3.24, 0), Vector3.ZERO, Color(0.12, 0.09, 0.1))
		_vento_pendurado(m2, 3.25, 0.4, 0.3)
		_fim_peca(g, "N2_Estandarte_%s" % ("E" if lado < 0 else "D"), Transform3D(Basis(), Vector3(lado * 1.3, 0.14, -0.62)))
	g = _inicio_peca()
	var e := 1.4  # coroa grande: precisa ler da câmera do jogo
	_cil(0.2 * e, 0.24 * e, 0.12 * e, 8, Vector3(0, 0.06 * e, 0), Vector3.ZERO, P.ouro.darkened(0.2))
	for k in 5:
		var a := (k - 2) * 0.38
		var alto := (0.32 if k % 2 == 0 else 0.22) * e
		_blocod(Vector3(0.08, alto, 0.08) * e, Vector3(sin(a) * 0.2 * e, 0.12 * e + alto / 2, cos(a) * 0.05), Vector3(0, 0, -rad_to_deg(a) * 0.5), P.ouro, 0.02)
	_esfera(0.07 * e, Vector3(0, 0.5 * e, 0.02), Vector3.ONE, cor.lightened(0.3), true, 6, 3)
	_fim_peca(g, "N2_Coroa", Transform3D(Basis(), Vector3(0, topo + 0.15, -0.1)))


## Samurai: forja. Fornalha de pedra com a boca acesa, chaminé (fumaça),
## martelo-pilão de ferro, bigorna sob o molde e um suporte com duas katanas.
func _maq_forja() -> void:
	_cor_brilho = Color(1.0, 0.45, 0.15)
	_cor_vapor = Color(0.35, 0.32, 0.36)
	var laca: Color = P.torii
	_maquina_base(P.pedra2, P.madeira2, laca)
	_cil(0.3, 0.42, 0.12, 8, Vector3(0, YM + 0.0, 0.05), Vector3.ZERO, FERRO.lightened(0.1))  # bigorna
	# Pórtico de laca vermelha com trave curva (kasagi).
	for x in [-0.85, 0.85]:
		_viga(Vector3(x, 0.2, -0.15), Vector3(x, 2.35, -0.15), 0.18, laca.darkened(0.2))
	for k in 5:
		var x0 := -1.15 + k * 0.46
		_blocod(Vector3(0.48, 0.16, 0.28), Vector3(x0 + 0.23, 2.42 + absf(x0 + 0.23) * 0.12, -0.15), Vector3(0, 0, -signf(x0 + 0.23) * 7), Color(0.1, 0.08, 0.1), 0.04)
	_blocod(Vector3(1.8, 0.12, 0.22), Vector3(0, 2.18, -0.15), Vector3.ZERO, laca, 0.03)
	_placa(Vector3(0, 2.15, 0.08), Color(0.1, 0.08, 0.12), P.ouro.darkened(0.3), 0.28)
	# Fornalha à esquerda: pedras, boca acesa, chaminé.
	_tipo = 3
	_blocod(Vector3(0.7, 0.9, 0.8), Vector3(-1.15, 0.65, -0.05), Vector3(0, 0, 0), P.pedra, 0.08)
	_tipo = 0
	_caixa(Vector3(0.36, 0.28, 0.04), Vector3(-1.15, 0.6, 0.36), Vector3.ZERO, Color(1.0, 0.5, 0.15), true)
	_cil(0.2, 0.26, 1.2, 7, Vector3(-1.2, 1.7, -0.1), Vector3.ZERO, P.pedra2)
	_pecas_marcador("Vapor", Vector3(-1.2, 2.4, -0.1))
	# Suporte de katanas à direita.
	_blocod(Vector3(0.12, 0.9, 0.3), Vector3(1.2, 0.65, 0.2), Vector3.ZERO, Color(0.1, 0.08, 0.1), 0.02)
	for k in 2:
		_blocod(Vector3(0.9, 0.05, 0.05), Vector3(1.2, 0.75 + k * 0.28, 0.38), Vector3(0, 0, 8 - k * 4), Color(0.78, 0.8, 0.86), 0.01)
		_blocod(Vector3(0.25, 0.06, 0.06), Vector3(0.82, 0.71 + k * 0.28, 0.39), Vector3(0, 0, 8 - k * 4), Color(0.12, 0.08, 0.1), 0.01)
	_prensa(func() -> void:
		_blocod(Vector3(0.6, 0.4, 0.5), Vector3.ZERO, Vector3.ZERO, FERRO.lightened(0.05), 0.06)
		_blocod(Vector3(0.66, 0.08, 0.56), Vector3(0, 0.12, 0), Vector3.ZERO, laca, 0.02)
		_cil(0.24, 0.3, 0.1, 8, Vector3(0, -0.24, 0), Vector3.ZERO, FERRO))
	_gira("Gira_engrenagem", Vector3(0.95, 1.55, 0.05), 1.3, func() -> void:
		_engrenagem(10, 0.22, 0.1, P.madeira2, 0.0))


## Ninja de Shuriken: esmeril. Roda de afiar grande girando rápido (faíscas
## no "vapor"), prensa que estampa a estrela, varal de pano preto e shurikens.
func _maq_shuriken() -> void:
	_cor_brilho = Color(0.55, 0.85, 1.0)
	_cor_vapor = Color(1.0, 0.8, 0.45)
	var preto := Color(0.1, 0.09, 0.12)
	_maquina_base(P.pedra2, Color(0.22, 0.16, 0.16), Color(0.7, 0.72, 0.8))
	for x in [-0.85, 0.85]:
		_viga(Vector3(x, 0.2, -0.15), Vector3(x * 0.92, 2.3, -0.15), 0.14, preto)
	_blocod(Vector3(1.95, 0.16, 0.24), Vector3(0, 2.35, -0.15), Vector3(0, 0, -1.5), preto, 0.04)
	# Pano preto pendurado atrás (balança no vento).
	var m := _marca()
	for k in 3:
		_blocod(Vector3(0.52, 0.9, 0.02), Vector3(-0.55 + k * 0.55, 1.85, -0.3), Vector3(0, 0, (k - 1) * 2), Color(0.14, 0.12, 0.2).lightened(k * 0.04), 0.01)
	_vento_pendurado(m, 2.3, 0.9, 1.0)
	_placa(Vector3(0, 2.62, 0.0), preto, Color(0.7, 0.72, 0.8), 0.3)
	# Shurikens cravadas no poste esquerdo.
	for k in 3:
		_cil(0.11, 0.11, 0.02, 4, Vector3(-0.85, 0.9 + k * 0.4, 0.03), Vector3(90, k * 20.0, 0), Color(0.75, 0.78, 0.85))
	_pecas_marcador("Vapor", Vector3(1.05, 1.0, 0.35))
	_prensa(func() -> void:
		_blocod(Vector3(0.55, 0.32, 0.5), Vector3.ZERO, Vector3.ZERO, preto.lightened(0.1), 0.05)
		for k in 4:
			var a := TAU * k / 4.0
			_blocod(Vector3(0.12, 0.06, 0.36), Vector3(0, -0.2, 0), Vector3(0, rad_to_deg(a) + 45, 0), Color(0.75, 0.78, 0.85), 0.01))
	# Roda de afiar (pedra) com eixo e manivela.
	_blocod(Vector3(0.14, 0.75, 0.3), Vector3(1.15, 0.6, 0.05), Vector3.ZERO, Color(0.22, 0.16, 0.16), 0.02)
	_gira("Gira_esmeril", Vector3(1.15, 1.25, 0.2), 4.0, func() -> void:
		_cil(0.48, 0.48, 0.14, 14, Vector3.ZERO, Vector3(90, 0, 0), P.pedra)
		_cil(0.22, 0.22, 0.16, 10, Vector3.ZERO, Vector3(90, 0, 0), P.pedra2)
		_viga(Vector3(0, 0, 0.1), Vector3(0.3, 0.0, 0.1), 0.05, FERRO))


## Kitsune (Mago): santuário da raposa. Mini torii, corda com papéis shide,
## duas raposas de pedra, carimbo hanko gigante e um anel de fogo-raposa
## girando atrás do molde.
## Variações (magos opostos do Ciclo 2.4, classe_base kitsune): "luz" = torii
## creme e dourado, raposas brancas, fogo dourado; "sombria" = torii negro com
## laca roxa, raposas de pedra escura, fogo roxo.
func _maq_raposa(variante := "") -> void:
	var fogo := Color(1.0, 0.5, 0.78)
	_cor_brilho = fogo
	_cor_vapor = Color(1.0, 0.8, 0.9)
	var vermelho: Color = P.torii
	var pedra_raposa: Color = P.pedra.lightened(0.15)
	if variante == "luz":
		fogo = Color(1.0, 0.85, 0.4)
		_cor_brilho = fogo
		_cor_vapor = Color(1.0, 0.97, 0.85)
		vermelho = Color(0.95, 0.9, 0.78)
		pedra_raposa = Color(0.97, 0.95, 0.9)
	elif variante == "sombria":
		fogo = Color(0.6, 0.3, 1.0)
		_cor_brilho = fogo
		_cor_vapor = Color(0.3, 0.2, 0.4)
		vermelho = Color(0.35, 0.12, 0.5)
		pedra_raposa = Color(0.16, 0.13, 0.2)
	_maquina_base(P.pedra, Color(0.3, 0.12, 0.1) if variante == "" else vermelho.darkened(0.6), vermelho)
	# Torii.
	for x in [-0.88, 0.88]:
		_cil(0.09, 0.11, 2.3, 8, Vector3(x, 1.35, -0.2), Vector3.ZERO, vermelho)
	_blocod(Vector3(2.4, 0.14, 0.24), Vector3(0, 2.5, -0.2), Vector3.ZERO, P.ouro if variante == "luz" else Color(0.1, 0.08, 0.1), 0.04)
	_blocod(Vector3(2.1, 0.12, 0.2), Vector3(0, 2.3, -0.2), Vector3.ZERO, vermelho, 0.03)
	# Corda sagrada com shide.
	var m := _marca()
	_viga(Vector3(-0.85, 2.12, -0.05), Vector3(0.85, 2.12, -0.05), 0.07, P.corda)
	for k in 4:
		var x := -0.6 + k * 0.4
		_blocod(Vector3(0.09, 0.3, 0.015), Vector3(x, 1.94, -0.03), Vector3(0, 0, 8 * (1 - 2 * (k % 2))), P.branco, 0.0)
	_vento_pendurado(m, 2.15, 0.35, 1.2)
	_placa(Vector3(0, 2.75, -0.1), Color(0.1, 0.08, 0.12), vermelho, 0.28)
	# Raposas de pedra sentadas nas pontas da prateleira.
	for s in [-1.0, 1.0]:
		var b := Vector3(s * 1.2, 0.22, 0.45)
		_esfera(0.2, b + Vector3(0, 0.25, 0), Vector3(0.9, 1.3, 0.8), pedra_raposa, false, 7, 4)
		_esfera(0.13, b + Vector3(0, 0.62, 0.05), Vector3(1, 0.9, 1.1), pedra_raposa, false, 7, 4)
		for o in [-1.0, 1.0]:
			_cil(0.0, 0.05, 0.14, 4, b + Vector3(o * 0.07, 0.76, 0.03), Vector3.ZERO, pedra_raposa)
		_caixa(Vector3(0.22, 0.08, 0.02), b + Vector3(0, 0.45, 0.17), Vector3.ZERO, vermelho)  # babador
		_esfera(0.13, b + Vector3(-s * 0.18, 0.12, -0.1), Vector3(1.6, 0.6, 0.7), pedra_raposa, false, 6, 3)  # cauda
	_pecas_marcador("Vapor", Vector3(0, 1.3, -0.25))
	_prensa(func() -> void:  # carimbo hanko
		_cil(0.3, 0.3, 0.42, 12, Vector3.ZERO, Vector3.ZERO, Color(0.85, 0.75, 0.55))
		_cil(0.31, 0.31, 0.06, 12, Vector3(0, -0.22, 0), Vector3.ZERO, vermelho)
		_cil(0.12, 0.16, 0.2, 8, Vector3(0, 0.28, 0), Vector3.ZERO, Color(0.1, 0.08, 0.1)), 1.8)
	# Anel de fogo-raposa: 6 chamas girando atrás do molde.
	_gira("Gira_fogo_raposa", Vector3(0, 1.45, -0.32), 1.6, func() -> void:
		for k in 6:
			var a := TAU * k / 6.0
			_esfera(0.08, Vector3(cos(a), sin(a), 0) * 0.62, Vector3(1, 1.3, 1), fogo, true, 6, 3)
		_toro(0.58, 0.62, Vector3.ZERO, Vector3(1, 1, 0.3), P.corda.darkened(0.3)))


## Ronin Oni: fornalha oni. Ferro preto e pedra, máscara oni no alto com
## chifres, pontas nos postes, correntes e a prensa cravejada (kanabo).
func _maq_oni() -> void:
	_cor_brilho = Color(0.55, 1.0, 0.5)
	_cor_vapor = Color(0.3, 0.2, 0.35)
	var preto := Color(0.08, 0.07, 0.09)
	var vermelho: Color = P.torii.darkened(0.15)
	_maquina_base(P.pedra2.darkened(0.2), Color(0.18, 0.12, 0.12), Color(0.45, 1.0, 0.55))
	for x in [-0.9, 0.9]:
		_blocod(Vector3(0.3, 2.3, 0.3), Vector3(x, 1.35, -0.15), Vector3.ZERO, preto, 0.05)
		for k in 3:
			_cil(0.0, 0.06, 0.2, 5, Vector3(x - signf(x) * 0.0, 0.8 + k * 0.6, 0.06), Vector3(90, 0, 0), FERRO.lightened(0.2))
	_blocod(Vector3(2.3, 0.3, 0.36), Vector3(0, 2.6, -0.15), Vector3.ZERO, preto, 0.06)
	# Máscara oni em cima da trave: o enfeite fica na testa dela.
	_esfera(0.42, Vector3(0, 2.95, -0.05), Vector3(1.0, 0.95, 0.5), vermelho, false, 9, 5)
	for s in [-1.0, 1.0]:
		_cil(0.0, 0.1, 0.45, 6, Vector3(s * 0.33, 3.35, -0.05), Vector3(0, 0, -s * 28), Color(0.9, 0.86, 0.75))
		_caixa(Vector3(0.14, 0.05, 0.02), Vector3(s * 0.15, 2.92, 0.17), Vector3(0, 0, s * 15), Color(1.0, 0.85, 0.3), true)
		_cil(0.0, 0.04, 0.12, 4, Vector3(s * 0.12, 2.7, 0.15), Vector3(180, 0, 0), P.branco)
	_pecas_marcador("Enfeite", Vector3(0, 3.12, 0.2))
	# Correntes penduradas.
	for x in [-0.6, 0.6]:
		for k in 4:
			_toro(0.03, 0.06, Vector3(x, 2.35 - k * 0.12, 0.1), Vector3(1, 1.5, 1), FERRO.lightened(0.15))
	_pecas_marcador("Vapor", Vector3(0.0, 2.9, 0.1))
	_prensa(func() -> void:
		_cil(0.3, 0.34, 0.45, 8, Vector3.ZERO, Vector3.ZERO, preto.lightened(0.08))
		for k in 8:
			var a := TAU * k / 8.0
			_cil(0.0, 0.05, 0.12, 4, Vector3(cos(a) * 0.33, -0.05 + (k % 2) * 0.15, sin(a) * 0.33), Vector3(0, -rad_to_deg(a), 90), FERRO.lightened(0.25)), 1.8)
	_gira("Gira_engrenagem", Vector3(1.2, 1.25, 0.05), 0.8, func() -> void:
		_engrenagem(12, 0.22, 0.12, FERRO.lightened(0.1), 0.0)
		_cil(0.08, 0.08, 0.16, 6, Vector3.ZERO, Vector3(90, 0, 0), vermelho))


## Arqueiro Yumi: ateliê do arco. Pórtico alto e assimétrico de bambu, um yumi
## gigante armado em cima, aljava com flechas e o alvo de palha (makiwara)
## girando devagar.
func _maq_yumi() -> void:
	_cor_brilho = Color(1.0, 0.9, 0.5)
	var bambu: Color = P.bambu
	_maquina_base(P.pedra2, P.madeira2.lightened(0.05), P.corda)
	_viga(Vector3(-0.9, 0.2, -0.15), Vector3(-0.85, 2.7, -0.15), 0.14, bambu)
	_viga(Vector3(0.9, 0.2, -0.15), Vector3(0.88, 2.2, -0.15), 0.14, bambu)
	_viga(Vector3(-1.0, 2.25, -0.15), Vector3(1.0, 2.25, -0.15), 0.12, bambu.darkened(0.15))
	# Yumi gigante (2/3 acima do punho, como o de verdade) e a corda.
	var pts := []
	for k in 9:
		var t := lerpf(-0.75, 1.35, k / 8.0)
		pts.append(Vector3(-0.9 + t * 0.95, 2.55 + sin(t * 1.2) * 0.04 - 0.08 * t * t, -0.05))
	for k in 8:
		_viga(pts[k], pts[k + 1], 0.06, Color(0.25, 0.12, 0.08))
	_viga(pts[0], pts[8], 0.012, P.branco)
	_placa(Vector3(0.0, 2.35, 0.05), Color(0.1, 0.08, 0.12), bambu, 0.24)
	# Aljava com flechas à esquerda.
	_cil(0.14, 0.12, 0.7, 8, Vector3(-1.2, 0.6, 0.15), Vector3(0, 0, 10), Color(0.25, 0.12, 0.08))
	for k in 4:
		_viga(Vector3(-1.2 + k * 0.04, 0.9, 0.1 + k * 0.03), Vector3(-1.3 + k * 0.06, 1.3, 0.1 + k * 0.03), 0.02, bambu.lightened(0.2))
		_caixa(Vector3(0.05, 0.12, 0.02), Vector3(-1.3 + k * 0.06, 1.33, 0.1 + k * 0.03), Vector3.ZERO, P.branco)
	_pecas_marcador("Vapor", Vector3(1.2, 1.3, 0.3))
	_prensa(func() -> void:  # viga de curvar o bambu
		_blocod(Vector3(0.8, 0.18, 0.3), Vector3.ZERO, Vector3(0, 0, 0), P.madeira2.darkened(0.15), 0.04)
		_cil(0.26, 0.3, 0.12, 10, Vector3(0, -0.15, 0), Vector3.ZERO, bambu.darkened(0.2)))
	# Alvo de palha (makiwara) na direita.
	_blocod(Vector3(0.12, 0.9, 0.12), Vector3(1.2, 0.6, 0.05), Vector3.ZERO, P.madeira, 0.02)
	_gira("Gira_alvo", Vector3(1.2, 1.3, 0.15), 0.6, func() -> void:
		_cil(0.42, 0.42, 0.12, 14, Vector3.ZERO, Vector3(90, 0, 0), P.corda)
		_cil(0.3, 0.3, 0.13, 14, Vector3.ZERO, Vector3(90, 0, 0), P.branco)
		_cil(0.18, 0.18, 0.14, 12, Vector3.ZERO, Vector3(90, 0, 0), Color(0.1, 0.08, 0.1))
		_cil(0.07, 0.07, 0.15, 8, Vector3.ZERO, Vector3(90, 0, 0), P.torii)
		_viga(Vector3(0.08, 0.05, 0.08), Vector3(0.3, 0.2, 0.5), 0.02, bambu.lightened(0.2)))


## Construtor: serraria. Andaime de bambu amarrado, serra circular grande,
## tora em cima da mesa lateral, serragem e a prensa-malho de madeira.
func _maq_serraria() -> void:
	_cor_brilho = Color(1.0, 0.8, 0.4)
	_cor_vapor = Color(0.85, 0.7, 0.5)
	var bambu: Color = P.bambu
	_maquina_base(P.pedra2, P.madeira2, P.corda.darkened(0.2))
	for x in [-0.88, 0.88]:
		_viga(Vector3(x, 0.2, -0.15), Vector3(x, 2.35, -0.15), 0.13, bambu)
		_toro(0.07, 0.11, Vector3(x, 2.15, -0.15), Vector3(1, 0.6, 1), P.corda)
	_viga(Vector3(-1.05, 2.3, -0.15), Vector3(1.05, 2.3, -0.15), 0.12, bambu.darkened(0.15))
	_viga(Vector3(-0.88, 0.6, -0.2), Vector3(0.88, 2.2, -0.2), 0.07, bambu.darkened(0.1))  # escora
	_placa(Vector3(0, 2.6, -0.05), P.madeira2, P.corda.darkened(0.2), 0.28)
	# Toras empilhadas à esquerda e serragem no chão.
	for k in 3:
		_tora(Vector3(-1.2, 0.36 + (k / 2) * 0.32, -0.25 + (k % 2) * 0.42 + (k / 2) * 0.2), 90.0, 0.9, 0.16)
	for k in 6:
		_esfera(0.12, Vector3(0.6 + k * 0.12, 0.24, 0.55 - (k % 2) * 0.2), Vector3(1.3, 0.3, 1), P.madeira2.lightened(0.35), false, 5, 2)
	_pecas_marcador("Vapor", Vector3(1.1, 1.0, 0.4))
	_prensa(func() -> void:  # malho
		_cil(0.25, 0.25, 0.5, 10, Vector3.ZERO, Vector3(0, 0, 90), P.madeira2.darkened(0.1))
		for s in [-1.0, 1.0]:
			_cil(0.26, 0.26, 0.05, 10, Vector3(s * 0.2, 0, 0), Vector3(0, 0, 90), FERRO))
	_blocod(Vector3(0.14, 0.75, 0.3), Vector3(1.15, 0.6, 0.0), Vector3.ZERO, P.madeira, 0.02)
	_gira("Gira_serra", Vector3(1.15, 1.25, 0.15), 6.0, func() -> void:
		_cil(0.45, 0.45, 0.03, 16, Vector3.ZERO, Vector3(90, 0, 0), Color(0.72, 0.74, 0.8))
		for k in 16:
			var a := TAU * k / 16.0
			var d := Vector3(cos(a), sin(a), 0)
			var l := Vector3(-sin(a), cos(a), 0)
			_tri(d * 0.45 + l * 0.08, d * 0.55, d * 0.45 - l * 0.02, Color(0.72, 0.74, 0.8), Vector3(0, 0, 1))
		_cil(0.1, 0.1, 0.06, 8, Vector3.ZERO, Vector3(90, 0, 0), FERRO))


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
		_subir_nivel(raiz)
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
	var cb: Color = P.luz1 if _cor_brilho.r < 0 else _cor_brilho
	mb.albedo_color = Color(cb.r * 2.2, cb.g * 2.0, cb.b * 1.6)
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
	mv.albedo_color = P.branco.lerp(P.sombra, 0.15) if _cor_vapor.r < 0 else _cor_vapor
	_cor_brilho = Color(-1, 0, 0)
	_cor_vapor = Color(-1, 0, 0)
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


## "subir_nivel" (1,4 s): as peças N2_* brotam do chão uma depois da outra,
## com o anel aceso e uma baforada. Salvas escondidas (nível 1).
func _subir_nivel(raiz: Node3D) -> void:
	var n2: Array[Node3D] = []
	for f in raiz.get_children():
		if f.name.begins_with("N2_"):
			f.visible = false
			n2.append(f)
	if n2.is_empty():
		return
	var an := Animation.new()
	an.length = 1.4
	for k in n2.size():
		var no := n2[k]
		var t0 := 0.12 * k
		var t := an.add_track(Animation.TYPE_VALUE)
		an.track_set_path(t, "%s:visible" % no.name)
		an.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
		an.track_insert_key(t, 0.0, true)
		t = an.add_track(Animation.TYPE_VALUE)
		an.track_set_path(t, "%s:scale" % no.name)
		for q in [[0.0, 0.01], [t0, 0.01], [t0 + 0.28, 1.22], [t0 + 0.45, 0.92], [t0 + 0.6, 1.0]]:
			an.track_insert_key(t, q[0], Vector3.ONE * q[1])
	var t := an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Brilho:visible")
	an.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	an.track_insert_key(t, 0.0, true)
	an.track_insert_key(t, 1.2, false)
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Brilho:scale")
	for q in [[0.0, 0.6], [0.5, 2.6], [1.2, 3.4]]:
		an.track_insert_key(t, q[0], Vector3(q[1], 0.5, q[1]))
	t = an.add_track(Animation.TYPE_VALUE)
	an.track_set_path(t, "Vapor:emitting")
	an.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	an.track_insert_key(t, 0.0, false)
	an.track_insert_key(t, 0.1, true)
	var ap: AnimationPlayer = raiz.get_node("AnimationPlayer")
	ap.get_animation_library("").add_animation("subir_nivel", an)


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
		"kitsune", "kitsune_luz", "kitsune_sombria":  # máscara de raposa com chama entre as orelhas
			var branco: Color = P.branco if classe != "kitsune_sombria" else Color(0.1, 0.08, 0.12)
			var chama := Color(1.0, 0.5, 0.78)
			if classe == "kitsune_luz":
				chama = Color(1.0, 0.85, 0.4)
			elif classe == "kitsune_sombria":
				chama = Color(0.6, 0.3, 1.0)
			_tri(Vector3(-0.2, 0.05, 0), Vector3(-0.08, 0.12, 0), Vector3(-0.2, 0.3, 0), branco, Vector3(0, 0, 1))
			_tri(Vector3(0.08, 0.12, 0), Vector3(0.2, 0.05, 0), Vector3(0.2, 0.3, 0), branco, Vector3(0, 0, 1))
			_esfera(0.17, Vector3(0, -0.02, 0), Vector3(1.15, 0.9, 0.4), branco, false, 8, 4)
			_esfera(0.06, Vector3(0, -0.17, 0.04), Vector3(1, 0.8, 0.8), Color(0.1, 0.06, 0.08), false, 6, 3)
			for sx in [-1.0, 1.0]:
				_blocod(Vector3(0.09, 0.025, 0.03), Vector3(sx * 0.08, 0.0, 0.06), Vector3(0, 0, sx * 18), P.torii if classe == "kitsune" else chama, 0.005)
			_cil(0.0, 0.07, 0.18, 6, Vector3(0, 0.3, 0.02), Vector3.ZERO, chama, true)
		"ronin_oni":  # chifres de oni sobre um kanabo (clava cravejada)
			_viga(Vector3(-0.2, -0.26, 0), Vector3(0.18, 0.2, 0), 0.1, Color(0.12, 0.08, 0.1))
			for k in 4:
				_esfera(0.03, Vector3(-0.08 + k * 0.08, -0.1 + k * 0.1, 0.05), Vector3.ONE, ouro, false, 4, 2)
			for sx in [-1.0, 1.0]:
				_cil(0.0, 0.06, 0.22, 5, Vector3(sx * 0.17, 0.18, 0), Vector3(0, 0, -sx * 25), P.torii.darkened(0.2))
		"arqueiro_yumi":  # arco longo assimétrico com flecha
			for k in 6:
				var a0 := lerpf(-1.1, 1.1, k / 6.0)
				var a1 := lerpf(-1.1, 1.1, (k + 1) / 6.0)
				_viga(Vector3(-0.12 + cos(a0) * 0.06, sin(a0) * 0.3 + 0.02, 0), Vector3(-0.12 + cos(a1) * 0.06, sin(a1) * 0.3 + 0.02, 0), 0.035, P.madeira2)
			_viga(Vector3(-0.08, 0.29, 0.01), Vector3(-0.08, -0.25, 0.01), 0.01, P.branco)
			_viga(Vector3(-0.22, -0.05, 0.02), Vector3(0.26, -0.05, 0.02), 0.02, P.madeira2.lightened(0.2))
			_tri(Vector3(0.26, 0.0, 0.03), Vector3(0.26, -0.1, 0.03), Vector3(0.34, -0.05, 0.03), aco, Vector3(0, 0, 1))
		"armadilheiro":  # estrepe (makibishi): quatro pontas
			for d in [Vector3(0, 1, 0), Vector3(-0.94, -0.33, 0.3), Vector3(0.94, -0.33, 0.3), Vector3(0, -0.33, -0.94)]:
				var b := Basis(Vector3.UP.cross(d).normalized() if absf(d.y) < 0.99 else Vector3.RIGHT, Vector3.UP.angle_to(d))
				_cil(0.0, 0.05, 0.22, 5, b * Vector3(0, 0.11, 0), b.get_euler() * 180.0 / PI, aco)
			_esfera(0.05, Vector3.ZERO, Vector3.ONE, aco.darkened(0.3), false, 5, 3)
		"bombardeiro":  # bomba de pólvora com pavio aceso
			_esfera(0.17, Vector3(0, -0.04, 0), Vector3.ONE, Color(0.12, 0.1, 0.13), false, 8, 5)
			_cil(0.05, 0.06, 0.06, 6, Vector3(0.08, 0.13, 0), Vector3(0, 0, -30), aco.darkened(0.3))
			_viga(Vector3(0.1, 0.15, 0), Vector3(0.17, 0.25, 0), 0.02, P.corda)
			_esfera(0.05, Vector3(0.18, 0.27, 0.02), Vector3.ONE, P.luz2, true, 5, 3)
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
		t.pilha_model = load(d + "deposito_madeira.scn")
		t.tora_model = load(d + "tora.scn")
		ResourceSaver.save(t, caminho)
		print("tema %s: economia ligada" % tema)
