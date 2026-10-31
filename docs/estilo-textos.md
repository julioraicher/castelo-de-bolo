# Estilo dos textos (fontes, tamanhos, tom)

Fonte única de verdade: `scripts/ui/estilo.gd`. Ciclo 2.4n.

## Fontes (todas OFL, em assets/fonts)

| Constante | Fonte | Para quê |
|---|---|---|
| `Estilo.TITULO` | Shojumaru (pincel) | só títulos curtos: nome do jogo, Pausado, Vitória, nome da classe, nome do golpe. **Nunca frase.** O zero dela parece redemoinho: números usam NUMERO |
| `Estilo.FORTE` | Barlow Condensed Bold | botões, rótulos, dicas, status |
| `Estilo.NUMERO` | Barlow Condensed ExtraBold | placar, vida, contadores, números de dano, avisos grandes |
| `Estilo.CORPO` | Barlow Semi Condensed Medium | texto corrido (tutorial, controles, configurações) |
| `Estilo.espacada(fonte, px)` | qualquer uma, com letras afastadas | subtítulo e rótulo em CAIXA ALTA ("SUA MÁSCARA") |

## Tamanhos (tela-base 1600x900)

`T_GIGANTE` 110 · `T_TITULO` 56 · `T_GRANDE` 28 · `T_MEDIO` 22 · `T_TEXTO` 20 ·
`T_PEQUENO` 17 · `T_MIN` 15 (nada menor; `Estilo.ajustes` já corta abaixo disso).
Em Label3D (mundo): `font_size` 44-64 e `pixel_size` ~0,01, contorno de tinta.

## Cores

`TEXTO` papel de arroz, `TEXTO_FRACO` tinta lavada, `TINTA` contorno, `OURO` destaque
e interativo, `FANTASMA` espíritos/Chi pronto, `PERIGO` alerta, `CIANO` aliado.
Time: `Config.team_color(t)`. Nada de branco-azulado neon.

## Peças prontas

- `Estilo.rotulo(texto, tam, cor, fonte)` · `Estilo.titulo(...)` (pincel) ·
  `Estilo.aviso(...)` (aviso grande, caixa alta) · `Estilo.tecla("E")` ·
  `Estilo.ornamento(largura)` (filete dourado sob títulos) · `Estilo.painel(...)`.
- HUD: `hud.show_big(texto, cor, s)` = aviso no meio (vira CAIXA ALTA sozinho; até
  ~30 letras por linha, no máximo 2 linhas). `hud.set_hint("Frase [E] frase")` =
  dica embaixo; o primeiro `[X]` vira tecla desenhada.

## Tom da escrita

- Imperativo curto: "Leve a tora ao depósito", não "Levando tora...".
- Status do jogador e avisos: CAIXA ALTA. Texto corrido: frase normal com ponto.
- Português com acento, "você", sem gíria de programador ("spawn", "buff").
- Nome de classe/poder como em `config/classes/*.tres` (`display_name`, `power_name`).
- Tecla sempre como tecla desenhada ou entre colchetes na dica, nunca "(E)" solto.
