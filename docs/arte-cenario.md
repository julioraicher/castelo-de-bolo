# Arte do cenário

Diário de decisões da frente de **cenário** (mapa, castelos, construções,
ambientação). Personagens e jogabilidade têm conversas próprias.
Fonte da verdade: se uma decisão mudar, risque a antiga e escreva a nova.

## Como iteramos

1. Claude propõe direções e escreve prompts para o Gemini.
2. Julio gera imagens, escolhe e manda (pode ser só "gostei da 2, sem as nuvens").
3. Claude traduz a imagem em **paleta + kit de peças + regras de composição**,
   implementa como dados (`config/temas/*.tres`, `config/mapas/*.tres`) e manda print.
4. Decisão registrada aqui.

A imagem do Gemini é **referência de clima e silhueta**, não modelo 3D: o que
vale extrair dela é paleta (5-7 cores), formas grandes e o que fica no fundo.

## Orçamento de desempenho (Intel UHD integrada, WebGL)

Hoje, qualidade Média: ~230 draw calls, ~170k triângulos, dos quais ~190
chamadas são personagens. Sobra pouco para o cenário. Regras:

| Regra | Por quê |
|---|---|
| Cada *tipo* de peça repetida vira 1 MultiMesh (1 draw call para N cópias) | custo de CPU/driver é por chamada, não por objeto |
| Cenário inteiro ≤ ~40 draw calls e ≤ ~60k triângulos | GPU integrada é limitada por preenchimento e vértices |
| Cor por vértice ou 1 textura-atlas compartilhada, sem texturas grandes | banda de memória é compartilhada com a CPU |
| Nada de transparência em área grande (água, vidro, folhas alfa) | *overdraw*: cada pixel pintado várias vezes |
| Sombra só do sol, só em peças grandes; decoração sem sombra | o mapa de sombra redesenha a cena inteira |
| Clima via céu/neblina/cor, não via partículas | neblina é praticamente grátis no shader |

## Direções propostas (2026-10-29)

Ver opções e prompts abaixo. Decisão: _pendente_.

### A. Confeitaria (castelo de bolo literal) — recomendada
Castelos de bolo em camadas com cobertura escorrendo, torres de cupcake/vela,
muralhas de biscoito wafer, chão de grama com granulado, árvores de pirulito
e algodão-doce, rio de chocolate. Combina com o nome e é **o mais barato**:
quase tudo sai de cilindros, cones e esferas low-poly com cor por vértice,
geráveis por código (sem baixar pack).

Prompt Gemini:
> Isometric 3/4 top-down concept art of a small game battlefield, two opposing
> castles made of layered cakes (one blueberry blue, one strawberry red) facing
> each other across a grassy valley. Castle walls are wafer cookies, towers are
> giant cupcakes and birthday candles, frosting dripping from battlements.
> Lollipop trees, cotton candy bushes, a small chocolate river with a cookie
> bridge in the middle. Low-poly 3D style, flat shading, soft pastel colors,
> clean readable shapes, no characters, no text. Camera angle like a strategy
> game seen from 45 degrees above.

### B. Medieval de brinquedo (polir o atual)
Mantém o KayKit e dá vida: rio com ponte no meio, vila neutra disputável,
estrada de pedra, cercas, plantações. Risco: continua parecendo "pack de asset".

Prompt Gemini:
> Isometric 3/4 top-down concept art of a cozy medieval valley battlefield, two
> small stone castles (blue banners vs red banners) at opposite ends, a river
> with a wooden bridge in the center, fields, fences and a tiny neutral village
> between them. Low-poly 3D toy style, flat shading, bright saturated colors,
> clean shapes, no characters, no text.

### C. Sinistro de verdade (Halloween fofo)
Expande o tema noturno: lápides, abóboras-lanterna, árvores secas, cerca torta,
castelos de pedra escura com janelas acesas em emissivo (brilho barato).

Prompt Gemini:
> Isometric 3/4 top-down concept art of a spooky but cute night battlefield,
> two dark stone castles with glowing windows (one blue-lit, one red-lit),
> twisted dead trees, jack-o-lantern pumpkins, crooked fences, tombstones and
> light purple fog in a valley between them. Low-poly 3D style, flat shading,
> limited palette of deep purple, teal and orange, no characters, no text.

### D. Diorama de mesa (tilt-shift)
O mapa é uma maquete sobre uma mesa: borda de madeira, peças de papelão e
feltro, fundo desfocado. Charme alto, mas o desfoque (DOF) custa caro na
GPU integrada; só vale com DOF desligado na qualidade Baixa.

Prompt Gemini:
> Tilt-shift photo style concept of a tabletop diorama battlefield: two small
> handmade castles of cardboard and felt (blue and red), cotton-ball trees,
> paper river, sitting on a wooden table, seen from 45 degrees above, shallow
> depth of field, warm lamp light, no characters, no text.

### Dica para os prompts
- Peça sempre "isometric 3/4 top-down, 45 degrees": é o ângulo da câmera do jogo.
  Imagem de frente ou de baixo não serve de referência.
- "no characters, no text" evita bonecos e letras que confundem a leitura.
- Depois de escolher, peça ao Gemini um **asset sheet**: "same style, asset sheet
  of individual props on white background: castle keep, tower, wall segment,
  gate, tree, rock, bridge". Isso vira a lista de peças a modelar.
