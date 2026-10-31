class_name HatPad
extends Node3D
## Maquininha de chapéu no castelo (Ciclo 2.3). Pegar o chapéu troca a classe
## da unidade e tira 1 do estoque. A máquina fabrica 1 chapéu a cada
## `maquina_intervalo` s enquanto o estoque está abaixo de `maquina_estoque_max`,
## e começa cheia. Estoque zero = "acabou o seu favorito": joga de outra coisa.
##
## Modelo do tema (ThemeConfig.maquina_model): a engrenagem gira sozinha, a
## animação "fabricar" toca quando um chapéu fica pronto, ele salta do "Molde"
## e vai para a prateleira "Estoque_N". Sem modelo: pedestal com chapéu flutuando.
##
## Nível 2 (quiz do Ciclo 2.4, pergunta 6): quando o time ergue uma oficina cuja
## `classe_base` é esta classe, a máquina sobe de nível: fabrica a cada
## `maquina_n2_intervalo` s até `maquina_n2_estoque`. Modelo: os nós "N2_*"
## ficam escondidos no nível 1 e aparecem no 2; toca "subir_nivel" se existir.
## Também sobe com madeira: Construtores do time parados a OBRA_RAIO m puxam 1
## madeira do estoque a cada oficina_puxar_intervalo / Σv s até maquina_n2_custo.

var team := 0
var stats: ClassStats
var available := true
var estoque := 0
var estoque_max := 3
var intervalo := 20.0
var nivel := 1
## Madeira já posta no nível 2 (fica guardada, como a obra das oficinas).
var madeira_n2 := 0

const OBRA_RAIO := 2.8

var _hat: Node3D          # sem modelo: o chapéu que flutua no pedestal
var _fab_t := 0.0
var _t := randf() * TAU
var _label: Label3D
# Com modelo do tema:
var _maquina: Node3D
var _anim: AnimationPlayer
var _molde: Node3D
var _slots: Array[Node3D] = []      # Estoque_1..N
var _chapeus: Array[Node3D] = []    # um por chapéu em estoque, na ordem dos slots
var _n2: Array[Node3D] = []         # nós "N2_*" do modelo (aparecem no nível 2)
var _puxar_t := 0.0
var _contador: ContadorMadeira


func setup(p_team: int, p_stats: ClassStats, pos: Vector3) -> void:
	team = p_team
	stats = p_stats
	position = pos
	estoque_max = Config.cfg.maquina_estoque_max
	intervalo = Config.cfg.maquina_intervalo
	estoque = estoque_max
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # chapéu animado em _process
	var th: ThemeConfig = Config.theme()
	# Máquina própria da classe (maquina_<arquivo da classe>.scn na pasta do
	# tema), senão a genérica do tema.
	var propria := th.model_path("maquina_%s.scn" % stats.resource_path.get_file().get_basename())
	var cena: PackedScene = load(propria) if ResourceLoader.exists(propria) else th.maquina_model
	if cena:
		_montar_maquina(th, cena)
	else:
		var base := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.0
		cyl.bottom_radius = 1.2
		cyl.height = 0.5
		base.mesh = cyl
		base.material_override = Fx.lit(Color(0.55, 0.55, 0.6))
		base.position.y = 0.25
		add_child(base)
		_hat = make_hat(stats.hat_style, stats.hat_color)
		_hat.position.y = 1.2
		add_child(_hat)
	_label = Label3D.new()
	_label.font = Estilo.LETREIRO
	_label.font_size = 40
	_label.pixel_size = 0.011
	_label.line_spacing = -6
	_label.outline_size = 10
	_label.outline_modulate = Estilo.TINTA
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 3.4 if _maquina else 2.6
	_label.modulate = stats.hat_color.lightened(0.3)
	add_child(_label)
	_contador = ContadorMadeira.new()
	_contador.position.y = _label.position.y + 0.9
	add_child(_contador)
	_contador.visible = false
	_atualizar()


## Maquininha do tema: emblema da classe no "Enfeite" e um chapéu em cada
## "Estoque_N" (o estoque fica à vista). Tudo de frente para +z (a câmera).
func _montar_maquina(th: ThemeConfig, cena: PackedScene) -> void:
	_maquina = cena.instantiate()
	add_child(_maquina)
	_anim = _maquina.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_molde = _maquina.find_child("Molde", true, false) as Node3D
	for i in range(1, 9):
		var n := _maquina.find_child("Estoque_%d" % i, true, false) as Node3D
		if n == null:
			break
		_slots.append(n)
	for n in _maquina.find_children("N2_*", "Node3D", true, false):
		n.visible = false
		_n2.append(n)
	var enfeite := _maquina.find_child("Enfeite", true, false) as Node3D
	var emblema := th.model_path("emblema_%s.scn" % stats.resource_path.get_file().get_basename())
	if enfeite and ResourceLoader.exists(emblema):
		enfeite.add_child((load(emblema) as PackedScene).instantiate())
	for i in estoque:
		_chapeus.append(_novo_chapeu(_slot(i), 0.62))


