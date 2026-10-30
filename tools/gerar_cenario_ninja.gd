extends SceneTree
## Gera o cenário ninja por código: modelos (.scn) dos dois temas, os temas
## (config/temas/*.tres) e o mapa (config/mapas/vale_ninja.tres).
##   godot --headless --path . -s tools/gerar_cenario_ninja.gd
## Cada modelo é UMA malha com até 2 superfícies (fosca com cor por vértice +
## brilho sem sombreamento), para o Arena juntar cópias num MultiMesh.
## Mudou cor, forma ou posição? Edite aqui e rode de novo.

const TEMAS := {
	"dia": {
		"pedra": Color(0.66, 0.63, 0.6), "pedra2": Color(0.52, 0.5, 0.5), "musgo": Color(0.32, 0.62, 0.2),
		"madeira": Color(0.56, 0.32, 0.15), "madeira2": Color(0.82, 0.55, 0.26), "reboco": Color(0.95, 0.86, 0.72),
		"telhado": Color(0.86, 0.42, 0.2), "folha": Color(0.26, 0.68, 0.18), "folha2": Color(0.46, 0.82, 0.26),
		"tronco": Color(0.48, 0.3, 0.16), "bambu": Color(0.46, 0.76, 0.28), "capim": Color(0.3, 0.68, 0.16),
		"capim2": Color(0.48, 0.8, 0.22), "torii": Color(0.95, 0.24, 0.14), "chao_folha": Color(1.0, 0.86, 0.22),
		"chao_folha2": Color(1.0, 0.58, 0.72), "agua": Color(0.18, 0.55, 0.9), "corda": Color(0.92, 0.82, 0.55),
		"montanha": Color(0.34, 0.56, 0.36), "neve": Color(0.96, 0.98, 1.0),
		"luz1": Color(1.0, 0.86, 0.4), "luz2": Color(1.0, 0.52, 0.32), "papel": Color(1.0, 0.92, 0.7),
		"ouro": Color(1.0, 0.8, 0.3), "branco": Color(1.0, 1.0, 0.96),
		"arvore": "sakura",
		"sombra": Color(0.36, 0.42, 0.72), "forca_sombra": 0.16, "borda": Color(1.0, 0.9, 0.65), "tinta": Color(0.16, 0.08, 0.05),
	},
	"oni": {
		"pedra": Color(0.44, 0.42, 0.5), "pedra2": Color(0.32, 0.3, 0.38), "musgo": Color(0.16, 0.3, 0.22),
		"madeira": Color(0.24, 0.14, 0.13), "madeira2": Color(0.4, 0.26, 0.18), "reboco": Color(0.72, 0.7, 0.78),
		"telhado": Color(0.3, 0.26, 0.4), "folha": Color(0.12, 0.3, 0.22), "folha2": Color(0.2, 0.42, 0.3),
		"tronco": Color(0.2, 0.15, 0.17), "bambu": Color(0.24, 0.5, 0.32), "capim": Color(0.16, 0.3, 0.26),
		"capim2": Color(0.3, 0.2, 0.38), "torii": Color(0.42, 0.06, 0.12), "chao_folha": Color(0.5, 0.16, 0.12),
		"chao_folha2": Color(0.62, 0.32, 0.12), "agua": Color(0.08, 0.2, 0.22), "corda": Color(0.75, 0.68, 0.5),
		"montanha": Color(0.12, 0.08, 0.17), "neve": Color(0.3, 0.22, 0.4),
		"luz1": Color(0.35, 1.0, 0.6), "luz2": Color(0.7, 0.4, 1.0), "papel": Color(0.45, 1.0, 0.7),
		"ouro": Color(1.0, 0.8, 0.35), "branco": Color(0.9, 0.95, 1.0),
		"arvore": "bambu",
		"sombra": Color(0.3, 0.2, 0.5), "forca_sombra": 0.35, "borda": Color(0.5, 1.0, 0.75), "tinta": Color(0.03, 0.02, 0.05),
	},
	"luar": {
		"pedra": Color(0.5, 0.5, 0.55), "pedra2": Color(0.38, 0.38, 0.44), "musgo": Color(0.25, 0.42, 0.3),
		"madeira": Color(0.38, 0.2, 0.12), "madeira2": Color(0.55, 0.36, 0.2), "reboco": Color(0.93, 0.91, 0.86),
		"telhado": Color(0.32, 0.38, 0.5), "folha": Color(1.0, 0.68, 0.82), "folha2": Color(1.0, 0.82, 0.9),
		"tronco": Color(0.3, 0.18, 0.16), "bambu": Color(0.3, 0.55, 0.32), "capim": Color(0.26, 0.42, 0.32),
		"capim2": Color(0.34, 0.5, 0.36), "torii": Color(0.85, 0.18, 0.1), "chao_folha": Color(1.0, 0.72, 0.85),
		"chao_folha2": Color(1.0, 0.86, 0.92), "agua": Color(0.12, 0.24, 0.42), "corda": Color(0.85, 0.78, 0.6),
		"montanha": Color(0.18, 0.24, 0.38), "neve": Color(0.8, 0.85, 0.95),
		"luz1": Color(1.0, 0.7, 0.3), "luz2": Color(1.0, 0.45, 0.35), "papel": Color(1.0, 0.75, 0.4),
		"ouro": Color(1.0, 0.8, 0.35), "branco": Color(1.0, 1.0, 0.95),
		"arvore": "sakura",
		"sombra": Color(0.3, 0.35, 0.65), "forca_sombra": 0.3, "borda": Color(0.75, 0.85, 1.0), "tinta": Color(0.04, 0.04, 0.08),
	},
	"crepusculo": {
		"pedra": Color(0.55, 0.5, 0.52), "pedra2": Color(0.4, 0.37, 0.42), "musgo": Color(0.27, 0.38, 0.2),
		"madeira": Color(0.3, 0.17, 0.12), "madeira2": Color(0.55, 0.33, 0.2), "reboco": Color(0.86, 0.78, 0.68),
		"telhado": Color(0.36, 0.27, 0.34), "folha": Color(0.22, 0.4, 0.2), "folha2": Color(0.36, 0.5, 0.24),
		"tronco": Color(0.3, 0.2, 0.16), "bambu": Color(0.36, 0.52, 0.26), "capim": Color(0.26, 0.42, 0.18),
		"capim2": Color(0.4, 0.48, 0.22), "torii": Color(0.7, 0.14, 0.1), "chao_folha": Color(0.85, 0.45, 0.16),
		"chao_folha2": Color(0.7, 0.25, 0.2), "agua": Color(0.16, 0.22, 0.36), "corda": Color(0.75, 0.62, 0.42),
		"montanha": Color(0.2, 0.18, 0.3), "neve": Color(0.75, 0.7, 0.8),
		"luz1": Color(1.0, 0.68, 0.3), "luz2": Color(1.0, 0.42, 0.22), "papel": Color(1.0, 0.78, 0.45),
		"ouro": Color(1.0, 0.75, 0.32), "branco": Color(0.92, 0.88, 0.84),
		"arvore": "sakura",
		"sombra": Color(0.38, 0.3, 0.68), "forca_sombra": 0.42, "borda": Color(1.0, 0.6, 0.32), "tinta": Color(0.06, 0.03, 0.06),
	},
}
const SHADER := preload("res://assets/shaders/pintura.gdshader")
const CONTORNO := preload("res://assets/shaders/contorno.gdshader")
## Peças sem contorno de tinta: enfeite miúdo (seria só ruído e dobraria o custo
## do espalhador), água e paisagem distante.
const SEM_CONTORNO := ["capim", "pedrinhas", "folhas", "cogumelos", "lajota", "broto", "flores", "flores_b",
	"lanterna_chao", "rio_a", "rio_b", "cachoeira", "lago", "borda_a", "borda_b", "borda_c", "montanha_a", "montanha_b"]
## Peças que balançam com o vento (peso cresce com a altura; valor = força).
const VENTO := {"capim": 1.0, "flores": 1.0, "flores_b": 1.0, "broto": 1.0, "arvore_grande": 1.2,
	"arvore_media": 1.2, "arvore_alta": 1.0, "arvore_espirito": 0.8, "bambuzal": 0.8, "borda_a": 0.6, "borda_b": 0.6}
const TIMES := {"azul": Color(0.3, 0.6, 1.0), "vermelho": Color(1.0, 0.3, 0.28)}

var P: Dictionary
var V := [PackedVector3Array(), PackedVector3Array()]
var N := [PackedVector3Array(), PackedVector3Array()]
var C := [PackedColorArray(), PackedColorArray()]
var I := [PackedInt32Array(), PackedInt32Array()]
var U := [PackedVector2Array(), PackedVector2Array()]
var _dir := ""
var _tris := {}
var _ao := 1.0       # oclusão pintada dos próximos vértices (1 = aberto)
var _vento := 0.0    # peso de vento dos próximos vértices
var _tipo := 0       # desenho do material (UV.y): 0 liso, 1 tábuas, 2 telhas, 3 pedras, 4 reboco
var _tipo_auto := false  # sem _tipo: deduz o desenho pela cor da paleta
var _contorno := true
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	if not _gerar_tudo():
		return
	for tema in TEMAS:
		P = TEMAS[tema]
		_dir = "res://assets/ninja/" + tema
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
		_gerar_modelos()
	_gerar_temas()
	_gerar_mapa()
	print("triângulos por modelo (oni): ", _tris)
	quit()


## Ferramentas que herdam este script (ex.: prancha_catalogo.gd) devolvem false.
func _gerar_tudo() -> bool:
	return true


