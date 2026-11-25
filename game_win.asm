default rel

%macro chamar 1
    sub  rsp, 48
    mov  [rsp+40], r9
    mov  [rsp+32], r8
    mov  r9, rcx
    mov  r8, rdx
    mov  rdx, rsi
    mov  rcx, rdi
    call %1
    add  rsp, 48
%endmacro
; Mude para 0 e recompile para remover os atalhos I/R e a imunidade de teste.
%define DESENVOLVIMENTO 1

extern SDL_SetWindowTitle
extern SDL_RenderSetLogicalSize
extern SDL_GetKeyboardState

extern Mix_OpenAudio, Mix_LoadWAV_RW, Mix_LoadMUS
extern Mix_PlayChannelTimed, Mix_PlayMusic, Mix_VolumeMusic, Mix_PlayChannel
extern Mix_FreeChunk, Mix_FreeMusic, Mix_CloseAudio
extern Mix_AllocateChannels

extern SDL_Init, SDL_CreateWindow, SDL_CreateRenderer
extern SDL_PollEvent
extern SDL_SetRenderDrawColor, SDL_RenderClear, SDL_RenderPresent, SDL_Delay
extern SDL_RWFromFile, SDL_LoadBMP_RW, SDL_CreateTextureFromSurface, SDL_FreeSurface
extern SDL_QueryTexture, SDL_RenderCopy, SDL_DestroyTexture
extern SDL_DestroyRenderer, SDL_DestroyWindow, SDL_Quit
extern SDL_RenderDrawRect   ; só pra testar
global main

SDL_INIT_VIDEO     equ 0x20
WINDOWPOS_CENTERED equ 0x2FFF0000
SDL_WINDOW_SHOWN   equ 4
SDL_QUIT           equ 0x100

SDL_INIT_AUDIO equ 0x10
MIX_DEFAULT_FORMAT equ 0x8010    ; AUDIO_S16LSB

SDL_WINDOW_FULLSCREEN_DESKTOP equ 0x1001
SDL_KEYDOWN                   equ 0x300
SDLK_ESCAPE                   equ 27
W equ 800
H equ 450

VEL    equ 3        ; velocidade em pixels por quadro
SC_W   equ 26       ; scancodes (posição física da tecla)
SC_A   equ 4
SC_S   equ 22
SC_D   equ 7
%if DESENVOLVIMENTO
SC_R   equ 21       ; reinicia a partida (somente desenvolvimento)
SC_I   equ 12       ; alterna imunidade ao boss (somente desenvolvimento)
%endif
SC_LEFT  equ 80
SC_RIGHT equ 79
SC_UP    equ 82
SC_DOWN  equ 81

BOXREI_A equ 30     ; altura da hitbox do rei 
BOXREI_L equ 20     ; largura da hitbox

; Rei no lado esquerdo, centralizado verticalmente pela hitbox.
REI_INICIO_X equ W / 5 - BOXREI_L / 2
REI_INICIO_Y equ (H - BOXREI_A) / 2

BOSS_HITBOX_L equ 30  
BOSS_HITBOX_A equ 50

; Centro visivel do frame 1 dentro da imagem de 200 x 225 (inclui margens).
BOSS_CENTRO_X equ 116
BOSS_CENTRO_Y equ 74

; Ajustes do combate em quadros (cada quadro tem SDL_Delay de 16 ms + desenho).
BOSS_PERSEGUIR equ 0
BOSS_CARREGAR equ 1
BOSS_DASH equ 2
BOSS_VULNERAVEL equ 3
BOSS_MORTO equ 4
BOSS_FRAME_ANDANDO equ 0
BOSS_FRAME_CARGA equ 1
BOSS_CARGA_FRAMES equ 6
BOSS_FRAME_DASH equ 7
BOSS_FRAME_VULNERAVEL equ 9
BOSS_FRAME_MORTE equ 10
BOSS_TOTAL_FRAMES equ 11
BOSS_PE_Y equ 100               ; linha dos pes nas sprites de movimento/ataque
; Boss no lado direito; desconta as margens transparentes da sprite.
BOSS_INICIO_X equ W * 4 / 5 - BOSS_CENTRO_X
BOSS_INICIO_Y equ H / 2 - BOSS_CENTRO_Y
BOSS_ESPERA_QUADROS equ 160       ; cerca de 4 s perseguindo entre ataques
BOSS_CARGA_POR_FRAME equ 5       ; ataque1 a ataque6: cerca de 0,96 s no total
BOSS_DASH_QUADROS equ 15          ; cerca de 0,32 s, dash1 e dash2
BOSS_DASH_DISTANCIA equ 170       ; pixels, igual em qualquer direcao
BOSS_VULNERAVEL_QUADROS equ 20    ; cerca de 0,75 s com a sprite vulneravel
PLAYER_ATAQUE_INTERVALO equ 20  ; quadros entre o inicio de dois ataques
BOSS_HITBOX_X equ 100
BOSS_HITBOX_Y equ 50

WALL1_X equ 0       ; parede esquerda
WALL1_Y equ 0
WALL1_A equ 450
WALL1_L equ 40

WALL2_X equ 0       
WALL2_Y equ 0
WALL2_A equ 30
WALL2_L equ 380

WALL5_X equ 435   
WALL5_Y equ 0
WALL5_A equ 30
WALL5_L equ 370

WALL3_X equ 0       
WALL3_Y equ 420
WALL3_A equ 30
WALL3_L equ 800

WALL4_X equ 770     
WALL4_Y equ 0
WALL4_A equ 450
WALL4_L equ 30

CAMP_X  equ 410
CAMP_Y  equ 245
CAMP_A  equ 15
CAMP_L  equ 25

SWIPE_DIST equ 2

section .data
%if DESENVOLVIMENTO
    titulo      db "O Retorno do Rei - R: reiniciar | I: imunidade DESLIGADA", 0
    titulo_imune db "O Retorno do Rei - R: reiniciar | I: imunidade LIGADA", 0
    titulo_derrota db "O Retorno do Rei - Voce morreu! R para reiniciar | ESC para sair", 0
%else
    titulo      db "O Retorno do Rei", 0
    titulo_derrota db "O Retorno do Rei - Voce morreu! ESC para sair", 0
