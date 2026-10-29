extends "res://tools/gerar_cenario_ninja.gd"
## Catálogo de peças de cenário CANDIDATAS (ainda fora do jogo), para o Julio
## escolher por número. Usa o mesmo construtor de malha do gerador.
## Uso (xvfb no servidor):
##   xvfb-run -a -s "-screen 0 800x600x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy -s tools/prancha_catalogo.gd -- DIR [oni|luar]
## Salva DIR/peca_NN.png (uma por peça); a montagem com números é feita fora.

const PECAS := ["ponte", "riacho", "portao", "vigia", "sino", "casa", "festival", "jardim", "cachoeira", "barricada", "arvore_espirito", "jizos"]

var _saida := "user://catalogo"
var _cena: Node3D


func _gerar_tudo() -> bool:
	return false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	P = TEMAS[args[1] if args.size() > 1 else "oni"]
	_dir = "catalogo"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar.call_deferred()


func _rodar() -> void:
	root.size = Vector2i(800, 600)
	for i in PECAS.size():
		_cena = Node3D.new()
		root.add_child(_cena)
		_luz()
		call("_c_" + PECAS[i])
		var mi := MeshInstance3D.new()
		mi.mesh = _malha()
		_cena.add_child(mi)
		var bb := mi.get_aabb()
		var centro := bb.get_center()
		var raio := bb.size.length() * 0.5
		var cam := Camera3D.new()
		cam.fov = 40
		_cena.add_child(cam)
		cam.position = centro + Vector3(0.55, 0.5, 0.8).normalized() * raio * 2.9
		cam.look_at(centro)
		for k in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_saida.path_join("peca_%02d.png" % (i + 1)))
		print("salvo peça ", i + 1, " ", PECAS[i])
		_cena.queue_free()
		await process_frame
	quit()


func _luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.05, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.8)
	env.ambient_light_energy = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_cena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(0.8, 0.85, 1.0)
	sol.light_energy = 1.2
	sol.rotation_degrees = Vector3(-50, 35, 0)
	sol.shadow_enabled = true
	_cena.add_child(sol)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	chao.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.17, 0.15, 0.22)
	chao.material_override = m
	_cena.add_child(chao)


# --- Peças candidatas ----------------------------------------------------------

## 1. Ponte arqueada (taikobashi) sobre um canal.
func _c_ponte() -> void:
	_caixa(Vector3(10, 0.06, 4.0), Vector3(0, 0.03, 0), Vector3.ZERO, P.agua)
	for i in 11:
		var t := (i - 5) / 5.0
		_caixa(Vector3(2.4, 0.18, 0.6), Vector3(0, 0.25 + 1.0 * (1.0 - t * t), t * 3.2), Vector3(-atan(-2.0 * t * 1.0 / 3.2) * 57.3, 0, 0), P.torii)
	for x in [-1.2, 1.2]:
		for i in 5:
			var t := (i - 2) / 2.0
			_cil(0.06, 0.06, 0.8, 5, Vector3(x, 1.65 - 1.0 * t * t * 0.9, t * 2.8), Vector3.ZERO, P.torii)
		_esfera(0.12, Vector3(x, 2.15, 0), Vector3.ONE, P.ouro, true)


## 2. Riacho com pedras de travessia e juncos.
func _c_riacho() -> void:
	for i in 6:
		_caixa(Vector3(2.2, 0.05, 2.4), Vector3(sin(i * 0.8) * 0.5, 0.03, i * 2.2 - 5.5), Vector3(0, sin(i) * 15, 0), P.agua.lightened(0.05 * (i % 2)))
	for i in 5:
		_esfera(0.35, Vector3(cos(i * 1.3) * 0.4, 0.1, i * 2.2 - 4.4), Vector3(1, 0.4, 1), P.pedra, false, 6, 3)
	for i in 10:
		var s := -1.0 if i % 2 else 1.0
		_cil(0.0, 0.05, 0.9, 3, Vector3(s * 1.4, 0.45, i * 1.1 - 5.5), Vector3(s * 8, 0, 0), P.capim)
	_esfera(0.1, Vector3(0.5, 0.4, 1.0), Vector3.ONE, P.luz1, true)
	_esfera(0.1, Vector3(-0.4, 0.6, -2.0), Vector3.ONE, P.luz1, true)


