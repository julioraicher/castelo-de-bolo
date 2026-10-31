# Princípios do projeto

O que **não muda** sem o Julio dizer. Qualquer agente lê isto antes de mexer
(ideia da "constituição" do Spec Kit, adaptada). Se uma regra mudar, troque
aqui e anote no CHANGELOG.

1. **A `main` é a versão de teste e está sempre jogável.** Coisa nova vai num
   branch; entra na main com o "aprovado" do Julio ou estável (testes de regra
   + 5 min simulados sem erro, os dois no CI).
2. **Toda entrega na main tem "O que testar"** na entrada do CHANGELOG.
3. **Conteúdo é dado.** Classes, temas e mapas são `.tres`; código só monta o
   que os dados descrevem. Campo novo = campo no esquema com padrão que não
   quebra os arquivos existentes.
4. **Cérebro decide, corpo executa.** IA e jogador só preenchem intenções;
   `unit.gd` aplica as regras.
5. **Sensação aprovada não se mexe:** dash/esquiva como está, ritmo rápido.
6. **Orçamento de desempenho:** o PC do Julio é Intel UHD integrada. Mudança
   visual mede antes/depois (`--perf`, `--vista=mapa`); limite de ~10% a menos
   na qualidade Média.
7. **Direção visual atual:** `docs/direcao-ciclo-2.2.md` (pintado estilo Fat
   Princess PS3, tom sombrio, poder no corpo, ~3,5 cabeças).
8. **Rodadas curtas:** uma imagem por rodada, feedback por número/letra.
9. **Ideias não escolhidas vão para `docs/ideias.md`** (A/B/C); nada sobe sem o
   Julio escolher.
10. **Explicar com a física por trás** quando houver (impulso, decaimento,
    Nyquist...).
11. **Git:** `git pull --rebase origin main` antes de push; nunca force push.
12. **Economia de tokens:** seguir `docs/economia-de-tokens.md` (modelo por
    papel, arquivos grandes por trecho, logs filtrados).