%endif
    rei_bmp db "assets/sprites/Rei.bmp", 0
    rei_morte_bmp db "assets/sprites/Rei-morte.bmp", 0
    reiC1_bmp db "assets/sprites/Rei C1.bmp", 0
    reiC2_bmp db "assets/sprites/Rei C2.bmp", 0
    reiAUp_bmp db "assets/sprites/Rei Atk Up.bmp", 0
    reiADwn_bmp db "assets/sprites/Rei Atk Dwn.bmp", 0
    reiAEsq_bmp db "assets/sprites/Rei Atk Esq.bmp", 0
    reiADir_bmp db "assets/sprites/Rei Atk Dir.bmp", 0

    atk_swipeUp db "assets/effects/Atk Swipe Up.bmp", 0
    atk_swipeDwn db "assets/effects/Atk Swipe Dwn.bmp", 0
    atk_swipeEsq db "assets/effects/Atk Swipe Esq.bmp", 0
    atk_swipeDir db "assets/effects/Atk Swipe Dir.bmp", 0

    boss_bmp db "assets/sprites/boss1/boss1andando.bmp", 0
    boss_ataque1_bmp db "assets/sprites/boss1/boss1ataque1.bmp", 0
    boss_ataque2_bmp db "assets/sprites/boss1/boss1ataque2.bmp", 0
    boss_ataque3_bmp db "assets/sprites/boss1/boss1ataque3.bmp", 0
    boss_ataque4_bmp db "assets/sprites/boss1/boss1ataque4.bmp", 0
    boss_ataque5_bmp db "assets/sprites/boss1/boss1ataque5.bmp", 0
    boss_ataque6_bmp db "assets/sprites/boss1/boss1ataque6.bmp", 0
    boss_dash1_bmp db "assets/sprites/boss1/boss1dash1.bmp", 0
    boss_dash2_bmp db "assets/sprites/boss1/boss1dash2.bmp", 0
    ; Nome original com acento em UTF-8, como esperado pelo SDL no Linux.
    boss_vulneravel_bmp db "assets/sprites/boss1/boss1Vulner", 0xC3, 0xA1, "vel.bmp", 0
    boss_morte_bmp db "assets/sprites/boss1/boss1morte.bmp", 0
    boss_arquivos dq boss_bmp, boss_ataque1_bmp, boss_ataque2_bmp, boss_ataque3_bmp
                  dq boss_ataque4_bmp, boss_ataque5_bmp, boss_ataque6_bmp
                  dq boss_dash1_bmp, boss_dash2_bmp, boss_vulneravel_bmp, boss_morte_bmp
    ; Recortes em pixels dos desenhos novos, sem alterar os arquivos originais.
    boss_vulneravel_src dd 38, 50, 46, 54
    boss_morte_src dd 34, 343, 28, 33
    ; Posicao da imagem completa; o corpo comeca 88 px a direita e 41 px abaixo.
    boss_rect dd BOSS_INICIO_X, BOSS_INICIO_Y, 0, 0
    modo_leitura db "rb", 0
    img_mode db "rb", 0
    img_file db "assets/background/chao.bmp", 0 
    img_file2 db "assets/background/chao960.bmp", 0       ; novo mapa
    cena_atual db 0

    snd_golpe_f   db "assets/sounds/sfx/swipe_fix.wav", 0

    percival_theme_f      db "assets/sounds/music/Percival.ogg", 0   ; ajuste nome e pasta

section .bss
    tex_w         resd 1   ; largura da imagem (preenchido por SDL_QueryTexture)
    tex_h         resd 1   ; altura da imagem
    idle_w        resd 1   ; largura do sprite parado
    idle_h        resd 1   ; altura do sprite parado

    king_idle     resq 1   ; textura do Rei.bmp (sprite parado)
    king_morte    resq 1   ; textura do Rei-morte.bmp
    king_atk_u    resq 1   ; textura do Rei Atk Up.bmp (ataque para cima)
    king_atk_d    resq 1   ; textura do Rei Atk Dwn.bmp (ataque para baixo)
    king_atk_l    resq 1   ; textura do Rei Atk Esq.bmp (ataque para esquerda)
    king_atk_r    resq 1  ; textura do Rei Atk Dir.bmp (ataque para direita)
    king_walk     resq 2   ; [0] = Rei C.bmp, [1] = Rei C2.bmp

    boss_texturas resq BOSS_TOTAL_FRAMES
    boss_frame    resd 1   ; indice na tabela boss_arquivos (BOSS_FRAME_*)
    boss_desenho_rect resd 4 ; destino visual, independente da posicao/hitbox
    boss_estado   resd 1   ; inicia em BOSS_PERSEGUIR
    boss_contador resd 1   ; quadros no estado atual
    boss_dash_x   resd 1   ; posicao fracionaria durante o dash (float)
    boss_dash_y   resd 1
    boss_dash_vx  resd 1   ; direcao/velocidade fixadas no inicio do dash
    boss_dash_vy  resd 1
    boss_meio_passo resd 1 ; acumula a metade de pixel restante entre quadros
    percival_vivo resd 1   ; 0 = morto, 1 = vivo
    percival_hitbox resd 4   ; hitbox do boss (x, y, w, h)

    frame_atual   resd 1   ; 0 ou 1 (qual das duas está ativa)
    cont_anim     resd 1   ; quadros passados desde a última troca
    movendo       resd 1   ; 0 = parado, 1 = se moveu neste quadro
    walk_delay    equ 8    ; trocar de frame a cada X quadros

    rei_morto     resd 1   ; 1 = derrotado por contato com o boss
%if DESENVOLVIMENTO
    dev_imune     resd 1   ; 1 = ignora dano do boss, sem remover a colisao
%endif
    rei_x         resd 1   ; posisão x hitbox
    rei_y         resd 1   ; posisão y hitbox

    ataque_cooldown resd 1 ; nao zera ao soltar as setas
    atk_dir       resd 1   ; direção do ataque (0= não, 1=esquerda, 2=direita, 3=cima, 4=baixo)
    atacou        resd 1   ; 0 = não atacou, 1 = atacou
    atk_fr        equ 12   ; frames que o ataque dura (1/60s cada)
    ataque_timer  resd 1    ; conta quantos frames faltam para terminar o ataque

    atk_swipe_u    resq 1   ; textura do efeito de ataque para cima
    atk_swipe_d    resq 1   ; textura do efeito de ataque para baixo
    atk_swipe_l    resq 1   ; textura do efeito de ataque para esquerda
    atk_swipe_r    resq 1   ; textura do efeito de ataque para direita
    swipe_atual    resq 1   ; textura do efeito de ataque atual (usada no desenho)
    atk_hitbox     resd 4   ; hitbox do ataque (x, y, w, h)

    percival_theme resq 1

    snd_golpe     resq 1

section .text
; Pilha em main:
; [rsp+0  .. rsp+63] SDL_Event
; [rsp+64 .. rsp+79] SDL_Rect de destino (onde o sprite será desenhado)
main:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi
    sub  rsp, 80         ; <- era 80

    ; Inicializa o SDL com vídeo e áudio
    mov  edi, SDL_INIT_VIDEO | SDL_INIT_AUDIO
    chamar SDL_Init

    ; Mix_OpenAudio(frequency, format, channels, chunksize)
    mov  edi, 44100
    mov  esi, MIX_DEFAULT_FORMAT
    mov  edx, 2                   ; estéreo
    mov  ecx, 512            ; buffer
    chamar Mix_OpenAudio

    mov  edi, 16
    chamar Mix_AllocateChannels

    lea  rdi, [titulo]
    mov  esi, WINDOWPOS_CENTERED
    mov  edx, WINDOWPOS_CENTERED
    mov  ecx, W
    mov  r8d, H
    mov  r9d, SDL_WINDOW_SHOWN | SDL_WINDOW_FULLSCREEN_DESKTOP
    chamar SDL_CreateWindow
    mov  rbx, rax

    mov  rdi, rbx
    mov  esi, -1
    xor  edx, edx
    chamar SDL_CreateRenderer
    mov  r12, rax
    mov  rdi, r12
    mov  esi, W              ; 640
    mov  edx, H              ; 480
    chamar SDL_RenderSetLogicalSize

    ; ---- chão ----

    lea  rdi, [img_file]
    call CarregarTextura
    mov  r15, rax                   ; r15 = textura do chão


    ; ---- carrega o sprite ----
    ; sprite parado
    lea  rdi, [rei_bmp]
    call CarregarTextura
    mov  r14, rax                   ; r14 = textura atual (usada no desenho)
    mov  [king_idle], rax          ; cópia guardada

    lea  rdi, [rei_morte_bmp]
    call CarregarTextura
    mov  [king_morte], rax

    ; andando, frame 0
    lea  rdi, [reiC1_bmp]
    call CarregarTextura
    mov  [king_walk], rax

    ; andando, frame 1
    lea  rdi, [reiC2_bmp]
    call CarregarTextura
    mov  [king_walk + 8], rax     ; +8: segundo ponteiro do array

    ; Carrega todos os frames antes de usar r13 para o teclado.
    xor  r13d, r13d
