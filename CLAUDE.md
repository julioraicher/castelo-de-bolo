# CLAUDE.md

Contexto enxuto para o Claude trabalhar neste repo sem reler conversas antigas.
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
# Partida simulada sem janela (bots jogam pelo jogador; eventos no stdout):
godot --headless --path . --fixed-fps 60 --quit-after 18000 -- --autoplay
# Prints (precisa de xvfb; renderizador do navegador):
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy -- --autoplay --shots=DIR
# Exportar só os dados, sem templates, e inspecionar como no jogo publicado:
godot --headless --path . --export-pack "Linux" x.pck
godot --headless --main-pack x.pck -s diag.gd
```

CI (`.github/workflows/build.yml`): todo push na `main` exporta Web (GitHub Pages)
e Windows/Linux (release `ultima-versao`). Push direto na `main` é o fluxo combinado.

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
- Desempenho: o PC/navegador do Julio rendeu 9-12 FPS (provável WebGL sem GPU).
  Existe `AutoQuality` (baixa qualidade sozinho). xvfb aqui também é software:
  bom para comparar, não para medir FPS real.

## Fluxo de trabalho

Rodadas: Julio joga e manda feedback (áudio transcrito). Responder com lista
curta do que entendeu, fazer tudo, publicar, adicionar entrada no CHANGELOG.md.
Conversas curtas: a cada poucas rodadas, nova conversa a partir deste arquivo.

## Preferências do Julio

- Manter o dash/esquiva como está.
- Quer prints a cada marco e explicações com a física por trás.
- Fase 1 = polimento (bugs, sensação, equilíbrio, desempenho). Features novas
  (recursos, oficinas, catapulta) são Fase 2, uma conversa por feature.
