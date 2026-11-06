#!/bin/bash
# Sonda de equilíbrio: 8 partidas simuladas de 5 min com todas as classes
# (--variacoes=0..7: cada classe passa por todos os papéis de bot, ataque e defesa),
# 4 em paralelo. Soma mortes e abates por classe. Uso: tools/sonda_equilibrio.sh [PASTA]
D=${1:-/tmp/sonda}; rm -rf "$D"; mkdir -p "$D"; cd "$(dirname "$0")/.."
for lote in "0 1 2 3" "4 5 6 7"; do
  for o in $lote; do
    (timeout 400 godot --headless --path . --fixed-fps 60 --quit-after 18000 -- \
      --autoplay --variacoes=$o --equilibrio > "$D/r$o.log" 2>&1) &
  done
  wait
done
cat "$D"/r*.log | grep "^ABATE" | awk '{d[$2]++; if($3!="nada") k[$3]++}
  END{for(c in d) printf "%-16s mortes %3d abates %3d  K/D %.2f\n", c, d[c], k[c]+0, (k[c]+0)/d[c]}' | sort
echo "pontos nas 8 partidas: $(grep -h PONTO "$D"/r*.log | wc -l)"
# Por minuto vivo (Ciclo 2.10): abates, dano causado e cura dada. Mede a
# utilidade de quem tanka ou cura, que o K/D sozinho esconde.
for f in "$D"/r*.log; do grep "^RESUMO" "$f" | awk '{u[$2]=$0} END{for(c in u) print u[c]}'; done > "$D/resumos.txt"
cat "$D"/r*.log | grep "^ABATE" | awk '$3!="nada"{print "K", $3}' > "$D/abates.txt"
cat "$D/resumos.txt" "$D/abates.txt" | awk '$1=="RESUMO"{d[$2]+=$3; c[$2]+=$4; v[$2]+=$5} $1=="K"{k[$2]++}
  END{printf "%-16s %8s %8s %8s %8s\n", "por min vivo", "abates", "dano", "cura", "min"; for(x in v) if(v[x]>0) printf "%-16s %8.2f %8.0f %8.0f %8.0f\n", x, k[x]*60/v[x], d[x]*60/v[x], c[x]*60/v[x], v[x]/60}' | sort
