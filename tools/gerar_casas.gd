extends "res://tools/gerar_economia.gd"
## Casas das classes (Ciclo 2.21), nos quatro temas:
##   maquina_<base>      a barraquinha de festival da classe do pátio: a maquininha
##                       de antes (mesmos nós) com toldo listrado, franja e lanternas
##   maquina_<evoluída>  a casa de cada caminho (8): é a maquininha da classe
##                       evoluída (contrato do HatPad: Molde, Prensa, Estoque_1..5,
##                       Enfeite, Vapor, "fabricar"), com "Telhado" à parte (cai no
##                       fim da obra) e uma peça por nível (Ciclo 2.22: a casa nasce
##                       no nível 3): N4_Andar (nível 4), N5_Topo e N5_Estandartes (5).
##                       A barraquinha ganha N3_Lanternas, N4_Nobori e N5_Arco.
##   bairro_<base>       chão pintado do bairro, os dois tapetes (Tapete_0/1), o selo
##                       de cada um (Selo_0/1, escondido), o estandarte com um pano por
##                       dono (Pano_azul, Pano_vermelho, Pano_c0, Pano_c1) e os
##                       marcadores Emblema_bandeira, Emblema_0, Emblema_1
##   emblema_sohei, emblema_kusarigama
## Posições do bairro iguais às de scripts/items/oficina.gd (CASA, BARRACA, TAPETES,
## BANDEIRA). Rode depois de tools/gerar_economia.gd:
##   godot --headless --path . -s tools/gerar_casas.gd
## Tudo de frente para +z (a câmera do jogo olha de +z).

const BASES := {
	"guerreiro": ["ronin_oni", "sohei"],
	"arqueiro": ["arqueiro_yumi", "kusarigama"],
	"kitsune": ["kitsune_luz", "kitsune_sombria"],
	"construtor": ["armadilheiro", "bombardeiro"],
}
## Cor do chapéu de cada classe (config/classes/*.tres; o gerador não carrega
## os .tres para não depender dos scripts do jogo).
const COR := {
	"guerreiro": Color(1, 0.78, 0.3), "arqueiro": Color(0.3, 0.95, 1), "kitsune": Color(1, 0.45, 0.75),
	"construtor": Color(1, 0.6, 0.2), "ronin_oni": Color(0.85, 0.12, 0.12), "sohei": Color(0.35, 0.86, 0.74),
	"arqueiro_yumi": Color(0.6, 0.4, 0.2), "kusarigama": Color(0.5, 0.56, 1), "kitsune_luz": Color(1, 0.92, 0.6),
	"kitsune_sombria": Color(0.55, 0.25, 0.95), "armadilheiro": Color(0.45, 1, 0.45), "bombardeiro": Color(1, 0.32, 0.12),
}
# Bairro (igual a Oficina.TAPETES / BANDEIRA).
const TAPETES := [Vector3(-3.7, 0, 0.3), Vector3(3.7, 0, 0.3)]
const BANDEIRA := Vector3(4.3, 0, -3.3)
const RAIO := 5.4
# Casa.
const W := 3.4
const D := 2.6
const Y0 := 0.3
const HP := 2.1
const ZM := 1.15  # z do molde (balcão na frente da casa)


func _gerar_economia() -> bool:
	return false


func _init() -> void:
	for tema in TEMAS:
		P = TEMAS[tema]
		_dir = "res://assets/ninja/" + tema
		for base in BASES:
			_barraquinha(base); _salvar("maquina_" + base); _completar("maquina_" + base, true)
			for c in BASES[base]:
				_casa(c); _salvar("maquina_" + c); _completar("maquina_" + c, true)
			_bairro(base); _salvar("bairro_" + base); _completar("bairro_" + base, false)
		for c in ["sohei", "kusarigama"]:
			_emblema(c); _salvar("emblema_" + c)
		for velho in ["oficina_azul", "oficina_vermelho"]:
			var arq := _dir.path_join(velho + ".scn")
			if FileAccess.file_exists(arq):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(arq))
	print("triângulos (último tema): ", _tris)
	quit()


# --- Barraquinha de festival (classe do pátio) ----------------------------------

## A maquininha da classe com cara de yatai: dois postes atrás, toldo listrado
## na cor da classe inclinado para a câmera, franja recortada e um varal de
## chōchin. O nível 2 (N2_*) continua por cima.
func _barraquinha(base: String) -> void:
	_rng.seed = 80 + base.length()
	match base:
		"guerreiro": _maq_forja()
		"arqueiro": _maq_shuriken()
		"kitsune": _maq_raposa()
		"construtor": _maq_serraria()
	var cor: Color = COR[base]
	var mad: Color = P.madeira
	var xs := 1.45
	var zt := -0.85   # postes de trás
	var zf := -0.05   # beirada da frente do toldo (não tampa a casa atrás)
	var yt := 3.3
	var yf := 3.1
	for s in [-1.0, 1.0]:
		_viga(Vector3(s * xs, 0.0, zt), Vector3(s * xs, yt + 0.1, zt), 0.13, mad, 0.03)
		_viga(Vector3(s * xs, yt, zt), Vector3(s * xs, yf, zf), 0.1, mad, 0.03)
	# Toldo: faixas na cor da classe e brancas, alternadas ao longo de x.
	var n := 7
	for k in n:
		var x0 := -xs - 0.1 + (2.0 * xs + 0.2) * k / n
		var x1 := -xs - 0.1 + (2.0 * xs + 0.2) * (k + 1) / n
		var c: Color = cor.darkened(0.1) if k % 2 == 0 else P.branco.darkened(0.04)
		_quad(Vector3(x0, yt + 0.06, zt - 0.15), Vector3(x1, yt + 0.06, zt - 0.15), Vector3(x1, yf + 0.06, zf), Vector3(x0, yf + 0.06, zf), c, Vector3(0, 1, 0.4))
		_quad(Vector3(x0, yt + 0.02, zt - 0.15), Vector3(x1, yt + 0.02, zt - 0.15), Vector3(x1, yf + 0.02, zf), Vector3(x0, yf + 0.02, zf), c.darkened(0.45), Vector3(0, -1, -0.3))
	# Franja recortada (noren curtinho) na frente, balançando.
	var m := _marca()
	var nf := 9
	for k in nf:
		var x0 := -xs - 0.1 + (2.0 * xs + 0.2) * k / nf
		var x1 := -xs - 0.1 + (2.0 * xs + 0.2) * (k + 1) / nf
		var c: Color = cor if k % 2 == 0 else P.branco
		_quad(Vector3(x0, yf + 0.05, zf + 0.01), Vector3(x1, yf + 0.05, zf + 0.01), Vector3(x1, yf - 0.22, zf + 0.01), Vector3(x0, yf - 0.22, zf + 0.01), c, Vector3(0, 0, 1))
		_tri(Vector3(x0, yf - 0.22, zf + 0.01), Vector3(x1, yf - 0.22, zf + 0.01), Vector3((x0 + x1) / 2, yf - 0.34, zf + 0.01), c, Vector3(0, 0, 1))
	_vento_pendurado(m, yf + 0.05, 0.4, 0.7)
	# Varal de lanternas de papel na beirada (vermelhas e brancas, acesas).
	m = _marca()
	_viga(Vector3(-xs, yf - 0.05, zf + 0.06), Vector3(xs, yf - 0.05, zf + 0.06), 0.02, P.corda.darkened(0.3), 0.0)
	for k in 4:
		var x := -1.05 + k * 0.7
		var c: Color = P.torii.lightened(0.15) if k % 2 == 0 else P.papel
		_esfera(0.13, Vector3(x, yf - 0.24, zf + 0.08), Vector3(1, 1.25, 1), c, true, 7, 4)
		_cil(0.07, 0.07, 0.04, 6, Vector3(x, yf - 0.08, zf + 0.08), Vector3.ZERO, Color(0.1, 0.08, 0.08))
	_vento_pendurado(m, yf - 0.05, 0.35, 0.5)
	# Plaquinha com a cor da classe no poste da esquerda (o nome sai no letreiro).
	_blocod(Vector3(0.2, 0.9, 0.05), Vector3(-xs - 0.02, 2.2, zt + 0.1), Vector3.ZERO, P.papel, 0.01)
	_blocod(Vector3(0.24, 0.08, 0.06), Vector3(-xs - 0.02, 2.66, zt + 0.1), Vector3.ZERO, cor.darkened(0.2), 0.01)
	_nivel2()
	_barraca_niveis(base, cor)


