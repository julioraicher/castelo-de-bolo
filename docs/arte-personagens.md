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

## Pipeline (do conceito 2D ao modelo jogável)

1. **Conceito (Gemini).** Julio gera imagens com os prompts abaixo. Primeiro a
   folha de estilo, depois uma por classe.
2. **Folha de turnaround.** Para virar 3D, cada personagem precisa de frente,
   lado e costas em T-pose ou A-pose, fundo liso, sem sombra forte.
3. **Imagem → 3D.** Três caminhos, do mais barato ao mais livre:
   - **A. Reaproveitar KayKit.** Mesmo modelo, nova paleta/textura, shader
     toon (cel shading + contorno), troca de chapéu/arma. Rápido, sem risco.
   - **B. Kitbash.** Partes novas (cabeças, chapéus, armas, armaduras)
     encaixadas nos ossos do esqueleto KayKit. Ganha identidade sem refazer
     animações.
   - **C. Gerador image-to-3D** (Meshy, Tripo, Hunyuan3D, Rodin). Gera malha
     e textura a partir do turnaround. Saída costuma ter 20–200 mil tris e
     topologia ruim: precisa decimar (Blender), refazer UV/textura às vezes,
     e riggar (auto-rig do próprio gerador ou Mixamo) e redirecionar as
     animações. Conferir a licença de cada gerador antes de publicar.
4. **Import no Godot.** `.glb` em `assets/characters/`, novo `.tres` em
   `config/classes/`. Conferir tris, draw calls e se a cor do time pega.
5. **Print** no jogo (comando de prints do CLAUDE.md) e comparação com o conceito.

## Prompts para o Gemini

Regra: sempre colar o bloco de estilo inteiro no início e só trocar o pedido.
Assim as imagens saem coerentes entre si.

### Bloco de estilo (preencher quando o estilo for escolhido)

```
[ESTILO] (a definir)
```

### Folha de turnaround de um personagem

```
[ESTILO]
Character turnaround sheet of a [CLASSE: ex. stubby knight soldier] for a
top-down 3D action game. Front view, side view and back view side by side,
same scale, A-pose, full body, flat neutral grey background, even studio
lighting, no cast shadows, no text. Chibi proportions (head about 1/3 of body
height), chunky readable silhouette, large simple shapes, flat colors with
minimal texture. Team-colored parts (tabard, plume, cape) painted in plain
white so they can be tinted in-engine. Low-poly friendly design.
```

## Decisões

| Data | Decisão |
|---|---|
| 2026-10-29 | Frente de visual separada; fluxo conceito no Gemini → turnaround → 3D. |
