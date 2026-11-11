# Ciclo 2.23: heróis raros no nível 6 e relógio de 10 minutos

Plano de execução. Escrito em 2026-11-11 a partir do quiz "Heróis raros do nível 6"
(fonte na pasta do projeto: `castelo-de-bolo/quiz/quiz-herois-nv6.html`) e dos
comentários do Julio. **Nada disto está implementado.** Quem executar segue este
arquivo de cima para baixo; o que não estiver aqui, decide pelo espírito das
respostas e anota no CHANGELOG.

## 0. O que o Julio decidiu

| # | Resposta | Comentário dele (resumo fiel) |
|---|---|---|
| 1 | C, adaptada | Tirar os heróis do Construtor: ele continua só coletando e construindo. As duas vagas vão para as outras classes, mesmo desigual. Mais opções, uma escolha só: fica mais raro. |
| 2 | A (escolha livre) | No Nv3 o quintal já tem 2 casinhas de chapéu. No Nv6 passam a ser 3, e só o herói raro é Nv6 ("um pouco mais upado"). No Nv5 com madeira, o quintal ganha destaque avisando que dá para subir para o herói. O Construtor chega e escolhe entre 2 ou mais. Heróis futuros entram por aí. |
| 3 | A | Um chapéu de herói por bairro. |
| 4 | A, adaptada | Entregar **tudo de uma vez na main**. Conferir tudo durante o trabalho e refazer o que ficar fraco (peças 3D inclusive). Feedback dele vem depois. |
| 5 | B | Acelerar a escada. Além disso: partidas mais rápidas ou **cronômetro de 10 min na tela**; acabou o tempo, vale o placar, e **pode dar empate**. |
| Livre | | Este plano primeiro (Fable). Com o ok dele, a execução pesada (peças 3D, conferência) roda em Opus. |

Consequência da resposta 4: a autorização de ir direto para a main vale para este
ciclo. O princípio 13 continua valendo como **autoconferência**: prancha e gifs são
feitos e olhados por quem executa, antes do merge (§12).

## 1. A escada com o Nv6

Do Nv1 ao Nv5 nada muda na lógica (Ciclo 2.22). Entra um degrau:

- **Nv5 → Nv6**: segunda escolha do bairro. O Construtor escolhe **um** herói entre
  os `herois` da classe base (2 ou mais). Sobe o **Pavilhão do Herói**, a terceira
  casinha de chapéu do quintal. Os heróis não escolhidos ficam fora da partida.
- A escolha é **livre**: não depende do caminho do Nv3.
- Bairro sem `herois` (Construtor) termina no Nv5, como hoje.
- Só o herói é Nv6. Barraquinha e casa do caminho param no Nv5 (bônus de 3 níveis:
  +24% dano, +24% vida, +30% Chi). O herói recebe 4 níveis: **+32% dano, +32% vida,
  +40% Chi** (`heroi_bonus_niveis = 4`).
- O rótulo do bairro e os avisos passam a dizer "nível 6".

### 1.1 Elenco e bairros

| Bairro | Heróis (ordem dos botões) | Por quê |
|---|---|---|
| Samurai | Sumotori, Kappa do Rio | Os dois brigam de perto e seguram a linha. |
| Ninja de Shuriken | Yamabushi do Leque, Karasu Tengu, Mujina | Média distância, mobilidade e flanco. |
| Kitsune | Onmyoji de Papel, Tennin do Manto, Komusō | Magia de apoio e de controle. |
| Construtor | nenhum | Função vital: madeira e obra. |

Mujina foi para o Ninja (vive de flanco e golpe pelas costas) e Komusō para a
Kitsune (feitiço de controle). São 8 heróis, 3 escolhidos por time por partida.

### 1.2 Lugar e estados do pavilhão

Posição: o **tapete do caminho escolhido** (`Oficina.TAPETES[caminho]`), que hoje
fica vazio depois que a casa sobe. O tapete selado mantém o selo. O quintal fica:
barraquinha na frente, casa atrás, pavilhão de lado.

