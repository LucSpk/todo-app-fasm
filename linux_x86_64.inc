SYS_write   equ 1
SYS_exit    equ 60
SYS_socket  equ 41

AF_INET equ 2
SOCK_STREAM equ 1

STDOUT equ 1
STDERR equ 2

macro funcall2 func, a, b
{
    MOV     rdi, a
    MOV     rsi, b
    CALL    func
}

macro exit code
{
    MOV     rax, SYS_exit
    MOV     rdi, code
    SYSCALL
}

macro socket domain, type, protocol
{
    MOV rax, SYS_socket
    MOV rdi, domain
    MOV rsi, type
    MOV rdx, protocol
    SYSCALL
}

