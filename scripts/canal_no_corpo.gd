class_name CanalNoCorpo
extends RefCounted
## Base do Reanimar e do Finalizar: segurar [F] num corpo caído (revisão 3a,
## NU-15). As duas regras copiavam a busca do corpo mais perto, a reserva de um
## bot por corpo, o "pode canalizar", o nome no placar e as peças da marca no
## chão (anel e letreiro). A filha responde só o que muda:
##   _ligado()              a regra está ligada no game_config
##   _vale(c, u)            o corpo c serve para u (time certo, ainda dá tempo)
##   _dono(c)               quem já está canalizando em c
##   _no_outro_canal(u)     u está ocupado no outro canal (reanimar x finalizar)
##   _raio_bot(u)           até onde o bot vai buscar um corpo
##   _livre_para_bot(c, u)  o bot pode ir até c (padrão: sim)

const ANEL := preload("res://assets/shaders/anel_reanimar.gdshader")

var game: Game
var cfg: GameConfig
## Corpo -> peças da marca no chão (raiz, anel, placa...).
var _visuais := {}
## Corpo -> bot que está indo até ele (um bot por corpo).
var _reservas := {}
var _efeito_t := 0.0
static var _mat_anel: ShaderMaterial


func _init(g: Game) -> void:
	game = g
	cfg = Config.cfg


func _ligado() -> bool:
	return false


func _vale(_c: Unit, _u: Unit) -> bool:
	return false


func _dono(_c: Unit) -> Unit:
	return null


func _no_outro_canal(_u: Unit) -> bool:
	return false


func _raio_bot(_u: Unit) -> float:
	return 0.0


func _livre_para_bot(_c: Unit, _u: Unit) -> bool:
	return true


## Corpo que `u` pode usar mais perto, dentro de `raio` (o de outro dono não vale).
func corpo_perto(u: Unit, raio: float) -> Unit:
	var melhor: Unit = null
	var dmin := raio
	for c in game.units:
		if not _vale(c, u):
			continue
		var dono := _dono(c)
		if dono != null and dono != u:
			continue
		var d := u.global_position.distance_to(c.global_position)
		if d < dmin:
			dmin = d
			melhor = c
	return melhor


## Corpo que o bot `u` deve ir buscar (ou null). Um bot por corpo.
func corpo_para_bot(u: Unit) -> Unit:
	if not _ligado() or u.carried_princess or u.carried_tora:
		return null
	var melhor: Unit = null
	var dmin := _raio_bot(u)
	for c in game.units:
		if not _vale(c, u):
			continue
		var r: Unit = _reservas.get(c)
		if r and r != u and is_instance_valid(r) and r.alive:
			continue
		if not _livre_para_bot(c, u):
			continue
		var d := u.global_position.distance_to(c.global_position)
		if d < dmin:
			dmin = d
			melhor = c
	if melhor:
		_reservas[melhor] = u
	return melhor


## Vivo, no chão, sem dash nem carga e livre do outro canal.
func _pode_canalizar(u: Unit) -> bool:
	return u.alive and not u.em_voo and u._dodge_t <= 0.0 and u.carried_princess == null \
			and u.carried_tora == null and not u.is_equipping() and not _no_outro_canal(u)


## Nome do boneco no placar (o do amigo, online), senão o da classe.
func _nome(u: Unit) -> String:
	var l := game.placar.linha(u)
	return String(l.get("nome", u.stats.display_name))


# --- Marca no chão -------------------------------------------------------------

func _raiz_marca(u: Unit) -> Node3D:
	var raiz := Node3D.new()
	raiz.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	game.add_child(raiz)
	raiz.global_position = u.global_position
	return raiz


## Anel no chão (anel_reanimar.gdshader) do tamanho do raio do canal.
func _anel(raiz: Node3D, raio: float, altura: float) -> MeshInstance3D:
	if _mat_anel == null:
		_mat_anel = ShaderMaterial.new()
		_mat_anel.shader = ANEL
	var anel := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	var lado := raio * 2.0
	pl.size = Vector2(lado, lado)
	anel.mesh = pl
	anel.material_override = _mat_anel
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anel.position = Vector3(0, altura, 0)
	anel.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	raiz.add_child(anel)
	return anel


## Letreiro sobre o corpo ("CAÍDO", "FINALIZE [F]", a porcentagem do canal).
func _placa(raiz: Node3D, texto: String, cor: Color) -> Label3D:
	var placa := Label3D.new()
	placa.text = texto
	placa.font = Estilo.LETREIRO
	placa.font_size = 44
	placa.outline_size = 14
	placa.pixel_size = 0.006
	placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placa.no_depth_test = true
	placa.modulate = cor
	placa.outline_modulate = Color(0.05, 0.04, 0.08, 0.9)
	placa.position = Vector3(0, 2.05, 0)
	placa.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	raiz.add_child(placa)
	return placa


func _remover_visual(u: Unit) -> void:
	if not _visuais.has(u):
		return
	(_visuais[u].raiz as Node3D).queue_free()
	_visuais.erase(u)