.carrega_boss:
    lea  rax, [boss_arquivos]
    mov  rdi, [rax + r13*8]
    call CarregarTextura
    lea  rcx, [boss_texturas]
    mov  [rcx + r13*8], rax
    inc  r13d
    cmp  r13d, BOSS_TOTAL_FRAMES
    jl   .carrega_boss

    mov rdi, [boss_texturas]
    xor esi, esi
    xor edx, edx
    lea rcx, [boss_rect + 8]
    lea r8, [boss_rect + 12]
    chamar SDL_QueryTexture

    ; ataque
    lea rdi, [reiAUp_bmp]
    call CarregarTextura
    mov [king_atk_u], rax

    lea rdi, [reiADwn_bmp]
    call CarregarTextura
    mov [king_atk_d], rax

    lea rdi, [reiAEsq_bmp]
    call CarregarTextura
    mov [king_atk_l], rax

    lea rdi, [reiADir_bmp]
    call CarregarTextura
    mov [king_atk_r], rax

    lea  rdi, [atk_swipeUp]
    call CarregarTextura
    mov  [atk_swipe_u], rax

    lea rdi, [atk_swipeDwn]
    call CarregarTextura
    mov  [atk_swipe_d], rax

    lea rdi, [atk_swipeEsq]
    call CarregarTextura
    mov  [atk_swipe_l], rax

    lea rdi, [atk_swipeDir]
    call CarregarTextura
    mov  [atk_swipe_r], rax

    ; Sons e Musica
    lea rdi, [snd_golpe_f]
    call CarregarSom
    mov [snd_golpe], rax
    test rax, rax
    jz .audio_indisponivel

    jmp .audio_carregado

.audio_indisponivel:
        mov qword [snd_golpe], 0

.audio_carregado:

     ; Música de fundo
    lea  rdi, [percival_theme_f]
    chamar Mix_LoadMUS             ; já recebe o caminho direto, sem RWFromFile
    mov  [percival_theme], rax
    test rax, rax
    jz   .sem_musica             ; arquivo não encontrado: segue sem música

    mov  rdi, rax                ; Mix_Music*
    mov  esi, -1                 ; -1 = loop infinito
    chamar Mix_PlayMusic

    mov  edi, 40                 ; volume da música (0 a 128)
    chamar Mix_VolumeMusic
.sem_musica:

    ; pega o tamanho real da imagem, para não distorcer o sprite
    mov  rdi, r14
    xor  esi, esi                ; format (NULL, não precisamos)
    xor  edx, edx                ; access (NULL)
    lea  rcx, [tex_w]
    lea  r8,  [tex_h]
    chamar SDL_QueryTexture

    ; monta o retângulo de destino: centralizado, com o tamanho da imagem
    mov eax, [tex_w]
    mov [idle_w], eax            ; guarda largura do sprite parado

    mov eax, [tex_h]
    mov [idle_h], eax            ; guarda altura do sprite parado

    xor  edi, edi
    chamar SDL_GetKeyboardState    ; devolve ponteiro para um array de bytes
    mov  r13, rax                ; r13 = estado do teclado
    jmp  .reiniciar

.loop:
.eventos:
    mov  rdi, rsp
    chamar SDL_PollEvent
    test eax, eax
    jz   .teclado           ; <- antes era .desenha
    cmp  dword [rsp], SDL_QUIT
    je   .fim
    cmp  dword [rsp], SDL_KEYDOWN       ; foi uma tecla pressionada?
    jne  .eventos
    cmp  dword [rsp+20], SDLK_ESCAPE    ; era o ESC?
    je   .fim
%if DESENVOLVIMENTO
    cmp  byte [rsp+13], 0              ; uma acao por pressionamento, sem repeticao
    jne  .eventos
    cmp  dword [rsp+16], SC_R          ; scancode de R, inclusive com Shift
    je   .reiniciar
    cmp  dword [rsp+16], SC_I
    jne  .eventos
    cmp  dword [rei_morto], 0          ; imunidade nao revive o rei
    jne  .eventos
    xor  dword [dev_imune], 1
    mov  rdi, rbx
    lea  rsi, [titulo]
    cmp  dword [dev_imune], 0
    je   .dev_atualiza_titulo
    lea  rsi, [titulo_imune]
.dev_atualiza_titulo:
    chamar SDL_SetWindowTitle
%endif
    jmp  .eventos

.reiniciar:
    ; Reutiliza janela e sprites; so restaura o fundo se mudou de cenario.
    cmp  byte [cena_atual], 0
    je   .reiniciar_estado
    mov  rdi, r15
    chamar SDL_DestroyTexture
    lea  rdi, [img_file]
    call CarregarTextura
    mov  r15, rax
.reiniciar_estado:
    call ReiniciarPartida
    mov  r14, [king_idle]
    mov  rdi, rbx
    lea  rsi, [titulo]
    chamar SDL_SetWindowTitle
    jmp  .eventos

.teclado:
    cmp dword [rei_morto], 0
    jne .rei_derrotado
    cmp dword [ataque_cooldown], 0
    je .cooldown_atualizado
    dec dword [ataque_cooldown]
.cooldown_atualizado:
    mov  r8d, [rei_x]              ; x antigo (antes era rsp+64) 
    mov  r9d, [rei_y]              ; y antigo (rsp+68)
    mov  r10d, [atk_dir]           ; direção do ataque

    ; ---- lê as teclas e altera x, y ----
    cmp  byte [r13 + SC_W], 0
    je   .sem_w
    sub  dword [rei_y], VEL        ; W: sobe (y diminui)    trocado 
.sem_w:
    cmp  byte [r13 + SC_S], 0
    je   .sem_s
    add  dword [rei_y], VEL        ; S: desce (y aumenta)
.sem_s:
    cmp  byte [r13 + SC_A], 0
    je   .sem_a
    sub  dword [rei_x], VEL        ; A: esquerda (x diminui)
.sem_a:
    cmp  byte [r13 + SC_D], 0
    je   .sem_d
    add  dword [rei_x], VEL        ; D: direita (x aumenta)
.sem_d:

    ; ---- atualiza a direção do ataque ----

