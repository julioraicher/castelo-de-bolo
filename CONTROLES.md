# Controles e regras

Os mesmos controles aparecem no jogo em **Controles** (tela inicial e Esc). O menu tem
cinco seções: Começo (modo normal ou teste e o seu time, Azul ou Vermelho), Como jogar
(clipes por tema), Classes (ficha de cada classe com clipe, números e Q/E/R), Controles
e Configurações.

## Teclado e mouse

| Tecla | Ação |
|---|---|
| **W A S D** | andar |
| **Mouse** | mirar (o personagem olha para o cursor) |
| **Clique esquerdo** | atacar (segure para atacar sem parar). Combo de 3: o 3º é o forte (Samurai corta na vertical, Ninja solta um leque, Kitsune uma bola que explode) |
| **Clique direito** (segurar) | **defender** (todas as classes): reduz o dano que vem pela frente e quem bate no escudo quica. Erguido na hora do golpe = **contra-golpe**. Golpes seguidos na defesa **quebram a guarda** (o arco esquenta para laranja antes): atordoa 0,6 s e não defende por 1,2 s. Virado para uma **torreta**, o virote dela **volta** e acerta a torreta |
| **Q** | **habilidade rápida** da classe, recarga curta (barra dourada no HUD). Tabela abaixo |
| **E** | **poder de Chi**, quando o medidor (barra rosa) enche |
| **R** | **SUPER**, quando a barra de ouro enche (só enche jogando: dano, abates, itens, espíritos e captura). Samurai: Passo da Sombra (some 3,5 s, mais rápido, golpe de surpresa x2,5). Outras classes: o poder do E em versão gigante |
| **Espaço** ou **Shift** | esquivar: rolamento rápido, com recarga |
| **F** | pegar um chapéu (perto do pedestal); pegar ou soltar a máscara; perto de um terreno vazio, trocar qual oficina construir; **perto da catapulta da base, subir** (F de novo lança: a barra de força vai e volta e o minimapa mostra onde cai) |
| **F** (segure) | **reanimar** o aliado caído colado em você (chama na cor do time): 3 s, arrastando o corpo se andar; a Kitsune reanima parada e mais rápido. **Caído**, segure F para desistir e renascer no castelo |
| **Tab** (segure) | **placar** estilo Battlefield: pontos, abates, assistências, mortes, dano, almas, toras e obra de cada um (bots e você), com o jogo borrado ao fundo. Abre sozinho no fim da partida |
| **M** / **N** (modo teste) | chama a morte súbita na hora / mostra o letreiro do multikill |
| **Esc** ou **P** | pausar e abrir o menu (Como jogar, Classes, Controles, Configurações) |
| **F5** | reiniciar a partida |
| **F11** | tela cheia (liga/desliga) |
| **Enter** | começar (na tela inicial) |

## Q, E e R por classe

Gerada dos `config/classes/*.tres` por `python3 tools/tabela_classes.py` (rode
depois de mudar uma classe; o menu **Classes** do jogo lê os mesmos arquivos).
Recarga do Q já com o desconto da regra. Heróis raros: um chapéu só por time,
no pavilhão dourado do bairro (nível 6).

