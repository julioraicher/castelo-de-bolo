# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.
Entradas até o Ciclo 2.29b (2026-11-14) estão em `docs/changelog-antigo.md`.

## Revisão 3c (2026-11-20), Diretor de Jogabilidade: kit visual arrumado
Lote 3c do relatório de 2026-11-19 (mexe em arquivos de efeito, papel do Diretor
Visual: só reorganização, nenhum desenho novo). **Nada muda no jogo; na tela, o
mesmo desenho com menos chamadas de desenho.** Prova: o resumo da partida (SINC)
ficou idêntico ao do 3b nas 6 partidas de prova; as 23 malhas pintadas e de
projétil saem byte a byte iguais; testes 1688/1688; varredura de poderes sem erro;
os 12 modos de print/filme/vitrine rodam sem erro e com os mesmos arquivos.

**Código**
- `FxBase` (`scripts/fx/fx_base.gd`): cache de recurso, nó/malha de efeito, onde
  pendurar o efeito de um boneco, tremor da câmera e o portão da qualidade Mínima,
  que 7 kits escreviam cada um do seu jeito (FX-12/13/24).
- `MalhaPintada` (`scripts/fx/malha_pintada.gd`): material pintado do tema e os
  construtores (tubo, bola, corda, caixa, placa, aro...) que FxNatureza, FxObra e
  FxItens tinham em 3 cópias e chamavam os `_` privados um do outro (FX-15/16).
  `MalhaUnica.pecas` junta peças soltas (era escrito 3 vezes) (FX-14).
- `Estilo.letreiro_3d`: os 15 Label3D (nome do golpe, avisos, placas das casas,
  torreta, nome do boneco...) nascem numa receita só; cada um mantém os próprios
  números (FX-19/UI-16).
- Variantes de shader viraram arquivos (`magia_energia_atras`,
  `assinatura_selo_frente`, corpo em `.gdshaderinc`): antes eram feitas trocando
  texto do código em tempo de execução, o que quebrava calado se alguém mexesse
  no `render_mode` (FX-25).
- `Fx.prewarm` cobre o que ficava de fora (marca de chão dos poderes, as duas
  variantes, respingo, os 14 tipos de projétil): no navegador, o 1º poder de
  área não trava mais compilando shader (FX-08).
- Menos chamadas de desenho: coluna de fogo 6 → 1, pétalas da bênção 10 → 1
  (MultiMesh com as mesmas curvas), minas do campo minado com malha e material
  únicos, contorno tirado com uma cópia por material e não por peça (FX-22/34).
- Tempo de voo da Saideira é regra e foi para `cfg.herois.saideira_voo` (FX-10);
  código morto do AreaEffect e números do selo antigo saíram (FX-30/31);
  `Assinatura.peca_fixa` mora no Assinatura (FX-42); `FxHerois.AZUL_FANTASMA`
  (o FANTASMA verde do NinjaVisual é outra cor) (FX-27).
- AutoQuality mede o tempo real durante a câmera lenta (antes a janela de medida
  esticava no slow-motion) (FX-40).

**Ficou para decidir com prancha (muda a tela):** Decalque (marcas no chão num
MultiMesh só: muda a ordem de desenho em relação às ondas e ao chão), cores
repetidas com valores diferentes (PAPEL tem 5, OURO 4, TINTA da magia ≠ da
interface), anel do chão triplicado, regra de neblina nos efeitos.

**O que testar**
- Nada novo. Se quiser conferir: Kitsune de Luz (bênção e coluna), Armadilheiro
  (campo minado) e o Predero (Saideira) no modo teste, iguais a antes.

## Revisão 3b (2026-11-20), Diretor de Jogabilidade: peças do mundo
Lote 3b do relatório de 2026-11-19. **Nada muda no jogo nem no modo teste.**
Prova: o resumo antigo da partida (SINC) ficou idêntico, quadro a quadro, nas
mesmas 6 partidas do 3a; os testes de rede e de sincronia (60 × 23 FPS) passam
com o resumo novo.

**Código**
- Base comum `PecaDoMundo` para teia, para-raios, poça, andaime, árvore do
  Kodama, estrepes e mina: dono, time, hora em que nasceu, grupo, vida e saída
  numa cópia só; `sair()` no lugar de sumir/secar/cair; "passou do máximo, a mais
  antiga some" numa função (`limitar`, era escrita 4 vezes) (IT-01/09/10).
- **Estruturas no resumo da partida (SINC)**: máscaras, torretas, catapultas,
  casas, maquininhas, plantas, toras, espíritos, itens, peças no chão e tiros.
  Online, se uma obra ou uma poça se separar entre os PCs, o aviso aparece na
  hora e diz o que foi (antes só aparecia quando chegava num boneco) (IT-08).
- Mira da torreta virou regra (`Torreta.mira_y`); antes o tiro lia o giro do
  modelo 3D (IT-04).
- "Golpe no arco" numa função (`Game.mais_perto_no_arco`, era escrito 4 vezes:
  plantas, árvore, andaime, torreta) e "Construtores em volta da obra" numa conta
  (`Game.ritmo_obra`, 3 cópias) (IT-02/06).
- Raios de obra e da armadilha saíram do código para o `game_config`
  (`raio_obra_*`, `obra_parado_vel`, `armadilha_raio`, `armadilha_vida`) (IT-12).
- As peças não mexem mais nos campos internos do boneco e da maquininha
  (`defende_de`, `escondido`, `em_casulo`, `veste`, `HatPad.subir_degrau`) (IT-11).

