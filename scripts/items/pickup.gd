class_name Pickup
extends Node3D
## Item no chão (power-up). Quem encosta pega na hora:
##   pocao      -> cura parte da vida          (cabaça laqueada)
##   escudo     -> bolha que absorve dano      (leque de guerra)
##   velocidade -> corre mais por alguns segundos (tamanca geta)
##   dano       -> dano multiplicado por alguns segundos (kunais cruzadas)
##   medidor    -> enche o medidor do poder na hora (pergaminho de chi)
## Números em game_config.tres > Itens no chão. Visual em FxItens (Ciclo 2.32):
## cai do céu e quica, flutua girando com o brilho de energia de cada um, e se
## desfaz em energia na cor dele quando pego.

const KINDS := ["pocao", "escudo", "velocidade", "dano", "medidor"]
const COLORS := {"pocao": Color(1.0, 0.3, 0.4), "escudo": Color(0.35, 0.85, 1.0), "velocidade": Color(1.0, 0.85, 0.2),
		"dano": Color(1.0, 0.15, 0.1), "medidor": Color(0.85, 0.4, 1.0)}
const NAMES := {"pocao": "Poção", "escudo": "Escudo", "velocidade": "Velocidade", "dano": "Dano dobrado", "medidor": "Poder cheio"}
const ALTURA := 0.95   # m do meio do objeto acima do chão
const ESCALA := 1.35
const QUEDA := 3.5     # m de onde ele cai quando nasce

var kind := "pocao"
var _visual: Node3D
var _objeto: Node3D
var _t := randf() * TAU
var _queda := QUEDA


func setup(p_kind: String, pos: Vector3) -> void:
	kind = p_kind
	position = pos
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado em _process
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_objeto = Node3D.new()
	_visual.add_child(_objeto)
	var mi := MeshInstance3D.new()
	mi.mesh = FxItens.malha_item(kind)
	mi.material_override = FxItens.mat_objeto(get_parent())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_objeto.add_child(mi)
	FxItens.energia_item(_objeto, kind)
	if kind == "velocidade":
		_objeto.rotation = Vector3(-0.35, 0.0, 0.3)  # tamanca no meio do passo
	_visual.scale = Vector3.ONE * ESCALA
	var anel := FxItens.anel_chao(self, FxItens.PAL_ITEM[kind], 0.95, {"voltas": 8.0, "forca": 0.5, "banda": 0.1, "alfa": 0.8, "gira": 0.08})
	anel.scale = Vector3(0.05, 1.0, 0.05)
	# Cai do céu e quica; o anel abre quando ele assenta (visual: tween comum).
	var tw := create_tween()
	tw.tween_property(self, "_queda", 0.0, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(anel, "scale", Vector3(0.95, 1.0, 0.95), 0.45).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_callback(FxItens.item_assenta.bind(get_parent(), pos, kind)).set_delay(0.3)
	_process(0.0)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * (3.2 if kind == "velocidade" else 1.6)
	_visual.position.y = ALTURA + _queda + sin(_t * 3.0) * 0.13
	# Cada um com seu jeito de esperar.
	match kind:
		"pocao":
			_objeto.rotation.z = sin(_t * 2.2) * 0.18
		"escudo":
			_objeto.rotation.z = sin(_t * 1.6) * 0.35
		"velocidade":
			_objeto.position.y = absf(sin(_t * 4.0)) * 0.12
		"dano":
			_objeto.rotation.z = sin(_t * 2.6) * 0.25
		_:
			_objeto.rotation.x = sin(_t * 1.8) * 0.15


## Aplica o efeito em quem pegou.
func apply_to(u: Unit) -> void:
	var cfg := Config.cfg
	match kind:
		"pocao":
			u.heal(u.max_hp() * cfg.pickup_heal)
		"escudo":
			u.give_shield(cfg.pickup_shield, cfg.pickup_shield_time)
		"velocidade":
			u.give_boost(cfg.pickup_speed_mult, cfg.pickup_speed_time)
		"dano":
			u.give_damage_boost(cfg.pickup_damage_time)
		"medidor":
			u.fill_power()
	u.play_gesture("Interact", 1.8)
	FxItens.item_pego(u.game, global_position + Vector3(0, ALTURA, 0), kind, u)
	if u.is_player:
		u.game.hud.show_big(NAMES[kind] + "!", COLORS[kind], 1.0)