## Níveis 3 a 5 da barraquinha (Ciclo 2.22: ela sobe junto com a casa do
## caminho). Uma peça por nível, cada uma com silhueta própria para ler de
## longe: N3 dois tōrō de pedra acesos na frente, N4 um nobori alto na cor da
## classe ao lado, N5 um arco dourado com fitas de papel por cima do toldo.
func _barraca_niveis(base: String, cor: Color) -> void:
	for s in [-1.0, 1.0]:
		var g := _inicio_peca()
		_tipo = 3
		_cil(0.3, 0.36, 0.16, 6, Vector3(0, 0.08, 0), Vector3.ZERO, P.pedra2.darkened(0.05))
		_cil(0.1, 0.13, 0.62, 6, Vector3(0, 0.47, 0), Vector3.ZERO, P.pedra2)
		_cil(0.26, 0.22, 0.1, 6, Vector3(0, 0.83, 0), Vector3.ZERO, P.pedra2.darkened(0.1))
		_tipo = 0
		_caixa(Vector3(0.3, 0.28, 0.3), Vector3(0, 1.02, 0), Vector3.ZERO, P.luz1, true)
		for k in 4:
			var a := k * PI / 2.0
			_caixa(Vector3(0.06, 0.3, 0.06), Vector3(cos(a) * 0.17, 1.02, sin(a) * 0.17), Vector3.ZERO, P.pedra2.darkened(0.25))
		_cil(0.04, 0.38, 0.26, 6, Vector3(0, 1.3, 0), Vector3.ZERO, P.pedra2.darkened(0.15))
		_esfera(0.07, Vector3(0, 1.48, 0), Vector3.ONE, cor.lightened(0.1), true, 6, 3)
		_fim_peca(g, "N3_Toro_%s" % ("E" if s < 0 else "D"), Transform3D(Basis(), Vector3(s * 1.95, 0.0, 1.05)))
	# N4: nobori, a bandeira vertical de festival (pano comprido preso num
	# mastro em "L"), na cor da classe com faixa branca e o pé de pedra.
	var g4 := _inicio_peca()
	var mad: Color = P.madeira.darkened(0.15)
	_blocod(Vector3(0.36, 0.2, 0.36), Vector3(0, 0.1, 0), Vector3.ZERO, P.pedra2.darkened(0.1), 0.03)
	_viga(Vector3(0, 0.1, 0), Vector3(0, 5.0, 0), 0.08, mad)
	_viga(Vector3(0, 4.85, 0), Vector3(-0.75, 4.85, 0), 0.05, mad)
	var m := _marca()
	_blocod(Vector3(0.62, 3.0, 0.03), Vector3(-0.38, 3.3, 0), Vector3.ZERO, cor.darkened(0.12), 0.01)
	_blocod(Vector3(0.18, 2.3, 0.04), Vector3(-0.38, 3.2, 0.01), Vector3.ZERO, P.branco, 0.01)
	_blocod(Vector3(0.64, 0.12, 0.04), Vector3(-0.38, 4.75, 0.0), Vector3.ZERO, P.ouro, 0.01)
	_vento_pendurado(m, 4.8, 3.2, 0.9)
	_fim_peca(g4, "N4_Nobori", Transform3D(Basis(), Vector3(2.35, 0.0, -0.35)))
	# N5: arco dourado (dois pilares e uma verga curva) com shide, as fitas de
	# papel em ziguezague, e uma corda grossa (shimenawa) entre os pilares.
	var g5 := _inicio_peca()
	var xa := 1.85
	for s in [-1.0, 1.0]:
		_cil(0.11, 0.13, 3.7, 8, Vector3(s * xa, 1.85, 0), Vector3.ZERO, P.torii)
		_cil(0.15, 0.15, 0.16, 8, Vector3(s * xa, 0.08, 0), Vector3.ZERO, P.ouro.darkened(0.2))
	var n := 8
	for k in n:
		var t0 := float(k) / n
		var t1 := float(k + 1) / n
		var x0 := lerpf(-xa - 0.45, xa + 0.45, t0)
		var x1 := lerpf(-xa - 0.45, xa + 0.45, t1)
		var y0 := 3.75 + 0.35 * pow(absf(t0 * 2.0 - 1.0), 2.0)
		var y1 := 3.75 + 0.35 * pow(absf(t1 * 2.0 - 1.0), 2.0)
		_viga(Vector3(x0, y0, 0), Vector3(x1, y1, 0), 0.13, P.ouro)
	_viga(Vector3(-xa, 3.3, 0.02), Vector3(xa, 3.3, 0.02), 0.08, P.torii.darkened(0.2))
	var mc := _marca()
	for k in 7:
		var x := lerpf(-xa + 0.3, xa - 0.3, k / 6.0)
		_esfera(0.09, Vector3(x, 3.34 - 0.08 * sin(k / 6.0 * PI), 0.06), Vector3(1.6, 1, 1), P.corda, false, 6, 3)
	_vento_pendurado(mc, 3.4, 0.3, 0.3)
	for k in 4:
		var x := lerpf(-xa + 0.55, xa - 0.55, k / 3.0)
		var mf := _marca()
		for j in 3:
			var dx := 0.06 if j % 2 == 0 else -0.06
			_blocod(Vector3(0.12, 0.2, 0.01), Vector3(x + dx, 3.12 - j * 0.19, 0.09), Vector3(0, 0, -dx * 200.0), P.papel, 0.0)
		_vento_pendurado(mf, 3.25, 0.7, 1.0)
	_esfera(0.16, Vector3(0, 4.2, 0.05), Vector3(1, 1.2, 1), cor.lightened(0.2), true, 8, 4)
	_fim_peca(g5, "N5_Arco", Transform3D(Basis(), Vector3(0, 0.0, 1.35)))


# --- Casa da classe evoluída ------------------------------------------------------

## Cores e jeito de cada casa: paredes, pilares, telhado, acento, luz das
## janelas, desenho das paredes (1 tábuas, 3 pedras, 4 reboco) e curva do beiral.
func _estilo(c: String) -> Dictionary:
	var acento: Color = COR[c]
	match c:
		"ronin_oni":
			return {"parede": P.madeira.darkened(0.5), "pilar": Color(0.1, 0.08, 0.09), "telhado": Color(0.3, 0.16, 0.15).lerp(P.telhado, 0.15),
				"acento": acento, "luz": Color(1.0, 0.38, 0.16), "tipo": 1, "curva": 0.42}
		"sohei":
			return {"parede": P.reboco, "pilar": P.torii.darkened(0.1), "telhado": P.telhado.lerp(Color(0.18, 0.42, 0.4), 0.55),
				"acento": acento, "luz": P.papel, "tipo": 4, "curva": 0.3}
		"arqueiro_yumi":
			return {"parede": P.madeira2, "pilar": P.madeira, "telhado": P.telhado.lerp(Color(0.3, 0.4, 0.22), 0.5),
				"acento": acento.lightened(0.15), "luz": P.papel, "tipo": 1, "curva": 0.18}
		"kusarigama":
			return {"parede": Color(0.16, 0.17, 0.25), "pilar": Color(0.09, 0.09, 0.12), "telhado": Color(0.2, 0.22, 0.34),
				"acento": acento, "luz": Color(0.62, 0.72, 1.0), "tipo": 1, "curva": 0.28}
		"kitsune_luz":
			return {"parede": P.branco.darkened(0.05), "pilar": P.ouro.darkened(0.15), "telhado": Color(0.94, 0.9, 0.8).lerp(P.telhado, 0.15),
				"acento": P.ouro, "luz": Color(1.0, 0.9, 0.6), "tipo": 4, "curva": 0.34}
		"kitsune_sombria":
			return {"parede": Color(0.26, 0.18, 0.33), "pilar": Color(0.4, 0.15, 0.55), "telhado": Color(0.3, 0.2, 0.42),
				"acento": acento, "luz": Color(0.66, 0.36, 1.0), "tipo": 4, "curva": 0.5}
		"armadilheiro":
			return {"parede": P.bambu.darkened(0.15), "pilar": P.madeira, "telhado": Color(0.72, 0.62, 0.36),
				"acento": acento.darkened(0.2), "luz": P.luz1, "tipo": 1, "curva": 0.08}
		"bombardeiro":
			return {"parede": P.pedra, "pilar": Color(0.14, 0.11, 0.1), "telhado": P.telhado.darkened(0.3),
				"acento": acento, "luz": P.luz2, "tipo": 3, "curva": 0.2}
	return {"parede": P.reboco, "pilar": P.madeira, "telhado": P.telhado, "acento": acento, "luz": P.papel, "tipo": 4, "curva": 0.25}