| Estado | Quando | O que aparece |
|---|---|---|
| Fantasma | Bairro no Nv5, herói não escolhido | Pavilhão translúcido dourado (shader `casa_fantasma`), com "?" no altar. |
| Destaque | Fantasma **e** depósito com madeira ≥ `heroi_custo` | Anel dourado pulsando no tapete, pilar de luz baixo, estrela piscando no minimapa, seta do `GuiaConstrutor`, aviso único "Herói raro disponível no bairro de X". |
| Obra | Herói escolhido, madeira entrando | Três etapas visíveis por fração de madeira: base de pedra, colunas, telhado. Mesmo ritmo de puxar madeira das subidas de nível (`_obra_nivel`). |
| Pronto | Última madeira | Clarão, sino, adorno do herói no topo, chapéu no altar. `pad_heroi` criado. |
| Vazio | Chapéu em uso ou voltando | Altar apagado. Com o herói caído de vez, um anel enche em `heroi_retorno` s. |

### 1.3 Escolha

- **Jogador Construtor**: [F] no bairro abre o painel que já existe
  (`Hud.abrir_escolha`), agora com **N botões** (2 a 4 numa linha; teclas 1 a 4).
  Cada botão: nome, epíteto, uma linha de estilo, nomes do Q, E e R. Mesmas travas
  de hoje: fora da briga, com madeira, fecha ao sair do bairro.
- **Bots**: param `ESCOLHA_T` s no tapete do pavilhão e escolhem o herói sorteado
  no começo (`escolha_heroi_bot`), na hora, como já fazem com o caminho.
- Aviso para os dois times: "Herói escolhido: Sumotori!" / "O inimigo chamou o Sumotori".

### 1.4 Raridade

- `pad_heroi`: estoque máximo 1, **sem fabricação por tempo**.
- Quem pega vira o herói. O chapéu só volta quando ele **perde a classe**: renasce
  como aldeão (`Unit._respawn`) ou troca de chapéu. Caído esperando reanimar não
  conta: se for levantado, continua herói.
- Perdeu: o altar conta `heroi_retorno = 20` s e o chapéu reaparece.
- Aviso curto ao time quando alguém veste: "O Sumotori entrou na briga!".
- Bots só pegam o chapéu se o jogador não pegou em `heroi_espera_jogador = 8` s
  depois que ele aparece (o jogador testa o herói sem disputar com bot).
- Leitura no campo: anel do time com filete dourado e ★ ao lado do nome; ★ na
  linha do placar [Tab].

## 2. Ritmo e madeira

| Item | Hoje | Novo |
|---|---|---|
| Nv1 → 2 | 4 | 4 |
| Casa do caminho (Nv2 → 3) | 6, +2 por casa já feita | igual |
| Nv3 → 4 | 6 | **5** |
| Nv4 → 5 | 9 | **7** |
| Nv5 → 6 (herói) | não existe | **10** (`heroi_custo`) |
| Toras por árvore | 4 | **5** |

Escada inteira: 100 madeiras nos 4 bairros + 30 dos 3 heróis = 130 por time.

**Bots com foco**: depois das 4 barraquinhas no Nv2, o time leva **um bairro com
herói** (sorteado por partida) direto até o Nv6 (caminho, Nv4, Nv5, herói: 28
madeiras) antes de abrir os outros caminhos. Depois segue a ordem de hoje. Mexe em
`Game.mago_para_subir` e `obra_do_time`.

**Meta medida**: em 3 partidas simuladas de 10 min só com bots, o 1º herói de cada
time sai entre **7:00 e 8:30**. Se não sair, ajustar nesta ordem: `heroi_custo`,
`mago_nivel_custo`, `arvore_toras`. Registrar os tempos no CHANGELOG.

## 3. Relógio de 10 minutos e empate

- `tempo_limite = 600` s (0 desliga). O relógio do placar (`Game.tempo_partida`)
  vira **regressivo** e vai para o topo da tela, no meio do placar, no lugar do "VS".
- Último minuto: relógio vermelho pulsando. Últimos 10 s: um tique por segundo.
- Tempo zerou: quem tem mais pontos de máscara vence. **Igual = EMPATE** (tela do
  placar com "Empate", som neutro, os dois times parados).
- **Última corrida**: se no zero alguma máscara está nas mãos de alguém, a partida
  segue até essa máscara ser entregue, cair ou voltar, no máximo
  `prorrogacao_max = 30` s. Aviso "Última corrida!".
- `score_to_win = 3` continua encerrando antes.
- Modo teste: sem relógio. Simulações do CI (5 min) não são afetadas.

## 4. Os 8 heróis

Regra de custo: cada herói traz **um truque novo de verdade** (marcado NOVO). O
resto reaproveita mecânica existente com efeito, som e números próprios (marcado
REUSO, com a peça de origem). Números são o ponto de partida antes do bônus de
Nv6; o equilíbrio fecha na sonda (§12). Referência: Samurai 165 de vida, Ronin
190, Ninja 80, Kitsune 80.

