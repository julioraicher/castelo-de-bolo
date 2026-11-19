class_name Personalidade
extends RefCounted
## Personalidade do corpo (Ciclo 2.34). Cada personagem tem um de 8 jeitos
## (ClassStats.personalidade) de ficar parado, correr, pousar do dash e
## finalizar um herói caído. Tudo aqui é VISUAL (pose, efeito, som, letreiro);
## a regra da finalização (tempo, alcance, recompensa) mora em
## scripts/finalizar.gd e é a mesma para todos.
##
## Por que a personalidade mora fora do dash: o dash dura 0,24 s a 17 m/s
## (princípio 5: não muda). São 14 quadros; uma cambalhota de 360° nisso gira a
## 1.500°/s e o olho só vê borrão. O que o olho lê é antecipação e follow-through
## (as regras de animação da Disney): o pouso, que segura uma pose 0,4 s sem
## travar o controle, e o tempo em que o boneco está parado ou correndo.
##
## Campos de DADOS (rad para ângulos; ausente = 0):
##  parado:   coluna (+ curva o peito, − estufa), ergue (cabeça para cima),
##            rola (cabeça de lado) com rola_hz (0 = fixa), respira (fração da
##            escala) com respira_hz, flutua (m).
##  correndo: quique (× o pulinho do passo), ginga (balanço de lado por passo),
##            inclina (tronco a mais), bracos (0..1 braços para trás),
##            coluna_corre.
##  pouso:    jeito de pousar do dash e pouso_t (s).
##  finalizar: canal (animação segurando [F]), golpe (+ golpe_vel), verbo
##            (letreiro que sobe do corpo) e som.

