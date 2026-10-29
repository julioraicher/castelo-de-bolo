extends SceneTree
## Gera o cenário ninja por código: modelos (.scn) dos dois temas, os temas
## (config/temas/*.tres) e o mapa (config/mapas/vale_ninja.tres).
##   godot --headless --path . -s tools/gerar_cenario_ninja.gd
## Cada modelo é UMA malha com até 2 superfícies (fosca com cor por vértice +
## brilho sem sombreamento), para o Arena juntar cópias num MultiMesh.
## Mudou cor, forma ou posição? Edite aqui e rode de novo.

const TEMAS := {
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
	},
}
const TIMES := {"azul": Color(0.3, 0.6, 1.0), "vermelho": Color(1.0, 0.3, 0.28)}

var P: Dictionary
var V := [PackedVector3Array(), PackedVector3Array()]
var N := [PackedVector3Array(), PackedVector3Array()]
var C := [PackedColorArray(), PackedColorArray()]
var I := [PackedInt32Array(), PackedInt32Array()]
var _dir := ""
var _tris := {}


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


func _toro_pedra() -> void:
	_cil(0.38, 0.48, 0.25, 6, Vector3(0, 0.12, 0), Vector3.ZERO, P.pedra)
	_cil(0.15, 0.17, 0.8, 6, Vector3(0, 0.65, 0), Vector3.ZERO, P.pedra)
	_cil(0.4, 0.3, 0.15, 6, Vector3(0, 1.1, 0), Vector3.ZERO, P.pedra)
	_caixa(Vector3(0.42, 0.42, 0.42), Vector3(0, 1.38, 0), Vector3.ZERO, P.papel, true)
	_cil(0.05, 0.6, 0.38, 6, Vector3(0, 1.78, 0), Vector3.ZERO, P.pedra2)
	_esfera(0.1, Vector3(0, 2.02, 0), Vector3.ONE, P.pedra2)


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


func _salvar(nome: String) -> void:
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
		arr[Mesh.ARRAY_INDEX] = I[s]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _mat(s == 1))
		_ultima_tris += I[s].size() / 3
	for s in 2:
		V[s] = PackedVector3Array()
		N[s] = PackedVector3Array()
		C[s] = PackedColorArray()
		I[s] = PackedInt32Array()
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
