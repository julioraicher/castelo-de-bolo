class_name Oficina
extends Node3D
## Casa da classe (Ciclo 2.21): um bairro por classe do pátio. Na frente fica a
## barraquinha de festival da classe base (HatPad pad_base); dos lados, dois
## tapetes com o FANTASMA da casa de cada caminho (ClassStats.caminhos: [0] à
## esquerda, [1] à direita, como a câmera vê).
##
## Escada do bairro (Ciclo 2.22), `nivel` vale para o bairro inteiro:
##   Nv1 → Nv2: Construtores parados no bairro puxam casa_nv2_custo madeiras e
##              a barraquinha sobe sozinha (sem caminho).
##   Nv2 → Nv3: escolha do caminho. O jogador Construtor aperta [F] no bairro
##              e escolhe num painel com dois botões (Hud.abrir_escolha); bots
##              Construtores param ESCOLHA_T s no tapete sorteado. A primeira
##              madeira entra, o outro tapete é selado e a casa sobe; pronta,
##              nasce no Nv3 e a barraquinha vai junto.
##   Nv3 → Nv5: uma subida (mago_nivel_custo) leva barraquinha e casa juntas.
##   Nv5 → Nv6 (Ciclo 2.23): segunda escolha, um HERÓI RARO entre os
##              ClassStats.herois da classe base (2 ou mais; o Construtor não
##              tem). O Pavilhão do Herói sobe no tapete do caminho escolhido
##              (heroi_custo madeiras) e é a terceira casinha de chapéu: 1
##              chapéu só, sem fabricar; volta heroi_retorno s depois que o
##              herói sai de campo (renasce como aldeão ou troca de chapéu).
##              Só o herói é Nv6; barraquinha e casa param no 5.
##
## Obra: d(progresso)/dt = Σ velocidade_obra / oficina_build_time, somando os
## Construtores do time a menos de BUILD_RADIUS do centro do bairro, mas o
## progresso não passa de madeira_entregue / oficina_custo_madeira (Ciclo 2.3).
## Quem está no bairro puxa 1 madeira do estoque a cada oficina_puxar_intervalo
## / Σv s. Pronta, a casa É a maquininha da classe evoluída (HatPad pad, modelo
## maquina_<classe>.scn), já no nível 2; a barraquinha também sobe para o 2.
## Cada nível acima do 2: peça nova no modelo (N3_*/N4_*/N5_* na barraquinha,
## N4_*/N5_* na casa), +1 chapéu de estoque e fabricação mais rápida nas duas,
## e bônus de dano/vida/Chi para quem usa a classe base ou a do caminho.
##
## (O nome "Oficina" ficou dos ciclos antigos: game.oficinas, minimapa, bots.)

enum Estado { VAZIO, OBRA, PRONTA }

## Posições no bairro (a câmera olha de +z): casa atrás, barraquinha na frente,
## tapetes dos lados, estandarte no canto de trás.
const CASA := Vector3(0, 0, -2.6)
const BARRACA := Vector3(0, 0, 3.0)
const TAPETES := [Vector3(-3.7, 0, 0.3), Vector3(3.7, 0, 0.3)]
const BANDEIRA := Vector3(4.3, 0, -3.3)
const TAPETE_R := 1.3
## Construtor a menos disto do centro trabalha na casa (obra e níveis).
const BUILD_RADIUS := 4.8
## Raio do chão pintado do bairro (QA do mapa, minimapa).
const RAIO := 5.4
const ESCOLHA_T := 0.5
## Construtor mais lento que isto (m/s) conta como parado trabalhando.
const PARADO_VEL := 1.5
const FANTASMA_ESC := 0.56
const SHADER_FANTASMA := preload("res://assets/shaders/casa_fantasma.gdshader")

var team := 0
var estado := Estado.VAZIO
var progresso := 0.0
var madeira_entregue := 0
## Obra parada porque o time não tem madeira (o contador pisca).
var falta_madeira := false
## Classe do pátio desta casa (Samurai, Ninja...).
var base: ClassStats
## Barraquinha de festival da classe base (sempre de pé).
var pad_base: HatPad
## A casa pronta: maquininha da classe evoluída.
var pad: HatPad
## -1 = caminho ainda não escolhido; 0/1 = índice em base.caminhos.
var caminho := -1
var nivel := 1
var madeira_nivel := 0
## Antigo (terreno de mago selado). A casa nunca fica selada: quem é selado é
## o tapete do caminho que não foi escolhido.
var selada := false
## Tapete que os bots vão escolher (sorteado no começo da partida).
var escolha_bot := 0

var _game: Game
var _tapete_t := [0.0, 0.0]
var _bairro: Node3D
var _selos: Array[Node3D] = [null, null]
var _panos: Dictionary = {}   # "azul"/"vermelho"/"c0"/"c1" -> Node3D
var _emblema_bandeira: Node3D
var _fantasmas: Array[MeshInstance3D] = []
var _obra: Node3D
var _telhado: Node3D
var _label: Label3D
var _contador: ContadorMadeira
var _puxar_t := 0.0
var _dust_t := 0.0
var _t := randf() * TAU
var _texto := ""
var _custo := -1   # fixado na escolha do caminho
## Ciclo 2.23: herói raro do Nv6. heroi = índice em herois() (-1 = nenhum);
## pad_heroi = o chapéu no pavilhão (estoque 1, sem fabricar).
var heroi := -1
var escolha_heroi_bot := 0
var pad_heroi: HatPad
var heroi_pronto := false
var _retorno_t := -1.0
var _heroi_t := 0.0
var _pav_fantasma: MeshInstance3D
var _pav_obra: Node3D
var _destaque: Node3D
var _destaque_avisado := false