<!-- tabela-classes:inicio -->
| Classe | Q: rápido (recarga) | E: Chi (barra cheia) | R: Super (barra dourada) |
|---|---|---|---|
| Samurai | **Investida** (3,1 s): Corte em avanço: atravessa quem estiver na frente. | **Redemoinho**: Gira com a lâmina: dano e empurrão em volta. | **Passo da Sombra**: some por uns segundos, mais rápido, e o golpe de surpresa dói mais |
| Ronin Oni (caminho, Samurai) | **Pisão** (4,9 s): Onda curta que arremessa quem está perto. | **Fúria**: Mais força e vida por alguns segundos. | o E em versão gigante |
| Sohei (caminho, Samurai) | **Varrida** (4,2 s): Giro largo da naginata: fere e empurra quem está na frente e dos lados, e dá escudo aos aliados perto. | **Muralha de Fé**: Anel de fé no chão: aliados dentro ganham escudo e pressa; inimigos são empurrados para fora. | o E em versão gigante |
| Sumotori (herói, Samurai) | **Agarrão** (4,2 s): Agarra quem está na frente e arremessa longe; quem cai em cima também apanha. | **Pisão do Santuário**: Pisão do santuário: dano e arremesso em volta. | **Dohyō**: Ringue de sal: ninguém entra nem sai, e quem está dentro do seu time bate mais forte. |
| Kappa do Rio (herói, Samurai) | **Rasteira do Rio** (3,6 s): Some numa poça e reaparece no pé do inimigo, derrubando. | **Jato d'Água**: Jato d'água em linha: empurra todos de uma vez. | o E em versão gigante |
| Ochimusha (herói, Samurai) | **Flecha Arrancada** (4,8 s): Arranca uma das flechas das costas e crava em quem está na frente: dano e lentidão. As flechas são as cargas do Q. | **Onibi**: Três fogos-fantasma giram em volta e estouram em quem encosta: dano e susto. | **Carga dos Caídos**: Quatro samurais-fantasma avançam em linha e ferem quem estiver na faixa. |
| Shishimai (herói, Samurai) | **Mordida da Sorte** (4,2 s): Morde quem está na frente: aliado cura e ganha Sorte (próximo golpe dobrado); inimigo apanha e ganha Azar (o próximo golpe dele erra). | **Arrastão**: Avança levando o primeiro inimigo na boca (ele larga a máscara) e o prende no fim. | **Festa da Vila**: Vira o leão gigante: dá Sorte aos aliados perto e levanta o aliado caído que alcançar. |
| Ninja de Shuriken | **Shuriken Perfurante** (2,8 s): Tiro cheio que atravessa os inimigos em linha. | **Leque de Shuriken**: Leque de shurikens à frente. | o E em versão gigante |
| Arqueiro Yumi (caminho, Ninja de Shuriken) | **Flecha Perfurante** (3,5 s): Tiro cheio que atravessa os inimigos em linha. | **Chuva de Flechas**: Flechas caem numa área à frente. | o E em versão gigante |
| Kusarigama (caminho, Ninja de Shuriken) | **Gancho** (4,5 s): Lança o peso na mira: o primeiro inimigo na linha apanha, fica preso e é puxado para perto. | **Ciranda de Aço**: Gira a corrente em volta: o peso fere quem está na borda do anel (colado no corpo não corta). | o E em versão gigante |
| Yamabushi do Leque (herói, Ninja de Shuriken) | **Rajada do Leque** (3,6 s): Abano do leque: devolve flechas e empurra quem está na frente. | **Redemoinho**: Redemoinho onde você mira: puxa para o meio e arremessa no fim. | o E em versão gigante |
| Karasu Tengu (herói, Ninja de Shuriken) | **Mergulho** (4,2 s): Sobe ao céu e cai em cima do atirador mais isolado. | **Revoada**: Corvos numa área: quem está dentro fica cego e erra. | **Noite de Corvos**: Três mergulhos seguidos, cada um no inimigo mais perto. |
| Mujina (herói, Ninja de Shuriken) | **Roubar Rosto** (7,1 s): Toca num inimigo e vira ele: os outros não te veem como inimigo até o 1º golpe. | **Susto**: Mostra o rosto vazio: quem está perto foge correndo. | **Passo sem Rosto**: some por uns segundos, mais rápido, e o golpe de surpresa dói mais |
| Jorogumo (herói, Ninja de Shuriken) | **Teia** (3,6 s): Teia no chão: inimigo que pisa fica preso, e ela corre mais rápido em cima. | **Puxar os Fios**: Quem ela marcou com fio, teia ou rede vem para perto e fica preso. | **Casulo**: Os inimigos perto viram casulo: não andam nem atacam até um aliado deles quebrar a seda. |
| Kaminari-kozō (herói, Ninja de Shuriken) | **Para-raios** (4,2 s): Crava uma baqueta de cobre que dá choque em volta e chama a descarga e os raios para ela. | **Relâmpago**: Vira raio e salta em linha até antes da parede, ferindo quem estiver no caminho. | **Tambores do Trovão**: Tempestade: raios caem do céu no inimigo mais perto de você ou de um para-raios seu. |
| Kitsune | **Cura** (2,4 s): Cura quem estiver em volta. | **Coluna de Fogo-Raposa**: Colunas de fogo-raposa onde você mira. | o E em versão gigante |
| Kitsune da Luz (caminho, Kitsune) | **Cura da Luz** (2,1 s): Cura quem estiver em volta. | **Bênção da Raposa**: Cura e escudo nos aliados perto. | o E em versão gigante |
| Kitsune Sombria (caminho, Kitsune) | **Orbe Perfurante** (2,8 s): Tiro cheio que atravessa os inimigos em linha. | **Selo Sombrio**: Inimigos em volta ficam sem atacar. | o E em versão gigante |
| Onmyoji de Papel (herói, Kitsune) | **Dobrar Shikigami** (2,1 s): Dobra um shikigami (até 3) que engole golpes; cheio, solta talismãs que caçam o alvo. | **Grou de Papel**: Grou de papel que atravessa: fere inimigos e cura aliados no caminho. | **Mil Grous**: Revoada de grous em leque: atravessa tudo, fere e cura. |
| Tennin do Manto (herói, Kitsune) | **Laço do Manto** (6 s): Puxa de volta o aliado caído (levanta na hora) ou o ferido longe, curando. | **Dança Celeste**: Dança: cura os aliados em volta enquanto dura. | **Véu Celeste**: Véu do céu: aliados em volta não morrem por alguns segundos. |
| Komusō (herói, Kitsune) | **Canção de Ninar** (4,8 s): Canção: quem estiver na frente dorme até levar um golpe. | **Hipnose**: Puxa os inimigos em volta para perto de você. | **Réquiem**: Réquiem: inimigos em volta ficam sem Q, E e R por alguns segundos. |
| Kodama do Shinboku (herói, Kitsune) | **Raízes** (4,8 s): Raízes rompem o chão em linha: ferem e prendem quem está no caminho. | **Bosque Sagrado**: Três árvores nascem onde você mira: o tronco bloqueia passagem e tiro, e a sombra cura os aliados. | **Floresta Antiga**: Anel de árvores gigantes em volta: as raízes prendem e ferem os inimigos dentro, e os aliados se curam. |
| Construtor | **Estrepes** (2,8 s): Estrepes no chão: dano e lentidão em quem pisa. | **Mutirão**: Adianta a obra perto de você. | o E em versão gigante |
| Armadilheiro (caminho, Construtor) | **Mina** (2,4 s): Mina no chão: explode quando um inimigo pisa. | **Campo Minado**: Minas em volta. | o E em versão gigante |
| Bombardeiro (caminho, Construtor) | **Bomba Grande** (3,5 s): Bomba carregada que explode onde cai: dano em área. | **Bombardeio**: Bombas caem numa área. | o E em versão gigante |
| Predero (herói, Construtor) | **Poça de Cachaça** (4,2 s): Garrafão vira poça na mira: inimigo que pisa derrapa, e qualquer fogo acende a poça. | **Andaime Expresso**: Levanta uma parede de andaime: bloqueia passagem e tiro e empurra quem estava no lugar. | **Saideira**: Garrafas chovem em espiral na mira, cada uma deixa poça, e a última vem acesa e põe fogo nelas. |
| Recruta | (nada) | (nada) | (nada) |
<!-- tabela-classes:fim -->

