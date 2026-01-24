macro syscall1 number_of_sycall, a {
    MOV     rax, number_of_sycall
    MOV     rdi, a
    SYSCALL
}

macro syscall2 number_of_sycall, a, b {
    MOV     rax, number_of_sycall
    MOV     rdi, a
    MOV     rsi, b
    SYSCALL
}

macro syscall3 number_of_sycall, a, b, c {
    MOV     rax, number_of_sycall
    MOV     rdi, a
    MOV     rsi, b
    MOV     rdx, c
    SYSCALL
}

macro syscall5 number_of_sycall, a, b, c, d, e {
    MOV     rax, number_of_sycall
    MOV     rdi, a
    MOV     rsi, b
    MOV     rdx, c
    MOV     r10, d
    MOV     r8,  e
    SYSCALL
}

macro write fd, buf, count
{
    syscall3 SYS_write, fd, buf, count
}

macro read fd, buf, count
{
    syscall3 SYS_read, fd, buf, count
}

macro close fd
{
    syscall1 SYS_close, fd
}
