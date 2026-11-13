extends "res://tools/gerar_casas.gd"
## Pavilhão do Herói (Ciclo 2.23), nos quatro temas:
##   pavilhao             santuário aberto (hokora) que sobe no tapete do caminho no
##                        Nv6: base de pedra em dois degraus, quatro colunas vermelhas,
##                        telhado duplo curvo DOURADO (cor que nenhuma casa usa),
##                        shimenawa com shide e duas lanternas balançando na frente.
##                        Nós: Estoque_1 (o chapéu no altar), Adorno (topo do telhado),
##                        Enfeite (emblema no estandarte), Pano_azul/Pano_vermelho e
##                        Luz_azul/Luz_vermelho (o jogo apaga o do outro time).
##   adorno_<herói>       enfeite do topo do telhado (~0,5 m), um por herói
##   emblema_<herói>      enfeite do estandarte (o mesmo desenho, menor e chato)
## Rode depois de tools/gerar_casas.gd:
##   godot --headless --path . -s tools/gerar_pavilhao.gd
## Tudo de frente para +z (a câmera do jogo olha de +z).

const HEROIS := ["sumotori", "kappa", "yamabushi", "karasu_tengu", "mujina", "onmyoji", "tennin", "komuso",
	"ochimusha", "shishimai", "jorogumo"]
const PW := 1.7    # vão entre as colunas (x)
const PD := 1.4    # (z)
const YB := 0.36   # topo da base
const YC := 2.55   # topo das colunas


func _gerar_casas() -> bool:
	return false


func _init() -> void:
	for tema in TEMAS:
		P = TEMAS[tema]
		_dir = "res://assets/ninja/" + tema
		_pavilhao(); _salvar("pavilhao"); _completar("pavilhao", false)
		for h in HEROIS:
			_adorno_heroi(h, 1.0, 1.0); _salvar("adorno_" + h)
			_adorno_heroi(h, 0.55, 0.35); _salvar("emblema_" + h)
	print("triângulos (último tema): ", _tris)
	quit()


