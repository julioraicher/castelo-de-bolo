# Identidade do jogo

Diário de decisões da frente de **identidade e direção de arte**: nome, tema,
estilo geral, paleta, logo e artes de divulgação. O que é específico de
personagem vai para `docs/arte-personagens.md`; de cenário, para
`docs/arte-cenario.md`. Se uma decisão mudar, risque a antiga e escreva a nova.

## Como iteramos

Sem gerador de imagem por enquanto (decisão do Julio em 2026-10-29): tudo sai
daqui, em 3D, no estilo do jogo.

1. **Quiz de identidade** (respostas salvas no banco do artefato, Claude lê):
   https://claude.ai/artifact/3dyzh7VgMQiDnc1NPT2fcB — 8 mundos candidatos,
   tom, proporções, acabamento, paleta, efeitos, poderes, mudanças de regra, nome.
2. **Pranchas 3D**: Claude monta variações low-poly por código no Godot e manda
   uma imagem por rodada (opções A/B/C/D, close + câmera do jogo no tamanho real).
   Julio responde por letra ("B com o chapéu da D").
3. O escolhido vira dado (`config/`) e vai para o jogo publicado.
4. Decisão registrada aqui; personagem e cenário seguem nas frentes deles.

## Restrições que qualquer estilo precisa respeitar

| Restrição | Valor | Consequência para a arte |
|---|---|---|
| Câmera | offset (0, 21, 19) m, FOV 42°: ~48° de inclinação, ~28 m de distância, perspectiva | conceitos pedidos em vista 3/4 de cima, não isométrica pura |
| Tamanho na tela | boneco com 60-100 px de altura | classe se lê por silhueta e massa de cor, não por detalhe |
| GPU | Intel UHD integrada, WebGL | low-poly, cor chapada, efeitos com formas grandes e emissivo, pouca transparência |
| Times | azul x vermelho tingidos no jogo | partes do time em áreas grandes e lisas |
| Key art | sem limite técnico | pode ser pintada e rica, mantendo formas e cores do jogo |

## Direção v1 (2026-10-29, a partir do quiz 2)

Rascunho fechado por Claude com base nas notas do Julio. Tudo aqui é reversível.
**Em comparação (2026-10-29):** Julio pediu para ver a primeira prancha com as 4
classes em 3 mundos (Clãs de Neon, Festival Infernal adulto, Cavaleiros Malditos)
antes de fechar. O resto desta seção vale para qualquer um dos três.

**Mundo: Clãs de Neon, com um lado sombrio.** Dois clãs rivais brigam à noite
pelos telhados e vielas de uma cidade japonesa estilizada: lanternas, letreiros
de neon, templos. O lado "maldito" (oni, almas, necromancia, fogo verde) entra
como tempero, e a atitude rock entra nos efeitos (raios, brilho, impacto). Tom
para público jovem/adulto, nada infantil. Ninja levou "Amo"; Festival Infernal e
Cavaleiros Malditos levaram "Gosto"; vikings, gangues e asfalto ficaram de fora.

| Item | Decisão v1 | Por quê |
|---|---|---|
| Tesouro | **Máscara Oni** de cada clã, levada nos braços | escolhida no quiz e casa com o mundo ninja |
| Carga que pesa | **espíritos** (chamas-fantasma, *hitodama*) que surgem no meio; cada um prende mais uma corrente na sua máscara | mesma mecânica do bolo, sem engordar ninguém |
| Times | v1: cor do time na roupa toda (azul x vermelho). v2 possível: ninjas x samurais com visual diferente | v2 dobra o trabalho de modelo; vale depois do estilo aprovado |
| Proporção | cartoon 1:3 | escolha do quiz 2 |
| Acabamento | liso estilo Brawl Stars: formas redondas, cor forte, brilho simples | escolha do quiz 2; barato na GPU |
| Rosto | expressivo (bravo, assustado, carregando peso) | quiz 1 |
| Luz | noite com coisas brilhando | quiz 1 e 2 |
| Paleta | base "Neon de cidade" (azul-noite, ciano, magenta) + acentos "Sombrio verde" (fogo-fantasma) | 4 paletas marcadas; essas duas cobrem o mundo |
| Efeitos | hitstop forte no golpe final, números de dano, rastro no dash, anel de área, brilho emissivo, rachaduras brilhando, choque elétrico | quiz 2; intensidade 7/10, caos 5/10 |
| Medidor | barra sob o retrato + ícone do poder pulsando quando cheio | marcou todos; esses são os mais legíveis |

Ficam como estão: carregar o tesouro nos braços, chapéu no pedestal (oficinas
na Fase 2), um mapa fixo e polido, partida de 5 a 10 min, sem eventos aleatórios
exceto a **Hora do Caos** no último minuto.

**Nome.** Julio pediu nome que abstraia o tema (vale para qualquer mundo).
Favoritos do quiz que já fazem isso: *Heavy Loot*, *Bring It Home*,
*Carry the Heart*, *Vault Brawl*. Candidatos novos no mesmo espírito:
*Heavy Hands*, *Haul Rush*, *Grab & Dash*, *Carry Clash*. "Castelo de Bolo"
segue como nome provisório do repositório até a escolha.

**Ideia guardada para outro projeto:** espionagem/hackers com drones, visual
pixelado. Ver `docs/ideias-futuras.md`.

## Bloco de estilo

```
[ESTILO v1] Stylized 3D, smooth rounded shapes like Brawl Stars, cartoon 1:3
proportions, expressive faces. Night city of rival ninja clans: lanterns, neon
signs, temple roofs. Palette: deep navy night, cyan and magenta neon, ghost-fire
green accents; team colors blue vs red on the whole outfit. Glow comes from
emissive shapes, not real lights. Readable silhouettes from a high 3/4 camera.
```

## Decisões

| Data | Decisão |
|---|---|
| 2026-10-29 | Frente de identidade criada. Nome "Castelo de Bolo" segue provisório. |
| 2026-10-29 | Sem Gemini: conceitos feitos aqui em 3D por código. Quiz de identidade publicado. |
| 2026-10-29 | Comparar 3 mundos na prancha de personagens antes de fechar (Neon, Festival Infernal, Malditos). |
| 2026-10-29 | Quiz 1 rejeitado (fofo demais). Quiz 2: direção v1 = Clãs de Neon com lado sombrio, Máscara Oni + espíritos, Brawl Stars 1:3, noite neon. |
