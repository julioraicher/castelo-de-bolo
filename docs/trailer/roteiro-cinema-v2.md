# Trailer de cinema v2: "A Máscara Tem Fome"

Decisão do Julio (2026-10-31): trailer de **cinema puro**, longe do visual do jogo
(como os trailers de Clash of Clans). Curto (~35 s), muitas cenas épicas e de medo,
animação puxada para o realista. Nada de print do jogo na tela.

## Como gerar (Hugging Face, conta grátis do Julio)

- Imagem: `mcp-tools/FLUX.1-Krea-dev` (1024×576). Personagem repetido: gerar a 1ª
  vez com FLUX Krea e manter igual nos outros planos com `mcp-tools/FLUX.1-Kontext-Dev`
  ("same character, new pose/scene").
- Vídeo: `zerogpu-aoti/wan2-2-fp8da-aoti-faster` (imagem → vídeo) ou
  `Lightricks/ltx-video-distilled` (mais barato, 3-5 s). Cota ~5 min de GPU/dia:
  priorizar os planos 1, 4, 6, 9 e 10; o resto pode ser imagem com zoom lento no ffmpeg.
- Julgar cada resultado; refazer só ajustando o prompt (máx. 2 tentativas por plano).
- Montar com ffmpeg em 16:9 e corte vertical 9:16. Música e sons: `tools/gerar_sons.py`
  ou síntese própria (taiko, drone grave, sino).

## Bíblia visual (vale para todos os prompts)

`STYLE`: cinematic still from a dark animated feature film, stylized realism (Arcane,
Love Death + Robots), feudal Japan dark fantasy, painterly textures, volumetric fog,
blood-red moon, cold blue shadows, warm lantern light, anamorphic lens, film grain.

- **Kuro**, ninja do clã azul: jovem, magro, máscara de pano azul-noite, faixa rasgada,
  selos de tinta azul-ciano que brilham na pele dos braços e no pescoço, olhos ciano.
- **Ronin Oni**, líder do clã vermelho: gigante, armadura laqueada vermelha rachada,
  máscara de demônio oni, porrete de ferro com cravos, brasas saindo das frestas.
- **A Máscara Oni**: máscara antiga de laca vermelha, chifres dourados, presas, correntes
  de ferro, chamas-fantasma azul-pálidas (hitodama) em volta.

## Planos (~35 s)

| # | s | Cena | Prompt de imagem (+ STYLE) | Movimento |
|---|---|---|---|---|
| 1 | 3 | Lua de sangue, corvos | huge blood-red moon behind torn clouds over a silhouetted Japanese castle on a cliff, crows | slow push-in, crows cross the moon |
| 2 | 3 | Vila morta | abandoned Japanese village street at night, paper lanterns, river with red wooden bridge, thick fog | lanterns go out one by one toward camera |
| 3 | 4 | A Máscara | the Oni mask on a stone altar in a ruined castle hall, chained, ghost flames orbiting, eye holes glowing | slow dolly in; chains tremble; eyes ignite |
| 4 | 3 | Kuro desperta | extreme close-up of Kuro, cyan ink seals crawling up his neck, eyes igniting cyan, rain | seals light up, eyes flare |
| 5 | 3 | O exército vermelho | dozens of red-armored warriors with glowing red eyes marching out of fog on a bridge, Ronin Oni in front | march toward camera |
| 6 | 3 | Ronin Oni | low angle of Ronin Oni raising a spiked iron club, embers bursting from cracked armor, red moon behind | club rises, embers swirl |
| 7 | 2 | Choque | Kuro's blade meeting the iron club, shockwave of sparks and ink splash, slow motion | impact, sparks freeze |
| 8 | 2 | Raposa de fogo | giant fox made of blue fire leaping over rooftops at night | fox leaps across frame |
| 9 | 4 | Fuga | Kuro sprinting through burning village carrying the huge Oni mask in his arms, ghost chains pulling him back | tracking shot, chains yank |
| 10 | 3 | O sorriso | extreme close-up of the Oni mask, its mouth slowly opening into a grin, total darkness around | mouth opens; hard cut to black |
| — | 5 | Título | preto, título do jogo em pincel vermelho, "Em breve" | corvo grita |

Textos na tela (curtos, entre planos): "Dizem que a máscara dorme." (após 2) ·
"...mas ela tem fome." (após 3) · "Leve para casa." (após 9).
