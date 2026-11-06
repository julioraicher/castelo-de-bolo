extends "res://tools/gerar_cenario_ninja.gd"
## Torretas do Construtor (Ciclo 2.9b): três pilotos, nos dois times e nos
## quatro temas, com o mesmo construtor de malha e material do cenário.
##   godot --headless --path . -s tools/gerar_torretas.gd
## Sai assets/ninja/<tema>/torreta_<a|b|c>_<azul|vermelho>.scn.
##
## Quiz de 2026-11-06 (Julio): torre de vigia MAIS BAIXA + toque de santuário
## da raposa; a besta "encantada" com magia evidente mas discreta; cor do time
## acendendo. Cada modelo tem:
##   - "Arma": a besta, nó à parte que o jogo gira para o alvo (frente = +Z,
##     pivô na origem do nó, na altura Torreta.ALTURA_ARMA);
##   - "Arma/Gira_magia": fogo-fátuo que orbita a besta (gira no shader);
##   - peças penduradas (lanterna, bandeira, shide) balançam com o vento.
## a = yagura baixa (torre de vigia de madeira);
## b = santuário da raposa (hokora de pedra com a besta no altar);
## c = posto da raposa (mistura: pernas de yagura, telhado de santuário, torii).

const ESTILOS := ["a", "b", "c"]
const ALTURA_ARMA := 2.6   # igual a Torreta.ALTURA_ARMA (altura do pivô da besta)


func _gerar_tudo() -> bool:
	return false


func _init() -> void:
	for tema in TEMAS:
		P = TEMAS[tema]
		_dir = "res://assets/ninja/" + tema
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
		for t in TIMES:
			for e in ESTILOS:
				call("_torreta_" + e, TIMES[t])
				_salvar("torreta_%s_%s" % [e, t])
			_catapulta(TIMES[t])
			_salvar("catapulta_" + t)
	print("triângulos por modelo (último tema): ", _tris)
	quit()


# --- Peças comuns ------------------------------------------------------------------

## Besta encantada (nó "Arma"): coronha de madeira, arco de duas lâminas, corda
## que brilha na cor do time, virote carregado e um cristal com fogo-fátuo
## orbitando. `luz` = cor do time clara (o que "acende").
func _besta(time: Color, luz: Color) -> void:
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	var ferro := Color(0.2, 0.18, 0.19)
	var g := _inicio_peca()
	_ao = 1.0
	_tipo = 0
	# Pivô (pino de ferro) e coronha.
	_cil(0.09, 0.11, 0.16, 8, Vector3(0, -0.08, 0), Vector3.ZERO, ferro)
	_blocod(Vector3(0.16, 0.13, 1.15), Vector3(0, 0.02, 0.18), Vector3.ZERO, mad.darkened(0.1), 0.03)
	_blocod(Vector3(0.1, 0.1, 0.4), Vector3(0, 0.0, -0.5), Vector3(-12, 0, 0), mad.darkened(0.2), 0.02)   # cabo
	_blocod(Vector3(0.06, 0.2, 0.08), Vector3(0, 0.12, -0.2), Vector3.ZERO, ferro, 0.01)                # gatilho/trava
	# Arco: duas lâminas curvas (3 segmentos cada) e as pontas de ferro.
	for s in [-1.0, 1.0]:
		var pts := [Vector3(0, 0.03, 0.62), Vector3(0.28 * s, 0.03, 0.56), Vector3(0.5 * s, 0.03, 0.44), Vector3(0.64 * s, 0.03, 0.26)]
		for i in 3:
			_viga(pts[i], pts[i + 1], 0.07 - i * 0.012, mad2.darkened(0.05 * i), 0.02)
		_cil(0.03, 0.03, 0.1, 6, pts[3], Vector3(0, 0, 90), ferro)
		# Corda brilhante da ponta até a trava.
		_viga(pts[3], Vector3(0, 0.08, -0.16), 0.025, luz, 0.0)
	# Virote carregado.
	_cil(0.025, 0.025, 0.8, 6, Vector3(0, 0.1, 0.25), Vector3(90, 0, 0), P.branco.darkened(0.1))
	_cil(0.0, 0.05, 0.14, 6, Vector3(0, 0.1, 0.7), Vector3(90, 0, 0), ferro)
	# Cristal encantado sobre a coronha (acende) e um aro de ferro em volta.
	_esfera(0.075, Vector3(0, 0.2, 0.05), Vector3(0.8, 1.5, 0.8), luz, true, 6, 3)
	_toro(0.02, 0.1, Vector3(0, 0.14, 0.05), Vector3(1, 0.6, 1), ferro)
	_fim_peca(g, "Arma", Transform3D(Basis(), Vector3(0, ALTURA_ARMA, 0)))
	# Fogo-fátuo: três chamas orbitando o cristal (gira no shader, eixo Z local = Y do mundo).
	g = _inicio_peca()
	for i in 3:
		var a := TAU * i / 3.0
		var p := Vector3(cos(a), sin(a), 0) * 0.34
		_esfera(0.05, p, Vector3.ONE, luz, true, 6, 3)
		_esfera(0.03, p + Vector3(-sin(a), cos(a), 0) * 0.08, Vector3.ONE, luz.lightened(0.4), true, 5, 3)
	_fim_peca(g, "Arma/Gira_magia", Transform3D(Basis.from_euler(Vector3(-PI / 2, 0, 0)), Vector3(0, 0.2, 0.05)), Vector2(1.8, 0.0))