static var _malhas_fantasma := {}   # caminho da cena -> ArrayMesh (uma superfície)


func setup(game: Game, p_team: int, pos: Vector3, p_base: ClassStats) -> void:
	_game = game
	team = p_team
	base = p_base
	position = pos
	escolha_bot = Sorte.i() % 2
	escolha_heroi_bot = Sorte.i() % maxi(herois().size(), 1)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # cresce por código
	_montar_bairro()
	pad_base = HatPad.new()
	pad_base.aceita_madeira = false
	game.add_child(pad_base)
	pad_base.setup(team, base, pos + BARRACA)
	game.hat_pads.append(pad_base)
	for i in mini(caminhos().size(), 2):
		_fantasmas.append(_montar_fantasma(i))
	_label = Label3D.new()
	_label.font = Estilo.LETREIRO
	_label.font_size = 42
	_label.pixel_size = 0.011
	_label.line_spacing = -6
	_label.outline_size = 12
	_label.outline_modulate = Estilo.TINTA
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = CASA + Vector3(0, 4.4, 0)
	_label.add_to_group("letreiro_perto")  # some de longe (Game._letreiros_perto)
	add_child(_label)
	_contador = ContadorMadeira.new()
	_contador.position = CASA + Vector3(0, 4.0, 0)
	add_child(_contador)
	_update_label()


func caminhos() -> Array[ClassStats]:
	return base.caminhos if base else ([] as Array[ClassStats])


## Heróis raros do Nv6 desta classe (Ciclo 2.23); vazio = o bairro para no 5.
func herois() -> Array[ClassStats]:
	return base.herois if base else ([] as Array[ClassStats])


## Herói escolhido (ou, antes, o sorteado dos bots). null = bairro sem herói.
func heroi_cls() -> ClassStats:
	var h := herois()
	if h.is_empty():
		return null
	return h[heroi if heroi >= 0 else escolha_heroi_bot]


## Nível 5 com herói para escolher (o Construtor decide no painel ou no tapete).
func pede_heroi() -> bool:
	return estado == Estado.PRONTA and nivel >= Config.cfg.mago_nivel_max and heroi < 0 \
			and herois().size() >= 1 and caminho >= 0


## Onde fica o pavilhão: o tapete do caminho escolhido (vazio depois da casa).
func pavilhao_pos() -> Vector3:
	return tapete_pos(maxi(caminho, 0))


## Escolhe o herói i: gasta a primeira madeira e começa o pavilhão. false =
## não é hora, já escolhido ou o time sem madeira.
func escolher_heroi(i: int, gratis := false) -> bool:
	if not pede_heroi() or i < 0 or i >= herois().size():
		return false
	if not gratis and not _game.gastar_madeira(team, 1):
		return false
	heroi = i
	madeira_nivel = 0 if gratis else 1
	_tapete_t = [0.0, 0.0]
	_comecar_pavilhao()
	if is_inside_tree():
		var cor := Estilo.OURO_CLARO
		Fx.pillar(_game, pavilhao_pos(), cor, 2.2)
		Fx.burst(_game, pavilhao_pos() + Vector3(0, 0.8, 0), cor, 16, 4.0)
		Sfx.play("sino", pavilhao_pos(), 0.05)
	_game.on_heroi_escolhido(self)
	_update_label()
	return true


## Classe do caminho escolhido (ou, antes da escolha, a do tapete dos bots).
func opcao() -> ClassStats:
	var c := caminhos()
	if c.is_empty():
		return base
	return c[caminho if caminho >= 0 else escolha_bot]


func tapete_pos(i: int) -> Vector3:
	return global_position + TAPETES[i]


## Índice do tapete sob `pos` (-1 = nenhum).
func tapete_sob(pos: Vector3) -> int:
	for i in 2:
		var d := pos - tapete_pos(i)
		d.y = 0.0
		if d.length() < TAPETE_R:
			return i
	return -1


## Ponto de trabalho da casa para o Construtor: a frente da barraquinha no
## Nv1, o tapete dos bots no Nv2 (escolha), a frente da casa depois.
func alvo_obra(from: Vector3) -> Vector3:
	var lado := from - global_position
	lado.y = 0.0
	if nivel < 2:
		# Nv1: na frente da barraquinha (fora dos tapetes: lá não se escolhe ainda).
		return global_position + BARRACA + Vector3(clampf(lado.x, -1.6, 1.6), 0, 1.0)
	if caminho < 0:
		return tapete_pos(escolha_bot)
	if pede_heroi() or (heroi >= 0 and not heroi_pronto):
		# Nv6: o tapete do pavilhão (os bots param nele para escolher o herói).
		return pavilhao_pos() + Vector3(0, 0, 0.2 if pede_heroi() else 1.6)
	var frente := global_position + CASA + Vector3(0, 0, 2.0)
	return frente + Vector3(clampf(lado.x, -2.2, 2.2), 0, 0)


