extends "res://tests/lib/caso.gd"
## Testes de regra: dados. Rodam pelo tests/regras.gd, na ordem de lá.

## Conteúdo: tudo que o game_config lista existe e tem números com sentido.
func _dados() -> void:
	var classes: Array = cfg.todas_classes()
	classes.append(cfg.villager)
	for c in classes:
		_check(c != null, "classe nula no game_config")
		if c == null:
			continue
		_check(c.model != null, "classe %s sem modelo" % c.id)
		_check(c.max_hp > 0.0, "classe %s com vida <= 0" % c.id)
		_check(c.move_speed > 0.0, "classe %s com velocidade <= 0" % c.id)
	# Ficha do menu (seção Classes): toda classe jogável tem epíteto e identidade.
	for c in cfg.todas_classes():
		if c:
			_check(c.epiteto != "" and c.descricao != "", "classe %s sem epíteto/descrição na ficha" % c.id)
	_check(not cfg.themes.is_empty(), "nenhum tema em game_config.themes")
	for t in cfg.themes:
		_check(t != null, "tema nulo em game_config.themes")
	_check(not cfg.maps.is_empty(), "nenhum mapa em game_config.maps")
	_check(cfg.herois != null and cfg.herois.resource_path.ends_with("herois_regras.tres"), "game_config sem herois = config/herois_regras.tres (números dos heróis)")
	_check(cfg.carrier_damage_mult > 0.0 and cfg.carrier_damage_mult <= 1.0,
		"carrier_damage_mult fora de (0, 1]")
	# Caça 2026-11-19 (TL-01): o gerador do cenário recriava os temas e apagava
	# as peças da economia que o gerar_economia liga (árvore, bambu, tora, pilha).
	for t in cfg.themes:
		if t == null:
			continue
		var nome_t := String(t.resource_path).get_file()
		_check(t.arvore_estagios.size() >= 3 and not t.arvore_estagios.has(null), "tema %s sem os 3 estágios da árvore" % nome_t)
		_check(not t.bambu_estagios.is_empty() and not t.bambu_estagios.has(null), "tema %s sem estágios do bambu" % nome_t)
		_check(t.maquina_model != null and t.pilha_model != null and t.tora_model != null,
			"tema %s sem máquina, depósito ou tora" % nome_t)
	_esquema_classes()
	_listas_de_classes()
	_cenas_comprimidas()


## UI-04 (caça 2026-11-19): ★ ✔ ● → ⚔ não existem na Nunito nem na Lilita. No
## .exe o Windows empresta outra fonte; no navegador viram um quadrado. Varre os
## textos entre aspas de scripts/ (comentários não contam). A Lilita cai na Nunito
## para o que não tem, então a Nunito precisa ter tudo.
func _glifos() -> void:
	var nunito: FontFile = load("res://assets/fonts/Nunito-Black.ttf")
	var aspas := RegEx.new()
	aspas.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var faltam := {}
	var pastas := ["res://scripts"]
	while not pastas.is_empty():
		var d: String = pastas.pop_back()
		for sub in DirAccess.get_directories_at(d):
			pastas.append(d.path_join(sub))
		for arq in DirAccess.get_files_at(d):
			if not arq.ends_with(".gd"):
				continue
			var n := 0
			for linha in FileAccess.get_file_as_string(d.path_join(arq)).split("\n"):
				n += 1
				if linha.strip_edges().begins_with("#"):
					continue
				for m in aspas.search_all(linha):
					var txt := m.get_string(1)
					for i in txt.length():
						var c := txt.unicode_at(i)
						if c > 127 and not nunito.has_char(c) and not faltam.has(c):
							faltam[c] = "%s:%d" % [arq, n]
	for c in faltam:
		_check(false, "glifo %s (U+%04X) não existe na fonte do jogo (%s): vira quadrado na Web" % [char(c), c, faltam[c]])
	_check(true, "glifos dos textos")


