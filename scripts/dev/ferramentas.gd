class_name Ferramentas
extends Node
## Modos de ferramenta da linha de comando: prints, filme, vitrine, pisca, medição
## de desempenho, pranchas e fotos dos menus. Revisão 3a (NU-11): moravam no
## game.gd (~600 linhas que iam no jogo publicado, misturadas com as regras). O
## Game só cria este nó quando algum argumento daqui aparece (Ferramentas.criar);
## sem ele nada aqui existe. Nada aqui é regra: só fotografa e, nos roteiros
## (filme, vitrine, pranchas), mexe no jogador como um teclado faria.
##   --shots=DIR           salva prints em alguns momentos e fecha o jogo
##   --print-poder[=s]     com --shots: os prints saem s segundos (0,15) depois de cada poder do jogador
##   --mira                com --shots: mostra a mira do jogador no print (segue a mira do bot)
##   --placar              com --shots: placar (Tab) sempre aberto
##   --menu=inicio|pausa   com --autoplay: abre essa tela por cima da partida, sem pausar
##   --vista=mapa|alto|patio|torreta|px,py,pz,ax,ay,az  câmera parada (prints)
##   --filme=DIR           roteiro fixo com o jogador (golpe, dash, pulo, pancada, morte),
##                         um PNG a cada 2 quadros (com --classe=<nome>, filma essa classe)
##   --vitrine=DIR         com --classe: câmera parada, 3 alvos, 3 ataques, Q, E e R;
##                         1 PNG a cada 3 quadros (tools/vitrine.sh faz o GIF antes/depois)
##   --pisca=DIR           chão piscando: câmera andando 1 cm por quadro (PISCA_PASSO=m),
##                         pisca.jpg com o que muda em vermelho (PISCA_FOCO=x,z, PISCA_TUDO=1)
##   --perf=N              desempenho na qualidade N (0-3): a cada 5 s ms de CPU, chamadas,
##                         triângulos e objetos; no começo o CENSO (CENSO_DETALHE=Dono)
##   --tutorial=DIR        print de cada seção do menu e aba do Como jogar, e sai
##   --clipe=DIR --cena=NOME [--clipe-n=N]  grava um clipe do Como jogar (ClipeCenas)
##   --prancha-finalizar=DIR / --prancha-reanimar=DIR  pranchas das personalidades e do reanimar
##   HUD_TESTE=1 / PORRADA_TESTE=1 (ambiente) com --sandbox --shots=DIR: prints do HUD (2.25)
##                         e da porrada (2.26)

var game: Game
var _shots_dir := ""
var _shot_times: Array[float] = [4.0, 15.0, 30.0, 50.0, 75.0]
var _print_poder := false
var _print_atraso := 0.15
var _mira_print := false
var _menu_print := ""
var _vista := ""
var _clipe_dir := ""
var _clipe_max := 40
var _clipe_cena := ""
var _tutorial_dir := ""
var _filme_dir := ""
var _filme_f := -1
var _filme_y := 0.0
var _pisca_dir := ""
var _pisca_f := 0
var _pisca_imgs: Array[Image] = []
var _pisca_quadro := -1
var _vitrine_dir := ""
var _vitrine_f := -1
var _vitrine_p0 := Vector3.ZERO
var _vitrine_alvos: Array[Unit] = []
var _perf_acc := {}
var _perf_n := 0
var _perf_t := 0.0
var _perf_t0 := 0
var _perf_censo := true
var _prancha_rean_dir := ""
var _prancha_fin_dir := ""