## Lanterna de papel pendurada num gancho, na cor do time (acende), balançando.
func _lanterna_pendurada(pos: Vector3, luz: Color) -> void:
	var m := _marca()
	_cil(0.015, 0.015, 0.3, 4, pos + Vector3(0, -0.15, 0), Vector3.ZERO, Color(0.2, 0.18, 0.19))
	_caixa(Vector3(0.2, 0.05, 0.2), pos + Vector3(0, -0.32, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.17, 0.26, 0.17), pos + Vector3(0, -0.47, 0), Vector3.ZERO, luz, true)
	_caixa(Vector3(0.2, 0.05, 0.2), pos + Vector3(0, -0.62, 0), Vector3.ZERO, P.madeira)
	_vento_pendurado(m, pos.y, 0.7, 1.2)


## Estandarte (nobori) estreito na cor do time, com o brasão branco.
func _nobori(base: Vector3, h: float, time: Color) -> void:
	_cil(0.03, 0.04, h, 5, base + Vector3(0, h / 2, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.05, 0.03, 0.42), base + Vector3(0, h - 0.05, 0.21), Vector3.ZERO, P.madeira)
	var m := _marca()
	_caixa(Vector3(0.025, 0.95, 0.4), base + Vector3(0, h - 0.55, 0.22), Vector3.ZERO, time)
	_cil(0.11, 0.11, 0.01, 10, base + Vector3(0.015, h - 0.4, 0.22), Vector3(0, 0, 90), P.branco)
	_vento_pendurado(m, base.y + h - 0.08, 1.0, 1.0)


## Corda sagrada (shimenawa) entre dois pontos com os papéis em zigue-zague (shide).
func _shimenawa(a: Vector3, b: Vector3, n_shide: int) -> void:
	_viga(a, b, 0.06, P.corda, 0.01)
	for i in n_shide:
		var p := a.lerp(b, (i + 0.5) / n_shide)
		var m := _marca()
		_caixa(Vector3(0.1, 0.22, 0.012), p + Vector3(0, -0.13, 0), Vector3(0, 0, 8), P.branco)
		_caixa(Vector3(0.08, 0.16, 0.012), p + Vector3(0.03, -0.3, 0), Vector3(0, 0, -10), P.branco)
		_vento_pendurado(m, p.y, 0.4, 1.4)