## Corpo comum: alicerce, varanda com a prateleira dos chapéus (Estoque_1..5),
## paredes, janelas de papel acesas dos lados do vão aberto, balcão com o molde,
## prensa pendurada na verga, placa do emblema, telhado (nó "Telhado") e os
## andares dos níveis 3 e 4. Depois, os enfeites que dão a cara de cada classe.
func _casa(c: String) -> void:
	_rng.seed = 300 + c.length() * 7
	var e := _estilo(c)
	_cor_brilho = e.luz
	_cor_vapor = Color(-1, 0, 0)
	var yt := Y0 + HP
	var mad: Color = P.madeira
	# Alicerce de pedra e varanda (engawa).
	_tipo = 3
	_blocod(Vector3(W + 0.4, Y0, D + 0.3), Vector3(0, Y0 / 2, -0.05), Vector3.ZERO, P.pedra2, 0.06)
	_tipo = 1
	_blocod(Vector3(W + 0.3, 0.14, 0.8), Vector3(0, Y0 - 0.02, D / 2 + 0.45), Vector3.ZERO, mad.lightened(0.05), 0.03)
	for x in [-W / 2, -0.6, 0.6, W / 2]:
		_blocod(Vector3(0.12, Y0 - 0.06, 0.12), Vector3(x, (Y0 - 0.06) / 2, D / 2 + 0.75), Vector3.ZERO, mad.darkened(0.2), 0.02)
	# Paredes de trás e dos lados.
	_tipo = e.tipo
	_blocod(Vector3(W - 0.1, HP, 0.16), Vector3(0, Y0 + HP / 2, -D / 2 + 0.08), Vector3.ZERO, e.parede, 0.03)
	for s in [-1.0, 1.0]:
		_blocod(Vector3(0.16, HP, D - 0.1), Vector3(s * (W / 2 - 0.08), Y0 + HP / 2, 0), Vector3.ZERO, e.parede.darkened(0.07), 0.03)
	# Frente: rodapé e janelas de papel acesas dos dois lados do vão.
	var pw := (W - 1.6) / 2.0 - 0.08
	for s in [-1.0, 1.0]:
		var cx: float = s * (0.8 + pw / 2.0 + 0.04)
		_blocod(Vector3(pw + 0.08, 0.55, 0.14), Vector3(cx, Y0 + 0.27, D / 2 - 0.07), Vector3.ZERO, e.parede.darkened(0.12), 0.03)
		_tipo = 0
		_caixa(Vector3(pw, HP - 0.75, 0.05), Vector3(cx, Y0 + 0.55 + (HP - 0.75) / 2, D / 2 - 0.06), Vector3.ZERO, e.luz.lerp(P.papel, 0.35), true)
		for k in range(1, 3):
			_caixa(Vector3(0.04, HP - 0.75, 0.07), Vector3(cx - pw / 2 + k * pw / 3, Y0 + 0.55 + (HP - 0.75) / 2, D / 2 - 0.03), Vector3.ZERO, e.pilar)
		_caixa(Vector3(pw, 0.04, 0.07), Vector3(cx, Y0 + 0.55 + (HP - 0.75) / 2, D / 2 - 0.03), Vector3.ZERO, e.pilar)
		_tipo = e.tipo
	# Fundo do vão aberto, escuro (o balcão e o molde aparecem contra ele).
	_tipo = 0
	_ao = 0.35
	_blocod(Vector3(1.55, HP - 0.1, 0.05), Vector3(0, Y0 + HP / 2, -D / 2 + 0.2), Vector3.ZERO, Color(0.12, 0.09, 0.09), 0.01)
	_blocod(Vector3(1.55, 0.05, D - 0.4), Vector3(0, Y0 + 0.02, 0), Vector3.ZERO, mad.darkened(0.3), 0.01)
	_ao = 1.0
	# Pilares e verga.
	for p in [Vector2(-W / 2, D / 2), Vector2(W / 2, D / 2), Vector2(-W / 2, -D / 2), Vector2(W / 2, -D / 2), Vector2(-0.8, D / 2), Vector2(0.8, D / 2)]:
		_viga(Vector3(p.x, Y0, p.y + 0.02), Vector3(p.x, yt + 0.12, p.y + 0.02), 0.2, e.pilar, 0.04)
	_blocod(Vector3(W + 0.35, 0.24, 0.26), Vector3(0, yt, D / 2 + 0.02), Vector3.ZERO, e.pilar.darkened(0.12), 0.04)
	_blocod(Vector3(W + 0.2, 0.16, 0.2), Vector3(0, yt, -D / 2), Vector3.ZERO, e.pilar.darkened(0.12), 0.04)
	# Balcão com o molde (o chapéu nasce aqui) e a prensa que desce da verga.
	_tipo = 1
	_blocod(Vector3(1.45, 0.12, 0.62), Vector3(0, YM - 0.06, ZM), Vector3.ZERO, P.madeira2, 0.03)
	_blocod(Vector3(1.4, YM - Y0 - 0.12, 0.1), Vector3(0, Y0 + (YM - Y0 - 0.12) / 2, ZM + 0.26), Vector3.ZERO, e.pilar.lerp(mad, 0.4), 0.02)
	_tipo = 0
	_cil(0.42, 0.46, 0.08, 12, Vector3(0, YM + 0.04, ZM), Vector3.ZERO, FERRO)
	_cil(0.47, 0.47, 0.04, 12, Vector3(0, YM + 0.08, ZM), Vector3.ZERO, e.acento.darkened(0.15))
	_pecas_marcador("Molde", Vector3(0, YM + 0.1, ZM))
	for x in [-0.3, 0.3]:
		_viga(Vector3(x, yt - 0.1, ZM - 0.12), Vector3(x, YM + 0.95, ZM - 0.12), 0.05, FERRO)
	var g := _inicio_peca()
	_prensa_classe(c, e)
	_viga(Vector3(0, 0.17, 0), Vector3(0, 0.5, 0), 0.04, P.corda)
	_fim_peca(g, "Prensa", Transform3D(Basis(), Vector3(0, YM + 0.85, ZM)))
	# Prateleira dos chapéus prontos, na beira da varanda.
	_tipo = 1
	_blocod(Vector3(W - 0.1, 0.08, 0.34), Vector3(0, 0.47, D / 2 + 0.6), Vector3.ZERO, P.madeira2.lightened(0.05), 0.03)
	for x in [-1.5, 0.0, 1.5]:
		_blocod(Vector3(0.1, 0.2, 0.28), Vector3(x, 0.36, D / 2 + 0.6), Vector3.ZERO, mad, 0.02)
	_tipo = 0
	for k in 5:
		_pecas_marcador("Estoque_%d" % (k + 1), Vector3(-1.3 + k * 0.65, 0.52, D / 2 + 0.62))
	# Placa redonda do emblema na verga, e uma lanterna em cada canto.
	_placa(Vector3(0, yt + 0.42, D / 2 + 0.16), Color(0.1, 0.08, 0.12), e.acento, 0.3)
	for s in [-1.0, 1.0]:
		var m := _marca()
		_cil(0.02, 0.02, 0.3, 4, Vector3(s * (W / 2 + 0.05), yt - 0.25, D / 2 + 0.3), Vector3.ZERO, Color(0.1, 0.1, 0.1))
		_esfera(0.17, Vector3(s * (W / 2 + 0.05), yt - 0.55, D / 2 + 0.3), Vector3(1, 1.3, 1), e.luz, true, 7, 4)
		_vento_pendurado(m, yt - 0.1, 0.65, 0.7)
	_adorno(c, e)
	_telhado_casa(c, e)
	_andar_n3(c, e)
	_topo_n4(c, e)


