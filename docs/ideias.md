# Ideias para futuras atualizações

Lista viva. Qualquer frente anota aqui; o Julio escolhe o que sobe de nível.
**A** = próxima rodada · **B** = depois · **C** = talvez. Ao virar trabalho,
a ideia sai daqui e entra no ROADMAP/CHANGELOG.

## A — próxima
- **Ciclo 2.2** (aprovado 2026-10-30): piloto da direção nova em
  `docs/direcao-ciclo-2.2.md`. As ideias de cenário abaixo passam a seguir o
  estilo pintado e o tom sombrio de lá.
- **Peças do Rio das Lanternas**: prancha `cenario/06-pecas-rio.png`; o Julio
  diz por número o que detalhar mais, trocar ou repetir.
- **Leva 2 de peças**: prancha `cenario/07-leva2-pecas.png` (templo, casa de chá,
  forja, dojo, barco, ponte de corda, moradores, fundos das casas).
- **Leva 3** (próximas): cemitério de lanternas, estábulo, mercado de peixe,
  casa de banho (onsen com vapor), santuário de raposas com fileira de torii.
- **Moradores com animação leve** (balançar, varrer) e reação à briga (fugir).
- **Capturas raras**: bots quase não levam a máscara até o fim (frente Jogabilidade).
  Rodada 16: média ~2 pontos em 5 min. Se ainda faltar: renascer em ondas,
  Hora do Caos.
- **Navegação do Rio** (frente Cenário): pontos onde bots ficam presos, ex.
  (-15, 12), (9, -6), (-9, -12), (-12, 21) e alvos no pedestal "inalcançáveis".
- **Ajuste dos poderes novos** depois do teste do Julio (dano, raio, recarga).

## B — depois
- **Dividir `scripts/actors/unit.gd`** (1.469 linhas) em partes: movimento,
  combate, animação/corpo, aura/poder. Antes, ampliar `tests/regras.gd` para
  cobrir combo, bloqueio e poderes, que protegem a mudança (Jogabilidade).
- **Bonecos mais leves** (frente Visual, medido na Rodada 19): cada boneco tem
  ~11 mil triângulos com o contorno (16 = ~180 mil por quadro). LOD simples
  (versão de menos polígonos de longe) e contorno desligado na qualidade Mínima.
- **Hora do Caos** (avaliado na Rodada 12, Jogabilidade): relógio de partida
  (ex.: 8 min) e, nos 2 últimos, chi enche 2x, espíritos caem em dobro e a
  música acelera. Barato (só regras + HUD) e resolve partidas que não terminam
  (capturas raras). Precisa do relógio no placar primeiro.
- **Gatilhos de poder** (avaliado na Rodada 12): segundo poder por variação,
  carregado por um feito (3 abates sem morrer, roubar a máscara, terminar uma
  obra) em vez do medidor. Mais complexo: 12 poderes novos + ícones; fazer
  depois de o Julio aprovar os poderes atuais.
- Outros mapas da prancha `cenario/03-ideias-de-mapa.png` (Bambuzal de Três
  Trilhas, Templo Central) usando as peças do Rio.
- Segundo poder por variação (o "forte", com gatilho), como no `docs/design-jogo.md`.
- Oficina com nível 2 (o Construtor "upa" a casinha: chapéu sai mais rápido).
- Efeito de chão por clima: poças que refletem o neon, pétalas caindo, névoa baixa.
- Animação de vitória do time (todos comemoram em volta da máscara).
- Sons próprios por poder (shuriken, talismã, fogo-raposa, explosão de pólvora).

## C — talvez
- **Outro mundo, se um dia trocar o tema** (Julio, 2026-10-30): "minhas vs
  cowboys" (transcrição de áudio; provavelmente mineiros vs cowboys, faroeste).
  Por enquanto fica ninja.
- Catapulta / arma de cerco construída pelo Construtor (Fase 2).
- Recursos no mapa (madeira, pólvora) para pagar oficinas.
- Clima que muda durante a partida (a lua sobe, a névoa fecha).
- Modo treino com alvos para testar cada classe sozinho.

## Outros projetos (não cabem neste jogo)
- **Espionagem e hackers** (2026-10-29, quiz 2): drones, espionagem e hackers
  com visual "meio pixelado" (render em baixa resolução ampliado). Mecânicas:
  drones de reconhecimento, hackear torretas/portas, silenciar poderes,
  câmeras de segurança. O "silenciar" já entrou aqui como o **Selo** do mago.
