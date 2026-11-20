#!/usr/bin/env bash
# Prepara o Godot no CI (caça 2026-11-19, CI-02/CI-07): baixa a versão fixa,
# CONFERE o SHA-512 oficial (SHA512-SUMS.txt da release) e importa os assets.
# Com "templates", baixa também os modelos de exportação (conferidos).
# Uso: tools/ci_preparar_godot.sh [templates]
# Precisa de GODOT_VERSION, GODOT_SHA512 (e TEMPLATES_SHA512 com "templates").
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT_VERSION:?}" "${GODOT_SHA512:?}"
base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
tmp=$(mktemp -d)

z="Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
curl -sSfL -o "$tmp/$z" "$base/$z"
echo "$GODOT_SHA512  $tmp/$z" | sha512sum -c -
unzip -q -o "$tmp/$z" -d "$tmp"
mv "$tmp/Godot_v${GODOT_VERSION}-stable_linux.x86_64" ./godot
chmod +x ./godot

if [ "${1:-}" = "templates" ]; then
  : "${TEMPLATES_SHA512:?}"
  t="Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
  curl -sSfL -o "$tmp/$t" "$base/$t"
  echo "$TEMPLATES_SHA512  $tmp/$t" | sha512sum -c -
  d="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
  mkdir -p "$d"
  unzip -q -o "$tmp/$t" -d "$tmp"
  mv "$tmp"/templates/* "$d/"
  rm -f "$tmp/$t"
fi
rm -rf "$tmp"

bash tools/baixar_webrtc.sh

# Importar: o 1º import reclama de coisas do cache ainda vazio e sai com erro,
# então o código de saída não serve; confere o resultado.
./godot --headless --import --path . > import.log 2>&1 || true
n=$(find .godot/imported -type f 2>/dev/null | wc -l)
echo "import: $n arquivos em .godot/imported ($(wc -l < import.log) linhas de log)"
if [ "$n" -lt 1000 ]; then
  tail -40 import.log
  echo "::error::O import do Godot não gerou os assets."
  exit 1
fi