const DADOS := {
	# Ronin Oni, Sumotori, Sohei, Shishimai, Kappa: base larga, peito pesado,
	# ginga de lado ao correr; pousa num pisão; finaliza esmagando.
	"pesado": {"coluna": 0.07, "ergue": -0.05, "respira": 0.04, "respira_hz": 0.38,
		"quique": 0.6, "ginga": 0.1,
		"pouso": "pisao", "pouso_t": 0.45,
		"canal": "Spellcast_Raise", "golpe": "2H_Melee_Attack_Chop", "golpe_vel": 2.4,
		"verbo": "ESMAGADO", "som": "sumotori_final"},
	# Samurai, Ochimusha: peito estufado, queixo erguido, passo firme; pousa
	# parado como quem embainha; finaliza no iai (o corte chega depois).
	"samurai": {"coluna": -0.06, "ergue": 0.08, "respira": 0.015, "respira_hz": 0.3,
		"quique": 0.75, "inclina": 0.05,
		"pouso": "iai", "pouso_t": 0.42,
		"canal": "Blocking", "golpe": "1H_Melee_Attack_Slice_Horizontal", "golpe_vel": 2.0,
		"verbo": "CORTE IAI", "som": "samurai_final"},
	# Shuriken, Kusarigama, Mujina, Karasu, Yamabushi: curvado e inquieto;
	# corre inclinado com os braços para trás; pousa agachado com a mão no
	# chão; finaliza aparecendo pelas costas.
	"ninja": {"coluna": 0.14, "ergue": 0.1, "respira": 0.02, "respira_hz": 0.95,
		"quique": 0.75, "inclina": 0.2, "bracos": 0.85, "coluna_corre": 0.12,
		"pouso": "agacha", "pouso_t": 0.42,
		"canal": "Blocking", "golpe": "Dualwield_Melee_Attack_Stab", "golpe_vel": 2.2,
		"verbo": "PELAS COSTAS", "som": "ninja_final"},
	# Yumi, Armadilheiro, Komusō: calmo, cabeça de lado de quem mira; pousa
	# ajoelhado; finaliza à queima-roupa.
	"atirador": {"rola": 0.08, "respira": 0.015, "respira_hz": 0.3,
		"quique": 0.9, "inclina": 0.06,
		"pouso": "ajoelha", "pouso_t": 0.38,
		"canal": "2H_Ranged_Aiming", "golpe": "2H_Ranged_Shoot", "golpe_vel": 1.8,
		"verbo": "À QUEIMA-ROUPA", "som": "arqueiro_yumi_final"},
	# Construtor, Bombardeiro, Predero: corcunda de tralha, olha para os lados,
	# corre quicando torto; pousa cambaleando; finaliza numa pancada cômica.
	"trapalhao": {"coluna": 0.07, "rola": 0.12, "rola_hz": 0.33, "respira": 0.03, "respira_hz": 0.7,
		"quique": 1.3, "ginga": 0.06,
		"pouso": "tropeco", "pouso_t": 0.55,
		"canal": "Use_Item", "golpe": "1H_Melee_Attack_Chop", "golpe_vel": 1.8,
		"verbo": "BONK", "som": "madeira_golpe"},
	# Kitsune (aprendiz), Kaminari-kozō: curioso e ingênuo. Inclina a cabeça de
	# um lado para o outro, corre saltitando; pousa num pulinho; finaliza com
	# uma cutucada de fogo-raposa.
	"curioso": {"coluna": 0.02, "ergue": 0.1, "rola": 0.3, "rola_hz": 0.21, "respira": 0.02, "respira_hz": 0.85,
		"quique": 1.4, "ginga": 0.03,
		"pouso": "pulinho", "pouso_t": 0.42,
		"canal": "Interact", "golpe": "Spellcast_Shoot", "golpe_vel": 1.6,
		"verbo": "CUTUCADA", "som": "kitsune_final"},
	# Kitsune da Luz, Tennin, Onmyoji, Kodama: sereno e protetor. Ereto, boia
	# devagar, desliza; pousa sem amassar; finaliza purificando.
	"sereno": {"coluna": -0.05, "ergue": 0.08, "respira": 0.015, "respira_hz": 0.22, "flutua": 0.05,
		"quique": 0.35, "inclina": -0.04,
		"pouso": "plana", "pouso_t": 0.48,
		"canal": "Spellcasting", "golpe": "Spellcast_Raise", "golpe_vel": 2.0,
		"verbo": "PURIFICADO", "som": "kitsune_luz_final"},
	# Kitsune Sombria, Jorogumo: astuto e predador. Agachado, cabeça erguida
	# vigiando, corre rente ao chão; pousa rastejando; finaliza dando o bote.
	"predador": {"coluna": 0.24, "ergue": 0.2, "respira": 0.03, "respira_hz": 0.6,
		"quique": 0.55, "inclina": 0.22, "bracos": 0.35, "coluna_corre": 0.14,
		"pouso": "rasteja", "pouso_t": 0.48,
		"canal": "2H_Melee_Idle", "golpe": "1H_Melee_Attack_Stab", "golpe_vel": 2.2,
		"verbo": "DEVORADO", "som": "kitsune_sombria_final"},
}
## Quem não tem personalidade (recruta) finaliza assim.
const NEUTRO := {"canal": "Idle", "golpe": "1H_Melee_Attack_Chop", "golpe_vel": 1.8, "verbo": "FINALIZADO", "som": ""}


## Dados da personalidade da classe ({} = neutro: corpo como antes do 2.34).
static func de(cls: ClassStats) -> Dictionary:
	if cls == null:
		return {}
	return DADOS.get(cls.personalidade, {})


static func _f(p: Dictionary, k: String) -> float:
	return float(p.get(k, 0.0))


# --- Corpo: parado, correndo e pouso (Unit._tick_personalidade) ------------------

