# Mapa do código por sistema

Onde mora cada sistema que entrou ciclo a ciclo. O CLAUDE.md tem só a
arquitetura geral; leia daqui a seção do sistema em que vai mexer.

## Personagem novo (classe ou herói): checklist

"Copiar um .tres" é só o começo. Uma classe ou herói novo também passa por:

1. `config/classes/<id>.tres` (copiar um parecido): números, `skill`/`power`/`super_tipo`
   e os textos `skill_desc`, `power_desc`, `super_desc` (o teste de esquema reprova
   descrição vazia ou valor fora da lista), `personalidade` (um dos 8 jeitos).
   Classe do pátio: id em `hat_class_list` (`config/game_config.tres`). Herói: em
   `HEROIS` de `tools/gerar_herois.gd` e em `herois` no .tres da base.
2. Corpo: função `_<id>(time)` em `scripts/actors/ninja_visual.gd` (`_montar` chama
   pelo nome) e prancha `tools/prancha_personagens.gd` (princípio 13: pitaco antes).
3. Poder novo (valor novo de `skill`/`power`): enum em `scripts/data/class_stats.gd`,
   regra em `unit.gd`/`herois*.gd`, efeito pelo kit `Magia`, bot em `scripts/ai/`.
4. Assinatura: desenho em `tools/assinaturas/desenhos.js` + linha em `DADOS` de
   `scripts/fx/assinatura.gd` (nunca reutilizar o selo de outro).
5. Sons: nomes novos em `SOUNDS` de `scripts/autoload/sfx.gd`.
6. Casa/pavilhão: `BASES` de `tools/gerar_casas.gd` (classe base) ou
   `tools/gerar_pavilhao.gd` (herói); depois `tools/gerar_tudo.sh`.
7. Menus: id em `tools/lib/classes.sh` (lista única dos scripts de vídeo) e
   `tools/clipes_tutorial.sh classe:<id>`. O teste `_listas_de_classes` reprova se
   faltar o selo, o clipe ou a linha nos geradores (casas, heróis, pavilhão).
8. Testes: `POR_DESENHO` (`tests/varredura_poderes.gd`) se o poder não fere de
   propósito; `ESPERADO` (`tests/varredura_aliados.gd`) se cura/protege; `_check`
   em `tests/regras/<sistema>.gd` para a regra que importa. Rodar `tools/checar.sh tudo`.
9. Sandbox: o personagem precisa aparecer no modo teste na mesma entrega.

## Partida e boneco (revisão 3a)

- `scripts/game.gd`: monta a partida e aplica as regras por distância (`_rules()`;
  raios em `cfg.raio_*`, grupo "Raios das regras").
- `scripts/partida/modo_teste.gd` (`ModoTeste`, `Game.modo_teste`): tudo que só
  existe no modo teste (torretas de pé, aliado/Samurai/herói de treino,
  mostruário, teclas [M] [L] [N] em `regras()`) e na Arena de chapéus (fileiras,
  tambores, `nivel_arena`, `--arena-prova`). Peça nova no sandbox = aqui.
- `scripts/dev/ferramentas.gd` (`Ferramentas`): prints, filmes, vitrine, pisca,
  pranchas de reanimar/finalizar, `--perf` e CENSO. O Game só cria quando um
  desses argumentos aparece; modo novo de print = aqui, nunca no game.gd.
- Números: `GameConfig` (`config/game_config.tres`) para as regras gerais;
  `HeroisConfig` (`config/herois_regras.tres`, lido como `cfg.herois.X`) para
  os heróis raros.
- `Unit.yaw`: direção do corpo (regra; guardada em float32 para bater com o
  Node3D). O visual só copia; teste e regra mexem em `yaw`, nunca em
  `_visual.rotation`.
- Travas de ação: tabela `Unit.TRAVAS` (campo do estado -> `Trava.MAOS|Q|ER|DASH`)
  e `travado(acao)`. Estado novo que prende o boneco = uma linha na tabela
  (o teste `_travas` confere a tabela).
- Registro de poderes: enum de `class_stats.gd`, ramo da regra e ramo do bot
  conferidos pelo teste `_registro_poderes` (poder sem regra ou sem bot reprova).
- Canal no corpo caído ([F] segurado): `scripts/canal_no_corpo.gd`
  (`CanalNoCorpo`) é a base de `Reanimar` e `Finalizar` (busca, reserva de bot,
  anel e letreiro); a filha responde só o que muda.

## Peças do mundo (revisão 3b)

- Peça que um boneco põe no chão e some sozinha (teia, para-raios, poça, andaime,
  árvore do Kodama, estrepes e mina) = `extends PecaDoMundo`
  (`scripts/items/peca_do_mundo.gd`): `_iniciar(game, dono, grupo, vida, pos)` no
  setup, `sair()` para acabar (uma vez só; `_saindo()` + visual de saída),
  `dono_valido()`, `PecaDoMundo.limitar(arvore, dono, grupo, max)` (a mais antiga
  sai). Peça nova = filha + o grupo em `PecaDoMundo.GRUPOS`.
