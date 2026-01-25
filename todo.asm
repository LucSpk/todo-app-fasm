format ELF64 executable 

include "linux_x86_64.inc"

MAX_CONN equ 5

segment readable executable

include "utils.inc"

entry main
main: 

    funcall2 write_cstr, STDOUT, start

    funcall2 write_cstr, STDOUT, socket_trace_msg
    socket AF_INET, SOCK_STREAM, 0
    CMP     rax, 0
    JL      .fatal_error

    MOV     qword [sockfd], rax

    setsockopt [sockfd], SOL_SOCKET, SO_REUSEADDR, enable, 4
    CMP     rax, 0
    JL      .fatal_error

    funcall2 write_cstr, STDOUT, bind_trace_msg
    MOV     word [servaddr.sin_family], AF_INET
    MOV     word [servaddr.sin_port], 14619
    MOV     dword [servaddr.sin_addr], INADDR_ANY
    bind [sockfd], servaddr.sin_family, sizeof_servaddr
    CMP     rax, 0
    JL      .fatal_error

    funcall2 write_cstr, STDOUT, listen_trace_msg
    listen [sockfd], MAX_CONN

    close [sockfd]
    exit 0

.fatal_error:
    funcall2 write_cstr, STDERR, error_msg
    close [sockfd]
    exit 1


segment readable writeable

enable              dd 1
sockfd              dq -1

servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family

start               db "INFO: Starting Web Server!", 10, 0
socket_trace_msg    db "INFO: Creating a socket...", 10, 0
bind_trace_msg      db "INFO: Binding the socket...", 10, 0
listen_trace_msg    db "INFO: Listening to the socket...", 10, 0

error_msg           db "FATAL ERROR!", 10, 0