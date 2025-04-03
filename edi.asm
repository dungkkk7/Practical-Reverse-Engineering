section .data 
   src db "hello" , 0 
   des times 5 db 0 
   src_len equ 5 
section .text
    global_start

_start 
    mov esi , src ; 
    mov edi , des ; 
    mov ecx , src_len ; 
    
    ; ld: Xóa cờ hướng, đảm bảo ESI và EDI tăng lên trong quá trình sao chép.
    cld; 
    rep movsb  ; Lặp lại lệnh movsb (move string byte) ECX lần. Lệnh movsb sao chép một byte từ địa chỉ được trỏ bởi ESI đến địa chỉ được trỏ bởi EDI, sau đó tăng ESI và EDI.
_exit 
    mov eax ,1 
    xor ebx , ebx ;  Thoát khỏi chương trình với mã thoát 0.
    int 0x80

; Liên kết: Sử dụng trình liên kết LD để tạo tệp thực thi:

; Bash

; ld -m elf_i386 copy_string.o -o copy_string
; Chạy: Chạy tệp thực thi:

; Bash

; ./copy_string