Todos: `classe_base` = id da classe do bairro; corpo no esqueleto KayKit com
peças por código (`NinjaVisual._<id>`, uma malha só); uma peça emissiva na cor do
time; três animações lidas na prancha (parado, golpe, poder); `chapeu_tempo_mult`
não se aplica.

### 4.1 Sumotori (Samurai) "O lutador do santuário"

- **Corpo**: `Barbarian.glb`, `escala_modelo` 1.18, sem arma. Barriga e ombros
  largos (esferas achatadas), coque chonmage, mawashi na cor do time, corda tsuna
  branca com fitas de papel que balançam. Dash "rolar".
- **Números**: vida 215, velocidade 5.8, dano 15, alcance 2.6, recarga 0.42,
  empurrão 9. Combo de 4 tapas, o último com as duas mãos (×1.6).
- **Q Agarrão** (NOVO, `skill = "agarrao"`, recarga 7 s): pega o primeiro inimigo
  a até 2.8 m num cone de 70°. Segura 0.35 s (alvo preso) e arremessa até 9 m na
  direção da mira, em arco (voo e pouso da catapulta: `pose_voo`, `aterrissagem`).
  No pouso o alvo leva 22 e fica 0.6 s no chão; inimigos a 2.2 m do pouso levam 14
  e empurrão. Quem carrega a máscara solta a máscara ao ser agarrado. Não agarra
  alvo no meio do dash.
- **E Pisão** (REUSO `pisao`, maior): raio 5.0, dano 26, derruba 0.9 s.
- **R Dohyō** (REUSO do empurrão de borda da `muralha`, nos dois sentidos): anel de
  sal de raio 6 por 6 s. Inimigo dentro não sai, de fora não entra. Aliados passam.
  O Sumotori ganha +20% de dano dentro.
- **Bot**: Q quando há inimigo a 3 m, mirando no maior grupo inimigo ou para longe
  da própria máscara. E com 2 ou mais inimigos no raio. R com 2 ou mais dentro e
  aliados perto.

### 4.2 Kappa do Rio (Samurai) "O espírito do rio"

- **Corpo**: `Rogue.glb`, escala 0.92, pele verde, casco nas costas (esfera
  achatada com placas), prato d'água na cabeça que brilha na cor do time, bico.
  Dash "rolamento" (rola no casco).
- **Números**: vida 150, velocidade 7.0, dano 13, alcance 2.4, recarga 0.45,
  empurrão 5. Combo de 3 garras (×1.5).
- **Passiva Casco** (NOVO, campo `casco = 0.6`): dano que chega por trás (mais de
  110° do rosto), golpe ou projétil, é reduzido em 60%. Faísca e som de casco.
- **Q Rasteira** (REUSO do avanço do `_corte_relampago`, sem dano no trajeto,
  recarga 6 s): some numa poça, reaparece 6 m à frente e derruba o inimigo mais
  perto a 2 m (16 de dano, preso 0.8 s).
- **E Jato** (REUSO `tiro_carregado` perfurante): linha de água de 12 m, dano 24,
  empurrão 14, atravessa todos.
- **R Enchente** (`super_tipo = "maior"` sobre o Jato): faixa mais larga, dano e
  empurrão dobrados.
- **Bot**: procura ficar de costas para os atiradores inimigos quando briga de
  perto (peso pequeno no `_steer`). Q para fechar distância em atirador. E com 2
  ou mais alinhados.

### 4.3 Yamabushi do Leque (Ninja) "O eremita tengu"

- **Corpo**: `Mage.glb`, rosto vermelho de nariz comprido (máscara tengu), tokin
  preto na testa, pompons laranja no peito, leque de penas grande na mão com a
  borda acesa na cor do time. Dash "ninja".
- **Números**: vida 105, velocidade 6.6, tiro médio: projétil novo "vento" (lâmina
  curta que atravessa 2 alvos), dano 12, alcance 9, recarga 0.6, empurrão 6.
- **Q Rajada** (NOVO, `skill = "rajada"`, recarga 6 s): cone de 70° e 7 m. Empurra
  inimigos (empurrão 16, dano 8) e **rebate todo projétil inimigo** dentro do cone
  (flecha, shuriken, magia, bomba, virote): inverte a direção e passa a ser do time
  dele. Mexe em `Projectile` (trocar dono e direção).
