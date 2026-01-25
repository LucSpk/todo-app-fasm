SYS_write equ 1
STDOUT equ 1

macro funcall2 func, a, b
{
    MOV     rdi, a
    MOV     rsi, b
    CALL    func
}