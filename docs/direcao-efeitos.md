# Direção dos efeitos: lançamentos, impactos e animações "uau"

**Decidido pelo Julio em 2026-10-31** no Quiz dos Efeitos
(https://claude.ai/artifact/W1rM2CeAN8SkDEUQ6pCv4u), inspirado no reel "Feel the
Frost" do canal Pragmatic Game Developer: **mesmo dano, outra sensação**.
Escrito pelo estagiário de ideias.

## 1. A receita: seis camadas

Cada lançamento ganha **cor, forma, rastro, impacto, reação do alvo e som**
(B1 = ABCDE). O brilho de carga na mão ficou de fora.

O porquê: o olho lê movimento por fluxo óptico. O rastro desenha a trajetória
recente, então dá para estimar direção e velocidade sem seguir o projétil.
Forma e cor criam redundância de pistas (você reconhece o poder sem ler nada).
Impacto e reação fecham a causalidade "A acertou B".

Tom: **sombrio e "uau"**, dentro da direção do Ciclo 2.2 (conto sombrio
pintado). Antes de desenhar, leia o roteiro do trailer
(`docs/trailer/roteiro-cinema-v2.md` e `roteiro.md` no branch
`claude/project-thread-y822xi`), que
descreve a sensação que o Julio quer.

## 2. Orçamento por frequência (pedido do Julio)

Ataque rápido e frequente leva efeito **leve**. O efeito máximo fica para o
poder raro. O custo na tela é proporcional a Σ (disparos por segundo × partículas
por disparo), então quem atira 3 vezes por segundo não pode custar o mesmo que um
poder de Chi a cada 20 s.

| Nível | O quê | Orçamento por disparo (indicativo) |
|---|---|---|
| 1 leve | ataque básico (shuriken, flecha, orbes, bomba comum) | forma + rastro curto (≤ 8 partículas vivas), impacto pequeno |
| 2 médio | habilidade Q | rastro completo, impacto próprio, reação |
| 3 máximo | poder de Chi (E) | tudo, com marca no chão e som cheio |

Quantidade total na tela: **média** (B10 = B). Se um detalhe quase não se vê,
corte (ele pediu "ache um bom meio termo"). O rastro desliga na qualidade
Mínima. O orçamento de ~10% de FPS de `docs/principios.md` continua valendo,
então meça com `--perf` antes e depois.

## 3. Escolhas por projétil

| Projétil | Classe | Escolha |
|---|---|---|
| Shuriken | Ninja de Shuriken | **B**: lascas de metal voando no caminho, estilhaço no acerto (leve) |
| Flecha | Arqueiro Yumi | **A**: flecha de verdade, fita de vento fina, poeira e marca no chão (leve) |
| Bomba | Bombardeiro | **A**: faíscas do pavio e fumacinha de sprite no voo |
| Fogo-raposa | Kitsune | **B**: três fogos-fátuos (kitsunebi) girando juntos |
| Luz | Kitsune da Luz | **A**: lança dourada que deixa brilhos piscando; cruz de luz no acerto |
| Sombra | Kitsune Sombria | **B**: orbe do vazio com olho e fita de sombra; implode no acerto |
| Minas e o resto | todos | todos no mesmo lote (B12 = A) |

- **Impactos** (B8): os cinco tipos (faíscas + anel, estilhaço, marca no chão
  que some em ~2 s, explosão com fumaça, implosão), cada um onde combina.
- **Reação do alvo** (B9 = B): a marca do elemento no corpo por ~1 s (brasa,
  tinta escorrendo, brilho), **só visual**, sem mudar o dano.
- **Som** (B11): ao lançar, ao acertar e com volume pela distância. Sem
  zumbido contínuo. Sons gerados por código (`tools/gerar_sons.py`).

## 4. Outras aplicações (C1 = A, E, F)

- **Golpe corpo a corpo**: arco do corte com rastro e faísca no acerto.
- **Subir nível da oficina**: anéis dourados subindo e o letreiro.
- **Captura da máscara**: coluna de luz no castelo.

## 5. Porrada e números (A2 = B, D)

- Ainda falta peso, mas **não** é mais tremor: deve vir das camadas acima
  (impacto, reação e som).
- Números de dano **um pouco menores**, e cada jogador vê só o dano que deu
  e o que levou.

## 6. Como entregar (C3 = A e o comentário do C1)

- O Diretor Visual cria sozinho o que achar necessário neste lote. Antes de
  pedir o pitaco, ele mesmo avalia (prints e partidas) e refaz o que ficou
  ruim.
- A entrega é um **GIF curto por poder, antes e depois lado a lado**, e uma
  versão estável na main (testes de regra + 5 min simulados), com "O que
  testar".
- **Regra nova, daqui para frente**: toda mudança de personagem, casinha ou
  cenário vem com animações novas para ela. O pitaco do Julio entra antes de
  produzir, por prancha ou GIF.

## 7. O que ainda depende do quiz de alinhamento

Pátio circular e castelo novo, ritmo da partida ("cheio demais na entrada"),
página de tutorial (classes, evolução, Construtor), identidade única das
letras e da interface, e se as variações do Construtor (Bombardeiro,
Armadilheiro) cortam árvores.
