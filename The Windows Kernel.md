# The Windows Kernel 

phần này thảo luận về các nguyên tắc và kỹ thuật cần thiết để phân tích mã driver kernel-mode , ví dụ như rootkit, trên nền tảng Windows. Bởi vì các driver tương tác với Hệ điều hành (OS) thông qua các giao diện được định nghĩa rõ ràng, công việc phân tích có thể được chia nhỏ thành các mục tiêu tổng quát sau:

* Hiểu cách các thành phần cốt lõi của Hệ điều hành được triển khai.
* Hiểu cấu trúc của một driver.
* Hiểu các giao diện người dùng-driver và driver-OS, cũng như cách Windows triển khai chúng.
* Hiểu cách một số cấu trúc phần mềm nhất định của driver được thể hiện dưới dạng mã nhị phân.
* Áp dụng một cách có hệ thống kiến thức từ các bước trên vào quy trình dịch ngược mã (reverse engineering) tổng quát.

Nếu quy trình dịch ngược driver Windows có thể được mô hình hóa như một công việc riêng biệt, thì 90% công việc là hiểu cách Windows hoạt động và 10% là hiểu mã assembly. Do đó, phần này được viết như một phần giới thiệu về nhân Windows (Windows kernel) dành cho những người làm công việc dịch ngược mã. phần bắt đầu bằng việc thảo luận về các giao diện người dùng-nhân (user-kernel) và cách chúng được triển khai. Tiếp theo, phần thảo luận về danh sách liên kết (linked lists) và cách chúng được sử dụng trong Windows. Sau đó, phần giải thích các khái niệm như luồng (threads), tiến trình (processes), bộ nhớ (memory), ngắt (interrupts), và cách chúng được sử dụng trong kernel và driver. Kế đến, phần đi sâu vào kiến trúc của một driver kernel mode và driver-kernel programming interface . phần kết thúc bằng việc áp dụng các khái niệm này vào việc dịch ngược mã của một rootkit.

Trừ khi được chỉ định khác, mọi ví dụ trong phần này đều được lấy từ Windows 8 RTM.

## Windows Fundamentals
 Chúng ta sẽ bắt đầu với khái niêm windows kernel , bao gồm các cấu trúc dữ liệu cơ bản and kernel objects liến quan đến lập trình driver and reverse engeneering. 

### Memory Layout

Giống như các hệ điều hành khác , Windows chia Virtual address thành 2 phần : 
- Kernel space 
- User space

Trên kiến trúc x86 và ARM: 2GB vùng địa chỉ cao (upper 2GB) được dành riêng cho kernel và 2GB vùng địa chỉ thấp (bottom 2GB) dành cho các tiến trình người dùng. Do đó, các địa chỉ ảo từ 0 đến 0x7fffffff thuộc về User space , còn từ 0x80000000 trở lên thuộc về Kernel space.

Trên kiến trúc x64: Khái niệm tương tự cũng được áp dụng, ngoại trừ việc User space là từ 0 đến 0x000007ffffffffff và không gian nhân là từ 0xffff080000000000 trở lên.

Hình 3.1 minh họa bố cục tổng quát này trên x86 và x64.

![alt text](image-5.png)


Không gian bộ nhớ nhân phần lớn là giống nhau giữa tất cả các tiến trình. Tuy nhiên, các tiến trình đang chạy chỉ có quyền truy cập vào không gian địa chỉ người dùng của chính chúng; trong khi mã chạy ở kernel-mode có thể truy cập cả hai - Kernel space và  User space . (Lưu ý: Một số dải địa chỉ trong Kernel space , ví dụ như các vùng thuộc session space và hyper space, có thể khác nhau giữa các tiến trình.)

Đây là một sự thật quan trọng cần ghi nhớ vì chúng ta sẽ quay lại vấn đề này sau khi thảo luận về ngữ cảnh thực thi (execution context). Các trang bộ nhớ (pages) thuộc kernel mode và user mode được phân biệt bởi một bit đặc biệt trong mục nhập của bảng trang (page table entry) tương ứng với trang đó.