; Verifica se alguma seta está pressionada
    mov eax, 0
    cmp byte [r13 + SC_LEFT], 0
    jne .tem_seta
    cmp byte [r13 + SC_RIGHT], 0
    jne .tem_seta
    cmp byte [r13 + SC_UP], 0
    jne .tem_seta
    cmp byte [r13 + SC_DOWN], 0
    jne .tem_seta

    ; Nenhuma seta pressionada:
    ; permite um novo ataque
    mov dword [atk_dir], 0
    mov dword [atacou], 0
    mov dword [ataque_timer], 0
    jmp .fim_ataque

.tem_seta:
    ; Se já atacou nesta pressionada, fica no idle
    cmp dword [atacou], 1
    je .ja_atacou
    cmp dword [ataque_cooldown], 0
    jne .termina_ataque

    ; Escolhe a direção do ataque
    cmp byte [r13 + SC_LEFT], 0
    je .verifica_direita
    mov dword [atk_dir], 1
    jmp .marca_ataque

.verifica_direita:
    cmp byte [r13 + SC_RIGHT], 0
    je .verifica_cima
    mov dword [atk_dir], 2
    jmp .marca_ataque

.verifica_cima:
    cmp byte [r13 + SC_UP], 0
    je .verifica_baixo
    mov dword [atk_dir], 3
    jmp .marca_ataque

.verifica_baixo:
    mov dword [atk_dir], 4

.marca_ataque:
    mov dword [ataque_cooldown], PLAYER_ATAQUE_INTERVALO
    mov dword [atacou], 1
    mov dword [ataque_timer], atk_fr

    cmp qword [snd_golpe], 0
    je .fim_ataque

    mov rdi, [snd_golpe]
    call TocarSom
    jmp .fim_ataque

.ja_atacou:
    cmp dword [ataque_timer], 0
    je  .termina_ataque

    dec dword [ataque_timer]
    ; Mantém atk_dir diferente de zero,
    ; portanto continua mostrando o ataque
    jmp .fim_ataque

.termina_ataque:
    mov dword [atk_dir], 0
    mov qword [swipe_atual], 0
    mov dword [atk_hitbox], 0
    mov dword [atk_hitbox + 4], 0
    mov dword [atk_hitbox + 8], 0
    mov dword [atk_hitbox + 12], 0

    mov dword [atk_dir], 0

.fim_ataque:


    ; ---- limita x entre 0 e W - largura ----
    mov  eax, [rei_x]
    test eax, eax
    jge  .x_min_ok
    xor  eax, eax                   ; passou da esquerda: x = 0
.x_min_ok:
    mov  ecx, W
    sub  ecx, BOXREI_L               ; x máximo trocado [tex_w] -> BOXREI_L
    cmp  eax, ecx
    jle  .x_max_ok       
    mov  eax, ecx                   ; passou da direita: x = máximo          
.x_max_ok:
    mov  [rei_x], eax

    ; ---- limita y entre 0 e H - altura ----
.y_limit_start:  
    mov  eax, [rei_y]
    test eax, eax
    jge  .y_min_ok
    cmp byte [cena_atual], 0  ; vê se tá no mapa 0 
    je .trocar_cena2            ; troca cena
    xor  eax, eax
    jmp .y_min_ok

.trocar_cena2:
    mov byte [cena_atual], 1        
    mov dword [rei_x], W / 2 - BOXREI_L / 2   
    mov dword [rei_y], H - BOXREI_A - 40

    mov dword [percival_vivo], 1    ; spawna boss 1
    mov dword [boss_estado], BOSS_PERSEGUIR
    mov dword [boss_frame], BOSS_FRAME_ANDANDO
    mov dword [boss_contador], 0
    mov dword [boss_rect], BOSS_INICIO_X
    mov dword [boss_rect + 4], BOSS_INICIO_Y
    call AtualizarPercivalHitbox
    
    mov rdi, r15                     
    chamar SDL_DestroyTexture          
    
    lea rdi, [img_file2]            
    call CarregarTextura             
    mov r15, rax                     
    
    jmp .sem_colisao_boss

.y_min_ok:
    mov  ecx, H
    sub  ecx, BOXREI_A              
    cmp  eax, ecx
    jle  .y_max_ok
    mov  eax, ecx
.y_max_ok:
    mov  [rei_y], eax

    cmp dword [percival_vivo], 1
    jne .sem_colisao_boss

    mov edi, [percival_hitbox]
    mov esi, [percival_hitbox + 4]
    mov edx, [percival_hitbox + 8]
    mov ecx, [percival_hitbox + 12]
    call TestaContatoBoss

    cmp rax, 1
    je .houve_colisao

.sem_colisao_boss:

.colisoes_cenario:
    mov edi, WALL1_X
    mov esi, WALL1_Y
    mov edx, WALL1_L
    mov ecx, WALL1_A
    call TestaColisao      
    cmp rax, 1
    je .houve_colisao

    mov edi, WALL2_X
    mov esi, WALL2_Y
    mov edx, WALL2_L
    mov ecx, WALL2_A
    call TestaColisao
    cmp rax, 1
    je .houve_colisao

    mov edi, WALL3_X
    mov esi, WALL3_Y
    mov edx, WALL3_L
    mov ecx, WALL3_A
    call TestaColisao
    cmp rax, 1
    je .houve_colisao

    mov edi, WALL4_X
    mov esi, WALL4_Y
    mov edx, WALL4_L
    mov ecx, WALL4_A
    call TestaColisao
    cmp rax, 1
    je .houve_colisao

    mov edi, WALL5_X
    mov esi, WALL5_Y
    mov edx, WALL5_L
    mov ecx, WALL5_A
    call TestaColisao
    cmp rax, 1
    je .houve_colisao

    mov edi, CAMP_X
    mov esi, CAMP_Y
    mov edx, CAMP_L
    mov ecx, CAMP_A
    call TestaColisao
    cmp rax, 1
    je .houve_colisao

    jmp .sem_colisao

.houve_colisao:         ; volta pra onde estava
    mov [rei_x], r8d
    mov [rei_y], r9d
    
.sem_colisao:
    mov  dword [movendo], 0
        mov  eax, [rei_x]          
        cmp  eax, r8d
        jne  .mexeu
        mov  eax, [rei_y]
        cmp  eax, r9d
        je   .animacao
.mexeu:
    mov  dword [movendo], 1

.animacao:
    cmp dword [rei_morto], 0
    jne .derrota_player
    call AtualizarBoss
    cmp dword [rei_morto], 0
    je .verificar_ataque
.derrota_player:
    mov dword [movendo], 0
    mov dword [atk_dir], 0
    mov dword [ataque_timer], 0
    mov qword [swipe_atual], 0
    mov dword [atk_hitbox + 8], 0
    mov dword [atk_hitbox + 12], 0
    mov rdi, rbx
    lea rsi, [titulo_derrota]
    chamar SDL_SetWindowTitle
    jmp .rei_derrotado

.verificar_ataque:
    cmp  dword [atk_dir], 0
    jne  .atacando
    jmp  .verificar_movimento

.atacando:
    mov  eax, [atk_dir]
    cmp  eax, 1
    je   .atk_esq
    cmp  eax, 2
    je   .atk_dir
    cmp  eax, 3
    je   .atk_up
    cmp  eax, 4
    je   .atk_down

.atk_esq:
    mov  r14, [king_atk_l]
    mov rax, [atk_swipe_l]
    mov [swipe_atual], rax
    jmp  .desenha