## Raposa de pedra sentada (guardiã do santuário), olhos acesos na cor do time.
func _raposa(pos: Vector3, rot_y: float, luz: Color, esc := 1.0) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(rot_y), 0))
	var ap := func(v: Vector3) -> Vector3:
		return pos + b * (v * esc)
	var pedra: Color = P.pedra
	_blocod(Vector3(0.5, 0.12, 0.6) * esc, ap.call(Vector3(0, 0.06, 0)), Vector3(0, rot_y, 0), P.pedra2, 0.03)
	_esfera(0.2 * esc, ap.call(Vector3(0, 0.32, -0.05)), Vector3(1, 1.3, 1.1), pedra, false, 7, 4)   # corpo sentado
	_esfera(0.14 * esc, ap.call(Vector3(0, 0.66, 0.1)), Vector3(1, 0.95, 1.15), pedra, false, 7, 4)  # cabeça
	_cil(0.0, 0.06 * esc, 0.16 * esc, 4, ap.call(Vector3(0, 0.6, 0.26)), Vector3(70 + 0, rot_y, 0), pedra)  # focinho
	for s in [-1.0, 1.0]:
		_cil(0.0, 0.05 * esc, 0.16 * esc, 4, ap.call(Vector3(0.08 * s, 0.82, 0.08)), Vector3(0, rot_y, -12 * s), pedra)  # orelhas
		_esfera(0.025 * esc, ap.call(Vector3(0.06 * s, 0.68, 0.22)), Vector3.ONE, luz, true, 5, 3)   # olhos
		_cil(0.05 * esc, 0.06 * esc, 0.3 * esc, 5, ap.call(Vector3(0.11 * s, 0.17, 0.14)), Vector3(0, rot_y, 0), pedra)  # patas
	_cil(0.03 * esc, 0.1 * esc, 0.5 * esc, 5, ap.call(Vector3(0.12, 0.3, -0.28)), Vector3(-50, rot_y, 25), pedra)  # cauda
	_esfera(0.07 * esc, ap.call(Vector3(0.2, 0.5, -0.4)), Vector3.ONE, pedra.lightened(0.15), false, 5, 3)


# --- a) Yagura baixa -------------------------------------------------------------------