## Configurações (Esc > Configurações)

Em três grupos: Som, Vídeo e Partida.

| Opção | O que faz |
|---|---|
| Música / Efeitos | 0 a 100% (no zero, muta) |
| Dificuldade dos inimigos | Fácil: bots vermelhos reagem ~2x mais devagar e batem 30% menos. Difícil: reagem ~30% mais rápido e batem 5% mais |
| Qualidade gráfica | Alta: sombras completas e antisserrilhado. Média (padrão no navegador): sombras leves. Baixa: sem sombras, 3D em 75% da resolução. Mínima: 3D em 50% |
| Baixar sozinho se travar | se o FPS ficar abaixo de 40 no começo, o jogo baixa a qualidade sozinho |
| Tema do mapa | Festival ao Sol, Crepúsculo, Floresta Oni ou Templo ao Luar; a partida recomeça. O mapa é um só: Rio das Lanternas |
| Mostrar FPS | mostra quadros por segundo no canto superior esquerdo (60 é o ideal) |
| Tela cheia | também pela tecla F11. No navegador, em tela cheia, segure Esc ou aperte F para sair |
| Tremor da câmera | liga/desliga o "chacoalhar" nos impactos |
| Números de dano | liga/desliga os números que sobem dos golpes |
| Abrir Como jogar ao iniciar | mostra o Como jogar na próxima vez que o jogo abrir |
| Seu time (Começo) | Azul ou Vermelho, na partida normal e no modo teste; `--time=vermelho` ou `?time=vermelho` na web |

As escolhas ficam salvas (no navegador, no próprio navegador).

## Regras em 30 segundos

1. Cada time tem uma **Máscara Oni** no pedestal do seu castelo.
2. **Ponto:** leve a máscara **inimiga** até o pedestal do **seu** castelo.
   Primeiro a 3 vence.
