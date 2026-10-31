# Direção do Ciclo 2.3: Economia do Construtor

**Rascunho de 2026-10-31**, escrito pelo estagiário de ideias a partir de dois
áudios do Julio. As respostas do quiz clicável não chegaram, então valem as
opções recomendadas (seção 2). O Julio troca qualquer uma por letra.

## 1. A ideia, em palavras

O Construtor vira o **lenhador do time**: corta madeira ou bambu, leva para o
castelo e, de vez em quando, sobe o nível de uma casinha. Os chapéus deixam de
ser pedestais infinitos e passam a sair de **maquininhas animadas** que fabricam
o chapéu com o enfeite da classe (o Ninja de Shuriken sai com a shuriken
moldada na aba). Elas fabricam devagar e têm estoque, então às vezes o seu
chapéu favorito acabou e você joga de outra coisa.

Fora deste ciclo: poderes novos no chão (o Julio disse não), habilidades "uau"
e interface nova (Ciclo 2.4), metal, pedra e Ninja vs Cowboys (Fase 3).

## 2. Decisões (opções recomendadas do quiz)

| # | Pergunta | Valendo | Troca? |
|---|---|---|---|
| 1 | Quem coleta | **A**: só o Construtor | B: todos, Construtor 3x |
| 2 | Transporte | **B**: 1 tora nos braços até o castelo (lento, sem atacar) | A: direto pro estoque |
| 3 | Fabricação | **A**: 1 chapéu a cada ~20 s, estoque máx. 3 | C: infinita só com animação |
| 4 | Rodízio de classe | **D**: o estoque já limita; refina depois de jogar | B: não repetir a classe |
| 5 | Gasto da madeira | **A + B**: erguer as oficinas que faltam (agora custam madeira) e o nível 2 das maquininhas | C, D |
| 6 | Início da partida | **A**: 4 maquininhas prontas e cheias | B: só a do Construtor |
| 7, 8 | Habilidades "uau" e interface | vão para o **Ciclo 2.4** | |
| 9 | Hoje à noite | **A**: Etapa 1 em branch, com piloto | C: só pranchas |

## 3. As regras (com os números iniciais e o porquê)

Todos os números ficam em `game_config.tres` e serão calibrados jogando.

**Árvores e bambu.** Cada planta tem 3 estágios: broto, jovem e adulta. Sobe um
estágio a cada `arvore_tempo_estagio` (40 s para a árvore e 15 s para o bambu;
bambu é, de fato, a planta que cresce mais rápido do mundo). Cortar uma adulta
leva 3 golpes e cada golpe solta 1 tora; no último ela volta a broto. Uma
jovem rende só 1 tora e também volta a broto, então cortar cedo é desperdício.
O bambu rende 2 varas, cresce mais rápido e fica no meio do mapa, onde há briga.

**Transporte.** O Construtor carrega 1 tora nos braços, anda a 70% da
velocidade e não ataca (o dash continua valendo). Se apanhar, a tora cai no
chão e qualquer Construtor pode pegá-la, inclusive o inimigo. Entregue na
**pilha do castelo**, a tora vira estoque do time (número em cima da pilha e
no HUD).

Vazão de um Construtor (v = 6,6 m/s; carregando, 0,7·v ≈ 4,6 m/s; corte ≈ 2,5 s):

    T(d) = d/v + d/(0,7·v) + t_corte ≈ 0,37·d + 2,5   [s, d em metros]

Bosque seguro a 20 m dá T ≈ 10 s, ou seja, ~6 toras/min. Bambuzal central a
40 m dá T ≈ 17 s, ~3,5 varas/min. A oferta de cada bosque é
N·toras/(2·t_estágio): o seguro tem 2 árvores, 2·3/80 s ≈ 4,5 toras/min,
abaixo dos ~6 que um Construtor consegue carregar. O bambuzal tem 6 bambus,
6·2/30 s = 24 varas/min, sobra. Por isso o bosque seguro esgota e empurra o
Construtor para o meio arriscado. É esse o motor de decisão.

