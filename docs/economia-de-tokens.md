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
