section .data
    str db "Hello, World!", 0   ; Chuỗi cần tìm kiếm
    c db 'o'                    ; Ký tự cần tìm
    found_msg db "Found at: ", 0
    found_len equ $ - found_msg
    not_found_msg db "Not found", 0
    not_found_len equ $ - not_found_msg
    newline db 10, 0

section .bss
    result resb 11               ; Buffer để lưu kết quả (đủ lớn để chứa số 32-bit)

section .text
    global _start

_start:
    mov esi, str             ; Địa chỉ chuỗi
    mov al, c                ; Ký tự cần tìm
    call strchr              ; Gọi hàm strchr
    ; Kết quả trả về trong EAX
    cmp eax, -1             ; Kiểm tra xem có tìm thấy không
    je print_not_found       ; Nếu không tìm thấy, nhảy đến nhãn not_found

    ; In thông báo "Found at: "
    mov eax, 4               ; sys_write
    mov ebx, 1               ; stdout
    mov ecx, found_msg
    mov edx, found_len
    int 0x80

    ; Chuyển địa chỉ tìm thấy thành chuỗi và in ra
    push eax                 ; Lưu địa chỉ tìm thấy vào stack
    push esi                 ; Lưu địa chỉ đầu chuỗi vào stack
    call convert_to_string    ; Gọi hàm chuyển đổi
    add esp, 8               ; Dọn dẹp stack

    ; In chuỗi kết quả
    mov eax, 4               ; sys_write
    mov ebx, 1               ; stdout
    mov ecx, result
    mov edx, 11              ; Độ dài chuỗi kết quả
    int 0x80

    jmp exit

print_not_found:
    mov eax, 4               ; sys_write
    mov ebx, 1               ; stdout
    mov ecx, not_found_msg
    mov edx, not_found_len
    int 0x80

exit:
    mov eax, 1               ; sys_exit
    xor ebx, ebx             ; exit code 0
    int 0x80

strchr:
    push ebp                 ; Lưu EBP cũ
    mov ebp, esp             ; Thiết lập EBP cho hàm
    xor ecx, ecx             ; Đặt ECX = 0 (chỉ số ký tự)
    mov edi, esi             ; Đặt EDI trỏ đến đầu chuỗi
    mov al, byte [ebp + 8]    ; Lấy ký tự cần tìm từ stack
    cld                      ; Clear direction flag (tăng EDI)
loop_strchr:
    cmp byte [edi], al       ; So sánh ký tự hiện tại với ký tự cần tìm
    je found_char            ; Nếu tìm thấy, nhảy đến found_char
    cmp byte [edi], 0        ; Kiểm tra ký tự null (kết thúc chuỗi)
    je not_found             ; Nếu gặp ký tự null, nhảy đến not_found
    inc edi                  ; Tăng EDI để kiểm tra ký tự tiếp theo
    jmp loop_strchr

found_char:
    mov eax, edi             ; Lưu địa chỉ tìm thấy vào EAX
    pop ebp                  ; Khôi phục EBP cũ
    ret                      ; Trả về từ hàm

not_found:
    mov eax, -1              ; Trả về -1 nếu không tìm thấy
    pop ebp                  ; Khôi phục EBP cũ
    ret                      ; Trả về từ hàm

convert_to_string:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]       ; Địa chỉ tìm thấy
    sub eax , [ebp + 12]       ; Tính offset
    mov ebx, result          ; Buffer để lưu kết quả
    add ebx, 10              ; Bắt đầu từ cuối buffer
    mov byte [ebx], 10       ; Thêm newline
    dec ebx

convert_loop:
    xor edx, edx             ; Clear EDX cho phép chia
    mov ecx, 10              ; Chia cho 10
    div ecx                  ; EAX = thương, EDX = dư
    add dl, '0'              ; Convert sang ASCII
    mov [ebx], dl            ; Lưu vào buffer
    dec ebx                  ; Di chuyển pointer
    cmp eax, 0               ; Kiểm tra thương = 0
    jne convert_loop         ; Tiếp tục nếu chưa xong

    mov eax, result          ; Trả về địa chỉ chuỗi kết quả
    pop ebp
    ret