; --- strcmp_64.asm ---
; Assembler: NASM (Intel syntax)
; Target: x86 amd 64 Linux (cdecl)

section .text
    global _start 

_start: 
    push ebp
    mov ebp , esp
    mov esi , [ebp + 8] ; Địa chỉ chuỗi đầu tiên
    mov edi  , [ebp + 12 ] ; Địa chỉ chuỗi thứ hai
    xor ecx , ecx ; Đặt ECX = 0 (chỉ số ký tự)

_compare_loop: 
    mov al, [esi + ecx] ; Lấy ký tự từ chuỗi đầu tiên
    mov ah, [edi + ecx] ; Lấy ký tự từ chuỗi thứ hai
    cmp al, ah ; So sánh hai ký tự
    jne _not_equal ; Nếu khác nhau, nhảy đến nhãn not_equal
    cmp al, 0 ; Kiểm tra ký tự null (kết thúc chuỗi)
    je _equal ; Nếu bằng 0, nhảy đến nhãn equal
    inc ecx ; Tăng chỉ số ký tự
    jmp _compare_loop ; Lặp lại vòng lặp

_equal : 
    mov eax , 0 ; Trả về 0 (hai chuỗi bằng nhau)
    jmp _exit
_not_equal: 
    mov eax , 1 ; Trả về 1 (hai chuỗi khác nhau)
_exit:
    pop ebp ; Khôi phục giá trị EBP cũ
    ret ; Kết thúc hàm
    