## Pose do quadro. `corre` 0..1 (andando de verdade), `parado` 0..1, `t` relógio
## visual do boneco, `pouso` 0..1 do pouso (< 0 = sem pouso). Devolve
## {coluna, ergue, rola, bracos, inclina, ginga, flutua, respira}.
static func pose(p: Dictionary, corre: float, parado: float, t: float, fase_passo: float, pouso: float) -> Dictionary:
	var coluna := _f(p, "coluna") * parado + _f(p, "coluna_corre") * corre
	var ergue := _f(p, "ergue") * (parado + corre * 0.5)
	var rola := 0.0
	var r0 := _f(p, "rola")
	if r0 != 0.0:
		var hz := _f(p, "rola_hz")
		if hz > 0.0:
			# Segura inclinado e troca de lado rápido (|sen|^0,35 fica perto de ±1).
			var s := sin(TAU * hz * t)
			rola = r0 * signf(s) * pow(absf(s), 0.35) * parado
		else:
			rola = r0 * parado
	var inclina := _f(p, "inclina") * corre
	var ginga := sin(fase_passo) * _f(p, "ginga") * corre
	var bracos := _f(p, "bracos") * corre
	var flutua := _f(p, "flutua") * (0.6 + 0.4 * sin(TAU * 0.33 * t)) * (0.4 + 0.6 * parado)
	var respira := sin(TAU * _f(p, "respira_hz") * t) * _f(p, "respira") * parado
	if pouso >= 0.0:
		# Bate na pose na hora e solta no último 70% do pouso.
		var e := 1.0 - smoothstep(0.3, 1.0, pouso)
		match String(p.get("pouso", "")):
			"pisao":
				coluna += 0.32 * e
				ergue -= 0.12 * e
			"iai":
				coluna -= 0.14 * e
				ergue += 0.12 * e
			"agacha":
				coluna += 0.4 * e
				inclina += 0.42 * e
				ergue += 0.28 * e
				bracos = maxf(bracos, 0.9 * e)
			"ajoelha":
				coluna += 0.22 * e
				inclina += 0.24 * e
				rola += 0.1 * e
			"tropeco":
				ginga += sin(pouso * TAU * 2.5) * 0.32 * (1.0 - pouso)
				coluna += 0.16 * e
			"pulinho":
				rola += sin(pouso * PI) * 0.45
				ergue += 0.12 * e
			"plana":
				flutua += 0.2 * sin(pouso * PI)
				coluna -= 0.08 * e
			"rasteja":
				coluna += 0.48 * e
				inclina += 0.32 * e
				ergue += 0.38 * e
	return {"coluna": coluna, "ergue": ergue, "rola": rola, "bracos": bracos,
			"inclina": inclina, "ginga": ginga, "flutua": flutua, "respira": respira}


## Pouso do dash (chamado em Unit._fim_dash): o efeito e o som de cada jeito.
## A pose em si é a curva de `pose()` pelos próximos pouso_t s.
static func pouso(u: Unit) -> void:
	var p: Dictionary = u._pers  # o corpo montado (a Mujina disfarçada pousa como o disfarce)
	if p.is_empty() or u.game == null:
		return
	var g := u.game
	var pe := u.global_position + Vector3(0, 0.15, 0)
	var poeira := Color(0.62, 0.55, 0.45)
	match String(p.get("pouso", "")):
		"pisao":
			Sfx.play("hit", u.global_position, 0.06, 0.55, -6.0)
		"iai":
			# Embainha: um brilho fino na cintura e o tinido da lâmina.
			Fx.slash(g, u.global_position + Vector3(0, 0.95, 0), u._facing(), 1.1, 50.0, Color(0.95, 0.97, 1.0), 0.0, false)
			Sfx.play("tinido", u.global_position, 0.05, 1.2, -4.0)
		"agacha":
			# Derrapa: a mão no chão levanta um risco de poeira para trás.
			Fx.burst(g, pe - u._dodge_dir * 0.3, poeira, 8, 2.6)
		"ajoelha":
			Fx.burst(g, pe, poeira, 5, 1.6)
		"tropeco":
			Sfx.play("madeira_golpe", u.global_position, 0.1, 1.4, -10.0)
		"pulinho":
			u._mola(6.5, 0.0)
		"plana":
			u._mola(5.5, 0.0)  # desfaz o amassado do pouso: chega leve, esticada
		"rasteja":
			Fx.burst(g, pe, Color(0.55, 0.3, 0.8), 6, 1.8)
	peca_dash(u, false)


## A peça do personagem (pena, sal, folha, nota...) no começo e no fim do dash,
## para cada um ter rastro próprio. Heróis com `dash_peca` já soltam a deles.
## Só perto do jogador (o resto não aparece na tela e cada estouro é 1 chamada).
static func peca_dash(u: Unit, inicio: bool) -> void:
	if u.stats.dash_peca or u.game == null:
		return
	var d := Assinatura.de(u)
	if d.is_empty():
		return
	var pl: Unit = u.game.player
	if pl and pl != u and pl.global_position.distance_squared_to(u.global_position) > 26.0 * 26.0:
		return
	Assinatura.pecas(u.game, u.global_position + Vector3(0, 0.8, 0), d["peca"], d["peca_cor"], 5 if inicio else 3, {"tam": 0.7})


