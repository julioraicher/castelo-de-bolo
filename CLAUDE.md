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
# Desempenho (xvfb): PERF (fps, chamadas, tris, CPU por seção) + CENSO (passes por dono).
#   CENSO_DETALHE=Arena lista cada instância; MU_DEBUG=1 mostra os grupos da malha única.
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy --quit-after 600 -- --autoplay --perf=3
# Prints (precisa de xvfb; renderizador do navegador):
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy -- --autoplay --shots=DIR
# Prints de cada seção do menu e aba do Como jogar: --tutorial=DIR (com xvfb, como acima)
# Regravar os clipes dos menus (xvfb): tools/clipes_tutorial.sh [cena|classe:id ...]
#   (classe nova = id em CLASSES do script; quadros importam com perda, ~12 KB cada)
# QA do mapa (passagem, escondidos da câmera, bots presos): qa_mapa.txt (+ .jpg com tela)
godot --headless --path . --fixed-fps 60 -- --qa-mapa=DIR
# Chão/objeto piscando ao andar (z-fighting, desenho fino): pisca.jpg com o que muda em vermelho
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy -- --autoplay --sandbox --pisca=DIR
# Sons: trocar/ouvir/gerar efeitos = skill .claude/skills/efeitos-sonoros (tools/sons/)
# Equilíbrio por classe (8 partidas, mortes/abates por classe): tools/sonda_equilibrio.sh
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
- UI feita por código: `scripts/ui/hud.gd`, `scripts/ui/menus.gd` (navegação lateral:
  Começo, Como jogar = `tutorial.gd`, Classes = `pagina_classes.gd`, Controles,
  Configurações). Clipes dos menus: `tools/clipes_tutorial.sh` (cenas em `clipe_cenas.gd`).

## Armadilhas já pagas (não repetir)

- Torreta 2.9 (2026-11-06): entrou como "lógica" e ganhou visual de primitivas
  sem pitaco. Toda peça visível segue o princípio 13 (quiz, piloto com detalhe,
  animações), mesmo quando a thread é de jogabilidade.
- `editor/export/convert_text_resources_to_binary` deve ficar **false**: a
  conversão perdia `visible_meshes` e os personagens ficavam invisíveis no export.
- Empurrão: velocidade de andar (`_move_vel`) e de empurrão (`_knock`) são
  separadas. Somar o empurrão à velocidade anterior o integra de novo a cada quadro.
- Modelo `.scn` gerado: salvar com `ResourceSaver.FLAG_COMPRESS` (7x menor, mesmo
  conteúdo; download web 104 → 43 MB). `tools/comprimir_cenas.gd` converte os antigos.
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
  bom para comparar, não para medir FPS real. O gargalo é chamada de desenho
  (1 MeshInstance3D = 1 chamada por passe: cor, cada divisão de sombra, contorno),
  não script (~1,5 ms/quadro). Peça parada composta de várias malhas: terminar com
  `MalhaUnica.juntar(raiz, [o que se mexe])` (Ciclo 2.17); peças que dividem UM
  material (selo, emblema) = `Fx.montar_pecas` (já junta). Renderizador é
  Compatibility em todas as plataformas; não voltar para Forward+. Alta = FXAA +
  escala 0,9 + casca de contorno (`CascaContorno`) + Alta dinâmica
  (`AutoQuality.degrau`, mira 30 FPS); não reintroduzir MSAA. O llvmpipe do xvfb
  IGNORA MSAA e custo por pixel: nele compare chamadas/tris (CENSO), nunca FPS.

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
- Casas de chapéu (Ciclo 2.21, escada 2.22): `Oficina` = bairro da classe base
  (barraquinha + 2 tapetes com fantasma + casa do caminho). Nv1→2 só a barraquinha;
  Nv2→3 escolha (jogador: painel `Hud.abrir_escolha` com [F]; bots: tapete), a casa
  nasce no Nv3; Nv3→5 as duas sobem juntas. Super da classe travado no Nv1.
  Modelos em `tools/gerar_casas.gd` (estende `gerar_economia.gd`; rode depois de
  mudar; peças N3_/N4_/N5_ por nível), prancha em `tools/prancha_casas.gd`.
  Caminhos = `caminhos` no .tres da base.