## 3. Portão do castelo (karamon) com portas pesadas.
func _c_portao() -> void:
	for z in [-2.6, 2.6]:
		_caixa(Vector3(1.4, 4.2, 1.2), Vector3(0, 2.1, z), Vector3.ZERO, P.pedra)
	_caixa(Vector3(1.2, 0.5, 6.4), Vector3(0, 4.3, 0), Vector3.ZERO, P.madeira)
	_cil(0.3, 2.6, 1.3, 4, Vector3(0, 5.2, 0), Vector3(0, 45, 0), P.telhado, false, Vector3(0.7, 1, 1.6))
	for z in [-1.0, 1.0]:
		_caixa(Vector3(0.25, 3.6, 1.9), Vector3(0.2, 1.8, z), Vector3(0, z * 25, 0), P.madeira2)
		for y in [0.8, 1.8, 2.8]:
			_caixa(Vector3(0.3, 0.1, 1.9), Vector3(0.2, y, z), Vector3(0, z * 25, 0), Color(0.15, 0.15, 0.18))
	_caixa(Vector3(1.25, 0.12, 6.4), Vector3(0, 4.05, 0), Vector3.ZERO, Color(0.3, 0.6, 1.0) * 1.4, true)


## 4. Torre de vigia de madeira (poderia ser construível na Fase 2).
func _c_vigia() -> void:
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_cil(0.1, 0.12, 5.0, 5, Vector3(x, 2.5, z), Vector3(-z * 4, 0, x * 4), P.madeira)
	_caixa(Vector3(2.6, 0.2, 2.6), Vector3(0, 5.0, 0), Vector3.ZERO, P.madeira2)
	for s in [-1, 1]:
		_caixa(Vector3(2.6, 0.6, 0.08), Vector3(0, 5.4, s * 1.3), Vector3.ZERO, P.madeira)
		_caixa(Vector3(0.08, 0.6, 2.6), Vector3(s * 1.3, 5.4, 0), Vector3.ZERO, P.madeira)
	_cil(0.1, 2.1, 1.0, 4, Vector3(0, 6.7, 0), Vector3(0, 45, 0), P.telhado)
	for k in 8:
		_caixa(Vector3(0.6, 0.06, 0.06), Vector3(0, 0.5 + k * 0.6, 1.25), Vector3.ZERO, P.madeira2)
	_esfera(0.22, Vector3(1.2, 5.9, 1.2), Vector3(1, 1.3, 1), P.papel, true)


## 5. Campanário do templo (shoro) com sino de bronze.
func _c_sino() -> void:
	_caixa(Vector3(3.2, 0.5, 3.2), Vector3(0, 0.25, 0), Vector3.ZERO, P.pedra)
	for x in [-1.3, 1.3]:
		for z in [-1.3, 1.3]:
			_cil(0.12, 0.14, 3.0, 6, Vector3(x, 2.0, z), Vector3.ZERO, P.madeira)
	_cil(0.2, 2.6, 1.2, 4, Vector3(0, 4.0, 0), Vector3(0, 45, 0), P.telhado)
	_cil(0.55, 0.7, 1.4, 10, Vector3(0, 2.4, 0), Vector3.ZERO, Color(0.35, 0.45, 0.35))
	_esfera(0.55, Vector3(0, 3.1, 0), Vector3(1, 0.5, 1), Color(0.35, 0.45, 0.35))
	_cil(0.1, 0.1, 2.0, 6, Vector3(0, 2.1, 1.0), Vector3(0, 0, 90), P.madeira2)


