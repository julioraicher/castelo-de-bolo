#!/usr/bin/env bash
# Vitrine dos poderes: mesmo roteiro (3 ataques, Q, E) para cada classe, com
# câmera fixa. Uso:
#   tools/vitrine.sh SAIDA [classe ...]           -> SAIDA/<classe>/f_*.png
#   tools/vitrine.sh --gif ANTES DEPOIS SAIDA     -> SAIDA/<classe>.gif (lado a lado)
# Para o "antes": git worktree add /tmp/antes <commit>, rode lá e compare.
set -e
CLASSES_PADRAO="guerreiro ronin_oni arqueiro arqueiro_yumi bombardeiro armadilheiro construtor kitsune kitsune_luz kitsune_sombria"
if [ "$1" = "--gif" ]; then
  A="$2"; D="$3"; OUT="$4"; mkdir -p "$OUT"
  for dir in "$D"/*/; do
    c=$(basename "$dir")
    [ -d "$A/$c" ] || continue
    ffmpeg -loglevel error -y -framerate 20 -i "$A/$c/f_%03d.png" -framerate 20 -i "$D/$c/f_%03d.png" \
      -filter_complex "[0]scale=400:-2,drawtext=text='ANTES':x=8:y=6:fontsize=18:fontcolor=white:borderw=2[a];[1]scale=400:-2,drawtext=text='DEPOIS':x=8:y=6:fontsize=18:fontcolor=white:borderw=2[b];[a][b]hstack,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=4" \
      "$OUT/$c.gif"
    echo "$OUT/$c.gif"
  done
  exit 0
fi
OUT="$1"; shift
CLASSES="${*:-$CLASSES_PADRAO}"
for c in $CLASSES; do
  mkdir -p "$OUT/$c"
  rm -f "$OUT/$c"/f_*.png
  timeout 600 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
    --rendering-method gl_compatibility --audio-driver Dummy --resolution 800x450 --fixed-fps 60 \
    -- --autoplay --classe="$c" --vitrine="$OUT/$c" 2>&1 | grep -E "SCRIPT ERROR" | head -3 || true
  echo "$c: $(ls "$OUT/$c" | wc -l) quadros"
done
