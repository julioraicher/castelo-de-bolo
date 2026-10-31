# Identidade da interface: "Festival sombrio"

**Escolhido pelo Julio em 2026-10-31** no Quiz de Identidade
(https://claude.ai/artifact/4XN3GPQY6oqyVDhr6uWERk). A regra é **uma vibe só no
jogo inteiro**: menu, HUD, placar, tutorial "Como jogar", letreiros 3D, avisos e
dicas. Este documento substitui as escolhas de fonte de
`docs/estilo-textos.md`. O tom da escrita e a escala de tamanhos de lá
continuam valendo.

## Referência

Fat Princess, Brawl Stars e Clash Royale, com a paleta escura do "conto sombrio
pintado" (Ciclo 2.2). O porquê: numa briga vista de cima, o texto fica sobre um
fundo colorido que muda a cada quadro. Só traço grosso com contorno escuro
garante contraste em qualquer pixel (a luminância do contorno separa a letra do
fundo, seja qual for a cor dele). Letra fina perde legibilidade no caos.

## As peças (iguais em todo lugar)

| Peça | Escolha |
|---|---|
| Títulos, avisos grandes, números (placar, vida, dano, contadores) | **Lilita One** (OFL), com contorno escuro grosso (#1a1020) e sombra sólida 3-4 px para baixo |
| Texto (dicas, menus, tutorial, descrições) | **Nunito Black** (900, OFL), com contorno fino quando estiver sobre o jogo |
| Placas e molduras | **laca escura** (#1b1420) com **borda de ouro** (#e2b553) de 2 px, cantos arredondados (~10 px) e sombra sólida embaixo, como uma peça física |
| Botões | ouro em degradê (#f3d48a → #d39a2a), texto escuro, contorno escuro e sombra sólida |
| Cores | ouro (destaque), cor do time (azul #6fb0ff / vermelho #ff6a5f) e laca escura. Mais nenhuma cor de interface |
| HUD | **cheio** (escolha do Julio): vida, placar, Q/E, minimapa, abates, mortes e Chi sempre visíveis, **mas presos nas bordas**. O centro da tela é da briga e dos efeitos novos |

A Shojumaru e a Barlow Condensed **saem** da interface. Se a Shojumaru for
boa para algo pintado no cenário (placa de madeira de uma casa), ela pode ficar
**só lá**, como arte e não como interface.

## Como aplicar

- Um lugar só define fontes, cores e o estilo de placa (`Estilo` em
  `scripts/ui/`). Nada de cor ou fonte solta em `hud.gd`, `menus.gd`,
  letreiros ou tutorial.
- Os letreiros 3D (`Label3D`: "DEPÓSITO · N", "NÍVEL 3/5", nomes das
  maquininhas) usam Lilita One com `outline_size` grande, para combinar com o
  HUD.
- A página "Como jogar" (`docs/direcao-patio-e-tutorial.md`) já nasce neste
  estilo.
- Conferir no navegador do Julio (WebGL fraco): fontes como `.ttf` em
  `assets/fonts`, sem carregar nada da internet.
- Entrega com um print do menu, do HUD na briga e do tutorial, lado a lado.
