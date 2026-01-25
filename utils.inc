write_cstr:
    PUSH    rsi
    PUSH    rdi
    MOV     rdi, rsi
    CALL    strlen

    MOV     rdx, rax
    MOV     rax, SYS_write
    POP     rdi
    POP     rsi
    SYSCALL
    RET

strlen:
    PUSH    rdi
    XOR     rax, rax
.next_char:
    MOV     al, byte [rdi]
    CMP     rax, 0
    JE      .done

    INC     rdi
    JMP     .next_char

.done:
    POP     rsi
    SUB     rdi, rsi
    MOV     rax, rdi
    RET
