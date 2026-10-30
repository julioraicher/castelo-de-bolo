# Direção do Ciclo 2.2: um jogo mais "completo"

**Aprovado pelo Julio em 2026-10-30**, com um acréscimo: pegada mais sombria
e ninjas com poder visível no corpo (seção 3, itens 5 e 6). Escrito pelo
estagiário de ideias a partir do quiz.

## 1. O problema, em palavras

O Julio acha o jogo **quadrado, liso e vazio**, e o que mais incomoda é:

| Palavra | O que é tecnicamente | Por que acontece hoje |
|---|---|---|
| Quadrado | Silhueta previsível, quinas retas | Peças montadas com primitivas (caixa, cilindro) |
| Liso | Falta de detalhe fino (alta frequência) | Cada superfície tem uma cor só (cor por vértice) |
| Vazio | Pouca densidade entre objetos grandes | Chão limpo, pouco enfeite, nada se mexe |
| Bonecos duros | Animação sem exagero | Clipes do KayKit tocados "como vieram" |

Cor e luz chapadas (F) e câmera (G) **não** foram marcadas: a paleta do
Festival ao Sol e a câmera atual ficam.

## 2. O que pegar do Fat Princess de PS3

Sim: **textura pintada à mão**, **animação exagerada**, **muito enfeite no
chão**, **luz quente e suave com brilho**.
Não (por enquanto): cabeção chibi e sangue de desenho.

## 3. Decisões

1. **Proporção: meio-termo.** Cabeça maior que a atual, mas longe do chibi.
   Alvo: altura ≈ 3,5 cabeças (hoje ≈ 4,5; Fat Princess ≈ 2,5). Mãos e pés um
   pouco maiores, para o golpe ler de longe.
2. **Animação: comparativo primeiro, com tendência a refazer.** Uma prancha
   com o mesmo golpe em 3 versões (atual / exagerada por código / refeita em
   estilo desenho). O Julio escolhe; o mais provável é refazer.
3. **Escopo: cenário e personagens, com piloto primeiro.** E o Julio aceita
   mudança grande se o piloto pedir (ver pergunta aberta no fim).
4. **Desempenho: pode perder um pouco.** Meta: no máximo ~10% de FPS a menos
   no PC dele na qualidade Média. O visual mais cheio pode ser só na Alta.
5. **Tom: conto sombrio pintado.** O jeito do Fat Princess (pintado, cheio,
   exagerado), mas com clima mais pesado: fim de tarde puxando para o
   crepúsculo, sombras longas e frias (roxo/azul), céu alaranjado-vermelho,
   neblina baixa, lanternas acesas, corvos, fumaça. Mantém a leitura da cor
   do time. O Festival ao Sol continua como tema opcional; o piloto mostra a
   mesma casa nas duas luzes e o Julio escolhe o padrão.
6. **Ninjas com poder junto.** O poder aparece no corpo, não só no golpe:
   marcas/selos na pele e na roupa que acendem conforme o medidor enche,
   aura ou fumaça escura quando o poder está pronto, olhos que brilham ao
   usar, rastro de energia nos golpes fortes e no dash. Cor do poder = cor da
   classe (fogo-raposa, tinta, talismã etc.), com um toque da cor do time.

## 4. Como atacar cada problema (o porquê técnico)

A ideia central é separar em **duas camadas**, para não refazer o mapa peça
por peça:

**Camada global (vale para tudo de uma vez, quase de graça):**
- **Shader de pintura**: em vez de cor chapada, o material do cenário mistura
  a cor da peça com um ruído de pincel, escurece cantos e frestas (oclusão
  pintada) e clareia as bordas viradas para o sol. É matemática no pixel, sem
  mais polígonos: resolve boa parte do "liso" em todas as peças existentes.
  **Cuidado de Nyquist**: um boneco ocupa ~60-100 px e uma casa ~150-250 px
  na tela; detalhe menor que ~2 px vira chuvisco (aliasing) ao mover a
  câmera. Então a "pintura" é de **baixa frequência**: pinceladas grandes,
  gradiente de cima para baixo, cantos escuros, não veio fino de madeira.
- **Vento no shader**: grama, folhas, bandeiras e varais balançam com um seno
  deslocado pela posição (custo zero de CPU). Ataca o "parado".
- **Espalhador de enfeite**: tufos de grama, flores, pedrinhas, folhas,
  manchas de terra nos caminhos, por MultiMesh (1 draw call por tipo), sem
  sombra e sem transparência (recorte opaco), dentro do orçamento de
  `cenario/arte-cenario.md` (cenário ≤ ~40 draw calls; o espalhador leva ≤ 6).
  Ataca o "vazio" entre as coisas.
- **Luz**: sol mais quente, sombra mais azulada, brilho leve (o glow já existe
  no tema de dia; só a dose muda).

**Camada por peça (caro, só no piloto e depois peça a peça):**
- **Silhueta**: chanfrar quinas, telhado que cede no meio, paredes
  levemente tortas, proporções gordas (telhado grande, porta baixa).