# --- Modelos -----------------------------------------------------------------

func _gerar_modelos() -> void:
	for t in TIMES:
		_castelo(TIMES[t]); _salvar("castelo_" + t)
		_torre(TIMES[t]); _salvar("torre_" + t)
		_bandeira(TIMES[t]); _salvar("bandeira_" + t)
	_muro(); _salvar("muro")
	_barris(); _salvar("barril")
	_caixotes(); _salvar("caixotes")
	_barraca(); _salvar("barraca")
	_pedra_grande(); _salvar("pedra_grande")
	_arvore_grande(); _salvar("arvore_grande")
	_arvore_media(); _salvar("arvore_media")
	_arvore_alta(); _salvar("arvore_alta")
	_torii(); _salvar("torii")
	_toro_pedra(); _salvar("lanterna_pedra")
	_estatua(); _salvar("estatua")
	_santuario(); _salvar("santuario")
	_lago(); _salvar("lago")
	_varal(); _salvar("varal")
	_cerca(); _salvar("cerca")
	_pagode(); _salvar("pagode")
	_ruina(); _salvar("ruina")
	_rochas(); _salvar("rochas")
	_tronco_caido(); _salvar("tronco_caido")
	_borda_a(); _salvar("borda_a")
	_borda_b(); _salvar("borda_b")
	_borda_c(); _salvar("borda_c")
	_montanha(0); _salvar("montanha_a")
	_montanha(1); _salvar("montanha_b")
	_capim(); _salvar("capim")
	_pedrinhas(); _salvar("pedrinhas")
	_folhas(); _salvar("folhas")
	_cogumelos(); _salvar("cogumelos")
	_lajota(); _salvar("lajota")
	_broto(); _salvar("broto")
	_flores(0); _salvar("flores")
	_flores(1); _salvar("flores_b")
	_lanterna_chao(); _salvar("lanterna_chao")


## Castelo japonês (tenshu): base de pedra inclinada, 3 andares de reboco,
## telhados largos e uma faixa de neon na cor do time sob cada beiral.
func _castelo(time: Color) -> void:
	var telha: Color = P.telhado.lerp(time, 0.35)
	_cil(4.3, 5.1, 2.4, 4, Vector3(0, 1.2, 0), Vector3(0, 45, 0), P.pedra)
	for k in 4:  # fiadas de pedra
		_cil(4.95 - k * 0.2, 5.0 - k * 0.2, 0.06, 4, Vector3(0, 0.5 + k * 0.5, 0), Vector3(0, 45, 0), P.pedra2)
	var andares := [[6.2, 2.6, 5.6, 2.4], [4.4, 2.2, 4.0, 6.0], [3.0, 1.6, 2.8, 9.0]]
	var telhados := [[2.2, 5.0, 1.3], [1.4, 3.7, 1.1], [0.2, 2.7, 1.4]]
	for i in 3:
		var a: Array = andares[i]
		var y0: float = a[3]
		_caixa(Vector3(a[0], a[1], a[2]), Vector3(0, y0 + a[1] / 2.0, 0), Vector3.ZERO, P.reboco)
		_caixa(Vector3(a[0] + 0.05, 0.25, a[2] + 0.05), Vector3(0, y0 + 0.3, 0), Vector3.ZERO, P.madeira)
		for s in [-1, 1]:  # janelas de papel acesas
			for k in range(-1, 2):
				if i == 2 and k != 0:
					continue
				_caixa(Vector3(0.55, 0.6, 0.06), Vector3(k * a[0] * 0.3, y0 + a[1] * 0.6, s * (a[2] / 2.0 + 0.02)), Vector3.ZERO, P.papel, true)
				_caixa(Vector3(0.06, 0.6, 0.55), Vector3(s * (a[0] / 2.0 + 0.02), y0 + a[1] * 0.6, k * a[2] * 0.3), Vector3.ZERO, P.papel, true)
		var t: Array = telhados[i]
		var ty: float = y0 + a[1]
		_cil(t[0], t[1], t[2], 4, Vector3(0, ty + t[2] / 2.0 - 0.1, 0), Vector3(0, 45, 0), telha)
		_cil(t[0] * 0.98 + 0.05, t[0] + 0.12, 0.12, 4, Vector3(0, ty + t[2] - 0.1, 0), Vector3(0, 45, 0), time * 1.3, true)
		_caixa(Vector3(t[1] * 1.42, 0.12, t[1] * 1.42), Vector3(0, ty - 0.12, 0), Vector3.ZERO, time * 1.4, true)
	# Golfinhos dourados (shachi) no topo.
	for s in [-1, 1]:
		_cil(0.0, 0.18, 0.55, 5, Vector3(0, 12.2, s * 0.55), Vector3(s * 25, 0, 0), P.ouro, true)
	_esfera(0.22, Vector3(0, 10.4, 1.45), Vector3.ONE, time * 1.6, true)
	_esfera(0.22, Vector3(0, 10.4, -1.45), Vector3.ONE, time * 1.6, true)


## Torre de canto (yagura): 2 andares.
func _torre(time: Color) -> void:
	# Baixa de propósito: fica no portão e não pode esconder a briga da câmera.
	var telha: Color = P.telhado.lerp(time, 0.35)
	_cil(2.3, 2.75, 1.2, 4, Vector3(0, 0.6, 0), Vector3(0, 45, 0), P.pedra)
	_caixa(Vector3(3.0, 2.0, 3.0), Vector3(0, 2.2, 0), Vector3.ZERO, P.reboco)
	_caixa(Vector3(3.05, 0.2, 3.05), Vector3(0, 1.45, 0), Vector3.ZERO, P.madeira)
	for s in [-1, 1]:
		_caixa(Vector3(0.5, 0.5, 0.06), Vector3(0, 2.5, s * 1.52), Vector3.ZERO, P.papel, true)
		_caixa(Vector3(0.06, 0.5, 0.5), Vector3(s * 1.52, 2.5, 0), Vector3.ZERO, P.papel, true)
	_cil(0.2, 2.8, 1.2, 4, Vector3(0, 3.75, 0), Vector3(0, 45, 0), telha)
	_caixa(Vector3(3.9, 0.1, 3.9), Vector3(0, 3.15, 0), Vector3.ZERO, time * 1.4, true)


## Estandarte (nobori) no topo da torre, na cor do time.
func _bandeira(time: Color) -> void:
	_cil(0.05, 0.06, 2.8, 5, Vector3(0, 1.4, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.05, 1.7, 0.65), Vector3(0, 1.75, 0.36), Vector3.ZERO, time)
	_cil(0.2, 0.2, 0.07, 10, Vector3(0.04, 2.05, 0.36), Vector3(0, 0, 90), P.branco, true)
	_caixa(Vector3(0.06, 0.06, 0.7), Vector3(0, 2.6, 0.36), Vector3.ZERO, P.madeira)
	_esfera(0.09, Vector3(0, 2.85, 0), Vector3.ONE, P.ouro, true)


