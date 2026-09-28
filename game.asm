global _start

section .data
    msg db "Ola, mundo!", 10     ; 10 = nova linha
    len equ $ - msg              ; tamanho calculado na montagem

section .text
_start:
    mov rax, 1        ; syscall write
    mov rdi, 1        ; descritor 1 = stdout
    mov rsi, msg      ; endereço do texto
    mov rdx, len      ; quantos bytes
    syscall

    mov rax, 60       ; syscall exit
    xor rdi, rdi      ; código de saída 0
    syscall