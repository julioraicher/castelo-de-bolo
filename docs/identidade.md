# Identidade do jogo

Diário de decisões da frente de **identidade e direção de arte**: nome, tema,
estilo geral, paleta, logo e artes de divulgação. O que é específico de
personagem vai para `docs/arte-personagens.md`; de cenário, para
`docs/arte-cenario.md`. Se uma decisão mudar, risque a antiga e escreva a nova.

## Como iteramos

Sem gerador de imagem por enquanto (decisão do Julio em 2026-10-29): tudo sai
daqui, em 3D, no estilo do jogo.

1. **Quiz de identidade** (respostas salvas no banco do artefato, Claude lê):
   https://claude.ai/artifact/3dyzh7VgMQiDnc1NPT2fcB — 8 mundos candidatos,
   tom, proporções, acabamento, paleta, efeitos, poderes, mudanças de regra, nome.
2. **Pranchas 3D**: Claude monta variações low-poly por código no Godot e manda
   uma imagem por rodada (opções A/B/C/D, close + câmera do jogo no tamanho real).
   Julio responde por letra ("B com o chapéu da D").
3. O escolhido vira dado (`config/`) e vai para o jogo publicado.
4. Decisão registrada aqui; personagem e cenário seguem nas frentes deles.

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
| 2026-10-29 | Frente de identidade criada. Nome "Castelo de Bolo" segue provisório. |
| 2026-10-29 | Sem Gemini: conceitos feitos aqui em 3D por código. Quiz de identidade publicado. |