**Maquininhas de chapéu** (substituem os HatPads do pátio). Cada uma fabrica 1
chapéu a cada `maquina_intervalo` (20 s), até `maquina_estoque_max` (3), e
começa cheia. O nível 2 custa 8 madeiras e baixa para 12 s com estoque 4
(Etapa 2). O limite de classe aparece sozinho, por teoria de filas: uma
máquina entrega μ = 3 chapéus/min. Se 3 jogadores do time querem Samurai e
cada um morre a cada ~45 s, a procura é λ = 4/min > μ. O estoque S₀ = 3 então
acaba em S₀/(λ − μ) = 3 min e, daí em diante, alguém troca de classe.
Somando as 4 máquinas, o time recebe 12/min e precisa de ~8/min, então
sempre há chapéu de *alguma* classe. Falta só o seu favorito, que é o efeito
pedido.

**Casinhas (oficinas das variações).** Continuam como hoje (escolhe a variação
e ergue), mas custam `oficina_custo_madeira` (6) e a obra cai de 20 s para
10 s. O Construtor perto da obra puxa madeira do estoque do time, 1 a cada
1,5 s, com a animação de martelar. Em cima de cada casinha aparece um **contador
claro**: ícone de tora e "faltam 4", mais uma barrinha. Ele fica grande quando
você joga de Construtor e pequeno nas outras classes. Sem estoque, o contador
pisca "falta madeira".

**Bots Construtores** (ordem de prioridade): carregando tora, voltam para a
pilha. Com obra pendente e estoque suficiente, constroem. Senão, vão até a
planta adulta mais próxima que nenhum aliado está cortando, preferindo o bosque
seguro enquanto houver adulta lá. Inimigo a menos de 5 m: largam a tarefa e
lutam ou fogem. No máximo 2 bots Construtores por time.

**Mapa.** O Rio das Lanternas ganha um bosque seguro de 2 árvores atrás de
cada castelo e um bambuzal de 6 bambus no meio, perto do rio. O mapa pode
mudar mais se o QA automático pedir.

## 4. QA automático do mapa (poucos tokens)

É uma ferramenta que o Julio nunca precisa rodar. Uma flag `--qa-mapa=DIR`
monta a partida e gera **um texto curto e uma imagem**. O Claude lê só o texto
e abre a imagem apenas se o texto acusar problema.

1. **Passagem**: uma grade de pontos a cada 1 m no chão andável. Para cada
   castelo e cada ponto, calcula o caminho de navegação. Lista os pontos
   inalcançáveis e os que têm desvio = comprimento do caminho / distância reta
   acima de 2,5 (beco ou passagem fechada).
2. **Escondido atrás de estrutura**: para cada objeto importante (maquininha,
   pilha, árvore, bambu, oficina, máscara, saída do castelo), coloca a câmera
   do jogo (o mesmo deslocamento e ângulo) sobre um anel de posições em volta
   e lança raios câmera → objeto. Se mais de 40% das posições têm o raio
   bloqueado, o objeto é marcado como escondido.
3. **Bot preso**: 3 min de partida acelerada. Anota cada boneco que quer andar
   e se move menos de 0,3 m em 3 s, com a posição.
4. **Saída**: `qa_mapa.txt` com até 30 linhas (problema, x, z e objeto) e
   `qa_mapa.jpg`, uma vista de cima ≤ 1280 px com os pontos vermelhos
   numerados iguais ao texto.

Isso também resolve a pendência antiga de bots presos no Rio, listada em
`docs/ideias.md` A.

## 5. Piloto (uma imagem, antes de entrar na main)

Uma prancha com: árvore nos 3 estágios, bambu nos 3 estágios, a maquininha
em 4 quadros da animação de fabricar (prensa desce, molde brilha, chapéu sai,
vapor), uma casinha com o contador e uma vista do mapa com os bosques
marcados. Tudo no tema Crepúsculo, com o shader de pintura.

