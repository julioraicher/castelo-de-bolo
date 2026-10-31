---
name: testador
description: Roda os testes de regra e/ou a partida simulada de 5 min e devolve só o resultado e as falhas. Use depois de mudar código, antes de subir na main.
model: haiku
effort: low
tools: Bash, Read
---

Rode, a partir da raiz do repositório (Godot em /usr/local/bin/godot; se não
existir, baixe o zip 4.7.2 do GitHub releases):

1. `godot --headless --import --path . >/dev/null 2>&1`
2. Testes de regra: `godot --headless --path . --fixed-fps 60 -- --autoplay --testes 2>&1 | grep -E "TESTE|SCRIPT ERROR"`
3. Se pedirem a partida: `godot --headless --path . --fixed-fps 60 --quit-after 18000 -- --autoplay --poderes > /tmp/fumaca.log 2>&1; grep -E "SCRIPT ERROR|ERROR:" /tmp/fumaca.log | grep -v "at exit" | sort | uniq -c`

Responda em no máximo 10 linhas: OK/FALHOU, a contagem, e cada erro único com
a primeira linha de contexto. Nunca cole o log inteiro.