## Telhado principal (nó "Telhado"): quatro águas curvo, cumeeira escura com as
## pontas da classe.
func _telhado_casa(c: String, e: Dictionary) -> void:
	var g := _inicio_peca()
	var RW := W + 1.3
	var RD := D + 1.25
	var hT := 1.25
	var yb := Y0 + HP + 0.12
	var curva: float = e.curva
	var f_tel := func(px: float, pz: float) -> float:
		return _altura_telhado(px, pz, RW, RD, hT, 0.08, curva)
	_superficie(Vector3(0, yb, 0.08), f_tel, -RW / 2, RW / 2, -RD / 2, RD / 2, 12, 10, 0.14, e.telhado, e.pilar)
	var r := (RW - RD) / 2.0
	var yc: float = yb + f_tel.call(0.0, 0.0)
	_blocod(Vector3(2 * r + 0.7, 0.2, 0.32), Vector3(0, yc + 0.06, 0.08), Vector3.ZERO, e.telhado.darkened(0.4), 0.05)
	for s in [-1.0, 1.0]:
		_ponta_cumeeira(c, e, Vector3(s * (r + 0.32), yc + 0.15, 0.08), s)
	_fim_peca(g, "Telhado", Transform3D())


## Enfeite nas pontas da cumeeira: a assinatura da casa vista de longe.
func _ponta_cumeeira(c: String, e: Dictionary, p: Vector3, s: float) -> void:
	match c:
		"ronin_oni":  # chifres de oni
			_cil(0.0, 0.12, 0.6, 5, p + Vector3(s * 0.08, 0.28, 0), Vector3(0, 0, -s * 22), Color(0.92, 0.85, 0.7))
		"sohei", "kitsune_luz":  # peixe-dragão dourado (shachi) estilizado
			_esfera(0.14, p + Vector3(0, 0.12, 0), Vector3(0.8, 1.4, 0.7), P.ouro, false, 6, 3)
			_cil(0.0, 0.1, 0.28, 4, p + Vector3(-s * 0.1, 0.36, 0), Vector3(0, 0, s * 35), P.ouro.darkened(0.15))
		"kitsune_sombria":  # chama roxa torta
			_cil(0.0, 0.12, 0.5, 5, p + Vector3(s * 0.12, 0.22, 0), Vector3(0, 0, -s * 30), e.luz, true)
		"kusarigama":  # gancho de foice
			_viga(p, p + Vector3(s * 0.12, 0.35, 0), 0.06, FERRO)
			_cil(0.0, 0.05, 0.3, 4, p + Vector3(s * 0.02, 0.45, 0), Vector3(0, 0, s * 70), Color(0.78, 0.8, 0.86))
		"bombardeiro":  # foguete de festa
			_cil(0.07, 0.07, 0.4, 6, p + Vector3(0, 0.2, 0), Vector3.ZERO, e.acento)
			_cil(0.0, 0.08, 0.16, 6, p + Vector3(0, 0.48, 0), Vector3.ZERO, P.branco)
		_:
			_esfera(0.1, p + Vector3(0, 0.08, 0), Vector3.ONE, e.acento, false, 6, 3)


## Nível 4 (N4_Andar; era o nível 3 antes do Ciclo 2.22): um andar a mais em cima do telhado, com janelas acesas
## e telhado próprio. Desenhado em volta da base dele (cresce dali).
func _andar_n3(c: String, e: Dictionary) -> void:
	var base := Vector3(0, Y0 + HP + 1.05, 0.0)
	var g := _inicio_peca()
	var w2 := W * 0.52
	var d2 := D * 0.5
	var h2 := 0.85
	_tipo = e.tipo
	_blocod(Vector3(w2, h2, d2), Vector3(0, h2 / 2, 0), Vector3.ZERO, e.parede, 0.03)
	_tipo = 0
	for s in [-1.0, 1.0]:
		_viga(Vector3(s * w2 / 2, 0, d2 / 2 + 0.02), Vector3(s * w2 / 2, h2 + 0.08, d2 / 2 + 0.02), 0.13, e.pilar, 0.03)
	_caixa(Vector3(w2 * 0.6, h2 * 0.5, 0.04), Vector3(0, h2 * 0.5, d2 / 2 + 0.02), Vector3.ZERO, e.luz, true)
	for k in range(1, 3):
		_caixa(Vector3(0.035, h2 * 0.5, 0.06), Vector3(-w2 * 0.3 + k * w2 * 0.2, h2 * 0.5, d2 / 2 + 0.04), Vector3.ZERO, e.pilar)
	var RW := w2 + 1.0
	var RD := d2 + 0.9
	var curva: float = e.curva
	var f := func(px: float, pz: float) -> float:
		return _altura_telhado(px, pz, RW, RD, 0.75, 0.04, curva * 0.8)
	_superficie(Vector3(0, h2 + 0.05, 0), f, -RW / 2, RW / 2, -RD / 2, RD / 2, 8, 6, 0.12, e.telhado.lightened(0.04), e.pilar)
	var r := (RW - RD) / 2.0
	var yc: float = h2 + 0.05 + f.call(0.0, 0.0)
	_blocod(Vector3(2 * r + 0.5, 0.16, 0.26), Vector3(0, yc + 0.05, 0), Vector3.ZERO, e.telhado.darkened(0.4), 0.04)
	# Faixa na cor da classe embaixo do beiral: o nível 3 se lê de longe.
	_blocod(Vector3(w2 + 0.1, 0.12, d2 + 0.1), Vector3(0, h2 - 0.02, 0), Vector3.ZERO, e.acento.darkened(0.1), 0.02)
	_fim_peca(g, "N4_Andar", Transform3D(Basis(), base))


