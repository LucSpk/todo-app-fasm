format ELF64 executalbe 

include "linux_x86_64.inc"

MAX_CONN        equ 5
REQUEST_CAP     equ 128 * 1024
TODO_SIZE       equ 256
TODO_CAP        equ 246

segment readable executable

include "utils.inc"

entry main
main: 