default rel

extern SDL_Init, SDL_CreateWindow, SDL_CreateRenderer
extern SDL_PollEvent
extern SDL_SetRenderDrawColor, SDL_RenderClear, SDL_RenderFillRect
extern SDL_RenderPresent, SDL_Delay
extern SDL_DestroyRenderer, SDL_DestroyWindow, SDL_Quit
global main

SDL_INIT_VIDEO     equ 0x20
WINDOWPOS_CENTERED equ 0x2FFF0000
SDL_WINDOW_SHOWN   equ 4
SDL_QUIT           equ 0x100

W      equ 20               ; largura da grade (células)
H      equ 15               ; altura da grade (células)
STRIDE equ W + 1            ; +1 para o \n no fim de cada linha do terminal
CELL   equ 32               ; pixels por célula na janela (20*32=640, 15*32=480)

RX     equ 6                ; retângulo, em células
RY     equ 5
RW     equ 8
RH     equ 5

section .data
    msg db "Starting the game...", 10     ; 10 = \n
    len equ $ - msg                       ; tamanho do texto em bytes
    titulo db "Quadrado", 0

section .bss
    screen resb STRIDE * H                ; ainda sem uso (para o desenho em texto)

section .text

; Função: escreve a mensagem no terminal e volta para quem chamou
terminal:
    mov rax, 1        ; syscall write
    mov rdi, 1        ; stdout
    lea rsi, [msg]    ; endereço da mensagem
    mov rdx, len      ; quantidade de bytes
    syscall
    ret               ; volta para o main 

main:
    push rbx                    ; rbx = janela
    push r12                    ; r12 = renderer
    sub  rsp, 88

    call terminal               ; imprime a mensagem no terminal

    ; ---- abre a janela ----
    mov  edi, SDL_INIT_VIDEO
    call SDL_Init

    lea  rdi, [titulo]
    mov  esi, WINDOWPOS_CENTERED
    mov  edx, WINDOWPOS_CENTERED
    mov  ecx, W * CELL          ; 640
    mov  r8d, H * CELL          ; 480
    mov  r9d, SDL_WINDOW_SHOWN
    call SDL_CreateWindow
    mov  rbx, rax

    mov  rdi, rbx
    mov  esi, -1
    xor  edx, edx
    call SDL_CreateRenderer
    mov  r12, rax

    ; o retângulo em pixels (células * CELL)
    mov  dword [rsp+64], RX * CELL
    mov  dword [rsp+68], RY * CELL
    mov  dword [rsp+72], RW * CELL
    mov  dword [rsp+76], RH * CELL

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
    mov  rdi, r12               ; fundo azul-escuro
    mov  esi, 20
    mov  edx, 20
    mov  ecx, 40
    mov  r8d, 255
    call SDL_SetRenderDrawColor
    mov  rdi, r12
    call SDL_RenderClear

    mov  rdi, r12               ; retângulo amarelo
    mov  esi, 255
    mov  edx, 200
    xor  ecx, ecx
    mov  r8d, 255
    call SDL_SetRenderDrawColor
    mov  rdi, r12
    lea  rsi, [rsp+64]
    call SDL_RenderFillRect

    mov  rdi, r12
    call SDL_RenderPresent

    mov  edi, 16
    call SDL_Delay
    jmp  .loop

.fim:
    mov  rdi, r12
    call SDL_DestroyRenderer
    mov  rdi, rbx
    call SDL_DestroyWindow
    call SDL_Quit

    add  rsp, 88
    pop  r12
    pop  rbx
    xor  eax, eax
    ret

section .note.GNU-stack noexec