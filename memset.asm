; --- memset_32_basic.asm ---
; Assembler: NASM (Intel syntax)
; Target: 32-bit Linux/Windows (cdecl)

section .text 
    global _start

_start: 
    push ebp; 
    mov ebp , esp ; Lưu giá trị EBP cũ
    mov al, [ebp - 8]
    mov ecx, [ebp - 12] ; Lấy số byte cần set
    mov edi , [ebp - 16] ; Địa chỉ bắt đầu
    cld ; Xóa cờ DF để tăng EDI sau mỗi lần sao chép
    rep stosb ; Sao chép byte từ AL vào địa chỉ EDI
    pop ebp ; Khôi phục giá trị EBP cũ
    ret ; Kết thúc hàm

; ### Giải thích:
; 1. **`cld`**: Đảm bảo `EDI` tăng lên sau mỗi lần ghi.
; 2. **`rep stosb`**: Lặp lại lệnh `stosb` cho đến khi `ECX = 0`.

; ### Ứng dụng:
; - `STOS` thường được dùng để khởi tạo hoặc điền một vùng nhớ với một giá trị cố định, tương tự như hàm `memset` trong C
; Lệnh `STOS` (Store String) trong assembly x86 được sử dụng để ghi giá trị từ thanh ghi `AL`, `AX`, hoặc `EAX` vào địa chỉ bộ nhớ được trỏ bởi thanh ghi `EDI`. Sau khi ghi, `EDI` sẽ tự động tăng hoặc giảm tùy thuộc vào cờ hướng (`DF`) trong thanh ghi `EFLAGS`.

; ### Các biến thể của `STOS`:
; 1. **`STOSB`**: Ghi 1 byte từ `AL` vào `[EDI]`.
; 2. **`STOSW`**: Ghi 2 byte từ `AX` vào `[EDI]`.
; 3. **`STOSD`**: Ghi 4 byte từ `EAX` vào `[EDI]`.

; ### Cách hoạt động:
; - **Nguồn**: Giá trị trong `AL`, `AX`, hoặc `EAX`.
; - **Đích**: Địa chỉ bộ nhớ `[EDI]`.
; - **Cập nhật `EDI`**:
;   - Nếu `DF = 0` (cờ hướng bị xóa bằng `CLD`): `EDI` tăng lên (hướng tiến).
;   - Nếu `DF = 1` (cờ hướng được đặt bằng `STD`): `EDI` giảm xuống (hướng lùi).



.