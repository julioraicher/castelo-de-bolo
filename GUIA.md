# Guia do código: Castelo de Bolo

Mapa para você entender o projeto e mudar coisas sem se perder. A ordem de
leitura sugerida está no fim.

## 1. Como rodar

1. Instale o **Godot 4.7** (versão "Standard", não a .NET): <https://godotengine.org/download>.
   É um executável só, sem instalador.
2. Abra o Godot, clique em **Importar**, escolha o `project.godot` desta pasta.
3. Aperte **F5**. Na primeira vez ele importa os modelos 3D (demora uns segundos).

Sem instalar nada: o link da versão web fica em *Settings > Pages* do
repositório, e o .exe fica em *Releases > Última versão*. Os dois são gerados
sozinhos a cada push (veja `.github/workflows/build.yml`).

**Modo de teste automático:** `godot --path . -- --autoplay --shots=/tmp/prints`
faz o seu soldado também ser controlado pela IA e salva prints aos 4, 15, 30,
50 e 75 s. Com `--headless --fixed-fps 60` a partida roda sem janela e mais
rápido que o tempo real, e os eventos (sequestros, pontos) aparecem no terminal.
Foi assim que o jogo foi testado e balanceado.

## 2. Ideias de engine que você precisa (5 minutos)

| Conceito | No Godot | Onde aparece aqui |
|---|---|---|
| **Game loop** | Cada nó pode ter `_process(delta)` (todo quadro) e `_physics_process(delta)` (60× por segundo, fixo). `delta` é o tempo desde o último passo. | Todo movimento usa `_physics_process`, então a física é igual em PC rápido ou lento. |
| **Nós e cenas** | Tudo é uma árvore de nós (`Node3D`, `Camera3D`, `Label`...). Uma cena é uma árvore salva em arquivo. | `scenes/main.tscn` tem um nó só; o resto é criado por código em `game.gd`. |
| **Recursos** | Arquivos de dados (`.tres`) editáveis no Inspector. | `config/` guarda TODOS os números de balanceamento. |
| **Sinais** | Eventos: um nó emite, outros escutam (`died.connect(...)`). | `Unit.died`, `Princess.state_changed`. |
| **Autoload** | Script global acessível de qualquer lugar. | `Config` (regras) e `Sfx` (sons). |
| **Corpo cinemático** | `CharacterBody3D` + `move_and_slide()`: você define a velocidade, o motor resolve colisões. | `Unit` (soldados). |
| **Navegação** | Uma malha de caminhos gerada a partir dos colisores; `NavigationAgent3D` acha a rota. | `Arena._bake_navigation()` e `BotBrain._steer()`. |

## 3. Mapa dos arquivos

```
config/
  game_config.tres        regras da partida, lista de classes, temas e mapa
  classes/*.tres          uma ficha por classe (vida, dano, velocidade, chapéu, animações)
  temas/*.tres            clima visual: luz, céu, neblina, chão, modelos
  mapas/*.tres            forma do mapa: castelo, torres, pedestais, objetos
scenes/main.tscn          cena principal (só o nó "Jogo" com game.gd)
scripts/
  game.gd                 regras: pegar princesa/bolo/chapéu, pontuar, vitória
  world/arena.gd          monta o mapa: chão, luz, castelos, muralhas, navegação
  actors/unit.gd          soldado: anda, ataca, esquiva, carrega, morre, renasce
  actors/princess.gd      princesa: estados (casa, carregada, caída) e peso
  ai/player_brain.gd      teclado + mouse -> intenções da Unit do jogador
  ai/bot_brain.gd         IA dos bots (lista de prioridades + papéis)
  items/cake.gd           bolo (visual feito com cilindros)
  items/hat_pad.gd        pedestal de chapéu (troca de classe)
  items/projectile.gd     flecha e magia
  fx/camera_rig.gd        câmera 3/4 com suavização e tremor
  fx/fx.gd                números de dano, faíscas, anel de cura
  ui/hud.gd               placar, vida, dicas, tela de vitória
  ui/menus.gd             tela inicial e menu de pausa (Controles/Configurações)
  autoload/config.gd      carrega o config, registra as teclas e a lista CONTROLS
  autoload/settings.gd    preferências do jogador (volume, dificuldade...), salvas em disco
  autoload/sfx.gd         toca sons
  data/*.gd               definem os campos dos arquivos .tres
tools/gerar_sons.py       sintetiza todos os sons e a música (Python puro)
assets/                   modelos KayKit (CC0) e sons gerados
.claude/skills/           manuais de Godot e game design para o Claude
```

## 4. A arquitetura em uma frase

**Cérebro decide, corpo executa.** `PlayerBrain` e `BotBrain` só preenchem
`move_intent`, `aim_dir` e `wants_attack` na `Unit`; a `Unit` não sabe se
quem a controla é humano ou bot. Por isso trocar um bot por um jogador
online, no futuro, é trocar só o cérebro.

