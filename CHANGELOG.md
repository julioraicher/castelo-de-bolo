# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.

## Rodada 14 (2026-10-29), frente Cenário: leva 2 de peças e vila com moradores
- Peças novas (`tools/gerar_mapa_rio.gd`, nos 2 temas): **templo** (dois
  telhados, corda sagrada, altar dourado, incensário, barris de saquê), **casa
  de chá** (janela redonda, bacia de pedra, bordo vermelho, mestre servindo),
  **forja** (fornalha acesa, chaminé com fumaça, bigorna, ferreiro martelando,
  rack de katanas), **dojo** (alunos treinando, pergaminho, bonecos de madeira,
  estandartes), **barco** com barqueiro e **ponte de corda** pênsil.
- **Moradores** (`_aldeao`): bonecos low-poly com poses (vender, varrer,
  martelar, sentado, lanterna, remar, treinar, servir). Fazem parte do modelo
  das casas: vendedor na loja, senhor sentado na varanda (com gato), moça com
  lanterna na varanda da pousada, vendedores nas barracas; grupos conversando
  perto da vila.
- **Fundos e laterais** de todas as casas: janela acesa, porta com noren,
  calha de bambu, barril de chuva, varal com roupas, lenha (a fileira de trás
  mostra os fundos para a câmera).
- No Rio das Lanternas: templo e dojo nos campos fora das muralhas, forja e
  casa de chá na vila (no lugar do sino e do jardim), 4 barcos no rio, pontes
  de corda sobre as cachoeiras. Prancha: `tools/prancha_pecas.gd` aceita
  `peca@180` para mostrar os fundos.
- Teste: 5 min simulados sem erro (8 roubos de máscara, 1 ponto).
- **O que testar**:
  1. Passeie pela vila: as casas parecem "habitadas"? Moradores no tamanho certo?
  2. Templo (campo norte) e dojo (campo sul), perto dos castelos: atrapalham o caminho?
  3. Bots se enroscam na forja, na casa de chá ou nos grupos de moradores?

## Rodada 13 (2026-10-29), frente Jogabilidade: mira honesta com ajuda leve
- Pergunta do Julio: "acertei muitas flechas meio na sorte, tem assistência?"
  Não tinha assistência: o acerto era uma **esfera de 1,25 m** em volta do
  peito, ou seja, um corredor de ~2,5 m de largura para a flecha passar.
- Agora o acerto é a **cápsula do boneco** (0,7 m de raio já somando o
  projétil, dos pés até 2,1 m): corredor de 1,4 m. Vale para todos os
  projéteis (flecha, shuriken, bomba direta, chi, talismã, fogo-raposa).
- **Assistência leve, só do jogador** (`Unit._aim_assist`): se um inimigo está
  a até 7° da mira e no alcance, a mira gira 60% do caminho até ele (errar por
  7° vira errar por ~3°; a 15 m isso ainda é ~0,7 m de erro e pode errar). Nos
  tiros em arco, a flecha cai na distância do alvo assistido. O leque de
  shuriken não tem ajuda.
- Bots seguem com a mira deles (erro de propósito); a taxa de acerto deles
  ficou parecida (~70-75% nas simulações, quase sempre de perto).
- Teste: 5 min simulados no Rio e no Vale sem erro.
- **O que testar**:
  1. Atire em inimigos parados e correndo de longe: dá para errar quando a mira
     está longe, e acertar quando ela está quase em cima?
  2. Ainda parece "na sorte" ou ficou difícil demais? (dá para mexer no cone de
     7° e na puxada de 60%)

## Rodada 12 (2026-10-29), frente Jogabilidade: porradaria com mais peso
- Pedido do Julio: "porradaria insana", mantendo dash e ritmo. Sem partícula
  nova pesada: tudo é câmera, tempo e física (custo quase zero na Intel UHD).
- **Lançar no ar** (`Unit.launch(vy)`): Fúria do Ronin (7 m/s), bomba (até 5,
  cai com a distância), mina (6) e golpe final do combo (3,5) tiram o alvo do
  chão. h = vy²/2g com g = 30: a Fúria sobe ~0,8 m. Quem morre no ar agora cai.
- **Fúria** agora dá hit-stop nos atingidos e no Ronin, e ignora quem está em
  outro andar (muralha/ponte), como os golpes normais.
