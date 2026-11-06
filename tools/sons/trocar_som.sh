#!/usr/bin/env bash
# Troca um som do jogo por 1 ou mais arquivos (vira <nome>.ogg, <nome>_2.ogg, ...).
# Uso:   tools/sons/trocar_som.sh <nome> <arquivo> [arquivo2 ...] [--vol=-3] [--corte=0.6]
#        tools/sons/trocar_som.sh --voltar <nome>     (apaga os .ogg; volta ao .wav sintetizado)
#        tools/sons/trocar_som.sh --lista             (nomes que o jogo usa)
# Cada arquivo: tira silêncio do início, normaliza volume (pico -2 dB, + --vol), corta em
# --corte segundos se pedido, converte para .ogg mono 44,1 kHz. Nomes válidos: SOUNDS em
# scripts/autoload/sfx.gd. Depois rode: godot --headless --import --path .
set -euo pipefail
cd "$(dirname "$0")/../.."
AUD=assets/audio
nomes() { python3 -c "import re;s=open('scripts/autoload/sfx.gd').read();print('\\n'.join(re.findall(r'\"([a-z_]+)\"',re.search(r'const SOUNDS := \[(.*?)\]',s,re.S).group(1))))"; }

if [[ "${1:-}" == "--lista" ]]; then nomes | tr '\n' ' '; echo; exit 0; fi
if [[ "${1:-}" == "--voltar" ]]; then
  rm -f "$AUD/$2".ogg "$AUD/$2".ogg.import "$AUD/$2"_[0-9].ogg "$AUD/$2"_[0-9].ogg.import
  echo "$2: voltou ao $AUD/$2.wav"; exit 0
fi

NOME=${1:?nome do som}; shift
nomes | grep -qx "$NOME" || { echo "nome '$NOME' não existe no jogo. Use --lista."; exit 1; }
VOL=0; CORTE=""; ARQS=()
for a in "$@"; do
  case $a in --vol=*) VOL=${a#--vol=};; --corte=*) CORTE=${a#--corte=};; *) ARQS+=("$a");; esac
done
[[ ${#ARQS[@]} -gt 0 ]] || { echo "faltou o arquivo"; exit 1; }
rm -f "$AUD/$NOME".ogg "$AUD/$NOME"_[0-9].ogg "$AUD/$NOME".ogg.import "$AUD/$NOME"_[0-9].ogg.import
i=1
for f in "${ARQS[@]}"; do
  out="$AUD/$NOME.ogg"; [[ $i -gt 1 ]] && out="$AUD/${NOME}_$i.ogg"
  pico=$(ffmpeg -hide_banner -i "$f" -af volumedetect -f null - 2>&1 | grep -oE 'max_volume: -?[0-9.]+' | grep -oE -- '-?[0-9.]+' || echo 0)
  ganho=$(python3 -c "print(-2 - ($pico) + ($VOL))")
  filtro="silenceremove=start_periods=1:start_threshold=-50dB,volume=${ganho}dB"
  [[ -n "$CORTE" ]] && filtro="$filtro,atrim=0:$CORTE,afade=t=out:st=$(python3 -c "print(max(0,$CORTE-0.05))"):d=0.05"
  ffmpeg -loglevel error -y -i "$f" -af "$filtro" -ac 1 -ar 44100 -c:a libvorbis -q:a 5 "$out"
  echo "$out  <- $f"
  i=$((i+1))
done