## 6. Casa da vila (machiya) com placa de neon.
func _c_casa() -> void:
	_caixa(Vector3(5.0, 2.6, 3.6), Vector3(0, 1.3, 0), Vector3.ZERO, P.madeira2)
	_caixa(Vector3(3.6, 1.4, 0.05), Vector3(0, 1.2, 1.82), Vector3.ZERO, P.papel, true)
	for k in 7:
		_caixa(Vector3(0.06, 1.5, 0.06), Vector3(-1.8 + k * 0.6, 1.2, 1.86), Vector3.ZERO, P.madeira)
	_cil(0.2, 3.9, 1.3, 4, Vector3(0, 3.25, 0), Vector3(0, 45, 0), P.telhado, false, Vector3(1.0, 1, 0.75))
	_caixa(Vector3(0.12, 2.0, 0.7), Vector3(2.7, 2.4, 1.2), Vector3.ZERO, Color(0.05, 0.05, 0.08))
	for k in 3:
		_caixa(Vector3(0.14, 0.12, 0.45), Vector3(2.72, 3.0 - k * 0.55, 1.2), Vector3.ZERO, P.luz2 * 1.4, true)
	_caixa(Vector3(5.0, 0.6, 0.03), Vector3(0, 2.3, 1.84), Vector3.ZERO, P.luz2, false)


## 7. Fileira de barracas de festival com máscaras e lanternas.
func _c_festival() -> void:
	for i in 3:
		var x := (i - 1) * 3.2
		for z in [-0.9, 0.9]:
			_cil(0.07, 0.07, 2.3, 5, Vector3(x - 1.3, 1.15, z), Vector3.ZERO, P.madeira)
			_cil(0.07, 0.07, 2.3, 5, Vector3(x + 1.3, 1.15, z), Vector3.ZERO, P.madeira)
		_caixa(Vector3(2.9, 0.12, 2.2), Vector3(x, 2.35, 0), Vector3(-8, 0, 0), [P.torii, P.telhado, P.luz2][i])
		_caixa(Vector3(2.6, 0.8, 0.6), Vector3(x, 0.4, 0.8), Vector3.ZERO, P.madeira2)
		for k in 3:
			_esfera(0.16, Vector3(x - 0.7 + k * 0.7, 1.6, 1.0), Vector3(1, 1.1, 0.5), [P.branco, P.torii, P.luz1][k])
	for i in 7:
		_esfera(0.2, Vector3(-4.6 + i * 1.53, 2.7 - sin(i / 6.0 * PI) * 0.3, 1.2), Vector3(1, 1.3, 1), P.papel, true)


## 8. Jardim zen: areia rastelada e pedras.
func _c_jardim() -> void:
	_caixa(Vector3(7, 0.08, 5), Vector3(0, 0.04, 0), Vector3.ZERO, Color(0.75, 0.73, 0.7))
	for k in 12:
		_caixa(Vector3(6.8, 0.03, 0.06), Vector3(0, 0.09, -2.3 + k * 0.42), Vector3.ZERO, Color(0.62, 0.6, 0.58))
	for p in [Vector3(-1.8, 0.4, -0.6), Vector3(1.5, 0.5, 0.8), Vector3(0.4, 0.3, -1.4)]:
		_esfera(0.7, p, Vector3(1, 0.8, 0.8), P.pedra, false, 6, 3)
		_toro(0.75, 1.0, Vector3(p.x, 0.09, p.z), Vector3(1, 0.05, 1), Color(0.62, 0.6, 0.58))
	for s in [-1, 1]:
		_caixa(Vector3(7.2, 0.25, 0.25), Vector3(0, 0.12, s * 2.6), Vector3.ZERO, P.madeira)


