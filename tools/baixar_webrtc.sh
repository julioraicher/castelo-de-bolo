#!/bin/bash
# Extensão WebRTC oficial do Godot (github.com/godotengine/webrtc-native), usada
# pela conexão automática do multiplayer (Ciclo 2.28c). Versão FIXA e conferida
# pelo SHA-256: se o arquivo do GitHub mudar, o build para em vez de usar outro.
# Só as bibliotecas de Windows e Linux x86_64 entram (lib/ fica fora do git).
# Uso: tools/baixar_webrtc.sh
set -euo pipefail
VERSAO="1.2.2-stable"
SHA="98e9446921740d995bd9ca1be48798dc3c2ceed51e044a25ce18b3cff11f56e5"
cd "$(dirname "$0")/.."
destino="addons/webrtc_native/lib"
if [ -f "$destino/.versao" ] && [ "$(cat "$destino/.versao")" = "$VERSAO" ]; then
  echo "WebRTC $VERSAO já está aqui."; exit 0
fi
tmp=$(mktemp -d)
curl -sSfL -o "$tmp/w.zip" "https://github.com/godotengine/webrtc-native/releases/download/$VERSAO/godot-extension-webrtc_native.zip"
echo "$SHA  $tmp/w.zip" | sha256sum -c -
mkdir -p "$destino"
for f in linux.template_debug.x86_64.so linux.template_release.x86_64.so \
         windows.template_debug.x86_64.dll windows.template_release.x86_64.dll; do
  unzip -o -j -q "$tmp/w.zip" "addons/webrtc_native/lib/libwebrtc_native.$f" -d "$destino"
done
echo "$VERSAO" > "$destino/.versao"
rm -rf "$tmp"
echo "WebRTC $VERSAO instalado em $destino"