Khi một luồng (thread) trong một tiến trình (process) được lập lịch để thực thi, Hệ điều hành (OS) sẽ thay đổi một thanh ghi đặc thù của bộ xử lý để trỏ đến thư mục trang (page directory) của chính tiến trình đó. Điều này là để đảm bảo tất cả các phép dịch địa chỉ ảo-sang-vật lý là dành riêng cho tiến trình đó, chứ không phải cho các tiến trình khác. Đây chính là cách Hệ điều hành có thể chạy nhiều tiến trình đồng thời và mỗi tiến trình lại có "ảo giác" rằng nó sở hữu toàn bộ không gian địa chỉ chế độ người dùng.

Trên các kiến trúc x86 và x64, thanh ghi cơ sở của page directory là CR3.
Trên kiến trúc ARM, đó là thanh ghi cơ sở của bảng dịch (translation table base register - TTBR).

Ghi chú:

Có thể thay đổi hành vi phân chia bộ nhớ mặc định (2GB/2GB trên hệ 32-bit) bằng cách chỉ định tùy chọn /3GB trong các tùy chọn khởi động (boot options). Với tùy chọn /3GB, không gian địa chỉ người dùng sẽ tăng lên 3GB và 1GB còn lại được dành cho nhân.
Các dải địa chỉ của người dùng/nhân được lưu trữ trong hai biểu tượng (symbols) trong nhân: MmSystemRangeStart (địa chỉ bắt đầu của không gian nhân) và MmHighestUserAddress (địa chỉ cao nhất của không gian người dùng). Các biểu tượng này có thể được xem bằng một trình gỡ lỗi nhân (kernel debugger).
Bạn có thể nhận thấy rằng có một khoảng trống 64KB giữa không gian người dùng và không gian nhân trên x86/ARM. Vùng này, thường được gọi là vùng không truy cập (no-access region), tồn tại để đảm bảo nhân không vô tình vượt qua ranh giới địa chỉ và làm hỏng bộ nhớ ở chế độ người dùng.

Trên x64, người đọc tinh ý có thể nhận thấy rằng địa chỉ 0xffff0800‘00000000 (được đề cập ở phần trước là điểm bắt đầu của Kernel space) là một địa chỉ không chuẩn tắc (non-canonical address) và do đó hệ điều hành không thể sử dụng được. Địa chỉ này thực sự chỉ được sử dụng như một dấu phân tách giữa không gian người dùng và không gian nhân. Địa chỉ thực sự có thể sử dụng đầu tiên trong không gian nhân bắt đầu từ 0xffff8000‘00000000.

## Processor Initialization 

Khi nhân (kernel) khởi động, nó thực hiện một số khởi tạo cơ bản cho mỗi bộ xử lý (processor/CPU). Hầu hết các chi tiết khởi tạo không quá quan trọng đối với công việc dịch ngược mã (reverse engineering) hàng ngày, nhưng việc biết một vài cấu trúc cốt lõi là cần thiết.

Vùng Kiểm soát Bộ xử lý (Processor Control Region - PCR) là một cấu trúc dành riêng cho mỗi bộ xử lý, lưu trữ thông tin và trạng thái CPU quan trọng. Ví dụ, trên x86, nó chứa địa chỉ cơ sở của Bảng Mô tả Ngắt (Interrupt Descriptor Table - IDT) và mức yêu cầu ngắt hiện tại (Interrupt Request Level - IRQL). Bên trong PCR là một cấu trúc dữ liệu khác gọi là Khối Kiểm soát Vùng Bộ xử lý (Processor Region Control Block - PRCB).

PRCB cũng là một cấu trúc cho mỗi bộ xử lý, chứa thông tin chi tiết về bộ xử lý đó—ví dụ: loại CPU, model, tốc độ, luồng (thread) hiện tại đang chạy, luồng kế tiếp sẽ chạy, hàng đợi các Lời gọi Thủ tục Trì hoãn (Deferred Procedure Calls - DPCs) cần chạy, vân vân. 