func _pavilhao() -> void:
	_rng.seed = 2023
	var ouro: Color = P.ouro
	var verm: Color = P.torii
	var mad: Color = P.madeira
	# Base de pedra em dois degraus e a escadinha da frente.
	_tipo = 3
	_blocod(Vector3(2.4, 0.18, 2.2), Vector3(0, 0.09, 0), Vector3.ZERO, P.pedra2, 0.05)
	_blocod(Vector3(2.05, 0.18, 1.85), Vector3(0, 0.27, -0.02), Vector3.ZERO, P.pedra, 0.05)
	_blocod(Vector3(0.8, 0.09, 0.3), Vector3(0, 0.045, 1.2), Vector3.ZERO, P.pedra2.darkened(0.08), 0.03)
	_tipo = 1
	_blocod(Vector3(1.9, 0.05, 1.7), Vector3(0, YB + 0.02, -0.02), Vector3.ZERO, mad.lightened(0.08), 0.02)
	_tipo = 0
	# Quatro colunas laqueadas com base preta e as vigas do topo.
	for p in [Vector2(-PW / 2, PD / 2), Vector2(PW / 2, PD / 2), Vector2(-PW / 2, -PD / 2), Vector2(PW / 2, -PD / 2)]:
		_cil(0.15, 0.15, 0.14, 8, Vector3(p.x, YB + 0.07, p.y), Vector3.ZERO, Color(0.08, 0.07, 0.08))
		_viga(Vector3(p.x, YB, p.y), Vector3(p.x, YC + 0.1, p.y), 0.2, verm, 0.04)
	for z in [PD / 2, -PD / 2]:
		_blocod(Vector3(PW + 0.5, 0.2, 0.22), Vector3(0, YC, z), Vector3.ZERO, verm.darkened(0.15), 0.04)
		_blocod(Vector3(PW + 0.3, 0.1, 0.16), Vector3(0, YC - 0.42, z), Vector3.ZERO, verm.darkened(0.25), 0.03)
	for x in [PW / 2, -PW / 2]:
		_blocod(Vector3(0.2, 0.18, PD + 0.4), Vector3(x, YC + 0.02, 0), Vector3.ZERO, verm.darkened(0.2), 0.04)
	# Kumimono: consolos dourados em cima de cada coluna.
	for p in [Vector2(-PW / 2, PD / 2), Vector2(PW / 2, PD / 2)]:
		_blocod(Vector3(0.36, 0.12, 0.3), Vector3(p.x, YC + 0.17, p.y + 0.04), Vector3.ZERO, ouro.darkened(0.2), 0.03)
	# Altar: mesinha preta com borda dourada; a luz do time embaixo do chapéu.
	_blocod(Vector3(0.82, 0.56, 0.56), Vector3(0, YB + 0.28, -0.12), Vector3.ZERO, Color(0.09, 0.07, 0.08), 0.03)
	_blocod(Vector3(0.9, 0.06, 0.62), Vector3(0, YB + 0.58, -0.12), Vector3.ZERO, ouro.darkened(0.15), 0.02)
	_cil(0.26, 0.3, 0.1, 10, Vector3(0, YB + 0.66, -0.12), Vector3.ZERO, ouro.darkened(0.3))
	for k in TIMES:
		var g := _inicio_peca()
		_cil(0.24, 0.24, 0.03, 12, Vector3.ZERO, Vector3.ZERO, TIMES[k].lightened(0.3), true)
		_toro(0.2, 0.27, Vector3(0, 0.02, 0), Vector3(1, 0.4, 1), TIMES[k])
		_fim_peca(g, "Luz_" + k, Transform3D(Basis(), Vector3(0, YB + 0.73, -0.12)))
	_pecas_marcador("Estoque_1", Vector3(0, YB + 0.78, -0.12))
	# Fundo: biombo baixo de papel atrás do altar (o chapéu lê contra ele).
	_blocod(Vector3(PW - 0.1, 1.1, 0.06), Vector3(0, YB + 0.55, -PD / 2 + 0.05), Vector3.ZERO, P.papel.darkened(0.12), 0.01)
	for x in [-0.55, 0.0, 0.55]:
		_blocod(Vector3(0.05, 1.12, 0.08), Vector3(x, YB + 0.55, -PD / 2 + 0.07), Vector3.ZERO, Color(0.1, 0.08, 0.08), 0.01)
	# Shimenawa: corda grossa caída entre as colunas da frente, com quatro shide.
	var zf := PD / 2 + 0.14
	var m := _marca()
	for k in 8:
		var t0 := k / 8.0
		var t1 := (k + 1) / 8.0
		var y0 := YC - 0.3 - sin(t0 * PI) * 0.22
		var y1 := YC - 0.3 - sin(t1 * PI) * 0.22
		_viga(Vector3(lerpf(-PW / 2, PW / 2, t0), y0, zf), Vector3(lerpf(-PW / 2, PW / 2, t1), y1, zf), 0.11, P.corda.lightened(0.1), 0.03)
	_vento_pendurado(m, YC - 0.3, 0.6, 0.25)
	for k in 4:
		var x := lerpf(-PW / 2, PW / 2, (k + 0.5) / 4.0)
		var yt := YC - 0.36 - sin((k + 0.5) / 4.0 * PI) * 0.22
		var ms := _marca()
		for j in 3:  # zigue-zague de papel
			_blocod(Vector3(0.12, 0.14, 0.015), Vector3(x + (0.03 if j % 2 else -0.03), yt - 0.08 - j * 0.13, zf + 0.02), Vector3(0, 0, 12 if j % 2 else -12), P.branco, 0.0)
		_vento_pendurado(ms, yt, 0.45, 0.9)
	# Duas lanternas penduradas nos cantos da frente.
	for s in [-1.0, 1.0]:
		var ml := _marca()
		var x: float = s * (PW / 2 + 0.38)
		_cil(0.015, 0.015, 0.3, 4, Vector3(x, YC - 0.25, PD / 2 + 0.2), Vector3.ZERO, Color(0.1, 0.1, 0.1))
		_esfera(0.17, Vector3(x, YC - 0.58, PD / 2 + 0.2), Vector3(1, 1.3, 1), P.luz1, true, 7, 4)
		_cil(0.1, 0.1, 0.04, 6, Vector3(x, YC - 0.36, PD / 2 + 0.2), Vector3.ZERO, Color(0.1, 0.08, 0.08))
		_cil(0.1, 0.1, 0.04, 6, Vector3(x, YC - 0.8, PD / 2 + 0.2), Vector3.ZERO, Color(0.1, 0.08, 0.08))
		_vento_pendurado(ml, YC - 0.1, 0.8, 0.7)
	# Telhado duplo curvo dourado com cumeeira e o pináculo do adorno.
	var borda := verm.darkened(0.45)
	var f1 := func(px: float, pz: float) -> float:
		return _altura_telhado(px, pz, 2.75, 2.45, 0.62, 0.06, 0.42)
	_superficie(Vector3(0, YC + 0.22, 0), f1, -1.375, 1.375, -1.225, 1.225, 10, 9, 0.12, ouro, borda)
	var y2: float = YC + 0.22 + f1.call(0.0, 0.0) - 0.08
	_blocod(Vector3(1.1, 0.34, 0.9), Vector3(0, y2 + 0.12, 0), Vector3.ZERO, verm.darkened(0.2), 0.03)
	var f2 := func(px: float, pz: float) -> float:
		return _altura_telhado(px, pz, 1.75, 1.55, 0.55, 0.05, 0.5)
	_superficie(Vector3(0, y2 + 0.3, 0), f2, -0.875, 0.875, -0.775, 0.775, 8, 7, 0.1, ouro.lightened(0.08), borda)
	var yt2: float = y2 + 0.3 + f2.call(0.0, 0.0)
	_blocod(Vector3(0.5, 0.14, 0.24), Vector3(0, yt2 + 0.02, 0), Vector3.ZERO, borda, 0.03)
	_cil(0.07, 0.11, 0.18, 8, Vector3(0, yt2 + 0.15, 0), Vector3.ZERO, ouro.darkened(0.25))
	_pecas_marcador("Adorno", Vector3(0, yt2 + 0.26, 0))
	# Estandarte lateral (nobori): mastro e um pano por time, com o emblema.
	var bp := Vector3(1.42, 0, 0.55)
	_tipo = 3
	_blocod(Vector3(0.32, 0.22, 0.32), bp + Vector3(0, 0.11, 0), Vector3.ZERO, P.pedra2, 0.03)
	_tipo = 0
	_viga(bp, bp + Vector3(0, 3.7, 0), 0.08, mad.darkened(0.25))
	_viga(bp + Vector3(0, 3.5, 0), bp + Vector3(0, 3.5, 0.62), 0.05, mad.darkened(0.25))
	_esfera(0.08, bp + Vector3(0, 3.74, 0), Vector3.ONE, ouro, false, 6, 3)
	for k in TIMES:
		var cor: Color = TIMES[k]
		var g := _inicio_peca()
		var mp := _marca()
		_blocod(Vector3(0.03, 2.1, 0.56), Vector3(0, -1.08, 0.31), Vector3.ZERO, cor.darkened(0.15), 0.01)
		_blocod(Vector3(0.04, 0.14, 0.58), Vector3(0, -0.08, 0.31), Vector3.ZERO, ouro.darkened(0.1), 0.01)
		_blocod(Vector3(0.04, 0.14, 0.58), Vector3(0, -2.1, 0.31), Vector3.ZERO, cor.darkened(0.45), 0.01)
		_cil(0.24, 0.24, 0.02, 14, Vector3(0.025, -0.9, 0.31), Vector3(0, 0, 90), P.branco.lerp(cor, 0.12))
		_vento_pendurado(mp, 0.0, 2.2, 0.6)
		_fim_peca(g, "Pano_" + k, Transform3D(Basis(), bp + Vector3(0, 3.48, 0)))
	_pecas_marcador("Enfeite", bp + Vector3(0.06, 2.58, 0.31))


