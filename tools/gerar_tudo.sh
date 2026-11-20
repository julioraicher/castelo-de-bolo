#!/usr/bin/env bash
# Roda TODOS os geradores de modelos e dados na ordem certa (caça 2026-11-19, TL-01/02).
# Cada um usa ou sobrescreve o que o anterior gravou, então a ordem importa:
#   cenário (temas + peças) -> mapa do rio -> torretas/catapulta -> economia
#   (árvore, tora, depósito; liga nos temas) -> casas (barraquinhas e casas,
#   donas de maquina_<classe>) -> pavilhão dos heróis -> heróis (.tres) -> import.
# Uso: tools/gerar_tudo.sh [godot]      (padrão: godot do PATH)
# Para mexer numa peça só, rode o gerador dela e depois TODOS os que vêm depois.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${1:-godot}"
for g in gerar_cenario_ninja gerar_mapa_rio gerar_torretas gerar_economia gerar_casas gerar_pavilhao gerar_herois; do
  echo "== $g"
  log=$(mktemp)
  "$GODOT" --headless --path . -s "tools/$g.gd" > "$log" 2>&1 || true
  if grep -E "SCRIPT ERROR|Parse Error" "$log"; then
    echo "!! $g falhou (log: $log)"; exit 1
  fi
  tail -2 "$log"; rm -f "$log"
done
echo "== import"
"$GODOT" --headless --import --path . > /dev/null 2>&1 || true
echo "Pronto. Confira com: godot --headless --path . --fixed-fps 60 -- --autoplay --testes"
