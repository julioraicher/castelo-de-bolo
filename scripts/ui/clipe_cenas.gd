class_name ClipeCenas
extends Node
## Gravador dos clipes do "Como jogar" (--clipe=DIR --cena=NOME).
## Cada cena é um roteiro curto com o jogador sem cérebro (as intenções vêm
## daqui), câmera fixa perto do boneco, HUD escondido e os outros bonecos
## congelados fora do quadro, menos os que a cena usa. Sai um JPG a cada
## PASSO quadros de física (60/PASSO por segundo), até N quadros.
##
## Cenas: objetivo, controles, madeira, oficinas, torreta, catapulta,
## luz_sombra, heroi e classe:<id> (3 golpes, Q, E e R da classe, como a vitrine).
## Uso: tools/clipes_tutorial.sh (grava todas e troca assets/tutorial).

const PASSO := 8          # 7,5 quadros por s
const TAM := Vector2i(400, 225)
const FRENTE := Vector3(1, 0, 0)

var game: Game
var dir := ""
var cena := ""
var max_quadros := 40
var _f := -1
var _n := 0
var _p0 := Vector3.ZERO
var _foco := Vector3.ZERO
var _cam_off := Vector3(0, 6.2, 8.0)
var _cam_alvo_y := 0.8
var _cam_vies := Vector3.ZERO   # a câmera mira um pouco à frente do boneco
var _alvos_pos: Array[Vector3] = []  # onde os alvos da vitrine de classe ficam
var _extras: Array[Unit] = []   # bonecos que a cena usa (parados)
var _teclado: PlayerBrain       # só para interact_pressed (F)
var _alvo_planta: Planta


## A cena é montada já na entrada na árvore (antes do primeiro quadro de física),
## senão o cérebro de bot do jogador age antes (ex.: veste um chapéu).
func _ready() -> void:
	_preparar()


func _physics_process(_delta: float) -> void:
	_f += 1
	var p := game.player
	# F dura um quadro, como no teclado.
	game.player_brain = _teclado
	_teclado.interact_pressed = false
	p.wants_quick = false
	p.wants_power = false
	p.wants_super = false
	p.wants_dodge = false
	if cena.begins_with("classe:"):
		_cena_classe(p)
	else:
		call("_cena_" + cena, p)
	for u in _extras:
		if u.alive:
			u.hp = maxf(u.hp, u.max_hp() * 0.6)
	_camera()
	if _f % PASSO == 0 and _f >= PASSO:
		_salvar()
	if _n >= max_quadros:
		get_tree().quit()


func _preparar() -> void:
	var p := game.player
	p.brain = null
	p._cancel_equip()
	p.move_intent = Vector3.ZERO
	_teclado = PlayerBrain.new()
	_teclado.unit = p
	_teclado.game = game
	game.hud.visible = false
	game.camera.set_process(false)
	game.camera.set_physics_process(false)
	game.camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	game.camera.fov = 42
	# Os outros bonecos saem do quadro; cada cena pega os que precisa de volta.
	for u in game.units:
		if u == p:
			continue
		u.brain = null
		u.move_intent = Vector3.ZERO
		u.wants_attack = false
		u.process_mode = Node.PROCESS_MODE_DISABLED
		u.global_position = Vector3(0, -40, 0)
		u.visible = false
	_p0 = Vector3(-24, 0, 0)
	_p0.y = game.arena.ground_y(_p0.x, _p0.z, 10.0)
	_foco = p.global_position
	call("_prep_" + ("classe" if cena.begins_with("classe:") else cena), p)
	_foco = p.global_position + _cam_vies
	game.camera.global_position = _foco + _cam_off


## Boneco parado que a cena usa: um bot congelado do time pedido ou, no modo
## teste (sem bots), um novo. Fica em pos, virado para dir, com hp_frac de vida.
## caido = pega o aliado de treino caído do modo teste (o Laço da Tennin
## levanta); senão só bonecos de pé (o caído aparecia como "CAÍDO" no clipe).
func _extra(team: int, pos: Vector3, dir: Vector3, hp_frac := 0.6, classe := "guerreiro", caido := false) -> Unit:
	var u: Unit = null
	for c in game.units:
		if c != game.player and c.team == team and c not in _extras and c.alive != caido:
			u = c
			break
	if u == null:
		u = Unit.new()
		u.name = "Extra_%d" % _extras.size()
		game.add_child(u)
		u.setup(game, team, false, load("res://config/classes/%s.tres" % classe))
		game.units.append(u)
	u.process_mode = Node.PROCESS_MODE_INHERIT
	u.visible = true
	pos.y = game.arena.ground_y(pos.x, pos.z, pos.y + 10.0)
	u.global_position = pos
	u.reset_physics_interpolation()
	u.aim_dir = dir
	u.move_intent = Vector3.ZERO
	if u.alive:
		u.hp = u.max_hp() * hp_frac
	_extras.append(u)
	return u