- **E Redemoinho** (REUSO `redemoinho` com sucção, lançado no cursor como a
  `coluna_fogo`): raio 3.5, 3 s, 7 por pulso; o último pulso ergue (`launch`).
- **R Tufão** (`"maior"` sobre o Redemoinho).
- **Bot**: Q quando há projétil inimigo vindo (já existe `_esquiva_projetil`) ou
  inimigo a 4 m. Mantém 6 a 8 m do alvo.

### 4.4 Karasu Tengu (Ninja) "O corvo da montanha"

- **Corpo**: `Rogue_Hooded.glb`, penas pretas, asas dobradas nas costas (abrem no
  Mergulho), bico amarelo, olhos acesos na cor do time, pés de garra. Dash "ninja".
- **Números**: vida 95, velocidade 7.3, dano 13, alcance 2.6, recarga 0.5,
  `dano_costas` 0.3. Combo de 3, o último com saltinho.
- **Q Mergulho** (NOVO, `skill = "mergulho"`, recarga 7 s): sobe 0.5 s (intocável),
  cai no ponto do cursor a até 11 m. Uma marca no chão aparece 0.5 s antes do
  impacto (contra-jogo). Impacto de raio 2.6: dano 26 e empurrão. O destino precisa
  ser chão válido (mesma checagem do pouso da catapulta). Interpolação de física:
  `reset_physics_interpolation()` no salto.
- **E Revoada** (REUSO `nuvem`/`area_effect` + status pequeno "cego"): nuvem de
  corvos de raio 4.5 por 4 s, 4 por pulso. Bot dentro erra a mira (desvio de até
  35°); jogador dentro vê vinheta escura e perde os nomes.
- **R Noite de Corvos** (REUSO do Mergulho em cadeia): três mergulhos seguidos nos
  três inimigos mais próximos.
- **Bot**: Q em atirador ou curandeiro isolado a mais de 5 m. Bots inimigos
  esquivam da marca em metade das vezes.

### 4.5 Mujina, a Sem Rosto (Ninja) "A ladra de rostos"

- **Corpo**: `Rogue.glb`, rosto liso e pálido sem olhos, um risco fino que acende
  na cor do time, cabelo preto comprido (fitas com balanço), quimono escuro. Dash "ninja".
- **Números**: vida 90, velocidade 7.2, dano 12, alcance 2.3, recarga 0.45,
  `dano_costas` 1.0 (dobro pelas costas).
- **Q Roubar Rosto** (NOVO, `skill = "roubar_rosto"`, recarga 12 s): toca um inimigo
  a até 3 m e fica 10 s com a **classe e a cor do time dele** (troca de visual com
  cache). Bots e torretas inimigos não a tratam como alvo (mesmo caminho lógico do
  `na_sombra_para`). O jogador inimigo vê um boneco do próprio time. Quebra no
  primeiro golpe dela (+50% de dano nesse golpe) ou ao tomar dano.
- **E Susto** (NOVO pequeno, status "andar forçado", o mesmo da Hipnose): cone de
  90° e 6 m, dano 6. Quem está no cone corre para longe dela por 1.5 s sem atacar.
- **R Passo sem Rosto** (`super_tipo = "sombra"`, o Super do Samurai): invisível e
  rápida por pouco tempo, golpe de surpresa. No painel de ideias era "usar o Super
  do inimigo"; troquei pelo que já existe e combina (ver §13).
- **Bot**: Q antes de entrar no pátio inimigo ou ir na máscara; disfarçada, anda
  sem atacar até chegar às costas de alguém.

### 4.6 Onmyoji de Papel (Kitsune) "O dobrador de shikigami"

- **Corpo**: `Mage.glb`, eboshi preto alto (chapéu `eboshi` já existe), manto
  branco com faixa na cor do time, talismã na mão. Dash "chama" recolorido para papel.
- **Números**: vida 95, velocidade 6.4, tiro: projétil "talisma" (existe), dano
  11, alcance 14, recarga 0.7.
- **Q Dobrar** (NOVO, `skill = "dobrar"`, recarga 3.5 s): cria um boneco de papel
  que orbita (até 3). Cada boneco **engole um golpe inteiro** e some. Com 3 em
  volta, o próximo Q lança os três como talismãs que seguem o alvo (14 cada).
  Os bonecos são uma malha só com órbita no shader (1 chamada de desenho). O HUD
  mostra as cargas.
- **E Grou** (REUSO de projétil largo perfurante): grou de papel de 18 m que cura
  aliados atravessados (25) e fere inimigos (22).
