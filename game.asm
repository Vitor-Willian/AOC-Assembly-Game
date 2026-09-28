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

W      equ 50               ; largura da grade (células)
H      equ 25               ; altura da grade (células)
STRIDE equ W + 1            ; +1 para o \n no fim de cada linha do terminal
CELL   equ 32               ; pixels por célula na janela

RX     equ 23                ; posição X do retângulo, em células
RY     equ 10                ; posição Y do retângulo, em células
RW     equ 10                 ; largura do retângulo, em pixels
RH     equ 10                ; altura do retângulo, em pixels

RX2    equ 24                ; posição X do segundo retângulo, em células
RY2    equ 10                ; posição Y do segundo retângulo, em células

SIZE equ 20
CENTER_X   equ (W * CELL) / 2
CENTER_Y   equ (H * CELL) / 2

section .data

    msg db "Starting the game...", 10     ; 10 = \n
    len equ $ - msg                       ; tamanho do texto em bytes
    titulo db "Quadrado", 0                ; título da janela terminado com zero

section .text

; Função: escreve a mensagem no terminal e volta para quem chamou
terminal:
    mov rax, 1                 ; syscall write
    mov rdi, 1                 ; stdout
    lea rsi, [msg]             ; endereço da mensagem
    mov rdx, len               ; quantidade de bytes
    syscall                    ; executa a chamada ao sistema
    ret                        ; volta para o main

main:
    push rbx                   ; salva RBX, usado para guardar a janela
    push r12                   ; salva R12, usado para guardar o renderer
    sub rsp, 88                ; reserva espaço para SDL_Event e SDL_Rect

    call terminal              ; imprime a mensagem no terminal

    ; ---- abre a janela ----
    mov edi, SDL_INIT_VIDEO    ; seleciona o subsistema de vídeo do SDL
    call SDL_Init              ; inicializa o SDL

    lea rdi, [titulo]          ; primeiro argumento: título da janela
    mov esi, WINDOWPOS_CENTERED ; segundo argumento: posição X centralizada
    mov edx, WINDOWPOS_CENTERED ; terceiro argumento: posição Y centralizada
    mov ecx, W * CELL          ; quarto argumento: largura da janela
    mov r8d, H * CELL          ; quinto argumento: altura da janela
    mov r9d, SDL_WINDOW_SHOWN  ; sexto argumento: janela visível
    call SDL_CreateWindow      ; cria a janela
    mov rbx, rax               ; salva o endereço da janela em RBX

    mov rdi, rbx               ; primeiro argumento: janela
    mov esi, -1                ; usa o driver de vídeo padrão
    xor edx, edx               ; nenhuma flag adicional
    call SDL_CreateRenderer    ; cria o renderer
    mov r12, rax               ; salva o endereço do renderer em R12

; primeiro retângulo
    mov dword [rsp+64], RX * CELL + (CELL - RW) / 2
                                ; calcula X em pixels e centraliza o retângulo

    mov dword [rsp+68], RY * CELL + (CELL - RH) / 2
                                ; calcula Y em pixels e centraliza o retângulo

    mov dword [rsp+72], RW     ; guarda a largura em pixels
    mov dword [rsp+76], RH     ; guarda a altura em pixels

.loop:
.eventos:
    mov rdi, rsp               ; endereço onde o SDL armazenará o evento
    call SDL_PollEvent         ; pega o próximo evento da fila
    test eax, eax              ; verifica se existe um evento
    jz .desenha                ; se não houver evento, desenha a janela

    cmp dword [rsp], SDL_QUIT ; verifica se o evento é SDL_QUIT
    je .fim                    ; se for, encerra o programa

    jmp .eventos               ; continua lendo os eventos

.desenha:
    mov rdi, r12               ; primeiro argumento: renderer
    mov esi, 0                 ; valor vermelho do fundo
    mov edx, 0                 ; valor verde do fundo
    mov ecx, 0                 ; valor azul do fundo
    mov r8d, 255               ; valor alfa, totalmente opaco
    call SDL_SetRenderDrawColor ; define a cor do fundo

    mov rdi, r12               ; primeiro argumento: renderer
    call SDL_RenderClear        ; limpa a tela usando a cor definida

    mov rdi, r12               ; primeiro argumento: renderer
    mov esi, 244               ; valor vermelho do primeiro retângulo
    mov edx, 208               ; valor verde do primeiro retângulo
    mov ecx, 163               ; valor azul do primeiro retângulo
    mov r8d, 255               ; valor alfa, totalmente opaco
    call SDL_SetRenderDrawColor ; define a cor do primeiro retângulo

    ; primeiro quadrado, acima do centro
    mov dword [rsp+64], CENTER_X - SIZE / 2   ; x = 795
    mov dword [rsp+68], CENTER_Y - SIZE       ; y = 390
    mov dword [rsp+72], SIZE            ; largura = 10
    mov dword [rsp+76], SIZE            ; altura = 10

    mov rdi, r12               ; primeiro argumento: renderer
    lea rsi, [rsp+64]          ; endereço do SDL_Rect reutilizado
    call SDL_RenderFillRect    ; desenha o primeiro retângulo

    mov rdi, r12               ; primeiro argumento: renderer
    mov esi, 0                 ; valor vermelho do segundo retângulo
    mov edx, 0                 ; valor verde do segundo retângulo
    mov ecx, 255               ; valor azul do segundo retângulo
    mov r8d, 255               ; valor alfa, totalmente opaco
    call SDL_SetRenderDrawColor ; define a cor do segundo retângulo

    ; segundo quadrado, abaixo do primeiro
    mov dword [rsp+64], CENTER_X - SIZE / 2   ; x = 795
    mov dword [rsp+68], CENTER_Y             ; y = 400
    mov dword [rsp+72], SIZE           ; largura = 10
    mov dword [rsp+76], SIZE           ; altura = 10

    mov rdi, r12               ; primeiro argumento: renderer
    lea rsi, [rsp+64]          ; usa o mesmo SDL_Rect reutilizado
    call SDL_RenderFillRect    ; desenha o segundo retângulo

    mov rdi, r12               ; primeiro argumento: renderer
    call SDL_RenderPresent      ; atualiza a janela com o conteúdo desenhado

    mov edi, 16                ; tempo de espera em milissegundos
    call SDL_Delay              ; aguarda para controlar a velocidade do loop

    jmp .loop                  ; volta para o início do loop principal

.fim:
    mov rdi, r12               ; endereço do renderer
    call SDL_DestroyRenderer   ; destrói o renderer

    mov rdi, rbx               ; endereço da janela
    call SDL_DestroyWindow     ; destrói a janela

    call SDL_Quit              ; encerra o SDL

    add rsp, 88                ; libera o espaço reservado na pilha
    pop r12                    ; restaura R12
    pop rbx                    ; restaura RBX

    xor eax, eax               ; retorna zero ao sistema operacional
    ret                        ; encerra main

section .note.GNU-stack noexec