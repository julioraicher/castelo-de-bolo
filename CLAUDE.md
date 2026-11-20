# CLAUDE.md

Contexto enxuto para o Claude trabalhar neste repo sem reler conversas antigas.
**Leia primeiro `docs/principios.md`** (o que não muda sem o Julio; este arquivo
não repete os princípios). Onde mora cada sistema: `docs/mapa-do-codigo.md`.
Todos os comandos: `docs/comandos.md`. Para humanos: GUIA.md. Plano: ROADMAP.md.
O que mudou: CHANGELOG.md (leia a entrada mais nova). Regras do jogo: CONTROLES.md.

## O que é

Jogo 3D de ação 8v8 com bots no estilo de *Fat Princess* (nome, arte e código
originais). Godot 4.7.2 + GDScript. Alvo: PC, navegador (Web) e .exe.
Dono: Julio (estudante de Engenharia Física). Respostas em português, diretas.

## Comandos do dia a dia

```bash
godot --headless --import --path .   # depois de criar class_name novo
tools/checar.sh regras|partida|rede|tudo   # as MESMAS checagens do CI (~1,5 min por grupo)
godot --headless --path . --fixed-fps 60 -- --autoplay --testes --semente=1234   # só regras
godot --headless --path . --fixed-fps 60 --quit-after 18000 -- --autoplay        # partida 5 min
tools/teste_sincronia.sh 90 7        # multiplayer: mesma semente em 60 x 23 FPS = mesmo SINC
tools/gerar_tudo.sh                  # todos os geradores de modelos/dados, na ordem certa
```

Godot não vem no container: baixe o zip 4.7.2 do GitHub releases para
/usr/local/bin/godot. CI (`.github/workflows/build.yml`): todo push roda
`tools/checar.sh` em 3 grupos paralelos (regras, partida, rede); qualquer
`SCRIPT ERROR` reprova. Na `main`, se passarem, exporta Web (GitHub Pages),
Windows/Linux (release `ultima-versao`) e itch.io (se configurado). Regra nova
que importa = um `_check` em `tests/regras.gd`.

## Arquitetura

- `scripts/game.gd`: monta tudo e aplica as regras por distância em `_rules()`.
- `scripts/actors/unit.gd`: corpo do soldado. `PlayerBrain`/`BotBrain` só
  preenchem `move_intent`, `aim_dir`, `wants_*` (princípio 4).
- Conteúdo é dado (`config/*.tres`, esquema em `scripts/data/*.gd`):
  - `game_config.tres`: regras, lista de classes do pátio, temas, mapa.
  - `classes/*.tres` (`ClassStats`): modelo, partes, chapéu, números, textos dos
    poderes. Personagem novo: checklist em `docs/mapa-do-codigo.md` (não é só o .tres).
  - `temas/*.tres` (`ThemeConfig`): luz, céu, neblina, chão, modelos (`{cor}`
    vira blue/red), `model_swaps`. Tema novo = copiar e pôr em `themes`.
  - `mapas/*.tres` (`MapLayout` + `MapProp`): arena, castelo, objetos.
  - `scripts/world/arena.gd` só monta o que esses arquivos descrevem.
  - Para gerar/alterar .tres com sub-recursos, prefira um script `-s` com
    `ResourceSaver.save()` a editar o texto à mão; gerador de .tres carrega o
    arquivo existente e só troca o que gera.
- Autoloads: `Config` (teclas, constantes, `CONTROLS`), `Settings` (preferências
  em `user://configuracoes.cfg`, gravadas 0,4 s depois da última mudança e ao
  fechar), `Sfx`, `Rede`.
- UI feita por código: `scripts/ui/hud.gd`, `scripts/ui/menus.gd` (navegação lateral:
  Começo, Como jogar = `tutorial.gd`, Classes = `pagina_classes.gd`, Controles,
  Configurações). Clipes dos menus: `tools/clipes_tutorial.sh` (cenas em `clipe_cenas.gd`).
