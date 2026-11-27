; Menu compartilhado por Linux e Windows, sem fontes ou bibliotecas extras.
%macro PAUSA_API 1
%ifidn __OUTPUT_FORMAT__, win64
    chamar %1
%else
    call %1
%endif
%endmacro

extern SDL_RenderFillRect
extern Mix_Pause, Mix_Resume, Mix_PauseMusic, Mix_ResumeMusic

; Expandido dentro de main: todos os desvios permanecem no loop de eventos.
%macro PAUSA_EVENTOS 0
    cmp byte [rsp+13], 0
    jne .eventos
    cmp dword [rsp+20], SDLK_ESCAPE
    je .pausa_alternar
    cmp dword [pausa_ativa], 0
    je .pausa_evento_fim
    mov eax, [rsp+16]
    cmp eax, SC_UP
    je .pausa_anterior
    cmp eax, SC_W
    je .pausa_anterior
    cmp eax, SC_DOWN
    je .pausa_proxima
    cmp eax, SC_S
    je .pausa_proxima
    cmp eax, 40                  ; Enter
    je .pausa_confirmar
    cmp eax, 88                  ; Enter do teclado numerico
    je .pausa_confirmar
    jmp .eventos                ; bloqueia ataques e atalhos de desenvolvimento
.pausa_anterior:
    dec dword [pausa_opcao]
    jns .eventos
    mov dword [pausa_opcao], 2
    jmp .eventos
.pausa_proxima:
    inc dword [pausa_opcao]
    cmp dword [pausa_opcao], 3
    jb .eventos
    mov dword [pausa_opcao], 0
    jmp .eventos
.pausa_confirmar:
    cmp dword [pausa_opcao], 0
    je .pausa_retomar
    cmp dword [pausa_opcao], 2
    je .fim
    jmp .menu_inicial                ; menu principal: reservado, ainda indisponivel
.pausa_alternar:
    cmp dword [pausa_ativa], 0
    jne .pausa_retomar
    mov dword [pausa_ativa], 1
    mov dword [pausa_opcao], 0
    mov edi, -1
    PAUSA_API Mix_Pause
    PAUSA_API Mix_PauseMusic
    jmp .eventos
.pausa_retomar:
    mov dword [pausa_ativa], 0
    mov dword [pausa_aguarda_teclas], 1
    mov edi, -1
    PAUSA_API Mix_Resume
    PAUSA_API Mix_ResumeMusic
    jmp .eventos
.pausa_evento_fim:
%endmacro

; Nunca passa pelo desenho normal enquanto pausado: ele tambem calcula dano.
%macro PAUSA_QUADRO 0
    cmp dword [pausa_ativa], 0
    jne .pausa_desenhar
    cmp dword [pausa_aguarda_teclas], 0
    je .pausa_quadro_fim
    ; Evita que a seta usada no menu vire um ataque ao retomar.
    lea rax, [pausa_teclas]
.pausa_soltar_teclas:
    movzx ecx, byte [rax]
    test ecx, ecx
    jz .pausa_teclas_liberadas
    cmp byte [r13+rcx], 0
    jne .pausa_esperar
    inc rax
    jmp .pausa_soltar_teclas
.pausa_esperar:
    mov edi, 16
    PAUSA_API SDL_Delay
    jmp .eventos
.pausa_teclas_liberadas:
    mov dword [pausa_aguarda_teclas], 0
    jmp .pausa_quadro_fim
.pausa_desenhar:
    call DesenharMenuPausa
    jmp .apresenta_quadro
.pausa_quadro_fim:
%endmacro

%macro PAUSA_COR 3
    mov rdi, r12
    mov esi, %1
    mov edx, %2
    mov ecx, %3
    mov r8d, 255
    PAUSA_API SDL_SetRenderDrawColor
%endmacro

%macro PAUSA_TEXTO 3
    lea rdi, [%1]
    mov esi, %2
    mov edx, %3
    call DesenharTextoPausa
%endmacro

