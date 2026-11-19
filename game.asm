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

BOXREI_A equ 30     ; altura da hitbox do rei 
BOXREI_L equ 20     ; largura da hitbox

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
BOSS_ESPERA_QUADROS equ 225       ; cerca de 4 s perseguindo entre ataques
BOSS_CARGA_POR_FRAME equ 5       ; ataque1 a ataque6: cerca de 0,96 s no total
BOSS_DASH_QUADROS equ 15          ; cerca de 0,32 s, dash1 e dash2
BOSS_DASH_DISTANCIA equ 200       ; pixels, igual em qualquer direcao
BOSS_VULNERAVEL_QUADROS equ 47    ; cerca de 0,75 s com a sprite vulneravel
BOSS_HITBOX_X equ 105
BOSS_HITBOX_Y equ 50

WALL1_X equ 0       ; obstaculo teste
WALL1_Y equ 0
WALL1_A equ 450
WALL1_L equ 40

WALL2_X equ 0       
WALL2_Y equ 0
WALL2_A equ 30
WALL2_L equ 800

WALL3_X equ 0       
WALL3_Y equ 420
WALL3_A equ 30
WALL3_L equ 800

WALL4_X equ 770     
WALL4_Y equ 0
WALL4_A equ 210
WALL4_L equ 30

WALL5_X equ 770     
WALL5_Y equ 250
WALL5_A equ 225
WALL5_L equ 30

ROCK_X  equ 54
ROCK_Y  equ 69
ROCK_A  equ 40
ROCK_L  equ 35

CAMP_X  equ 410
CAMP_Y  equ 245
CAMP_A  equ 15
CAMP_L  equ 25

section .data
    titulo      db "Sprite", 0
    rei_bmp db "Rei.bmp", 0
    reiC1_bmp db "Rei C1.bmp", 0
    reiC2_bmp db "Rei C2.bmp", 0
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
    boss_rect dd 284, 60, 0, 0    ; x, y, largura, altura (tamanho original)
    modo_leitura db "rb", 0
    img_mode db "rb", 0
    img_file db "chao.bmp", 0 
    img_file2 db "chao960.bmp", 0       ; novo mapa
    cena_atual db 0

section .bss
    tex_w         resd 1   ; largura da imagem (preenchido por SDL_QueryTexture)
    tex_h         resd 1   ; altura da imagem
    king_idle     resq 1   ; textura do Rei.bmp (sprite parado)
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
    king_walk     resq 2   ; [0] = Rei C.bmp, [1] = Rei C2.bmp
    frame_atual   resd 1   ; 0 ou 1 (qual das duas está ativa)
    cont_anim     resd 1   ; quadros passados desde a última troca
    movendo       resd 1   ; 0 = parado, 1 = se moveu neste quadro
    walk_delay    equ 8    ; trocar de frame a cada X quadros
    rei_x         resd 1   ; posisão x hitbox
    rei_y         resd 1   ; posisão y hitbox

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

    mov  rdi, [boss_texturas]
    xor  esi, esi
    xor  edx, edx
    lea  rcx, [boss_rect + 8]
    lea  r8, [boss_rect + 12]
    call SDL_QueryTexture

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
    cmp byte [cena_atual], 0        
    je .trocar_cena2
    mov  eax, ecx                   ; passou da direita: x = máximo
    jmp .x_max_ok

    .trocar_cena2:
        mov byte [cena_atual], 1        ; troca o byte do mapa
        mov eax, 100                    ; Posiciona o rei na borda do outro lado
        mov [rei_x], eax                 

        mov rdi, r15                     
        call SDL_DestroyTexture          
        
        lea rdi, [img_file2]            
        call CarregarTextura             
        mov r15, rax                     
        
        jmp .y_limit_start               

.x_max_ok:
    mov  [rei_x], eax

    ; ---- limita y entre 0 e H - altura ----
.y_limit_start:  
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

    cmp dword [boss_estado], BOSS_MORTO
    je .colisoes_cenario
    mov edi, dword [boss_rect]       ; X do boss
    add edi, BOSS_HITBOX_X           ; ajuste x
    mov esi, dword [boss_rect + 4]   ; Y do boss
    add esi, BOSS_HITBOX_Y           ; ajuste y
    mov edx, BOSS_HITBOX_L
    mov ecx, BOSS_HITBOX_A
    call TestaColisao
    cmp rax, 1
    je .houve_colisao

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
    call AtualizarBoss

    ; lógica de animação aqui
    ; por exemplo, alternar entre texturas diferentes
    ; para simular movimento
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

    ; Desenha o boss sobre o cenario, antes do personagem.
    call PrepararDesenhoBoss     ; rdx = recorte/NULL, rcx = destino alinhado
    mov  rdi, r12
    mov  eax, [boss_frame]
    lea  rsi, [boss_texturas]
    mov  rsi, [rsi + rax*8]
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

    cmp dword [boss_estado], BOSS_MORTO
    je .desenha_paredes
    mov eax, dword [boss_rect]
    add eax, BOSS_HITBOX_X       ; ajuste do X
    mov dword [rsp+64], eax
    mov eax, dword [boss_rect + 4]
    add eax, BOSS_HITBOX_Y       ; ajuste do Y
    mov dword [rsp+68], eax

    mov dword [rsp+72], BOSS_HITBOX_L 
    mov dword [rsp+76], BOSS_HITBOX_A

    mov rdi, r12
    lea rsi, [rsp+64]
    call SDL_RenderDrawRect
    
.desenha_paredes:
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

    mov dword [rsp+64], WALL5_X
    mov dword [rsp+68], WALL5_Y
    mov dword [rsp+72], WALL5_L
    mov dword [rsp+76], WALL5_A

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
    xor  r13d, r13d
.libera_boss:
    lea  rax, [boss_texturas]
    mov  rdi, [rax + r13*8]
    call SDL_DestroyTexture
    inc  r13d
    cmp  r13d, BOSS_TOTAL_FRAMES
    jl   .libera_boss
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

    ; Preserva a colisao existente com o jogador. Dano sera integrado depois.
    mov  edi, [boss_rect]
    add  edi, BOSS_HITBOX_X
    mov  esi, [boss_rect + 4]
    add  esi, BOSS_HITBOX_Y
    mov  edx, BOSS_HITBOX_L
    mov  ecx, BOSS_HITBOX_A
    call TestaColisao
    test eax, eax
    jz   .fim
.interrompe_dash:
    mov  [boss_rect], r8d
    mov  [boss_rect + 4], r9d

.inicia_vulneravel:
    mov  dword [boss_estado], BOSS_VULNERAVEL
    mov  dword [boss_contador], 0
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
    ; O sistema de dano devera definir boss_estado = BOSS_MORTO ao derrotar o boss.
    mov  dword [boss_frame], BOSS_FRAME_MORTE
.fim:
    add  rsp, 8
    ret

; Persegue o centro do jogador, com metade de VEL em cada eixo.
; Usa apenas registradores temporarios e mantem o primeiro sprite.
MovimentarBoss:
    sub  rsp, 8                 ; alinhamento antes de TestaColisao
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
    call TestaColisao
    
    cmp rax, 1
    jne .passo_ok
    
    mov dword [boss_rect], r8d          ;volta pra posição anterior
    mov dword [boss_rect + 4], r9d

    .passo_ok:
        add rsp, 8
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