Giống như PCR, cấu trúc PRCB không được Microsoft tài liệu hóa chính thức (undocumented), nhưng bạn vẫn có thể xem định nghĩa của nó bằng trình gỡ lỗi nhân (kernel debugger) thông qua các lệnh như dt nt!_KPCR và dt nt!_KPRCB.

__PCR x86/64__

```asm

    kd> dt nt!_KPCR
   +0x000 NtTib            : _NT_TIB
   +0x000 GdtBase          : Ptr64 _KGDTENTRY64
   +0x008 TssBase          : Ptr64 _KTSS64
   +0x010 UserRsp          : Uint8B
   +0x018 Self             : Ptr64 _KPCR
   +0x020 CurrentPrcb      : Ptr64 _KPRCB
...
   +0x180 Prcb             : _KPRCB
``` 

__PRCB x86/64__

```
   kd> dt nt!_KPRCB
   +0x000 MxCsr            : Uint4B
   +0x004 LegacyNumber     : UChar
   +0x005 ReservedMustBeZero : UChar
   +0x006 InterruptRequest : UChar
   +0x007 IdleHalt         : UChar
   +0x008 CurrentThread    : Ptr64 _KTHREAD
   +0x010 NextThread       : Ptr64 _KTHREAD
   +0x018 IdleThread       : Ptr64 _KTHREAD
...
   +0x040 ProcessorState   : _KPROCESSOR_STATE
   +0x5f0 CpuType          : Char
   +0x5f1 CpuID            : Char
   +0x5f2 CpuStep          : Uint2B
   +0x5f2 CpuStepping      : UChar
   +0x5f3 CpuModel         : UChar
   +0x5f4 MHz              : Uint4B
...
   +0x2d80 DpcData          : [2] _KDPC_DATA
   +0x2dc0 DpcStack         : Ptr64 Void
   +0x2dc8 MaximumDpcQueueDepth : Int4B
...
```

__PCR ARM__

```
    kd> dt nt!_KPCR
   +0x000 NtTib            : _NT_TIB
   +0x000 TibPad0          : [2] Uint4B
   +0x008 Spare1           : Ptr32 Void
   +0x00c Self             : Ptr32 _KPCR
   +0x010 CurrentPrcb      : Ptr32 _KPRCB
...
```

__PRCB ARM__
```
    kd> dt nt!_KPCR
   +0x000 NtTib            : _NT_TIB
   +0x000 TibPad0          : [2] Uint4B
   +0x008 Spare1           : Ptr32 Void
   +0x00c Self             : Ptr32 _KPCR
   +0x010 CurrentPrcb      : Ptr32 _KPRCB
...
   kd> dt nt!_KPRCB
   +0x000 LegacyNumber     : UChar
   +0x001 ReservedMustBeZero : UChar
   +0x002 IdleHalt         : UChar
   +0x004 CurrentThread    : Ptr32 _KTHREAD
   +0x008 NextThread       : Ptr32 _KTHREAD
   +0x00c IdleThread       : Ptr32 _KTHREAD
...
   +0x020 ProcessorState   : _KPROCESSOR_STATE
   +0x3c0 ProcessorModel   : Uint2B
   +0x3c2 ProcessorRevision : Uint2B
   +0x3c4 MHz              : Uint4B
...
   +0x690 DpcData          : [2] _KDPC_DATA
   +0x6b8 DpcStack         : Ptr32 Void
...
   +0x900 InterruptCount   : Uint4B
   +0x904 KernelTime       : Uint4B
   +0x908 UserTime         : Uint4B
   +0x90c DpcTime          : Uint4B
   +0x910 InterruptTime    : Uint4B

```


Truy cập PCR/PRCB:

PCR của bộ xử lý hiện tại luôn có thể được truy cập từ chế độ nhân thông qua các thanh ghi đặc biệt. Nó được lưu trữ trong:

- Thanh ghi đoạn FS (trên x86)
- Thanh ghi đoạn GS (trên x64)
- Một trong các thanh ghi của bộ đồng xử lý hệ thống (system coprocessor registers) (trên ARM)


