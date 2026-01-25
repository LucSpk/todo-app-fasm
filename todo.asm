format ELF64 executable 

include "linux_x86_64.inc"

MAX_CONN    equ 5
REQUEST_CAP equ 128 * 1024
TODO_SIZE   equ 256
TODO_CAP    equ 256

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
    CMP     rax, 0
    JL      .fatal_error

.next_request:
    
    funcall2 write_cstr, STDOUT, accept_trace_msg
    accept [sockfd], cliaddr.sin_family, cliaddr_len
    CMP     rax, 0
    JL      .fatal_error

    MOV     qword [connfd], rax
    read [connfd], request, REQUEST_CAP
    CMP     rax, 0
    JL      .fatal_error

    MOV     [request_len], rax
    MOV     [request_cur], request
    write STDOUT, [request_cur], [request_len]

    funcall4 starts_with, [request_cur], [request_len], get, get_len
    CMP     rax, 0
    JG      .handle_get_method

.handle_get_method:
    ADD     [request_cur], get_len
    SUB     [request_len], get_len

    funcall4 starts_with, [request_cur], [request_len], index_route, index_route_len
    CALL    starts_with
    CMP     rax, 0
    jg .serve_index_page

.serve_index_page:
    funcall2 write_cstr, [connfd], index_page_response
    funcall2 write_cstr, [connfd], index_page_header

    close [connfd]
    close [sockfd]
    exit 0

.fatal_error:
    funcall2 write_cstr, STDERR, error_msg
    close [connfd]
    close [sockfd]
    exit 1


render_todos_as_html:
    PUSH    0
    PUSH    todo_begin

.next_todo:
    MOV     rax, [rsp]
    MOV     rbx, todo_begin
    ADD     rbx, [todo_end_offset]
    CMP     rax, rbx
    JGE     .done

    funcall2 write_cstr, [connfd], todo_header
    funcall2 write_cstr, [connfd], delete_button_prefix
    funcall2 write_uint, [connfd], [rsp + 8]
    funcall2 write_cstr, [connfd], delete_button_suffix

    MOV     rax, SYS_write
    MOV     rdi, [connfd]
    MOV     rsi, [rsp]
    XOR     rdx, rdx
    MOV     dl, byte [rsi]
    INC     rsi
    SYSCALL

    funcall2 write_cstr, [connfd], todo_footer
    MOV     rax, [rsp]
    ADD     rax, TODO_SIZE
    MOV     [rsp], rax
    INC     qword [rsp+8]
    JMP     .next_todo

.done:
    POP     rax
    POP     rax
    RET

segment readable writeable

enable              dd 1
sockfd              dq -1
connfd              dq -1

servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family

cliaddr servaddr_in
cliaddr_len dd sizeof_servaddr

start               db "INFO: Starting Web Server!", 10, 0
socket_trace_msg    db "INFO: Creating a socket...", 10, 0
bind_trace_msg      db "INFO: Binding the socket...", 10, 0
listen_trace_msg    db "INFO: Listening to the socket...", 10, 0
accept_trace_msg    db "INFO: Waiting for client connections...", 10, 0

error_msg           db "FATAL ERROR!", 10, 0

request     rb REQUEST_CAP
request_len rq 1
request_cur rq 1

get db "GET "
get_len = $ - get

index_route db "/ "
index_route_len = $ - index_route

index_page_response  db "HTTP/1.1 200 OK", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db 0
index_page_header    db "<h1>To-Do</h1>", 10
                     db "<ul>", 10
                     db 0
todo_header          db "  <li>"
                     db 0
todo_footer          db "</li>", 10
                     db 0
delete_button_prefix db "<form style='display: inline' method='post' action='/'>"
                     db "<button style='width: 25px' type='submit' name='delete' value='"
                     db 0
delete_button_suffix db "'>x</button></form> "
                     db 0

todo_begin rb TODO_SIZE * TODO_CAP
todo_end_offset rq 1