## Lê os argumentos que sobraram do Game. Nenhum daqui = null (o jogo segue sem
## o nó). Alguns mexem no Game ou nas Configurações já aqui, antes de montar a
## partida (qualidade fixa no xvfb, modo teste das pranchas).
static func criar(g: Game, args: Array[String]) -> Ferramentas:
	var f := Ferramentas.new()
	f.name = "Ferramentas"
	f.game = g
	var usado := false
	for arg in args:
		var conhecido := true
		if arg.begins_with("--perf="):
			g._perf = true
			Settings.auto_quality = false
			Settings.quality = int(arg.trim_prefix("--perf="))
		elif arg.begins_with("--print-poder"):
			f._print_poder = true
			if arg.contains("="):
				f._print_atraso = float(arg.get_slice("=", 1))
		elif arg == "--mira":
			f._mira_print = true
		elif arg == "--placar":
			g.placar_print = true  # placar (Tab) sempre aberto
		elif arg.begins_with("--filme="):
			f._filme_dir = arg.trim_prefix("--filme=")
		elif arg.begins_with("--pisca="):
			f._pisca_dir = arg.trim_prefix("--pisca=")
			Settings.auto_quality = false
		elif arg.begins_with("--vitrine="):
			f._vitrine_dir = arg.trim_prefix("--vitrine=")
			Settings.auto_quality = false  # o xvfb é lento: sem isso cairia para a Mínima
			Settings.quality = 2
		elif arg.begins_with("--clipe="):
			f._clipe_dir = arg.trim_prefix("--clipe=")
		elif arg.begins_with("--cena="):
			f._clipe_cena = arg.trim_prefix("--cena=")
		elif arg.begins_with("--clipe-n="):
			f._clipe_max = int(arg.trim_prefix("--clipe-n="))
		elif arg.begins_with("--tutorial="):
			f._tutorial_dir = arg.trim_prefix("--tutorial=")
		elif arg.begins_with("--shots="):
			f._shots_dir = arg.trim_prefix("--shots=")
			Settings.auto_quality = false  # o xvfb é lento: sem isso o print sairia na Mínima
		elif arg.begins_with("--menu="):
			f._menu_print = arg.trim_prefix("--menu=")
		elif arg.begins_with("--vista="):
			f._vista = arg.trim_prefix("--vista=")
		elif arg.begins_with("--prancha-finalizar="):
			f._prancha_fin_dir = arg.trim_prefix("--prancha-finalizar=")
			Game.sandbox_pedido = true
			g._autoplay = true
		elif arg.begins_with("--prancha-reanimar="):
			f._prancha_rean_dir = arg.trim_prefix("--prancha-reanimar=")
			Game.sandbox_pedido = true
			g._autoplay = true
			Settings.auto_quality = false
			Settings.quality = 2
		else:
			conhecido = false  # é do Game, da Rede ou de outro modo: não é daqui
		usado = usado or conhecido
	if not usado:
		f.free()
		return null
	if f._print_poder:
		f._shot_times = [1e9, 1e9, 1e9, 1e9, 1e9, 1e9]  # quem marca a hora é o poder
	return f


## Câmera parada das vistas (--vista), logo depois de o Game criar a câmera.
func depois_da_camera() -> void:
	if _vista == "":
		return
	game.camera.set_process(false)
	game.camera.set_physics_process(false)
	game.camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if _vista == "mapa":
		game.camera.fov = 50
		game.camera.position = Vector3(0, 95, 62)
		game.camera.look_at(Vector3(0, 0, 2))
	elif _vista == "patio":
		var cx := -game.arena.map.castle_distance
		game.camera.fov = 42
		game.camera.position = Vector3(cx, 0, 0) + Vector3(0, 21, 19) * 1.55
		game.camera.look_at(Vector3(cx, 0, 0))
	elif _vista == "torreta" and not game.torretas.is_empty():  # a 1ª torreta azul, com a câmera do jogo
		var tp: Vector3 = game.torretas[0].global_position
		game.camera.fov = 42
		game.camera.position = tp + Config.cfg.camera_offset * 0.55
		game.camera.look_at(tp + Vector3(0, 1.2, 0))
	elif _vista.count(",") == 5:  # --vista=px,py,pz,ax,ay,az: câmera em p olhando para a
		var v := _vista.split_floats(",")
		game.camera.fov = 42
		game.camera.position = Vector3(v[0], v[1], v[2])
		game.camera.look_at(Vector3(v[3], v[4], v[5]))
	else:
		game.camera.fov = 45
		game.camera.position = Vector3(-22, 22, 26)
		game.camera.look_at(Vector3(-40, 2, 0))


## Interface pronta: mira no print e HUD escondido nas vistas.
func depois_do_hud() -> void:
	game.mira.para_print = _mira_print
	if _vista != "":
		game.hud.visible = false