.atk_dir:
    mov  r14, [king_atk_r]
    mov rax, [atk_swipe_r]
    mov [swipe_atual], rax
    jmp  .desenha
.atk_up:
    mov  r14, [king_atk_u]
    mov rax, [atk_swipe_u]
    mov [swipe_atual], rax
    jmp  .desenha
.atk_down:
    mov  r14, [king_atk_d]
    mov rax, [atk_swipe_d]
    mov [swipe_atual], rax
    jmp  .desenha

.verificar_movimento:
    mov qword [swipe_atual], 0
    cmp  dword [movendo], 0
    jne  .andando

    ; parado
    mov  dword [frame_atual], 0
    mov  dword [cont_anim], 0
    mov  r14, [king_idle]
    jmp  .desenha

.andando:
    inc  dword [cont_anim]
    cmp  dword [cont_anim], walk_delay
    jl   .escolhe
    mov  dword [cont_anim], 0
    xor  dword [frame_atual], 1     ; alterna 0 <-> 1

.escolhe:
    mov  eax, [frame_atual]         ; eax zera a parte alta de rax
    lea  rcx, [king_walk]
    mov  r14, [rcx + rax*8]         ; r14 = textura do frame atual
    jmp  .desenha

.rei_derrotado:
    mov  r14, [king_morte]

.desenha:
    ; Obtém o tamanho do sprite atual
    mov  rdi, r14
    xor  esi, esi
    xor  edx, edx
    lea  rcx, [tex_w]
    lea  r8,  [tex_h]
    chamar SDL_QueryTexture

    mov  rdi, r12 
    chamar SDL_RenderClear

    mov rdi, r12
    mov rsi, r15
    xor edx, edx
    xor ecx, ecx
    chamar SDL_RenderCopy

    cmp byte [cena_atual], 1        ; n desenha o boss se tiver em mapa 1
    jne .pula_desenho_boss1

    ; O corpo continua visivel depois da morte, sem hitbox ativa.
    call PrepararDesenhoBoss     ; rdx = recorte/NULL, rcx = destino alinhado
    mov  rdi, r12
    mov  eax, [boss_frame]
    lea  rsi, [boss_texturas]
    mov  rsi, [rsi + rax*8]
    chamar SDL_RenderCopy
    
.pula_desenho_boss1:
    ; x = posição do rei + metade da diferença de largura
    mov eax, [rei_x]
    mov ecx, [idle_w]
    sub ecx, [tex_w]
    sar ecx, 1
    add eax, ecx
    mov [rsp+64], eax

    ; y = posição do rei + metade da diferença de altura
    mov eax, [rei_y]
    mov ecx, [idle_h]
    sub ecx, [tex_h]
    sar ecx, 1
    add eax, ecx
    mov [rsp+68], eax

    ; desenha usando o tamanho real do sprite atual
    mov eax, [tex_w]
    mov [rsp+72], eax

    mov eax, [tex_h]
    mov [rsp+76], eax

    mov  rdi, r12                 ; SDL_RenderCopy(renderer, texture, NULL, &destino)
    mov  rsi, r14
    xor  edx, edx                 ; srcrect = NULL -> usa a imagem inteira
    lea  rcx, [rsp+64]            ; dstrect
    chamar SDL_RenderCopy

    ; Se houver swipe, desenha o efeito de ataque
    cmp qword [swipe_atual], 0
    je .sem_swipe

    mov r14, [swipe_atual]

    mov rdi, r14
    xor esi, esi
    xor edx, edx
    lea rcx, [tex_w]
    lea r8, [tex_h]
    chamar SDL_QueryTexture

; Define a posição do swipe conforme a direção
    cmp dword [atk_dir], 1
    je .pos_swipe_esq

    cmp dword [atk_dir], 2
    je .pos_swipe_dir

    cmp dword [atk_dir], 3
    je .pos_swipe_up

    ; Caso restante: ataque para baixo
    jmp .pos_swipe_down


.pos_swipe_esq:
    ; x = rei_x - largura_swipe - distância
    mov eax, [rei_x]
    sub eax, [tex_w]
    sub eax, SWIPE_DIST
    mov [rsp+64], eax

    ; y centralizado
    mov eax, [rei_y]

    mov ecx, BOXREI_A
    sub ecx, [tex_h]
    sar ecx, 1

    add eax, ecx
    mov [rsp+68], eax
    jmp .tamanho_swipe


.pos_swipe_dir:
    ; x = rei_x + largura_hitbox + distância
    mov eax, [rei_x]
    add eax, BOXREI_L
    add eax, SWIPE_DIST
    mov [rsp+64], eax

    ; y centralizado
    mov eax, [rei_y]

    mov ecx, BOXREI_A
    sub ecx, [tex_h]
    sar ecx, 1

    add eax, ecx
    mov [rsp+68], eax
    jmp .tamanho_swipe


.pos_swipe_up:
    ; x centralizado
    mov eax, [rei_x]

    mov ecx, BOXREI_L
    sub ecx, [tex_w]
    sar ecx, 1

    add eax, ecx
    mov [rsp+64], eax
    mov [rsp+64], eax

    ; y = rei_y - altura_swipe - distância
    mov eax, [rei_y]
    sub eax, [tex_h]
    sub eax, SWIPE_DIST
    mov [rsp+68], eax
    jmp .tamanho_swipe


.pos_swipe_down:
    ; x centralizado
    mov eax, [rei_x]

    mov ecx, BOXREI_L
    sub ecx, [tex_w]
    sar ecx, 1

    add eax, ecx
    mov [rsp+64], eax

    ; y = rei_y + altura_hitbox + distância
    mov eax, [rei_y]
    add eax, BOXREI_A
    add eax, SWIPE_DIST
    mov [rsp+68], eax


.tamanho_swipe:
    mov eax, [rsp+64]
    mov [atk_hitbox], eax

    mov eax, [rsp+68]
    mov [atk_hitbox + 4], eax


    mov eax, [tex_w]
    mov [rsp+72], eax
    mov [atk_hitbox + 8], eax          ; largura do swipe

    mov eax, [tex_h]
    mov [rsp+76], eax
    mov [atk_hitbox + 12], eax      ; altura do swipe

    ; Desenha o swipe
    mov rdi, r12
    mov rsi, r14
    xor edx, edx
    lea rcx, [rsp+64]
    chamar SDL_RenderCopy

    ; Verifica se Percival está vivo
    cmp dword[percival_vivo], 1
    jne .sem_swipe

    call BossAttacked
    cmp eax, 1
    jne .sem_swipe
    call BossDied

.sem_swipe:
    cmp qword [swipe_atual], 0
    je .sem_hitbox_ataque

    mov eax, [atk_hitbox]
    mov [rsp+64], eax
    mov eax, [atk_hitbox + 4]
    mov [rsp+68], eax
    mov eax, [atk_hitbox + 8]
    mov [rsp+72], eax
    mov eax, [atk_hitbox + 12]
    mov [rsp+76], eax
    ; Cor do contorno do hitbox do ataque: amarelo
    mov rdi, r12
    mov esi, 255
    mov edx, 255
    mov ecx, 0
    mov r8d, 255
    chamar SDL_SetRenderDrawColor

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

