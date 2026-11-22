# AOC-Assembly-Game

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

O estado `BOSS_MORTO` esta preparado: o sistema de dano devera definir
`boss_estado` para esse valor quando o boss for derrotado. Ainda nao existe
uma condicao de morte automatica, pois vida e dano nao foram implementados.

O alcance inicial e `BOSS_DASH_DISTANCIA = 180` pixels. A direcao e calculada
quando o dash comeca e fica fixa durante o avanco. A distancia e a mesma nas
diagonais; contato com o jogador ou com o limite da arena interrompe o dash e
inicia a vulnerabilidade. Ainda nao ha dano nem tratamento de pedra/fogueira
para o dash. A vulnerabilidade identifica o estado para integrar o dano depois.

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

