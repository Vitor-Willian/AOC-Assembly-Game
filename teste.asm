default rel

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

W equ 640
H equ 480

section .data
    titulo      db "Sprite", 0
    caminho_bmp db "Teste Rei-1.png.bmp", 0
    modo_leitura db "rb", 0

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
    sub  rsp, 88          ; <- era 80

    mov  edi, SDL_INIT_VIDEO
    call SDL_Init

    lea  rdi, [titulo]
    mov  esi, WINDOWPOS_CENTERED
    mov  edx, WINDOWPOS_CENTERED
    mov  ecx, W
    mov  r8d, H
    mov  r9d, SDL_WINDOW_SHOWN
    call SDL_CreateWindow
    mov  rbx, rax

    mov  rdi, rbx
    mov  esi, -1
    xor  edx, edx
    call SDL_CreateRenderer
    mov  r12, rax

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

.loop:
.eventos:
    mov  rdi, rsp
    call SDL_PollEvent
    test eax, eax
    jz   .desenha
    cmp  dword [rsp], SDL_QUIT
    je   .fim
    jmp  .eventos

.desenha:
    mov  rdi, r12                ; fundo cinza-escuro
    mov  esi, 30
    mov  edx, 30
    mov  ecx, 30
    mov  r8d, 255
    call SDL_SetRenderDrawColor
    mov  rdi, r12
    call SDL_RenderClear

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
    mov  rdi, r14
    call SDL_DestroyTexture
    mov  rdi, r12
    call SDL_DestroyRenderer
    mov  rdi, rbx
    call SDL_DestroyWindow
    call SDL_Quit

    add  rsp, 88          ; <- era 80
    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    xor  eax, eax
    ret

section .note.GNU-stack noexec