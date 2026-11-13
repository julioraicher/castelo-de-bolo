class_name Sorte
## Sorteio das REGRAS (Ciclo 2.28, multiplayer): um gerador só, com semente,
## que todos os PCs da sala começam iguais. Tudo que muda o jogo (IA, onde
## nasce, quem pega o quê, ângulo de tiro) sorteia aqui; enfeite visual
## (faísca, tremidinha, giro de efeito) continua no randf() global.
## Regra: se o resultado pode mexer em posição, vida, decisão ou colisão,
## é Sorte.f(); se só muda o desenho, é randf(). Misturar os dois
## dessincroniza a partida online (o teste "sincronia" no CI pega).

static var rng := RandomNumberGenerator.new()


static func semear(s: int) -> void:
	rng.seed = s
	rng.state = s


static func f() -> float:
	return rng.randf()


static func r(a: float, b: float) -> float:
	return rng.randf_range(a, b)


static func i() -> int:
	return rng.randi()


## Relógio das regras: quadros de física desde o começo da partida (Game
## soma 1 por quadro). Use no lugar de Time.get_ticks_msec() em qualquer
## regra: o relógio de parede é diferente em cada PC.
static var tick := 0


static func ms() -> int:
	return tick * 1000 / Engine.physics_ticks_per_second
