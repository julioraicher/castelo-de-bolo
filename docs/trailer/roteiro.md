# Trailer cinematográfico: roteiro v1

Thread "Estagiário produtor de vídeo". Cutscenes, não gameplay. Tom do Ciclo 2.2
(`docs/direcao-ciclo-2.2.md`): conto sombrio pintado, crepúsculo, neblina baixa,
lanternas, corvos, poder aceso no corpo dos ninjas.

**Título provisório: "A Máscara Tem Fome"** · ~55 s · 8 planos.

## Como cada plano é feito

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
| 1, 3, 8 | castelo e fundo com shader de pintura/vento/enfeite; Máscara Oni (não muda neste ciclo) | Diretor Visual, rodada 2 |
| 2, 7 | tema Crepúsculo (`config/temas/crepusculo.tres`) + casa piloto (`tools/gerar_piloto.gd`, branch claude/project-thread-n9z79h); falta o Julio escolher a luz padrão | Diretor Visual, rodadas 1-2 |
| 4, 5, 6, 7 | ninjas 3,5 cabeças + marcas de poder acesas | Diretor Visual, rodada 3 |

Render só depois da arte firme, para não refazer.

## Em aberto (Julio)

- Nome do jogo no título final (hoje "Castelo de Bolo" é provisório).
- Texto na tela (como acima) ou narração de voz grave.
