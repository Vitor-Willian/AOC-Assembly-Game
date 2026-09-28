# AOC-Assembly-Game

## Como rodar:
No terminal:
- make (compila o código)
- ./game (roda o código)

## Conceitos básicos:
rax 	;resultado de operações e número da syscall  
rbx, r12–r15	;uso geral (a função chamada deve preservá-los)  
rcx, rdx, rsi, rdi, r8–r11  	;uso geral e argumentos (podem ser sobrescritos)  
rsp	    ;ponteiro da pilha (stack)  
rbp	    ;ponteiro de base do frame (opcional)  
rip	    ;próxima instrução a executar  
  
section .data      ; dados inicializados (textos, constantes)  
section .bss       ; dados não inicializados (buffers grandes)  
section .text      ; código  

### Operações

mov rax, 10        ; rax = 10  
add rax, 5         ; rax += 5  
sub rax, 3         ; rax -= 3  
inc rax            ; rax++  
dec rax            ; rax--  
imul rax, 4        ; rax *= 4  
and rax, 0xFF      ; AND bit a bit  
or  rax, 1         ; OR  
xor rax, rbx       ; XOR  
shl rax, 2         ; desloca 2 bits à esquerda (×4)  
shr rax, 1         ; desloca à direita (÷2, sem sinal)  
  
Divisão é um caso especial: div rbx divide rdx:rax por rbx, deixando o quociente em rax e o resto em rdx. Antes dela, você precisa zerar rdx com xor rdx, rdx
  
### Jump

cmp rax, 10  
je      ; salta se rax == 10  
jne     ; salta se !=  
jl      ; salta se <  (com sinal)  
jg      ; salta se >  (com sinal)  
jmp     ; salta sempre  
  
### Laço
mov rcx, 5  
.laco:  
    ; ... corpo ...  
    dec rcx  
    jnz .laco       ; repete enquanto rcx != 0  

### Memória
section .data  
    vida  dq 100          ; dq = 8 bytes (quad word)  
    pos_x db 5            ; db = 1 byte  
section .bss  
    mapa  resb 200        ; reserva 200 bytes  
  
section .text  
    mov rax, [vida]       ; lê 8 bytes  
    add rax, 10  
    mov [vida], rax       ; escreve de volta  
    mov byte [pos_x], 7   ; precisa dizer o tamanho quando não há registrador  
    lea rsi, [mapa]       ; carrega o ENDEREÇO em rsi  
  
### Endereço Indexado
mov al, [mapa + rbx]         ; mapa[rbx]
mov rax, [tabela + rcx*8]    ; array de 8 bytes por elemento
push rax     ; empilha (rsp diminui 8)
pop  rbx     ; desempilha

### Funções
call empilha o endereço de retorno e salta. ret volta. Pela convenção System V (Linux):  
  
Argumentos: rdi, rsi, rdx, rcx, r8, r9, nessa ordem.  
Retorno: rax.  
A função deve preservar: rbx, rbp, r12–r15 (se usar, faça push e pop).  
Podem ser sobrescritos: todos os outros.  
nasm  
; soma(a, b) -> rax  
soma:  
    mov rax, rdi  
    add rax, rsi  
    ret  
  
; uso:  
    mov rdi, 3  
    mov rsi, 4  
    call soma        ; rax = 7  