# --- Finalização: o canal ([F] segurado) e o golpe --------------------------------

## Animação de quem segura [F] no corpo (a antecipação do golpe).
static func anim_canal(u: Unit) -> String:
	var p := de(u.stats)
	return String((NEUTRO if p.is_empty() else p).get("canal", "Idle"))


static func verbo(u: Unit) -> String:
	var p := de(u.stats)
	return String((NEUTRO if p.is_empty() else p).get("verbo", "FINALIZADO"))


## Faísca do canal (a cada ~0,15 s): energia juntando na mão, mais forte no fim.
static func canal_fx(u: Unit, c: Unit, prog: float) -> void:
	var pal := Assinatura.paleta(u)
	var mao := u.global_position + Vector3(0, 1.2, 0) + (c.global_position - u.global_position).normalized() * 0.4
	Fx.burst(u.game, mao, pal[1], 2 + int(prog * 5.0), 1.5 + prog * 2.0)
	if prog > 0.55:
		u._tremor_t = maxf(u._tremor_t, 0.08)  # treme de vontade antes do golpe


## O golpe: animação de quem finaliza, efeito no corpo, letreiro com o hanko.
## `dir` = de quem finaliza para o corpo, no chão.
static func golpe(u: Unit, c: Unit) -> void:
	var g := u.game
	var p := de(u.stats)
	var q: Dictionary = NEUTRO if p.is_empty() else p
	var corpo := c.global_position
	var dir := corpo - u.global_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.05 else u._facing()
	var pal := Assinatura.paleta(u)
	var tinta := Config.team_color(c.team)
	u._play_once(String(q.golpe), 0.45, float(q.golpe_vel))
	u._agito = 1.0
	# Comum a todos: o selo de quem finalizou no chão, a tinta do caído espirra,
	# o corpo amassa e treme, um clarão na cor de quem bateu.
	Assinatura.selo(g, corpo, u, 1.9, 2.4)
	Respingo.em(g, corpo, dir, tinta, 1.0)
	Respingo.em(g, corpo + dir * 0.4, dir.rotated(Vector3.UP, 0.6), tinta, 0.7)
	Magia.clarao(g, corpo, pal[1], 7.0, 0.32, 2.6)
	c._tremor_t = 0.35
	var som := String(q.get("som", ""))
	if som == "" or not Sfx.has(som):
		som = u.stats.som_golpe_final
	if Sfx.has(som):
		Sfx.play(som, corpo, 0.04)
	Sfx.play("corte_critico", corpo, 0.04, 0.9)
	var peito := corpo + Vector3(0, 0.4, 0)
	match u.stats.personalidade:
		"pesado":
			c._mola(-12.0, 0.0)  # vira panqueca
			Magia.onda(g, corpo, pal, 3.4, 0.5)
			Magia.rachaduras(g, corpo, pal, 2.6, 10, 1.4)
			Fx.burst(g, corpo + Vector3(0, 0.2, 0), Color(0.62, 0.55, 0.45), 18, 5.0)
			if g.camera:
				g.camera.shake_at(corpo, 0.5)
		"samurai":
			# Iai: passa o corte, embainha... e o corte chega depois.
			var lado := dir.cross(Vector3.UP).normalized()
			Fx.slash(g, corpo + Vector3(0, 0.5, 0), dir, 2.4, 140.0, Color(0.96, 0.98, 1.0), 0.0, true)
			Assinatura._depois(g, 0.24, func() -> void:
				Magia.lanca(g, peito - lado * 1.8, peito + lado * 1.8, pal, 0.22, 0.3)
				Respingo.em(g, corpo, lado, tinta, 1.1)
				c._mola(-7.0, 0.0)
				Sfx.play("tinido", corpo, 0.04, 0.8))
		"ninja":
			Fx.burst(g, u.global_position + Vector3(0, 1.0, 0), Color(0.35, 0.33, 0.38), 14, 3.5)  # some na fumaça
			Magia.lanca(g, peito + Vector3(0, 1.6, 0) - dir * 0.3, peito, pal, 0.26, 0.25)
			var d := Assinatura.de(u)
			if not d.is_empty():
				Assinatura.pecas(g, peito + Vector3(0, 0.3, 0), d["peca"], d["peca_cor"], 9, {"mov": "espirra"})
			c._mola(-6.0, 0.0)
		"atirador":
			var mao := u.global_position + Vector3(0, 1.2, 0)
			Magia.lanca(g, mao, peito, pal, 0.2, 0.22)
			Magia.estouro(g, peito, pal, 0.8, 0.35)
			var d := Assinatura.de(u)
			if not d.is_empty():
				Assinatura.pecas(g, peito, d["peca"], d["peca_cor"], 8, {"mov": "espirra"})
			u._mola(0.0, -6.0)  # coice
			c._mola(-5.0, 0.0)
		"trapalhao":
			c._mola(-14.0, 0.0)
			Magia.estouro(g, peito, pal, 0.7, 0.3)
			# Estrelinhas rodando em volta do caído (tonto).
			Assinatura.pecas(g, corpo + Vector3(0, 0.9, 0), "estrela", Color(1.0, 0.86, 0.35), 8, {"mov": "sobe", "anel": 0.55, "tang": 7.0, "vida": 1.3})
			Sfx.play("madeira_golpe", corpo, 0.05, 0.75)
		"curioso":
			c._mola(9.0, 0.0)  # boing
			Magia.bola(g, peito + Vector3(0, 0.3, 0), pal, 0.65, 0.4)
			var d := Assinatura.de(u)
			if not d.is_empty():
				Assinatura.pecas(g, peito, d["peca"], d["peca_cor"], 10, {"mov": "sobe"})
			Sfx.play("magia_estouro", corpo, 0.04, 1.4, -4.0)
		"sereno":
			Magia.anel_sobe(g, corpo, pal, 1.4, 2.6, 1.2)
			Magia.anel_sobe(g, corpo, pal, 0.8, 1.8, 0.9, 0.12)
			var d := Assinatura.de(u)
			Assinatura.pecas(g, peito, String(d.get("peca", "petala")), d.get("peca_cor", pal[1]), 12, {"mov": "sobe"})
			Sfx.play("magia_luz", corpo, 0.04)
		"predador":
			# Três garras cruzando o corpo.
			for i in 3:
				var tilt := -32.0 + 32.0 * i
				Fx.slash(g, corpo + Vector3(0, 0.45 + 0.12 * i, 0), dir, 1.7, 95.0, pal[1], tilt, i == 1)
			Magia.estouro(g, peito, "sombra", 0.9, 0.35)
			Sfx.play("sombra", corpo, 0.05)
			c._mola(-8.0, 0.0)
		_:
			Fx.slash(g, corpo + Vector3(0, 0.5, 0), dir, 1.8, 110.0, Color(1, 0.9, 0.6), 0.0, true)
			c._mola(-8.0, 0.0)
	_letreiro(u, c)