func _teleportar(p: Unit, pos: Vector3, dir := FRENTE) -> void:
	pos.y = game.arena.ground_y(pos.x, pos.z, pos.y + 10.0)
	p.global_position = pos
	p.reset_physics_interpolation()
	p.aim_dir = dir
	p.aim_point = pos + dir * 4.0
	_foco = pos


func _classe(p: Unit, id: String) -> void:
	p.set_class(load("res://config/classes/%s.tres" % id))


## Câmera: segue o boneco no chão (sem suavizar: quadro a quadro comparável),
## de frente e um pouco de cima, como a vitrine dos poderes.
func _camera() -> void:
	var p := game.player
	var alvo := p.global_position + _cam_vies
	if not p.em_voo:
		alvo.y = game.arena.ground_y(alvo.x, alvo.z, p.global_position.y + 5.0)
	_foco = _foco.lerp(alvo, 0.18)
	game.camera.global_position = _foco + _cam_off
	game.camera.look_at(_foco + Vector3(0, _cam_alvo_y, 0))


func _salvar() -> void:
	var full := game.get_viewport().get_texture().get_image()
	# Recorte do meio (16:9) com 80% da largura.
	var w := int(full.get_width() * 0.8)
	var h := int(w * 9 / 16)
	var img := full.get_region(Rect2i((full.get_width() - w) / 2, (full.get_height() - h) / 2, w, h))
	img.resize(TAM.x, TAM.y, Image.INTERPOLATE_LANCZOS)
	img.save_jpg("%s/%02d.jpg" % [dir, _n], 0.8)
	_n += 1


func _andar(p: Unit, para: Vector3, vira := true) -> void:
	var d := para - p.global_position
	d.y = 0.0
	if d.length() < 0.6:
		p.move_intent = Vector3.ZERO
		return
	p.move_intent = d.normalized()
	if vira:
		p.aim_dir = d.normalized()
		p.aim_point = para


# --- Cenas --------------------------------------------------------------------

## Pegar a máscara inimiga no pedestal e correr de volta.
func _prep_objetivo(p: Unit) -> void:
	_classe(p, "guerreiro")
	var m := game.princesses[1 - p.team]
	var fr := game.arena.forward(p.team)
	_teleportar(p, m.global_position - fr * 5.0, fr)
	_cam_off = Vector3(0, 7.0, 9.0)


func _cena_objetivo(p: Unit) -> void:
	var m := game.princesses[1 - p.team]
	var fr := game.arena.forward(p.team)
	if _f < 150 and not p.carried_princess:
		_andar(p, m.global_position - fr * 1.6)
		if p.global_position.distance_to(m.global_position) < 2.6 and _f % 10 == 0:
			_teclado.interact_pressed = true
	elif p.carried_princess:
		_andar(p, m.global_position - fr * 30.0)
	else:
		p.move_intent = Vector3.ZERO


## Combo de 3, defesa com contra-golpe e esquiva, contra dois inimigos parados.
func _prep_controles(p: Unit) -> void:
	_classe(p, "guerreiro")
	_teleportar(p, _p0)
	_extra(1 - p.team, _p0 + Vector3(2.2, 0, -0.8), -FRENTE)
	_extra(1 - p.team, _p0 + Vector3(2.6, 0, 1.0), -FRENTE)


func _cena_controles(p: Unit) -> void:
	p.move_intent = Vector3.ZERO
	p.aim_dir = FRENTE
	p.aim_point = _p0 + FRENTE * 3.0
	# O clique fica apertado 4 quadros: a recarga do golpe pode acabar no meio.
	p.wants_attack = (_f >= 20 and _f < 24) or (_f >= 70 and _f < 74) or (_f >= 120 and _f < 124)
	match _f:
		170:
			p.wants_block = true
		190:
			_extras[0].wants_attack = true
		191:
			_extras[0].wants_attack = false
		250:
			p.wants_block = false
		270:
			p.move_intent = -FRENTE
			p.wants_dodge = true
		300:
			p.move_intent = Vector3.ZERO