Ví dụ, nhân Windows cung cấp hai hàm để lấy con trỏ đến cấu trúc EPROCESS (đại diện cho tiến trình) và ETHREAD (đại diện cho luồng) hiện tại: PsGetCurrentProcess và PsGetCurrentThread. Các hàm này hoạt động bằng cách truy vấn thông tin từ PCR/PRCB.


```asm 

    PsGetCurrentThread proc near      ; Bắt đầu định nghĩa hàm PsGetCurrentThread
        mov     rax, gs:188h          ; Di chuyển dữ liệu từ địa chỉ gs:188h vào thanh ghi rax
                                    ; Chú thích:
                                    ; gs:[0] là địa chỉ cơ sở của PCR (Processor Control Region)
                                    ; offset 0x180 trong PCR là bắt đầu của PRCB (Processor Region Control Block)
                                    ; offset 0x8 trong PRCB là trường CurrentThread (con trỏ đến ETHREAD hiện tại)
        retn                          ; Trở về từ hàm
    PsGetCurrentThread endp           ; Kết thúc định nghĩa hàm

... 
    PsGetCurrentProcess proc near   ; Bắt đầu định nghĩa hàm PsGetCurrentProcess
        mov     rax, gs:188h        ; Lấy con trỏ ETHREAD của luồng hiện tại (giống hệt PsGetCurrentThread)
        mov     rax, [rax+0B8h]     ; Đọc giá trị tại địa chỉ (rax + 0B8h) và lưu vào rax
                                    ; Chú thích: offset 0xB8 trong ETHREAD trỏ đến tiến trình liên quan
                                    ; (thực tế là ETHREAD.ApcState.Process)
        retn                        ;Trở về từ hàm
    PsGetCurrentProcess endp        ; Kết thúc định nghĩa hàm

```

Điểm cốt lõi: Cả hai hàm đều dựa vào việc thanh ghi GS (trên x64) cung cấp lối vào nhanh chóng đến thông tin về bộ xử lý và luồng hiện tại thông qua các cấu trúc PCR và PRCB, sử dụng các offset cố định (nhưng có thể thay đổi giữa các phiên bản Windows) để truy cập các trường dữ liệu cần thiết.

## System Call 

Một hệ điều hành quản lý các tài nguyên phần cứng và cung cấp các giao diện thông qua đó người dùng có thể yêu cầu chúng. Giao diện được sử dụng phổ biến nhất là **lời gọi hệ thống (system call)**. Một lời gọi hệ thống điển hình là một hàm trong nhân (kernel) phục vụ các yêu cầu Nhập/Xuất (I/O) từ người dùng; nó được triển khai trong nhân vì chỉ có mã với đặc quyền cao mới có thể quản lý các tài nguyên như vậy.

Ví dụ, khi một trình soạn thảo văn bản lưu một tệp tin vào đĩa, trước tiên nó cần yêu cầu một file handle  từ kernel , ghi dữ liệu vào tệp, và sau đó xác nhận (commit) nội dung tệp vào đĩa cứng; Hệ điều hành (OS) cung cấp các lời gọi hệ thống để có được file handle và ghi các byte vào đó. Mặc dù đây có vẻ là các thao tác đơn giản, các lời gọi hệ thống phải thực hiện nhiều tác vụ quan trọng trong nhân để phục vụ yêu cầu. 

Ví dụ, để lấy được file handle, nó phải tương tác với hệ thống tệp (file system) (để xác định đường dẫn có hợp lệ hay không) và sau đó yêu cầu trình quản lý bảo mật (security manager) xác định xem người dùng có đủ quyền để truy cập tệp hay không; để ghi các byte vào tệp, nhân cần phải tìm ra ổ đĩa cứng (volume) nào chứa tệp đó, gửi yêu cầu đến ổ đĩa đó, và đóng gói dữ liệu thành một cấu trúc mà bộ điều khiển đĩa cứng bên dưới có thể hiểu được. Tất cả các thao tác này được thực hiện hoàn toàn minh bạch đối với người dùng.

