# CLAUDE.md

Contexto enxuto para o Claude trabalhar neste repo sem reler conversas antigas.
**Leia primeiro `docs/principios.md`** (o que não muda sem o Julio).
Detalhes para humanos: GUIA.md. Plano: ROADMAP.md. O que mudou em cada rodada:
CHANGELOG.md (leia a entrada mais nova). Regras do jogo: CONTROLES.md.

## O que é

Jogo 3D de ação 8v8 com bots no estilo de *Fat Princess* (nome, arte e código
originais). Godot 4.7.2 + GDScript. Alvo: PC, navegador (Web) e .exe.
Dono: Julio (estudante de Engenharia Física). Respostas em português, diretas.

## Comandos

```bash
# Depois de criar um script com class_name novo (senão "Identifier not declared"):
godot --headless --import --path .
# Testes de regra (dano, carregador, esquiva, escudo, cura, empurrão, dados); sai 0/1:
godot --headless --path . --fixed-fps 60 -- --autoplay --testes
# Partida simulada sem janela (bots jogam pelo jogador; eventos no stdout):
godot --headless --path . --fixed-fps 60 --quit-after 18000 -- --autoplay
# Prints (precisa de xvfb; renderizador do navegador):
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy -- --autoplay --shots=DIR
# Exportar só os dados, sem templates, e inspecionar como no jogo publicado:
godot --headless --path . --export-pack "Linux" x.pck
godot --headless --main-pack x.pck -s diag.gd
```

CI (`.github/workflows/build.yml`): todo push roda os testes de regra e 5 min
simulados; na `main`, se passarem, exporta Web (GitHub Pages) e Windows/Linux
(release `ultima-versao`). Regra nova que importa = um `_check` em `tests/regras.gd`.
Godot não vem no container: baixe o zip 4.7.2 do GitHub releases para /usr/local/bin/godot.

## Arquitetura

- `scripts/game.gd`: monta tudo e aplica as regras por distância em `_rules()`.
- `scripts/actors/unit.gd`: corpo do soldado. **Cérebro decide, corpo executa**:
  `PlayerBrain`/`BotBrain` só preenchem `move_intent`, `aim_dir`, `wants_*`.
- **Tudo que é conteúdo é dado** (`config/*.tres`, esquema em `scripts/data/*.gd`):
  - `game_config.tres`: regras, lista de classes do pátio, temas, mapa.
  - `classes/*.tres` (`ClassStats`): modelo, partes visíveis, chapéu, números.
    Classe nova = copiar um .tres e pôr em `hat_class_list`. Sem código.
  - `temas/*.tres` (`ThemeConfig`): luz, céu, neblina, chão, modelos (`{cor}`
    vira blue/red), `model_swaps`. Tema novo = copiar e pôr em `themes`.
  - `mapas/*.tres` (`MapLayout` + `MapProp`): arena, castelo, objetos.
  - `scripts/world/arena.gd` só monta o que esses arquivos descrevem.
  - Para gerar/alterar .tres com sub-recursos, prefira um script `-s` com
    `ResourceSaver.save()` a editar o texto à mão.
- Autoloads: `Config` (teclas, constantes, `CONTROLS`), `Settings` (preferências
  em `user://configuracoes.cfg`), `Sfx`.
- UI feita por código: `scripts/ui/hud.gd`, `scripts/ui/menus.gd`.

## Armadilhas já pagas (não repetir)

- `editor/export/convert_text_resources_to_binary` deve ficar **false**: a
  conversão perdia `visible_meshes` e os personagens ficavam invisíveis no export.
- Empurrão: velocidade de andar (`_move_vel`) e de empurrão (`_knock`) são
  separadas. Somar o empurrão à velocidade anterior o integra de novo a cada quadro.
- Material billboard ignora escala: use `billboard_keep_scale = true`.
- `Label` com quebra de linha dentro de `GridContainer` vira uma letra por linha.
- Interpolação de física está ligada: teleporte chama `reset_physics_interpolation()`;
  nós animados em `_process`/tween usam `PHYSICS_INTERPOLATION_MODE_OFF`.
- Música: loop vem do `.import` (`loop_mode=2`); canais em `default_bus_layout.tres`.
- Inferência `:=` falha com valores sem tipo (ex.: `surface_get_format`): tipar.
- Script de diagnóstico `-s`: não citar `Unit`/classes do jogo nem autoloads
  (`Config`) por nome: compila antes dos autoloads e quebra o `Unit`. Use
  variáveis sem tipo e `root.get_node("/root/Config")`.
- Animação só do tronco: `Unit._play_upper(anim)` (cópia filtrada, criada sob demanda).
- Desempenho: o PC/navegador do Julio rendeu 9-12 FPS (provável WebGL sem GPU).
  Existe `AutoQuality` (baixa qualidade sozinho). xvfb aqui também é software:
  bom para comparar, não para medir FPS real.

## Economia de tokens (detalhes: docs/economia-de-tokens.md)

- Arquivo grande (`unit.gd`, `tools/gerar_*.gd`): subagente `explorador` ou Grep
  + leitura por trecho. Testes/partida: subagente `testador` ou saída filtrada.
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
curta do que entendeu, fazer tudo, publicar, adicionar entrada no CHANGELOG.md.
Conversas curtas: a cada poucas rodadas, nova conversa a partir deste arquivo.

## Organização (threads do projeto no Claude)

O Julio fala no chat principal (coordenador), que abre threads por ciclo. Cada
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
  e avise no CHANGELOG. Campo novo num `.tres` = campo novo no esquema em
  `scripts/data/`, com valor padrão que não quebre os arquivos existentes.
- Sempre `git pull --rebase origin main` antes de `git push`; nunca force push.
- Cada papel registra suas mudanças no CHANGELOG.md, com o papel no título
  (entradas antigas em `docs/changelog-antigo.md`).
- Cenário: `tools/gerar_cenario_ninja.gd` (+ `gerar_mapa_rio.gd`) gera tudo com o
  material `pintura.gdshader`: COLOR.a = oclusão, UV.x = vento, UV.y = desenho
  (0 liso, 1 tábuas, 2 telhas, 3 pedras, 4 reboco). Rode os dois depois de mudar.
- Visual: peças por código no esqueleto KayKit (`NinjaVisual`) + shader toon;
  pitaco por prancha (`tools/prancha_personagens.gd`). Ver docs/arte-personagens.md.

## Fluxo de testes e ideias (permanente)

- A `main` é o que o Julio testa: precisa estar **sempre jogável**.
- Coisa nova (cenário, poder, feature) vai num branch e só entra na `main`
  com aprovação do Julio ou quando estável (testes de regra + 5 min simulados).
- Toda entrega na `main` ganha um bloco **"O que testar"** na entrada do CHANGELOG.
- Ideias para futuras atualizações vão em `docs/ideias.md` (A = próxima, B = depois,
  C = talvez). Qualquer frente pode anotar; o Julio escolhe o que sobe.

## Preferências do Julio

- **Direção atual (Ciclo 2.2)**: `docs/direcao-ciclo-2.2.md` manda no visual
  (pintado estilo Fat Princess PS3, tom sombrio, poder no corpo, ~3,5 cabeças).

- Manter o dash/esquiva como está.
- Quer prints a cada marco e explicações com a física por trás.
- Fase 1 = polimento (bugs, sensação, equilíbrio, desempenho). Features novas
  (recursos, oficinas, catapulta) são Fase 2, uma conversa por feature.