## Enfeite do herói. `e` = escala, `fundo` = profundidade (emblema é chato).
func _adorno_heroi(h: String, e: float, fundo: float) -> void:
	var z := Vector3(e, e, e * fundo)
	var branco: Color = P.branco
	var ouro: Color = P.ouro
	match h:
		"sumotori":  # coque preto dobrado com a tsuna branca em volta
			_esfera(0.2 * e, Vector3(0, 0.12 * e, 0), Vector3(1.1, 0.8, 1.0 * fundo), Color(0.06, 0.05, 0.07), false, 8, 4)
			_cil(0.07 * e, 0.07 * e, 0.38 * e, 8, Vector3(0, 0.3 * e, 0), Vector3(0, 0, 90), Color(0.06, 0.05, 0.07), false, Vector3(1, 1, fundo))
			_esfera(0.11 * e, Vector3(0.22 * e, 0.32 * e, 0), Vector3(0.7, 1.3, fundo), Color(0.06, 0.05, 0.07), false, 6, 3)
			_toro(0.2 * e, 0.27 * e, Vector3(0, 0.05 * e, 0), Vector3(1, 0.6, fundo), branco)
			for s in [-1.0, 1.0]:
				_blocod(Vector3(0.08, 0.16, 0.015) * e, Vector3(s * 0.14 * e, -0.06 * e, 0.2 * e * fundo), Vector3(0, 0, 14 * s), branco, 0.0)
		"kappa":  # prato com água acesa e o tufo verde
			for k in 7:
				var a := TAU * k / 7.0
				_cil(0.0, 0.05 * e, 0.2 * e, 4, Vector3(cos(a) * 0.2 * e, 0.06 * e, sin(a) * 0.2 * e * fundo), Vector3(sin(a) * 35, 0, -cos(a) * 35), Color(0.25, 0.5, 0.3))
			_cil(0.24 * e, 0.2 * e, 0.08 * e, 12, Vector3(0, 0.1 * e, 0), Vector3.ZERO, Color(0.86, 0.83, 0.72), false, Vector3(1, 1, fundo))
			_cil(0.2 * e, 0.2 * e, 0.02 * e, 12, Vector3(0, 0.15 * e, 0), Vector3.ZERO, Color(0.35, 0.85, 0.95), true, Vector3(1, 1, fundo))
			if fundo < 0.9:  # no estandarte o prato fica de frente
				_cil(0.2 * e, 0.2 * e, 0.02, 12, Vector3(0, 0.1 * e, 0.06), Vector3(90, 0, 0), Color(0.35, 0.85, 0.95), true)
		"yamabushi":  # leque de penas em meia-lua com cabo
			_viga(Vector3(0, -0.05, 0) * e, Vector3(0, 0.15, 0) * e, 0.05 * e, P.madeira2)
			for k in 7:
				var a := deg_to_rad(lerpf(-65.0, 65.0, k / 6.0))
				_esfera(0.07 * e, Vector3(sin(a) * 0.2, 0.15 + cos(a) * 0.2, 0) * e, Vector3(0.55, 1.6, 0.25 * fundo + 0.1), branco if k % 2 else branco.darkened(0.1), false, 6, 3)
				_esfera(0.03 * e, Vector3(sin(a) * 0.38, 0.15 + cos(a) * 0.38, 0.01) * e, Vector3(1, 1, 0.5), Color(1.0, 0.55, 0.18), false, 4, 2)
			_esfera(0.05 * e, Vector3(0, 0.15, 0.02) * e, Vector3.ONE, Color(1.0, 0.55, 0.18), false, 5, 3)
		"karasu_tengu":  # pena preta comprida, com brilho azul
			_esfera(0.1 * e, Vector3(0.02, 0.22, 0) * e, Vector3(0.7, 2.6, 0.3 * fundo + 0.1), Color(0.08, 0.08, 0.12), false, 8, 4)
			_esfera(0.05 * e, Vector3(0.04, 0.28, 0.02) * e, Vector3(0.5, 3.2, 0.3), Color(0.2, 0.24, 0.45), false, 6, 3)
			_viga(Vector3(-0.04, -0.06, 0) * e, Vector3(0.06, 0.52, 0) * e, 0.018 * e, Color(0.75, 0.6, 0.2))
		"mujina":  # máscara lisa: um ovo pálido com a fenda fina
			_esfera(0.2 * e, Vector3(0, 0.2 * e, 0), Vector3(0.85, 1.1, 0.55 * fundo + 0.15), Color(0.94, 0.91, 0.87), false, 10, 5)
			_blocod(Vector3(0.18, 0.018, 0.02) * e, Vector3(0, 0.2 * e, 0.12 * e * (0.55 * fundo + 0.15) / 0.7 + 0.01), Vector3.ZERO, Color(0.72, 0.45, 0.95), 0.0)
			_esfera(0.21 * e, Vector3(0, 0.3 * e, -0.03 * e), Vector3(0.9, 0.6, 0.3 * fundo + 0.1), Color(0.05, 0.05, 0.07), false, 8, 3)
		"onmyoji":  # grou de papel (tsuru)
			_tri(Vector3(-0.32, 0.18, 0) * e, Vector3(0, 0.1, 0.12 * fundo) * e, Vector3(0, 0.34, 0) * e, branco, Vector3(0, 0, 1))
			_tri(Vector3(0, 0.34, 0) * e, Vector3(0, 0.1, 0.12 * fundo) * e, Vector3(0.32, 0.18, 0) * e, branco.darkened(0.08), Vector3(0, 0, 1))
			_tri(Vector3(0, 0.34, 0) * e, Vector3(0, 0.1, -0.12 * fundo) * e, Vector3(-0.32, 0.18, 0) * e, branco.darkened(0.15), Vector3(0, 0, -1))
			_tri(Vector3(0.32, 0.18, 0) * e, Vector3(0, 0.1, -0.12 * fundo) * e, Vector3(0, 0.34, 0) * e, branco.darkened(0.15), Vector3(0, 0, -1))
			_cil(0.0, 0.03 * e, 0.26 * e, 4, Vector3(-0.1, 0.36, 0) * e, Vector3(0, 0, 30), branco)
			_cil(0.0, 0.03 * e, 0.22 * e, 4, Vector3(0.1, 0.33, 0) * e, Vector3(0, 0, -40), branco)
			_blocod(Vector3(0.04, 0.04, 0.02) * e, Vector3(-0.16, 0.47, 0) * e, Vector3(0, 0, 30), Color(0.8, 0.12, 0.1), 0.0)
		"tennin":  # laço do manto: duas voltas e as pontas caídas, com uma joia
			var rosa := Color(1.0, 0.72, 0.78)
			for s in [-1.0, 1.0]:
				_toro(0.06 * e, 0.13 * e, Vector3(s * 0.13 * e, 0.24 * e, 0), Vector3(1.2, 0.8, fundo), rosa)
				_blocod(Vector3(0.08, 0.26, 0.02) * e, Vector3(s * 0.07, 0.06, 0) * e, Vector3(0, 0, 20 * s), rosa.darkened(0.1), 0.01)
			_esfera(0.06 * e, Vector3(0, 0.24 * e, 0.03 * e), Vector3.ONE, ouro, true, 6, 3)
		"komuso":  # tengai: cesto fundo de palha com a janelinha
			var palha := Color(0.66, 0.52, 0.28)
			_cil(0.15 * e, 0.22 * e, 0.36 * e, 10, Vector3(0, 0.18 * e, 0), Vector3.ZERO, palha, false, Vector3(1, 1, fundo + 0.1))
			for y in [0.06, 0.18, 0.3]:
				_cil(0.2 * e - y * 0.2 * e, 0.21 * e - y * 0.2 * e, 0.02 * e, 10, Vector3(0, y * e, 0), Vector3.ZERO, palha.darkened(0.3), false, Vector3(1, 1, fundo + 0.1))
			_blocod(Vector3(0.14, 0.04, 0.02) * e, Vector3(0, 0.2 * e, 0.19 * e * (fundo + 0.1)), Vector3.ZERO, Color(0.1, 0.07, 0.05), 0.0)
		"ochimusha":  # kabuto rachado com um chifre quebrado e a flecha cravada
			var ferro := Color(0.2, 0.2, 0.24)
			_esfera(0.2 * e, Vector3(0, 0.14 * e, 0), Vector3(1.1, 0.75, 1.0 * fundo), ferro, false, 10, 4)
			_cil(0.24 * e, 0.26 * e, 0.03 * e, 10, Vector3(0, 0.07 * e, 0), Vector3(-6, 0, 5), Color(0.08, 0.08, 0.1), false, Vector3(1, 1, fundo))
			_cil(0.0, 0.035 * e, 0.28 * e, 5, Vector3(-0.1, 0.32, 0.02) * e, Vector3(0, 0, 32), Color(0.62, 0.5, 0.25))
			_cil(0.02 * e, 0.035 * e, 0.1 * e, 5, Vector3(0.09, 0.25, 0.02) * e, Vector3(0, 0, -32), Color(0.62, 0.5, 0.25))
			for k in 3:
				_blocod(Vector3(0.018, 0.07, 0.02) * e, Vector3(0.04 + k * 0.03, 0.2 - k * 0.04, 0.17 * fundo + 0.01) * e, Vector3(0, 0, 30 - k * 30), Color(0.55, 0.78, 1.0), 0.0)
			_viga(Vector3(-0.2, 0.0, 0) * e, Vector3(0.18, 0.42, 0) * e, 0.014 * e, P.madeira2)
			_tri(Vector3(0.16, 0.4, 0) * e, Vector3(0.26, 0.48, 0) * e, Vector3(0.2, 0.36, 0) * e, Color(0.55, 0.78, 1.0), Vector3(0, 0, 1))
		"shishimai":  # cabeça de leão vermelha com olhos dourados e juba branca
			var laca := Color(0.78, 0.12, 0.1)
			for k in 7:
				var a := deg_to_rad(lerpf(-110.0, 110.0, k / 6.0))
				_esfera(0.07 * e, Vector3(sin(a) * 0.2, 0.18 + cos(a) * 0.14, -0.04) * e, Vector3(0.8, 1.4, 0.4 * fundo + 0.1), branco, false, 6, 3)
			_esfera(0.17 * e, Vector3(0, 0.18 * e, 0), Vector3(1.15, 0.95, 0.9 * fundo), laca, false, 10, 4)
			_blocod(Vector3(0.24, 0.08, 0.12 * fundo + 0.02) * e, Vector3(0, 0.08, 0.1 * fundo) * e, Vector3(8, 0, 0), laca.darkened(0.1), 0.01)
			for s2 in [-1.0, 1.0]:
				_esfera(0.045 * e, Vector3(s2 * 0.08, 0.24, 0.14 * fundo + 0.01) * e, Vector3.ONE, ouro, true, 6, 3)
			for k in 4:
				_blocod(Vector3(0.03, 0.035, 0.02) * e, Vector3((k - 1.5) * 0.05, 0.05, 0.16 * fundo + 0.02) * e, Vector3.ZERO, branco, 0.0)
		"jorogumo":  # aranha de ouro com o corpo escuro e teia atrás
			for k in 4:
				_viga(Vector3(0, 0.2, -0.02) * e, Vector3(cos(TAU * k / 8.0) * 0.26, 0.2 + sin(TAU * k / 8.0) * 0.26, -0.02) * e, 0.008 * e, branco.darkened(0.15))
				_viga(Vector3(0, 0.2, -0.02) * e, Vector3(-cos(TAU * k / 8.0) * 0.26, 0.2 - sin(TAU * k / 8.0) * 0.26, -0.02) * e, 0.008 * e, branco.darkened(0.15))
			for r in [0.1, 0.18]:  # espiral da teia: dois octógonos no plano da frente
				for k in 8:
					var a0 := TAU * k / 8.0
					var a1 := TAU * (k + 1) / 8.0
					_viga(Vector3(cos(a0) * r, 0.2 + sin(a0) * r, -0.02) * e, Vector3(cos(a1) * r, 0.2 + sin(a1) * r, -0.02) * e, 0.007 * e, branco.darkened(0.15))
			_esfera(0.09 * e, Vector3(0, 0.16 * e, 0.02 * e), Vector3(0.9, 1.25, 0.7 * fundo + 0.2), Color(0.12, 0.07, 0.14), false, 8, 4)
			_esfera(0.06 * e, Vector3(0, 0.29 * e, 0.02 * e), Vector3(1, 0.9, 0.7 * fundo + 0.2), Color(0.12, 0.07, 0.14), false, 6, 3)
			_blocod(Vector3(0.05, 0.05, 0.02) * e, Vector3(0, 0.15, 0.07 * fundo + 0.02) * e, Vector3(0, 0, 45), Color(0.85, 0.16, 0.3), 0.0)
			for s2 in [-1.0, 1.0]:
				for k in 3:
					var y0 := 0.22 - k * 0.06
					_viga(Vector3(s2 * 0.05, y0, 0.02) * e, Vector3(s2 * 0.2, y0 + 0.08 - k * 0.05, 0.02) * e, 0.012 * e, ouro.darkened(0.1))

