# Arte do cenário

Diário de decisões da frente de **cenário** (mapa, castelos, construções,
ambientação). Personagens e jogabilidade têm conversas próprias.
Fonte da verdade: se uma decisão mudar, risque a antiga e escreva a nova.

## Como iteramos (editável: se achar um jeito mais fácil, mude aqui)

1. Claude monta peças 3D por código (primitivas low-poly) e tira **uma prancha**:
   um print só com as peças lado a lado e numeradas, no ângulo da câmera do jogo.
2. Julio responde curto, por número: "3 mais alta", "5 fora", "cor do 2 mais quente".
3. Claude ajusta, grava como dados (`config/temas/*.tres`, `config/mapas/*.tres`)
   e manda o print dentro da partida.
4. Decisão registrada aqui, em uma linha.

Economia de tokens: uma prancha por rodada, feedback por número, sem textão.

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

## Decisões

- 2026-10-29: sem Gemini; referências saem de pranchas feitas aqui.
- Direção visual: Clãs de Neon com lado sombrio (ver `docs/identidade.md`).
- 2026-10-29: prancha 1 (`tools/prancha_cenario.gd`): templo-castelo, torre de vigia,
  muralha, torii, casa, lanterna de papel, lanterna de pedra, letreiro neon,
  pedestal da Máscara Oni, pinheiro. Todas juntas ~1.700 triângulos; no jogo cada
  peça vira uma malha só (1 draw call por tipo, MultiMesh nas repetidas).
  Aguardando o retorno do Julio por número.
