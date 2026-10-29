# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.

## 2026-10-29, frente Identidade: prompt-mestre do Gemini
- `docs/identidade.md`: diário de nome, tema, estilo geral, logo e divulgação,
  com as restrições que qualquer estilo precisa respeitar e o bloco de estilo.
- Prompt-mestre para um Gem do Gemini (link no `docs/identidade.md`).
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