- **R Mil Grous** (REUSO `_leque`): cinco grous em leque de 50°.
- **Bot**: mantém 3 bonecos fora da briga; lança os três em alvo com pouca vida.
  E quando há aliado ferido e inimigo na mesma linha.

### 4.7 Tennin do Manto (Kitsune) "A dançarina celeste"

- **Corpo**: `Mage.glb`, escala 0.98, **flutua** (visual 0.25 m acima do chão com
  balanço; `flutua = true`), manto hagoromo: duas fitas longas na cor do time com
  balanço (`_fita` + `balanco.gdshaderinc`), halo fino, coque alto. Dash "chama".
- **Números**: vida 100, velocidade 6.8, golpe em volta (arco 360°, alcance 3.2,
  dano 10, recarga 0.7, empurrão 4). **Não é empurrada** (`knock_imune = true`).
- **Q Laço** (NOVO, `skill = "laco"`, recarga 10 s): mira um aliado **caído** a até
  12 m, puxa até ela (puxada do `gancho`) e levanta na hora com 40% da vida
  (`levantar_reanimado`). Sem caído no alcance: puxa um aliado vivo e cura 20.
- **E Dança** (REUSO `bencao` + empurrão de borda da `muralha`): raio 5.5 por 4 s,
  cura 6% por pulso e afasta inimigos.
- **R Véu** (REUSO `give_shield`): aliados a até 14 m ficam intocáveis por 3 s.
- **Bot**: fica atrás da linha; Q assim que um aliado cai no alcance; R quando 3
  ou mais aliados perto estão abaixo de 50%.

### 4.8 Komusō (Kitsune) "O monge sem rosto"

- **Corpo**: `Knight.glb`, cesto de palha cobrindo a cabeça (chapéu `cesto` já
  existe), flauta shakuhachi, kesa (faixa diagonal) na cor do time. Dash "rolar".
- **Números**: vida 110, velocidade 6.2, tiro: projétil novo "nota" que atravessa
  todos, dano 9, alcance 12, recarga 0.8, empurrão 3.
- **Q Sono** (REUSO `apply_slow` + `prender`, canalizado, recarga 8 s): toca parado
  por 1.6 s num cone de 60° e 8 m. Quem está no cone fica lento (×0.5); quem ainda
  está lá no fim dorme 1.6 s (acorda com dano). Interrompe se ele for atingido.
- **E Hipnose** (NOVO, `power = "hipnose"`, status "andar forçado"): inimigos a até
  7 m andam **na direção dele** por 2 s, sem atacar. Feito para combinar com Pisão,
  armadilha e bomba dos aliados.
- **R Réquiem** (REUSO `silence`): inimigos a até 16 m sem poder nenhum por 4 s.
- **Bot**: E quando há aliado de área perto; Q em grupo parado (briga na máscara).

### 4.9 Status novo compartilhado: andar forçado

`Unit.forcar_andar(origem: Vector3, t: float, afasta: bool)`: por `t` s o corpo
ignora o cérebro, anda para longe ou para perto de `origem` e não ataca nem usa
poder. Dano não quebra. Imunes: quem carrega a máscara (anda a 50%) e heróis em
Super. Usado pelo Susto e pela Hipnose. Ícone sobre a cabeça.

## 5. Pavilhão do Herói (peça nova, princípio 13)

- **Silhueta**: santuário pequeno e aberto (hokora). Base de pedra de dois
  degraus, quatro colunas vermelhas, telhado duplo curvo **dourado** (cor que
  nenhuma casa usa), shimenawa na frente, duas lanternas penduradas. Cabe no
  tapete: até 2.4 m de largura, 4.2 m de altura.
- **Cor do time**: estandarte lateral e a luz do altar.
- **Identidade do herói**: um adorno no topo do telhado e o emblema no estandarte.
  Adornos: coque com tsuna (Sumotori), prato d'água (Kappa), leque de penas
  (Yamabushi), pena preta (Karasu), máscara lisa (Mujina), grou de papel (Onmyoji),
  laço de manto (Tennin), cesto (Komusō).
- **Animações**: parado (lanternas e shimenawa balançam, chapéu gira no altar);
  ação (ao pegar o chapéu: clarão e sino); fim (altar apagado, anel de retorno).
