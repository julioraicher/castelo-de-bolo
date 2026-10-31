extends Node
## QA automático do mapa (direção do Ciclo 2.3, seção 4). Monta a partida e
## gera um texto curto (qa_mapa.txt, até 30 linhas) e, se houver tela, uma
## vista de cima (qa_mapa.jpg) com os problemas numerados:
##   godot --headless --path . --fixed-fps 60 -- --qa-mapa=DIR
##   (com xvfb e sem --headless sai também a imagem)
## 1. Passagem: grade de 1 m no chão andável; caminho de navegação de cada
##    castelo até cada ponto. Acusa inalcançável e desvio > DESVIO_MAX
##    (comprimento do caminho / distância reta: beco ou passagem fechada).
## 2. Escondido: câmera do jogo num anel em volta de cada objeto importante;
##    raio câmera -> objeto. Bloqueado em mais de 40% = escondido. Só vê
##    colisores (telhado sem colisão não conta).
## 3. Bot preso: TEMPO_PRESOS s de partida; quem quer andar e sai menos de
##    0,3 m em 3 s.
## Pontos vizinhos viram um problema só (células de CELULA m).
## QA_DBG=1 no ambiente imprime cada amostra de bot preso (nome, classe, objetivo).

const DESVIO_MAX := 2.5
const BLOQUEIO_MAX := 0.4
const TEMPO_PRESOS := 180.0
const CELULA := 5.0
const MAX_LINHAS := 30

var game  # Game (sem tipo: o script é carregado em tempo de execução)
var dir := ""
var _problemas: Array = []  # [texto, Vector3, peso]
var _n_pontos := 0
var _n_alvos := 0
var _n_amostras := 0


func _ready() -> void:
	game.get_node("/root/Config").cfg.score_to_win = 999  # a partida não acaba no meio
	await get_tree().create_timer(1.0).timeout  # navegação sincronizada
	var t0 := Time.get_ticks_msec()
	_passagem()
	_escondidos()
	print("QA: passagem e escondidos em %d ms" % (Time.get_ticks_msec() - t0))
	await _presos()
	await _salvar()
	get_tree().quit(0)


func _add(texto: String, pos: Vector3, peso := 1) -> void:
	_problemas.append([texto, pos, peso])


## Agrupa pontos em células de CELULA m: [centro médio, quantidade].
func _agrupar(pontos: Array) -> Array:
	var cel := {}
	for p in pontos:
		var k := Vector2i(floori(p.x / CELULA), floori(p.z / CELULA))
		if not cel.has(k):
			cel[k] = [Vector3.ZERO, 0]
		cel[k][0] += p
		cel[k][1] += 1
	var out := []
	for k in cel:
		out.append([cel[k][0] / cel[k][1], cel[k][1]])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out


func _passagem() -> void:
	var arena = game.arena
	var nav: RID = arena.get_world_3d().navigation_map
	var hw: float = arena.map.half_width
	var hd: float = arena.map.half_depth
	var space: PhysicsDirectSpaceState3D = arena.get_world_3d().direct_space_state
	for team in 2:
		var origem := NavigationServer3D.map_get_closest_point(nav, arena.spawn_center[team])
		var fora := []
		var volta := []
		var x := -hw + 1.0
		while x <= hw - 1.0:
			var z := -hd + 1.0
			while z <= hd - 1.0:
				var p := Vector3(x, 0, z)
				var q := NavigationServer3D.map_get_closest_point(nav, p)
				if Vector2(q.x - x, q.z - z).length() < 0.35 and q.y < 1.0 and _chao(space, p):
					_n_pontos += 1
					var path := NavigationServer3D.map_get_path(nav, origem, q, true)
					if path.is_empty() or path[path.size() - 1].distance_to(q) > 1.0:
						fora.append(q)
					else:
						var reta := origem.distance_to(q)
						var compr := 0.0
						for i in range(1, path.size()):
							compr += path[i - 1].distance_to(path[i])
						if reta > 6.0 and compr / reta > DESVIO_MAX:
							volta.append(q)
				z += 1.0
			x += 1.0
		var nome: String = ["Azul", "Vermelho"][team]
		for g in _agrupar(fora):
			_add("inalcançável do castelo %s (%d pontos)" % [nome, g[1]], g[0], g[1])
		for g in _agrupar(volta):
			_add("desvio > %.1fx do castelo %s (%d pontos)" % [DESVIO_MAX, nome, g[1]], g[0], g[1])


## O primeiro colisor de cima para baixo é o chão (e não o topo de uma casa,
## pedra ou muralha, onde a navegação também deixa ilhas que ninguém pisa).
func _chao(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 20, 0), p + Vector3(0, -5, 0), 1))
	return h.is_empty() or h.position.y < 0.3


