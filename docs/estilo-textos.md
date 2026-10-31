# Estilo dos textos (fontes, tamanhos, tom)

Identidade: **"Festival sombrio"** (`docs/identidade-interface.md`). Fonte única de
verdade: `scripts/ui/estilo.gd`. Nada de cor ou fonte solta em `hud.gd`, `menus.gd`,
tutorial ou letreiros 3D.

## Fontes (OFL, em assets/fonts)

| Constante | Fonte | Para quê |
|---|---|---|
| `Estilo.TITULO` = `NUMERO` = `LETREIRO` | **Lilita One** | títulos, avisos grandes, números (placar, vida, dano, contadores), botões, nomes de classe e golpe, Label3D. Sempre com contorno grosso de `TINTA` e sombra sólida para baixo (`Estilo.ajustes` já faz) |
| `Estilo.CORPO` = `FORTE` | **Nunito Black** (900) | texto: dicas, menus, tutorial, descrições. Contorno fino quando está sobre o jogo |
| `Estilo.espacada(fonte, px)` | qualquer uma, com letras afastadas | subtítulo e rótulo em CAIXA ALTA ("SUA MÁSCARA") |

Shojumaru e Barlow saíram (2.5e). `FORTE` ficou como apelido de `CORPO` para não quebrar
código antigo; em código novo use `CORPO` (texto) ou `NUMERO`/`TITULO` (destaque).

## Peças de moldura

- `Estilo.placa(fundo, borda, raio)`: laca escura `#1b1420`, borda de ouro 2 px, cantos
  10 px e sombra sólida 4 px embaixo. **A** moldura de tudo (`painel()` antigo virou ela).
- `Estilo.botao_ouro(estado)`: ouro em degradê `#f3d48a`→`#d39a2a`, contorno de tinta e
  sombra sólida (estados normal, hover, pressed, disabled). Todo `Button` sob
  `Estilo.tema()` já sai assim.
- `Estilo.letreiro(label3d, tamanho)`: Lilita + contorno de tinta grosso (`size / 4`).
- `Estilo.cor_time(t)`: azul `#6fb0ff` / vermelho `#ff6a5f` (interface; o modelo 3D
  continua com `Config.team_color`).

## HUD

Cheio, mas preso nas bordas: topo = máscaras + placar numa faixa só; canto superior
esquerdo = abates e quedas (+ FPS); canto superior direito = ajuda Esc; inferior
esquerdo = cartão do jogador; inferior direito = minimapa; embaixo no meio = dica. O
aviso grande sai logo abaixo do placar. **O centro da tela é da briga**: não ponha nada lá.

## Tamanhos (tela-base 1600x900)

`T_GIGANTE` 110 · `T_TITULO` 56 · `T_GRANDE` 28 · `T_MEDIO` 22 · `T_TEXTO` 20 ·
`T_PEQUENO` 17 · `T_MIN` 15 (nada menor; `Estilo.ajustes` já corta abaixo disso).
Em Label3D (mundo): `font_size` 44-64 e `pixel_size` ~0,01, contorno de tinta.

## Cores

Só três famílias: **ouro** (`OURO`, `OURO_CLARO`, `OURO_ESCURO`: destaque e interativo),
**cor do time** (`AZUL`, `VERMELHO`; `CIANO` e `PERIGO` são apelidos) e **laca**
(`LACA`, `LACA_CLARA`, `TINTA` no contorno). Letra: `TEXTO` (clara), `TEXTO_FRACO`,
`TEXTO_BOTAO` (escura, sobre ouro). `FANTASMA` é cor do jogo (espíritos, Chi pronto),
não de moldura.

## Peças prontas

- `Estilo.rotulo(texto, tam, cor, fonte)` · `Estilo.titulo(...)` (Lilita) ·
  `Estilo.aviso(...)` (aviso grande, caixa alta) · `Estilo.tecla("E")` ·
  `Estilo.ornamento(largura)` (filete dourado sob títulos) · `Estilo.placa(...)` ·
  `Estilo.botao_ouro(...)` · `Estilo.barra(...)`.
- HUD: `hud.show_big(texto, cor, s)` = aviso no meio (vira CAIXA ALTA sozinho; até
  ~30 letras por linha, no máximo 2 linhas). `hud.set_hint("Frase [E] frase")` =
  dica embaixo; o primeiro `[X]` vira tecla desenhada.

## Tom da escrita

- Imperativo curto: "Leve a tora ao depósito", não "Levando tora...".
- Status do jogador e avisos: CAIXA ALTA. Texto corrido: frase normal com ponto.
- Português com acento, "você", sem gíria de programador ("spawn", "buff").
- Nome de classe/poder como em `config/classes/*.tres` (`display_name`, `power_name`).
- Tecla sempre como tecla desenhada ou entre colchetes na dica, nunca "(E)" solto.
- Símbolos que as fontes têm: `· × › … —` e acentos. **Não use `→`** (nenhuma das fontes tem;
  no navegador vira quadradinho). Confira glifo novo com fontTools antes de usar.