## A obra começou: o caminho está escolhido (a primeira madeira já entrou).
func comecada() -> bool:
	return caminho >= 0


## Madeira da casa: oficina_custo_madeira + oficina_custo_degrau por casa que
## o time já tinha escolhido antes desta (fica fixo na escolha).
func custo() -> int:
	if _custo >= 0:
		return _custo
	if _game == null or _game.sandbox:
		return Config.cfg.oficina_custo_madeira
	var antes := 0
	for of in _game.oficinas:
		if of != self and of.team == team and of.caminho >= 0:
			antes += 1
	return Config.cfg.oficina_custo_madeira + Config.cfg.oficina_custo_degrau * antes


func faltam() -> int:
	return maxi(custo() - madeira_entregue, 0)


## Teto da obra: a fração de madeira já entregue.
func teto() -> float:
	return 1.0 if custo() <= 0 else float(madeira_entregue) / custo()


## Escolhe o caminho i: gasta a primeira madeira, sela o outro tapete e começa
## a casa. false = já escolhido ou o time sem madeira.
func escolher(i: int, gratis := false) -> bool:
	if caminho >= 0 or i < 0 or i >= caminhos().size() or nivel < 2:
		return false
	if not gratis and not _game.gastar_madeira(team, 1):
		return false
	_custo = custo()
	caminho = i
	madeira_entregue = 0 if gratis else 1
	estado = Estado.OBRA
	_selar_tapete(1 - i)
	_comecar_obra()
	_pintar_estandarte()
	if is_inside_tree():
		var cor := opcao().hat_color.lightened(0.3)
		Fx.pillar(_game, tapete_pos(i), cor, 1.6)
		Fx.burst(_game, tapete_pos(i) + Vector3(0, 0.8, 0), cor, 14, 4.0)
		Sfx.play("nivel", tapete_pos(i), 0.05)
	_game.on_caminho_escolhido(self)
	_update_label()
	return true


## Puxa 1 madeira do estoque do time para a obra. false = sem estoque ou já cheia.
func puxar_madeira() -> bool:
	if estado != Estado.OBRA or faltam() <= 0 or not _game.gastar_madeira(team, 1):
		return false
	madeira_entregue += 1
	if is_inside_tree():
		Fx.burst(_game, global_position + CASA + Vector3(0, 0.6, 1.2), Color(0.7, 0.5, 0.25), 5, 2.5)
	return true


func add_progress(frac: float, by: Unit) -> void:
	if estado != Estado.OBRA:
		return
	progresso = minf(progresso + frac, teto())
	if _obra:
		_obra.scale.y = maxf(progresso, 0.04)
	if by:
		by.building_t = 0.25
	if progresso >= 1.0 - 1e-6:
		progresso = 1.0
		_finish()


## Σ velocidade_obra dos Construtores do time parados no bairro (e os marca
## construindo). Parado: quem só passa pelo bairro (indo ao depósito) não
## puxa madeira para a casa sem querer.
func _ritmo_obra() -> float:
	var rate := 0.0
	for u in _game.units:
		if u.alive and u.team == team and u.lenhador() and not u.carried_princess \
				and not u.carried_tora and u.global_position.distance_to(global_position) < BUILD_RADIUS \
				and Vector2(u.velocity.x, u.velocity.z).length() < PARADO_VEL:
			rate += u.stats.velocidade_obra
			u.building_t = 0.25
	return rate


## Bot Construtor do time parado no tapete i? (Passar por cima não escolhe.)
## O jogador escolhe pelo painel ([F] no bairro), nunca pisando.
func _construtor_no_tapete(i: int) -> bool:
	for u in _game.units:
		if u.alive and u.team == team and u.lenhador() and not u.carried_princess \
				and u.brain is BotBrain \
				and not u.carried_tora and tapete_sob(u.global_position) == i \
				and Vector2(u.velocity.x, u.velocity.z).length() < PARADO_VEL:
			return true
	return false


func _physics_process(delta: float) -> void:
	if _game.game_over:
		return
	match estado:
		Estado.VAZIO:
			if nivel < 2:
				_obra_nivel(delta)
			else:
				_escolha(delta)
		Estado.OBRA:
			_obra_tick(delta)
		Estado.PRONTA:
			if pede_heroi():
				_escolha_heroi(delta)
			elif pode_subir():
				_obra_nivel(delta)
			if heroi_pronto:
				_tick_heroi(delta)
	_update_label()


func _escolha(delta: float) -> void:
	falta_madeira = false
	for i in _fantasmas.size():
		if _construtor_no_tapete(i):
			_tapete_t[i] += delta
			falta_madeira = _game.madeira[team] <= 0
			if _tapete_t[i] >= ESCOLHA_T and escolher(i):
				return
		else:
			_tapete_t[i] = 0.0


func _obra_tick(delta: float) -> void:
	var rate := _ritmo_obra() * _game.mult_obra()
	if rate <= 0.0:
		falta_madeira = false
		return
	_puxar_t -= delta * rate
	if _puxar_t <= 0.0 and faltam() > 0:
		if puxar_madeira():
			_puxar_t = Config.cfg.oficina_puxar_intervalo
	falta_madeira = faltam() > 0 and progresso >= teto() - 1e-4 and _game.madeira[team] <= 0
	if progresso >= teto() - 1e-4:
		return  # esperando madeira: sem poeira nem martelada
	add_progress(rate * delta / Config.cfg.oficina_build_time, null)
	_dust_t -= delta
	if _dust_t <= 0.0 and estado == Estado.OBRA:
		_dust_t = 0.35
		Fx.burst(_game, global_position + CASA + Vector3(randf_range(-1.4, 1.4), 0.3, randf_range(-0.5, 1.4)), Color(0.75, 0.65, 0.5), 4, 2.5)
		Sfx.play("swing", global_position, 0.3)


