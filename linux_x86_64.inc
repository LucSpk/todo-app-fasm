SYS_read        equ 0
SYS_write       equ 1
SYS_open        equ 2
SYS_close       equ 3
SYS_exit        equ 60
SYS_socket      equ 41
SYS_setsockopt  equ 54
SYS_bind        equ 49
SYS_listen      equ 50
SYS_accept      equ 43

O_WRONLY = 1
O_CREAT = 64
O_TRUNC = 512

AF_INET         equ 2
SOCK_STREAM     equ 1
INADDR_ANY      equ 0

SOL_SOCKET = 1
SO_REUSEADDR = 2

STDOUT          equ 1
STDERR          equ 2

struc servaddr_in
{
    .sin_family dw 0
    .sin_port   dw 0
    .sin_addr   dd 0
    .sin_zero   dq 0
}

macro funcall2 func, a, b {
    MOV     rdi, a
    MOV     rsi, b
    CALL    func
}

macro funcall3 func, a, b, c {
    MOV     rdi, a
    MOV     rsi, b
    MOV     rdx, c
    CALL    func
}

macro funcall4 func, a, b, c, d {
    MOV     rdi, a
    MOV     rsi, b
    MOV     rdx, c
    MOV     r10, d
    CALL    func
}


macro exit code {
    syscall1 SYS_exit, code
}

macro open filename, flags, mode {
    syscall3 SYS_open, filename, flags, mode
}

macro socket domain, type, protocol {
    syscall3 SYS_socket, domain, type, protocol
}

macro setsockopt sockfd, level, optname, optval, optlen {
    syscall5 SYS_setsockopt, sockfd, level, optname, optval, optlen
}

macro close fd {
    syscall1 SYS_close, fd
}

macro bind sockfd, addr, addrlen {
    syscall3 SYS_bind, sockfd, addr, addrlen
}

macro listen sockfd, backlog {
    syscall2 SYS_listen, sockfd, backlog
}

macro accept sockfd, addr, addrlen {
    syscall3 SYS_accept, sockfd, addr, addrlen
}

macro read fd, buf, count {
    syscall3 SYS_read, fd, buf, count
}

macro write fd, buf, count {
    syscall3 SYS_write, fd, buf, count
}


macro syscall1 number, a {
    MOV     rax, number
    MOV     rdi, a
    SYSCALL
}

macro syscall2 number, a, b {
    MOV     rax, number
    MOV     rdi, a
    MOV     rsi, b
    SYSCALL
}

macro syscall3 number, a, b, c {
    MOV     rax, number
    MOV     rdi, a
    MOV     rsi, b
    MOV     rdx, c
    SYSCALL
}

macro syscall5 number, a, b, c, d, e {
    MOV     rax, number
    MOV     rdi, a
    MOV     rsi, b
    MOV     rdx, c
    MOV     r10, d
    MOV     r8,  e
    SYSCALL
}
