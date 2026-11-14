#!/bin/bash
# Teste de rede de verdade (Ciclo 2.28): anfitrião e um amigo em dois
# processos, conectados por 127.0.0.1. Cada "humano" é um macaco de teste
# (Rede.macaco) e o amigo roda a 37 quadros/s. O resumo do estado (SINC) da
# parte online tem de bater nos dois. Sai 1 se divergir ou não conectar.
# Uso: tools/teste_rede.sh [quadros=5000] [godot=godot] [extra...]
#   extra vai para os dois PCs (ex.: --classe=arqueiro_yumi: todo humano nasce Yumi)
Q=${1:-5000}; GODOT=${2:-godot}; shift 2 2>/dev/null; EXTRA="$*"
cd "$(dirname "$0")/.."
timeout 900 "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$Q" -- --autoplay --sinc --hospedar-teste=2 --nome=Anfitriao $EXTRA > /tmp/rede_h.txt 2>&1 &
H=$!
sleep 3
timeout 900 "$GODOT" --headless --path . --fixed-fps 37 --quit-after "$Q" -- --autoplay --sinc --entrar=127.0.0.1 --nome=Amigo $EXTRA > /tmp/rede_c.txt 2>&1
wait $H
# Só a partida online: para quando o tick volta (o anfitrião fechou e o amigo
# voltou para uma partida sozinho, que começa do zero).
pega() { sed -n '/^REDE partida/,$p' "$1" | grep "^SINC " | awk '{ if ($2 + 0 <= ult) exit; ult = $2 + 0; print }' ult=-1; }
pega /tmp/rede_h.txt > /tmp/rede_h_sinc.txt
pega /tmp/rede_c.txt > /tmp/rede_c_sinc.txt
nh=$(wc -l < /tmp/rede_h_sinc.txt); nc=$(wc -l < /tmp/rede_c_sinc.txt)
n=$(( nh < nc ? nh : nc ))
grep "^REDE partida" /tmp/rede_h.txt /tmp/rede_c.txt
if grep -E "SCRIPT ERROR|DESSINC" /tmp/rede_h.txt /tmp/rede_c.txt; then echo "REDE: erro de script ou dessincronia"; exit 1; fi
if [ "$n" -lt 10 ]; then echo "REDE: a partida online quase não rodou ($n resumos)"; tail -20 /tmp/rede_c.txt; exit 1; fi
dif=$(diff <(head -n "$n" /tmp/rede_h_sinc.txt) <(head -n "$n" /tmp/rede_c_sinc.txt) | head -2)
if [ -n "$dif" ]; then echo "REDE: estados diferentes:"; echo "$dif"; exit 1; fi
echo "REDE OK: $n resumos iguais entre anfitrião e amigo $EXTRA"