**Achados para decidir (não mudei):** o virote da torreta volta no escudo mesmo
com a guarda quebrada (o golpe não volta); obra de torreta e maquininha não pede
"parado" nem acelera no modo teste, a da casa pede. Catapulta ainda lê a mão do
modelo para soltar o passageiro (trocar muda o ponto de lançamento em milímetros).

**O que testar**
- Nada no jogo. Se o CI ficar verde, está certo.

## Revisão 3a (2026-11-20), Diretor de Jogabilidade: núcleo do código arrumado
Lote 3a do relatório de 2026-11-19 (mesmo pedido do 3e: lotes grandes que não
mudam o jogo). **Nada muda no jogo nem no modo teste.** Prova: o resumo da
partida (SINC) ficou idêntico, quadro a quadro, ao de antes em 6 partidas
(sementes 7 e 1234, três com variações e heróis, uma na Arena de chapéus), e
os 12 modos de print/filme/prancha geram os mesmos arquivos.

**Código**
- `game.gd` de 3.005 para 2.084 linhas. As ferramentas de print, filme, vitrine,
  pisca, pranchas, `--perf` e CENSO foram para `scripts/dev/ferramentas.gd`
  (`Ferramentas`, só existe quando um desses argumentos aparece); modo teste e
  Arena de chapéus foram para `scripts/partida/modo_teste.gd` (`ModoTeste`) (NU-11).
- Números dos heróis raros saíram do `GameConfig` para `HeroisConfig`
  (`config/herois_regras.tres`, lido como `cfg.herois.X`); o `GameConfig` voltou
  a ter só regras da partida, com os grupos em ordem (NU-16).
- Números mágicos viraram campos: raios de pontuar, pegar máscara, resgatar,
  alimentar, pegar espírito e item (grupo "Raios das regras"), Fúria ×1,8,
  preso ×0,1 e a gravidade (NU-18).
- O que cada estado trava (mãos, Q, E/R, dash) está numa tabela só,
  `Unit.TRAVAS`, com teste. Mesmo comportamento de hoje, inclusive o preso que
  ainda usa E e R (decisão sua pendente: agora é mudar uma linha) (NU-06).
- Direção do corpo virou regra (`Unit.yaw`); antes as regras de bloqueio e de
  golpe pelas costas liam a rotação do modelo 3D (NU-08).
- Reanimar e Finalizar dividem uma base (`CanalNoCorpo`): busca do corpo, bot
  reservado, anel e letreiro numa cópia só (NU-15).
- Teste novo `_registro_poderes`: todo Q/E/R do enum tem regra, toda regra está
  no enum e todo herói tem o poder também na IA dos bots (NU-14).
- Comentários do esquema corrigidos (Chi é do E, listas de dash e super
  completas) e o texto do Q em Controles não lista mais só 6 classes (NU-10).
- Ficou de fora: a consulta espacial única (NU-13). Ela troca a ordem em que as
  regras olham os bonecos, e isso muda a partida; precisa de uma rodada própria.

**O que testar**
- Nada no jogo. Modo teste e Arena de chapéus iguais (tambores, mostruário,
  [M] [L] [N]). Se o CI ficar verde, está certo.

## Revisão 3e (2026-11-20), Diretor de Jogabilidade: testes e ferramentas
Lote 3e do relatório de 2026-11-19 (pedido do Julio: gastar o limite em lotes
grandes que não mudam o jogo). **Nada muda no jogo** nem no modo teste; muda como
o jogo é testado.

**Testes**
- `tests/regras.gd` (3.300 linhas) virou um runner de 130: os testes moram em
  `tests/regras/<sistema>.gd` (dados, combate, poderes, economia, partida,
  reanimar, itens, herois, sistema), com base comum `tests/lib/caso.gd` (um
  `_por` só no lugar de 4 cópias divergentes) e o tempo de cada arquivo no fim.
- **Bots parados durante os testes** (`BotBrain.parado`): o resultado não depende
  mais da semente nem de onde os bots andaram (antes havia teste que falhava
  "1 em 5"). Conferido com 4 sementes: mesmas checagens, todas ok.
- Testes novos: os 5 itens do chão (poção, escudo, velocidade, dano, medidor),
  configurações salvas ao fechar a janela, IA dos 14 heróis (todo herói usa Q, E
  ou R com 3 inimigos na frente e mira no grupo), lista de classes igual em todo
  lugar (selos, clipes, geradores de casa/herói/pavilhão, `tools/lib/classes.sh`),
  e todo `.scn` comprimido. 1.113 → 1.471 checagens; piso subiu para 1.400.
- Boneco de teste único (`tests/lib/bonecos.gd`) nas regras e nas duas varreduras.

**Ferramentas e CI**
- QA do mapa só avisa o que piorou em relação a `tests/qa_mapa_base.txt` (antes
  repetia os mesmos 477 avisos em todo push).
- Testes de rede com pasta própria (`tools/lib/sinc.sh`, `mktemp -d`): queda e
  dessincronia rodam juntas no CI (grupo rede ~1,5 min mais curto).
- `tools/lib/classes.sh`: lista única das classes para `clipes_tutorial.sh` e
  `vitrine.sh` (a da vitrine tinha parado nas 10 da 2.4).
- Saiu `tools/comprimir_cenas.gd` (migração de uma vez só; o teste novo garante).

**O que testar**
- Nada no jogo. Se o CI ficar verde, está certo.

