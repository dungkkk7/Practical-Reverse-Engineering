
section .text
    global _strset
; char *strset(char *str, int c); // Hoặc _strset
_strset: 
    push ebp; 
    mov ebp , esp
    mov al, [ebp + 8] ; Lấy giá trị cần set từ tham số đầu tiên
    mov edi, [ebp + 12] ; Lấy địa chỉ chuỗi từ tham số thứ hai
    xor ecx , ecx ; Đặt ECX = 0 (chỉ số ký tự) 

_set_Loop: 
    cmp al , 0 ; Kiểm tra ký tự null (kết thúc chuỗi)
    je _done ; Nếu bằng 0, nhảy đến nhãn done
    mov [edi + ecx] , al ; Gán ký tự vào chuỗi
    inc ecx ; Tăng chỉ số ký tự
    jmp _set_Loop ; Lặp lại vòng lặp



_done: 
     pop ebp ; Khôi phục giá trị EBP cũ
     ret ; Kết thúc hàm 