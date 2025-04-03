; Chương trình đơn giản để in mảng
section .data
    ; Mảng các số nguyên
    numbers dd 10, 20, 30, 40, 50
    array_size equ 5
    
    ; Ký tự xuống dòng
    newline db 10

section .bss
    buffer resb 12     ; Buffer để lưu số dưới dạng chuỗi

section .text
    global _start

_start:
    xor ecx, ecx       ; Khởi tạo ECX = 0 (index)

print_loop:
    ; Kiểm tra nếu đã in hết các phần tử
    cmp ecx, array_size
    jge exit_program
    
    ; Lấy phần tử hiện tại
    mov eax, [numbers + ecx*4]
    
    ; Chuyển số thành chuỗi
    push ecx
    call int_to_string
    pop ecx
    
    ; In số
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, buffer     ; chuỗi cần in
    mov edx, eax        ; độ dài chuỗi (từ int_to_string)
    int 0x80
    
    ; In xuống dòng
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, newline    ; ký tự xuống dòng
    mov edx, 1          ; độ dài 1 byte
    int 0x80
    
    ; Tăng index và lặp lại
    inc ecx
    jmp print_loop

exit_program:
    ; Thoát chương trình
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; exit code 0
    int 0x80

; Hàm đơn giản chuyển số trong EAX thành chuỗi
; Đầu ra: buffer chứa chuỗi, EAX chứa độ dài chuỗi
int_to_string:
    push ebx
    push ecx
    push edx
    push edi
    
    mov edi, buffer     ; Trỏ đến buffer
    mov ebx, 10         ; Cơ số 10
    xor ecx, ecx        ; Đếm số chữ số
    
    ; Xử lý trường hợp đặc biệt nếu số = 0
    test eax, eax
    jnz not_zero
    mov byte [edi], '0'
    mov eax, 1          ; Độ dài = 1
    jmp end_conversion
    
not_zero:
    ; Lưu stack hiện tại
    mov edx, edi
    
    ; Chuyển đổi từng chữ số
digit_loop:
    xor edx, edx        ; Xóa edx cho phép chia
    div ebx             ; eax = eax / 10, edx = eax % 10
    add dl, '0'         ; Chuyển thành ký tự ASCII
    push edx            ; Lưu chữ số vào stack
    inc ecx             ; Tăng số đếm chữ số
    test eax, eax       ; Kiểm tra nếu eax = 0
    jnz digit_loop
    
    ; Pop các chữ số từ stack vào buffer (theo thứ tự ngược lại)
    mov eax, ecx        ; Lưu độ dài vào eax
reverse_loop:
    pop edx
    mov [edi], dl
    inc edi
    loop reverse_loop
    
end_conversion:
    ; Thêm null terminator
    mov byte [edi], 0
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret