default rel
extern SDL_RenderSetLogicalSize
extern SDL_GetKeyboardState

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
SC_LEFT  equ 80
SC_RIGHT equ 79
SC_UP    equ 82
SC_DOWN  equ 81

BOXREI_A equ 30     ; altura da hitbox do rei 
BOXREI_L equ 20     ; largura da hitbox

WALL1_X equ 0       ; obstaculo teste
WALL1_Y equ 0
WALL1_A equ 450
WALL1_L equ 40

WALL2_X equ 0       
WALL2_Y equ 0
WALL2_A equ 30
WALL2_L equ 800

WALL3_X equ 770     
WALL3_Y equ 0
WALL3_A equ 450
WALL3_L equ 30

WALL4_X equ 0       
WALL4_Y equ 420
WALL4_A equ 30
WALL4_L equ 800

ROCK_X  equ 54
ROCK_Y  equ 69
ROCK_A  equ 40
ROCK_L  equ 35

CAMP_X  equ 410
CAMP_Y  equ 245
CAMP_A  equ 15
CAMP_L  equ 25

section .data
    titulo      db "O Retorno do Rei", 0
    rei_bmp db "assets/sprites/Rei.bmp", 0
    reiC1_bmp db "assets/sprites/Rei C1.bmp", 0
    reiC2_bmp db "assets/sprites/Rei C2.bmp", 0
    reiAUp_bmp db "assets/sprites/Rei Atk Up.bmp", 0
    reiADwn_bmp db "assets/sprites/Rei Atk Dwn.bmp", 0
    reiAEsq_bmp db "assets/sprites/Rei Atk Esq.bmp", 0
    reiADir_bmp db "assets/sprites/Rei Atk Dir.bmp", 0
    modo_leitura db "rb", 0
    img_mode db "rb", 0
    img_file db "assets/background/chao.bmp", 0 

section .bss
    tex_w         resd 1   ; largura da imagem (preenchido por SDL_QueryTexture)
    tex_h         resd 1   ; altura da imagem
    king_idle     resq 1   ; textura do Rei.bmp (sprite parado)
    king_atk_u    resq 1   ; textura do Rei Atk Up.bmp (ataque para cima)
    king_atk_d    resq 1   ; textura do Rei Atk Dwn.bmp (ataque para baixo)
    king_atk_l    resq 1   ; textura do Rei Atk Esq.bmp (ataque para esquerda)
    king_atk_r    resq 1  ; textura do Rei Atk Dir.bmp (ataque para direita)
    king_walk     resq 2   ; [0] = Rei C.bmp, [1] = Rei C2.bmp
    frame_atual   resd 1   ; 0 ou 1 (qual das duas está ativa)
    cont_anim     resd 1   ; quadros passados desde a última troca
    movendo       resd 1   ; 0 = parado, 1 = se moveu neste quadro
    walk_delay    equ 8    ; trocar de frame a cada X quadros
    rei_x         resd 1   ; posisão x hitbox
    rei_y         resd 1   ; posisão y hitbox
    atk_dir       resd 1   ; direção do ataque (0= não, 1=esquerda, 2=direita, 3=cima, 4=baixo)

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
    sub  rsp, 80          ; <- era 80

    mov  edi, SDL_INIT_VIDEO
    call SDL_Init

    lea  rdi, [titulo]
    mov  esi, WINDOWPOS_CENTERED
    mov  edx, WINDOWPOS_CENTERED
    mov  ecx, W
    mov  r8d, H
    mov  r9d, SDL_WINDOW_SHOWN | SDL_WINDOW_FULLSCREEN_DESKTOP
    call SDL_CreateWindow
    mov  rbx, rax

    mov  rdi, rbx
    mov  esi, -1
    xor  edx, edx
    call SDL_CreateRenderer
    mov  r12, rax
    mov  rdi, r12
    mov  esi, W              ; 640
    mov  edx, H              ; 480
    call SDL_RenderSetLogicalSize

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

    ; andando, frame 0
    lea  rdi, [reiC1_bmp]
    call CarregarTextura
    mov  [king_walk], rax

    ; andando, frame 1
    lea  rdi, [reiC2_bmp]
    call CarregarTextura
    mov  [king_walk + 8], rax     ; +8: segundo ponteiro do array

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

    ; pega o tamanho real da imagem, para não distorcer o sprite
    mov  rdi, r14
    xor  esi, esi                ; format (NULL, não precisamos)
    xor  edx, edx                ; access (NULL)
    lea  rcx, [tex_w]
    lea  r8,  [tex_h]
    call SDL_QueryTexture

    ; monta o retângulo de destino: centralizado, com o tamanho da imagem
    mov  eax, [tex_w]
    mov  r9d, W
    sub  r9d, eax
    sar  r9d, 1                  ; (W - largura) / 2
    mov  [rei_x], r9d           ; x

    mov  eax, [tex_h]
    mov  r9d, H
    sub  r9d, eax
    sar  r9d, 1                  ; (H - altura) / 2
    mov  [rei_y], r9d           ; y

    mov  eax, [tex_w]
    mov  [rsp+72], eax           ; largura
    mov  eax, [tex_h]
    mov  [rsp+76], eax           ; altura

    xor  edi, edi
    call SDL_GetKeyboardState    ; devolve ponteiro para um array de bytes
    mov  r13, rax                ; r13 = estado do teclado

