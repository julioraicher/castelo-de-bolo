# Identidade do jogo

Diário de decisões da frente de **identidade e direção de arte**: nome, tema,
estilo geral, paleta, logo e artes de divulgação. O que é específico de
personagem vai para `docs/arte-personagens.md`; de cenário, para
`docs/arte-cenario.md`. Se uma decisão mudar, risque a antiga e escreva a nova.

## Como iteramos

1. Julio conversa com um Gem do Gemini que tem o **prompt-mestre** como
   instrução fixa (contexto do jogo + restrições + tipos de pedido).
   Doc para copiar: https://claude.ai/artifact/43ndxxs3f3jfxfrraadV4s
2. Traz as imagens escolhidas, o prompt usado e o que gostou/odiou.
3. Claude fecha a decisão aqui e atualiza o **bloco de estilo**, que passa a
   abrir todos os prompts (personagens, cenário, efeitos, divulgação).

## Restrições que qualquer estilo precisa respeitar

| Restrição | Valor | Consequência para a arte |
|---|---|---|
| Câmera | offset (0, 21, 19) m, FOV 42°: ~48° de inclinação, ~28 m de distância, perspectiva | conceitos pedidos em vista 3/4 de cima, não isométrica pura |
| Tamanho na tela | boneco com 60-100 px de altura | classe se lê por silhueta e massa de cor, não por detalhe |
| GPU | Intel UHD integrada, WebGL | low-poly, cor chapada, efeitos com formas grandes e emissivo, pouca transparência |
| Times | azul x vermelho tingidos no jogo | partes do time em áreas grandes e lisas |
| Key art | sem limite técnico | pode ser pintada e rica, mantendo formas e cores do jogo |

## Aberto

Nome definitivo, tema, estilo, paleta, design da princesa, nomes dos poderes, logo.

## Bloco de estilo

```
[ESTILO] (a definir)
```

## Decisões

| Data | Decisão |
|---|---|
| 2026-10-29 | Frente de identidade criada; prompt-mestre do Gemini entregue. Nome "Castelo de Bolo" segue provisório. |
