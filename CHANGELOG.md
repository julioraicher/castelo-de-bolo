# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.
Entradas até a Rodada 19 estão em `docs/changelog-antigo.md`.

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

## Ciclo 2.28d (2026-11-14), Diretor de Jogabilidade: online sem partida "separada"
Julio: jogando com o amigo, de repente cada um estava numa partida diferente
sem perceber; o nome do outro continuava no placar, "congelado".
- **Causa achada**: não foi queda, foi **dessincronia**. Tiro de longe de um
  humano congela o alvo por ~30 ms (hitstop), mas só no PC de quem atirou
  (`is_player`). No outro PC o alvo seguia andando e, como a briga é caótica,
  os dois jogos se afastaram e cada PC passou a mostrar um mundo. Agora vale
  para qualquer humano em todos os PCs (`Unit.take_damage`). O teste antigo
  não via porque o "humano" de teste só andava pela base de recruta.
- **Se separar de novo** (outra causa que ainda não conheço): aviso grande na
  tela e, em 5 s, **todos voltam para a sala** com a mensagem do que houve
  (quadro e boneco onde separou, para o Claude achar a causa). É só Começar de
  novo. Antes aparecia uma frase por 6 s e o jogo seguia separado.
- **Se alguém cair** (internet piscou, PC travou): quem caiu volta **sozinho**
  para a sala pelo mesmo código; enquanto o anfitrião estiver na partida, a
  tela dele diz "espere". O anfitrião vê "Fulano caiu: um bot joga no lugar ·
  Esc → Voltar à sala (todos)" fixo no alto. Quem caiu sai da lista da sala;
  quando volta, entra de novo. O amigo que fica 30 s sem nada do anfitrião
  também é tratado como queda (antes podia ficar parado esperando).
- Online, Configurações não mostra mais Tema e Mapa (trocar ali recarregava só
  o seu PC e separava a partida).
- Testes: humano de teste agora vai para cima do inimigo e mira nele; rede com
  **todas as 26 classes** como humanos (todas batem); `tools/teste_queda.sh`
  (queda e dessincronia: voltam para a sala e a partida nova bate) no CI;
  rede com Yumi no CI; checagem nova em tests/regras.gd. Modo teste não muda
  (é coisa do online).
- **O que testar**: baixem o zip novo (os dois). Joguem de Yumi ou Ninja
  atirando um no outro e nos bots por uns minutos: tem de continuar junto. Para
  testar a queda, o amigo desliga o Wi-Fi uns 10 s no meio: ele cai, a tela
  dele diz que está tentando voltar, você vê "caiu" no alto; Esc → Voltar à
  sala (todos) e ele aparece na sala sozinho.

## Ciclo 2.29b (2026-11-14), Diretor de Jogabilidade: arena mais simples + revisão dos poderes
Julio: o tambor gerava herói demais, o inimigo soltava poder sem parar (a
aranha), um poder parecia bugado e às vezes o jogo dizia que não tinha inimigo
"na frente" com o inimigo ali.
- **Dois tambores**: o vermelho (**Tambor de Desafio**) chama só **classe base**
  (Samurai, Ninja, Kitsune, Construtor, Ronin); o dourado com faixa roxa
  (**Tambor dos Heróis**) chama caminho Nv2-5 ou herói raro.
- **Inimigo da arena no ritmo normal**: o modo teste dava Chi, Super e Q
  rápidos para TODO mundo, inclusive o inimigo gerado. Agora só você recarrega
  rápido (`Game.recarga_rapida`).
- **Varredura de poderes** (`--varredura-poderes`, tests/varredura_poderes.gd):
  usa Q, E e R das 26 classes com um inimigo parado e alinhado na frente e
  aponta o que não saiu ou não fez nada. Achou:
  - **Bug real: trocar de chapéu no meio de um poder** (Ciranda, Redemoinho,
    Muralha, Fúria) deixava o poder antigo girando com os números da classe
    nova e **travava o Q** dela até acabar. Agora a troca encerra o poder.
  - **"NINGUÉM NA FRENTE / NINGUÉM PERTO" com inimigo ali**: Flecha Arrancada
    (Ochimusha), Roubar Rosto (Mujina), Agarrão (Sumotori) e Mordida (Shishimai)
    mediam de centro a centro, num cone estreito. Agora medem até a borda do
    corpo, a Flecha tem cone de 100° (era 80°) e **o inimigo sob o cursor vale
    primeiro** (`Herois.alvo_toque`).
  - Laço do Manto (Tennin) sem aliado longe falhava calado: agora diz
    "NENHUM ALIADO LONGE".
  - Os outros 11 "sem efeito" são de propósito (cura sem ferido, mina, anel do
    Dohyō, Véu...): lista com o motivo em `POR_DESENHO` na varredura.
- Testes: 10 checagens novas (994/994), varredura 0 suspeitos, 5 min
  simulados, arena com tambor automático e sincronia online ok.
- **O que testar**: na Arena, o tambor vermelho deve dar só classe base e o
  inimigo não pode mais spammar poder. Pegue Kusarigama, solte o E e troque de
  chapéu no meio: a corrente para. De Ochimusha/Mujina, mire no inimigo com o
  cursor e use Q encostado: não deve mais dizer "NINGUÉM". Se o poder que você
  achou bugado continuar estranho, me diga qual é.

## Ciclo 2.29 (2026-11-13), Diretor de Jogabilidade: Arena de chapéus
Pedido do Julio: um terceiro "mundo" de testes com os chapéus de todos os
personagens lado a lado e um botão que gera um inimigo aleatório na frente.
- **Novo modo na tela inicial** (Partida → "Arena de chapéus"; `--arena` ou
  `?arena` na web): campo de testes na frente do portão do seu castelo, com
  **4 fileiras de maquininhas**: as classes base, os caminhos Nv2-5 e os 13
  heróis raros em duas fileiras. Todo chapéu à mão, com reposição em 1 s.
- **Caminho veste no nível máximo** (Kitsune Luz/Sombria com 5 caudas, bônus
  cheios) e **herói com o bônus de herói**: é a forma final de cada classe.
- **Tambor de Desafio** ao lado do spawn: aperte [F] nele e nasce um inimigo
  de classe sorteada (qualquer uma, heróis inclusive) a 6 m na direção da sua
  mira. Ele caça você, não rouba a máscara, e **some ao cair** (não renasce).
  Máximo de 6 em campo ao mesmo tempo.
- Por dentro o modo liga o sandbox: mapa leve, sem bots, sem relógio, Chi/Super
  rápidos, madeira infinita. Ponto de máscara não encerra a partida na arena.
- QA: `--autoplay --arena-prova=N` toca o tambor sozinho a cada N s (sem
  teclado). 20 testes de regra novos (sorteio completo, fileiras, níveis).
- **O que testar**: na tela inicial, troque Partida para "Arena de chapéus".
  Pegue chapéus das 4 fileiras (heróis ao fundo, perto do rio) e bata no
  tambor vermelho para brigar. O inimigo some sozinho depois que cai?
  As fileiras ficaram bem espaçadas no seu PC?

## Ciclo 2.28c (2026-11-13), Diretor de Jogabilidade: conexão automática por código (sem Radmin)
Julio: o roteador não abriu a porta ("Código da internet: indisponível") e o
Radmin é complicado demais. Escolheu a conexão automática (WebRTC) e autorizou
a extensão oficial do Godot.
- **Criar sala** agora sorteia um **código de 8 letras** e liga os PCs **direto**
  por WebRTC: ICE + STUN (Google e Cloudflare) fura o NAT, inclusive a maioria
  dos CGNAT. **Nenhuma porta aberta no roteador** e ninguém instala nada.
- **Quadro de recados** (`scripts/rede/sinal.gd`): antes de ligar, os PCs trocam
  meia dúzia de recados pelo ntfy.sh (serviço público sem conta) num tópico tirado
  do código, **cifrados** (AES-256 + HMAC, chave tirada do código) e sem cache.
  O ntfy só vê lixo; sem o código ninguém acha, lê ou forja recado.
- Se a ligação direta não passar (NAT muito fechado dos dois lados, ~10-20%), a
  tela diz isso; plano B: os dois no Radmin VPN e **o mesmo código**.
- Extensão `godotengine/webrtc-native` 1.2.2 (oficial), baixada no CI por
  `tools/baixar_webrtc.sh` com **SHA-256 fixo** (só Windows/Linux x86_64; `lib/` fora
  do git). O CI barra o .exe se a DLL não for junto.
- **Bug consertado (vale para o Radmin também)**: o amigo podia cair ao carregar a
  partida (o ENet derrubava quem ficava 5 s sem responder; agora 30 s) e um
  comando que chegasse antes de o anfitrião montar o jogo se perdia (travava no
  quadro 3). O limite de espera agora é em tempo de verdade.
- Ping medido pelo próprio jogo (funciona nos dois transportes).
- Testes: 6 checagens novas (código sorteado, recado cifrado volta igual, outro
  código não lê, adulterado é ignorado); `tools/teste_rtc.sh` (dois jogos ligados
  por WebRTC, recados por pasta) no CI; o mesmo pela internet de verdade como aviso.
- Sala de teste (2 janelas) continua por ENet local.

**O que testar**
- Você: Com amigos → Criar sala → "Copiar código" → manda pro amigo.
- Amigo: cola o código → Entrar (sem Radmin). Liga? Quanto de atraso a sala mostra?
- Se o Windows perguntar do firewall, permita.

## Ciclo 2.28b (2026-11-13), Diretor de Jogabilidade: porta do roteador mais insistente + blindagem
Julio criou a sala e apareceu "Código da internet: indisponível".
- **UPnP insiste**: procura o roteador duas vezes (3 s cada, a segunda aceitando
  qualquer aparelho), pede a porta com prazo de 2 h e, se recusar, permanente.
  A porta com prazo fecha sozinha se o jogo fechar sem apagar.
- **A sala diz o motivo**: roteador não respondeu (UPnP desligado), roteador
  recusou, ou CGNAT da operadora; e avisa para criar a sala de novo depois de
  instalar o Radmin. Dica do firewall do Windows (marcar rede pública também).
- **Blindagem** (revisão de segurança): o anfitrião só aceita comando do tamanho
  certo (17 bytes) e no máximo 64 quadros à frente (um jogo adulterado não enche
  a memória nem a rede dos outros); nome vindo da lista da rede local cortado em 14.

**O que testar**
- Criar sala: a linha de baixo agora diz qual dos três casos é o seu.

## Ciclo 2.28 (2026-11-13), Diretor de Jogabilidade: multiplayer com amigos
Julio: "quero jogar com meus amigos no modo multiplayer, a gente escolhe o lado
azul ou vermelho". Quiz respondido com todas as recomendadas (1A 2B 3A 4AB 5A)
+ 8v8 sempre, trocar de time no meio, nome em cima da cabeça, atraso mínimo.
- **Como funciona (lockstep determinístico)**: cada PC roda a partida inteira e
  pela rede só passam as **intenções** de cada humano (17 bytes por quadro:
  botões, movimento, mira). Um comando lido no quadro t vale no quadro
  t+atraso em todos os PCs, inclusive no de quem apertou. O anfitrião junta e
  repassa; a cada 2 s todos comparam um resumo do estado (dessincronia = aviso).
  O **atraso se ajusta ao ping** (2 a 9 quadros; rede local/Radmin ≈ 33 ms).
- **Jogo determinístico** (parte 1, d2b4655): sorteio de regra em `Sorte`
  (semente da sala), relógio de regra em `Sorte.ms()`, tweens/timers de regra
  na física, navegação sem iteração assíncrona, câmera lenta desligada online,
  torreta sem ler o transform visual. Mesma semente = mesma partida em 60 ou
  23 FPS (5 min idênticos).
- **Menu "Com amigos"** (botão na tela inicial): seu nome, **Criar sala**
  (abre a porta do roteador sozinho por UPnP e mostra um **código de 8 letras**
  tipo `K7QF-M9X2` para mandar no WhatsApp) ou **Entrar** (código, ou o IP do
  Radmin VPN), e a lista das **salas da sua rede** (aparecem sozinhas).
- **Sala**: duas colunas azul × vermelho com 8 vagas; vaga vazia = bot (os
  bots dividem os papéis entre si). Clique numa vaga para ir; o anfitrião (★)
  clica num amigo e depois numa vaga para movê-lo, ajusta tempo (10/15 min) e
  dificuldade dos bots e pode embaralhar. Amigos marcam **Pronto**; o anfitrião
  pode começar mesmo assim.
- **Na partida**: nome em cima da cabeça de cada humano (cor do time), Esc não
  pausa (o menu fica por cima), **Trocar de time** no Esc (você assume um bot
  do outro lado e o seu boneco vira bot), anfitrião tem **Voltar à sala
  (todos)** para a revanche, "Sair da partida". Quem cai vira bot; anfitrião
  caiu = partida acaba. Bots do time com humano seguem as regras de time do
  jogador (dano normal, sem bônus). F5 não reinicia online.
- Só no **.exe** (o navegador não deixa abrir sala); todos com a mesma versão
  (o CI carimba o commit) e o mesmo sistema (Windows com Windows).
- **Modo teste**: botão **"Sala de teste (abre 2 janelas neste PC)"** no Com
  amigos: abre a sala e uma segunda janela que entra nela.
- Testes: 17 checagens novas em `tests/regras.gd` (`_multiplayer`); CI ganhou
  `tools/teste_sincronia.sh` (60 × 23 FPS) e `tools/teste_rede.sh` (anfitrião +
  amigo de verdade em 127.0.0.1, 37 FPS).
- Arquivos novos: `scripts/rede/` (`rede.gd` autoload, `comando.gd`,
  `rede_brain.gd`, `codigo_sala.gd`, `sorte.gd`), `scripts/ui/lobby.gd`. Mexi de
  leve em `unit.gd` (`humano` separado de `is_player`, `set_nome_tag`),
  `placar.gd`, `reanimar.gd`, `hud.gd`, `menus.gd`, `settings.gd`, `config.gd`.

**Como jogar com amigos**
1. Todos baixam o mesmo .exe da release "ultima-versao".
2. Você: Com amigos → Criar sala → "Copiar código" → manda no WhatsApp.
3. Eles: Com amigos → cola o código → Entrar → escolhem a vaga → Pronto.
4. Se o código não conectar (roteador sem UPnP ou internet com CGNAT, aparece
   "indisponível"): todos instalam o **Radmin VPN** (grátis), entram na mesma
   rede dele, e os amigos digitam o IP 26.x que aparece na sua sala.

**O que testar**
- Sala de teste no mesmo PC: as duas janelas na sala, mude de vaga, Pronto, Começar.
- Com um amigo: o código conecta? Quanto aparece de atraso na sala?
- Dash, golpe e poder: dá para sentir o atraso? (rede local ≈ 33 ms)
- Esc → Trocar de time no meio da partida; nome em cima da cabeça.
- Fim da partida → anfitrião: Esc → Voltar à sala (todos) para a revanche.
- Se aparecer "dessincronia" na tela, me mande o print (é bug de regra).

## Ciclo 2.27c (2026-11-13), Diretor de Jogabilidade: máscara mais pesada no começo
Julio: "tomei 3 pontos logo no começo, a máscara ainda tá andando muito rápido".
- A máscara agora **nasce com peso 0,3** (três espíritos já orbitando), em vez
  de 0. O primeiro roubo anda ~11% mais devagar que antes; dali em diante tudo
  segue o 2.25 (almas até 0,75, espíritos até 1, morte súbita zera o peso).
- Número novo `peso_inicial` em `game_config.gd` (padrão 0,3; ajustável no
  `game_config.tres`). Teste novo `_mascara_pesada` em `tests/regras.gd`.
- Modo teste: as máscaras também nascem com 0,3 (mesma regra, nada a ligar).

**O que testar**
- Começo da partida: as duas máscaras já com 3 espíritos e a barra de peso no HUD em 30%.
- Roube a máscara nos primeiros minutos: deve dar mais tempo para o inimigo te alcançar.
- Diga se ficou pouco (0,4 ou 0,5 é só trocar o número).