## Verbo do golpe subindo do corpo, na fonte de pincel, com o hanko de quem
## finalizou (o mesmo jeito do nome do poder, FxPoder._nome).
static func _letreiro(u: Unit, c: Unit) -> void:
	var g := u.game
	var perto := u.is_player or c.is_player
	var l := Label3D.new()
	l.text = verbo(u) + "!"
	l.font = Estilo.TITULO
	l.font_size = 58 if perto else 40  # menor que o nome do poder: o golpe é que tem de aparecer
	l.pixel_size = 0.011
	l.outline_size = 16 if perto else 12
	l.outline_modulate = Estilo.TINTA
	l.modulate = Assinatura.cor(u).lightened(0.15)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	g.add_child(l)
	l.global_position = c.global_position + Vector3(0, 3.0, 0)
	l.scale = Vector3.ONE * 0.35
	Assinatura.hanko(l, u)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.2, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector3.ONE, 0.1)
	tw.set_parallel()
	tw.tween_property(l, "global_position:y", l.global_position.y + 0.9, 1.1).set_delay(0.45)
	tw.tween_property(l, "modulate:a", 0.0, 0.45).set_delay(1.0 if perto else 0.6)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.45).set_delay(1.0 if perto else 0.6)
	tw.chain().tween_callback(l.queue_free)