lưu ý :Handle là một tham chiếu trừu tượng, một token hoặc một mã định danh. Nó không phải là con trỏ trực tiếp đến dữ liệu mà là một giá trị đại diện cho một đối tượng hoặc tài nguyên nào đó.  Handle là một cơ chế nền tảng và mạnh mẽ trong các hệ điều hành hiện đại và lập trình hệ thống. Nó cung cấp một cách thức linh hoạt, an toàn và hiệu quả để các ứng dụng tương tác với các tài nguyên do hệ thống quản lý, đồng thời che giấu đi sự phức tạp của việc quản lý đó. Hiểu rõ về handle là rất quan trọng khi làm việc với các API hệ thống.

Các chi tiết triển khai System Call của Windows chính thức không được tài liệu hóa (undocumented), vì vậy việc khám phá chúng là đáng giá vì lý do trí tuệ và sư phạm. Mặc dù việc triển khai thay đổi giữa các bộ xử lý, các khái niệm vẫn giữ nguyên. Chúng ta sẽ giải thích các khái niệm trước và sau đó thảo luận về các chi tiết triển khai trên x86, x64 và ARM.

Windows mô tả và lưu trữ thông tin lời gọi hệ thống bằng hai cấu trúc dữ liệu: một **bộ mô tả bảng dịch vụ (service table descriptor)** và một **mảng các con trỏ hàm/offset (array of function pointers/offsets)**. Bộ mô tả bảng dịch vụ là một cấu trúc chứa siêu dữ liệu (metadata) về các lời gọi hệ thống được OS hỗ trợ; định nghĩa của nó chính thức không được tài liệu hóa, nhưng nhiều người đã dịch ngược mã các thành viên trường quan trọng của nó như sau. (Bạn cũng có thể tìm ra các trường này bằng cách phân tích các hàm `KiSystemCall64` hoặc `KiSystemService`.)

```c
typedef struct _KSERVICE_TABLE_DESCRIPTOR
{
  PULONG Base;      // Mảng các địa chỉ hoặc offset
  PULONG Count;     // (Không rõ mục đích chính xác)
  ULONG Limit;     // Kích thước của mảng Base
  PUCHAR Number;   
  ...
} KSERVICE_TABLE_DESCRIPTOR, *PKSERVICE_TABLE_DESCRIPTOR;
```

`Base` là một con trỏ đến một mảng các con trỏ hàm hoặc offset (tùy thuộc vào bộ xử lý); một số hiệu lời gọi hệ thống (system call number) là một chỉ số (index) vào mảng này. `Limit` là số lượng mục (entries) trong mảng. Nhân giữ hai mảng toàn cục kiểu `KSERVICE_DESCRIPTOR_DESCRIPTOR`: `KeServiceDescriptorTable` và `KeServiceDescriptorTableShadow`. Bảng cũ chứa bảng syscall gốc (native); bảng sau chứa cùng dữ liệu đó, cộng thêm bảng syscall cho các luồng GUI (Giao diện người dùng đồ họa). Nhân cũng giữ hai con trỏ toàn cục đến các mảng địa chỉ/offset: `KiServiceTable` trỏ đến bảng syscall không phải GUI và `W32pServiceTable` trỏ đến bảng GUI. 

**Hình 3.2**  minh họa mối quan hệ giữa các cấu trúc dữ liệu này trên x86.

![alt text](image-6.png)

**Trên x86**, trường `Base` là một mảng các **con trỏ hàm** cho các syscall:

```
0: kd> dps nt!KeServiceDescriptorTable  // Hiển thị nội dung KeServiceDescriptorTable
81472400  813564d0 nt!KiServiceTable    ; Base (trỏ đến KiServiceTable)
81472404  00000000
81472408  000001ad                     ; Limit (số lượng syscall)
8147240c  81356b88 nt!KiArgumentTable

0: kd> dd nt!KiServiceTable           // Hiển thị các con trỏ hàm trong KiServiceTable
813564d0  81330901 812cf1e2 81581540 816090af
813564e0  815be478 814b048f 8164e434 8164e3cb
...

0: kd> dps nt!KiServiceTable          // Hiển thị các con trỏ hàm với tên tương ứng
813564d0  81330901 nt!NtWorkerFactoryWorkerReady
813564d4  812cf1e2 nt!NtYieldExecution
813564d8  81581540 nt!NtWriteVirtualMemory
813564dc  816090af nt!NtWriteRequestData
...
```

