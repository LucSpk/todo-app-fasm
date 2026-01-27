;; Generally useful utility functions

;; Write an integer to a file
;;   rdi - int fd
;;   rsi - uint64_t int x
write_uint:
    TEST    rsi, rsi
    JZ      .base_zero

    MOV     rcx, 10     ;; 10 literal for division
    MOV     rax, rsi    ;; keeping track of rsi in rax cause it's easier to div it like that
    MOV     r10, 0      ;; counter of how many digits we already converted

.next_digit:
    TEST    rax, rax
    JZ      .done
    MOV     rdx, 0
    DIV     rcx
    ADD     rdx, '0'
    DEC     rsp
    MOV     byte [rsp], dl
    INC     r10
    JMP     .next_digit

.done:
    write rdi, rsp, r10
    ADD     rsp, r10
    RET

.base_zero:
    DEC     rsp
    MOV     byte [rsp], '0'
    write rdi, rsp, 1
    INC     rsp
    RET

;; Write a NULL-terminated string to a file
;;   rdi - int fd
;;   rsi - const char *s
write_cstr:
    PUSH    rsi
    PUSH    rdi
    MOV     rdi, rsi
    CALL    strlen

    MOV     rdx, rax
    MOV     rax, SYS_write
    POP     rdi
    POP     rsi
    SYSCALL
    RET

;; Compute the length of a NULL-terminated string
;;   rdi - const char *s
strlen:
    PUSH    rdi
    XOR     rax, rax
.next_char:
    MOV     al, byte [rdi]
    CMP     rax, 0
    JE      .done

    INC     rdi
    JMP     .next_char

.done:
    POP     rsi
    SUB     rdi, rsi
    MOV     rax, rdi
    RET

;; Parse unsigned integer from a sized string
;;   rdi - void *buf
;;   rsi - size_t n
parse_uint:
    XOR     rax, rax
    XOR     rbx, rbx
    MOV     rcx, 10
.next_digit:
    CMP     rsi, 0
    JLE     .done

    MOV     bl, byte [rdi]
    CMP     rbx, '0'
    JL      .done
    CMP     rbx, '9'
    JG      .done
    SUB     rbx, '0'

    MUL     rcx
    ADD     rax, rbx

    INC     rdi
    DEC     rsi
    JMP     .next_digit

.done:
    RET

;; Copy a chunk of memory
;;   rdi - void *dst
;;   rsi - void *src
;;   rdx - size_t n
memcpy:
.next_byte:
    CMP     rdx, 0
    JLE     .done

    MOV     al, byte [rsi]
    MOV     byte [rdi], al

    INC     rdi
    INC     rsi
    DEC     rdx

    JMP     .next_byte
.done:
    RET


;; Find a character with a sized string
;;   rdi - void *buf
;;   rsi - size_t n
;;   rdx - char c
find_char:
    CMP     rsi, 0
    JLE     .not_found

    MOV     al, byte [rdi]
    CMP     dl, al
    JE      .found

    INC     rdi
    DEC     rsi
    JMP     find_char

.not_found:
    XOR     rax, rax
    RET
.found:
    MOV     rax, rdi
    RET


;; Check if text starts with the prefix (both strings are sized)
;;   rdi - void *text
;;   rsi - size_t text_len
;;   rdx - void *prefix
;;   r10 - size_t prefix_len
starts_with:
    XOR     rax, rax
    XOR     rbx, rbx

.next_char:
    CMP     rsi, 0
    JLE     .done

    CMP     r10, 0
    JLE     .done

    MOV     al, byte [rdi]
    MOV     bl, byte [rdx]
    CMP     rax, rbx
    JNE     .done

    DEC     rsi
    INC     rdi
    DEC     r10
    INC     rdx
    JMP     .next_char

.done:
    CMP     r10, 0
    JE      .yes

.no:
    MOV     rax, 0
    RET

.yes:
    MOV     rax, 1
    RET
