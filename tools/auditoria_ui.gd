extends SceneTree
## Auditoria da interface (Ciclo 2.33): abre cada tela (HUD com os painéis da
## escolha de caminho e de herói raro, placar, tela inicial, pausa, Com amigos,
## fichas das Classes, abas do Como jogar) em várias resoluções e confere, por
## medida, se algum texto:
##   - vaza da moldura em que está (cartão, botão, placa);
##   - sai da tela;
##   - precisa de mais altura/largura do que recebeu (texto por cima do vizinho);
## e se dois blocos do HUD (painel da escolha, minimapa, cartão do jogador,
## dica do F...) se sobrepõem. Imprime "UI FALHA ..." e sai 1 se achar algo.
## Só medir (é o que o CI roda; não precisa de xvfb):
##   godot --headless --path . -s tools/auditoria_ui.gd -- --sandbox --sem-prints
## Com prints (DIR recebe um JPG por tela e resolução, só do HUD, placar e menus):
##   xvfb-run -a -s "-screen 0 2600x1500x24" godot --path . --rendering-driver opengl3 \
##     --rendering-method gl_compatibility --audio-driver Dummy \
##     -s tools/auditoria_ui.gd -- DIR --sandbox [--res=1280x720,1024x768]
## UI_DEBUG=1 lista os blocos do HUD de cada tela. A tela lógica nunca fica menor
## que 1600x900 (stretch canvas_items + expand): janela 4:3 ganha altura, 21:9
## ganha largura. Sem tipos do jogo aqui (ver CLAUDE.md).

const RESOLUCOES := ["1280x720", "1366x768", "1920x1080", "2560x1440", "1024x768", "1280x1024", "2560x1080"]

var _saida := ""
var _prints := true
var _res_atual := ""
var _falhas: Array[String] = []
var _telas := 0
var _g: Node
var _hud: Node
var _menus: Node


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var resolucoes: Array = RESOLUCOES.duplicate()
	for a in args:
		if a.begins_with("--res="):
			resolucoes = a.trim_prefix("--res=").split(",")
		elif a == "--sem-prints":
			_prints = false
		elif not a.begins_with("--"):
			_saida = a
	if _saida != "":
		DirAccess.make_dir_recursive_absolute(_saida)
	var settings := root.get_node("/root/Settings")
	settings.auto_quality = false
	settings.tutorial_visto = true
	var jogo: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(jogo)
	for k in 30:
		await process_frame
	_g = jogo if "oficinas" in jogo else jogo.find_child("Game", true, false)
	_hud = _g.hud
	for m in _g.get_children():
		if "_painel" in m and "_secoes" in m:
			_menus = m
	_menus._painel.visible = false
	paused = true  # nada anda: o painel da escolha não fecha sozinho
	for r in resolucoes:
		var p: PackedStringArray = String(r).split("x")
		_res_atual = r
		root.size = Vector2i(int(p[0]), int(p[1]))
		await _quadros(6)
		print("UI resolução %s: tela lógica %s" % [r, root.get_visible_rect().size])
		await _auditar_hud()
		await _auditar_menus()
	print("UI %d telas conferidas, %d falhas" % [_telas, _falhas.size()])
	quit(1 if not _falhas.is_empty() else 0)


func _quadros(n: int) -> void:
	for k in n:
		await process_frame


func _foto(nome: String) -> void:
	if not _prints or _saida == "":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_width() > 1280:
		img.resize(1280, int(img.get_height() * 1280.0 / img.get_width()), Image.INTERPOLATE_BILINEAR)
	img.save_jpg(_saida.path_join("%s_%s.jpg" % [_res_atual, nome]), 0.82)


# --- Telas ---------------------------------------------------------------------