## Torre de vigia de madeira, baixa (plataforma a 2,1 m): base de pedra, quatro
## pernas inclinadas com travessas em X, guarda-corpo, telhado de telhas na cor
## do time, lanterna e estandarte. A besta fica no meio da plataforma.
func _torreta_a(time: Color) -> void:
	_rng.seed = 31
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	var luz := time.lightened(0.35)
	var telha: Color = P.telhado.lerp(time, 0.35)
	var y_piso := 2.1
	# Base de pedra (degrau sextavado) com pedras soltas.
	_tipo = 3
	_cil(1.05, 1.2, 0.3, 8, Vector3(0, 0.15, 0), Vector3(0, 22, 0), P.pedra2)
	_cil(0.9, 1.0, 0.16, 8, Vector3(0, 0.38, 0), Vector3(0, 12, 0), P.pedra)
	for i in 5:
		var a := TAU * i / 5.0 + 0.4
		_esfera(_rng.randf_range(0.12, 0.2), Vector3(cos(a) * 1.25, 0.08, sin(a) * 1.25), Vector3(1.2, 0.6, 1), P.pedra.lerp(P.pedra2, _rng.randf()), false, 6, 3)
	_tipo = 0
	# Pernas inclinadas (mais abertas embaixo) e travessas em X em cada lado.
	var pe := []
	for s in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
		var a := Vector3(s[0] * 0.78, 0.42, s[1] * 0.78)
		var b := Vector3(s[0] * 0.58, y_piso + 0.05, s[1] * 0.58) + Vector3(_rng.randf_range(-0.03, 0.03), 0, _rng.randf_range(-0.03, 0.03))
		_viga(a, b, 0.17, mad, 0.04)
		pe.append([a, b])
	for i in 4:
		var p1: Array = pe[i]
		var p2: Array = pe[(i + 1) % 4]
		_viga(p1[0].lerp(p1[1], 0.12), p2[0].lerp(p2[1], 0.82), 0.075, mad2.darkened(0.08), 0.02)
		_viga(p2[0].lerp(p2[1], 0.12), p1[0].lerp(p1[1], 0.82), 0.075, mad2.darkened(0.12), 0.02)
		_viga(p1[0].lerp(p1[1], 0.5), p2[0].lerp(p2[1], 0.5), 0.09, mad, 0.02)   # cinta do meio
	# Plataforma de tábuas e vigas de apoio.
	_tipo = 1
	_blocod(Vector3(1.75, 0.13, 1.75), Vector3(0, y_piso + 0.06, 0), Vector3.ZERO, mad2, 0.03)
	_tipo = 0
	for s in [-1.0, 1.0]:
		_blocod(Vector3(1.85, 0.1, 0.12), Vector3(0, y_piso - 0.02, s * 0.7), Vector3.ZERO, mad.darkened(0.1), 0.02)
	# Guarda-corpo: postes de canto, corrimão e balaústres.
	for s in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
		_blocod(Vector3(0.1, 0.62, 0.1), Vector3(s[0] * 0.82, y_piso + 0.43, s[1] * 0.82), Vector3.ZERO, mad, 0.02)
	for i in 4:
		var ang := TAU * i / 4.0
		var dirv := Vector3(cos(ang), 0, sin(ang))
		var lado := Vector3(-sin(ang), 0, cos(ang))
		var c := dirv * 0.82 + Vector3(0, y_piso + 0.68, 0)
		_viga(c - lado * 0.82, c + lado * 0.82, 0.07, mad2, 0.02)
		for k in 3:
			var p := c + lado * ((k - 1) * 0.41)
			_blocod(Vector3(0.05, 0.42, 0.05), p + Vector3(0, -0.3, 0), Vector3(0, -rad_to_deg(ang), 0), mad2.darkened(0.15), 0.01)
	# Meia-água de telhas só sobre a metade de trás (a câmera olha de +Z e a
	# besta precisa aparecer): dois esteios altos atrás, dois baixos no meio.
	var y_tel := y_piso + 1.45
	for s in [-1.0, 1.0]:
		_viga(Vector3(s * 0.78, y_piso + 0.12, -0.78), Vector3(s * 0.7, y_tel + 0.02, -0.72), 0.1, mad, 0.02)
		_viga(Vector3(s * 0.78, y_piso + 0.12, 0.05), Vector3(s * 0.72, y_tel - 0.42, 0.05), 0.1, mad, 0.02)
	_blocod(Vector3(1.6, 0.08, 0.1), Vector3(0, y_tel - 0.02, -0.72), Vector3.ZERO, mad.darkened(0.15), 0.02)
	_blocod(Vector3(1.6, 0.08, 0.1), Vector3(0, y_tel - 0.46, 0.05), Vector3.ZERO, mad.darkened(0.15), 0.02)
	_tipo = 2
	_blocod(Vector3(1.9, 0.09, 1.15), Vector3(0, y_tel - 0.16, -0.38), Vector3(-24, 0, 0), telha, 0.02)
	_tipo = 0
	_blocod(Vector3(1.95, 0.1, 0.12), Vector3(0, y_tel + 0.1, -0.9), Vector3.ZERO, time.darkened(0.25), 0.02)  # cumeeira
	_esfera(0.08, Vector3(0.0, y_tel + 0.2, -0.9), Vector3.ONE, luz, true, 6, 3)
	_sombra_faixa(y_tel - 0.8, y_tel - 0.2, 0.6, 1.0, 0.5, -0.4)
	# Lanterna no beiral da frente da meia-água e estandarte no canto de trás.
	_lanterna_pendurada(Vector3(0.6, y_tel - 0.44, 0.22), luz)
	_nobori(Vector3(-0.78, y_piso + 0.1, -0.5), 2.5, time)
	# Suporte da besta no meio da plataforma (toco de madeira com aro de ferro).
	_cil(0.14, 0.17, ALTURA_ARMA - y_piso - 0.2, 7, Vector3(0, (ALTURA_ARMA + y_piso - 0.2) / 2, 0), Vector3.ZERO, mad.darkened(0.05))
	_toro(0.02, 0.16, Vector3(0, ALTURA_ARMA - 0.2, 0), Vector3(1, 0.5, 1), Color(0.2, 0.18, 0.19))
	_besta(time, luz)


# --- b) Santuário da raposa --------------------------------------------------------------

