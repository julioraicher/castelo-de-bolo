# Kit de teste no Gemini: personagens do trailer

Sem pressa: use quando lembrar. Serve para ver no Gemini como os ninjas ficam
no tom do trailer antes de eu renderizar os quadros no Godot.

## Como usar (2 min por teste)

1. Abra o app do Gemini e escolha **Criar imagem** (o modelo Nano Banana).
2. **Anexe a referência**: `personagens/04-ninja-variacoes.png` (na pasta do
   projeto). É ela que mantém as roupas e as cores dos nossos ninjas.
3. Cole o **bloco de estilo** e, logo abaixo, **um** dos prompts 1 a 5.
4. Se gostar, peça no mesmo chat: *"agora anime isso em 8 segundos"* (Veo) ou
   leve a imagem para o Flow.
5. Me mande os prints com o número do prompt e o que achou ("3 ficou bom, 2 muito fofo").

Prompts em inglês porque os geradores respondem melhor nele.

## Bloco de estilo (cole sempre antes do prompt)

```
STYLE: dark painted fairy-tale, like a hand-painted PS3-era stylized game
(Fat Princess) but grim and cinematic. Stylized 3D characters about 3.5 heads
tall, slightly big hands and feet, chunky readable silhouettes, expressive
angry faces. Hand-painted textures with big soft brush strokes, painted
shadows in corners, warm rim light. Lighting: dusk turning to night, blood-
orange and red sky, long cold purple-blue shadows, low fog on the ground,
paper lanterns glowing, crows. Each ninja shows POWER ON THE BODY: glowing
seals/sigils on skin and cloth, glowing eyes, dark smoke aura. Rival clans:
BLUE clan vs RED clan, team colour on most of the outfit. Keep the costumes,
hats and weapons of the attached reference image, only restyle them.
Cinematic 16:9, shallow depth of field, film grain, no text, no logos.
```

## Prompts

**1. Elenco (pôster dos 4 papéis)**
```
Lineup poster of four blue-clan ninjas standing on a wooden bridge in the
fog, low camera looking up: the Samurai (blue kabuto with small golden horns,
glowing cyan katana), the Shuriken Ninja (blue hood, magenta headband,
glowing star blades between fingers), the Chi Monk (wide straw hat, prayer
beads, green spirit fire in both palms), the Trapper (goggles, mask, backpack
full of spikes). Their seals glow brighter from left to right. Behind them,
far away, a red castle under a huge red moon.
```

**2. Plano 4 do trailer: o ninja se prepara (close)**
```
Extreme close-up of the blue-clan Samurai tightening the cloth wrap on his
fist. Glowing cyan seals crawl up his forearm, his eyes ignite, dark smoke
rises from his shoulders. Lantern light from the side, fog, embers floating.
```

**3. Plano 5 do trailer: o clã vermelho sai da neblina**
```
Wide shot of a long wooden bridge over a dark river at night. Six red-clan
ninjas walk out of thick fog toward the camera in perfect step: the Ronin
Oni with a red demon mask and a spiked club in front, a Kitsune with a white
fox mask and blue fox-fire wisps, an Onmyoji with a tall black hat and paper
talismans. Only their glowing red eyes and red seals are clearly visible,
the rest is silhouette. Menacing, horror movie framing.
```

**4. Plano 3 do trailer: a Máscara Oni**
```
A large ancient Oni demon mask (red lacquer, golden horns, fangs) resting on
a stone pedestal inside a dark castle hall, bound by heavy iron chains.
Ghost flames (hitodama, pale blue-green) orbit it slowly. Its empty eyes are
starting to glow. Dust in the light beams, unsettling, quiet dread.
```

**5. Plano 7 do trailer: fuga com a máscara**
```
A blue-clan Shuriken Ninja running through a dark village street at dusk,
carrying the huge Oni demon mask in both arms, straining under its weight.
Ghostly chains of spirit light pour out of the mask and pull him backward.
Red-clan silhouettes with glowing eyes chase him through the fog. Dynamic
low angle, motion blur, lanterns swinging.
```

## O que eu faço com o retorno

O que você aprovar vira a "bíblia" dos quadros: eu renderizo os mesmos
personagens no Godot (com a arte nova do Ciclo 2.2) e uso esses prompts,
ajustados, para animar no Flow. Se o Gemini sair melhor que o Godot em algum
plano, dá para usar a imagem dele direto como quadro-chave.