## 5. Onde mexer para mudar X

| Quero... | Arquivo | O que mudar |
|---|---|---|
| Guerreiro mais forte | `config/classes/guerreiro.tres` | `damage`, `max_hp` |
| Partida mais longa | `config/game_config.tres` | `score_to_win` |
| Bolo engordar mais | `config/game_config.tres` | `fat_per_cake`, `fat_slowdown` |
| Mais/menos soldados | `config/game_config.tres` | `units_per_team` |
| Bots mais fáceis | `config/game_config.tres` | aumente `bot_think_interval` (ou só use Esc > Configurações > Dificuldade) |
| Câmera mais longe | `config/game_config.tres` | `camera_offset` |
| Trocar teclas | `scripts/autoload/config.gd` | `_setup_input()` e o texto em `CONTROLS` (aparece no menu e no [CONTROLES.md](CONTROLES.md)) |
| Nova opção de configuração | `scripts/autoload/settings.gd` + `scripts/ui/menus.gd` | variável + linha em `_settings_form()` |
| Mapa diferente | `config/mapas/vale.tres` | tamanho, muralhas, torres e `middle_props` |
| Classe nova (ex.: Espadachim) | copie `config/classes/guerreiro.tres`, mude nome, `visible_meshes` (ex.: `2H_Sword`), números e `hat_style`; adicione em `game_config.tres > hat_class_list` e um ponto em `mapas/vale.tres > hat_spots` |
| Clima novo (ex.: sinistro, neve) | copie `config/temas/sinistro.tres`, mude cores/modelos e adicione em `game_config.tres > themes` |
| Outro tipo de castelo | `config/temas/*.tres > Modelos` (quais modelos) e `config/mapas/vale.tres > Castelo` (posições) |
| Novo som | `tools/gerar_sons.py` + nome em `Sfx.SOUNDS` |

Dica: os `.tres` abrem no **Inspector** do Godot com campos agrupados
(Visual, Atributos, Animações). Mude, salve, F5.

## 6. A física por trás (para quem faz Engenharia Física)

- **Integração**: `move_and_slide()` aplica Euler semi-implícito no passo
  fixo de 1/60 s: v é atualizado antes de x. Projéteis usam Euler explícito
  `x += v·dt` mais um *raycast* entre x(t) e x(t+dt) para não atravessar
  paredes (o problema de *tunneling* quando `|v|·dt` é maior que a parede).
- **Aceleração limitada**: `velocity.move_toward(alvo, ACCEL·dt)` dá um tempo
  de resposta de `v_max / ACCEL` ≈ 0,1 s. É isso que deixa o controle "liso".
- **Suavização da câmera**: `lerp(a, b, 1 - e^(-k·dt))` é a solução exata de
  `dx/dt = k(b - x)` num passo dt, então o resultado não depende do FPS
  (um `lerp(a, b, 0.1)` fixo dependeria).
- **Screen shake**: amplitude ∝ trauma², com ruído coerente (Perlin) em vez de
  aleatório puro, para tremer sem "pular".
- **Peso da princesa**: velocidade do carregador = `v · c · (1 - g·f)`, com
  `f ∈ [0,1]` a gordura e `g = fat_slowdown`.
- **Karplus-Strong** (em `gerar_sons.py`): um buffer de ruído realimentado
  com a média de amostras vizinhas é um filtro passa-baixa em loop; o
  período do buffer define a frequência fundamental, como uma corda.

## 7. Ordem de leitura sugerida

1. `config/classes/guerreiro.tres` no Inspector (mude algo e jogue).
2. `scripts/game.gd` → `_ready()` (como tudo nasce) e `_rules()`.
3. `scripts/actors/unit.gd` → `_physics_process()`.
4. `scripts/ai/bot_brain.gd` → `_think()`.
5. `scripts/world/arena.gd` → `to_world()` e `_build_castle()`.

## 8. Usando o Claude neste projeto

A pasta `.claude/skills/` tem manuais de Godot e game design (de
[awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills),
Apache-2.0). Qualquer sessão do Claude Code aberta nesta pasta os carrega
quando a tarefa pede. Peça coisas como "adicione uma classe de mago de
fogo" ou "faça os bots desviarem de flechas".

Regras que não mudam: `docs/principios.md`. Para conferir que nada quebrou:
`godot --headless --path . --fixed-fps 60 -- --autoplay --testes` (testes de
regra em `tests/regras.gd`; o CI roda em todo push). Suas skills pessoais
(`rodada-de-playtest`, `forjar-ideia`, `estagiario-de-ideias`,
`contexto-do-projeto`) valem em qualquer projeto.
