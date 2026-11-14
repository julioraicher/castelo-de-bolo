#!/bin/bash
# Teste de queda e de dessincronia (Ciclo 2.28d). Anfitrião e amigo ligam por
# código (WebRTC, recados por pasta) e, no quadro 900, o amigo:
#   queda   -> derruba a ligação: tem de voltar SOZINHO para a sala quando o
#              anfitrião voltar (aqui ele volta 6 s depois), e jogar de novo;
#   dessinc -> mexe no próprio estado: os dois têm de ver o aviso e voltar
#              para a sala em 5 s, e a partida nova tem de bater.
# Sai 1 se algo não acontecer. Uso: tools/teste_queda.sh [queda|dessinc] [quadros=9000] [godot=godot]
MODO=${1:-queda}; Q=${2:-9000}; GODOT=${3:-godot}
cd "$(dirname "$0")/.."
SD=$(mktemp -d); H=/tmp/queda_${MODO}_h.txt; C=/tmp/queda_${MODO}_c.txt
[ "$MODO" = "dessinc" ] && GATILHO="--dessinc-teste=900" || GATILHO="--cair-teste=900"
timeout 900 "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$Q" -- --autoplay --sinc --criar-sala-teste=2 --recomecar-teste --codigo=18A1-WA26 --sinal-dir="$SD" --nome=Anfitriao > "$H" 2>&1 &
P=$!
sleep 3
timeout 900 "$GODOT" --headless --path . --fixed-fps 37 --quit-after "$Q" -- --autoplay --sinc --entrar=18A1-WA26 --sinal-dir="$SD" --nome=Amigo $GATILHO > "$C" 2>&1
wait $P
rm -rf "$SD"
falha() { echo "QUEDA ($MODO) FALHOU: $1"; grep -hE "^REDE|^DESSINC|SCRIPT ERROR" "$H" | sed 's/^/  anfitrião: /' | head -12; grep -hE "^REDE|^DESSINC|SCRIPT ERROR" "$C" | sed 's/^/  amigo: /' | head -12; exit 1; }
grep -q "SCRIPT ERROR" "$H" "$C" && falha "erro de script"
[ "$(grep -c '^REDE partida' "$H")" -ge 2 ] || falha "o anfitrião não começou a segunda partida"
[ "$(grep -c '^REDE partida' "$C")" -ge 2 ] || falha "o amigo não voltou para a segunda partida"
if [ "$MODO" = "dessinc" ]; then
  grep -q "^DESSINC" "$H" || falha "o anfitrião não percebeu a dessincronia"
  grep -q "^DESSINC" "$C" || falha "o amigo não recebeu o aviso"
  grep -q "^REDE sala" "$C" || falha "o amigo não voltou para a sala"
else
  grep -q "^REDE voltou" "$C" || falha "o amigo não voltou sozinho para a sala"
fi
# Segunda partida: o resumo tem de bater.
seg() { awk '/^REDE partida/{n++} n>=2' "$1" | grep "^SINC " | awk '{ if ($2 + 0 <= ult) exit; ult = $2 + 0; print }' ult=-1; }
seg "$H" > /tmp/queda_h_sinc.txt; seg "$C" > /tmp/queda_c_sinc.txt
nh=$(wc -l < /tmp/queda_h_sinc.txt); nc=$(wc -l < /tmp/queda_c_sinc.txt); n=$(( nh < nc ? nh : nc ))
[ "$n" -ge 5 ] || falha "a segunda partida quase não rodou ($n resumos)"
dif=$(diff <(head -n "$n" /tmp/queda_h_sinc.txt) <(head -n "$n" /tmp/queda_c_sinc.txt) | head -2)
[ -z "$dif" ] || falha "a segunda partida não bate: $dif"
echo "QUEDA OK ($MODO): voltaram para a sala e a partida nova bate ($n resumos)"
