class_name FxBase
extends RefCounted
## Base comum do kit visual (revisão 3c, FX-12/13/24). Sem regra nenhuma: só o
## que os kits (Fx, Magia, FxProjetil, FxHerois, FxNatureza, FxObra, FxItens)
## escreviam cada um do seu jeito.
##   cache(chave, fazer)   recurso criado uma vez (chave com o prefixo do kit)
##   no / malha            nó sem interpolação e malha sem sombra
##   g / tremer            onde pendurar o efeito de um boneco; tremor da câmera
##   enfeite / qtd         o portão de qualidade (Mínima corta enfeite e metade das partículas)

static var _cache := {}


## Recurso reaproveitado: cria uma vez com `fazer` e devolve o mesmo nas próximas.
## Partículas não animam o material, então todas do mesmo tipo e cor podem
## dividir malha e material (menos alocação e nenhum shader novo no meio da luta).
static func cache(chave: String, fazer: Callable) -> Variant:
	if not _cache.has(chave):
		_cache[chave] = fazer.call()
	return _cache[chave]


## Nó vazio em `pos`, sem interpolação de física (efeito anima por tween).
static func no(pai: Node, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pai.add_child(n)
	n.global_position = pos
	return n


## Malha com material, filha de `pai` (sem sombra, salvo `sombra`).
static func malha(pai: Node3D, m: Mesh, mat: Material, sombra := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi


## Onde pendurar o efeito de um boneco (o Game dele).
static func g(u: Unit) -> Node:
	return u.game


## Tremor da câmera perto de `pos` (nada se `onde` não for o Game ou não tiver câmera).
static func tremer(onde: Node, pos: Vector3, forca: float) -> void:
	var game := onde as Game
	if game and game.camera:
		game.camera.shake_at(pos, forca)


## Enfeite (rastro, brasas, carga, clarão): desliga na qualidade Mínima.
static func enfeite() -> bool:
	return Settings.quality > 0


## Quantidade de partículas: metade (no mínimo 1) na qualidade Mínima.
static func qtd(n: int) -> int:
	return n if Settings.quality > 0 else maxi(1, n / 2)