## Ciclo 2.27b (2026-11-13), Diretor de Jogabilidade + Diretor Visual: Kodama e Kaminari-kozō (parte 2 de 2)
Fecha o quiz da thread "Criar quatro personagens novos": o Kodama que o Julio
escolheu e o quinto de raio criado por nós (Julio: "encaixar onde bem
entender, sem ser na casinha do construtor"). Agora são 13 heróis raros.
- **Kodama do Shinboku** (Kitsune, 4º herói do bairro): básico atira
  **sementes** em arco; o 3º tiro brota nos pés de quem acerta e prende 0,5 s.
  Q **Raízes**: uma linha de 8 m rompe o chão, fere e prende 1 s. E **Bosque
  Sagrado**: três árvores nascem onde ele mira (até 9 m) e ficam 12 s. **O tronco
  é sólido**: bloqueia passagem e tiro dos dois times; a sombra cura os aliados
  (8/s, não acumula com várias árvores). R **Floresta Antiga**: um anel de dez
  árvores gigantes de 10 m em volta dele por 8 s; a cada 2 s as raízes prendem e
  ferem quem é do outro time dentro do anel e os aliados de dentro recuperam vida.
  O Construtor (qualquer lenhador) derruba uma árvore em 2 golpes (gigante: 4) e
  ganha 1 tora.
- **Kaminari-kozō** (Ninja de Shuriken, 5º herói do bairro): o menino do
  trovão. Básico é um **trovão** reto que solta faísca em quem passa perto; o 3º
  estoura em raios (área de 2,5 m, não queima nada). **Carga estática**: correr
  carrega (mais rápido, mais carga), o dash dá +35% e o Relâmpago +50%. Com a
  carga cheia o cabelo faísca e a HUD mostra "CARGA CHEIA"; o próximo golpe que
  acertar solta a **descarga**: +16 de dano, prende 0,4 s e pula para até 3
  inimigos a 5 m. Q **Para-raios**: crava uma baqueta de cobre (até 2, 6 s) que dá
  choque em volta a cada 1 s; a descarga perto dela também estoura nela. E
  **Relâmpago**: vira raio e salta 9 m em linha (para antes da parede), ferindo
  quem estiver no caminho. R **Tambores do Trovão**: 6 s de tempestade; a cada
  0,5 s um raio do céu cai no inimigo mais perto dele ou de um para-raios dele.
- **Reações novas** (quiz 3B): **molhado conduz** (a água do Kappa molha 4 s:
  raio fere 50% mais e a descarga pula o dobro da distância); **fogo queima o
  bosque** (a árvore vira tocha 2 s, fere o time dela em volta e cai);
  **a árvore do Kodama é para-raios** (raio que cai a até 4 m dela cai nela e ela
  pega fogo). Fogo do próprio time não queima.
- **Dash com peça** nos dois (quiz 4B): o Kodama afunda num tufo de raízes e
  brota adiante; o Kaminari-kozō vira um risco de raio.
- **Visual** (princípio 13): Kodama com máscara de madeira entalhada (olhos
  ocos acesos na cor do time), galhos de chifre, coroa de folhas, corpo de
  casca, shimenawa com papéis shide na cintura, musgo do time e cajado de muda.
  Kaminari-kozō pequeno, cabelo espetado com pontas acesas, chifrinhos de oni,
  tanga de tigre, baquetas e o anel de seis tambores nas costas (pele com o
  tomoe do time). A **árvore do Kodama** é a do santuário: tronco torcido, três
  nuvens de copa podadas (as de fora na cor do time), shimenawa com shide e
  raízes com musgo, no material pintado do tema (vento, sombra e raio X iguais
  aos do cenário), uma chamada de desenho por árvore. Raios em zigue-zague com
  galho, que piscam e se rasgam (kit Magia, paleta "raio"). Chapéu no chão,
  enfeite e emblema no pavilhão, selo, verbo (`brota`, `troveja`) e figura do R
  próprios (cedro brotando; tambores no céu, cada batida um raio).
- **Sons** sintetizados (`gerar_sons.py herois227b`): madeira rangendo (atrito
  de aderência e deslize), folhas, terra rachando; estalo de faísca, zumbido,
  carga subindo e trovão (estalo da onda de choque + ronco dos ecos).
- Bots usam os seis poderes (Bosque entre ele e quem persegue a máscara,
  Relâmpago para fugir ferido, R com dois ou mais em volta).
- Testes de regra 857/857 (47 novos dos dois e das três reações).
- Sonda com heróis (`HEROIS=1 tools/sonda_equilibrio.sh`, 8 partidas, ~9 min
  vivo cada; abates e dano por min vivo): a 1ª versão deu Kaminari-kozō 3,0
  abates/614 de dano (o dobro dos outros) e Kodama 0,2/137. Ajuste: Kaminari
  dano 12→10, descarga 22→16, raspão do trovão 35→25%; Kodama dano 12→14, Raízes
  14→16, sombra 2,6→3,2 m e cura 6→8/s. Depois: **Kaminari 2,0/407**, **Kodama
  0,9/262 (+48 de cura)**; Yamabushi 1,5/492, Sohei 1,4/354, Shishimai 1,4/220.
  Amostra pequena: o pitaco do Julio manda.
- **Modo teste**: os dois já estão no painel do pavilhão; suba a casa da
  Kitsune (Kodama) ou do Shuriken (Kaminari-kozō) até o Nv5 e escolha.
- **O que testar**: com o **Kodama**, plante o Bosque na frente de quem vem
  (eles têm que contornar, e tiro bate no tronco) e fique na sombra ferido; solte
  a Floresta Antiga no meio de uma briga. Com o **Kaminari-kozō**, corra até o
  cabelo faiscar e bata num grupo (a descarga pula), crave um para-raios e use os
  Tambores perto dele. Junte um Kappa (água) com o raio e uma Kitsune (fogo) com
  o bosque para ver as reações.

## Ciclo 2.27 (2026-11-13), Diretor de Jogabilidade + Diretor Visual: três heróis novos do Nv6 (parte 1 de 2)
Quiz do Julio (thread "Criar quatro personagens novos"): Ochimusha, Shishimai,
Jorogumo e Kodama + um quinto de raio criado por nós (Kaminari-kozō), reações
óbvias entre elementos, o dash solta a peça do personagem, direto na `main`.
Plano completo em project-files `castelo-de-bolo/herois/plano-5-herois-novos.md`.
Esta parte traz os três primeiros; Kodama, Kaminari-kozō e as reações de raio e
bosque vêm na parte 2.
- **Ochimusha** (Samurai, herói raro): **não cai de primeira**. O golpe que o
  mataria deixa 1 de vida e ele vira fantasma intocável por 3 s; se derrubar
  alguém nesse tempo volta com 35% da vida, senão cai (uma vez por vida). Golpe
  final do combo deixa um **corte que ecoa** 0,6 s depois. Q **Flecha Arrancada**:
  arranca uma das 4 flechas das costas e crava em quem está na frente (dano +
  lento); as flechas são as cargas do Q (a HUD mostra ×N). E **Onibi**: três
  fogos-fantasma giram em volta 5 s e estouram em quem encosta (dano + susto).
  R **Carga dos Caídos**: quatro samurais-fantasma avançam 12 m em linha.
- **Shishimai** (Samurai): **Sorte e Azar**. Q **Mordida da Sorte**: aliado
  cura 15% e ganha Sorte (o próximo golpe dele sai dobrado e o próximo que levar
  desvia); inimigo leva dano e Azar (o próximo golpe dele erra). E **Arrastão**:
  avança 8 m levando o primeiro inimigo na boca (derruba a máscara) e o prende no
  fim. R **Festa da Vila**: vira o leão gigante por 7 s, dá Sorte aos aliados
  perto a cada 2 s e levanta aliado caído que alcança.
- **Jorogumo** (Ninja de Shuriken): básico é um **fio de seda** que gruda
  (lentidão que acumula até 3); o 3º tiro (Rede) prende 1 s. Q **Teia** no chão
  (até 3, 10 s): inimigo que pisa fica preso 1 s, ela corre 40% mais em cima.
  E **Puxar os Fios**: quem ela marcou com fio, teia ou rede a até 10 m vem 3 m
  para perto e fica preso. R **Casulo**: até 3 inimigos perto viram casulo por
  4 s (não andam nem atacam, a seda segura metade do dano); 3 golpes ou tiros de
  um aliado deles quebram o casulo (os bots vão soltar o amigo).
- **Reações** (`scripts/actors/reacoes.gd`): fogo queima teia (fogos da
  Kitsune, Luz, Sombria, Onibi, bomba e mina do Bombardeiro/Armadilheiro) e
  vento rasga teia (leque e redemoinho do Yamabushi, asas do Karasu Tengu).
  Nenhum time queima a própria teia.
- **Visual** (princípio 13): corpo próprio dos três no esqueleto (elmo rachado
  com chifre quebrado, flechas nas costas na cor do time e fogo-fantasma;
  cabeça de leão de laca com juba e pano verde de dança; dama de quimono com seis
  patas de aranha e quatro olhos na cor do time), chapéu no chão, enfeite e
  emblema no pavilhão. Assinatura própria: selos novos (ensō partido com
  flechas, cabeça de leão, teia com a aranha), verbos novos (`racha`, `estala`,
  `tece`), figuras do R (samurai caído, leão, aranha descendo no fio) e peças
  (cinza azul, confete, fio de seda). O atlas passou para 7x7/5x5 e já tem os
  desenhos do Kodama e do Kaminari-kozō. O dash dos três solta a peça deles.
- **Sons** sintetizados (`gerar_sons.py herois227`): fantasma com coro grave
  desafinado, flecha arrancada, chama azul, marcha dos caídos; estalo de madeira
  da boca do leão, suzu, taiko e fue da festa; seda, koto esticando, casulo.
- **Painel do pavilhão** aceita até 5 heróis (cartões estreitam com 4 ou 5).
  Samurai e Ninja agora têm 4 heróis cada; a Kitsune ganha o 4º na parte 2.
- Fichas (Classes) e clipes dos três; texto do Como jogar atualizado.
- Testes de regra 810/810 (35 novos: não cair, flechas, Onibi, Sorte/Azar,
  Arrastão, fio, teia, fogo e vento na teia, Puxar, Casulo, R uma vez só).
- Sonda com heróis (8 partidas, abates por minuto vivo): Ochimusha 1,74,
  Shishimai 1,26, Jorogumo 0,95 (Samurai 1,82, Sohei 1,54, Kappa 1,31): no
  meio da faixa dos outros, sem número fora da curva.
- **Modo teste**: os três já estão no painel do pavilhão; suba a casa do Samurai
  ou do Shuriken até o Nv5 (madeira infinita, obra rápida) e escolha. Q, E e R
  recarregam rápido como os outros.
- **O que testar**: no Modo teste, pegue a **Ochimusha** e deixe um Samurai de
  treino te derrubar (você vira fantasma: derrube alguém em 3 s). Com o
  **Shishimai**, morda um aliado (moeda dourada sobre a cabeça) e um inimigo
  (nuvem roxa: o próximo golpe dele erra), e use o Arrastão em quem leva a
  máscara. Com a **Jorogumo**, ponha uma teia no caminho de um inimigo, puxe com
  o E e solte o Casulo num grupo; depois veja uma Kitsune queimar a teia.

## Revisão 2.26s (2026-11-13), Diretor de Jogabilidade: achados da revisão autorizados
O Julio autorizou os achados que mudavam comportamento (lista em project-files
`castelo-de-bolo/revisao/revisao-codigo-2026-11-13.md`).
- **Torreta não mira quem voa na catapulta** (antes gastava a cadência de 1,2 s
  num virote que não fazia nada); agora atira em quem está no chão.
- **Projétil atravessa quem está no ar** da catapulta (antes sumia sem dano) e
  segue até acertar alguém atrás.
- **Recargas correm durante o voo** (2,4 s): ataque, esquiva, cura, Q, Chi e a
  guarda. Antes tudo congelava no ar.
- **Fim de jogo com alguém no ar**: ele desce no ponto de queda, sem meteoro
  (antes ficava parado no céu até reiniciar).
- Obra da oficina e da torreta usam a mesma regra (`Unit.lenhador()`); nada muda hoje.
- Nomes das camadas de física sem uso ("itens", "projeteis") saíram do `project.godot`.
- Testes de regra 750/750 e 5 min simulados sem erro (21 lançamentos de catapulta).
- **O que testar**: no Modo teste, lance-se pela catapulta perto de uma torreta
  inimiga (ela deve ignorar você no ar) e use a esquiva logo ao pousar (deve estar pronta).

## Revisão 2.26r (2026-11-13), Diretor de Jogabilidade: limpeza sem mudar o jogo
Pedido do Julio: revisar, otimizar e tirar o que não serve antes do próximo lote
de feedback. Nada muda na jogabilidade nem no visual.
- **Download do jogo 104 MB → 43 MB** (pacote exportado). Os 568 modelos de
  `assets/ninja/` (4 climas) agora são salvos com `ResourceSaver.FLAG_COMPRESS`:
  73 MB → 15 MB no disco, conteúdo idêntico (impressão digital de cada cena:
  árvore, transforms, vértices e materiais, iguais antes e depois). No navegador,
  o jogo começa bem mais rápido; o .exe encolhe junto.
  Geradores (`gerar_cenario_ninja`, `gerar_economia` e quem estende, `gerar_mapa_rio`)
  já salvam comprimido; `tools/comprimir_cenas.gd` converte o que existe.
- **Código morto removido** (~100 linhas): painel de fim antigo do HUD (`show_end`,
  nunca aparecia: o placar faz esse papel), `Game._mascara_em_maos`,
  `Menus._abrir_tutorial`, `Oficina.nome_caminho`/`concluir_heroi_ja`/`_ritmo`/`_obra_cena`,
  campos antigos do `GameConfig` sem leitor (`oficina_classes`, `magos_opostos`,
  `magos_caminho_nomes`), `Config.LAYER_ITEMS/LAYER_PROJECTILES`, `KITSUNEBI`,
  `Estilo.T_GIGANTE` e variáveis locais sem uso.
- Conferido e deixado: duplicação quase nula (blocos repetidos têm parâmetros
  diferentes); script por quadro sem desperdício que valha o risco; malhas
  paradas já juntas (`MalhaUnica`).
- Achados que **mudariam** comportamento (esperam o Julio): project-files
  `castelo-de-bolo/revisao/revisao-codigo-2026-11-13.md`.
- Testes de regra 750/750 e 5 min simulados sem erro, antes e depois.
- **O que testar**: abrir o jogo no navegador (deve carregar mais rápido) e jogar
  uma partida normal: nada deve parecer diferente.

## Ciclo 2.26 (2026-11-13), Diretor de Jogabilidade: porrada que se sente
Pedido do Julio: aproveitar 3 h; ele escolheu o pacote "Porrada que se sente"
(itens 1, 3, 4 e 5 da lista de sensação de porrada em `docs/ideias.md`).
- **Rastro na barra de vida**: o pedaço que o golpe tirou fica **branco** por
  0,45 s e desce depois (`rastro_espera`, `rastro_vel`). Nos bonecos (mesmo quad,
  `barra_vida.gdshader` ganhou `rastro`) e na barra do HUD (uma barra branca por baixo).
- **Borda vermelha do golpe forte**: levou ≥ 15% da vida num golpe (ou um golpe com
  empurrão forte), a borda acende e some em ~0,4 s, mais forte do lado de onde veio
  (`Hud.golpe_forte`, `golpe_forte_frac`). Separada da borda de vida baixa.
- **Guarda que quebra**: cada golpe que bate na defesa gasta a guarda em
  dano / vida máxima (tiro gasta metade, virote de torreta nada). Somou 0,7 =
  **GUARDA QUEBRADA!**: atordoa 0,6 s, não defende por 1,2 s e quem quebrou ganha
  10 de Chi. Recupera depois de 1 s sem apanhar. O arco da defesa esquenta para
  laranja e treme perto de quebrar. A física: a defesa absorve impulso; golpe
  pesado gasta mais e corpo grande aguenta mais (Kitsune aguenta 3 golpes de
  Samurai; Samurai aguenta 5 de Samurai e ~10 de Kitsune). Bots param de defender com a guarda gasta. Contra-golpe intacto.
  Números no grupo "Botão direito" do `game_config` (`guarda_*`).
- **Respingo de tinta no chão**: golpe que acerta pinta uma mancha de pincel na cor
  do time de quem apanhou, esticada na direção do golpe, com gotas na frente; some
  roída pelas bordas em 2 s. Todos os respingos = **1 chamada de desenho**
  (`scripts/fx/respingo.gd`, MultiMesh de 48, forma por shader, sem textura).
- **Modo teste**: Samurai **inimigo de treino** ao lado do aliado caído
  (`BrainPancada`): defende 4 s (quebre a guarda dele), bate 2,5 s se você estiver
  perto (sinta o golpe forte, treine a sua defesa) e fica parado 2,5 s; cura sozinho
  e renasce no mesmo lugar.
- Testes de regra: `_guarda_quebra` (guarda, tiro, torreta, recuperação, quebra,
  trava, Chi, rastro, respingo). Print: `PORRADA_TESTE=1` com `--sandbox --shots=DIR`.
- Prancha: project-files `castelo-de-bolo/jogabilidade/20-porrada-que-se-sente.jpg`.
- **O que testar**: no Modo teste, bata no Samurai vermelho enquanto ele defende
  (a guarda dele quebra no 4º golpe forte?), deixe ele bater em você (borda vermelha e o
  branco na barra) e veja a tinta no chão. Na partida: a guarda quebra rápido ou
  devagar demais? O respingo atrapalha a leitura da briga? O branco da barra
  ajuda a ver quanto cada golpe tira?

## Ciclo 2.25c (2026-11-13), Diretor de Jogabilidade: som próprio em toda classe
Pedido do Julio: "o que eu pulei de etapa nas classes novas?". A auditoria
(project-files `castelo-de-bolo/revisao/auditoria-classes-novas-2026-11-12.md`)
achou só uma etapa pulada: **som**. Os 8 heróis, Armadilheiro, Yumi, Bombardeiro
e Ronin Oni tocavam o "power + poder_boom" genérico no E e o `super_maior` no R;
Sohei e Kusarigama emprestavam sons de outros (`magia_luz`, `samurai_final`...).
- **45 sons novos** sintetizados (`tools/gerar_sons.py assinaturas2`, sem fonte
  externa): `<id>_poder`, `<id>_super` e `<id>_final` para as 14 classes (+3 das Kitsunes), ligados
  nos `som_*` dos `.tres`. O som segue o elemento: catraca e mola (Armadilheiro),
  corda grave + chuva de flechas (Yumi), pavios em cascata (Bombardeiro), rosnado de
  oni (Ronin), pisão shiko + sal (Sumotori), jato e bolhas (Kappa), trompa de concha
  + vento (Yamabushi), asas e crocito (Karasu), papel e talismã (Onmyoji),
  shakuhachi (Komusō), ar ao contrário + estalo dissonante (Mujina), harpa e coro
  (Tennin), sino do templo + naginata (Sohei), corrente de elos (Kusarigama). O R de
  cada um = o som do E por cima de dois taikos e um gongo.
- **3º tiro com som**: o golpe final de quem atira flecha/bola (Yumi, Bombardeiro,
  Yamabushi, Onmyoji, Komusō) e das Kitsunes não tocava `som_golpe_final`; agora
  toca (`unit.gd`, 2 linhas). Kitsune, Luz e Sombria ganharam o seu.
- Teste novo `_sons_proprios`: toda classe tem som de poder carregado e nenhum
  repetido; caminhos e heróis têm super e golpe final próprios.
- Modo teste: nada a ligar, os sons vêm com a classe (chapéus todos disponíveis).
- Para ouvir sem jogar: `project-files castelo-de-bolo/sons/sons-classes-2.25c.mp4`.
- **O que testar**: no Modo teste, pegue cada herói e o Armadilheiro/Yumi/
  Bombardeiro/Ronin e aperte E, R e faça o 3º golpe. Algum som estranho, alto ou
  baixo demais? Diga "troca o som do X" que eu refaço só ele.

## Ciclo 2.25b (2026-11-12), Diretor de Jogabilidade: cura do mago mais fraca
Pedido do Julio: o mago que cura fica "muito apelão" quando 2-3 bots andam
juntos com ele. Só números:
- **Cura em aliados** (Q): Kitsune 15 → 13, Kitsune Luz 22 → 19,5, herói
  Onmyōji (grou) 25 → 22 (≈ −12%).
- **Autocura**: o Q agora cura o próprio curandeiro com 90% do valor
  (`cura_propria_mult`), total ≈ −20% contra antes. Teste de regra novo cobre isso.
- **O que testar**: grudar em uma Kitsune Luz com 2-3 bots e ver se o bolinho
  ainda é imortal; jogar de Kitsune e sentir se a autocura ficou justa.

## Ciclo 2.25 (2026-11-12), Diretor de Jogabilidade: menos empate e heróis mais fortes
Pedido do Julio depois do 2.24: "a borda ainda corta", "tá dando muito empate:
um pouquinho mais fácil de fazer ponto" e heróis "um pouquinho mais apelões, sem
exagero, igualmente fortes entre eles". Dois quizzes (mente aberta, depois os
números); o alvo escolhido foi ~4 pontos somados por partida.
- **Por que empatava** (3 partidas de bots de 15 min): cada abate pesava a máscara
  de quem matou e as duas batiam no peso máximo aos 10 min; o ladrão andava a ~39%
  da velocidade e 9 de cada 10 roubos morriam no caminho. 1 a 3 pontos somados.
- **Peso**: alma do abate 0,15 → 0,05 e só enche até **75%** (`alma_teto`); dali
  para cima, só espírito entregue. Peso máximo freia 38% (antes 45%).
- **Carregar**: +0,10 em toda classe (`carregar_bonus`). **Escolta** soma: o 1º
  aliado colado dá +15% (como antes), o 2º e o 3º +6% cada para quem carrega
  (até +27%). O HUD mostra "ESCOLTA +N%".
- **Defesa**: ladrão leva 37% do dano (antes 40%); devolver a máscara caída leva
  4 s (antes 3) e **não soma mais por defensor**: três defensores juntos
  devolviam em menos de 1 s (média medida 1,8 s), sem chance de retomada.
- **Bots do ladrão**: atacantes escoltam e correm para retomar a máscara caída de
  qualquer lugar do mapa; defensores e Construtores seguem no que estavam.
- **Seta dourada** (a mesma do Construtor) mostra onde está a máscara fora do
  pedestal: ESCOLTE, RETOME, DEVOLVA, RECUPERE ou ENTREGUE.
- **Morte súbita**: placar igual no fim (depois da prorrogação) abre 2 min com
  as duas máscaras leves (peso 0, almas param de pesar), música mais rápida e o
  relógio "MORTE SÚBITA"; o primeiro ponto vence. Sem ponto, vence quem tem mais
  pontos no placar do Tab ("decidido pelos pontos do placar"); igual até nisso,
  empate.
- **Placar**: abate 100 → 120. **Multikill** em escadinha: abate até 5 s depois
  do anterior continua a corrente; duplo +50, triplo +100, do 4º em diante +150
  cada. Quem fez vê o **letreiro dourado** embaixo do relógio (cresce a cada
  degrau); os outros veem o nome do degrau subindo em cima de quem fez.
- **Obra**: 1 madeira a menos (casas 5/7/9/11, níveis 4 e 6, herói 7) e martelo
  15% mais rápido (obra 8,5 s, puxa madeira a cada 1,3 s).
- **Heróis**: +10% de vida e dano e Q e Chi do E 15% mais rápidos, para os 8
  (`heroi_vida_mult`, `heroi_dano_mult`, `heroi_recarga_mult`; `ClassStats.heroi`).
  Empurrão nos de baixo da sonda, pensando em quem acerta fácil e quem acerta
  difícil (pitaco do Julio): Karasu Tengu (mergulho no cursor, difícil: 32 → 40;
  vida 105; Revoada 5), Mujina (pelas costas: vida 100, golpe 14, Susto 9),
  Tennin (giro de 360° acerta fácil, dano igual; vida 110, Laço cura 28),
  Yamabushi (Rajada 10), Komusō (sono 1,9 s e a **nota teleguiada**: curva
  devagar atrás do alvo, balançando, e some no fim do alcance; dá para desviar).
- **Placar do fim/Tab** encolhe para caber na janela (a borda cortava a última
  coluna).
- **Medido depois** (10 partidas de bots, 15 min): **nenhum empate** (antes quase
  todas). 2 foram para a morte súbita e saíram pelos pontos do placar; 3 acabaram
  em 3 × 1 lá pelos 9-12 min; as outras no relógio com alguém na frente. Média de
  2,3 pontos somados (o alvo era ~4; a variação entre partidas é grande, de 0 a 4).
  A máscara carregada vive ~7 s em média (antes 8) e a devolvida leva 4-5 s
  (antes 1-2). Sonda dos heróis (dano por minuto vivo): Komusō 105 → 214, Mujina
  219 → 273, Karasu 119 → 140 (abates/min 0,48 → 0,99), Tennin cura 162 → 256,
  Yamabushi 268 → 302; Kappa 422 e Onmyoji 362 no topo. Do pior ao melhor caiu de
  ~3,8× para ~3×.
- **Modo teste**: perto de uma máscara, **M** chama a morte súbita e **N** mostra
  o letreiro do multikill (duplo, triplo, multi). O resto (escolta, seta, peso,
  heróis, obra) já vale lá.
- Testes novos: teto das almas, carregar, escolta por aliado, devolver sem somar,
  morte súbita (abre, zera o peso, espera a máscara, decide no placar, primeiro
  ponto vence), escadinha do multikill, heróis marcados.
- Arquivos: `game_config.gd`/`.tres`, `class_stats.gd`, `princess.gd`, `unit.gd`,
  `game.gd`, `placar.gd`, `hud.gd`, `placar_tela.gd`, `pagina_classes.gd`,
  `tutorial.gd`, `bot_brain.gd`, `guia_construtor.gd`, `projectile.gd`, `sfx.gd`,
  `config.gd`, `tools/gerar_herois.gd` + os 8 heróis, `tests/regras.gd`,
  CONTROLES.md.

### O que testar
- Jogue uma partida inteira: ainda empata? Pontuar ficou "um pouquinho" mais
  fácil ou passou do ponto?
- Roube a máscara com aliados colados: dá para sentir a escolta? A seta dourada
  ajuda a achar a máscara caída?
- Faça um duplo/triplo: o letreiro dourado embaixo do relógio fica bom?
- **Modo teste**: M (morte súbita) e N (letreiro) perto de uma máscara.
- Heróis: algum ainda fraco ou algum passou do ponto? A nota do Komusō curvando.

## Ciclo 2.24 (2026-11-12), Diretor Visual + Jogabilidade: assinatura de cada personagem e relógio de 15 min
Pedido do Julio: relógio de 15 min (dar tempo de construir e chegar nos heróis) e
"muitos símbolos iguais nos poderes: cada personagem com um efeito de acordo com
a personalidade, bem completo e complexo". Quiz: selo próprio "e também não selo",
abertura do R própria ("inove!"), partículas próprias, o Q também, tudo maior e
"o R mais ainda"; prorrogação enquanto houver máscara fora do castelo.
- **O que repetia**: todo E escrevia o mesmo círculo com estrela e todo R abria com
  o mesmo pilar e selo dourados. Agora os 20 personagens têm **assinatura própria**
  (kit `Assinatura`, tabela completa em docs/direcao-efeitos.md §9):
  - **Selo com silhueta própria** (nem todo selo é um círculo): ensō com katanas
    (Samurai), chifres e chão rachando (Ronin), rosário e sino (Sohei), shuriken
    (Ninja), alvo com olho (Yumi), corrente de elos (Kusarigama), pata (Kitsune),
    lótus (Luz), coroa com olhos (Sombria), planta quadrada (Construtor), mandíbula
    (Armadilheiro), pavio em espiral (Bombardeiro), corda shimenawa (Sumotori),
    ondas (Kappa), folhas de bordo (Yamabushi), cata-vento de penas (Tengu), rosto
    oval rachando (Mujina), estrela de Seimei (Onmyoji, o único com 5 pontas),
    fitas (Tennin), cesto e ondas de som (Komusō).
  - **Verbo próprio**: cada selo aparece de um jeito (pincel dando a volta, carimbo
    que bate, ondas do meio para fora, mordida de fora para dentro, queima, espiral,
    névoa, risco). A frente da escrita acende.
  - **Partícula com forma**: penas, folhas, sal, talismãs, notas, contas, gotas,
    cacos, elos, estrepes, pétalas, chamas (tombam no ar ou sobem, conforme a peça).
  - **R de cada um, maior que tudo**: máscara oni queimando atrás do Ronin, sino
    gigante do Sohei, olho de luz no céu do Yumi, 3 sombras do Ninja, asas do
    Tengu, rosto liso da Mujina, talismãs que viram grous do Onmyoji, andaimes de
    luz do Construtor, pavio que queima e estoura do Bombardeiro, mandíbula do
    Armadilheiro, gêiser do Kappa, leque do Yamabushi, halo da Luz, olhos no chão
    da Sombria, fogos-fátuos da Kitsune, sal e papéis shide do Sumotori, véu da
    Tennin, anéis de som parados do Komusō, risco de tinta do Samurai. O letreiro
    e o clarão do R saem na cor do personagem (antes sempre dourado).
  - **Q**: o emblema bate pequeno sob os pés com algumas peças.
  - **Hanko**: carimbo vermelho com o emblema ao lado do nome do golpe.
  - **Cor do time no brilho do selo**: dá para ver de quem é o selo na briga.
  - Tamanho: selo do E 15% maior (até 6,4 m de raio); selo do R com 7 m.
- **Relógio de 15 min** (`tempo_limite` 600 → 900). **Prorrogação nova**: no zero,
  se uma máscara estiver fora do castelo (na mão ou caída), a partida segue com
  "PRORROGAÇÃO" na tela até ela ser entregue ou voltar ao pedestal. Máscara caída
  sempre espera a volta (15 s parada); na mão, no máximo 60 s (`prorrogacao_max`,
  antes 30) para a partida não ficar sem fim.
- **Custo**: cada selo, figura e sistema de partículas é 1 chamada de desenho e some
  sozinho; os dois atlas somam ~360 KB. Na qualidade Mínima as peças desligam.
- **Modo teste**: nada a ligar, todos os personagens já estão lá com Q/E/R
  recarregando rápido (o relógio não corre no modo teste).
- Teste novo: todo personagem com poder precisa ter selo, verbo e peça próprios
  (`_assinaturas`), e a prorrogação com máscara caída (`_relogio`).
- Arquivos: `scripts/fx/assinatura.gd` (novo), `assets/shaders/assinatura_selo.gdshader`
  e `assinatura_peca.gdshader` (novos), `assets/fx/assinaturas/`, `tools/assinaturas/`
  (desenhos e gerador), `fx_poder.gd`, `fx_herois.gd`, `unit.gd` (ganchos do Q e do
  R), `game.gd`/`hud.gd`/`game_config.gd` (relógio), `tests/regras.gd`.

### O que testar
- **Modo teste**: troque de personagem e solte Q, E e R de cada um. Algum selo
  ainda parece o de outro? Algum R ficou fraco perto dos demais? Tamanho bom?
- O **carimbo vermelho** ao lado do nome do golpe: atrapalha ou fica?
- Numa briga cheia: dá para ver de que time é cada selo pelo brilho em volta?
- **Partida**: o relógio começa em 15:00. No zero com máscara fora do castelo
  aparece "PRORROGAÇÃO" e a partida só acaba quando ela é entregue ou volta.

## Ciclo 2.23b (2026-11-11), Diretor Visual + Interface: clipes e fichas de todos os personagens
Pedido do Julio: conferir a tela que explica cada personagem (Menu > Classes),
pôr o clipe de quem não tinha, ver se o clipe pega o poder mesmo e completar o
que falta, mudando pouco o resto.
- **12 clipes novos** na ficha: Sohei, Kusarigama, Armadilheiro, Bombardeiro e os
  8 heróis raros. **Os 8 antigos foram regravados**: eram de antes do Personagens
  2.0 e da magia nova (Ciclo 2.20), então mostravam bonecos e efeitos velhos.
- **Cada clipe mostra os 3 golpes, o Q, o E e o R acertando** (conferido quadro a
  quadro): os alvos voltam ao lugar antes de cada poder (o combo e o E empurravam
  e o poder seguinte acertava o vazio, ex.: Agarrão do Sumotori), a mira vai no
  meio deles (o Jato do Kappa saía de costas depois da Rasteira), os de longe têm
  alvos a 5 m com a câmera entre os dois (a 7 m ficavam fora do quadro), a Tennin
  puxa um aliado **caído** com o Laço e o levanta, e o golpe saindo da sombra do
  Passo da Sombra agora cabe no clipe. O aliado caído do modo teste não aparece
  mais como "CAÍDO" nos outros clipes.