## Caça 2.35 (2026-11-20), Diretor de Jogabilidade: revisão completa, lote de consertos + CI + docs
Pedido do Julio: revisão do jogo inteiro e, da fase 2, o pacote "Consertos + CI +
docs" (lotes 0, 1 e 3h do relatório de 2026-11-19, pasta do projeto
`revisao/revisao-completa-2026-11-19/`). Nada de regra de jogo nova: as decisões
pendentes (mira e invisível, online de 20 min, preso no E/R, altura, torreta e
sombra, cor do Chi, prancha de efeitos) continuam esperando o Julio.

**Jogo**
- **Configurações salvas de verdade**: gravam 0,4 s depois de cada mudança e ao
  fechar a janela. Antes só salvavam ao sair pelo menu: mudar na tela inicial,
  jogar e fechar o X (ou a aba no navegador) perdia volume, qualidade e dificuldade.
- **Clique curto não some** a 10 FPS: o clique que entra e sai entre dois quadros
  de física também ataca (offline e online).
- **Estrepes e minas** guardam time e dano ao nascer: o dono morto ou trocado não
  dá mais erro, e o bot não confunde projétil sem dono.
- **Recarga do Q** numa conta só (`ClassStats.recarga_q`): a ficha do menu Classes
  mostrava a da cura e a das armadilhas erradas (agora 2,4 s na Kitsune, por ex.).

**Textos**
- Fichas dos 6 heróis que estavam em branco (Ochimusha, Shishimai, Jorogumo, Kodama,
  Kaminari-kozō, Predero): os textos de Q/E/R agora moram nos `.tres`
  (`skill_desc`, `power_desc`, `super_desc`) e um teste reprova texto vazio.
- Como jogar lista os heróis a partir dos `.tres` (o Predero aparece). Cartão da
  Máscara com o objetivo certo ("leve a máscara inimiga ao seu castelo").
- Caracteres que a fonte não tem (★, →, ⚔, ♪...) viravam quadrado: trocados por
  texto ("DUELO: ...!", "HERÓI RARO", "MUDO", "Esc > ..."); um teste varre os textos.
- Mina do Armadilheiro e Bomba Grande do Bombardeiro com descrição própria.

**Efeitos**
- Avisos de regra (CONTRA!, SELADO, PRESO, NINGUÉM PERTO...) sempre aparecem;
  só os números de dano/cura obedecem a opção "números de dano".
- Rastro das lâminas e projéteis medido em tempo: mesmo comprimento a 10 ou 144
  FPS (a 10 FPS ficava 6x mais comprido) e colado na arma interpolada.
- Raio/faísca (`Magia.raio`) numa malha só; Kaminari-kozō e `Fx.zap` usam ele.
- Papel do Onmyoji com material de sprite certo; olho do orbe carregado cresce.

**Testes e CI**
- Erro de script durante os testes **reprova** (na 4.7 ele não muda o código de
  saída): `tests/contador_erros.gd` + `tools/checar.sh` procurando `SCRIPT ERROR`.
- Testes com semente fixa (1234) e impressa; mínimo de checagens; esquema das 27
  classes (valores de skill/power/personalidade e textos) e campos dos temas.
- `tools/checar.sh regras|partida|rede|tudo`: o MESMO script no CI e no agente
  testador. CI em 3 grupos paralelos (~2,5 min em vez de 5+), Godot e templates
  conferidos pelo SHA-512 oficial, Actions fixadas por SHA, permissão mínima por
  job, release "ultima-versao" atualizada sem apagar, teste RTC pela internet só na
  main, butler com versão e SHA-256 por variável (`BUTLER_VERSAO`, `BUTLER_SHA256`).
- Geradores: `tools/gerar_tudo.sh` roda todos na ordem certa; `gerar_cenario_ninja`
  e `gerar_herois` carregam o `.tres` e só trocam o que geram (antes apagavam os
  campos da economia e a `personalidade` dos heróis). Aviso: rodar os geradores
  hoje ainda muda um pouco `dia.tres` (contraste) e o `rio_lanternas.tres`
  (objetos do mapa) em relação ao que está no repo; não foram regravados.
- `tools/tabela_classes.py` gera a tabela de Q/E/R do CONTROLES.md dos `.tres`.

**Docs**
- CLAUDE.md de 268 para ~170 linhas: mapa dos sistemas em `docs/mapa-do-codigo.md`
  (com o **checklist de personagem novo**), comandos em `docs/comandos.md`, sem
  repetir os princípios. README (R = super, F5 reinicia, Tab, reanimar, créditos
  Kenney/IA), CONTROLES (tabela de todas as 27 classes, caminhos e heróis), GUIA,
  ROADMAP (ciclos 2.6-2.35), ideias, AULA (números de hoje). `project.godot` sem
  MSAA e com "GL Compatibility". Ciclos até o 2.29b arquivados em
  `docs/changelog-antigo.md`.

**Modo teste**: nada novo para montar; tudo acima vale lá também.

### O que testar
1. Mude volume e qualidade na tela inicial, jogue um pouco e feche pelo X (ou a
   aba): ao abrir de novo, ficou como você deixou?
2. Menu Classes: as fichas do Ochimusha, Shishimai, Jorogumo, Kodama,
   Kaminari-kozō e Predero têm texto em Q, E e R? A recarga da Kitsune diz 2,4 s?
3. Como jogar: a lista de heróis tem o Predero? O cartão da Máscara diz o
   objetivo certo?
