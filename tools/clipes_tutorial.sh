#!/usr/bin/env bash
# Grava os clipes do "Como jogar" (cenas roteirizadas de scripts/ui/clipe_cenas.gd)
# direto em assets/tutorial/<cena>/NN.jpg. Precisa de xvfb.
#   tools/clipes_tutorial.sh                 -> todas as cenas e todas as classes
#   tools/clipes_tutorial.sh objetivo torreta classe:guerreiro
# No fim importa os quadros e troca para compressão com perda (WebP): sem
# perda cada quadro virava ~100 KB no jogo exportado (1.400 quadros = 147 MB).
set -e
cd "$(dirname "$0")/.."
CENAS="objetivo controles madeira oficinas heroi torreta catapulta luz_sombra"
CLASSES="guerreiro ronin_oni sohei arqueiro arqueiro_yumi kusarigama kitsune kitsune_luz kitsune_sombria
  construtor armadilheiro bombardeiro sumotori kappa yamabushi karasu_tengu mujina onmyoji tennin komuso ochimusha shishimai jorogumo
  kodama kaminari_kozo predero"
LISTA="${*:-$CENAS $(for c in $CLASSES; do echo -n "classe:$c "; done)}"
for cena in $LISTA; do
  pasta="assets/tutorial/${cena/classe:/classe_}"
  n=40; [[ "$cena" == classe:* ]] && n=56
  # Vitrines (classes, controles, Luz e Sombra) no mapa leve do modo teste: fundo limpo.
  modo=""; case "$cena" in classe:*|controles|luz_sombra|heroi) modo="--sandbox";; esac
  mkdir -p "$pasta"
  rm -f "$pasta"/*.jpg "$pasta"/*.jpg.import
  timeout 600 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
    --rendering-method gl_compatibility --audio-driver Dummy --resolution 800x450 --fixed-fps 60 \
    -- --autoplay $modo --clipe="$pasta" --cena="$cena" --clipe-n=$n 2>&1 | grep -E "SCRIPT ERROR|At:" | head -4 || true
  echo "$cena: $(ls "$pasta" | wc -l) quadros, $(du -sh "$pasta" | cut -f1)"
done
godot --headless --import --path . >/dev/null 2>&1 || true
sed -i 's/^compress\/mode=0/compress\/mode=1/' assets/tutorial/*/*.import
godot --headless --import --path . >/dev/null 2>&1 || true
echo "importado (compressão com perda): $(grep -h '^path=' assets/tutorial/*/*.import | sed 's/path="res:\/\///;s/"//' | xargs du -cb | tail -1)"
