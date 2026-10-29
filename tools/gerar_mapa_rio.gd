extends "res://tools/gerar_cenario_ninja.gd"
## Gera o mapa "Rio das Lanternas" (rio com 3 pontes + vila neon dos dois
## lados + colinas + castelos com muralha de passarela) e os modelos dele, nos
## dois temas. Rode depois de tools/gerar_cenario_ninja.gd:
##   godot --headless --path . -s tools/gerar_mapa_rio.gd
## Tudo aqui é dado: posições em metros (x liga os castelos, z é a profundidade).

const ALT_MURO := 3.2       # altura da passarela da muralha
const ESP_MURO := 3.6       # espessura da muralha
const ALT_COLINA := 2.4
const ALT_PONTE := 1.4
const RIO_MEIA := 4.5       # meia-largura do rio

var _props: Array = []      # MapProp do meio do mapa
var _patio: Array = []      # MapProp do pátio (coordenadas locais do castelo)
var _MP: Script


func _gerar_tudo() -> bool:
	return false


func _init() -> void:
	for tema in TEMAS:
		P = TEMAS[tema]
		_dir = "res://assets/ninja/" + tema
		_gerar_modelos_rio()
	_gerar_mapa_rio()
	print("triângulos (último tema): ", _tris)
	quit()


func _gerar_modelos_rio() -> void:
	_muralha(); _salvar("muralha")
	for t in TIMES:
		_torre_alta(TIMES[t]); _salvar("torre_alta_" + t)
	_portao(); _salvar("portao")
	_escada(7.0, ALT_MURO, 3.0, 2.0); _salvar("escada_muralha")
	_escada(5.5, ALT_COLINA, 3.2, 0.0); _salvar("escada_colina")
	_colina(); _salvar("colina")
	_rio(0); _salvar("rio_a")
	_rio(1); _salvar("rio_b")
	_ponte(8.0); _salvar("ponte_grande")
	_ponte(4.6); _salvar("ponte_lateral")
	_cachoeira(); _salvar("cachoeira")
	_casa_a(); _salvar("casa_a")
	_casa_b(); _salvar("casa_b")
	_loja(); _salvar("loja")
	_pousada(); _salvar("pousada")
	_armazem(); _salvar("armazem")
	_festival(); _salvar("festival")
	_poco(); _salvar("poco")
	_carroca(); _salvar("carroca")
	_poste(); _salvar("poste")
	_sino(); _salvar("sino")
	_vigia(); _salvar("vigia")
	_jardim(); _salvar("jardim")
	_barricada(); _salvar("barricada")
	_arvore_espirito(); _salvar("arvore_espirito")
	_jizos(); _salvar("jizos")
	_bambuzal(); _salvar("bambuzal")
	_pilha(); _salvar("pilha")
	_aldeoes(); _salvar("aldeoes")
	_templo(); _salvar("templo")
	_casa_de_cha(); _salvar("casa_de_cha")
	_barco(); _salvar("barco")
	_ponte_corda(); _salvar("ponte_corda")
	_forja(); _salvar("forja")
	_dojo(); _salvar("dojo")


# --- Ferramentas de forma ------------------------------------------------------

## Triângulo com normal para fora (`fora` = direção aproximada da face).
func _tri(a: Vector3, b: Vector3, c: Vector3, cor: Color, fora: Vector3, brilho := false) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.dot(fora) < 0.0:
		n = -n
	else:
		var t := b
		b = c
		c = t
	# Godot desenha a frente no sentido horário visto de fora.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t2 := b
		b = c
		c = t2
	var s := 1 if brilho else 0
	var base: int = V[s].size()
	for v in [a, b, c]:
		V[s].append(v)
		N[s].append(n)
		C[s].append(cor)
	I[s].append(base)
	I[s].append(base + 1)
	I[s].append(base + 2)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, cor: Color, fora: Vector3, brilho := false) -> void:
	_tri(a, b, c, cor, fora, brilho)
	_tri(a, c, d, cor, fora, brilho)


## Telhado japonês de quatro águas com beiral levantado. `base` = centro na
## altura do beiral; w no eixo x (>= d), h = altura da cumeeira.
func _telhado(base: Vector3, w: float, d: float, h: float, cor: Color, beiral := 0.6) -> void:
	var r := maxf(w - d, 0.2) / 2.0
	var c0 := [Vector3(-w / 2, 0, -d / 2), Vector3(w / 2, 0, -d / 2), Vector3(w / 2, 0, d / 2), Vector3(-w / 2, 0, d / 2)]
	var topo := [Vector3(-r, h, 0), Vector3(r, h, 0)]
	var o := base
	_quad(o + c0[3], o + c0[2], o + topo[1], o + topo[0], cor, Vector3(0, 1, 1))
	_quad(o + c0[0], o + c0[1], o + topo[1], o + topo[0], cor, Vector3(0, 1, -1))
	_tri(o + c0[1], o + c0[2], o + topo[1], cor.darkened(0.08), Vector3(1, 1, 0))
	_tri(o + c0[0], o + c0[3], o + topo[0], cor.darkened(0.08), Vector3(-1, 1, 0))
	# Beiral: aba que se abre para fora e sobe um pouco nas pontas.
	var e := beiral
	var c1 := [Vector3(-w / 2 - e, 0.12, -d / 2 - e), Vector3(w / 2 + e, 0.12, -d / 2 - e), Vector3(w / 2 + e, 0.12, d / 2 + e), Vector3(-w / 2 - e, 0.12, d / 2 + e)]
	for k in 4:
		var k2 := (k + 1) % 4
		var mid: Vector3 = (c0[k] + c0[k2]) / 2.0
		_quad(o + c0[k], o + c0[k2], o + c1[k2], o + c1[k], cor.lightened(0.06), Vector3(mid.x, 2.0, mid.z))
		_quad(o + c0[k] - Vector3(0, 0.08, 0), o + c0[k2] - Vector3(0, 0.08, 0), o + c1[k2] - Vector3(0, 0.02, 0), o + c1[k] - Vector3(0, 0.02, 0), Color(0.08, 0.07, 0.09), Vector3(0, -1, 0))
	# Cumeeira e telhas (linhas mais escuras).
	_caixa(Vector3(2 * r + 0.3, 0.18, 0.3), o + Vector3(0, h + 0.05, 0), Vector3.ZERO, cor.darkened(0.3))
	for k in range(1, int(w / 0.7)):
		var x := -w / 2 + k * 0.7
		var hz := h * (1.0 - clampf((absf(x) - r) / (w / 2 - r + 0.001), 0.0, 1.0)) if absf(x) > r else h
		_tri(o + Vector3(x - 0.04, 0.01, d / 2 + 0.01), o + Vector3(x + 0.04, 0.01, d / 2 + 0.01), o + Vector3(x, hz + 0.01, 0.02), cor.darkened(0.2), Vector3(0, 1, 1))
		_tri(o + Vector3(x - 0.04, 0.01, -d / 2 - 0.01), o + Vector3(x + 0.04, 0.01, -d / 2 - 0.01), o + Vector3(x, hz + 0.01, -0.02), cor.darkened(0.2), Vector3(0, 1, -1))


## Painel de papel aceso com grade de madeira (shoji / janela).
func _shoji(centro: Vector3, w: float, h: float, normal_z: float, cor_luz: Color) -> void:
	var z := normal_z * 0.03
	_caixa(Vector3(w, h, 0.04), centro, Vector3.ZERO, cor_luz, true)
	var nx := maxi(int(w / 0.45), 1)
	for k in range(1, nx):
		_caixa(Vector3(0.05, h, 0.06), centro + Vector3(-w / 2 + k * w / nx, 0, z), Vector3.ZERO, Color(0.12, 0.08, 0.07))
	for k in range(1, 3):
		_caixa(Vector3(w, 0.05, 0.06), centro + Vector3(0, -h / 2 + k * h / 3, z), Vector3.ZERO, Color(0.12, 0.08, 0.07))
	_caixa(Vector3(w + 0.12, 0.1, 0.08), centro + Vector3(0, h / 2, z), Vector3.ZERO, P.madeira)
	_caixa(Vector3(w + 0.12, 0.1, 0.08), centro + Vector3(0, -h / 2, z), Vector3.ZERO, P.madeira)


func _lanterna_papel(pos: Vector3, cor: Color, r := 0.22) -> void:
	_cil(0.02, 0.02, 0.3, 4, pos + Vector3(0, r * 1.3 + 0.15, 0), Vector3.ZERO, Color(0.1, 0.1, 0.1))
	_esfera(r, pos, Vector3(1, 1.35, 1), cor, true, 8, 5)
	_cil(r * 0.6, r * 0.6, 0.06, 8, pos + Vector3(0, r * 1.3, 0), Vector3.ZERO, Color(0.12, 0.1, 0.1))
	_cil(r * 0.6, r * 0.6, 0.06, 8, pos - Vector3(0, r * 1.3, 0), Vector3.ZERO, Color(0.12, 0.1, 0.1))


## Placa vertical de neon com "letras" (barras) — a cara da vila.
func _placa_neon(pos: Vector3, altura: float, cor: Color, rot_y := 0.0) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(rot_y))
	_caixa(Vector3(0.7, altura, 0.16), pos, Vector3(0, rot_y, 0), Color(0.05, 0.05, 0.08))
	_caixa(Vector3(0.78, 0.06, 0.2), pos + Vector3(0, altura / 2, 0), Vector3(0, rot_y, 0), cor * 1.5, true)
	_caixa(Vector3(0.78, 0.06, 0.2), pos - Vector3(0, altura / 2, 0), Vector3(0, rot_y, 0), cor * 1.5, true)
	var n := int(altura / 0.55)
	for k in n:
		var y := altura / 2 - 0.35 - k * 0.55
		var larg := 0.42 if k % 2 == 0 else 0.3
		_caixa(Vector3(larg, 0.09, 0.2), pos + b * Vector3(0, y, 0), Vector3(0, rot_y, 0), cor * 1.8, true)
		_caixa(Vector3(0.08, 0.3, 0.2), pos + b * Vector3(0.12 * (1 if k % 2 else -1), y - 0.12, 0), Vector3(0, rot_y, 0), cor * 1.8, true)


func _vaso(pos: Vector3) -> void:
	_cil(0.22, 0.17, 0.35, 8, pos + Vector3(0, 0.17, 0), Vector3.ZERO, Color(0.35, 0.22, 0.18))
	_esfera(0.3, pos + Vector3(0, 0.55, 0), Vector3(1, 0.8, 1), P.folha if P.arvore == "sakura" else Color(0.18, 0.4, 0.28), false, 7, 4)


# --- Castelo -------------------------------------------------------------------

## Módulo de muralha alta (6 m em x) com passarela de madeira em cima e mureta
## com ameias do lado de fora (+z). Coincide com o colisor do Arena._wall_walk.
func _muralha() -> void:
	var h := ALT_MURO
	var t := ESP_MURO
	_caixa(Vector3(6.0, 1.5, t + 0.3), Vector3(0, 0.75, 0), Vector3.ZERO, P.pedra)
	for k in 3:  # fiadas de pedra
		_caixa(Vector3(6.02, 0.05, t + 0.32), Vector3(0, 0.35 + k * 0.4, 0), Vector3.ZERO, P.pedra2)
	for x in [-2.0, 0.0, 2.0]:
		_caixa(Vector3(0.05, 1.5, t + 0.32), Vector3(x + 0.3, 0.75, 0), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(6.0, h - 1.5, t), Vector3(0, 1.5 + (h - 1.5) / 2, 0), Vector3.ZERO, P.reboco)
	_caixa(Vector3(6.0, 0.18, t + 0.06), Vector3(0, 1.55, 0), Vector3.ZERO, P.madeira)
	# Passarela de tábuas.
	for k in 6:
		_caixa(Vector3(0.95, 0.06, t - 0.45), Vector3(-2.5 + k, h + 0.03, -0.2), Vector3.ZERO, P.madeira2.darkened(0.05 * (k % 2)))
	_caixa(Vector3(6.0, 0.12, 0.12), Vector3(0, h + 0.02, -t / 2 + 0.06), Vector3.ZERO, P.madeira)
	# Mureta de fora com telhadinho e ameias.
	_caixa(Vector3(6.0, 1.0, 0.4), Vector3(0, h + 0.5, t / 2 - 0.2), Vector3.ZERO, P.reboco)
	_caixa(Vector3(6.05, 0.12, 0.7), Vector3(0, h + 1.05, t / 2 - 0.2), Vector3.ZERO, P.telhado)
	for x in [-2.0, 0.0, 2.0]:
		_caixa(Vector3(0.9, 0.45, 0.42), Vector3(x, h + 1.33, t / 2 - 0.2), Vector3.ZERO, P.reboco)
		_caixa(Vector3(0.95, 0.08, 0.5), Vector3(x, h + 1.58, t / 2 - 0.2), Vector3.ZERO, P.telhado)
		_caixa(Vector3(0.12, 0.35, 0.44), Vector3(x + 1.0, h + 0.55, t / 2 - 0.2), Vector3.ZERO, Color(0.06, 0.05, 0.08))
	# Seteiras e lanterna na face de dentro.
	for x in [-1.5, 1.5]:
		_caixa(Vector3(0.15, 0.45, 0.06), Vector3(x, 2.3, t / 2 + 0.01), Vector3.ZERO, Color(0.06, 0.05, 0.08))
	_caixa(Vector3(0.3, 0.38, 0.3), Vector3(0, 2.6, -t / 2 - 0.15), Vector3.ZERO, P.papel, true)
	_caixa(Vector3(0.38, 0.06, 0.38), Vector3(0, 2.82, -t / 2 - 0.15), Vector3.ZERO, Color(0.1, 0.08, 0.08))


## Torre do portão, mais alta que a muralha (base de pedra + yagura de 2 andares).
func _torre_alta(time: Color) -> void:
	var telha: Color = P.telhado.lerp(time, 0.35)
	_cil(2.4, 2.9, ALT_MURO + 0.3, 4, Vector3(0, (ALT_MURO + 0.3) / 2, 0), Vector3(0, 45, 0), P.pedra)
	for k in 3:
		_cil(2.85 - k * 0.15, 2.88 - k * 0.15, 0.05, 4, Vector3(0, 0.6 + k * 0.9, 0), Vector3(0, 45, 0), P.pedra2)
	var y := ALT_MURO + 0.3
	_caixa(Vector3(3.4, 1.8, 3.4), Vector3(0, y + 0.9, 0), Vector3.ZERO, P.reboco)
	_caixa(Vector3(3.45, 0.2, 3.45), Vector3(0, y + 0.1, 0), Vector3.ZERO, P.madeira)
	for s in [-1, 1]:
		_shoji(Vector3(0, y + 1.0, s * 1.72), 1.2, 0.7, s, P.papel)
	_telhado(Vector3(0, y + 1.8, 0), 3.6, 3.6, 1.0, telha, 0.5)
	_caixa(Vector3(4.6, 0.08, 4.6), Vector3(0, y + 1.75, 0), Vector3.ZERO, time * 1.4, true)
	_caixa(Vector3(2.0, 1.0, 2.0), Vector3(0, y + 3.1, 0), Vector3.ZERO, P.reboco)
	_telhado(Vector3(0, y + 3.6, 0), 2.2, 2.2, 0.9, telha, 0.35)


