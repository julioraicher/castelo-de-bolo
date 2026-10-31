# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.
Entradas até a Rodada 19 estão em `docs/changelog-antigo.md`.


## Planejamento (2026-10-31), estagiário de ideias: Ciclo 2.3 aberto
- Pedido do Julio (2 áudios): chapéus saindo de maquininhas animadas, limite
  de chapéus, madeira/bambu com árvores de 3 estágios, Construtor simples
  (coleta, volta, upa casinha) com contador "faltam X", QA automático do
  mapa; sem poderes novos no chão.
- Novo `docs/direcao-ciclo-2.3.md`: regras com números iniciais e o porquê
  (vazão do Construtor, teoria de filas do estoque de chapéus), QA automático
  do mapa, piloto e instruções/contrato para os dois diretores.
- ROADMAP: Ciclo 2.3 e 2.4 na Fase 2; metal/pedra e Ninja vs Cowboys na Fase 3.
  `docs/ideias.md`: Ninja vs Cowboys em C.
- **O que testar**: nada no jogo (só documentos).

## Organização (2026-10-31), estagiário de ideias: economia de tokens
- Pedido do Julio: rever boas práticas de economia de tokens para um projeto
  deste tamanho (modelo por agente, skills, organização) e aplicar.
- Novo `docs/economia-de-tokens.md`: o que gasta de verdade (contexto ×
  mensagens), modelo e esforço recomendados por papel, 10 regras para agentes.
  Fonte: documentação oficial do Claude Code (custos e modelos), lida hoje.
- Subagentes baratos em `.claude/agents/` (Haiku, esforço baixo):
  `explorador` (acha coisas em arquivos grandes sem lê-los inteiros) e
  `testador` (roda testes/partida e devolve só as falhas).
- `.claude/settings.json`: bloqueia leitura de binários e cache (`.godot/`,
  `.glb`, `.bin`, `.scn`, `.wav`, `build/`), que só gastariam tokens.
- CLAUDE.md: seção curta de economia + instruções de compactação.
- **O que testar**: nada no jogo.

## Organização (2026-10-31), estagiário de ideias: boas práticas e testes de regra
- Pedido do Julio: revisar o projeto com o que aprendemos dos repositórios de
  agentes (BMAD, Spec Kit e outros; comparativo no Claude Doc do projeto) e aplicar.
- **Testes de regra** (`tests/regras.gd`, flag `--testes` em `game.gd`): 68
  conferências dentro de uma partida real (dano, carregador leva metade, dash
  anula dano, escudo absorve, cura não passa do máximo, empurrão freia
  40 m/s² e 8 m/s → 0,8 m, todas as classes/temas/mapas do game_config válidos).
  Rodam no CI antes da partida de 5 min; se uma regra quebrar, a main não publica.
  Conferido que pegam erro: mudar KNOCK_DECAY para 30 reprova.
- **`docs/principios.md`**: as regras que não mudam num arquivo só (ideia da
  "constituição" do Spec Kit). CLAUDE.md manda ler primeiro.
- CLAUDE.md com a organização atual (diretores/estagiários e o que cada um
  mexe), comando de teste e skills; ROADMAP atualizado; GUIA seção 8.
- CHANGELOG encurtado: Rodadas 1 a 19 em `docs/changelog-antigo.md`.
  `docs/ideias-futuras.md` virou a seção "Outros projetos" de `docs/ideias.md`.
- Outros papéis: `scripts/game.gd` ganhou só a flag `--testes` (não muda o jogo).
  `projectile.gd`: projétil com velocidade zero não chama mais `look_at` (erro
  "origin and target are in the same position" reprovou a partida simulada do
  CI uma vez; raro, não reproduziu em 4 partidas locais).
- **O que testar**: nada novo no jogo; jogue normal. Se quiser, veja o CI no
  GitHub (Actions): o passo "Testes de regra" aparece antes da partida simulada.

## Ciclo 2.2, rodada 3 + piloto 2 (2026-10-30), frente Visual: ninjas com poder no corpo, pátio à vista e casas que funcionam
- Pedidos do Julio: "pegada mais sombria, ninjas com poder junto"; a oficina de
  chapéus ficava atrás da torre principal e a câmera não via; casas "quadradas e
  bobinhas", com vontade de manivelas, engrenagens e animação. Pranchas
  personagens/07, cenario/12 e o vídeo cenario/12b aprovadas ("aplique tudo").
