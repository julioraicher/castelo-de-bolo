#!/bin/bash
# Teste da conexão automática (Ciclo 2.28c): anfitrião cria a sala por código
# e o amigo entra pelo código, ligando por WebRTC. Os recados vão por uma pasta
# (--sinal-dir) em vez do ntfy.sh, para rodar sem internet; a ligação em si é
# WebRTC de verdade (ICE em 127.0.0.1). Sai 1 se não ligar ou divergir.
# Com "internet" no 3º argumento usa o ntfy.sh e STUN de verdade (código sorteado).
# Precisa de tools/baixar_webrtc.sh antes. Uso: tools/teste_rtc.sh [quadros=5000] [godot=godot] [internet]
Q=${1:-5000}; GODOT=${2:-godot}; MODO=${3:-local}
cd "$(dirname "$0")/.."
SD=$(mktemp -d)
COD="18A1-WA26"; SINAL="--sinal-dir=$SD"
if [ "$MODO" = "internet" ]; then
  COD=$(python3 -c "
import random
A='0123456789ABCDEFGHJKMNPQRSTVWXYZ'
n=random.getrandbits(32); c=0x5A
for i in range(4): c=(c*31+((n>>(8*i))&255))&255
n=(n<<8)|c; o=''
for i in range(8): o=A[n&31]+o; n>>=5
print(o[:4]+'-'+o[4:])")
  SINAL="--rede-real"
fi
timeout 900 "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$Q" -- --autoplay --sinc --criar-sala-teste=2 --codigo="$COD" "$SINAL" --nome=Anfitriao > /tmp/rtc_h.txt 2>&1 &
H=$!
sleep 3
timeout 900 "$GODOT" --headless --path . --fixed-fps 37 --quit-after "$Q" -- --autoplay --sinc --entrar="$COD" "$SINAL" --nome=Amigo > /tmp/rtc_c.txt 2>&1
wait $H
rm -rf "$SD"
pega() { sed -n '/^REDE partida/,$p' "$1" | grep "^SINC " | awk '{ if ($2 + 0 <= ult) exit; ult = $2 + 0; print }' ult=-1; }
pega /tmp/rtc_h.txt > /tmp/rtc_h_sinc.txt
pega /tmp/rtc_c.txt > /tmp/rtc_c_sinc.txt
nh=$(wc -l < /tmp/rtc_h_sinc.txt); nc=$(wc -l < /tmp/rtc_c_sinc.txt)
n=$(( nh < nc ? nh : nc ))
grep "^REDE partida" /tmp/rtc_h.txt /tmp/rtc_c.txt
if grep -E "SCRIPT ERROR|DESSINC" /tmp/rtc_h.txt /tmp/rtc_c.txt; then echo "RTC: erro de script ou dessincronia"; exit 1; fi
if [ "$n" -lt 10 ]; then echo "RTC: a partida online quase não rodou ($n resumos)"; tail -20 /tmp/rtc_c.txt; exit 1; fi
dif=$(diff <(head -n "$n" /tmp/rtc_h_sinc.txt) <(head -n "$n" /tmp/rtc_c_sinc.txt) | head -2)
if [ -n "$dif" ]; then echo "RTC: estados diferentes:"; echo "$dif"; exit 1; fi
echo "RTC OK: $n resumos iguais (ligação WebRTC por código)"
