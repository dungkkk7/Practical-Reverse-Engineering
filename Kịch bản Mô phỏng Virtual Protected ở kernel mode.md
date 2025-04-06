**Bối cảnh:**

* Máy tính của bạn có **RAM vật lý** (ví dụ: 8GB). Đây là phần cứng thực tế.
* Bạn chạy một chương trình, ví dụ như **Notepad (Tiến trình A)**.
* Hệ điều hành (Windows Kernel) đang chạy.

**Bước 1: Notepad (Tiến trình A) yêu cầu bộ nhớ**

1.  Bạn gõ chữ vào Notepad. Notepad cần một vùng nhớ để lưu trữ văn bản này.
2.  Notepad yêu cầu hệ điều hành cấp cho nó một vùng nhớ, ví dụ 4KB.
3.  Hệ điều hành tìm một **Trang Vật Lý (Physical Page)** còn trống trong RAM, giả sử trang này có **Địa chỉ Vật Lý** là `0x78900000`.
4.  Hệ điều hành cập nhật **Bảng Trang (Page Table)** của riêng **Tiến trình A (Notepad)**. Nó tạo một mục ánh xạ, nói rằng:
    * **Địa chỉ Ảo `0x12340000`** (trong không gian ảo của Notepad) sẽ tương ứng với **Địa chỉ Vật Lý `0x78900000`**.
5.  Hệ điều hành trả về **Địa chỉ Ảo `0x12340000`** cho Notepad.
6.  **Quan trọng:** Notepad chỉ biết và làm việc với **Địa chỉ Ảo `0x12340000`**. Nó không hề biết dữ liệu thực sự nằm ở địa chỉ vật lý `0x78900000` trên thanh RAM nào. Khi Notepad đọc/ghi vào `0x12340000`, CPU (MMU) sẽ tự động tra bảng trang của Notepad và truy cập vào `0x78900000` trên RAM.

**Bước 2: Một Driver cần truy cập dữ liệu của Notepad (Ví dụ: Driver Antivirus)**

Bây giờ, giả sử có một Driver Antivirus (chạy trong Kernel) cần quét nội dung mà bạn vừa gõ vào Notepad để kiểm tra virus.

1.  Driver này biết rằng Notepad đang dùng vùng đệm tại **Địa chỉ Ảo `0x12340000`** (có thể thông qua các cơ chế khác của HĐH).
2.  Driver không thể truy cập trực tiếp vào `0x12340000` của Notepad một cách an toàn vì đó là không gian địa chỉ của tiến trình khác. Driver cần một cách để "nhìn thấy" dữ liệu đó từ không gian Kernel.
3.  Driver sử dụng `MDL`:
    * Gọi `IoAllocateMdl` với **Địa chỉ Ảo `0x12340000`** của Notepad và kích thước 4KB.
    * Gọi `MmProbeAndLockPages` với `MDL` vừa tạo.
        * Hệ thống kiểm tra xem Notepad có quyền truy cập `0x12340000` không.
        * Hệ thống tra cứu Bảng Trang của Notepad, thấy rằng `0x12340000` ánh xạ tới **Địa chỉ Vật Lý `0x78900000`**.
        * Hệ thống ghi thông tin về trang vật lý `0x78900000` này vào cấu trúc `MDL`.
        * Hệ thống **khóa (lock)** trang vật lý `0x78900000` lại, đảm bảo nó không bị đẩy ra đĩa (swap) hoặc bị dùng cho việc khác trong lúc driver đang xử lý.
4.  Bây giờ, `MDL` chứa thông tin quan trọng: "Vùng nhớ ảo `0x12340000` của Notepad hiện đang nằm tại trang vật lý `0x78900000` và trang này đã bị khóa."
5.  Driver gọi `MmMapLockedPagesSpecifyCache` với `MDL`.
    * Hệ điều hành tìm một **Địa chỉ Ảo** còn trống trong **không gian Kernel**, ví dụ: `0xFFFFAB0011220000`.
    * Hệ điều hành cập nhật **Bảng Trang của Kernel**. Nó tạo một mục ánh xạ mới, nói rằng:
        * **Địa chỉ Ảo Kernel `0xFFFFAB0011220000`** sẽ tương ứng với **Địa chỉ Vật Lý `0x78900000`**.
    * Hàm này trả về **Địa chỉ Ảo Kernel `0xFFFFAB0011220000`** cho driver.
6.  **Kết quả:** Bây giờ Driver Antivirus có thể đọc (hoặc ghi, nếu yêu cầu quyền ghi) dữ liệu tại **Địa chỉ Ảo Kernel `0xFFFFAB0011220000`**. Khi driver làm vậy, CPU (MMU) sẽ tra bảng trang của Kernel, dịch ra **Địa chỉ Vật Lý `0x78900000`** và truy cập vào đúng vùng RAM chứa dữ liệu của Notepad.

**Tóm tắt ví dụ:**

* Notepad thấy dữ liệu tại **Địa chỉ Ảo `0x12340000`** (không gian User).
* Driver Antivirus thấy *cùng* dữ liệu đó tại **Địa chỉ Ảo `0xFFFFAB0011220000`** (không gian Kernel).
* Cả hai địa chỉ ảo này, dù khác nhau và thuộc các không gian khác nhau, cuối cùng đều được MMU dịch thành cùng một **Địa chỉ Vật Lý `0x78900000`** trên RAM.
* `MDL` chính là cấu trúc dữ liệu trung gian giúp driver tìm ra địa chỉ vật lý (`0x78900000`) từ địa chỉ ảo của Notepad (`0x12340000`), khóa trang vật lý đó lại, và tạo ra một địa chỉ ảo mới (`0xFFFFAB0011220000`) trong Kernel để truy cập an toàn vào trang vật lý đó.