## Módulo de muralha (6 m no eixo x): base de pedra, reboco e telhadinho.
func _muro() -> void:
	_caixa(Vector3(6.0, 1.1, 1.7), Vector3(0, 0.55, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(6.0, 0.06, 1.72), Vector3(0, 0.6, 0), Vector3.ZERO, P.pedra2)
	_caixa(Vector3(6.0, 2.3, 1.1), Vector3(0, 2.25, 0), Vector3.ZERO, P.reboco)
	_caixa(Vector3(6.0, 0.22, 1.14), Vector3(0, 1.25, 0), Vector3.ZERO, P.madeira)
	for x in [-1.5, 1.5]:
		_caixa(Vector3(0.35, 0.35, 1.14), Vector3(x, 2.6, 0), Vector3.ZERO, P.telhado)
	_caixa(Vector3(6.05, 0.2, 1.9), Vector3(0, 3.45, 0), Vector3.ZERO, P.telhado)
	_caixa(Vector3(6.05, 0.22, 1.2), Vector3(0, 3.62, 0), Vector3.ZERO, P.telhado)
	_caixa(Vector3(6.05, 0.2, 0.5), Vector3(0, 3.82, 0), Vector3.ZERO, P.telhado.lightened(0.15))


func _barris() -> void:
	for p in [Vector3(0, 0.45, 0), Vector3(0.95, 0.45, 0.1), Vector3(0.48, 1.35, 0.05)]:
		_cil(0.45, 0.45, 0.9, 10, p, Vector3.ZERO, P.madeira2)
		for dy in [-0.3, 0.3]:
			_cil(0.47, 0.47, 0.07, 10, p + Vector3(0, dy, 0), Vector3.ZERO, P.corda)
		_caixa(Vector3(0.35, 0.4, 0.04), p + Vector3(0, 0, 0.45), Vector3.ZERO, P.branco)


func _caixotes() -> void:
	_caixa(Vector3(1.0, 1.0, 1.0), Vector3(0, 0.5, 0), Vector3(0, 10, 0), P.madeira2)
	_caixa(Vector3(0.8, 0.8, 0.8), Vector3(0.2, 1.4, 0.1), Vector3(0, -15, 0), P.madeira2)
	_caixa(Vector3(1.02, 0.12, 1.02), Vector3(0, 0.5, 0), Vector3(0, 10, 0), P.madeira)
	for p in [Vector3(1.0, 0.3, 0.4), Vector3(1.1, 0.3, -0.5), Vector3(1.05, 0.75, 0.0)]:
		_esfera(0.42, p, Vector3(1, 0.7, 0.8), P.corda.lightened(0.15))


## Barraca de feira: 4 postes, telhado inclinado, cortina (noren) e lanterna.
func _barraca() -> void:
	for x in [-1.3, 1.3]:
		for z in [-0.9, 0.9]:
			_cil(0.08, 0.08, 2.4 if z < 0 else 2.0, 5, Vector3(x, 1.2 if z < 0 else 1.0, z), Vector3.ZERO, P.madeira)
	_caixa(Vector3(3.0, 0.12, 2.3), Vector3(0, 2.25, 0), Vector3(-10, 0, 0), P.telhado)
	_caixa(Vector3(2.7, 0.8, 0.7), Vector3(0, 0.4, 0.9), Vector3.ZERO, P.madeira2)
	for k in 3:
		_caixa(Vector3(0.8, 0.6, 0.03), Vector3(-0.9 + k * 0.9, 1.75, 1.05), Vector3.ZERO, P.luz2 if k == 1 else P.reboco)
	_esfera(0.22, Vector3(1.3, 1.6, 1.15), Vector3(1, 1.3, 1), P.papel, true)


## Rocha grande sagrada com corda (shimenawa) e papéis (shide).
func _pedra_grande() -> void:
	_esfera(1.7, Vector3(0, 1.3, 0), Vector3(1, 0.95, 1), P.pedra, false, 7, 4)
	_esfera(1.15, Vector3(1.3, 0.7, 0.7), Vector3(1, 0.8, 1), P.pedra2, false, 6, 4)
	_esfera(0.95, Vector3(-1.2, 0.6, -0.8), Vector3(1, 0.8, 1), P.pedra2, false, 6, 4)
	_esfera(1.1, Vector3(0, 2.6, 0), Vector3(1.1, 0.35, 1.1), P.musgo, false, 7, 3)
	_toro(1.62, 1.82, Vector3(0, 1.6, 0), Vector3(1, 0.6, 1), P.corda)
	for k in 5:
		var a := TAU * k / 5.0
		_caixa(Vector3(0.12, 0.35, 0.03), Vector3(cos(a) * 1.78, 1.25, sin(a) * 1.78), Vector3(0, -rad_to_deg(a) + 90, 0), P.branco, true)


func _arvore_grande() -> void:
	if P.arvore == "bambu":
		for k in 11:
			var a := TAU * k / 11.0 + k
			var r := 0.6 + fmod(k * 0.37, 1.0) * 1.7
			var h := 7.0 + fmod(k * 0.53, 1.0) * 3.5
			_bambu(Vector3(cos(a) * r, 0, sin(a) * r), h, Vector3(sin(k) * 5, 0, cos(k * 1.3) * 5))
		for k in 5:
			var a := TAU * k / 5.0
			_esfera(1.6, Vector3(cos(a) * 1.4, 8.0 + k % 2, sin(a) * 1.4), Vector3(1, 0.55, 1), P.folha if k % 2 else P.folha2, false, 7, 4)
		_esfera(0.2, Vector3(1.8, 2.6, 0.4), Vector3(1, 1.3, 1), P.luz1, true)
	else:
		_cil(0.35, 0.6, 3.2, 7, Vector3(0, 1.6, 0), Vector3.ZERO, P.tronco)
		for s in [-1, 1]:
			_cil(0.15, 0.3, 2.4, 6, Vector3(s * 0.9, 3.4, 0.2), Vector3(0, 0, -40 * s), P.tronco)
		for k in 7:
			var a := TAU * k / 7.0
			var r := 1.6 if k % 2 else 2.2
			_esfera(1.5 - (k % 3) * 0.15, Vector3(cos(a) * r, 4.3 + (k % 3) * 0.5, sin(a) * r), Vector3(1, 0.8, 1), P.folha if k % 2 else P.folha2, false, 8, 5)
		_esfera(1.9, Vector3(0, 5.2, 0), Vector3(1, 0.75, 1), P.folha2, false, 8, 5)


func _arvore_media() -> void:
	if P.arvore == "bambu":
		# Árvore morta retorcida com lanterna-fantasma pendurada.
		_cil(0.25, 0.4, 2.2, 6, Vector3(0, 1.1, 0), Vector3(0, 0, 8), P.tronco)
		_cil(0.15, 0.25, 1.8, 6, Vector3(-0.35, 2.8, 0), Vector3(0, 0, 25), P.tronco)
		_cil(0.08, 0.15, 1.6, 5, Vector3(0.4, 2.9, 0.2), Vector3(10, 0, -55), P.tronco)
		_cil(0.06, 0.1, 1.2, 5, Vector3(-0.9, 3.7, -0.2), Vector3(-20, 0, 50), P.tronco)
		_caixa(Vector3(0.02, 0.6, 0.02), Vector3(1.05, 3.0, 0.2), Vector3.ZERO, P.corda)
		_esfera(0.25, Vector3(1.05, 2.55, 0.2), Vector3(1, 1.35, 1), P.luz1, true)
		_esfera(0.6, Vector3(0, 0.15, 0), Vector3(1.2, 0.3, 1.2), P.musgo, false, 6, 3)
	else:
		# Pinheiro japonês (matsu) com copas achatadas.
		_cil(0.2, 0.35, 2.6, 6, Vector3(0.2, 1.3, 0), Vector3(0, 0, -10), P.tronco)
		_cil(0.12, 0.2, 1.6, 6, Vector3(-0.3, 2.6, 0), Vector3(0, 0, 40), P.tronco)
		for p in [Vector3(0.5, 2.7, 0), Vector3(-0.9, 3.2, 0.2), Vector3(0.3, 3.7, -0.3)]:
			_esfera(1.2, p, Vector3(1, 0.38, 1), Color(0.14, 0.32, 0.22), false, 8, 4)


func _arvore_alta() -> void:
	if P.arvore == "bambu":
		# Cedro sagrado gigante com corda.
		_cil(0.75, 1.3, 6.0, 8, Vector3(0, 3.0, 0), Vector3.ZERO, P.tronco)
		for k in 3:
			_cil(0.2, 2.9 - k * 0.6, 2.8, 7, Vector3(0, 5.6 + k * 2.0, 0), Vector3(0, k * 20, 0), P.folha if k % 2 else P.folha2)
		_toro(1.05, 1.25, Vector3(0, 2.2, 0), Vector3(1, 0.6, 1), P.corda)
		for k in 6:
			var a := TAU * k / 6.0
			_caixa(Vector3(0.12, 0.35, 0.03), Vector3(cos(a) * 1.2, 1.85, sin(a) * 1.2), Vector3(0, -rad_to_deg(a) + 90, 0), P.branco, true)
	else:
		# Cerejeira chorona.
		_cil(0.45, 0.75, 3.5, 7, Vector3(0, 1.75, 0), Vector3.ZERO, P.tronco)
		_esfera(2.8, Vector3(0, 4.6, 0), Vector3(1, 0.7, 1), P.folha, false, 9, 5)
		for k in 12:
			var a := TAU * k / 12.0
			_cil(0.06, 0.18, 2.4, 4, Vector3(cos(a) * 2.5, 3.2, sin(a) * 2.5), Vector3.ZERO, P.folha2)


func _torii() -> void:
	var cor: Color = P.torii
	for z in [-4.6, 4.6]:
		_cil(0.26, 0.3, 5.3, 8, Vector3(0, 2.65, z), Vector3.ZERO, cor)
		_cil(0.36, 0.36, 0.5, 8, Vector3(0, 0.25, z), Vector3.ZERO, Color(0.08, 0.08, 0.1))
		_caixa(Vector3(0.12, 0.6, 0.35), Vector3(0.3, 1.9, z), Vector3.ZERO, P.branco, true)  # talismã
	_caixa(Vector3(0.45, 0.35, 10.2), Vector3(0, 4.3, 0), Vector3.ZERO, cor)
	_caixa(Vector3(0.6, 0.45, 11.4), Vector3(0, 5.35, 0), Vector3.ZERO, cor)
	_caixa(Vector3(0.7, 0.22, 12.0), Vector3(0, 5.68, 0), Vector3.ZERO, Color(0.1, 0.08, 0.1))
	_caixa(Vector3(0.25, 0.9, 0.9), Vector3(0, 4.85, 0), Vector3.ZERO, Color(0.1, 0.08, 0.1))
	_caixa(Vector3(0.08, 0.08, 11.0), Vector3(0.2, 5.1, 0), Vector3.ZERO, P.luz2, true)


## Kasuga-dōrō: base sextavada, coluna com barriga, caixa de fogo acesa,
## chapéu sextavado com pontas viradas e joia no topo. Velha: inclinada,
## com musgo no chapéu e na base, pedrinhas e um tufo de capim no pé.
func _toro_pedra() -> void:
	_rng.seed = 11
	var pedra: Color = P.pedra
	var p2: Color = P.pedra2
	var inc := Basis.from_euler(Vector3(deg_to_rad(2.5), 0, deg_to_rad(-2.0)))
	var ap := func(v: Vector3) -> Vector3:
		return inc * v
	# Base: degrau sextavado + pedras ao redor.
	_cil(0.62, 0.68, 0.18, 6, Vector3(0, 0.09, 0), Vector3.ZERO, p2)
	_cil(0.5, 0.56, 0.2, 6, ap.call(Vector3(0, 0.28, 0)), Vector3(2.5, 30, -2), pedra)
	# Coluna com barriga (3 trechos) e anéis.
	_cil(0.17, 0.2, 0.35, 8, ap.call(Vector3(0, 0.55, 0)), Vector3(2.5, 0, -2), pedra)
	_cil(0.2, 0.17, 0.35, 8, ap.call(Vector3(0, 0.9, 0)), Vector3(2.5, 0, -2), pedra)
	_cil(0.22, 0.22, 0.06, 8, ap.call(Vector3(0, 0.72, 0)), Vector3(2.5, 0, -2), p2)
	# Prato sob a caixa de fogo.
	_cil(0.42, 0.24, 0.16, 6, ap.call(Vector3(0, 1.15, 0)), Vector3(2.5, 30, -2), pedra)
	# Caixa de fogo: luz por dentro, 6 colunas de pedra e janelas recortadas.
	_cil(0.26, 0.26, 0.42, 6, ap.call(Vector3(0, 1.44, 0)), Vector3(2.5, 0, -2), P.papel, true)
	for j in 6:
		var a := j * TAU / 6.0
		var c := Vector3(cos(a), 0, sin(a)) * 0.29
		_bloco(Vector3(0.1, 0.44, 0.1), ap.call(Vector3(0, 1.44, 0) + c), inc * Basis(Vector3.UP, -a), pedra, 0.03)
	_cil(0.36, 0.33, 0.06, 6, ap.call(Vector3(0, 1.67, 0)), Vector3(2.5, 30, -2), p2)
	# Chapéu: superfície sextavada com perfil côncavo e pontas viradas.
	var topo: Vector3 = ap.call(Vector3(0, 2.02, 0))
	var anel := []
	var sub := 3
	for j in 6 * sub:
		var a := j * TAU / (6 * sub)
		var ponta := 1.0 if j % sub == 0 else 0.0
		var rr := 0.7 + 0.06 * ponta
		anel.append(ap.call(Vector3(cos(a) * rr, 1.72 + 0.14 * ponta, sin(a) * rr)))
	var meio := []
	for j in 6 * sub:
		var a := j * TAU / (6 * sub)
		meio.append(ap.call(Vector3(cos(a) * 0.36, 1.86, sin(a) * 0.36)))
	var n := anel.size()
	for j in n:
		var j2 := (j + 1) % n
		var fora: Vector3 = (anel[j] + anel[j2]) / 2.0 - topo + Vector3(0, 0.6, 0)
		var tom := pedra.darkened(0.04 * float(j % 2))
		_quad(anel[j], anel[j2], meio[j2], meio[j], tom, fora)
		_tri(meio[j], meio[j2], topo, tom.lightened(0.03), fora + Vector3(0, 0.5, 0))
		_ao = 0.45
		_tri(anel[j] - Vector3(0, 0.07, 0), anel[j2] - Vector3(0, 0.07, 0), ap.call(Vector3(0, 1.66, 0)), p2.darkened(0.3), Vector3(0, -1, 0))
		_ao = 1.0
		_quad(anel[j], anel[j2], anel[j2] - Vector3(0, 0.07, 0), anel[j] - Vector3(0, 0.07, 0), p2, fora - Vector3(0, 0.6, 0))
	# Joia (hōju) no topo.
	_cil(0.1, 0.13, 0.1, 8, topo + Vector3(0, 0.04, 0), Vector3.ZERO, p2)
	_esfera(0.13, topo + Vector3(0, 0.2, 0), Vector3(1, 1.1, 1), pedra, false, 8, 5)
	_cil(0.0, 0.05, 0.1, 6, topo + Vector3(0, 0.36, 0), Vector3.ZERO, pedra)
	# Musgo (manchas gordas, baixa frequência) no chapéu e na base.
	for j in 4:
		var a := _rng.randf() * TAU
		var pm: Vector3 = ap.call(Vector3(cos(a) * 0.45, 1.84, sin(a) * 0.45))
		_esfera(0.13, pm, Vector3(1.3, 0.25, 1.0), P.musgo.lerp(pedra, 0.55 + _rng.randf() * 0.2), false, 7, 3)
	for j in 3:
		var a := _rng.randf() * TAU
		_esfera(0.16, Vector3(cos(a) * 0.55, 0.2, sin(a) * 0.55), Vector3(1.3, 0.3, 1.0), P.musgo.lerp(p2, 0.3), false, 7, 3)
	# Pedrinhas e capim no pé.
	for j in 5:
		var a := _rng.randf() * TAU
		var pr := Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.75, 1.0)
		_esfera(_rng.randf_range(0.07, 0.13), pr + Vector3(0, 0.04, 0), Vector3(1.2, 0.7, 1.0), p2.lightened(_rng.randf() * 0.15), false, 6, 3)
	var m := _marca()
	for j in 7:
		var a := 0.6 + j * 0.25
		var base := Vector3(cos(a), 0, sin(a)) * 0.78
		_cil(0.0, 0.05, _rng.randf_range(0.3, 0.5), 3, base + Vector3(0, 0.18, 0), Vector3(_rng.randf_range(-20, 20), 0, _rng.randf_range(-20, 20)), P.capim.lerp(P.capim2, _rng.randf()))
	_vento_planta(m, 0.0, 0.45)


