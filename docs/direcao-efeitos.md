# Direção dos efeitos: lançamentos, impactos e animações "uau"

**Decidido pelo Julio em 2026-10-31** no Quiz dos Efeitos
(https://claude.ai/artifact/W1rM2CeAN8SkDEUQ6pCv4u), inspirado no reel "Feel the
Frost" do canal Pragmatic Game Developer: **mesmo dano, outra sensação**.
Escrito pelo estagiário de ideias.

## 1. A receita: seis camadas

Cada lançamento ganha **cor, forma, rastro, impacto, reação do alvo e som**
(B1 = ABCDE). O brilho de carga na mão ficou de fora.

O porquê: o olho lê movimento por fluxo óptico. O rastro desenha a trajetória
recente, então dá para estimar direção e velocidade sem seguir o projétil.
Forma e cor criam redundância de pistas (você reconhece o poder sem ler nada).
Impacto e reação fecham a causalidade "A acertou B".

Tom: **sombrio e "uau"**, dentro da direção do Ciclo 2.2 (conto sombrio
pintado). Antes de desenhar, leia o roteiro do trailer
(`docs/trailer/roteiro-cinema-v2.md` e `roteiro.md` no branch
`claude/project-thread-y822xi`), que
descreve a sensação que o Julio quer.

## 2. Orçamento por frequência (pedido do Julio)

Ataque rápido e frequente leva efeito **leve**. O efeito máximo fica para o
poder raro. O custo na tela é proporcional a Σ (disparos por segundo × partículas
por disparo), então quem atira 3 vezes por segundo não pode custar o mesmo que um
poder de Chi a cada 20 s.

| Nível | O quê | Orçamento por disparo (indicativo) |
|---|---|---|
| 1 leve | ataque básico (shuriken, flecha, orbes, bomba comum) | forma + rastro curto (≤ 8 partículas vivas), impacto pequeno |
| 2 médio | habilidade Q | rastro completo, impacto próprio, reação |
| 3 máximo | poder de Chi (E) | tudo, com marca no chão e som cheio |

Quantidade total na tela: **média** (B10 = B). Se um detalhe quase não se vê,
corte (ele pediu "ache um bom meio termo"). O rastro desliga na qualidade
Mínima. O orçamento de ~10% de FPS de `docs/principios.md` continua valendo,
então meça com `--perf` antes e depois.

## 3. Escolhas por projétil

| Projétil | Classe | Escolha |
|---|---|---|
| Shuriken | Ninja de Shuriken | **B**: lascas de metal voando no caminho, estilhaço no acerto (leve) |
| Flecha | Arqueiro Yumi | **A**: flecha de verdade, fita de vento fina, poeira e marca no chão (leve) |
| Bomba | Bombardeiro | **A**: faíscas do pavio e fumacinha de sprite no voo |
| Fogo-raposa | Kitsune | **B**: três fogos-fátuos (kitsunebi) girando juntos |
| Luz | Kitsune da Luz | **A**: lança dourada que deixa brilhos piscando; cruz de luz no acerto |
| Sombra | Kitsune Sombria | **B**: orbe do vazio com olho e fita de sombra; implode no acerto |
| Minas e o resto | todos | todos no mesmo lote (B12 = A) |

- **Impactos** (B8): os cinco tipos (faíscas + anel, estilhaço, marca no chão
  que some em ~2 s, explosão com fumaça, implosão), cada um onde combina.
- **Reação do alvo** (B9 = B): a marca do elemento no corpo por ~1 s (brasa,
  tinta escorrendo, brilho), **só visual**, sem mudar o dano.
- **Som** (B11): ao lançar, ao acertar e com volume pela distância. Sem
  zumbido contínuo. Sons gerados por código (`tools/gerar_sons.py`).

## 4. Outras aplicações (C1 = A, E, F)

- **Golpe corpo a corpo**: arco do corte com rastro e faísca no acerto.
- **Subir nível da oficina**: anéis dourados subindo e o letreiro.
- **Captura da máscara**: coluna de luz no castelo.

## 5. Porrada e números (A2 = B, D)

- Ainda falta peso, mas **não** é mais tremor: deve vir das camadas acima
  (impacto, reação e som).
- Números de dano **um pouco menores**, e cada jogador vê só o dano que deu
  e o que levou.

## 6. Como entregar (C3 = A e o comentário do C1)

- O Diretor Visual cria sozinho o que achar necessário neste lote. Antes de
  pedir o pitaco, ele mesmo avalia (prints e partidas) e refaz o que ficou
  ruim.
- A entrega é um **GIF curto por poder, antes e depois lado a lado**, e uma
  versão estável na main (testes de regra + 5 min simulados), com "O que
  testar".
- **Regra nova, daqui para frente**: toda mudança de personagem, casinha ou
  cenário vem com animações novas para ela. O pitaco do Julio entra antes de
  produzir, por prancha ou GIF.

## 7. O que ainda depende do quiz de alinhamento

Pátio circular e castelo novo, ritmo da partida ("cheio demais na entrada"),
página de tutorial (classes, evolução, Construtor), identidade única das
letras e da interface, e se as variações do Construtor (Bombardeiro,
Armadilheiro) cortam árvores.

## 8. Ciclo 2.20: energia desenhada (kit `Magia`)

**Decidido pelo Julio em 2026-11-10** (quiz "Magia de verdade"): elemento com
contorno de tinta, pico forte de ~0,3 s que limpa rápido, tudo refeito (E/R, Q,
básico, impactos, auras), marca no chão, clarão, câmera e som. Dois freios dele:
**fumaça só leve** e **golpe básico discreto**.

Como se monta um efeito agora (`scripts/fx/magia.gd`):

- Nada de malha primitiva com cor chapada. Toda forma usa `Magia.mat(paleta)`
  (shader `magia_energia`): uma máscara `m` (0..1) diz onde há energia e um
  ruído rolando decide a borda. `a = m + (ruído-0,5)·forca - corroi` é a
  existência (a < 0 some; faixa fina acima de 0 vira o filete de tinta); a cor
  sai em degraus (borda › meio › núcleo em 0,27 / 0,42 / 0,62). Animar `corroi`
  de 0 a 1 faz a peça se RASGAR em vez de só ficar transparente.
- Três atos: carga (selo se escreve + faíscas entrando, ~0,2 s), estouro (peça
  principal + onda + clarão, ~0,3 s), resto (brasas e marca no chão, 1-4 s).
- Mistura normal, não aditiva: aditivo estoura para branco no chão claro.
- Orçamento: 1 malha por peça, material por efeito (uniforme de instância
  estoura o buffer no Compatibility), luz só na Alta, enfeite desliga na Baixa.
- Conferir sempre na bancada (`tools/bancada_magia.gd`) e na vitrine
  (`tools/vitrine.sh`) antes de subir.

## 9. Ciclo 2.24: assinatura por personagem (kit `Assinatura`)

Pedido do Julio (2026-11-12): "muitos símbolos iguais nos poderes; cada personagem
com um efeito de acordo com a personalidade, bem completo e complexo". Quiz: selo
próprio "e também não selo" (1A), abertura do R própria, "inove!" (2A), selo +
abertura + partículas + Q (3ABCD), tudo maior e "o R mais ainda" (4C).

**O que repetia**: todo E escrevia o mesmo círculo com estrela de N pontas e todo
R abria com o mesmo pilar e selo dourados. **Regra nova**: três coisas mudam de um
personagem para outro, e são as que se leem da câmera da partida (28 m):

1. **Silhueta**: nem todo selo é um círculo. Planta quadrada (Construtor), rosto
   oval (Mujina), corda grossa (Sumotori), cata-vento de penas (Tengu), pata
   (Kitsune), ensō aberto (Samurai). Só o Onmyoji tem estrela de 5 pontas (Seimei).
2. **Verbo**: como o desenho aparece. `pincel` (dá a volta), `carimbo` (bate e
   assenta), `ondas` (do meio para fora), `morde` (de fora para dentro), `queima`,
   `espiral`, `nevoa`, `risco` (da esquerda para a direita). A frente da escrita
   acende (ponta do pincel, faísca do pavio).
3. **Matéria**: a partícula tem forma (pena, folha de bordo, sal, talismã, nota,
   conta, gota, caco, elo, estrepe...) e jeito de se mexer (`espirra`, `cai`
   tombando, `sobe`).

Mais: o **brilho em volta do selo é a cor do time** (amigo ou inimigo na briga), o
R abre com uma **figura em pé** (de frente para a câmera) e o nome do golpe ganha
o **hanko** (carimbo vermelho com o emblema).

| Personagem | Selo (silhueta) | Verbo | Peça | Abertura do R |
|---|---|---|---|---|
| Samurai | ensō aberto + katanas cruzadas | pincel | lascas de aço | risco de tinta atravessa a tela, fumaça |
| Ronin Oni | chifres, presas, chão rachando | queima | cacos em brasa | máscara oni queima atrás dele e ruge |
| Sohei | rosário de contas + sino | ondas | contas de luz | sino gigante cai e bate, 3 anéis de som |
| Ninja de Shuriken | shuriken com furo + fumaça | carimbo, girando | shuriken | fumaça e 3 sombras dele |
| Arqueiro Yumi | alvo com olho e miras | morde | lascas | olho de luz se abre no céu, riscos de flecha |
| Kusarigama | corrente de elos + foice | pincel, girando | elos | corrente em redemoinho, espiral de faíscas |
| Kitsune | pata + fogos-fátuos | carimbo | chamas rosa | fogos-fátuos brotam em roda, a raposa pisca |
| Kitsune da Luz | lótus em anel liso | ondas | pétalas | halo dourado desce, chuva de pétalas |
| Kitsune Sombria | coroa em ziguezague + olhos | morde | chamas roxas | olhos se abrem no chão, caudas de sombra |
| Construtor | planta quadrada (esquadro, compasso) | risco | lascas e pregos | andaimes de luz sobem dos lados |
| Armadilheiro | mandíbula com dentes | morde | estrepes | a mandíbula fecha e os dentes sobem |
| Bombardeiro | pavio em espiral + bomba | morde (queima até o meio) | estrelas | pavio queima e estoura |
| Sumotori | corda shimenawa + shide + sal | carimbo | grãos de sal | nuvem de sal, papéis shide caindo |
| Kappa | ondas quebradas + prato | ondas, pulsando | gotas | gêiser do prato e chuva |
| Yamabushi | folhas de bordo em espiral | espiral, girando | folhas | o leque varre, redemoinho de folhas |
| Karasu Tengu | cata-vento de penas | espiral, girando | penas | asas se abrem, penas explodem |
| Mujina | rosto oval rachando | névoa | cacos de máscara | rosto liso aparece, racha, cacos caem |
| Onmyoji | Seimei (5 pontas) + talismãs | pincel | talismãs | talismãs em leque viram grous |
| Tennin | fitas em espiral + nuvens | espiral, girando | pétalas | véu de fitas, anéis subindo |
| Komusō | cesto trançado + ondas de som | ondas, pulsando | notas | nota no ar, anéis de som que param |
| Ochimusha (2.27) | ensō partido com 4 flechas cravadas | racha | cinza azul | samurai caído se ergue atrás dele, chão racha |
| Shishimai (2.27) | cabeça de leão com juba em estrela | estala | confete | cabeça do leão pula e morde, 3 batidas de taiko, chuva de confete |
| Jorogumo (2.27) | teia de 8 raios com a aranha | tece, girando | fios de seda | a aranha desce pelo fio, a teia se fecha |
| Kodama (2.27, parte 2) | anéis de tronco com broto | brota | sementes | (parte 2) |
| Kaminari-kozō (2.27, parte 2) | anel de 8 tambores + raio | troveja | faíscas | (parte 2) |

**Como é feito** (barato: cada peça é 1 chamada de desenho):
- `tools/assinaturas/desenhos.js`: os 25 selos, 21 figuras e 22 peças em SVG
  (branco = tinta, preto = corte). `node tools/assinaturas/gerar.js [--prancha x.png]`
  e depois `python3 tools/assinaturas/cinza.py` geram dois atlas de **campo de
  distância** (`assets/fx/assinaturas/selos.png` 7x7, `pecas.png` 5x5 desde o 2.27;
`Assinatura.COLS`/`PCOLS` acompanham). Do campo de
  distância o shader tira traço, filete de tinta e brilho, nítidos de 1 a 14 m.
- `assets/shaders/assinatura_selo.gdshader` (selo, figura em pé, hanko) e
  `assinatura_peca.gdshader` (partícula que tomba no ar).
- `scripts/fx/assinatura.gd`: tabela `DADOS` (paleta, verbo, peça, giro) e as
  coreografias `abrir_e`, `abrir_r`, `toque_q`. Personagem novo = um desenho no
  `desenhos.js` (no fim da lista, para não mexer nos índices), uma linha em
  `SELOS`/`DADOS` e, se quiser, um ramo em `abrir_r`.
- Tamanho: selo do E 15% maior que antes (até 6,4 m de raio), selo do R com 7 m.
- Qualidade Mínima: as peças desligam (`Magia.enfeite()`); selo e figura ficam.
- Conferir: `VITRINE_LONGE=1 tools/vitrine.sh SAIDA [classes]` usa a câmera da
  partida (sem a variável, câmera de perto).