func _slot(i: int) -> Node3D:
	if _slots.is_empty():
		return _molde if _molde else _maquina
	return _slots[mini(i, _slots.size() - 1)]


func _novo_chapeu(pai: Node3D, esc: float) -> Node3D:
	var h := make_hat(stats.hat_style, stats.hat_color)
	h.scale = Vector3.ONE * esc
	pai.add_child(h)
	return h


func _process(delta: float) -> void:
	_t += delta
	if _hat:
		_hat.rotation.y += delta * 1.8
		_hat.position.y = 1.2 + sin(_t * 2.5) * 0.15


func _physics_process(delta: float) -> void:
	avancar(delta)
	if nivel == 1:
		_obra_n2(delta)


func faltam_n2() -> int:
	return maxi(Config.cfg.maquina_n2_custo - madeira_n2, 0) if nivel == 1 else 0


## Puxa 1 madeira do estoque do time para o nível 2; completa = sobe.
func puxar_madeira_n2(game: Game) -> bool:
	if nivel >= 2 or faltam_n2() <= 0 or not game.gastar_madeira(team, 1):
		return false
	madeira_n2 += 1
	if is_inside_tree():
		Fx.burst(game, global_position + Vector3(0, 1.0, 0), Color(0.7, 0.5, 0.25), 5, 2.5)
		Sfx.play("swing", global_position, 0.3)
	if faltam_n2() <= 0:
		subir_nivel()
	return true


## Construtores do time em volta da máquina: puxam madeira para o nível 2.
## O contador aparece com madeira já posta ou com o jogador Construtor perto.
func _obra_n2(delta: float) -> void:
	var game := get_parent() as Game
	if game == null or game.game_over:
		return
	var rate := 0.0
	for u in game.units:
		if u.alive and u.team == team and u.stats.velocidade_obra > 0.0 and not u.carried_princess \
				and not u.carried_tora and u.global_position.distance_to(global_position) < OBRA_RAIO:
			rate += u.stats.velocidade_obra
			u.building_t = 0.25
	if rate > 0.0:
		_puxar_t -= delta * rate
		if _puxar_t <= 0.0 and puxar_madeira_n2(game):
			_puxar_t = Config.cfg.oficina_puxar_intervalo
	var p := game.player
	var perto := p != null and p.team == team and p.lenhador() and p.global_position.distance_to(global_position) < OBRA_RAIO + 1.2
	_contador.visible = nivel == 1 and (madeira_n2 > 0 or perto)
	if _contador.visible:
		_contador.mostrar(faltam_n2(), Config.cfg.maquina_n2_custo, perto, faltam_n2() > 0 and game.madeira[team] <= 0)


## Relógio da fábrica (separado do _physics_process para os testes).
func avancar(delta: float) -> void:
	if estoque >= estoque_max:
		_fab_t = 0.0
		return
	_fab_t += delta
	if _fab_t >= intervalo:
		_fab_t -= intervalo
		estoque += 1
		_fabricou()
	_atualizar()