func _escondidos() -> void:
	var cfg = game.get_node("/root/Config").cfg
	var space: PhysicsDirectSpaceState3D = game.arena.get_world_3d().direct_space_state
	var alvos := []  # [nome, pos, raio do próprio objeto]
	for pad in game.hat_pads:
		alvos.append(["maquininha %s" % pad.stats.display_name, pad.global_position, 1.5])
	for p in game.pilhas:
		alvos.append(["pilha de madeira", p.global_position, 1.5])
	for p in game.plantas:
		alvos.append([p.tipo, p.global_position, 1.5])
	for of in game.oficinas:
		alvos.append(["oficina", of.global_position, 2.5])
	for team in 2:
		alvos.append(["máscara", game.arena.princess_spot[team], 1.5])
		alvos.append(["saída do castelo", game.arena.gate_spot[team], 1.5])
	_n_alvos = alvos.size()
	for a in alvos:
		var alvo: Vector3 = a[1] + Vector3(0, 1.0, 0)
		var bloq := 0
		var n := 8
		for i in n:
			var ang := TAU * i / n
			var foco: Vector3 = a[1] + Vector3(cos(ang), 0, sin(ang)) * 3.0
			var cam: Vector3 = foco + cfg.camera_offset
			var q := PhysicsRayQueryParameters3D.create(cam, alvo, 1)  # LAYER_WORLD
			var hit := space.intersect_ray(q)
			if hit and hit.position.distance_to(alvo) > a[2]:
				bloq += 1
		if float(bloq) / n > BLOQUEIO_MAX:
			_add("escondido: %s (%d/%d vistas bloqueadas)" % [a[0], bloq, n], a[1], 50)


func _presos() -> void:
	var antes := {}
	var presos := []
	var t := 0.0
	while t < TEMPO_PRESOS:
		await get_tree().create_timer(3.0, true, true).timeout
		t += 3.0
		for u in game.units:
			var p: Vector3 = u.global_position
			_n_amostras += 1
			if antes.has(u) and u.alive and u.move_intent.length() > 0.1 and p.distance_to(antes[u]) < 0.3:
				presos.append(p)
				if OS.has_environment("QA_DBG"):
					print("PRESO %s %s pos=(%.1f,%.1f) goal=%s tora=%s" % [u.name, u.stats.id, p.x, p.z, u.brain.get("_goal"), u.carried_tora != null])
			antes[u] = p
	for g in _agrupar(presos):
		if g[1] >= 4:  # até ~9 s parado é briga ou fila, não beco
			_add("bot preso (%d vezes)" % g[1], g[0], g[1])


func _salvar() -> void:
	_problemas.sort_custom(func(a, b): return a[2] > b[2])
	var linhas := PackedStringArray()
	linhas.append("QA do mapa %s: %d problemas (%d pontos x 2 castelos, %d objetos, %d amostras de bot)" % [
		game.arena.map.display_name, _problemas.size(), _n_pontos / 2, _n_alvos, _n_amostras])
	for i in mini(_problemas.size(), MAX_LINHAS - 1):
		var p = _problemas[i]
		linhas.append("%d. %s  x=%.0f z=%.0f" % [i + 1, p[0], p[1].x, p[1].z])
	var texto := "\n".join(linhas)
	print(texto)
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("qa_mapa.txt"), FileAccess.WRITE)
	if f:
		f.store_string(texto + "\n")
		f.close()
	if DisplayServer.get_name() == "headless":
		return
	# Vista de cima com os pontos numerados iguais ao texto.
	for i in mini(_problemas.size(), MAX_LINHAS - 1):
		var pos: Vector3 = _problemas[i][1]
		var bola := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.9
		sp.height = 1.8
		bola.mesh = sp
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1, 0.1, 0.1)
		m.no_depth_test = true
		bola.material_override = m
		game.add_child(bola)
		bola.global_position = pos + Vector3(0, 1, 0)
		var l := Label3D.new()
		l.text = str(i + 1)
		l.font_size = 96
		l.pixel_size = 0.03
		l.outline_size = 18
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		game.add_child(l)
		l.global_position = pos + Vector3(0, 3.5, 0)
	var cam: Camera3D = game.camera
	cam.set_process(false)
	cam.set_physics_process(false)
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam.fov = 50
	cam.position = Vector3(0, 95, 62)
	cam.look_at(Vector3(0, 0, 2))
	game.hud.visible = false
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img.get_width() > 1280:
		img.resize(1280, int(img.get_height() * 1280.0 / img.get_width()))
	img.save_jpg(dir.path_join("qa_mapa.jpg"), 0.8)