## Hokora de pedra: escada, corpo de madeira escura com portas de papel acesas,
## telhado curvo de telhas na cor do time, torii em frente, duas raposas de
## guarda e a shimenawa. A besta fica no altar do topo, entre fogos-fátuos.
func _torreta_b(time: Color) -> void:
	_rng.seed = 32
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	var luz := time.lightened(0.35)
	var telha: Color = P.telhado.lerp(time, 0.4)
	var torii: Color = P.torii.lerp(time, 0.45)
	# Degraus de pedra.
	_tipo = 3
	_blocod(Vector3(2.3, 0.22, 2.1), Vector3(0, 0.11, 0), Vector3(0, 0, 0.5), P.pedra2, 0.05)
	_blocod(Vector3(1.8, 0.22, 1.6), Vector3(0, 0.33, -0.05), Vector3(0, 0, -0.4), P.pedra, 0.05)
	_blocod(Vector3(1.9, 0.12, 0.5), Vector3(0, 0.17, 1.05), Vector3.ZERO, P.pedra, 0.04)   # degrau da frente
	_tipo = 0
	# Corpo da capela com portas de papel acesas e vigas.
	_tipo = 1
	_blocod(Vector3(1.35, 1.15, 1.15), Vector3(0, 1.0, -0.05), Vector3.ZERO, mad.darkened(0.12), 0.04)
	_tipo = 0
	for s in [-1.0, 1.0]:
		_caixa(Vector3(0.36, 0.72, 0.03), Vector3(s * 0.24, 0.98, 0.54), Vector3.ZERO, luz, true)
		_blocod(Vector3(0.08, 1.2, 0.08), Vector3(s * 0.7, 1.0, 0.58), Vector3.ZERO, mad2, 0.02)
		_blocod(Vector3(0.08, 1.2, 0.08), Vector3(s * 0.7, 1.0, -0.62), Vector3.ZERO, mad2, 0.02)
	_blocod(Vector3(0.05, 0.72, 0.03), Vector3(0, 0.98, 0.55), Vector3.ZERO, mad2, 0.01)
	_blocod(Vector3(1.5, 0.12, 1.3), Vector3(0, 1.62, -0.05), Vector3.ZERO, mad2, 0.03)
	# Telhado curvo de 4 águas (mais largo que o corpo) e cumeeira.
	_tipo = 2
	var f := func(x: float, z: float) -> float:
		return _altura_telhado(x, z, 2.2, 2.0, 0.55, 0.12, 0.35)
	_superficie(Vector3(0, 1.68, -0.05), f, -1.1, 1.1, -1.0, 1.0, 8, 8, 0.07, telha, telha.darkened(0.3))
	_tipo = 0
	_blocod(Vector3(0.9, 0.1, 0.14), Vector3(0, 2.28, -0.05), Vector3.ZERO, time.darkened(0.25), 0.02)
	_sombra_faixa(1.15, 1.66, 0.55, 1.0, 0.9, -0.05)
	# Altar no topo: tábua com a besta e dois pilares de ferro com fitas.
	_blocod(Vector3(0.7, 0.08, 0.7), Vector3(0, ALTURA_ARMA - 0.28, 0), Vector3.ZERO, mad.darkened(0.2), 0.02)
	_cil(0.12, 0.14, 0.18, 7, Vector3(0, ALTURA_ARMA - 0.15, 0), Vector3.ZERO, Color(0.2, 0.18, 0.19))
	# Torii em frente (na cor do time) com a shimenawa e os shide.
	for s in [-1.0, 1.0]:
		_cil(0.07, 0.085, 1.9, 7, Vector3(s * 0.62, 0.95, 1.5), Vector3(0, 0, s * 2.0), torii)
	_blocod(Vector3(1.7, 0.1, 0.1), Vector3(0, 1.72, 1.5), Vector3.ZERO, torii.darkened(0.15), 0.02)
	_blocod(Vector3(1.95, 0.12, 0.14), Vector3(0, 1.92, 1.5), Vector3(0, 0, 0), torii, 0.03)
	_blocod(Vector3(0.1, 0.12, 0.1), Vector3(0, 1.82, 1.5), Vector3.ZERO, P.branco)   # placa
	_shimenawa(Vector3(-0.6, 1.6, 1.56), Vector3(0.6, 1.6, 1.56), 3)
	# Raposas de guarda nos dois lados da escada e lanternas de pedra pequenas.
	_raposa(Vector3(-1.05, 0.0, 0.85), 25.0, luz, 0.9)
	_raposa(Vector3(1.05, 0.0, 0.85), -25.0, luz, 0.9)
	for s in [-1.0, 1.0]:
		_cil(0.1, 0.12, 0.5, 6, Vector3(s * 1.0, 0.25, -0.75), Vector3.ZERO, P.pedra2)
		_caixa(Vector3(0.2, 0.2, 0.2), Vector3(s * 1.0, 0.6, -0.75), Vector3.ZERO, P.pedra)
		_esfera(0.06, Vector3(s * 1.0, 0.6, -0.64), Vector3.ONE, luz, true, 5, 3)
		_cil(0.02, 0.18, 0.12, 4, Vector3(s * 1.0, 0.76, -0.75), Vector3(0, 45, 0), P.pedra2)
	_besta(time, luz)


# --- c) Posto da raposa (mistura) ------------------------------------------------------------