4. Com "números de dano" desligado: os avisos (CONTRA!, PRESO, SELADO) aparecem?
5. Algum quadradinho no lugar de letra (duelo, painel do herói, lobby)?
6. Com o FPS baixo (navegador): o rastro da lâmina e do shuriken fica curto, colado
   na arma? E cliques rápidos sempre saem golpe?
7. R da Kitsune Sombria, papel do Onmyoji, raio do Kaminari-kozō: tudo como antes?

## Ciclo 2.34 (2026-11-19), Diretor de Jogabilidade: personalidade no corpo + finalização de herói
Pedido do Julio: dash com personalidade (as Kitsunes e a "corrida ninja") e
combos/finalizações com câmera lenta ao derrubar herói, tudo junto. O dash por
estilo e as Kitsunes de 1 a 5 caudas já existiam (2.14/2.15); o problema era o
dash durar 0,24 s (14 quadros, 4 m a 17 m/s): o olho não lê detalhe nisso. Então a
personalidade foi para antes e depois dele (antecipação e pouso, as regras da
animação) e para o tempo em que o boneco está parado ou correndo. O dash em si
(tempo, distância, recarga) não mudou (princípio 5).
- **8 personalidades** (`ClassStats.personalidade`, dados em
  `scripts/actors/personalidade.gd`; pose do peito, cabeça e braços em `PoseDash`):
  **pesado** (Ronin, Sumotori, Sohei, Shishimai, Kappa: peito pesado, ginga de lado,
  pousa num pisão), **samurai** (Samurai, Ochimusha: peito estufado, queixo alto,
  pousa embainhando com tinido), **ninja** (Shuriken, Kusarigama, Mujina, Karasu,
  Yamabushi: curvado, **corre inclinado com os braços para trás**, pousa agachado),
  **atirador** (Yumi, Armadilheiro, Komusō: cabeça de lado, pousa ajoelhado),
  **trapalhão** (Construtor, Bombardeiro, Predero: olha para os lados, corre
  quicando torto, pousa cambaleando), **curioso** (Kitsune aprendiz, Kaminari-kozō:
  inclina a cabeça de um lado para o outro, saltita, pousa num pulinho), **sereno**
  (Kitsune da Luz, Tennin, Onmyoji, Kodama: ereto, boia, pousa sem amassar) e
  **predador** (Kitsune Sombria, Jorogumo: agachado, cabeça erguida vigiando, pousa
  rastejando). O pouso segura a pose ~0,4 s **sem travar o controle**.
- **Peça no dash para todos**: cada personagem solta a peça da sua assinatura
  (pena, sal, folha, nota, shuriken...) no começo e no fim do dash, só perto da
  câmera (antes só 6 heróis tinham).
- **Finalização de herói** (`scripts/finalizar.gd`): herói Nv6 caído pode ser
  finalizado por um inimigo colado no corpo segurando **[F] por 0,8 s** (reanimar
  leva 3 s: vira corrida). Finalizado **não pode mais ser reanimado**; quem
  finaliza ganha 40 de Chi, 30 de super e 150 pontos no placar. O canal não para
  com dano (igual ao Reanimar) e para se soltar o F, dar dash ou se afastar.
  O golpe é o da personalidade de quem bate: ESMAGADO (pisão com rachaduras),
  CORTE IAI (o corte chega 0,24 s depois), PELAS COSTAS, À QUEIMA-ROUPA, BONK
  (estrelinhas), CUTUCADA (boing), PURIFICADO (coluna de luz) e DEVORADO (três
  garras). Selo de quem finalizou no chão, tinta do caído espirrando, letreiro
  com o hanko, câmera lenta, câmera aproxima e faixas de cinema.
- **Herói caiu**: letreiro ("Herói caiu! Segure [F] nele", "Seu X caiu! Reanime!",
  "X inimigo caiu! Finalize!"), meio segundo de câmera lenta perto do jogador e
  marca vermelha "FINALIZE [F]" no corpo, só para o time que pode finalizar.
- **Online**: sem câmera lenta (mexe na física e separaria a partida); ficam o
  congelamento do golpe (regra, igual nos dois PCs), a câmera e as faixas.
- **Bots** vão finalizar herói inimigo caído a até 14 m (sem inimigo colado) e
  continuam correndo para reanimar o deles.
- **Modo teste**: herói inimigo de treino ao lado do Samurai de treino, parado e
  com 25% da vida; derrube, segure [F] e veja o golpe. Ao voltar, vem como outro
  herói (Sumotori, Tennin, Jorogumo, Karasu). Prancha:
  `--prancha-finalizar=DIR` (xvfb) tira parado/correndo/golpe das 8 personalidades.
- **Testes de regra**: finalizar (só herói, longe não começa, soltar F para, nega
  reanimar, Chi/super/placar, renascer limpa) e toda classe com personalidade
  válida e animações existentes.

**O que testar**: no modo teste, troque de chapéu e fique parado e corra perto do
portão (cada família tem postura e passada própria; Ninja corre com os braços para
trás). Dê dash e repare no pouso. Derrube o herói de treino (do lado do Samurai de
treino), segure [F] colado nele e veja o golpe de cada personalidade. Numa partida
normal, quando um herói cair, veja o aviso e a marca vermelha, e tente finalizar
antes que o time dele reanime.

