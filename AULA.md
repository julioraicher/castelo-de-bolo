# Aula: engenharia reversa do Castelo de Bolo

Versão 1. Arquivo para editar à vontade: responda nas caixas `> Minhas notas:`,
marque `[x]` nos experimentos feitos, apague o que não servir.

O método é o de laboratório: **hipótese → perturbação → medida → modelo**.
Você não lê o código de cima a baixo; você mexe em um parâmetro, prevê o
efeito antes de rodar, roda e compara. Quando a previsão falha, o modelo
mental estava errado, e é aí que se aprende.

Pré-requisito: Godot 4.7 aberto no projeto (veja [GUIA.md](GUIA.md), seção 1).
F5 roda o jogo; **F8** para; erros aparecem no painel **Depurador** embaixo.

---

## Sprint 0: o laço do jogo (20 min)

Todo jogo é um sistema dinâmico discreto: um estado `S` e uma regra
`S(t+Δt) = f(S(t), entrada, Δt)` aplicada 60 vezes por segundo. No Godot,
`f` está espalhada em funções `_physics_process(delta)` de cada nó.

Neste jogo, um quadro (passo de física) faz, nesta ordem:

1. `Game._physics_process` → `_rules()`: checa distâncias e aplica as regras
   (pegar princesa, pontuar, bolo, chapéu). `scripts/game.gd`
2. Cada `Unit._physics_process`: o **cérebro** (`PlayerBrain` ou `BotBrain`)
   preenche intenções; o **corpo** integra velocidade e chama
   `move_and_slide()`. `scripts/actors/unit.gd`
3. `Princess`, `Projectile`, `Cake` atualizam o próprio estado.
4. Depois da física, `_process` desenha: câmera (`camera_rig.gd`), HUD.

**Experimento 0.1** [ ]: em `unit.gd`, dentro de `_physics_process`, logo
no começo, coloque `if is_player: print(delta)`. Rode. Que número aparece e
por quê não varia? (Dica: procure "physics_ticks_per_second" em
Projeto > Configurações do Projeto.) Apague a linha depois.

> Minhas notas:

---

## Sprint 1: cinemática do soldado (30 min)

Trecho central (`unit.gd`, `_physics_process`):

```gdscript
var target := move_intent.limit_length(1.0) * speed + _separation() * 3.0
horizontal = horizontal.move_toward(target, ACCEL * delta)
```

`move_toward` limita a variação do vetor velocidade a `ACCEL·Δt` por passo:
é aceleração de módulo constante `a = 70 m/s²` até atingir o alvo. Para um
guerreiro (`move_speed = 6.2`), o tempo para sair do repouso até a
velocidade máxima é `t = v/a ≈ 0,089 s`, ou seja, ~5 quadros. Por isso o
controle parece "liso" mas responsivo.

**Experimento 1.1** [ ]: troque `ACCEL` para `8.0`. Previsão antes de rodar:
quanto tempo até a velocidade máxima? Como isso muda a sensação? (O nome
técnico disso é *input latency* percebida.)

**Experimento 1.2** [ ]: `_separation()` é uma força repulsiva de curto
alcance entre aliados, linear em `(1,5 − d)`. É um potencial harmônico
truncado: `U(d) = ½k(1,5 − d)²` para `d < 1,5`. Troque o `1.5` por `4.0` nos
dois lugares. O que acontece com grupos de bots? Por que formam "cristais"?

> Minhas notas:

---

## Sprint 2: o modelo da princesa gorda (30 min)

A velocidade de quem carrega (`Unit.current_speed`):

```
v = v₀ · m_carry · (1 − f · k)
```

`v₀` = `move_speed` da classe, `m_carry` = `carry_speed_mult`,
`f ∈ [0, 1]` = gordura (cada bolo soma `fat_per_cake = 0,1`),
`k` = `fat_slowdown = 0,45` (em `config/game_config.tres`).

Os pedestais ficam em `x = ±49` (`Arena.to_world(team, -1, 0)` com
`CASTLE_DISTANCE = 48`), então a distância em linha reta é `L ≈ 98 m`.
Tempo de carregar, guerreiro (`v₀ = 6,2`, `m = 0,7`):

