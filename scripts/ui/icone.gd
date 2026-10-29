class_name Icone
extends Control
## Ícones da interface desenhados por código (sem imagens): máscara oni,
## espírito, armas de cada papel, losango de placar. Coordenadas de -1 a 1.

## mascara, espirito, katana, shuriken, chi, martelo, recruta, losango
var tipo := "mascara"
var cor := Color.WHITE
var cheio := true  # losango: cheio (ponto feito) ou só contorno


static func novo(p_tipo: String, p_cor: Color, lado := 40.0) -> Icone:
	var i := Icone.new()
	i.tipo = p_tipo
	i.cor = p_cor
	i.custom_minimum_size = Vector2(lado, lado)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func mudar(p_tipo: String, p_cor: Color) -> void:
	if p_tipo == tipo and p_cor == cor:
		return
	tipo = p_tipo
	cor = p_cor
	queue_redraw()


## Papel da classe pelo que ela faz (vale para variações novas sem código).
static func do_papel(stats: ClassStats) -> String:
	if stats.id == &"recruta":
		return "recruta"
	if stats.velocidade_obra > 0.0:
		return "martelo"
	match stats.attack_kind:
		"healer":
			return "chi"
		"ranged":
			return "shuriken"
	return "katana"


func _p(x: float, y: float) -> Vector2:
	var r := minf(size.x, size.y) * 0.5
	return size * 0.5 + Vector2(x, y) * r


func _poli(pts: Array, c: Color) -> void:
	var v := PackedVector2Array()
	for q in pts:
		v.append(_p(q.x, q.y))
	draw_colored_polygon(v, c)


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var escuro := Color(0.03, 0.02, 0.06, 0.95)
	match tipo:
		"mascara":
			# Chifres, rosto, olhos rasgados e presas.
			_poli([Vector2(-0.62, -0.35), Vector2(-0.85, -0.98), Vector2(-0.3, -0.55)], cor.lightened(0.35))
			_poli([Vector2(0.62, -0.35), Vector2(0.85, -0.98), Vector2(0.3, -0.55)], cor.lightened(0.35))
			_poli([Vector2(-0.7, -0.5), Vector2(0.7, -0.5), Vector2(0.78, 0.1), Vector2(0.45, 0.72), Vector2(0, 0.92), Vector2(-0.45, 0.72), Vector2(-0.78, 0.1)], cor)
			_poli([Vector2(-0.55, -0.2), Vector2(-0.12, -0.05), Vector2(-0.5, 0.05)], escuro)
			_poli([Vector2(0.55, -0.2), Vector2(0.12, -0.05), Vector2(0.5, 0.05)], escuro)
			_poli([Vector2(-0.4, 0.38), Vector2(0.4, 0.38), Vector2(0.28, 0.6), Vector2(-0.28, 0.6)], escuro)
			_poli([Vector2(-0.3, 0.38), Vector2(-0.18, 0.38), Vector2(-0.24, 0.55)], Color.WHITE)
			_poli([Vector2(0.3, 0.38), Vector2(0.18, 0.38), Vector2(0.24, 0.55)], Color.WHITE)
		"espirito":
			_poli([Vector2(-0.55, 0.25), Vector2(-0.2, -0.45), Vector2(0.15, -0.95), Vector2(0.1, -0.4), Vector2(0.55, 0.25)], Color(cor, 0.85))
			draw_circle(_p(0, 0.3), r * 0.58, cor)
			draw_circle(_p(0.05, 0.35), r * 0.3, cor.lightened(0.6))
		"katana":
			_poli([Vector2(-0.72, 0.62), Vector2(0.62, -0.88), Vector2(0.78, -0.75), Vector2(-0.56, 0.75)], cor.lightened(0.5))
			_poli([Vector2(-0.62, 0.42), Vector2(-0.4, 0.62), Vector2(-0.52, 0.74), Vector2(-0.74, 0.54)], cor)
			_poli([Vector2(-0.68, 0.66), Vector2(-0.6, 0.74), Vector2(-0.9, 0.98), Vector2(-0.98, 0.9)], cor.darkened(0.3))
		"shuriken":
			var pts := []
			for k in 8:
				var a := k * PI / 4.0 - PI / 2.0
				var raio := 0.95 if k % 2 == 0 else 0.3
				pts.append(Vector2(cos(a), sin(a)) * raio)
			_poli(pts, cor)
			draw_circle(_p(0, 0), r * 0.16, escuro)
		"chi":
			draw_circle(_p(0, 0), r * 0.9, Color(cor, 0.25))
			draw_arc(_p(0, 0), r * 0.75, 0.0, TAU * 0.8, 24, cor, maxf(2.0, r * 0.14), true)
			draw_arc(_p(0, 0), r * 0.42, PI, PI + TAU * 0.7, 18, cor.lightened(0.3), maxf(2.0, r * 0.12), true)
			draw_circle(_p(0, 0), r * 0.14, cor.lightened(0.6))
		"martelo":
			_poli([Vector2(-0.12, -0.3), Vector2(0.12, -0.3), Vector2(0.12, 0.95), Vector2(-0.12, 0.95)], cor.darkened(0.25))
			_poli([Vector2(-0.75, -0.8), Vector2(0.75, -0.8), Vector2(0.75, -0.25), Vector2(-0.75, -0.25)], cor)
			_poli([Vector2(-0.75, -0.8), Vector2(-0.55, -0.8), Vector2(-0.55, -0.25), Vector2(-0.75, -0.25)], cor.lightened(0.4))
		"recruta":
			draw_circle(_p(0, 0.1), r * 0.7, cor)
			_poli([Vector2(-0.72, -0.2), Vector2(0.72, -0.2), Vector2(0.72, 0.05), Vector2(-0.72, 0.05)], Estilo.MAGENTA)
			_poli([Vector2(0.65, -0.15), Vector2(0.98, 0.15), Vector2(0.85, 0.3)], cor.lightened(0.3))
		"losango":
			var d := [Vector2(0, -0.9), Vector2(0.9, 0), Vector2(0, 0.9), Vector2(-0.9, 0)]
			if cheio:
				_poli(d, cor)
				_poli([Vector2(0, -0.5), Vector2(0.5, 0), Vector2(0, 0.5), Vector2(-0.5, 0)], cor.lightened(0.5))
			else:
				var v := PackedVector2Array()
				for q in d + [d[0]]:
					v.append(_p(q.x, q.y))
				draw_polyline(v, Color(cor, 0.6), maxf(1.5, r * 0.18), true)
