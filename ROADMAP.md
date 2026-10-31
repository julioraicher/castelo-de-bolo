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

Detalhes em [docs/design-jogo.md](docs/design-jogo.md) (classes, poderes, progressão).

- [x] Nova identidade v1: Clãs de Neon, Máscara Oni + espíritos no lugar de princesa + bolo ([docs/identidade.md](docs/identidade.md))
- [x] Papel Construtor (4º papel) e Clérigo → Monge (nomes provisórios)
- [x] Itens no chão: poção, escudo, velocidade
- [ ] Gatilhos de poder (sequência de abates, ao morrer, Hora do Caos)
- [ ] **Ciclo 2.3: Economia do Construtor** (aberto 2026-10-31): madeira e bambu em 3 estágios, Construtor carrega toras, maquininhas de chapéu com estoque, casinhas custam madeira com contador, QA automático do mapa: [docs/direcao-ciclo-2.3.md](docs/direcao-ciclo-2.3.md)
- [ ] Oficinas sobem de nível (nível 2 das maquininhas: Etapa 2 do Ciclo 2.3)
- [ ] **Ciclo 2.4**: habilidade "uau" por personagem e interface nova
- [ ] Catapulta (carregar, mirar, lançar aliados/pedras)
- [ ] Portão do castelo que pode ser quebrado e consertado
- [ ] Atalho que abre durante a partida
- [ ] Segundo mapa
- [x] **Ciclo 2.2: jogo mais "completo"** (visual pintado estilo Fat Princess PS3, tom sombrio, poder no corpo, animação exagerada; piloto primeiro): [docs/direcao-ciclo-2.2.md](docs/direcao-ciclo-2.2.md)

## Fase 3: depois

- [ ] Metal e pedra (minério ninja) como recursos
- [ ] Ninja vs Cowboys (mundo novo; ver docs/ideias.md C)
- [ ] Multijogador (local com 2 teclados ou online)
- [ ] Versão para celular (controles de toque)
- [ ] Arte e sons próprios

## Como trabalhar

1. Jogue a versão publicada e conte o que achou na conversa da fase atual.
2. Para começar um item grande da Fase 2, peça no chat principal do projeto:
   ele vira uma conversa nova, com plano, código e prints.
3. Quer mexer você mesmo? Veja [GUIA.md](GUIA.md) e [AULA.md](AULA.md).
