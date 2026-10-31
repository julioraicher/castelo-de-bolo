extends SceneTree
## Exporta a planta do mapa (tudo em coordenadas do mundo) para JSON, para
## tools/planta_mapa.py desenhar a vista de cima numerada:
##   godot --headless --path . -s tools/planta_mapa.gd -- SAIDA.json [res://config/mapas/X.tres]
## Sem tipos do jogo aqui (o script compila antes dos autoloads).


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var m: Resource = load(args[1] if args.size() > 1 else "res://config/mapas/rio_lanternas.tres")
	var out := {"meia_largura": m.half_width, "meia_prof": m.half_depth, "objetos": [], "pontos": []}
	for pr in m.middle_props:
		for p in pr.positions():
			out.objetos.append(_obj(pr, p, pr.rotation_deg))
	for team in 2:
		var f := 1.0 if team == 0 else -1.0
		var w := func(l: Vector2) -> Array: return [-m.castle_distance * f + l.x * f, l.y]
		for pr in m.courtyard_props:
			for p in pr.positions():
				var o := _obj(pr, Vector3(-m.castle_distance * f + p.x * f, p.y, p.z), pr.rotation_deg + (0.0 if team == 0 else 180.0))
				out.objetos.append(o)
		var c: Array = w.call(Vector2.ZERO)
		out.pontos.append({"tipo": "castelo", "time": team, "pos": c, "atras": m.wall_back * f, "frente": m.wall_front * f, "meia": m.wall_half_width, "portao": m.gate_half_width})
		out.pontos.append({"tipo": "torre_principal", "time": team, "pos": w.call(m.keep_position)})
		out.pontos.append({"tipo": "mascara", "time": team, "pos": w.call(m.princess_spot)})
		for k in m.hat_spots.size():
			out.pontos.append({"tipo": "maquina", "time": team, "pos": w.call(m.hat_spots[k]), "n": k})
		for s in m.oficina_spots:
			out.pontos.append({"tipo": "oficina", "time": team, "pos": w.call(s)})
		for s in m.tower_spots:
			out.pontos.append({"tipo": "torre", "time": team, "pos": w.call(s)})
		if "tree_spots" in m:
			for s in m.tree_spots:
				out.pontos.append({"tipo": "arvore", "time": team, "pos": w.call(s)})
			out.pontos.append({"tipo": "pilha", "time": team, "pos": w.call(m.pilha_spot)})
		out.pontos.append({"tipo": "nascer", "time": team, "pos": w.call((m.spawn_min + m.spawn_max) / 2.0)})
	if "bamboo_spots" in m:
		for s in m.bamboo_spots:
			out.pontos.append({"tipo": "bambu", "time": -1, "pos": [s.x, s.y]})
	var fa := FileAccess.open(args[0], FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	quit()


func _obj(pr: Resource, p: Vector3, rot: float) -> Dictionary:
	return {"modelo": pr.model.get_basename(), "pos": [p.x, p.z], "y": p.y, "rot": rot, "col": pr.collider,
		"raio": pr.collider_radius, "tam": [pr.collider_size.x, pr.collider_size.z], "desl": [pr.collider_offset.x, pr.collider_offset.z]}
