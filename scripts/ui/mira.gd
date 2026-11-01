class_name Mira
extends CanvasLayer
## Mira do jogador (Ciclo 2.6c, piloto aprovado pelo Julio).
##
## Três camadas:
##  1. A ponta é um cursor de HARDWARE (Input.set_custom_mouse_cursor): aro +
##     4 marcas + ponto, na cor do time. Quem desenha é o sistema, então ela
##     continua lisa mesmo a 10 FPS. Estados: normal, travado (inimigo embaixo:
##     cor do inimigo, marcas giram 45° e fecham) e apagado (fora do alcance).
##  2. Enfeites desenhados pelo jogo em volta da ponta: anel de Chi (E), tracinho
##     da recarga do Q, defesa (hexágono), vida baixa pulsando e as faíscas do
##     clique/Q/E. Se o FPS cair, só o enfeite fica mais duro.
##  3. Marcas no chão, só onde a distância do cursor conta: onde o tiro em arco
##     cai e a área do poder E quando ele está pronto (cada poder do seu jeito).

const TAM_BASE := 48.0     # px da ponta antes da escala
const ESCALA := 1.25
const HEX_DEFESA := Color(0.31, 0.61, 1.0)
const OURO := Color(1.0, 0.85, 0.54)
const CONTORNO := Color(0.16, 0.08, 0.03, 0.9)
## Poder E com centro no cursor: multiplicador do alcance (igual ao unit.gd).
const PODER_NO_PONTO := {"chuva_de_flechas": 1.4, "selo": 1.0, "coluna_fogo": 1.0}
## Poder E em volta do próprio corpo.
const PODER_NO_CORPO := ["redemoinho", "bencao", "furia", "campo_minado", "mutirao"]