func _estatua() -> void:
	_caixa(Vector3(1.3, 0.7, 1.3), Vector3(0, 0.35, 0), Vector3.ZERO, P.pedra2)
	if P.arvore == "bambu":
		# Estátua de oni: corpo agachado, chifres de osso, olhos acesos.
		_esfera(0.65, Vector3(0, 1.25, 0), Vector3(1, 0.9, 0.9), P.pedra)
		_esfera(0.5, Vector3(0, 2.05, 0.1), Vector3.ONE, P.pedra)
		for s in [-1, 1]:
			_cil(0.0, 0.13, 0.55, 6, Vector3(0.28 * s, 2.55, 0.05), Vector3(0, 0, -20 * s), Color(0.85, 0.8, 0.7))
			_esfera(0.08, Vector3(0.18 * s, 2.12, 0.55), Vector3.ONE, P.luz2, true)
			_esfera(0.22, Vector3(0.55 * s, 1.0, 0.35), Vector3.ONE, P.pedra)
		_caixa(Vector3(0.4, 0.08, 0.05), Vector3(0, 1.88, 0.58), Vector3.ZERO, Color(0.85, 0.8, 0.7))
	else:
		# Cão-leão guardião (komainu).
		_esfera(0.55, Vector3(0, 1.15, -0.1), Vector3(0.9, 0.9, 1.2), P.pedra)
		_esfera(0.42, Vector3(0, 1.75, 0.35), Vector3.ONE, P.pedra)
		_esfera(0.48, Vector3(0, 1.7, 0.2), Vector3(1.1, 1.0, 0.7), P.pedra2)
		_esfera(0.16, Vector3(0, 1.62, 0.75), Vector3.ONE, P.pedra)
		for s in [-1, 1]:
			_cil(0.12, 0.14, 0.6, 6, Vector3(0.3 * s, 0.95, 0.4), Vector3.ZERO, P.pedra)
		_toro(0.32, 0.4, Vector3(0, 1.45, 0.25), Vector3(1, 0.6, 1), P.luz2)