## Ciclo 2.33 (2026-11-16), Diretor de Jogabilidade: textos que vazavam dos painéis
Print de um amigo do Julio: no painel "Nível 6 de Samurai: escolha o herói raro" o
texto dos cartões passava da borda, o rodapé "Clique num herói... F fecha" ficava
por cima dos cartões e o minimapa cobria o 4º herói. Não era a resolução dele:
acontecia em qualquer tela (a tela lógica é sempre 1600x900 ou maior).
- **Painel da escolha** (caminho Nv2→3 e herói Nv6, `Hud.abrir_escolha`): cartões
  viraram `PanelContainer` (crescem com o texto; o `Button` antigo tinha altura fixa
  e o texto vazava). Q, E e R em linhas separadas, rodapé com quebra de linha,
  largura do cartão pelo que cabe na tela (220-330 px), o painel encolhe quando
  passa de 5 heróis para 2 caminhos e fica **acima do minimapa e do cartão do
  jogador** (antes ficava por baixo dos dois).
- **Configurações**: a nota "Alta dinâmica" ocupava uma célula da grade e trocava
  os pares do Vídeo ("Baixar sozinho se travar" ia para a coluna dos botões); a
  coluna Partida passava da moldura ("Festival ao Sol (dia)"). Nota no lugar certo,
  listas que encolhem com "..." e coluna da direita um pouco mais larga.
- **Auditoria nova** `tools/auditoria_ui.gd` (também no CI, sem xvfb): abre HUD com
  todos os painéis de escolha, placar, tela inicial, pausa, Com amigos, as 26 fichas
  e as abas do Como jogar em 7 resoluções (1280x720, 1366x768, 1920x1080,
  2560x1440, 1024x768, 1280x1024, 2560x1080) e falha se algum texto vaza da
  moldura, sai da tela ou se dois blocos do HUD se cobrem. Antes: 72 falhas em
  1280x720; agora 0 em todas. Antes/depois em
  `castelo-de-bolo/interface/09-textos-que-vazavam-antes-depois.jpg`.
- **Modo teste**: usa os mesmos painéis e menus, então já vem consertado lá.

**O que testar**: no modo teste, F no bairro do Samurai no Nv5 (4 heróis) e no do
Ninja de Shuriken (5 heróis): todo texto dentro do cartão, nada embaixo do minimapa,
clique e teclas 1-5 escolhendo. Pausa > Configurações: cada opção do lado do seu
botão. Se der, pedir ao amigo para abrir o mesmo painel no PC dele.
## Ciclo 2.32c (2026-11-15), Diretor Visual: shuriken preta
Pedido do Julio (prancha aprovada): a shuriken do Ninja Shuriken passa a ser preta.
- **Projétil** (`FxProjetil.malha_shuriken`): lâmina de aço preto com fio chanfrado
  claro na borda, ponta que reluz e anel no miolo. O fio é o que faz ela aparecer
  em chão escuro. Vale para o tiro, a shuriken cravada no chão/corpo e o Leque (E).
- **No corpo** (`NinjaVisual._ninja`): shurikens da mão, do peito e das costas
  pretas, sem o neon ciano; a bandoleira do peito ficou preta também.
- Rastro de Chi do tiro um pouco mais forte (alfa 0,3 → 0,45) para seguir o voo.
- Prancha: `tools/prancha_shuriken.gd` (projétil parado + boneco de frente/costas).
- **Modo teste**: nada a ligar, a classe já está disponível lá com a shuriken nova.

**O que testar**: jogue de Ninja Shuriken no modo teste e numa partida: dá para
ver o tiro em voo no chão claro e no escuro? A shuriken na mão e na bandoleira
aparecem pretas?

## Ciclo 2.32b (2026-11-15), Diretor de Jogabilidade: 1 madeira a menos em toda construção
Pedido do Julio: mais heróis evoluídos em campo ao mesmo tempo, um pouco mais cedo.
Só números em `config/game_config.tres` (sem código):
- Barraquinha Nv1→2 4 → **3**; casa do caminho (Nv3) 5 → **4** (+2 por casa que o
  time já fez, degrau igual); Nv3→4 / Nv4→5 4/6 → **3/5**; pavilhão do herói 7 → **6**.
- Posto da raposa (torreta) 3 → **2**; maquininha Nv2 6 → **5**.
- Escada até o herói de um bairro: 4+5+4+6+7 = 26 → **21** madeiras (-19%).
- **Modo teste**: já tem madeira infinita, nada muda lá; textos do Como jogar e das
  fichas leem os custos do config e mostram os números novos.

**O que testar**: numa partida de 20 min, quando aparece o 1º herói raro e quantos
heróis cada time tem lá pelos 12-15 min. Se ficar cedo demais, é só subir de volta
no `.tres`.

## Ciclo 2.32 (2026-11-15), Diretor Visual: espírito, itens e armadilhas refeitos (lote D)
Lote D da caça aos bugs: as três peças que ainda eram primitivas soltas (fora do
princípio 13). Quiz do Julio: chama-fantasma, objetos de verdade, ferramentas de
ninja, lote caprichado. Kit novo `scripts/fx/fx_itens.gd` (`FxItens`); prancha
`tools/prancha_itens.gd`.
- **Espírito (hitodama)**: gota de fogo-fátuo no shader do kit Magia (núcleo claro,
  cauda que se rasga e ondula, borda de tinta), duas chaminhas em órbita e a chama
  respirando. Nasce com um anel subindo; **pego** = a chama estica e se rasga, com
  brasas, e o que vai na cabeça de quem pegou dá um pulo (`Unit.pulso_espirito`);
  **preso na máscara** = estouro, dois anéis subindo e faíscas (a alma de abate faz
  a versão pequena). O mesmo visual vai na cabeça, voando para a máscara e em
  volta dela.