## Nível 5 (N5_Topo e N5_Estandartes; era o 4 antes do Ciclo 2.22): coroa da classe no alto e dois
## estandartes altos na cor dela nos cantos da frente.
func _topo_n4(c: String, e: Dictionary) -> void:
	var base := Vector3(0, Y0 + HP + 1.05 + 0.85 + 0.85, 0.0)
	var g := _inicio_peca()
	match c:
		"ronin_oni":  # máscara oni grande com chifres, olhos acesos
			_esfera(0.42, Vector3(0, 0.45, 0.1), Vector3(1.0, 1.05, 0.55), e.acento.darkened(0.15), false, 9, 5)
			for s in [-1.0, 1.0]:
				_cil(0.0, 0.14, 0.7, 6, Vector3(s * 0.3, 0.95, 0.05), Vector3(0, 0, -s * 25), Color(0.92, 0.85, 0.7))
				_caixa(Vector3(0.14, 0.06, 0.04), Vector3(s * 0.15, 0.55, 0.33), Vector3(0, 0, s * 15), e.luz, true)
			_caixa(Vector3(0.36, 0.08, 0.04), Vector3(0, 0.28, 0.32), Vector3.ZERO, Color(0.95, 0.92, 0.85))
		"sohei", "kitsune_luz":  # sorin: mastro dourado com anéis e a joia no alto
			_cil(0.05, 0.08, 1.5, 6, Vector3(0, 0.75, 0), Vector3.ZERO, P.ouro.darkened(0.1))
			for k in 5:
				_cil(0.2 - k * 0.025, 0.2 - k * 0.025, 0.05, 10, Vector3(0, 0.35 + k * 0.22, 0), Vector3.ZERO, P.ouro)
			_esfera(0.15, Vector3(0, 1.6, 0), Vector3(1, 1.3, 1), e.luz if c == "kitsune_luz" else e.acento, true, 8, 4)
		"kitsune_sombria":  # coroa de raios em ziguezague
			for k in 5:
				var a := (k - 2) * 0.42
				_cil(0.0, 0.1, 0.8 + 0.25 * (2 - absi(k - 2)), 4, Vector3(sin(a) * 0.35, 0.45, cos(a) * 0.08), Vector3(0, 0, -rad_to_deg(a) * 0.6), e.luz if k % 2 == 0 else e.pilar, k % 2 == 0)
			_esfera(0.12, Vector3(0, 0.25, 0.1), Vector3.ONE, e.luz, true, 7, 4)
		"kusarigama":  # foice e corrente cruzadas sobre um peso
			_viga(Vector3(-0.35, 0.1, 0), Vector3(0.3, 1.0, 0), 0.07, P.madeira2)
			_blocod(Vector3(0.5, 0.08, 0.04), Vector3(0.38, 1.02, 0), Vector3(0, 0, -25), Color(0.8, 0.82, 0.88), 0.01)
			for k in 5:
				_toro(0.04, 0.07, Vector3(0.3 - k * 0.14, 0.2 + k * 0.16, 0.05), Vector3.ONE, FERRO.lightened(0.2))
			_esfera(0.16, Vector3(-0.42, 0.15, 0.05), Vector3.ONE, FERRO, false, 7, 4)
		"arqueiro_yumi":  # arco grande de pé com a flecha apontada para o céu
			for k in 6:
				var a0 := lerpf(-1.15, 1.15, k / 6.0)
				var a1 := lerpf(-1.15, 1.15, (k + 1) / 6.0)
				_viga(Vector3(cos(a0) * 0.25 - 0.2, sin(a0) * 0.75 + 0.8, 0), Vector3(cos(a1) * 0.25 - 0.2, sin(a1) * 0.75 + 0.8, 0), 0.07, P.madeira2)
			_viga(Vector3(-0.05, 0.1, 0.02), Vector3(-0.05, 1.5, 0.02), 0.02, P.branco)
			_viga(Vector3(-0.05, 0.6, 0.04), Vector3(0.0, 1.75, 0.04), 0.035, P.madeira2.lightened(0.2))
			_cil(0.0, 0.07, 0.18, 4, Vector3(0.0, 1.82, 0.04), Vector3.ZERO, Color(0.8, 0.82, 0.88))
		"armadilheiro":  # estrepe gigante dourado
			for d in [Vector3(0, 1, 0), Vector3(-0.94, -0.33, 0.3), Vector3(0.94, -0.33, 0.3), Vector3(0, -0.33, -0.94)]:
				var b := Basis(Vector3.UP.cross(d).normalized() if absf(d.y) < 0.99 else Vector3.RIGHT, Vector3.UP.angle_to(d))
				_cil(0.0, 0.12, 0.55, 5, Vector3(0, 0.45, 0) + b * Vector3(0, 0.27, 0), b.get_euler() * 180.0 / PI, P.ouro)
		"bombardeiro":  # bombona com pavio aceso
			_esfera(0.42, Vector3(0, 0.42, 0), Vector3.ONE, Color(0.12, 0.1, 0.13), false, 9, 6)
			_cil(0.12, 0.14, 0.14, 8, Vector3(0.18, 0.84, 0), Vector3(0, 0, -30), FERRO.lightened(0.2))
			_viga(Vector3(0.24, 0.9, 0), Vector3(0.4, 1.15, 0), 0.04, P.corda)
			_esfera(0.11, Vector3(0.42, 1.2, 0.02), Vector3.ONE, e.luz, true, 6, 3)
	_fim_peca(g, "N5_Topo", Transform3D(Basis(), base))
	g = _inicio_peca()
	for s in [-1.0, 1.0]:
		var x: float = s * (W / 2 + 0.45)
		_viga(Vector3(x, 0, D / 2 + 0.7), Vector3(x, 4.6, D / 2 + 0.7), 0.09, e.pilar.darkened(0.2))
		_viga(Vector3(x, 4.45, D / 2 + 0.7), Vector3(x - s * 0.6, 4.45, D / 2 + 0.7), 0.06, e.pilar.darkened(0.2))
		var m := _marca()
		_blocod(Vector3(0.56, 2.1, 0.03), Vector3(x - s * 0.3, 3.35, D / 2 + 0.7), Vector3.ZERO, e.acento.darkened(0.15), 0.01)
		_blocod(Vector3(0.58, 0.14, 0.04), Vector3(x - s * 0.3, 4.32, D / 2 + 0.7), Vector3.ZERO, P.ouro, 0.01)
		_blocod(Vector3(0.14, 1.3, 0.04), Vector3(x - s * 0.3, 3.3, D / 2 + 0.71), Vector3.ZERO, P.branco.lerp(e.acento, 0.2), 0.01)
		_vento_pendurado(m, 4.4, 2.2, 0.8)
	_fim_peca(g, "N5_Estandartes", Transform3D())


## Prensa de cada casa (desenhada em volta da origem; desce até o molde).
func _prensa_classe(c: String, e: Dictionary) -> void:
	match c:
		"ronin_oni", "kusarigama", "bombardeiro":
			_blocod(Vector3(0.62, 0.38, 0.5), Vector3.ZERO, Vector3.ZERO, FERRO.lightened(0.05), 0.05)
			_blocod(Vector3(0.68, 0.08, 0.56), Vector3(0, 0.12, 0), Vector3.ZERO, e.acento.darkened(0.2), 0.02)
			_cil(0.24, 0.3, 0.1, 8, Vector3(0, -0.24, 0), Vector3.ZERO, FERRO)
		_:
			_cil(0.3, 0.3, 0.4, 12, Vector3.ZERO, Vector3.ZERO, Color(0.85, 0.75, 0.55))
			_cil(0.31, 0.31, 0.06, 12, Vector3(0, -0.21, 0), Vector3.ZERO, e.acento.darkened(0.1))
			_cil(0.12, 0.16, 0.2, 8, Vector3(0, 0.28, 0), Vector3.ZERO, Color(0.1, 0.08, 0.1))


