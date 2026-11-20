#!/usr/bin/env bash
# Checagens automáticas do jogo, em grupos (caça 2026-11-19: o MESMO script roda
# no CI e no agente testador, para "verde aqui" valer "verde lá").
#   tools/checar.sh regras   testes de regra (semente fixa), auditoria da interface, varreduras de poderes
#   tools/checar.sh partida  5 min simulados, sincronia 60 x 23 FPS, QA do mapa (só avisa)
#   tools/checar.sh rede     rede local, conexão por código (WebRTC), queda e dessincronia
#   tools/checar.sh tudo     os três, em sequência (~5 min)
# Variáveis: GODOT (padrão: godot), SEMENTE (padrão 1234), CHECAR_INTERNET=1 (teste RTC pelo
# ntfy.sh de verdade, só avisa), CHECAR_LOGS=DIR (guarda os logs).
# Qualquer "SCRIPT ERROR" ou "Parse Error" num passo do Godot reprova, mesmo com código de saída 0
# (na 4.7 o erro aborta só a função e o processo segue).
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
SEM="${SEMENTE:-1234}"
LOGS="${CHECAR_LOGS:-$(mktemp -d)}"
mkdir -p "$LOGS"
FALHAS=()
AVISOS=()

# rodar NOME TEMPO comando...: roda e guarda o log (e o código/tempo em LOG.rc).
# avaliar NOME: mostra o resumo e reprova com exit != 0 ou erro de script.
# passo = rodar + avaliar. Dois "rodar" em segundo plano + wait = passos em paralelo.
_log() { echo "$LOGS/$(echo "$1" | tr ' /' '__').log"; }
rodar() {
  local nome="$1" tempo="$2"; shift 2
  local log ini=$SECONDS
  log=$(_log "$nome")
  timeout "$tempo" "$@" > "$log" 2>&1
  echo "$? $((SECONDS - ini))" > "$log.rc"
}
avaliar() {
  local nome="$1" log rc dur
  log=$(_log "$nome")
  read -r rc dur < "$log.rc"
  echo "::group::$nome"
  grep -E "^(TESTES|VARREDURA FIM|ALIADOS FIM|SINCRONIA|REDE|RTC|QUEDA|DESSINC|SEMENTE|AUDITORIA|UI)" "$log" | tail -8
  if grep -qE "SCRIPT ERROR|Parse Error" "$log"; then
    grep -E -A3 "SCRIPT ERROR|Parse Error" "$log" | head -30
    rc=99
  fi
  if [ "$rc" -ne 0 ]; then
    tail -25 "$log"
    echo "::endgroup::"
    echo "::error::$nome falhou (código $rc, $dur s)"
    FALHAS+=("$nome")
  else
    echo "::endgroup::"
    echo "ok  $nome ($dur s)"
  fi
}
passo() {
  rodar "$@"
  avaliar "$1"
}

