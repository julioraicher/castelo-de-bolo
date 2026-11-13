class_name Reacoes
extends RefCounted
## Reações entre elementos (Heróis 2.27, quiz 3B: só as óbvias). Quem solta o
## elemento chama `em` no ponto do impacto, com o raio que o efeito cobre.
##  - Fogo queima teia (Kitsune, Luz, Sombria, Onibi, bomba e mina).
##  - Vento rasga teia (leque do Yamabushi, redemoinho, asas do Karasu Tengu).
##  - Fogo queima o bosque do Kodama (a árvore vira tocha e cai: ArvoreKodama).
##  Raio × molhado e árvore como para-raios: HeroisNatureza.
## Só afeta o que é do outro time: ninguém queima a própria teia sem querer.

const FOGO := ["fogo", "chi", "magia", "bomba", "onibi", "coluna_fogo", "brasa"]
const VENTO := ["vento", "redemoinho", "rajada", "pena", "revoada"]


static func tipo(elemento: String) -> String:
	if elemento in FOGO:
		return "fogo"
	if elemento in VENTO:
		return "vento"
	return ""


static func em(g: Node, pos: Vector3, raio: float, elemento: String, time: int) -> void:
	var t := tipo(elemento)
	if t == "" or g == null or not g.is_inside_tree():
		return
	for n in g.get_tree().get_nodes_in_group("teias"):
		var teia := n as Teia
		if teia == null or teia.indo or teia.time == time:
			continue
		var d := teia.global_position - pos
		if absf(d.y) > 2.5:
			continue
		d.y = 0
		if d.length() > raio + teia.raio * 0.8:
			continue
		if t == "fogo":
			teia.queimar()
		else:
			teia.rasgar()
	if t != "fogo":
		return
	for n in g.get_tree().get_nodes_in_group("arvores_kodama"):
		var arv := n as ArvoreKodama
		if arv == null or arv.indo or arv.time == time:
			continue
		var d := arv.global_position - pos
		if absf(d.y) > 3.0:
			continue
		d.y = 0
		if d.length() <= raio + arv.raio_tronco() + 0.6:
			arv.queimar(time)
