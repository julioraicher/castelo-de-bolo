class_name ContadorMadeira
extends Node3D
## Contador de madeira em cima de uma obra (casinha/oficina): ícone de tora,
## "faltam N" e uma barrinha. Sempre de frente para a câmera e por cima do
## telhado (sem teste de profundidade). Grande para quem joga de Construtor,
## pequeno para as outras classes; sem estoque no time, pisca "falta madeira".
## Com `obra` (0..1, Jogabilidade 2.3c) a barra tem duas camadas: dourado =
## madeira entregue (até onde dá para construir), claro = já construído; o
## texto começa com a porcentagem da obra.
## 5 chamadas de desenho enquanto visível: esconda quando a obra acabar.

const ICONE := preload("res://assets/ui/icone_tora.png")
const COR_OK := Estilo.OURO
const COR_FALTA := Estilo.PERIGO
const COR_FUNDO := Color(0.055, 0.045, 0.12, 0.85)
const COR_OBRA := Color(0.75, 1.0, 0.8)
const LARG := 2.2  # largura da barra no tamanho grande (m)

var _icone: Sprite3D
var _texto: Label3D
var _fundo: MeshInstance3D
var _barra: MeshInstance3D
var _mat_barra: StandardMaterial3D
var _obra: MeshInstance3D
var _sem_estoque := false
var _t := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_icone = Sprite3D.new()
	_icone.texture = ICONE
	_icone.pixel_size = 0.0045
	_icone.position = Vector3(-1.0, 0.36, 0)
	_icone.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icone.no_depth_test = true
	_icone.render_priority = 10
	_icone.shaded = false
	add_child(_icone)
	_texto = Label3D.new()
	_texto.font = Estilo.NUMERO
	_texto.font_size = 64
	_texto.outline_size = 18
	_texto.outline_modulate = Estilo.TINTA
	_texto.pixel_size = 0.009
	_texto.position = Vector3(0.3, 0.36, 0)
	_texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_texto.no_depth_test = true
	_texto.render_priority = 11
	_texto.outline_render_priority = 10
	add_child(_texto)
	_fundo = _quad(Vector2(LARG + 0.1, 0.26), COR_FUNDO, 10)
	_barra = _quad(Vector2(LARG, 0.16), COR_OK, 11)
	_mat_barra = _barra.material_override
	_obra = _quad(Vector2(LARG, 0.16), COR_OBRA, 12)
	_obra.visible = false
	mostrar(0, 1)


## faltam = madeiras que ainda faltam; total = custo da obra; obra = fração
## já construída (negativa = sem camada de obra).
func mostrar(faltam: int, total: int, grande := true, sem_estoque := false, obra := -1.0) -> void:
	_sem_estoque = sem_estoque and faltam > 0
	scale = Vector3.ONE * (1.0 if grande else 0.55)
	var pct := "%d%%  " % int(obra * 100.0) if obra >= 0.0 else ""
	if faltam <= 0:
		_texto.text = pct + "construindo" if obra >= 0.0 and obra < 1.0 else "pronto!"
	elif _sem_estoque:
		_texto.text = pct + "falta madeira"
	else:
		_texto.text = pct + "faltam %d" % faltam
	var f := 1.0 - clampf(float(faltam) / maxf(total, 1), 0.0, 1.0)
	_encher(_barra, f)
	_obra.visible = obra > 0.0
	if _obra.visible:
		_encher(_obra, clampf(obra, 0.0, 1.0))
	_pintar(1.0)


func _encher(q: MeshInstance3D, f: float) -> void:
	q.scale.x = maxf(f, 0.001)
	q.position.x = -LARG * (1.0 - f) / 2.0


func _process(delta: float) -> void:
	if not _sem_estoque:
		return
	_t += delta
	_pintar(0.45 + 0.55 * absf(sin(_t * 5.0)))


func _pintar(a: float) -> void:
	var c := COR_FALTA if _sem_estoque else COR_OK
	_texto.modulate = Color(c.lightened(0.35), a)
	_icone.modulate = Color(1, 1, 1, a)
	_mat_barra.albedo_color = c


## Retângulo de frente para a câmera (sem luz, por cima de tudo).
func _quad(tam: Vector2, cor: Color, prioridade: int) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = tam
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.no_depth_test = true
	m.render_priority = prioridade
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = cor
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