func _auditar_hud() -> void:
	_menus._painel.visible = false
	var feitas := {}
	for of in _g.oficinas:
		if of.team != _g.player.team or of.base == null:
			continue
		var id := String(of.base.id)
		if feitas.has(id):
			continue
		feitas[id] = true
		if not of.caminhos().is_empty():
			_hud.abrir_escolha(of, func(_i): pass)
			await _quadros(4)
			_checar(_hud, "caminho_" + id)
			_blocos_hud("caminho_" + id)
			if id == "guerreiro":
				await _foto("painel_caminho")
		if not of.herois().is_empty():
			_hud.abrir_escolha(of, func(_i): pass, true)
			await _quadros(4)
			_checar(_hud, "heroi_%s(%d)" % [id, of.herois().size()])
			_blocos_hud("heroi_" + id)
			if id == "guerreiro" or of.herois().size() >= 5:
				await _foto("painel_heroi_" + id)
		_hud.fechar_escolha()
	await _quadros(2)
	_checar(_hud, "hud")
	_blocos_hud("hud")
	# Placar (Tab).
	for c in _g.get_children():
		if c.has_method("_preencher") and "_corpo" in c:
			c._abrir()
			await _quadros(6)
			_checar(c, "placar")
			await _foto("placar")
			c.visible = false


func _auditar_menus() -> void:
	for modo in ["inicio", "pausa"]:
		_menus.mostrar_para_print(modo)
		for secao in ["jogar", "controles", "config"]:
			_menus._mostrar(secao)
			await _quadros(4)
			_checar(_menus, "%s_%s" % [modo, secao])
			if modo == "pausa" and secao in ["controles", "config"]:
				await _foto("pausa_" + secao)
	_menus.mostrar_para_print("inicio")
	await _quadros(2)
	await _foto("inicio")
	_menus._mostrar("amigos")
	await _quadros(4)
	_checar(_menus, "amigos_entrada")
	var rede := root.get_node("/root/Rede")
	if rede.criar_sala("Julio"):
		for i in 7:
			rede._adicionar(100 + i, ["Pedro", "Ana", "Lucas", "Bia", "Maximiliano", "Gabriela", "Teo"][i])
		rede.sala_mudou.emit()
		await _quadros(4)
		_checar(_menus, "amigos_sala")
		await _foto("amigos_sala")
		rede.sair()
	_menus._mostrar("classes")
	for s in _menus._classes.lista():
		_menus._classes._mostrar(s)
		await _quadros(3)
		_checar(_menus, "classe_" + String(s.id))
	_menus._mostrar("como_jogar")
	var tabs: TabContainer = _menus._tutorial._tabs
	for i in tabs.get_tab_count():
		tabs.current_tab = i
		await _quadros(3)
		_checar(_menus, "como_jogar_%d" % i)
	_menus._painel.visible = false


# --- Medidas -------------------------------------------------------------------

func _falha(tela: String, msg: String) -> void:
	var linha := "UI FALHA [%s] %s: %s" % [_res_atual, tela, msg]
	if linha in _falhas:
		return
	_falhas.append(linha)
	print(linha)


