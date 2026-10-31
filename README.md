# Castelo de Bolo

Jogo de ação 3D para PC e navegador, feito em Godot 4.7, num mundo ninja.
Dois castelos, uma **Máscara Oni** em cada. Invada o castelo inimigo, leve a
máscara deles até o seu pedestal e não deixe levarem a sua. Primeiro a 3 vence.

- 8 contra 8, com bots
- Chapéus trocam a classe: Samurai, Ninja de Shuriken, Kitsune e Construtor;
  oficinas e o caminho dos magos liberam mais
- O Construtor corta madeira e ergue as oficinas do pátio
- Morreu? Volta como recruta e pega outro chapéu

## Jogar

- **No navegador:** <https://julioraicher.github.io/castelo-de-bolo/>
- **Windows/Linux:** [Releases > Última versão](https://github.com/julioraicher/castelo-de-bolo/releases/tag/ultima-versao)
- **No editor:** abra o `project.godot` no Godot 4.7 e aperte F5.

| Tecla | Ação |
|---|---|
| WASD | andar |
| Mouse | mirar |
| Clique esquerdo | atacar |
| Clique direito (segurar) | defender (contra-golpe se erguido na hora) |
| Q | habilidade rápida da classe |
| E | poder de Chi (medidor cheio) |
| Espaço / Shift | esquivar |
| F | pegar chapéu ou máscara, escolher oficina |
| Esc / P | pausar: controles e configurações |
| R | reiniciar |
| F11 | tela cheia |

Detalhes, regras e dicas em [CONTROLES.md](CONTROLES.md). Volume, dificuldade,
qualidade, tema e tremor de câmera ficam no menu **Esc > Configurações** e são
salvos para a próxima vez.

**Primeira abertura no navegador demora uns segundos:** o navegador baixa o
motor do jogo e os modelos 3D (algumas dezenas de MB) uma vez. Depois fica em cache e abre rápido. A versão
.exe abre na hora.

## Para quem vai mexer no código

Leia o [GUIA.md](GUIA.md): mapa dos arquivos, onde mudar cada coisa e a física
por trás. O que está feito e o que vem depois fica no [ROADMAP.md](ROADMAP.md).

## Créditos

- Corpos dos personagens: [KayKit](https://kaylousberg.com) por Kay Lousberg (CC0). Cenário e roupas ninja feitos por código (`tools/gerar_*.gd`, `scripts/actors/ninja_visual.gd`).
- Sons e música: sintetizados por `tools/gerar_sons.py`.
- Inspirado no estilo de jogo de *Fat Princess* (2009). Nome, arte e código são originais.
