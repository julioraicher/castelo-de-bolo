# Castelo de Bolo

Jogo de ação 3D para PC, feito em Godot 4.7. Dois castelos, uma princesa em
cada. Invada o castelo inimigo, carregue a princesa deles até o seu e não
deixe roubarem a sua. Alimente a sua princesa com bolo: quanto mais gorda,
mais devagar anda quem tentar levá-la.

- 8 contra 8, com bots
- Chapéus trocam a classe: Guerreiro, Arqueiro e Clérigo (cura)
- Morreu? Volta como aldeão e precisa pegar outro chapéu

## Jogar

- **No navegador:** link em *Settings > Pages* deste repositório.
- **Windows/Linux:** baixe em *Releases > Última versão*.
- **No editor:** abra o `project.godot` no Godot 4.7 e aperte F5.

| Tecla | Ação |
|---|---|
| WASD | andar |
| Mouse | mirar |
| Clique esquerdo | atacar |
| Clique direito / Q | curar (clérigo) |
| Espaço | esquivar |
| E | pegar/soltar princesa, trocar de chapéu |
| R | reiniciar |

## Para quem vai mexer no código

Leia o [GUIA.md](GUIA.md): mapa dos arquivos, onde mudar cada coisa e a física
por trás.

## Créditos

- Personagens e cenário: [KayKit](https://kaylousberg.com) por Kay Lousberg (CC0).
- Sons e música: sintetizados por `tools/gerar_sons.py`.
- Inspirado no estilo de jogo de *Fat Princess* (2009). Nome, arte e código são originais.