- Heróis raros (Ciclo 2.23): Nv5→6 = segunda escolha, um herói de `herois` no .tres
  da base (Construtor não tem). Pavilhão dourado no tapete do caminho, 1 chapéu só,
  volta `heroi_retorno` s depois que o herói sai de campo. Regras em
  `scripts/actors/herois.gd` (ganchos de Unit), voo em `voo_heroi.gd`, bots em
  `scripts/ai/bot_herois.gd`, efeitos em `fx_herois.gd`. Gerar: `tools/gerar_herois.gd`
  (.tres), `tools/gerar_pavilhao.gd` (pavilhão, adornos, emblemas); prancha
  `tools/prancha_herois.gd`; sonda `HEROIS=1 tools/sonda_equilibrio.sh`. Relógio de
  15 min com empate e prorrogação enquanto houver máscara fora (`tempo_limite`).
  Heróis 2.27 (Ochimusha, Shishimai, Jorogumo; parte 2: Kodama, Kaminari-kozō):
  estados em `Herois._tick_2_27`/`_apanhar_2_27`; reações entre elementos em
  `scripts/actors/reacoes.gd` (quem solta fogo/vento chama `Reacoes.em` no impacto);
  teia no chão = `scripts/items/teia.gd`. Painel do pavilhão aceita até 5 heróis.
- Efeitos de poder: kit `Magia` (`scripts/fx/magia.gd`, shader `magia_energia`):
  energia com ruído que se rasga (`corroi`) + filete de tinta; nunca primitiva de
  cor chapada. Receita e orçamento em docs/direcao-efeitos.md §8; conferir com
  `tools/bancada_magia.gd` e `tools/vitrine.sh SAIDA [classes]`.
- Assinatura por personagem (Ciclo 2.24): kit `Assinatura` (`scripts/fx/assinatura.gd`).
  Selo com silhueta e verbo próprios, figura em pé no R, partícula com forma, hanko.
  Desenhos em `tools/assinaturas/desenhos.js` (gerar: `node tools/assinaturas/gerar.js`
  + `cinza.py`). Personagem novo ganha desenho + linha em `DADOS`; nunca reutilizar
  o selo de outro. Tabela em docs/direcao-efeitos.md §9 (atlas 7x7 desde o 2.27).
- Visual: peças por código no esqueleto KayKit (`NinjaVisual`) + shader toon;
  pitaco por prancha (`tools/prancha_personagens.gd`). Ver docs/arte-personagens.md.

## Fluxo de testes e ideias (permanente)

- A `main` é o que o Julio testa: precisa estar **sempre jogável**.
- Coisa nova (cenário, poder, feature) vai num branch e só entra na `main`
  com aprovação do Julio ou quando estável (testes de regra + 5 min simulados).
- Toda entrega na `main` ganha um bloco **"O que testar"** na entrada do CHANGELOG.
- **Modo teste (sandbox) espelha a `main`** (Julio, 2026-11-06): é a versão em que ele
  testa cada peça sozinho (botão "Modo teste" na tela inicial, `?sandbox` na web,
  `--sandbox`). Lá tudo fica disponível o tempo inteiro: oficinas prontas, maquininhas
  no nível 2, torretas de pé, catapultas, chapéu em 1 s, Q/E/R/catapulta recarregando
  rápido (grupo "Modo teste" do `game_config.gd`; `Game._montar_sandbox`,
  `_regras_sandbox`). Feature nova na `main` = na mesma entrega, deixá-la pronta e
  disponível no sandbox e dizer isso no CHANGELOG.
- Ideias para futuras atualizações vão em `docs/ideias.md` (A = próxima, B = depois,
  C = talvez). Qualquer frente pode anotar; o Julio escolhe o que sobe.

## Preferências do Julio

- **Direção atual (Ciclo 2.2)**: `docs/direcao-ciclo-2.2.md` manda no visual
  (pintado estilo Fat Princess PS3, tom sombrio, poder no corpo, ~3,5 cabeças).

- Manter o dash/esquiva como está.
- Quer prints a cada marco e explicações com a física por trás.
- **Peça nova na tela** (torreta, catapulta, casinha, personagem, item, efeito):
  princípio 13 de `docs/principios.md`. Quiz/prancha antes, piloto com silhueta
  própria + cor do time + animações parada/ação/fim, nunca primitivas como
  entrega. Vale também para threads de jogabilidade.
- Fase 1 = polimento (bugs, sensação, equilíbrio, desempenho). Features novas
  (recursos, oficinas, catapulta) são Fase 2, uma conversa por feature.