## Enfeites de cada casa, no corpo (malha fixa), e a peça que gira.
func _adorno(c: String, e: Dictionary) -> void:
	var yt := Y0 + HP
	match c:
		"ronin_oni":
			# Correntes penduradas da verga, rachaduras em brasa no alicerce e a
			# clava cravejada encostada na parede; fumaça pela boca da máscara.
			for s in [-1.0, 1.0]:
				for k in 4:
					_toro(0.04, 0.07, Vector3(s * 1.05, yt - 0.15 - k * 0.14, D / 2 + 0.2), Vector3(1, 1, 0.5) if k % 2 == 0 else Vector3(0.5, 1, 1), FERRO.lightened(0.15))
			for k in 4:
				_caixa(Vector3(0.35, 0.04, 0.03), Vector3(-1.4 + k * 0.9, 0.12 + 0.05 * (k % 2), D / 2 + 0.11), Vector3(0, 0, (k - 1.5) * 18), e.luz, true)
			_viga(Vector3(W / 2 + 0.25, 0.0, 0.6), Vector3(W / 2 + 0.05, 1.7, 0.4), 0.16, Color(0.12, 0.08, 0.08))
			for k in 4:
				_esfera(0.05, Vector3(W / 2 + 0.2 - k * 0.04, 0.9 + k * 0.2, 0.62 - k * 0.05), Vector3.ONE, P.ouro, false, 4, 2)
			_esfera(0.3, Vector3(0, yt + 0.95, D / 2 + 0.22), Vector3(1.1, 1.0, 0.45), e.acento.darkened(0.1), false, 8, 4)
			for s in [-1.0, 1.0]:
				_cil(0.0, 0.08, 0.4, 5, Vector3(s * 0.22, yt + 1.28, D / 2 + 0.2), Vector3(0, 0, -s * 20), Color(0.92, 0.85, 0.7))
			_pecas_marcador("Vapor", Vector3(0, yt + 0.85, D / 2 + 0.45))
		"sohei":
			# Sino do templo num pórtico à direita, suporte de naginatas à
			# esquerda, bandeirinhas de oração e o incensário (fumaça).
			var bx := W / 2 + 0.75
			for z in [-0.45, 0.45]:
				_viga(Vector3(bx, 0, z), Vector3(bx, 2.5, z), 0.14, e.pilar)
			_blocod(Vector3(0.3, 0.18, 1.3), Vector3(bx, 2.5, 0), Vector3.ZERO, e.telhado.darkened(0.2), 0.04)
			_cil(0.28, 0.34, 0.75, 10, Vector3(bx, 1.85, 0), Vector3.ZERO, Color(0.38, 0.5, 0.45).lerp(P.ouro, 0.25))
			_cil(0.08, 0.08, 0.12, 6, Vector3(bx, 2.28, 0), Vector3.ZERO, FERRO)
			for k in 3:
				_toro(0.3, 0.35, Vector3(bx, 1.62 + k * 0.2, 0), Vector3(1, 0.4, 1), P.ouro.darkened(0.25))
			var rx := -W / 2 - 0.45
			_blocod(Vector3(0.12, 1.1, 0.6), Vector3(rx, 0.55, 0.4), Vector3.ZERO, e.pilar.darkened(0.3), 0.02)
			for k in 2:
				_viga(Vector3(rx - 0.05, 0.1, 0.2 + k * 0.35), Vector3(rx - 0.05, 2.4, 0.2 + k * 0.35), 0.05, P.madeira2)
				_blocod(Vector3(0.05, 0.42, 0.1), Vector3(rx - 0.05, 2.6, 0.24 + k * 0.35), Vector3(-12, 0, 0), Color(0.8, 0.82, 0.88), 0.01)
			var m := _marca()
			_viga(Vector3(-W / 2 - 0.1, yt + 0.1, D / 2 + 0.35), Vector3(W / 2 + 0.1, yt + 0.1, D / 2 + 0.35), 0.02, P.corda, 0.0)
			for k in 9:
				var cores := [e.acento, P.branco, P.torii, P.ouro, Color(0.3, 0.5, 0.9)]
				_blocod(Vector3(0.2, 0.26, 0.015), Vector3(-1.6 + k * 0.4, yt - 0.06, D / 2 + 0.36), Vector3(0, 0, (k % 3 - 1) * 5), cores[k % 5], 0.0)
			_vento_pendurado(m, yt + 0.1, 0.35, 1.2)
			_cil(0.2, 0.15, 0.3, 8, Vector3(-1.2, Y0 + 0.2, D / 2 + 0.45), Vector3.ZERO, FERRO.lightened(0.15))
			_cil(0.22, 0.22, 0.04, 8, Vector3(-1.2, Y0 + 0.36, D / 2 + 0.45), Vector3.ZERO, P.ouro.darkened(0.3))
			_pecas_marcador("Vapor", Vector3(-1.2, Y0 + 0.45, D / 2 + 0.45))
		"arqueiro_yumi":
			# Alvo de palha (mato) num cavalete à direita, girando de leve; arcos
			# longos encostados à esquerda; aljava com flechas.
			var tx := W / 2 + 0.75
			_viga(Vector3(tx - 0.3, 0, 0.1), Vector3(tx, 1.4, 0.1), 0.08, P.madeira)
			_viga(Vector3(tx + 0.3, 0, 0.1), Vector3(tx, 1.4, 0.1), 0.08, P.madeira)
			_gira("Gira_alvo", Vector3(tx, 1.45, 0.25), 0.8, func() -> void:
				_cil(0.55, 0.55, 0.14, 16, Vector3.ZERO, Vector3(90, 0, 0), P.corda.darkened(0.1))
				_cil(0.42, 0.42, 0.15, 16, Vector3(0, 0, 0.005), Vector3(90, 0, 0), P.branco)
				_cil(0.3, 0.3, 0.16, 16, Vector3(0, 0, 0.01), Vector3(90, 0, 0), Color(0.08, 0.07, 0.08))
				_cil(0.18, 0.18, 0.17, 16, Vector3(0, 0, 0.015), Vector3(90, 0, 0), P.branco)
				_cil(0.08, 0.08, 0.18, 12, Vector3(0, 0, 0.02), Vector3(90, 0, 0), P.torii)
				_viga(Vector3(0.1, 0.05, 0.08), Vector3(0.45, 0.25, 0.5), 0.025, P.madeira2.lightened(0.2)))
			for k in 3:
				var bx := -W / 2 - 0.3 - k * 0.12
				for j in 6:
					var a0 := lerpf(-1.2, 1.2, j / 6.0)
					var a1 := lerpf(-1.2, 1.2, (j + 1) / 6.0)
					_viga(Vector3(bx - cos(a0) * 0.12, 1.1 + sin(a0) * 1.0, 0.2 + k * 0.25), Vector3(bx - cos(a1) * 0.12, 1.1 + sin(a1) * 1.0, 0.2 + k * 0.25), 0.04, P.madeira2.darkened(0.1 * k))
			_cil(0.13, 0.11, 0.7, 8, Vector3(1.3, Y0 + 0.4, D / 2 + 0.95), Vector3(0, 0, 8), P.madeira)
			for k in 4:
				_viga(Vector3(1.28 + k * 0.03, Y0 + 0.7, D / 2 + 0.95), Vector3(1.3 + k * 0.06, Y0 + 1.15, D / 2 + 0.92 + k * 0.02), 0.02, P.branco)
			_pecas_marcador("Vapor", Vector3(-1.2, yt + 0.3, D / 2 + 0.3))
		"kusarigama":
			# Noren azul-escuro no vão, corrente com peso girando ao lado direito,
			# foices penduradas e a forja pequena à esquerda (fumaça).
			var m := _marca()
			for j in 3:
				_blocod(Vector3(0.5, 0.55, 0.025), Vector3(-0.52 + j * 0.52, yt - 0.38, D / 2 + 0.16), Vector3(0, 0, (j - 1) * 2.5), e.parede.lightened(0.15 - 0.05 * j), 0.01)
			_cil(0.12, 0.12, 0.02, 10, Vector3(0, yt - 0.38, D / 2 + 0.18), Vector3(90, 0, 0), e.acento)
			_vento_pendurado(m, yt - 0.1, 0.55, 1.3)
			var cx := W / 2 + 0.4
			_viga(Vector3(cx, 0, 0.6), Vector3(cx, 2.3, 0.6), 0.12, e.pilar)
			_gira("Gira_corrente", Vector3(cx, 2.1, 0.75), 3.2, func() -> void:
				for k in 6:
					_toro(0.035, 0.06, Vector3(0.12 + k * 0.1, 0, 0), Vector3(1, 1, 0.5) if k % 2 == 0 else Vector3(1, 0.5, 1), FERRO.lightened(0.25))
				_esfera(0.13, Vector3(0.75, 0, 0), Vector3.ONE, FERRO, false, 7, 4))
			for s in [-1.0, 1.0]:
				_viga(Vector3(s * 1.35, yt - 0.1, -D / 2 + 0.35), Vector3(s * 1.35, yt - 0.6, -D / 2 + 0.35), 0.04, P.madeira2)
				_blocod(Vector3(0.36, 0.06, 0.03), Vector3(s * 1.45, yt - 0.62, -D / 2 + 0.37), Vector3(0, 0, -s * 20), Color(0.8, 0.82, 0.88), 0.01)
			_tipo = 3
			_blocod(Vector3(0.6, 0.7, 0.6), Vector3(-W / 2 - 0.45, 0.35, 0.5), Vector3.ZERO, P.pedra2.darkened(0.2), 0.06)
			_tipo = 0
			_caixa(Vector3(0.3, 0.2, 0.04), Vector3(-W / 2 - 0.45, 0.35, 0.82), Vector3.ZERO, Color(1.0, 0.5, 0.2), true)
			_cil(0.14, 0.18, 1.0, 7, Vector3(-W / 2 - 0.5, 1.2, 0.4), Vector3.ZERO, P.pedra2)
			_pecas_marcador("Vapor", Vector3(-W / 2 - 0.5, 1.8, 0.4))
		"kitsune_luz", "kitsune_sombria":
			# Torii na frente da varanda, raposas de pedra, anel de fogo-raposa
			# girando sob o beiral e o incensário.
			var luz := c == "kitsune_luz"
			var tor: Color = P.branco.darkened(0.05) if luz else e.pilar
			var tz := D / 2 + 1.1
			for s in [-1.0, 1.0]:
				var torto: float = 0.0 if luz else s * 4.0
				_cil(0.08, 0.1, 2.6, 8, Vector3(s * 1.05, 1.3, tz), Vector3(0, 0, torto), tor)
			_blocod(Vector3(2.7, 0.14, 0.22), Vector3(0, 2.7, tz), Vector3(0, 0, 0.0 if luz else -3.0), P.ouro if luz else Color(0.08, 0.06, 0.1), 0.04)
			_blocod(Vector3(2.3, 0.1, 0.18), Vector3(0, 2.45, tz), Vector3.ZERO, tor, 0.03)
			var pedra: Color = Color(0.97, 0.95, 0.9) if luz else Color(0.16, 0.13, 0.2)
			for s in [-1.0, 1.0]:
				var b := Vector3(s * 1.55, Y0, D / 2 + 0.6)
				_esfera(0.2, b + Vector3(0, 0.25, 0), Vector3(0.9, 1.3, 0.8), pedra, false, 7, 4)
				_esfera(0.13, b + Vector3(0, 0.62, 0.05), Vector3(1, 0.9, 1.1), pedra, false, 7, 4)
				for o in [-1.0, 1.0]:
					_cil(0.0, 0.05, 0.14, 4, b + Vector3(o * 0.07, 0.76, 0.03), Vector3.ZERO, pedra)
				_caixa(Vector3(0.22, 0.08, 0.02), b + Vector3(0, 0.45, 0.17), Vector3.ZERO, e.acento if luz else e.luz)
				if not luz:
					for o in [-1.0, 1.0]:
						_esfera(0.025, b + Vector3(o * 0.05, 0.65, 0.16), Vector3.ONE, e.luz, true, 4, 2)
			var fogo: Color = e.luz
			_gira("Gira_fogo_raposa", Vector3(0, yt + 0.45, D / 2 + 0.3), 1.4 if luz else -2.2, func() -> void:
				for k in 6:
					var a := TAU * k / 6.0
					_esfera(0.09, Vector3(cos(a), sin(a), 0) * 0.55, Vector3(1, 1.3, 1), fogo, true, 6, 3))
			_cil(0.18, 0.14, 0.28, 8, Vector3(1.2, Y0 + 0.2, D / 2 + 0.45), Vector3.ZERO, P.ouro.darkened(0.2) if luz else FERRO)
			_pecas_marcador("Vapor", Vector3(1.2, Y0 + 0.42, D / 2 + 0.45))
		"armadilheiro":
			# Cerca de bambu pontudo dos lados, rede pendurada na parede, gaiola
			# de mola com engrenagem girando e estrepes no degrau.
			for s in [-1.0, 1.0]:
				for k in 5:
					var z := -1.0 + k * 0.45
					var h := 0.9 + 0.2 * ((k + int(s)) % 2)
					_cil(0.05, 0.06, h, 5, Vector3(s * (W / 2 + 0.35), h / 2, z), Vector3(s * 4.0, 0, 0), P.bambu)
					_cil(0.0, 0.06, 0.2, 5, Vector3(s * (W / 2 + 0.35), h + 0.1, z), Vector3(s * 4.0, 0, 0), P.bambu.lightened(0.2))
				_viga(Vector3(s * (W / 2 + 0.35), 0.5, -1.1), Vector3(s * (W / 2 + 0.35), 0.5, 0.9), 0.04, P.corda.darkened(0.2))
			var m := _marca()
			for k in 5:
				_viga(Vector3(-1.5 + k * 0.15, yt - 0.15, D / 2 + 0.12), Vector3(-1.2 + k * 0.1, yt - 1.0, D / 2 + 0.12), 0.015, P.corda)
				_viga(Vector3(-1.55, yt - 0.25 - k * 0.17, D / 2 + 0.13), Vector3(-0.95, yt - 0.25 - k * 0.17, D / 2 + 0.13), 0.015, P.corda)
			_vento_pendurado(m, yt - 0.1, 1.0, 0.4)
			var gx := W / 2 + 0.95
			_tipo = 1
			_blocod(Vector3(0.8, 0.6, 0.7), Vector3(gx, 0.3, 0.7), Vector3.ZERO, P.madeira, 0.03)
			_tipo = 0
			for k in 4:
				_viga(Vector3(gx - 0.3 + k * 0.2, 0.6, 1.05), Vector3(gx - 0.3 + k * 0.2, 1.1, 1.05), 0.03, P.bambu.darkened(0.2))
			_blocod(Vector3(0.8, 0.06, 0.7), Vector3(gx, 1.12, 0.7), Vector3.ZERO, P.madeira2, 0.02)
			_gira("Gira_mola", Vector3(gx, 0.75, 1.1), 1.8, func() -> void:
				_engrenagem(8, 0.16, 0.08, FERRO.lightened(0.25), 0.0))
			for k in 3:
				_cil(0.0, 0.05, 0.14, 4, Vector3(-0.9 + k * 0.9, 0.62, D / 2 + 0.95), Vector3(0, 0, 0), Color(0.78, 0.8, 0.86))
			_pecas_marcador("Vapor", Vector3(gx, 1.2, 0.7))
		"bombardeiro":
			# Barris de pólvora com cinta vermelha, rack de foguetes, chaminé de
			# pedra (fumaça), bandeira de perigo e o catavento de fogos girando.
			for k in 3:
				var p := Vector3(-W / 2 - 0.45, 0.35 + (0.62 if k == 2 else 0.0), 0.2 + (0.0 if k == 0 else 0.6) - (0.3 if k == 2 else 0.0))
				_cil(0.3, 0.3, 0.62, 10, p, Vector3.ZERO, P.madeira.darkened(0.1))
				_cil(0.31, 0.31, 0.08, 10, p + Vector3(0, 0.15, 0), Vector3.ZERO, e.acento)
				_cil(0.31, 0.31, 0.06, 10, p - Vector3(0, 0.2, 0), Vector3.ZERO, FERRO)
			var rx := W / 2 + 0.55
			_blocod(Vector3(0.6, 0.1, 0.5), Vector3(rx, 0.9, 0.7), Vector3.ZERO, P.madeira, 0.02)
			for k in 4:
				_cil(0.06, 0.06, 0.8, 6, Vector3(rx - 0.22 + k * 0.15, 1.3, 0.7), Vector3(0, 0, (k - 1.5) * 6), [e.acento, P.ouro, P.branco, e.acento.lightened(0.3)][k])
				_cil(0.0, 0.07, 0.16, 6, Vector3(rx - 0.22 + k * 0.15 - (k - 1.5) * 0.04, 1.78, 0.7), Vector3(0, 0, (k - 1.5) * 6), P.branco)
			for x in [rx - 0.25, rx + 0.25]:
				_viga(Vector3(x, 0, 0.7), Vector3(x, 0.9, 0.7), 0.06, P.madeira)
			_tipo = 3
			_blocod(Vector3(0.6, 1.2, 0.6), Vector3(1.0, Y0 + HP + 0.9, -0.6), Vector3.ZERO, P.pedra2, 0.06)
			_tipo = 0
			_pecas_marcador("Vapor", Vector3(1.0, Y0 + HP + 1.6, -0.6))
			var m := _marca()
			_viga(Vector3(-W / 2 - 0.15, 0, D / 2 + 0.9), Vector3(-W / 2 - 0.15, 2.6, D / 2 + 0.9), 0.05, P.madeira2)
			_blocod(Vector3(0.6, 0.4, 0.02), Vector3(-W / 2 + 0.17, 2.35, D / 2 + 0.9), Vector3.ZERO, e.acento, 0.0)
			_vento_pendurado(m, 2.55, 0.7, 1.4)
			_gira("Gira_catavento", Vector3(rx, 2.15, 0.75), 2.6, func() -> void:
				for j in 4:
					var a := TAU * j / 4.0
					var dir := Vector3(cos(a), sin(a), 0)
					var lado := Vector3(-sin(a), cos(a), 0)
					_tri(Vector3.ZERO, dir * 0.4, dir * 0.4 + lado * 0.2 + Vector3(0, 0, 0.06), e.acento if j % 2 == 0 else P.ouro, Vector3(0, 0, 1))
					_tri(Vector3.ZERO, dir * 0.4 + lado * 0.2 + Vector3(0, 0, 0.06), dir * 0.4, e.acento.darkened(0.3) if j % 2 == 0 else P.ouro.darkened(0.3), Vector3(0, 0, -1))
				_cil(0.05, 0.05, 0.08, 6, Vector3(0, 0, 0.04), Vector3(90, 0, 0), FERRO))
			_viga(Vector3(rx, 1.4, 0.7), Vector3(rx, 2.15, 0.7), 0.05, P.madeira)


