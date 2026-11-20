# Comandos (referência completa)

O CLAUDE.md guarda só os do dia a dia; o resto fica aqui. Godot não vem no
container: baixe o zip 4.7.2 do GitHub releases para `/usr/local/bin/godot`
(no CI, `tools/ci_preparar_godot.sh` baixa e confere o SHA-512).

## Checagens (as mesmas do CI)

```bash
tools/checar.sh regras    # testes de regra (semente 1234), auditoria da interface, varreduras de Q/E/R
tools/checar.sh partida   # 5 min simulados, sincronia 60 x 23 FPS, QA do mapa (só avisa)
tools/checar.sh rede      # rede local, sala por código (WebRTC), queda e dessincronia
tools/checar.sh tudo      # os três (~5 min). GODOT=..., SEMENTE=N, CHECAR_LOGS=DIR
```

Qualquer `SCRIPT ERROR`/`Parse Error` reprova, mesmo com saída 0 (na 4.7 o erro
aborta só a função). Os testes também contam erros pelo `tests/contador_erros.gd`.

## Godot direto

```bash
# Depois de criar um script com class_name novo (senão "Identifier not declared"):
godot --headless --import --path .
# Testes de regra (dano, carregador, esquiva, escudo, cura, empurrão, dados, esquema
# das classes, glifos da fonte); sai 0/1. A semente sai no começo: repita com ela.
godot --headless --path . --fixed-fps 60 -- --autoplay --testes --semente=1234
# Partida simulada sem janela (bots jogam pelo jogador; eventos no stdout):
godot --headless --path . --fixed-fps 60 --quit-after 18000 -- --autoplay
# Arena de chapéus (Ciclo 2.29, 3º modo do menu; --arena / ?arena): QA sem teclado,
# o Tambor de Desafio toca sozinho a cada N s e gera inimigos:
godot --headless --path . --fixed-fps 60 --quit-after 7200 -- --autoplay --arena-prova=8
# Varredura de poderes (2.29b): Q, E e R de todas as classes com inimigo alinhado; sai 0/1.
#   VARREDURA_SO=id1,id2 filtra; --varredura-perto=N muda a distância. Poder novo
#   que não fere de propósito = entrada em POR_DESENHO (tests/varredura_poderes.gd).
godot --headless --path . --fixed-fps 60 -- --autoplay --varredura-poderes
# Varredura de aliados (cura/escudo/buff chegam em quem devem; ESPERADO em tests/varredura_aliados.gd):
godot --headless --path . --fixed-fps 60 -- --autoplay --varredura-aliados
# Interface (2.33): texto vazando/fora da tela/HUD sobreposto em 7 resoluções; sai 0/1.
#   Com DIR e xvfb também tira prints; --res=1280x720,1024x768 filtra; UI_DEBUG=1 lista blocos.
godot --headless --path . -s tools/auditoria_ui.gd -- --sandbox --sem-prints
# QA do mapa (passagem, escondidos da câmera, bots presos): qa_mapa.txt (+ .jpg com tela)
godot --headless --path . --fixed-fps 60 -- --qa-mapa=DIR
```

## Com tela (xvfb, renderizador do navegador)

```bash
GL='--rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy'
# Desempenho: PERF (fps, chamadas, tris, CPU por seção) + CENSO (passes por dono).
#   CENSO_DETALHE=Arena lista cada instância; MU_DEBUG=1 mostra os grupos da malha única.
#   O llvmpipe ignora MSAA e custo por pixel: compare chamadas/tris, nunca FPS.
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . $GL --quit-after 600 -- --autoplay --perf=3
# Prints da partida / de cada seção do menu e aba do Como jogar:
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . $GL -- --autoplay --shots=DIR
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . $GL -- --tutorial=DIR
# Chão/objeto piscando ao andar (z-fighting): pisca.jpg com o que muda em vermelho
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . $GL -- --autoplay --sandbox --pisca=DIR
# Prancha das finalizações (2.34):
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . $GL -- --prancha-finalizar=DIR
# Regravar os clipes dos menus: tools/clipes_tutorial.sh [cena|classe:id ...]
#   (classe nova = id em tools/lib/classes.sh; quadros importam com perda, ~12 KB cada)
```

## Geradores de modelos e dados

```bash
tools/gerar_tudo.sh [godot]   # TODOS na ordem certa + import (cada um usa o que o anterior gravou)
```

Ordem: `gerar_cenario_ninja` (temas + peças) → `gerar_mapa_rio` → `gerar_torretas`
→ `gerar_economia` (árvore, tora, depósito) → `gerar_casas` (barraquinhas, casas e
`maquina_<classe>`) → `gerar_pavilhao` → `gerar_herois` (.tres). Mexeu numa peça:
rode o gerador dela e todos os que vêm depois. Os geradores de `.tres` carregam o
arquivo existente e só trocam o que geram (campos novos, como `personalidade`, ficam).

## Multiplayer

```bash
tools/teste_sincronia.sh 90 7      # [segundos] [semente] [godot] [--variacoes ...]: mesmo SINC em 60 x 23 FPS
tools/teste_rede.sh 5000 godot --classe=arqueiro_yumi  # anfitrião + amigo (127.0.0.1), compara SINC
tools/teste_queda.sh queda|dessinc # amigo cai/separa: voltam para a sala e a partida nova bate
tools/baixar_webrtc.sh             # extensão WebRTC oficial (SHA-256 fixo); antes do import
tools/teste_rtc.sh 5000            # sala por código (WebRTC, recados por pasta); "internet" = ntfy real
```

## Outros

```bash
# Sons: trocar/ouvir/gerar efeitos = skill .claude/skills/efeitos-sonoros (tools/sons/)
# Equilíbrio por classe (8 partidas, mortes/abates por classe; HEROIS=1 para heróis):
tools/sonda_equilibrio.sh
# Exportar só os dados, sem templates, e inspecionar como no jogo publicado:
godot --headless --path . --export-pack "Linux" x.pck
godot --headless --main-pack x.pck -s diag.gd
```