## Santuário pequeno (hokora) com oferendas e velas.
func _santuario() -> void:
	_caixa(Vector3(1.8, 0.4, 1.8), Vector3(0, 0.2, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(1.1, 1.0, 1.0), Vector3(0, 0.9, 0), Vector3.ZERO, P.madeira2)
	_caixa(Vector3(0.6, 0.6, 0.04), Vector3(0, 0.9, 0.52), Vector3.ZERO, P.papel, true)
	_cil(0.1, 1.0, 0.6, 4, Vector3(0, 1.7, 0), Vector3(0, 45, 0), P.telhado, false, Vector3(1.0, 1, 1.3))
	for s in [-1, 1]:
		_cil(0.05, 0.05, 0.25, 5, Vector3(0.55 * s, 0.52, 0.7), Vector3.ZERO, P.branco)
		_esfera(0.06, Vector3(0.55 * s, 0.7, 0.7), Vector3(1, 1.5, 1), P.luz1, true)
	# Mini torii na frente.
	for s in [-1, 1]:
		_cil(0.05, 0.06, 1.0, 5, Vector3(0.45 * s, 0.5, 1.4), Vector3.ZERO, P.torii)
	_caixa(Vector3(1.25, 0.1, 0.12), Vector3(0, 1.0, 1.4), Vector3.ZERO, P.torii)


func _lago() -> void:
	_cil(3.1, 3.1, 0.06, 16, Vector3(0, 0.04, 0), Vector3.ZERO, P.agua)
	_cil(2.2, 2.2, 0.03, 16, Vector3(0.3, 0.08, -0.2), Vector3.ZERO, P.agua.lightened(0.12))
	for k in 14:
		var a := TAU * k / 14.0
		_esfera(0.45 + fmod(k * 0.37, 1.0) * 0.3, Vector3(cos(a) * 3.2, 0.15, sin(a) * 3.2), Vector3(1, 0.6, 1), P.pedra if k % 2 else P.pedra2, false, 6, 3)
	for p in [Vector3(1.2, 0.09, 0.8), Vector3(-1.0, 0.09, -0.6), Vector3(0.2, 0.09, -1.6), Vector3(-1.5, 0.09, 1.2)]:
		_cil(0.35, 0.35, 0.02, 8, p, Vector3.ZERO, Color(0.2, 0.42, 0.28))
		_esfera(0.11, p + Vector3(0.1, 0.08, 0), Vector3(1, 0.7, 1), P.luz2 if P.arvore == "sakura" else P.luz1, true)


## Varal de lanternas de papel atravessando a estrada.
func _varal() -> void:
	for z in [-4.8, 4.8]:
		_cil(0.1, 0.12, 4.2, 6, Vector3(0, 2.1, z), Vector3.ZERO, P.madeira)
	var n := 9
	for i in n:
		var t := (i + 0.5) / n
		var z := lerpf(-4.8, 4.8, t)
		var y := 3.9 - sin(t * PI) * 0.6
		_caixa(Vector3(0.03, 0.03, 9.6 / n + 0.05), Vector3(0, y + 0.3, z), Vector3(rad_to_deg(cos(t * PI) * 0.18), 0, 0), Color(0.08, 0.08, 0.1))
		_esfera(0.25, Vector3(0, y, z), Vector3(1, 1.3, 1), P.papel if i % 2 else P.luz2, true, 8, 4)


func _cerca() -> void:
	for x in [-2.0, -1.0, 0.0, 1.0, 2.0]:
		_cil(0.07, 0.07, 1.2, 5, Vector3(x, 0.6, 0), Vector3.ZERO, P.bambu)
	for y in [0.4, 0.95]:
		_cil(0.05, 0.05, 4.2, 5, Vector3(0, y, 0.08), Vector3(0, 0, 90), P.bambu.darkened(0.2))


## Pagode de 3 andares: marco no meio de cada lado do mapa.
func _pagode() -> void:
	_caixa(Vector3(3.6, 0.5, 3.6), Vector3(0, 0.25, 0), Vector3.ZERO, P.pedra)
	var larg := 2.4
	var y := 0.5
	for k in 3:
		_caixa(Vector3(larg, 1.2, larg), Vector3(0, y + 0.6, 0), Vector3.ZERO, P.madeira if k == 0 else P.reboco)
		for sx in [-1, 1]:
			_caixa(Vector3(0.4, 0.5, 0.05), Vector3(0, y + 0.7, sx * (larg / 2 + 0.02)), Vector3.ZERO, P.papel, true)
		_cil(0.3, larg * 1.05, 0.7, 4, Vector3(0, y + 1.5, 0), Vector3(0, 45, 0), P.telhado)
		y += 1.75
		larg *= 0.78
	_cil(0.05, 0.08, 1.6, 5, Vector3(0, y + 0.6, 0), Vector3.ZERO, P.ouro)
	for k in 4:
		_cil(0.16, 0.16, 0.05, 8, Vector3(0, y + 0.3 + k * 0.25, 0), Vector3.ZERO, P.ouro)
	_esfera(0.14, Vector3(0, y + 1.45, 0), Vector3.ONE, P.luz1, true)


## Ruína: pedaços de muro quebrado, pilar caído e pedras soltas.
func _ruina() -> void:
	_caixa(Vector3(2.4, 1.6, 0.5), Vector3(-0.4, 0.8, 0), Vector3(0, 0, 3), P.reboco.darkened(0.15))
	_caixa(Vector3(1.0, 0.7, 0.52), Vector3(-1.0, 1.8, 0), Vector3(0, 0, 18), P.reboco.darkened(0.15))
	_caixa(Vector3(2.5, 0.5, 0.8), Vector3(-0.4, 0.25, 0), Vector3.ZERO, P.pedra)
	_cil(0.25, 0.25, 2.6, 7, Vector3(1.3, 0.25, 1.0), Vector3(0, 30, 90), P.madeira)
	for p in [Vector3(1.0, 0.2, -0.8), Vector3(0.4, 0.15, 1.6), Vector3(-1.9, 0.2, 0.9)]:
		_caixa(Vector3(0.5, 0.4, 0.45), p, Vector3(10, p.x * 40, 0), P.pedra2)
	_esfera(0.5, Vector3(-0.4, 1.65, 0), Vector3(2.2, 0.3, 0.7), P.musgo, false, 6, 3)
	_caixa(Vector3(0.25, 0.45, 0.03), Vector3(0.2, 1.0, 0.27), Vector3.ZERO, P.branco, true)


func _rochas() -> void:
	_esfera(0.9, Vector3(0, 0.55, 0), Vector3(1, 0.75, 0.9), P.pedra, false, 6, 3)
	_esfera(0.6, Vector3(0.9, 0.35, 0.4), Vector3(1, 0.7, 1), P.pedra2, false, 6, 3)
	_esfera(0.5, Vector3(-0.7, 0.3, 0.6), Vector3(1, 0.7, 1), P.pedra2, false, 5, 3)
	_esfera(0.6, Vector3(0, 1.05, 0), Vector3(1, 0.3, 0.85), P.musgo, false, 6, 3)


func _tronco_caido() -> void:
	_cil(0.32, 0.38, 3.2, 7, Vector3(0, 0.33, 0), Vector3(0, 0, 90), P.tronco)
	_cil(0.3, 0.3, 0.05, 7, Vector3(1.62, 0.33, 0), Vector3(0, 0, 90), P.madeira2)
	_esfera(0.4, Vector3(-0.4, 0.62, 0), Vector3(2.0, 0.3, 0.8), P.musgo, false, 6, 3)
	for k in 3:
		_esfera(0.07, Vector3(0.3 + k * 0.35, 0.68, 0.15), Vector3(1, 0.6, 1), P.luz1 if P.arvore == "bambu" else P.folha, P.arvore == "bambu", 5, 3)


# Borda (o Arena escala estes por 3 a 4,5): modelos pequenos.
func _borda_a() -> void:
	if P.arvore == "bambu":
		for k in 6:
			var a := TAU * k / 6.0
			var h := 2.0 + fmod(k * 0.53, 1.0) * 0.8
			_cil(0.035, 0.04, h, 5, Vector3(cos(a) * 0.35, h / 2, sin(a) * 0.35), Vector3(sin(k) * 6, 0, cos(k) * 6), P.bambu)
		for k in 3:
			_esfera(0.3, Vector3(cos(k * 2.1) * 0.35, 1.9 + k * 0.3, sin(k * 2.1) * 0.35), Vector3(1, 0.5, 1), P.folha2 if k % 2 else P.folha, false, 6, 3)
	else:
		_cil(0.08, 0.14, 0.9, 5, Vector3(0, 0.45, 0), Vector3.ZERO, P.tronco)
		_esfera(0.55, Vector3(0, 1.2, 0), Vector3(1, 0.8, 1), P.folha, false, 7, 4)
		_esfera(0.4, Vector3(0.35, 1.0, 0.2), Vector3(1, 0.8, 1), P.folha2, false, 6, 3)


func _borda_b() -> void:
	_cil(0.06, 0.1, 0.6, 5, Vector3(0, 0.3, 0), Vector3.ZERO, P.tronco)
	for k in 3:
		_cil(0.05, 0.6 - k * 0.15, 0.7, 6, Vector3(0, 0.8 + k * 0.45, 0), Vector3.ZERO, Color(0.1, 0.22, 0.2) if P.arvore == "bambu" else Color(0.14, 0.3, 0.24))


func _borda_c() -> void:
	_esfera(0.5, Vector3(0, 0.3, 0), Vector3(1, 0.7, 0.9), P.pedra2, false, 6, 3)
	_esfera(0.3, Vector3(0.45, 0.2, 0.2), Vector3(1, 0.7, 1), P.pedra, false, 5, 3)
	_esfera(0.35, Vector3(0, 0.55, 0), Vector3(1, 0.3, 0.9), P.musgo, false, 6, 3)


func _montanha(v: int) -> void:
	_cil(0.2, 3.0, 3.2 + v * 0.6, 6 + v, Vector3(0, 1.6 + v * 0.3, 0), Vector3(0, v * 20, 0), P.montanha)
	_cil(0.05, 0.75, 0.8, 6 + v, Vector3(0, 2.85 + v * 0.6, 0), Vector3(0, v * 20, 0), P.neve, P.arvore == "bambu")
	_cil(0.1, 1.8, 1.8, 5, Vector3(1.8, 0.9, 0.8), Vector3(0, 10, 0), P.montanha.lightened(0.05))


# Enfeites do chão (sem colisão, sem sombra).
func _capim() -> void:
	for k in 6:
		var a := TAU * k / 6.0
		_cil(0.0, 0.05, 0.35 + fmod(k * 0.41, 1.0) * 0.25, 3, Vector3(cos(a) * 0.12, 0.2, sin(a) * 0.12), Vector3(cos(a) * 18, 0, sin(a) * 18), P.capim if k % 3 else P.capim2)


func _pedrinhas() -> void:
	_esfera(0.18, Vector3(0, 0.05, 0), Vector3(1, 0.55, 0.8), P.pedra, false, 5, 3)
	_esfera(0.12, Vector3(0.3, 0.03, 0.15), Vector3(1, 0.5, 1), P.pedra2, false, 5, 3)
	_esfera(0.09, Vector3(-0.2, 0.03, 0.25), Vector3(1, 0.5, 1), P.pedra, false, 5, 3)


func _folhas() -> void:
	for k in 9:
		var a := k * 2.4
		var r := 0.15 + fmod(k * 0.37, 1.0) * 0.55
		_caixa(Vector3(0.14, 0.012, 0.09), Vector3(cos(a) * r, 0.03, sin(a) * r), Vector3(0, rad_to_deg(a * 1.7), 0), P.chao_folha if k % 2 else P.chao_folha2)


func _cogumelos() -> void:
	if P.arvore == "bambu":
		for p in [Vector3(0, 0, 0), Vector3(0.22, 0, 0.1), Vector3(-0.1, 0, 0.2)]:
			var h: float = 0.15 + p.x * 0.4
			_cil(0.025, 0.035, h, 5, p + Vector3(0, h / 2, 0), Vector3.ZERO, Color(0.85, 0.85, 0.9))
			_esfera(0.08, p + Vector3(0, h, 0), Vector3(1, 0.55, 1), P.luz1 if p.z < 0.15 else P.luz2, true, 6, 3)
	else:
		for k in 5:
			var a := TAU * k / 5.0
			var p := Vector3(cos(a) * 0.2, 0, sin(a) * 0.2)
			_cil(0.012, 0.012, 0.22, 3, p + Vector3(0, 0.11, 0), Vector3.ZERO, P.capim)
			_esfera(0.05, p + Vector3(0, 0.23, 0), Vector3.ONE, Color(1, 1, 0.9) if k % 2 else Color(1.0, 0.85, 0.3), false, 5, 3)


func _lajota() -> void:
	_caixa(Vector3(0.9, 0.05, 0.7), Vector3(0, 0.025, 0), Vector3(0, 8, 0), P.pedra)
	_caixa(Vector3(0.6, 0.05, 0.5), Vector3(0.85, 0.025, 0.2), Vector3(0, -12, 0), P.pedra2)


func _broto() -> void:
	if P.arvore == "bambu":
		for p in [Vector3(0, 0, 0), Vector3(0.18, 0, 0.12), Vector3(-0.12, 0, 0.15)]:
			_cil(0.0, 0.07, 0.35 + p.x, 5, p + Vector3(0, 0.17, 0), Vector3.ZERO, P.bambu.darkened(0.15))
	else:
		_esfera(0.35, Vector3(0, 0.22, 0), Vector3(1, 0.7, 1), Color(0.18, 0.36, 0.26), false, 6, 3)
		_esfera(0.25, Vector3(0.3, 0.16, 0.1), Vector3(1, 0.7, 1), Color(0.22, 0.42, 0.3), false, 6, 3)



## Tufo de flores de desenho animado (tulipas grandes, cores puras).
func _flores(v: int) -> void:
	var cores := [Color(0.95, 0.14, 0.12), Color(0.18, 0.38, 1.0)] if v == 0 else [Color(1.0, 0.84, 0.12), Color(1.0, 1.0, 0.95)]
	for k in 3:
		var a := k * 2.3 + v
		var p := Vector3(cos(a), 0, sin(a)) * (0.08 + 0.17 * (k % 3))
		var h := 0.3 + 0.1 * (k % 2)
		_cil(0.018, 0.024, h, 3, p + Vector3(0, h / 2, 0), Vector3.ZERO, P.capim)
		_esfera(0.12, p + Vector3(0, h + 0.05, 0), Vector3(1, 1.25, 1), cores[k % 2], false, 5, 2)
		_caixa(Vector3(0.05, 0.14, 0.012), p + Vector3(0.05, 0.07, 0), Vector3(0, a * 40.0, -30), P.capim2)

func _lanterna_chao() -> void:
	_caixa(Vector3(0.32, 0.05, 0.32), Vector3(0, 0.03, 0), Vector3.ZERO, P.madeira)
	_caixa(Vector3(0.26, 0.42, 0.26), Vector3(0, 0.26, 0), Vector3.ZERO, P.papel, true)
	_caixa(Vector3(0.34, 0.05, 0.34), Vector3(0, 0.5, 0), Vector3.ZERO, P.madeira)


func _bambu(base: Vector3, h: float, rot: Vector3) -> void:
	var b := Basis.from_euler(rot * PI / 180.0)
	_cil(0.1, 0.13, h, 6, base + b * Vector3(0, h / 2, 0), rot, P.bambu)
	var k := 1.2
	while k < h:
		_cil(0.14, 0.14, 0.08, 6, base + b * Vector3(0, k, 0), rot, P.bambu.darkened(0.25))
		k += 1.3


# --- Construtor de malha -------------------------------------------------------

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
	_tipo_auto = true
	_sincronizar()


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, cor: Color, fora: Vector3, brilho := false) -> void:
	_tri(a, b, c, cor, fora, brilho)
	_tri(a, c, d, cor, fora, brilho)