# --- Bairro ---------------------------------------------------------------------------

## Chão do bairro: areia rastelada tingida da cor da classe, anel de pedras na
## borda, passos de pedra até os tapetes. Tapetes de tatame com a beirada na
## cor de cada caminho e a plaquinha do emblema atrás; selo (corda e papéis)
## escondido por tapete; estandarte alto com um pano por dono.
func _bairro(base: String) -> void:
	_rng.seed = 900 + base.length()
	var cb: Color = COR[base]
	var areia: Color = P.corda.lerp(P.pedra, 0.35).lerp(cb, 0.14)
	_tipo = 0
	_ao = 0.95
	_cil(RAIO - 0.25, RAIO - 0.15, 0.04, 28, Vector3(0, 0.02, 0), Vector3.ZERO, areia)
	# Miolo mais claro em volta da casa (areia rastelada).
	_cil(2.9, 3.0, 0.04, 20, Vector3(0, 0.035, -1.2), Vector3.ZERO, areia.lightened(0.1))
	_ao = 1.0
	# Pedras da borda.
	_tipo = 3
	var n := 22
	for k in n:
		var a := TAU * (k + _rng.randf() * 0.3) / n
		var p := Vector3(cos(a), 0, sin(a)) * (RAIO - 0.15)
		_caixa(Vector3(_rng.randf_range(1.0, 1.35), _rng.randf_range(0.1, 0.16), 0.42), p + Vector3(0, 0.05, 0), Vector3(0, -rad_to_deg(a) + 90, 0), P.pedra.lerp(P.pedra2, _rng.randf()))
	# Passos de pedra da barraquinha até cada tapete.
	for s in [-1.0, 1.0]:
		for k in 3:
			var t := (k + 1) / 4.0
			var p := Vector3(0, 0, 3.0).lerp(TAPETES[0 if s < 0 else 1], t)
			_esfera(0.3, p + Vector3(0, 0.02, 0), Vector3(1.2, 0.12, 0.9), P.pedra2.lightened(0.1), false, 7, 2)
	_tipo = 0
	# Tapetes (tatame) com a beirada na cor do caminho e o emblema atrás.
	var cams: Array = BASES[base]
	for i in 2:
		var cc: Color = COR[cams[i]]
		var tp: Vector3 = TAPETES[i]
		_tipo = 1
		_blocod(Vector3(2.1, 0.07, 1.6), tp + Vector3(0, 0.05, 0), Vector3.ZERO, Color(0.78, 0.74, 0.48).lerp(P.corda, 0.3), 0.02)
		_tipo = 0
		for q in [[Vector3(2.2, 0.08, 0.14), Vector3(0, 0.07, 0.8)], [Vector3(2.2, 0.08, 0.14), Vector3(0, 0.07, -0.8)],
				[Vector3(0.14, 0.08, 1.6), Vector3(1.05, 0.07, 0)], [Vector3(0.14, 0.08, 1.6), Vector3(-1.05, 0.07, 0)]]:
			_blocod(q[0], tp + q[1], Vector3.ZERO, cc.darkened(0.2), 0.01)
		# Poste com a placa do emblema do caminho, atrás do tapete.
		_viga(tp + Vector3(0, 0, -1.05), tp + Vector3(0, 1.5, -1.05), 0.09, P.madeira)
		_cil(0.3, 0.3, 0.06, 12, tp + Vector3(0, 1.55, -1.0), Vector3(78, 0, 0), Color(0.1, 0.08, 0.12))
		_cil(0.34, 0.34, 0.04, 12, tp + Vector3(0, 1.55, -1.03), Vector3(78, 0, 0), cc)
		_pecas_marcador("Emblema_%d" % i, tp + Vector3(0, 1.56, -0.95))
		# Selo: corda grossa sobre estacas em volta do tapete, com papéis.
		var g := _inicio_peca()
		for cx in [-1.15, 1.15]:
			for cz in [-0.88, 0.88]:
				_viga(Vector3(cx, 0, cz), Vector3(cx, 0.6, cz), 0.07, P.madeira)
		var cantos := [Vector3(-1.15, 0.55, -0.88), Vector3(1.15, 0.55, -0.88), Vector3(1.15, 0.55, 0.88), Vector3(-1.15, 0.55, 0.88)]
		for k in 4:
			_viga(cantos[k], cantos[(k + 1) % 4], 0.08, P.corda.darkened(0.05))
		for k in 6:
			var lado: Vector3 = cantos[k % 4].lerp(cantos[(k + 1) % 4], 0.5 if k < 4 else 0.25)
			_blocod(Vector3(0.14, 0.32, 0.015), lado + Vector3(0, -0.2, 0), Vector3(0, 90 if k % 2 else 0, (k % 3 - 1) * 8), P.branco, 0.0)
		_blocod(Vector3(0.32, 0.5, 0.02), Vector3(0, 0.45, 0.9), Vector3(-25, 0, 0), P.papel, 0.0)
		_blocod(Vector3(0.06, 0.34, 0.025), Vector3(0, 0.45, 0.91), Vector3(-25, 0, 0), P.torii.darkened(0.2), 0.0)
		_fim_peca(g, "Selo_%d" % i, Transform3D(Basis(), tp))
	# Estandarte (nobori): mastro, trave e um pano por dono.
	var bp := BANDEIRA
	_viga(bp, bp + Vector3(0, 5.8, 0), 0.1, P.madeira.darkened(0.2))
	_viga(bp + Vector3(0, 5.55, 0), bp + Vector3(-0.95, 5.55, 0), 0.06, P.madeira.darkened(0.2))
	_esfera(0.1, bp + Vector3(0, 5.85, 0), Vector3.ONE, P.ouro, false, 6, 3)
	_tipo = 3
	_blocod(Vector3(0.6, 0.3, 0.6), bp + Vector3(0, 0.15, 0), Vector3.ZERO, P.pedra2, 0.05)
	_tipo = 0
	var donos := {"azul": TIMES["azul"], "vermelho": TIMES["vermelho"], "c0": COR[cams[0]], "c1": COR[cams[1]]}
	for k in donos:
		var cor: Color = donos[k]
		var g := _inicio_peca()
		var m := _marca()
		_blocod(Vector3(0.85, 2.9, 0.03), Vector3(-0.47, -1.5, 0), Vector3.ZERO, cor.darkened(0.15), 0.01)
		_blocod(Vector3(0.87, 0.16, 0.04), Vector3(-0.47, -0.12, 0.0), Vector3.ZERO, P.ouro.darkened(0.1), 0.01)
		_blocod(Vector3(0.87, 0.16, 0.04), Vector3(-0.47, -2.88, 0.0), Vector3.ZERO, cor.darkened(0.45), 0.01)
		_cil(0.33, 0.33, 0.02, 14, Vector3(-0.47, -1.35, 0.025), Vector3(90, 0, 0), P.branco.lerp(cor, 0.12))
		_vento_pendurado(m, 0.0, 3.0, 0.7)
		_fim_peca(g, "Pano_" + k, Transform3D(Basis(), bp + Vector3(0, 5.5, 0.06)))
	_pecas_marcador("Emblema_bandeira", bp + Vector3(-0.47, 4.15, 0.12))


