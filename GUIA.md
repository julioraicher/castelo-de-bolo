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
  game.gd                 cérebro da partida: monta tudo e aplica as regras em _rules()
  world/arena.gd          monta o mapa a partir do MapLayout + ThemeConfig, navegação
  actors/unit.gd          soldado: anda, ataca, defende, Q/E, esquiva, carrega, morre
  actors/ninja_visual.gd  roupa ninja por código no corpo KayKit (estilo do .tres)
  actors/escala_ossos.gd  proporção (~3,5 cabeças) aplicada depois da animação
  actors/princess.gd      a Máscara Oni (nome antigo no código): estados e peso
  ai/player_brain.gd      teclado + mouse -> intenções da Unit do jogador
  ai/bot_brain.gd         IA dos bots (prioridades + papéis + quando usar Q/E)
  items/cake.gd           espírito solto (nome antigo no código); pesa a máscara
  items/hat_pad.gd        maquininha de chapéu (troca de classe, estoque)
  items/oficina.gd        terreno de oficina / caminho dos magos (obra e níveis)
  items/planta.gd, tora.gd, pilha.gd   ciclo da madeira do Construtor
  items/projectile.gd, trap.gd, pickup.gd   tiros, armadilhas, itens no chão
  fx/                     câmera, efeitos, poderes (fx_poder, area_effect, marca_chao,
                          arrow_rain), guia do Construtor, qualidade automática
  ui/                     HUD, menus, minimapa, estilo (fontes/cores), ícones
  autoload/config.gd      carrega o config, registra as teclas e a lista CONTROLS
  autoload/settings.gd    preferências do jogador, salvas em disco
  autoload/sfx.gd         toca sons
  data/*.gd               definem os campos dos arquivos .tres
tests/regras.gd           testes de regra (rodam no CI); qa_mapa.gd = QA do mapa
tools/gerar_*.gd          geram cenário, mapa e peças por código; prancha_*.gd = imagens de pitaco
tools/gerar_sons.py       sintetiza todos os sons e a música (Python puro)
assets/                   corpos KayKit (CC0), cenário ninja gerado (.scn), sons, fontes, shaders
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
| Mapa diferente | `config/mapas/rio_lanternas.tres` (gerado por `tools/gerar_mapa_rio.gd`) | tamanho, muralhas, torres e `middle_props` |
| Classe nova (ex.: Espadachim) | copie `config/classes/guerreiro.tres`, mude nome, `visible_meshes` (ex.: `2H_Sword`), números e `hat_style`; adicione em `game_config.tres > hat_class_list` e um ponto em `mapas/rio_lanternas.tres > hat_spots` |
| Clima novo (ex.: neve) | copie `config/temas/luar.tres`, mude cores/modelos e adicione em `game_config.tres > themes` |
| Outro tipo de castelo | `config/temas/*.tres > Modelos` (quais modelos) e `config/mapas/rio_lanternas.tres > Castelo` (posições) |
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