# --- Níveis 2, 4 e 5 -----------------------------------------------------------

## Aceita madeira para subir de nível: a barraquinha no Nv1 (sobe ao 2 sem
## caminho) ou a casa pronta abaixo do máximo (as duas sobem juntas).
func pode_subir() -> bool:
	return (estado == Estado.VAZIO and nivel < 2) or (estado == Estado.PRONTA and nivel < Config.cfg.mago_nivel_max) \
			or (heroi >= 0 and not heroi_pronto)


## Esperando a escolha do caminho (Nv2, sem caminho).
func pede_escolha() -> bool:
	return estado == Estado.VAZIO and nivel >= 2 and caminhos().size() >= 2


func custo_nivel() -> int:
	if nivel < 2:
		return Config.cfg.casa_nv2_custo
	if nivel >= Config.cfg.mago_nivel_max:
		return Config.cfg.heroi_custo
	var c := Config.cfg.mago_nivel_custo
	var i := nivel - 3
	return c[clampi(i, 0, c.size() - 1)] if not c.is_empty() else 0


func faltam_nivel() -> int:
	if pede_heroi():
		return Config.cfg.heroi_custo
	return maxi(custo_nivel() - madeira_nivel, 0) if pode_subir() else 0


## Puxa 1 madeira do estoque para o próximo nível; a última sobe o nível.
func puxar_madeira_nivel() -> bool:
	if not pode_subir() or not _game.gastar_madeira(team, 1):
		return false
	madeira_nivel += 1
	if is_inside_tree():
		var onde := CASA + Vector3(0, 1.2, 1.0) if estado == Estado.PRONTA else BARRACA + Vector3(0, 1.0, 0)
		if heroi >= 0:
			onde = pavilhao_pos() - global_position + Vector3(0, 0.8, 0.6)
		Fx.burst(_game, global_position + onde, cor_nivel(), 5, 2.5)
	if heroi >= 0:
		_crescer_pavilhao()
	if faltam_nivel() <= 0:
		subir_nivel()
	return true


## Cor dos efeitos de nível: a do caminho com a casa de pé, a da base antes.
func cor_nivel() -> Color:
	if heroi >= 0:
		return Estilo.OURO_CLARO
	return (opcao() if estado == Estado.PRONTA else base).hat_color.lightened(0.3)


func subir_nivel() -> void:
	if not pode_subir():
		return
	if heroi >= 0 and not heroi_pronto:
		_finish_heroi()
		return
	nivel += 1
	madeira_nivel = 0
	if nivel == 2:
		# Só a barraquinha (HatPad.subir_nivel: estoque e ritmo do nível 2).
		if pad_base:
			pad_base.subir_nivel()
		_update_label()
		_game.on_mago_nivel(self)
		return
	_degrau_pad(pad)
	_degrau_pad(pad_base)
	if is_inside_tree():
		var cor := cor_nivel()
		Fx.pillar(_game, global_position + CASA, cor, 2.6 + 0.4 * nivel)
		FxPoder.subir_nivel(_game, global_position + CASA, cor, nivel)
		Fx.pillar(_game, global_position + BARRACA, base.hat_color.lightened(0.3), 2.0 + 0.3 * nivel)
		Sfx.play("nivel", global_position, 0.02)
	_update_label()
	_game.on_mago_nivel(self)


## Um nível acima do 2 numa maquininha do bairro: +1 de estoque (ganha o chapéu
## na hora), fabrica mais rápido e mostra a peça do nível.
func _degrau_pad(p: HatPad) -> void:
	if p == null:
		return
	p.estoque_max += 1
	p.intervalo *= Config.cfg.mago_pad_intervalo_mult
	if p.estoque < p.estoque_max:
		p.estoque += 1
		p._fabricou()
	p.mostrar_nivel(nivel)


func _obra_nivel(delta: float) -> void:
	var rate := _ritmo_obra() * _game.mult_obra()
	if rate > 0.0:
		_puxar_t -= delta * rate
		if _puxar_t <= 0.0 and puxar_madeira_nivel():
			_puxar_t = Config.cfg.oficina_puxar_intervalo
	falta_madeira = rate > 0.0 and _game.madeira[team] <= 0


# --- Herói raro (Nv6, Ciclo 2.23) ------------------------------------------------

## Bot Construtor parado no tapete do pavilhão: escolhe o herói sorteado.
func _escolha_heroi(delta: float) -> void:
	var i := maxi(caminho, 0)
	falta_madeira = false
	if _construtor_no_tapete(i):
		_heroi_t += delta
		falta_madeira = _game.madeira[team] <= 0
		if _heroi_t >= ESCOLHA_T and escolher_heroi(escolha_heroi_bot):
			_heroi_t = 0.0
	else:
		_heroi_t = 0.0