- **Ninjas**: cabeça 0,58, mãos e pés 1,3, pernas +20% (~3,5 cabeças; o KayKit
  tinha ~2,5). Marcas pelo corpo que ficam apagadas sem poder, acendem enquanto
  a barra enche e, cheia, selos e olhos brilham na cor do time
  (`toon_time.gdshader`: `usar_marcas`, posição de repouso em CUSTOM0; o
  `poder_carga` da Jogabilidade não mudou). `ClassStats.escala_extremidades`.
- **Pátio**: nada de jogo atrás da torre principal nem na frente da escada da
  muralha (a câmera olha de cima a ~48°: uma torre de 6 m esconde ~5,5 m atrás
  dela). Oficinas em (-3,5, ±7), chapéus em (7 e 2,5, ±9,2); o pedestal da
  variação pronta aparece ao lado da oficina, do lado do portão.
- **Peças que giram** sem custo de CPU: nós `Gira_*` nos modelos, girados no
  shader (UV2 = velocidade e vaivém; `relogio` substitui o TIME). Engrenagens
  com o mesmo passo engrenam de verdade (velocidade na razão dos dentes).
  O Arena tira essas peças da junção do cenário e junta as iguais num MultiMesh.
- **Oficina de chapéus nova** (`oficina_{cor}`, `ThemeConfig.oficina_model`):
  martelo batendo no chapéu, engrenagens com manivela, catavento e chapéu-placa;
  as engrenagens andam na velocidade da obra (mais Construtores, mais rápido) e
  o telhado cai do céu quando fica pronta.
- **Casa da roda d'água** (`casa_moinho` e `casa_moinho_esq`, espelhada) no lugar
  da casa de fazenda na vila: caixa d'água, roda, engrenagens, manivela e pilão
  de arroz. Poço com sarilho e manivela, forja com pedra de amolar e fole, loja
  com catavento de papel. Toda caixa grande dos modelos ganhou quina chanfrada
  (menos cara de bloco).
- Outras frentes (mudança mínima, combinada com a Jogabilidade): `unit.gd`
  (passa `escala_extremidades`), `oficina.gd` (modelo do tema, relógio das
  engrenagens, posição do pedestal), `arena.gd` (peças `Gira_*`), `game.gd`
  (`--vista=patio`). Ferramentas: `tools/prancha_poder.gd`, `prancha_patio.gd`
  (`--alvo=X,Z`), `prancha_mecanica.gd`, `montar_mecanica.py`.
- Testes: 5 min simulados sem erro de script; 22 destravadas de bot (antes 42).
- **O que testar**:
  - Os ninjas com cabeça menor e mãos/pés maiores: a silhueta ficou boa no jogo?
    Encha o Chi e veja as marcas acenderem e os olhos brilharem quando está cheio.
  - No pátio, as duas oficinas aparecem sem esconder nada? Com um Construtor,
    as engrenagens giram mais rápido quanto mais gente trabalha?
  - Na vila, a casa da roda d'água (dos dois lados do rio), o poço, a forja e o
    catavento da loja estão girando? Algum lugar ficou apertado para passar?
  - O FPS na Média ficou igual ao de antes?

## Ciclo 2.2, rodada 2b (2026-10-30), frente Visual: desempenho do cenário pintado
- A Jogabilidade mediu a rodada 2 na Média: +32% de chamadas de desenho e +93%
  de triângulos (o orçamento da direção é ~10%).
- Causas e correções (`scripts/world/arena.gd`, só cenário):
  - O material pintado não entrava na junção do cenário em pedaços; agora entra,
    e as cópias iguais do material (cada .scn salva a sua) viram uma só.
  - O contorno de tinta do cenário desenhava tudo de novo, inclusive na sombra:
    agora só na qualidade Alta.
  - Enfeite (capim, flores...): 100% na Alta, 60% na Média, 35% na Baixa
    (`visible_instance_count`, troca na hora).
- Medida aqui (xvfb, Média, 26 s, mesma régua para as duas): antes desta correção
  541 chamadas e 1,37 milhão de triângulos; depois 344 e 620 mil (−36% e −55%),
  abaixo do que era antes do Ciclo 2.2 na mesma proporção.
- **O que testar**: o FPS na Média voltou ao de antes? Na Alta, o contorno do
  cenário aparece; na Média, não.

## Ciclo 2.2, rodadas 1 e 2 (2026-10-30), frente Visual: estilo pintado em todo o cenário e mapa mexido
- Pedido do Julio: o jogo estava "quadrado, liso e vazio"; o piloto (pranchas
  cenario/10 e 10b) mostrou o caminho e ele pediu para "mudar bem o mapa" e
  publicar tudo junto para jogar.