## Menus prontos: tela por cima da partida, fotos dos menus, pranchas e clipes.
func depois_dos_menus(menus: Menus) -> void:
	if game._autoplay and _menu_print != "":
		menus.mostrar_para_print(_menu_print)
	if _tutorial_dir != "":
		_prints_tutorial.call_deferred(menus)
	if _prancha_rean_dir != "":
		_prancha_reanimar.call_deferred()
	if _prancha_fin_dir != "":
		_prancha_finalizar.call_deferred()
	if _clipe_dir != "":
		var cc := ClipeCenas.new()
		cc.game = game
		cc.dir = _clipe_dir
		cc.cena = _clipe_cena
		cc.max_quadros = _clipe_max
		game.add_child(cc)


## Filme, vitrine e clipe roteirizam a partida: sem relógio de partida.
func sem_relogio() -> bool:
	return _vitrine_dir != "" or _clipe_dir != "" or _filme_dir != ""


## Vitrine e clipes mostram o R de qualquer classe: o super nunca trava.
func super_livre() -> bool:
	return _vitrine_dir != "" or _clipe_dir != ""


## O jogador usou o poder: o próximo print sai daqui a _print_atraso (--print-poder).
func on_player_power() -> void:
	if _print_poder and _shots_dir != "" and not _shot_times.is_empty():
		_shot_times[0] = game._time + _print_atraso


func _process(delta: float) -> void:
	if game._perf:
		_measure(delta)


## Um passo de física do Game, no mesmo ponto de antes (antes das regras):
## soma do --perf, prints do HUD e da porrada, prints, filme, pisca e vitrine.
func quadro_fisica(delta: float) -> void:
	var t := game._time
	if game._perf:
		for k in game.perf_secoes:
			_perf_acc["us_" + k] = _perf_acc.get("us_" + k, 0.0) + game.perf_secoes[k]
			game.perf_secoes[k] = 0
	# Print do HUD novo (Ciclo 2.25): HUD_TESTE=1 com --sandbox --shots=DIR abre
	# a morte súbita aos 2 s e mostra um triplo aos 14,6 s (print dos 15 s).
	if _shots_dir != "" and game.sandbox and OS.get_environment("HUD_TESTE") != "":
		if t >= 2.0 and t - delta < 2.0:
			game.abrir_morte_subita()
		if t >= 14.6 and t - delta < 14.6:
			game._multikill(game.player, 3, Placar.bonus_degrau(3, Config.cfg))
	# Print da porrada (Ciclo 2.26): PORRADA_TESTE=1 com --sandbox --shots=DIR.
	if _shots_dir != "" and game.sandbox and OS.get_environment("PORRADA_TESTE") != "" and game.pancada:
		_porrada_teste(delta)
	if _shots_dir != "" and not _shot_times.is_empty() and t >= _shot_times[0]:
		_take_shot()
	if _filme_dir != "" and t >= 3.0:
		_filme()
	if _pisca_dir != "" and t >= 1.0:
		_pisca()
	if _vitrine_dir != "" and t >= 1.0:
		_vitrine()