.sem_hitbox_ataque:

    ; Define a cor do "pincel" do SDL para azul (R=0, G=0, B=255, Alpha=255)
    mov rdi, r12
    xor esi, esi
    xor ecx, ecx
    mov ecx, 255
    mov r8d, 255
    chamar SDL_SetRenderDrawColor

    ; Hitbox deve usar rei_x/rei_y, não a posição ajustada do sprite
    mov eax, [rei_x]
    mov [rsp+64], eax

    mov eax, [rei_y]
    mov [rsp+68], eax

    mov dword [rsp+72], BOXREI_L
    mov dword [rsp+76], BOXREI_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect       

    mov rdi, r12
    lea rsi, [rsp+64]            
    chamar SDL_RenderDrawRect

    ; Define a cor do "pincel" do SDL para Vermelho (R=255, G=0, B=0, Alpha=255)
    cmp dword [percival_vivo], 1
    jne .sem_hitbox_boss

    mov rdi, r12
    mov esi, 255
    xor edx, edx
    xor ecx, ecx
    mov r8d, 255
    chamar SDL_SetRenderDrawColor

    mov eax, [percival_hitbox]
    mov [rsp+64], eax

    mov eax, [percival_hitbox + 4]
    mov [rsp+68], eax

    mov eax, [percival_hitbox + 8]
    mov [rsp+72], eax

    mov eax, [percival_hitbox + 12]
    mov [rsp+76], eax

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

.sem_hitbox_boss:
    
.desenha_paredes:
    ; parede verde
    mov rdi, r12
    xor esi, esi            ; R = 0
    mov edx, 255            ; G = 255
    xor ecx, ecx            ; B = 0
    mov r8d, 255            ; Alpha = 255
    chamar SDL_SetRenderDrawColor

    ; contorno 
    mov dword [rsp+64], WALL1_X
    mov dword [rsp+68], WALL1_Y
    mov dword [rsp+72], WALL1_L
    mov dword [rsp+76], WALL1_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect
    
    mov dword [rsp+64], WALL2_X
    mov dword [rsp+68], WALL2_Y
    mov dword [rsp+72], WALL2_L
    mov dword [rsp+76], WALL2_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

    mov dword [rsp+64], WALL3_X
    mov dword [rsp+68], WALL3_Y
    mov dword [rsp+72], WALL3_L
    mov dword [rsp+76], WALL3_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

    mov dword [rsp+64], WALL4_X
    mov dword [rsp+68], WALL4_Y
    mov dword [rsp+72], WALL4_L
    mov dword [rsp+76], WALL4_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

    mov dword [rsp+64], WALL5_X
    mov dword [rsp+68], WALL5_Y
    mov dword [rsp+72], WALL5_L
    mov dword [rsp+76], WALL5_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

    mov dword [rsp+64], CAMP_X
    mov dword [rsp+68], CAMP_Y
    mov dword [rsp+72], CAMP_L
    mov dword [rsp+76], CAMP_A

    mov rdi, r12
    lea rsi, [rsp+64]
    chamar SDL_RenderDrawRect

    ;Restaura a cor do pincel para Preto, senão a tela piscará vermelho no próximo frame
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    xor ecx, ecx
    mov r8d, 255
    chamar SDL_SetRenderDrawColor

    mov  rdi, r12
    chamar SDL_RenderPresent

    mov  edi, 16
    chamar SDL_Delay
    jmp  .loop

.fim:
    cmp qword [boss_texturas], 0
    je .boss_ja_removido
    xor  r13d, r13d
.libera_boss:
    lea  rax, [boss_texturas]
    mov  rdi, [rax + r13*8]
    chamar SDL_DestroyTexture
    inc  r13d
    cmp  r13d, BOSS_TOTAL_FRAMES
    jl   .libera_boss

.boss_ja_removido:
    mov  rdi, r15
    chamar SDL_DestroyTexture
    mov  rdi, [king_idle]
    chamar SDL_DestroyTexture
    mov  rdi, [king_morte]
    chamar SDL_DestroyTexture
    mov  rdi, [king_walk]
    chamar SDL_DestroyTexture
    mov  rdi, [king_walk + 8]
    chamar SDL_DestroyTexture
    mov  rdi, r12
    chamar SDL_DestroyRenderer
    mov  rdi, rbx
    chamar SDL_DestroyWindow

    ; Libera os sons
    mov rdi, [snd_golpe]
    test rdi, rdi
    jz .sem_golpe
    chamar Mix_FreeChunk

.sem_golpe:

    mov  rdi, [percival_theme]
    test rdi, rdi
    jz   .sem_free_musica
    chamar Mix_FreeMusic

.sem_free_musica:

    chamar SDL_Quit

    add  rsp, 80
    pop  rsi
    pop  rdi          ; <- era 80
    pop  r15
    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    xor  eax, eax
    ret

; Estado inicial compartilhado pela abertura do jogo e pela tecla R.
; Preserva as texturas, suas dimensoes e os registradores de main.
ReiniciarPartida:
%if DESENVOLVIMENTO
    mov  dword [dev_imune], 0
%endif
    mov  byte [cena_atual], 0
    mov  dword [rei_morto], 0
    mov  dword [rei_x], REI_INICIO_X
    mov  dword [rei_y], REI_INICIO_Y
    mov  dword [frame_atual], 0
    mov  dword [cont_anim], 0
    mov  dword [movendo], 0
    mov  dword [ataque_cooldown], 0
    mov  dword [atk_dir], 0
    mov  dword [atacou], 0
    mov  dword [ataque_timer], 0
    mov  qword [swipe_atual], 0
    mov  qword [atk_hitbox], 0
    mov  qword [atk_hitbox + 8], 0
    mov  dword [boss_rect], BOSS_INICIO_X
    mov  dword [boss_rect + 4], BOSS_INICIO_Y
    mov  dword [boss_estado], BOSS_PERSEGUIR
    mov  dword [boss_frame], BOSS_FRAME_ANDANDO
    mov  dword [boss_contador], 0
    mov  dword [boss_dash_x], 0
    mov  dword [boss_dash_y], 0
    mov  dword [boss_dash_vx], 0
    mov  dword [boss_dash_vy], 0
    mov  dword [boss_meio_passo], 0
    mov  dword [percival_vivo], 0           ; boss 1 incialmente morto, att quando trocar de cena
    jmp  AtualizarPercivalHitbox

; Alinha as novas poses pelos pes, mantendo a escala original dos pixels.
; Retorna os argumentos srcrect (rdx) e dstrect (rcx) de SDL_RenderCopy.
PrepararDesenhoBoss:
    lea  rcx, [boss_desenho_rect]
    mov  eax, [boss_rect]
    mov  [rcx], eax
    mov  eax, [boss_rect + 4]
    mov  [rcx + 4], eax
    mov  eax, [boss_rect + 8]
    mov  [rcx + 8], eax
    mov  eax, [boss_rect + 12]
    mov  [rcx + 12], eax
    xor  edx, edx
    cmp  dword [boss_frame], BOSS_FRAME_VULNERAVEL
    je   .vulneravel
    cmp  dword [boss_frame], BOSS_FRAME_MORTE
    jne  .fim
    lea  rdx, [boss_morte_src]
    jmp  .alinhar
