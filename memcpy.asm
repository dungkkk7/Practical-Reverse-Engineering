
section .data 
    src db "hello", 0          ; Chuỗi nguồn
    des times 6 db 0           ; Chuỗi đích (đủ lớn để chứa chuỗi nguồn)
    src_len equ 6              ; Độ dài chuỗi nguồn (bao gồm ký tự null)

section .text
    global _start

_start:
    mov esi, src               ; Địa chỉ nguồn
    mov edi, des               ; Địa chỉ đích
    mov ecx, src_len           ; Độ dài chuỗi nguồn

    rep movsb                  ; Sao chép chuỗi từ [ESI] sang [EDI]

    ; Kết thúc chương trình
    mov eax, 1                 ; sys_exit
    xor ebx, ebx               ; exit code 0
    int 0x80

; ### Giải thích:
; 1. **`rep movsb`**:
;    - Lệnh này sao chép `ECX` byte từ địa chỉ nguồn `[ESI]` sang địa chỉ đích `[EDI]`.
;    - Sau mỗi lần sao chép, `ESI` và `EDI` tự động tăng lên (nếu cờ hướng `DF` được xóa bằng `cld`).

; 2. **`src_len`**:
;    - Bao gồm cả ký tự null (`0`) để đảm bảo chuỗi được sao chép đầy đủ.

; 3. **`cld` (nếu cần)**:
;    - Nếu trước đó cờ hướng (`DF`) bị đặt, bạn cần thêm lệnh `cld` để đảm bảo `ESI` và `EDI` tăng lên thay vì giảm.

; ### Kết quả:
; - Chuỗi `"hello"` sẽ được sao chép từ `src` sang `des`, bao gồm cả ký tự null (`0`).
; - Bạn có thể kiểm tra kết quả bằng cách in chuỗi `des` sau khi thực thi.