## Construtor corta a árvore, a tora cai, ele pega e sai andando.
func _prep_madeira(p: Unit) -> void:
	_classe(p, "construtor")
	for pl in game.plantas:
		if pl.lado == p.team and pl.tipo == "arvore" and pl.adulta():
			_alvo_planta = pl
			break
	var pos := _alvo_planta.global_position + Vector3(-0.9, 0, 1.7)
	_teleportar(p, pos, (_alvo_planta.global_position - pos).normalized())
	_cam_off = Vector3(0, 9.5, 9.0)
	_cam_alvo_y = 1.4


func _cena_madeira(p: Unit) -> void:
	if _f < 150:
		p.move_intent = Vector3.ZERO
		var d := _alvo_planta.global_position - p.global_position
		d.y = 0.0
		p.aim_dir = d.normalized()
		p.aim_point = _alvo_planta.global_position
		p.wants_attack = (_f >= 20 and _f < 24) or (_f >= 60 and _f < 64) or (_f >= 100 and _f < 104)
	elif _f < 230:
		# A tora caiu ao lado da árvore: encosta nela para pegar.
		p.wants_attack = false
		var t := game.nearest_tora_solta(p.global_position, 6.0)
		if t:
			_andar(p, t.global_position)
		else:
			p.move_intent = Vector3.ZERO
	else:
		_andar(p, game.pilhas[p.team].global_position)


## Recruta chega na barraquinha do Samurai e veste o chapéu com F. Desde as
## casinhas 2.0 a maquininha "mais longe da catapulta" caía atrás de um
## telhado; agora a cena é no miolo do bairro, com a câmera de cima.
var _pad_cena: HatPad


func _prep_oficinas(p: Unit) -> void:
	_classe(p, "recruta")
	for of in game.oficinas:
		if of.team == p.team and of.base.id == &"guerreiro" and of.pad_base:
			_pad_cena = of.pad_base
			# Chega pela frente da barraquinha (lado da câmera).
			_teleportar(p, of.global_position + Vector3(1.8, 0, 8.5), Vector3(0, 0, -1))
			_cam_vies = Vector3(0, 0, -2.0)
	if _pad_cena == null:
		_pad_cena = _pad_longe_da_catapulta(p.team)
		var fr := game.arena.forward(p.team)
		_teleportar(p, _pad_cena.global_position - fr * 4.5 + Vector3(0, 0, 1.0), fr)
	_cam_off = Vector3(0, 11.0, 5.5)


## Maquininha do time mais longe da catapulta (perto dela, o F sobe na catapulta).
func _pad_longe_da_catapulta(team: int) -> HatPad:
	var cat := game.catapulta_do_time(team)
	var melhor: HatPad = null
	for hp in game.hat_pads:
		if hp.team != team:
			continue
		if melhor == null or cat == null or hp.global_position.distance_to(cat.global_position) > melhor.global_position.distance_to(cat.global_position):
			melhor = hp
	return melhor


func _cena_oficinas(p: Unit) -> void:
	var pad := _pad_cena
	if _f < 200 and p.is_villager():
		_andar(p, pad.global_position)
		if p.global_position.distance_to(pad.global_position) < 1.9 and _f % 10 == 0:
			_teclado.interact_pressed = true
	elif _pad_cena != _pad_longe_da_catapulta(p.team):
		# Samurai novo: sai da barraquinha em direção à câmera e golpeia.
		if _virou_f < 0:
			_virou_f = _f
		var t := _f - _virou_f
		p.move_intent = Vector3(0, 0, 1) if t < 30 else Vector3.ZERO
		p.aim_dir = Vector3(0, 0, 1)
		p.aim_point = p.global_position + Vector3(0, 0, 4)
		p.wants_attack = t > 34 and t % 40 < 4
	else:
		p.move_intent = Vector3.ZERO
		var fr := game.arena.forward(p.team)
		p.aim_dir = fr
		p.aim_point = p.global_position + fr * 4.0


