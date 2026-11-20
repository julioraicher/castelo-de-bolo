# shellcheck shell=bash
# Funções comuns dos testes de multiplayer (revisão 2026-11-19, TL-14): antes o bloco
# "pega o SINC e compara" estava copiado em 3 scripts, com arquivos fixos em /tmp (o que
# impedia rodar dois testes ao mesmo tempo). Uso: . "$(dirname "$0")/lib/sinc.sh"

# pega_sinc LOG [N]: linhas "SINC tick hash" da N-ésima partida online do LOG (padrão 1),
# até o tick voltar para trás (o processo começou outra partida sozinho).
pega_sinc() {
  awk -v alvo="${2:-1}" '/^REDE partida/{n++} n>=alvo' "$1" | grep "^SINC " \
    | awk '{ if ($2 + 0 <= ult) exit; ult = $2 + 0; print }' ult=-1
}

# compara_sinc A B: compara as primeiras SINC_N linhas dos dois (SINC_N = a menor
# contagem). Falha (código 1) com a 1ª diferença em SINC_DIF.
compara_sinc() {
  local na nb
  na=$(wc -l < "$1"); nb=$(wc -l < "$2")
  SINC_N=$(( na < nb ? na : nb ))
  SINC_DIF=$(diff <(head -n "$SINC_N" "$1") <(head -n "$SINC_N" "$2") | head -2)
  [ -z "$SINC_DIF" ]
}

# pasta_temporaria: cria a pasta dos logs deste teste; some sozinha se o teste passar.
pasta_temporaria() {
  T=$(mktemp -d)
}
