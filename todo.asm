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

    funcall4 starts_with, [request_cur], [request_len], post, post_len
    CMP     rax, 0
    JG      .handle_post_method

    JMP .serve_error_405


.handle_get_method:
    ADD     [request_cur], get_len
    SUB     [request_len], get_len

    funcall4 starts_with, [request_cur], [request_len], index_route, index_route_len
    CALL    starts_with
    CMP     rax, 0
    JG      .serve_index_page

    JMP     .serve_error_404

.handle_post_method:
    ADD     [request_cur], post_len
    SUB     [request_len], post_len

    funcall4 starts_with, [request_cur], [request_len], index_route, index_route_len
    CMP     rax, 0
    JG      .process_add_or_delete_todo_post 

.process_add_or_delete_todo_post:
    CALL    drop_http_header
    CMP     rax, 0
    JE      .serve_error_400

    funcall4 starts_with, [request_cur], [request_len], todo_form_data_prefix, todo_form_data_prefix_len
    CMP     rax, 0
    JG      .add_new_todo_and_serve_index_page

    funcall4 starts_with, [request_cur], [request_len], delete_form_data_prefix, delete_form_data_prefix_len
    CMP     rax, 0
    JG      .delete_todo_and_serve_index_page

    JMP     .serve_error_400

.serve_index_page:
    funcall2 write_cstr, [connfd], index_page_response
    funcall2 write_cstr, [connfd], index_page_header
    CALL    render_todos_as_html

    funcall2 write_cstr, [connfd], index_page_footer
    close [connfd]

    JMP     .next_request

.serve_error_400:
    funcall2 write_cstr, [connfd], error_400
    close [connfd]
    JMP     .next_request

.serve_error_404:
    funcall2 write_cstr, [connfd], error_404
    close [connfd]
    JMP     .next_request

    close [connfd]
    close [sockfd]
    exit 0

.serve_error_405:
    funcall2 write_cstr, [connfd], error_405
    close [connfd]
    JMP     .next_request

.add_new_todo_and_serve_index_page:
    ADD     [request_cur], todo_form_data_prefix_len
    SUB     [request_len], todo_form_data_prefix_len

    funcall2 add_todo, [request_cur], [request_len]
    CALL    save_todos
    JMP     .serve_index_page

.delete_todo_and_serve_index_page:
    ADD     [request_cur], delete_form_data_prefix_len
    SUB     [request_len], delete_form_data_prefix_len

    funcall2 parse_uint, [request_cur], [request_len]
    MOV     rdi, rax
    CALL    delete_todo
    CALL    save_todos
    JMP     .serve_index_page

.fatal_error:
    funcall2 write_cstr, STDERR, error_msg
    close [connfd]
    close [sockfd]
    exit 1

drop_http_header:
.next_line:
    funcall4 starts_with, [request_cur], [request_len], clrs, 2
    CMP     rax, 0
    JG      .reached_end

    funcall3 find_char, [request_cur], [request_len], 10
    CMP     rax, 0
    JE      .invalid_header

    MOV     rsi, rax
    SUB     rsi, [request_cur]
    INC     rsi
    ADD     [request_cur], rsi
    SUB     [request_len], rsi

    JMP     .next_line
    

.reached_end:
    ADD     [request_cur], 2
    SUB     [request_len], 2
    MOV     rax, 1
    RET

.invalid_header:
    XOR     rax, rax
    RET

;; rdi - size_t index
delete_todo:
    MOV     rax, TODO_SIZE
    MUL     rdi
    CMP     rax, [todo_end_offset]
    JGE     .overflow

    ;; ****** ****** ******
    ;; ^      ^             ^
    ;; dst    src           end
    ;;
    ;; count = end - src

    MOV     rdi, todo_begin
    ADD     rdi, rax
    MOV     rsi, todo_begin
    ADD     rsi, rax
    ADD     rsi, TODO_SIZE
    MOV     rdx, todo_begin
    ADD     rdx, [todo_end_offset]
    SUB     rdx, rsi
    CALL    memcpy

    SUB     [todo_end_offset], TODO_SIZE

.overflow:
    RET


save_todos:
    open todo_db_file_path, O_CREAT or O_WRONLY or O_TRUNC, 420
    CMP     rax, 0
    JL      .fail
    PUSH    rax
    write qword [rsp], todo_begin, [todo_end_offset]
    close qword [rsp]
    POP     rax

.fail:
    RET

;; TODO: sanitize the input to prevent XSS
;; rdi - void *buf
;; rsi - size_t count
add_todo:
    ;; Check for TODO capacity overflow
    CMP      qword [todo_end_offset], TODO_SIZE * TODO_CAP
    JGE      .capacity_overflow

    ;; Truncate strings longer than 255
    MOV      rax, 0xFF
    CMP      rsi, rax
    CMOVG    rsi, rax

    PUSH     rdi ;; void *buf [rsp+8]
    PUSH     rsi ;; size_t count [rsp]

    ;; +*******
    ;;  ^
    ;;  rdi
    MOV     rdi, todo_begin
    ADD     rdi, [todo_end_offset]
    MOV     rdx, [rsp]
    MOV     byte [rdi], dl
    INC     rdi
    MOV     rsi, [rsp+8]
    CALL    memcpy

    ADD [todo_end_offset], TODO_SIZE

    POP     rsi
    POP     rdi
    MOV     rax, 0
    RET

.capacity_overflow:
    MOV      rax, 1
    RET

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

todo_db_file_path db "todo.db", 0

request     rb REQUEST_CAP
request_len rq 1
request_cur rq 1

get db "GET "
get_len = $ - get
post db "POST "
post_len = $ - post

index_route db "/ "
index_route_len = $ - index_route

clrs db 13, 10


error_400            db "HTTP/1.1 400 Bad Request", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Bad Request</h1>", 10
                     db "<a href='/'>Back to Home</a>", 10
                     db 0
error_404            db "HTTP/1.1 404 Not found", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Page not found</h1>", 10
                     db "<a href='/'>Back to Home</a>", 10
                     db 0
error_405            db "HTTP/1.1 405 Method Not Allowed", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Method not Allowed</h1>", 10
                     db "<a href='/'>Back to Home</a>", 10
                     db 0
index_page_response  db "HTTP/1.1 200 OK", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db 0
index_page_header    db "<h1>To-Do</h1>", 10
                     db "<ul>", 10
                     db 0
index_page_footer    db "  <li>", 10
                     db "    <form style='display: inline' method='post' action='/' enctype='text/plain'>", 10
                     db "        <input style='width: 25px' type='submit' value='+'>", 10
                     db "        <input type='text' name='todo' autofocus>", 10
                     db "    </form>", 10
                     db "  </li>", 10
                     db "</ul>", 10
                     db "<form method='post' action='/shutdown'>", 10
                     db "    <input type='submit' value='shutdown'>", 10
                     db "</form>", 10
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

todo_form_data_prefix db "todo="
todo_form_data_prefix_len = $ - todo_form_data_prefix
delete_form_data_prefix db "delete="
delete_form_data_prefix_len = $ - delete_form_data_prefix

todo_begin rb TODO_SIZE * TODO_CAP
todo_end_offset rq 1
