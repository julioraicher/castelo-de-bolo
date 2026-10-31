class_name GuiaConstrutor
extends Node3D
## Guia do ciclo da madeira para o JOGADOR Construtor (pedido do Julio: "o
## jogo falar para você: vai coletar madeira, ó, tá aqui"). Mostra o próximo
## passo do ciclo cortar -> carregar -> entregar -> construir:
##  - seta dourada no chão, em volta do jogador, apontando para o alvo;
##  - marcador que quica em cima do alvo, com o verbo ("CORTE", "PEGUE",
##    "ENTREGUE", "CONSTRUA");
##  - o mesmo alvo vira linha tracejada no minimapa.
## Só lê o estado do jogo: nenhuma regra muda aqui.

const COR := Color(1.0, 0.82, 0.36)

var game: Game
var alvo := Vector3.INF
var verbo := ""

var _seta: MeshInstance3D
var _marca: Node3D
var _cone: MeshInstance3D
var _texto: Label3D
var _t := 0.0


func setup(p_game: Game) -> void:
	game = p_game
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true

	_seta = MeshInstance3D.new()
	_seta.mesh = _malha_seta()
	var mat := Fx.unshaded(Color(1.0, 0.9, 0.45), true)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 1
	_seta.material_override = mat
	_seta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_seta)
	# Contorno escuro (a mesma seta, maior, desenhada antes): lê em grama e telha.
	var borda := MeshInstance3D.new()
	borda.mesh = _seta.mesh
	var mb := Fx.unshaded(Color(0.12, 0.07, 0.02, 0.8), true)
	mb.cull_mode = BaseMaterial3D.CULL_DISABLED
	mb.no_depth_test = true
	mb.render_priority = 0
	borda.material_override = mb
	borda.scale = Vector3.ONE * 1.3
	borda.position = Vector3(0, -0.01, 0.05)
	borda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_seta.add_child(borda)

	_marca = Node3D.new()
	add_child(_marca)
	_cone = MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.42
	c.bottom_radius = 0.0
	c.height = 0.8
	c.radial_segments = 4
	_cone.mesh = c
	var mc := Fx.unshaded(COR)
	mc.no_depth_test = true
	mc.render_priority = 1
	_cone.material_override = mc
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marca.add_child(_cone)
	_texto = Label3D.new()
	_texto.font = Estilo.FORTE
	_texto.font_size = 60
	_texto.pixel_size = 0.011
	_texto.outline_size = 14
	_texto.outline_modulate = Color(0.12, 0.07, 0.02)
	_texto.modulate = COR
	_texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_texto.no_depth_test = true
	_texto.position.y = 0.95
	_marca.add_child(_texto)
	visible = false


## Seta achatada (chevron) no plano XZ, apontando para -z.
static func _malha_seta() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [Vector3(0, 0, -0.9), Vector3(0.75, 0, 0.1), Vector3(0.28, 0, 0.1),
			Vector3(0.28, 0, 0.7), Vector3(-0.28, 0, 0.7), Vector3(-0.28, 0, 0.1), Vector3(-0.75, 0, 0.1)]
	# Ponta e haste (dois triângulos da haste).
	for tri in [[0, 1, 6], [2, 3, 4], [2, 4, 5]]:
		for i in tri:
			st.set_normal(Vector3.UP)
			st.add_vertex(pts[i])
	return st.commit()


## Decide o próximo passo do jogador Construtor (ou nenhum).
func calcular() -> void:
	alvo = Vector3.INF
	verbo = ""
	var u := game.player
	if u == null or not u.alive or not u.lenhador() or u.carried_princess or u.is_equipping():
		return
	var pos := u.global_position
	if u.carried_tora:
		alvo = game.pilhas[u.team].global_position
		verbo = "ENTREGUE"
		return
	var t := game.nearest_tora_solta(pos, 25.0)
	if t:
		alvo = t.global_position
		verbo = "PEGUE"
		return
	# Obra pendente com madeira no estoque (mesma conta dos bots).
	var of := game.obra_do_time(u.team, pos)
	if of:
		var falta := of.faltam()
		if (falta > 0 and game.madeira[u.team] >= falta) or (falta == 0 and of.comecada() and of.progresso < 1.0):
			alvo = of.global_position
			verbo = "CONSTRUA"
			return
	# Árvore/bambu adulto mais perto (as do próprio bosque contam como mais perto).
	var melhor := INF
	for p in game.plantas:
		if not p.adulta():
			continue
		var d := pos.distance_to(p.global_position) * (0.7 if p.lado == u.team else 1.0)
		if d < melhor:
			melhor = d
			alvo = p.global_position
			verbo = "CORTE"


func _process(delta: float) -> void:
	if game == null:
		return
	_t += delta
	calcular()
	visible = alvo != Vector3.INF
	if not visible:
		return
	var u := game.player
	var to := alvo - u.global_position
	to.y = 0.0
	var d := to.length()
	# Seta no chão a 2,4 m do jogador; some quando o alvo está a um passo.
	_seta.visible = d > 4.0
	if _seta.visible:
		var dir := to / d
		var vai := fmod(_t * 1.6, 1.0)
		_seta.global_position = u.global_position + dir * (2.2 + vai * 0.7) + Vector3(0, 0.12, 0)
		_seta.global_basis = Basis.looking_at(dir, Vector3.UP).scaled(Vector3.ONE * 1.5)
		_seta.transparency = vai * 0.5
	# Marcador quicando em cima do alvo (mais alto em árvore e casa).
	var alt := 4.2 if verbo == "CORTE" or verbo == "CONSTRUA" else 2.6
	_marca.global_position = alvo + Vector3(0, alt + absf(sin(_t * 4.0)) * 0.5, 0)
	_cone.rotation.y = _t * 2.0
	_texto.text = verbo