- **Como jogar**: clipe novo na aba **Herói raro** (o pavilhão fica pronto, o
  Recruta pega o chapéu, vira Sumotori, Agarrão e Pisão) e clipe da aba **Casas**
  consertado (desde as casinhas 2.0 ficava atrás de um telhado; agora o Recruta
  pega o chapéu na barraquinha do Samurai e sai golpeando).
- **Textos que faltavam**: Q e E do Sohei (Varrida, Muralha de Fé) e da Kusarigama
  (Gancho, Ciranda de Aço) estavam sem descrição na ficha.
- **Visual**: o "ō" de Komusō e Dohyō saía numa fonte fina fora da linha (a Lilita
  não tem a letra; agora cai na Nunito Black); a aba Caminhos estourava a moldura
  para a direita e para baixo (títulos curtos, cartões com rolagem quando não
  cabem, "Caminho da Arco" corrigido).
- **Jogo mais leve**: os quadros dos clipes agora importam com compressão com perda
  (WebP). Os 1.416 quadros ocupam ~17 MB no jogo exportado; sem isso seriam
  ~147 MB (os 728 antigos já davam ~75 MB). O navegador baixa bem menos.
- Arquivos: `scripts/ui/clipe_cenas.gd` (roteiros), `tools/clipes_tutorial.sh`
  (lista de classes, cena `heroi`, importação com perda), `pagina_classes.gd`,
  `tutorial.gd`, `estilo.gd`, `assets/tutorial/`.

### O que testar
- Menu > **Classes**: passe por todos (os heróis ficam no fim da lista). Todo mundo
  tem clipe; o Q, o E e o R aparecem acertando os inimigos. Sohei e Kusarigama
  com o texto do Q e do E.
- Ficha do **Komusō** e o R do **Sumotori** (Dohyō): o "ō" igual às outras letras.
- **Como jogar**: abas **Casas**, **Herói raro** (clipe novo) e **Caminhos** (tudo
  dentro da moldura).
- Na web: o jogo deve carregar mais rápido (pacote menor).

## Ciclo 2.23 (2026-11-11), Jogabilidade + Diretor Visual: heróis raros no nível 6 e relógio de 10 min
Pedido do Julio (quiz dos heróis: Construtor sem herói; só o herói é Nv6, como
terceira casa de chapéu; Nv5 com madeira destaca o bairro; um herói por bairro;
tudo de uma vez na main; escada mais rápida + relógio de 10 min com empate).
Plano em docs/direcao-ciclo-2.23-herois.md.
- **Relógio de 10 min** no topo (`tempo_limite`): no zero vence quem tem mais
  pontos; igual = **empate**. Se uma máscara está sendo levada, a partida segue
  ("Última corrida", até `prorrogacao_max` = 30 s). Modo teste sem relógio.
- **Escada mais rápida**: Nv3→4→5 custa 5 e 7 madeiras (era 6 e 9) e cada árvore
  rende 5 toras (era 4).
- **Nível 6 = herói raro** (Samurai, Shuriken e Kitsune; o Construtor para no 5).
  Com o bairro no Nv5, o Construtor aperta [F] e escolhe um herói no painel (bots
  sorteiam). O **Pavilhão do Herói** sobe no tapete do caminho (**8 madeiras**, a
  1ª entra na escolha) e guarda **um chapéu só, sem fabricar**: ele volta
  `heroi_retorno` = 20 s depois que o herói sai de campo de vez (caído esperando
  reanimação ainda conta como em campo). Quem veste ganha 4 níveis de bônus (o 5
  da casa dá 3). Bots não pegam o chapéu nos primeiros 8 s (vez do jogador).
- **Destaque do Nv6**: bairro no 5 com madeira no depósito = anel dourado no
  tapete, pavilhão fantasma, aviso único, **estrela piscando no minimapa** e a seta
  do Construtor com "★ HERÓI". Pavilhão pronto = estrela fixa no minimapa.
- **Os 8 heróis** (Q / E / R; R próprio quando o Super "maior" não bastava):
  - **Sumotori** (Samurai): Agarrão (agarra e arremessa; quem cai em cima apanha),
    Pisão do Santuário, R **Dohyō** (ringue de sal: ninguém entra nem sai, o time
    dele bate +20% dentro). O maior do jogo (215 de vida, rola no dash).
  - **Kappa do Rio** (Samurai): Rasteira (some na poça, reaparece no pé e derruba),
    Jato d'Água em linha, R Enchente. **Casco**: golpe pelas costas leva 60% menos.
  - **Yamabushi do Leque** (Shuriken): tiro de vento; Rajada (**devolve flechas e
    shurikens** a quem atirou e empurra), Redemoinho onde mira (puxa e arremessa),
    R Tufão.
  - **Karasu Tengu** (Shuriken): Mergulho (sobe, intocável, e cai no atirador
    isolado; o chão avisa onde vai cair e bots desviam metade das vezes), Revoada
    (cega: quem está dentro erra os golpes), R **Noite de Corvos** (3 mergulhos).
  - **Mujina** (Shuriken): Roubar Rosto (vira o inimigo tocado: bots e torretas
    inimigos não a veem até o 1º golpe, que dá ×1,5), Susto (quem está perto foge),
    R Passo sem Rosto (sombra).
  - **Onmyoji de Papel** (Kitsune): talismãs retos; Dobrar Shikigami (até 3
    bonecos de papel que engolem golpes; cheio, solta talismãs que caçam o alvo),
    Grou de Papel (atravessa: fere inimigos e cura aliados), R **Mil Grous** em leque.
  - **Tennin do Manto** (Kitsune): flutua e não leva empurrão; ataque em giro de
    360°; Laço do Manto (puxa o aliado caído e o levanta com 40% da vida, ou puxa
    o ferido longe), Dança Celeste (cura em volta), R **Véu Celeste** (aliados a
    14 m não morrem por 3 s).
  - **Komusō** (Kitsune): notas de flauta que atravessam; Canção de Ninar (dormem
    até levar golpe), Hipnose (puxa para perto), R **Réquiem** (inimigos a 16 m sem
    Q, E e R por 4 s).
- **Bots**: bom senso por herói (`scripts/ai/bot_herois.gd`): Agarrão joga para
  longe da máscara, Rajada quando vem projétil, Mergulho só em atirador isolado,
  Rosto antes de entrar no pátio inimigo, Laço em caído, Canção com 2 juntos...
- **Visual** (princípio 13): corpo próprio de cada um em `NinjaVisual` (barriga e
  mawashi do time com a tsuna e os shide; casco, bico e prato aceso; máscara tengu
  de nariz longo e leque de penas; capuz de corvo, bico e asas; rosto liso com a
  fenda acesa; eboshi alto e kariginu; coque, halo e as fitas do hagoromo; tengai
  e kesa do time), chapéus novos no pedestal (coque, prato, tokin, bico,
  máscara lisa, halo, tengai), efeitos de cada poder no kit Magia (`FxHerois`,
  paletas água, sal, papel, pena, som e celeste). **Pavilhão dourado** (hokora de
  telhado duplo dourado, shimenawa e lanternas balançando, estandarte do time)
  com o adorno do herói no topo e o emblema no estandarte, nos 4 temas
  (`tools/gerar_pavilhao.gd`). Prancha: project-files/castelo-de-bolo/herois/.
- **Sons novos**: papel (Kenney), água, grasnido e flauta (sintetizados por
  `tools/sons/sintetizar_herois.py`, sem fonte externa).
- **Menus**: fichas dos 8 heróis em Classes (grupo "★ herói raro"), aba **Herói
  raro** no Como jogar, cartão do relógio na aba Objetivo. Sem clipe ainda.
- **Modo teste (sandbox)**: o Nv6 funciona igual (madeira infinita, obra 3× mais
  rápida) e o chapéu do herói volta em 3 s (`sandbox_heroi_retorno`).
- Testes de regra: relógio/empate/última corrida, Nv6 (Construtor para no 5,
  escolha gasta madeira, pavilhão, estoque 1 sem fabricar, retorno, bônus 4 vs 3,
  bot espera o jogador) e uma regra por herói + "R sai uma vez só" nos 8; 535/535.
- **Ritmo** (partidas só com bots): o 1º herói foi escolhido aos 4:50, 6:47,
  7:08 e 8:42; numa de 10 min ninguém chegou (os dois times no Nv5 aos 9 min).
  Pavilhão levava 80-100 s com 10 madeiras: agora são **8**. Com você de
  Construtor focando num bairro, o herói chega antes.
- **Equilíbrio** (`HEROIS=1 tools/sonda_equilibrio.sh`, 8 partidas com os heróis
  em campo desde o início; amostra pequena, 6-13 mortes por herói): Kappa (1,7
  abates/min) e Onmyoji (1,0) fortes; Sumotori, Komusō, Yamabushi, Karasu e
  Tennin ficaram abaixo da classe base e foram reforçados (dano e recarga do ataque;
  Agarrão 22→30, Mergulho 26→32). Reavaliar depois que você jogar.
- **Desempenho**: cada herói é 1 malha de corpo + 1 de peças, como as classes
  (CENSO: ~2,1 passes por boneco nos dois casos); o pavilhão vira 1 malha só
  (fora o chapéu e o que balança). QA do mapa sem bot preso.
- **O que testar**: (1) No Modo teste, suba um bairro de Samurai, Shuriken ou
  Kitsune até o 5 com o Construtor: o tapete brilha e a estrela pisca no
  minimapa? (2) [F] no bairro: o painel mostra os heróis; o pavilhão dourado sobe
  no tapete? (3) Vista cada herói e teste Q, E e R (o chapéu volta em 3 s no modo
  teste). (4) Numa partida normal: o relógio de 10 min aparece, e no fim dá
  vitória por pontos ou empate? (5) Os corpos: dá para saber quem é cada herói de
  longe? Diga qual ficou fraco que eu refaço.