.loop:
.eventos:
    mov  rdi, rsp
    call SDL_PollEvent
    test eax, eax
    jz   .teclado           ; <- antes era .desenha
    cmp  dword [rsp], SDL_QUIT
    je   .fim
    cmp  dword [rsp], SDL_KEYDOWN       ; foi uma tecla pressionada?
    jne  .eventos
    cmp  dword [rsp+20], SDLK_ESCAPE    ; era o ESC?
    je   .fim
    jmp  .eventos

.teclado:
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

    mov dword [atk_dir], 0
    
    cmp  byte [r13 + SC_LEFT], 0
    je   .sem_left
    mov  dword [atk_dir], 1        ; esquerda
.sem_left:
    cmp  byte [r13 + SC_RIGHT], 0
    je   .sem_right
    mov  dword [atk_dir], 2        ; direita
.sem_right:
    cmp  byte [r13 + SC_UP], 0
    je   .sem_up
    mov  dword [atk_dir], 3        ; cima
.sem_up:
    cmp  byte [r13 + SC_DOWN], 0
    je   .sem_down
    mov  dword [atk_dir], 4        ; baixo
.sem_down:

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
    mov  eax, [rei_y]
    test eax, eax
    jge  .y_min_ok
    xor  eax, eax
.y_min_ok:
    mov  ecx, H
    sub  ecx, BOXREI_A              
    cmp  eax, ecx
    jle  .y_max_ok
    mov  eax, ecx
.y_max_ok:
    mov  [rei_y], eax

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

    mov edi, ROCK_X
    mov esi, ROCK_Y
    mov edx, ROCK_L
    mov ecx, ROCK_A
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
    jmp  .desenha
.atk_dir:
    mov  r14, [king_atk_r]
    jmp  .desenha
.atk_up:
    mov  r14, [king_atk_u]
    jmp  .desenha
.atk_down:
    mov  r14, [king_atk_d]
    jmp  .desenha

.verificar_movimento:
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

