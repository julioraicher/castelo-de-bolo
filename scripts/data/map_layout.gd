class_name MapLayout
extends Resource
## Forma do mapa: tamanho da arena, castelo (muralhas, torres, pedestais) e
## objetos. Os dois castelos são espelhos: tudo de castelo usa coordenadas
## LOCAIS (x aponta para o inimigo, z para o lado), convertidas por
## Arena.to_world(). Os modelos vêm do tema (ThemeConfig).

@export var display_name := "Vale dos Dois Castelos"

@export_group("Arena")
## Distância do centro do mapa até o centro de cada castelo.
@export var castle_distance := 48.0
@export var half_width := 68.0
@export var half_depth := 36.0
## Área (meia-largura x, meia-profundidade z) onde os bolos aparecem.
@export var cake_area := Vector2(26, 28)
@export var road_width := 7.0

@export_group("Castelo")
@export var wall_back := -13.0
@export var wall_front := 11.0
@export var wall_half_width := 13.0
## Meia-largura do vão do portão na muralha da frente.
@export var gate_half_width := 5.0
@export var keep_position := Vector2(-8, 0)
@export var keep_collider_size := Vector3(6.0, 6.0, 6.5)
@export var tower_spots: PackedVector2Array = [Vector2(-13, -13), Vector2(-13, 13), Vector2(11, -13), Vector2(11, 13), Vector2(11, -5.5), Vector2(11, 5.5)]
@export var tower_collider_radius := 1.8
@export var princess_spot := Vector2(-1, 0)
@export var pedestal_radius := 1.7
## Um pedestal de chapéu por classe de GameConfig.hat_class_list, na ordem.
@export var hat_spots: PackedVector2Array = [Vector2(5, -8.5), Vector2(5, 8.5), Vector2(-3, -8.5), Vector2(-3, 8.5)]
## Terrenos de oficina (o time escolhe que variação construir em cada um).
@export var oficina_spots: PackedVector2Array = [Vector2(-7.5, -8.5), Vector2(-7.5, 8.5)]
## Economia do Construtor (coordenadas locais, aparecem nos dois castelos,
## espelhadas): árvores do bosque seguro, bambus do meio (lx perto de
## castle_distance = perto do centro) e a pilha de madeira do castelo.
@export var tree_spots: PackedVector2Array = []
@export var bamboo_spots: PackedVector2Array = []
@export var pilha_spot := Vector2(8, -12)
@export var spawn_min := Vector2(-1, -5)
@export var spawn_max := Vector2(6, 5)
## Quanto à frente da muralha os defensores ficam de guarda.
@export var gate_guard_distance := 3.0
## Muralha com passarela: altura do caminho em cima (0 = muralha antiga, só bloqueia).
## As escadas são objetos do pátio com colisor "caixa" inclinado.
@export var wall_height := 0.0
@export var wall_thickness := 2.2
## Mureta do lado de fora da passarela (altura).
@export var wall_parapet := 1.0
## Troca os modelos do tema só neste mapa (vazio = usa o do tema). Ex.: muralha
## alta com passarela no lugar do muro baixo.
@export var wall_model := ""
@export var tower_model := ""
## Altura da bandeira na torre neste mapa (negativo = usa a do tema).
@export var flag_height := -1.0

@export_group("Objetos")
## Objetos de cada pátio (coordenadas locais, aparecem nos dois castelos).
@export var courtyard_props: Array[MapProp] = []
## Objetos do meio do mapa (coordenadas do mundo).
@export var middle_props: Array[MapProp] = []
## Espaçamento da paisagem decorativa em volta da arena.
@export var border_spacing := 7.0