- **Arquivos**: `tools/gerar_casas.gd` ganha `_pavilhao()` e 8 adornos. Um
  `pavilhao.scn` por tema (nós `H_Base`, `H_Colunas`, `H_Telhado`, `Estoque_1`) +
  `adorno_<heroi>.scn` e `emblema_<heroi>.scn` pequenos, nos 4 temas. Não gerar um
  pavilhão inteiro por herói (pouparia nada e custa ~13 MB no repo). Terminar com
  `MalhaUnica.juntar`, deixando soltos só o chapéu e o que balança.
- **Chapéus do pedestal** (`HatPad.make_hat`, enum `hat_style`): novos `coque`,
  `prato`, `tokin`, `bico`, `mascara_lisa`, `halo`. `eboshi` e `cesto` já existem.

## 6. Efeitos e sons

- Efeitos pelo kit `Magia` (`scripts/fx/magia.gd`), receita e orçamento de
  `docs/direcao-efeitos.md` §8. Nada de primitiva de cor chapada. Uma função por
  poder em `fx_poder.gd` (`q_agarrao`, `dohyo`, `q_rajada`, `mergulho`, `revoada`,
  `q_rosto`, `susto`, `shikigami`, `grou`, `q_laco`, `danca`, `veu`, `q_sono`,
  `hipnose`, `requiem`, `casco`, `jato`). Conferir na `tools/bancada_magia.gd`.
- Elemento por herói (cor e som seguem o elemento): Sumotori terra e sal; Kappa
  água; Yamabushi vento; Karasu pena e sombra; Mujina fumaça roxa; Onmyoji papel
  e luz; Tennin luz rosa-dourada; Komusō som (ondas e notas).
- Sons pela skill `efeitos-sonoros` (biblioteca CC0). Reaproveitar a família
  `magia_*` onde servir. Novos, no máximo 9: tapa, arremesso com baque, casco,
  água, grasnido, papel dobrando, nota de flauta, susto, sino do pavilhão.

## 7. Dados e esquema

`scripts/data/class_stats.gd` (todos com padrão que não muda os .tres atuais):

- Grupo "Heróis raros (Ciclo 2.23)": `herois: Array[ClassStats] = []` (na classe
  base), `casco := 0.0`, `knock_imune := false`, `flutua := false`,
  `super_poder := ""` (id do poder do R quando `super_tipo = "proprio"`),
  `estilo_linha := ""` (a linha de estilo do painel).
- Enums: `skill` += agarrao, rasteira, rajada, mergulho, roubar_rosto, dobrar,
  laco, sono. `power` += pisao_grande, jato, redemoinho_longe, revoada, susto,
  grou, danca, hipnose, dohyo, mergulho3, mil_grous, veu, requiem. `super_tipo` +=
  proprio. `projetil` += vento, nota, grou. `hat_style` += os 6 do §5.

`scripts/data/game_config.gd`, grupo "Heróis raros (Ciclo 2.23)": `heroi_custo :=
10`, `heroi_retorno := 20.0`, `heroi_espera_jogador := 8.0`, `heroi_bonus_niveis
:= 4`, `sandbox_heroi_retorno := 3.0`. Grupo "Partida": `tempo_limite := 600.0`,
`prorrogacao_max := 30.0`. Mudar em `game_config.tres`: `mago_nivel_custo = (5,
7)`, `arvore_toras = 5`. `mago_nivel_max` continua 5.

Classes novas: `config/classes/{sumotori,kappa,yamabushi,karasu_tengu,mujina,
onmyoji,tennin,komuso}.tres`, geradas por script `-s` com `ResourceSaver.save()`.
`guerreiro.tres`, `arqueiro.tres` e `kitsune.tres` ganham `herois`.

**Herói futuro** = um .tres + entrar em `herois` da base + `NinjaVisual._<id>` +
adorno e emblema. Só precisa de código de regra se trouxer truque novo.

## 8. Código: onde mexe