## Portão de entrada (pilares, viga, telhado e portas abertas).
func _portao() -> void:
	for z in [-5.6, 5.6]:
		_caixa(Vector3(1.2, 4.8, 1.0), Vector3(0, 2.4, z), Vector3.ZERO, P.madeira)
		_caixa(Vector3(1.3, 0.5, 1.1), Vector3(0, 0.25, z), Vector3.ZERO, P.pedra)
		for y in [1.2, 2.4, 3.6]:
			_caixa(Vector3(1.25, 0.08, 1.05), Vector3(0, y, z), Vector3.ZERO, Color(0.12, 0.12, 0.15))
	_caixa(Vector3(1.0, 0.6, 12.4), Vector3(0, 4.6, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(1.05, 0.1, 12.4), Vector3(0, 4.25, 0), Vector3.ZERO, P.luz2 * 1.4, true)
	# Sem telhado largo: a câmera precisa ver a luta no portão.
	_caixa(Vector3(1.5, 0.22, 13.4), Vector3(0, 5.0, 0), Vector3.ZERO, P.telhado)
	_caixa(Vector3(0.3, 0.3, 13.6), Vector3(0, 5.2, 0), Vector3.ZERO, P.telhado.darkened(0.3))
	_caixa(Vector3(0.12, 1.0, 2.4), Vector3(0.6, 3.6, 0), Vector3.ZERO, Color(0.06, 0.05, 0.08))
	_caixa(Vector3(0.14, 0.8, 2.2), Vector3(0.62, 3.6, 0), Vector3.ZERO, P.ouro, true)
	for s in [-1, 1]:  # portas abertas encostadas
		_caixa(Vector3(2.6, 3.8, 0.25), Vector3(-1.4, 1.9, s * 4.9), Vector3(0, 0, 0), P.madeira2)
		for y in [0.8, 1.9, 3.0]:
			_caixa(Vector3(2.62, 0.12, 0.3), Vector3(-1.4, y, s * 4.9), Vector3.ZERO, Color(0.12, 0.12, 0.15))
		_lanterna_papel(Vector3(0.7, 3.4, s * 5.0), P.papel, 0.25)


## Escada maciça de `comp` m subindo até `alt`, largura `larg`, com patamar
## de `patamar` m no topo. Começa em x = 0 e sobe para +x.
func _escada(comp: float, alt: float, larg: float, patamar: float) -> void:
	var n := int(comp / 0.45)
	for k in n:
		var h := alt * (k + 1) / n
		var x := comp * (k + 0.5) / n
		_caixa(Vector3(comp / n + 0.01, h, larg), Vector3(x, h / 2, 0), Vector3.ZERO, P.pedra if k % 2 else P.pedra.darkened(0.06))
		_caixa(Vector3(comp / n * 0.4, 0.04, larg), Vector3(x + comp / n * 0.3, h + 0.02, 0), Vector3.ZERO, P.madeira2)
	if patamar > 0.0:
		_caixa(Vector3(patamar, alt, larg), Vector3(comp + patamar / 2, alt / 2, 0), Vector3.ZERO, P.pedra)
		_caixa(Vector3(patamar, 0.06, larg), Vector3(comp + patamar / 2, alt + 0.03, 0), Vector3.ZERO, P.madeira2)
	# Corrimão no lado aberto (-z) com postes e lanternas.
	var a := atan2(alt, comp)
	_caixa(Vector3(sqrt(comp * comp + alt * alt), 0.08, 0.08), Vector3(comp / 2, alt / 2 + 0.95, -larg / 2 + 0.06), Vector3(0, 0, rad_to_deg(a)), P.madeira)
	for k in 4:
		var x := comp * k / 3.0
		_cil(0.05, 0.05, 1.0, 5, Vector3(x, alt * k / 3.0 + 0.5, -larg / 2 + 0.06), Vector3.ZERO, P.madeira)
	_toro_mini(Vector3(0.2, 0, -larg / 2 - 0.4))


func _toro_mini(at: Vector3) -> void:
	_cil(0.2, 0.26, 0.15, 6, at + Vector3(0, 0.07, 0), Vector3.ZERO, P.pedra)
	_cil(0.08, 0.08, 0.55, 6, at + Vector3(0, 0.42, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(0.28, 0.28, 0.28), at + Vector3(0, 0.82, 0), Vector3.ZERO, P.papel, true)
	_cil(0.03, 0.36, 0.22, 6, at + Vector3(0, 1.07, 0), Vector3.ZERO, P.pedra2)


# --- Relevo e água -------------------------------------------------------------

## Colina de 12 x 8 m e 2,4 m de altura: muro de arrimo de pedra, topo de grama
## e musgo caindo pela borda.
func _colina() -> void:
	var w := 12.0
	var d := 8.0
	_cil(0.0, 1.0, ALT_COLINA, 4, Vector3(0, ALT_COLINA / 2, 0), Vector3(0, 45, 0), P.pedra, false, Vector3(w / 1.414 + 0.2, 1, d / 1.414 + 0.2))
	_caixa(Vector3(w, ALT_COLINA, d), Vector3(0, ALT_COLINA / 2, 0), Vector3.ZERO, P.pedra)
	for k in 3:
		_caixa(Vector3(w + 0.04, 0.05, d + 0.04), Vector3(0, 0.5 + k * 0.7, 0), Vector3.ZERO, P.pedra2)
	for k in 9:
		var x := -w / 2 + 0.7 + k * (w - 1.4) / 8.0
		for s in [-1, 1]:
			_caixa(Vector3(0.05, ALT_COLINA, 0.04), Vector3(x + 0.3 * s, ALT_COLINA / 2, s * (d / 2 + 0.01)), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(w + 0.1, 0.12, d + 0.1), Vector3(0, ALT_COLINA + 0.02, 0), Vector3.ZERO, P.capim.darkened(0.1))
	for k in 14:
		var a := k * 2.39
		var p := Vector3(cos(a) * (w / 2 - 0.3) * (0.4 + 0.6 * fmod(k * 0.37, 1.0)), ALT_COLINA + 0.1, sin(a) * (d / 2 - 0.3) * (0.4 + 0.6 * fmod(k * 0.53, 1.0)))
		_esfera(0.35, p, Vector3(1, 0.5, 1), P.capim if k % 2 else P.musgo, false, 6, 3)
	for s in [-1, 1]:  # musgo escorrendo
		for k in 6:
			_caixa(Vector3(0.6, 0.5 + fmod(k * 0.41, 1.0) * 0.8, 0.06), Vector3(-w / 2 + 1 + k * 2, ALT_COLINA - 0.4, s * (d / 2 + 0.04)), Vector3.ZERO, P.musgo)


## Trecho de rio (9 x 8 m): água, faixa clara de correnteza, margens de pedra
## com juncos, pedras e lanternas flutuantes.
func _rio(v: int) -> void:
	var L := 8.2
	_caixa(Vector3(RIO_MEIA * 2, 0.05, L), Vector3(0, 0.03, 0), Vector3.ZERO, P.agua)
	for k in 3:
		_caixa(Vector3(0.25 + 0.15 * k, 0.02, L * (0.5 + 0.15 * k)), Vector3(-1.5 + k * 1.4 + v * 0.5, 0.065, (k - 1) * 0.8), Vector3(0, 4 - k * 3, 0), P.agua.lightened(0.18 + 0.05 * k))
	for s in [-1, 1]:
		_caixa(Vector3(0.7, 0.8, L), Vector3(s * (RIO_MEIA + 0.1), 0.4, 0), Vector3.ZERO, P.pedra)
		_caixa(Vector3(0.8, 0.1, L), Vector3(s * (RIO_MEIA + 0.1), 0.82, 0), Vector3.ZERO, P.pedra2)
		for k in 5:
			_caixa(Vector3(0.72, 0.04, 0.05), Vector3(s * (RIO_MEIA + 0.1), 0.4, -L / 2 + 0.8 + k * 1.6), Vector3.ZERO, P.pedra2)
		for k in 7:
			var z := -L / 2 + 0.6 + k * 1.15
			_cil(0.0, 0.04, 0.9 + fmod(k * 0.37, 1.0) * 0.5, 3, Vector3(s * (RIO_MEIA - 0.4), 0.45, z), Vector3(s * 8, 0, s * 10), P.capim)
	for k in 3:
		var p := Vector3(sin(k * 2.1 + v) * 2.5, 0.12, -2.5 + k * 2.5)
		_esfera(0.4 + 0.15 * k, p, Vector3(1, 0.45, 0.9), P.pedra2, false, 6, 3)
	for k in 2:  # lanternas flutuantes (tourou nagashi)
		var p := Vector3(-1.8 + k * 3.0 + v, 0.12, 1.8 - k * 3.4 + v)
		_caixa(Vector3(0.4, 0.08, 0.4), p, Vector3(0, 20 * k, 0), P.madeira)
		_caixa(Vector3(0.3, 0.3, 0.3), p + Vector3(0, 0.19, 0), Vector3(0, 20 * k, 0), P.papel if (k + v) % 2 else P.luz2, true)
	for k in 3:
		_cil(0.3, 0.3, 0.02, 8, Vector3(cos(k * 2.0 + v) * 3.2, 0.07, sin(k * 1.3) * 3.0), Vector3.ZERO, Color(0.2, 0.42, 0.28))


## Ponte arqueada de `larg` m, 18 m de ponta a ponta (x de -9 a 9).
func _ponte(larg: float) -> void:
	var n := 18
	for k in n:
		var x0 := -9.0 + 18.0 * k / n
		var x1 := -9.0 + 18.0 * (k + 1) / n
		var y0 := _altura_ponte(x0)
		var y1 := _altura_ponte(x1)
		var mx := (x0 + x1) / 2
		var ang := rad_to_deg(atan2(y1 - y0, x1 - x0))
		_caixa(Vector3(x1 - x0 + 0.04, 0.22, larg), Vector3(mx, (y0 + y1) / 2 - 0.09, 0), Vector3(0, 0, ang), P.torii.darkened(0.15) if k % 2 else P.torii.darkened(0.25))
	for s in [-1, 1]:
		var zr: float = s * (larg / 2 - 0.12)
		for k in 9:
			var x := -8.0 + k * 2.0
			_cil(0.07, 0.08, 1.0, 6, Vector3(x, _altura_ponte(x) + 0.5, zr), Vector3.ZERO, P.torii)
			_esfera(0.09, Vector3(x, _altura_ponte(x) + 1.05, zr), Vector3.ONE, P.ouro, true, 6, 3)
		for k in 8:
			var x0 := -8.0 + k * 2.0
			var x1 := x0 + 2.0
			var y0 := _altura_ponte(x0) + 0.95
			var y1 := _altura_ponte(x1) + 0.95
			_caixa(Vector3(2.05, 0.1, 0.12), Vector3((x0 + x1) / 2, (y0 + y1) / 2, zr), Vector3(0, 0, rad_to_deg(atan2(y1 - y0, 2.0))), P.torii)
		_lanterna_papel(Vector3(-9.2, 1.6, s * (larg / 2 + 0.3)), P.papel)
		_lanterna_papel(Vector3(9.2, 1.6, s * (larg / 2 + 0.3)), P.papel)
		for x in [-9.2, 9.2]:
			_cil(0.08, 0.08, 1.4, 5, Vector3(x, 0.7, s * (larg / 2 + 0.3)), Vector3.ZERO, P.madeira)
	# Pilares de pedra dentro da água.
	for x in [-3.0, 3.0]:
		for s in [-1, 1]:
			_cil(0.3, 0.35, ALT_PONTE, 6, Vector3(x, ALT_PONTE / 2 - 0.1, s * (larg / 2 - 0.5)), Vector3.ZERO, P.pedra2)


## Perfil da ponte: rampa de 4,5 m em cada margem e tabuleiro reto sobre o rio.
func _altura_ponte(x: float) -> float:
	var ax := absf(x)
	if ax <= RIO_MEIA:
		return ALT_PONTE + 0.15 * (1.0 - ax / RIO_MEIA)
	return ALT_PONTE * clampf((9.0 - ax) / (9.0 - RIO_MEIA), 0.0, 1.0)


## Cachoeira no fim do rio: paredão de pedra, quedas de água e espuma.
func _cachoeira() -> void:
	_caixa(Vector3(16, 6.0, 3.0), Vector3(0, 3.0, -1.5), Vector3.ZERO, P.pedra2)
	for k in 7:
		_esfera(1.6 + fmod(k * 0.37, 1.0), Vector3(-7 + k * 2.3, 5.0 + fmod(k * 0.53, 1.0) * 1.5, -1.0), Vector3(1, 0.8, 0.8), P.pedra if k % 2 else P.pedra2, false, 7, 4)
		_esfera(0.9, Vector3(-7 + k * 2.3, 6.6, -0.6), Vector3(1, 0.4, 0.9), P.musgo, false, 6, 3)
	for k in 4:
		_caixa(Vector3(1.4 - k * 0.2, 5.6, 0.1), Vector3(-1.8 + k * 1.2, 2.8, 0.05 + k * 0.03), Vector3(-6, 0, 0), P.agua.lightened(0.45 if k % 2 else 0.3), true)
	for k in 10:
		_esfera(0.35, Vector3(-2.4 + k * 0.5, 0.25, 0.6 + fmod(k * 0.37, 1.0) * 0.8), Vector3(1, 0.6, 1), P.branco, true, 6, 3)
	for s in [-1, 1]:
		_bambu(Vector3(s * 6.5, 0, 1.0), 7.0, Vector3(0, 0, -s * 6))
		_bambu(Vector3(s * 7.3, 0, 0.6), 8.0, Vector3(0, 0, -s * 3))


# --- Vila -----------------------------------------------------------------------

## Machiya de 2 andares (5 x 4,5 m), frente em +z: portas de correr acesas,
## cortina noren, telhadinho, varanda de treliça e telhado de quatro águas.
func _casa_a() -> void:
	var w := 5.0
	var d := 4.5
	_caixa(Vector3(w + 0.2, 0.3, d + 0.2), Vector3(0, 0.15, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(w, 2.4, d), Vector3(0, 1.5, 0), Vector3.ZERO, P.madeira2)
	for x in [-w / 2, -w / 6, w / 6, w / 2]:
		_caixa(Vector3(0.18, 2.5, 0.18), Vector3(x, 1.5, d / 2 + 0.02), Vector3.ZERO, P.madeira)
	_shoji(Vector3(-0.9, 1.35, d / 2 + 0.03), 1.4, 1.8, 1, P.papel)
	_shoji(Vector3(1.1, 1.35, d / 2 + 0.03), 1.6, 1.8, 1, P.papel)
	for k in 3:
		_caixa(Vector3(0.44, 0.6, 0.03), Vector3(-1.35 + k * 0.46, 2.0, d / 2 + 0.12), Vector3.ZERO, [P.torii, P.telhado, P.torii][k])
	_caixa(Vector3(w + 0.6, 0.12, 1.2), Vector3(0, 2.85, d / 2 + 0.45), Vector3(-18, 0, 0), P.telhado)
	_caixa(Vector3(w - 0.3, 1.9, d - 0.9), Vector3(0, 3.75, -0.3), Vector3.ZERO, P.reboco)
	for k in 9:  # treliça mushiko do 2º andar
		_caixa(Vector3(0.07, 0.9, 0.06), Vector3(-1.6 + k * 0.4, 3.75, d / 2 - 0.73), Vector3.ZERO, P.madeira)
	_caixa(Vector3(3.4, 0.9, 0.03), Vector3(0, 3.75, d / 2 - 0.77), Vector3.ZERO, P.papel.darkened(0.15), true)
	_telhado(Vector3(0, 4.7, -0.3), w + 0.2, d - 0.4, 1.2, P.telhado, 0.55)
	_lanterna_papel(Vector3(-w / 2 + 0.2, 2.2, d / 2 + 0.45), P.luz2)
	_lanterna_papel(Vector3(w / 2 - 0.2, 2.2, d / 2 + 0.45), P.papel)
	_vaso(Vector3(-w / 2 + 0.4, 0.3, d / 2 + 0.6))
	_vaso(Vector3(w / 2 - 0.5, 0.3, d / 2 + 0.6))
	_caixa(Vector3(1.4, 0.1, 0.4), Vector3(1.4, 0.55, d / 2 + 0.7), Vector3.ZERO, P.madeira2)  # banco
	for x in [0.9, 1.9]:
		_caixa(Vector3(0.08, 0.45, 0.35), Vector3(x, 0.3, d / 2 + 0.7), Vector3.ZERO, P.madeira)
	if P.arvore == "bambu":
		_placa_neon(Vector3(w / 2 + 0.45, 3.4, d / 2 - 0.3), 2.2, P.luz2, 90.0)
	else:
		_placa_neon(Vector3(w / 2 + 0.45, 3.4, d / 2 - 0.3), 2.2, P.torii, 90.0)
	_fundos(w, d, [1.4])
	_shoji(Vector3(-w * 0.2, 3.75, -0.3 - (d - 0.9) / 2 - 0.03), 1.2, 0.8, -1, P.papel)
	_aldeao(Vector3(-1.3, 0, d / 2 + 1.0), 30.0, P.luz2.darkened(0.35), "varrer")


## Casa de fazenda térrea (6 x 5 m) com telhado alto de palha e varanda (engawa).
func _casa_b() -> void:
	var w := 6.0
	var d := 5.0
	var palha := Color(0.36, 0.3, 0.22) if P.arvore == "bambu" else Color(0.68, 0.56, 0.36)
	_caixa(Vector3(w + 0.2, 0.45, d + 0.2), Vector3(0, 0.22, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(w, 2.2, d - 1.2), Vector3(0, 1.55, -0.6), Vector3.ZERO, P.reboco)
	for k in 6:
		_caixa(Vector3(0.16, 2.2, 0.16), Vector3(-w / 2 + k * w / 5, 1.55, d / 2 - 1.2), Vector3.ZERO, P.madeira)
	for k in 3:
		_shoji(Vector3(-1.8 + k * 1.8, 1.45, d / 2 - 1.18), 1.3, 1.6, 1, P.papel if k != 1 else P.luz1.lerp(P.papel, 0.5))
	_caixa(Vector3(w, 0.12, 1.2), Vector3(0, 0.62, d / 2 - 0.6), Vector3.ZERO, P.madeira2)  # engawa
	for x in [-w / 2 + 0.1, 0.0, w / 2 - 0.1]:
		_cil(0.08, 0.08, 2.2, 6, Vector3(x, 1.65, d / 2 - 0.05), Vector3.ZERO, P.madeira)
	_telhado(Vector3(0, 2.7, 0), w + 0.6, d + 0.4, 2.4, palha, 0.45)
	_caixa(Vector3(w * 0.5, 0.35, 0.5), Vector3(0, 5.05, 0), Vector3.ZERO, P.madeira)
	for k in 4:  # lenha empilhada
		_cil(0.12, 0.12, 1.2, 6, Vector3(-w / 2 - 0.4, 0.15 + k * 0.22, -1.2 + (k % 2) * 0.12), Vector3(90, 0, 0), P.madeira2)
		_cil(0.12, 0.12, 1.2, 6, Vector3(-w / 2 - 0.65, 0.15 + k * 0.22, -1.1), Vector3(90, 0, 0), P.madeira2.darkened(0.1))
	_lanterna_papel(Vector3(w / 2 - 0.3, 2.3, d / 2 + 0.1), P.papel)
	_vaso(Vector3(-1.0, 0.45, d / 2 + 0.5))
	_fundos(w, d, [1.45])
	_aldeao(Vector3(1.3, 0.68, d / 2 - 0.55), 0.0, P.telhado.lightened(0.25), "sentado")
	for k in 2:  # gato dormindo na varanda
		_esfera(0.13 - k * 0.04, Vector3(2.0 + k * 0.17, 0.78 + k * 0.05, d / 2 - 0.4), Vector3(1.4, 0.8, 1), Color(0.95, 0.6, 0.25), false, 6, 3)


## Loja com toldo listrado, balcão com mercadorias e placa de neon grande.
func _loja() -> void:
	var w := 5.0
	var d := 4.5
	_caixa(Vector3(w + 0.2, 0.3, d + 0.2), Vector3(0, 0.15, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(w, 3.0, d - 1.0), Vector3(0, 1.8, -0.5), Vector3.ZERO, P.madeira2)
	_caixa(Vector3(w - 0.4, 2.0, 0.04), Vector3(0, 1.4, d / 2 - 0.98), Vector3.ZERO, Color(1.0, 0.85, 0.6), true)
	for k in 3:  # prateleiras com coisas coloridas
		_caixa(Vector3(w - 0.5, 0.06, 0.4), Vector3(0, 0.8 + k * 0.6, d / 2 - 1.15), Vector3.ZERO, P.madeira)
		for j in 6:
			_caixa(Vector3(0.3, 0.3, 0.25), Vector3(-1.9 + j * 0.75, 1.0 + k * 0.6, d / 2 - 1.1), Vector3.ZERO, [P.torii, P.luz1, P.ouro, P.luz2, P.branco, P.madeira2][(j + k) % 6])
	_caixa(Vector3(w - 0.2, 0.9, 0.7), Vector3(0, 0.75, d / 2 - 0.3), Vector3.ZERO, P.madeira)
	for j in 5:
		_esfera(0.18, Vector3(-1.8 + j * 0.9, 1.35, d / 2 - 0.3), Vector3(1, 0.7, 1), [P.ouro, P.torii, P.luz1, P.branco, P.luz2][j], false, 6, 3)
	for k in 6:  # toldo listrado
		_caixa(Vector3(w / 6 + 0.01, 0.06, 1.6), Vector3(-w / 2 + (k + 0.5) * w / 6, 2.75, d / 2 + 0.1), Vector3(-22, 0, 0), P.luz2 if k % 2 else P.branco)
	_telhado(Vector3(0, 3.3, -0.5), w + 0.2, d - 0.8, 1.1, P.telhado, 0.5)
	_placa_neon(Vector3(-w / 2 - 0.1, 3.4, d / 2 - 0.2), 3.0, P.luz1 if P.arvore == "bambu" else P.luz2, 0.0)
	for j in 5:
		_lanterna_papel(Vector3(-2.0 + j, 2.55, d / 2 + 0.85), P.papel if j % 2 else P.luz2, 0.16)
	_aldeao(Vector3(0.9, 0.3, d / 2 - 0.85), 0.0, P.torii.darkened(0.1), "vender", false, P.branco)
	_fundos(w, d, [1.6])


## Pousada de 3 andares com varanda e cordão de lanternas.
func _pousada() -> void:
	var w := 6.0
	var d := 5.0
	_caixa(Vector3(w + 0.2, 0.3, d + 0.2), Vector3(0, 0.15, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(w, 2.5, d), Vector3(0, 1.55, 0), Vector3.ZERO, P.madeira2)
	_shoji(Vector3(0, 1.4, d / 2 + 0.03), 2.6, 1.9, 1, P.papel)
	_caixa(Vector3(1.6, 0.6, 0.12), Vector3(0, 2.55, d / 2 + 0.1), Vector3.ZERO, Color(0.08, 0.06, 0.05))
	_caixa(Vector3(1.3, 0.35, 0.14), Vector3(0, 2.55, d / 2 + 0.11), Vector3.ZERO, P.ouro, true)
	_caixa(Vector3(w + 0.4, 0.15, d + 0.6), Vector3(0, 2.85, 0.2), Vector3.ZERO, P.madeira)  # piso da varanda
	_caixa(Vector3(w - 0.6, 2.2, d - 0.8), Vector3(0, 4.05, -0.1), Vector3.ZERO, P.reboco)
	for k in 3:
		_shoji(Vector3(-1.8 + k * 1.8, 4.0, d / 2 - 0.47), 1.3, 1.3, 1, P.papel)
	for k in 13:  # balaústre
		_caixa(Vector3(0.06, 0.7, 0.06), Vector3(-w / 2 - 0.1 + k * (w + 0.2) / 12, 3.3, d / 2 + 0.45), Vector3.ZERO, P.madeira)
	_caixa(Vector3(w + 0.3, 0.08, 0.1), Vector3(0, 3.65, d / 2 + 0.45), Vector3.ZERO, P.madeira)
	_telhado(Vector3(0, 5.15, -0.1), w, d - 0.6, 0.9, P.telhado, 0.5)
	_caixa(Vector3(w - 2.0, 1.6, d - 2.0), Vector3(0, 6.25, -0.1), Vector3.ZERO, P.reboco)
	_shoji(Vector3(0, 6.3, d / 2 - 0.97), 2.0, 0.8, 1, P.papel)
	_telhado(Vector3(0, 7.05, -0.1), w - 1.6, d - 1.6, 1.1, P.telhado, 0.45)
	for k in 7:
		_lanterna_papel(Vector3(-w / 2 + k * w / 6, 3.0 - (0.15 if k % 2 else 0.0), d / 2 + 0.8), P.luz2 if k % 3 == 0 else P.papel, 0.17)
	_aldeao(Vector3(1.6, 2.93, 2.3), -15.0, P.luz2.darkened(0.2), "lanterna")
	_aldeao(Vector3(-1.9, 0.3, d / 2 + 0.6), 20.0, P.madeira2.lightened(0.2), "parado", true)
	_fundos(w, d, [1.4])
	_shoji(Vector3(-w * 0.2, 4.0, -0.1 - (d - 0.8) / 2 - 0.03), 1.3, 0.9, -1, P.papel)


## Armazém (kura): reboco branco, base com grade namako, porta pesada.
func _armazem() -> void:
	var w := 4.5
	var d := 4.0
	_caixa(Vector3(w, 1.2, d), Vector3(0, 0.6, 0), Vector3.ZERO, Color(0.15, 0.15, 0.2))
	for k in 6:  # grade diagonal namako
		for s in [-1, 1]:
			_caixa(Vector3(0.06, 1.5, 0.03), Vector3(-w / 2 + 0.4 + k * 0.75, 0.6, s * (d / 2 + 0.01)), Vector3(0, 0, 45), P.branco.darkened(0.2))
			_caixa(Vector3(0.06, 1.5, 0.03), Vector3(-w / 2 + 0.4 + k * 0.75, 0.6, s * (d / 2 + 0.01)), Vector3(0, 0, -45), P.branco.darkened(0.2))
	_caixa(Vector3(w, 2.4, d), Vector3(0, 2.4, 0), Vector3.ZERO, P.reboco)
	_caixa(Vector3(1.4, 1.9, 0.2), Vector3(0, 1.05, d / 2 + 0.06), Vector3.ZERO, Color(0.12, 0.1, 0.1))
	for y in [0.5, 1.0, 1.5]:
		_caixa(Vector3(1.45, 0.06, 0.24), Vector3(0, y, d / 2 + 0.06), Vector3.ZERO, P.ouro)
	_caixa(Vector3(0.7, 0.6, 0.2), Vector3(0, 3.0, d / 2 + 0.06), Vector3.ZERO, Color(0.12, 0.1, 0.1))
	_cil(0.25, 0.25, 0.04, 10, Vector3(0, 3.0, d / 2 + 0.18), Vector3(90, 0, 0), P.branco)
	_telhado(Vector3(0, 3.6, 0), w + 0.2, d + 0.2, 1.3, P.telhado, 0.45)
	for k in 3:
		_caixa(Vector3(0.8, 0.8, 0.8), Vector3(w / 2 + 0.6, 0.4 + (0.8 if k == 2 else 0.0), -0.9 + (k % 2) * 0.9), Vector3(0, k * 13, 0), P.madeira2)
	_cil(0.4, 0.4, 0.85, 10, Vector3(-w / 2 - 0.55, 0.43, 0.8), Vector3.ZERO, P.madeira2)
	_cil(0.42, 0.42, 0.08, 10, Vector3(-w / 2 - 0.55, 0.65, 0.8), Vector3.ZERO, P.corda)
	_fundos(w, d, [2.6])


## Fileira de 3 barracas de festival com máscaras, peixinhos e lanternas.
func _festival() -> void:
	for i in 3:
		var x := (i - 1) * 3.0
		for z in [-0.9, 0.9]:
			for dx in [-1.35, 1.35]:
				_cil(0.06, 0.06, 2.4 if z < 0 else 2.1, 5, Vector3(x + dx, 1.2 if z < 0 else 1.05, z), Vector3.ZERO, P.madeira)
		for k in 5:
			_caixa(Vector3(0.56, 0.06, 2.2), Vector3(x - 1.12 + k * 0.56, 2.3, 0), Vector3(-9, 0, 0), [P.torii, P.branco][k % 2] if i != 1 else [P.luz2, P.branco][k % 2])
		_caixa(Vector3(2.6, 0.8, 0.6), Vector3(x, 0.4, 0.8), Vector3.ZERO, P.madeira2)
		if i == 1:
			_caixa(Vector3(2.2, 0.15, 0.5), Vector3(x, 0.85, 0.8), Vector3.ZERO, P.agua.lightened(0.3), true)
			for k in 4:
				_esfera(0.07, Vector3(x - 0.7 + k * 0.45, 0.95, 0.8), Vector3(1.5, 0.6, 0.6), P.luz2 if k % 2 else P.ouro, true, 5, 3)
		else:
			for k in 4:
				_esfera(0.17, Vector3(x - 0.9 + k * 0.6, 1.7, 0.95), Vector3(1, 1.15, 0.5), [P.branco, P.torii, P.luz1, P.ouro][(k + i) % 4])
				_esfera(0.04, Vector3(x - 0.95 + k * 0.6, 1.75, 1.03), Vector3.ONE, Color(0.05, 0.05, 0.05))
		_caixa(Vector3(2.4, 0.4, 0.04), Vector3(x, 2.05, 1.02), Vector3.ZERO, Color(0.06, 0.05, 0.07))
		_caixa(Vector3(1.6, 0.12, 0.05), Vector3(x, 2.05, 1.04), Vector3.ZERO, [P.luz1, P.luz2, P.ouro][i] * 1.4, true)
	for k in 9:
		_lanterna_papel(Vector3(-4.4 + k * 1.1, 2.65 - sin(k / 8.0 * PI) * 0.3, 1.25), P.papel if k % 2 else P.luz2, 0.15)
	for i in 3:  # vendedores atrás das barracas
		_aldeao(Vector3((i - 1) * 3.0 + 0.3, 0, 0.05), 0.0, [P.telhado.lightened(0.3), P.torii.lightened(0.1), P.musgo.lightened(0.25)][i], "vender", i == 1)


func _poco() -> void:
	_cil(0.9, 1.0, 0.8, 10, Vector3(0, 0.4, 0), Vector3.ZERO, P.pedra)
	_cil(0.75, 0.75, 0.05, 10, Vector3(0, 0.78, 0), Vector3.ZERO, P.agua)
	for s in [-1, 1]:
		_cil(0.07, 0.07, 2.0, 5, Vector3(s * 0.85, 1.6, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(2.0, 0.1, 0.12), Vector3(0, 2.4, 0), Vector3.ZERO, P.madeira)
	_telhado(Vector3(0, 2.5, 0), 1.6, 1.2, 0.6, P.telhado, 0.25)
	_cil(0.2, 0.17, 0.3, 8, Vector3(0.95, 0.95, 0.3), Vector3.ZERO, P.madeira2)
	_caixa(Vector3(0.02, 1.4, 0.02), Vector3(0, 1.7, 0), Vector3.ZERO, P.corda)


func _carroca() -> void:
	_caixa(Vector3(2.4, 0.15, 1.3), Vector3(0, 0.75, 0), Vector3.ZERO, P.madeira2)
	for s in [-1, 1]:
		_caixa(Vector3(2.4, 0.4, 0.08), Vector3(0, 1.0, s * 0.62), Vector3.ZERO, P.madeira)
		_toro(0.42, 0.55, Vector3(0, 0.55, s * 0.75), Vector3(1, 1, 1), P.madeira)
	for s in [-1, 1]:
		_cil(0.05, 0.05, 2.0, 5, Vector3(2.1, 0.75, s * 0.4), Vector3(0, 0, 90), P.madeira)
	for k in 4:
		_esfera(0.33, Vector3(-0.8 + k * 0.5, 1.15, (k % 2) * 0.3 - 0.15), Vector3(1, 0.75, 0.85), P.corda.lightened(0.1), false, 7, 4)


## Poste de rua com lanterna pendurada (luz da vila).
func _poste() -> void:
	_cil(0.09, 0.11, 3.2, 6, Vector3(0, 1.6, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.9, 0.08, 0.08), Vector3(0.35, 3.1, 0), Vector3.ZERO, P.madeira)
	_lanterna_papel(Vector3(0.7, 2.55, 0), P.papel, 0.24)
	_cil(0.2, 0.25, 0.25, 6, Vector3(0, 0.12, 0), Vector3.ZERO, P.pedra)


## Campanário do templo com sino de bronze e tronco para tocar.
func _sino() -> void:
	_caixa(Vector3(3.4, 0.6, 3.4), Vector3(0, 0.3, 0), Vector3.ZERO, P.pedra)
	for k in 3:
		_caixa(Vector3(3.42, 0.04, 3.42), Vector3(0, 0.12 + k * 0.18, 0), Vector3.ZERO, P.pedra2)
	for x in [-1.3, 1.3]:
		for z in [-1.3, 1.3]:
			_cil(0.12, 0.15, 3.1, 7, Vector3(x, 2.15, z), Vector3(0, 0, -x * 2), P.madeira)
	for y in [1.4, 3.4]:
		_caixa(Vector3(2.8, 0.15, 0.15), Vector3(0, y, 1.3), Vector3.ZERO, P.madeira)
		_caixa(Vector3(2.8, 0.15, 0.15), Vector3(0, y, -1.3), Vector3.ZERO, P.madeira)
	_telhado(Vector3(0, 3.7, 0), 3.4, 3.4, 1.4, P.telhado, 0.7)
	_cil(0.55, 0.7, 1.4, 12, Vector3(0, 2.45, 0), Vector3.ZERO, Color(0.32, 0.45, 0.36))
	_esfera(0.56, Vector3(0, 3.15, 0), Vector3(1, 0.5, 1), Color(0.32, 0.45, 0.36), false, 10, 4)
	for k in 4:
		_toro(0.6, 0.72, Vector3(0, 1.95 + k * 0.3, 0), Vector3(1, 0.4, 1), Color(0.26, 0.36, 0.3))
	_cil(0.12, 0.12, 2.2, 6, Vector3(0, 2.0, 1.0), Vector3(0, 0, 90), P.madeira2)
	_caixa(Vector3(0.02, 0.8, 0.02), Vector3(-0.9, 2.5, 1.0), Vector3.ZERO, P.corda)
	_caixa(Vector3(0.02, 0.8, 0.02), Vector3(0.9, 2.5, 1.0), Vector3.ZERO, P.corda)


## Torre de vigia de madeira em estacas, com escada de mão.
func _vigia() -> void:
	for x in [-1.1, 1.1]:
		for z in [-1.1, 1.1]:
			_cil(0.12, 0.15, 5.4, 6, Vector3(x * 0.95, 2.7, z * 0.95), Vector3(-z * 3, 0, x * 3), P.madeira)
	for y in [1.6, 3.2]:
		for s in [-1, 1]:
			_caixa(Vector3(2.3, 0.1, 0.1), Vector3(0, y, s * 1.0), Vector3(0, 0, 40 * s), P.madeira2)
			_caixa(Vector3(0.1, 0.1, 2.3), Vector3(s * 1.0, y, 0), Vector3(40 * s, 0, 0), P.madeira2)
	_caixa(Vector3(2.8, 0.2, 2.8), Vector3(0, 5.4, 0), Vector3.ZERO, P.madeira2)
	for s in [-1, 1]:
		_caixa(Vector3(2.8, 0.7, 0.08), Vector3(0, 5.85, s * 1.4), Vector3.ZERO, P.madeira)
		_caixa(Vector3(0.08, 0.7, 2.8), Vector3(s * 1.4, 5.85, 0), Vector3.ZERO, P.madeira)
	for x in [-1.3, 1.3]:
		for z in [-1.3, 1.3]:
			_cil(0.05, 0.05, 1.6, 5, Vector3(x, 6.3, z), Vector3.ZERO, P.madeira)
	_telhado(Vector3(0, 7.1, 0), 3.0, 3.0, 1.0, P.telhado, 0.4)
	for k in 9:
		_caixa(Vector3(0.6, 0.06, 0.06), Vector3(0, 0.5 + k * 0.6, 1.3), Vector3.ZERO, P.madeira2)
	for s in [-1, 1]:
		_caixa(Vector3(0.06, 5.4, 0.06), Vector3(s * 0.3, 2.7, 1.32), Vector3.ZERO, P.madeira)
	_lanterna_papel(Vector3(1.2, 6.5, 1.2), P.papel)
	_caixa(Vector3(0.5, 0.15, 0.6), Vector3(-0.8, 5.6, -0.8), Vector3.ZERO, P.corda)  # sacos de flecha


func _jardim() -> void:
	_caixa(Vector3(7, 0.1, 5), Vector3(0, 0.05, 0), Vector3.ZERO, Color(0.74, 0.72, 0.7))
	for k in 14:
		_caixa(Vector3(6.8, 0.03, 0.05), Vector3(0, 0.11, -2.3 + k * 0.35), Vector3.ZERO, Color(0.6, 0.58, 0.56))
	for p in [Vector3(-1.8, 0.45, -0.6), Vector3(1.5, 0.55, 0.8), Vector3(0.4, 0.35, -1.4)]:
		_esfera(0.75, p, Vector3(1, 0.8, 0.8), P.pedra, false, 7, 4)
		_esfera(0.5, p + Vector3(0, 0.4, 0), Vector3(1.1, 0.3, 0.9), P.musgo, false, 6, 3)
		for k in 3:
			_toro(0.8 + k * 0.3, 0.85 + k * 0.3, Vector3(p.x, 0.12, p.z), Vector3(1, 0.05, 0.85), Color(0.6, 0.58, 0.56))
	for s in [-1, 1]:
		_caixa(Vector3(7.3, 0.3, 0.3), Vector3(0, 0.15, s * 2.6), Vector3.ZERO, P.madeira)
		_caixa(Vector3(0.3, 0.3, 5.5), Vector3(s * 3.6, 0.15, 0), Vector3.ZERO, P.madeira)
	_vaso(Vector3(3.2, 0.1, 2.0))
	_toro_mini(Vector3(-3.0, 0.1, 1.9))


## Barricada de estacas (cobertura no meio do mapa).
func _barricada() -> void:
	for k in 6:
		var x := -2.5 + k
		_cil(0.0, 0.12, 2.4, 6, Vector3(x, 0.75, 0.4), Vector3(-48, 0, 0), P.madeira2)
		_cil(0.0, 0.12, 2.4, 6, Vector3(x + 0.5, 0.75, -0.4), Vector3(48, 0, 0), P.madeira2.darkened(0.1))
		_esfera(0.05, Vector3(x, 1.6, 1.2), Vector3.ONE, P.madeira, false, 4, 2)
	_cil(0.13, 0.13, 6.0, 7, Vector3(0, 0.75, 0), Vector3(0, 0, 90), P.madeira)
	for x in [-2.0, 0.5, 2.5]:
		_toro(0.14, 0.2, Vector3(x, 0.75, 0), Vector3(0.3, 1, 1), P.corda)
	_caixa(Vector3(0.3, 0.5, 0.03), Vector3(0.2, 1.0, 0.16), Vector3.ZERO, P.branco, true)
	for k in 3:
		_caixa(Vector3(0.6, 0.45, 0.5), Vector3(-1.5 + k * 1.4, 0.22, -1.0), Vector3(0, k * 20, 0), P.corda.lightened(0.05))


## Árvore-espírito gigante: raízes, corda sagrada e orbes de fogo-fantasma.
func _arvore_espirito() -> void:
	_cil(1.0, 1.7, 5.5, 10, Vector3(0, 2.75, 0), Vector3.ZERO, P.tronco)
	for k in 5:
		var a := TAU * k / 5.0
		_cil(0.2, 0.55, 3.2, 7, Vector3(cos(a) * 1.4, 6.0, sin(a) * 1.4), Vector3(sin(a) * 35, 0, -cos(a) * 35), P.tronco)
		_esfera(2.1, Vector3(cos(a) * 2.9, 7.6 + (k % 2) * 0.6, sin(a) * 2.9), Vector3(1, 0.62, 1), P.folha2 if k % 2 else P.folha, false, 9, 5)
		_esfera(0.2, Vector3(cos(a + 0.5) * 3.3, 5.5, sin(a + 0.5) * 3.3), Vector3(1, 1.4, 1), P.luz1 if k % 2 else P.luz2, true, 7, 4)
		_caixa(Vector3(0.02, 0.9, 0.02), Vector3(cos(a + 0.5) * 3.3, 6.2, sin(a + 0.5) * 3.3), Vector3.ZERO, P.corda)
	_esfera(2.6, Vector3(0, 8.9, 0), Vector3(1, 0.6, 1), P.folha, false, 9, 5)
	_toro(1.55, 1.85, Vector3(0, 2.4, 0), Vector3(1, 0.6, 1), P.corda)
	for k in 8:
		var a := TAU * k / 8.0
		_caixa(Vector3(0.14, 0.4, 0.03), Vector3(cos(a) * 1.85, 2.0, sin(a) * 1.85), Vector3(0, -rad_to_deg(a) + 90, 0), P.branco, true)
		_cil(0.2, 0.45, 1.8, 6, Vector3(cos(a) * 1.9, 0.3, sin(a) * 1.9), Vector3(sin(a) * 70, 0, -cos(a) * 70), P.tronco)
	_caixa(Vector3(1.4, 0.5, 0.8), Vector3(0, 0.25, 2.2), Vector3.ZERO, P.pedra)
	for k in 3:
		_cil(0.04, 0.04, 0.2, 5, Vector3(-0.4 + k * 0.4, 0.6, 2.2), Vector3.ZERO, P.branco)
		_esfera(0.05, Vector3(-0.4 + k * 0.4, 0.75, 2.2), Vector3(1, 1.5, 1), P.luz1, true, 5, 3)


func _jizos() -> void:
	_caixa(Vector3(6.4, 0.25, 1.2), Vector3(0, 0.12, 0), Vector3.ZERO, P.pedra2)
	for k in 5:
		var x := -2.4 + k * 1.2
		_caixa(Vector3(0.8, 0.3, 0.8), Vector3(x, 0.4, 0), Vector3.ZERO, P.pedra2)
		_cil(0.25, 0.32, 0.9, 8, Vector3(x, 1.0, 0), Vector3.ZERO, P.pedra)
		_esfera(0.26, Vector3(x, 1.65, 0), Vector3.ONE, P.pedra, false, 8, 5)
		_cil(0.33, 0.37, 0.3, 8, Vector3(x, 1.35, 0.02), Vector3.ZERO, Color(0.85, 0.12, 0.12))
		_cil(0.29, 0.28, 0.06, 8, Vector3(x, 1.95, 0), Vector3.ZERO, Color(0.85, 0.12, 0.12))
		_cil(0.03, 0.03, 0.18, 5, Vector3(x + 0.3, 0.64, 0.45), Vector3.ZERO, P.branco)
		_esfera(0.045, Vector3(x + 0.3, 0.77, 0.45), Vector3(1, 1.6, 1), P.luz1, true, 5, 3)
		_esfera(0.08, Vector3(x - 0.25, 0.6, 0.45), Vector3.ONE, P.ouro, false, 5, 3)
	for k in 6:  # cata-ventos coloridos
		var x := -3.0 + k * 1.2
		_cil(0.015, 0.015, 0.7, 3, Vector3(x, 0.6, -0.5), Vector3.ZERO, P.madeira)
		_cil(0.12, 0.12, 0.02, 6, Vector3(x, 0.95, -0.5), Vector3(90, 0, 0), [P.torii, P.luz1, P.ouro][k % 3])


## Bambuzal denso (parede que dá cobertura).
func _bambuzal() -> void:
	for k in 22:
		var a := k * 2.39
		var r := 0.3 + fmod(k * 0.618, 1.0) * 2.0
		var h := 6.0 + fmod(k * 0.53, 1.0) * 4.0
		_bambu(Vector3(cos(a) * r * 1.6, 0, sin(a) * r * 0.7), h, Vector3(sin(k) * 5, 0, cos(k * 1.3) * 5))
	for k in 6:
		_esfera(1.5, Vector3(-2.5 + k, 7.5 + (k % 2), (k % 3 - 1) * 0.6), Vector3(1, 0.5, 1), P.folha if k % 2 else P.folha2, false, 7, 4)
	for k in 8:
		_esfera(0.4, Vector3(-3 + k * 0.85, 0.15, (k % 2) * 0.8 - 0.4), Vector3(1, 0.4, 1), P.musgo, false, 6, 3)


## Pilha de caixas e barris (cobertura baixa).
func _pilha() -> void:
	for k in 3:
		_caixa(Vector3(1.0, 1.0, 1.0), Vector3(-0.6 + k * 1.05, 0.5, 0), Vector3(0, k * 7, 0), P.madeira2)
		_caixa(Vector3(1.02, 0.1, 1.02), Vector3(-0.6 + k * 1.05, 0.5, 0), Vector3(0, k * 7, 0), P.madeira)
	_caixa(Vector3(0.9, 0.9, 0.9), Vector3(0, 1.45, 0.05), Vector3(0, 15, 0), P.madeira2)
	for k in 2:
		_cil(0.42, 0.42, 0.9, 10, Vector3(1.0 + k * 0.85, 0.45, 1.0), Vector3.ZERO, P.madeira2.darkened(0.1))
		_cil(0.44, 0.44, 0.07, 10, Vector3(1.0 + k * 0.85, 0.65, 1.0), Vector3.ZERO, P.corda)
	_caixa(Vector3(1.4, 0.06, 0.9), Vector3(0, 1.93, 0.05), Vector3(0, 15, 6), P.torii.darkened(0.2))


# --- Aldeões (moradores parados, parte do modelo) ------------------------------

const PELE := Color(0.93, 0.76, 0.62)
const CABELO := Color(0.08, 0.06, 0.08)


## Morador low-poly (~1,6 m) em `pos`, virado para `rot_y` (0 = olha para +z).
## pose: parado, vender, varrer, martelar, sentado, lanterna, remar, treinar, servir.
func _aldeao(pos: Vector3, rot_y: float, roupa: Color, pose := "parado", chapeu := false, obi := Color(-1, 0, 0)) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(rot_y))
	var faixa := obi if obi.r >= 0.0 else roupa.lerp(P.ouro, 0.6)
	var sentado := pose == "sentado" or pose == "servir"
	var dy := -0.5 if sentado else 0.0
	if sentado:
		# Pernas dobradas para a frente (seiza/sentado na varanda).
		_caixa(Vector3(0.46, 0.22, 0.5), pos + b * Vector3(0, 0.11, 0.12), Vector3(0, rot_y, 0), roupa.darkened(0.35))
	else:
		_cil(0.19, 0.3, 0.78, 7, pos + b * Vector3(0, 0.39, 0), Vector3(0, rot_y, 0), roupa.darkened(0.35))
		for s in [-1.0, 1.0]:
			_caixa(Vector3(0.1, 0.06, 0.22), pos + b * Vector3(s * 0.1, 0.03, 0.06), Vector3(0, rot_y, 0), Color(0.1, 0.08, 0.07))
	_cil(0.2, 0.21, 0.58, 7, pos + b * Vector3(0, 1.06 + dy, 0), Vector3(0, rot_y, 0), roupa)
	_cil(0.215, 0.215, 0.12, 7, pos + b * Vector3(0, 0.86 + dy, 0), Vector3(0, rot_y, 0), faixa)
	for s in [-1.0, 1.0]:  # gola cruzada
		_caixa(Vector3(0.05, 0.36, 0.02), pos + b * Vector3(s * 0.05, 1.2 + dy, 0.2), Vector3(0, rot_y, s * 24.0), P.branco.darkened(0.1))
	_esfera(0.15, pos + b * Vector3(0, 1.5 + dy, 0.01), Vector3.ONE, PELE, false, 8, 5)
	_esfera(0.155, pos + b * Vector3(0, 1.55 + dy, -0.03), Vector3(1, 0.8, 1), CABELO, false, 8, 4)
	_esfera(0.07, pos + b * Vector3(0, 1.69 + dy, -0.08), Vector3.ONE, CABELO, false, 6, 3)
	for s in [-1.0, 1.0]:
		_esfera(0.022, pos + b * Vector3(s * 0.055, 1.52 + dy, 0.145), Vector3.ONE, Color(0.05, 0.04, 0.05), false, 4, 2)
	if chapeu:
		_cil(0.0, 0.4, 0.22, 8, pos + b * Vector3(0, 1.74 + dy, 0), Vector3(0, rot_y, 0), P.corda)
	# Braços: [inclinação para a frente (graus, negativo = à frente), abertura].
	var bracos := {
		"parado": [[0.0, 8.0], [0.0, 8.0]], "vender": [[-55.0, 6.0], [-55.0, 6.0]],
		"varrer": [[-35.0, 4.0], [-50.0, 18.0]], "martelar": [[-35.0, 6.0], [-150.0, 10.0]],
		"sentado": [[-30.0, 6.0], [-30.0, 6.0]], "lanterna": [[0.0, 8.0], [-70.0, 4.0]],
		"remar": [[-40.0, 10.0], [-25.0, 25.0]], "treinar": [[-90.0, 4.0], [-90.0, 4.0]],
		"servir": [[-65.0, 4.0], [-65.0, 4.0]],
	}
	var mao := Vector3.ZERO
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var ang: Array = bracos.get(pose, bracos["parado"])[i]
		var ba := Basis.from_euler(Vector3(deg_to_rad(ang[0]), 0, deg_to_rad(-s * ang[1])))
		var ombro := Vector3(s * 0.25, 1.3 + dy, 0)
		_cil(0.07, 0.1, 0.5, 6, pos + b * (ombro + ba * Vector3(0, -0.25, 0)), Vector3(ang[0], rot_y, -s * ang[1]), roupa.lightened(0.05))
		mao = ombro + ba * Vector3(0, -0.53, 0)
		_esfera(0.055, pos + b * mao, Vector3.ONE, PELE, false, 5, 3)
		if i == 0:
			continue
		# Objeto na mão direita, conforme a pose.
		match pose:
			"varrer":
				_cil(0.025, 0.025, 1.4, 4, pos + b * (mao + Vector3(-0.15, -0.35, 0.25)), Vector3(-30, rot_y, 25), P.madeira2)
				_caixa(Vector3(0.35, 0.25, 0.08), pos + b * (mao + Vector3(-0.42, -0.95, 0.6)), Vector3(-10, rot_y, 0), P.corda)
			"martelar":
				_cil(0.025, 0.025, 0.45, 4, pos + b * (mao + Vector3(0, 0.2, 0)), Vector3(0, rot_y, 0), P.madeira)
				_caixa(Vector3(0.22, 0.12, 0.12), pos + b * (mao + Vector3(0, 0.45, 0)), Vector3(0, rot_y, 0), Color(0.25, 0.25, 0.3))
			"lanterna":
				_lanterna_papel(pos + b * (mao + Vector3(0, -0.28, 0.05)), P.papel, 0.13)
			"remar":
				_cil(0.025, 0.025, 2.6, 4, pos + b * (mao + Vector3(0.2, -0.5, 0)), Vector3(0, rot_y, -20), P.madeira2)
			"treinar":
				_cil(0.022, 0.03, 1.0, 5, pos + b * (mao + Vector3(0.05, 0.1, 0.45)), Vector3(70, rot_y, 0), P.madeira2.lightened(0.2))
			"servir":
				_cil(0.06, 0.05, 0.08, 6, pos + b * (mao + Vector3(-0.12, 0.04, 0.02)), Vector3(0, rot_y, 0), P.musgo.lightened(0.3))


## Grupo de moradores conversando (enfeite sem colisão).
func _aldeoes() -> void:
	_aldeao(Vector3(-0.6, 0, 0), 60.0, P.telhado.lightened(0.15), "parado", true)
	_aldeao(Vector3(0.5, 0, 0.4), -110.0, P.torii.lightened(0.1), "lanterna")
	_aldeao(Vector3(0.1, 0, -0.6), 170.0, P.musgo.lightened(0.15), "vender")
	_caixa(Vector3(0.5, 0.35, 0.4), Vector3(-0.2, 0.17, 0.9), Vector3(0, 20, 0), P.madeira2)  # cesto
	_esfera(0.12, Vector3(-0.25, 0.42, 0.9), Vector3.ONE, P.ouro, false, 5, 3)


## Lanterna de pedra (ishidoro) em qualquer posição e escala.
func _ishidoro(pos: Vector3, e := 1.0) -> void:
	_cil(0.35 * e, 0.42 * e, 0.2 * e, 6, pos + Vector3(0, 0.1 * e, 0), Vector3.ZERO, P.pedra2)
	_cil(0.12 * e, 0.14 * e, 0.8 * e, 6, pos + Vector3(0, 0.6 * e, 0), Vector3.ZERO, P.pedra)
	_cil(0.3 * e, 0.22 * e, 0.12 * e, 6, pos + Vector3(0, 1.06 * e, 0), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(0.36, 0.3, 0.36) * e, pos + Vector3(0, 1.27 * e, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(0.2, 0.2, 0.38) * e, pos + Vector3(0, 1.27 * e, 0), Vector3.ZERO, P.luz1, true)
	_caixa(Vector3(0.38, 0.2, 0.2) * e, pos + Vector3(0, 1.27 * e, 0), Vector3.ZERO, P.luz1, true)
	_cil(0.05 * e, 0.42 * e, 0.28 * e, 6, pos + Vector3(0, 1.56 * e, 0), Vector3.ZERO, P.pedra)
	_esfera(0.07 * e, pos + Vector3(0, 1.74 * e, 0), Vector3.ONE, P.pedra, false, 5, 3)


## Fundos e lateral de uma casa (frente em +z): janelas, porta, calha, varal,
## barril de chuva e lenha. `andares` = alturas (centro) das janelas de trás.
func _fundos(w: float, d: float, andares: Array, recuo := 0.0) -> void:
	var z := -d / 2 - 0.03 + recuo
	for k in andares.size():
		var y: float = andares[k]
		var largura := minf(w * 0.35, 1.6) if k == 0 else minf(w * 0.3, 1.3)
		_shoji(Vector3(w * 0.22, y, z), largura, 0.9, -1, P.papel if k % 2 == 0 else P.luz1.lerp(P.papel, 0.5))
		_caixa(Vector3(largura + 0.3, 0.08, 0.3), Vector3(w * 0.22, y + 0.6, z - 0.15), Vector3(20, 0, 0), P.telhado.darkened(0.15))
	# Porta dos fundos.
	_caixa(Vector3(0.9, 1.8, 0.06), Vector3(-w * 0.25, 1.2, z - 0.02), Vector3.ZERO, Color(0.1, 0.08, 0.07))
	_caixa(Vector3(1.1, 0.12, 0.12), Vector3(-w * 0.25, 2.15, z - 0.05), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.7, 0.5, 0.04), Vector3(-w * 0.25, 1.75, z - 0.07), Vector3.ZERO, P.torii.lightened(0.1))  # noren
	# Calha de bambu e barril de chuva.
	_cil(0.05, 0.05, 2.4, 5, Vector3(w / 2 - 0.2, 1.4, z - 0.12), Vector3.ZERO, P.bambu)
	_cil(0.3, 0.3, 0.7, 8, Vector3(w / 2 - 0.25, 0.35, z - 0.45), Vector3.ZERO, P.madeira2)
	_cil(0.31, 0.31, 0.05, 8, Vector3(w / 2 - 0.25, 0.55, z - 0.45), Vector3.ZERO, P.corda)
	_cil(0.27, 0.27, 0.02, 8, Vector3(w / 2 - 0.25, 0.71, z - 0.45), Vector3.ZERO, P.agua.lightened(0.2), true)
	# Varal com roupas coloridas.
	for x in [-w / 2 + 0.3, -w * 0.25 + 0.9]:
		_cil(0.03, 0.03, 1.7, 4, Vector3(x, 0.85, z - 1.0), Vector3.ZERO, P.madeira)
	var cores := [P.luz2, P.branco, P.torii, P.telhado.lightened(0.3)]
	var x0 := -w / 2 + 0.3
	var x1 := -w * 0.25 + 0.9
	_cil(0.01, 0.01, x1 - x0, 3, Vector3((x0 + x1) / 2, 1.65, z - 1.0), Vector3(0, 0, 90), P.corda)
	for k in 3:
		_caixa(Vector3(0.36, 0.5, 0.02), Vector3(x0 + 0.25 + k * (x1 - x0 - 0.5) / 2.0, 1.38, z - 1.0), Vector3(0, 0, (k - 1) * 3), cores[k % 4])
	# Lenha e caixotes encostados.
	for k in 3:
		_cil(0.1, 0.1, 0.9, 5, Vector3(w * 0.1 + k * 0.05, 0.12 + k * 0.18, z - 0.3), Vector3(0, 0, 90), P.madeira2.darkened(0.05 * k))
	_caixa(Vector3(0.6, 0.5, 0.5), Vector3(w * 0.38, 0.25, z - 0.35), Vector3(0, 12, 0), P.madeira2)
	# Lateral (+x): janela pequena com grade e uma lanterna.
	_caixa(Vector3(0.04, 0.7, 0.9), Vector3(w / 2 + 0.02, 1.5, -d * 0.1 + recuo * 0.5), Vector3.ZERO, P.papel, true)
	for k in 4:
		_caixa(Vector3(0.06, 0.7, 0.04), Vector3(w / 2 + 0.05, 1.5, -d * 0.1 - 0.35 + k * 0.23 + recuo * 0.5), Vector3.ZERO, P.madeira)
	_lanterna_papel(Vector3(-w / 2 - 0.15, 2.0, -d * 0.2 + recuo * 0.5), P.luz2, 0.15)


# --- Leva 2: templo, casa de chá, barco, ponte de corda, forja, dojo --------------

## Templo (hondo) 8 x 6,5 m em plataforma de pedra, frente em +z.
func _templo() -> void:
	_caixa(Vector3(8.4, 0.45, 6.6), Vector3(0, 0.22, 0), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(7.8, 0.45, 6.0), Vector3(0, 0.67, -0.1), Vector3.ZERO, P.pedra)
	for k in 3:  # escadaria
		_caixa(Vector3(3.2, 0.3, 0.4), Vector3(0, 0.15 + k * 0.3, 3.5 - k * 0.4), Vector3.ZERO, P.pedra if k % 2 else P.pedra2)
	_caixa(Vector3(6.4, 2.6, 4.2), Vector3(0, 2.2, -0.6), Vector3.ZERO, P.madeira2)
	_caixa(Vector3(7.4, 0.14, 1.3), Vector3(0, 0.96, 2.05), Vector3.ZERO, P.madeira)  # varanda
	for k in 6:
		var x := -3.3 + k * 1.32
		_cil(0.15, 0.17, 2.9, 8, Vector3(x, 2.4, 2.55), Vector3.ZERO, P.torii)
		_cil(0.2, 0.2, 0.12, 8, Vector3(x, 1.05, 2.55), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(7.2, 0.22, 0.25), Vector3(0, 3.7, 2.55), Vector3.ZERO, P.torii)
	_caixa(Vector3(7.2, 0.12, 0.2), Vector3(0, 3.35, 2.55), Vector3.ZERO, P.ouro)
	for x in [-2.2, 2.2]:
		_shoji(Vector3(x, 2.1, 1.52), 1.8, 1.9, 1, P.papel)
	_caixa(Vector3(2.0, 2.0, 0.05), Vector3(0, 2.05, 1.5), Vector3.ZERO, Color(0.08, 0.05, 0.05))  # porta aberta
	_caixa(Vector3(0.9, 1.0, 0.3), Vector3(0, 1.75, 0.9), Vector3.ZERO, P.ouro, true)  # altar ao fundo
	_esfera(0.3, Vector3(0, 2.45, 0.9), Vector3(1, 1.2, 1), P.ouro, true, 7, 4)
	# Caixa de oferendas e corda sagrada com papéis shide.
	_caixa(Vector3(1.5, 0.55, 0.6), Vector3(0, 1.3, 2.25), Vector3.ZERO, P.madeira)
	for k in 6:
		_caixa(Vector3(0.05, 0.03, 0.6), Vector3(-0.6 + k * 0.24, 1.59, 2.25), Vector3.ZERO, Color(0.1, 0.08, 0.07))
	_cil(0.13, 0.13, 3.6, 7, Vector3(0, 3.15, 2.7), Vector3(0, 0, 90), P.corda)
	for k in 5:
		var x := -1.4 + k * 0.7
		for j in 3:
			_caixa(Vector3(0.14, 0.14, 0.02), Vector3(x + (j % 2) * 0.06, 2.9 - j * 0.13, 2.75), Vector3.ZERO, P.branco, true)
	_lanterna_papel(Vector3(0, 2.6, 2.8), P.luz2, 0.42)
	for x in [-2.6, 2.6]:
		_lanterna_papel(Vector3(x, 2.9, 2.75), P.papel, 0.2)
	# Telhado em dois níveis.
	_telhado(Vector3(0, 3.85, -0.1), 8.6, 6.2, 0.9, P.telhado, 0.75)
	_caixa(Vector3(5.0, 1.0, 3.2), Vector3(0, 5.15, -0.4), Vector3.ZERO, P.madeira2)
	for k in 7:
		_caixa(Vector3(0.12, 0.6, 0.04), Vector3(-1.8 + k * 0.6, 5.15, 1.22), Vector3.ZERO, P.madeira)
	_caixa(Vector3(4.0, 0.6, 0.03), Vector3(0, 5.15, 1.2), Vector3.ZERO, P.papel, true)
	_telhado(Vector3(0, 5.65, -0.4), 6.6, 4.6, 1.9, P.telhado, 0.8)
	for x in [-1.7, 1.7]:  # enfeites dourados na cumeeira
		_caixa(Vector3(0.25, 0.5, 0.2), Vector3(x, 7.75, -0.4), Vector3(0, 0, -x * 12), P.ouro, true)
	# Barris de saquê oferecidos, incensário e lanternas de pedra.
	for k in 6:
		var fila := 0 if k < 3 else 1
		var col := k if k < 3 else k - 3
		if fila == 1 and col == 2:
			continue
		var p := Vector3(-3.4 + col * 0.62 + fila * 0.31, 1.18 + fila * 0.52, 0.6)
		_cil(0.3, 0.3, 0.52, 8, p, Vector3(90, 0, 0), P.branco.darkened(0.1))
		_cil(0.31, 0.31, 0.1, 8, p, Vector3(90, 0, 0), P.torii)
	_cil(0.35, 0.45, 0.4, 8, Vector3(0, 0.2, 4.7), Vector3.ZERO, P.pedra2)
	_esfera(0.45, Vector3(0, 0.75, 4.7), Vector3(1, 0.7, 1), Color(0.22, 0.2, 0.18), false, 8, 4)
	_cil(0.32, 0.32, 0.05, 8, Vector3(0, 0.98, 4.7), Vector3.ZERO, P.luz1, true)
	for k in 3:
		_cil(0.012, 0.012, 0.35, 3, Vector3(-0.12 + k * 0.12, 1.15, 4.7), Vector3.ZERO, P.ouro)
	for x in [-3.0, 3.0]:
		_ishidoro(Vector3(x, 0, 4.3))
	_aldeao(Vector3(2.0, 0, 4.9), -70.0, Color(0.95, 0.55, 0.15), "varrer")


## Casa de chá (chashitsu) com jardim seco, bacia de pedra e bordo vermelho.
func _casa_de_cha() -> void:
	_caixa(Vector3(3.6, 0.35, 3.4), Vector3(0, 0.17, -0.6), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(3.2, 2.0, 3.0), Vector3(0, 1.35, -0.6), Vector3.ZERO, P.reboco.darkened(0.08))
	for x in [-1.6, -0.5, 0.5, 1.6]:
		_cil(0.07, 0.08, 2.1, 6, Vector3(x, 1.4, 0.9), Vector3.ZERO, P.tronco)
	_cil(0.5, 0.5, 0.04, 14, Vector3(-0.8, 1.5, 0.92), Vector3(90, 0, 0), P.papel, true)  # janela redonda
	for k in 3:
		_caixa(Vector3(0.03, 0.9, 0.03), Vector3(-1.1 + k * 0.3, 1.5, 0.95), Vector3.ZERO, P.bambu)
	_caixa(Vector3(0.7, 0.75, 0.05), Vector3(0.75, 0.75, 0.92), Vector3.ZERO, Color(0.1, 0.07, 0.06))  # porta baixa
	_caixa(Vector3(3.6, 0.1, 0.9), Vector3(0, 0.55, 1.35), Vector3.ZERO, P.madeira2)  # varanda
	var casca := Color(0.3, 0.22, 0.18) if P.arvore == "bambu" else Color(0.5, 0.36, 0.26)
	_telhado(Vector3(0, 2.35, -0.3), 4.2, 4.0, 1.5, casca, 0.4)
	_aldeao(Vector3(0.6, 0.6, 1.4), 0.0, P.musgo.lightened(0.2), "servir", false, P.branco)
	_caixa(Vector3(0.5, 0.06, 0.4), Vector3(-0.2, 0.62, 1.45), Vector3.ZERO, Color(0.12, 0.08, 0.06))  # bandeja
	_cil(0.07, 0.06, 0.1, 7, Vector3(-0.3, 0.7, 1.45), Vector3.ZERO, P.musgo.lightened(0.3))
	_cil(0.09, 0.09, 0.14, 7, Vector3(-0.05, 0.72, 1.45), Vector3.ZERO, Color(0.2, 0.18, 0.16))
	# Pedras de pisar, bacia tsukubai com bica de bambu, lanterna e bordo.
	for k in 5:
		_cil(0.28, 0.3, 0.08, 7, Vector3(0.9 + sin(k * 1.3) * 0.4, 0.04, 2.0 + k * 0.55), Vector3.ZERO, P.pedra)
	_cil(0.4, 0.45, 0.45, 8, Vector3(-1.3, 0.22, 2.6), Vector3.ZERO, P.pedra)
	_cil(0.3, 0.3, 0.03, 8, Vector3(-1.3, 0.45, 2.6), Vector3.ZERO, P.agua.lightened(0.3), true)
	_cil(0.04, 0.04, 0.9, 5, Vector3(-1.75, 0.65, 2.6), Vector3(0, 0, 70), P.bambu)
	_cil(0.04, 0.04, 0.6, 5, Vector3(-2.15, 0.35, 2.6), Vector3.ZERO, P.bambu)
	_ishidoro(Vector3(1.9, 0, 2.6), 0.7)
	_cil(0.08, 0.12, 1.6, 6, Vector3(-2.2, 0.8, 0.6), Vector3(0, 0, 8), P.tronco)
	var bordo := Color(0.9, 0.22, 0.18) if P.arvore == "bambu" else Color(0.95, 0.35, 0.25)
	for k in 4:
		_esfera(0.55, Vector3(-2.3 + (k % 2) * 0.5, 1.8 + k * 0.2, 0.4 + (k / 2) * 0.5), Vector3(1, 0.7, 1), bordo.darkened(0.08 * k), false, 7, 4)
	for k in 10:  # cascalho rastelado
		_caixa(Vector3(2.6, 0.02, 0.04), Vector3(-0.2, 0.02, 1.9 + k * 0.12), Vector3.ZERO, Color(0.7, 0.68, 0.66))
	_cerca_baixa(Vector3(0, 0, 3.3), 4.6)


func _cerca_baixa(pos: Vector3, comp: float) -> void:
	var n := int(comp / 0.25)
	for k in n:
		_cil(0.03, 0.03, 0.5, 4, pos + Vector3(-comp / 2 + k * 0.25, 0.25, 0), Vector3.ZERO, P.bambu)
	_cil(0.025, 0.025, comp, 4, pos + Vector3(0, 0.4, 0), Vector3(0, 0, 90), P.bambu.darkened(0.2))


## Barco de rio (5 m em x) com cobertura, lanterna e barqueiro.
func _barco() -> void:
	var casco: Color = P.madeira2
	_caixa(Vector3(4.0, 0.35, 1.3), Vector3(0, 0.2, 0), Vector3.ZERO, casco.darkened(0.1))
	for s in [-1.0, 1.0]:
		_caixa(Vector3(4.2, 0.5, 0.1), Vector3(0, 0.4, s * 0.68), Vector3(s * 12.0, 0, 0), casco)
		_caixa(Vector3(1.0, 0.5, 0.1), Vector3(s * 2.35, 0.55, 0.0), Vector3(0, 90, s * 25.0), casco)
	_caixa(Vector3(0.9, 0.1, 1.4), Vector3(2.4, 0.75, 0), Vector3(0, 0, 25), casco.darkened(0.15))
	_caixa(Vector3(0.9, 0.1, 1.4), Vector3(-2.4, 0.75, 0), Vector3(0, 0, -25), casco.darkened(0.15))
	for x in [-1.3, 0.5]:
		for z in [-0.6, 0.6]:
			_cil(0.04, 0.04, 1.2, 4, Vector3(x, 1.0, z), Vector3.ZERO, P.bambu.darkened(0.25))
	_caixa(Vector3(1.8, 0.06, 1.3), Vector3(-0.4, 1.58, 0), Vector3.ZERO, P.corda.darkened(0.25))
	for s in [-1.0, 1.0]:
		_caixa(Vector3(1.8, 0.6, 0.04), Vector3(-0.4, 1.3, s * 0.62), Vector3(s * 10.0, 0, 0), P.corda.darkened(0.15))
	_caixa(Vector3(0.6, 0.4, 0.5), Vector3(-0.6, 0.55, 0.1), Vector3(0, 10, 0), P.madeira)
	_cil(0.2, 0.2, 0.4, 7, Vector3(0.2, 0.55, -0.2), Vector3.ZERO, P.branco.darkened(0.1))
	_cil(0.03, 0.03, 1.6, 4, Vector3(-2.1, 1.3, 0), Vector3(0, 0, -15), P.madeira)
	_lanterna_papel(Vector3(-2.45, 1.75, 0), P.luz2, 0.18)
	_aldeao(Vector3(1.6, 0.35, 0), -90.0, P.telhado.lightened(0.2), "remar", true)
	for k in 6:  # marolas brilhando em volta
		_esfera(0.18, Vector3(-2.6 + k * 1.05, 0.05, (0.85 if k % 2 else -0.85)), Vector3(2.2, 0.15, 0.6), P.agua.lightened(0.45), true, 6, 2)


## Ponte de corda pênsil (14 m em x), tábuas em catenária, lanternas penduradas.
func _ponte_corda() -> void:
	var meia := 7.0
	var alt := 4.6
	var flecha := 0.8
	for s in [-1.0, 1.0]:
		for z in [-0.75, 0.75]:
			_cil(0.13, 0.16, alt + 1.2, 6, Vector3(s * meia, (alt + 1.2) / 2, z), Vector3.ZERO, P.madeira)
		_caixa(Vector3(0.3, 0.25, 1.9), Vector3(s * meia, alt + 1.0, 0), Vector3.ZERO, P.madeira2)
		_cil(0.06, 0.06, 2.0, 4, Vector3(s * (meia + 0.9), alt * 0.5, 0.75), Vector3(0, 0, s * 40), P.corda)
		_lanterna_papel(Vector3(s * meia, alt + 1.45, 0), P.luz2, 0.2)
	var n := 40
	for k in n:
		var x := -meia + 2.0 * meia * (k + 0.5) / n
		var y := alt - flecha * (1.0 - pow(x / meia, 2.0))
		_caixa(Vector3(0.25, 0.06, 1.4), Vector3(x, y, 0), Vector3(0, 0, 0), P.madeira2 if k % 3 else P.madeira2.darkened(0.2))
	for z in [-0.72, 0.72]:
		for k in 14:
			var xa := -meia + 2.0 * meia * k / 14.0
			var xb := -meia + 2.0 * meia * (k + 1) / 14.0
			var ya := alt + 0.9 - flecha * (1.0 - pow(xa / meia, 2.0))
			var yb := alt + 0.9 - flecha * (1.0 - pow(xb / meia, 2.0))
			var meio := Vector3((xa + xb) / 2, (ya + yb) / 2, z)
			_cil(0.025, 0.025, Vector2(xb - xa, yb - ya).length(), 4, meio, Vector3(0, 0, 90 + rad_to_deg(atan2(yb - ya, xb - xa))), P.corda)
			if k % 2 == 0:
				_cil(0.012, 0.012, 0.9, 3, Vector3(xa, (ya + alt - flecha * (1.0 - pow(xa / meia, 2.0))) / 2.0, z), Vector3.ZERO, P.corda)
	for k in 3:
		var x := -3.5 + k * 3.5
		_lanterna_papel(Vector3(x, alt - flecha * (1.0 - pow(x / meia, 2.0)) - 0.45, 0.8), P.papel if k != 1 else P.luz2, 0.15)
	_aldeao(Vector3(2.2, alt - flecha * (1.0 - pow(2.2 / meia, 2.0)) + 0.03, 0), -90.0, P.torii.lightened(0.15), "lanterna", true)


## Forja (5 x 4 m) aberta na frente: fornalha acesa, bigorna, ferreiro e armas.
func _forja() -> void:
	var w := 5.0
	var d := 4.0
	_caixa(Vector3(w + 0.2, 0.2, d + 0.2), Vector3(0, 0.1, 0), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(w, 2.8, 0.25), Vector3(0, 1.5, -d / 2 + 0.12), Vector3.ZERO, P.madeira2)
	for s in [-1.0, 1.0]:
		_caixa(Vector3(0.25, 2.8, d), Vector3(s * (w / 2 - 0.12), 1.5, 0), Vector3.ZERO, P.madeira2)
		_cil(0.12, 0.14, 2.9, 6, Vector3(s * (w / 2 - 0.1), 1.45, d / 2 - 0.1), Vector3.ZERO, P.madeira)
	_caixa(Vector3(w + 0.1, 0.25, 0.25), Vector3(0, 2.9, d / 2 - 0.1), Vector3.ZERO, P.madeira)
	_telhado(Vector3(0, 3.05, 0), w + 0.4, d + 0.4, 1.2, P.telhado.darkened(0.15), 0.5)
	# Fornalha de pedra com brasa e chaminé.
	_caixa(Vector3(1.8, 1.1, 1.3), Vector3(-1.2, 0.75, -1.1), Vector3.ZERO, P.pedra)
	_caixa(Vector3(1.0, 0.45, 0.1), Vector3(-1.2, 0.85, -0.42), Vector3.ZERO, Color(1.0, 0.45, 0.12) * 1.6, true)
	_caixa(Vector3(1.3, 0.12, 0.9), Vector3(-1.2, 1.36, -1.1), Vector3.ZERO, Color(1.0, 0.35, 0.1) * 1.3, true)
	_cil(0.3, 0.4, 3.4, 6, Vector3(-1.4, 3.2, -1.4), Vector3.ZERO, P.pedra2)
	_cil(0.32, 0.32, 0.1, 6, Vector3(-1.4, 4.92, -1.4), Vector3.ZERO, Color(1.0, 0.5, 0.15), true)
	for k in 3:  # fumaça
		_esfera(0.4 + k * 0.15, Vector3(-1.4 + k * 0.25, 5.4 + k * 0.6, -1.4), Vector3(1, 0.7, 1), Color(0.45, 0.42, 0.5, 1).darkened(0.1 * k), false, 6, 3)
	# Bigorna, balde, pedra de amolar e rack de armas.
	_caixa(Vector3(0.4, 0.5, 0.35), Vector3(0.6, 0.45, 0.2), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.75, 0.2, 0.32), Vector3(0.6, 0.8, 0.2), Vector3.ZERO, Color(0.2, 0.2, 0.24))
	_caixa(Vector3(0.5, 0.04, 0.06), Vector3(0.55, 0.92, 0.2), Vector3.ZERO, Color(1.0, 0.55, 0.2) * 1.5, true)
	_aldeao(Vector3(0.6, 0.2, 0.95), 180.0, Color(0.3, 0.26, 0.3), "martelar", false, P.torii)
	_cil(0.28, 0.24, 0.5, 8, Vector3(1.7, 0.45, -0.2), Vector3.ZERO, P.madeira2)
	_cil(0.24, 0.24, 0.03, 8, Vector3(1.7, 0.7, -0.2), Vector3.ZERO, P.agua.lightened(0.2), true)
	_cil(0.4, 0.4, 0.12, 12, Vector3(1.6, 0.75, 1.2), Vector3(90, 0, 0), P.pedra)
	_caixa(Vector3(0.1, 0.6, 0.5), Vector3(1.6, 0.4, 1.2), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.12, 1.6, 2.2), Vector3(w / 2 - 0.35, 1.2, -0.2), Vector3.ZERO, P.madeira)
	for k in 5:
		var z := -1.1 + k * 0.45
		_caixa(Vector3(0.03, 1.1, 0.05), Vector3(w / 2 - 0.45, 1.3, z), Vector3(0, 0, 4), Color(0.75, 0.78, 0.85))
		_caixa(Vector3(0.05, 0.3, 0.08), Vector3(w / 2 - 0.45, 0.7, z), Vector3.ZERO, P.torii.darkened(0.3))
	_caixa(Vector3(2.4, 0.6, 0.05), Vector3(0, 2.45, d / 2 + 0.05), Vector3.ZERO, Color(0.06, 0.05, 0.07))
	_caixa(Vector3(1.8, 0.14, 0.06), Vector3(0, 2.45, d / 2 + 0.08), Vector3.ZERO, Color(1.0, 0.5, 0.2) * 1.4, true)
	for k in 6:  # faíscas paradas no ar
		_esfera(0.04, Vector3(0.4 + k * 0.08, 1.0 + fmod(k * 0.37, 0.5), 0.3 + fmod(k * 0.61, 0.4)), Vector3.ONE, Color(1.0, 0.7, 0.25) * 1.6, true, 4, 2)
	_fundos(w, d, [1.6])


## Dojo (8 x 6 m): piso elevado, portas abertas, pergaminho, alunos treinando
## e bonecos de madeira na frente.
func _dojo() -> void:
	var w := 8.0
	var d := 6.0
	_caixa(Vector3(w + 0.3, 0.6, d + 0.3), Vector3(0, 0.3, 0), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(w, 0.12, d), Vector3(0, 0.66, 0), Vector3.ZERO, P.madeira2.lightened(0.12))
	for k in 12:
		_caixa(Vector3(0.03, 0.02, d - 0.2), Vector3(-w / 2 + 0.3 + k * 0.65, 0.73, 0), Vector3.ZERO, P.madeira2)
	_caixa(Vector3(w, 2.8, 0.2), Vector3(0, 2.1, -d / 2 + 0.1), Vector3.ZERO, P.reboco)
	for s in [-1.0, 1.0]:
		_caixa(Vector3(0.2, 2.8, d), Vector3(s * (w / 2 - 0.1), 2.1, 0), Vector3.ZERO, P.reboco)
	for k in 5:
		_cil(0.13, 0.13, 2.9, 7, Vector3(-w / 2 + 0.15 + k * (w - 0.3) / 4.0, 2.15, d / 2 - 0.1), Vector3.ZERO, P.madeira)
	_caixa(Vector3(w + 0.1, 0.3, 0.25), Vector3(0, 3.5, d / 2 - 0.1), Vector3.ZERO, P.madeira)
	for s in [-1.0, 1.0]:  # portas de correr abertas
		_shoji(Vector3(s * 3.2, 1.9, d / 2 - 0.25), 1.5, 2.3, 1, P.papel.darkened(0.15))
	_caixa(Vector3(1.2, 1.7, 0.03), Vector3(0, 2.4, -d / 2 + 0.22), Vector3.ZERO, P.branco)  # pergaminho
	for k in 4:
		_caixa(Vector3(0.16, 0.16 + (k % 2) * 0.1, 0.02), Vector3(0, 2.9 - k * 0.32, -d / 2 + 0.24), Vector3(0, 0, k * 15), Color(0.05, 0.05, 0.06))
	_caixa(Vector3(2.6, 0.6, 0.5), Vector3(0, 1.0, -d / 2 + 0.45), Vector3.ZERO, P.madeira)  # kamiza
	for x in [-0.9, 0.9]:
		_cil(0.06, 0.08, 0.3, 6, Vector3(x, 1.45, -d / 2 + 0.45), Vector3.ZERO, P.luz1, true)
	for k in 6:  # rack de bokken na parede lateral
		_caixa(Vector3(0.04, 1.0, 0.05), Vector3(-w / 2 + 0.3, 1.6, -1.8 + k * 0.3), Vector3(0, 0, 8), P.madeira2.lightened(0.2))
	_aldeao(Vector3(0, 0.72, -1.7), 0.0, P.branco.darkened(0.15), "parado", false, Color(0.08, 0.06, 0.06))
	_aldeao(Vector3(-1.2, 0.72, 0.4), 180.0, P.branco, "treinar", false, Color(0.08, 0.06, 0.06))
	_aldeao(Vector3(1.3, 0.72, 0.6), 180.0, P.branco, "treinar", false, P.torii)
	_aldeao(Vector3(2.4, 0.72, 0.2), 200.0, P.branco.darkened(0.05), "treinar", false, P.ouro)
	_telhado(Vector3(0, 3.65, 0), w + 0.4, d + 0.4, 1.9, P.telhado, 0.7)
	_caixa(Vector3(2.2, 0.6, 0.08), Vector3(0, 4.05, d / 2 + 0.6), Vector3.ZERO, Color(0.06, 0.05, 0.07))
	_caixa(Vector3(1.7, 0.15, 0.1), Vector3(0, 4.05, d / 2 + 0.63), Vector3.ZERO, P.ouro, true)
	for k in 3:  # degraus
		_caixa(Vector3(2.0, 0.2, 0.35), Vector3(0, 0.1 + k * 0.2, d / 2 + 0.85 - k * 0.3), Vector3.ZERO, P.pedra)
	for x in [-3.0, 3.2]:  # bonecos de treino (mokujin) e estandartes
		_cil(0.16, 0.18, 1.7, 8, Vector3(x, 0.85, d / 2 + 1.8), Vector3.ZERO, P.madeira2)
		for y in [0.9, 1.3]:
			_cil(0.04, 0.04, 0.7, 5, Vector3(x, y, d / 2 + 2.0), Vector3(90, 0, 0), P.madeira)
		_cil(0.17, 0.17, 0.25, 8, Vector3(x, 1.3, d / 2 + 1.8), Vector3.ZERO, P.corda)
		_cil(0.03, 0.03, 3.4, 4, Vector3(x * 1.25, 1.7, d / 2 + 1.0), Vector3.ZERO, P.madeira)
		_caixa(Vector3(0.5, 2.2, 0.03), Vector3(x * 1.25 + 0.27, 2.2, d / 2 + 1.0), Vector3.ZERO, P.torii if x < 0 else P.telhado.lightened(0.25))
		_caixa(Vector3(0.12, 1.6, 0.04), Vector3(x * 1.25 + 0.27, 2.2, d / 2 + 1.02), Vector3.ZERO, P.branco, true)
	_fundos(w, d, [2.2])


# --- Mapa -------------------------------------------------------------------------

func _p(model: String, pos: Vector3, rot := 0.0, col := "nenhuma", raio := 1.0, alt := 2.0) -> Resource:
	var p: Resource = _MP.new()
	p.model = model
	p.position = pos
	p.scale = 1.0
	p.rotation_deg = rot
	p.collider = col
	p.collider_radius = raio
	p.collider_height = alt
	return p


## Colisor caixa sem modelo (rampa, plataforma, trava do rio).
func _caixa_col(pos: Vector3, rot: float, size: Vector3, offset: Vector3, giro := Vector3.ZERO) -> Resource:
	var p := _p("", pos, rot, "caixa")
	p.collider_size = size
	p.collider_offset = offset
	p.collider_rot = giro
	return p


## Rampa sólida de `comp` m subindo `alt` m no +x local (o modelo começa em x = 0).
func _rampa_col(pos: Vector3, rot: float, comp: float, alt: float, larg: float) -> Resource:
	var a := atan2(alt, comp)
	var L := sqrt(comp * comp + alt * alt)
	var t := 0.6
	var centro := Vector3(comp / 2 + t / 2 * sin(a), alt / 2 - t / 2 * cos(a), 0)
	return _caixa_col(pos, rot, Vector3(L, t, larg), centro, Vector3(0, 0, rad_to_deg(a)))


## Põe nos dois lados do rio (x e -x). `dir` = o objeto aponta para +x local
## (rampas): no lado espelhado ele gira meia volta.
func _dois_lados(lista: Array, model: String, pos: Vector3, rot := 0.0, col := "nenhuma", raio := 1.0, alt := 2.0, dir := false) -> void:
	lista.append(_p(model, pos, rot, col, raio, alt))
	lista.append(_p(model, Vector3(-pos.x, pos.y, pos.z), 180.0 - rot if dir else rot, col, raio, alt))


func _gerar_mapa_rio() -> void:
	_MP = load("res://scripts/data/map_prop.gd")
	var ML: Script = load("res://scripts/data/map_layout.gd")
	var m: Resource = ML.new()
	m.display_name = "Rio das Lanternas"
	m.castle_distance = 48.0
	m.half_width = 68.0
	m.half_depth = 36.0
	m.cake_area = Vector2(30, 30)
	m.road_width = 7.0
	m.wall_back = -16.0
	m.wall_front = 12.0
	m.wall_half_width = 16.0
	m.gate_half_width = 6.8
	m.keep_position = Vector2(-9, 0)
	m.tower_spots = PackedVector2Array([Vector2(12, -7.6), Vector2(12, 7.6)])
	m.tower_collider_radius = 2.0
	m.hat_spots = PackedVector2Array([Vector2(5, -8.5), Vector2(5, 8.5), Vector2(-3, -8.5), Vector2(-3, 8.5)])
	m.oficina_spots = PackedVector2Array([Vector2(-8.5, -8.3), Vector2(-8.5, 8.3)])
	m.wall_height = ALT_MURO
	m.wall_thickness = ESP_MURO
	m.wall_parapet = 1.0
	m.wall_model = "muralha.scn"
	m.tower_model = "torre_alta_{cor}.scn"
	m.flag_height = ALT_MURO + 0.3 + 4.5

	# Pátio (coordenadas locais; +x aponta para o inimigo).
	var zr := 16.0 - ESP_MURO / 2 - 1.5  # centro da escada, encostada na muralha lateral
	for s in [-1.0, 1.0]:
		_patio.append(_p("escada_muralha.scn", Vector3(-9, 0, s * zr)))
		_patio.append(_rampa_col(Vector3(-9, 0, s * zr), 0.0, 7.0, ALT_MURO, 3.0))
		_patio.append(_caixa_col(Vector3(-9, 0, s * zr), 0.0, Vector3(2.0, ALT_MURO, 3.0), Vector3(8.0, ALT_MURO / 2, 0)))
	_patio.append(_p("portao.scn", Vector3(12, 0, 0)))
	_patio.append(_p("barril.scn", Vector3(-14, 0, 11.0), 17.0))
	_patio.append(_p("caixotes.scn", Vector3(-14, 0, -11.0), 29.0))
	_patio.append(_p("sino.scn", Vector3(-12.6, 0, 5.8), 90.0, "cilindro", 1.6, 4.0))
	_patio.append(_p("poco.scn", Vector3(9.0, 0, -12.0), 0.0, "cilindro", 1.0, 2.0))
	_patio.append(_p("carroca.scn", Vector3(9.5, 0, 12.0), 75.0))
	for z in [-4.6, 4.6]:
		_patio.append(_p("lanterna_pedra.scn", Vector3(9.0, 0, z)))
		_patio.append(_p("poste.scn", Vector3(1.0, 0, z * 2.2), 90.0))

	# Rio: trechos de água + travas (alta fora das pontes, baixa embaixo delas).
	var zs := range(-32, 33, 8)
	for i in zs.size():
		_props.append(_p("rio_a.scn" if i % 2 == 0 else "rio_b.scn", Vector3(0, 0, zs[i])))
	for faixa in [[-36.5, -24.3, 3.0], [-19.7, -4.0, 3.0], [4.0, 19.7, 3.0], [24.3, 36.5, 3.0], [-24.3, -19.7, 0.9], [-4.0, 4.0, 0.9], [19.7, 24.3, 0.9]]:
		var zc: float = (faixa[0] + faixa[1]) / 2.0
		var comp: float = faixa[1] - faixa[0]
		_props.append(_caixa_col(Vector3(0, 0, zc), 0.0, Vector3(RIO_MEIA * 2 + 1.0, faixa[2], comp), Vector3(0, faixa[2] / 2.0, 0)))
	# Pontes: rampas, tabuleiro e parapeitos.
	for b in [[0.0, 8.0, "ponte_grande.scn"], [-22.0, 4.6, "ponte_lateral.scn"], [22.0, 4.6, "ponte_lateral.scn"]]:
		var z: float = b[0]
		var larg: float = b[1]
		_props.append(_p(b[2], Vector3(0, 0, z)))
		_props.append(_rampa_col(Vector3(-9, 0, z), 0.0, 9.0 - RIO_MEIA, ALT_PONTE, larg))
		_props.append(_rampa_col(Vector3(9, 0, z), 180.0, 9.0 - RIO_MEIA, ALT_PONTE, larg))
		_props.append(_caixa_col(Vector3(0, 0, z), 0.0, Vector3(RIO_MEIA * 2 + 0.2, 0.5, larg), Vector3(0, ALT_PONTE - 0.25, 0)))
		for s in [-1.0, 1.0]:
			_props.append(_caixa_col(Vector3(0, 0, z), 0.0, Vector3(18.0, 2.6, 0.3), Vector3(0, 1.3, s * (larg / 2.0 - 0.12))))
	_props.append(_p("cachoeira.scn", Vector3(0, 0, -37.5)))
	_props.append(_p("cachoeira.scn", Vector3(0, 0, 37.5), 180.0))
	_props.append(_p("ponte_corda.scn", Vector3(0, 0, -35.2)))
	_props.append(_p("ponte_corda.scn", Vector3(0, 0, 35.2), 180.0))
	for b in [[1.5, -11.0, 90.0], [-1.5, 12.0, -90.0], [1.4, -30.0, 90.0], [-1.4, 30.0, -90.0]]:
		_props.append(_p("barco.scn", Vector3(b[0], 0, b[1]), b[2]))

	# Vila (dos dois lados). Fileira norte olha para +z (rua), sul para -z.
	var c := "caixa"
	var casas := [
		["casa_a.scn", Vector3(12.5, 0, -9.0), 0.0, Vector3(5.0, 4.8, 4.5)],
		["loja.scn", Vector3(19.5, 0, -9.0), 0.0, Vector3(5.0, 4.4, 4.5)],
		["pousada.scn", Vector3(27.0, 0, -9.3), 0.0, Vector3(6.0, 7.0, 5.0)],
		["loja.scn", Vector3(12.5, 0, 9.0), 180.0, Vector3(5.0, 4.4, 4.5)],
		["casa_b.scn", Vector3(20.0, 0, 9.3), 180.0, Vector3(6.0, 5.0, 5.0)],
		["armazem.scn", Vector3(27.5, 0, 9.0), 180.0, Vector3(4.5, 4.8, 4.0)],
		["casa_b.scn", Vector3(13.0, 0, -16.8), 180.0, Vector3(6.0, 5.0, 5.0)],
		["casa_a.scn", Vector3(27.5, 0, -16.8), 180.0, Vector3(5.0, 4.8, 4.5)],
		["casa_a.scn", Vector3(14.0, 0, 16.8), 0.0, Vector3(5.0, 4.8, 4.5)],
		["pousada.scn", Vector3(28.0, 0, 17.0), 0.0, Vector3(6.0, 7.0, 5.0)],
	]
	for h in casas:
		for sx in [1.0, -1.0]:
			var pos := Vector3(h[1].x * sx, 0, h[1].z)
			var pr := _p(h[0], pos, h[2], c)
			pr.collider_size = h[3]
			pr.collider_offset = Vector3(0, h[3].y / 2.0, 0)
			_props.append(pr)
	_dois_lados(_props, "forja.scn", Vector3(20.5, 0, -16.8), 0.0, "caixa")
	_dois_lados(_props, "casa_de_cha.scn", Vector3(21.0, 0, 16.0), 0.0, "caixa")
	_dois_lados(_props, "festival.scn", Vector3(32.5, 0, 9.5), 180.0, "cilindro", 1.2, 2.0)
	_dois_lados(_props, "poco.scn", Vector3(32.0, 0, -9.5), 0.0, "cilindro", 1.0, 2.0)
	for x in [10.5, 16.0, 23.0, 30.5]:
		for z in [-4.3, 4.3]:
			_dois_lados(_props, "poste.scn", Vector3(x, 0, z), 90.0 if z < 0 else -90.0)
	_dois_lados(_props, "varal.scn", Vector3(19.0, 0, 0))
	_dois_lados(_props, "torii.scn", Vector3(10.5, 0, 0))
	_dois_lados(_props, "estatua.scn", Vector3(10.2, 0, -6.0), 0.0, "cilindro", 0.8, 2.0)
	_dois_lados(_props, "estatua.scn", Vector3(10.2, 0, 6.0), 0.0, "cilindro", 0.8, 2.0)
	_dois_lados(_props, "carroca.scn", Vector3(23.5, 0, -13.0), 10.0)
	_dois_lados(_props, "pilha.scn", Vector3(17.0, 0, 13.0), 30.0, "cilindro", 1.2, 2.0)

	# Colinas nos 4 cantos do meio, com escada do lado do rio e do castelo.
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			var cx: float = 20.0 * sx
			var cz: float = 30.0 * sz
			var col := _p("colina.scn", Vector3(cx, 0, cz), 0.0, "caixa")
			col.collider_size = Vector3(12.0, ALT_COLINA, 8.0)
			col.collider_offset = Vector3(0, ALT_COLINA / 2, 0)
			_props.append(col)
			# Escada do lado do rio: começa em |x| = 8,5 e sobe até a borda (|x| = 14).
			var rot := 0.0 if sx > 0 else 180.0
			var x0: float = 8.5 * sx
			_props.append(_p("escada_colina.scn", Vector3(x0, 0, cz - 1.5 * sz), rot))
			_props.append(_rampa_col(Vector3(x0, 0, cz - 1.5 * sz), rot, 5.5, ALT_COLINA, 3.2))
			# Escada do lado do castelo: começa em |x| = 31,5 e desce para o centro.
			var x1: float = 31.5 * sx
			_props.append(_p("escada_colina.scn", Vector3(x1, 0, cz + 1.0 * sz), 180.0 - rot))
			_props.append(_rampa_col(Vector3(x1, 0, cz + 1.0 * sz), 180.0 - rot, 5.5, ALT_COLINA, 3.2))
			# Em cima: pagode ou vigia, árvore e lanternas.
			var topo := ALT_COLINA
			_props.append(_p("pagode.scn" if sz < 0 else "vigia.scn", Vector3(cx + 2.5 * sx, topo, cz + 1.0 * sz), 0.0, "cilindro", 1.9, 6.0))
			_props.append(_p("arvore_media.scn", Vector3(cx - 3.5 * sx, topo, cz + 2.0 * sz), -1.0, "cilindro", 1.0, 3.0))
			_props.append(_p("lanterna_pedra.scn", Vector3(cx - 1.5 * sx, topo, cz - 2.6 * sz)))
			_props.append(_p("lanterna_pedra.scn", Vector3(cx + 4.5 * sx, topo, cz - 2.6 * sz)))

	# Cobertura no meio: margens do rio e trilhas das pontes laterais.
	_dois_lados(_props, "rochas.scn", Vector3(7.5, 0, -12.5), -1.0, "cilindro", 1.0, 2.0)
	_dois_lados(_props, "rochas.scn", Vector3(7.0, 0, 13.0), -1.0, "cilindro", 1.0, 2.0)
	_dois_lados(_props, "barricada.scn", Vector3(13.0, 0, -22.5), 90.0, "caixa")
	_dois_lados(_props, "barricada.scn", Vector3(13.0, 0, 22.5), 90.0, "caixa")
	_dois_lados(_props, "jizos.scn", Vector3(29.0, 0, -22.0), 90.0)
	_dois_lados(_props, "pilha.scn", Vector3(23.0, 0, 22.0), -1.0, "cilindro", 1.2, 2.0)
	_dois_lados(_props, "lanterna_pedra.scn", Vector3(10.0, 0, -19.5))
	_dois_lados(_props, "lanterna_pedra.scn", Vector3(10.0, 0, -24.5))
	_dois_lados(_props, "lanterna_pedra.scn", Vector3(10.0, 0, 19.5))
	_dois_lados(_props, "lanterna_pedra.scn", Vector3(10.0, 0, 24.5))
	_dois_lados(_props, "estatua.scn", Vector3(34.0, 0, -22.0), 0.0, "cilindro", 0.8, 2.0)
	_dois_lados(_props, "arvore_grande.scn", Vector3(7.5, 0, -30.0), -1.0, "cilindro", 2.0, 4.0)
	_dois_lados(_props, "arvore_grande.scn", Vector3(7.5, 0, 30.0), -1.0, "cilindro", 2.0, 4.0)
	# Campos fora das muralhas (perto dos castelos).
	_dois_lados(_props, "templo.scn", Vector3(50.0, 0, -28.5), 0.0, "caixa")
	_dois_lados(_props, "arvore_espirito.scn", Vector3(61.0, 0, -30.5), -1.0, "cilindro", 1.8, 5.0)
	_dois_lados(_props, "dojo.scn", Vector3(47.0, 0, 28.5), 0.0, "caixa")
	_dois_lados(_props, "lago.scn", Vector3(58.5, 0, 27.0), 0.0, "cilindro", 3.2, 2.0)
	_dois_lados(_props, "bambuzal.scn", Vector3(40.5, 0, 24.0), 90.0, "caixa")
	_dois_lados(_props, "bambuzal.scn", Vector3(62.0, 0, -24.0), 0.0, "caixa")
	_dois_lados(_props, "santuario.scn", Vector3(41.0, 0, -29.0), 0.0, "cilindro", 1.3, 2.0)
	_dois_lados(_props, "arvore_alta.scn", Vector3(64.5, 0, 31.5), -1.0, "cilindro", 2.0, 4.0)
	_dois_lados(_props, "arvore_media.scn", Vector3(38.0, 0, -20.5), -1.0, "cilindro", 1.0, 2.0)
	_dois_lados(_props, "ruina.scn", Vector3(44.0, 0, 20.5), -1.0, "cilindro", 1.4, 2.0)
	_dois_lados(_props, "rochas.scn", Vector3(57.0, 0, 20.0), -1.0, "cilindro", 1.0, 2.0)
	_dois_lados(_props, "cerca.scn", Vector3(57.0, 0, 34.0))
	_dois_lados(_props, "cerca.scn", Vector3(54.0, 0, -33.5))
	_dois_lados(_props, "aldeoes.scn", Vector3(32.0, 0, -27.5), 200.0, "cilindro", 1.0, 2.0)
	_dois_lados(_props, "aldeoes.scn", Vector3(32.0, 0, 27.5), 20.0, "cilindro", 1.0, 2.0)
	# Colisores em caixa das construções novas e das coberturas.
	for pr in _props:
		if pr.model == "forja.scn":
			pr.collider_size = Vector3(5.2, 4.0, 4.2)
			pr.collider_offset = Vector3(0, 2.0, 0)
		elif pr.model == "casa_de_cha.scn":
			pr.collider_size = Vector3(3.6, 3.2, 3.4)
			pr.collider_offset = Vector3(0, 1.6, -0.6)
		elif pr.model == "templo.scn":
			pr.collider_size = Vector3(8.4, 5.0, 6.6)
			pr.collider_offset = Vector3(0, 2.5, 0)
		elif pr.model == "dojo.scn":
			pr.collider_size = Vector3(8.3, 4.5, 6.3)
			pr.collider_offset = Vector3(0, 2.25, 0)
		elif pr.model == "barricada.scn":
			pr.collider_size = Vector3(6.0, 1.6, 1.4)
			pr.collider_offset = Vector3(0, 0.8, 0)
		elif pr.model == "bambuzal.scn":
			pr.collider_size = Vector3(7.0, 4.0, 3.0)
			pr.collider_offset = Vector3(0, 2.0, 0)

	var meio: Array[Resource] = []
	meio.assign(_props)
	var patio: Array[Resource] = []
	patio.assign(_patio)
	m.middle_props.assign(meio)
	m.courtyard_props.assign(patio)
	ResourceSaver.save(m, "res://config/mapas/rio_lanternas.tres")
	print("mapa salvo: %d objetos no meio, %d no pátio" % [meio.size(), patio.size()])