3. Quem carrega a máscara anda mais devagar, não ataca e leva 37% do dano. Com
   um aliado a até 6 m, os dois andam 15% mais rápido (escolta); o 2º e o 3º
   aliados colados somam +6% cada para quem carrega (até +27%). Se morrer, ela cai
   no chão. Um inimigo dela pode pegar de novo; um aliado dela fica ao lado por
   4 s para devolvê-la (mais gente não acelera). Se ninguém mexer, ela volta
   sozinha depois de 25 s. A seta dourada mostra onde está a máscara fora do pedestal.
4. **Chapéus** saem das maquininhas do pátio: chegue perto e aperte **F**.
   - No começo: Samurai (Redemoinho), Ninja de Shuriken (Leque), Kitsune
     (Colunas de fogo-raposa; cura) e Construtor (corta madeira e constrói; Mutirão).
   - Cada classe tem um **bairro** no pátio. A barraquinha sobe ao nível 2; no 3
     o Construtor escolhe um de dois **caminhos**, que ganha casa própria e sobe
     até o nível 5: Samurai → Ronin Oni (Fúria) ou Sohei (Muralha); Ninja de
     Shuriken → Arqueiro Yumi (Chuva de flechas) ou Kusarigama (Ciranda);
     Kitsune → Kitsune da Luz (Bênção: cura + escudo) ou Kitsune Sombria (Selo:
     inimigos sem atacar); Construtor → Armadilheiro (minas) ou Bombardeiro (bombas).
   - **Nível 6** (bairro no 5): o Construtor escolhe um **herói raro** da classe
     (6 madeiras), que sobe num pavilhão dourado com um chapéu só. Ele volta 20 s
     depois que o herói sai de campo. O Construtor tem um herói só: o Predero.
   - Recruta (sem chapéu): rápido, socos em combo, sem poder.
   - O medidor de **Chi** enche batendo, apanhando, abatendo, entregando
     espírito e capturando a máscara. Cheio, aperte E.
5. **Oficinas:** Construtores cortam árvores, levam as toras ao depósito e
   erguem as casinhas do pátio; pronta, ela libera a maquininha da classe. Perto
   de um terreno vazio, **F** troca qual classe construir.
6. **Espíritos** (chamas verdes) aparecem no meio do mapa. Levar um até a
   **sua** máscara a deixa mais pesada: quem a carrega fica mais lento. Cada abate
   também manda uma alma pequena para a máscara de quem matou (20 abates = um
   espírito), mas as almas só enchem até 75% do peso: dali para cima, só espírito.
7. **Itens no chão** aparecem de vez em quando no meio do mapa: poção, escudo,
   velocidade, kunai (dano 2x por 6 s) e chama de chi (enche o medidor).
8. Morreu? Volta em alguns segundos como recruta no seu castelo.
9. **Relógio de 20 minutos** no topo. No **último minuto** as duas máscaras
   perdem todo o peso (empatado ou não): o fim é corrida. No zero vence quem tem
   mais pontos. Se uma máscara fora do castelo (na mão ou caída) ainda empata ou
   vira o jogo para quem a roubou, a partida segue em **PRORROGAÇÃO** até ela
   voltar ao castelo (entregue, devolvida ou de volta sozinha; na mão, trava de
   segurança de 3 min). Placar igual no fim abre a **MORTE SÚBITA**: 2 min e o
   primeiro ponto vence. Ninguém pontuou nem assim: vence o time com mais pontos
   no placar do Tab. No modo teste, **M** perto de uma máscara chama a morte
   súbita na hora e **L** liga o relógio a 1:10 do fim.
10. **Multikill**: abate até 5 s depois do anterior continua a corrente. Abate vale
   120 no placar; duplo +50, triplo +100 e do 4º em diante +150 cada.

Para mudar teclas ou números, veja o [GUIA.md](GUIA.md).

## Classes (Ciclo 2.10)

- **Atirar deixa lento**: por 0,4 s depois de cada tiro, quem atira anda a 80%.
  O atirador escolhe entre correr e atirar; quem é de perto alcança.
- **Samurai**: golpe pelas costas ou pelo lado do alvo dá +25% de dano.
- **Ninja de Shuriken**: o mais rápido e frágil; o shuriken perde força de longe
  (100% até 8 m, 80% no alcance máximo).
- **Ronin Oni**: o grandão, com mais vida e mais lento que todos.