## TL-11 (revisão 2026-11-19): a lista de classes estava copiada em 8 lugares (selos,
## scripts de vídeo, geradores de casa, herói e pavilhão), e a da vitrine já tinha
## ficado nas 10 da 2.4. A fonte é config/classes/; aqui todas as cópias têm de bater.
func _listas_de_classes() -> void:
	var ids: Array[String] = []
	for f in DirAccess.get_files_at("res://config/classes/"):
		if f.ends_with(".tres") and f != "recruta.tres":
			ids.append(f.get_basename())
	ids.sort()
	var selos: Array[String] = []
	for s in Assinatura.SELOS:
		selos.append(String(s))
	_check(_ordenado(selos) == ids, "Assinatura.SELOS não bate com config/classes: %s" % _dif(selos, ids))
	var sh := FileAccess.get_file_as_string("res://tools/lib/classes.sh")
	var m := RegEx.create_from_string('CLASSES_TODAS="([^"]*)"').search(sh)
	var lista: Array[String] = []
	if m:
		for w in m.get_string(1).split(" ", false):
			if w.strip_edges() != "":
				lista.append(w.strip_edges())
	_check(lista == selos, "tools/lib/classes.sh fora da ordem dos selos ou sem classe: %s" % _dif(lista, ids))
	for id in ids:
		_check(DirAccess.dir_exists_absolute("res://assets/tutorial/classe_" + id),
			"classe %s sem clipe em assets/tutorial (tools/clipes_tutorial.sh classe:%s)" % [id, id])
	# Geradores (não carregam os .tres de propósito): bairros, caminhos, heróis e cores.
	var casas: Dictionary = load("res://tools/gerar_casas.gd").get_script_constant_map()
	var herois_g: Dictionary = load("res://tools/gerar_herois.gd").get_script_constant_map()
	var pav: Dictionary = load("res://tools/gerar_pavilhao.gd").get_script_constant_map()
	var bases: Array[String] = []
	var herois: Array[String] = []
	for c in cfg.hat_class_list:
		var b := String(c.id)
		bases.append(b)
		_check(_nomes(c.caminhos) == _txt(casas.BASES.get(b, [])), "gerar_casas.BASES[%s] diferente dos caminhos do .tres" % b)
		_check(_nomes(c.herois) == _txt(herois_g.BAIRROS.get(b, [])), "gerar_herois.BAIRROS[%s] diferente dos heróis do .tres (ordem do painel)" % b)
		herois.append_array(_nomes(c.herois))
		for x in [c] + c.caminhos:
			var cor: Color = casas.COR.get(String(x.id), Color.BLACK)
			_check(Color(cor, 1).is_equal_approx(Color(x.hat_color, 1)), "gerar_casas.COR[%s] diferente do hat_color do .tres" % x.id)
	_check(_ordenado(_txt(casas.BASES.keys())) == _ordenado(bases), "gerar_casas.BASES com bairro que não está no pátio")
	_check(_ordenado(_txt(pav.HEROIS)) == _ordenado(herois), "gerar_pavilhao.HEROIS diferente dos heróis do .tres: %s" % _dif(_txt(pav.HEROIS), herois))


func _txt(a: Array) -> Array[String]:
	var out: Array[String] = []
	for x in a:
		out.append(String(x))
	return out


func _nomes(lista: Array) -> Array[String]:
	var out: Array[String] = []
	for c in lista:
		out.append(String(c.id))
	return out


func _ordenado(a: Array[String]) -> Array[String]:
	var b: Array[String] = a.duplicate()
	b.sort()
	return b


func _dif(a: Array[String], b: Array[String]) -> String:
	var falta := b.filter(func(x): return not a.has(x))
	var sobra := a.filter(func(x): return not b.has(x))
	return "falta %s, sobra %s" % [falta, sobra]


## TL-18 (revisão 2026-11-19): todo .scn gerado sai comprimido (FLAG_COMPRESS, começa
## com "RSCC"; sem isso o download web volta de 43 para 104 MB). Substitui o
## tools/comprimir_cenas.gd, que era de uma vez só.
func _cenas_comprimidas() -> void:
	var soltos: Array[String] = []
	var total := 0
	for tema in DirAccess.get_directories_at("res://assets/ninja/"):
		var pasta := "res://assets/ninja/%s/" % tema
		for f in DirAccess.get_files_at(pasta):
			if not f.ends_with(".scn"):
				continue
			total += 1
			var arq := FileAccess.open(pasta + f, FileAccess.READ)
			if arq == null or arq.get_buffer(4).get_string_from_ascii() != "RSCC":
				soltos.append(tema + "/" + f)
	_check(total > 100, "só %d cenas .scn em assets/ninja (esperava os modelos dos 4 temas)" % total)
	_check(soltos.is_empty(), "cena salva sem FLAG_COMPRESS (7x maior): %s" % [soltos.slice(0, 5)])


## NU-03 (caça 2026-11-19): valor de texto fora da lista do @export_enum some no
## Inspector e um "salvar" pelo editor troca pelo 1º item (o Predero perdia a poça).
## Varre TODOS os .tres de classes (pátio, caminhos e heróis).
func _esquema_classes() -> void:
	var dir := "res://config/classes/"
	var listas := {}
	var amostra = load(dir + "guerreiro.tres")
	for prop in amostra.get_property_list():
		if prop.type == TYPE_STRING and prop.hint == PROPERTY_HINT_ENUM:
			listas[prop.name] = String(prop.hint_string).split(",")
	_check(listas.has("skill") and listas.has("power"), "esquema: skill/power deixaram de ser listas fechadas")
	var n := 0
	for arq in DirAccess.get_files_at(dir):
		if not arq.ends_with(".tres"):
			continue
		var c = load(dir + arq)
		if not (c is ClassStats):
			continue
		n += 1
		for campo in listas:
			var v := String(c.get(campo))
			_check((listas[campo] as PackedStringArray).has(v), "classe %s: %s = \"%s\" fora da lista do esquema" % [arq, campo, v])
		# UI-03: a ficha do menu Classes lê o texto do .tres (seis heróis saíam em branco).
		if c.skill != "nenhum":
			_check(c.skill_desc != "", "classe %s: Q sem skill_desc (ficha em branco)" % arq)
		if c.power != "nenhum":
			_check(c.power_desc != "", "classe %s: E sem power_desc (ficha em branco)" % arq)
		if c.super_tipo == "proprio":
			_check(c.super_desc != "", "classe %s: R próprio sem super_desc (ficha em branco)" % arq)
	_check(n >= 27, "esquema: só %d classes lidas em config/classes" % n)


