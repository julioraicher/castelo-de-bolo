# Ideias para futuras atualizações

Lista viva. Qualquer frente anota aqui; o Julio escolhe o que sobe de nível.
**A** = próxima rodada · **B** = depois · **C** = talvez. Ao virar trabalho,
a ideia sai daqui e entra no ROADMAP/CHANGELOG.

## A — próxima
- **Ciclo 2.3: Economia do Construtor** (2026-10-31): `docs/direcao-ciclo-2.3.md`.
  Depois dele, o Ciclo 2.4: habilidade "uau" por personagem + interface nova.
- As ideias de cenário abaixo seguem o estilo pintado e o tom sombrio do
  Ciclo 2.2 (`docs/direcao-ciclo-2.2.md`).
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

- **Sensação de porrada, próximos passos** (thread de controles, 2026-10-31; já feito
  no 2.5: escudo que quica, número com "pop", som por peso, peso no acerto de longe):
  1. Barra de vida com "rastro" branco que desce atrasado (lê quanto o golpe tirou).
  2. Som em camadas por golpe (assobio + baque + estalo) e um som por arma; hoje é
     um "hit" só com tom variando. Precisa gerar 4-6 sons novos (sfxr).
  3. Respingo de tinta no chão onde o golpe acertou (decal que some em 2 s), na cor
     do time de quem apanhou. Cuidar do orçamento de draw calls (MultiMesh).
  4. Postura/"poise": golpes seguidos quebram a guarda (defesa cai, atordoa 0,6 s).
     Dá contra-jogo à defesa nova, que hoje dá para segurar para sempre.
  5. Borda vermelha na tela quando o jogador apanha forte (vinheta 0,2 s).
  6. Abate em sequência (2+ em 3 s): zoom curto + letreiro "DUPLO!".
- **Superpoder especial** (pedido do Julio, 2026-10-31; só anotado): um terceiro
  poder, mais raro que o E, com medidor próprio (ex.: enche com abates e capturas)
  e tecla própria (R ou a roda do mouse; o R hoje reinicia a partida). Cada classe
  com um golpe de "virar a luta" (ex.: Samurai corta todos em linha num traço só).

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
- Efeito de chão por clima: poças que refletem o neon, pétalas caindo, névoa baixa.
- Animação de vitória do time (todos comemoram em volta da máscara).
- Sons próprios por poder (shuriken, talismã, fogo-raposa, explosão de pólvora).

## Radar do estagiário (rodada 1, 2026-10-29)

Achados da pesquisa externa. Nada é adotado sem o Julio escolher; a letra é a
sugestão de prioridade. Custo = rodadas de trabalho, não dinheiro (salvo dito).

- **A · Teste de fumaça no CI** (frente Jogabilidade): rodar a partida
  `--autoplay` de 5 min no GitHub Actions em todo push de branch e falhar se o
  stdout tiver `SCRIPT ERROR`. Automatiza a regra "main sempre jogável" sem
  ninguém lembrar. Custo: ~1 rodada curta, só YAML. Depois, se quiser testes
  de unidade: gdUnit4 + `MikeSchulze/gdUnit4-action` (MIT).
- **A · Sons por poder com IA** (frentes Visual/Jogabilidade; já é ideia B
  "Sons próprios por poder"): ElevenLabs text-to-SFX gera shuriken, talismã,
  explosão em segundos a partir de texto. Atenção: conferir a licença do plano
  grátis para uso comercial. Alternativa 100% livre: sfxr/jsfxr (CC0, gerado
  por parâmetros, combina com o resto feito por código). Custo: 1 rodada.
- **B · Visual mais "Fat Princess original"** (frente Visual): o shader toon
  atual pode ganhar bandas de luz mais duras + luz de borda (rim) colorida;
  referência aberta: "Ultimate Toon Shader" e "Simple Outline" em
  godotshaders.com (MIT/CC0, conferir cada um). Mudança só de material, sem
  modelo novo. Custo: 1 rodada + 1 print.
- **B · Playtesters de fora**: página no itch.io (o export Web já existe) e
  inscrição no "Playtest & Feedback Exchange Jam" (mensal no itch; a edição
  atual fecha em 2026-11-01, a seguinte abre logo depois). Troca: você testa
  jogos dos outros, eles testam o seu. Custo: ~1 h do Julio, zero código.
- **B · Packs CC0 da Quaternius** (frente Cenário): natureza, construções e
  props low-poly CC0 (sem atribuição obrigatória) para encher o mapa maior
  mais rápido que modelar tudo por código; mesmo estilo do KayKit. Custo:
  baixar + 1 tema de teste.
- **C · Hunyuan3D-2 (Tencent, pesos abertos)**: imagem/texto → modelo 3D.
  Útil para props únicos (estátua oni, barco). Contra: malha pesada (precisa
  decimar para o PC do Julio), estilo difícil de casar, licença própria com
  restrições (conferir). Só se o fluxo "peças por código" travar.
- **C · Godot MCP** (`Coding-Solo/godot-mcp`, MIT): deixa um Claude abrir o
  editor Godot, rodar o jogo e ler erros. Aqui na nuvem já fazemos isso em
  headless; só vale se o Julio quiser trabalhar no editor no próprio PC.
  Evitar os pagos/proprietários (GDAI, Summer Engine) por enquanto.
- **C · Estagiário automático**: uma rotina semanal que refaz esta pesquisa e
  anota aqui. Custo: gasta parte do limite semanal; só se o Julio quiser.

## C — talvez
- **Spotar inimigos no minimapa, estilo Battlefield** (Julio, 2026-10-31): marcar um
  inimigo (tecla ou ao acertar) e ele aparece no minimapa por alguns segundos para o
  time. O Julio ficou em dúvida se é boa ideia; por isso o minimapa (2.4o) não mostra
  inimigos. Gancho: `Minimapa._draw` em `scripts/ui/minimapa.gd`.
- **Ninja vs Cowboys** (Julio, 2026-10-31; antes anotado como "minhas vs
  cowboys"): mudança grande para o futuro (Fase 3), um mundo/time novo contra
  os ninjas. Por enquanto fica só ninja.
- Catapulta / arma de cerco construída pelo Construtor (Fase 2).
- Clima que muda durante a partida (a lua sobe, a névoa fecha).
- Modo treino com alvos para testar cada classe sozinho.

## Outros projetos (não cabem neste jogo)
- **Espionagem e hackers** (2026-10-29, quiz 2): drones, espionagem e hackers
  com visual "meio pixelado" (render em baixa resolução ampliado). Mecânicas:
  drones de reconhecimento, hackear torretas/portas, silenciar poderes,
  câmeras de segurança. O "silenciar" já entrou aqui como o **Selo** do mago.