.desenha:
    mov  rdi, r12 
    call SDL_RenderClear

    mov rdi, r12
    mov rsi, r15
    xor edx, edx
    xor ecx, ecx
    call SDL_RenderCopy

    mov eax, [rei_x]            ; hitbox largura
    mov [rsp+64], eax

    mov eax, [rei_y]            ; hitbox altura
    mov [rsp+68], eax

    mov eax, [tex_w]
    mov [rsp+72], eax

    mov eax, [tex_h]
    mov [rsp+76], eax

    mov  rdi, r12                 ; SDL_RenderCopy(renderer, texture, NULL, &destino)
    mov  rsi, r14
    xor  edx, edx                 ; srcrect = NULL -> usa a imagem inteira
    lea  rcx, [rsp+64]            ; dstrect
    call SDL_RenderCopy

    ; 1. Define a cor do "pincel" do SDL para Vermelho (R=255, G=0, B=0, Alpha=255)
    mov rdi, r12
    mov esi, 255
    xor edx, edx
    xor ecx, ecx
    mov r8d, 255
    call SDL_SetRenderDrawColor

    mov dword [rsp+72], BOXREI_L        
    mov dword [rsp+76], BOXREI_A        

    mov rdi, r12
    lea rsi, [rsp+64]            
    call SDL_RenderDrawRect

    ; parede verde
    mov rdi, r12
    xor esi, esi            ; R = 0
    mov edx, 255            ; G = 255
    xor ecx, ecx            ; B = 0
    mov r8d, 255            ; Alpha = 255
    call SDL_SetRenderDrawColor

    ; contorno 
    mov dword [rsp+64], WALL1_X
    mov dword [rsp+68], WALL1_Y
    mov dword [rsp+72], WALL1_L
    mov dword [rsp+76], WALL1_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect
    
    mov dword [rsp+64], WALL2_X
    mov dword [rsp+68], WALL2_Y
    mov dword [rsp+72], WALL2_L
    mov dword [rsp+76], WALL2_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect

    mov dword [rsp+64], WALL3_X
    mov dword [rsp+68], WALL3_Y
    mov dword [rsp+72], WALL3_L
    mov dword [rsp+76], WALL3_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect

    mov dword [rsp+64], WALL4_X
    mov dword [rsp+68], WALL4_Y
    mov dword [rsp+72], WALL4_L
    mov dword [rsp+76], WALL4_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect

    mov dword [rsp+64], ROCK_X
    mov dword [rsp+68], ROCK_Y
    mov dword [rsp+72], ROCK_L
    mov dword [rsp+76], ROCK_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect

    mov dword [rsp+64], CAMP_X
    mov dword [rsp+68], CAMP_Y
    mov dword [rsp+72], CAMP_L
    mov dword [rsp+76], CAMP_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect

    ;Restaura a cor do pincel para Preto, senão a tela piscará vermelho no próximo frame
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    xor ecx, ecx
    mov r8d, 255
    call SDL_SetRenderDrawColor

    mov  rdi, r12
    call SDL_RenderPresent

    mov  edi, 16
    call SDL_Delay
    jmp  .loop

.fim:
    mov  rdi, r15
    call SDL_DestroyTexture
    mov  rdi, [king_idle]
    call SDL_DestroyTexture
    mov  rdi, [king_walk]
    call SDL_DestroyTexture
    mov  rdi, [king_walk + 8]
    call SDL_DestroyTexture
    mov  rdi, r12
    call SDL_DestroyRenderer
    mov  rdi, rbx
    call SDL_DestroyWindow
    call SDL_Quit

    add  rsp, 80          ; <- era 80
    pop  r15
    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    xor  eax, eax
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

CarregarTextura:
    push rbx                        ; guarda rbx (e alinha a pilha em 16)
    lea  rsi, [modo_leitura]
    call SDL_RWFromFile             ; rdi já tem o caminho

    mov  rdi, rax
    mov  esi, 1
    call SDL_LoadBMP_RW
    mov  rbx, rax                   ; rbx = surface

    mov  rdi, r12
    mov  rsi, rbx
    call SDL_CreateTextureFromSurface

    sub  rsp, 16                    ; espaço temporário (mantém alinhamento)
    mov  [rsp], rax                 ; salva a textura: FreeSurface vai sobrescrever rax
    mov  rdi, rbx
    call SDL_FreeSurface
    mov  rax, [rsp]                 ; recupera a textura
    add  rsp, 16

    pop  rbx
    ret

section .note.GNU-stack noexec