- **Grupinhos de vida**: cada casa ganha seu "kit" de entorno (barril, lenha,
  vaso, roupa no varal, lanterna).

**Personagens:**
- Proporção nova por escala de ossos (`escala_ossos.gd` já faz isso).
- Animação exagerada por código, sem refazer clipes: antecipação antes do
  golpe, "estica e encolhe" no impacto e no pouso do dash, quique ao andar,
  tremor de quem apanha. É a parte mais barata e que mais muda a sensação.
- Shader de pintura nos bonecos também (roupa com dobra pintada).

## 5. Piloto (depois da aprovação)

1. **Peça-base no nível máximo**: a **casa comum da vila** (a mais repetida
   no mapa) + **um enfeite** (lanterna de pedra). Silhueta nova, shader de
   pintura, kit de entorno, vento. Prancha em 3 ângulos + print no jogo.
2. **Resto do mapa em versão barata**: só a camada global aplicada em todas
   as peças atuais (shader + vento + espalhador), sem remodelar. Um print do
   mapa inteiro. Mostra quanto o "de graça" já entrega e quais peças ainda
   pedem remodelagem.
3. **Comparativo de animação + poder no corpo**: o mesmo golpe nas 3 versões,
   com o boneco em proporção 3,5 cabeças e as marcas acesas, numa prancha.

A prancha 1 do piloto mostra a casa + lanterna **lado a lado em duas luzes**
(Festival ao Sol × Crepúsculo sombrio).

Uma imagem por rodada. Tudo em branch; entra na main só com o "aprovado".

## 6. Quem faz o quê (proposta)

- **Diretor Visual**: shader de pintura, vento, espalhador, tema Crepúsculo,
  casa + lanterna do piloto, proporção dos bonecos, marcas de poder no corpo,
  prancha de animação.
- **Diretor de Jogabilidade**: animação exagerada por código em `unit.gd`
  (antecipação, estica e encolhe, tremor), medir FPS antes/depois e cuidar do
  orçamento.

## 7. Fora deste ciclo

Cabeção chibi, sangue de desenho, mudar câmera, mapas novos, mudar a paleta.

## 8. Tema

O tema ninja **fica** ("ainda tem muito a melhorar"). Se um dia trocar, a
ideia do Julio é outro mundo (anotado em `docs/ideias.md`, C).

## 9. Instruções para os diretores (Ciclo 2.2)

Regras gerais: tudo em branch próprio; uma imagem por rodada; nada entra na
main sem o "aprovado" do Julio; cada entrega na main com "O que testar" no
CHANGELOG; orçamento da seção 3.4 medido com `--perf` antes e depois.

### Diretor Visual — ordem de trabalho
1. **Rodada 1 (prancha do piloto, cenário):** casa comum da vila remodelada
   (chanfros, telhado cedendo, paredes tortas, porta baixa, kit de entorno:
   barril, lenha, vaso, varal) + lanterna de pedra. Material novo
   `assets/shaders/pintura.gdshader` (ruído de pincel em espaço de mundo,
   oclusão pintada por cor de vértice ou curvatura, borda clara pro sol,
   vento por seno no vértice com máscara de altura). Prancha: a peça em 3
   ângulos, nas duas luzes (Festival ao Sol × tema novo `crepusculo.tres`).
2. **Rodada 2 (mapa barato):** só a camada global em todas as peças atuais
   (shader de pintura + vento + espalhador MultiMesh de grama/flores/pedras/
   folhas + tema escolhido). Um print do Rio inteiro e uma lista numerada das
   peças que ainda pedem remodelagem.
3. **Rodada 3 (personagens):** proporção 3,5 cabeças por `escala_ossos.gd`,
   shader de pintura nos bonecos, marcas de poder que acendem com o medidor
   (uniform `poder_carga` 0..1) e aura quando pronto. Prancha com 4 classes.
4. Depois do pitaco: remodelar as peças da lista, por ordem de quantas vezes
   aparecem no mapa.

### Diretor de Jogabilidade — ordem de trabalho
1. **Animação exagerada por código** em `scripts/actors/unit.gd` (sem refazer
   clipes): antecipação curta antes do golpe (sem atrasar o dano além de
   ~50 ms), estica e encolhe no impacto, no pulo e no pouso do dash (volume
   ~constante: escala y·x·z ≈ 1), quique ao andar, tremor de quem apanha.
   Tudo com intensidade num parâmetro de `ClassStats`/`game_config`.
2. Prancha de comparação do mesmo golpe (atual / exagerado / alvo "refeito")
   junto com o Diretor Visual; o Julio escolhe.
3. Ligar o medidor de poder ao visual (`poder_carga` no material do boneco) e
   o rastro de energia no dash e nos golpes fortes.
4. Medir FPS antes/depois de cada rodada do Visual e avisar se passar de 10%.
