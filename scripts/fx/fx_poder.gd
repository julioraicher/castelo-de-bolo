class_name FxPoder
extends RefCounted
## Assinatura visual de cada poder: nome do golpe no ar, selo que se escreve no
## chão e um efeito próprio por poder, montado com o kit `Magia` (Ciclo 2.20).
## Só visual (dano, raio e tempo ficam em Unit). Regra de tela (quiz 2B): pico
## forte por ~0,3 s (estouro, onda, clarão) e depois só um resto discreto
## (brasas, marca no chão). Cada peça é 1 chamada de desenho e some sozinha.


# --- Comum a todos ---------------------------------------------------------------

## Elemento de cada poder: paleta do kit e desenho do selo (pontas da estrela
## ou pétalas). Poder sem linha aqui usa a cor do chapéu.
const ELEMENTO := {
	"redemoinho": ["vento", 4, 0],
	"furia": ["brasa", 3, 0],
	"leque": ["aco", 6, 0],
	"corte_relampago": ["aco", 6, 0],
	"chuva_de_flechas": ["", 4, 0],
	"bencao": ["luz", 0, 8],
	"selo": ["sombra", 5, 0],
	"coluna_fogo": ["", 5, 0],
	"campo_minado": ["veneno", 6, 0],
	"mutirao": ["luz", 8, 0],
	"bombardeio": ["brasa", 3, 0],
	"muralha": ["", 8, 0],
	"ciranda": ["aco", 6, 0],
}


static func pal_de(u: Unit) -> Array:
	var e: Array = ELEMENTO.get(u.stats.power, ["", 5, 0])
	if e[0] == "":
		return Magia.paleta_de(Config.team_color(u.team) if u.stats.power == "chuva_de_flechas" else u.stats.hat_color)
	return Magia.paleta(e[0])


## Chamado no começo de qualquer poder: ato 1 (tudo é sugado para o corpo), o
## nome do golpe e o selo do elemento se escrevendo sob os pés.
static func lancar(u: Unit) -> void:
	var cor := u.stats.hat_color.lightened(0.35)
	_nome(u, cor)
	var pal := pal_de(u)
	var e: Array = ELEMENTO.get(u.stats.power, ["", 5, 0])
	var raio := maxf(u.stats.power_radius, 2.5) if u.stats.power != "leque" else 3.0
	if u.stats.power != "selo":  # o Selo Sombrio escreve o próprio, no alvo
		Magia.selo(u.game, u.global_position, pal, minf(raio, 7.0), 1.1, {"pontas": e[1], "petalas": e[2], "escrita": 0.16, "giro": 0.12})
	Magia.carga(u.game, u.global_position + Vector3(0, 1.1, 0), pal[1], 2.2, 0.18, 12)
	Magia.clarao(u.game, u.global_position, pal[1], raio * 1.5 + 3.0, 0.3, 2.2)


## Nome do golpe na fonte de pincel, sobe e some (estilo anime).
static func _nome(u: Unit, cor: Color) -> void:
	var l := Label3D.new()
	l.text = u.stats.power_name.to_upper() + "!"
	l.font = Estilo.TITULO
	l.font_size = 96 if u.is_player else 46  # bots: menor e mais curto, para não poluir a briga
	l.pixel_size = 0.011
	l.outline_size = 22 if u.is_player else 14
	l.outline_modulate = Estilo.TINTA
	l.modulate = cor
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	u.game.add_child(l)
	l.global_position = u.global_position + Vector3(0, 3.3, 0)
	l.scale = Vector3.ONE * 0.4
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector3.ONE, 0.08)
	tw.set_parallel()
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.0, 0.9).set_delay(0.3)
	var some := 0.8 if u.is_player else 0.45
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(some)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.4).set_delay(some)
	tw.chain().tween_callback(l.queue_free)



# --- Um por poder ------------------------------------------------------------------

## Samurai (Redemoinho): tufão de pinceladas de vento em funil, um miolo de aço
## girando ao contrário, folhas sugadas para dentro e a rajada final.
static func redemoinho(u: Unit) -> void:
	var dur := u.stats.power_duration
	var r := u.stats.power_radius
	var g := u.game
	Magia.vortice(u, "vento", r * 0.5, 3.4, dur, {"r_topo": 1.9, "gira": 1.9})
	Magia.vortice(u, "aco", r * 0.3, 2.3, dur, {"r_topo": 1.5, "gira": -2.6, "forca": 1.6, "base": 0.15, "topo": 0.02, "y": 0.2})
	Magia.orbita(u, Color(0.95, 0.9, 0.7), r * 0.85, dur, 14)
	Magia.onda(g, u.global_position, "vento", r * 1.25, 0.4, {"gira": 1.5, "banda": 0.13})
	_succao(u, r * Config.cfg.redemoinho_puxa_raio, dur)
	var fim := u.create_tween()
	fim.tween_interval(maxf(dur - 0.05, 0.1))
	fim.tween_callback(func() -> void:
		Magia.onda(g, u.global_position, "vento", r * 1.5, 0.45, {"gira": -1.2})
		Magia.brasas(g, u.global_position, Color(1.0, 0.95, 0.75), 8, r * 0.6, 0.9))