| Arquivo | O que muda |
|---|---|
| `scripts/items/oficina.gd` | `heroi := -1`, `pad_heroi`, `escolha_heroi_bot`, `herois()`, `pede_heroi()`, `escolher_heroi(i, gratis)`, obra do pavilhão por madeira, `_finish_heroi()`, retorno do chapéu (`heroi_dono`, `_retorno_t`), estados visuais do §1.2, rótulo. `pode_subir()` aceita o Nv5 → 6 só depois da escolha. |
| `scripts/items/hat_pad.gd` | Modo raro: estoque 1 sem fabricação, anel de retorno, `make_hat` com 6 chapéus novos. |
| `scripts/game.gd` | `_dica_casa` (dicas do Nv5/Nv6), `_confirmar_heroi`, `on_heroi_escolhido`, `on_heroi_pronto`, `on_heroi_vestido`; `bonus_mago`, `nivel_casa`, `nivel_visual_mago` conhecem o herói; `mago_para_subir`/`obra_do_time` com o foco; `nearest_free_hat` com a espera do jogador; relógio, empate e última corrida (`_fim_por_tempo`); sandbox. |
| `scripts/actors/unit.gd` | As regras novas do §4 e o §4.9: `_agarrao`, casco em `take_damage`, `_rajada`, `_mergulho`, disfarce (`_disfarce`, `alvo_valido_para`), cargas de shikigami em `take_damage`, `_laco`, `_sono`, `forcar_andar`, `cego_t`, `knock_imune`, `flutua`, `super_tipo = "proprio"`. Aviso ao game quando perde a classe de herói. Arquivo de 2.678 linhas: ler por trecho (Grep), nunca inteiro. Se passar de ~3.000, extrair as regras dos heróis para `scripts/actors/herois.gd` (funções estáticas que recebem a `Unit`). |
| `scripts/items/projectile.gd` | `rebater(novo_dono, dir)`; tipos vento, nota, grou (cura aliado ao atravessar). |
| `scripts/ai/bot_brain.gd` | Ramos em `_should_use_quick`, `_should_use_power`, `_should_use_super` para cada herói; ignorar a Mujina disfarçada; esquivar da marca do Mergulho; andar forçado e cego; Construtor escolhe herói; foco do bairro. |
| `scripts/actors/ninja_visual.gd` | Oito funções `_<id>(time)`; malhas auxiliares novas (asa, casco, leque, cesto, boneco de papel). |
| `scripts/fx/fx_poder.gd`, `fx_projetil.gd`, `marca_chao.gd` | Efeitos do §6, marca do Mergulho, anel do Dohyō. |
| `scripts/ui/hud.gd` | Painel de escolha com N botões; relógio regressivo; cargas do Onmyoji; ★ do herói; vinheta do "cego". |
| `scripts/ui/placar_tela.gd`, `scripts/placar.gd` | Estado "Empate"; ★ na linha do herói. |
| `scripts/ui/minimapa.gd` | Estrela no bairro Nv6; piscando no estado Destaque. |
| `scripts/ui/pagina_classes.gd`, `tutorial.gd` | Grupo "Heróis raros" com as 8 fichas e o bairro de cada um; aba Casas e Caminhos com o Nv6; relógio e empate nas regras. Textos por `docs/estilo-textos.md`. |
| `tools/gerar_casas.gd`, `prancha_casas.gd`, `prancha_personagens.gd`, `vitrine.sh`, `sonda_equilibrio.sh` | Pavilhão, adornos, emblemas; pranchas e sonda conhecem os heróis. |
| `tests/regras.gd` | §10. |
| `CHANGELOG.md`, `CLAUDE.md`, `CONTROLES.md`, `docs/ideias.md` | Entrada 2.23 com "O que testar"; linha da escada no CLAUDE.md; ideias não usadas voltam para B. |

## 9. Modo teste

Espelha a main: madeira infinita, nada construído, escolhas valendo, F5 troca.
O Nv6 se constrói como o resto (obra 3× mais rápida). O chapéu do herói volta em
`sandbox_heroi_retorno = 3` s. O aliado de treino que já existe lá
(`Game._aliado_de_treino`, `reanimar.treino`) serve de alvo para o Laço; conferir
se ele volta a cair depois de levantado. Sem relógio.

## 10. Testes de regra (um `_check` por linha)

Escada: Nv5 com `herois` pede escolha e não sobe sozinho; bairro sem `herois`
para no 5; escolher gasta a 1ª madeira e fixa o herói; pavilhão pronto cria o
pad com estoque 1; base e caminho com bônus 3, herói com bônus 4; chapéu não
fabrica por tempo; volta `heroi_retorno` s depois do renascer, não enquanto caído;
bot espera o jogador. Relógio: mais pontos vence no zero; igual empata; máscara na
mão estende até cair, no máximo `prorrogacao_max`.

Heróis: Agarrão arremessa, fere no pouso e solta a máscara; Casco reduz só por
trás; Rajada troca dono e direção do projétil; Mergulho é intocável no ar e fere
no raio; cego desvia a mira do bot; disfarce tira a Mujina dos alvos e quebra no
golpe; cada shikigami engole um golpe e o 3º Q lança os três; Laço levanta o
caído com 40%; Tennin não é empurrada; Sono dorme quem fica e interrompe com
dano; andar forçado aproxima e afasta; Réquiem e Véu duram o tempo certo; Dohyō
segura dentro e fora; Super de cada herói gasta a barra uma vez só.

