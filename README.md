# Castelo de Bolo

Jogo de ação 3D para PC, feito em Godot 4.7. Dois castelos, uma princesa em
cada. Invada o castelo inimigo, carregue a princesa deles até o seu e não
deixe roubarem a sua. Alimente a sua princesa com bolo: quanto mais gorda,
mais devagar anda quem tentar levá-la.

- 8 contra 8, com bots
- Chapéus trocam a classe: Guerreiro, Arqueiro, Monge (cura) e Construtor (estrepes)
- Morreu? Volta como aldeão e precisa pegar outro chapéu

## Jogar

- **No navegador:** <https://julioraicher.github.io/castelo-de-bolo/>
- **Windows/Linux:** [Releases > Última versão](https://github.com/julioraicher/castelo-de-bolo/releases/tag/ultima-versao)
- **No editor:** abra o `project.godot` no Godot 4.7 e aperte F5.

| Tecla | Ação |
|---|---|
| WASD | andar |
| Mouse | mirar |
| Clique esquerdo | atacar |
| Clique direito (segurar) | bloquear / tiro carregado / curar |
| Q | poder especial (medidor de Glacê cheio) |
| Espaço / Shift | esquivar |
| E | pegar chapéu, pegar/soltar princesa |
| Esc / P | pausar: controles e configurações |
| R | reiniciar |
| F / F11 | tela cheia |

Detalhes, regras e dicas em [CONTROLES.md](CONTROLES.md). Volume, dificuldade,
tela cheia e tremor de câmera ficam no menu **Esc > Configurações** e são
salvos para a próxima vez.

**Primeira abertura no navegador demora uns segundos:** o navegador baixa o
motor do jogo e os modelos 3D (algumas dezenas de MB) uma vez. Depois fica em cache e abre rápido. A versão
.exe abre na hora.

## Para quem vai mexer no código

Leia o [GUIA.md](GUIA.md): mapa dos arquivos, onde mudar cada coisa e a física
por trás. O que está feito e o que vem depois fica no [ROADMAP.md](ROADMAP.md).

## Créditos

- Personagens e cenário: [KayKit](https://kaylousberg.com) por Kay Lousberg (CC0).
- Sons e música: sintetizados por `tools/gerar_sons.py`.
- Inspirado no estilo de jogo de *Fat Princess* (2009). Nome, arte e código são originais.