## Vórtice do Redemoinho: onda de vento na borda da puxada que se FECHA no
## Samurai (2 vezes), para ler "puxa" e não só "gira".
static func _succao(u: Unit, r_puxa: float, dur: float) -> void:
	var meia := maxf(dur, 0.6) / 2.0
	var tw := u.create_tween()
	for k in 2:
		tw.tween_callback(func() -> void:
			Magia.onda(u, u.global_position, "vento", r_puxa * 0.35, meia, {"r0": 1.0 / 0.35, "gira": 2.0, "banda": 0.07, "forca": 0.9}))
		tw.tween_interval(meia)


## Armadilheiro (Campo Minado): cada mina sai da mão em arco com uma fita de
## pólvora verde atrás e acende ao cair (onda, faíscas e brilho).
static func campo_minado(u: Unit, pontos: Array) -> void:
	var g := u.game
	var pal: Array = Magia.paleta("veneno")
	var origem := u.global_position + Vector3(0, 1.3, 0)
	for k in pontos.size():
		var alvo: Vector3 = pontos[k]
		var n := _no(g, origem)
		var s := SphereMesh.new()
		s.radius = 0.16
		s.height = 0.32
		s.radial_segments = 6
		s.rings = 3
		_malha(n, s, Fx.unshaded(Color(0.12, 0.14, 0.1)))
		Magia.fita(n, Vector3(0, -0.14, 0), Vector3(0, 0.14, 0), pal, 0.0, {"pontos": 8})
		var atraso := 0.04 * k
		var tw := n.create_tween()
		tw.tween_interval(atraso)
		tw.tween_method(func(f: float) -> void:
			n.global_position = origem.lerp(alvo, f) + Vector3(0, sin(f * PI) * 1.6, 0), 0.0, 1.0, 0.32)
		tw.tween_callback(func() -> void:
			Magia.onda(g, alvo, pal, 1.1, 0.35)
			FxProjetil.faiscas(g, alvo + Vector3(0, 0.2, 0), pal[1], 5, 4.0)
			FxProjetil.brilho(g, alvo + Vector3(0, 0.3, 0), pal[0], 0.9)
			n.queue_free())


