section .text
    global_start

_start: 
    ; gọi hàm sum(10,20)
    push 20; 
    push 10; 
    call sum; 
    add esp, 8; dọn dẹp stack 2 int 4 byte mỗi cái 

_end: 
    mov eax ,1; 
    xor ebx , ebx; 
    int 0x80; 

sum: 
    push ebp; lưu lại giá trị ebp của hàm trước 
    mov ebp, esp ; đặp esp làm stack frame hiện tại 

    mov eax , [ebp + 8]  ; truy cập tham số thứ 1 , truy cập tham số sẽ them + offset 
                         ; đối với biến trong hàm thì - offset 
    add eax , [ebp + 12] ; cộng eax với tham số thứ 2 lưu vào eax

    pop ebp ; khôi phục ebp của hàm trc 
    ret ;kết  thúc hàm sum trả về eax 


; Địa chỉ Stack	Giá trị	Mô tả
; ESP+12 b = 20	Tham số thứ 2
; ESP+8	a = 10	Tham số thứ 1
; ESP+4	Return Address	Địa chỉ trả về sau khi RET
; ESP (EBP)	EBP cũ	Lưu giá trị EBP trước đó