| f | v (m/s) | t = L/v |
|---|---|---|
| 0 | 4,34 | 22,6 s |
| 0,5 | 3,36 | 29,2 s |
| 1 | 2,39 | 41,0 s |

**Exercício 2.1** [ ]: o aldeão tem `carry_speed_mult = 0,95` e `v₀ = 7`.
Quem é o melhor carregador? Isso é bug ou design? (No jogo original, a
classe "trabalhadora" é justamente a que carrega bem.)

**Exercício 2.2** [ ]: se `k = 1` e `f = 1`, o que acontece? Por que o
projeto usa `k < 1`? Mude no `.tres` e confirme.

**Exercício 2.3** [ ]: qual `fat_per_cake` faz 5 bolos dobrarem o tempo de
carregar um guerreiro? (Resolva `1/(1 − 5·p·k) = 2`.)

> Minhas notas:

---

## Sprint 3: a câmera como filtro passa-baixa (20 min)

`camera_rig.gd`:

```gdscript
_focus = _focus.lerp(desired, 1.0 - exp(-cfg.camera_smooth * delta))
```

Isso é a solução exata, num passo `Δt`, de `dx/dt = −λ(x − x_alvo)`, com
`λ = camera_smooth = 7 s⁻¹`. Constante de tempo `τ = 1/λ ≈ 0,14 s`. Usar
`exp` em vez de `lerp(…, 0.1)` torna o resultado independente do FPS: com
um fator fixo, um PC a 144 Hz teria uma câmera mais "dura" que um a 30 Hz.

O tremor usa `trauma²`: como `trauma ∈ [0,1]`, o quadrado deixa golpes
fracos quase imperceptíveis e golpes fortes bem marcados (resposta
não linear, mesma ideia de uma curva de gama).

**Experimento 3.1** [ ]: troque o fator por `0.1` fixo. Em `game.gd`, no
`_ready()`, ponha `Engine.max_fps = 20` e rode; depois `Engine.max_fps = 144`.
Descreva a diferença. Volte o `exp` e repita: a diferença some?

> Minhas notas:

---

## Sprint 4: a IA como lista de prioridades (40 min)

`bot_brain.gd` não usa aprendizado de máquina. É uma **árvore de decisão
achatada**: a primeira regra verdadeira vence (leia o comentário no topo do
arquivo). Duas ideias importantes:

- **Pensar não é andar.** `_think()` roda a cada `bot_think_interval`
  (0,25 s, multiplicado pela dificuldade); `_steer()` roda todo quadro.
  Isso economiza CPU e cria um tempo de reação parecido com o humano.
- **Papéis** (`ATTACK`, `DEFEND`, `CAKE`) quebram a simetria: sem eles,
  os 8 bots tomariam a mesma decisão e iriam todos ao mesmo lugar.

**Experimento 4.1** [ ]: em `game.gd`, troque `BOT_ROLES` para oito
`BotBrain.Role.ATTACK`. Rode o modo teste (GUIA.md, "autoplay") por 5 min.
Mais ou menos pontos que o normal? Por quê?

**Experimento 4.2** [ ]: escreva uma regra nova: "se a minha vida está
abaixo de 25% e há uma Kitsune da Luz aliada (ela cura) a menos de 15 m, ir até ela". Onde na
lista ela deve entrar para não quebrar a prioridade 1?

> Minhas notas:

---

## Sprint 5: dados separados do código (20 min)

Abra `config/classes/guerreiro.tres` no Inspector. Os campos vêm de
`scripts/data/class_stats.gd` (`@export var ...`). Isso é o padrão
*data-driven*: o código define o **esquema**, o `.tres` guarda os
**valores**. Game designers mexem nos valores sem tocar no código.

**Exercício 5.1** [ ]: crie a classe "Lanceiro": copie `guerreiro.tres`,
aumente `attack_range`, diminua `damage`. Siga a linha "Classe nova" da
tabela do GUIA.md.

> Minhas notas:

---

## Para depois (versão de semanas)

Ideias para virar sprints futuros, quando quiser:

- Multijogador local (2 teclados) ou online: só um novo "cérebro".
- Catapulta e oficina de recursos (madeira/metal), como no jogo original.
- Mais mapas: `arena.gd` gerado a partir de um arquivo de dados.
- Árvore de comportamento ou *utility AI* no lugar da lista de prioridades.

> Minhas notas:
