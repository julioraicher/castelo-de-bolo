extends SceneTree
## Regrava os modelos .scn de assets/ninja/ com ResourceSaver.FLAG_COMPRESS
## (revisão 2.26r): o conteúdo é o mesmo, o arquivo fica ~7x menor e o
## download do jogo no navegador cai de ~104 MB para ~40 MB.
## Os geradores (tools/gerar_*.gd) já salvam comprimido; isto só converte o
## que já existe. Uso: godot --headless --path . -s tools/comprimir_cenas.gd

func _initialize() -> void:
	var antes := 0
	var depois := 0
	var n := 0
	for tema in DirAccess.get_directories_at("res://assets/ninja"):
		var dir := "res://assets/ninja/" + tema
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".scn"):
				continue
			var caminho := dir.path_join(f)
			antes += FileAccess.open(caminho, FileAccess.READ).get_length()
			var res := ResourceLoader.load(caminho, "", ResourceLoader.CACHE_MODE_IGNORE)
			var err := ResourceSaver.save(res, caminho, ResourceSaver.FLAG_COMPRESS)
			if err != OK:
				printerr("falhou: ", caminho, " ", err)
				continue
			depois += FileAccess.open(caminho, FileAccess.READ).get_length()
			n += 1
	print("comprimidas %d cenas: %.1f MB -> %.1f MB" % [n, antes / 1048576.0, depois / 1048576.0])
	quit()