## Torreta inimiga de pé; o jogador defende e o virote volta nela.
func _prep_torreta(p: Unit) -> void:
	_classe(p, "guerreiro")
	for t in game.torretas:
		if t.team != p.team:
			t.concluir_ja()
			var fr := game.arena.forward(p.team)
			_teleportar(p, t.global_position - fr * 10.0, fr)
			break
	_cam_off = Vector3(0, 9.0, 9.0)
	_cam_alvo_y = 1.2


func _cena_torreta(p: Unit) -> void:
	p.move_intent = Vector3.ZERO
	for t in game.torretas:
		if t.team != p.team:
			var d := t.global_position - p.global_position
			d.y = 0.0
			p.aim_dir = d.normalized()
			p.aim_point = t.global_position
			break
	p.wants_block = _f >= 30


## Subir na catapulta e voar.
func _prep_catapulta(p: Unit) -> void:
	_classe(p, "guerreiro")
	var cat := game.catapulta_do_time(p.team)
	var fr := game.arena.forward(p.team)
	_teleportar(p, cat.global_position - fr * 2.0, fr)
	_cam_off = Vector3(0, 13.0, 15.0)
	_cam_alvo_y = 1.5


func _cena_catapulta(p: Unit) -> void:
	var cat := game.catapulta_do_time(p.team)
	p.move_intent = Vector3.ZERO
	if _f == 20:
		cat.embarcar(p)
	if _f == 110 and cat.passageiro == p:
		cat.forca = 0.8
		cat.lancar()


## Kitsune da Luz cura (Q) e abençoa (E) uma aliada ferida; depois a Sombria
## solta o Orbe (Q) e o Selo (E) nos inimigos.
func _prep_luz_sombra(p: Unit) -> void:
	_classe(p, "kitsune_luz")
	_teleportar(p, _p0)
	_extra(p.team, _p0 + Vector3(-1.4, 0, 1.6), FRENTE, 0.35)
	_extra(1 - p.team, _p0 + Vector3(7.5, 0, -0.9), -FRENTE)
	_extra(1 - p.team, _p0 + Vector3(8.3, 0, 1.0), -FRENTE)


func _cena_luz_sombra(p: Unit) -> void:
	p.move_intent = Vector3.ZERO
	p.aim_dir = FRENTE
	p.aim_point = _p0 + FRENTE * 8.0
	if _f < 180:
		_extras[0].hp = minf(_extras[0].hp, _extras[0].max_hp() * 0.45)
	match _f:
		30:
			p.wants_quick = true
		90:
			p.fill_power()
			p.wants_power = true
		190:
			_classe(p, "kitsune_sombria")
		220:
			p.wants_quick = true
		280:
			p.fill_power()
			p.wants_power = true


## Herói raro (aba do "Como jogar"): o pavilhão dourado do bairro do Samurai
## fica pronto, o Recruta pega o chapéu único e vira o herói, que já usa o Q.
var _of_heroi: Oficina
var _virou_f := -1


func _prep_heroi(p: Unit) -> void:
	_classe(p, "recruta")
	for of in game.oficinas:
		if of.team == p.team and of.base.id == &"guerreiro":
			_of_heroi = of
	_of_heroi.concluir_ja(0)
	while _of_heroi.nivel < Config.cfg.mago_nivel_max and _of_heroi.pode_subir():
		_of_heroi.subir_nivel()  # as peças do Nv4/Nv5 nas duas casas
	_of_heroi.nivel = Config.cfg.mago_nivel_max
	game.madeira[p.team] = maxi(game.madeira[p.team], Config.cfg.heroi_custo)
	_of_heroi.escolher_heroi(0, true)
	# Bairro: casa em z-2,6, barraquinha em z+3, tapetes em x±3,7. Fora dele há
	# telhados do castelo, então tudo acontece no miolo do bairro (entre a casa
	# e a barraquinha), com a câmera bem de cima para nada tampar.
	var meio := _of_heroi.global_position + Vector3(0, 0, 0.3)
	var lado := signf(_of_heroi.pavilhao_pos().x - meio.x)
	_teleportar(p, meio + Vector3(0.6 * lado, 0, 0), Vector3(lado, 0, 0))
	_extra(1 - p.team, meio + Vector3(-1.8 * lado, 0, 0), Vector3(lado, 0, 0))
	_cam_off = Vector3(0, 11.0, 5.5)
	_cam_vies = Vector3(-0.6 * lado, 0, 0)  # do lado de fora do pavilhão há o muro do castelo