- **Material pintado em todas as peças** (`assets/shaders/pintura.gdshader`):
  pincel de baixa frequência em espaço de mundo, oclusão pintada (COLOR.a),
  luz em faixas suaves, sombra fria, borda clara pro sol, vento por vértice
  (UV.x) e desenho do material (UV.y: tábuas, telhas, pedras, reboco) com
  antisserrilhado por `fwidth`. Peças antigas recebem o desenho pela cor da
  paleta (`_desenho_pela_cor`).
- **Contorno de tinta** nas construções e objetos (o `contorno.gdshader` dos
  bonecos como next_pass); enfeite miúdo, água e paisagem distante ficam sem.
- **Casa comum nova** (`casa_a`: chanfros, tábuas tortas, telhado curvo que cede,
  porta baixa, barril, lenha, vaso, varal, corvo) e **lanterna de pedra nova**
  (velha, inclinada, com musgo). Árvores, capim e flores balançam no vento.
- **Chão pintado** (`assets/shaders/chao_pintado.gdshader`): grama em manchas e
  a estrada desenhada com borda irregular (sai a malha de estrada separada).
  Enfeite do Festival ao Sol quase dobrou.
- **Tema novo Crepúsculo (sombrio)** em Esc > Configurações > Tema (paleta
  `crepusculo` no gerador). Festival ao Sol continua o padrão.
- **Mapa Rio das Lanternas mexido**: bosques de sakura no lugar dos jardins de
  pedra, feira de barracas na boca da ponte grande e arrozais com espantalho nos
  campos de fora das muralhas.
- Ferramentas: todo o construtor (chanfro, viga, superfície curva, oclusão,
  vento) está em `tools/gerar_cenario_ninja.gd`; prancha da casa em
  `tools/prancha_piloto.gd` + `tools/montar_piloto.py`.
- Outras frentes: `scripts/world/arena.gd` (só o material do chão) e
  `config/game_config.tres` (tema na lista). Navegação: 42 destravadas de bot
  em 5 min simulados (antes 33-58), sem erro de script.
- **O que testar**:
  1. Ainda parece quadrado, liso e vazio? Olhe as casas, telhados, pedras e chão.
  2. O contorno de tinta no cenário combina com o dos ninjas?
  3. Esc > Configurações > Tema > Crepúsculo: o clima sombrio funciona para jogar?
  4. Bosques, feira e arrozais: atrapalham ou ajudam a luta e a fuga?
  5. FPS comparado com antes (o contorno dobra as chamadas de desenho do cenário).

## Rodada 21 (2026-10-30), frente Jogabilidade: animação exagerada e poder no corpo
- Direção do Ciclo 2.2, seção 9 (Diretor de Jogabilidade, itens 1 e 3).
- **Corpo de desenho** em `unit.gd` (`_tick_corpo`), sem mexer nos clipes: duas
  molas amortecidas (ω = 26 rad/s, ζ = 0,32: passa do ponto e volta em ~0,3 s)
  esticam/amassam o boneco na vertical e para a frente, com volume constante
  (sx·sy·sz = 1, como massa de modelar). Recebem "petelecos" em:
  - **Golpe**: antecipação de 50 ms (encolhe e recua; o dano sai depois dela,
    alinhado com o braço) e esticão para a frente no golpe; o final do combo estica mais.
  - **Dash**: esticão na saída, amassa no "pouso".
  - **Pulo/lançamento**: sai esticado, pousa amassado na proporção da queda.
  - **Andar**: quique de um pulinho por passo, em fase com o clipe de corrida.
  - **Apanhar**: amassa e treme ~0,2 s (o tremor continua durante o hitstop).
  - **Morte cômica**: "boing", pulinho girando uma volta, vira panqueca com
    poeira e estrelinhas.
  - Intensidade: `GameConfig.exagero_animacao` (1,4; 0 desliga) ×
    `ClassStats.exagero` por classe (1 em todas por enquanto).
- **Poder no corpo** (para o Visual usar): `toon_time.gdshader` ganhou
  `instance uniform poder_carga` (0..1, mandado pelo `Unit._tick_aura` só
  quando muda 2%) e `cor_poder` (= cor do chapéu). Por enquanto o contraluz
  acende com o medidor, puxa para a cor da classe e pulsa quando o [Q] está pronto.
- **Teste de fumaça no CI** (achado do estagiário, aprovado): todo push em
  qualquer branch roda 5 min de partida simulada; erro de script reprova e,
  na main, o export só sai se ele passar.
