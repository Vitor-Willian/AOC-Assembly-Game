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
- **Esc**: abrir o menu de pausa ou retomar a partida.

## Menu de pausa

Use **W/S** ou **setas para cima/baixo** para selecionar e **Enter** para confirmar:

- **Retomar**: continua exatamente de onde parou.
- **Menu principal — em breve**: reservado para o futuro menu; por enquanto,
  confirmar essa opcao mantem o jogo pausado.
- **Sair do jogo**: fecha o jogo.

A pausa funciona nos dois mapas, durante a introducao e depois da morte.
Movimento, ataques, dano, animacoes e temporizadores ficam congelados; musica
e efeitos sonoros tambem pausam. Os atalhos **R/I** ficam bloqueados no menu.
Ao retomar, solte as teclas de navegacao para evitar um ataque involuntario.
O menu usa apenas o teclado e e compartilhado por Linux e Windows em
`pause_menu.inc`, com uma fonte simples desenhada pelo SDL, sem dependencias extras.

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

## Introducao da arena

O jogo abre no mapa da fogueira (`chao.bmp`). Ao sair pelo topo, o rei entra
pela parte inferior da arena (`chao2.bmp`) e caminha automaticamente na diagonal
ate o lado esquerdo. Depois, o boss emerge do solo a direita usando
`boss1ataque4.bmp`, `boss1ataque5.bmp` e `boss1ataque6.bmp`, nessa ordem.
A parte ainda enterrada fica escondida por um recorte; a sprite sobe sem
mudar de escala.

O controle manual, os ataques e o dano ficam suspensos durante a entrada.
Depois da animacao do boss, ha uma breve pausa antes de liberar o combate;
a espera pelo primeiro ataque so comeca depois da introducao. **Esc** continua
funcionando, e **R**, no modo de desenvolvimento, volta para a fogueira.

Os ajustes ficam em `game.asm` e `game_win.asm`: `VEL` controla a caminhada,
`INTRO_BOSS_POR_FRAME` define 25 quadros por pose do boss (75 no total) e
`INTRO_PAUSA_QUADROS` define a pausa final de 24 quadros. `INTRO_BOSS_BASE_Y`
marca a linha logo abaixo dos pes nas tres imagens (108 pixels).

`ReiniciarPartida` prepara o estado completo na fogueira; `IniciarEntradaArena`
inicia a introducao na passagem entre mapas, e `AtualizarEntradaArena` avanca
a animacao no loop normal. A musica acompanha a troca de mapa e o reinicio.

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

No Ubuntu/WSL, instale as dependencias antes de compilar:

```bash
sudo apt update
sudo apt install build-essential nasm libsdl2-dev libsdl2-mixer-dev
```

O pacote `libsdl2-mixer-dev` e necessario para os sons e a musica. Se aparecer
`cannot find -lSDL2_mixer`, instale esse pacote no mesmo Ubuntu/WSL em que
executa o `make`, depois rode `make run` novamente.

Com o Makefile:

```bash
make          # compila
./game        # executa
make run      # compila (se preciso) e executa
make clean    # apaga game e game.o
```

