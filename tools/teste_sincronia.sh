#!/bin/bash
# Teste de sincronia (Ciclo 2.28, multiplayer em lockstep): duas partidas com
# a MESMA semente, uma a 60 quadros/s e outra a 23 (o ritmo de desenho muda,
# o de física não). Se as regras forem determinísticas, o resumo do estado
# (SINC) bate quadro a quadro. Diferença = algo nas regras depende do FPS, do
# relógio de parede ou de sorteio fora de Sorte. Sai 1 se divergir.
# Uso: tools/teste_sincronia.sh [segundos=90] [semente=7] [godot=godot] [extra...]
S=${1:-90}; SEM=${2:-7}; GODOT=${3:-godot}; shift $(( $# < 3 ? $# : 3 )); EXTRA="$*"  # shift 3 com menos de 3 args não tirava nada (TL-13)
cd "$(dirname "$0")/.."
. tools/lib/sinc.sh
pasta_temporaria
run() { timeout 1200 "$GODOT" --headless --path . --fixed-fps "$1" --quit-after $(( $1 * S )) -- --autoplay --semente="$SEM" --sinc $EXTRA 2>&1 | grep "^SINC " > "$T/$2.txt"; }
run 60 a & run 23 b & wait
n=$(wc -l < "$T/b.txt")
if [ "$n" -lt $(( S - 2 )) ]; then echo "SINCRONIA: poucas linhas ($n)"; exit 1; fi
dif=$(head -n "$n" "$T/a.txt" | diff - "$T/b.txt" | head -2)
if [ -n "$dif" ]; then echo "SINCRONIA FALHOU (semente $SEM):"; echo "$dif"; exit 1; fi
rm -rf "$T"
echo "SINCRONIA OK: $n resumos iguais ($S s, semente $SEM $EXTRA)"