## 9. Cachoeira pequena saindo de um paredão, com lago.
func _c_cachoeira() -> void:
	_esfera(3.0, Vector3(0, 1.5, -1.5), Vector3(1.3, 1.1, 0.6), P.pedra2, false, 7, 4)
	_esfera(1.6, Vector3(-2.6, 1.0, -0.6), Vector3(1, 0.9, 0.8), P.pedra, false, 6, 3)
	_esfera(1.4, Vector3(2.6, 0.9, -0.6), Vector3(1, 0.9, 0.8), P.pedra, false, 6, 3)
	for k in 3:
		_caixa(Vector3(0.5, 3.0, 0.08), Vector3(-0.5 + k * 0.5, 1.6, 0.25 + k * 0.03), Vector3(-8, 0, 0), P.agua.lightened(0.4) if k == 1 else P.agua.lightened(0.25), true)
	_cil(2.4, 2.4, 0.05, 14, Vector3(0, 0.04, 1.6), Vector3.ZERO, P.agua)
	for k in 6:
		_esfera(0.18, Vector3(-0.6 + k * 0.25, 0.15, 0.6 + sin(k) * 0.2), Vector3.ONE, P.branco, true, 5, 3)


## 10. Barricada de estacas (o Construtor poderia erguer).
func _c_barricada() -> void:
	for k in 5:
		var x := -2.0 + k
		_cil(0.0, 0.12, 2.2, 5, Vector3(x, 0.7, 0.35), Vector3(-50, 0, 0), P.madeira2)
		_cil(0.0, 0.12, 2.2, 5, Vector3(x + 0.5, 0.7, -0.35), Vector3(50, 0, 0), P.madeira2)
	_cil(0.12, 0.12, 5.0, 6, Vector3(0, 0.75, 0), Vector3(0, 0, 90), P.madeira)
	_caixa(Vector3(0.3, 0.45, 0.04), Vector3(0, 1.0, 0.15), Vector3.ZERO, P.branco, true)


## 11. Árvore-espírito gigante com orbes de fogo-fantasma.
func _c_arvore_espirito() -> void:
	_cil(1.0, 1.7, 5.5, 9, Vector3(0, 2.75, 0), Vector3.ZERO, P.tronco)
	for k in 5:
		var a := TAU * k / 5.0
		_cil(0.2, 0.55, 3.0, 6, Vector3(cos(a) * 1.4, 6.0, sin(a) * 1.4), Vector3(sin(a) * 35, 0, -cos(a) * 35), P.tronco)
		_esfera(2.0, Vector3(cos(a) * 2.8, 7.6, sin(a) * 2.8), Vector3(1, 0.6, 1), P.folha2 if k % 2 else P.folha, false, 7, 4)
		_esfera(0.18, Vector3(cos(a + 0.5) * 3.2, 5.6, sin(a + 0.5) * 3.2), Vector3(1, 1.4, 1), P.luz1 if k % 2 else P.luz2, true)
	_toro(1.55, 1.8, Vector3(0, 2.4, 0), Vector3(1, 0.6, 1), P.corda)
	for k in 8:
		var a := TAU * k / 8.0
		_cil(0.2, 0.45, 1.6, 5, Vector3(cos(a) * 1.8, 0.3, sin(a) * 1.8), Vector3(sin(a) * 70, 0, -cos(a) * 70), P.tronco)


## 12. Fileira de estátuas jizo com babadores vermelhos e velas.
func _c_jizos() -> void:
	for k in 5:
		var x := -2.4 + k * 1.2
		_caixa(Vector3(0.8, 0.3, 0.8), Vector3(x, 0.15, 0), Vector3.ZERO, P.pedra2)
		_cil(0.25, 0.32, 0.9, 7, Vector3(x, 0.75, 0), Vector3.ZERO, P.pedra)
		_esfera(0.26, Vector3(x, 1.4, 0), Vector3.ONE, P.pedra)
		_cil(0.33, 0.36, 0.25, 7, Vector3(x, 1.1, 0.02), Vector3.ZERO, Color(0.85, 0.12, 0.12))
		_esfera(0.05, Vector3(x + 0.3, 0.4, 0.45), Vector3(1, 1.6, 1), P.luz1, true)
