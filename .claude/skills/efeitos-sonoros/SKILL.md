---
name: efeitos-sonoros
description: Use quando o Julio pedir para trocar, adicionar, ouvir ou gerar efeitos sonoros do Castelo de Bolo (golpe, poder, interface). Fluxo barato em tokens com biblioteca Kenney CC0 e geração por IA.
---

# Efeitos sonoros (Castelo de Bolo)

Trocar som = trocar arquivo. Nenhum código de jogo muda, então o gasto é só escolher.

## Como o jogo toca
- `scripts/autoload/sfx.gd` (autoload `Sfx`): `const SOUNDS` lista os nomes usados
  (`hit`, `swing`, `poder_boom`...). Carrega `assets/audio/<nome>.ogg`, senão `.wav`.
- Variações `<nome>_2.ogg` ... `_8.ogg` tocam sorteadas, com pitch variando (`play()`).
- Som novo (nome que não existe): pôr o nome em `SOUNDS` e chamar
  `Sfx.play("nome", posicao)` onde o evento acontece (frente de Jogabilidade).

## Fontes (já no repo / já liberadas na rede)
- `assets/audio/biblioteca/kenney/{impacto,interface,rpg}/`: 280 sons CC0 (Kenney Impact
  Sounds, Interface Sounds, RPG Audio). Tem `.gdignore`: não entra no jogo exportado.
- IA: `tools/sons/gerar_ia.py` salva em `assets/audio/biblioteca/ia/`.
  `--motor=stable` (Stable Audio Open, grátis, precisa `HF_TOKEN` nos segredos do ambiente)
  ou `--motor=eleven` (ElevenLabs, pago, precisa `ELEVENLABS_API_KEY`).
- Rede do ambiente já libera: kenney.nl (o site recusa downloads automáticos: use os
  espelhos do GitHub), opengameart.org, freesound.org (recusa robô; precisa da API com
  chave), o Space do Stable Audio e api.elevenlabs.io.

## Passo a passo (poucas chamadas)
1. Ouvir: `python3 tools/sons/catalogo.py /mnt/project-files/castelo-de-bolo/sons/catalogo-sons.html`
   e anexar o HTML para o Julio (filtro por nome, um player por som, caminho pronto).
2. Julio responde "hit = impact_punch_heavy_000, _001". Não ouvir por ele; se ele pedir
   sugestão, escolher pelo nome do arquivo (punch = soco, metal = espada, plate = armadura).
3. Aplicar: `tools/sons/trocar_som.sh hit <arq1> <arq2> [--vol=-3] [--corte=0.4]`
   (normaliza pico -2 dB, tira silêncio inicial, mono .ogg). Desfazer: `--voltar hit`.
4. `godot --headless --import --path .`, testes de regra e 5 min simulados, CHANGELOG
   com "O que testar" (ex.: "acerto de espada soa mais pesado").
5. Créditos: Kenney é CC0 (crédito opcional); som de outra fonte vai em
   `assets/audio/biblioteca/CREDITOS.md` com licença.

## Armadilhas
- `.ogg` precisa ser importado (passo 4) antes de rodar, senão o jogo cai no `.wav`.
- Volume: tudo sai em -2 dB de pico; som de UI costuma pedir `--vol=-6`.
- Música (`music.wav`) não passa por aqui: o loop vem do `.import` (`loop_mode=2`).