- **Itens no chão** viraram objetos pintados: Poção = cabaça laqueada com vapor
  rosa; Escudo = leque de guerra com o emblema janome e um aro de guarda girando;
  Velocidade = tamanca geta num redemoinho de vento; Dano dobrado = duas kunais
  com o talho em X atrás; Poder cheio = pergaminho roxo com três chaminhas de chi
  (deixou de ser o gêmeo roxo do espírito). Caem do céu quicando, cada um espera
  do seu jeito e, pego, se desfaz em energia na cor dele com a peça do tema.
- **Armadilhas**: estrepes do Construtor = makibishi de ferro numa tabuinha de
  bambu com folhas e a estaca com a fita do time; mina do Armadilheiro = panela de
  pólvora de barro com a corda do time, selo de papel e a brasa do estopim
  pulsando. Caem quicando (a mina balança), disparam com peças próprias
  (makibishi espirrando, cacos de barro) e, quando vencem ou são trocadas pela
  nova, afundam no chão em vez de sumir de estalo (`Trap.sumir`).
- **Anel do chão** refeito (`FxItens.anel_chao`): anel de energia com filete de
  tinta em vez do toro chapado, cor e traço próprios por peça (espírito verde
  esfiapado, item na cor dele, armadilha tracejada na cor do time).
- **12 sons próprios** (`gerar_sons.py itens232`): um por item, item caindo,
  espírito pego/preso, estrepes armados/pisados, mina armada e armadilha sumindo.
- Mais leve: estrepes custavam 8 chamadas de desenho cada (7 cones + anel), agora 2.
- **Modo teste**: mostruário na frente do portão com os 5 itens em fila e um
  espírito; o que for pego volta 2,5 s depois. Estrepes = Construtor, mina =
  Armadilheiro (o Samurai de treino serve de alvo).
- Clipes do Como jogar regravados: objetivo, Construtor e Armadilheiro.

### O que testar
- Modo teste: olhar o mostruário de perto e pegar cada item (som e efeito de cada um).
- Pegar um espírito e levar até a máscara: a chama na cabeça, o pulo ao pegar e o
  suspiro de faíscas ao prender.
- Construtor (botão direito) e Armadilheiro (botão direito e R): armadilhas
  caindo, a fita/corda na cor do time, o Samurai de treino pisando e as
  armadilhas antigas afundando quando passam do limite.

## Ciclo 2.31 (2026-11-15), Diretor de Jogabilidade: partida de 20 min, último minuto leve
Pedido do Julio (sem quiz, direto na main depois da caça aos bugs).
- **Relógio de 20 min** (era 15): mais tempo para heróis Nv6 entrarem em campo.
- **Último minuto: as duas máscaras perdem todo o peso**, empatado ou não
  (`ultimo_minuto_leve` = 60 s no `game_config`). Espírito entregue e alma de
  abate não pesam mais até o fim (o espírito ainda enche o E/R de quem entrega).
  Letreiro "ÚLTIMO MINUTO!" e o relógio passa a dizer "MÁSCARAS LEVES".
- **Prorrogação só quando a máscara decide**: no zero, ela abre se uma máscara
  fora do castelo (na mão ou caída) empata ou vira o jogo para quem a roubou
  (ladrão empatado ou 1 atrás). Segue **até a máscara voltar ao castelo**
  (entregue, devolvida ou de volta sozinha). Máscara fora que não muda nada
  (ladrão 2+ atrás) não segura mais o fim. Na mão, `prorrogacao_max` (60 → 180 s)
  ficou só como trava contra quem foge com ela sem entregar.
- Placar igual no fim: morte súbita como antes (2 min, primeiro ponto vence).
- Como jogar, CONTROLES.md e CLAUDE.md atualizados. Regras novas em `tests/regras.gd`.
- **Modo teste**: **[L]** liga o relógio a 1:10 do fim (último minuto leve,
  prorrogação e fim de verdade). [M] segue chamando a morte súbita.

### O que testar
- Partida normal: relógio começa em 20:00.
- No 1:00 aparece "ÚLTIMO MINUTO!" e as máscaras ficam sem espíritos em volta;
  quem rouba anda rápido.
- Empate no zero com alguém do time de trás carregando a máscara: prorrogação
  até ela ser entregue ou voltar. Ganhando de 2 com a máscara fora: acaba na hora.
- Modo teste: [L] e esperar 1 min e pouco.

## Ciclo 2.30f (2026-11-15), Diretor de Jogabilidade: caça aos bugs, lote E (parte 2)
- **Bot com a máscara preso**: atrás de um andaime do Predero ou de uma árvore
  do Kodama (a navegação não conhece esses colisores) quem leva a máscara não
  destravava nunca. Agora destrava quando fica parado de vez (6 s), como os outros.
- **Testes instáveis no CI** (falhavam 1 em ~5): o do placar escolhia um bot da
  partida que às vezes estava intocável; o da Ochimusha pegava um Construtor com
  tora na mão (Q travado). Placar usa bonecos próprios; os testes de herói
  escolhem quem está de mãos livres e zeram os estados que travam.
- Conferido sem mudança: sincronia com heróis em campo (150 s, `--com-herois`,
  semente 11: igual), poderes no voo da catapulta (não saem no ar; recargas
  correm, desde o 2.26s).