## --perf: média por quadro dos monitores do motor, impressa a cada 10 s.
func _measure(delta: float) -> void:
	var keys := {
		"cpu_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"fisica_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"tris_mil": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0,
		"objetos": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"nos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
	for k in keys:
		_perf_acc[k] = _perf_acc.get(k, 0.0) + keys[k]
	_perf_n += 1
	_perf_t += delta
	if _perf_t >= 5.0:
		if _perf_censo:
			_perf_censo = false
			_censo()
		# FPS pelo relógio real (com --fixed-fps o delta é sempre 1/60).
		var real := (Time.get_ticks_usec() - _perf_t0) / 1e6
		_perf_t0 = Time.get_ticks_usec()
		var out := "PERF t=%d fps=%.1f" % [int(game._time), _perf_n / real]
		for k in _perf_acc:
			out += " %s=%.1f" % [k, _perf_acc[k] / _perf_n]
		print(out)
		_perf_acc.clear()
		_perf_n = 0
		_perf_t = 0.0


## --perf: uma vez, conta o que a cena desenha, agrupado pelo dono (classe do
## script do ancestral mais próximo com script): instâncias, superfícies,
## passes (next_pass) e quem projeta sombra. Serve para achar quem come as
## chamadas de desenho.
func _censo() -> void:
	var grupos := {}
	var fila: Array[Node] = [get_tree().root]
	while not fila.is_empty():
		var n: Node = fila.pop_back()
		fila.append_array(n.get_children())
		var gi := n as GeometryInstance3D
		if gi == null or not gi.is_visible_in_tree():
			continue
		var dono := n
		while dono and dono.get_script() == null:
			dono = dono.get_parent()
		var nome := "?"
		if dono:
			var scr: Script = dono.get_script()
			nome = scr.get_global_name() if scr.get_global_name() != "" else scr.resource_path.get_file()
		nome += "/" + n.get_class()
		var surfs := 1
		var passes := 0
		var mats: Array[Material] = []
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi := n as MeshInstance3D
			surfs = mi.mesh.get_surface_count()
			for si in surfs:
				mats.append(mi.get_active_material(si))
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
			var mm := (n as MultiMeshInstance3D).multimesh
			surfs = mm.mesh.get_surface_count()
			for si in surfs:
				mats.append(gi.material_override if gi.material_override else mm.mesh.surface_get_material(si))
		else:
			mats.append(gi.material_override)
		for m in mats:
			var mm: Material = gi.material_override if gi.material_override else m
			var k := 1
			while mm and mm.next_pass:
				k += 1
				mm = mm.next_pass
			passes += k
		var tris := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			tris = _tris_da_malha((n as MeshInstance3D).mesh)
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
			var mmx := (n as MultiMeshInstance3D).multimesh
			tris = _tris_da_malha(mmx.mesh) * (mmx.visible_instance_count if mmx.visible_instance_count >= 0 else mmx.instance_count)
		if nome.get_slice("/", 0) in OS.get_environment("CENSO_DETALHE").split(","):
			print("CENSO.  %-50s surf=%d passes=%d tris=%d sombra=%s" % [String(n.get_path()).right(60), surfs, passes, tris,
					gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
		var g: Dictionary = grupos.get(nome, {"inst": 0, "surf": 0, "passes": 0, "sombra": 0, "tris": 0})
		g.inst += 1
		g.surf += surfs
		g.passes += passes
		g.tris += tris * maxi(passes / maxi(surfs, 1), 1)
		g.sombra += surfs if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		grupos[nome] = g
	var chaves := grupos.keys()
	chaves.sort_custom(func(a, b): return grupos[a].passes > grupos[b].passes)
	print("CENSO (visíveis): dono/tipo  instâncias  superfícies  passes(=chamadas)  superfícies com sombra  mil tris×passes")
	for k in chaves:
		var g: Dictionary = grupos[k]
		print("CENSO %-44s %5d %5d %5d %5d %7.1f" % [k, g.inst, g.surf, g.passes, g.sombra, g.tris / 1000.0])


func _tris_da_malha(me: Mesh) -> int:
	var tris := 0
	for si in me.get_surface_count():
		var arr := me.surface_get_arrays(si)
		var idx = arr[Mesh.ARRAY_INDEX]
		tris += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return tris


## --tutorial=DIR: fotografa cada seção do menu (tela inicial, Controles,
## Configurações, Classes e cada aba do Como jogar) e sai.
func _prints_tutorial(menus: Menus) -> void:
	menus.mostrar_para_print("inicio")
	var n := 0
	for secao in ["jogar", "controles", "config", "classes"]:
		menus._mostrar(secao)
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/menu_%d_%s.jpg" % [_tutorial_dir, n, secao], 0.85)
		n += 1
	# Com amigos: a entrada e uma sala cheia (amigos de mentira, só para o print).
	menus._mostrar("amigos")
	for f in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/amigos_entrada.jpg" % _tutorial_dir, 0.85)
	if Rede.criar_sala("Julio"):
		for i in 4:
			Rede._adicionar(100 + i, ["Pedro", "Ana", "Lucas", "Bia"][i])
		Rede.jogadores()[100].pronto = true
		Rede.jogadores()[102].pronto = true
		Rede.sala_mudou.emit()
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/amigos_sala.jpg" % _tutorial_dir, 0.85)
		Rede.sair()
	# Uma ficha por classe (barras, textos e quadros de cada uma).
	menus._mostrar("classes")
	for s in PaginaClasses.lista():
		menus._classes._mostrar(s)
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/classe_%s.jpg" % [_tutorial_dir, s.id], 0.85)
	menus._mostrar("como_jogar")
	var tabs: TabContainer = menus._tutorial._tabs
	for i in tabs.get_tab_count():
		tabs.current_tab = i
		for f in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/tutorial_%d.jpg" % [_tutorial_dir, i], 0.85)
	get_tree().quit()


## --prancha-finalizar=DIR (modo teste, xvfb, Ciclo 2.34): para cada
## personalidade o jogador (sem cérebro) fica parado ao lado do herói de treino,
## corre de lado, derruba o herói e segura [F]; cada momento vira um JPG em DIR
## (N-personalidade-parado/correndo/golpe.jpg).
const PRANCHA_PERS := [["pesado", "ronin_oni"], ["samurai", "guerreiro"], ["ninja", "arqueiro"], ["atirador", "arqueiro_yumi"],
		["trapalhao", "construtor"], ["curioso", "kitsune"], ["sereno", "kitsune_luz"], ["predador", "kitsune_sombria"]]

func _prancha_finalizar() -> void:
	DirAccess.make_dir_recursive_absolute(_prancha_fin_dir)
	var h := game.heroi_treino
	var p := game.player
	p.brain = null
	p.move_intent = Vector3.ZERO
	p.wants_attack = false
	p.wants_block = false
	var off0: Vector3 = Config.cfg.camera_offset
	Config.cfg.camera_offset = off0 * 0.42
	var real := func(t: float) -> void:
		await get_tree().create_timer(t, true, false, true).timeout
	var foto := func(nome: String) -> void:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("%s/%s.jpg" % [_prancha_fin_dir, nome], 0.88)
	await real.call(2.2)
	for i in PRANCHA_PERS.size():
		var par: Array = PRANCHA_PERS[i]
		var nome := "%d-%s" % [i + 1, par[0]]
		if not h.alive:
			h._respawn_t = 0.01
		var limite := 0
		while (not h.alive or not h.stats.heroi) and limite < 400:
			limite += 1
			await get_tree().physics_frame
		await get_tree().physics_frame
		p.set_class(load("res://config/classes/%s.tres" % par[1]))
		p.global_position = h.global_position + Vector3(-1.5, 0, 0.5)
		p.reset_physics_interpolation()
		p.aim_dir = Vector3(1, 0, -0.3).normalized()
		p.move_intent = Vector3.ZERO
		game.camera.snap()
		await real.call(1.3)
		await foto.call(nome + "-1-parado")
		p.move_intent = Vector3(0, 0, 1)
		await real.call(0.75)
		await foto.call(nome + "-2-correndo")
		p.move_intent = Vector3.ZERO
		p.global_position = h.global_position + Vector3(-1.3, 0, 0.4)
		p.reset_physics_interpolation()
		p.aim_dir = Vector3(1, 0, -0.3).normalized()
		game.camera.snap()
		h._intocavel_t = 0.0
		h._nao_cai_usado = true
		h.take_damage(h.hp + 999.0, p, Vector3(1, 0, 0))
		await real.call(1.0)
		p.wants_reanimar = true
		limite = 0
		while not h.finalizado and limite < 300:
			limite += 1
			await get_tree().physics_frame
		await real.call(0.16)
		await foto.call(nome + "-3-golpe")
		p.wants_reanimar = false
		await real.call(1.2)
	Config.cfg.camera_offset = off0
	game.camera.snap()
	print("PRANCHA FINALIZAR OK")
	get_tree().quit()


## --prancha-reanimar=DIR (modo teste, xvfb): o jogador sem cérebro reanima o
## aliado de treino num roteiro fixo e cada momento vira um JPG em DIR:
## caído esperando, arrastando, Kitsune abençoando, levantando, câmera do jogo.
func _prancha_reanimar() -> void:
	DirAccess.make_dir_recursive_absolute(_prancha_rean_dir)
	var c := game.reanimar.boneco_treino
	var p := game.player
	p.brain = null
	p.move_intent = Vector3.ZERO
	p.wants_attack = false
	p.wants_block = false
	var off0: Vector3 = Config.cfg.camera_offset
	Config.cfg.camera_offset = off0 * 0.42
	p.set_class(load("res://config/classes/guerreiro.tres"))
	p.global_position = c.global_position + Vector3(-1.3, 0, 0.5)
	p.reset_physics_interpolation()
	p.aim_dir = Vector3(1, 0, 0)
	game.camera.snap()
	var foto := func(nome: String) -> void:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("%s/%s.jpg" % [_prancha_rean_dir, nome], 0.88)
	await get_tree().create_timer(2.2).timeout
	await foto.call("1-caido-esperando")
	p.wants_reanimar = true
	await get_tree().create_timer(0.2).timeout
	p.move_intent = Vector3(-1, 0, -0.3).normalized()
	await get_tree().create_timer(1.2).timeout
	await foto.call("2-arrastando")
	await get_tree().create_timer(1.25).timeout
	p.move_intent = Vector3.ZERO
	var limite := 0
	while not c.alive and limite < 400:
		limite += 1
		await get_tree().physics_frame
	p.wants_reanimar = false
	await get_tree().create_timer(0.3).timeout
	await foto.call("4-levantando")
	limite = 0
	while c.alive and limite < 400:
		limite += 1
		await get_tree().physics_frame
	p.set_class(load("res://config/classes/kitsune_luz.tres"))
	p.global_position = c.global_position + Vector3(-1.2, 0, 0.6)
	p.reset_physics_interpolation()
	await get_tree().create_timer(1.2).timeout
	p.wants_reanimar = true
	await get_tree().create_timer(1.0).timeout
	await foto.call("3-kitsune-abencoando")
	Config.cfg.camera_offset = off0
	game.camera.snap()
	await get_tree().create_timer(0.25).timeout
	await foto.call("5-camera-do-jogo")
	get_tree().quit()


## --filme: o jogador (sem cérebro) faz um roteiro fixo, de lado para a
## câmera, e cada 2 quadros vira um PNG.
## --pisca=DIR: mede o "chão piscando". Com a câmera andando 1 cm por quadro
## (~0,3 px na tela), só bordas e desenhos mais finos que ~3 px mudam de cor de um
## quadro para o outro: é o que o olho vê como piscar/tremer ao andar (desenho
## abaixo de Nyquist, ou faces no mesmo plano brigando na profundidade).
func _pisca() -> void:
	var foco := game.arena.to_world(Config.TEAM_BLUE, -4.0, 0.0)
	if OS.has_environment("PISCA_FOCO"):  # "x,z" no mundo (conferir um achado do QA do mapa)
		var xz := OS.get_environment("PISCA_FOCO").split(",")
		foco = Vector3(float(xz[0]), 0.0, float(xz[1]))
	if _pisca_f == 0:
		game.player.brain = null
		game.player.move_intent = Vector3.ZERO
		game.player.visible = false
		game.hud.visible = false
		game.mira.visible = false
		game.camera.set_process(false)
		game.camera.set_physics_process(false)
		game.camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		game.camera.fov = Config.cfg.camera_fov
	# Roda na física: no xvfb (lento) vários passos de física cabem num quadro
	# desenhado, e capturar a cada passo comparava a MESMA imagem com ela mesma
	# (dava 0 pixels sempre; achado na caça aos bugs 2026-11-15). Um passo de
	# câmera por quadro desenhado: a imagem capturada é a do passo anterior.
	if Engine.get_frames_drawn() == _pisca_quadro:
		return
	_pisca_quadro = Engine.get_frames_drawn()
	if _pisca_f >= 6:  # os primeiros quadros ainda trocam de câmera e escondem a interface
		_pisca_imgs.append(get_viewport().get_texture().get_image())
	var passo := float(OS.get_environment("PISCA_PASSO")) if OS.has_environment("PISCA_PASSO") else 0.01
	game.camera.global_position = foco + Config.cfg.camera_offset + Vector3(passo * _pisca_f, 0, 0)
	game.camera.look_at(foco)
	_pisca_f += 1
	if _pisca_imgs.size() < 6:
		return
	var base: Image = _pisca_imgs[0].duplicate()
	var w := base.get_width()
	var h := base.get_height()
	var mudou := 0
	var marca := Image.create(w, h, false, Image.FORMAT_L8)
	for i in range(1, _pisca_imgs.size()):
		var ant: Image = _pisca_imgs[i - 1]
		var img: Image = _pisca_imgs[i]
		for y in h:
			for x in w:
				if marca.get_pixel(x, y).r > 0.5:
					continue
				var a := ant.get_pixel(x, y)
				var b := img.get_pixel(x, y)
				if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
					marca.set_pixel(x, y, Color.WHITE)
					mudou += 1
	for y in h:
		for x in w:
			if marca.get_pixel(x, y).r > 0.5:
				base.set_pixel(x, y, Color(1, 0.1, 0.1))
	DirAccess.make_dir_recursive_absolute(_pisca_dir)
	base.save_jpg(_pisca_dir.path_join("pisca.jpg"), 0.85)
	if OS.has_environment("PISCA_TUDO"):
		for i in _pisca_imgs.size():
			_pisca_imgs[i].save_png(_pisca_dir.path_join("pisca_%d.png" % i))
	print("PISCA: %d pixels de %d mudaram com a câmera andando %.0f mm por quadro (%.2f%%)" % [mudou, w * h, passo * 1000, 100.0 * mudou / (w * h)])
	get_tree().quit()


func _filme() -> void:
	_filme_f += 1
	var f := _filme_f
	var p := game.player
	var lado := Vector3(-1, 0, 0)
	if f == 0:
		p.brain = null
		p.move_intent = Vector3.ZERO
		p.aim_dir = lado
		p.set_class(load("res://config/classes/%s.tres" % (game._classe_jogador if game._classe_jogador != "" else "guerreiro")))
		p.fill_power()
		# Câmera parada, baixa e de lado, perto do boneco.
		game.hud.visible = false
		game.camera.set_process(false)
		game.camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		game.camera.fov = 30
		game.camera.near = 6.5  # corta o que estiver entre a câmera e o boneco
		_filme_y = p.global_position.y
	# A câmera acompanha o boneco de lado só no chão (o pulo aparece), sem
	# suavizar, para comparar quadros.
	var foco := Vector3(p.global_position.x, _filme_y, p.global_position.z)
	game.camera.global_position = foco + Vector3(0, 3.5, 9.0)
	game.camera.look_at(foco + Vector3(0, 1.2, 0))

	match f:
		10:
			p._attack()
		50:
			p.move_intent = lado
			p._start_dodge()
		66:
			p.move_intent = Vector3.ZERO
		100:
			p.launch(9.0)
		160:
			p.take_damage(4.0, null, -lado, 1.5, true)
		200:
			p.take_damage(9999.0, null, -lado, 1.0, true)
		270:
			get_tree().quit()
	if f % 2 == 0:
		get_viewport().get_texture().get_image().save_png("%s/f_%03d.png" % [_filme_dir, f])


## --vitrine: o mesmo roteiro para qualquer classe (3 ataques, Q, E) com
## câmera fixa e alvos parados que não morrem. Rodar no commit antigo e no
## novo dá o GIF antes/depois de cada poder.
func _vitrine() -> void:
	_vitrine_f += 1
	var f := _vitrine_f
	var p := game.player
	var frente := Vector3(1, 0, 0)
	var corpo := p.stats.attack_kind == "melee"
	if f == 0:
		_vitrine_p0 = Vector3(-24, 0, 0)
		_vitrine_p0.y = game.arena.ground_y(_vitrine_p0.x, _vitrine_p0.z, 10.0)
		game.hud.visible = false
		game.camera.set_process(false)
		game.camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		game.camera.fov = 42
		var aliado: Unit = null
		for u in game.units:
			if u == p:
				continue
			if u.team != p.team and _vitrine_alvos.size() < 3:
				u.brain = null
				_vitrine_alvos.append(u)
			elif u.team == p.team and aliado == null:
				aliado = u  # aliado ferido (cura, bênção, corrida)
			else:
				u.process_mode = Node.PROCESS_MODE_DISABLED
				u.global_position = Vector3(0, -40, 0)
				u.visible = false
		aliado.brain = null
		_vitrine_alvos.append(aliado)
		p.brain = null
	if f == 0 or f == 150 or f == 290:
		p.global_position = _vitrine_p0
		p.reset_physics_interpolation()
		var perto := 2.2 if corpo else 8.0
		var lugares := [Vector3(perto, 0, -0.9), Vector3(perto + 0.6, 0, 1.0), Vector3(perto + 2.0, 0, 0.1), Vector3(-1.6, 0, 1.8)]
		for i in _vitrine_alvos.size():
			var u := _vitrine_alvos[i]
			u.global_position = _vitrine_p0 + lugares[i]
			u.reset_physics_interpolation()
			u.move_intent = Vector3.ZERO
			u.aim_dir = -frente if i < 3 else frente
	var foco := _vitrine_p0 + frente * (1.6 if corpo else 4.6)
	# VITRINE_LONGE=1: a câmera da partida (confere tamanho e leitura de longe).
	game.camera.global_position = foco + (Config.cfg.camera_offset if OS.get_environment("VITRINE_LONGE") != "" else Vector3(0, 6.2, 8.0))
	game.camera.look_at(foco + Vector3(0, 0.8, 0))
	p.move_intent = Vector3.ZERO
	p.aim_dir = frente
	p.aim_point = _vitrine_p0 + frente * (3.0 if corpo else 9.0)
	for i in _vitrine_alvos.size():
		var u := _vitrine_alvos[i]
		if not u.alive:
			continue
		u.hp = maxf(u.hp, u.max_hp() * (0.5 if i == 3 else 0.6))
		if i == 3 and f < 150:
			u.hp = u.max_hp() * 0.4
	match f:
		20, 70, 120:  # 50 quadros: cabe a recarga de qualquer classe e o combo não zera
			p.wants_attack = true
		21, 71, 121:
			p.wants_attack = false
		165:
			p.wants_quick = true
		300:
			p.fill_power()
			p.wants_power = true
		470:  # depois do E acabar (o Redemoinho segura o super enquanto gira)
			p.super_carga = p.POWER_MAX
			p.wants_super = true
		600:
			p.wants_attack = p.stats.super_tipo == "sombra"  # golpe saindo da sombra
		601:
			p.wants_attack = false
		700:
			get_tree().quit()

	if f % 3 == 0 and f >= 6:
		get_viewport().get_texture().get_image().save_png("%s/f_%03d.png" % [_vitrine_dir, f / 3])


## Roteiro do print da porrada: jogador na frente do Samurai de treino; quebra
## a guarda dele, respinga tinta e leva um golpe forte (borda vermelha).
func _porrada_teste(delta: float) -> void:
	var u := game.pancada
	var a := func(t: float) -> bool: return game._time >= t and game._time - delta < t
	if a.call(1.5):
		_shot_times = [4.4, 6.45]
		game.player.brain = null  # parado: quem mexe é o roteiro
		game.player.move_intent = Vector3.ZERO
		game.player.wants_attack = false
		u.guarda = 0.0
		game.player.global_position = u.global_position - game.arena.forward(game.time_jogador) * 1.6
		game.player.reset_physics_interpolation()
		game.camera.snap()
	var dir := (u.global_position - game.player.global_position)
	dir.y = 0.0
	dir = dir.normalized()
	for k in 4:
		if a.call(2.6 + k * 0.35):
			u.yaw = atan2(-dir.x, -dir.z)
			u._blocking = u._guarda_trava_t <= 0.0
			u._block_t = 5.0
			u.take_damage(u.max_hp() * 0.19, game.player, dir, 1.0, true)
	for k in 3:
		if a.call(4.05 + k * 0.1):
			u.take_damage(u.max_hp() * 0.08, game.player, (dir + Vector3(Sorte.r(-0.6, 0.6), 0, 0)).normalized(), 1.0, true)
	if a.call(6.35):
		game.player.take_damage(30.0, u, -dir, 1.4, true)


func _take_shot() -> void:
	var t: float = _shot_times.pop_front()
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/shot_%03d.png" % [_shots_dir, int(t)])
	if _shot_times.is_empty():
		get_tree().quit()
