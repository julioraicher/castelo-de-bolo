class_name Trap
extends Node3D
## Armadilhas do Construtor:
##   estrepes (Construtor, botão direito): o primeiro inimigo que pisa leva dano
##     e fica lento.
##   mina (Armadilheiro: botão direito e o campo minado do R): explode em área e
##     empurra (sem lentidão).
## Visual em FxItens (Ciclo 2.32): estrepes = makibishi de ferro numa tabuinha de
## bambu com a estaca e a fita do time; mina = panela de pólvora de barro com a
## corda do time e a brasa do estopim pulsando. Cai quicando quando é posta,
## dispara com peças próprias e, se vencer, afunda no chão (sumir).

const RADIUS := 1.4
const LIFETIME := 40.0

var owner_unit: Unit
var _game: Game
var _life := LIFETIME
var _mina := false
var _vis: Node3D
var _brasa: MeshInstance3D
var _blink_t := 0.0


func setup(game: Game, p_owner: Unit, pos: Vector3) -> void:
	_game = game
	owner_unit = p_owner
	add_to_group("traps")
	global_position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # parada; só aparece com tween
	_mina = p_owner.stats.trap_kind == "mina"
	var cor := Config.team_color(p_owner.team)
	_vis = Node3D.new()
	_vis.name = "Visual"
	_vis.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_vis)
	var mi := MeshInstance3D.new()
	mi.mesh = FxItens.malha_mina(cor) if _mina else FxItens.malha_estrepes(cor, randi() % 3)
	mi.material_override = FxItens.mat_objeto(game)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vis.add_child(mi)
	if _mina:
		_brasa = FxItens.brasa(_vis)
	_vis.rotation.y = randf() * TAU
	# Anel tracejado na cor do time: aliados enxergam onde está.
	FxItens.anel_chao(_vis, Magia.paleta_de(cor), RADIUS, {"voltas": 10.0, "forca": 1.0, "banda": 0.06, "alfa": 0.5, "gira": 0.02, "y": 0.04})
	# Jogada no chão: cai quicando (a mina balança antes de assentar).
	_vis.position.y = 0.7
	var tw := _vis.create_tween()
	tw.tween_property(_vis, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if _mina:
		tw.tween_property(_vis, "rotation:z", 0.12, 0.08)
		tw.tween_property(_vis, "rotation:z", -0.07, 0.1)
		tw.tween_property(_vis, "rotation:z", 0.0, 0.12)
	FxItens.armadilha_arma(game, pos, _mina)


func _process(delta: float) -> void:
	if _brasa:
		_blink_t += delta
		# Brasa do estopim: acende devagar e apaga (o mesmo ritmo do pisca antigo).
		var k := 0.5 + 0.5 * sin(_blink_t * TAU / 0.8)
		_brasa.scale = Vector3.ONE * lerpf(0.022, 0.05, k * k)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		sumir()
		return
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 1.5:
			continue
		d.y = 0
		if d.length() <= RADIUS:
			var s := owner_unit.stats
			if _mina:
				_explode()
				queue_free()
				return
			var dir := d.normalized() if d.length() > 0.1 else Vector3.FORWARD
			u.take_damage(s.trap_damage, owner_unit, dir, 0.3)
			u.apply_slow(s.trap_slow, s.trap_slow_time)
			FxItens.estrepes_fisga(_game, global_position, dir)
			queue_free()
			return


## Some sem disparar (venceu o tempo ou foi trocada pela nova): a regra tira
## na hora; o visual se solta e afunda no chão.
func sumir() -> void:
	if is_queued_for_deletion():
		return
	remove_from_group("traps")
	if _vis and is_instance_valid(_game):
		var t := _vis.global_transform
		remove_child(_vis)
		_game.add_child(_vis)
		_vis.global_transform = t
		FxItens.armadilha_some(_game, _vis, _mina)
	queue_free()


func _explode() -> void:
	var r := RADIUS * 1.6
	FxProjetil.explosao(_game, global_position, r)
	FxProjetil.anel_chao(_game, global_position, Color(1.0, 0.55, 0.15, 0.8), r)
	FxItens.mina_estoura(_game, global_position)
	Reacoes.em(_game, global_position, r, "bomba", owner_unit.team)
	Sfx.play("explosao", global_position, 0.1, 1.1)
	_game.camera.shake_at(global_position, 0.5)
	for u in _game.units:
		if not u.alive or u.team == owner_unit.team:
			continue
		var d := u.global_position - global_position
		if absf(d.y) > 1.5:
			continue
		d.y = 0
		if d.length() <= r:
			u.take_damage(owner_unit.stats.trap_damage, owner_unit, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 1.5)
			u.launch(6.0)