section .data
    pausa_titulo db 'PAUSADO', 0
    pausa_retomar db 'RETOMAR', 0
    pausa_principal db 'MENU PRINCIPAL', 0
    pausa_em_breve db 'EM BREVE', 0
    pausa_sair db 'SAIR DO JOGO', 0
    pausa_ajuda db 'W S OU SETAS   ENTER CONFIRMA', 0
    pausa_esc db 'ESC RETOMA', 0
    pausa_teclas db 26, 4, 22, 7, 79, 80, 81, 82, 40, 88, 41, 0
    pausa_painel dd 210, 126, 380, 230
    pausa_botoes dd 230, 151, 340, 48
                 dd 230, 215, 340, 72
                 dd 230, 295, 340, 48
    ; Fonte de 5 x 7 pixels, A a Z. Cada byte representa uma linha.
    pausa_fonte:
    db 14,17,17,31,17,17,17 ; A
    db 30,17,17,30,17,17,30 ; B
    db 14,17,16,16,16,17,14 ; C
    db 30,17,17,17,17,17,30 ; D
    db 31,16,16,30,16,16,31 ; E
    db 31,16,16,30,16,16,16 ; F
    db 14,17,16,23,17,17,15 ; G
    db 17,17,17,31,17,17,17 ; H
    db 14,4,4,4,4,4,14      ; I
    db 7,2,2,2,18,18,12    ; J
    db 17,18,20,24,20,18,17 ; K
    db 16,16,16,16,16,16,31 ; L
    db 17,27,21,21,17,17,17 ; M
    db 17,25,21,19,17,17,17 ; N
    db 14,17,17,17,17,17,14 ; O
    db 30,17,17,30,16,16,16 ; P
    db 14,17,17,17,21,18,13 ; Q
    db 30,17,17,30,20,18,17 ; R
    db 15,16,16,14,1,1,30   ; S
    db 31,4,4,4,4,4,4      ; T
    db 17,17,17,17,17,17,14 ; U
    db 17,17,17,17,17,10,4  ; V
    db 17,17,17,21,21,21,10 ; W
    db 17,17,10,4,10,17,17  ; X
    db 17,17,10,4,4,4,4    ; Y
    db 31,1,2,4,8,16,31    ; Z

section .bss
    pausa_ativa resd 1
    pausa_opcao resd 1
    pausa_aguarda_teclas resd 1

section .text
DesenharMenuPausa:
    sub rsp, 8
    PAUSA_COR 16, 19, 25
    mov rdi, r12
    PAUSA_API SDL_RenderClear
    PAUSA_COR 30, 35, 44
    mov rdi, r12
    lea rsi, [pausa_painel]
    PAUSA_API SDL_RenderFillRect
    PAUSA_COR 96, 69, 38
    mov eax, [pausa_opcao]
    shl eax, 4
    lea rsi, [pausa_botoes]
    add rsi, rax
    mov rdi, r12
    PAUSA_API SDL_RenderFillRect
    PAUSA_COR 239, 193, 112
    PAUSA_TEXTO pausa_titulo, 337, 78
    PAUSA_COR 242, 239, 230
    PAUSA_TEXTO pausa_retomar, 337, 165
    PAUSA_TEXTO pausa_sair, 292, 309
    PAUSA_COR 154, 158, 166
    PAUSA_TEXTO pausa_principal, 274, 240
    PAUSA_TEXTO pausa_ajuda, 148, 378
    PAUSA_TEXTO pausa_esc, 310, 411
    add rsp, 8
    ret

; rdi = texto A-Z/espacos, esi = x, edx = y; r12 = renderer.
; Preserva os registradores persistentes de main nas duas plataformas.
DesenharTextoPausa:
    push rbx
    push rbp
    push r13
    push r14
    push r15
    push rdi
    push rsi
    sub rsp, 32                ; SDL_Rect e indice de coluna; pilha alinhada
    mov rbx, rdi
    mov r13d, esi
    mov r14d, edx
    mov dword [rsp+8], 3
    mov dword [rsp+12], 3
.letra:
    movzx eax, byte [rbx]
    test eax, eax
    jz .fim
    sub eax, 'A'
    cmp eax, 25
    ja .proxima
    imul eax, 7
    lea r15, [pausa_fonte]
    add r15, rax
    xor ebp, ebp
.linha:
    mov dword [rsp+16], 0
.coluna:
    mov ecx, 4
    sub ecx, [rsp+16]
    movzx eax, byte [r15+rbp]
    bt eax, ecx
    jnc .avanca_coluna
    mov eax, [rsp+16]
    lea eax, [eax+eax*2]
    add eax, r13d
    mov [rsp], eax
    lea eax, [ebp+ebp*2]
    add eax, r14d
    mov [rsp+4], eax
    mov rdi, r12
    mov rsi, rsp
    PAUSA_API SDL_RenderFillRect
.avanca_coluna:
    inc dword [rsp+16]
    cmp dword [rsp+16], 5
    jb .coluna
    inc ebp
    cmp ebp, 7
    jb .linha
.proxima:
    add r13d, 18
    inc rbx
    jmp .letra
.fim:
    add rsp, 32
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop rbp
    pop rbx
    ret