## Emblemas novos (o resto vem do gerar_economia).
func _emblema(classe: String) -> void:
	var aco := Color(0.78, 0.8, 0.86)
	match classe:
		"sohei":  # naginata em pé atrás de um rosário (juzu)
			_viga(Vector3(0, -0.3, 0), Vector3(0, 0.22, 0), 0.04, P.madeira2)
			_blocod(Vector3(0.07, 0.2, 0.03), Vector3(0.025, 0.3, 0), Vector3(0, 0, -12), aco, 0.01)
			_cil(0.05, 0.05, 0.04, 8, Vector3(0, 0.2, 0.01), Vector3(90, 0, 0), P.ouro)
			for k in 12:
				var a := TAU * k / 12.0
				_esfera(0.035, Vector3(cos(a) * 0.2, sin(a) * 0.2 - 0.05, 0.03), Vector3.ONE, COR["sohei"].darkened(0.1) if k % 4 else P.ouro, false, 5, 3)
		"kusarigama":  # foice na ponta da corrente, com o peso
			_viga(Vector3(-0.05, -0.25, 0), Vector3(-0.05, 0.12, 0), 0.05, P.madeira2)
			_blocod(Vector3(0.3, 0.06, 0.03), Vector3(0.08, 0.15, 0), Vector3(0, 0, -18), aco, 0.01)
			for k in 4:
				_toro(0.025, 0.045, Vector3(0.0 + k * 0.07, -0.27 - (k % 2) * 0.01, 0.02), Vector3(1, 1, 0.5) if k % 2 == 0 else Vector3(1, 0.5, 1), aco.darkened(0.25))
			_esfera(0.07, Vector3(0.3, -0.27, 0.02), Vector3.ONE, FERRO.lightened(0.2), false, 6, 4)
		_:
			super(classe)
