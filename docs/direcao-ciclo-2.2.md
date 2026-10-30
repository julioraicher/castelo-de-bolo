# Direção do Ciclo 2.2: um jogo mais "completo"

Rascunho para aprovação do Julio (2026-10-30). Escrito pelo estagiário de ideias
a partir do quiz de 5 perguntas. Nada aqui é feito antes do "aprovado".

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

## 4. Como atacar cada problema (o porquê técnico)

A ideia central é separar em **duas camadas**, para não refazer o mapa peça
por peça:

**Camada global (vale para tudo de uma vez, quase de graça):**
- **Shader de pintura**: em vez de cor chapada, o material do cenário mistura
  a cor da peça com um ruído de pincel, escurece cantos e frestas (oclusão
  pintada) e clareia as bordas viradas para o sol. É matemática no pixel, sem
  mais polígonos: resolve boa parte do "liso" em todas as peças existentes.
- **Vento no shader**: grama, folhas, bandeiras e varais balançam com um seno
  deslocado pela posição (custo zero de CPU). Ataca o "parado".
- **Espalhador de enfeite**: tufos de grama, flores, pedrinhas, folhas,
  manchas de terra nos caminhos, por MultiMesh (1 draw call por tipo).
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
3. **Comparativo de animação**: o mesmo golpe nas 3 versões, numa prancha.

Uma imagem por rodada. Tudo em branch; entra na main só com o "aprovado".

## 6. Quem faz o quê (proposta)

- **Diretor Visual**: shader de pintura, vento, espalhador, casa + lanterna
  do piloto, proporção dos bonecos, prancha de animação.
- **Diretor de Jogabilidade**: animação exagerada por código em `unit.gd`
  (antecipação, estica e encolhe, tremor), medir FPS antes/depois e cuidar do
  orçamento.

## 7. Fora deste ciclo

Cabeção chibi, sangue de desenho, mudar câmera, mapas novos, mudar a paleta.

## 8. Pergunta aberta

Na pergunta 5 o Julio marcou também **"mudança grande, até mexer no tema
ninja"**. Leitura adotada: o tema ninja **fica**, e o piloto decide se algo
dele precisa mudar. Se a intenção era trocar o tema agora, isso muda o plano.