- **Multiplayer (Ciclo 2.28)**: lockstep determinístico. Autoload `Rede`
  (`scripts/rede/rede.gd`: sala, ENet, UPnP, lista LAN, quadros, resumo a cada
  120 quadros); `Comando` (17 bytes de intenção) → `RedeBrain` no boneco do
  amigo; o humano local amostra com `PlayerBrain.amostrar` e também espera o
  quadro. Lobby = `scripts/ui/lobby.gd`. `Unit.humano` (regra: humano ou não)
  ≠ `is_player`/`game.player` (só o deste PC: câmera, HUD, som). Bots usam
  `game.time_tem_humano(t)`, nunca `time_jogador`, para regras de time.
  Conexão (2.28c): "Criar sala" = `Rede.criar_sala` (WebRTC; código sorteado;
  recados cifrados por `Sinal` no ntfy.sh). IP digitado e Sala de teste = ENet.

## Armadilhas já pagas (não repetir)

- Torreta 2.9 (2026-11-06): entrou como "lógica" e ganhou visual de primitivas
  sem pitaco. Peça visível segue o princípio 13 mesmo em thread de jogabilidade.
- `editor/export/convert_text_resources_to_binary` deve ficar **false**: a
  conversão perdia `visible_meshes` e os personagens ficavam invisíveis no export.
- Empurrão: velocidade de andar (`_move_vel`) e de empurrão (`_knock`) são
  separadas. Somar o empurrão à velocidade anterior o integra de novo a cada quadro.
- Modelo `.scn` gerado: salvar com `ResourceSaver.FLAG_COMPRESS` (7x menor, mesmo
  conteúdo; download web 104 → 43 MB). `tools/comprimir_cenas.gd` converte os antigos.
- Material billboard ignora escala: use `billboard_keep_scale = true`.
- `Label` com quebra de linha dentro de `GridContainer` vira uma letra por linha.
- Texto dentro de `Button` não faz o botão crescer: cartão com texto = `PanelContainer`
  (+ `gui_input`). Painel ancorado não encolhe sozinho: `reset_size()` ao trocar o
  conteúdo. Peça nova de interface: rode `tools/auditoria_ui.gd` (2.33).
- Texto na tela só com caracteres da fonte Nunito (★, ⚔, → viram quadrado; o
  teste de glifos reprova). Número de dano/cura = `Fx.damage_number` (respeita a
  opção); aviso de regra = `Fx.letreiro` (sempre aparece).
- Interpolação de física está ligada: teleporte chama `reset_physics_interpolation()`;
  nós animados em `_process`/tween usam `PHYSICS_INTERPOLATION_MODE_OFF`; o visual
  que segue um nó da física lê `get_global_transform_interpolated()`.
- Clique: `Input.is_action_just_pressed` também (clique curto cai entre dois
  quadros de física e `is_action_pressed` sozinho perde o golpe).
- Música: loop vem do `.import` (`loop_mode=2`); canais em `default_bus_layout.tres`.
- **Determinismo (multiplayer)**: toda regra roda igual em qualquer PC/FPS.
  Sorteio de regra = `Sorte.f()/r()/i()` (nunca `randf`/`pick_random`/`shuffle`
  global; esses só no visual); tempo de regra = `Sorte.ms()`/`tempo_partida`
  (nunca `Time.get_ticks_*`); tween/timer que muda regra roda na física
  (`create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)`,
  `create_timer(t, false, true)`); regra não lê transform de nó visual; nada de
  regra em `_process`. `is_player` só para câmera/HUD/som: regra que depende de
  "quem bateu é humano" usa `humano` (2.28d: hitstop só no PC de quem atirou
  separava a partida).
- Inferência `:=` falha com valores sem tipo (ex.: `surface_get_format`): tipar.
- Script de diagnóstico `-s`: não citar `Unit`/classes do jogo nem autoloads
  (`Config`) por nome: compila antes dos autoloads e quebra o `Unit`. Use
  variáveis sem tipo e `root.get_node("/root/Config")`.
- Na 4.7 um `SCRIPT ERROR` aborta só a função e o processo sai 0: por isso o
  `checar.sh` procura o texto e os testes contam erros (`tests/contador_erros.gd`).
- Referência a nó que pode sumir (dono de armadilha, alvo de fita): guardar o
  que a regra precisa no `setup` e checar `is_instance_valid` antes de usar.