- Resumo da partida (SINC, `Game.hash_partes`): placar, um pedaço por boneco e um
  por tipo de estrutura (`Game.PARTES_MUNDO`: máscaras, torretas/catapultas,
  casas/maquininhas, chão, peças, tiros). Cada peça tem `hash_estado()` só com
  estado de regra. Estrutura nova com estado de regra = `hash_estado()` + entrar
  num desses pedaços.
- Golpe no arco: `Game.no_arco` e `Game.mais_perto_no_arco` (plantas, árvore,
  andaime; a torreta usa `no_arco`). Obra: `Game.ritmo_obra(time, pos, raio,
  parado_vel)` (bairro, torreta, maquininha); raios em `cfg.raio_obra_*`.
- Leituras públicas da Unit para as peças: `defende_de(dir)`, `escondido()`,
  `em_casulo()`, `veste(cls)`. Mira da torreta = `Torreta.mira_y` (regra; o nó
  da besta só copia).

## Cenário

`tools/gerar_cenario_ninja.gd` (+ `gerar_mapa_rio.gd`) gera temas e peças com o
material `pintura.gdshader`: COLOR.a = oclusão, UV.x = vento, UV.y = desenho
(0 liso, 1 tábuas, 2 telhas, 3 pedras, 4 reboco). Depois de mudar, rode
`tools/gerar_tudo.sh` (a ordem dos geradores importa; ver docs/comandos.md).

## Casas de chapéu (Ciclo 2.21, escada 2.22)

`Oficina` = bairro da classe base (barraquinha + 2 tapetes com fantasma + casa do
caminho). Nv1→2 só a barraquinha; Nv2→3 escolha (jogador: painel
`Hud.abrir_escolha` com [F]; bots: tapete), a casa nasce no Nv3; Nv3→5 as duas
sobem juntas. Super da classe travado no Nv1. Modelos em `tools/gerar_casas.gd`
(estende `gerar_economia.gd`; peças N3_/N4_/N5_ por nível, dona de
`maquina_<classe>`), prancha em `tools/prancha_casas.gd`. Caminhos = `caminhos`
no .tres da base.

## Heróis raros (Ciclo 2.23 em diante)

Nv5→6 = segunda escolha, um herói de `herois` no .tres da base. Pavilhão dourado
no tapete do caminho, 1 chapéu só, volta `heroi_retorno` s depois que o herói sai
de campo. Regras em `scripts/actors/herois.gd` (ganchos de Unit; lista dos
supers próprios em `Herois.super_proprio`), voo em `voo_heroi.gd`, bots em
`scripts/ai/bot_herois.gd`, efeitos em `fx_herois.gd`. Gerar: `tools/gerar_herois.gd`
(.tres), `tools/gerar_pavilhao.gd` (pavilhão, adornos, emblemas); prancha
`tools/prancha_herois.gd`; sonda `HEROIS=1 tools/sonda_equilibrio.sh`.

- Relógio de 20 min (2.31): último minuto com máscaras leves, prorrogação
  enquanto a máscara fora ainda empata ou vira (`tempo_limite`, `ultimo_minuto_leve`).
- Ochimusha, Shishimai, Jorogumo (2.27): estados em `Herois._tick_2_27`/`_apanhar_2_27`;
  reações entre elementos em `scripts/actors/reacoes.gd` (quem solta fogo/vento
  chama `Reacoes.em` no impacto); teia no chão = `scripts/items/teia.gd`. Painel do
  pavilhão aceita até 5 heróis.
- Kodama, Kaminari-kozō (2.27b): regras em `scripts/actors/herois_natureza.gd`
  (carga, descarga em cadeia, molhado conduz), árvore = `scripts/items/arvore_kodama.gd`
  (StaticBody no LAYER_WORLD: bloqueia passagem e tiro), baqueta = `para_raios.gd`,
  efeitos em `scripts/fx/fx_natureza.gd` (malhas no material pintado do tema).
- Predero (2.30, único herói do Construtor): regras em `scripts/actors/herois_obra.gd`
  (encachaçado, derrapa = ACCEL × poca_atrito), poça = `items/poca_cachaca.gd`
  (fogo de qualquer time acende via `Reacoes`), andaime = `items/andaime.gd`
  (LAYER_WORLD), projétil "garrafa" em `projectile.gd`, efeitos em `fx/fx_obra.gd`.

## Efeitos

- Poderes: kit `Magia` (`scripts/fx/magia.gd`, shader `magia_energia`): energia com
  ruído que se rasga (`corroi`) + filete de tinta; nunca primitiva de cor chapada.
  Raio/faísca = `Magia.raio` (uma malha só; `Fx.zap` e `FxNatureza.raio` usam).
  Rastro = `Fita` (comprimento em tempo, não em quadros). Receita e orçamento em
  docs/direcao-efeitos.md §8; conferir com `tools/bancada_magia.gd` e
  `tools/vitrine.sh SAIDA [classes]`.
- Texto flutuante: `Fx.damage_number` só para números de dano/cura (respeita a
  opção "números de dano"); aviso de regra ("CONTRA!", "ESQUIVA!") = `Fx.letreiro`,
  sempre visível. Todo `Label3D` nasce em `Estilo.letreiro_3d(texto, tam, o)`
  (fonte, contorno de tinta, billboard; revisão 3c).