## Depósito com madeira para o herói inteiro: o quintal avisa que dá para subir.
func destaque_heroi() -> bool:
	return pede_heroi() and (_game.sandbox or _game.madeira[team] >= Config.cfg.heroi_custo)


## Herói deste bairro em campo: alguém do time vestido com ele (ou trocando
## para ele). Caído esperando reanimar continua herói.
func heroi_em_campo() -> bool:
	var h := heroi_cls()
	if h == null:
		return false
	for u in _game.units:
		if u.team == team and (u.stats == h or u._equip_stats == h or u._stats_normal == h):
			return true
	return false


## Pavilhão pronto: o chapéu volta heroi_retorno s depois que o herói sai de campo.
func _tick_heroi(delta: float) -> void:
	if pad_heroi == null or pad_heroi.estoque > 0:
		_retorno_t = -1.0
		return
	if heroi_em_campo():
		_retorno_t = -1.0
		pad_heroi.retorno = -1.0
		return
	if _retorno_t < 0.0:
		_retorno_t = Config.cfg.sandbox_heroi_retorno if _game.sandbox else Config.cfg.heroi_retorno
	_retorno_t -= delta
	pad_heroi.retorno = maxf(_retorno_t, 0.0)
	if _retorno_t <= 0.0:
		_retorno_t = -1.0
		pad_heroi.restaurar()