.vulneravel:
    lea  rdx, [boss_vulneravel_src]
.alinhar:
    mov  eax, [rdx + 8]
    mov  [rcx + 8], eax
    shr  eax, 1
    neg  eax
    add  eax, BOSS_CENTRO_X
    add  [rcx], eax
    mov  eax, [rdx + 12]
    mov  [rcx + 12], eax
    neg  eax
    add  eax, BOSS_PE_Y
    add  [rcx + 4], eax
.fim:
    ret

; Apenas a perseguicao move normalmente. Carga e vulnerabilidade ficam paradas.
AtualizarBoss:
    sub  rsp, 8                 ; alinhamento System V antes das chamadas
    cmp  dword [boss_estado], BOSS_MORTO
    je   .morto
    cmp  dword [boss_estado], BOSS_CARREGAR
    je   .carga
    cmp  dword [boss_estado], BOSS_DASH
    je   .dash
    cmp  dword [boss_estado], BOSS_VULNERAVEL
    je   .vulneravel

.perseguir:
    cmp  dword [boss_contador], BOSS_ESPERA_QUADROS
    jae  .inicia_carga
    mov  dword [boss_frame], BOSS_FRAME_ANDANDO
    inc  dword [boss_contador]
    call MovimentarBoss
    jmp  .fim

.inicia_carga:
    mov  dword [boss_estado], BOSS_CARREGAR
    mov  dword [boss_contador], 0
.carga:
    mov  eax, [boss_contador]
    cmp  eax, BOSS_CARGA_POR_FRAME * BOSS_CARGA_FRAMES
    jae  .inicia_dash
    xor  edx, edx
    mov  ecx, BOSS_CARGA_POR_FRAME
    div  ecx
    add  eax, BOSS_FRAME_CARGA   ; ataque1 (aviso) seguido de ataque2 a ataque6
    mov  [boss_frame], eax
    inc  dword [boss_contador]
    jmp  .fim

.inicia_dash:
    ; Mira no centro atual do jogador uma unica vez; nao o segue durante o dash.
    mov  eax, [rei_x]
    add  eax, BOXREI_L / 2 - BOSS_CENTRO_X
    sub  eax, [boss_rect]
    cvtsi2ss xmm0, eax
    mov  eax, [rei_y]
    add  eax, BOXREI_A / 2 - BOSS_CENTRO_Y
    sub  eax, [boss_rect + 4]
    cvtsi2ss xmm1, eax

    ; Normaliza (dx, dy): o alcance nao aumenta nas diagonais.
    movaps xmm2, xmm0
    mulss xmm2, xmm0
    movaps xmm3, xmm1
    mulss xmm3, xmm1
    addss xmm2, xmm3
    xorps xmm3, xmm3
    ucomiss xmm2, xmm3
    je   .inicia_vulneravel      ; centros coincidentes: evita divisao por zero
    sqrtss xmm2, xmm2
    mov  eax, BOSS_DASH_DISTANCIA
    cvtsi2ss xmm3, eax
    mov  eax, BOSS_DASH_QUADROS
    cvtsi2ss xmm4, eax
    divss xmm3, xmm4
    divss xmm3, xmm2
    mulss xmm0, xmm3
    mulss xmm1, xmm3
    movss [boss_dash_vx], xmm0
    movss [boss_dash_vy], xmm1
    cvtsi2ss xmm0, dword [boss_rect]
    cvtsi2ss xmm1, dword [boss_rect + 4]
    movss [boss_dash_x], xmm0
    movss [boss_dash_y], xmm1
    mov  dword [boss_estado], BOSS_DASH
    mov  dword [boss_contador], 0

.dash:
    cmp  dword [boss_contador], BOSS_DASH_QUADROS
    jae  .inicia_vulneravel
    mov  eax, BOSS_FRAME_DASH    ; primeira metade: dash1
    cmp  dword [boss_contador], BOSS_DASH_QUADROS / 2
    jb   .frame_dash
    inc  eax                    ; segunda metade: dash2
.frame_dash:
    mov  [boss_frame], eax
    inc  dword [boss_contador]
    mov  r8d, [boss_rect]
    mov  r9d, [boss_rect + 4]
    movss xmm0, [boss_dash_x]
    addss xmm0, [boss_dash_vx]
    movss [boss_dash_x], xmm0
    cvtss2si eax, xmm0
    mov  [boss_rect], eax
    movss xmm1, [boss_dash_y]
    addss xmm1, [boss_dash_vy]
    movss [boss_dash_y], xmm1
    cvtss2si eax, xmm1
    mov  [boss_rect + 4], eax

    ; O corpo do boss nao deve sair da arena durante o dash.
    cmp  dword [boss_rect], WALL1_L - BOSS_HITBOX_X
    jl   .interrompe_dash
    cmp  dword [boss_rect], WALL4_X - BOSS_HITBOX_X - BOSS_HITBOX_L
    jg   .interrompe_dash
    cmp  dword [boss_rect + 4], WALL2_A - BOSS_HITBOX_Y
    jl   .interrompe_dash
    cmp  dword [boss_rect + 4], WALL3_Y - BOSS_HITBOX_Y - BOSS_HITBOX_A
    jg   .interrompe_dash

    ; Contato causa dano antes de desfazer o passo que atingiu o jogador.
    mov  edi, [boss_rect]
    add  edi, BOSS_HITBOX_X
    mov  esi, [boss_rect + 4]
    add  esi, BOSS_HITBOX_Y
    mov  edx, BOSS_HITBOX_L
    mov  ecx, BOSS_HITBOX_A
    call TestaContatoBoss
    test eax, eax
    jz   .fim
.interrompe_dash:
    mov  [boss_rect], r8d
    mov  [boss_rect + 4], r9d

.inicia_vulneravel:
    mov  dword [boss_estado], BOSS_VULNERAVEL
    mov  dword [boss_contador], 0
    call AtualizarPercivalHitbox
.vulneravel:
    cmp  dword [boss_contador], BOSS_VULNERAVEL_QUADROS
    jae  .volta_perseguir
    mov  dword [boss_frame], BOSS_FRAME_VULNERAVEL
    inc  dword [boss_contador]
    jmp  .fim
.volta_perseguir:
    mov  dword [boss_estado], BOSS_PERSEGUIR
    mov  dword [boss_contador], 0
    mov  dword [boss_meio_passo], 0
    jmp  .perseguir
.morto:
    mov  dword [boss_frame], BOSS_FRAME_MORTE
.fim:
    cmp dword [percival_vivo], 1
    jne .retorna
    call AtualizarPercivalHitbox
.retorna:
    add  rsp, 8
    ret

