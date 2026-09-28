global _start

section .data
    msg db "Starting the game...", 10     ; 10 = \n
    len equ $ - msg              ; tamanho do texto em bytes ($ = endereço atual, msg = endereço do texto)

section .text
_start:
; Sequência de instruções para escrever a mensagem na saída padrão

    mov rax, 1        ; número da syscall para sys_write
    mov rdi, 1        ; primeiro argumento: file descriptor (0 = input do teclado, 1 = saída padrão, 2 = erro)
    mov rsi, msg      ; Segundo argumento: ponteiro para a mensagem
    mov rdx, len      ; terceiro argumento: quantos bytes o kernel deve escrever
    syscall           ; chamada de sistema

; syscall exit
    mov rax, 60       ; número da syscall para sys_exit
    xor rdi, rdi      ; primeiro argumento: código de saída 0 (equivalente à mov rdi, 0)
    syscall