- **Diagnóstico da linha do Construtor** (sonda 8 partidas, sem mexer em número):
  por minuto vivo, Construtor 0,23 abate e 48 de dano, Armadilheiro 0,16 / 36,
  Bombardeiro 0,34 / 57, contra Arqueiro 1,88 / 450 e Guerreiro 2,05 / 551.
  O Construtor passa o tempo cortando e entregando madeira (é o papel dele); as
  duas evoluções herdam o comportamento de bot de obra e quase não brigam. Se o
  Julio quiser, o ajuste é no cérebro (Nv3 sair para a briga), não nos números.

### O que testar
- Nada muda na tela; é robustez de bot e de teste.

## Ciclo 2.30e (2026-11-15), Diretor de Jogabilidade: caça aos bugs, lote C (mapa)
- **Cantinhos atrás das estátuas fechados**: entre a colina do fundo, a escada
  dela e a estátua (|x| 27-35, z -48 a -44, os dois lados) o jogador entrava
  (cápsula fina) e nenhum bot chegava (a navegação tem raio maior); ali a
  colina ainda tapava a câmera. Agora há parede invisível que só segura quem
  anda (`so_passagem`, tiro passa), gerada em `tools/gerar_mapa_rio.gd`
  (`_tampas_estatua`) e já gravada em `rio_lanternas.tres`. QA do mapa:
  inalcançável 8 → 2 (sobram 2 pontos de 1 m entre árvores em |x| = 63).
- **Ferramenta `--pisca` consertada**: no xvfb vários passos de física cabem num
  quadro desenhado e ela comparava a mesma imagem com ela mesma (sempre 0
  pixels). Agora dá um passo de câmera por quadro desenhado; `PISCA_FOCO=x,z`
  mira em qualquer ponto. **Correção do que eu disse no quiz**: com ela
  funcionando, telhados, chão e torre **não piscam**; o que muda de um quadro
  para o outro são só bordas finas (serrilhado, que o FXAA do 2.30d alisa) e
  coisas animadas. As ~475 "faces sobrepostas" do QA são invisíveis na prática.
- **Maquininha do Construtor "escondida"**: conferida em print. A placa e o
  tapete aparecem; a guarita da muralha cobre só o pé da barraquinha, e quem
  fica atrás dela aparece em silhueta (raio X). Não mexi. O QA agora só conta
  as vistas de onde dá para pisar (antes contava câmera dentro da muralha).

### O que testar
- Ir até os fundos do mapa atrás das colinas perto das estátuas (atrás do
  pagode): o boneco para na beira, não entra mais no cantinho.
- Nada mais muda na partida.

## Ciclo 2.30d (2026-11-15), Diretor de Jogabilidade: caça aos bugs, lote B (antisserrilhado de verdade na Alta)
Achado da caça aos bugs: desde o 2.19 a Alta trocou o MSAA pelo FXAA do Godot,
mas o `Viewport.screen_space_aa` **só existe no Forward+/Mobile**. No
Compatibility (o renderizador do jogo no .exe e na web) o Godot recusava com
um aviso e a Alta rodava **sem antisserrilhado nenhum**.
- **FXAA próprio** (`assets/shaders/fxaa.gdshader`, FXAA "console" de Lottes):
  lê o brilho (luma) das 4 diagonais, acha a direção da borda e borra só ao
  longo dela (o contorno de tinta não engorda). 9 leituras por pixel, uma
  passada: +1 chamada de desenho e uma cópia da tela.
- Fica numa camada de tela abaixo do HUD (`Settings._fxaa_ligado`): pega o 3D
  já ampliado (escala 0,9); textos, barras, menus e mira continuam nítidos.
  Só na Alta (inclusive no modo teste e na Arena); Média, Baixa e Mínima iguais.
- `--shots` desliga a qualidade automática (no xvfb lento os prints saíam na
  Mínima). `SEM_FXAA=1` no ambiente tira o FXAA (prints de antes/depois).
- Print: project-files castelo-de-bolo/desempenho/2026-11-15-fxaa-antes-depois.jpg.
- Testes: regras 1034/1034 (novo: FXAA liga só na Alta, abaixo do HUD).
- **O que testar**: na Alta, olhe as bordas dos telhados e das muralhas: menos
  "escadinha". Se o FPS cair perceptivelmente na Alta, me avise (a Alta
  dinâmica continua mirando 30).

## Ciclo 2.30c (2026-11-15), Diretor de Jogabilidade: caça aos bugs, lote A (testes) + bot preso no rio
Julio pediu uma caça a bugs e pontas soltas (quiz: project-files
castelo-de-bolo/quiz/quiz-caca-bugs.html). Lote A = ferramentas de teste; elas
acharam um bug de verdade, consertado junto.
- **Bug: bot preso no rio para sempre.** O leito do rio tem malha de navegação
  própria, fechada pelas travas das margens. Salto ou teleporte que mirava no
  rio (Mergulho e Noite de Corvos do Karasu, Rasteira do Kappa, Relâmpago do
  Kaminari) deixava o boneco lá dentro: o jogador sai andando, mas o bot não
  acha caminho (6 de 6 bots ficaram presos 30 s no teste). Agora
  `Herois.chao_valido` só devolve chão ligado ao castelo: saltos e teleportes
  **terminam a travessia na margem da frente**; o que é plantado (árvore,
  andaime, poça) fica na margem mais perto. Teste `_rio_sem_ilha`.
