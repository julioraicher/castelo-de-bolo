class_name Placar
extends RefCounted
## Placar estilo Battlefield (Ciclo 2.16): estatística de cada boneco, do
## jogador e dos bots, contada ao longo da partida inteira (o boneco é o mesmo
## nó depois de morrer, só troca de classe).
## Pontos = Σ campo × peso, com os pesos em game_config.tres, grupo
## "Placar (Tab)": o peso do campo "abates" é `pts_abates`, e assim por diante.
## Quem mostra é PlacarTela (Tab ou fim da partida).

## Ordem das colunas e das contas. Campo novo = entrada aqui + `pts_<campo>`
## no GameConfig + chamada de somar() onde a coisa acontece.
const CAMPOS := ["abates", "assist", "mortes", "dano", "cura", "almas", "madeira", "obra_s", "capturas", "roubos", "resgates"]

## Nomes dos bots (o jogador é "Você"). Curtos para caber na coluna.
const NOMES := ["Hayato", "Kenji", "Sora", "Rin", "Daichi", "Yuki", "Haru", "Kaito",
		"Mei", "Ren", "Taro", "Aiko", "Botan", "Goro", "Jun", "Nao"]

var cfg: GameConfig
## Unit -> {nome, unit, campos...}
var _linhas := {}
## Vítima -> {atacante: instante do último dano} (para as assistências)
var _danos := {}


func _init(config: GameConfig) -> void:
	cfg = config


func registrar(u: Object, team: int, indice: int, jogador: bool) -> void:
	var l := {"nome": "Você" if jogador else NOMES[(team * 8 + indice) % NOMES.size()], "unit": u, "team": team, "jogador": jogador}
	for c in CAMPOS:
		l[c] = 0.0
	_linhas[u] = l


func linha(u: Object) -> Dictionary:
	return _linhas.get(u, {})


func somar(u: Object, campo: String, v := 1.0) -> void:
	var l: Dictionary = _linhas.get(u, {})
	if not l.is_empty():
		l[campo] += v


## Dano de `atacante` em `alvo` (já descontado escudo/bloqueio). Só conta
## dano em inimigo; guarda o instante para a assistência.
func dano(alvo: Object, atacante: Object, v: float, agora: float) -> void:
	if atacante == null or alvo == atacante or v <= 0.0:
		return
	somar(atacante, "dano", v)
	if not _danos.has(alvo):
		_danos[alvo] = {}
	_danos[alvo][atacante] = agora


## Abate: morte para quem caiu, abate para quem matou e assistência para quem
## bateu nele há pouco. Devolve os assistentes (para o aviso "+ASSISTÊNCIA").
func abate(morto: Object, killer: Object, agora: float) -> Array:
	somar(morto, "mortes")
	var assist := []
	if killer and killer != morto:
		somar(killer, "abates")
	var recentes: Dictionary = _danos.get(morto, {})
	for a in recentes:
		if a != killer and is_instance_valid(a) and agora - float(recentes[a]) <= cfg.assistencia_janela:
			somar(a, "assist")
			assist.append(a)
	_danos.erase(morto)
	return assist


func pontos(l: Dictionary) -> int:
	return Placar.pontos_de(l, cfg)


## A conta, separada para os testes de regra.
static func pontos_de(l: Dictionary, c: GameConfig) -> int:
	var p := 0.0
	for campo in CAMPOS:
		p += float(l.get(campo, 0.0)) * float(c.get("pts_" + campo))
	return int(round(p))


## Linhas de um time, da maior pontuação para a menor (empate: mais abates).
func time(team: int) -> Array:
	var out := []
	for u in _linhas:
		var l: Dictionary = _linhas[u]
		if l.team == team:
			l["pontos"] = pontos(l)
			out.append(l)
	out.sort_custom(func(a, b): return a.pontos > b.pontos or (a.pontos == b.pontos and a.abates > b.abates))
	return out


func total(team: int) -> int:
	var t := 0
	for l in time(team):
		t += int(l.pontos)
	return t