func _sincronizar() -> void:
	for s in 2:
		while U[s].size() < V[s].size():
			var i: int = U[s].size()
			U[s].append(Vector2(_vento, _tipo))
			var c: Color = C[s][i]
			c.a = _ao
			C[s][i] = c
			if _tipo == 0 and _tipo_auto and s == 0:
				U[s][i].y = _desenho_pela_cor(c)


## Marca onde a malha está, para mexer só no que vier depois (_vento_pendurado).
func _marca() -> Array:
	return [V[0].size(), V[1].size()]


## Vento de coisa pendurada: 0 no ponto de apoio (y = topo) até 1 a `comp` abaixo.
func _vento_pendurado(m: Array, topo: float, comp: float, forca := 1.0) -> void:
	for s in 2:
		for i in range(m[s], V[s].size()):
			U[s][i].x = clampf((topo - V[s][i].y) / comp, 0.0, 1.0) * forca


## Vento de planta: 0 na base (y = base) até `forca` a `comp` acima.
func _vento_planta(m: Array, base: float, comp: float, forca := 1.0) -> void:
	for s in 2:
		for i in range(m[s], V[s].size()):
			U[s][i].x = clampf((V[s][i].y - base) / comp, 0.0, 1.0) * forca


## Escurece o que já foi desenhado numa faixa de altura (embaixo do beiral):
## fator 1 em y0 até `fator` em y1, só dentro do retângulo |x| < mx, |z - cz| < mz.
func _sombra_faixa(y0: float, y1: float, fator: float, mx: float, mz: float, cz := 0.0) -> void:
	for i in V[0].size():
		var v: Vector3 = V[0][i]
		if v.y < y0 or v.y > y1 + 0.02 or absf(v.x) > mx or absf(v.z - cz) > mz:
			continue
		var c: Color = C[0][i]
		c.a *= lerpf(1.0, fator, clampf((v.y - y0) / (y1 - y0), 0.0, 1.0))
		C[0][i] = c



## Desenho do material deduzido pela cor (peças antigas, sem _tipo explícito).
func _desenho_pela_cor(c: Color) -> int:
	for par in [["telhado", 2], ["madeira2", 1], ["pedra", 3], ["pedra2", 3], ["reboco", 4]]:
		var p: Color = P[par[0]]
		if absf(c.r - p.r) + absf(c.g - p.g) + absf(c.b - p.b) < 0.12:
			return par[1]
	return 0


## Caixa com quinas chanfradas (44 triângulos). `torcer` deforma os pontos no
## espaço local antes de girar/posicionar (paredes tortas, tábuas cedendo).
func _bloco(size: Vector3, pos: Vector3, basis: Basis, cor: Color, chanfro := 0.06, torcer := Callable()) -> void:
	var h := size / 2.0
	var c := minf(chanfro, minf(h.x, minf(h.y, h.z)) * 0.9)
	var pts := {}
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var s := Vector3(sx, sy, sz)
				for eixo in 3:
					var q := (h - Vector3(c, c, c)) * s
					q[eixo] = h[eixo] * s[eixo]
					if torcer.is_valid():
						q = torcer.call(q)
					pts[Vector3i(sx, sy, sz) * 4 + Vector3i(eixo, 0, 0)] = basis * q + pos
	var meio := pos
	var P_ := func(sx: int, sy: int, sz: int, eixo: int) -> Vector3:
		return pts[Vector3i(sx, sy, sz) * 4 + Vector3i(eixo, 0, 0)]
	var ordem := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
	for eixo in 3:
		var e1 := (eixo + 1) % 3
		var e2 := (eixo + 2) % 3
		for s in [-1, 1]:
			var q := []
			for o in ordem:
				var v := Vector3i.ZERO
				v[eixo] = s
				v[e1] = o.x
				v[e2] = o.y
				q.append(P_.call(v.x, v.y, v.z, eixo))
			var centro: Vector3 = (q[0] + q[2]) / 2.0
			_quad(q[0], q[1], q[2], q[3], cor, centro - meio)
		# Arestas ao longo de `eixo`.
		for o in ordem:
			var a := Vector3i.ZERO
			a[eixo] = -1
			a[e1] = o.x
			a[e2] = o.y
			var b := a
			b[eixo] = 1
			var q0: Vector3 = P_.call(a.x, a.y, a.z, e1)
			var q1: Vector3 = P_.call(b.x, b.y, b.z, e1)
			var q2: Vector3 = P_.call(b.x, b.y, b.z, e2)
			var q3: Vector3 = P_.call(a.x, a.y, a.z, e2)
			_quad(q0, q1, q2, q3, cor.darkened(0.04), (q0 + q2) / 2.0 - meio)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var a0: Vector3 = P_.call(sx, sy, sz, 0)
				var a1: Vector3 = P_.call(sx, sy, sz, 1)
				var a2: Vector3 = P_.call(sx, sy, sz, 2)
				_tri(a0, a1, a2, cor.darkened(0.04), (a0 + a1 + a2) / 3.0 - meio)


## Bloco reto alinhado aos eixos com rotação em graus (atalho de _bloco).
func _blocod(size: Vector3, pos: Vector3, rot: Vector3, cor: Color, chanfro := 0.06, torcer := Callable()) -> void:
	_bloco(size, pos, Basis.from_euler(rot * PI / 180.0), cor, chanfro, torcer)


## Viga chanfrada de `a` até `b` (postes tortos, cumeeiras, varal).
func _viga(a: Vector3, b: Vector3, esp: float, cor: Color, chanfro := 0.04) -> void:
	var d := b - a
	var cima := Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.FORWARD
	var basis := Basis.looking_at(d, cima)
	_bloco(Vector3(esp, esp, d.length()), (a + b) / 2.0, basis, cor, chanfro)