- Ferramenta: `-- --autoplay --filme=PASTA` grava o jogador fazendo golpe,
  dash, pulo, pancada e morte de lado, quadro a quadro (prancha 02 da Jogabilidade).
- Desempenho (`--perf=1`, Média, mesmo trecho): sem diferença mensurável
  (física 3,2 → 3,3 ms; draw calls e triângulos iguais dentro do ruído).
- Teste: 5 min simulados com `--poderes`, sem erro.
- Outras frentes: `assets/shaders/toon_time.gdshader` (2 uniforms novos,
  padrão sem efeito visível com medidor vazio) e `.github/workflows/build.yml`.
- **O que testar**:
  1. Bater, dar dash e apanhar: o boneco estica e amassa? Está exagerado
     demais, de menos ou no ponto? (dá para ajustar um número só)
  2. O golpe ficou "atrasado"? A antecipação é de 50 ms.
  3. Morrer: o pulinho girando com panqueca ficou engraçado ou atrapalha?
  4. Encher o Chi: o contorno do boneco acende e pulsa quando o [Q] está pronto?

## Ciclo 2.2 (2026-10-30), estagiário de ideias: direção nova (só documentos)
- Pedido do Julio: o jogo está "quadrado, liso, vazio"; aproximar do Fat
  Princess de PS3 e dar uma pegada mais sombria, com ninjas que mostram o
  poder no corpo. Quiz respondido e direção aprovada.
- Novo `docs/direcao-ciclo-2.2.md`: diagnóstico, decisões (proporção ~3,5
  cabeças, textura pintada de baixa frequência, enfeite, vento, luz de
  crepúsculo, marcas de poder), piloto (casa + lanterna no nível máximo, resto
  só com a camada global) e ordem de trabalho dos Diretores Visual e de
  Jogabilidade.
- Atualizados para bater com ela: `docs/identidade.md`,
  `docs/arte-personagens.md`, `docs/ideias.md`, `ROADMAP.md`, `CLAUDE.md`.
- Nada mudou no jogo. **O que testar**: nada; é só leitura.

## Rodada 20 (2026-10-29), frente Visual: cara de Fat Princess original e mapa único
- Pedido do Julio: chegar mais perto do visual do Fat Princess original (PS3,
  colorido, de dia, grama viva com flores) e menos do Adventures (PS4);
  um mapa só por enquanto, menos apertado; poderes no chão mais claros e
  nada de círculo simples.
- Tema novo **Festival ao Sol (dia)**, agora o padrão (`config/temas/dia.tres`,
  modelos em `assets/ninja/dia/`, paleta "dia" em `tools/gerar_cenario_ninja.gd`):
  céu azul, sol quente, grama verde-viva, telhados laranja, água azul, árvores
  redondas verdes e tufos de tulipas de desenho (`flores.scn`, `flores_b.scn`).
  Floresta Oni e Templo ao Luar continuam em Configurações > Tema.
- Mapa único: só o Rio das Lanternas (`game_config.maps`). A segunda fileira de
  casas da vila virou jardim e árvore; ficam a forja e a casa de chá. Mais
  campo aberto atrás das casas para brigar e fugir.
- Marcas de poder no chão (`scripts/fx/marca_chao.gd`, `MarcaChao`): um shader
  desenha o símbolo de cada poder de área, com um aro fino na cor do time e a
  borda que **esvazia como um relógio** até o poder acabar:
  - Bombas de Fumaça: borda de pincel de tinta e manchas de tinta girando.
  - Selo (Onmyoji): estrela de 5 pontas e anel de "escrita" correndo.
  - Kitsune: língua de fogo-raposa na borda e 3 caudas girando dentro.
  - Chuva de Flechas: sombras das flechas chegando, borda tracejada e 4 setas
    apontando para dentro (piscam no aviso antes da chuva).
- Personagens: a faixa de sombra do toon ficou mais clara (0,25 → 0,4), cara
  de desenho animado de dia.
- Outras frentes: `area_effect.gd` e `arrow_rain.gd` trocam o disco + anel pela
  `MarcaChao` (só visual; dano, raio e duração iguais).
- **O que testar**:
  1. O tema de dia lembra mais o Fat Princess original? Cores, grama, flores.
  2. Os poderes de área (fumaça, selo, kitsune, chuva de flechas): dá para ver
     a área, de quem é e quanto tempo falta?
  3. O mapa ficou menos apertado atrás das casas?
  4. FPS no tema de dia comparado com o de noite.