## Ciclo 2.22 (2026-11-11), Jogabilidade + Diretor Visual: casinhas até o nível 5 e o R repetido
Pedido do Julio (quiz "Casinhas até o nível 5": 1B, 2A, 3A + "no nível 1 o R não
está liberado", 4AB, 5A). Antes a barraquinha da classe base parava no nível 2,
só a casa do caminho subia (até o 4) e a escolha era "ficar 0,5 s no tapete".
- **Escada do bairro** (vale para os 4): **Nv1 → Nv2** a barraquinha sobe sozinha
  (`casa_nv2_custo` = 4 madeiras, Construtor parado no bairro); **Nv2 → Nv3** é a
  escolha do caminho, a casa sobe (6 madeiras, +2 por casa que o time já fez) e
  **nasce no Nv3 junto com a barraquinha**; **Nv3 → 4 → 5** uma subida só leva as
  duas (6 e 9 madeiras). `mago_nivel_max` = 5. Lógica em `Oficina` (`pode_subir`,
  `pede_escolha`, `subir_nivel`, `_degrau_pad`).
- **Painel da escolha** (1B): o jogador Construtor aperta **[F] no bairro** e clica
  num dos dois caminhos (ou 1/2): nome, caminho, epíteto, Q e E de cada um
  (`Hud.abrir_escolha`). Só abre e só fica aberto **fora da briga** (nenhum inimigo
  a 9 m); fecha ao sair do bairro, cair, ou se um bot escolher antes. Clique no
  painel não vira golpe. Pisar no tapete não escolhe mais nada para o jogador.
- **Quem escolhe** (2A): só o Construtor. Os bots continuam no tapete sorteado, na hora.
- **Bônus por nível** (3A): barraquinha e casa ganham o mesmo pacote por nível
  acima do 2 (+1 chapéu, fabricação ×0,85) e a **classe base também** ganha
  +8% dano, +8% vida e +10% Chi por nível (antes só a do caminho).
- **R travado no Nv1** (comentário da 3): com o bairro da classe no nível 1, o
  Super dela não sai (a barra enche igual; o HUD diz "Super travado: casa no Nv1").
  Subiu ao 2, libera (`super_nivel_min`). Classes de caminho nascem no Nv3, então
  nunca travam.
- **Visual dos níveis** (4AB): a casa nasce no Nv3 como era; o **andar** aparece no
  Nv4 e o **topo + estandartes** no Nv5 (nós renomeados `N4_Andar`, `N5_Topo`,
  `N5_Estandartes`). A barraquinha ganhou uma peça por nível: **Nv3** dois tōrō de
  pedra acesos, **Nv4** um nobori alto na cor da classe, **Nv5** um arco dourado
  com shimenawa e fitas de papel balançando (`gerar_casas.gd`, `_barraca_niveis`).
  Prancha: project-files/castelo-de-bolo/casinhas/03-escada-ate-nivel-5.jpg.
- **Bug do R repetido** (Kitsune Sombria, também Ronin Oni): o Super "maior"
  decidia se o poder E tinha saído olhando o Chi depois (`power > 0` = "não saiu,
  devolve a barra"). O Selo e a Fúria ferem no mesmo quadro e o dano dá Chi, então
  o Super era devolvido e saía DE NOVO a cada quadro enquanto houvesse alguém no
  círculo (sim de 5 min com todas Sombrias: 129 devoluções, rajadas de 5 a 20 em
  0,3 s, cada uma com o Selo gigante). Agora `Unit._use_power()` devolve se saiu;
  o Chi que o dano do Super rendeu fica com quem lançou.
- **Ritmo**: bots sobem primeiro as 4 barraquinhas ao Nv2 (liberam o R), depois
  escolhem caminhos e só então sobem níveis (`Game.barraca_nv1`, `mago_para_subir`).
  A escada inteira custa ~112 madeiras por time; para caber melhor, **cada árvore
  agora rende 4 toras** (era 3). Três partidas simuladas de 10 min só com bots:
  todas as barraquinhas no Nv2 entre 2 e 4,5 min, um caminho novo a cada ~1 min
  a partir de ~3,5 min, o 1º Nv4 perto dos 9 min. Bots sozinhos não chegam ao Nv5
  em 10 min; com você de Construtor focando num bairro, dá.
- **Modo teste (sandbox)**: sem bots, **madeira infinita** (HUD mostra ∞),
  **nenhuma casa construída** (barraquinhas no Nv1, R travado até o Nv2), obra e
  entrega de madeira 3× mais rápidas (`sandbox_obra_mult`). A escolha vale de
  verdade: F5 recomeça para testar o outro lado. Saiu o atalho "[F] sobe o nível /
  troca o caminho". Torretas e catapultas continuam prontas.
- Como jogar (aba Casas e Caminhos) e fichas das Classes com a escada nova.
- Testes de regra: escolha só no Nv2, Nv1→2 com madeira sem caminho, casa nasce
  no Nv3 com a barraquinha junto, as duas sobem até o 5, bônus da base, R travado
  no Nv1, e "Super do Selo e da Fúria gasta a barra uma vez só"; 475/475.
- **O que testar**: (1) No Modo teste, pegue o Construtor e suba uma barraquinha
  ao Nv2: o R da classe liberou? (2) No Nv2, [F] no bairro: o painel deixa claro o
  que você está escolhendo? Escolha, erga a casa e suba até o 5: as duas sobem
  juntas, e dá para ver de longe cada nível (lanternas, nobori, arco)? (3) F5 e
  faça a outra escolha. (4) Jogue de Kitsune Sombria: o R sai uma vez só por barra.
  (5) Numa partida normal: o ritmo das casas (R travado no começo, caminhos a partir
  de ~3 min) ficou bom?

## Ciclo 2.21 (2026-11-10), Diretor Visual + Jogabilidade: casinhas 2.0 (casa da classe)
Pedido do Julio (quizzes "Casinhas 2.0": 1A, 2C, 3A, 4AC, 5ABCDE; classes novas:
1C, 2A, 3A, 4B, 5A): repensar as casinhas de chapéu num pedido só. Antes eram
duas oficinas soltas (Luz/Sombria) e barraquinhas sem leitura de onde ficava
cada coisa. Agora **cada classe base tem um bairro** no seu trecho da ferradura
e **uma casa só** que vira um de dois caminhos.
- **Bairro da classe** (`Oficina`, `scripts/items/oficina.gd`, reescrita): chão de
  areia, barraquinha de festival na frente (o chapéu da classe base, sempre
  disponível), dois **tapetes** com o **fantasma translúcido** da casa evoluída
  em cima (shader `casa_fantasma.gdshader`, 1 passe sem luz) e um estandarte alto.
  O Construtor **escolhe parando no tapete** (0,5 s) e a obra começa ali; o
  outro tapete se sela. Pronta, a casa vira o pad da classe evoluída (nível 2)
  e a barraquinha também sobe. Depois, cada nível custa 6 e 9 madeiras (até o 4),
  e **cada nível põe um telhado/andar a mais** na casa.
- **Todos os caminhos em pares** (2C): Samurai → Ronin Oni **ou Sohei**; Ninja de
  Shuriken → Arqueiro Yumi **ou Kusarigama**; Kitsune → Luz ou Sombria;
  Construtor → Armadilheiro ou Bombardeiro. Níveis 2 a 4 para todos (4B).
- **Sohei** (novo, `config/classes/sohei.tres`): monge da naginata, tanque de
  apoio. Regra própria (1C): **a lâmina só corta na faixa entre 1,5 m e o
  alcance**; colado demais leva o cabo (empurrão, sem dano), menos no golpe final,
  que desce na vertical. [Q] Varrida: giro de ~300° que fere na faixa da lâmina e
  dá escudo aos aliados a 5,5 m. [E] Muralha de Fé: anel de 5,5 m que fica no
  lugar por 5 s, dá escudo + pressa aos aliados e empurra inimigos até a borda
  (v0 = √(2·a·s), com a = 40 m/s², para parar exatamente na borda).
- **Kusarigama** (nova, `kusarigama.tres`): foice com corrente, alcance de 5,2 m
  em faixa estreita e último golpe do combo girando 360°. [Q] Gancho: o peso vai
  na linha da mira (9,5 m), fere, **PRENDE** 0,45 s (não anda, não ataca, não
  esquiva) e puxa até ~1,6 m; errou, a recarga volta rápido. [E] Ciranda de Aço:
  corrente girando 2,4 s, pulsos a cada 0,3 s no anel (o miolo não corta).
  Visual das duas por código (`NinjaVisual._sohei`, `_kusarigama`), efeitos com o
  kit `Magia` (`FxPoder.q_varrida`, `q_gancho`, `muralha`, `ciranda`).
- **Ritmo de ~10 min em escada** (4AC, 5A): a 1ª casa custa 6 e cada casa a mais
  do time custa +2 (`oficina_custo_degrau`). Partida simulada de 10 min: 1º
  caminho ~15 s, 2º ~2,2 min, 3º ~3,7 min, 4º ~6-7 min, 1º nível 3 aos ~6,5 min.
- **Onde fica cada casa** (5ABCDE): minimapa com emblema da classe e anel de
  estado (cinza vazio, arco da obra na cor do caminho, dourado pronta, pontos de
  nível; o do inimigo menor); estandarte alto; chão pintado do bairro; aviso
  grande para os DOIS times quando alguém escolhe um caminho
  (`caminho_aviso_inimigo`); dicas novas do Construtor (`_dica_casa`).
- Modelos: `tools/gerar_casas.gd` (estende `gerar_economia.gd`) gera as 4
  barraquinhas, as 8 casas (com `Telhado`, `N3_Andar`, `N4_Topo`) e os 4 bairros
  para os 4 temas; as `oficina_azul/vermelho` antigas saíram. Casa ~2,3-3,1 mil
  triângulos, bairro ~2,4 mil, tudo juntado com `MalhaUnica`.
- **Custo** (CENSO, 900 quadros com xvfb, mesma partida): main 556 chamadas por
  quadro em média (pico 680) → 618 (pico 701), +11 %, por 8 bairros e casas
  novas. O chão do bairro, o pano e o emblema do estandarte não projetam
  sombra (cortou ~35). Os fantasmas (2 por bairro) só existem até a escolha.
  `CENSO_DETALHE` agora aceita vários nomes separados por vírgula.
- Como jogar: abas "Casas" e "Caminhos" reescritas (linhas geradas dos dados).
  Classes: cada base seguida dos seus caminhos, com a origem ("casa, N madeiras").
- Bots: escolhem um tapete ao acaso, sobem o nível da casa mais avançada, usam
  Varrida/Gancho/Muralha/Ciranda (`bot_brain.gd`).
- **Modo teste (sandbox)**: todas as casas já prontas; [F] perto de uma casa
  sobe o nível e, no nível máximo, troca para o outro caminho (dá para ver as 8
  casas e testar Sohei/Kusarigama na hora). Custos de nível = 1.
- Testes de regra: pares de caminho em todas as classes, escolha no tapete,
  custo em escada, níveis até 4, e as regras do Sohei/Kusarigama (cabo sem dano,
  lâmina na faixa, escudo da Varrida, empurrão da Muralha até a borda, Gancho
  prende e puxa ~1,6 m, Ciranda poupa o miolo); 460/460.
- **O que testar**: (1) no começo, ache no minimapa e no pátio onde fica cada
  casa: dá para ler de longe? (2) Como Construtor, pare num tapete: o fantasma
  e a escolha ficam claros? (3) Jogue de Sohei: a regra "colado só empurra" fica
  justa ou frustrante? A Muralha ajuda o time? (4) Jogue de Kusarigama: o Gancho
  acerta onde você mira? Prender 0,45 s é muito? (5) O ritmo de ~10 min para
  ver as casas subindo ficou bom? (6) No Modo teste, [F] nas casas para ver
  todos os níveis e os 8 modelos.

## Ciclo 2.20 (2026-11-10), Diretor Visual + Jogabilidade: magia de verdade nos poderes
Pedido do Julio (quiz "Magia de verdade": 1C, 2B, 3 tudo, 4 sem piloto, 5 ABCD):
tirar os "cones e cilindros secos". Diagnóstico: `FxPoder` montava tudo com
malha primitiva + cor chapada aditiva + tween de escala/alfa. Agora cada poder é
feito de ENERGIA desenhada: ruído rolando, borda que se rasga em degraus e filete
de tinta escura (o mesmo traço do cenário), em três atos: carga, estouro, resto.
- **Kit `Magia`** (`scripts/fx/magia.gd` + `assets/shaders/magia_energia.gdshader`
  e `magia_selo.gdshader`): chama, onda, estouro, selo que se ESCREVE no chão,
  vórtice, lança, rachaduras, bola de fogo, brasas, clarão e fita de rastro
  (`scripts/fx/fita.gd`). Um shader só (compila uma vez), 1 malha por peça,
  ruído de 128² gerado no começo. Paletas por elemento em `Magia.PALETAS`.
- **Poder [E] e super [R] das 10 classes refeitos** (`fx_poder.gd` inteiro):
  Redemoinho (funil de vento com faixas girando), Fúria do Oni (estouro de brasa,
  chifres de fogo, aura atrás do corpo), Corte Relâmpago, Leque, Chuva de
  Flechas (lanças de luz + arremate), Campo Minado, Bombardeio (aviso que fecha,
  bola de fogo que se corrói, chão queimado), Mutirão, Coluna de Fogo-Raposa,
  Bênção (pétalas + pilar de luz), Selo Sombrio (o selo se escreve, chamas nas 5
  pontas, raios). Todo lançamento abre com o selo do elemento escrito no chão.
- **Q de cada classe** ganhou efeito próprio (pisão, investida, tiro carregado,
  cura com fio de luz até cada aliado, armadilha); a corrida deixa selo de vento.
- **Golpe básico**: corte fino de energia (uma malha; antes duas) e fita de
  rastro na lâmina só no golpe que arremata o combo. De propósito leve, como
  pedido: nada de clarão nem câmera no básico.
- **Impactos**: projéteis de nível 2+ estouram em energia; a explosão de pólvora
  virou bola de fogo. Fumaça leve, como pedido: só 2 sopros por explosão, e a
  nuvem do Bombardeio (8 esferas lilases chapadas que tapavam a luta) virou
  dois véus de fiapos girando (2 malhas, dá para ver quem está dentro).
- **Marca no chão** depois dos poderes fortes (tinta queimada que some em 3-4 s)
  e **clarão que ilumina** o chão e os bonecos (luz curta, só na qualidade Alta).
- **Câmera e som**: poder [E] dá tranco + zoom curto + 0,16 s de câmera lenta;
  o super [R] um pouco mais. Cinco sons novos gerados (`magia_selo`, `_fogo`,
  `_vento`, `_luz`, `_estouro` em `tools/gerar_sons.py magia`), um por elemento.
- **Custo**: cada peça é 1 chamada de desenho e vive < 1 s; na qualidade Baixa
  os enfeites (brasas, cargas, luz) desligam. Medido com todo mundo soltando
  poder a cada 4 s (`--perf=3 --poderes`, 40 s): 457 → 470 chamadas por quadro
  em média (pico 505 → 483) e 1,14 → 1,16 M de triângulos, ou seja, dentro do
  ruído entre partidas. O que o xvfb NÃO mede é custo por pixel: efeito grande
  na tela cheia pode pesar no Intel UHD; se pesar, o ajuste é no tamanho.
- Modo teste (sandbox): tudo vale igual lá (os efeitos são os mesmos nós), e é
  o melhor lugar para ver, porque Q/E/R recarregam rápido e todos os chapéus
  estão disponíveis.
- Ferramentas: `tools/bancada_magia.gd` (cada peça do kit em 6 tempos, sem
  partida) e `tools/vitrine.sh` (antes/depois por classe).
- Testes de regra: cada peça do kit nasce e se libera sozinha, fita usa o
  shader de energia, todo poder tem paleta; 357/357.
- **O que testar** (no Modo teste é mais rápido): (1) pegue cada chapéu e solte
  [E] e [R]: dá para reconhecer o elemento de cada classe? Algum efeito tapa
  demais o boneco ou a luta? (2) O golpe básico ficou discreto o bastante?
  (3) A marca no chão e a câmera lenta de 0,16 s ajudam ou atrapalham? (4) Os
  sons novos combinam (dá para trocar um por um)? (5) Na sua máquina, soltar
  vários poderes juntos derruba o FPS? Se sim, me diga em qual poder.

## Ciclo 2.19b (2026-11-09), Jogabilidade: desistir desconta a espera já passada
Pedido do Julio: caído há um tempo, apertar [F] para desistir recomeçava uma
contagem própria (metade da espera, mínimo 4 s) e às vezes demorava mais do que
só esperar. Agora o pedaço da barra que já correu caído sai dessa contagem.
- `Reanimar.espera_ao_desistir(total, restante)`: contagem rápida
  (`reanimar_desistir_frac` × espera da morte, mín. `reanimar_desistir_min`)
  menos o que a barra já andou; nunca passa do que faltava e pode zerar
  (renasce na hora). Vale para o jogador e para os bots que desistem sozinhos.
- Ex.: espera de 12 s, contagem rápida 6 s. Desistiu logo = 6 s; com a barra
  já 4 s andada = 2 s; com 6 s ou mais andados = renasce na hora.
- Modo teste: mesma regra (não há caminho separado); o aliado de treino segue
  esperando para sempre.
- Testes de regra: 5 checks novos em `espera_ao_desistir`; 342/342.
- **O que testar**: morra, espere a barra andar um pouco e segure [F]. O
  "RENASCENDO NO CASTELO EM N s" deve mostrar menos tempo quanto mais você
  esperou antes, e esperando bastante deve renascer quase na hora.

## Ciclo 2.19 (2026-11-09), Jogabilidade: Alta a 30 FPS (detetive de desempenho)
Pedido do Julio (quiz "Detetive do FPS", todas as recomendadas): a Alta ficava
abaixo de 20 FPS no Intel UHD; meta de 30. Culpados medidos: MSAA 2X + resolução
100% (só a Alta tinha), glow, contorno do cenário em 2ª chamada por superfície
(+~40), selos das torretas (48 chamadas), sombras dos chapéus e peças dos 16
bonecos. Scripts inocentes (~7 ms/quadro). Relatório da investigação em
project-files/castelo-de-bolo/desempenho/.
- **Alta: FXAA no lugar do MSAA 2X** (o MSAA guarda 2 amostras por pixel, ~2× a
  banda de escrita; o FXAA é 1 passada sobre a imagem pronta) e **resolução 3D
  90%** (pixels ∝ escala²: 81% do trabalho; HUD segue nítido). `settings.gd`.
- **Contorno do cenário numa casca só** (`CascaContorno`, arena.gd): a geometria
  pintada dos pedaços é copiada numa malha única com o mesmo `contorno.gdshader`;
  mesma tinta, ~40 chamadas viram 1-2. Os pedaços perdem o `next_pass` (cópia de
  material sem ele); peças que giram e modelos montados na partida seguem como antes.
- **Selo/emblema/marca numa malha só** (`Fx.montar_pecas` com SurfaceTool):
  torretas 48 → 8 chamadas no censo; o material continua compartilhado, então o
  pulso de transparência segue funcionando.
- **Chapéus sem sombra** (pads e soldados): a sombra deles era invisível e cada
  superfície pagava 2 redesenhos no mapa de sombra da Alta (61 → 30 superfícies).
- **LOD dos soldados** (`Game._lod_bonecos` + `Unit.set_pecas_longe`): a mais de
  20 m do jogador as peças pequenas (armadura, cachecol, caudas) e o raio-X delas
  somem (histerese 16/20 m). Unit: 126 → 82 passes no censo.
- **Alta dinâmica** (`AutoQuality.degrau` + `Settings.alta_ajuste`): na Alta a
  meta é 30 FPS (mede 32 com folga); antes de cair para a Média, desliga por
  degraus o menos visível primeiro: resolução 80% → sem glow → sem contorno do
  cenário, avisando na tela. As Configurações mostram o que está desligado e
  escolher qualidade no menu zera os ajustes (mede de novo).
- Vale igual no modo teste (sandbox): as mudanças são do renderizador/cenário.
- Testes de regra: escada de degraus, casca existe/sem sombra/só na Alta,
  pedaços sem next_pass; 333/333.
- **O que testar**: Esc › Configurações › **Alta**. (1) Deve segurar ~30 FPS
  ("Mostrar FPS" para conferir); se não segurar, aparece "Alta dinâmica: ..."
  dizendo o que desligou, e as Configurações mostram o estado. (2) O visual da
  Alta continua com contorno de tinta e glow (lanternas), serrilhado parecido.
  (3) De perto os soldados têm todas as peças; a ~20 m as pecinhas somem (não
  deve dar para notar: me avise se notar o pisca). (4) Selos das torretas e
  chapéus nas prateleiras iguais aos de antes.

## Ciclo 2.18b (2026-11-08), Jogabilidade: desistir rápido e bug do "dois de mim"
Feedback do Julio jogando a 2.18: apertou para desistir caído, um aliado o reanimou
mesmo assim e "apareceram dois dele"; e quer que desistir renasça bem mais rápido.
- **Causa**: enquanto alguém te reanimava, a barra mostrava só "X TE REANIMANDO" (dourada,
  enchendo) e escondia o progresso do desistir. Soltando o F antes da hora, parecia que tinha
  desistido, e a reanimação terminava. Quem reanimou (às vezes da mesma classe) ficou colado em
  você: os "dois de mim". Nas partidas simuladas com checagem a cada quadro não apareceu cópia
  de boneco nem estado sujo.
- **Desistir**: segurar F por **0,5 s** (era 0,8). Agora vale **mesmo no meio de uma
  reanimação** (solta quem estava reanimando) e a barra do desistir (vermelha, "continue
  segurando [F]") fica por cima de tudo. Ao desistir aparece "Desistiu: renascendo no castelo"
  e a barra mostra os segundos.
- **Renasce bem mais rápido**: metade da espera da morte, nunca menos de 4 s
  (`reanimar_desistir_frac` 0,5 e `reanimar_desistir_min` 4). No começo da partida, 7 s viram
  4 s; no fim, 13 s viram 6,5 s. Continua perdendo o chapéu e ficando fora da briga.
- **Bots** sem aliado vivo a 20 m desistem sozinhos depois de 1,5 s no chão (mesma regra).
- **Sendo reanimado, o relógio para**: ninguém renasce no castelo no meio do resgate.
- Travas extras: `levantar()` não levanta quem desistiu ou já renasceu; o painel da classe
  mostra "Caído" (dá para reanimar) ou "Renascendo...".
- Testes de regra: desistir no meio da reanimação, relógio parado, tempo rápido com mínimo;
  322/322. 3 partidas de 5 min com checagem a cada quadro, sem erro.
- **O que testar**: caia perto de um aliado, deixe ele começar a reanimar e segure F: a barra
  vermelha enche, você renasce no castelo em ~4 s e ninguém te levanta. Sem segurar F, ele te
  reanima normalmente.

## Ciclo 2.18 (2026-11-08), Jogabilidade + Visual: reanimar aliados caídos (estilo Battlefield 6)
Pedido do Julio (quiz "Reanimar aliados caídos", todas as recomendadas + comentários estilo BF6).
Regra em `scripts/reanimar.gd` (`Reanimar`, em `Game.reanimar`); números no `game_config`, grupo
"Reanimar (Ciclo 2.18)". Prancha: `castelo-de-bolo/jogabilidade/19-reanimar-prancha.jpg`
(gerada com `--prancha-reanimar=DIR`, xvfb).
- **Caído**: quem morre fica no chão durante a espera de renascer. Esperando ajuda, o relógio
  corre a `reanimar_ritmo_espera` (0,65: janela maior); **caído, segurar F desiste** e renasce no
  castelo como recruta (relógio normal). Bot caído só espera se tem aliado a até 20 m.
- **Reanimar = segurar F colado no corpo** (`reanimar_raio` 1,6 m) por `reanimar_tempo` 3 s. Quem
  reanima **continua apanhando e o canal não para com dano** (risco proposital); para ao soltar F,
  dar dash, morrer ou se afastar. O progresso fica guardado no corpo (outro pode continuar).
- **Arrasto**: classe comum puxa o corpo andando de costas (`Walking_Backwards` + braços de
  `Use_Item`), a 45% da velocidade, numa corda de 1,1 m: dá para tirar o aliado da briga.
- **Kitsunes** (aprendiz, Luz e Sombria) reanimam **paradas**, com `Spellcasting` e feixe de benção
  (dourado na Luz, roxo na Sombria), **1,5× mais rápido**, chegando a **2× no nível 5** do caminho.
- **Levanta com a classe e o chapéu que tinha**, 50% da vida e **2 s intocável** (faíscas douradas).
- **Time inteiro caído = ninguém reanima** (todos vão para o castelo no relógio normal).
- **Visual** (princípio 13): chama de espírito (fogo-raposa na cor do time, 1 quad, sem sombra,
  por cima de tudo como o marcador do Battlefield) que encolhe conforme a espera acaba e fica
  branca/dourada enquanto reanimam; anel tracejado no chão (alcance) com arco dourado de
  progresso; ao levantar, coluna de luz + anel + faíscas. **Só o seu time vê** as chamas.
  HUD: barra "CAÍDO · espere um aliado · segure [F]..." / "X TE REANIMANDO" / "REANIMANDO".
  Pedido do Julio depois da prancha: deixar mais claro que está caído. Letreiro **"CAÍDO"**
  sobre o corpo (vira **"REANIMANDO 40%"** dourado no canal) e **cruz no minimapa** em cada
  aliado caído que ainda dá para reanimar.
- **Sons**: `reanimar_arrasto` (pano no chão, Kenney CC0 cloth1-4) e `reanimado` (Kenney
  maximize_006/008) junto com o `renascer`.
- **Placar (Tab)**: coluna **Reanim.** e `pts_reanimar` = 60 (Nome e Classe ficaram um pouco
  mais estreitas para caber). "+60 REANIMOU" aparece para o jogador.
- **Bots**: vão reanimar quem caiu a até 10 m (Kitsunes 20 m), um bot por corpo, sem inimigo a
  3,5 m; arrastam para longe do inimigo mais perto. Em 5 min simulados: 15 reanimações.
- **Modo teste**: um **aliado de treino** (Samurai) fica caído na frente do portão para sempre;
  depois de reanimado cai de novo em 4 s. Dá para testar com qualquer classe (troque nas
  oficinas e veja a Kitsune mais rápida).
- Textos: CONTROLES.md (F segurado) e o card "Resgate" do Como jogar.
- Testes de regra: `_reanimar` (classe mantida, vida, intocável, dano não para, corda, mago,
  time todo caído, placar); 313/313 ok. 5 min simulados sem erro.
- **O que testar**: no **modo teste**, ande até o Samurai caído na frente do portão, segure F
  (como Samurai: ande para arrastar; como Kitsune: fica parada e mais rápida). Numa partida:
  morra perto de aliados e veja se eles vêm te buscar; segure F caído para desistir. Olhar se a
  chama azul se lê bem no meio da briga e se 3 s parece justo.

## Ciclo 2.17 (2026-11-08), Jogabilidade + Visual: otimização geral (mesma imagem, menos trabalho) e relógio do placar
Pedido do Julio depois da 2.16: o relógio do placar seguia contando depois do fim da partida; e
otimizar o jogo ao máximo mantendo o visual, porque o PC dele (placa integrada) não roda bem.
Medido no mesmo início de partida, em Alta (xvfb, software: serve para comparar, não para
medir FPS real): **chamadas de desenho 820 → 460 (−44%)** e **triângulos por quadro 1,56 M →
0,94 M (−40%)**; na Média, ~450-500 chamadas e ~0,7 M triângulos. O custo que sobrou é
principalmente o cenário (24 pedaços de 34 m × 3 materiais, cada um com sombra) e os 16 bonecos
(corpo + peças + raio X + contorno + sombra), que são o visual em si.
- **Relógio do placar** (`Game.tempo_partida`): só anda enquanto a partida está em andamento;
  no placar final mostra o tempo em que acabou.
- **Malha única** (`scripts/world/malha_unica.gd`, `MalhaUnica.juntar`): peças paradas debaixo de
  um nó viram UMA malha, com a posição gravada nos vértices e a cor base no vértice
  (`vertex_color_use_as_albedo`), agrupadas por material. Usada nos chapéus (17 peças → 1-2
  superfícies), no corpo das maquininhas (fora o que a animação move, molde e prateleiras),
  nos lotes e casas das oficinas, na bandeira, na torreta (fora a arma) e na máscara da princesa.
  Canais ausentes (cor, UV, UV2, tangente) ganham o valor padrão da GPU, ShaderMaterial iguais
  (mesmo shader e parâmetros, sem `instance uniform`) juntam, e rugosidade/metálico arredondam a
  0,5 na chave. Uma MeshInstance3D é pelo menos uma chamada por passe (cor + cada divisão de
  sombra + contorno): oito maquininhas custavam ~136 chamadas e sombras; agora ~24.
- **Barra de vida em 1 quad** (`assets/shaders/barra_vida.gdshader`): eram dois quads (fundo +
  preenchimento escalado) por boneco com material próprio; agora um quad com um material por
  time e a fração em `instance uniform`. 16 chamadas a menos e 32 materiais a menos.
- **Raio X das peças só na Alta** (`NinjaVisual.pecas(..., raio_x)`): o corpo continua acendendo
  atrás de parede em toda qualidade; o passe extra das peças (chapéu, armadura) só na Alta.
  A silhueta se lê igual pelo corpo; 16 chamadas a menos na Média.
- **Sombras**: a câmera vê ~45 m, então as 4 divisões PSSM da Alta só redesenhavam o mapa para
  sombras que ninguém via: **Alta com 2 divisões (55 m)**, **Média com 1 (ortogonal, 45 m)**;
  mapa de sombra 2048 (era 4096: 4× a memória escrita por quadro, para nada a 25 m de câmera).
- **Renderizador Compatibility (OpenGL) em todas as plataformas** (`project.godot`): o .exe
  usava Forward+ (Vulkan), que gasta passes extras (profundidade, agrupamento de luzes) que o
  jogo não usa e pesa mais na placa integrada; agora PC = navegador = CI. Os shaders já eram
  escritos para ele (stencil do raio X incluído).
- **Diagnóstico** (`--perf=<qualidade>`, com xvfb): além de FPS/chamadas/triângulos, imprime o
  **CENSO** (instâncias, superfícies, passes e sombras por dono: Arena, Unit, HatPad...) e o
  tempo de CPU por seção (`us_regras`, `us_cerebro`, `us_fisica_corpo`, `us_animacao`). Com
  `CENSO_DETALHE=Arena` lista cada instância do dono; `MU_DEBUG=1` mostra os grupos da malha
  única. Medido: os scripts (regras + cérebro dos bots + física + animação) somam ~1,5 ms por
  quadro; o gargalo é o desenho, não a lógica.
- Modo teste: tudo vale igual (as mesmas peças são juntadas). Testes de regra 291/291; 5 min
  simulados sem erro; prints em Alta e Média conferidos lado a lado com a 2.16.
- **O que testar**: jogar uma partida inteira e ver se está mais leve (FPS no canto, se ligado em
  Configurações). Procurar algo que tenha sumido ou mudado de cor: chapéus na prateleira e na
  cabeça, maquininhas, casas das oficinas, torretas, máscara da princesa, barra de vida (azul
  no seu time, vermelha no inimigo, some quando cheia). Se o .exe abrir estranho (tela preta ou
  erro de OpenGL), avise: é o renderizador novo.
## Ciclo 2.16 (2026-11-08), Visual + Jogabilidade: armadura do Samurai refeita e placar estilo Battlefield (Tab)
Pedido do Julio depois de jogar a 2.15: a armadura do Samurai tampava o rosto; ver detalhes menores
nas outras classes; e um placar com a pontuação de cada um (bot ou jogador), no Tab a qualquer
momento e no fim da partida, com o jogo borrado ao fundo.
- **Samurai refeito** (`NinjaVisual._samurai`): o peitoral (dō) descia do rosto até a barriga
  porque as faixas estavam 0,3 m acima de onde a cabeça começa. Agora as três faixas lamelares
  ficam abaixo do pescoço, justas no tronco, com cordão dourado e o **brasão (mon) do time** no
  peito. O elmo ganhou **shikoro** (protetor de nuca em três lâminas, só atrás e dos lados),
  **fukigaeshi** (abas viradas ao lado do rosto) e o mon na testa; as ombreiras viraram duas
  lâminas com filete dourado. O rosto fica livre de frente e de 3/4.
- **Detalhes menores**: a corda shimenawa do Ronin era um aro largo flutuando; agora são duas voltas
  justas na barriga. Ninja de Shuriken com **kunai no coldre da coxa**. Construtor com
  **lanterna de papel na cor do time** pendurada no cesto (a "luz própria" da ideia B da revisão
  2.9b, balançando como fogo calmo) e **martelo no cinto**.
- **Correção de desempenho/erro (vinha da 2.14)**: o contorno de tinta do cenário tinha herdado o
  `instance uniform agito` do balanço das caudas; cada peça do mapa ocupava um lugar no buffer
  global de 4.096 e o jogo enchia o log de "Too many instances using shader instance variables"
  (os bonecos podiam perder o agito/brilho do poder). Bonecos agora usam
  `contorno_boneco.gdshader`; o `contorno.gdshader` do cenário voltou a não ter instance uniform.
- **Placar (Tab)** (`scripts/placar.gd` + `scripts/ui/placar_tela.gd`): segure **Tab** e aparecem
  os dois times lado a lado, do mais pontuado para o menos: nome (bots com nome próprio, você
  destacado em ouro), classe atual, **pontos, abates, assistências, mortes, dano, almas, toras,
  obra (segundos martelando) e máscara** (capturas + roubos + resgates); quem está caído tem †.
  O jogo continua rodando atrás, borrado, sem cor e escuro (`placar_fundo.gdshader`, 25 amostras,
  funciona no navegador). **No fim da partida** o placar abre sozinho com Vitória/Derrota em cima
  (substitui o painel antigo, que dizia "R jogar de novo"; o certo é F5).
- **Pontuação fácil de ajustar**: `game_config.tres`, grupo **"Placar (Tab)"**: pontos =
  Σ estatística × peso, com o peso de cada campo em `pts_<campo>`. Padrão: abate 100,
  assistência 50 (deu dano no abatido nos últimos 8 s), alma (espírito levado à máscara) 40,
  tora entregue 25, obra 4/s, dano 0,25 por ponto de vida, cura em aliado 0,4/pv, roubo da
  máscara 100, resgate da própria máscara 75, captura 500, morte 0. A legenda no pé do placar
  lê esses números, então muda junto. Assistência do jogador mostra "ASSISTÊNCIA +50" na tela.
- Tecla nova em `Config` (ação "placar") e em CONTROLES.md. `--placar` deixa o placar aberto
  (para prints). Modo teste: o placar funciona igual (só você na lista).
- Testes de regra: 291/291 (novos: todo boneco tem linha, todo campo tem peso, a conta, e um abate
  real dá abate a quem matou, assistência a quem ajudou e morte a quem caiu). 5 min simulados
  sem erro.
- **O que testar**: segure Tab no meio da briga e solte; veja se dá para acompanhar o jogo borrado
  atrás. Ganhe ou perca uma partida para ver o placar final. De perto, o rosto do Samurai e a
  lanterna do Construtor. Se algum peso parecer errado (ex.: dano valendo muito), é só dizer o
  número novo.
## Ciclo 2.15 (2026-11-08), Visual: Personagens 2.0, parte 2 (detalhe nos corpos e rolamento de verdade)
Feedback do Julio na parte 1: queria peças 3D construídas ao redor do corpo (armadura, camadas de
roupa) e um rolamento animado no dash, principalmente nas classes que atiram. Prancha
`personagens/09-detalhe-e-rolamento.jpg`.
- **Peças novas por classe** (tudo na malha única de peças: nenhuma chamada de desenho a mais):
  Samurai com peitoral lamelar de três faixas debruadas em ouro, saiote de placas (kusazuri),
  braçadeiras, caneleiras, bainha na cintura e **bandeira do time nas costas (sashimono)** que
  balança na corrida; Ninja de Shuriken com cachecol de ponta solta esvoaçante, bandoleira de
  shurikens, faixas de pano nos braços e canelas e bolsa no cinto; Ronin Oni com gola de pelo,
  ombreira gigante de placas com espigões de osso e corda shimenawa com dois shide de papel;
  Arqueira Yumi com ombreira assimétrica de arqueira, luva na corda, abas de hakama e jingasa de
  palha pendurada nas costas; Construtor com cinto de ferramentas, toalha no ombro e joelheiras;
  Armadilheiro com avental de couro e minas de reserva no cinto; Bombardeiro com bandoleira de
  bombinhas e pavio na cintura. Panos e papéis usam o mesmo balanço por vértice das caudas
  (`_fita` em `NinjaVisual`). Peças por classe: 0,6k-2,3k triângulos (medido).
- **Rolamento de verdade** (`dash_estilo` "rolamento"): o corpo gira 360° para a frente em volta
  do próprio centro durante o dash (pivô compensado para não cavar o chão; o pouso dá um pulinho
  e um tufo de poeira). Agora rolam: **Ninja de Shuriken, Arqueira Yumi, Armadilheiro** e o
  **Ronin Oni** (o "rolar" pesado dele usa o mesmo giro, com tremor de tela no pouso). Morrer no
  meio da cambalhota endireita o corpo.
- **Dashes criativos novos**: Bombardeiro sai de **foguete de pólvora** (estouro atrás, faíscas no
  rastro, inclinado para trás); Construtor **tropeça** para a frente quase caindo, com poeira.
  O Samurai segue na corrida inclinada e as Kitsunes seguem virando chama.
  Distância, tempo e recarga do dash continuam iguais para todos.
- Testes de regra: 271/271 (a lista de estilos de dash válidos cobre os novos).
- Modo teste: nada muda (visual puro); os dashes aparecem lá do mesmo jeito.
- **O que testar**: dê dash com cada classe (dois cliques na direção): a cambalhota do Ninja/Yumi/
  Armadilheiro, o foguete do Bombardeiro e o tropeço do Construtor. De perto, repare na bandeira
  do Samurai balançando e no cachecol do Ninja. Diga se alguma peça atrapalha a leitura do time.
## Ciclo 2.14 (2026-11-08), Visual: Personagens 2.0, parte 1 (Kitsunes e dash com personalidade)
Ideia guardada do Julio (cardápio da próxima grande atualização, opção recomendada). Julio pediu
para subir para a main e testar no jogo (2026-11-08); prancha `personagens/08-kitsunes-e-dash.jpg`
(`tools/prancha_kitsunes.gd`).
- **Kitsune aprendiz** (nível 1): uma cauda laranja de ponta branca, máscara de raposa branca e
  lisa (fendas pretas nos olhos, miolo vermelho nas orelhas), sem fogo em volta.
- **Luz e Sombria usam o mesmo modelo evoluído**, com **uma cauda por nível do mago (2 → 5)**:
  Luz com caudas brancas de ponta dourada, anel dourado liso atrás da cabeça (cresce com o nível)
  e fogo-raposa que boia calmo; Sombria com caudas roxo-escuras, coroa de raios em ziguezague
  (mais alta a cada nível), olhos acesos e fogo tremido. Subir o mago refaz só as peças
  (`Unit.atualizar_nivel_visual`, chamado por `Game.on_mago_nivel`).
- **Animação nas peças sem osso novo** (`assets/shaders/balanco.gdshaderinc`): NinjaVisual grava
  em CUSTOM1 (peso, fase, tipo); a cauda é uma viga em balanço (deslocamento ∝ peso², peso 0 na
  raiz e 1 na ponta), o fogo calmo é um seno lento e o tremido soma 3 senos de frequências quase
  incomensuráveis. `agito` por boneco: 0 parado, 1 no ataque/poder/super (caudas abrem e varrem
  rápido), -1 na morte (caudas param moles, fogo apaga). Toon, neon, raio X e contorno usam a
  mesma conta, então a silhueta acompanha. O neon virou `neon_pecas.gdshader` (mesmo visual).
- **Dash com personalidade** (`ClassStats.dash_estilo`; **distância, tempo e recarga iguais**):
  Samurai e Ninja de Shuriken correm inclinados com os braços para trás (`PoseDash`, modificador
  de esqueleto); Ronin Oni rola pesado (amassa mais, pó e tremor curto no pouso); as Kitsunes
  somem num lampejo de fogo-raposa e reaparecem no fim, com rastro. As outras classes seguem com
  a cambalhota de antes.
- Custo: cada cauda ~190 triângulos (Sombria/Luz nível 5 ≈ +1.000 com contorno); nenhuma chamada
  de desenho a mais (caudas no toon das peças, fogo no neon).
- Testes de regra: 271/271 (novos: caudas no nível 2 e 5 ao subir o mago; estilos de dash válidos).
- `--filme` agora filma a classe de `--classe=` (antes era sempre o Samurai).
- Modo teste: subir o mago custa **1 tora por nível** lá, para ver as caudas 2 → 5 rápido.
- **O que testar**: no modo teste, pegue a Kitsune da Luz ou a Sombria e leve madeira ao terreno
  dela: a cada nível nasce mais uma cauda e o anel/coroa cresce. Ataque e veja as caudas abrirem;
  dê dash com Samurai, Ninja, Ronin e Kitsune (o alcance do dash não mudou).
## Ciclo 2.13 (2026-11-06), Jogabilidade: morte pesa mais e fim da guarda eterna da máscara
Pedidos do Julio: penalizar mais a morte (fim de jogo travado, impossível roubar a máscara)
e tirar o bot que fica sempre plantado embaixo da máscara dando o golpe final.
- **Renascer cresce com a partida**: base de 6 s → 7 s, +0,75 s por minuto de jogo, teto de
  13 s (`respawn_time`, `respawn_cresce`, `respawn_max`; `Game.respawn_atual()`). Aos 5 min
  são ~10,8 s. Física de fila: com N mortes/min no time, a população média fora de combate é
  N·T/60 (Little); subir T de 6 → ~11 s quase dobra os buracos na defesa no fim, abrindo
  janelas para o time unido roubar. No começo quase não muda, para não esfriar a porradaria.
- **Guarda-costas eterno era um bug**: com a máscara no peso máximo, `feed()` recusava o
  espírito e o bot confeiteiro ficava para sempre embaixo dela com o bolo na mão (visto em
  simulação: dos 200 s em diante, sempre o mesmo bot lá). Agora bot não pega espírito com a
  máscara cheia e, se estiver com um na mão, volta ao papel dele. Visitas à máscara ficam
  só as entregas de verdade ("pode estar às vezes, mas não sempre").
- Medida (3 partidas de 5 min antes e depois, bots): roubos 9/9/6 antes, 8/15/4 depois —
  mesma faixa (a variação entre partidas é enorme); roubos tardios (t>200 s) continuam.
  O efeito real do respawn aparece melhor em partida longa, que a simulação de 5 min não cobre.
- Testes de regra: 261/261 (novos: respawn cresce/teto/modo teste; máscara cheia recusa
  espírito e o bot não acampa).
- Modo teste: o renascer NÃO cresce lá (fica nos 7 s fixos; esperar mais só atrapalharia
  o teste solo).
- **O que testar**: morrer no fim da partida deve segurar você uns 11-13 s na tela de
  renascer (no começo, ~7 s). Chegar de surdina na máscara inimiga cheia não deve mais ter
  um bot parado embaixo dela o tempo todo; quem aparece ali é quem está entregando espírito.
## Ciclo 2.12d (2026-11-06), Jogabilidade: chapéu da classe forte demora mais
Julio aprovou as propostas 1 e 3 de `jogabilidade/proposta-chapeus-casinhas.md`.
- **Tempo de chapéu por classe** (campo novo `ClassStats.chapeu_tempo_mult`, padrão 1,0):
  Ronin Oni ×1,2 (20 → 24 s; nível 2, 12 → 14,4 s), Arqueiro Yumi ×1,1 (22 s), Samurai e
  Ninja de Shuriken ×0,9 (18 s). Kitsunes e Construtor iguais. Física: a maquininha é uma
  fila com oferta μ = 60/T por minuto; T +20% corta ~17% da oferta do Ronin sem mexer em
  como ele luta (na sonda ele tinha o dobro do K/D do Samurai).
- **Bots sobem o mago antes de reerguer a torreta** (`Game.torreta_para_obra`): com uma
  torreta do time de pé e o mago podendo subir, o terreno vazio da outra espera. Torreta
  já começada continua recebendo madeira; sem nenhuma de pé, ela volta primeiro.
- Medida (2 partidas de 10 min): ainda não aparece nível 3 do mago; a coleta dos bots é
  o gargalo (só 1 bot Construtor por time, que pega o chapéu mais perto; o
  `bots_construtores_max = 2` é um teto, não uma meta). Fica como ideia, sem mudar.
- Testes de regra: 255/255 (novo caso torreta x mago; os de maquininha usam o multiplicador).
- Modo teste: os chapéus continuam saindo em 1 s lá (nada muda).
- **O que testar**: na partida, a maquininha do Ronin mostra 24 s e a do Samurai/Ninja 18 s
  no letreiro. Se a torreta de um lado cair, a madeira do time deve ir para o mago antes.
## Ciclo 2.12c (2026-11-06), Jogabilidade: Passo da Sombra translúcido para o próprio time
Julio: no R do Samurai o próprio time ainda via o corpo inteiro (só uma película roxa
escura por cima); quer o corpo meio transparente para ele e o time, e sumido para o
inimigo (já era). Dano, duração, velocidade e visão dos bots não mudam.
- **Fantasma** (`assets/shaders/toon_fantasma.gdshader`): o toon dos personagens foi
  para `toon_time.gdshaderinc`; o opaco e o fantasma incluem o mesmo corpo, e o fantasma
  liga `FANTASMA`: alfa 1 - `sombra_alfa`, borda roxa por Fresnel pulsando, sem contorno
  nem raio X, sem sombra no chão. `depth_prepass_alpha` grava a profundidade antes, então
  só a camada da frente aparece (braço atrás do tronco não soma transparência).
- `Unit._aplicar_sombra` troca o material de cada pedaço pela versão translúcida (cache
  por material, compartilhado pelo time) e devolve no fim. Ninguém paga o passe de alfa
  fora do super. `GeometryInstance3D.transparency` não pega no Compatibility/WebGL com o
  toon (testado), por isso a troca de material.
- Novo `sombra_alfa` (0,6) no `game_config` (grupo da sombra). Teste de regra: corpo
  fica translúcido no super e volta ao material opaco no fim.
- Modo teste: o R recarrega rápido como antes, é só pegar o Samurai e apertar R.
- **O que testar**: Samurai, R: você e os aliados veem um vulto roxo meio transparente
  (dá para ver o chão através); o inimigo não vê nada; ao bater ou acabar, volta ao
  normal sem ficar pedaço transparente. Antes/depois em
  `jogabilidade/18-passo-da-sombra-fantasma.jpg`.
## Ciclo 2.12b (2026-11-06), Interface: fichas das classes cabem na moldura e ganharam identidade
Julio: na seção Classes as barras de vida/velocidade/dano e os cartões Q/E/R passavam do
quadro (e até da moldura maior), botões e descrições grandes demais, e faltava dizer quem
cada classe é no mundo do jogo. Nada de jogabilidade muda.
- **Cabe tudo** (`scripts/ui/pagina_classes.gd`): a soma das larguras fixas (clipe 400 +
  barra 150 + rótulos) passava dos 940 px da área do menu. Agora lista 216 + ficha 708,
  clipe 320x180, a barra estica no que sobra da linha e a ficha fica numa rolagem
  vertical, então nunca escapa das molduras.
- **Menor**: botões da lista 34 px e letra 17 (com bolinha na cor da classe; a letra na cor
  da classe sumia nas claras, como a Kitsune da Luz), cartões Q/E/R mais baixos com nome
  18 e texto 15, nome da classe 28.
- **Identidade**: cada classe ganhou epíteto e 2-3 frases de quem ela é (dois clãs, a
  Máscara Oni, Chi, espíritos-raposa zenko/yako para as Kitsunes, ronin mascarado, kyudo
  do Yumi...). Ficam no próprio `.tres`, campos novos `epiteto` e `descricao` em
  `ClassStats` (padrão vazio: classe sem texto só não mostra). Classe nova = escrever os
  dois campos; `tests/regras.gd` acusa classe jogável sem eles.
- Texto do R: "mais área, mais força e mais tempo" (antes dizia "dano" até no Mutirão e na
  Bênção) e números com vírgula.
- `--tutorial=DIR` agora também tira `classe_<id>.jpg` de cada ficha.
- Modo teste: o menu é o mesmo, vale igual.
- **O que testar**: menu inicial (ou Esc na partida) > Classes, clicar em cada classe:
  nada pode passar das duas molduras, barras e números dentro do quadro, e ler as
  descrições (tom e fatos). Antes/depois em `interface/08-classes-antes-depois.jpg`.
## Ciclo 2.12 (2026-11-06), Jogabilidade: construções mais baratas
Pedido do Julio: "muito demorado para começar a aparecerem coisas legais", às vezes a partida
acaba sem tudo construído. Ajuste moderado, só na madeira.
- **Custos** (`config/game_config.tres`), ~28% a menos no total por time (58 → 42):
  oficina 6 → 4, posto da raposa (torreta) 4 → 3, maquininha nível 2 8 → 6, níveis do
  caminho dos magos 6/8/10 → 4/6/8. Tempo de obra, coleta e bônus não mudaram. Como jogar
  e Classes leem os números do config, então já mostram os custos novos.
- **Construtor parado na torreta** (`Game.torreta_para_construir`, bug achado medindo):
  com a obra da torreta já no teto da madeira entregue e o estoque vazio, o bot ficava de
  pé ao lado dela esperando (até 40 s seguidos); a seta-guia do jogador também apontava
  para lá. Agora ele só vai se houver o que fazer (estoque ou obra atrás do teto); senão
  volta a cortar. Teste de regra novo em `_torretas` (228/228).
- **Medida** (10 min simulados, bots, 1 partida antes e 3 depois): 1ª oficina 48 s → ~35 s;
  2ª oficina (caminho dos magos) 244-514 s → 133-189 s; 3ª oficina, que antes não saía em
  10 min, em 236-288 s. Achado que ficou para o Julio decidir: os bots gastam a madeira
  reerguendo a torreta derrubada antes de subir o mago (nenhum nível 3 em 10 min).
- Modo teste: nada a ligar; lá tudo já nasce pronto e o F sobe o mago sem madeira.
- **O que testar**: numa partida normal, olhe quando a 1ª e a 2ª oficina ficam prontas e se
  aos ~5 min já há maquininha no nível 2 e torreta de pé. De Construtor, com a torreta
  esperando madeira e o depósito vazio, a seta deve mandar cortar em vez de ficar na torreta.
## Ciclo 2.11c (2026-11-06), Jogabilidade: o tiro vai onde o jogador clica
Bug do Julio: da ponte, clicando em cima do inimigo na margem, o tiro saía
oblíquo para baixo e errava feio. Eram três problemas somados:
- **Paredes invisíveis engoliam o tiro.** O parapeito da ponte é um colisor de
  2,6 m desde o chão, e o rio tem travas invisíveis de 3 m (para ninguém
  atravessar a nado): a flecha morria nelas a 2 m do arqueiro. Camada de física
  nova `LAYER_PASSAGEM` (`MapProp.so_passagem`): parapeito da ponte, mureta da
  muralha e travas do rio seguram quem ANDA, mas tiro, golpe e mira passam.
  Agora dá para atirar da ponte para a margem e através do rio.
- **Clicar no inimigo mirava no chão atrás dele.** O raio do mouse só via o
  cenário; clicar no peito de alguém mirava o chão 1-2 m atrás (e num telhado,
  20-30 graus de erro). Agora o raio vê os bonecos: clicou em cima de um
  inimigo, o tiro mira NELE (`CameraRig.aim_na_tela`, `Unit.aim_unit`), em
  qualquer altura. Aliados no caminho não roubam o clique.
- **Todo projétil assumia que o alvo estava na mesma altura do atirador.**
  Shuriken voava reto na altura do próprio peito (da ponte, passava por cima
  de todo mundo); a bola do mago idem; o arco da Yumi caía no "chão" errado.
  Agora os três miram a altura do ALVO (peito de quem foi clicado, ou o chão
  sob o cursor), descendo e subindo ponte, muralha e telhado.
- Assistência de mira: o limite de diferença de altura subiu de 2,5 m para
  4 m (altura da muralha), já que o tiro agora alcança lá.
- Teste de regra novo `_mira` (12 checagens: clique mira no inimigo na ponte,
  rio, telhado e chão plano; o tiro acerta de verdade; travas continuam
  contando como "chão alto" para bolo/enfeites).
- Gerador do mapa: `torreta_spots` e `catapulta_spot` moravam só no .tres e
  sumiam ao rodar `gerar_mapa_rio.gd`; agora estão no gerador também.
- GIF antes/depois: `jogabilidade/17-mira-ponte-antes-depois.gif` (pasta do
  projeto). Física do porquê: com a câmera a ~48° de inclinação, cada metro de
  altura do alvo vira ~0,9 m de erro horizontal no ponto do raio no chão: por
  isso clicar "em cima" errava mais em alvo alto.
- **O que testar**: da ponte, clicar num inimigo na margem (Yumi, Ninja,
  Kitsune): o tiro deve descer e acertar. Atirar através do rio fora da ponte.
  De cima da muralha para baixo e do chão em alguém no telhado/muralha. No modo
  teste (sandbox) vale igual: as pontes e o rio são os mesmos. Confira também
  que ninguém atravessa o rio andando (as travas continuam segurando).

## Ciclo 2.11b (2026-11-06), Jogabilidade: chão da praça parou de piscar
Julio, no modo teste: "o chão fica piscando, tremendo, parece uma sombra passando, pedaços
somem e aparecem", em todas as qualidades, e para quando ele fica parado.
- **Causa** (medida, não chute): as 2-3 primeiras lajes de cada caminho que sai da praça
  do pátio ficavam **em cima do disco da praça, no mesmo plano** (topo em y = 0,06 as duas).
  Duas faces na mesma profundidade empatam no teste de profundidade e quem ganha muda a
  cada pixel conforme a câmera anda (z-fighting): o desenho de pedra da laje aparecia e
  sumia em retângulos sobre a praça. Parado, a câmera congela um padrão qualquer.
  `tools/gerar_mapa_rio.gd` (`_praca_patio`): lajes só fora da praça; `praca_patio.scn`
  regerado nos 4 temas (os outros .scn ficaram como estavam).
- **Desenho fino demais para a tela** (`assets/shaders/pintura.gdshader`, mexido pela
  Jogabilidade): com a câmera do jogo um pixel do chão mede ~3,5 cm e o rejunte das pedras
  tinha ~2 cm, abaixo de Nyquist: cada quadro cai num ponto diferente da linha e o chão
  "chuvisca" ao andar. Agora o rejunte alarga até ~1,5 px e o desenho some antes de virar
  ruído (como já faziam as telhas); o tom por pedra/tábua/telha vira rampa de ~2 px na
  emenda em vez de degrau. De perto (paredes) nada muda. Custo: zero (mesmas contas).
- **Faixas de luz** (mesmo shader): o corte seco das 3 faixas virou degrau de 20% de
  largura. A sombra do sol é reencaixada na câmera a cada quadro e a penumbra oscila um
  pouco; com o corte seco uma faixa inteira do chão trocava de tom (Alta/Média).
- **Medidor** `--pisca=DIR` (`scripts/game.gd`): câmera do jogo sobre a praça andando 1 cm
  por quadro, `pisca.jpg` marca em vermelho o que mudou de um quadro para o outro e imprime
  a fração. Antes/depois (xvfb, Compatibility): Alta 11,2% → 9,2%, Mínima 9,2% → 7,3%; o
  que sobra é borda de objeto, sombra, vento e desenho de perto. Imagem:
  `jogabilidade/17-chao-piscando.jpg` na pasta do projeto.
- **QA do mapa** ganhou o passo 4, `tests/qa_sobrepostos.gd`: varre todas as faces do
  cenário e acusa pares no mesmo plano (< 4 mm) que se cobrem, com área e posição
  (`--qa-rapido` pula os 3 min de bots presos). Achados que ficaram para olhar depois,
  todos sem flicker visível no medidor: discos de ~30 m² em y ≈ 0 nos pontos das
  maquininhas e oficinas (peça do jogo sobre peça da cena), e faces de 33 m² em y = 9,4 na
  torre da máscara (duas faces internas da mesma cor).
- Modo teste: vale igual, é onde o Julio viu o bug.
- **O que testar**: andar pela praça do pátio (modo teste ou partida) em qualquer qualidade:
  o chão tem que ficar parado. Olhar também as lajes dos caminhos, os caminhos de pedra
  perto das casas e os telhados de longe: o desenho ficou um pouco mais suave de longe; se
  ficou liso demais, é o `some` do shader.
## Ciclo 2.11 (2026-11-06), Interface: menu de jogo de verdade
Pedido do Julio: menus, Como jogar e configurações estavam desatualizados, apertados e com
GIFs antigos gravados num canto ruim do mapa. Nada de jogabilidade nem de visual da partida muda.
- **Menu único com navegação lateral** (`scripts/ui/menus.gd`): uma placa só, botões à
  esquerda e o conteúdo à direita. Tela inicial: JOGAR, Começo, Como jogar, Classes,
  Controles, Configurações, Sair. Pausa (Esc): Continuar e Reiniciar no lugar de JOGAR, com
  as mesmas seções. Esc volta ao Começo na tela inicial e continua a partida na pausa.
- **Começo**: resumo do jogo, 3 dicas, e as escolhas de **Partida** (normal 8x8 ou modo
  teste) e **Seu time** (Azul ou Vermelho). Valem ao apertar JOGAR; se mudarem, a cena
  recarrega e já começa jogando. `--time=vermelho` e `?time=vermelho` na web fazem o mesmo
  (`Game.time_jogador`; a dificuldade dos bots segue o time inimigo do jogador).
- **Como jogar** (`tutorial.gd`): 6 abas (Objetivo, Madeira, Oficinas, Torreta, Catapulta,
  Luz e Sombra), clipe grande (500 px) e no máximo 3 cartões curtos por aba. A antiga aba
  Classes virou seção própria.
- **Classes** (`pagina_classes.gd`, novo): lista por origem (pátio, oficina, caminho dos
  magos) e ficha com clipe da classe (3 golpes, Q, E e R), papel, barras de vida, velocidade
  e dano, e o que Q, E e R fazem (dicionário por `skill`/`power`: classe nova = ficha nova).
- **Controles**: grade solta, uma tecla por linha, mais a tabela Q/E/R de cada classe.
- **Configurações** em três grupos (Som, Vídeo, Partida) com a opção nova "Abrir Como jogar
  ao iniciar".
- **Clipes regravados** (`scripts/ui/clipe_cenas.gd` + `tools/clipes_tutorial.sh`): cenas
  roteirizadas com câmera fixa perto do boneco, sem HUD e sem bots soltos (roubo da máscara,
  combo/defesa/esquiva, corte da árvore, chapéu na maquininha, escudo contra a torreta, voo
  da catapulta, Luz e Sombra) e uma vitrine por classe no mapa leve do modo teste. 15 clipes,
  400x225, 7,5 quadros/s, ~12 MB. As flags antigas `--clipe-cena/--clipe-ini` saíram.
- `--tutorial=DIR` agora fotografa todas as seções do menu. Print: `interface/07-menu-novo.jpg`.
- Mexe fora da interface, de leve: `game.gd` (time do jogador, gravador de clipes),
  `bot_brain.gd`/`unit.gd` (dificuldade por `game.time_jogador` em vez de `TEAM_BLUE`).
- Modo teste: tudo igual, e agora dá para jogar de Vermelho por ele (Começo > Seu time).
- **O que testar**: abra Esc no meio da partida: acha as teclas e as configurações mais
  rápido que antes? Na seção Classes, os clipes e as fichas dizem o que você queria saber
  antes de pegar um chapéu? Jogue uma partida de Vermelho (Começo > Seu time): o placar,
  o minimapa e o "Roube a máscara" fazem sentido do outro lado? No Como jogar, algum clipe
  ficou confuso ou curto demais?



## Revisão 2.10r (2026-11-06), Jogabilidade: código revisado depois dos ciclos 2.9 a 2.10s
Só limpeza; **nada muda na jogabilidade nem no visual** (testes de regra e partida
simulada de 5 min iguais antes e depois).
- Regra "que torreta o Construtor ergue agora" existia em dois lugares (bots e seta-guia)
  com a condição escrita diferente: virou `Game.torreta_para_construir`, usada pelos dois.
- `Fx.montar_pecas` e `Fx.tirar_contorno`: três e duas cópias do mesmo laço (selo, emblema
  e mira da catapulta; modelo sem contorno abaixo da qualidade Alta) viraram uma função.
- Voo da catapulta: `Array` posicional (`v[5]` = altura) virou a classe `Catapulta.Voo`.
- Comentários e ordem de campos arrumados em `map_layout.gd`, `game_config.gd`,
  `unit.gd` e `bot_brain.gd`.
- Achados que mudariam comportamento ficaram anotados, não feitos (torreta mira em quem
  voa; cronômetros param durante o voo): `revisao/revisao-codigo-2026-11-06.md` na pasta
  do projeto.
- **O que testar**: nada deve ter mudado. Se o Construtor (bot ou a seta-guia) parar de
  ir à torreta depois da 1ª oficina, ou a catapulta cair em lugar diferente da mira, é
  desta rodada.
## Ciclo 2.10s (2026-11-06), Sons: cada classe com som próprio
- **O som segue o elemento, não o evento.** Antes todo poder E e todo super tocavam o
  mesmo `poder_boom` (taiko + estrondo), e por isso a magia soava como explosão. Agora
  `ClassStats` tem `som_poder`, `som_super` e `som_golpe_final`; vazio = som antigo.
- Sons novos por síntese (`tools/gerar_sons.py elementos`, com a física no código): Kitsune
  (fogo azul + tigela rin com batimento + guizos + coro), Luz (brilhos + coro maior),
  Sombria (sucção + baque), Samurai (vento + aço + taiko; 3º golpe com taiko; sombra com
  shakuhachi e coração), Ninja (assobios, tinidos em cascata), Construtor (marteladas),
  super genérico e renascer.
- Kenney CC0 no jogo: `hit` (4 variações), `block` (3), `madeira_golpe` (3, novo).
- Estavam mudos e ganharam som: bater na torreta, sair da sombra, renascer e o golpe
  pelas costas do Samurai (2.10, `corte_critico`). Cortar árvore
  usava o som de soco e agora usa madeira.
- Torreta e catapulta (2.9) mantêm os sons da thread de jogabilidade; a troca por IA
  fica para quando houver `HF_TOKEN`.
- Antes/depois para ouvir: `sons/antes-depois.mp4` (pasta do projeto). No modo teste
  (sandbox) os sons já valem: Q/E/R recarregam rápido, dá para ouvir tudo em sequência.
- **O que testar**: solte o E de Kitsune, Samurai e Ninja e veja se dá para saber quem
  foi de olhos fechados. Dê o 3º golpe de Samurai e bata numa torreta. O soco e o
  bloqueio novos cansam depois de 5 min?
## Ciclo 2.10b (2026-11-06), Visual: a briga aparece debaixo dos telhados
Item 5 da revisão geral (`revisao/revisao-geral-2026-11-06.md`): no meio da partida o boneco
sumia atrás das casas grandes.
- **Telhado pontilhado**: o cenário entre a câmera e o jogador (sempre) e as 3 brigas mais
  perto dele (golpe dado/levado há < 2 s com inimigo a < 5 m) vira pontilhado num círculo de
  ~2,6 m em volta do boneco. Geometria: cone com vértice na câmera e eixo até o peito; some
  o que está na frente do boneco e acima dos pés (chão, ponte e degraus ficam). O
  "transparente" é uma matriz de Bayer 4x4 no pixel (descarte), então não precisa de alfa
  nem de ordenar objetos. O raio abre e fecha em 0,25 s para não piscar.
  `assets/shaders/recorte.gdshaderinc` (incluído em `pintura` e no contorno do cenário);
  focos em 4 `shader_globals` do `project.godot`, preenchidos pelo `CameraRig`.
- **Raio X na cor do time**: a parte do boneco escondida atrás de parede, telhado ou árvore
  aparece como silhueta (miolo 28%, aro forte). Stencil: o cenário grava 2, o boneco grava
  1; o passe `raio_x.gdshader` desenha sem teste de profundidade só onde ficou 2. Braço na
  frente do tronco, pé enterrado no chão e boneco atrás de boneco não acendem. Samurai
  invisível (super) continua invisível para o inimigo. Funciona no navegador (Compatibility).
- Custo: um descarte por pixel do cenário e os pixels escondidos de cada boneco; sem leitura
  de profundidade nem passe extra no cenário. `--sem-recorte` desliga tudo (prancha de antes).
- Modo teste: vale igual (foco = o jogador), sem configuração.
- Mexe em `pintura`, `contorno`, `toon_time` (1 linha de stencil), `raio_x` (novo),
  `ninja_visual.gd` (passe novo), `camera_rig.gd` (focos), `project.godot` (globais).
- **O que testar**: ande por baixo dos beirais das casas do meio e atrás da casa grande perto
  da torreta: o telhado em volta de você fica pontilhado e volta sozinho? Bots brigando atrás
  de uma casa aparecem como silhueta azul/vermelha? O pontilhado incomoda (prefere mais
  forte, mais fraco, círculo maior)? No modo teste, dá para conferir sozinho embaixo dos telhados.

## Ciclo 2.10 (2026-11-06), Jogabilidade: equilíbrio das classes e lote da revisão geral
Pedido do Julio: "duvide de tudo" da sonda de bots, diferença notável entre as classes mas
nunca roubada, o grandão lento de verdade. Proposta em `jogabilidade/proposta-equilibrio-classes.md`.
- **Atirar deixa lento**: 0,4 s a 80% da velocidade depois de cada tiro. Física da
  perseguição: o corpo a corpo fecha a distância se v_perto > v_atirador × 0,8.
- **Samurai**: +25% de dano pelas costas ou pelo lado (faísca dourada), investida 6 → 4,5 s,
  vida 140 → 165, velocidade 6,5 → 6,8.
- **Ninja de Shuriken**: o mais rápido (7,1) e frágil (80); o shuriken cai para 80% do dano
  entre 8 m e o alcance máximo.
- **Ronin Oni**: o grandão (vida 190, velocidade 5,6), dano 30 → 24 e golpe a cada 1,1 s.
- **Kitsunes** a 6,6 m/s; Sombria dano 16 → 13; Luz cura 26 → 22. **Yumi** 6,3 m/s.
- **Bots esquivam de projétil** (dash invulnerável, chance `bot_esquiva_projetil`): a sonda
  fica mais perto de gente, e os bots ficam mais difíceis de acertar.
- **Sonda nova**: além de K/D, abates, dano e cura por minuto vivo de cada classe.
- **Revisão geral** (itens 1, 3, 4, 6 e 9): escolta da máscara (carregador com aliado a 6 m
  e o aliado andam +15%); árvore cresce em 25 s por estágio (era 40); bots só sobem na
  catapulta com a máscara inimiga em casa (lançar = ir roubar); letreiros de estado
  (oficina, maquininha, depósito, torreta) somem longe do jogador; aba nova "Torreta e
  catapulta" no Como jogar, com clipes.
- **Piloto do item 7** (só prancha, nada no jogo): roupa na cor da classe e o time no cinto,
  punho, gola e chapéu: `revisao/02-cor-da-classe-piloto.jpg`, `tools/prancha_cor_classe.gd`
  (uniform `usar_cor_classe` desligado no jogo).

Sonda de 8 partidas (K/D; abates por minuto vivo):

| Classe | Antes | Depois | Abates/min |
|---|---|---|---|
| Samurai | 0,42 | 0,68 | 2,1 |
| Ninja de Shuriken | 0,93 | 0,97 | 2,0 |
| Arqueiro Yumi | 0,80 | 1,24 | 2,1 |
| Kitsune | 1,64 | 1,19 | 1,4 |
| Kitsune Sombria | 2,91 | 1,62 | 1,6 |
| Kitsune da Luz | 2,83 | 1,55 | 0,5 (cura 300/min) |
| Ronin Oni | 1,68 | 1,78 | 2,6 |

Pontos nas 8 partidas: 1 → 3-4. O Samurai é o que mais morre (vai na frente), mas abate
tanto quanto os atiradores. Modo teste: tudo vale lá igual (nada novo a ligar).
- Mexe em `unit.gd`, `projectile.gd`, `bot_brain.gd`, `game.gd`, `tutorial.gd`, `torreta.gd`,
  `oficina.gd`, `hat_pad.gd`, `pilha.gd`, `class_stats.gd`, `game_config.gd`, 7 classes,
  `toon_time.gdshader` (uniform desligado), `tools/sonda_equilibrio.sh`, CONTROLES.md.
  Teste de regra `_equilibrio_2_10`: 225/225.
- **O que testar**: de Samurai, chegue num Ninja que está atirando (ele fica lento) e bata
  pelas costas (faísca dourada). De Ninja, sinta que você é o mais rápido mas cai fácil, e
  que de muito longe o shuriken tira menos. De Ronin, ande ao lado de um Samurai: a
  diferença de velocidade tem que ser clara. Carregue a máscara com um aliado do lado. Veja
  se os bots esquivando dos seus tiros ficaram chatos ou bons. Abra a aba "Torreta e
  catapulta" no Como jogar. Diga se a diferença entre as classes ficou do tamanho que você
  quer, e o que acha da prancha da cor da classe.

## Ciclo 2.9b (2026-11-06), Jogabilidade + Visual: torreta mais identificável
- **Em cima**: letreiro "TORRETA" a pincel (branco no terreno vazio, âmbar na obra, cor
  do time pronta) e um **emblema da besta** (anel com arco, coronha e virote) na cor do
  time, sem sombra, que gira e sobe/desce. Some quando a torreta tomba e volta com o selo.
- **Ao redor**: o selo no chão ficou 60% maior (passa da base da torre e lê de cima) e
  mais forte (pronta 0,12 → 0,30 de alfa; na obra pulsa 0,2-0,7).
- Linha de estado embaixo do letreiro: "2 madeiras · Construtor", "45% · faltam 1" ou a
  vida quando machucada. Teclas: o F na tela inicial agora cita a catapulta.
- **Modo teste (sandbox) conferido** contra a ideia do Julio ("tudo disponível o tempo
  inteiro, poder recarregando rápido"): já tinha oficinas prontas, maquininhas no nível 2,
  chapéu em 1 s, F troca classe/sobe nível, torretas dos dois lados de pé (2.9). **Faltava
  a recarga rápida**: agora o Chi enche 8× mais rápido (~4 s), o Super do zero em 6 s, o Q
  recarrega em 1/4 do tempo e a catapulta em 1/5 (grupo "Modo teste" no `game_config.gd`).
  Regra nova no CLAUDE.md: feature na main entra no sandbox na mesma entrega.
- Mexe em `torreta.gd`, `config.gd`, `game.gd`, `unit.gd` (Q), `catapulta.gd`,
  `game_config.gd`, CLAUDE.md. Testes 216/216.
- **O que testar**: de longe, com a câmera do jogo, a torreta (vazia, em obra e pronta)
  se destaca do cenário? O emblema girando incomoda ou ajuda? No modo teste, veja se o E,
  o R e o Q voltam rápido o bastante para testar poder atrás de poder, e se a catapulta
  (F na base) recarrega sem espera.

## Ciclo 2.9 (2026-11-06), Jogabilidade + Visual: torretas do Construtor, catapulta e o padrão de peça nova
Quiz do Julio (respostas em `quiz/quiz-torretas.html` + chat): torre de vigia mais baixa com
toque de santuário da raposa e besta encantada; virote; selo no chão; catapulta de bambu com a
mão do Oni; pouso em meteoro de Chi; mira por barra de força com o ponto de queda no minimapa.
Regra nova no repo: **princípio 13** (`docs/principios.md`): peça nova na tela = quiz antes,
piloto com silhueta própria, cor do time e animações; nunca primitivas como entrega.

- **Torreta "Posto da raposa"** (escolhida entre 3 pilotos, `jogabilidade/12-torretas-pilotos.jpg`):
  modelo pintado como o cenário (`tools/gerar_torretas.gd` → `torreta_c_{cor}.scn`, 2,5 mil
  triângulos; estilos a/b/c em `game_config.torreta_estilo` ou `--torreta=`), pernas de yagura
  sobre pedra, guarda-corpo de torii na cor do time com shimenawa, telhado curvo só atrás (a
  besta fica à vista na câmera), raposa de guarda, lanternas que balançam. **Besta encantada**:
  cristal e corda que acendem na cor do time, três fogos-fátuos orbitando (giram no shader).
- **Animações**: obra cresce do chão e "pula" ao ficar de pé; besta gira para o alvo e dá o
  coice no tiro (clarão na boca); tranco ao levar dano; **derrubada tomba, afunda e some**, e
  o terreno volta a "a construir". **Selo** na cor do time marca o terreno (gira e pulsa; fraco
  com a torreta de pé).
- **Escudo contra torreta** (quiz): virado para o virote, ele **volta** e acerta a torreta
  (×1,5 do dano: pouco, de propósito). Sem janela de tempo; o "na hora certa" foi para
  `docs/ideias.md` B. O jeito de tirar uma torreta é **derrubar na porrada**: os bots agora
  vão até a torreta inimiga (até 9 m, vida > 40%) e batem nela.
- **Guia do Construtor** aponta a torreta (CONSTRUA) quando ela espera madeira e a dica do
  HUD cita "oficina ou torreta". Construtor revisado: jogabilidade já é a pedida (sem
  upgrade, estrepes no caminho, torretas, barraquinhas); o visual ganhou uma sugestão em
  `docs/ideias.md` B (peça que acende), que pede pitaco.
- **Catapulta** (`scripts/items/catapulta.gd`, modelo `catapulta_{cor}.scn`: cavaletes de
  bambu amarrados, eixo de ferro com tampas do time, sarilho que gira, estandarte, lanterna,
  cesto de pedras e a **mão de pedra do Oni** com o aro aceso). Fica na base
  (`MapLayout.catapulta_spot`, Rio: (-9, -12)), virada para o inimigo, sempre de pé.
  **F** perto dela sobe na mão; a **barra de força** (centro da tela) vai e volta e o
  **minimapa mostra onde cai** (anel no chão também); **F de novo lança**. Queda na metade
  inimiga: da beira do rio (força 0) até 8 m da muralha (força 1). Voo em parábola de 2,4 s
  (no ar nada acerta), braço dá o golpe e volta devagar; recarga de 12 s.
  **Meteoro de Chi** no pouso: pilar, rachaduras, tranco de câmera, 14 de dano + empurrão
  forte a 3,5 m (torretas inimigas também levam). Bots atacantes saindo da base usam
  (50% das decisões; 12 lançamentos por time em 5 min simulados).
- **Sons provisórios** com nome próprio em `Sfx.SOUNDS` (a thread de sons troca só o
  arquivo): `besta_virote`, `besta_devolve`, `torreta_pronta`, `torreta_cai`,
  `catapulta_arma`, `catapulta_lanca`, `catapulta_meteoro` (`tools/gerar_sons.py torretas`).
  Timbre pedido: besta = madeira + cristal/fogo-fátuo de raposa na cor do time; catapulta =
  bambu rangendo + pedra do Oni; meteoro = energia de Chi (luz), não bomba.
- Ferramentas: `tools/prancha_torretas.gd` (prancha dos modelos), `--vista=torreta`,
  `--clipe-cena=catapulta|torreta`, `--clipe-n=N`. Testes de regra `_torretas` (regra nova do
  escudo) e `_catapulta` (216/216). GIFs: `jogabilidade/13-catapulta.gif`,
  `jogabilidade/14-torreta-posto-da-raposa.gif`.
- **O que testar**: (1) de qualquer classe, vá à catapulta da base (canto do pátio, lado
  esquerdo olhando para a saída), aperte F, espere a barra e aperte F de novo: você vira um
  meteoro e cai na metade inimiga. (2) No modo teste, chegue na torreta vermelha segurando o
  botão direito virado para ela: o virote volta. (3) De Construtor, depois da 1ª oficina,
  siga a seta até o selo da torreta e construa; depois veja a besta girar e atirar nos bots.
## Ciclo 2.8s (2026-11-06), Sons: tudo pronto para trocar efeitos (nenhum som trocado)
- **Biblioteca** `assets/audio/biblioteca/kenney/` (280 sons CC0: impacto, interface, RPG),
  com `.gdignore` (não entra no jogo exportado). Créditos em `biblioteca/CREDITOS.md`.
- `Sfx` aceita `.ogg` (ganha do `.wav`) e variações `<nome>_2.ogg`... sorteadas a cada toque.
- Ferramentas em `tools/sons/`: `trocar_som.sh` (troca/desfaz em 1 comando, normaliza),
  `catalogo.py` (página para ouvir e escolher), `gerar_ia.py` (Stable Audio / ElevenLabs).
  Passo a passo na skill `.claude/skills/efeitos-sonoros/`.
- Rede do ambiente liberada para kenney.nl, opengameart, freesound, Stable Audio e ElevenLabs.
- **O que testar**: nada muda no som do jogo. Abra `sons/catalogo-sons.html` (pasta do
  projeto), ouça e mande "nome do jogo = arquivo" quando quiser trocar.

## Ciclo 2.8 (2026-11-06), Jogabilidade: SUPER poder na tecla R (piloto, pitaco do Julio)
- **Barra de ouro** embaixo do Chi. Não enche com o tempo: dano causado (×0,12), abate
  (+22), item pego (+12), espírito entregue na máscara (+30) e captura (+50). Não cai ao
  morrer. Cheia: **R** solta o super (abertura dourada, câmera lenta, letreiro).
- **Samurai: Passo da Sombra**: some por 3,5 s (o inimigo não vê o corpo nem a vida; os
  bots inimigos só enxergam a até 2 m), anda 35% mais rápido e o primeiro golpe sai como
  golpe final ×2,5 e encerra a sombra. Para chegar em quem atira de longe.
- **Outras classes**: o poder do E em versão gigante (raio ×1,6, dano ×2, duração ×1,6).
  O Chi do E não é gasto.
- Bots usam: a sombra contra quem atira de 4-16 m (ou para fugir com pouca vida); o resto
  com a mesma leitura do E.
- **Reiniciar** saiu do R e foi para o **F5** (também no menu de pausa).
- Config: grupo "Super (R)" em `game_config.gd`; `super_tipo`/`super_nome` em `ClassStats`.
  Teste de regra `_super` (todas as classes). Vitrine: o super sai no quadro 470.
- GIF: `jogabilidade/10-super-poder.gif` (pasta do projeto).
- **O que testar**: jogue até a barra de ouro encher (abates e espíritos enchem rápido),
  aperte R de Samurai e chegue em um Ninja ou Kitsune sem ser visto. Teste o R de Kitsune
  e de Ninja num grupo de inimigos. A barra enche rápido ou devagar demais?

## Ciclo 2.7b (2026-11-06), Jogabilidade: limpeza e equilíbrio pequeno
- **Limpeza**: os três leques de shuriken (poder E, 2ª onda e 3º tiro do combo) usam um
  helper só (`Unit._leque`, `_mult_poder`); saiu `_trap_cd` (nunca lido); texto do Q no
  "Como jogar" fala de estrepes. Varredura de funções, variáveis e campos de config sem uso:
  nada mais morto (as funções `_ninja`, `_kitsune` etc. do `NinjaVisual` são chamadas pelo nome).
- **Equilíbrio**: Samurai anda 6,2 → 6,5 e bate 22 → 24; Yumi vida 75 → 85 e dano 17 → 18.
  Sonda de 8 partidas: Yumi 0,60 → 0,83; Samurai segue o mais baixo (0,75; corpo a corpo é o
  primeiro alvo). A sonda varia muito entre rodadas (o Ninja foi de 1,35 a 0,62 sem mudança):
  só vale como tendência.
- **O que testar**: nada novo de controle. Veja se o Samurai e a Yumi ficaram menos frágeis.

## Ciclo 2.7 (2026-11-06), Jogabilidade: lote de feedback (poder toda hora, luta mais longa)
- **Q e E mais frequentes**: o Chi agora enche sozinho com o tempo (`power_regen` = 3/s,
  ~33 s do zero sem lutar) e bater/apanhar só adianta (`power_per_damage` 0,3 → 0,4). O
  vazamento por ficar parado saiu. Toda recarga de Q ficou 30% menor (`rapida_cooldown_mult`).
- **Mais vida para todos** (`vida_mult` 1,4 → 1,7): a luta dura mais com mais poder na tela.
- **Construtor sem variação**: Armadilheiro e Bombardeiro saíram das oficinas (os .tres
  continuam no repo, fora do jogo). O Q do Construtor virou **Estrepes** (até 3 no chão,
  lentidão + dano). As oficinas comuns agora oferecem só Ronin Oni e Arqueiro Yumi.
- **3º golpe forte em toda classe de combate**: Samurai/Ronin descem o 3º corte na
  **vertical** (faixa estreita à frente, `final_arco_mult` 0,45, dano ×2,0/×2,1); o Ninja de
  Shuriken solta um **leque de 3 shurikens** no 3º tiro; a Kitsune solta uma **bola de fogo
  que explode** (raio 2,6 m, ×1,8). Campo novo `combo_tiros` em `ClassStats`.
- **Itens no chão onde está a briga**: 65% dos itens caem a 3-7 m do bolo de gente mais
  cheio (fora dos castelos); um item a cada 9 s, até 5 no mapa.
- **Borda vermelha "machucado"** com vida abaixo de 30% (`vida_baixa_frac`): cresce e pulsa
  como batimento quanto menos vida. Um gradiente na tela, custo ~zero.
- Tutorial e CONTROLES.md atualizados. Teste de regra novo `_lote_2_7`.
- `--vitrine`: os 3 ataques agora saem a cada 50 quadros (antes 35; o 3º clique caía na
  recarga e o golpe final nunca aparecia). Print: `jogabilidade/09-golpe-final-2-7.jpg`.
- Sonda de equilíbrio (8 partidas): K/D Kitsune 2,5, Luz 1,7, Ninja 1,35, Sombria 1,2,
  Ronin 1,1, Samurai 0,8, Yumi 0,6; 2 pontos nas 8 partidas. Nenhum número de classe mexido
  além do combo: Samurai e Yumi baixos são candidatos ao próximo ajuste.
- Mexe em `unit.gd`, `projectile.gd`, `game.gd`, `hud.gd`, `mira.gd`, `game_config.gd`,
  `class_stats.gd` e nos .tres de Samurai, Ronin, Ninja, Kitsune e Construtor.
- **O que testar**: jogue de Samurai e faça o combo de 3 cliques (o 3º desce reto e pega só
  na frente); de Ninja, 3 tiros seguidos (o 3º é um leque); de Kitsune, 3 tiros (o 3º
  explode). Veja se o E enche em ~30 s mesmo sem acertar ninguém e se o Q volta rápido.
  Apanhe até ficar com pouca vida e veja a borda vermelha. Repare se aparecem itens perto
  da briga do meio. Diga se a vida maior deixou a luta longa demais.

## Publicação (2026-11-04): versão de teste também no itch.io
- CI (`build.yml`): na `main`, depois dos testes, manda web, Windows e Linux para o
  itch.io com o `butler` (canais `web`, `windows`, `linux`). Só liga quando existirem o
  segredo `BUTLER_API_KEY` e a variável `ITCH_ALVO` (ex.: `julioraicher/castelo-de-bolo`).
- GitHub Pages só publica com o repositório público; no privado o passo é pulado sem
  quebrar a CI. A release `ultima-versao` continua (no privado, só com login).
- **O que testar:** depois de configurar o itch.io, abrir a página oculta e jogar a
  versão web; o .exe aparece na mesma página. Nenhuma regra de jogo mudou.

## Ciclo 2.6d (2026-11-05), Jogabilidade: modo teste (sandbox)
- **Modo teste**: só você no mapa, **sem bots**. Todas as oficinas do seu castelo já
  prontas (inclusive as **duas** dos magos, Luz e Sombria, sem selo) e todas as
  maquininhas no nível 2. As maquininhas repõem o chapéu em 1 s.
- Na casa de uma oficina comum, **[F] troca a classe** (Ronin Oni, Yumi, Armadilheiro,
  Bombardeiro; o pedestal ganha o chapéu novo). Na casa de um mago, **[F] sobe o nível**
  até o 5.
- **Mapa leve** no modo teste (`Arena.leve`): saem os enfeites do chão (capim, flores),
  a floresta da borda, as partículas e as casas/árvores/lanternas do meio (com o colisor).
  Ficam chão, rio, pontes, colinas, castelos e as árvores de madeira.
- Como abrir: botão **"Modo teste (sem bots)"** na tela inicial (o mesmo botão volta para
  a partida normal); na web, o endereço com `?sandbox`; na linha de comando, `--sandbox`.
- Mexe em `game.gd` (`sandbox`, `_montar_sandbox`, `_regras_sandbox`), `oficina.gd`
  (`concluir_ja`, `trocar_pronta`), `arena.gd` (`leve`) e `menus.gd` (botão). A partida normal não muda.
- **O que testar**: abra o link com `?sandbox` (ou o botão na tela inicial), pegue cada
  chapéu, troque as oficinas com F e suba a Kitsune da Luz e a Sombria até o nível 5.

## Ciclo 2.6c (2026-11-01), Jogabilidade: mira nova (piloto do mouse aprovado)
- **Cursor próprio "Mira de ouro"** (`scripts/ui/mira.gd`, novo): aro + 4 marcas + ponto,
  na **cor do seu time**. É cursor de hardware (`Input.set_custom_mouse_cursor`, desenhado
  por código, sem arquivo de arte): continua liso mesmo com FPS baixo. Nos menus/pausa
  volta a setinha normal.
- **O cursor avisa**: inimigo embaixo (fica na cor do inimigo, as marcas giram e fecham),
  fora do alcance (apagado; só classes de tiro), anel de **Chi** em volta enchendo e
  brilhando quando o E está pronto, tracinho da **recarga do Q**, pulso vermelho com
  **vida baixa** e hexágono azul enquanto **defende**.
- **Efeitos no clique** (nível médio): faíscas douradas + anel no ataque, anel ciano no Q,
  explosão na cor do poder no E. Q/E sem carga dão um "não" cinza no cursor.
- **Marcas no chão por classe**: onde o tiro em **arco** cai (Yumi, Kitsune Sombria,
  Bombardeiro, já presa entre o mínimo e o máximo). Com o **E pronto**, a área do poder:
  no cursor (Chuva de flechas, Selo, Coluna de fogo), em volta do corpo (Redemoinho,
  Bênção, Fúria, Campo minado, Mutirão) ou a fila de explosões do Bombardeio.
- Flag de print `--mira` (com `--autoplay --shots`): desenha a mira seguindo o bot.
- Mexe em `player_brain.gd` (avisa a mira no clique/Q/E) e `game.gd` (cria a `Mira`).
  Nenhuma regra de jogo mudou.
- **O que testar**: jogue com o mouse e veja se a mira some no cenário; passe por cima de
  um inimigo; segure o direito; espere o anel do E encher e aperte E; jogue de Yumi e veja
  o círculo de onde a flecha cai. No navegador e no .exe.

## Limpeza 2.6b (2026-11-01), revisão rápida: peso morto e docs velhos
- Revisão do código: sem funções mortas, sem campos velhos nos `.tres`; testes de regra
  167/167. A limpeza grande já tinha sido a 2.5c (PR #21).
- **Build ~4,6 MB menor**: saíram as maquininhas de Ronin Oni, Yumi e Kitsune Luz/Sombria
  dos 4 temas (16 `.scn`). O jogo nunca as carregava: só as 4 classes do pátio têm
  maquininha. `tools/gerar_economia.gd` (`MAQUINAS`) e `prancha_economia.gd` passaram a
  gerar só essas 4; os desenhos das outras continuam no gerador (ver comentário).
- **Docs**: apagados `docs/identidade.md` (fase "Clãs de Neon"), `docs/design-jogo.md`
  (substituído por `docs/elenco-ciclo-2.4.md`) e `docs/revisao-2.4.md` (relatório
  pontual). ROADMAP com os Ciclos 2.3 a 2.5 marcados; AULA sem o Clérigo.
- Duas constantes sem uso em `scripts/ui/estilo.gd` e a malha de estrela antiga do
  `projectile.gd` (sobrou depois que os efeitos foram para `fx_projetil.gd`). Nenhuma regra de jogo mudou.
- **O que testar**: nada novo para jogar. Só confira que o jogo abre e as 4 maquininhas
  do pátio aparecem como antes.

## Ciclo 2.6a (2026-11-01), Diretor Visual: efeitos dos poderes (direção do Quiz dos Efeitos)
- **Seis camadas por projétil** (`scripts/fx/fx_projetil.gd`, novo): cor, forma, rastro,
  impacto, reação do alvo (só visual, ~1 s) e som, como em `docs/direcao-efeitos.md`.
  - Shuriken de **aço** (lâmina clara, fio brilhando), lascas de metal no caminho, estilhaço
    e tinido no acerto; fica cravada no alvo ou no chão um instante.
  - Flecha **de verdade** (haste, ponta, penas na cor do time), fita de vento fina, poeira
    e marca no chão; crava no chão ou no corpo.
  - Bomba com faíscas do pavio e fumacinha; explosão com bola de fogo, fumaça escura
    subindo e chão queimado por ~2 s (vale também para a mina).
  - Kitsune: **três fogos-fátuos** rosas girando em volta do tiro; faíscas e anel no acerto;
    brasa no corpo.
  - Kitsune da Luz: **lança dourada** com brilhos piscando; **cruz de luz** no acerto.
  - Kitsune Sombria: **orbe do vazio com um olho** e fita de sombra; **implode** no acerto
    e deixa tinta escorrendo no corpo.
- **Orçamento por frequência**: ataque básico leve (≤ 8 partículas no rastro), Q
  (tiro carregado, Leque) com rastro maior e impacto próprio, E com tudo + marca no chão +
  som cheio (taiko e estrondo). Na qualidade **Mínima** o rastro, a marca no corpo e as
  flechas cravadas desligam, e os impactos caem pela metade.
- **Golpe corpo a corpo**: o arco ganhou um fio claro na borda (lê como lâmina) e o acerto
  solta um risco de luz, fagulhas de aço quente e respingos de tinta escura (a faísca
  branca sumia no corpo que pisca branco).
- **Oficina sobe de nível**: três anéis dourados sobem pela casa e o letreiro "NÍVEL N!".
- **Captura da máscara**: coluna de luz na cor do time no castelo, anéis subindo e gongo.
- **Números de dano um pouco menores** e cada um vê só o dano que deu (amarelo) e o que
  levou (vermelho); a cura idem. Bots contra bots não enchem mais a tela de número.
- **Sons novos** (`tools/gerar_sons.py efeitos`): lançar metal, pavio, fogo, luz, sombra;
  tinido, flecha no chão, brasa, sino, implosão, explosão; estrondo do E, nível, captura.
  Volume pela distância (já era 3D).
- Custo: tudo é `CPUParticles3D` com malha e material em cache (1 draw call por sistema,
  nenhum shader novo na luta; `FxProjetil.prewarm` esquenta no começo). Medida em
  partida de 90 s com todo mundo soltando poder a cada 4 s (`--poderes --perf=2`, xvfb):
  FPS médio 7,1 → 6,9 (−3%, dentro do ruído e do orçamento de 10%), draw calls 560 → 510.
- Ferramenta: `--vitrine=<pasta>` + `tools/vitrine.sh` (mesmo roteiro por classe, câmera
  fixa) gera o GIF antes/depois de cada poder.
- Toque em código de Jogabilidade (aviso): `Unit.take_damage` ganhou `elemento` e `nivel`
  opcionais (só visual); `Unit.heal` ganhou `quem`.
- **O que testar**: jogue de Ninja de Shuriken, Yumi, Bombardeiro e das três Kitsunes e
  veja se dá para reconhecer cada tiro sem ler nada; se o golpe do Samurai/Ronin ficou com
  mais peso; suba uma oficina de mago de nível (anéis + letreiro) e capture a máscara
  (coluna de luz). Diga se ficou muito ou pouco na tela e se o FPS caiu.
## Ciclo 2.5g (2026-11-01), Jogabilidade + Interface: página "Como jogar"
- **Como jogar** (`scripts/ui/tutorial.gd`): 5 abas, Objetivo, Classes (4 papéis com as
  variações, de onde saem e a Q de cada), Madeira (cortar, pegar, entregar, construir;
  inclui o corte do Bombardeiro), Casinhas e níveis (maquininhas, oficinas, nível 2) e
  Luz e Sombra (caminho que sela o outro, níveis 2 a 5). Os números saem do
  `game_config`: mudou um custo lá, o texto muda junto. Visual com o Estilo "Festival
  sombrio".
- Abre sozinha na **1ª partida** (`Settings.tutorial_visto`), tem botão **Como jogar** ao
  lado de JOGAR e é a 1ª aba do menu de pausa (Esc), junto de Controles e Configurações.
- **Clipes** em cada aba, gravados do jogo (`assets/tutorial/<aba>/NN.jpg`, 10 quadros/s,
  importados em WebP com perdas, ~1,5 MB no total). Só carregam quando a aba abre.
  Ferramentas: `--tutorial=DIR` (print das abas) e `--clipe=DIR --clipe-ini=s
  --classe=X [--clipe-cena=mascara]` (grava um clipe novo).
- **O que testar**: (1) Abra o jogo (na 1ª vez a página abre sozinha; depois, botão
  "Como jogar" na tela inicial ou Esc > Como jogar). (2) Passe pelas 5 abas: o texto
  explica o Construtor de um jeito que dá para seguir? (3) Os clipes ajudam ou é melhor
  trocar por cenas montadas (ex.: alguém roubando a máscara)?

## Ciclo 2.5f (2026-10-31), Visual + Jogabilidade: pátio em ferradura e Torre da Máscara
- **Pátio em ferradura** (prancha aprovada pelo Julio): muralha com passarela em arco de raio
  22 m (antes era um retângulo de 32 × 28 m), aberta para o inimigo, com uma **saída larga** de
  24 m entre duas torres e **2 portões laterais** que dão nas trilhas da floresta. As 4
  maquininhas ficam no meio do arco, as oficinas vêm depois, e **Luz** (em cima) e **Sombra**
  (embaixo) ficam nas pontas. Há uma praça de pedra no centro, calçadas até as saídas e
  pilares com lanterna nas juntas da muralha.
- **Torre da Máscara** (refeita do zero): tem 20 m, 3 andares e frisos na cor do time. A
  **máscara Oni viva** na frente tem rugas, veias, órbitas fundas, olhos de fera (íris do
  time e pupila em fenda), narinas que soltam fumaça, boca rosnando com fogo dentro,
  mandíbula que respira, chifres em gomos com anéis de ouro, e juba e barba ao vento.
  Animações: "respirar" (sempre) e **"alarme"** quando a máscara é roubada (olhos piscam
  rápido, boca abre, fogo cresce, fumaça engrossa). Volta a respirar quando a máscara
  está em casa.
- Dados: campos novos `MapLayout.wall_arc_*` e `keep_model` (o padrão é 0/vazio, que mantém
  a muralha retangular). Arena: `_wall_arc`, `wall_arc_runs`, `torre_alarme`. O minimapa
  desenha o arco. Renascer (`spawn_spots`) em 6 pontos do arco, perto das saídas. O bosque
  seguro foi para fora do portão de baixo, e o depósito ficou por dentro dele. 16 objetos
  do meio do mapa que caíam dentro da ferradura saíram.
- Desempenho: a torre tem ~7,3 mil triângulos e 5 peças animadas (olhos, mandíbula, fogo da
  boca e 2 braseiros); as lanternas ficaram fixas para economizar chamadas de desenho.
- QA do mapa: os avisos caíram de 38 para 9 (os 4 "inalcançáveis" em z = -46 já existiam).
  Testes 167/167, com o `_ferradura` novo. 5 min simulados sem erro. O teste do Bombardeiro
  longe da árvore agora procura um ponto longe de todas as plantas.
- Saiu a escada da passarela: a muralha nova não tem acesso por cima (dá para voltar depois,
  se fizer falta).
- **O que testar**: (1) entre no seu pátio: ele deve parecer bem mais espaçoso, sem trombar
  nas casinhas. (2) Saia pelos portões laterais até as trilhas. (3) Pare na frente da torre
  e veja a máscara respirando e soltando fumaça. (4) Quando roubarem sua máscara, a torre
  entra em alarme. (5) Veja o minimapa com o arco.

## Ciclo 2.5e (2026-10-31), Interface: identidade "Festival sombrio" no jogo inteiro
- **Fontes**: Lilita One (títulos, avisos, números, botões, letreiros 3D) com contorno
  grosso de tinta e sombra sólida; Nunito Black no texto. Shojumaru e Barlow saíram
  (OFL das novas em `assets/fonts`). Tudo passa por `scripts/ui/estilo.gd`; os nomes
  antigos (`TITULO`, `FORTE`, `NUMERO`, `CORPO`) continuam valendo.
- **Molduras**: placas de laca escura com borda de ouro e sombra sólida
  (`Estilo.placa`); botões e aba escolhida em ouro com degradê (`Estilo.botao_ouro`,
  um StyleBox desenhado à mão, porque o StyleBoxFlat não faz degradê). Paleta reduzida a
  ouro, cor do time e laca.
- **HUD cheio, preso nas bordas**: máscaras e placar numa faixa só no topo (antes eram
  duas linhas descendo pela tela); **abates e quedas** novos no canto superior esquerdo;
  aviso grande saiu do meio e fica logo abaixo do placar; dica colada embaixo. O centro
  é da briga.
- **Tela inicial**: controles em duas colunas; o botão JOGAR agora cabe na tela
  (antes ficava cortado em 1280x720).
- Mudanças pequenas em pastas de outros papéis (aviso): `game.gd` ganhou
  `abates_jogador`/`quedas_jogador` e o modo de print `--menu=inicio|pausa`; Label3D de
  `oficina`, `pilha`, `hat_pad`, `guia_construtor`, `fx`, `fx_poder` e
  `contador_madeira` com Lilita e contorno de tinta. Guia atualizado:
  `docs/estilo-textos.md`.
- **O que testar**: abra o jogo e olhe a tela inicial (título, cartões, botão JOGAR de
  ouro). Na partida, confira se dá para ler placar, vida, Chi e Q no meio de uma briga
  com efeitos, e se o centro fica livre. Abata alguém e caia uma vez: os números no
  canto superior esquerdo sobem. Esc: abas e botões de ouro; Configurações legíveis.

## Ciclo 2.5d (2026-10-31), Jogabilidade: corte do Bombardeiro, contador de tora e ritmo
- **Bug**: Bombardeiro (e qualquer lenhador que ataca de longe) seguia a seta até a
  árvore e o clique jogava bomba. Agora, com uma planta jovem/adulta à frente a até ~3 m,
  o clique vira **machadada** (anim. de golpe, 1 tora). Longe dela, bomba normal. Bots do
  Bombardeiro chegam a 3 m para cortar. Teste novo `_machadada` (161 testes).
  O Armadilheiro já cortava (é corpo a corpo); agora o teste garante isso.
- **HUD**: ao lado de "Madeira do time: N" aparece **CARREGANDO 1/1** enquanto há tora
  nos braços (nó novo no `hud.gd`, nada movido).
- **Ritmo**: `MapLayout.spawn_spots` (+ `spawn_jitter`): renascer no ponto menos lotado
  entre 6 pontos do pátio (o mapa em ferradura vai trocar pelos pontos do arco).
  `game_config.inicio_calmo = 30` s: atacantes e confeiteiros ficam espalhados na própria
  metade (frente e laterais); depois invadem. Kitsunes atacantes andam ~6 m atrás do
  guerreiro aliado mais adiantado; o Construtor segue no bosque.
- **O que testar**: (1) pegue o chapéu de Construtor, suba para Bombardeiro, siga a seta
  e clique colado na árvore: deve sair machadada e tora. (2) Com a tora nos braços, veja
  "CARREGANDO 1/1" embaixo à esquerda. (3) Nos primeiros 30 s ninguém deve invadir seu
  castelo; depois a briga começa. (4) Morra algumas vezes: o renascer muda de lugar.

## Limpeza 2.5c (2026-10-31), revisão de código: tirar o que sobrou de versões antigas
- **Nada muda no jogo** (regras, números, visual e controles iguais). Testes 155/155 e 5 min
  simulados sem erro, antes e depois.
- Saíram (~2,9 MB, 93 arquivos): tema **Medieval** e os modelos KayKit de cenário
  (`assets/medieval`), tema Sinistro, mapas **Vale** e **Vale Ninja** (o padrão agora é o
  Rio das Lanternas), peças ninja que nenhum mapa usa (`casa_b`, `ponte_corda`,
  `pilha_toras`, `emblema_monge`).
- Código: poderes de classes descartadas no Ciclo 2.4 (Corrida como E, Corte Relâmpago
  como E, Reforço, Nuvem como E) em `unit.gd`, `bot_brain.gd` e `fx_poder.gd`; estilos
  `_monge`, `_onmyoji`, `_lamina_dupla`, `_fumaca`, `_carpinteiro` em `ninja_visual.gd`;
  linha de mira sem uso e `is_busy_carrying` em `unit.gd`; campo `hat_respawn_time`.
  Os padrões de `ThemeConfig`/`MapProp` passaram a apontar para as peças ninja.
- Ferramentas (Diretor Visual, aviso): saíram `gerar_classes.gd` (estava velho: rodá-lo
  sobrescreveria as classes atuais com números do Ciclo 2.2), os pilotos do 2.2
  (`prancha_piloto`, `prancha_mecanica`, `prancha_cenario`, `prancha_poder`, `montar_*`) e
  `minimapas.py` (mapa antigo). `gerar_cenario_ninja.gd` não gera mais o Vale Ninja;
  `gerar_mapa_rio.gd`/`gerar_economia.gd` não geram as peças sem uso. `.tres` das classes =
  fonte da verdade.
- Docs: README, CONTROLES (chapéus, oficinas, caminho dos magos, tema) e GUIA (mapa dos
  arquivos) atualizados para o jogo de hoje.
- Pendente (ideia, não feito para não mexer antes do teste): renomear no código
  `Princess` → máscara e `Cake` → espírito.
- **O que testar**: jogue normalmente; tudo deve estar igual à 2.5b. Em Esc >
  Configurações, troque os 4 temas (Festival ao Sol, Crepúsculo, Floresta Oni, Templo ao
  Luar) e veja se o mapa monta inteiro em cada um.

## Ciclo 2.5b (2026-10-31), Jogabilidade + mapa: caminhos opostos dos magos
- **Escolha de caminho** (pedido do Julio): cada castelo tem dois terrenos fixos de mago,
  **Luz em cima** (Kitsune da Luz) e **Sombra embaixo** (Kitsune Sombria), no meio do
  pátio. A primeira madeira num deles **sela o outro até o fim da partida** (corda de selo,
  estandarte tomba). As Kitsunes saíram do sorteio das oficinas comuns.
- **Níveis 2 a 5**: pronta, a oficina do caminho fica no nível 2 (sobe a maquininha de
  Kitsune, como antes) e o Construtor continua levando madeira: 6, 8 e 10 madeiras para os
  níveis 3, 4 e 5. Decisão de equilíbrio (fácil de mudar em `game_config.tres`, grupo
  "Caminho dos magos"): por nível acima do 2, o mago do caminho ganha **+8% de dano, +8% de
  vida e +10% de Chi**; a maquininha dele ganha +1 de estoque e fabrica 15% mais rápido.
  Nível 5 = +24% / +24% / +30%. Modesto porque a Luz já é forte (sonda 2.4l).
- **Indicações**: estandarte na cor do mago e título a pincel ("Luz"/"Sombra") em cada
  terreno; ao chegar perto pela primeira vez, aviso grande "Caminho da Luz ou da Sombra:
  construir um sela o outro"; dica embaixo com o que falta; aviso a cada nível (seu e do
  inimigo); losango no minimapa (X apagado no selado).
- Mapa: oficinas comuns foram para a frente do pátio (4,5; ±5,2); magos em (−3; ±6,2).
  Campo novo `MapLayout.mago_spots` (vazio = Kitsunes voltam ao sorteio, sem caminho).
  Bots escolhem um caminho ao começar a obra e sobem os níveis depois das outras obras.
- Testes: `_caminho_magos` (selo, selado não aceita madeira, níveis com 24 madeiras,
  bônus só para a classe e o time do caminho).
- **O que testar**: vá de Construtor até o meio do pátio; leia o aviso, leve madeira para
  a Luz ou a Sombra e veja o outro terreno ser selado. Depois de pronta, continue levando
  madeira: o letreiro mostra "NÍVEL 3/5" e o aviso aparece a cada nível. Diga se o bônus
  por nível é pouco ou demais, e se as oficinas comuns na frente atrapalham a passagem.

## Ciclo 2.5a (2026-10-31), Diretor de Jogabilidade: botões novos e sensação de porrada
- **Controles** (pedido do Julio): esquerdo ataca · **direito defende** (todas as classes,
  com contra-golpe) · **Q = habilidade rápida** com recarga curta · **E = poder de Chi**
  (o antigo Q) · **F = interagir** (chapéu, máscara, oficina; era o E) · tela cheia só F11.
- Q por classe (tabela em CONTROLES.md): o que era do botão direito virou Q na hora
  (tiro carregado = tiro cheio que atravessa, cura, mina). Novos: Samurai **Investida**
  (corte em avanço), Ronin **Pisão** (onda curta), Construtor **Corrida** curta; o E do
  Construtor virou **Mutirão**. Superpoder: só anotado em docs/ideias.md.
- Defesa visível: arco na cor do time na frente do corpo, mais forte na janela do
  contra-golpe. Quem bate no escudo quica para trás e trava um instante.
- Porrada: número de dano com "pop" (maior no golpe forte e no seu), escorrega para onde
  o golpe empurrou; golpe forte soa mais grave e pisca mais; tiro seu que acerta dá
  micro-pausa no alvo e um toque na câmera. Resto da lista em docs/ideias.md (A).
- Bots: defendem (corpo a corpo mais vezes), usam o Q de cada classe. Esquemas novos em
  `ClassStats` (`skill_name`, `skill_cooldown`, `skill_value`, `skill_radius`,
  `skill_duration`). Testes 157/157 (Q de toda classe sai e recarrega; Kitsune defende).
- **O que testar**: jogue de Samurai e de Ninja: direito segura a guarda, Q (barra dourada
  no HUD) e E quando o Chi enche. Pegue chapéu com **F**. Diga se a Investida/Pisão e as
  recargas estão rápidas demais ou devagar.

## Ciclo 2.4o (2026-10-31), Jogabilidade: coleta de madeira clara + minimapa
- **Guia do Construtor** (`scripts/fx/guia_construtor.gd`): quando você é Construtor, uma
  **seta dourada no chão** aponta o próximo passo e um marcador quica em cima do alvo com o
  verbo: **CORTE** (árvore pronta mais perto, a do seu bosque tem preferência), **PEGUE**
  (tora no chão), **ENTREGUE** (depósito, quando a tora está nos braços) e **CONSTRUA**
  (obra que já tem madeira no estoque). A dica de baixo repete o passo em texto.
- Virar Construtor mostra na hora: "Corte árvores e leve as toras ao depósito".
- **Depósito** (`pilha.gd`): ícone grande de tora flutuando, placa "DEPÓSITO · N" e um
  **anel no chão do raio de entrega**, que acende e pulsa quando você chega com uma tora.
- **Minimapa** no canto inferior direito (`scripts/ui/minimapa.gd`): castelos, máscaras,
  árvores/bambus prontos (verde vivo; crescendo = apagado), toras soltas, depósitos,
  oficinas, seu time e você (seta). Linha tracejada até o alvo da seta do Construtor.
  **Inimigos não aparecem** (ideia "spotar" anotada em `docs/ideias.md`, C).
- Regras e números intocados. Testes OK; 5 min simulados como Construtor sem erro.
- **O que testar**: pegue o chapéu laranja e siga só a seta e o minimapa: dá para cortar,
  entregar e construir sem ler mais nada? O minimapa atrapalha a visão em algum canto?
## Ciclo 2.4n (2026-10-31), Diretor Visual: letras e textos com identidade
- **Fontes novas** (OFL, `assets/fonts`): sai a Chakra Petch (cara de painel neon, sobra dos
  Clãs de Neon); entra a família **Barlow Condensed** (texto, botões, números), mais grossa e
  legível. **Shojumaru** (pincel) fica só para títulos curtos. Guia em `docs/estilo-textos.md`
  (fontes, escala de tamanhos `Estilo.T_*`, cores, tom da escrita), para todas as threads.
- Cores do texto quentes (papel de arroz e tinta), no lugar do branco-azulado neon.
  Nada abaixo de 15 px. Filete dourado sob os títulos. Teclas desenhadas sem borrão.
- **Avisos grandes** do meio da tela agora em letra larga e caixa alta (a de pincel embolava
  em frase de duas linhas). Placar, vida e números de dano na fonte de números.
- **Textos revistos**: tela inicial (subtítulo "A guerra da Máscara Oni"; lista de chapéus
  certa, lida do `game_config`; dicas mais curtas), lista de controles enxuta, frases de status
  no imperativo ("LEVE A TORA AO DEPÓSITO"), estado das máscaras, aviso de qualidade gráfica.
- Ajuda "Esc pausa e controles" foi para o **canto superior direito** (o inferior direito é do
  minimapa da outra thread).
- Toque mínimo fora do Visual (só texto): `config.gd` (CONTROLS), `unit.gd` (aviso do Chi),
  `auto_quality.gd`, `project.godot` (fonte padrão). Testes 111/111; 5 min simulados sem erro.
- Revisão das dicas novas do Construtor (thread do minimapa): ok; só a da maquininha nível 2
  usava "→", que as fontes não têm (viraria quadradinho no navegador).
- **O que testar**: tela inicial e Esc (leitura, nada cortado); placar e cartão do jogador
  durante a briga; avisos grandes (pegar chapéu, ponto, Chi cheio). Me diga se alguma letra
  ficou pequena demais no seu monitor.

## Ciclo 2.4m (2026-10-31), Diretor Visual: efeitos do Bombardeio e do arremate da Chuva
- **Bombardeio**: os anéis de aviso viraram pavio: cada anel encolhe e gira até o centro no
  tempo exato da sua explosão (lê a ordem da fila). Cada explosão ganha bola de fogo que
  incha, coluna curta, estilhaços, poeira escura e uma **mancha queimada** que fica ~4 s
  (`FxPoder.aviso_bombardeio`, `FxPoder.explosao_polvora`).
- **Arremate da Chuva**: cinco lanças de luz caem do céu no centro e abrem um clarão em cruz
  na cor do time (`FxPoder.arremate_chuva`). Cor pura e alfa baixo: aditivo forte em chão
  claro estourava para branco e parecia um cone de gesso.
- Toque mínimo no código do Jogabilidade (avisado): `unit.gd` (troca o laço de anéis pelo
  pavio e chama a explosão), `arrow_rain.gd` (chama o arremate). Dano, raio e tempo intocados.
- Ferramenta de print: `--classe=<nome>` (jogador começa na classe) e `--print-poder=<s>`
  (atraso do print depois do Q) em `game.gd`.
- **O que testar**: de Bombardeiro, solte o Q num grupo e veja se dá para fugir pelo pavio;
  de Yumi, veja o estouro no fim da chuva nos temas claro e escuro.

## Ciclo 2.4l (2026-10-31), Diretor de Jogabilidade: sonda de equilíbrio
- `tools/sonda_equilibrio.sh`: 8 partidas simuladas com todas as classes, girando quem pega
  cada papel de bot (`--variacoes=N`), e soma mortes/abates por classe (`--equilibrio`).
- Resultado (tabela em docs/revisao-2.4.md): classes de oficina rendem mais que as do pátio,
  como planejado; Samurai e Ninja perto de 1 abate por morte. **Não mexi em número.**
- Só ferramenta de teste: nada muda na partida normal.
- **O que testar**: nada novo para jogar; se achar alguma classe forte/fraca, me diga qual.

## Ciclo 2.4k (2026-10-31), Diretor Visual: efeitos do Campo Minado e do vórtice
- **Campo Minado** (Q novo do Armadilheiro): cada mina sai voando da mão em arco até o
  lugar no anel e acende ao cair; o anel no chão usa o verde do chapéu (`FxPoder.campo_minado`).
- **Redemoinho**: anel de vento na borda da puxada (raio × `redemoinho_puxa_raio`) que se
  fecha no Samurai duas vezes: lê "puxa", não só "gira" (`FxPoder._succao`).
- Toque mínimo em `unit.gd` (chama o efeito e passa os pontos das minas). Testes 109/109;
  1,5 min com todos soltando poder sem erro de script.
- **O que testar**: de Armadilheiro, solte o Q; de Samurai, solte o Q perto de inimigos.

## Ciclo 2.4j (2026-10-31), Diretor de Jogabilidade: Q "uau" da Yumi e do Bombardeiro
- **Bombardeio** (Bombardeiro, no lugar da Nuvem de Fumaça; quiz: "bombas de pólvora/fumaça"):
  5 explosões em fila do pé dele até a mira, uma a cada 0,16 s (`bombardeio_intervalo`),
  22 de dano cada (raio 2,6, arremessam); a última deixa fumaça por 4 s (`bombardeio_fumaca`).
  Anéis laranja avisam onde vai cair.
- **Arremate da Chuva de Flechas** (Yumi): quando a chuva acaba, a última salva cai junta no
  centro (60% do círculo), com 2,5× o dano do pulso (`chuva_arremate_mult`) e arremessa.
- Construtor fica com a Corrida (ele é o econômico; o "uau" dele é o upgrade).
- Testes 111/111; 2,5 min com todas as classes soltando Q a cada 4 s sem erro.
- **O que testar**: jogue de Bombardeiro e mire o Q num grupo; de Yumi, veja o estouro no
  fim da chuva.

## Ciclo 2.4i (2026-10-31), Diretor de Jogabilidade: mais pontos e Q com mais "uau"
- **Ritmo de pontos** (opção recomendada do card, alvo 1 a 3 pontos a cada 5 min):
  `carrier_damage_mult` 0,5 → 0,4 (quem leva a máscara aguenta mais) e
  `princess_return_time` 15 → 25 s (dá tempo de o time do ladrão retomar a máscara caída).
  Com bots: ~1,7 ponto por 5 min (antes ~0,5). **Você pode trocar**: são só esses dois
  números em `config/game_config.tres` (0,35/25 já dá 3-5 pontos e a partida acaba cedo).
- **Q com mais "uau"** (sem mudar o elenco do quiz):
  - Fúria (Ronin Oni): ele cresce 35% (`furia_escala`) e quase não é empurrado.
  - Redemoinho (Samurai): vira vórtice e puxa os inimigos em volta para dentro do giro
    (`redemoinho_puxa` 4,5 m/s, raio ×2,2).
  - Leque de Shuriken (Ninja): segunda onda 0,25 s depois.
  - **Campo Minado** (Armadilheiro, no lugar do Reforço): anel de 6 minas em volta dele (não contam no
    limite de armadilhas). Bots usam com 2+ inimigos perto ou defendendo o portão.
- Testes 109/109; 5 min com poderes a cada 4 s sem erro.
- **O que testar**: jogue de Ronin Oni e solte o Q no meio da briga; de Samurai, gire perto
  de um grupo; pegue a máscara e veja se dá para chegar em casa.

## Ciclo 2.4h (2026-10-31), Diretor Visual: nome dos poderes dos bots mais discreto
- Revisão por prints (Crepúsculo e Luar, com todos soltando poder): os nomes dos poderes
  dos bots ("REDEMOINHO!", "LEQUE DE SHURIKEN!") se empilhavam no meio da briga. Agora o
  nome do poder de bot é menor (46 em vez de 64) e some mais cedo; o do jogador continua
  grande (`fx_poder.gd`).
- Conferido: HUD novo, letreiros de 2 linhas e depósito legíveis no Luar; Coluna de
  Fogo rosa no Crepúsculo.
- **O que testar**: numa briga grande, veja se dá para ler o seu próprio poder.

## Ciclo 2.4g (2026-10-31), Diretor de Jogabilidade: menos texto na tela
- "ESQUIVA!" só aparece quando o jogador está na jogada (ele esquivou ou foi o golpe dele
  que passou pelo dash). Bot contra bot continua ganhando o Chi, sem o texto.
- **O que testar**: numa briga grande, a tela tem menos letreiro; o seu "ESQUIVA!" continua.

## Ciclo 2.4f (2026-10-31), Diretor Visual: revisão (fogo da Kitsune, trilha nos temas escuros)
- Coluna de Fogo (poder da Kitsune) na cor do chapéu de quem lança: rosa na Kitsune,
  dourado na da Luz, roxo na Sombria (`area_effect.gd`, `fx_poder.gd`, chamada em `unit.gd`).
- Trilha da floresta mais clara: no tema Oni ela quase sumia no chão roxo.
- Conferido nos prints: depósito à vista também no Luar; HUD novo legível em jogo.
- **O que testar**: jogue de Kitsune e solte o Q; troque o tema para Oni e siga a trilha.

## Ciclo 2.4e (2026-10-31), Diretor de Jogabilidade: esquiva perfeita e letreiros
- **Esquiva perfeita** (quiz 2.4, pergunta 7: "uau" também no dash): o dash continua
  igual; quando um golpe passa por dentro dele, sai "ESQUIVA!", ganha `chi_esquiva` 8 de
  Chi e, se for o jogador, um instante de câmera lenta (0,45× por 0,22 s).
- Letreiros das maquininhas em duas linhas (nome / "2/3 · 15s") e menores: o "Construtor
  3/3" não invade mais o "Ninja de Shuriken 3/3" ao lado (aviso do Visual).
- Revisão: 6 partidas de 5 min, com e sem a alma de abate, deram 0-1 ponto nos dois
  casos (5-20 roubos por partida). A alma não é a causa: o ladrão cai em 3-4 s dentro do
  castelo inimigo. Fica como observação para o Julio (ver docs/revisao-2.4.md).
- Testes 107/107; 5 min sem erro.
- **O que testar**: dê dash no instante do golpe de um inimigo e veja "ESQUIVA!" com a
  câmera lenta; olhe os letreiros das maquininhas lado a lado.


## Ciclo 2.4d (2026-10-31), Diretor Visual: nível 2 à vista, elenco com cara própria, tela moderna
- **Maquininha nível 2** (contrato `N2_*`): cada `maquina_<classe>.scn` ganhou degrau de pedra
  com quinas de ouro, dois estandartes na cor da classe com lanterna acesa e uma coroa
  dourada no topo; a animação `subir_nivel` (1,4 s) faz as peças brotarem uma a uma com o
  anel aceso e uma baforada. Leitura de longe, estilo "prédio melhorado".
- **Elenco 2.4 com cara própria** (`ninja_visual.gd`, `config/classes/`):
  - Construtor: operário simples (`_construtor`): faixa branca, armação nas costas com
    duas toras e marreta de madeira. Os ramos herdam a faixa e ganham óculos.
  - Armadilheiro: visual de armadilhas (cesto de estrepes, mina verde), chapéu kasa verde.
  - Bombardeiro: barril de pólvora com pavio aceso e bomba na mão, chapéu barril vermelho-fogo.
  - Kitsune: fogo de raposa **rosa** (o ciano é do Ninja de Shuriken; roxo fica para a
    Kitsune Sombria, dourado para a da Luz). Tiro "fogo" também rosa (`projectile.gd`,
    toque na área da Jogabilidade).
  - Kitsune da Luz / Kitsune Sombria: santuário próprio (creme e dourado / negro e roxo)
    e emblema (`maquina_kitsune_luz/_sombria`, `emblema_kitsune_luz/_sombria`).
- **Tela mais moderna** (`estilo.gd`, `menus.gd`): painéis de vidro escuro com cantos
  arredondados, borda fina e sombra macia; destaque dourado no lugar do magenta; sem o
  corte inclinado; teclas desenhadas como tecla clara de teclado; barras arredondadas.
- **Mapa**: trilhas de terra na floresta (|z| = 30, `MapLayout.trail_*` -> `chao_pintado`);
  depósito de madeira saiu de trás da torre do portão para o canto da frente do pátio
  (`pilha_spot` (9,5; 12), no lugar da carroça), com a boca virada para a câmera.
- Ferramenta: `--vista=px,py,pz,ax,ay,az` (câmera parada para prints); `--vista=patio`
  segue o `castle_distance`. Prancha `tools/prancha_economia.gd --maquinas --n2`.
- **O que testar**: suba uma maquininha para o nível 2 (oficina da classe ou 8 madeiras)
  e veja os estandartes e a coroa brotarem; ande pela trilha da floresta até o castelo
  inimigo; abra o Esc e veja os menus novos; jogue de Construtor e de Kitsune.
## Ciclo 2.4c (2026-10-31), Diretor de Jogabilidade: magos opostos
- Pedido 2 do quiz ("mago do bem e do mal"): duas oficinas novas que sobem a
  maquininha da Kitsune para o nível 2 (`classe_base` kitsune). O time escolhe o lado no
  terreno ([E] antes de a obra começar; bots sorteiam):
  - **Kitsune da Luz**: cura 26 em 7 m a cada 3 s, mais vida (90), poder **Bênção da
    Raposa** (cura 40% e escudo 25 em 6 m). Máscara branca, chamas douradas.
  - **Kitsune Sombria**: não cura; tiro de magia 16 com carga (cheio atravessa), poder
    **Selo Sombrio** (área que cala os poderes). Máscara negra, chamas roxas.
- Oficinas agora têm 6 opções. Visual: `ninja_visual.gd` ganhou `_raposa()` com as duas
  variações (toque mínimo; emblemas e maquininhas próprias ficam com o Visual).
- Bot Construtor usa a Corrida (Q) com a tora ou indo longe (antes guardava o medidor).
- Teste da maquininha: zera o relógio depois de encher (falhava às vezes no CI).
- Testes 106/106; 5 min sem erro (Kitsune da Luz saiu aos 203 s).
- **O que testar**: no terreno, aperte [E] até "Kitsune Sombria" ou "da Luz", erga a
  oficina e pegue o chapéu: compare a cura forte com o tiro carregado roxo.

## Ciclo 2.4b (2026-10-31), Diretor de Jogabilidade: bots com dash e botão direito "uau"
- **Revisão dos bots** (pedido do Julio: "os bots usam dash e poderes?"): não usavam dash
  nem bloqueio. Agora (`BotBrain._tatica`, a cada 0,2 s): dash para fechar distância
  (corpo a corpo a 4-8 m), fugir com <35% de vida, recuar o atirador encurralado, sair
  do combo de quem está batendo e correr com a tora; Samurai/Ronin erguem o bloqueio
  contra quem golpeia de frente. ~1 dash a cada 12 s por bot.
- **Botão direito mais forte e mais frequente** (quiz 2.4, perguntas 1 e 7):
  - **Contra-golpe**: bloqueio erguido há ≤ `parry_janela` 0,3 s quando o golpe chega =
    dano zero, quem bateu fica atordoado `parry_atordoa` 0,8 s e leva 1,5 × o seu dano
    de volta ("CONTRA!", anel dourado, hitstop dobrado).
  - **Tiro cheio** (Ninja, Yumi): atravessa `carga_perfura` 2 inimigos (−20% por
    inimigo), maior e brilhante. **Bombardeiro** ganhou o tiro carregado: bomba
    cheia explode `carga_raio_bomba` 1,5 × maior.
  - Recargas: cura da Kitsune 5 -> 3,5 s, mina do Armadilheiro 5 -> 3,5 s.
- Testes 98/98 (contra-golpe dentro e fora da janela, carga); 5 min sem erro
  (5 contra-golpes e 8 perfurações entre os bots).
- **O que testar**: de Samurai, segure o direito no instante do golpe do inimigo
  (não antes): sai "CONTRA!". De Ninja, carregue o tiro até o fim numa fila de inimigos.

## Ciclo 2.4a (2026-10-31), Diretor de Jogabilidade: maquininha nível 2 e madeira no HUD
- **Maquininha nível 2** (quiz 2.4, pergunta 6): fabrica a cada `maquina_n2_intervalo` 12 s
  até `maquina_n2_estoque` 4 e ganha 1 chapéu na hora. Sobe de dois jeitos:
  1. a oficina pronta sobe a maquininha da classe de origem (`ClassStats.classe_base`:
     Ronin Oni -> Samurai, Yumi -> Ninja de Shuriken, Armadilheiro/Bombardeiro -> Construtor);
  2. o Construtor parado ao lado de uma maquininha nível 1 põe madeira nela
     (`maquina_n2_custo` 8, guardada como a obra). Serve de destino para a madeira
     depois das oficinas (antes sobravam ~22 no estoque no fim dos 5 min).
- Contrato com o Visual: nós `N2_*` no `maquina_<classe>.scn` aparecem no nível 2;
  animação `subir_nivel` se existir. Sem isso: pulinho, pilar dourado e "Nv2" no letreiro.
- Bots Construtores: oficinas prontas -> levam a madeira para a maquininha mais adiantada.
- HUD (toque na área do Visual, `hud.gd`): "Madeira do time: N" com o ícone de tora no
  cartão do jogador; status "LEVANDO TORA AO DEPÓSITO".
- Testes 92/92 (nível 2 pela oficina e pela madeira, sem subir duas vezes); 5 min sem erro.
- **O que testar**: erga a oficina do Ronin Oni e veja a maquininha do Samurai virar Nv2
  (12 s, 4 chapéus); de Construtor, pare ao lado da maquininha da Kitsune com madeira no
  estoque e veja o contador "faltam N" até subir.

## Ciclo 2.3c (2026-10-31), Diretor de Jogabilidade: obra guardada e progresso à vista
- Pedido do Julio: o progresso da construção não ficava claro e tinha de ser guardado.
  Causa: perto do terreno o [E] trocava a opção da oficina e **zerava a obra**. Agora a
  opção trava assim que a obra começa (tem progresso ou madeira); quem volta, o mesmo
  Construtor ou um aliado, continua de onde parou.
- Bots Construtores tocam a obra começada mais adiantada do time (`Game.obra_do_time`)
  em vez da mais perto: não espalham madeira em vários terrenos. 1ª oficina caiu de
  ~146 s para ~65-73 s nos 5 min simulados.
- Clareza: na tela, perto da obra, "Obra de X: 66% · faltam 2 madeiras · fique aqui para
  construir"; em cima da casinha o contador mostra "NN%" e uma barra clara (construído)
  por cima da dourada (madeira entregue). Letreiro "Obra: X" desce para perto da casa e
  sobe com ela. (Toque no `contador_madeira.gd` do Visual: parâmetro opcional `obra`.)
- Junto: depósito de madeira 3D do Visual (e4a8ac8) mesclado.
- Testes 86/86 (4 novos: trocar não apaga, parada não perde, aliados voltam à mesma obra).
- **O que testar**: de Construtor, ajude a erguer uma casinha até a metade, saia, volte (ou
  deixe um bot continuar): a porcentagem segue de onde parou e o [E] não apaga mais nada.

## Ciclo 2.3b (2026-10-31), Diretor de Jogabilidade: elenco novo e madeira mais clara (branch, espera o OK)
- Elenco do quiz já no jogo: pátio = Samurai, Ninja de Shuriken, Kitsune (Mago),
  **Construtor** (nome certo; base só coleta, sem estrepes). Oficinas (com madeira):
  Ronin Oni, Arqueiro Yumi, **Armadilheiro** (ex-Mestre da Pólvora) e **Bombardeiro**
  (ex-Bombas de Fumaça), os dois ramos do Construtor e coletam madeira.
  Saíram Monge, Onmyoji, Lâmina Dupla e Carpinteiro.
- Cada casinha pronta deixa a linha do Construtor +5% mais rápida (`construtor_vel_por_oficina`).
- Dica na tela perto de árvore/bambu (quem corta e para onde levar); a tora entregue
  voa num arco para dentro do armazém (depósito 3D do Visual, branch ra8pxs e4a8ac8).
- Testes 82/82 (menos classes = menos checagens de dados); 5 min sem erro.
- **O que testar**: pegue o chapéu laranja (Construtor), corte a árvore com cerca acesa
  fora da muralha lateral, leve a tora ao depósito perto do portão; erga uma casinha e
  veja o Armadilheiro/Bombardeiro na maquininha nova.

## Ciclo 2.3 (2026-10-31), Diretor Visual: mapa maior e maquininha por classe (branch)
- Pedido do Julio: peças muito juntas; quer caminhos pela floresta para flanquear,
  mapa maior e mais espaçado. Rio das Lanternas passa de 136 x 72 para 168 x 96 m
  (`castle_distance` 60): vila com uma fileira de cada lado e becos de ~5 m,
  campo do meio solto (|z| 14 a 22), trilhas de floresta em |z| = 30 (pontes
  laterais -> mata -> lado do castelo inimigo, onde fica o bosque de corte dele),
  lanternas de pedra a cada ~12 m marcando a trilha, colinas viraram mirantes
  (|z| = 41) e um corredor de ~6 m atrás de cada castelo para contorná-lo.
- QA do mapa: nenhum bot preso; os "desvios" atrás dos castelos são o corredor
  novo (só se chega por fora, de propósito).
- `maquina_<classe>.scn` para guerreiro (forja), arqueiro (esmeril), kitsune
  (santuário), ronin_oni (fornalha oni), arqueiro_yumi (ateliê do arco) e
  construtor (serraria), com os mesmos nós da `maquina_chapeu`; emblemas do
  elenco 2.4. `tools/planta_mapa.gd` + `.py`: planta numerada do mapa.
- Tema Dia: verdes mais escuros e menos saturados (grama, folhas, capim, bambu;
  saturação 1,25 -> 1,0), pedido do Julio ("verde forte de joguinho bobinho").
- Testes 98/98, 5 min simulados sem erro. Julio aprovou a planta (1ª versão).
- **O que testar**: o mapa maior (trilhas da floresta pelas pontes laterais para
  flanquear, corredor atrás do castelo inimigo), as maquininhas de cada classe
  fabricando chapéu e o verde mais sóbrio do dia.

## Ciclo 2.3 (2026-10-31), Diretor de Jogabilidade: Economia do Construtor, Etapa 1
- **Madeira**: `Planta` (`scripts/items/planta.gd`): árvore e bambu em 3 estágios
  (broto, jovem, adulta), um a cada `arvore_tempo_estagio` 40 s / `bambu_tempo_estagio`
  15 s. Cada golpe de Construtor numa adulta solta 1 tora (`arvore_toras` 3,
  `bambu_varas` 2) e no fim volta a broto; jovem rende 1. Só a linha do Construtor
  (`velocidade_obra > 0`) corta.
- **Tora** (`tora.gd`): o Construtor pega encostando, anda a `tora_vel_mult` 0,7 e não
  ataca (dash vale). Apanhou, a tora cai e qualquer Construtor pega, até o inimigo.
  Entregue na **pilha do castelo** (`pilha.gd`, a `pilha_raio` m) vira estoque do time.
- **Maquininhas** (`hat_pad.gd`): 1 chapéu a cada `maquina_intervalo` 20 s até
  `maquina_estoque_max` 3, começam cheias; pegar tira 1. Usam `maquina_chapeu.scn`
  do Visual (chapéu sai do Molde e vai para a prateleira, emblema na frente).
- **Oficinas** custam `oficina_custo_madeira` 6 e a obra caiu para 10 s: quem está na
  obra puxa 1 madeira do estoque a cada 1,5 s; a obra não passa da madeira entregue.
  Contador do Visual em cima ("faltam N", barra; grande para quem é Construtor,
  pisca "falta madeira" sem estoque).
- **Bot Construtor**: tora nos braços -> pilha; obra com estoque suficiente -> constrói;
  tora solta perto -> pega; senão corta a adulta mais perto (bosque seguro primeiro,
  sem dois aliados na mesma). Inimigo a 5 m: briga. No máximo `bots_construtores_max` 2.
- **Alma de abate** (ideia do Julio): cada inimigo eliminado manda `alma_por_abate`
  0,15 de espírito voando para a máscara do time de quem matou (~7 abates = 1
  espírito). Quem só briga também deixa a máscara mais pesada para o inimigo.
- **Bot preso perto do objetivo**: parado < 0,3 m em 3 s duas vezes seguidas dá a volta
  (antes só valia longe do objetivo; o QA achou bots presos nos pátios do Rio).
- **QA do mapa** (`tests/qa_mapa.gd`, flag `--qa-mapa=DIR`): passagem (grade de 1 m,
  inalcançável e desvio > 2,5x), objetos escondidos da câmera (raios), bots presos
  (3 min). Gera `qa_mapa.txt` (≤ 30 linhas) e, com tela, `qa_mapa.jpg`. No CI roda
  como aviso. Hoje: 0 a 1 aviso (bot parado 2-3 amostras, briga).
- Esquemas novos: `GameConfig` (grupo "Economia do Construtor", maquininha, oficina,
  `alma_por_abate`), `MapLayout` (`tree_spots`, `pilha_spot` locais; `bamboo_spots` no
  mundo), `ThemeConfig` (`arvore_estagios`, `bambu_estagios`, `maquina_model`,
  `pilha_model`, `tora_model`). `Arena.registrar_contornos(no)` para modelos fora da Arena.
- Elenco novo decidido no quiz: `docs/elenco-ciclo-2.4.md` (entra no 2.4).
- Testes de regra 98/98 (novos: estágio, rendimento, tora, entrega, máquina, obra,
  alma); 5 min simulados sem erro, 0 a 5 pontos por partida (igual a antes).
- **O que testar**:
  1. Jogue de **Armadilheiro** (chapéu laranja): corte a castanheira fora da muralha
     lateral (perto do portão), leve a tora à pilha ao lado do portão e veja o número subir.
  2. Fique na obra de uma casinha: o "faltam N" deve cair 1 a cada 1,5 s enquanto houver
     madeira; sem madeira ele pisca.
  3. Pegue chapéus da mesma máquina até acabar (3): ela fabrica outro a cada 20 s.
  4. Apanhe carregando a tora: ela cai no chão.
  5. Mate inimigos e olhe a sua máscara: uma alminha voa até ela.
  6. Mapa maior do Visual (entrada acima): flanqueie pelas trilhas de floresta
     (|z| = 30). Com ele, 1 a 3 pontos por 5 min nos bots (antes 0 a 5).

## Organização (2026-10-31), estagiário de economia: checkup de tokens
- Pedido do Julio: checkup de onde o projeto gasta mais e aplicar as mudanças.
- `docs/economia-de-tokens.md`: modelo de custo (N·C₀ + Δ·N²/2), tabela com
  9 gastos medidos no histórico das threads e regras 11-17 (thread por tarefa,
  quiz econômico, resposta curta, lotes 3D com uma prancha, coordenador curto).
- `CLAUDE.md`: resumo das regras novas na seção de economia.
- **O que testar**: nada no jogo (só documentos).

## Ciclo 2.3 (2026-10-31), Diretor Visual: modelos da Economia do Construtor (branch)
- `tools/gerar_economia.gd` (rodar depois de `gerar_cenario_ninja.gd`): nos 4 temas,
  `arvore_e1..3` (castanheira de corte; adulta com cunha no tronco e ofuda aceso
  = "pronta"), `bambu_e1..3`, `tora` (centro na origem, eixo x), `pilha_toras`
  (nós `Nivel_1..4`, 3 toras cada, e `Contador`), `maquina_chapeu` (`Prensa`,
  `Gira_engrenagem`, `Molde`, `Brilho`, `Vapor`, `Enfeite`, `Estoque_1..4`,
  animação `fabricar` de 2 s) e `emblema_{guerreiro,arqueiro,monge,construtor}`.
  Liga os modelos nos temas sozinho quando o `ThemeConfig` ganhar os campos do contrato.
- `scripts/ui/contador_madeira.gd` (`ContadorMadeira.mostrar(faltam, total, grande,
  sem_estoque)`) + `assets/ui/icone_tora.png`: contador sobre a obra, por cima do telhado.
- Rio das Lanternas: pontos do contrato (bosque local (9,5, 21) e (8, 25), pilha
  local (9, 7,4), 6 bambus nas margens) gravados quando `MapLayout` tiver os campos;
  saiu o bambuzal de enfeite em (±40,5, 24), que confundiria com o de corte.
- Prancha: `tools/prancha_economia.gd` + `prancha_economia_mapa.gd` + `montar_economia.py`.
- Testes de regra 68/68 e 5 min simulados sem erro de script.
- **O que testar**: nada ainda (fora da main; o jogo usa os modelos quando a
  Jogabilidade ligar as regras).

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
