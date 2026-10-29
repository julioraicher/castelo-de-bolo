# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.

## Rodada 7 (2026-10-29), frente Jogabilidade: Construtor, itens no chão, Monge e Recruta
- Tema (princesa/bolo x Máscara Oni/espíritos) **não** mudou: o Julio ainda
  compara 3 mundos. Os nomes de classe abaixo são provisórios.
- Clérigo → Monge (`monge.tres`) e Aldeão → Recruta (`recruta.tres`, sem poder).
- Construtor (`construtor.tres`, 4º chapéu, modelo Barbarian com machado,
  chapéu cônico `kasa`): clique direito espalha estrepes (`scripts/items/trap.gd`):
  quem pisa leva 15 de dano e fica 50% mais lento por 2 s; até 3, recarga 4 s.
  Poder no Q: Corrida (o poder que era do Aldeão).
- Itens no chão (`scripts/items/pickup.gd`): poção (50% da vida), escudo (40
  por 8 s) e velocidade (1,35x por 6 s). Um a cada 15 s, no máximo 3.
  Números em `game_config.tres` > Itens no chão.
- Bots: Construtor arma estrepes com inimigo a até 7 m (ou na defesa do portão);
  qualquer bot desvia até 10 m para pegar item se não houver inimigo colado.
- Outras frentes (mudança mínima): `config/classes/` (renomes + construtor) e
  `config/mapas/vale.tres` (4º lugar de chapéu em (-3, 8.5); mesmo padrão em
  `map_layout.gd`).
- Teste: 5 min simulados sem erro; até 6 estrepes simultâneas, itens sendo pegos.
- Hora do Caos ficou para depois (precisa de relógio de partida).

## 2026-10-29, frente Identidade: direção v1 depois do quiz 2
- `docs/identidade.md`: direção v1 = Clãs de Neon com lado sombrio; Máscara Oni
  + espíritos substituem princesa + bolo; Brawl Stars 1:3; noite neon; bloco de estilo.
- `docs/design-jogo.md` (novo): 4 papéis com versões, progressão por oficinas,
  poderes rápidos x fortes, gatilhos, itens no chão, mapa e partida.
- `docs/ideias-futuras.md` (novo): jogo de espionagem/hackers pixelado.
- ROADMAP: Fase 2 reescrita a partir do design. Nenhum código mudou ainda.

## 2026-10-29, frente Identidade: diário e quiz
- `docs/identidade.md`: diário de nome, tema, estilo geral, logo e divulgação,
  com as restrições que qualquer estilo precisa respeitar e o bloco de estilo.
- Prompt do Gemini descartado: conceitos serão pranchas 3D feitas aqui.
  Quiz de identidade com 8 mundos candidatos (link no `docs/identidade.md`).
- CLAUDE.md: frente Identidade na tabela de frentes.

## Rodada 6 (2026-10-29), frente Jogabilidade: combate e poderes
- Combate com peso: hitstop de 60 ms no impacto (atacante e alvo congelam),
  golpe só no tronco (dá para bater correndo), rastro do golpe, reação
  Hit_A/Hit_B e morte Death_A/Death_B ao acaso.
- Combo de 3 golpes (Guerreiro: diagonal, horizontal, de cima; Aldeão: soco,
  soco, chute). O 3º dá 1,4x dano e empurrão, rastro dourado e hitstop maior.
- Botão direito (segurar): Guerreiro bloqueia 70% pela frente; Arqueiro
  carrega o tiro (até 1,6x dano, 1,5x velocidade, linha de mira); Clérigo cura.
- Flechas em parábola: caem na distância do mouse (6 m até 1,4x o alcance).
- Medidor de Glacê (0 a 100, no HUD) e poder no Q: Redemoinho, Chuva de
  flechas, Bênção (cura 40% + escudo 25), Corrida do bolo (+40% velocidade).
  Números em `game_config.tres` (fontes do medidor) e nos `.tres` das classes.
- Bots usam o tiro carregado e os poderes (`BotBrain._should_use_power`).
- Tela cheia: tecla F ou F11 (também no navegador); no navegador o Esc fica
  travado em tela cheia (Keyboard Lock); o jogo pausa sozinho ao perder o foco.
- Sons novos: bloqueio, poder, medidor cheio (`tools/gerar_sons.py`, `combate()`).
- Mexeu em `config/classes/*.tres` (só números de jogabilidade: combo, skill, power).

## Rodada 5 (2026-10-29): reorganização para mudanças fáceis
- Temas em `config/temas/` (luz, céu, neblina, chão, modelos, cores dos times).
  Novo tema de exemplo "Sinistro (noite)". Troca em Esc > Configurações > Tema.
- Mapa em `config/mapas/vale.tres` (arena, muralhas, torres, pedestais, objetos).
- Classes: lista do pátio e classes iniciais dos bots em `game_config.tres`;
  formato do chapéu (`hat_style`) no `.tres` de cada classe.
- Qualidade gráfica com 4 níveis (Mínima = 3D a 50% da resolução) e
  qualidade automática: baixa sozinha se o FPS ficar < 40 no começo.

## Rodada 4: barra de vida, música, chapéu
- Barra de vida voltou a diminuir (billboard sem `keep_scale`).
- Música audível, com loop nativo e canais de áudio fixos.
- Chapéu só com E, com animação de pegar e pôr na cabeça andando.
- Corpo de cada personagem numa malha só (menos chamadas de desenho).

## Rodada 3: fluidez e dificuldade
- Interpolação de física; decoração repetida em MultiMesh; Difícil suavizado.

## Rodada 2: combate e desempenho
- Bug do empurrão (~45 m por golpe) corrigido; qualidade gráfica e contador de FPS.

## Rodada 1: primeira versão pública
- Personagens invisíveis no export corrigidos; tela inicial, pausa,
  controles e configurações.
