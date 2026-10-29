# Arte dos personagens

Frente própria só para o visual de soldados, classes e princesa. Cenário e
jogabilidade ficam em outras conversas. Este arquivo é a "bíblia de estilo":
toda decisão de visual entra aqui.

## Estado atual

- Modelos CC0 da KayKit Adventurers (`assets/characters/*.glb`), todos no
  mesmo esqueleto e com as mesmas animações (`anim_attack` etc. no `.tres`).
- Cada classe é um `config/classes/*.tres`: `model`, `visible_meshes`
  (quais partes do .glb aparecem), `hat_style`, `hat_color`.
- Corpo fundido numa malha só por personagem (menos draw calls).

## Restrições técnicas (o que manda no pipeline)

| Restrição | Valor | Por quê |
|---|---|---|
| Triângulos por personagem | ~3–5 mil | 16+ personagens na tela, GPU Intel UHD integrada, WebGL |
| Texturas | 1 atlas 512–1024 px por modelo, cor chapada/paleta | menos memória e trocas de material |
| Materiais | 1 por personagem (+1 do time se precisar) | cada material extra = mais draw calls |
| Esqueleto | o mesmo humanoide para todas as classes | reaproveita todas as animações de uma vez |
| Cor do time | parte do modelo em cor neutra, tingida no jogo | 1 modelo serve para azul e vermelho |
| Silhueta | legível a ~20 m de câmera alta | a câmera é de cima; o detalhe fino some |

A física do problema: a câmera fica longe, então o personagem ocupa ~60–100 px
de altura na tela. Abaixo do limite de Nyquist da textura, detalhe vira ruído.
Logo, o que diferencia uma classe é **silhueta + massa de cor + proporção**,
não textura. Isso favorece estilos chibi (cabeça grande) e cores chapadas.

## Fluxo de trabalho (tudo nesta conversa, sem gerador de imagem externo)

Editável: se aparecer um jeito mais fácil, troque estas regras aqui.

1. **Direção.** Julio descreve o que quer (texto curto ou referência de jogo).
   O tema e o estilo saem da conversa "Definir identidade visual do jogo".
2. **Modelo por código.** Claude monta ou ajusta o boneco (peças do KayKit,
   primitivas, shader toon, paleta) e gera **uma prancha** por rodada: todas as
   classes lado a lado, frente/lado/costas, mais um print dentro do jogo.
3. **Pitaco.** Julio responde em poucas linhas sobre a prancha ("cabeça maior",
   "arqueiro mais magro"). Uma imagem por rodada, para gastar poucos tokens.
4. **Registro.** A decisão entra na tabela abaixo e no `.tres` da classe.

Caminhos para chegar no modelo, do mais barato ao mais livre:
- **A. Reaproveitar KayKit:** paleta nova, shader toon (cel + contorno),
  troca de chapéu/arma por dados.
- **B. Kitbash:** partes novas presas nos ossos do esqueleto KayKit, então as
  animações continuam servindo.
- **C. Modelo novo** (Blender ou gerador image-to-3D): decimar para o
  orçamento, riggar no mesmo esqueleto, conferir a licença.

Gerar a prancha (corpo KayKit + peças primitivas + shader toon com cor do time):
`tools/prancha_personagens.gd` (comando no topo do arquivo). As peças de cada
classe ficam nas funções `_pecas_*`; shaders em `assets/shaders/toon_time.gdshader`
(pele fica, cinza vira aço, resto vira cor do time) e `contorno.gdshader`.

Import: `.glb` em `assets/characters/`, `.tres` novo em `config/classes/`,
conferir tris, draw calls e cor do time.

## Decisões

| Data | Decisão |
|---|---|
| 2026-10-29 | Frente de visual separada. |
| 2026-10-29 | Sem Gemini: referências saem de modelos por código + prancha de prints aqui. Estilo espera a conversa de identidade visual. |
| 2026-10-29 | Prancha 1 (caminho A+B): Samurai (kabuto com chifres, katana neon), Ninja (faixa magenta, shuriken), Monge (kasa de palha, contas, chi verde), Armadilheiro (óculos, mochila com estrepes, mina). Roupa toda na cor do time. Aguardando pitaco. |
