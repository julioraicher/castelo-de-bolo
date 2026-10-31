# Trailer cinematográfico: roteiro v1

Thread "Estagiário produtor de vídeo". Cutscenes, não gameplay. Tom do Ciclo 2.2
(`docs/direcao-ciclo-2.2.md`): conto sombrio pintado, crepúsculo, neblina baixa,
lanternas, corvos, poder aceso no corpo dos ninjas.

**Título provisório: "A Máscara Tem Fome"** · ~55 s · 8 planos.

## Fluxo novo (2026-10-31, sem Gemini)

Tudo pelo conector do **Hugging Face** (conta grátis do Julio, ~5 min de GPU/dia):
1. Print do jogo no Godot (`tools/trailer/quadros.gd`) como referência de personagem e lugar.
2. **Imagem de cinema**: Qwen-Image-Edit ou FLUX.1 Kontext transformam o print em quadro
   "animação realista", épico e sombrio (o trailer pode ser bem diferente do jogo).
   FLUX.1 Krea ou Qwen-Image para cenas sem referência.
3. **Animar**: Wan 2.2 (imagem → vídeo, ou primeiro e último quadro) ou LTX-Video.
4. **Montar**: ffmpeg (cortes rápidos, títulos, música, sons).
Trailer curto (~30-40 s) com muitas cenas épicas de medo. Nada não oficial por enquanto.

## Como cada plano era feito (v1, Flow; descartado)

1. Claude renderiza no Godot um **quadro-chave** (1280×720, 16:9) com a arte do jogo.
2. O Julio cola o quadro + o prompt no **Google Flow** (Veo 3.1 Fast, imagem → vídeo,
   clipe de 8 s). Partir da nossa imagem mantém os personagens iguais entre planos.
3. Claude corta cada clipe (fica 3 a 8 s), põe títulos, música e sons com ffmpeg.
   O áudio gerado pelo Veo é descartado; a trilha é nossa (licença limpa).

## Planos

| # | Dur. | O que se vê | Texto na tela | Som |
|---|---|---|---|---|
| 1 | 5 s | Preto. Lua vermelha sai de trás das nuvens; corvos cruzam a lua. | — | sino de templo, longe |
| 2 | 7 s | A vila do Rio das Lanternas no crepúsculo, neblina sobre a água. As lanternas se apagam uma a uma, rio abaixo, em direção à câmera. | "Dizem que a máscara dorme." | vento, água, cada lanterna apaga com um "fff" |
| 3 | 7 s | Dentro do castelo: a Máscara Oni no pedestal, presa por correntes. Chamas-fantasma (hitodama) giram em volta; os olhos da máscara acendem. | "...mas ela tem fome." | tambor grave único, correntes rangendo |
| 4 | 6 s | Close: um ninja do clã azul aperta a faixa da mão. Os selos na pele acendem de baixo para cima; os olhos brilham. | — | respiração, estalo elétrico |
| 5 | 6 s | Ponte de madeira na neblina: o clã vermelho surge em silhueta, só os olhos e as marcas vermelhas visíveis. Avançam devagar. | — | passos em sincronia, taiko começa |
| 6 | 9 s | Montagem rápida (4 cortes de ~2 s, câmera lenta no impacto): lâminas se chocam com faísca; chuva de flechas no céu vermelho; raposa de fogo atravessa a tela; talismã explode em tinta. | — | taiko no máximo, um golpe por corte, silêncio de 0,3 s no último |
| 7 | 7 s | Um ninja corre pela vila com a máscara nos braços; correntes de espírito saem dela e o puxam para trás; perseguidores na neblina. | "Leve para casa." | taiko + coro grave |
| 8 | 8 s | Close na máscara: a boca se abre num sorriso. Corte seco para o preto. Título do jogo. Stinger: um corvo pousa no título e grita. | NOME DO JOGO · "Em breve" | silêncio → grito do corvo |

## Dependências da arte (Ciclo 2.2)

| Plano | Precisa de | Quem faz |
|---|---|---|
| 1, 3, 8 | castelo e fundo (main d8e23ea, **aprovado**); Máscara Oni (não muda neste ciclo) | pronto para renderizar |
| 2, 7 | Rio novo (sakuras, feira, arrozais, casa_a, lanterna_pedra), **aprovado** na main d8e23ea; luz do trailer = Crepúsculo (`--tema=1`); render na qualidade Alta (`--perf=3`) para sair o contorno de tinta | plano 2 pronto; o 7 tem ninja (espera a rodada 3) |
| 4, 5, 6, 7 | ninjas 3,5 cabeças + marcas de poder acesas: **aprovado** na main 38b9fe7 | pronto para renderizar |

Toda a arte está aprovada (main 38b9fe7). Falta só o ok do Julio no roteiro.
Ferramentas para enquadrar: `tools/prancha_patio.gd` (câmera do jogo, `--alvo=X,Z`),
`tools/prancha_mecanica.gd` (close das casas; quadros a 30 fps com
`--fixed-fps 30 ... -- DIR filme`) e `tools/prancha_poder.gd` (ninjas vazio/carregando/pronto).

Recurso da Jogabilidade (main dc459c4): `-- --autoplay --filme=PASTA` grava PNG a
cada 2 quadros com câmera baixa de lado (Samurai: golpe, dash, pulo, pancada,
morte). Útil para o plano 6 (impactos com estica e encolhe, contorno aceso com o
Chi). A morte cômica (panqueca) não combina com o tom: não usar.

## Em aberto (Julio)

- Nome do jogo no título final (hoje "Castelo de Bolo" é provisório).
- Texto na tela (como acima) ou narração de voz grave.
