# Roadmap

Plano do jogo em fases. Cada item grande vira uma conversa própria com o
Claude no projeto; esta lista é a fonte da verdade do que já foi feito e do
que vem depois. Edite à vontade (mude a ordem, risque, acrescente).

## Fase 1: protótipo jogável e polido (agora)

Objetivo: uma partida curta, sem bugs, gostosa de jogar no navegador e no .exe.
Aqui só entram correções, sensação de jogo (*game feel*), equilíbrio e desempenho.

- [x] Partida 8 contra 8 com bots, princesas, bolo, chapéus, respawn
- [x] Guerreiro, Arqueiro, Clérigo e aldeão
- [x] Esquiva rápida (dash), aprovada: manter como está
- [x] Publicação automática (web + Windows + Linux)
- [x] Tela inicial, pausa, controles e configurações salvas
- [x] Empurrão dos golpes corrigido (era bug)
- [x] Qualidade gráfica, contador de FPS, interpolação de física, MultiMesh
- [x] Dificuldade Difícil suavizada
- [ ] Jogo liso no navegador do Julio (medir FPS com Esc > Mostrar FPS)
- [ ] Juntar as partes de cada personagem numa malha só (menos chamadas de desenho)
- [ ] Revisão de equilíbrio depois de algumas partidas

## Fase 2: o "jogo de semanas" (mecânicas do estilo Fat Princess)

- [ ] Recursos: aldeões coletam madeira e metal
- [ ] Oficinas que *produzem* chapéus (chapéu deixa de ser infinito)
- [ ] Upgrades de classe pagos com recursos
- [ ] Catapulta (carregar, mirar, lançar aliados/pedras)
- [ ] Portão do castelo que pode ser quebrado e consertado
- [ ] Mais classes (Mago com dano em área, Trabalhador)
- [ ] Poções / bolos especiais
- [ ] Segundo mapa

## Fase 3: depois

- [ ] Multijogador (local com 2 teclados ou online)
- [ ] Versão para celular (controles de toque)
- [ ] Arte e sons próprios

## Como trabalhar

1. Jogue a versão publicada e conte o que achou na conversa da fase atual.
2. Para começar um item grande da Fase 2, peça no chat principal do projeto:
   ele vira uma conversa nova, com plano, código e prints.
3. Quer mexer você mesmo? Veja [GUIA.md](GUIA.md) e [AULA.md](AULA.md).