func _visiveis(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is CanvasItem and not (c as CanvasItem).visible:
			continue
		if c is CanvasLayer and not (c as CanvasLayer).visible:
			continue
		if c is Control:
			out.append(c)
		_visiveis(c, out)


func _alfa(c: CanvasItem) -> float:
	var a := 1.0
	var n: Node = c
	while n is CanvasItem:
		a *= (n as CanvasItem).modulate.a * ((n as CanvasItem).self_modulate.a if n == c else 1.0)
		n = n.get_parent()
	return a


func _nome(c: Node) -> String:
	if c is Label:
		var t: String = (c as Label).text.replace("\n", " ")
		return "\"%s\"" % (t.left(40) + ("…" if t.length() > 40 else ""))
	if c is Button and (c as Button).text != "":
		return "botão \"%s\"" % (c as Button).text.left(30)
	return "%s(%s)" % [c.get_class(), c.name]


## Moldura do texto: o primeiro ancestral com borda desenhada ou que corta.
## ScrollContainer = rola, então tudo bem passar dele.
func _moldura(c: Control) -> Control:
	var n := c.get_parent()
	while n is Control:
		if n is ScrollContainer:
			return null
		if n is PanelContainer or n is Panel or n is Button or (n as Control).clip_contents:
			return n
		n = n.get_parent()
	return null


func _rolagem(c: Control) -> ScrollContainer:
	var n := c.get_parent()
	while n is Control:
		if n is ScrollContainer:
			return n
		n = n.get_parent()
	return null


func _checar(raiz: Node, tela: String) -> void:
	_telas += 1
	var tela_r := root.get_visible_rect().grow(1.0)
	var lista: Array = []
	_visiveis(raiz, lista)
	for c: Control in lista:
		var txt := ""
		if c is Label:
			txt = (c as Label).text
		elif c is Button:
			txt = (c as Button).text
		if txt.strip_edges() == "" or _alfa(c) < 0.05:
			continue
		var r := c.get_global_rect()
		if r.size.x < 1.0 or r.size.y < 1.0:
			continue
		var rolagem := _rolagem(c)
		if rolagem:
			# Dentro de rolagem: só conta o que aparece na janela da rolagem.
			if not rolagem.get_global_rect().intersects(r):
				continue
			if rolagem.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED \
					and r.end.x > rolagem.get_global_rect().end.x + 2.0:
				_falha(tela, "%s passa da largura da rolagem %s" % [_nome(c), rolagem.name])
		elif not tela_r.encloses(r):
			_falha(tela, "%s sai da tela (%s fora de %s)" % [_nome(c), r, tela_r])
		var mol := _moldura(c)
		if mol and not mol.get_global_rect().grow(2.0).encloses(r):
			_falha(tela, "%s vaza de %s" % [_nome(c), _nome(mol)])
		var mn := c.get_combined_minimum_size()
		if c is Label and not (c.get_parent() is Container):
			# Fora de container ninguém garante o tamanho mínimo: o texto
			# transborda do retângulo do próprio rótulo.
			var l := c as Label
			if not l.clip_text and l.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING \
					and (mn.y > c.size.y + 2.0 or mn.x > c.size.x + 2.0):
				_falha(tela, "%s pede %s e tem %s" % [_nome(c), mn, c.size])
	# Button não cresce com os filhos: o conteúdo montado dentro tem de caber.
	for c: Control in lista:
		if c is Button:
			for f in c.get_children():
				if f is Control and (f as Control).visible:
					var fm := (f as Control).get_combined_minimum_size()
					if fm.y > c.size.y + 2.0 or fm.x > c.size.x + 2.0:
						_falha(tela, "conteúdo do cartão %s pede %s e o cartão tem %s" % [c.name, fm, c.size])


## Blocos do HUD que não podem se cobrir (painel da escolha x minimapa x
## cartão do jogador x dica x ajuda x placar do topo).
func _blocos_hud(tela: String) -> void:
	var tela_r := root.get_visible_rect()
	var blocos: Array[Control] = []
	var raiz: Control = null
	for c in _hud.get_children():
		var cc := c as Control
		if raiz == null and cc and cc.anchor_left == 0.0 and cc.anchor_top == 0.0 \
				and cc.anchor_right == 1.0 and cc.anchor_bottom == 1.0:
			raiz = cc  # a raiz de tela cheia do Hud (o minimapa também ancora em 1,1)
	var fontes: Array = []
	if raiz:
		fontes.append_array(raiz.get_children())
	fontes.append_array(_hud.get_children())
	for c in fontes:
		if not (c is Control) or c == raiz or not (c as Control).is_visible_in_tree():
			continue
		var ct := c as Control
		var r := ct.get_global_rect()
		if r.size.x < 4.0 or r.size.y < 4.0 or _alfa(ct) < 0.05:
			continue
		if r.size.x > tela_r.size.x * 0.9 and r.size.y > tela_r.size.y * 0.9:
			continue  # camada de tela cheia (vinheta, flash)
		if ct is Label and (ct as Label).text.strip_edges() == "":
			continue
		blocos.append(ct)
	if OS.get_environment("UI_DEBUG") != "":
		print("BLOCOS ", tela, " ", blocos.map(func(b): return "%s %s" % [_nome(b), b.get_global_rect()]))
	for i in blocos.size():
		for j in range(i + 1, blocos.size()):
			var a := blocos[i].get_global_rect().grow(-1.0)
			var b := blocos[j].get_global_rect().grow(-1.0)
			if a.intersects(b):
				_falha(tela, "%s cobre %s" % [_nome(blocos[i]), _nome(blocos[j])])
