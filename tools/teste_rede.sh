#!/bin/bash
# Teste de rede de verdade (Ciclo 2.28): anfitrião e um amigo em dois
# processos, conectados por 127.0.0.1. Cada "humano" é um macaco de teste
# (Rede.macaco) e o amigo roda a 37 quadros/s. O resumo do estado (SINC) da
# parte online tem de bater nos dois. Sai 1 se divergir ou não conectar.
# Uso: tools/teste_rede.sh [quadros=5000] [godot=godot] [extra...]
#   extra vai para os dois PCs (ex.: --classe=arqueiro_yumi: todo humano nasce Yumi)
Q=${1:-5000}; GODOT=${2:-godot}; shift $(( $# < 2 ? $# : 2 )); EXTRA="$*"  # shift 2 com menos de 2 args não tirava nada (TL-13)
cd "$(dirname "$0")/.."
. tools/lib/sinc.sh
pasta_temporaria
timeout 900 "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$Q" -- --autoplay --sinc --hospedar-teste=2 --nome=Anfitriao $EXTRA > "$T/h.txt" 2>&1 &
H=$!
sleep 3
timeout 900 "$GODOT" --headless --path . --fixed-fps 37 --quit-after "$Q" -- --autoplay --sinc --entrar=127.0.0.1 --nome=Amigo $EXTRA > "$T/c.txt" 2>&1
wait $H
# Só a partida online: para quando o tick volta (o anfitrião fechou e o amigo
# voltou para uma partida sozinho, que começa do zero).
pega_sinc "$T/h.txt" > "$T/h_sinc.txt"
pega_sinc "$T/c.txt" > "$T/c_sinc.txt"
compara_sinc "$T/h_sinc.txt" "$T/c_sinc.txt"; n=$SINC_N
grep "^REDE partida" "$T/h.txt" "$T/c.txt"
if grep -E "SCRIPT ERROR|DESSINC" "$T/h.txt" "$T/c.txt"; then echo "REDE: erro de script ou dessincronia"; exit 1; fi
if [ "$n" -lt 10 ]; then echo "REDE: a partida online quase não rodou ($n resumos)"; tail -20 "$T/c.txt"; exit 1; fi
if [ -n "$SINC_DIF" ]; then echo "REDE: estados diferentes:"; echo "$SINC_DIF"; exit 1; fi
rm -rf "$T"
echo "REDE OK: $n resumos iguais entre anfitrião e amigo $EXTRA"
