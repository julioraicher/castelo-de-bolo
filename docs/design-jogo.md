# Design do jogo: classes, poderes e progressão

Fonte: quiz 2 do Julio (2026-10-29) + direção v1 em `docs/identidade.md`.
É o cardápio de onde as frentes tiram trabalho. O que está marcado **v1**
entra primeiro; o resto é lista de desejos já aprovada pelo gosto do Julio.

## Os 4 papéis e as variações (mundo ninja)

Todo mundo nasce **Recruta** (sem item) e vira um papel ao pegar o item no
pedestal. Cada papel tem **3 variações**; todas usam o mesmo esqueleto e as
mesmas animações. O que muda é modelo, arma, números e **poderes com efeitos
próprios**. Nomes das variações vêm da prancha 4 de `docs/arte-personagens.md`.

| Papel | Variação A | Variação B | Variação C |
|---|---|---|---|
| Guerreiro | **Samurai**: katana, combo, bloqueio. Poder: Redemoinho (rápido) / Investida em linha | **Ronin Oni**: máscara oni, nodachi. Poder: Fúria (dano x2 por 6 s, sequência de abates) / Imortal 3 s com pouca vida | **Lâmina Dupla**: duas espadas, rápido. Poder: Corte relâmpago que teleporta / Gigante 5 s (item) |
| Atirador | **Ninja de shuriken**: rajadas. Poder: Rajada em leque / Marcar alvo | **Arqueiro Yumi**: arco longo, tiro carregado. Poder: Chuva de flechas / Tiro perfurante | **Bombas de Fumaça**: arremesso em parábola. Poder: Tiro explosivo / Armadilha no chão |
| Mago | **Monge de chi**: cura em toque. Poder: Bênção (cura + escudo) / Ressuscitar aliado | **Onmyoji**: talismãs. Poder: **Selo** (silencia poderes e ataques inimigos 2-3 s) / Prender no chão / Raio em cadeia | **Kitsune**: fogo-raposa. Poder: Coluna de fogo / Exército de espíritos / Teletransporte do grupo |
| Construtor | **Armadilheiro**: estrepes e minas. Poder: Campo de minas / Corrida | **Mestre da Pólvora**: dinamite, canhão. Poder: Torreta grande / Bomba no portador do tesouro | **Carpinteiro**: barricadas, pontes, conserta rápido. Poder: Muralha instantânea / Roubar item de classe |

Regra do Julio: o primeiro poder de cada variação é o de carga **rápida**; o
segundo é mais forte e carrega devagar (ou vem de outro gatilho). Cada poder
precisa de um visual "muito louco" na tela, mas barato: formas grandes,
emissivo, anel no chão, rachaduras brilhando, choque elétrico.

## Progressão: o time escolhe qual oficina construir

Igual ao Fat Princess, com uma escolha a mais:

1. **Todos** coletam recursos (madeira e metal) e consertam coisas. O
   Construtor faz isso mais rápido e é o único que constrói.
2. No começo da partida, cada papel tem só a **variação A** no pedestal.
3. O time decide qual **oficina** construir num terreno vazio do castelo:
   "Oficina do Ronin Oni" ou "Oficina da Lâmina Dupla", por exemplo. A oficina
   pronta põe o item daquela variação no pedestal.
4. Terrenos são poucos (ex.: 3 por castelo), então não dá para ter tudo: cada
   partida tem uma composição diferente.
5. Recursos extras sobem o nível da oficina (mais vida/dano para aquela variação).
6. O Construtor também gasta recursos em torretas, minas, barricadas e catapulta.

## Poderes

**Tipos de gatilho** (marcados no quiz): medidor cheio + Q (como hoje), item
no chão, sequência de abates sem morrer, ao morrer (explode), último minuto
(Hora do Caos: todo mundo com medidor cheio).

Regra do Julio: os poderes que já existem são os de carga **rápida**; os mais
fortes saem do resto da lista e carregam mais devagar.

Lista completa marcada no quiz, de onde saem os poderes das variações acima:

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
