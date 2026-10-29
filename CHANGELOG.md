# Changelog

Uma entrada por rodada de testes (mais nova em cima). Serve para a próxima
conversa saber o que mudou sem reler o histórico.

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