## Superfície com espessura a partir de uma função de altura y = f(x, z):
## telhados curvos. Topo em `cor`, fundo escuro e uma faixa na borda.
func _superficie(base: Vector3, f: Callable, x0: float, x1: float, z0: float, z1: float, nx: int, nz: int, esp: float, cor: Color, cor_borda: Color) -> void:
	var g := []
	for i in nx + 1:
		var linha := []
		for j in nz + 1:
			var x := lerpf(x0, x1, float(i) / nx)
			var z := lerpf(z0, z1, float(j) / nz)
			linha.append(base + Vector3(x, f.call(x, z), z))
		g.append(linha)
	var baixo := Vector3(0, -esp, 0)
	var ao_antes := _ao
	for i in nx:
		for j in nz:
			var a: Vector3 = g[i][j]
			var b: Vector3 = g[i + 1][j]
			var c: Vector3 = g[i + 1][j + 1]
			var d: Vector3 = g[i][j + 1]
			# Leve variação por telha-faixa: pincelada "na mão", não CG liso.
			var tom := cor.darkened(0.05 * float((i * 7 + j * 3) % 3))
			_tipo = 2
			_quad(a, b, c, d, tom, Vector3(0, 1, 0) + (a - base) * 0.05)
			_tipo = 0
			_ao = 0.45
			_quad(a + baixo, b + baixo, c + baixo, d + baixo, Color(0.12, 0.09, 0.1), Vector3(0, -1, 0))
			_ao = ao_antes
	# Faixa da borda (testeira de madeira).
	var borda := []
	for i in nx:
		borda.append([g[i][0], g[i + 1][0], Vector3(0, 0, -1)])
		borda.append([g[i][nz], g[i + 1][nz], Vector3(0, 0, 1)])
	for j in nz:
		borda.append([g[0][j], g[0][j + 1], Vector3(-1, 0, 0)])
		borda.append([g[nx][j], g[nx][j + 1], Vector3(1, 0, 0)])
	for e in borda:
		_quad(e[0], e[1], e[1] + baixo, e[0] + baixo, cor_borda, e[2])


## Altura do telhado de quatro águas japonês (cumeeira em x). Perfil côncavo
## (íngreme em cima, quase plano no beiral), meio da cumeeira cedendo e pontas
## do beiral viradas para cima.
func _altura_telhado(x: float, z: float, W: float, D: float, h: float, ceder: float, curva: float) -> float:
	var r := maxf(W - D, 0.0) / 2.0
	var fz := absf(z) / (D / 2.0)
	var fx := maxf(absf(x) - r, 0.0) / (D / 2.0)
	var fdist := clampf(maxf(fz, fx), 0.0, 1.0)
	var y := h * pow(1.0 - fdist, 1.6)
	y -= ceder * sin(PI * (x / W + 0.5)) * (1.0 - fdist * 0.6)
	var ax := absf(x) / (W / 2.0)
	y += curva * pow(ax * fz, 3.0) + curva * 0.25 * pow(fdist, 3.0)
	return y


func _caixa(size: Vector3, pos: Vector3, rot: Vector3, cor: Color, brilho := false) -> void:
	var m := BoxMesh.new()
	m.size = size
	_prim(m, pos, rot, Vector3.ONE, cor, brilho)


func _cil(top: float, bottom: float, h: float, lados: int, pos: Vector3, rot: Vector3, cor: Color, brilho := false, esc := Vector3.ONE) -> void:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = lados
	m.rings = 1
	m.cap_bottom = false
	m.cap_top = top > 0.0
	_prim(m, pos, rot, esc, cor, brilho)


func _esfera(r: float, pos: Vector3, esc: Vector3, cor: Color, brilho := false, segs := 8, aneis := 4) -> void:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2
	m.radial_segments = segs
	m.rings = aneis
	_prim(m, pos, Vector3.ZERO, esc, cor, brilho)


func _toro(inner: float, outer: float, pos: Vector3, esc: Vector3, cor: Color) -> void:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 16
	m.ring_segments = 4
	_prim(m, pos, Vector3.ZERO, esc, cor, false)


func _prim(mesh: PrimitiveMesh, pos: Vector3, rot_deg: Vector3, esc: Vector3, cor: Color, brilho: bool) -> void:
	var a := mesh.get_mesh_arrays()
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var b := Basis.from_euler(rot_deg * PI / 180.0) * Basis.from_scale(esc)
	var nb := b.inverse().transposed()
	var s := 1 if brilho else 0
	var base: int = V[s].size()
	for i in vs.size():
		V[s].append(b * vs[i] + pos)
		N[s].append((nb * ns[i]).normalized())
		C[s].append(cor)
	for i in ix:
		I[s].append(base + i)
	_tipo_auto = mesh is BoxMesh
	_sincronizar()


func _salvar(nome: String) -> void:
	_contorno = not SEM_CONTORNO.has(nome)
	if not _contorno:  # enfeite miúdo: sem desenho de material (viraria chuvisco)
		for i in U[0].size():
			U[0][i].y = 0.0
	if VENTO.has(nome):
		var topo := 0.1
		for v in V[0]:
			topo = maxf(topo, v.y)
		_vento_planta([0, 0], 0.0, topo, VENTO[nome])
	var mesh := _malha()
	_tris[nome] = _ultima_tris
	var root := Node3D.new()
	root.name = nome
	var mi := MeshInstance3D.new()
	mi.name = "Malha"
	mi.mesh = mesh
	root.add_child(mi)
	mi.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, _dir.path_join(nome + ".scn"))
	root.free()


var _ultima_tris := 0


## Fecha a malha com o que foi desenhado até agora e zera o construtor.
func _malha() -> ArrayMesh:
	# Oclusão de contato: tudo escurece perto do chão (a peça "senta" no terreno).
	# Só em peça com altura: enfeite rasteiro ficaria todo escuro.
	var topo := 0.0
	for v in V[0]:
		topo = maxf(topo, v.y)
	if topo > 0.4:
		var faixa := minf(0.9, topo * 0.25)
		for i in V[0].size():
			var c: Color = C[0][i]
			c.a *= lerpf(0.55, 1.0, smoothstep(0.0, faixa, V[0][i].y))
			C[0][i] = c
	var mesh := ArrayMesh.new()
	_ultima_tris = 0
	for s in 2:
		if V[s].is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V[s]
		arr[Mesh.ARRAY_NORMAL] = N[s]
		arr[Mesh.ARRAY_COLOR] = C[s]
		arr[Mesh.ARRAY_TEX_UV] = U[s]
		arr[Mesh.ARRAY_INDEX] = I[s]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _mat(true) if s == 1 else _mat_pintura())
		_ultima_tris += I[s].size() / 3
	for s in 2:
		V[s] = PackedVector3Array()
		N[s] = PackedVector3Array()
		C[s] = PackedColorArray()
		U[s] = PackedVector2Array()
		I[s] = PackedInt32Array()
	_ao = 1.0
	_vento = 0.0
	_tipo = 0
	return mesh


var _mats := {}


func _mat(brilho: bool) -> StandardMaterial3D:
	var k := _dir + str(brilho)
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	if brilho:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.8, 1.8, 1.8)
	else:
		m.roughness = 0.95
	_mats[k] = m
	return m


func _mat_pintura() -> ShaderMaterial:
	var k := _dir + "pintura" + str(_contorno)
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("cor_sombra", P.sombra)
	m.set_shader_parameter("forca_sombra", P.forca_sombra)
	m.set_shader_parameter("cor_borda", P.borda)
	# Contorno de tinta igual ao dos bonecos (casca invertida), mais fino.
	var c := ShaderMaterial.new()
	c.shader = CONTORNO
	c.set_shader_parameter("espessura", 0.03)
	c.set_shader_parameter("cor", P.tinta)
	if _contorno:
		m.next_pass = c
	_mats[k] = m
	return m


# --- Temas e mapa ----------------------------------------------------------------