- **Varredura de poderes com aliados** (`--varredura-aliados`,
  `tests/varredura_aliados.gd`): aliado ferido, caído e distante; confere fogo
  amigo, dono preso e, nos poderes de apoio, cura/escudo/reanimar/puxão/corrida/
  intocável. As duas varreduras (inimigo e aliados) agora rodam no CI.
- **QA do mapa**: a casca de contorno não conta mais como "chão piscando"
  (2.359 falsos alarmes); relatório com resumo por tipo e o que trava o jogo
  primeiro; leito do rio (dentro da trava) não conta como beco.
- Testes: regras 1031/1031, varredura 0 suspeitos, aliados 0 falhas.
- **O que testar**: com Karasu Tengu (Q), Kappa (Q) ou Kaminari-kozō (E), mire
  no meio do rio: você aparece na outra margem, não dentro d'água. Na partida,
  nenhum bot parado no rio. (No modo teste: Arena de chapéus tem os três.)

## Ciclo 2.30b (2026-11-15), Diretor de Jogabilidade: pausa sozinha ao plugar HDMI + Sair para o menu
Julio: o jogo pausou sozinho várias vezes ao plugar o cabo HDMI, e no menu de
pausa "não dava pra sair do jogo". Causa: o jogo pausa de propósito quando a
janela perde o foco (para ninguém morrer fora da tela), e o Windows tira e
devolve o foco várias vezes seguidas enquanto reconfigura os monitores — cada
piscada virava uma pausa. Não era defeito do PC.
- **Carência de meio segundo na auto-pausa** (`menus.gd`): ao perder o foco, o
  jogo espera 0,5 s e só pausa se o foco continuar fora. Alt-Tab de verdade
  continua pausando; a rajada do HDMI não.
- **Botão "Sair para o menu"** no menu de pausa: volta para a tela inicial.
  "Reiniciar partida" agora recomeça direto na partida (antes os dois caíam na
  tela inicial). "Sair do jogo" segue no rodapé (no .exe; a web não tem).
- Vale igual no modo teste e na Arena (mesmo menu de pausa).
- Testes: regras 1029/1029 ok.
- **O que testar**: plugue/desplugue o HDMI no meio de uma partida: pode pausar
  uma vez no máximo (se o foco ficar fora mesmo), não em sequência. No Esc,
  confira os três caminhos: Reiniciar partida, Sair para o menu, Sair do jogo.

## Ciclo 2.30 (2026-11-14), Diretor de Jogabilidade + Visual: Predero, o herói do Construtor
Julio: um herói de humor, o **Predero** (escrito errado de propósito, como na
placa da obra), que joga garrafa de cachaça nos inimigos. Único herói novo e o
primeiro do bairro do Construtor (que parava no Nv5). Kit "Mestre de obra".
- **Nv6 do Construtor**: com a casa no Nv5, o tapete do caminho pede o herói
  como nos outros bairros (pavilhão dourado com capacete e garrafa no topo).
- **Ataque, Garrafada**: garrafa em arco (como a bomba), o vidro estoura em
  estilhaço pequeno e deixa o alvo **encachaçado** ("HIC!", pingando): fogo
  nele arde 1,5×. O 3º tiro estoura maior. Garrafa que cai numa poça dele
  espalha o estilhaço pela poça inteira.
- **Q, Poça de Cachaça**: o garrafão voa até a mira e vira poça âmbar (2 por
  vez; a mais velha seca). Inimigo que pisa **derrapa**: a aceleração de andar
  cai para 12% (a = μ·g, μ despenca), então virar ou frear leva ~8× mais. A
  6,4 m/s ele para em 0,3 m no seco e em 2,4 m na poça. Qualquer fogo que
  encosta (até do inimigo) acende: queima quem está em cima e evapora.
- **E, Andaime Expresso**: parede de andaime com lona na cor do time, 4 m de
  largura por 7 s. Bloqueia passagem e tiro (como a árvore do Kodama); quem
  estava no lugar é empurrado; lenhador inimigo desmonta em 3 machadadas.
- **R, Saideira**: o engradado sobe e 8 garrafas chovem em espiral na mira;
  cada uma deixa uma pocinha e a última vem **acesa** e põe fogo nas poças dele.
- Visual: capacete amarelo torto com adesivo do time, bigodão, regata,
  engradado nas costas, cinto de ferramentas; chapéu "capacete" na
  maquininha; selo e figura próprios (garrafa tombando) na assinatura; sons
  sintetizados (vidro quebrando, chuá, fogo de álcool, marretadas).
  Bordões: "Ó O AÇO!", "TÁ NO PRUMO!", "ESCORREGOU!", "Ó O FOGO!".
- Código: regras em `scripts/actors/herois_obra.gd`, poça = `items/poca_cachaca.gd`,
  andaime = `items/andaime.gd`, efeitos em `scripts/fx/fx_obra.gd`.
- **Modo teste e Arena**: o Predero está na fileira dos heróis da Arena de
  chapéus (14 heróis agora) e no sandbox pelo bairro do Construtor.
- Testes: 26 checagens novas (1027/1027), varredura sem suspeito novo, 5 min
  simulados, arena e sincronia online (também com o Predero em campo) ok.
- **O que testar**: na Arena, pegue o capacete do Predero. Q na frente de
  inimigos e veja se eles patinam; jogue uma garrafa na poça; acenda a poça
  com fogo (Saideira ou Yamabushi). Levante o andaime entre você e um Ninja
  atirando. As frases e o tom de humor ficaram no ponto?