## Pernas de yagura curtas sobre base de pedra, plataforma a 1,6 m, guarda-corpo
## de torii na cor do time com shimenawa e shide, telhado curvo de santuário,
## raposa na frente e lanternas nos cantos. A besta no meio, mais baixa.
func _torreta_c(time: Color) -> void:
	_rng.seed = 33
	var mad: Color = P.madeira
	var mad2: Color = P.madeira2
	var luz := time.lightened(0.35)
	var telha: Color = time.lerp(P.telhado, 0.3)   # cor do time forte: lê de longe
	var torii: Color = time.lerp(P.torii, 0.2)
	var y_piso := 1.6
	# Base de pedra larga com musgo.
	_tipo = 3
	_blocod(Vector3(2.2, 0.28, 2.2), Vector3(0, 0.14, 0), Vector3(0, 0, 0.4), P.pedra2, 0.06)
	_blocod(Vector3(1.8, 0.14, 1.8), Vector3(0, 0.35, 0), Vector3(0, 0, -0.3), P.pedra, 0.05)
	_tipo = 0
	# Pernas curtas, cinta e um X só na frente/trás.
	var pe := []
	for s in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
		var a := Vector3(s[0] * 0.74, 0.4, s[1] * 0.74)
		var b := Vector3(s[0] * 0.62, y_piso + 0.05, s[1] * 0.62)
		_viga(a, b, 0.16, mad, 0.04)
		pe.append([a, b])
	for i in 4:
		var p1: Array = pe[i]
		var p2: Array = pe[(i + 1) % 4]
		_viga(p1[0].lerp(p1[1], 0.45), p2[0].lerp(p2[1], 0.45), 0.09, mad2.darkened(0.1), 0.02)
		if i % 2 == 0:
			_viga(p1[0].lerp(p1[1], 0.1), p2[0].lerp(p2[1], 0.85), 0.07, mad2.darkened(0.15), 0.02)
			_viga(p2[0].lerp(p2[1], 0.1), p1[0].lerp(p1[1], 0.85), 0.07, mad2.darkened(0.15), 0.02)
	# Plataforma de tábuas.
	_tipo = 1
	_blocod(Vector3(1.9, 0.14, 1.9), Vector3(0, y_piso + 0.07, 0), Vector3.ZERO, mad2, 0.03)
	_tipo = 0
	# Guarda-corpo de torii: postes vermelhos do time e travessas, shimenawa na frente.
	for s in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
		_cil(0.055, 0.065, 0.75, 7, Vector3(s[0] * 0.86, y_piso + 0.5, s[1] * 0.86), Vector3.ZERO, torii)
		_blocod(Vector3(0.16, 0.06, 0.16), Vector3(s[0] * 0.86, y_piso + 0.9, s[1] * 0.86), Vector3.ZERO, torii.darkened(0.2), 0.01)
	for i in 4:
		var ang := TAU * i / 4.0
		var dirv := Vector3(cos(ang), 0, sin(ang))
		var lado := Vector3(-sin(ang), 0, cos(ang))
		var c := dirv * 0.86 + Vector3(0, y_piso + 0.82, 0)
		_viga(c - lado * 0.86, c + lado * 0.86, 0.06, torii.darkened(0.1), 0.01)
		if i == 1:  # frente (+Z): corda sagrada
			_shimenawa(c - lado * 0.7 + Vector3(0, -0.1, 0.02), c + lado * 0.7 + Vector3(0, -0.1, 0.02), 4)
	# Telhado curvo de santuário só na metade de trás (deixa a besta à vista
	# para a câmera, que olha de +Z), sobre dois esteios.
	var y_tel := y_piso + 1.4
	for s in [-1.0, 1.0]:
		_viga(Vector3(s * 0.8, y_piso + 0.14, -0.8), Vector3(s * 0.72, y_tel, -0.6), 0.1, mad.darkened(0.05), 0.02)
		_viga(Vector3(s * 0.72, y_tel - 0.02, -0.6), Vector3(s * 0.72, y_tel - 0.02, 0.0), 0.08, mad.darkened(0.1), 0.02)
	_blocod(Vector3(1.6, 0.08, 0.1), Vector3(0, y_tel - 0.02, -0.6), Vector3.ZERO, mad.darkened(0.15), 0.02)
	_tipo = 2
	var f := func(x: float, z: float) -> float:
		return _altura_telhado(x, z, 2.4, 1.4, 0.5, 0.14, 0.4)
	_superficie(Vector3(0, y_tel + 0.02, -0.45), f, -1.2, 1.2, -0.7, 0.7, 8, 6, 0.07, telha, telha.darkened(0.3))
	_tipo = 0
	_blocod(Vector3(1.1, 0.1, 0.14), Vector3(0, y_tel + 0.56, -0.45), Vector3.ZERO, time.darkened(0.25), 0.02)
	_esfera(0.08, Vector3(0, y_tel + 0.68, -0.45), Vector3.ONE, luz, true, 6, 3)
	_sombra_faixa(y_tel - 0.7, y_tel - 0.02, 0.6, 1.1, 0.7, -0.45)
	# Lanternas nos dois cantos da frente do telhado, raposa na frente da base.
	_lanterna_pendurada(Vector3(1.05, y_tel + 0.02, 0.18), luz)
	_lanterna_pendurada(Vector3(-1.05, y_tel + 0.02, 0.18), luz)
	_raposa(Vector3(0.0, 0.42, 1.0), 0.0, luz, 0.7)
	# Suporte da besta.
	_cil(0.14, 0.17, ALTURA_ARMA - y_piso - 0.2, 7, Vector3(0, (ALTURA_ARMA + y_piso - 0.2) / 2, 0), Vector3.ZERO, mad.darkened(0.05))
	_toro(0.02, 0.16, Vector3(0, ALTURA_ARMA - 0.2, 0), Vector3(1, 0.5, 1), Color(0.2, 0.18, 0.19))
	_besta(time, luz)