func _gerar_temas() -> void:
	var TC: Script = load("res://scripts/data/theme_config.gd")
	var base := {
		"team_model_suffix": PackedStringArray(["azul", "vermelho"]),
		"keep_model": "castelo_{cor}.scn", "keep_scale": 1.0,
		"tower_model": "torre_{cor}.scn", "tower_scale": 1.0,
		"flag_model": "bandeira_{cor}.scn", "flag_scale": 1.0, "flag_height": 4.1,
		"wall_model": "muro.scn", "wall_scale": 1.0, "wall_module_length": 6.0,
		"border_trees": PackedStringArray(["borda_a.scn", "borda_a.scn", "borda_b.scn", "borda_c.scn"]),
		"border_mountains": PackedStringArray(["montanha_a.scn", "montanha_b.scn"]),
		"decor_estrada": {"lajota.scn": 150, "folhas.scn": 30},
	}
	var temas := {
		"dia": {
			"display_name": "Festival ao Sol (dia)", "models_dir": "res://assets/ninja/dia",
			"sun_rotation_deg": Vector3(-55, 30, 0), "sun_color": Color(1.0, 0.95, 0.82), "sun_energy": 1.35,
			"sky_top": Color(0.2, 0.5, 0.95), "sky_horizon": Color(0.68, 0.86, 1.0),
			"ground_horizon": Color(0.5, 0.7, 0.85), "ground_bottom": Color(0.2, 0.35, 0.5),
			"ambient_energy": 1.1, "saturation": 1.25, "contrast": 1.05, "glow_intensity": 0.25,
			"fog_enabled": false, "fog_color": Color(0.7, 0.85, 1.0), "fog_density": 0.002,
			"grass_dark": Color(0.3, 0.62, 0.14), "grass_light": Color(0.45, 0.78, 0.2),
			"road_dark": Color(0.68, 0.6, 0.48), "road_light": Color(0.82, 0.75, 0.6),
			"pedestal_neutral": Color(0.8, 0.72, 0.55),
			"decor_campo": {"capim.scn": 950, "flores.scn": 230, "flores_b.scn": 190, "broto.scn": 130, "pedrinhas.scn": 100, "folhas.scn": 110},
			"particulas": "petalas",
		},
		"crepusculo": {
			"display_name": "Crepúsculo (sombrio)", "models_dir": "res://assets/ninja/crepusculo",
			"sun_rotation_deg": Vector3(-28, 40, 0), "sun_color": Color(1.0, 0.62, 0.36), "sun_energy": 1.7,
			"sky_top": Color(0.17, 0.13, 0.32), "sky_horizon": Color(1.0, 0.5, 0.3),
			"ground_horizon": Color(0.55, 0.32, 0.35), "ground_bottom": Color(0.12, 0.1, 0.2),
			"ambient_energy": 1.0, "saturation": 1.1, "contrast": 1.05, "glow_intensity": 0.6,
			"fog_enabled": true, "fog_color": Color(0.45, 0.32, 0.5), "fog_density": 0.006,
			"grass_dark": Color(0.2, 0.32, 0.14), "grass_light": Color(0.34, 0.42, 0.18),
			"road_dark": Color(0.42, 0.33, 0.3), "road_light": Color(0.55, 0.43, 0.36),
			"pedestal_neutral": Color(0.45, 0.35, 0.35),
			"decor_campo": {"capim.scn": 950, "flores.scn": 110, "flores_b.scn": 80, "folhas.scn": 170, "pedrinhas.scn": 110, "broto.scn": 110, "cogumelos.scn": 70, "lanterna_chao.scn": 16},
			"particulas": "fantasmas",
		},
		"oni": {
			"display_name": "Floresta Oni (noite)", "models_dir": "res://assets/ninja/oni",
			"sun_rotation_deg": Vector3(-50, 35, 0), "sun_color": Color(0.72, 0.8, 1.0), "sun_energy": 1.1,
			"sky_top": Color(0.03, 0.02, 0.07), "sky_horizon": Color(0.3, 0.12, 0.4),
			"ground_horizon": Color(0.1, 0.06, 0.14), "ground_bottom": Color(0.03, 0.02, 0.05),
			"ambient_energy": 1.25, "saturation": 1.05, "contrast": 1.1, "glow_intensity": 0.8,
			"fog_enabled": true, "fog_color": Color(0.22, 0.08, 0.3), "fog_density": 0.006,
			"grass_dark": Color(0.15, 0.13, 0.2), "grass_light": Color(0.22, 0.19, 0.28),
			"road_dark": Color(0.28, 0.26, 0.33), "road_light": Color(0.36, 0.33, 0.42),
			"pedestal_neutral": Color(0.2, 0.15, 0.25),
			"decor_campo": {"capim.scn": 750, "pedrinhas.scn": 140, "folhas.scn": 170, "cogumelos.scn": 90, "broto.scn": 80, "lanterna_chao.scn": 22},
			"particulas": "fantasmas",
		},
		"luar": {
			"display_name": "Templo ao Luar", "models_dir": "res://assets/ninja/luar",
			"sun_rotation_deg": Vector3(-52, 30, 0), "sun_color": Color(0.82, 0.88, 1.0), "sun_energy": 1.15,
			"sky_top": Color(0.04, 0.07, 0.18), "sky_horizon": Color(0.22, 0.32, 0.52),
			"ground_horizon": Color(0.15, 0.2, 0.3), "ground_bottom": Color(0.05, 0.07, 0.12),
			"ambient_energy": 1.0, "saturation": 1.05, "contrast": 1.05, "glow_intensity": 0.6,
			"fog_enabled": true, "fog_color": Color(0.15, 0.2, 0.35), "fog_density": 0.004,
			"grass_dark": Color(0.15, 0.22, 0.2), "grass_light": Color(0.21, 0.29, 0.26),
			"road_dark": Color(0.36, 0.36, 0.4), "road_light": Color(0.45, 0.45, 0.5),
			"pedestal_neutral": Color(0.4, 0.4, 0.5),
			"decor_campo": {"capim.scn": 700, "pedrinhas.scn": 120, "folhas.scn": 220, "cogumelos.scn": 110, "broto.scn": 90, "lanterna_chao.scn": 18},
			"particulas": "petalas",
		},
	}
	for nome in temas:
		var t: Resource = TC.new()
		for k in base:
			t.set(k, base[k])
		for k in temas[nome]:
			t.set(k, temas[nome][k])
		ResourceSaver.save(t, "res://config/temas/%s.tres" % nome)


func _gerar_mapa() -> void:
	var ML: Script = load("res://scripts/data/map_layout.gd")
	var MP: Script = load("res://scripts/data/map_prop.gd")
	var m: Resource = ML.new()
	m.display_name = "Vale dos Dois Clãs"
	# [modelo, posição, rotação (-1 = aleatória), colisor, raio, altura, espelho x, espelho z]
	var meio := [
		["pedra_grande.scn", Vector3(16, 0, 0), -1.0, "cilindro", 1.7, 3.0, true, false],
		["arvore_grande.scn", Vector3(26, 0, 19), -1.0, "cilindro", 2.6, 4.0, true, true],
		["arvore_media.scn", Vector3(8, 0, 12), -1.0, "cilindro", 1.2, 2.0, true, true],
		["arvore_alta.scn", Vector3(0, 0, 24), -1.0, "cilindro", 2.8, 4.0, false, true],
		["torii.scn", Vector3(30, 0, 0), 0.0, "nenhuma", 1.0, 2.0, true, false],
		["estatua.scn", Vector3(30, 0, 6.6), 0.0, "cilindro", 0.8, 2.0, true, true],
		["varal.scn", Vector3(0, 0, 0), 0.0, "nenhuma", 1.0, 2.0, false, false],
		["lanterna_pedra.scn", Vector3(8, 0, 4.6), 0.0, "nenhuma", 0.4, 2.0, true, true],
		["lanterna_pedra.scn", Vector3(22, 0, 4.6), 0.0, "nenhuma", 0.4, 2.0, true, true],
		["lanterna_pedra.scn", Vector3(34, 0, -4.6), 0.0, "nenhuma", 0.4, 2.0, true, true],
		["santuario.scn", Vector3(17, 0, 15), 180.0, "cilindro", 1.3, 2.0, true, true],
		["lago.scn", Vector3(40, 0, 26), 0.0, "cilindro", 3.2, 2.0, true, true],
		["cerca.scn", Vector3(12, 0, 33.5), 0.0, "nenhuma", 1.0, 2.0, true, true],
		["cerca.scn", Vector3(22, 0, 33.8), 8.0, "nenhuma", 1.0, 2.0, true, true],
		["arvore_media.scn", Vector3(52, 0, 29), -1.0, "cilindro", 1.2, 2.0, true, true],
		["arvore_grande.scn", Vector3(64, 0, -2), -1.0, "cilindro", 2.6, 4.0, true, false],
		["pagode.scn", Vector3(0, 0, 13), 0.0, "cilindro", 1.9, 4.0, false, true],
		["ruina.scn", Vector3(24, 0, 9.5), -1.0, "cilindro", 1.4, 2.0, true, true],
		["arvore_media.scn", Vector3(19, 0, 27), -1.0, "cilindro", 1.2, 2.0, true, true],
		["arvore_grande.scn", Vector3(33, 0, 31), -1.0, "cilindro", 2.6, 4.0, true, true],
		["rochas.scn", Vector3(11, 0, 21), -1.0, "cilindro", 1.0, 2.0, true, true],
		["rochas.scn", Vector3(46, 0, 17), -1.0, "cilindro", 1.0, 2.0, true, true],
		["tronco_caido.scn", Vector3(9, 0, 7.5), 20.0, "nenhuma", 1.0, 1.0, true, true],
		["lanterna_pedra.scn", Vector3(3, 0, 9), 0.0, "nenhuma", 0.4, 2.0, true, true],
		["arvore_media.scn", Vector3(2, 0, 33), -1.0, "cilindro", 1.2, 2.0, true, true],
		["santuario.scn", Vector3(56, 0, -20), 90.0, "cilindro", 1.3, 2.0, true, true],
	]
	var patio := [
		["barril.scn", Vector3(-10.5, 0, 10.5), 17.0, false],
		["caixotes.scn", Vector3(-10.8, 0, -10.5), 29.0, false],
		["barraca.scn", Vector3(7.5, 0, -10.8), 90.0, false],
		["lanterna_pedra.scn", Vector3(8.5, 0, 6.8), 0.0, true],
		["lanterna_pedra.scn", Vector3(-4.5, 0, 2.6), 0.0, true],
	]
	var meios: Array[Resource] = []
	for d in meio:
		var p: Resource = MP.new()
		p.model = d[0]; p.position = d[1]; p.scale = 1.0; p.rotation_deg = d[2]
		p.collider = d[3]; p.collider_radius = d[4]; p.collider_height = d[5]
		p.mirror_x = d[6]; p.mirror_z = d[7]
		meios.append(p)
	var patios: Array[Resource] = []
	for d in patio:
		var p: Resource = MP.new()
		p.model = d[0]; p.position = d[1]; p.scale = 1.0; p.rotation_deg = d[2]; p.mirror_z = d[3]
		patios.append(p)
	m.middle_props.assign(meios)
	m.courtyard_props.assign(patios)
	ResourceSaver.save(m, "res://config/mapas/vale_ninja.tres")