## 6. Instruções para os diretores (Etapa 1)

Regras gerais: cada diretor trabalha no seu branch. Vale uma imagem por
rodada, e nenhum número de regra fica fora de `game_config.tres`. A
Etapa 1 entra na main quando os testes de regra e os 5 min simulados
passarem **e** os modelos do Visual estiverem no lugar dos provisórios. Se não
der tempo, ela fica no branch e o Julio vê a prancha de manhã. Toda entrega
na main leva "O que testar" no CHANGELOG.

**Contrato entre os dois** (combinado antes, para não haver conflito):
- `MapLayout`: `tree_spots` e `bamboo_spots` (`PackedVector2Array`) e
  `pilha_spot` por castelo, no mesmo formato de `hat_spots`.
- `ThemeConfig`: `arvore_estagios` e `bambu_estagios` (`Array[PackedScene]`,
  3 cada), `maquina_model` (`PackedScene` com peças `Gira_*`, um nó `Molde`
  onde o chapéu aparece e a animação `fabricar`), `pilha_model` e
  `tora_model`. Quando estiverem vazios, o código usa formas provisórias.
- Campo novo = campo no esquema em `scripts/data/` com padrão que não quebra
  os `.tres` existentes. Quem cria o campo é a Jogabilidade.

### Diretor de Jogabilidade (Sonnet, esforço alto)
1. Esquemas e números em `game_config.gd`: `arvore_tempo_estagio`,
   `bambu_tempo_estagio`, `arvore_toras`, `bambu_varas`,
   `tora_vel_mult` (0,7), `maquina_intervalo`, `maquina_estoque_max`,
   `oficina_custo_madeira`, `maquina_n2_custo/intervalo/estoque`.
2. `scripts/items/planta.gd` (estágios, cortar e soltar tora),
   `scripts/items/tora.gd` (carregar, cair ao apanhar, entregar),
   pilha/estoque do time em `game.gd`, HatPad → maquininha com estoque, e a
   oficina custando madeira, com o contador `Label3D` e a barra.
3. Testes novos em `tests/regras.gd`: estágio sobe no tempo certo; adulta
   rende 3 toras e volta a broto; carregar multiplica a velocidade por
   `tora_vel_mult` e bloqueia o ataque; entregar soma 1 ao estoque; a máquina
   fabrica no intervalo e para no máximo; pegar chapéu tira 1 do estoque; a
   obra consome madeira e não passa de 0.
4. Bot Construtor (seção 3) em `bot_brain.gd`.
5. QA automático do mapa (seção 4): flag `--qa-mapa=DIR` e o resumo no CI
   como aviso, sem falhar o build por enquanto.

### Diretor Visual (Sonnet, esforço médio-alto)
1. Prancha piloto (seção 5).
2. Modelos por código no estilo pintado: árvore e bambu em 3 estágios (o
   crescimento é um tween de escala com "estica e encolhe", e os galhos
   balançam com o vento do shader), maquininha de bambu e engrenagens
   (prensa, molde, vapor e o enfeite da classe na frente), pilha de toras que
   cresce com o estoque e tora para carregar.
3. Bosques e bambuzal em `gerar_mapa_rio.gd` (posições da seção 3), depois de
   rodar o QA e corrigir o que ele acusar.
4. Ícone de tora para o contador e o HUD.

## 7. Etapas seguintes

- **Etapa 2**: nível 2 das maquininhas e o refinamento do rodízio de classe,
  depois de o Julio jogar a Etapa 1.
- **Ciclo 2.4**: habilidade "uau" por personagem (efeito, câmera e som) e a
  interface nova, que precisa da referência que o Julio escolher.
- **Fase 3**: metal ou pedra (minério ninja), Ninja vs Cowboys e
  multijogador.