## Prensa desce, o chapéu salta do molde (0,8 a 1,2 s) e vai para a prateleira.
func _fabricou() -> void:
	if _maquina:
		if _anim and _anim.has_animation("fabricar"):
			_anim.stop()
			_anim.play("fabricar")
		var h := _novo_chapeu(_molde if _molde else _slot(estoque - 1), 0.85)
		h.visible = false
		_chapeus.append(h)
		var tw := h.create_tween()  # morre junto com o chapéu se ele for pego antes
		tw.tween_interval(0.8)
		tw.tween_callback(func(): h.visible = true)
		tw.tween_property(h, "position:y", 0.5, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.4)
		tw.tween_callback(func():
			if not _chapeus.has(h):
				return
			var alvo := _slot(_chapeus.find(h))
			h.reparent(alvo, true)
			var t2 := h.create_tween().set_parallel()
			t2.tween_property(h, "position", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
			t2.tween_property(h, "scale", Vector3.ONE * 0.62, 0.3))
	elif estoque == 1:
		_hat.visible = true
		_hat.scale = Vector3.ONE * 0.01
		create_tween().tween_property(_hat, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_inside_tree():
		Fx.burst(get_parent(), global_position + Vector3(0, 1.4, 0), Color(0.95, 0.95, 0.9), 6, 2.5)


## Sobe para o nível 2 (uma vez). Ganha 1 chapéu na hora, de presente.
func subir_nivel() -> bool:
	if nivel >= 2:
		return false
	nivel = 2
	if _contador:
		_contador.visible = false
	estoque_max = Config.cfg.maquina_n2_estoque
	intervalo = Config.cfg.maquina_n2_intervalo
	_fab_t = 0.0
	for n in _n2:
		n.visible = true
	if estoque < estoque_max:
		estoque += 1
		_fabricou()
	if _anim and _anim.has_animation("subir_nivel"):
		_anim.play("subir_nivel")
	if is_inside_tree():
		Fx.pillar(get_parent(), global_position, Color(1.0, 0.82, 0.36), 2.5)
		Fx.burst(get_parent(), global_position + Vector3(0, 1.6, 0), Color(1.0, 0.82, 0.36), 14, 4.5)
		Sfx.play("score", global_position, 0.1)
		# Sem peças "N2_*" no modelo: um pulinho mostra que mudou.
		var alvo: Node3D = _maquina if _maquina else self
		alvo.scale = Vector3(1.25, 0.75, 1.25)
		alvo.create_tween().tween_property(alvo, "scale", Vector3.ONE * (1.0 if _n2.size() > 0 or alvo == self else 1.08), 0.5) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_atualizar()
	return true


func _atualizar() -> void:
	available = estoque > 0
	if _hat:
		_hat.visible = available
	# Nome em cima, contagem embaixo: as maquininhas vizinhas ficam a ~4,5 m e
	# o letreiro numa linha só invadia o da lado.
	var txt := "%s%s\n%d/%d" % [stats.display_name, " Nv2" if nivel >= 2 else "", estoque, estoque_max]
	if estoque < estoque_max:
		txt += "  · %ds" % ceili(intervalo - _fab_t)
	if _label.text != txt:
		_label.text = txt
	_label.modulate = stats.hat_color.lightened(0.3) if available else Color(0.7, 0.7, 0.7, 0.8)


## Posição do chapéu no mundo (de onde ele "sai" ao ser pego).
func hat_world_position() -> Vector3:
	if not _chapeus.is_empty():
		return _chapeus.back().global_position
	return _hat.global_position if _hat else global_position + Vector3(0, 1.5, 0)


func take() -> ClassStats:
	estoque = maxi(estoque - 1, 0)
	if not _chapeus.is_empty():
		_chapeus.pop_back().queue_free()
	_atualizar()
	return stats


## Chapéus montados com formas simples: elmo, capuz, kasa e chapéu pontudo.
static func make_hat(style: String, color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := Fx.lit(color, 0.4)
	match style:
		"elmo":
			mat.metallic = 0.7
			var dome := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 0.7
			sp.is_hemisphere = true
			dome.mesh = sp
			dome.material_override = mat
			root.add_child(dome)
			var plume := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.05
			pc.bottom_radius = 0.12
			pc.height = 0.5
			plume.mesh = pc
			plume.material_override = Fx.lit(Color(0.9, 0.15, 0.15))
			plume.position = Vector3(0, 0.55, -0.1)
			plume.rotation_degrees.x = -25
			root.add_child(plume)
		"kasa":
			# Chapéu de palha cônico (kasa), largo e baixo.
			var kasa := MeshInstance3D.new()
			var k := CylinderMesh.new()
			k.top_radius = 0.05
			k.bottom_radius = 0.8
			k.height = 0.4
			k.radial_segments = 12
			kasa.mesh = k
			kasa.material_override = mat
			root.add_child(kasa)
			var knot := MeshInstance3D.new()
			var kn := SphereMesh.new()
			kn.radius = 0.09
			kn.height = 0.18
			knot.mesh = kn
			knot.material_override = Fx.lit(Color(0.55, 0.3, 0.15))
			knot.position.y = 0.22
			root.add_child(knot)
		"kabuto":
			_add(root, _sph(0.5, 0.35), Vector3.ZERO, Vector3.ZERO, mat)
			_add(root, _cyl(0.62, 0.66, 0.06), Vector3(0, -0.05, 0), Vector3.ZERO, Fx.lit(Color(0.08, 0.08, 0.12)))
			for s in [-1, 1]:
				_add(root, _cyl(0.0, 0.08, 0.55), Vector3(0.22 * s, 0.4, 0.2), Vector3(-25, 0, -35 * s), Fx.unshaded(Color(1, 0.8, 0.3)))
		"faixa", "hachimaki":
			_add(root, _cyl(0.45, 0.45, 0.12), Vector3.ZERO, Vector3.ZERO, Fx.unshaded(color) if style == "faixa" else mat)
			for s in [-1, 1]:
				_add(root, BoxMesh.new(), Vector3(0.12 * s, -0.2, -0.5), Vector3(55, 0, 15 * s), mat, Vector3(0.08, 0.5, 0.03))
		"mascara_oni":
			_add(root, _sph(0.42, 0.36), Vector3.ZERO, Vector3.ZERO, Fx.lit(Color(0.6, 0.06, 0.08)), Vector3(1, 1, 0.7))
			for s in [-1, 1]:
				_add(root, _cyl(0.0, 0.09, 0.45), Vector3(0.25 * s, 0.4, 0), Vector3(0, 0, -25 * s), Fx.lit(Color(0.92, 0.88, 0.75)))
				_add(root, _sph(0.06, 0.05), Vector3(0.14 * s, 0.08, 0.28), Vector3.ZERO, Fx.unshaded(Color(1, 0.8, 0.3)))
		"eboshi":
			_add(root, _cyl(0.24, 0.36, 0.8), Vector3(0, 0.2, 0), Vector3(-12, 0, 0), Fx.lit(Color(0.05, 0.05, 0.08)), Vector3(1, 1, 0.7))
			for i in 3:
				var a := TAU * i / 3.0
				_add(root, BoxMesh.new(), Vector3(cos(a) * 0.6, 0.1, sin(a) * 0.6), Vector3(0, -rad_to_deg(a) + 90, 0), Fx.unshaded(Color(0.9, 0.95, 1.0)), Vector3(0.14, 0.3, 0.01))
		"orelhas":
			var white := Fx.lit(Color(0.95, 0.94, 0.9))
			_add(root, _sph(0.4, 0.34), Vector3.ZERO, Vector3.ZERO, white, Vector3(1, 1, 0.75))
			_add(root, _cyl(0.0, 0.14, 0.3), Vector3(0, -0.1, 0.32), Vector3(90, 0, 0), white)
			for s in [-1, 1]:
				_add(root, _cyl(0.0, 0.13, 0.35), Vector3(0.26 * s, 0.4, 0), Vector3(0, 0, -15 * s), white)
				_add(root, BoxMesh.new(), Vector3(0.15 * s, 0.1, 0.31), Vector3(0, 0, -20 * s), Fx.unshaded(Color(1, 0.15, 0.2)), Vector3(0.16, 0.04, 0.02))
			_add(root, _sph(0.12, 0.14), Vector3(0.6, 0.2, 0), Vector3.ZERO, Fx.unshaded(color))
		"cesto":
			_add(root, _cyl(0.42, 0.3, 0.6), Vector3.ZERO, Vector3.ZERO, Fx.lit(Color(0.6, 0.45, 0.22)))
			for i in 5:
				var a := TAU * i / 5.0
				_add(root, _cyl(0.0, 0.06, 0.4), Vector3(cos(a) * 0.2, 0.45, sin(a) * 0.2), Vector3(sin(a) * 25, 0, -cos(a) * 25), Fx.lit(Color(0.6, 0.65, 0.75)))
		"barril":
			_add(root, _cyl(0.38, 0.38, 0.75), Vector3.ZERO, Vector3.ZERO, Fx.lit(Color(0.42, 0.26, 0.13)))
			for y in [-0.25, 0.25]:
				_add(root, _cyl(0.4, 0.4, 0.06), Vector3(0, y, 0), Vector3.ZERO, Fx.lit(Color(0.15, 0.15, 0.18)))
			_add(root, _sph(0.08, 0.08), Vector3(0.05, 0.55, 0), Vector3.ZERO, Fx.unshaded(Color(1, 0.5, 0.1)))
		"capuz":
			var hood := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.55
			cone.height = 0.7
			hood.mesh = cone
			hood.material_override = mat
			hood.rotation_degrees.x = -20
			root.add_child(hood)
			var feather := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.06, 0.6, 0.15)
			feather.mesh = box
			feather.material_override = Fx.lit(Color(0.95, 0.85, 0.3))
			feather.position = Vector3(0.35, 0.25, 0)
			feather.rotation_degrees.z = -30
			root.add_child(feather)
		_:
			var brim := MeshInstance3D.new()
			var b := CylinderMesh.new()
			b.top_radius = 0.75
			b.bottom_radius = 0.75
			b.height = 0.06
			brim.mesh = b
			brim.material_override = mat
			root.add_child(brim)
			var top := MeshInstance3D.new()
			var t := CylinderMesh.new()
			t.top_radius = 0.0
			t.bottom_radius = 0.42
			t.height = 1.0
			top.mesh = t
			top.material_override = mat
			top.position.y = 0.5
			root.add_child(top)
			var band := MeshInstance3D.new()
			var bd := CylinderMesh.new()
			bd.top_radius = 0.4
			bd.bottom_radius = 0.43
			bd.height = 0.12
			band.mesh = bd
			band.material_override = Fx.lit(Color(1.0, 0.8, 0.25), 0.3)
			band.position.y = 0.1
			root.add_child(band)
	return root


static func _add(root: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3, mat: Material, esc := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = esc
	root.add_child(mi)


static func _sph(r: float, h: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m


static func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 12
	m.rings = 1
	return m
