format ELF64 executable 

include "linux_x86_64.inc"

segment readable executable

include "utils.inc"

entry main
main: 

    funcall2 write_cstr, STDOUT, start


segment readable writeable
start            db "INFO: Starting Web Server!", 10, 0