- Animação só do tronco: `Unit._play_upper(anim)` (cópia filtrada, criada sob demanda).
- Desempenho: o PC/navegador do Julio rendeu 9-12 FPS (provável WebGL sem GPU).
  Existe `AutoQuality` (baixa qualidade sozinho). O gargalo é chamada de desenho
  (1 MeshInstance3D = 1 chamada por passe: cor, cada divisão de sombra, contorno),
  não script (~1,5 ms/quadro). Peça parada composta de várias malhas: terminar com
  `MalhaUnica.juntar(raiz, [o que se mexe])` (Ciclo 2.17); peças que dividem UM
  material (selo, emblema) = `Fx.montar_pecas` (já junta). Renderizador é
  Compatibility em todas as plataformas; não voltar para Forward+. Alta = FXAA +
  escala 0,9 + casca de contorno (`CascaContorno`) + Alta dinâmica
  (`AutoQuality.degrau`, mira 30 FPS); não reintroduzir MSAA. O llvmpipe do xvfb
  IGNORA MSAA e custo por pixel: nele compare chamadas/tris (CENSO), nunca FPS.

## Economia de tokens (detalhes: docs/economia-de-tokens.md)

- Arquivo grande (`unit.gd`, `game.gd`, `tools/gerar_*.gd`): subagente `explorador`
  ou Grep + leitura por trecho. Checagens: subagente `testador` (roda `checar.sh`)
  ou saída filtrada.
- CHANGELOG: só a entrada mais nova. Uma imagem por rodada (JPG, ≤1280 px).
- Avisar outra thread só quando ela depende disso, numa mensagem só.
- Thread por tarefa (não por papel); quiz ≤5 perguntas com a recomendada
  pré-marcada; resposta curta com o resto em arquivo; lote 3D com uma prancha
  no fim. Regras 11-17 em docs/economia-de-tokens.md.

# Compact instructions

Ao compactar, preserve: decisões do Julio, arquivos alterados, resultado dos
testes, pendências e o que espera aprovação. Descarte logs e saídas de comando.

## Fluxo de trabalho

Rodadas: Julio joga e manda feedback (áudio transcrito). Responder com lista
curta do que entendeu, fazer tudo, publicar, adicionar entrada no CHANGELOG.md
(com "O que testar", princípio 2). Conversas curtas: a cada poucas rodadas, nova
conversa a partir deste arquivo.

- **Modo teste (sandbox) espelha a `main`** (Julio, 2026-11-06): botão "Modo
  teste" na tela inicial, `?sandbox` na web, `--sandbox`. Lá tudo fica disponível
  o tempo inteiro: oficinas prontas, maquininhas no nível 2, torretas de pé,
  catapultas, chapéu em 1 s, Q/E/R/catapulta recarregando rápido (grupo "Modo
  teste" do `game_config.gd`; `Game._montar_sandbox`, `_regras_sandbox`). Feature
  nova na `main` = na mesma entrega, pronta no sandbox, e o CHANGELOG diz isso.
- Fase 1 = polimento (bugs, sensação, equilíbrio, desempenho). Features novas
  (recursos, oficinas, catapulta) são Fase 2, uma conversa por feature.
- Julio quer prints a cada marco.

## Organização (threads do projeto no Claude)

O Julio fala no chat principal (coordenador), que abre threads por tarefa. Cada
thread é uma sessão separada: o que ela não escrever no repo/memória se perde.

| Papel | Mexe em |
|---|---|
| Diretor Visual (personagens, cenário, efeitos, interface) | `config/classes/`, `config/temas/`, `config/mapas/`, `assets/`, `tools/gerar_*`, `scripts/actors/ninja_visual.gd` |
| Diretor de Jogabilidade (combate, física, IA, desempenho, testes) | `scripts/`, `tests/`, `config/game_config.tres`, `project.godot` |
| Estagiário de ideias (ideia solta → decisão → plano) | `docs/` (direção, ideias, princípios) |
| Estagiários pontuais (tendências, vídeo) | `docs/ideias.md`, pasta do projeto |

Skills do Julio úteis aqui (carregam sozinhas): `estagiario-de-ideias`,
`forjar-ideia`, `rodada-de-playtest`, `contexto-do-projeto`. Skills de Godot no
repo: `.claude/skills/`.

- Precisa mudar código ou pasta de outro papel? Faça a menor mudança possível
  e avise no CHANGELOG.
- Cada papel registra suas mudanças no CHANGELOG.md, com o papel no título.
  Entradas de ciclos antigos vão para `docs/changelog-antigo.md` (arquivar quando
  o CHANGELOG passar de ~1.000 linhas).