const SHADER_CHAO := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 cor : source_color = vec4(1.0);
uniform float tracejado = 0.0;
uniform float espessura = 0.07;
uniform float preenche = 0.12;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) discard;
	float aa = fwidth(r) * 1.5;
	float borda = 1.0 - smoothstep(espessura * 0.5 - aa, espessura * 0.5 + aa, abs(r - (1.0 - espessura * 0.5)));
	float ang = atan(p.y, p.x) / 6.2831853;
	float traco = tracejado > 0.5 ? step(0.45, fract(ang * 18.0 + TIME * 0.6)) : 1.0;
	float dentro = preenche * smoothstep(0.2, 1.0, r);
	ALBEDO = cor.rgb;
	ALPHA = cor.a * clamp(borda * traco + dentro, 0.0, 1.0);
}
"""

var game: Game
var _tela: Control
var _cursores := {}          # chave do estado -> ImageTexture
var _estado_atual := ""
var _parts: Array = []
var _t := 0.0
var _press := 0.0
var _marca_tiro: MeshInstance3D
var _marcas_poder: Array[MeshInstance3D] = []
var _ligada := false
var _sem_tela := false
## Para prints (--mira): liga com --autoplay, desenha a ponta no canvas (o
## cursor de hardware não sai no print) e põe o "mouse" na mira do bot.
var para_print := false


func setup(g: Game) -> void:
	game = g
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sem_tela = DisplayServer.get_name() == "headless"
	_tela = Control.new()
	_tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tela.draw.connect(_desenhar)
	add_child(_tela)
	var sh := Shader.new()
	sh.code = SHADER_CHAO
	_marca_tiro = _nova_marca(sh)
	for i in 6:
		_marcas_poder.append(_nova_marca(sh))


func _nova_marca(sh: Shader) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	m.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = sh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	m.visible = false
	game.add_child(m)
	return m


func _exit_tree() -> void:
	if not _sem_tela:
		Input.set_custom_mouse_cursor(null)


## Chamado pelo PlayerBrain quando o botão é apertado (antes do corpo gastar o
## poder): "atk", "q" ou "e"; ok = se a ação vai sair de fato.
func evento(acao: String, ok: bool) -> void:
	var p := _mouse()
	var f := _px()
	if not ok:
		_add({"k": "anel", "x": p, "c": Color(0.55, 0.55, 0.55, 0.9), "r": 14.0 * f, "cresce": -0.5, "vida": 0.2, "w": 2.0})
		return
	match acao:
		"atk":
			_press = 1.0
			_estouro(p, 10, OURO, 120.0, 260.0, 0.15, 0.35, f)
			_add({"k": "anel", "x": p, "c": OURO, "r": 8.0 * f, "cresce": 2.2, "vida": 0.25, "w": 2.5})
		"q":
			var c := Color(0.62, 0.89, 1.0)
			_add({"k": "anel", "x": p, "c": c, "r": 6.0 * f, "cresce": 3.5, "vida": 0.3, "w": 3.0})
			_estouro(p, 8, c, 150.0, 240.0, 0.15, 0.3, f)
		"e":
			var cp := _cor_poder()
			_add({"k": "brilho", "x": p, "c": cp, "r": 40.0 * f, "vida": 0.35})
			_add({"k": "anel", "x": p, "c": OURO, "r": 10.0 * f, "cresce": 6.0, "vida": 0.45, "w": 4.0})
			_estouro(p, 20, cp, 150.0, 340.0, 0.25, 0.55, f)


func _process(delta: float) -> void:
	_t += delta
	var u := game.player
	var ativa := u != null and (game.player_brain != null or para_print) and not get_tree().paused and not _sem_tela
	if ativa != _ligada:
		_ligada = ativa
		_tela.visible = ativa
		if not ativa:
			_estado_atual = ""
			if not _sem_tela:
				Input.set_custom_mouse_cursor(null)
	if not ativa:
		_esconder_marcas()
		return
	_press = maxf(_press - delta * 7.0, 0.0)
	var f := _px()
	for p in _parts:
		p.t += delta
		var d := exp(-p.get("drag", 0.0) * delta)
		p.v = p.get("v", Vector2.ZERO) * d
		p.x += p.v * delta
	_parts = _parts.filter(func(p): return p.t < p.vida)
	# Ponta: travada num inimigo? fora do alcance?
	var inimigo := _inimigo_sob_cursor(f)
	var fora := _fora_do_alcance(u)
	var cor := Config.team_color(u.team)
	if inimigo:
		cor = Config.team_color(inimigo.team)
	_por_cursor(cor, inimigo != null, fora and not inimigo)
	_marcas_no_chao(u)
	_tela.queue_redraw()


## Tamanho de 1 px da ponta (tela de verdade) em unidades do canvas esticado.
func _mouse() -> Vector2:
	if para_print and game.player:
		var u := game.player
		var to := u.aim_point - u.global_position
		to.y = 0
		var alvo := u.global_position + u.aim_dir.normalized() * clampf(to.length(), 5.0, 14.0)
		return game.camera.unproject_position(alvo)
	return get_viewport().get_mouse_position()


func _px() -> float:
	var s := get_viewport().get_final_transform().get_scale().x
	return ESCALA / maxf(s, 0.01)


func _cor_poder() -> Color:
	var u := game.player
	return u.stats.hat_color.lightened(0.35) if u and u.stats else OURO


func _inimigo_sob_cursor(f: float) -> Unit:
	var cam := game.camera
	var mouse := _mouse()
	var melhor: Unit = null
	var melhor_d := 30.0 * f
	for o in game.units:
		if not o.alive or o.team == game.player.team:
			continue
		var w: Vector3 = o.global_position + Vector3(0, 1.0, 0)
		if cam.is_position_behind(w):
			continue
		var d := cam.unproject_position(w).distance_to(mouse)
		if d < melhor_d:
			melhor_d = d
			melhor = o
	return melhor


func _fora_do_alcance(u: Unit) -> bool:
	if not u.alive or not (u.stats.attack_kind in ["ranged", "healer"]):
		return false
	var to := u.aim_point - u.global_position
	to.y = 0
	return to.length() > u.stats.attack_range * 1.4


func _por_cursor(cor: Color, travado: bool, apagado: bool) -> void:
	if _sem_tela:
		return
	var chave := "%s|%s|%s" % [cor.to_html(false), travado, apagado]
	if chave == _estado_atual:
		return
	_estado_atual = chave
	if not _cursores.has(chave):
		_cursores[chave] = _gerar_cursor(cor, travado, apagado)
	var tex: ImageTexture = _cursores[chave]
	var meio := tex.get_size() * 0.5
	if para_print:
		return
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, meio)


## Desenha a ponta pixel a pixel por distância (anti-serrilhado de graça).
func _gerar_cursor(cor: Color, travado: bool, apagado: bool) -> ImageTexture:
	var tam := int(TAM_BASE * ESCALA)
	var k := float(tam) / TAM_BASE
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	var c := Vector2(tam, tam) * 0.5
	var r := 11.0
	var giro := PI / 4.0 if travado else 0.0
	var r1 := r + (5.0 if travado else 9.0)
	var a_geral := 0.5 if apagado else 1.0
	for y in tam:
		for x in tam:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5) - c) / k
			var dist := p.length()
			var d_aro := absf(dist - r)
			var d_marca := 1e9
			for i in 4:
				var a := i * PI / 2.0 + giro
				var dir := Vector2(cos(a), sin(a))
				d_marca = minf(d_marca, _dist_seg(p, dir * (r + 3.0), dir * r1))
			var d_ponto := dist - 2.2
			var cont := maxf(maxf(_cobre(d_aro - 2.25, k), _cobre(d_marca - 2.5, k)), _cobre(d_ponto - 1.2, k))
			var miolo := maxf(maxf(_cobre(d_aro - 1.0, k), _cobre(d_marca - 1.25, k)), _cobre(d_ponto, k))
			var px := Color(CONTORNO.r, CONTORNO.g, CONTORNO.b, CONTORNO.a * cont)
			px = px.lerp(Color(cor.r, cor.g, cor.b, 1.0), miolo) if miolo > 0.0 else px
			px.a = maxf(cont * CONTORNO.a, miolo) * a_geral
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


func _cobre(d: float, k: float) -> float:
	return clampf(0.5 - d * k, 0.0, 1.0)


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ba := b - a
	var h := clampf((p - a).dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (p - a - ba * h).length()


func _desenhar() -> void:
	var u := game.player
	if u == null:
		return
	var f := _px()
	var m := _mouse()
	# Anel de Chi do E: enche e brilha quando dá para usar.
	if u.stats.power != "nenhum":
		var chi := clampf(u.power / Unit.POWER_MAX, 0.0, 1.0)
		_tela.draw_arc(m, 16.0 * f, 0.0, TAU, 40, Color(1, 1, 1, 0.12), 2.5 * f, true)
		if chi >= 1.0:
			var pulso := 0.5 + 0.5 * sin(_t * 6.0)
			_tela.draw_arc(m, 16.0 * f, 0.0, TAU, 40, Color(OURO, 0.25 + 0.2 * pulso), (6.0 + 3.0 * pulso) * f, true)
			_tela.draw_arc(m, 16.0 * f, 0.0, TAU, 40, OURO, 2.5 * f, true)
		elif chi > 0.0:
			_tela.draw_arc(m, 16.0 * f, -PI / 2.0, -PI / 2.0 + TAU * chi, 40, Color(0.91, 0.72, 0.29, 0.85), 2.5 * f, true)
	# Recarga do Q: tracinho embaixo.
	if u.tem_rapida() and not u.quick_ready():
		var q := u.quick_ratio()
		_tela.draw_arc(m, 20.0 * f, PI * 0.15, PI * 0.15 + PI * 0.7 * q, 24, Color(0.62, 0.89, 1.0, 0.9), 2.0 * f, true)
	# Vida baixa: pulso vermelho.
	if u.alive and u.hp_ratio() < 0.3:
		var s := sin(_t * 8.0)
		_tela.draw_arc(m, (22.0 + 2.0 * s) * f, 0.0, TAU, 40, Color(1.0, 0.35, 0.31, 0.4 + 0.4 * s), 2.0 * f, true)
	# Defesa segurada: hexágono girando.
	if Input.is_action_pressed("block") and u.alive:
		var pts := PackedVector2Array()
		for i in 7:
			var a := i * TAU / 6.0 + _t * 0.6
			pts.append(m + Vector2(cos(a), sin(a)) * 19.0 * f)
		_tela.draw_colored_polygon(pts.slice(0, 6), Color(HEX_DEFESA, 0.15))
		_tela.draw_polyline(pts, HEX_DEFESA, 3.0 * f, true)
	# Aperto do clique: o aro "fecha" um instante.
	if _press > 0.0:
		_tela.draw_arc(m, 11.0 * (1.0 - 0.22 * _press) * f, 0.0, TAU, 32, Color(OURO, _press), 2.0 * f, true)
	if para_print and _cursores.has(_estado_atual):
		var tex: ImageTexture = _cursores[_estado_atual]
		_tela.draw_texture_rect(tex, Rect2(m - tex.get_size() * 0.5 * f / ESCALA, tex.get_size() * f / ESCALA), false)
	for p in _parts:
		var vida: float = 1.0 - p.t / p.vida
		var c: Color = p.c
		match p.k:
			"faisca":
				var v: Vector2 = p.v
				_tela.draw_line(p.x, p.x - v * 0.04, Color(c, vida), p.r, true)
			"anel":
				var rr: float = p.r * (1.0 + p.get("cresce", 0.0) * (1.0 - vida))
				if rr > 0.5:
					_tela.draw_arc(p.x, rr, 0.0, TAU, 32, Color(c, vida), maxf(0.5, p.w * vida) * f, true)
			"brilho":
				for i in 4:
					_tela.draw_circle(p.x, p.r * (1.0 - i * 0.22), Color(c, 0.12 * vida))


func _add(p: Dictionary) -> void:
	p.t = 0.0
	if not p.has("v"):
		p.v = Vector2.ZERO
	_parts.append(p)


func _estouro(x: Vector2, n: int, c: Color, v0: float, v1: float, l0: float, l1: float, f: float) -> void:
	for i in n:
		var a := randf() * TAU
		_add({"k": "faisca", "x": x, "c": c, "r": 2.0 * f, "v": Vector2(cos(a), sin(a)) * randf_range(v0, v1) * f,
			"drag": 5.0, "vida": randf_range(l0, l1)})


# ---------- marcas no chão ----------

func _esconder_marcas() -> void:
	if _marca_tiro:
		_marca_tiro.visible = false
	for m in _marcas_poder:
		m.visible = false


func _marcas_no_chao(u: Unit) -> void:
	_esconder_marcas()
	if not u.alive:
		return
	var st := u.stats
	var cp := _cor_poder()
	var to := u.aim_point - u.global_position
	to.y = 0
	var dir := to.normalized() if to.length() > 0.1 else u.aim_dir
	# Tiro em arco: cai onde o cursor está, preso entre o mínimo e o máximo.
	if st.attack_kind == "ranged" and st.projetil != "shuriken":
		var minimo := 3.0 if st.projetil == "bomba" else 6.0
		var dist := clampf(to.length(), minimo, st.attack_range * 1.4)
		_mostrar(_marca_tiro, u.global_position + dir * dist, 0.9, Color(cp, 0.85), true, 0.15, u)
	if not u.power_ready():
		return
	var cor_e := Color(cp, 0.55 + 0.15 * sin(_t * 5.0))
	if PODER_NO_PONTO.has(st.power):
		var centro := u.global_position + to.limit_length(st.attack_range * float(PODER_NO_PONTO[st.power]))
		_mostrar(_marcas_poder[0], centro, st.power_radius, cor_e, true, 0.1, u)
	elif st.power in PODER_NO_CORPO:
		_mostrar(_marcas_poder[0], u.global_position, st.power_radius, cor_e, true, 0.06, u)
	elif st.power == "bombardeio":
		# Mesma fila do unit._bombardeio: explosões do pé até a mira.
		var alcance := clampf(to.length(), 5.0, st.attack_range * 1.2)
		var n := mini(maxi(int(st.power_duration), 1), _marcas_poder.size())
		for i in n:
			var pt := u.global_position + dir * lerpf(2.5, alcance, float(i) / maxf(n - 1, 1))
			_mostrar(_marcas_poder[i], pt, st.power_radius, cor_e, i == n - 1, 0.1, u)


func _mostrar(m: MeshInstance3D, pos: Vector3, raio: float, cor: Color, tracejado: bool, preenche: float, u: Unit) -> void:
	pos.y = game.arena.ground_y(pos.x, pos.z, u.global_position.y + 3.0) + 0.06
	m.global_position = pos
	m.scale = Vector3(raio, 1.0, raio)
	var mat: ShaderMaterial = m.material_override
	mat.set_shader_parameter("cor", cor)
	mat.set_shader_parameter("tracejado", 1.0 if tracejado else 0.0)
	mat.set_shader_parameter("espessura", clampf(0.12 / raio, 0.02, 0.2))
	mat.set_shader_parameter("preenche", preenche)
	m.visible = true
