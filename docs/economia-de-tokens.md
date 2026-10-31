# Economia de tokens

Como gastar menos do limite semanal do Julio sem perder qualidade. Baseado na
documentação oficial do Claude Code ([custos](https://code.claude.com/docs/en/costs),
[modelos e esforço](https://code.claude.com/docs/en/model-config)), lida em
2026-10-31.

## O que realmente gasta

Cada mensagem reenvia a conversa inteira (com cache, mais barato, mas não de
graça). Então o custo cresce com **tamanho do contexto × número de mensagens**.

| Gasta muito | Por quê |
|---|---|
| Thread longa e velha | Toda resposta relê o histórico; depois de ~1 h parada o cache esfria e relê a preço cheio |
| Mensagens entre threads | Cada aviso acorda outra thread, que relê todo o contexto dela |
| Ler arquivo grande inteiro | `unit.gd` (1.469 linhas), `gerar_mapa_rio.gd` (1.833), `gerar_cenario_ninja.gd` (1.258) |
| Log inteiro de partida no contexto | Milhares de linhas "mascara -> no castelo" |
| Modelo grande em tarefa simples | Opus/Fable custam várias vezes o Sonnet/Haiku |
| Esforço alto sem precisar | Raciocínio é cobrado como saída |
| Subagentes e "times" de agentes | Cada um tem contexto próprio (times: ~7x) |

Imagem é barata em comparação: ~largura × altura / 750 tokens (1280×720 ≈ 1.200).

## Modelo e esforço por papel (recomendação)

| Papel | Modelo | Esforço | Por quê |
|---|---|---|---|
| Coordenador (chat principal) | Sonnet | médio | Distribui e resume; pouco raciocínio fundo |
| Estagiário de ideias / direção | Opus | médio | Decisões de rumo, onde errar custa rodadas |
| Diretor de Jogabilidade (código, física, testes) | Sonnet | alto | Código do dia a dia; Opus só em bug cabeludo |
| Diretor Visual (geradores, shaders, pranchas) | Sonnet | médio/alto | Muito código repetitivo de modelagem |
| Radar de tendências, produtor de vídeo | Sonnet ou Haiku | baixo | Pesquisa e resumo |
| Subagentes de busca e teste (`.claude/agents/`) | Haiku | baixo | Já configurados: `explorador`, `testador` |
| Bug que ninguém achou, arquitetura nova | Opus ou Fable | alto | Exceção, por pedido |

## Regras para os agentes

1. **Arquivo grande: `explorador` ou Grep + leitura por trecho**, nunca inteiro.
2. **Testes e partida: `testador`**, ou filtre a saída (`grep TESTE`,
   `grep -E "SCRIPT ERROR|ERROR:" | sort | uniq -c`). Nunca cole log inteiro.
3. **CHANGELOG: leia só a entrada mais nova.** O antigo está em `docs/changelog-antigo.md`.
4. **Thread por ciclo, resolvida no fim.** Estado vai para o repo/memória; a
   próxima começa limpa em vez de arrastar contexto velho.
5. **Avise outra thread só quando o trabalho dela depende disso**, e numa
   mensagem só (não uma por detalhe).
6. **Pedido específico gasta menos que pedido vago:** "ajuste o dano do
   Samurai em `config/classes/guerreiro.tres`" em vez de "melhore o combate".
7. **Uma imagem por rodada**, JPG, até 1280 px no lado maior.
8. **CLAUDE.md abaixo de 200 linhas.** Instrução de fluxo específico vira skill
   (só carrega quando usada).
9. **Pesquisa na web:** modo padrão primeiro; o "extended" só se o padrão falhar.
10. **Nada de enxame/time de agentes** neste projeto (ver comparativo de repositórios).

## O que o Julio pode fazer

- No Claude Code do PC: `/usage` mostra o que mais gasta e sugere cortes;
  `/model` e `/effort` trocam modelo e esforço; `/clear` entre tarefas diferentes.
- Aqui no projeto: pedir "resolve as threads que acabaram" de vez em quando, e
  mandar feedback junto num áudio em vez de vários soltos.

## Checkup de 2026-10-31 (estagiário de economia)

### O modelo de custo, em uma linha

Uma thread com contexto inicial C₀ que cresce Δ por turno custa, em N turnos,
**Σ (C₀ + kΔ) ≈ N·C₀ + Δ·N²/2**. O termo quadrático manda: uma thread com 40
turnos custa ~4× o que duas de 20 custariam. Cache reduz o preço da releitura
(~10%), mas esfria depois de ~1 h parada: acordar thread velha paga cheio.
C₀ já é grande antes de qualquer conversa: prompt do sistema + lista de
ferramentas + skills + CLAUDE.md + índice da memória entram em **todo** turno.

### Onde o projeto gasta (medido no histórico das threads)

| # | Gasto | Evidência | Correção |
|---|---|---|---|
| 1 | Thread que muda de tarefa | "Estagiário de ideias" viveu 29 h e fez 3 tarefas (boas práticas, economia, Ciclo 2.3) carregando tudo | **Thread por tarefa**, não por papel. Fim da tarefa = estado no repo/memória e thread resolvida |
| 2 | Rodadas de ida e volta em quiz | Quiz em texto e depois o mesmo quiz em widget; respostas do widget não chegam ("já respondi tudo" = 1 rodada perdida) | Um quiz só, ≤5 perguntas, opção recomendada **já marcada**; silêncio = recomendado |
| 3 | "Uma pergunta por vez" (forjar-ideia) | Cada pergunta é um turno inteiro relendo o contexto | Blocos de 3-5 perguntas com hipótese pronta |
| 4 | Mesmo áudio longo copiado para várias threads | O coordenador anexa o áudio inteiro em cada thread acordada | Anexar só o trecho da área; cada thread recebe uma mensagem por rodada |
| 5 | Checkups repetidos | Economia de tokens auditada 2× no mesmo dia | Antes de auditar, ler este doc; checkup só quando o Julio pedir ou 1×/ciclo |
| 6 | Threads paradas abertas | "Redesenhar o cenário", "Definir identidade visual" (de 29/10, já superadas pelos ciclos) | Coordenador resolve as que acabaram; nada as acorda por engano |
| 7 | Imagens que ficam no contexto | Cada imagem (~1.200 tokens em 1280×720) é relida em todos os turnos seguintes | Gerar → conferir **uma** miniatura → anexar. Não reabrir PNG grande; prancha nova só por lote |
| 8 | Modelagem 3D por código | Geradores de 1.200-1.800 linhas | Editar por trecho (Grep + leitura de 80 linhas); peça nova = entrada de tabela/`.tres`, não função nova; render só no fim do lote |
| 9 | Lista fixa de ferramentas | Plugins *data* e *engineering* + Notion carregam dezenas de ferramentas/skills que este projeto não usa, em todo turno | Julio desliga o que não usa (ver abaixo) |

### Regras novas (somam às 10 de cima)

11. **Thread por tarefa.** Pedido novo e sem relação = thread nova (barata),
    não a continuação de uma thread grande. Ao terminar: estado no repo/memória,
    resolver.
12. **Quiz econômico:** um formato só (widget clicável), ≤5 perguntas, cada uma
    com a recomendada pré-marcada e comentário opcional. Na mesma mensagem:
    "se não responder, sigo com as marcadas". Quem pergunta já segue trabalhando
    na recomendada.
13. **Pergunta só quando muda o rumo.** Detalhe reversível: decidir, fazer e
    dizer o que escolheu. Escolha de rumo: `request_decision` (1 clique, chega
    de volta) em vez de quiz.
14. **Resposta curta por padrão:** resultado primeiro, ≤10 linhas; o resto num
    arquivo/doc anexado. Checklist em vez de mensagens de "andamento".
15. **Mensagem entre threads = uma por rodada**, com só o trecho relevante.
    Recado sem pressa pega carona na próxima mensagem que já ia ser mandada.
16. **Lotes grandes (peças 3D, mapa, efeitos):** combinar o lote inteiro antes,
    gerar tudo, uma prancha no fim. Não mandar prancha a cada peça.
17. **Coordenador** responde em ≤5 linhas, não repete o que a thread já disse,
    e a cada pedido de Julio confere a tabela de modelo/esforço antes de abrir
    thread.

### O que só o Julio pode fazer

- Desligar conectores e plugins sem uso neste projeto (Notion, plugins
  *data* e *engineering*): menos ferramentas em todo turno de toda thread.
- Mandar o feedback de uma rodada num áudio só, em vez de vários soltos.
- Responder quiz pelo clique **e colar** o texto copiado (o widget não envia
  sozinho).
