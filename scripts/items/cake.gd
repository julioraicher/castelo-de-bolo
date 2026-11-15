class_name Cake
extends Node3D
## Espírito solto no mapa (hitodama, chama-fantasma; o nome Cake ficou do
## protótipo). Quem encosta pega; levando até a própria máscara, ele fica
## preso nela e a deixa mais pesada para o inimigo carregar.
## Visual em FxItens (Ciclo 2.32): gota de fogo-fátuo do kit Magia com a cauda
## rasgando, duas chaminhas em órbita e o anel verde no chão. Pegar = a chama
## estica e se rasga (FxItens.hitodama_pego); preso = FxItens.hitodama_preso.


## Visual do espírito em escala `s` (o da cabeça de quem carrega, o que voa
## para a máscara e os que orbitam a máscara usam este).
static func make_visual(s := 1.0, orbitas := false) -> Node3D:
	return FxItens.hitodama(s, orbitas)


var _visual: Node3D
var _orbita: Node3D
var _chama: Node3D
var _r0 := 1.0
var _t := randf() * TAU
var _nasceu := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animado em _process
	_visual = make_visual(1.0, true)
	add_child(_visual)
	_orbita = _visual.get_node_or_null("Orbita")
	_chama = _visual.get_node("Chama")
	_r0 = _chama.scale.x
	FxItens.anel_chao(self, FxItens.PAL_HITODAMA, 0.95, {"voltas": 5.0, "forca": 0.85, "banda": 0.12, "alfa": 0.75, "gira": -0.05})
	# Nasce subindo do chão (visual: tween comum).
	_visual.scale = Vector3.ONE * 0.05
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not _nasceu:
		_nasceu = true  # a posição chega depois do _ready (Game._spawn_cakes)
		if Magia.enfeite():
			Magia.anel_sobe(get_parent(), global_position + Vector3(0, 0.1, 0), FxItens.PAL_HITODAMA, 0.8, 1.2, 0.6)
	_t += delta
	_visual.rotation.y += delta * 1.2
	_visual.position.y = 0.3 + sin(_t * 2.4) * 0.14
	var resp := 1.0 + sin(_t * 5.0) * 0.05  # a chama respira
	_chama.scale = Vector3(resp, 1.0 / resp, resp) * _r0
	if _orbita:
		_orbita.rotation.y -= delta * 2.6
		_orbita.position.y = 0.42 + sin(_t * 1.7) * 0.1