## Ronin Oni (Fúria): o chão estoura em brasa (cúpula que se rasga, labareda,
## pedras), dois chifres de fogo sobem das costas e a aura de brasa fica
## queimando no corpo enquanto a fúria dura.
static func furia(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	var r := u.stats.power_radius
	var dur := u.stats.power_duration
	Magia.estouro(g, p, "brasa", minf(r * 0.8, 5.0), 0.42)
	Magia.chama(g, p, "brasa", 1.7, 6.0, 0.7, {"forca": 1.15})
	Magia.onda(g, p, "brasa", r * 1.2, 0.5, {"voltas": 5.0})
	Magia.clarao(g, p, Color(1.0, 0.35, 0.1), r * 2.5, 0.35, 4.0)
	Magia.brasas(g, p, Color(1.0, 0.5, 0.15), 18, r * 0.7, 1.6)
	FxProjetil.marca_chao(g, p, Color(0.06, 0.03, 0.03, 0.6), r * 0.55, 3.5)
	_detritos(g, p, Color(0.35, 0.3, 0.32), 16)
	# Chifres do Oni: duas línguas de fogo inclinadas, saindo das costas.
	for lado: float in [-1.0, 1.0]:
		var ch := Magia.chama(u, p + Vector3(0, 1.2, 0), "brasa", 0.5, 3.6, 0.9, {"r_topo": 0.05, "forca": 0.9, "giro": 0.0, "rola": Vector2(0.0, -2.4)})
		ch.global_rotation = Vector3(deg_to_rad(-14), 0.0, deg_to_rad(-34.0 * lado))  # câmera fixa: abre para os lados da tela
	# Aura: labareda presa no Ronin + brasas subindo.
	var aura := Magia.chama(u, p, "brasa", 1.15, 3.1, dur + 0.3, {"segura": dur / (dur + 0.3), "r_topo": 0.3, "forca": 1.2, "base": 0.7, "topo": -0.1, "giro": 0.0, "rola": Vector2(0.25, -1.9), "atras": true})
	aura.position.y = 0.15
	Magia.aura_brasas(u, Color(1.0, 0.45, 0.12), dur, 9, 0.55)


## Lâmina Dupla: sombras do ninja pelo caminho (fumaça que se desfaz), X de
## corte no fim e, um instante depois, o "corte atrasado" em quem foi atravessado.
static func corte_relampago(u: Unit, de: Vector3, ate: Vector3, atingidos: Array) -> void:
	var g := u.game
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.7
	cap.radial_segments = 8
	cap.rings = 2
	for k in 5:
		var t := (k + 0.5) / 5.0
		var n := _no(g, de.lerp(ate, t) + Vector3(0, 0.9, 0))
		var mat := Magia.mat("aco", {"base": 0.5, "topo": 0.5, "forca": 0.9, "rola": Vector2(0.0, 1.5)})
		_malha(n, cap, mat)
		var tw := n.create_tween()
		tw.tween_interval(0.05 * k)
		Magia._anim(tw, mat, "corroi", 0.0, 1.0, 0.35)
		tw.tween_callback(n.queue_free)
	var dir := (ate - de).normalized()
	Fx.slash(g, ate + Vector3(0, 1.0, 0), dir, 2.6, 160.0, Color(0.5, 1.0, 1.0), 55.0, true)
	Fx.slash(g, ate + Vector3(0, 1.0, 0), dir, 2.6, 160.0, Color(0.5, 1.0, 1.0), -55.0, true)
	var n2 := _no(g, ate)
	var t2 := n2.create_tween()
	t2.tween_interval(0.28)
	t2.tween_callback(func() -> void:
		Magia.lanca(g, de + Vector3(0, 1.0, 0), ate + Vector3(0, 1.0, 0), "aco", 0.3, 0.25)
		for alvo in atingidos:
			if is_instance_valid(alvo):
				var q: Vector3 = alvo.global_position + Vector3(0, 1.0, 0)
				Magia.lanca(g, q - dir * 1.4 + Vector3(0, 0.6, 0), q + dir * 1.4 - Vector3(0, 0.6, 0), "aco", 0.4, 0.3)
				Fx.burst(g, q, Color(0.6, 1.0, 1.0), 10, 7.0)
		n2.queue_free())


## Ninja de Shuriken (Leque): arcos de luz abrindo na frente, uma shuriken
## gigante de aço girando num disco de vento e a pós-imagem do ninja em fumaça.
static func leque(u: Unit, dir: Vector3) -> void:
	var g := u.game
	var p := u.global_position
	var arco := maxf(u.stats.power_radius, 40.0)
	Fx.slash(g, p + Vector3(0, 1.1, 0), dir, 7.0, arco, Color(0.4, 1.0, 1.0), 0.0, true)
	Fx.slash(g, p + Vector3(0, 0.7, 0), dir, 4.5, arco * 0.8, Color(0.8, 1.0, 1.0), 12.0, false)
	var n := _no(g, p + Vector3(0, 2.6, 0) + dir * 0.6)
	var giro := Node3D.new()
	n.add_child(giro)
	var estrela := _malha(giro, FxProjetil.malha_shuriken(), FxProjetil.mat_solido())
	estrela.scale = Vector3.ONE * 5.0
	var mat := Magia.mat("aco", {"escala": Vector2(3.0, 0.8), "rola": Vector2(2.5, 0.0), "forca": 0.9, "base": 0.4, "topo": 0.8, "banda": 0.45, "centro": 0.62})
	_malha(giro, Magia.disco(), mat).scale = Vector3(1.5, 1, 1.5)
	n.rotation = Vector3(deg_to_rad(-60), atan2(dir.x, dir.z), 0)
	n.scale = Vector3.ONE * 0.4
	var tw := n.create_tween().set_parallel()
	tw.tween_property(giro, "rotation:y", TAU * 3.0, 0.6)
	tw.tween_property(n, "scale", Vector3.ONE * 1.6, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(estrela, "scale", Vector3.ONE * 0.2, 0.2).set_delay(0.4)
	Magia._anim(tw, mat, "corroi", 0.0, 1.0, 0.3).set_delay(0.3)
	tw.chain().tween_callback(n.queue_free)
	# Pós-imagem: o ninja "fica" um instante em fumaça escura que se desfaz.
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.7
	cap.radial_segments = 8
	cap.rings = 2
	var sombra := _no(g, p + Vector3(0, 0.9, 0) - dir * 0.5)
	var smat := Magia.mat("fumaca", {"base": 0.5, "topo": 0.5, "forca": 1.0, "rola": Vector2(0.0, 1.2)})
	_malha(sombra, cap, smat)
	var ts := sombra.create_tween()
	Magia._anim(ts, smat, "corroi", 0.1, 1.0, 0.5)
	ts.tween_callback(sombra.queue_free)


## Arqueiro Yumi (Chuva de Flechas): lanças de luz sobem para o céu e a mira
## se escreve no alvo como um selo que gira e aperta até a salva cair.
static func chuva(u: Unit, alvo: Vector3, r: float) -> void:
	var g := u.game
	var pal := Magia.paleta_de(Config.team_color(u.team).lightened(0.15))
	var p := u.global_position + Vector3(0, 1.6, 0)
	for k in 5:
		var off := Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		Magia.lanca(g, p + off * 0.3, p + off + Vector3(0, 14.0, 0), "luz", 0.28, 0.45, {"cresce": 0.12, "corre": 5.0})
	FxProjetil.faiscas(g, p, Color(1.0, 0.9, 0.5), 8, 7.0, Vector3.UP, 25.0)
	var mira := Magia.selo(g, alvo, pal, r, ArrowRain.WARN + 0.35, {"pontas": 4, "escrita": 0.25, "giro": 0.5})
	var tw := mira.create_tween()
	tw.tween_property(mira, "scale", Vector3(r * 0.72, 1, r * 0.72), ArrowRain.WARN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Kitsune Luz (Bênção da Raposa): lótus de luz abrindo pétala por pétala em
## cima do selo, coluna serena e pétalas soltas subindo devagar.
static func bencao(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	var r := u.stats.power_radius
	var n := _no(g, p + Vector3(0, 0.12, 0))
	var mat := Magia.mat("luz", {"escala": Vector2(1.0, 1.0), "rola": Vector2(0.0, 0.35), "forca": 0.5, "base": 0.62, "topo": 0.62, "tinta": 0.05})
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 0.25
	s.radial_segments = 8
	s.rings = 3
	var tw := n.create_tween().set_parallel()
	for k in 10:
		var pivo := Node3D.new()
		pivo.rotation.y = TAU * k / 10.0
		n.add_child(pivo)
		var mi := _malha(pivo, s, mat)
		mi.scale = Vector3(0.05, 0.05, 0.05)
		mi.position = Vector3(0, 0, 0.9)
		# Pétala por pétala: cada uma abre 0,03 s depois da vizinha.
		tw.tween_property(mi, "scale", Vector3(0.8, 1, 2.2), 0.3).set_delay(0.03 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "rotation:x", deg_to_rad(-45), 0.45).set_delay(0.03 * k)
	n.scale = Vector3.ONE * 1.6
	tw.tween_property(n, "rotation:y", PI / 3, 1.3)
	Magia._anim(tw, mat, "corroi", 0.0, 1.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(n.queue_free)
	Magia.onda(g, p, "luz", r, 0.6, {"voltas": 6.0, "forca": 0.5})
	Magia.anel_sobe(g, p + Vector3(0, 0.2, 0), "luz", r * 0.5, 3.0, 1.0, 0.1)
	if Magia.enfeite():
		FxProjetil.ps(g, p + Vector3(0, 0.4, 0), FxProjetil.quad("brilho", FxProjetil.tex_brilho(), false), Color(1.0, 0.8, 0.75), 16, 1.6, {
			"esfera": r * 0.6, "explosao": 0.6, "dir": Vector3.UP, "spread": 20.0, "v0": 0.8, "v1": 2.0, "rampa": "pisca", "s0": 0.12, "s1": 0.24,
		})


## Em cada aliado curado/protegido: um fio de luz viaja de quem lançou até ele,
## e nele sobem um anel e pontinhos de luz (cor do poder).
static func em_aliado(alvo: Unit, cor: Color, de: Unit = null) -> void:
	var g := alvo.game
	var pal := Magia.paleta_de(cor)
	if de != null and de != alvo and is_instance_valid(de):
		Magia.lanca(g, de.global_position + Vector3(0, 1.3, 0), alvo.global_position + Vector3(0, 1.1, 0), pal, 0.22, 0.4, {"cresce": 0.14, "corre": 4.0, "forca": 0.8})
	_motas(g, alvo.global_position, cor, 10)
	Magia.anel_sobe(g, alvo.global_position + Vector3(0, 0.2, 0), pal, 0.9, 2.0, 0.7)
	Magia.onda(g, alvo.global_position, pal, 1.4, 0.4)


## Corrida (Armadilheiro, Construtor): riscos de vento saindo do corpo e uma
## fita baixa atrás dos pés enquanto dura.
static func rastro(alvo: Unit, cor: Color, dur: float) -> void:
	if not Magia.enfeite():
		return
	var p := FxProjetil.ps(alvo, Vector3(0, 0.9, 0), FxProjetil.lasca(0.5, 0.045), Color(cor.lerp(Color.WHITE, 0.3), 0.85), 12, 0.3, {
		"one_shot": false, "local": false, "local_pos": true, "dir": Vector3.UP, "spread": 10.0, "v0": 0.2, "v1": 0.6, "rampa": "nasce",
	})
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.3, 0.6, 0.3)
	var tw := p.create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func(): p.emitting = false)
	tw.tween_interval(0.4)
	tw.tween_callback(p.queue_free)
	Magia.fita(alvo, Vector3(-0.3, 0.12, 0), Vector3(0.3, 0.12, 0), Magia.paleta_de(cor), dur, {"pontos": 10, "forca": 0.9})


## Bombas de Fumaça: estouro que se rasga e poucas nuvens de pincel (leve).
static func nuvem(g: Node, centro: Vector3, r: float) -> void:
	Magia.estouro(g, centro, "fumaca", r * 0.9, 0.45, {"sobe": false})
	Magia.onda(g, centro, "fumaca", r * 1.05, 0.5)


## Kitsune Sombria (Selo Sombrio): o selo se ESCREVE no chão em tinta roxa,
## acende, e de cada ponta da estrela sobe uma chama tremida com um raio em
## ziguezague; no miolo, um estouro que se rasga e brasas roxas que ficam.
static func selo(g: Node, centro: Vector3, r: float) -> void:
	var pal: Array = Magia.paleta("sombra")
	Magia.selo(g, centro, pal, r * 1.02, 1.7, {"pontas": 5, "escrita": 0.2, "giro": 0.05})
	Magia.carga(g, centro + Vector3(0, 1.0, 0), pal[1], r * 0.9, 0.2, 12)
	var n := _no(g, centro)
	var tw := n.create_tween()
	tw.tween_interval(0.18)
	tw.tween_callback(func() -> void:
		for k in 5:
			var a := TAU * k / 5.0 - PI / 2
			var p := centro + Vector3(cos(a), 0.0, sin(a)) * r * 0.7
			Magia.chama(g, p, pal, 0.55, 3.4 + (k % 2) * 0.7, 0.95, {"rola": Vector2(0.5, -2.6), "forca": 1.25, "r_topo": 0.1, "giro": 1.2})
			Fx.zap(g, p + Vector3(0, 0.2, 0), p + Vector3(cos(a) * 0.5, 4.6, sin(a) * 0.5), pal[0], 5)
		Magia.estouro(g, centro, pal, minf(r * 0.55, 4.5), 0.45)
		Magia.onda(g, centro, pal, r * 1.15, 0.5, {"voltas": 5.0})
		Magia.clarao(g, centro, pal[1], r * 2.2)
		Magia.brasas(g, centro, pal[1], 14, r * 0.7, 1.5)
		FxProjetil.marca_chao(g, centro, Color(Magia.TINTA, 0.55), r * 0.6, 3.0))
	tw.tween_interval(1.0)
	tw.tween_callback(n.queue_free)


## Kitsune (Coluna de Fogo-Raposa): labareda que nasce do chão num pulo e se
## desfaz em línguas, bolas de fogo-raposa girando em volta e brasas subindo.
static func coluna_fogo(g: Node, centro: Vector3, r: float, dur: float, cor := Color(0.25, 0.9, 1.25)) -> void:
	var pal := Magia.paleta_de(cor)
	Magia.chama(g, centro, pal, minf(r * 0.3, 1.4), 5.5, 0.7, {"giro": 0.6, "forca": 1.7, "r_topo": 0.3, "barriga": 0.2, "base": 0.68, "topo": -0.45, "escala": Vector2(3.0, 0.4)})
	Magia.onda(g, centro, pal, r * 1.1, 0.45)
	Magia.clarao(g, centro, pal[1], r * 2.2)
	Magia.brasas(g, centro, pal[1], 12, r * 0.6, 1.4)
	var n := _no(g, centro + Vector3(0, 1.4, 0))
	var s := SphereMesh.new()
	s.radius = 0.34
	s.height = 0.8
	s.radial_segments = 8
	s.rings = 4
	var mat := Magia.mat(pal, {"base": 0.45, "topo": 0.75, "forca": 0.8, "escala": Vector2(2.0, 1.0), "rola": Vector2(0.0, 1.6)})
	for k in 6:
		var a := TAU * k / 6.0
		var mi := _malha(n, s, mat)
		mi.position = Vector3(cos(a), sin(a * 2.0) * 0.4, sin(a)) * r * 0.75
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "rotation:y", TAU * dur * 0.8, dur)
	Magia._anim(tw, mat, "corroi", 0.0, 1.0, 0.35).set_delay(maxf(dur - 0.35, 0.0))
	tw.chain().tween_callback(n.queue_free)


## Construtor (Mutirão): fio de luz até a oficina e três marteladas nela
## (clarão, faíscas douradas e serragem voando).
static func mutirao(u: Unit, oficina: Node3D) -> void:
	var g := u.game
	var alvo := oficina.global_position
	Magia.lanca(g, u.global_position + Vector3(0, 1.2, 0), alvo + Vector3(0, 1.5, 0), "luz", 0.5, 0.7, {"cresce": 0.15})
	Magia.anel_sobe(g, alvo + Vector3(0, 0.3, 0), "luz", 2.2, 3.5, 1.0, 0.15)
	var n := _no(g, alvo)
	var tw := n.create_tween()
	for k in 3:
		tw.tween_interval(0.14 if k == 0 else 0.22)
		tw.tween_callback(func() -> void:
			var q := alvo + Vector3(randf_range(-1.0, 1.0), 1.0 + k * 0.7, randf_range(-1.0, 1.0))
			FxProjetil.brilho(g, q, Color(1.0, 0.95, 0.7), 1.3)
			FxProjetil.faiscas(g, q, Color(1.0, 0.8, 0.3), 8, 6.0)
			Fx.burst(g, q, Color(0.72, 0.55, 0.36), 6, 3.5))  # serragem
	tw.tween_callback(n.queue_free)
	_motas(g, alvo, Color(1.0, 0.85, 0.35), 16)
	_detritos(g, alvo + Vector3(0, 1.0, 0), Color(0.6, 0.4, 0.25), 8)


## Bombardeiro: aviso com pavio em cada ponto. A onda de brasa encolhe até o
## centro no tempo exato da explosão (dá para ler a ordem da fila e fugir) e
## uma faísca de pavio corre pela borda.
static func aviso_bombardeio(g: Node, pontos: Array, r: float, intervalo: float) -> void:
	for i in pontos.size():
		var atraso: float = intervalo * (i + 1)
		var centro: Vector3 = pontos[i]
		Magia.onda(g, centro, "brasa", r * 0.12, atraso, {"r0": 1.0 / 0.12, "banda": 0.14, "tinta": 0.02, "forca": 0.4, "voltas": 6.0, "gira": 0.6, "y": 0.1, "linear": true, "segura": 0.92})
		var n := _no(g, centro + Vector3(0, 0.1, 0))
		var pavio := FxProjetil.brilho_fixo(n, Vector3(0, 0.15, r), Color(1.0, 0.75, 0.3), 0.5, false)
		pavio.name = "Pavio"
		var tw := n.create_tween().set_parallel()
		tw.tween_property(n, "scale", Vector3(0.12, 1, 0.12), atraso).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "rotation:y", -TAU * (0.5 + i * 0.25), atraso)
		tw.chain().tween_callback(n.queue_free)


## Explosão de pólvora: bola de fogo que incha e se corrói, labareda curta,
## onda, estilhaços, brasas e o chão queimado que fica uns segundos.
static func explosao_polvora(g: Node, at: Vector3, r: float) -> void:
	Magia.bola(g, at + Vector3(0, 0.5, 0), "brasa", r * 0.85, 0.5, {"achata": 0.7})
	Magia.chama(g, at, "brasa", r * 0.5, 3.4, 0.5, {"forca": 1.2})
	Magia.onda(g, at, "brasa", r * 1.15, 0.4)
	Magia.clarao(g, at, Color(1.0, 0.55, 0.2), r * 2.5, 0.3, 3.5)
	Magia.brasas(g, at, Color(1.0, 0.6, 0.2), 8, r * 0.5, 1.2)
	_detritos(g, at, Color(0.22, 0.18, 0.16), 8)
	FxProjetil.marca_chao(g, at, Color(0.05, 0.035, 0.03, 0.6), r * 0.75, 4.0)


## Arremate da Chuva de Flechas: cinco lanças de luz caem juntas no centro e
## abrem um estouro com onda na cor do time (`cor` = cor pura, sem clarear).
static func arremate_chuva(g: Node, centro: Vector3, r: float, cor: Color) -> void:
	var pal := Magia.paleta_de(cor)
	for k in 5:
		var a := k * TAU / 5.0
		var p: Vector3 = centro + Vector3(cos(a), 0, sin(a)) * r * 0.35 if k > 0 else centro
		Magia.lanca(g, p + Vector3(0, 12.0, 0), p + Vector3(0, 0.2, 0), pal, 0.5 if k == 0 else 0.3, 0.32, {"cresce": 0.08, "corre": 6.0})
	Magia.estouro(g, centro, pal, r * 0.7, 0.4)
	Magia.chama(g, centro, pal, r * 0.4, 3.2, 0.4)
	Magia.onda(g, centro, pal, r * 1.3, 0.45, {"voltas": 5.0})
	Magia.clarao(g, centro, cor, r * 3.0)
	Magia.brasas(g, centro, cor.lightened(0.4), 10, r * 0.6, 1.1)
	FxProjetil.marca_chao(g, centro, Color(Magia.TINTA, 0.5), r * 0.7, 2.5)


# --- Habilidade rápida (Q), golpe básico e super -----------------------------------

## Som de camada do elemento do poder (gerado por tools/gerar_sons.py magia).
static func som_elemento(u: Unit) -> String:
	match ELEMENTO.get(u.stats.power, [""])[0]:
		"brasa": return "magia_fogo"
		"vento", "aco": return "magia_vento"
		"sombra": return "magia_selo"
		"luz": return "magia_luz"
	return "magia_fogo" if u.stats.power == "coluna_fogo" else "magia_vento"


## Sohei (Varrida): a lâmina da naginata risca um anel de aço só na faixa
## que corta (dentro fica vazio: o cabo não fere) e a fé sobe em volta.
static func q_varrida(u: Unit, r: float) -> void:
	var g := u.game
	var p := u.global_position
	var pal := Magia.paleta_de(u.stats.hat_color)
	Magia.onda(g, p, "aco", r, 0.3, {"r0": u.stats.alcance_min / maxf(r, 0.1), "gira": 2.2, "banda": 0.18})
	Magia.onda(g, p, pal, r * 1.1, 0.42, {"gira": -1.0, "banda": 0.08, "forca": 0.8})
	Magia.anel_sobe(g, p + Vector3(0, 0.1, 0), pal, Config.cfg.varrida_aliados_raio * 0.35, 1.4, 0.5)
	FxProjetil.marca_chao(g, p, Color(0.08, 0.06, 0.04, 0.4), r * 0.55, 2.0)


## Kusarigama (Gancho): a corrente estica até o alvo (ou o fim do alcance) e
## volta; quando prende, estala um anel de aço nele.
static func q_gancho(u: Unit, ponta: Vector3, prendeu: bool) -> void:
	var g := u.game
	var de := u.global_position + Vector3(0, 1.2, 0)
	var ate := ponta + Vector3(0, 1.0, 0)
	Magia.lanca(g, de, ate, "aco", 0.32, 0.38, {"cresce": 0.1, "corre": 7.0, "forca": 1.1})
	Magia.lanca(g, de, ate, Magia.paleta_de(u.stats.hat_color), 0.14, 0.5, {"cresce": 0.12, "corre": -4.0})
	if prendeu:
		Magia.estouro(g, ate - Vector3(0, 0.6, 0), "aco", 1.1, 0.28)
		Magia.anel_sobe(g, ponta + Vector3(0, 0.5, 0), "aco", 0.7, 0.6, 0.45)
		FxProjetil.faiscas(g, ate, Color(0.85, 0.9, 1.0), 8, 6.0, Vector3.UP, 60.0)
		Sfx.play("hit", ponta, 0.1, 0.8)


## Último elo do combo da Kusarigama: a corrente dá a volta no corpo.
static func giro_corrente(u: Unit, r: float) -> void:
	if not Magia.enfeite():
		return
	Magia.onda(u.game, u.global_position, "aco", r, 0.28, {"r0": 0.6, "gira": 3.0, "banda": 0.1})


## Sohei (Muralha de Fé): parede de fé translúcida no ponto onde ele fincou
## a naginata (não segue o corpo: é um lugar), selo de 8 pontas no chão e um
## estouro de luz quando ela some.
static func muralha(u: Unit, r: float, dur: float) -> void:
	var g := u.game
	var p := u.global_position
	var pal := Magia.paleta_de(u.stats.hat_color)
	var no := _no(g, p)
	Magia.vortice(no, pal, r, 2.6, dur, {"r_topo": 1.0, "gira": 0.5, "sobe": -0.6, "forca": 1.2, "base": 0.35, "topo": 0.0, "alfa": 0.85})
	Magia.vortice(no, "luz", r * 0.98, 1.2, dur, {"r_topo": 1.0, "gira": -0.8, "forca": 0.8, "base": 0.6, "topo": 0.0, "alfa": 0.6})
	Magia.selo(g, p, pal, r, dur, {"pontas": 8, "escrita": 0.3, "giro": 0.05})
	Magia.onda(g, p, pal, r * 1.2, 0.45, {"banda": 0.1})
	FxProjetil.marca_chao(g, p, Color(0.06, 0.08, 0.07, 0.45), 1.0, dur)
	var tw := no.create_tween()
	tw.tween_interval(maxf(dur - 0.05, 0.1))
	tw.tween_callback(func() -> void:
		Magia.onda(g, p, "luz", r * 1.3, 0.4, {"gira": 0.6})
		Magia.brasas(g, p, pal[1], 8, r * 0.7, 0.9))
	tw.tween_interval(0.5)
	tw.tween_callback(no.queue_free)


## Kusarigama (Ciranda de Aço): anel baixo de corrente girando em volta do
## corpo (acompanha) e faíscas na borda; o miolo fica limpo (o cabo não corta).
static func ciranda(u: Unit, r: float, dur: float) -> void:
	var g := u.game
	Magia.vortice(u, "aco", r, 0.9, dur, {"r_topo": 1.15, "gira": 3.2, "sobe": 0.0, "forca": 1.4, "base": 0.5, "topo": 0.1, "y": 0.4})
	Magia.vortice(u, Magia.paleta_de(u.stats.hat_color), r * 0.55, 0.6, dur, {"r_topo": 1.3, "gira": -2.0, "forca": 0.7, "base": 0.4, "topo": 0.05, "y": 0.5})
	Magia.orbita(u, Color(0.85, 0.9, 1.0), r * 0.9, dur, 10, 0.8)
	Magia.onda(g, u.global_position, "aco", r * 1.2, 0.35, {"gira": 2.0, "banda": 0.12})


## Fita da lâmina: a faixa por onde a arma passou no golpe (segue a mão de
## verdade). Fina e curta nos golpes comuns, dourada e maior no golpe final.
static func fita_lamina(u: Unit, forte: bool) -> void:
	if not Magia.enfeite():
		return
	var mao := u.mao_da_arma()
	if mao == null:
		return
	var ponta := 1.9 if u.stats.id in [&"ronin_oni", &"sohei"] else (1.7 if u.stats.id == &"guerreiro" else 1.1)
	var pal: Variant = "luz" if forte else ("brasa" if u.stats.id == &"ronin_oni" else "aco")
	Magia.fita(mao, Vector3(0, ponta * (0.3 if forte else 0.5), 0), Vector3(0, ponta, 0), pal, 0.2 if forte else 0.16, {"pontos": 9, "forca": 0.5, "lados": 0.3})


## Ronin (Pisão): o chão cospe brasa por um instante.
static func q_pisao(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	var r := u.stats.skill_radius
	Magia.estouro(g, p, "brasa", r * 0.55, 0.32)
	Magia.clarao(g, p, Color(1.0, 0.4, 0.15), r * 2.0, 0.22, 2.2)
	Magia.brasas(g, p, Color(1.0, 0.5, 0.15), 8, r * 0.5, 1.0)
	FxProjetil.marca_chao(g, p, Color(0.06, 0.03, 0.03, 0.5), r * 0.5, 2.5)


## Samurai (Investida): risco de aço no ar e o rasgo de vento que fica no chão.
static func q_investida(u: Unit, de: Vector3, ate: Vector3) -> void:
	var g := u.game
	Magia.lanca(g, de + Vector3(0, 1.0, 0), ate + Vector3(0, 1.0, 0), "aco", 1.0, 0.3, {"corre": 6.0})
	Magia.lanca(g, de + Vector3(0, 0.08, 0), ate + Vector3(0, 0.08, 0), "vento", 0.7, 0.7, {"corre": 1.5, "forca": 1.0})
	Magia.onda(g, ate, "aco", 1.6, 0.3)
	Sfx.play("magia_vento", ate, 0.08, 1.25, -5.0)


## Tiro carregado: a boca do disparo acende na cor da classe.
static func q_tiro(u: Unit, dir: Vector3) -> void:
	var g := u.game
	var p := u.global_position + Vector3(0, 1.4, 0) + dir * 0.7
	var pal := Magia.paleta_de(u.stats.hat_color)
	Magia.lanca(g, p, p + dir * 2.2, pal, 0.55, 0.22, {"cresce": 0.05, "corre": 6.0})
	FxProjetil.brilho(g, p, pal[0], 1.1, 0.14)


## Kitsune (Cura): flor de luz que se escreve no chão e pétalas subindo.
static func q_cura(u: Unit) -> void:
	var g := u.game
	var pal: Variant = "luz" if u.stats.power == "bencao" else "cura"
	Magia.selo(g, u.global_position, pal, minf(u.stats.heal_radius, 5.5), 0.9, {"pontas": 0, "petalas": 6, "escrita": 0.2, "giro": 0.1})
	Magia.anel_sobe(g, u.global_position + Vector3(0, 0.2, 0), pal, 1.0, 2.2, 0.7)


## Fio de fogo-raposa que viaja de quem cura até o aliado curado.
static func fio_cura(de: Unit, alvo: Unit) -> void:
	var pal: Variant = "luz" if de.stats.power == "bencao" else "cura"
	Magia.lanca(de.game, de.global_position + Vector3(0, 1.3, 0), alvo.global_position + Vector3(0, 1.1, 0), pal, 0.22, 0.35, {"cresce": 0.12, "corre": 4.0, "forca": 0.9})
	Magia.anel_sobe(alvo.game, alvo.global_position + Vector3(0, 0.2, 0), pal, 0.8, 1.9, 0.6, 0.1)


## Armadilha/estrepes armados: poeirinha e um aro curto na cor da classe.
static func q_armadilha(u: Unit, at: Vector3) -> void:
	Magia.onda(u.game, at, Magia.paleta_de(u.stats.hat_color), 1.2, 0.3)
	Fx.burst(u.game, at + Vector3(0, 0.2, 0), Color(0.62, 0.55, 0.45), 6, 2.5)


## Abertura do super (R): o selo grande de ouro, tudo é sugado e a cúpula estoura.
static func abrir_super(u: Unit) -> void:
	var g := u.game
	var p := u.global_position
	Magia.selo(g, p, "luz", 4.5, 1.4, {"pontas": 8, "escrita": 0.2, "giro": 0.25})
	Magia.carga(g, p + Vector3(0, 1.2, 0), Color(1.0, 0.85, 0.4), 3.5, 0.22, 18)
	Magia.estouro(g, p, "luz", 3.2, 0.4)
	Magia.brasas(g, p, Color(1.0, 0.85, 0.4), 14, 2.2, 1.4)


# --- Economia e placar ------------------------------------------------------------

## Oficina sobe de nível: três anéis de energia dourada sobem pela casa e o
## letreiro "NÍVEL N!" estoura em cima.
static func subir_nivel(g: Node, pos: Vector3, cor: Color, nivel: int) -> void:
	var ouro := Color(1.0, 0.82, 0.35)
	var pal := Magia.paleta_de(ouro.lerp(cor, 0.25))
	for i in 3:
		Magia.anel_sobe(g, pos + Vector3(0, 0.3, 0), pal, 2.45, 4.2 + i * 0.6, 1.1, 0.18 * i)
	Magia.onda(g, pos, pal, 3.2, 0.5)
	Magia.clarao(g, pos, ouro, 9.0)
	_motas(g, pos + Vector3(0, 1.0, 0), ouro, 16)
	var l := Label3D.new()
	l.text = "NÍVEL %d!" % nivel
	l.font = Estilo.TITULO
	l.font_size = 80
	l.pixel_size = 0.011
	l.outline_size = 20
	l.outline_modulate = Color(0.25, 0.12, 0.0, 0.95)
	l.modulate = ouro.lightened(0.2)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.add_child(l)
	l.global_position = pos + Vector3(0, 5.2, 0)
	l.scale = Vector3.ONE * 0.3
	var tl := l.create_tween()
	tl.tween_property(l, "scale", Vector3.ONE * 1.2, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tl.tween_property(l, "scale", Vector3.ONE, 0.1)
	tl.set_parallel()
	tl.tween_property(l, "global_position:y", l.global_position.y + 1.2, 1.4).set_delay(0.4)
	tl.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(1.2)
	tl.tween_property(l, "outline_modulate:a", 0.0, 0.5).set_delay(1.2)
	tl.chain().tween_callback(l.queue_free)


## Captura da máscara: coluna de luz no castelo de quem pontuou, visível de
## longe (sobe acima dos telhados), com anéis subindo e a marca no chão.
static func coluna_captura(g: Node, pos: Vector3, cor_time: Color) -> void:
	var claro := cor_time.lightened(0.45)
	var pal := Magia.paleta_de(cor_time.lightened(0.15))
	Magia.chama(g, pos, pal, 2.4, 40.0, 2.9, {"segura": 0.6, "r_topo": 0.7, "barriga": 0.0, "base": 0.55, "topo": 0.3, "forca": 0.7, "escala": Vector2(2.0, 4.0), "rola": Vector2(0.15, -1.2)})
	Magia.chama(g, pos, "luz", 1.0, 40.0, 2.6, {"segura": 0.6, "r_topo": 0.8, "barriga": 0.0, "base": 0.75, "topo": 0.4, "forca": 0.5, "escala": Vector2(1.0, 4.0), "rola": Vector2(-0.2, -2.0)})
	for i in 4:
		Magia.anel_sobe(g, pos + Vector3(0, 0.3, 0), pal, 3.0, 14.0, 1.6, 0.25 * i)
	Magia.onda(g, pos, pal, 6.0, 0.7, {"voltas": 6.0})
	Magia.selo(g, pos, pal, 4.0, 3.0, {"pontas": 8, "escrita": 0.4, "giro": 0.15})
	Magia.clarao(g, pos, claro, 16.0, 0.6, 4.0)
	_motas(g, pos + Vector3(0, 0.5, 0), claro, 24)
	FxProjetil.marca_chao(g, pos, Color(claro, 0.5), 3.5, 3.0)


# --- Peças --------------------------------------------------------------------------

static func _no(parent: Node, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado por tween
	parent.add_child(n)
	n.global_position = pos
	return n


static func _malha(parent: Node3D, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Pedaços (pedra/madeira) voando e caindo.
static func _detritos(g: Node, pos: Vector3, cor: Color, qtd: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = qtd
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 11.0
	p.gravity = Vector3(0, -26, 0)
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.mesh = Fx.cached("detrito" + cor.to_html(), func() -> Mesh:
		var b := BoxMesh.new()
		b.size = Vector3(0.22, 0.18, 0.2)
		b.material = Fx.lit(cor)
		return b)
	g.add_child(p)
	p.global_position = pos + Vector3(0, 0.2, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Pontinhos de luz subindo devagar piscando.
static func _motas(g: Node, pos: Vector3, cor: Color, qtd: int) -> void:
	Magia.brasas(g, pos + Vector3(0, 0.3, 0), cor.lerp(Color.WHITE, 0.3), qtd, 0.8, 1.0)
