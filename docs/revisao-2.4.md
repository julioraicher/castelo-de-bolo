# Revisão do Ciclo 2.4 (Diretor de Jogabilidade, 2026-10-31)

Revisão feita no bloco autônomo, com partidas simuladas de 5 min (bots dos dois lados).

## O que foi checado

| Ponto | Antes | Agora |
|---|---|---|
| Bots usam dash? | Nunca | ~1 dash a cada 12 s por bot: fechar distância, fugir com pouca vida, recuar atirador, sair do combo, correr com a tora |
| Bots bloqueiam? | Nunca | Samurai/Ronin erguem o bloqueio contra golpe de frente (às vezes sai contra-golpe) |
| Bots usam o Q? | Sim, menos o Construtor (Corrida) | Construtor usa a Corrida com a tora ou indo longe |
| Madeira tem destino? | Sobrava ~22 no fim | Depois das oficinas vai para o nível 2 das maquininhas |
| Obra perdia progresso? | Sim: [E] trocava a opção e zerava | Opção trava quando a obra começa |
| 1ª oficina | ~146 s | 65-130 s (bots tocam a obra mais adiantada) |

## Observação para o Julio: pontos raros

6 partidas de 5 min, metade com a alma de abate e metade sem: **0 a 1 ponto** nos dois casos,
com 5 a 20 roubos de máscara por partida. Quem rouba cai em 3-4 s, ainda dentro do castelo
inimigo, e a máscara volta. Ou seja, a alma de abate não é a causa: o castelo é fácil de
defender e o caminho de volta (mapa 168 x 96 m) é longo. Com jogador humano deve render mais.

Se quiser mais pontos, há três alavancas só de número, sem mudar regra:
1. `carrier_damage_mult` menor (o ladrão aguenta mais);
2. `carry_speed_mult` maior nas classes (o ladrão corre mais);
3. `princess_return_time` maior (hoje 15 s ao lado da máscara caída para devolvê-la; mais tempo = o time do ladrão retoma).

Aplicado em 2.4h (opção recomendada do card): 0,4 e 25 s, ~1,7 ponto por 5 min com bots.
Calibração (3 partidas cada): 0,5/15 ~0,5; 0,5/25 ~1,7; 0,42/25 ~1; 0,4/25 ~1,7; 0,35/25 3-5.

## O que falta (lista)

- **HUD moderno**: o Visual entregou a 1ª versão (PR #6). Falta o seu pitaco.
- **Poderes Q "uau"**: 2.4h deu Fúria gigante, Redemoinho vórtice, Leque em 2 ondas e
  Campo Minado. 2.4j: Bombardeio em fila (Bombardeiro) e arremate na Chuva (Yumi).
  Construtor fica com a Corrida. Falta o seu pitaco nos novos.
- **Opostos nas outras classes** (Samurai de honra x Ronin amaldiçoado, tecnológico x
  feitiço): o padrão está pronto (`classe_base` + oficina). Cada par novo é um `.tres`.
- **Equilíbrio das Kitsunes opostas**: números iniciais, sem teste com gente.
- **Ritmo de pontos**: aplicado (acima); confirmar jogando.

## Equilíbrio por classe (2026-10-31, 4 partidas de 5 min com `--variacoes`, bots)

| Classe | Mortes | Abates |
|---|---|---|
| Yumi (`arqueiro_yumi`) | 2 | 66 |
| Ninja de Shuriken (`arqueiro`) | 76 | 91 |
| Samurai (`guerreiro`) | 46 | 41 |
| Kitsune | 97 | 24 |
| Ronin Oni | 9 | 6 |
| Bombardeiro | 1 | 6 |
| Armadilheiro | 6 | 4 |
| Construtor | 5 | 4 |

Leitura: a **Yumi está forte demais** (33 abates por morte, igual nas 4 partidas) e a
**Kitsune fraca** (4 mortes por abate). Os números passam pelo jeito do bot jogar (a Yumi
fica longe), então o próximo passo é testar alcance/dano da Yumi e vida da Kitsune com a
mesma sonda (print `BAL` temporário em `Game._on_unit_died`, não commitado).
