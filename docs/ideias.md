# Ideias para futuras atualizações

Lista viva. Qualquer frente anota aqui; o Julio escolhe o que sobe de nível.
**A** = próxima rodada · **B** = depois · **C** = talvez. Ao virar trabalho,
a ideia sai daqui e entra no ROADMAP/CHANGELOG.

## A — próxima
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
- **B · Trailer cinematográfico** (pedido do Julio, 2026-10-29): cutscenes
  sombrias, de dar medo, no estilo trailer de lançamento; gameplay é opcional.
  Fluxo de custo zero:
  1. **Claude**: roteiro em 6-10 planos (ex.: lua vermelha, vila em silêncio,
     a Máscara Oni acorda, o clã rival nas pontes, briga, título) e storyboard.
  2. **Claude**: renderiza um quadro-chave de cada plano *dentro do Godot*
     (câmera de cinema, luz dramática, neblina, os ninjas do jogo). Como cada
     vídeo parte de uma imagem nossa, os personagens ficam iguais em todos os
     planos, que é o ponto fraco dessas IAs.
  3. **Julio**: anima cada quadro com image-to-video no site, usando os
     créditos grátis diários: Google Flow/Veo 3.1 (~50/dia, até 10 s),
     Seedance (~100/dia, sem marca d'água), Hailuo (bom em movimento de
     personagem, com marca d'água). Daqui da nuvem essas APIs estão bloqueadas.
  4. **Claude**: monta no ffmpeg com cortes, títulos, música do jogo e sons
     (sfxr/ElevenLabs).
  Atenção: no plano grátis, vários desses serviços proíbem uso comercial ou
  põem marca d'água; para divulgar de verdade, conferir os termos. Alternativa
  aberta: Wan 2.2 (pesos abertos, Colab grátis), mais lento e trabalhoso.
  Custo: ~2 rodadas do Claude + ~1 h do Julio gerando os clipes.
- **C · Estagiário automático**: uma rotina semanal que refaz esta pesquisa e
  anota aqui. Custo: gasta parte do limite semanal; só se o Julio quiser.

## C — talvez
- Catapulta / arma de cerco construída pelo Construtor (Fase 2).
- Recursos no mapa (madeira, pólvora) para pagar oficinas.
- Clima que muda durante a partida (a lua sobe, a névoa fecha).
- Modo treino com alvos para testar cada classe sozinho.
