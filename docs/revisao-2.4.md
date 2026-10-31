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

Não mexi: é decisão de ritmo de partida, e você ainda não reclamou disso.

## O que falta (lista)

- **HUD moderno**: o Visual entregou a 1ª versão (PR #6). Falta o seu pitaco.
- **Poderes Q "uau" novos**: só reaproveitei os existentes (Bênção, Selo) nas Kitsunes
  opostas. Um Q novo por classe exige o seu gosto (quiz curto quando você voltar).
- **Opostos nas outras classes** (Samurai de honra x Ronin amaldiçoado, tecnológico x
  feitiço): o padrão está pronto (`classe_base` + oficina). Cada par novo é um `.tres`.
- **Equilíbrio das Kitsunes opostas**: números iniciais, sem teste com gente.
- **Ritmo de pontos** (acima).