# --- Catapulta -------------------------------------------------------------------------

## Catapulta de bambu com a mão do Oni (quiz 2026-11-06, C1 = A + D): dois
## cavaletes de bambu amarrados com corda, eixo de ferro, patins no chão,
## sarilho atrás, estandarte e lanterna. O nó "Braco" (pivô no eixo, vara ao
## longo de +Y) leva o cesto de pedras no lado curto e, na ponta longa
## (BRACO_COMP = 3,1 m), a mão de pedra do Oni com o aro aceso na cor do time.
## Frente = +Z (o jogo vira o nó para o castelo inimigo).
func _catapulta(time: Color) -> void:
	_rng.seed = 34
	var luz := time.lightened(0.35)
	var ferro := Color(0.2, 0.18, 0.19)
	var bambu: Color = P.bambu
	var corda: Color = P.corda
	var y_eixo := 1.7
	# Patins e travessas no chão.
	for s in [-1.0, 1.0]:
		_bambu(Vector3(s * 0.95, 0.07, -1.5), 3.0, Vector3(90, 0, 0))
	for z in [-1.3, 0.0, 1.3]:
		_bambu(Vector3(-1.05, 0.16, z), 2.1, Vector3(0, 0, -90))
	# Cavaletes (A de bambu) nos dois lados, amarrados com corda no topo.
	for s in [-1.0, 1.0]:
		for z in [-0.9, 0.9]:
			var base := Vector3(s * 0.95, 0.1, z)
			var topo := Vector3(s * 0.12, y_eixo + 0.05, z)
			var d := topo - base
			_bambu(base, d.length(), Vector3(0, 0, -s * rad_to_deg(atan2(absf(d.x), d.y))))
		_toro(0.03, 0.16, Vector3(s * 0.12, y_eixo - 0.12, 0), Vector3(1, 1.3, 1), corda)
		_cil(0.17, 0.17, 0.5, 7, Vector3(s * 0.12, y_eixo - 0.12, 0), Vector3(90, 0, 0), corda.darkened(0.1))
	# Eixo de ferro com as tampas na cor do time.
	_cil(0.07, 0.07, 1.4, 8, Vector3(0, y_eixo, 0), Vector3(0, 0, 90), ferro)
	for s in [-1.0, 1.0]:
		_cil(0.12, 0.12, 0.08, 8, Vector3(s * 0.68, y_eixo, 0), Vector3(0, 0, 90), time)
	# Sarilho atrás: tambor de madeira com corda enrolada e manivela (gira devagar).
	_blocod(Vector3(0.1, 0.5, 0.1), Vector3(-0.55, 0.4, -1.3), Vector3.ZERO, P.madeira, 0.02)
	_blocod(Vector3(0.1, 0.5, 0.1), Vector3(0.55, 0.4, -1.3), Vector3.ZERO, P.madeira, 0.02)
	var g := _inicio_peca()
	_cil(0.16, 0.16, 0.9, 8, Vector3.ZERO, Vector3(0, 0, 90), P.madeira2)
	_cil(0.19, 0.19, 0.5, 8, Vector3.ZERO, Vector3(0, 0, 90), corda)
	_viga(Vector3(0.5, 0, 0), Vector3(0.5, 0.3, 0), 0.06, ferro, 0.01)
	_cil(0.035, 0.035, 0.22, 6, Vector3(0.5, 0.3, 0.11), Vector3(90, 0, 0), P.madeira2.lightened(0.15))
	_fim_peca(g, "Gira_sarilho", Transform3D(Basis.from_euler(Vector3(0, PI / 2, 0)), Vector3(0, 0.62, -1.3)), Vector2(0.5, 0.0))
	# Estandarte e lanterna.
	_nobori(Vector3(-1.1, 0.1, -1.45), 2.6, time)
	_lanterna_pendurada(Vector3(1.05, 1.5, 1.3), luz)
	_blocod(Vector3(0.06, 1.5, 0.06), Vector3(1.05, 0.8, 1.3), Vector3(0, 0, 0), P.madeira, 0.01)
	# Braço: vara de bambu ao longo de +Y (pivô no eixo), cesto de pedras no
	# lado curto e a mão do Oni na ponta longa.
	g = _inicio_peca()
	_cil(0.1, 0.13, 4.0, 7, Vector3(0, 1.1, 0), Vector3.ZERO, bambu)
	var k := -0.7
	while k < 3.0:
		_cil(0.14, 0.14, 0.07, 7, Vector3(0, k, 0), Vector3.ZERO, bambu.darkened(0.25))
		k += 0.65
	_toro(0.03, 0.15, Vector3(0, 0, 0), Vector3(1, 1.4, 1), corda)   # amarra no eixo
	_toro(0.025, 0.13, Vector3(0, 2.6, 0), Vector3(1, 1.4, 1), corda)
	# Cesto de contrapeso (vime) com pedras.
	_cil(0.38, 0.3, 0.45, 8, Vector3(0, -0.85, 0), Vector3.ZERO, corda.darkened(0.2))
	for i in 5:
		var a := TAU * i / 5.0
		_esfera(0.13, Vector3(cos(a) * 0.2, -0.6, sin(a) * 0.2), Vector3(1, 0.8, 1), P.pedra.lerp(P.pedra2, _rng.randf()), false, 6, 3)
	# Mão do Oni: pedra avermelhada, palma em concha, quatro dedos, polegar,
	# garras de osso e o aro aceso no pulso.
	var oni: Color = P.pedra.lerp(Color(0.62, 0.2, 0.16), 0.55)
	var osso := Color(0.9, 0.86, 0.76)
	_toro(0.05, 0.19, Vector3(0, 2.95, 0), Vector3(1, 1, 1), luz)
	_cil(0.16, 0.14, 0.3, 7, Vector3(0, 3.0, 0), Vector3.ZERO, oni)              # pulso
	_esfera(0.42, Vector3(0, 3.25, 0.1), Vector3(1.1, 0.5, 1.0), oni, false, 8, 4)  # palma
	for i in 4:
		var x := -0.3 + i * 0.2
		var b := Vector3(x, 3.3, 0.45)
		_cil(0.07, 0.085, 0.42, 6, b + Vector3(0, 0.16, 0.08), Vector3(-25, 0, 0), oni)
		_cil(0.06, 0.07, 0.3, 6, b + Vector3(0, 0.46, 0.0), Vector3(20, 0, 0), oni)
		_cil(0.0, 0.05, 0.18, 5, b + Vector3(0, 0.62, -0.1), Vector3(35, 0, 0), osso)
	_cil(0.08, 0.1, 0.4, 6, Vector3(0.5, 3.3, 0.05), Vector3(0, 0, -50), oni)    # polegar
	_cil(0.0, 0.05, 0.16, 5, Vector3(0.72, 3.5, 0.05), Vector3(0, 0, -70), osso)
	_esfera(0.05, Vector3(0, 3.48, -0.1), Vector3(1, 0.5, 1.6), luz, true, 5, 3)  # marca acesa no dorso
	_fim_peca(g, "Braco", Transform3D(Basis(), Vector3(0, y_eixo, 0)))