# aviso NOME TEMPO comando...: como passo, mas só avisa (depende de serviço de fora ou tem linha de base).
aviso() {
  local antes=${#FALHAS[@]}
  passo "$@"
  if [ ${#FALHAS[@]} -gt "$antes" ]; then
    unset 'FALHAS[-1]'
    AVISOS+=("$1")
    echo "::warning::$1 falhou (só aviso)"
  fi
}

regras() {
  passo "Testes de regra" 5m "$GODOT" --headless --path . --fixed-fps 60 -- --autoplay --testes --semente="$SEM"
  passo "Auditoria da interface" 15m "$GODOT" --headless --path . -s tools/auditoria_ui.gd -- --sandbox --sem-prints
  passo "Varredura de poderes (inimigo)" 15m "$GODOT" --headless --path . --fixed-fps 60 -- --autoplay --varredura-poderes --semente="$SEM"
  passo "Varredura de poderes (aliados)" 15m "$GODOT" --headless --path . --fixed-fps 60 -- --autoplay --varredura-aliados --semente="$SEM"
}

partida() {
  local log="$LOGS/fumaca.log" ini=$SECONDS
  echo "::group::Partida simulada de 5 min"
  timeout 20m "$GODOT" --headless --path . --fixed-fps 60 --quit-after 18000 -- --autoplay --poderes > "$log" 2>&1
  local rc=$?
  # Vazamento ao fechar ("still in use at exit") é do motor, não do jogo.
  if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$log" | grep -v "at exit"; then rc=99; fi
  echo "::endgroup::"
  if [ $rc -ne 0 ]; then tail -25 "$log"; echo "::error::Partida simulada falhou ($rc)"; FALHAS+=("Partida simulada"); else echo "ok  Partida simulada de 5 min ($((SECONDS - ini)) s)"; fi
  passo "Sincronia (mesma semente, 60 x 23 quadros/s)" 15m bash tools/teste_sincronia.sh 90 7 "$GODOT"
  qa_mapa
}

# QA do mapa (tests/qa_mapa.gd): só avisa; resumo no relatório do job.
qa_mapa() {
  local qa="$LOGS/qa"; rm -rf "$qa"
  timeout 10m "$GODOT" --headless --path . --fixed-fps 60 -- --qa-mapa="$qa" > "$LOGS/qa_mapa.log" 2>&1 || true
  if [ -f "$qa/qa_mapa.txt" ]; then
    cat "$qa/qa_mapa.txt"
    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
      { echo '### QA do mapa'; echo '```'; cat "$qa/qa_mapa.txt"; echo '```'; } >> "$GITHUB_STEP_SUMMARY"
    fi
    qa_novos "$qa/qa_mapa.txt"
  else
    echo "::warning::QA do mapa não gerou o relatório."
  fi
}

# Compara a linha "Por tipo: a N, b N, ..." com tests/qa_mapa_base.txt e avisa só do
# que piorou (TS-07: os mesmos ~477 de sempre viravam ruído em todo push).
qa_novos() {
  local tipos piorou=""
  tipos=$(sed -n 's/^Por tipo: //p' "$1" | tr ',' '\n' | sed 's/^ *//')
  while IFS= read -r par; do
    [ -z "$par" ] && continue
    local n="${par##* }" nome="${par% *}" base
    base=$(grep -v '^#' tests/qa_mapa_base.txt | grep "^$nome " | sed 's/.* //')
    base="${base:-0}"
    local folga=0
    [ "$nome" = "faces sobrepostas" ] && folga=2
    if [ "$n" -gt $((base + folga)) ]; then piorou="$piorou $nome $base -> $n;"; fi
  done <<< "$tipos"
  if [ -n "$piorou" ]; then
    echo "::warning::QA do mapa piorou:$piorou (base em tests/qa_mapa_base.txt)"
  else
    echo "QA do mapa: nada novo em relação à base (tests/qa_mapa_base.txt)"
  fi
}

rede() {
  passo "Rede local (anfitrião + amigo, humanos de Yumi)" 15m bash tools/teste_rede.sh 5000 "$GODOT" --classe=arqueiro_yumi
  passo "Conexão por código (WebRTC, recados por pasta)" 15m bash tools/teste_rtc.sh 5000 "$GODOT"
  # Queda e dessincronia ao mesmo tempo: cada um tem a sua pasta (TL-14), ~1 min a menos.
  rodar "Queda (o amigo cai e volta)" 15m bash tools/teste_queda.sh queda 9000 "$GODOT" &
  rodar "Dessincronia (todos voltam para a sala)" 15m bash tools/teste_queda.sh dessinc 9000 "$GODOT" &
  wait
  avaliar "Queda (o amigo cai e volta)"
  avaliar "Dessincronia (todos voltam para a sala)"
  if [ "${CHECAR_INTERNET:-0}" = "1" ]; then
    aviso "Conexão pela internet (ntfy.sh + STUN)" 15m bash tools/teste_rtc.sh 5000 "$GODOT" internet
  fi
}

case "${1:-tudo}" in
  regras) regras ;;
  partida) partida ;;
  rede) rede ;;
  tudo) regras; partida; rede ;;
  *) echo "uso: tools/checar.sh [regras|partida|rede|tudo]"; exit 2 ;;
esac

echo
[ ${#AVISOS[@]} -gt 0 ] && echo "Avisos: ${AVISOS[*]}"
if [ ${#FALHAS[@]} -gt 0 ]; then
  echo "FALHOU: ${FALHAS[*]} (logs em $LOGS)"
  exit 1
fi
echo "CHECAGENS OK (${1:-tudo}, semente $SEM, logs em $LOGS)"
