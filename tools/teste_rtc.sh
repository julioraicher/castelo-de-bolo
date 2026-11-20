#!/bin/bash
# Teste da conexão automática (Ciclo 2.28c): anfitrião cria a sala por código
# e o amigo entra pelo código, ligando por WebRTC. Os recados vão por uma pasta
# (--sinal-dir) em vez do ntfy.sh, para rodar sem internet; a ligação em si é
# WebRTC de verdade (ICE em 127.0.0.1). Sai 1 se não ligar ou divergir.
# Com "internet" no 3º argumento usa o ntfy.sh e STUN de verdade (código sorteado).
# Precisa de tools/baixar_webrtc.sh antes. Uso: tools/teste_rtc.sh [quadros=5000] [godot=godot] [internet]
Q=${1:-5000}; GODOT=${2:-godot}; MODO=${3:-local}
cd "$(dirname "$0")/.."
. tools/lib/sinc.sh
pasta_temporaria
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
timeout 900 "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$Q" -- --autoplay --sinc --criar-sala-teste=2 --codigo="$COD" "$SINAL" --nome=Anfitriao > "$T/h.txt" 2>&1 &
H=$!
sleep 3
timeout 900 "$GODOT" --headless --path . --fixed-fps 37 --quit-after "$Q" -- --autoplay --sinc --entrar="$COD" "$SINAL" --nome=Amigo > "$T/c.txt" 2>&1
wait $H
rm -rf "$SD"
pega_sinc "$T/h.txt" > "$T/h_sinc.txt"
pega_sinc "$T/c.txt" > "$T/c_sinc.txt"
compara_sinc "$T/h_sinc.txt" "$T/c_sinc.txt"; n=$SINC_N
grep "^REDE partida" "$T/h.txt" "$T/c.txt"
if grep -E "SCRIPT ERROR|DESSINC" "$T/h.txt" "$T/c.txt"; then echo "RTC: erro de script ou dessincronia"; exit 1; fi
if [ "$n" -lt 10 ]; then echo "RTC: a partida online quase não rodou ($n resumos)"; tail -20 "$T/c.txt"; exit 1; fi
if [ -n "$SINC_DIF" ]; then echo "RTC: estados diferentes:"; echo "$SINC_DIF"; exit 1; fi
rm -rf "$T"
echo "RTC OK: $n resumos iguais (ligação WebRTC por código)"