- Base comum do kit (revisão 3c): `FxBase` (`scripts/fx/fx_base.gd`) = cache de
  recurso por chave (prefixo do kit: "magia/", "fx/", "projetil/", "poder/"),
  `no`/`malha`, `g`/`tremer` (efeito de boneco e tremor), `enfeite`/`qtd` (portão
  da qualidade Mínima). Kit novo usa isso, não escreve o seu.
- Malha pintada (cor por vértice no `pintura.gdshader`: COLOR.a = oclusão, UV.x =
  vento, UV.y = desenho): `MalhaPintada` (`material(g)`, `vertice`, `tri`, `tubo`,
  `bola`, `corda`, `caixa`, `placa`, `aro`, `circulo`, `novo`/`fim`). Juntar peças
  soltas numa malha = `MalhaUnica.pecas([[malha, xf]])` (ou `[malha, xf, cor]`
  para cor por vértice sem normal); cena inteira parada = `MalhaUnica.juntar`.
- Variantes de shader são arquivos: o corpo mora em `.gdshaderinc` com `#ifdef`
  e a variante só faz `#define` (`magia_energia_atras`, `assinatura_selo_frente`).
  Shader ou variante nova entra no `Fx.prewarm` (o navegador compila no 1º uso e
  travava o primeiro poder).
- Peças pequenas do chão (Ciclo 2.32): espírito (`Cake`), itens (`Pickup`) e
  armadilhas (`Trap`) desenham pelo kit `FxItens` (`scripts/fx/fx_itens.gd`):
  objeto = ArrayMesh com cor por vértice no material pintado, energia = shader
  Magia, anel do chão = `FxItens.anel_chao`. Prancha `tools/prancha_itens.gd`;
  no modo teste há um mostruário com os 5 itens e um espírito.
- Assinatura por personagem (Ciclo 2.24): kit `Assinatura` (`scripts/fx/assinatura.gd`).
  Selo com silhueta e verbo próprios, figura em pé no R, partícula com forma, hanko.
  Desenhos em `tools/assinaturas/desenhos.js` (gerar: `node tools/assinaturas/gerar.js`
  + `cinza.py`). Tabela em docs/direcao-efeitos.md §9 (atlas 7x7 desde o 2.27).
- Texto na tela: só caracteres que a fonte Nunito tem (o teste de glifos reprova
  ★, ⚔, ⚑, →, ✓ e afins nas strings de `scripts/`).

## Personalidade e finalização (Ciclo 2.34)

`ClassStats.personalidade` (8 jeitos: pesado, samurai, ninja, atirador, trapalhao,
curioso, sereno, predador; dados em `scripts/actors/personalidade.gd`) muda
parado, corrida, pouso do dash (pose ~0,4 s sem travar controle; o dash em si não
muda) e o golpe de finalização. Pose de peito/cabeça/braços = `PoseDash`
(SkeletonModifier3D). Finalizar herói caído ([F] 0,8 s, nega o Reanimar) =
`scripts/finalizar.gd` (roda antes do Reanimar.tick). Prancha:
`--prancha-finalizar=DIR` (xvfb).

## Visual dos personagens

Peças por código no esqueleto KayKit (`NinjaVisual`) + shader toon; pitaco por
prancha (`tools/prancha_personagens.gd`). Ver docs/arte-personagens.md.

## Testes

`tools/checar.sh` agrupa tudo (é o que o CI e o agente `testador` rodam).
`tests/contador_erros.gd` (Logger) conta erros de script durante os testes e
reprova; `tests/regras.gd` exige um mínimo de checagens (`MIN_CHECAGENS`) para
um teste pulado não passar despercebido. Regra nova que importa = um `_check`.

- Testes de regra (revisão 3e): um arquivo por sistema em `tests/regras/`
  (dados, combate, poderes, economia, partida, reanimar, itens, herois, sistema),
  todos `extends "res://tests/lib/caso.gd"` (`_check`, `_por`, `_perto`, `cfg`,
  `game`). `tests/regras.gd` só chama na `ORDEM` (importa: o estado da partida é
  um só; o relógio vai por último) e imprime o tempo de cada arquivo. Teste novo
  = função no arquivo do sistema + uma linha na `ORDEM`.
- Bots parados durante os testes (`BotBrain.parado`): o resultado não depende de
  onde eles andaram nem da semente. Teste que precisa da IA chama o cérebro
  direto (ex.: `_bots_herois` chama `BotHerois.rapida/poder/super_r`).
- Boneco descartável: `tests/lib/bonecos.gd` (`criar`, `limpar`), o mesmo nas
  regras e nas duas varreduras.
- QA do mapa: `tests/qa_mapa_base.txt` guarda os números de hoje; o
  `checar.sh` avisa só quando algum tipo piora. Problema consertado = baixar a base.
- Rede: `tools/lib/sinc.sh` (`pega_sinc`, `compara_sinc`, `pasta_temporaria`);
  cada teste usa a sua pasta (`mktemp -d`), então podem rodar juntos.
