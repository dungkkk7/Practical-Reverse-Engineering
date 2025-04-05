; Chương trình tính độ dài chuỗi và in ra màn hình
; Build trên Ubuntu: nasm -f elf strlen.asm && ld -m elf_i386 strlen.o -o strlen && ./strlen

section .data
    ; Chuỗi mẫu để test
    str1    db  "Hello, World!", 0
    len     equ $ - str1 - 1        ; Độ dài thực tế (trừ ký tự null)
    
    ; Chuỗi thông báo kết quả
    msg     db  "Do dai chuoi la: ", 0
    msglen  equ $ - msg - 1

section .bss
    ; Biến để lưu số dưới dạng chuỗi
    numstr  resb    10              ; Buffer cho 10 ký tự

section .text
    global  _start

_start:
    ; In thông báo
    

    ; Tính độ dài chuỗi
    mov     esi, str1               ; pointer tới chuỗi
    xor     ecx, ecx                ; đếm = 0

count_loop:
    lodsb                           ; load byte từ [esi] vào al, tăng esi
    cmp     al, 0                   ; kiểm tra ký tự null
    je      end_count               ; nếu là null thì kết thúc
    inc     ecx                     ; tăng bộ đếm
    jmp     count_loop              ; tiếp tục vòng lặp

end_count:
    ; Chuyển số thành chuỗi
    mov     eax, ecx                ; số cần convert
    mov     ebx, numstr             ; pointer tới buffer
    add     ebx, 9                  ; bắt đầu từ cuối buffer
    mov     byte [ebx], 0xA         ; thêm newline
    dec     ebx
    
convert_loop:
    xor     edx, edx                ; clear edx cho phép chia
    mov     ecx, 10                 ; chia cho 10
    div     ecx                     ; eax = thương, edx = dư
    add     dl, '0'                 ; convert sang ASCII
    mov     [ebx], dl               ; lưu vào buffer
    dec     ebx                     ; di chuyển pointer
    cmp     eax, 0                  ; kiểm tra thương = 0
    jne     convert_loop            ; tiếp tục nếu chưa xong

    ; In kết quả
    inc     ebx                     ; điều chỉnh pointer
    mov     eax, 4                  ; sys_write
    mov     ecx, ebx                ; pointer tới chuỗi số
    mov     edx, numstr             ; tính độ dài
    sub     edx, ebx                ; 
    add     edx, 2                  ; cộng thêm newline
    mov     ebx, 1                  ; stdout
    int     0x80                    ; system call

    ; Thoát chương trình
    mov     eax, 1                  ; sys_exit
    xor     ebx, ebx                ; return 0
    int     0x80                    ; system call