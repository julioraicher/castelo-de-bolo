class_name MapProp
extends Resource
## Um objeto do mapa (pedra, árvore, barril...). Usado em MapLayout.

## Arquivo do modelo dentro da pasta de modelos do tema. Vazio = só colisor
## (rampas, travas do rio, plataformas).
@export var model := "rock_single_A.gltf"
## No pátio: coordenadas locais do castelo (x aponta para o inimigo).
## No meio do mapa: coordenadas do mundo.
@export var position := Vector3.ZERO
@export var scale := 3.0
## Graus. Negativo = aleatório a cada partida.
@export var rotation_deg := 0.0
@export_enum("nenhuma", "cilindro", "caixa") var collider := "nenhuma"
@export var collider_radius := 1.0
@export var collider_height := 2.0
## Colisor "caixa": tamanho, giro (graus, gira junto com o objeto) e deslocamento
## do centro em relação ao objeto. Uma caixa inclinada vira rampa.
@export var collider_size := Vector3(2, 2, 2)
@export var collider_rot := Vector3.ZERO
@export var collider_offset := Vector3.ZERO
## Cria também a cópia espelhada em -x e/ou -z (mapas simétricos).
@export var mirror_x := false
@export var mirror_z := false


## Posições finais, já com os espelhos.
func positions() -> Array[Vector3]:
	var out: Array[Vector3] = [position]
	if mirror_x:
		out.append(Vector3(-position.x, position.y, position.z))
	if mirror_z:
		for i in out.size():
			out.append(Vector3(out[i].x, out[i].y, -out[i].z))
	return out