## Caça aos bugs 2026-11-15: o leito do rio tem malha de navegação fechada
## pelas travas das margens. Salto/teleporte que mirava no rio deixava o bot
## preso lá para sempre. chao_valido nunca devolve ponto sem ligação.
func _rio_sem_ilha() -> void:
	var u = _alvo()
	if u == null:
		return
	var mapa: RID = u.get_world_3d().navigation_map
	var meio := Vector3(0, 0, -8)
	var ilha := NavigationServer3D.map_get_closest_point(mapa, meio)
	if Herois._ligado(u, mapa, ilha):
		return  # mapa sem ilha no meio: nada a conferir
	var antes: Vector3 = u.global_position
	u.global_position = Vector3(7, 0, -8)
	var perto := Herois.chao_valido(u, meio)
	var frente := Herois.chao_valido(u, meio, true)
	_check(Herois._ligado(u, mapa, perto) and absf(perto.x) > 5.0, "rio: pouso mirando no rio deveria ir para uma margem (x=%.1f)" % perto.x)
	_check(Herois._ligado(u, mapa, frente) and frente.x < -5.0, "rio: salto mirando no rio deveria terminar a travessia (x=%.1f)" % frente.x)
	u.global_position = antes
	u.reset_physics_interpolation()


## 2.25c: toda classe jogável tem som de poder próprio (nenhum repetido);
## caminhos e heróis têm super próprio; todos têm som de golpe final, exceto o
## Construtor (base corpo a corpo de martelo).
func _sons_proprios() -> void:
	var sfx := get_node("/root/Sfx")
	var vistos := {}
	for b: ClassStats in Config.cfg.hat_class_list:
		var lista: Array = [b]
		lista.append_array(b.caminhos)
		lista.append_array(b.herois)
		for c: ClassStats in lista:
			_check(sfx.has(c.som_poder), "%s: som_poder '%s' não carregou" % [c.display_name, c.som_poder])
			_check(not vistos.has(c.som_poder), "%s repete o som de poder de %s" % [c.display_name, vistos.get(c.som_poder, "")])
			vistos[c.som_poder] = c.display_name
			if c.attack_kind != "melee" or c != b:
				_check(sfx.has(c.som_golpe_final), "%s: som_golpe_final '%s' não carregou" % [c.display_name, c.som_golpe_final])
			if c != b:
				_check(sfx.has(c.som_super), "%s: som_super '%s' não carregou" % [c.display_name, c.som_super])


## Ciclo 2.20: toda peça do kit de magia nasce, anima e se libera sozinha
## (efeito que não some vaza nó e chamada de desenho a cada poder).
## Ciclo 2.24: todo personagem com poder tem assinatura PRÓPRIA (selo, verbo e
## peça); ninguém cai no selo genérico nem divide o desenho com outro.
func _assinaturas() -> void:
	var todos: Array[ClassStats] = []
	for c in Config.cfg.todas_classes():
		todos.append(c)
		for h in c.herois:
			if not todos.has(h):
				todos.append(h)
	var usados := {}
	for c in todos:
		if c.power == "nenhum":
			continue
		var d := Assinatura.de(c.id)
		_check(not d.is_empty(), "assinatura: %s não tem linha em Assinatura.DADOS" % c.id)
		if d.is_empty():
			continue
		var i := Assinatura.SELOS.find(c.id)
		_check(i >= 0 and not usados.has(i), "assinatura: %s sem selo próprio no atlas" % c.id)
		usados[i] = true
		_check(Assinatura.VERBO.has(d["verbo"]), "assinatura: verbo de %s não existe" % c.id)
		_check(Assinatura.PECAS.has(d["peca"]), "assinatura: peça de %s não existe no atlas" % c.id)
	_check(usados.size() >= 20, "assinatura: esperado 20 personagens com selo, há %d" % usados.size())
	var caixa := Node3D.new()
	game.add_child(caixa)
	caixa.global_position = Vector3(0, -30, 0)
	var antes := caixa.get_child_count()
	Assinatura.selo(caixa, caixa.global_position, &"onmyoji", 3.0, 0.4)
	Assinatura.figura(caixa, caixa.global_position, "oni", "brasa", Vector2(2, 2), 0.4)
	_check(caixa.get_child_count() == antes + 2, "assinatura: selo e figura deveriam nascer")
	caixa.queue_free()