**Tuy nhiên, trên x64 và ARM**, nó là một mảng các số nguyên 32-bit mã hóa **offset của lời gọi hệ thống và số lượng đối số được truyền trên ngăn xếp (stack)**. Offset được chứa trong 20 bit cao, và số lượng đối số trên ngăn xếp được chứa trong 4 bit thấp. Offset này được cộng vào địa chỉ cơ sở của `KiServiceTable` để có được địa chỉ thực của syscall. Ví dụ (trên x64):

```
0: kd> dps nt!KeServiceDescriptorTable // Hiển thị nội dung KeServiceDescriptorTable trên x64
fffff803'955cd900 fffff803'952ed200 nt!KiServiceTable    ; Base (trỏ đến KiServiceTable)
fffff803'955cd908 00000000'00000000
fffff803'955cd910 00000000'000001ad                     ; Limit
fffff803'955cd918 fffff803'952edf6c nt!KiArgumentTable

0: kd> u ntdll!NtCreateFile          // Xem mã assembly của NtCreateFile ở user-mode
ntdll!NtCreateFile:
000007f8'34f23130 mov     r10,rcx
000007f8'34f23133 mov     eax,53h     ; Số hiệu syscall là 53h
000007f8'34f23138 syscall             ; Lệnh thực hiện lời gọi hệ thống
...

0: kd> x nt!KiServiceTable           // Xem địa chỉ của KiServiceTable
fffff803'952ed200 nt!KiServiceTable (<no parameter info>)

0: kd> dd nt!KiServiceTable + (0x53*4) L1 // Đọc giá trị 32-bit tại chỉ số 53h trong KiServiceTable
fffff803'952ed34c  03ea2c07          ; Giá trị mã hóa offset và số đối số

0: kd> u nt!KiServiceTable + (0x03ea2c07 >> 4) ; Lấy offset (dịch phải 4 bit) và cộng vào Base để xem mã hàm xử lý
nt!NtCreateFile:                      ; Đây chính là hàm xử lý NtCreateFile trong kernel
fffff803'956d74c0 sub     rsp,88h
fffff803'956d74c7 xor     eax,eax
...

0: kd> ? 0x03ea2c07 & 0xf             ; Lấy 4 bit thấp để xem số đối số trên stack
Evaluate expression: 7 = 00000000'00000007

; Giải thích: NtCreateFile nhận 11 đối số. 4 đối số đầu tiên được truyền qua thanh ghi (theo quy ước x64)
; và 7 đối số cuối cùng được truyền trên ngăn xếp.
```

Như đã chứng minh, mỗi lời gọi hệ thống được xác định bởi một số hiệu, là chỉ số vào `KiServiceTable` hoặc `W32pServiceTable`. Ở mức thấp nhất, các API chế độ người dùng (user-mode) phân rã thành một hoặc nhiều lời gọi hệ thống.

Về mặt khái niệm, đây là cách lời gọi hệ thống hoạt động trên Windows. Các chi tiết triển khai thay đổi tùy thuộc vào kiến trúc bộ xử lý và nền tảng. Lời gọi hệ thống thường được triển khai thông qua các ngắt mềm (software interrupts) hoặc các lệnh đặc thù của kiến trúc, chi tiết về chúng sẽ được đề cập trong các phần sau.

---



## Faults, Traps, and Interrupts 

Để chuẩn bị cho các phần tiếp theo, chúng ta cần giới thiệu một số thuật ngữ cơ bản để giải thích cách các thiết bị ngoại vi và phần mềm tương tác với bộ xử lý. Trong các hệ thống máy tính đương đại, bộ xử lý thường được kết nối với các thiết bị ngoại vi thông qua một bus dữ liệu như PCI Express, FireWire, hoặc USB. Khi một thiết bị yêu cầu sự chú ý của bộ xử lý, nó gây ra một **ngắt (interrupt)**, buộc bộ xử lý phải tạm dừng bất cứ việc gì nó đang làm và xử lý yêu cầu của thiết bị.

