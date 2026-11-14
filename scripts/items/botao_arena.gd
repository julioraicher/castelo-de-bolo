class_name BotaoArena
extends Node3D
## Tambor da Arena de chapéus (Ciclo 2.29): um taiko baixo de laca escura com
## o botão no topo. [F] perto dele gera um inimigo aleatório na frente do
## jogador (Game._gerar_inimigo_arena). Dois tambores (2.29b): o de Desafio
## (botão vermelho) chama classe base; o dos Heróis (botão dourado, faixa
## roxa) chama caminho Nv2-5 ou herói raro.
## Silhueta própria (princípio 13): tambor com tachas douradas e duas
## baquetas cruzadas atrás; o botão afunda e volta ao ser apertado.

## Distância para acionar (igual ao raio de pegar chapéu).
const RAIO := 2.6

## true = Tambor dos Heróis (definir antes de entrar na árvore).
var heroi := false
var _botao: MeshInstance3D
var _aro: MeshInstance3D
var _apertando := false


func _ready() -> void:
	var laca := Fx.lit(Color(0.16, 0.1, 0.12), 0.45)
	var madeira := Fx.lit(Color(0.45, 0.28, 0.16))
	var ouro := Fx.lit(Color(1.0, 0.78, 0.3), 0.3)
	# Corpo do taiko: tambor deitado de pé, com os dois aros e as tachas.
	_peca(_cil(0.85, 0.9, 1.0, 10), Vector3(0, 0.5, 0), Vector3.ZERO, laca)
	for y in [0.12, 0.92]:
		_peca(_cil(0.95, 0.95, 0.1, 10), Vector3(0, y, 0), Vector3.ZERO, madeira)
	for i in 10:
		var a := TAU * i / 10.0
		_peca(_esf(0.06), Vector3(cos(a) * 0.9, 0.92, sin(a) * 0.9), Vector3.ZERO, ouro)
	# Baquetas cruzadas atrás, de quem acabou de chamar a briga.
	for s in [-1, 1]:
		_peca(_cil(0.045, 0.045, 1.3, 8), Vector3(0.25 * s, 0.75, -0.75), Vector3(0, 0, 35 * s), madeira)
	# Pele do tambor: o aro dourado e o botão vermelho que afunda.
	_aro = _peca(_cil(0.66, 0.7, 0.12, 12), Vector3(0, 1.0, 0), Vector3.ZERO, ouro)
	_botao = MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.58
	dome.height = 0.5
	dome.is_hemisphere = true
	dome.radial_segments = 12
	dome.rings = 4
	_botao.mesh = dome
	_botao.material_override = Fx.lit(Color(1.0, 0.76, 0.25) if heroi else Color(0.78, 0.12, 0.1), 0.25)
	if heroi:
		# Faixa roxa no meio do corpo: o tambor que chama os raros.
		_peca(_cil(0.88, 0.92, 0.18, 10), Vector3(0, 0.5, 0), Vector3.ZERO, Fx.lit(Color(0.45, 0.2, 0.6), 0.4))
	_botao.position = Vector3(0, 1.04, 0)
	add_child(_botao)
	# Letreiro no estilo das maquininhas.
	var l := Label3D.new()
	l.font = Estilo.LETREIRO
	l.font_size = 40
	l.pixel_size = 0.011
	l.line_spacing = -6
	l.outline_size = 10
	l.outline_modulate = Estilo.TINTA
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1.0, 0.82, 0.4) if heroi else Color(1.0, 0.55, 0.5)
	l.position.y = 2.6
	l.text = "%s\n[F] %s" % [nome().to_upper(), "caminho ou herói" if heroi else "classe base"]
	l.add_to_group("letreiro_perto")
	add_child(l)
	# Tudo que é parado vira uma malha só; o botão fica de fora (anima).
	MalhaUnica.juntar(self, [_botao])


func nome() -> String:
	return "Tambor dos Heróis" if heroi else "Tambor de Desafio"


## O botão afunda e salta de volta (tween na física: regra não depende dele,
## mas segue o padrão do projeto).
func acionar() -> void:
	if _apertando or _botao == null:
		return
	_apertando = true
	Sfx.play("swing", global_position, 0.2)
	var tw := _botao.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_botao, "position:y", 0.9, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_botao, "position:y", 1.04, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _apertando = false)
	Fx.burst(get_parent(), global_position + Vector3(0, 1.3, 0), Color(1.0, 0.4, 0.35), 10, 4.0)


func _peca(mesh: Mesh, pos: Vector3, rot: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	add_child(mi)
	return mi


func _cil(top: float, bottom: float, h: float, seg := 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


func _esf(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 8
	m.rings = 4
	return m
