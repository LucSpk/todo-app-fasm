format ELF64 executable 

include "linux_x86_64.inc"

segment readable executable

include "utils.inc"

entry main
main: 

    funcall2 write_cstr, STDOUT, start

    funcall2 write_cstr, STDOUT, socket_trace_msg
    socket AF_INET, SOCK_STREAM, 0
    CMP     rax, 0
    JL      .fatal_error

    exit 0

.fatal_error:
    funcall2 write_cstr, STDERR, error_msg
    exit 1


segment readable writeable
start            db "INFO: Starting Web Server!", 10, 0
socket_trace_msg db "INFO: Creating a socket...", 10, 0
error_msg        db "FATAL ERROR!", 10, 0