default rel
extern SDL_RenderSetLogicalSize
extern SDL_GetKeyboardState

extern SDL_Init, SDL_CreateWindow, SDL_CreateRenderer
extern SDL_PollEvent
extern SDL_SetRenderDrawColor, SDL_RenderClear, SDL_RenderPresent, SDL_Delay
extern SDL_RWFromFile, SDL_LoadBMP_RW, SDL_CreateTextureFromSurface, SDL_FreeSurface
extern SDL_QueryTexture, SDL_RenderCopy, SDL_DestroyTexture
extern SDL_DestroyRenderer, SDL_DestroyWindow, SDL_Quit
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

VEL    equ 4        ; velocidade em pixels por quadro
SC_W   equ 26       ; scancodes (posição física da tecla)
SC_A   equ 4
SC_S   equ 22
SC_D   equ 7

section .data
    titulo      db "Sprite", 0
    caminho_bmp db "rei.bmp", 0
    modo_leitura db "rb", 0
    img_mode db "rb", 0
    img_file db "chao.bmp", 0 

section .bss
    tex_w resd 1        ; largura da imagem (preenchido por SDL_QueryTexture)
    tex_h resd 1        ; altura da imagem

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

    ; ---- chao ----

    lea rdi, [img_file]
    lea rsi, [img_mode]
    call SDL_RWFromFile

    mov rdi, rax 
    mov esi, 1
    call SDL_LoadBMP_RW
    mov r13, rax

    mov rdi, r12
    mov rsi, r13
    call SDL_CreateTextureFromSurface
    mov r15, rax

    mov rdi, r13
    call SDL_FreeSurface

    ; ---- carrega o sprite ----
    lea  rdi, [caminho_bmp]
    lea  rsi, [modo_leitura]
    call SDL_RWFromFile          ; devolve SDL_RWops*

    mov  rdi, rax                ; primeiro argumento: o RWops que acabamos de abrir
    mov  esi, 1                  ; segundo argumento: 1 = fechar o arquivo sozinho
    call SDL_LoadBMP_RW          ; devolve SDL_Surface*
    mov  r13, rax

    mov  rdi, r12
    mov  rsi, r13
    call SDL_CreateTextureFromSurface   ; devolve SDL_Texture*
    mov  r14, rax

    mov  rdi, r13                ; a surface não é mais necessária
    call SDL_FreeSurface

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
    mov  [rsp+64], r9d           ; x

    mov  eax, [tex_h]
    mov  r9d, H
    sub  r9d, eax
    sar  r9d, 1                  ; (H - altura) / 2
    mov  [rsp+68], r9d           ; y

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
    ; ---- lê as teclas e altera x, y ----
    cmp  byte [r13 + SC_W], 0
    je   .sem_w
    sub  dword [rsp+68], VEL        ; W: sobe (y diminui)
.sem_w:
    cmp  byte [r13 + SC_S], 0
    je   .sem_s
    add  dword [rsp+68], VEL        ; S: desce (y aumenta)
.sem_s:
    cmp  byte [r13 + SC_A], 0
    je   .sem_a
    sub  dword [rsp+64], VEL        ; A: esquerda (x diminui)
.sem_a:
    cmp  byte [r13 + SC_D], 0
    je   .sem_d
    add  dword [rsp+64], VEL        ; D: direita (x aumenta)
.sem_d:

    ; ---- limita x entre 0 e W - largura ----
    mov  eax, [rsp+64]
    test eax, eax
    jge  .x_min_ok
    xor  eax, eax                   ; passou da esquerda: x = 0
.x_min_ok:
    mov  ecx, W
    sub  ecx, [tex_w]               ; x máximo
    cmp  eax, ecx
    jle  .x_max_ok
    mov  eax, ecx                   ; passou da direita: x = máximo
.x_max_ok:
    mov  [rsp+64], eax

    ; ---- limita y entre 0 e H - altura ----
    mov  eax, [rsp+68]
    test eax, eax
    jge  .y_min_ok
    xor  eax, eax
.y_min_ok:
    mov  ecx, H
    sub  ecx, [tex_h]
    cmp  eax, ecx
    jle  .y_max_ok
    mov  eax, ecx
.y_max_ok:
    mov  [rsp+68], eax


.desenha:
    mov  rdi, r12 
    call SDL_RenderClear

    mov rdi, r12
    mov rsi, r15
    xor edx, edx
    xor ecx, ecx
    call SDL_RenderCopy

    mov  rdi, r12                 ; SDL_RenderCopy(renderer, texture, NULL, &destino)
    mov  rsi, r14
    xor  edx, edx                 ; srcrect = NULL -> usa a imagem inteira
    lea  rcx, [rsp+64]            ; dstrect
    call SDL_RenderCopy

    mov  rdi, r12
    call SDL_RenderPresent

    mov  edi, 16
    call SDL_Delay
    jmp  .loop

.fim:
    mov  rdi, r15
    call SDL_DestroyTexture
    mov  rdi, r14
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

section .note.GNU-stack noexec