- **Câmera** (`camera_rig.gd`): coice direcional com mola amortecida
  (x'' = −ω²x − 2ζωx', ζ = 0,45) nos golpes do jogador e quando ele apanha;
  soco de zoom (FOV) no golpe final, no poder e no abate; `shake_at()` faz
  explosões e poderes de bots perto tremerem a tela, caindo com 1/(1+(d/8)²).
  A mola integra em passos de 8 ms: com FPS baixo ela explodia (ω·dt > 2).
- **Poder do jogador**: clarão na cor do papel, zoom e 0,14 s em câmera lenta
  (`Game.slowmo`, usa tempo real e volta sozinho). **Abate do jogador**:
  espírito sobe, tranco e 0,12 s de câmera lenta.
- Desligar "Tremor de câmera" nas Configurações desliga coice e zoom também.
- Flag de print `--print-poder` (com `--shots`): prints logo após cada poder.
- Ideias avaliadas (Hora do Caos, gatilhos de poder) foram para `docs/ideias.md` (B).
- Teste: 5 min simulados no Rio e no Vale (com e sem `--poderes`) sem erro.
- **O que testar**:
  1. Use o Q com algumas classes: o "congela e explode" do poder ficou bom ou
     enjoa? (dá para encurtar ou tirar a câmera lenta)
  2. Pegue o Ronin Oni e use a Fúria no meio do grupo: os inimigos voam?
  3. Bata o combo de 3 golpes: o último joga o alvo para cima e a tela dá tranco?
  4. Leve uma bomba ou pise numa mina: o tremor perto de explosões incomoda?
  5. No PC fraco, notou queda de FPS nos momentos de poder?

## Rodada 11 (2026-10-29), frente Visual: interface no estilo Clãs de Neon
- Pedido do Julio: textos, fontes e visual das informações na tela.
- Fontes livres (OFL) em `assets/fonts/`: **Shojumaru** (pincel japonês) nos
  títulos e mensagens grandes; **Chakra Petch** (painel neon) no resto, também
  nos números de dano e nomes dos pedestais/oficinas. Fonte padrão do projeto
  em `project.godot` (`gui/theme/custom_font`).
- `scripts/ui/estilo.gd` (`Estilo`): cores (noite, ciano, magenta, ouro,
  fogo-fantasma), painéis com borda neon e corte inclinado, tecla desenhada,
  barras e o `Theme` dos menus. `scripts/ui/icone.gd` (`Icone`): ícones por
  código (máscara oni, espírito, katana, shuriken, chi, martelo, losango).
- HUD: placar em placas dos times com losangos de pontos; cartões das duas
  máscaras com frase por situação ("ROUBADA!" pisca em vermelho, "com o seu
  time!" em ciano) e peso em espíritos; cartão do jogador com retrato do papel
  (cor do chapéu), vida com números (fica vermelha abaixo de 30%), Chi com
  tecla [Q] quando cheio; dicas com a tecla desenhada; mensagens grandes
  entram com "soco"; tela de fim com placar.
- Menus: tela inicial com título neon, 3 cartões de dica e controles com
  teclas desenhadas; pausa com abas, botões e listas no mesmo estilo.
  Textos atualizados para as classes ninja.
- Outras frentes: só a fonte nos `Label3D` de `fx.gd`, `hat_pad.gd`, `oficina.gd`.
- Teste: partida simulada até o fim (vitória aos 140 s) sem erro; pacote exportado roda sem erro de fonte.
- **O que testar**:
  1. Dá para ler tudo rápido no meio da briga (placar, estado das máscaras, vida)?
  2. A fonte de pincel nos títulos agrada? E a de texto?
  3. Tela inicial e Esc: os botões e as listas ficaram claros?
  4. Algo grande demais, pequeno demais ou cobrindo a ação?

## Rodada 10 (2026-10-29), frente Cenário: mapa Rio das Lanternas com altura
- Julio escolheu a ideia 1 (Rio das Lanternas) misturada com a Vila Neon, com
  mais cobertura no meio e mais altura. Mapa novo `config/mapas/rio_lanternas.tres`
  (padrão; o Vale Ninja continua em Esc > Configurações > Mapa).
- Rio no meio (norte-sul) com **3 pontes arqueadas**: a grande no centro (8 m)
  e duas laterais (4,6 m). O rio bloqueia; só se cruza pelas pontes.
- **Vila neon** dos dois lados da estrada: casas, loja com toldo, pousada de 2
  andares, armazém, barracas de festival, poço, sino, jardim zen, postes de
  lanterna, varais e torii nas cabeceiras das pontes.
- **Altura**: 4 colinas de 2,4 m (com escada dos dois lados, pagode ou torre de
  vigia em cima); castelos com **muralha andável** (3,2 m) e escada no pátio
  (`MapLayout.wall_height/wall_thickness/wall_parapet`).
- Cobertura no meio: rochas, barricadas, jizos, pilhas de sacos, bambuzais.
- 29 modelos novos por tema em `tools/gerar_mapa_rio.gd` (estende o gerador
  base); prancha das peças: `tools/prancha_pecas.gd`.
- **Mudanças em outras frentes** (pedidas para a altura funcionar):
  `Arena.ground_y()` (chão real por raio), mira balística até a altura do
  alvo, golpes/explosões/armadilhas/áreas ignoram quem está 2+ m acima ou
  abaixo, câmera mira no chão real, máscara cai no chão de verdade;
  `MapProp` com colisão "caixa" (tamanho, giro, deslocamento; modelo vazio =
  só colisão); `MapLayout.wall_model/tower_model/flag_height`;
  `GameConfig.maps` + opção Mapa no menu (`Settings.mapa`, flag `--mapa=N`);
  modelos com cor por vértice são juntados em blocos de 34 m (2 draw calls por bloco).
- Teste: 5 min simulados no Rio (Oni e Luar) e no Vale sem erro; roubos de
  máscara no Rio parecidos com o Vale (4 x 5).
- **O que testar**:
  1. Atravesse o rio pelas 3 pontes. A briga fica concentrada nelas? A ponte do
     meio é larga o bastante?
  2. Suba na muralha pela escada do pátio e numa colina. Atirar lá de cima é
     forte demais? (bomba e flecha miram no chão onde o alvo está)
  3. Alguma casa/peça esconde demais a luta? Algum bot fica preso?
  4. FPS no Rio comparado ao Vale (Esc > Configurações > Mapa).

## Rodada 9 (2026-10-29), frente Cenário: mapa atual com cenário ninja
- Julio escolheu os climas C (Floresta Oni) e B (Templo ao Luar), nessa ordem.
  Viraram os 2 temas do jogo (`config/temas/oni.tres` padrão, `luar.tres`);
  Medieval e Sinistro saíram da lista (arquivos continuam no repo).
- Mapa `config/mapas/vale_ninja.tres`: mesmas posições de jogo do Vale (pedra no
  meio da estrada, bosques, castelos), mais torii nos portões, estátuas oni /
  komainu, varal de lanternas no centro, lanternas de pedra, santuários, pagodes,
  ruínas, rochas, tronco caído, lagos e cercas de bambu.
- Modelos por código: `tools/gerar_cenario_ninja.gd` gera `assets/ninja/{oni,luar}/*.scn`
  (castelo japonês com telhados na cor do time, torres baixas no portão para não
  esconder a briga, muros com telhadinho, estandartes nobori), os 2 temas e o mapa.
  Cada modelo é 1 malha com 2 materiais (fosco + brilho), juntado em MultiMesh.
- Chão rico: `ThemeConfig.decor_campo` / `decor_estrada` espalham capim, pedrinhas,
  folhas/pétalas, cogumelos brilhantes/flores, brotos, lanternas de chão e lajotas
  (semente fixa, sem colisão, sem sombra). `particulas`: fogo-fantasma subindo
  (Oni) ou pétalas caindo (Luar); some na qualidade Baixa/Mínima.
- `ThemeConfig.flag_height` (altura da bandeira na torre; padrão 7 mantém o antigo).
- Flags de print: `--tema=N` e `--vista=mapa|alto` (câmera parada, sem HUD).
- Teste: 5 min simulados nos 2 temas sem erro.
- **O que testar**:
  1. Jogue uma partida no tema padrão (Floresta Oni). Dá para ver bem os bonecos
     e as brigas no portão? Alguma árvore/torre atrapalha a visão?
  2. Esc > Configurações > Tema do mapa: troque para Templo ao Luar e compare.
  3. FPS: o chão cheio de enfeites pesou? (se pesar, a qualidade Baixa tira as partículas)
  4. Bots se enroscam em alguma peça nova (pagode, ruína, rochas, estátuas)?

## Rodada 8 (2026-10-29), frente Visual dos personagens: mundo ninja no jogo
- Visual: `scripts/actors/ninja_visual.gd` monta as peças de cada estilo (kabuto,
  máscara oni, kasa, eboshi, orelhas de raposa...) numa malha só presa aos ossos
  (1 draw call por boneco), shader toon com aro na cor do time
  (`assets/shaders/toon_time.gdshader`) e contorno (`contorno.gdshader`).
  Cabeça 0,8 via `EscalaOssos` (modificador de esqueleto).
- 12 classes (4 papéis x 3 variações) + Recruta, geradas por `tools/gerar_classes.gd`.
  Campos novos em `ClassStats`: `estilo_ninja`, `escala_cabeca`, `escala_modelo`,
  `projetil`, `explosao_raio`, `trap_kind`, `velocidade_obra`; poderes novos
  (fúria, corte relâmpago, leque, nuvem, selo, coluna de fogo, reforço, mutirão).
  Poderes de área em `scripts/fx/area_effect.gd`; `Fx.beam/zap/cracks`.
- Projéteis: shuriken (reto, gira), bomba (arco até o chão, explode com dano
  que cai linearmente com a distância), talismã, fogo-raposa, chi.
- Construtor simples: toda variação constrói; o poder é de apoio, não de dano.
- Oficinas (`scripts/items/oficina.gd`): 2 terrenos por castelo
  (`MapLayout.oficina_spots`), o time escolhe a variação ([E] no terreno),
  construtores erguem (dP/dt = soma de `velocidade_obra` / `oficina_build_time`);
  pronta, ganha pedestal da variação. Bots construtores vão até o terreno.
- Animações: inclinação na corrida, achatamento ao levar golpe, machadadas na
  obra, levantar do chão ao renascer, comemoração ao pontuar, gesto ao pegar item,
  arremesso nos atiradores.
- Itens no chão novos: kunai (dano 2x por 6 s) e chama de chi (enche o medidor).
- Tema: princesa → Máscara Oni, bolo → espírito (hitodama), Glacê → Chi. Nomes
  de classe no código ficaram (`Princess`, `Cake`), com comentário.
- Outras frentes (mudanças em `scripts/`, `config/game_config.tres`,
  `map_layout.gd`/`arena.gd`, HUD/menus, CONTROLES.md): feitas por esta frente
  a pedido do Julio. Flags de teste: `--variacoes` (bots com todas as classes) e
  `--poderes` (enche o medidor a cada 4 s).
- Teste: 5 min simulados sem erro; oficinas prontas entre 22 e 90 s.
  Prancha: `personagens/05-ninjas-no-jogo.png` nos arquivos do projeto.
- Falta: cenário ninja (noite neon). Proposta vai para pitaco antes de montar.
- **O que testar** (no navegador ou no .exe da main):
  1. Pegue cada chapéu do pátio e olhe o visual e o ataque (shuriken, flechas, chi).
  2. Vire Construtor, vá até um terreno do castelo, aperte E para escolher a
     variação e fique perto até a casinha subir. Pegue a variação nova no pedestal.
  3. Encha o Chi (Q) com cada classe e veja se o poder é claro e forte o bastante.
  4. Kunai (dano 2x) e chama de chi no chão: dá para ver e pegar?
  5. Leve a Máscara Oni inimiga ao seu pedestal; leve espíritos à sua máscara.

## Rodada 7 (2026-10-29), frente Jogabilidade: Construtor, itens no chão, Monge e Recruta
- Tema (princesa/bolo x Máscara Oni/espíritos) **não** mudou: o Julio ainda
  compara 3 mundos. Os nomes de classe abaixo são provisórios.
- Clérigo → Monge (`monge.tres`) e Aldeão → Recruta (`recruta.tres`, sem poder).
- Construtor (`construtor.tres`, 4º chapéu, modelo Barbarian com machado,
  chapéu cônico `kasa`): clique direito espalha estrepes (`scripts/items/trap.gd`):
  quem pisa leva 15 de dano e fica 50% mais lento por 2 s; até 3, recarga 4 s.
  Poder no Q: Corrida (o poder que era do Aldeão).
- Itens no chão (`scripts/items/pickup.gd`): poção (50% da vida), escudo (40
  por 8 s) e velocidade (1,35x por 6 s). Um a cada 15 s, no máximo 3.
  Números em `game_config.tres` > Itens no chão.
- Bots: Construtor arma estrepes com inimigo a até 7 m (ou na defesa do portão);
  qualquer bot desvia até 10 m para pegar item se não houver inimigo colado.
- Outras frentes (mudança mínima): `config/classes/` (renomes + construtor) e
  `config/mapas/vale.tres` (4º lugar de chapéu em (-3, 8.5); mesmo padrão em
  `map_layout.gd`).
- Teste: 5 min simulados sem erro; até 6 estrepes simultâneas, itens sendo pegos.
- Hora do Caos ficou para depois (precisa de relógio de partida).

## 2026-10-29, frente Identidade: mundo ninja e variações
- Mundo escolhido: Clãs de Neon (ninja). Cabeça menor, um pouco mais realista.
- `docs/design-jogo.md`: 3 variações por papel com 2 poderes cada; o time
  escolhe qual oficina construir (poucos terrenos por castelo).

## 2026-10-29, frente Identidade: direção v1 depois do quiz 2
- `docs/identidade.md`: direção v1 = Clãs de Neon com lado sombrio; Máscara Oni
  + espíritos substituem princesa + bolo; Brawl Stars 1:3; noite neon; bloco de estilo.
- `docs/design-jogo.md` (novo): 4 papéis com versões, progressão por oficinas,
  poderes rápidos x fortes, gatilhos, itens no chão, mapa e partida.
- `docs/ideias-futuras.md` (novo): jogo de espionagem/hackers pixelado.
- ROADMAP: Fase 2 reescrita a partir do design. Nenhum código mudou ainda.

## 2026-10-29, frente Identidade: diário e quiz
- `docs/identidade.md`: diário de nome, tema, estilo geral, logo e divulgação,
  com as restrições que qualquer estilo precisa respeitar e o bloco de estilo.
- Prompt do Gemini descartado: conceitos serão pranchas 3D feitas aqui.
  Quiz de identidade com 8 mundos candidatos (link no `docs/identidade.md`).
- CLAUDE.md: frente Identidade na tabela de frentes.

## Rodada 6 (2026-10-29), frente Jogabilidade: combate e poderes
- Combate com peso: hitstop de 60 ms no impacto (atacante e alvo congelam),
  golpe só no tronco (dá para bater correndo), rastro do golpe, reação
  Hit_A/Hit_B e morte Death_A/Death_B ao acaso.
- Combo de 3 golpes (Guerreiro: diagonal, horizontal, de cima; Aldeão: soco,
  soco, chute). O 3º dá 1,4x dano e empurrão, rastro dourado e hitstop maior.
- Botão direito (segurar): Guerreiro bloqueia 70% pela frente; Arqueiro
  carrega o tiro (até 1,6x dano, 1,5x velocidade, linha de mira); Clérigo cura.
- Flechas em parábola: caem na distância do mouse (6 m até 1,4x o alcance).
- Medidor de Glacê (0 a 100, no HUD) e poder no Q: Redemoinho, Chuva de
  flechas, Bênção (cura 40% + escudo 25), Corrida do bolo (+40% velocidade).
  Números em `game_config.tres` (fontes do medidor) e nos `.tres` das classes.
- Bots usam o tiro carregado e os poderes (`BotBrain._should_use_power`).
- Tela cheia: tecla F ou F11 (também no navegador); no navegador o Esc fica
  travado em tela cheia (Keyboard Lock); o jogo pausa sozinho ao perder o foco.
- Sons novos: bloqueio, poder, medidor cheio (`tools/gerar_sons.py`, `combate()`).
- Mexeu em `config/classes/*.tres` (só números de jogabilidade: combo, skill, power).

## Rodada 5 (2026-10-29): reorganização para mudanças fáceis
- Temas em `config/temas/` (luz, céu, neblina, chão, modelos, cores dos times).
  Novo tema de exemplo "Sinistro (noite)". Troca em Esc > Configurações > Tema.
- Mapa em `config/mapas/vale.tres` (arena, muralhas, torres, pedestais, objetos).
- Classes: lista do pátio e classes iniciais dos bots em `game_config.tres`;
  formato do chapéu (`hat_style`) no `.tres` de cada classe.
- Qualidade gráfica com 4 níveis (Mínima = 3D a 50% da resolução) e
  qualidade automática: baixa sozinha se o FPS ficar < 40 no começo.

## Rodada 4: barra de vida, música, chapéu
- Barra de vida voltou a diminuir (billboard sem `keep_scale`).
- Música audível, com loop nativo e canais de áudio fixos.
- Chapéu só com E, com animação de pegar e pôr na cabeça andando.
- Corpo de cada personagem numa malha só (menos chamadas de desenho).

## Rodada 3: fluidez e dificuldade
- Interpolação de física; decoração repetida em MultiMesh; Difícil suavizado.

## Rodada 2: combate e desempenho
- Bug do empurrão (~45 m por golpe) corrigido; qualidade gráfica e contador de FPS.

## Rodada 1: primeira versão pública
- Personagens invisíveis no export corrigidos; tela inicial, pausa,
  controles e configurações.
