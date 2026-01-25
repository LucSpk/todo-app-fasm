SYS_write   equ 1
SYS_exit    equ 60

STDOUT equ 1

macro funcall2 func, a, b
{
    MOV     rdi, a
    MOV     rsi, b
    CALL    func
}

macro exit code
{
    mov rax, SYS_exit
    mov rdi, code
    syscall
}