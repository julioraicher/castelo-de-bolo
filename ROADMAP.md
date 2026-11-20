# Roadmap

Plano do jogo em fases. Cada item grande vira uma conversa própria com o
Claude no projeto; esta lista é a fonte da verdade do que já foi feito e do
que vem depois. Edite à vontade (mude a ordem, risque, acrescente).

## Fase 1: protótipo jogável e polido (feita)

Objetivo: uma partida curta, sem bugs, gostosa de jogar no navegador e no .exe.
Aqui só entram correções, sensação de jogo (*game feel*), equilíbrio e desempenho.

- [x] Partida 8 contra 8 com bots, princesas, bolo, chapéus, respawn
- [x] Guerreiro, Arqueiro, Clérigo e aldeão (hoje Monge e Recruta)
- [x] Esquiva rápida (dash), aprovada: manter como está
- [x] Publicação automática (web + Windows + Linux)
- [x] Tela inicial, pausa, controles e configurações salvas
- [x] Empurrão dos golpes corrigido (era bug)
- [x] Qualidade gráfica, contador de FPS, interpolação de física, MultiMesh
- [x] Dificuldade Difícil suavizada
- [x] Jogo liso no PC do Julio (.exe ~50 FPS; Rodada 19 e 2b do Ciclo 2.2)
- [x] Juntar as partes de cada personagem numa malha só (menos chamadas de desenho)
- [x] Temas, mapa e classes em arquivos de dados (re-skin sem código)
- [x] Qualidade automática
- [x] ~~Tema "Sinistro"~~ substituído pelos temas ninja (Festival ao Sol, Crepúsculo, Floresta Oni, Templo ao Luar)
- [ ] Revisão de equilíbrio depois de algumas partidas
- [x] Testes de regra no CI (`tests/regras.gd`) além da partida simulada

## Fase 2: o "jogo de semanas" (mecânicas do estilo Fat Princess)

Elenco atual: menu **Classes** do jogo (gerado de `config/classes/*.tres`); o plano original do elenco está em [docs/elenco-ciclo-2.4.md](docs/elenco-ciclo-2.4.md). Ideias em [docs/ideias.md](docs/ideias.md).

- [x] Mundo ninja fixo: Máscara Oni + espíritos no lugar de princesa + bolo
- [x] Papel Construtor (4º papel) e Clérigo → Monge (nomes provisórios)
- [x] Itens no chão: poção, escudo, velocidade
- [x] Gatilhos de poder: SUPER na tecla R carregado por abates, dano, itens e espíritos (Ciclo 2.8)
- [ ] Hora do Caos (em parte: último minuto com máscaras leves, Ciclo 2.31)
- [x] **Ciclo 2.3: Economia do Construtor** madeira e bambu em 3 estágios, Construtor carrega toras, maquininhas de chapéu com estoque, casinhas custam madeira com contador, QA automático do mapa: [docs/direcao-ciclo-2.3.md](docs/direcao-ciclo-2.3.md)
- [x] Oficinas sobem de nível (nível 2 das maquininhas: Etapa 2 do Ciclo 2.3)
- [x] **Ciclo 2.4**: elenco novo, habilidade "uau" por personagem e interface nova
- [x] **Ciclo 2.5**: pátio em ferradura, Torre da Máscara, identidade "Festival sombrio", página "Como jogar"
- [x] Torretas e catapulta do Construtor (Ciclo 2.9)
- [ ] Portão do castelo que pode ser quebrado e consertado
- [ ] Atalho que abre durante a partida
- [ ] Segundo mapa
- [x] **Ciclos 2.6-2.13**: efeitos dos poderes, mira nova, modo teste, SUPER (R), menus de jogo, equilíbrio das classes
- [x] **Ciclos 2.14-2.17**: Personagens 2.0 (corpos com detalhe, dash com personalidade), placar no Tab, otimização (malha única, Compatibility)
- [x] **Ciclos 2.18-2.20**: reanimar aliados, Alta a 30 FPS, magia de verdade nos poderes (kit Magia)
- [x] **Ciclos 2.21-2.23**: casinhas da classe até o nível 5, caminhos em pares, heróis raros no nível 6 (pavilhão dourado)
- [x] **Ciclos 2.24-2.27**: assinatura de cada personagem, menos empate, porrada que se sente, 5 heróis novos (13 no total)
- [x] **Ciclos 2.28-2.30**: multiplayer com amigos (sala por código), Arena de chapéus, Predero (herói do Construtor)
- [x] **Ciclos 2.31-2.35**: partida de 20 min, peças do chão refeitas, textos dos painéis, personalidade no corpo + finalização de herói, revisão completa do código
- [x] **Ciclo 2.2: jogo mais "completo"** (visual pintado estilo Fat Princess PS3, tom sombrio, poder no corpo, animação exagerada; piloto primeiro): [docs/direcao-ciclo-2.2.md](docs/direcao-ciclo-2.2.md)

## Fase 3: depois

- [ ] Metal e pedra (minério ninja) como recursos
- [ ] Ninja vs Cowboys (mundo novo; ver docs/ideias.md C)
- [x] Multijogador online com amigos (Ciclo 2.28; local com 2 teclados não)
- [ ] Versão para celular (controles de toque)
- [ ] Arte e sons próprios (em parte: cenário e roupas por código, sons Kenney CC0 + síntese)

## Como trabalhar

1. Jogue a versão publicada e conte o que achou na conversa da fase atual.
2. Para começar um item grande da Fase 2, peça no chat principal do projeto:
   ele vira uma conversa nova, com plano, código e prints.
3. Quer mexer você mesmo? Veja [GUIA.md](GUIA.md) e [AULA.md](AULA.md).
