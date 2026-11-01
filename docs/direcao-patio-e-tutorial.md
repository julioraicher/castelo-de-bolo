# Direção: pátio, castelo novo, ritmo e tutorial

**Decidido pelo Julio em 2026-10-31** no Quiz de Alinhamento
(https://claude.ai/artifact/So9tiB2Z1yMeFhiKBGhzur). Complementa
`docs/direcao-efeitos.md`. A identidade da interface (letras, molduras) **ainda
não foi escolhida**: ela sai de um quiz próprio, e até lá ninguém restiliza a UI.

## 1. Pátio em ferradura e castelo refeito (respostas 1 = B, 2 = A)

- **Pátio em ferradura**: as casinhas formam um arco aberto para a frente,
  com uma saída larga. As 4 maquininhas ficam no meio do arco, e Luz e Sombra
  ficam nas pontas, opostas. Tem que ter ar entre as peças. Rode o QA do mapa
  (`--qa-mapa`) antes de entregar. O navmesh precisa de vão ≥ 3,4 m entre
  colisores.
- **Castelo refeito do zero**, como peça-base no nível máximo da "nova era":
  torre alta com a máscara no fundo do arco, muralha que acompanha a
  ferradura, portões, formatos detalhados, luzes e efeitos. Ele segue o
  "conto sombrio pintado" (Ciclo 2.2) e a regra nova: modelo novo vem com
  animações novas (portão abrindo, bandeiras, fogo nas lanternas, torre
  reagindo à captura).
- Prancha ou GIF para o pitaco do Julio **antes** de produzir o resto do mapa.

## 2. Ritmo: "cheio demais na entrada" (3 = A, B, E)

- **Espalhar**: renascer em pontos diferentes do arco e sair pela saída larga
  e pelas laterais.
- **Bots se dividem por papel**: o Construtor vai ao bosque, os magos ficam
  atrás e os guerreiros vão à frente.
- **Começo calmo**: os primeiros ~30 s servem para pegar chapéu e cortar
  madeira. O número fica em `game_config.tres`.

## 3. Tutorial "Como jogar" (4 = A, B, C, D)

- Página no menu, ao lado de Controles e Configurações, com abas ilustradas:
  **Objetivo**, **Classes** (4 papéis × 3 variações: retrato, papel, Q e E),
  **Madeira** (cortar, pegar, entregar, construir), **Casinhas e níveis**,
  **Luz e Sombra**.
- Abre sozinha na 1ª partida. Depois fica no menu (preferência salva em
  `Settings`).
- **GIF curto em cada aba**, gravado do jogo. Carregar sob demanda, porque o
  navegador é fraco.
- **Contador no HUD**: "CARREGANDO 1/1" quando há tora nos braços, e o
  estoque do time sempre à vista.
- O texto do tutorial pode ser escrito já. O visual espera a identidade
  escolhida.

## 4. Bombardeiro e Armadilheiro cortam árvore (5 = A)

Bug de hoje: os dois são variações do Construtor (`velocidade_obra > 0`, então
`lenhador()` é verdadeiro e a seta aparece). Só que o corte de planta está
dentro do golpe corpo a corpo (`unit.gd`, perto de `golpear_plantas`), e o
Bombardeiro ataca à distância. A seta manda cortar e o clique joga bomba.

Correção: perto de uma planta adulta (≈ alcance do golpe + 0,6 m), o clique
de qualquer lenhador vira **machadada**. Longe dela, o ataque é o normal.
Precisa de teste de regra novo em `tests/regras.gd`.

O Julio ainda acha o lenhador complicado. A ideia de simplificar está em
`docs/ideias.md` (B).
