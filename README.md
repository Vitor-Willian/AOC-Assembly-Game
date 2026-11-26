# AOC-Assembly-Game

## Controles e reinicio

- **WASD**: movimentar o rei.
- **Setas**: atacar na direcao indicada.
- **R** (desenvolvimento): reiniciar a partida a qualquer momento, inclusive depois de morrer
  ou derrotar o boss, sem fechar a janela. Manter a tecla pressionada nao
  dispara reinicios repetidos.
- **I** (desenvolvimento): ligar/desligar a imunidade ao dano do boss, incluindo
  o dash. A colisao fisica continua ativa. Funciona com o rei vivo e nao revive
  um personagem morto. Segurar a tecla nao alterna repetidamente.
- **Esc**: sair.

O jogo comeca no mapa da fogueira. Saia pela abertura no centro do topo para
entrar na arena do primeiro boss pelo centro inferior. O rei caminha
automaticamente na diagonal ate o lado esquerdo, usando os frames de
caminhada. Ao chegar, o boss emerge no lado direito com as sprites de ataque
4, 5 e 6. Depois da animacao e da pausa, os controles e o combate sao liberados.
A base do trofeu central bloqueia a passagem do jogador no segundo mapa.
Sua hitbox usa as constantes `TROFEU_*` nos dois arquivos Assembly.
Durante toda a introducao, nao ha ataques nem dano; **R** e **Esc** continuam ativos.

O reinicio com **R** volta para a fogueira e restaura os personagens e os
temporizadores. A passagem para a arena preserva a imunidade de desenvolvimento.
A caminhada usa `VEL`; o tempo de cada sprite de entrada do boss usa
`INTRO_BOSS_POR_FRAME`, e a pausa final usa `INTRO_PAUSA_QUADROS` em ambos os
arquivos Assembly. O rei morto usa
`assets/sprites/Rei-morte.bmp`; o boss derrotado permanece no chao com
`boss1morte.bmp`, sem movimento, dano ou colisao.

### Remover os atalhos de desenvolvimento

No inicio de `game.asm`, altere `%define DESENVOLVIMENTO 1` para
`%define DESENVOLVIMENTO 0` e recompile com `make`. Isso exclui da compilacao
os atalhos **I** e **R**, a variavel e a verificacao de imunidade, e as dicas
desses atalhos no titulo da janela. A inicializacao normal do jogo permanece.

A imunidade comeca desligada e volta a ficar desligada ao reiniciar com **R**.
O titulo da janela indica o estado atual. Para reativar os recursos de teste,
volte a configuracao para `1` e recompile.

## Primeiro boss: ciclo de ataque

O boss persegue o jogador com metade da velocidade do player. Depois de um
periodo de perseguicao, para para carregar, executa um dash e fica vulneravel
antes de voltar a perseguir. Os ajustes ficam nas constantes `BOSS_*` em `game.asm`.

| Etapa | Sprite | Ajuste inicial |
|---|---|---|
| Perseguicao | `boss1andando.bmp` | `BOSS_ESPERA_QUADROS = 250` (aproximadamente 4 s) |
| Carga, sem movimento | `boss1ataque1.bmp` (aviso), depois `ataque2` a `ataque6` | `BOSS_CARGA_POR_FRAME = 10` (aproximadamente 0,96 s no total) |
| Dash | `boss1dash1.bmp` e `boss1dash2.bmp`, metade do tempo em cada | `BOSS_DASH_QUADROS = 20` (aproximadamente 0,32 s) |
| Vulnerabilidade, sem movimento | `boss1Vulnerável.bmp` | `BOSS_VULNERAVEL_QUADROS = 94` (aproximadamente 1,5 s) |
| Morto | `boss1morte.bmp` | Permanente, sem perseguicao, ataques ou bloqueio do jogador |

Os 11 bitmaps sao carregados no inicio. As poses vulneravel e morta sao
recortadas apenas na renderizacao e alinhadas pela linha dos pes, sem alterar
os arquivos ou a escala dos pixels. Isso compensa a margem diferente da pose
vulneravel e a tela de 512 x 512 da morte. Os recortes estao em
`boss_vulneravel_src` e `boss_morte_src`; se o desenho mudar de lugar no arquivo,
esses retangulos precisam acompanhar a alteracao.

Um ataque que acerta o boss durante a vulnerabilidade ativa `BOSS_MORTO`.
O contato com o boss vivo derrota o rei e interrompe o combate ate reiniciar.

O alcance inicial e `BOSS_DASH_DISTANCIA = 180` pixels. A direcao e calculada
quando o dash comeca e fica fixa durante o avanco. A distancia e a mesma nas
diagonais; contato com o jogador ou com o limite da arena interrompe o dash e
inicia a vulnerabilidade. Ainda nao ha tratamento de pedra/fogueira para o dash.

A espera de 4 s recomeca somente quando a vulnerabilidade termina. Um ciclo
completo sem interrupcao dura aproximadamente 6,8 s. Os tempos usam contagem
de quadros e o `SDL_Delay(16)` existente, portanto aumentam se o jogo ficar lento.
Mantenha as duracoes positivas e pelo menos dois quadros para o dash.

Para ajustar o alcance, altere `BOSS_DASH_DISTANCIA`. Para ajustar a rapidez do
avanco, altere `BOSS_DASH_QUADROS`: menos quadros deixam o dash mais rapido.
Evite passos maiores que a hitbox do jogador sem adicionar colisao por varredura,
pois um salto muito grande entre quadros pode atravessar o jogador.

## Compilar e executar

Com o Makefile:

```bash
make          # compila
./game        # executa
make run      # compila (se preciso) e executa
make clean    # apaga game e game.o
```

