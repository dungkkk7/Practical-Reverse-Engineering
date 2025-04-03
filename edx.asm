; Trong phép nhân 32-bit, khi nhân hai số lớn, kết quả có thể vượt quá 32-bit.
; Khi đó, EAX chứa phần thấp của kết quả và EDX chứa phần cao.
section .text
    global _start
    
_start:
    mov eax , 500000 ; 
    mov ecx , 300000 ; 
    imul ecx  ; nhân eax với ecx nhưng vif kết quả vượt quá 32 bit nên. 
              ; edx sẽ giữ phần cao của kết quả và eax sẽ giữ phần thấp 
            
    
    mov eax ,1 ; sys_exit 
    xor ebx , ebx 
    int 0x80




;; ví dụ khác 
section .text
    global _start
    
_start:
    MOV EAX, 100      ; EAX = 100 (số bị chia)
    XOR EDX, EDX      ; Xóa EDX (tránh lỗi do giá trị cũ)
    MOV ECX, 7        ; ECX = 7 (số chia)
    DIV ECX           ; Thực hiện phép chia: EAX = 100 / 7, EDX = 100 % 7

    ; Bây giờ:
    ; EAX = 14 (thương số)
    ; EDX = 2 (phần dư)

    ; Kết thúc chương trình
    MOV EAX, 1        ; syscall: exit
    XOR EBX, EBX
    INT 0x80


;; khác 
MOV DX, 0x60      ; Địa chỉ cổng 0x60
MOV AL, 0xAB      ; Giá trị gửi đi
OUT DX, AL        ; Gửi giá trị 0xAB đến cổng 0x60