func _cena_heroi(p: Unit) -> void:
	if _f == 10:
		_of_heroi._finish_heroi(true)
	var pad := _of_heroi.pad_heroi
	if p.is_villager():
		if _f > 40 and pad:
			_andar(p, pad.global_position)
			if p.global_position.distance_to(pad.global_position) < 1.9 and _f % 10 == 0:
				_teclado.interact_pressed = true
		else:
			p.move_intent = Vector3.ZERO
		return
	if _virou_f < 0:
		_virou_f = _f
	var alvo := _extras[0]
	var d := alvo.global_position - p.global_position
	d.y = 0.0
	if d.length() > 1.8 and _f - _virou_f < 40:
		_andar(p, alvo.global_position)
	else:
		p.move_intent = Vector3.ZERO
		p.aim_dir = d.normalized()
		p.aim_point = alvo.global_position
	if _f - _virou_f == 44:
		p.wants_quick = true
	elif _f - _virou_f == 110:
		p.fill_power()
		p.wants_power = true


## Uma classe: 3 golpes, Q, E e R, contra alvos parados (como a vitrine).
func _prep_classe(p: Unit) -> void:
	_classe(p, cena.trim_prefix("classe:"))
	_teleportar(p, _p0)
	var corpo := p.stats.attack_kind == "melee"
	# De longe: alvos a 5 m (a 7 m ficavam na beira do quadro e o E puxava/
	# empurrava gente que nem aparecia).
	var perto := 2.2 if corpo else 5.0
	for off in [Vector3(perto, 0, -0.9), Vector3(perto + 0.6, 0, 1.0), Vector3(perto + 2.0, 0, 0.1)]:
		_alvos_pos.append(_extra(1 - p.team, _p0 + off, -FRENTE).global_position)
	# Tennin: o Laço puxa o aliado caído (levanta na hora), então ele fica longe e caído.
	var laco := p.stats.skill == "laco"
	var ferido := Vector3(-4.2, 0, 2.6) if laco else Vector3(-1.6, 0, 1.8)
	_extra(p.team, _p0 + ferido, FRENTE, 0.4, "guerreiro", laco and game.sandbox)
	_cam_off = Vector3(0, 6.2, 8.0) if corpo else Vector3(0, 7.0, 9.0)
	_cam_vies = FRENTE * (1.2 if corpo else 2.6)


func _alvos_no_lugar() -> void:
	for i in _alvos_pos.size():
		var u := _extras[i]
		if u.alive and not u.em_voo and u.global_position.distance_to(_alvos_pos[i]) > 1.0:
			u.global_position = _alvos_pos[i]
			u.reset_physics_interpolation()
			u._knock = Vector3.ZERO


func _cena_classe(p: Unit) -> void:
	p.move_intent = Vector3.ZERO
	# Mira no meio dos alvos: quem se teleporta (Rasteira, Mergulho) vira para
	# eles de novo, e o E/R cai em cima deles.
	var meio := Vector3.ZERO
	var n := 0
	for i in _alvos_pos.size():
		if _extras[i].alive and not _extras[i].em_voo:
			meio += _extras[i].global_position
			n += 1
	var alvo := meio / n if n > 0 else p.global_position + FRENTE * 4.0
	var d := alvo - p.global_position
	d.y = 0.0
	p.aim_dir = d.normalized() if d.length() > 0.5 else FRENTE
	p.aim_point = alvo
	# Antes de cada poder os alvos voltam ao lugar (o combo e o E anterior
	# empurram, e o Q/E/R seguinte acertava o vazio).
	if _f in [154, 234, 374]:
		_alvos_no_lugar()
		# Quem se teleportou no Q (Rasteira, Mergulho) volta para a marca.
		if not p.em_voo and p.global_position.distance_to(_p0) > 1.5:
			_teleportar(p, _p0)
	if _f < 150:
		_extras[3].hp = minf(_extras[3].hp, _extras[3].max_hp() * 0.4)
	p.wants_attack = (_f >= 20 and _f < 24) or (_f >= 70 and _f < 74) or (_f >= 120 and _f < 124) \
			or (_f >= 425 and _f < 429 and p.stats.super_tipo == "sombra")  # golpe saindo da sombra (o clipe acaba no 448)
	match _f:
		160:
			p.wants_quick = true
		240:
			p.fill_power()
			p.wants_power = true
		380:
			p.super_carga = Unit.POWER_MAX
			p.wants_super = true
