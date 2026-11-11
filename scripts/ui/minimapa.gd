class_name Minimapa
extends Control
## Minimapa do canto (estilo Battlefield, mas só com o que é público): os dois
## castelos, as máscaras, os bosques com madeira pronta para cortar, os
## depósitos, os bairros das classes, as toras soltas, o seu time e você. Inimigos NÃO
## aparecem (spotar inimigos é ideia guardada em docs/ideias.md).
## Desenhado com _draw (sem nós por ícone) e redesenhado a 10 Hz.
## Mundo -> mapa: x vai para a direita e z para baixo (a câmera olha para -z).

const LARGURA := 300.0
const MARGEM := 8.0
const ICONE_TORA := preload("res://assets/ui/icone_tora.png")
const VERDE := Color(0.45, 0.95, 0.4)

var game: Game
## Alvo da seta-guia do Construtor (Vector3.INF = nenhum), desenhado como linha.
var alvo_guia := Vector3.INF

var _t := 0.0
var _escala := 1.0
var _altura := 135.0
var _fundo: StyleBoxFlat


func setup(p_game: Game) -> void:
	game = p_game
	var m := game.arena.map
	_escala = (LARGURA - MARGEM * 2.0) / (m.half_width * 2.0)
	_altura = m.half_depth * 2.0 * _escala + MARGEM * 2.0
	custom_minimum_size = Vector2(LARGURA, _altura + 22.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo = Estilo.painel(Estilo.OURO, false, Color(0.04, 0.045, 0.04, 0.78))


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0 and game:
		_t = 0.1
		queue_redraw()


func _p(w: Vector3) -> Vector2:
	var m := game.arena.map
	return Vector2(MARGEM + (w.x + m.half_width) * _escala, MARGEM + (w.z + m.half_depth) * _escala)


func _draw() -> void:
	if game == null or game.player == null:
		return
	var m := game.arena.map
	var arena := game.arena
	var me := game.player
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	draw_style_box(_fundo, Rect2(Vector2.ZERO, Vector2(LARGURA, _altura)))
	var chao := Rect2(Vector2(MARGEM, MARGEM), Vector2(LARGURA - MARGEM * 2.0, _altura - MARGEM * 2.0))
	draw_rect(chao, Color(0.2, 0.3, 0.16, 0.8))

	# Estrada do meio e trilhas de flanco da floresta.
	var esq := _p(Vector3(-m.half_width, 0, 0)).x
	var dir := _p(Vector3(m.half_width, 0, 0)).x
	draw_line(Vector2(esq, _p(Vector3.ZERO).y), Vector2(dir, _p(Vector3.ZERO).y), Color(0.55, 0.47, 0.33, 0.55), maxf(m.road_width * _escala, 2.0))
	if m.trail_z > 0.0:
		for s in [-1.0, 1.0]:
			var y := _p(Vector3(0, 0, m.trail_z * s)).y
			draw_line(Vector2(_p(Vector3(-m.trail_x_max, 0, 0)).x, y), Vector2(_p(Vector3(m.trail_x_max, 0, 0)).x, y), Color(0.5, 0.42, 0.3, 0.45), 1.5)

	# Castelos: muralha na cor do time (o seu mais forte).
	for team in 2:
		var cor_t := Config.team_color(team)
		if m.wall_arc_radius > 0.0:  # ferradura: arco grosso na cor do time
			for run: Array in arena.wall_arc_runs():
				var pts := PackedVector2Array()
				for k in 13:
					var a := deg_to_rad(lerpf(run[0], run[1], k / 12.0))
					var lp := m.wall_arc_center + Vector2(cos(a), sin(a)) * m.wall_arc_radius
					pts.append(_p(arena.to_world(team, lp.x, lp.y)))
				draw_polyline(pts, Color(cor_t, 0.9 if team == me.team else 0.55), 2.5)
			continue
		var a := _p(arena.to_world(team, m.wall_back, -m.wall_half_width))
		var b := _p(arena.to_world(team, m.wall_front, m.wall_half_width))
		var r := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs())
		var cor := Config.team_color(team)
		draw_rect(r, Color(cor, 0.22 if team == me.team else 0.14))
		draw_rect(r, Color(cor, 0.9 if team == me.team else 0.55), false, 2.0)

	# Bairros das classes (Ciclo 2.21): ícone da classe num disco escuro.
	# Anel cinza = só a barraquinha; arco na cor do caminho = casa em obra;
	# anel dourado = casa pronta, com um pontinho por nível acima do 2.
	for of in game.oficinas:
		var c := _p(of.global_position)
		var meu := of.team == me.team
		var r := 7.0 if meu else 5.0
		var cls: ClassStats = of.opcao() if of.caminho >= 0 else of.base
		var a := 1.0 if meu else 0.6
		draw_circle(c, r + 1.6, Color(0.05, 0.04, 0.03, 0.85 * a))
		Icone.pintar(self, Icone.do_papel(cls), Color(cls.hat_color.lightened(0.2), a), c, r * 0.72)
		var cinza := Color(0.62, 0.6, 0.58, 0.75 * a)
		match of.estado:
			Oficina.Estado.VAZIO:
				draw_arc(c, r + 1.6, 0.0, TAU, 20, cinza, 1.4, true)
			Oficina.Estado.OBRA:
				draw_arc(c, r + 1.6, 0.0, TAU, 20, cinza, 1.2, true)
				draw_arc(c, r + 1.6, -PI / 2.0, -PI / 2.0 + TAU * maxf(of.progresso, 0.04), 20, Color(cls.hat_color.lightened(0.35), a), 2.4, true)
			Oficina.Estado.PRONTA:
				draw_arc(c, r + 1.6, 0.0, TAU, 24, Color(Estilo.OURO, a), 2.2, true)
				var n := mini(of.nivel, Config.cfg.mago_nivel_max) - 2
				for k in n:
					draw_circle(c + Vector2((k - (n - 1) * 0.5) * 4.0, r + 4.5), 1.6, Color(Estilo.OURO, a))
		# Nv6 (Ciclo 2.23): estrela piscando = herói raro disponível com madeira;
		# estrela fixa em cima = pavilhão de pé.
		if meu and of.destaque_heroi():
			var pisca := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
			_estrela(c + Vector2(r + 3.0, -r - 3.0), 5.5, Color(Estilo.OURO_CLARO, pisca))
		elif of.heroi_pronto:
			_estrela(c + Vector2(r + 2.0, -r - 2.0), 4.0, Color(Estilo.OURO_CLARO, a))

	# Madeira: árvores/bambus adultos brilham; crescendo ficam apagados.
	for p in game.plantas:
		var c := _p(p.global_position)
		if p.adulta():
			draw_circle(c, 4.0, VERDE)
			draw_circle(c, 4.0, Color(0.05, 0.15, 0.05), false, 1.0)
		elif p.estagio != Planta.Estagio.BROTO:
			draw_circle(c, 2.0, Color(0.35, 0.6, 0.3, 0.7))
		else:
			draw_circle(c, 1.3, Color(0.3, 0.45, 0.25, 0.6))
	for t in game.toras:
		if t.no_chao():
			draw_rect(Rect2(_p(t.global_position) - Vector2(2.5, 1.2), Vector2(5, 2.4)), Color(0.85, 0.6, 0.35))

	# Depósitos: ícone de tora; o seu pulsa quando você leva uma tora.
	for team in game.pilhas.size():
		var c := _p(game.pilhas[team].global_position)
		var lado := 22.0
		if team == me.team and me.carried_tora:
			lado += 5.0 * pulso
			draw_circle(c, lado * 0.75, Color(Estilo.OURO, 0.25 + 0.25 * pulso))
		draw_circle(c, lado * 0.55, Color(0.1, 0.07, 0.04, 0.85))
		draw_arc(c, lado * 0.55, 0, TAU, 20, Config.team_color(team), 1.5)
		draw_texture_rect(ICONE_TORA, Rect2(c - Vector2(lado, lado) * 0.4, Vector2(lado, lado) * 0.8), false)

	# Máscaras (objetivo): losango dourado, contorno na cor do dono.
	for pr in game.princesses:
		var c := _p(pr.global_position)
		var s := 5.0 if pr.state == Princess.State.HOME else 5.0 + 2.0 * pulso
		var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)])
		draw_colored_polygon(pts, Estilo.OURO)
		pts.append(pts[0])
		draw_polyline(pts, Config.team_color(pr.team).darkened(0.3), 1.5)

	# Onde a catapulta vai te jogar: alvo na cor do time, pulsando.
	if game.catapulta_alvo != Vector3.INF:
		var c := _p(game.catapulta_alvo)
		var ct := Config.team_color(me.team)
		draw_circle(c, 5.0 + 2.0 * pulso, Color(ct, 0.35))
		draw_arc(c, 5.0 + 2.0 * pulso, 0, TAU, 20, ct.lightened(0.4), 1.5)
		draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), ct.lightened(0.4), 1.0)
		draw_line(c + Vector2(0, -8), c + Vector2(0, 8), ct.lightened(0.4), 1.0)

	# Linha até o alvo da seta-guia do Construtor.
	if alvo_guia != Vector3.INF and me.alive:
		_tracejado(_p(me.global_position), _p(alvo_guia), Color(Estilo.OURO, 0.85))

	# Seu time (sem inimigos) e você por cima: seta branca para onde mira.
	for u in game.units:
		if u.alive and u.team == me.team and u != me:
			draw_circle(_p(u.global_position), 2.4, Config.team_color(u.team).lightened(0.35))
		elif u.team == me.team and u != me and game.reanimar and game.reanimar.pode_reanimar(u):
			# Aliado caído que ainda dá para reanimar: cruz na cor do time.
			var cc := _p(u.global_position)
			var ct := Config.team_color(u.team).lightened(0.35)
			draw_line(cc + Vector2(-3.5, 0), cc + Vector2(3.5, 0), ct, 2.0)
			draw_line(cc + Vector2(0, -3.5), cc + Vector2(0, 3.5), ct, 2.0)
	if me.alive:
		var c := _p(me.global_position)
		var f := Vector2(me.aim_dir.x, me.aim_dir.z)
		f = f.normalized() if f.length() > 0.1 else Vector2.RIGHT
		var l := f.orthogonal()
		var tri := PackedVector2Array([c + f * 7.0, c - f * 4.0 + l * 4.5, c - f * 2.0, c - f * 4.0 - l * 4.5])
		draw_colored_polygon(tri, Color.WHITE)
		tri.append(tri[0])
		draw_polyline(tri, Color(0, 0, 0, 0.8), 1.2)

	# Legenda curta embaixo.
	var y := _altura + 15.0
	var x := 4.0
	var fonte := Estilo.CORPO
	draw_circle(Vector2(x + 4, y - 4), 3.0, VERDE)
	draw_string(fonte, Vector2(x + 11, y), "madeira", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Estilo.TEXTO)
	x += 90.0
	draw_texture_rect(ICONE_TORA, Rect2(Vector2(x, y - 11), Vector2(13, 13)), false)
	draw_string(fonte, Vector2(x + 16, y), "depósito", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Estilo.TEXTO)
	x += 100.0
	var d := Vector2(x + 4, y - 4)
	draw_colored_polygon(PackedVector2Array([d + Vector2(0, -4), d + Vector2(4, 0), d + Vector2(0, 4), d + Vector2(-4, 0)]), Estilo.OURO)
	draw_string(fonte, Vector2(x + 11, y), "máscara", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Estilo.TEXTO)


func _tracejado(a: Vector2, b: Vector2, cor: Color) -> void:
	var v := b - a
	var n := int(v.length() / 6.0)
	for i in n:
		if i % 2 == 0:
			draw_line(a + v * (float(i) / n), a + v * (float(i + 1) / n), cor, 1.6)


## Estrela de 5 pontas (herói raro).
func _estrela(c: Vector2, r: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var ang := -PI / 2.0 + PI * k / 5.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if k % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, cor)
	pts.append(pts[0])
	draw_polyline(pts, Color(0.1, 0.07, 0.03, cor.a), 1.0, true)