## 11. Ordem de execução

Branch `claude/project-thread-fjcvdl`. Cada etapa termina com testes verdes e
commit. A main só recebe no fim (§12). Se o limite de uso acabar, parar no fim de
uma etapa com o branch empurrado.

0. Godot 4.7.2 no container, `--import`, testes (base: 475), CENSO de base.
1. Relógio, empate, última corrida. Testes.
2. Sistema do Nv6 com um herói de mentira (cópia de uma classe): Oficina, HatPad
   raro, painel N, dicas, destaque, minimapa, bots, sandbox, custos. Testes e as
   3 simulações de ritmo.
3. Pavilhão, adornos, emblemas, chapéus. `prancha_casas.gd`.
4. Heróis, um por vez: Sumotori, Kappa, Yamabushi, Karasu Tengu, Mujina, Onmyoji,
   Tennin, Komusō. Para cada um: .tres, regra e teste, corpo, efeitos, sons, bot,
   ficha, gif na vitrine, commit.
5. Conferência (§12).
6. Menus, CHANGELOG, CLAUDE.md, PR, CI verde, merge, prancha final para a pasta
   do projeto, aviso ao Julio.

## 12. Conferência antes da main (pedido do Julio: conferir e refazer)

- **Prancha dos 8** (`tools/prancha_personagens.gd`) ao lado de Samurai, Ninja e
  Kitsune. Critérios: silhueta reconhecível em preto; classe legível a 20 m de
  câmera; peça na cor do time visível; nada que pareça primitiva solta. Reprovou,
  refaz a peça.
- **Vitrine** (`tools/vitrine.sh`) com um gif por herói mostrando Q, E e R.
  Critério: dá para dizer o que o poder faz sem ler o nome.
- **Prancha do quintal** nos 5 estados do pavilhão.
- **Equilíbrio** (`tools/sonda_equilibrio.sh` com heróis forçados): K/D de cada
  herói entre 1.1 e 1.6; nenhum acima de 1.8; nenhum abaixo da classe de caminho.
- **Ritmo**: 3 simulações de 10 min, 1º herói entre 7:00 e 8:30, partidas
  terminando por ponto ou por tempo, sem erro no log.
- **Desempenho** (CENSO no xvfb): no máximo +5% de chamadas de desenho sobre a
  main, com 3 pavilhões e 3 heróis por time em campo. Cada herói é uma malha só.
- **QA do mapa** (`--qa-mapa`) e **chão piscando** (`--pisca`) no quintal.
- Saídas em `castelo-de-bolo/herois/` na pasta do projeto.

## 13. Onde decidi pelo Julio (ele pode vetar antes do ok)

1. Mujina no Ninja e Komusō na Kitsune (2, 3 e 3 heróis).
2. Pavilhão no tapete do caminho escolhido, não num terreno novo.
3. Herói com bônus de Nv6 (+32%); base e caminho ficam no Nv5.
4. R simplificado em relação ao painel de ideias: Mujina usa a invisibilidade que
   já existe (não copia o Super do inimigo); Kappa e Yamabushi usam o E em versão
   gigante. Os outros cinco têm R próprio feito de peças existentes.
5. Susto e Hipnose são o mesmo status (andar forçado), em sentidos opostos.
6. Bots escolhem o herói na hora e esperam 8 s para o jogador pegar o chapéu.
7. Relógio de 10 min com "última corrida" de até 30 s quando há máscara na mão.
8. Bots focam um bairro até o herói antes de abrir os outros caminhos.

## 14. Custo estimado (tokens)

| Etapa | Estimativa |
|---|---|
| 1. Relógio e empate | 0,2 M |
| 2. Sistema do Nv6 e ritmo | 0,6 M |
| 3. Pavilhão, adornos, chapéus | 0,4 M |
| 4. Oito heróis (0,6 a 0,8 M cada) | 4,8 a 6,4 M |
| 5. Conferência e refações | 0,5 a 0,8 M |
| 6. Menus, CHANGELOG, merge | 0,3 M |
| **Total** | **6,8 a 8,7 M** |

Isso são duas a três janelas de 5 h. Este plano e os dois quizzes: ~0,9 M já gastos.
