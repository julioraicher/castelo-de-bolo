# Design do jogo: classes, poderes e progressão

Fonte: quiz 2 do Julio (2026-10-29) + direção v1 em `docs/identidade.md`.
É o cardápio de onde as frentes tiram trabalho. O que está marcado **v1**
entra primeiro; o resto é lista de desejos já aprovada pelo gosto do Julio.

## Os 4 papéis (fixos) e as versões

Todo mundo nasce **Recruta** (o aldeão de hoje, sem item) e vira um papel ao
pegar o item no pedestal. Cada papel tem versões (subclasses) que usam o mesmo
esqueleto e as mesmas animações; muda modelo, arma e números no `.tres`.

| Papel | v1 (mundo ninja) | Versões aprovadas para depois |
|---|---|---|
| Guerreiro | **Samurai** (katana, combo de 3, bloqueio) | Cavaleiro, Ninja de espada, Lutador, Guitarrista de metal, Cavaleiro maldito, Motoqueiro de corrente, Ceifador |
| Atirador | **Ninja de shuriken** (arremesso em sequência, tiro carregado) | Arqueiro, Caçador de besta, Agente de pistola, Atirador de elite, Escopeteiro, Pistoleiro, Lançador de dinamite, Chicote elétrico |
| Mago | **Monge de chi** (cura em toque, rajada de energia) | Mago clássico, Necromante, Bruxo do fogo, Hacker/tecnomante, Skald das runas, Bruxa do pântano, Feiticeiro do livro |
| Construtor | **Armadilheiro** (estrepes, minas, conserta) | Engenheiro de torreta, Mecânico, Mineiro, Lenhador, Carpinteiro |

O Clérigo de hoje vira o Monge (mesma função de cura). O Construtor é o papel
novo do código.

## Progressão (estilo Fat Princess, Fase 2)

1. **Todos** coletam recursos (madeira e metal) e consertam coisas; o
   Construtor faz isso mais rápido e é o único que constrói.
2. Recursos vão para a **oficina** do papel no castelo. Oficina cheia sobe de
   nível e libera, para o time todo, a **versão 2** daquele papel.
3. Na versão 2 o jogador **escolhe** qual subclasse pegar (ex.: Guerreiro
   nível 2 = Cavaleiro maldito *ou* Lutador). É o "upar com base nas escolhas".
4. O Construtor também gasta recursos em torretas, minas, barricadas e na
   catapulta.

## Poderes

**Tipos de gatilho** (marcados no quiz): medidor cheio + Q (como hoje), item
no chão, sequência de abates sem morrer, ao morrer (explode), último minuto
(Hora do Caos: todo mundo com medidor cheio).

Regra do Julio: os poderes que já existem são os de carga **rápida**; os mais
fortes saem do resto da lista e carregam mais devagar.

| Papel | Rápido (hoje) | Fortes (carga lenta / outros gatilhos) |
|---|---|---|
| Guerreiro | Redemoinho | Investida em linha, Fúria (dano x2 por 6 s, sequência de abates), Gigante por 5 s (item no chão), Imortal 3 s com pouca vida |
| Atirador | Torre automática | Chuva em área, Tiro perfurante, Rajada em leque, Armadilha, Marcar alvo, Tiro explosivo (item), Mira automática 5 s |
| Mago | Bênção (cura + escudo) | Ressuscitar aliado, Bolha anti-tiro, Exército de espíritos, Raio em cadeia, Coluna de fogo, Teletransporte do grupo, Prender no chão, Aura de ataque, **Selo** (silencia poderes e ataques inimigos por 2-3 s) |
| Construtor | Corrida (aliados correm mais) | Roubar o item de um inimigo, Campo de minas, Torreta grande (oficina) |

Visual: choque/eletricidade é bem-vindo (raio em cadeia, Selo, torre).

**Itens no chão (power-ups):** poção de vida, escudo, velocidade, dano dobrado,
bomba de arremesso, medidor cheio na hora.

## Mapa

Um mapa fixo e polido. "Mudar durante a partida" = algo pequeno: um atalho que
abre (ponte que desce, portão lateral), ou a catapulta. Nada de reconstruir
cenário. Caminhos secretos = atalhos baratos, não áreas novas.

## Partida

5 a 10 min (Julio ainda não tem certeza: testar). Hora do Caos no último minuto.