Làm thế nào bộ xử lý biết cách xử lý yêu cầu? Ở mức cao nhất, người ta có thể hình dung một ngắt được liên kết với một số hiệu, số hiệu này sau đó được sử dụng làm chỉ số (index) để truy cập vào một mảng các con trỏ hàm. Khi bộ xử lý nhận được ngắt, nó thực thi hàm tại chỉ số tương ứng với yêu cầu đó và sau đó tiếp tục thực thi tại bất kỳ điểm nào mà nó đã dừng trước khi ngắt xảy ra. Đây được gọi là **ngắt phần cứng (hardware interrupts)** bởi vì chúng được tạo ra bởi các thiết bị phần cứng. Chúng có bản chất là bất đồng bộ (asynchronous).

Khi bộ xử lý đang thực thi một lệnh, nó có thể gặp phải các **ngoại lệ (exceptions)**. Ví dụ, lệnh đó gây ra lỗi chia cho không, tham chiếu đến một địa chỉ không hợp lệ, hoặc kích hoạt việc chuyển đổi mức đặc quyền. Vì mục đích của cuộc thảo luận này, các ngoại lệ có thể được phân thành hai loại: lỗi (faults) và bẫy (traps).

Một **lỗi (fault)** là một ngoại lệ có thể *sửa chữa được*. Ví dụ, khi bộ xử lý thực thi một lệnh tham chiếu đến một địa chỉ bộ nhớ hợp lệ nhưng dữ liệu không có sẵn trong bộ nhớ chính (nó đã bị đưa ra bộ nhớ phụ - paged out), một ngoại lệ **lỗi trang (page fault)** được tạo ra. Bộ xử lý xử lý điều này bằng cách lưu trạng thái thực thi hiện tại, gọi trình xử lý lỗi trang (page fault handler) để sửa chữa ngoại lệ này (bằng cách nạp trang dữ liệu vào), và **thực thi lại chính lệnh đó** (lúc này lẽ ra không còn gây ra lỗi trang nữa).

Một **bẫy (trap)** là một ngoại lệ gây ra bởi việc thực thi các loại lệnh đặc biệt. Ví dụ, trên x64, lệnh `SYSCALL` khiến bộ xử lý bắt đầu thực thi tại một địa chỉ được chỉ định bởi một thanh ghi đặc tả mô hình (MSR - Model-Specific Register); sau khi trình xử lý hoàn tất, việc thực thi được tiếp tục tại lệnh **ngay sau** lệnh `SYSCALL`.

Do đó, sự khác biệt chính giữa một lỗi (fault) và một bẫy (trap) là **nơi việc thực thi được tiếp tục**. Lời gọi hệ thống (System calls) thường được triển khai thông qua các ngoại lệ đặc biệt hoặc các lệnh trap.

---

**Tóm tắt các điểm chính:**

* **Ngắt (Interrupt):** Do phần cứng ngoại vi gây ra, bất đồng bộ, làm bộ xử lý tạm dừng việc hiện tại để chạy một hàm xử lý (ISR), sau đó quay lại việc cũ.
* **Ngoại lệ (Exception):** Xảy ra *đồng bộ* với việc thực thi lệnh (ví dụ: lỗi lệnh, truy cập bộ nhớ sai). Gồm 2 loại chính:
    * **Lỗi (Fault):** Có thể sửa được (như Page Fault). Sau khi trình xử lý sửa lỗi, **lệnh gây lỗi được thực thi lại**.
    * **Bẫy (Trap):** Gây ra bởi lệnh đặc biệt (như `SYSCALL`). Sau khi trình xử lý chạy xong, **lệnh kế tiếp sau lệnh trap được thực thi**.
* **Lời gọi hệ thống (System Call):** Thường được thực hiện bằng cơ chế Trap.