func _finish_heroi(anim := true) -> void:
	heroi_pronto = true
	nivel = Config.cfg.mago_nivel_max + 1
	madeira_nivel = 0
	pad_heroi = HatPad.new()
	pad_heroi.raro = true
	_game.add_child(pad_heroi)
	pad_heroi.setup(team, heroi_cls(), pavilhao_pos(), _cena_pavilhao())
	pad_heroi.raio_pegar = 2.0
	pad_heroi.altura_letreiro(4.9)
	pad_heroi.adorno(_game.arena.theme if _game.arena else Config.theme())
	pad_heroi.mostrar_nivel(nivel)
	_game.hat_pads.append(pad_heroi)
	if _pav_obra:
		_pav_obra.queue_free()
		_pav_obra = null
	if anim and is_inside_tree():
		pad_heroi.scale = Vector3(1.0, 0.2, 1.0)
		pad_heroi.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).tween_property(pad_heroi, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.pillar(_game, pavilhao_pos(), Estilo.OURO_CLARO, 4.0)
		FxPoder.subir_nivel(_game, pavilhao_pos(), Estilo.OURO_CLARO, nivel)
		Fx.burst(_game, pavilhao_pos() + Vector3(0, 2.0, 0), Color(1.0, 0.85, 0.45), 24, 6.0)
		Sfx.play("sino", pavilhao_pos(), 0.0, 1.0, 3.0)
	_update_label()
	_game.on_heroi_pronto(self)


func _cena_pavilhao() -> String:
	var th: ThemeConfig = _game.arena.theme if _game and _game.arena else Config.theme()
	return th.model_path("pavilhao.scn")


## Fantasma do pavilhão no Nv5 (sem herói escolhido): translúcido e dourado.
func _montar_pav_fantasma() -> void:
	if _pav_fantasma or herois().is_empty() or caminho < 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_fantasma(_cena_pavilhao())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_FANTASMA
	mat.set_shader_parameter("cor", Color(1.0, 0.82, 0.4))
	mat.set_shader_parameter("alfa", 0.55)
	mat.set_shader_parameter("altura", 4.4)
	mi.material_override = mat
	mi.position = TAPETES[maxi(caminho, 0)] + Vector3(0, 0.15, 0)
	add_child(mi)
	_pav_fantasma = mi
	_destaque = Node3D.new()
	_destaque.position = TAPETES[maxi(caminho, 0)] + Vector3(0, 0.06, 0)
	_destaque.visible = false
	add_child(_destaque)
	# Anel dourado pulsando no tapete (1 chamada; luz omni custaria passes extras).
	var anel := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.32
	tor.outer_radius = 1.52
	tor.rings = 24
	tor.ring_segments = 6
	anel.mesh = tor
	anel.scale = Vector3(1.0, 0.25, 1.0)
	var m := Fx.unshaded(Color(1.0, 0.82, 0.36, 0.85), true)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	anel.material_override = m
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_destaque.add_child(anel)


## Obra do pavilhão: o modelo de verdade sobe do chão por fração de madeira
## (base, colunas, telhado) no lugar do fantasma.
func _comecar_pavilhao() -> void:
	if _pav_fantasma:
		_pav_fantasma.visible = false
	if _destaque:
		_destaque.visible = false
	_pav_obra = Node3D.new()
	_pav_obra.position = TAPETES[maxi(caminho, 0)]
	_pav_obra.scale.y = 0.06
	add_child(_pav_obra)
	var arq := _cena_pavilhao()
	if ResourceLoader.exists(arq):
		var pav: Node3D = (load(arq) as PackedScene).instantiate()
		_pav_obra.add_child(pav)
		HatPad.so_do_time(pav, team)
		for n in pav.find_children("Estoque_*", "Node3D", true, false):
			n.visible = false
		MalhaUnica.juntar(pav, MalhaUnica.animados(pav))
	_crescer_pavilhao()


func _crescer_pavilhao() -> void:
	if _pav_obra == null:
		return
	var f := float(madeira_nivel) / maxf(custo_nivel(), 1.0)
	var tw := _pav_obra.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_pav_obra, "scale:y", maxf(f, 0.06), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Fim da obra -----------------------------------------------------------------

func _finish(anim := true) -> void:
	estado = Estado.PRONTA
	nivel = 3
	madeira_nivel = 0
	pad = HatPad.new()
	_game.add_child(pad)
	pad.setup(team, opcao(), global_position + CASA)
	pad.raio_pegar = 2.7
	pad.altura_letreiro(5.6)
	# A casa nasce no Nv3: um degrau acima do 2 (estoque e ritmo).
	pad.estoque_max += 1
	pad.estoque = pad.estoque_max
	pad.intervalo *= Config.cfg.mago_pad_intervalo_mult
	pad.mostrar_nivel(3)
	_game.hat_pads.append(pad)
	if anim and _obra and is_inside_tree():
		# O telhado cai, a poeira sobe e a casa de verdade toma o lugar da obra.
		pad.visible = false
		var obra := _obra
		var tw := obra.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		if _telhado:
			_telhado.visible = true
			_telhado.position.y += 4.0
			tw.tween_property(_telhado, "position:y", _telhado.position.y - 4.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			Fx.burst(_game, global_position + CASA + Vector3(0, 2.2, 0), Color(0.75, 0.65, 0.5), 16, 5.0)
			if is_instance_valid(pad):
				pad.visible = true
			obra.queue_free())
		Fx.pillar(_game, global_position + CASA, Config.team_color(team).lightened(0.3), 3.0)
		Sfx.play("score", global_position, 0.05)
	elif _obra:
		_obra.queue_free()
	_obra = null
	_telhado = null
	if pad_base:
		pad_base.subir_nivel()  # garante o Nv2 (modo antigo/testes)
		_degrau_pad(pad_base)
	_update_label()
	_game.on_oficina_pronta(self)


## Modo teste: a casa fica pronta na hora, no caminho i, sem obra nem madeira.
func concluir_ja(i := 0) -> void:
	if estado == Estado.PRONTA:
		return
	if nivel < 2:
		nivel = 2
		madeira_nivel = 0
		if pad_base:
			pad_base.subir_nivel()
	if caminho < 0:
		escolher(i, true)
	madeira_entregue = custo()
	progresso = 1.0
	_finish(false)


# --- Visual ------------------------------------------------------------------------

## Chão pintado do bairro, tapetes, selos e estandarte (bairro_<classe>.scn do
## tema). Sem o modelo (tema antigo): um disco de terra simples.
func _montar_bairro() -> void:
	var th: ThemeConfig = _game.arena.theme if _game and _game.arena else Config.theme()
	var arq := th.model_path("bairro_%s.scn" % base.resource_path.get_file().get_basename())
	if not ResourceLoader.exists(arq):
		var chao := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = RAIO - 0.2
		c.bottom_radius = RAIO
		c.height = 0.05
		c.radial_segments = 10
		chao.mesh = c
		chao.position.y = 0.025
		chao.material_override = Fx.lit(base.hat_color.darkened(0.55).lerp(Color(0.42, 0.33, 0.24), 0.5))
		add_child(chao)
		return
	_bairro = (load(arq) as PackedScene).instantiate()
	add_child(_bairro)
	var fora: Array = []
	for i in 2:
		_selos[i] = _bairro.find_child("Selo_%d" % i, true, false) as Node3D
		if _selos[i]:
			_selos[i].visible = false
			fora.append(_selos[i])
	for k in ["azul", "vermelho", "c0", "c1"]:
		var p := _bairro.find_child("Pano_%s" % k, true, false) as Node3D
		if p:
			_panos[k] = p
			fora.append(p)
	_emblema_bandeira = _bairro.find_child("Emblema_bandeira", true, false) as Node3D
	if _emblema_bandeira:
		fora.append(_emblema_bandeira)
	for i in mini(caminhos().size(), 2):
		var mk := _bairro.find_child("Emblema_%d" % i, true, false) as Node3D
		var em := th.model_path("emblema_%s.scn" % caminhos()[i].resource_path.get_file().get_basename())
		if mk and ResourceLoader.exists(em):
			var e3: Node3D = (load(em) as PackedScene).instantiate()
			e3.rotation_degrees.x = -12.0
			mk.add_child(e3)
	_pintar_estandarte()
	var chao := MalhaUnica.juntar(_bairro, fora)
	# Desempenho: o bairro é quase todo chão (areia, pedras, tatame) e o pano é
	# fino; a sombra deles quase não se vê mas custava 1 passe a mais em cada
	# superfície (~7 chamadas por bairro, 16 bairros). Postes e casa mantêm a dela.
	if chao:
		chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for p in _panos.values():
		_sem_sombra(p)


## Estandarte: pano na cor do time com o emblema da classe base; com o caminho
## escolhido, pano e emblema passam para os do caminho.
func _pintar_estandarte() -> void:
	if _panos.is_empty():
		return
	var chave: String = ("c%d" % caminho) if caminho >= 0 else ("azul" if team == Config.TEAM_BLUE else "vermelho")
	if not _panos.has(chave):
		chave = "azul" if team == Config.TEAM_BLUE else "vermelho"
	for k in _panos:
		(_panos[k] as Node3D).visible = k == chave
	if _emblema_bandeira:
		for c in _emblema_bandeira.get_children():
			c.queue_free()
		var cls := opcao() if caminho >= 0 else base
		var th: ThemeConfig = _game.arena.theme if _game and _game.arena else Config.theme()
		var em := th.model_path("emblema_%s.scn" % cls.resource_path.get_file().get_basename())
		if ResourceLoader.exists(em):
			var e3: Node3D = (load(em) as PackedScene).instantiate()
			_emblema_bandeira.add_child(e3)
			_sem_sombra(e3)


static func _sem_sombra(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_sem_sombra(c)


func _selar_tapete(i: int) -> void:
	if i < 0 or i >= _fantasmas.size():
		return
	if _selos[i]:
		_selos[i].visible = true
		if is_inside_tree():
			_selos[i].scale = Vector3(1.0, 0.1, 1.0)
			_selos[i].create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).tween_property(_selos[i], "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var f := _fantasmas[i]
	if f and f.visible and is_inside_tree():
		# O fantasma do caminho selado se apaga e afunda no tapete.
		var mat := f.material_override as ShaderMaterial
		var tw := f.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
		tw.tween_method(func(a: float): mat.set_shader_parameter("alfa", a), 0.5, 0.0, 0.6)
		tw.tween_property(f, "position:y", -0.6, 0.6)
		tw.chain().tween_callback(func(): f.visible = false)
		Fx.burst(_game, tapete_pos(i) + Vector3(0, 0.8, 0), Color(0.5, 0.45, 0.6), 12, 3.0)
	elif f:
		f.visible = false
	# O fantasma escolhido também some: a obra de verdade sobe no lugar da casa.
	var j := 1 - i
	if j < _fantasmas.size() and _fantasmas[j]:
		var g := _fantasmas[j]
		if is_inside_tree() and g.visible:
			var tw2 := g.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
			tw2.tween_property(g, "position", CASA + Vector3(0, 1.0, 0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw2.tween_property(g, "scale", Vector3.ONE * 0.9, 0.45)
			tw2.chain().tween_callback(func(): g.visible = false)
		else:
			g.visible = false


## Fantasma da casa do caminho i, pairando sobre o tapete: a malha da casa
## inteira numa superfície só (1 chamada), com o shader translúcido.
func _montar_fantasma(i: int) -> MeshInstance3D:
	var cls: ClassStats = caminhos()[i]
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_fantasma(_cena_casa(cls))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_FANTASMA
	mat.set_shader_parameter("cor", cls.hat_color.lightened(0.15))
	mat.set_shader_parameter("alfa", 0.62)
	mat.set_shader_parameter("altura", 5.0)
	mi.material_override = mat
	mi.position = TAPETES[i] + Vector3(0, 0.2, -0.15)
	mi.scale = Vector3.ONE * FANTASMA_ESC
	add_child(mi)
	return mi


func _cena_casa(cls: ClassStats) -> String:
	var th: ThemeConfig = _game.arena.theme if _game and _game.arena else Config.theme()
	return th.model_path("maquina_%s.scn" % cls.resource_path.get_file().get_basename())


static func _malha_fantasma(arq: String) -> Mesh:
	if _malhas_fantasma.has(arq):
		return _malhas_fantasma[arq]
	var mesh: Mesh
	if ResourceLoader.exists(arq):
		var raiz: Node3D = (load(arq) as PackedScene).instantiate()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var algum := false
		for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh == null or not mi.visible or _nivelado(mi.name) \
					or _dentro_de(mi, raiz, ["N3_", "N4_", "N5_", "Estoque", "Molde"]):
				continue
			var xf := _relativa(mi, raiz)
			for s in mi.mesh.get_surface_count():
				st.append_from(mi.mesh, s, xf)
				algum = true
		raiz.free()
		if algum:
			mesh = st.commit()
	if mesh == null:
		var b := BoxMesh.new()
		b.size = Vector3(3.0, 3.6, 3.0)
		mesh = b
	_malhas_fantasma[arq] = mesh
	return mesh


static func _nivelado(nome: String) -> bool:
	return nome.begins_with("N3_") or nome.begins_with("N4_") or nome.begins_with("N5_")


static func _dentro_de(n: Node, raiz: Node, prefixos: Array) -> bool:
	var p := n.get_parent()
	while p and p != raiz:
		for pre in prefixos:
			if String(p.name).begins_with(pre):
				return true
		p = p.get_parent()
	return false


static func _relativa(n: Node3D, raiz: Node3D) -> Transform3D:
	var t := n.transform
	var p := n.get_parent()
	while p and p != raiz:
		if p is Node3D:
			t = (p as Node3D).transform * t
		p = p.get_parent()
	return t


## Obra: a casa do caminho cresce do chão (escala em y), sem as peças dos
## níveis 4/5; o "Telhado" fica escondido e cai no fim.
func _comecar_obra() -> void:
	var arq := _cena_casa(opcao())
	_obra = Node3D.new()
	_obra.position = CASA
	_obra.scale.y = 0.04
	add_child(_obra)
	if not ResourceLoader.exists(arq):
		return
	var casa: Node3D = (load(arq) as PackedScene).instantiate()
	_obra.add_child(casa)
	for padrao in ["N2_*", "N3_*", "N4_*", "N5_*", "Estoque_*"]:
		for n in casa.find_children(padrao, "Node3D", true, false):
			n.visible = false
	_telhado = casa.find_child("Telhado", true, false) as Node3D
	if _telhado:
		_telhado.visible = false
	var fora := MalhaUnica.animados(casa)
	if _telhado:
		fora.append(_telhado)
	for padrao in ["N2_*", "N3_*", "N4_*", "N5_*", "Estoque_*"]:
		fora.append_array(casa.find_children(padrao, "Node3D", true, false))
	MalhaUnica.juntar(casa, fora)


func _process(delta: float) -> void:
	if estado == Estado.PRONTA:
		_t += delta
		_visual_heroi()
		return
	if estado != Estado.VAZIO:
		return
	_t += delta
	# Fantasmas pairando e balançando devagar; o tapete pisado cresce e brilha.
	for i in _fantasmas.size():
		var f := _fantasmas[i]
		if not f.visible:
			continue
		var pisado: float = clampf(_tapete_t[i] / ESCOLHA_T, 0.0, 1.0)
		f.position.y = 0.2 + 0.08 * sin(_t * 1.6 + i * 2.0) + 0.25 * pisado
		f.rotation.y = 0.18 * sin(_t * 0.7 + i)
		f.scale = Vector3.ONE * FANTASMA_ESC * (1.0 + 0.25 * pisado)
		(f.material_override as ShaderMaterial).set_shader_parameter("alfa", 0.62 + 0.3 * pisado)


## Nv5 com herói: fantasma do pavilhão pairando; com madeira, anel dourado
## pulsando e o fantasma acende (o quintal avisa que dá para subir).
func _visual_heroi() -> void:
	if not pede_heroi():
		if _pav_fantasma and _pav_fantasma.visible and heroi >= 0:
			_pav_fantasma.visible = false
		return
	if _pav_fantasma == null:
		_montar_pav_fantasma()
		if _pav_fantasma == null:
			return
	var luz := destaque_heroi()
	_pav_fantasma.visible = true
	var pisado: float = clampf(_heroi_t / ESCOLHA_T, 0.0, 1.0)
	_pav_fantasma.position.y = 0.15 + 0.07 * sin(_t * 1.5) + 0.2 * pisado
	var a := (0.5 + 0.3 * (0.5 + 0.5 * sin(_t * 4.0))) if luz else 0.32
	(_pav_fantasma.material_override as ShaderMaterial).set_shader_parameter("alfa", a + 0.2 * pisado)
	_destaque.visible = luz
	if luz:
		var k := 1.0 + 0.12 * sin(_t * 4.0)
		_destaque.scale = Vector3(k, 1.0, k)
		if not _destaque_avisado:
			_destaque_avisado = true
			_game.on_heroi_disponivel(self)


func _update_label() -> void:
	var txt := ""
	var cs := caminhos()
	match estado:
		Estado.VAZIO:
			if cs.size() >= 2:
				if nivel < 2:
					txt = "%s  Nv1\nNv2 libera o Super  ·  Nv3: %s ou %s" % [base.display_name, cs[0].display_name, cs[1].display_name]
				else:
					txt = "%s  Nv2\nEscolha: %s  ou  %s" % [base.display_name, cs[0].display_name, cs[1].display_name]
		Estado.OBRA:
			txt = "Obra: %s  %d%%" % [opcao().display_name, int(progresso * 100.0)]
		Estado.PRONTA:
			if pede_heroi():
				txt = "★ Herói raro  Nv6\n%s" % "  ou  ".join(herois().map(func(c): return c.display_name))
			elif heroi >= 0 and not heroi_pronto:
				txt = "Pavilhão: %s  %d%%" % [heroi_cls().display_name, int(100.0 * madeira_nivel / maxf(custo_nivel(), 1.0))]
	if txt != _texto:
		_texto = txt
		_label.text = txt
		_label.visible = txt != ""
	_label.modulate = (opcao().hat_color if estado == Estado.OBRA else base.hat_color).lightened(0.35)
	if estado == Estado.OBRA:
		_label.position.y = lerpf(3.0, 4.8, progresso)
	elif estado == Estado.PRONTA and txt != "":
		_label.modulate = Estilo.OURO_CLARO
		_label.position = TAPETES[maxi(caminho, 0)] + Vector3(0, 4.6, 0)
	# Contador de madeira: na obra e nos níveis (com madeira posta ou com o
	# jogador Construtor perto); grande para quem joga de Construtor.
	var p := _game.player
	var construtor := p != null and p.team == team and p.lenhador()
	var perto := construtor and p.global_position.distance_to(global_position) < BUILD_RADIUS + 2.0
	if estado == Estado.OBRA:
		_contador.visible = true
		_contador.position = CASA
		_contador.position.y = _label.position.y + (1.0 if construtor else 0.7)
		_contador.mostrar(faltam(), custo(), construtor, falta_madeira or (faltam() > 0 and _game.madeira[team] <= 0), progresso)
	elif pode_subir() and (madeira_nivel > 0 or perto):
		_contador.visible = true
		_contador.position = BARRACA + Vector3(0, 4.6, 0) if estado == Estado.VAZIO else CASA + Vector3(0, 6.6, 0)
		if heroi >= 0:
			_contador.position = TAPETES[maxi(caminho, 0)] + Vector3(0, 5.4, 0)
		_contador.mostrar(faltam_nivel(), custo_nivel(), construtor, falta_madeira)
	else:
		_contador.visible = false