; Persegue o centro do jogador, com metade de VEL em cada eixo.
; Usa apenas registradores temporarios e mantem o primeiro sprite.
MovimentarBoss:
    cmp dword [percival_vivo], 1
    jne .boss_removido

    mov r8d, dword [boss_rect]          ; posição anterior 
    mov r9d, dword [boss_rect + 4]

    mov  ecx, [boss_meio_passo]
    add  ecx, VEL
    mov  eax, ecx
    and  eax, 1
    mov  [boss_meio_passo], eax
    shr  ecx, 1                 ; VEL=3: passos de 1, 2, 1, 2... pixels
    mov  edx, ecx
    neg  edx                    ; limite negativo do passo

    ; Limita o deslocamento a [-passo, +passo], sem ultrapassar o alvo.
    mov  eax, [rei_x]
    add  eax, BOXREI_L / 2 - BOSS_CENTRO_X
    sub  eax, [boss_rect]
    cmp  eax, ecx
    cmovg eax, ecx
    cmp  eax, edx
    cmovl eax, edx
    add  [boss_rect], eax

    mov  eax, [rei_y]
    add  eax, BOXREI_A / 2 - BOSS_CENTRO_Y
    sub  eax, [boss_rect + 4]
    cmp  eax, ecx
    cmovg eax, ecx
    cmp  eax, edx
    cmovl eax, edx
    add  [boss_rect + 4], eax

    mov edi, dword [boss_rect]
    add edi, BOSS_HITBOX_X
    mov esi, dword [boss_rect + 4]
    add esi, BOSS_HITBOX_Y
    mov edx, BOSS_HITBOX_L
    mov ecx, BOSS_HITBOX_A
    call TestaContatoBoss
    
    cmp rax, 1
    jne .passo_ok
    
    mov dword [boss_rect], r8d          ;volta pra posição anterior
    mov dword [boss_rect + 4], r9d

.passo_ok:
    call AtualizarPercivalHitbox
    ret
.boss_removido:
    ret

AtualizarPercivalHitbox:
    mov eax, [boss_rect]
    add eax, BOSS_HITBOX_X
    mov [percival_hitbox], eax

    mov eax, [boss_rect + 4]
    add eax, BOSS_HITBOX_Y
    mov [percival_hitbox + 4], eax

    mov dword [percival_hitbox + 8], BOSS_HITBOX_L
    mov dword [percival_hitbox + 12], BOSS_HITBOX_A
    ret

; Retorna 1 no contato (inclusive bordas) e aplica dano apenas com boss vivo.
; Recebe a hitbox candidata em edi/esi/edx/ecx, antes de reverter a colisao.
; Preserva r8/r9, que guardam a posicao anterior do player ou do boss.
TestaContatoBoss:
    xor eax, eax
    cmp dword [percival_vivo], 1
    jne .fim
    mov r10d, edi
    add r10d, edx
    cmp dword [rei_x], r10d
    jg .fim
    mov r10d, [rei_x]
    add r10d, BOXREI_L
    cmp r10d, edi
    jl .fim
    mov r10d, esi
    add r10d, ecx
    cmp dword [rei_y], r10d
    jg .fim
    mov r10d, [rei_y]
    add r10d, BOXREI_A
    cmp r10d, esi
    jl .fim
%if DESENVOLVIMENTO
    cmp dword [dev_imune], 0
    jne .contato
%endif
    mov dword [rei_morto], 1
.contato:
    mov eax, 1
.fim:
    ret

TestaColisao:
    mov eax, [rei_x]            ; pega x do rei
    mov r10d, edi               ; pega x da parede
    add r10d, edx               ; arede X + largura
    cmp eax, r10d               ; compara esquerda do rei(eax) com a direita da parede
    jge .livre                  ; pula se o valor do rei for MAIOR ou igual da parede 

    add eax, BOXREI_L           ; x do rei + largura do rei
    cmp eax, edi                ; compara com direita do rei com esquerda da parede 
    jle .livre                  ; pula se o valor do rei for MENOR ou igual da parede

    mov eax, [rei_y]            ; y do rei
    mov r10d, esi               ; y da parede 
    add r10d, ecx               ; parede y + altura
    cmp eax, r10d               ; compara y do rei com parte de baixo da parede 
    jge .livre

    add eax, BOXREI_A           ; y do rei + altura
    cmp eax, esi                ; compara com parte de cima da parede
    jle .livre

.bateu:
    mov rax, 1                  ; Retorna 1 (Houve colisão)
    ret

.livre:
    mov rax, 0                  ; Retorna 0 (Sem colisão)
    ret

BossAttacked:
    ; Apenas ataques ativos contra o boss vivo e vulneravel causam dano.
    cmp dword [percival_vivo], 1
    jne .boss_fora
    cmp dword [boss_estado], BOSS_VULNERAVEL
    jne .boss_fora
    cmp dword [atk_dir], 0
    je .boss_fora

    mov r8d, [percival_hitbox]
    mov r9d, [percival_hitbox + 4]

    mov r10d, r8d
    add r10d, [percival_hitbox + 8]

    mov r11d, r9d
    add r11d, [percival_hitbox + 12]

    mov edx, [atk_hitbox]
    mov ecx, [atk_hitbox + 4]

    mov rdi, rdx
    add edi, [atk_hitbox + 8]

    mov rsi, rcx
    add esi, [atk_hitbox + 12]

    cmp r10d, edx
    jl .boss_fora
    cmp r8d, edi
    jg .boss_fora
    cmp r11d, ecx
    jl .boss_fora
    cmp r9d, esi
    jg .boss_fora

    mov eax, 1
    ret

.boss_fora:
    mov eax, 0
    ret

BossDied:
    mov dword [boss_estado], BOSS_MORTO
    mov dword [boss_frame], BOSS_FRAME_MORTE
    mov dword [boss_contador], 0
    mov dword [percival_vivo], 0
    mov dword [percival_hitbox], 0
    mov dword [percival_hitbox + 4], 0
    mov dword [percival_hitbox + 8], 0
    mov dword [percival_hitbox + 12], 0
    ret

CarregarTextura:
    push rbx                        ; guarda rbx (e alinha a pilha em 16)
    lea  rsi, [modo_leitura]
    chamar SDL_RWFromFile             ; rdi já tem o caminho

    mov  rdi, rax
    mov  esi, 1
    chamar SDL_LoadBMP_RW
    mov  rbx, rax                   ; rbx = surface

    mov  rdi, r12
    mov  rsi, rbx
    chamar SDL_CreateTextureFromSurface

    sub  rsp, 16                    ; espaço temporário (mantém alinhamento)
    mov  [rsp], rax                 ; salva a textura: FreeSurface vai sobrescrever rax
    mov  rdi, rbx
    chamar SDL_FreeSurface
    mov  rax, [rsp]                 ; recupera a textura
    add  rsp, 16

    pop  rbx
    ret

; rdi = Mix_Chunk*
TocarSom:
    push r8
    push r9
    push r10
    push r11
    sub  rsp, 8                   ; 4 pushes (32) + ret (8) + 8 = alinhado

    mov  rsi, rdi                 ; chunk
    mov  edi, -1                  ; primeiro canal livre
    xor  edx, edx                 ; loops = 0
    mov  ecx, -1                  ; sem limite de tempo
    chamar Mix_PlayChannelTimed

    add  rsp, 8
    pop  r11
    pop  r10
    pop  r9
    pop  r8
    ret

; Entrada: rdi = caminho do arquivo
; Saída: rax = Mix_Chunk*, ou 0 em caso de erro
CarregarSom:
    push rbx
    lea rsi, [modo_leitura]
    chamar SDL_RWFromFile
    test rax, rax
    jz .erro

    mov rdi, rax
    mov esi, 1
    chamar Mix_LoadWAV_RW
    jmp .fim

.erro:
    xor eax, eax
.fim:
    pop rbx
    ret

