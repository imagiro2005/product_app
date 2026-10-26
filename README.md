# PT Product App 🛍️
> **Ứng dụng Demo minh họa Nền tảng OOP Nâng Cao & Kỹ thuật Xử lý Lỗi trong Dart/Flutter**

---

## 👥 Nhóm tác giả (Sinh viên thực hiện)
- **Huỳnh Ngọc Tịnh Phong**
- **Phạm Nhật Tân**

---

## 📖 Giới thiệu dự án

**PT Product App** là ứng dụng Flutter quản lý kho sản phẩm, được xây dựng nhằm hiện thực hóa và demo thực tế các kiến thức chuyên sâu về:
1. **Lập trình hướng đối tượng nâng cao (Advanced OOP)**: *Named Constructor*, *Factory Constructor*, *Mixins*, và *Generics*.
2. **Kỹ thuật xử lý lỗi chuyên sâu (Error Handling)**: *Phân cấp Custom Exception*, *Cấu trúc try-catch-finally*, *Result Pattern (Dart 3 Sealed Classes)*, *Hàm bao bọc gom lỗi tập trung (Safe Wrapper)*, và *Ghi nhật ký ra file ngoài (File Logging)*.

Ứng dụng đảm bảo tiêu chí **Zero-Crash** (ứng dụng không bao giờ bị dừng đột ngột do ngoại lệ runtime), đồng thời mang lại trải nghiệm người dùng thân thiện, giao diện tinh gọn và mã nguồn theo chuẩn **Clean Code**.

---

## 🚀 Các tính năng chính & Kiến thức áp dụng

### 1. Lập trình Hướng đối tượng nâng cao (OOP)
- **Named Constructor**:
  - `Product.draft(...)`: Khởi tạo sản phẩm dạng bản nháp với giá mặc định 0đ.
  - `Product.discounted(...)`: Khởi tạo sản phẩm có chiết khấu kèm logic kiểm tra tính hợp lệ.
- **Factory Constructor**:
  - `Product.fromJson(Map<String, dynamic> json)`: Khởi tạo linh hoạt từ dữ liệu Map/JSON, kiểm tra ràng buộc dữ liệu ngay tại bước khởi tạo trước khi tạo instance.
- **Mixins**:
  - `ValidationMixin`: Cung cấp các phương thức kiểm tra hợp lệ dùng chung (`requireNotEmpty`, `requirePositiveNumber`, `requireRange`, `requireMinLength`) mà không cần kế thừa cha - con.
  - `LoggerMixin`: Tự động định dạng và ghi log cho các lớp trong hệ thống (`Product`, `ProductService`, `ProductScreen`, `SafeRunner`).
- **Generics**:
  - Xây dựng kiểu dữ liệu bọc an toàn `Result<T>` và hàm gom lỗi an toàn `SafeRunner.run<T>(...)`, cho phép tái sử dụng cho bất kỳ kiểu dữ liệu trả về nào mà vẫn đảm bảo Type Safety.

### 2. Kỹ thuật Xử lý Lỗi (Error Handling)
- **Hệ thống Custom Exception phân cấp**:
  - Lớp cơ sở trừu tượng: `AppException`.
  - Các ngoại lệ chuyên biệt: `ValidationException`, `DataParsingException`, `NetworkException`, `NotFoundException`, `ServerException`.
- **Mô hình Result Pattern (Dart 3 Sealed Class)**:
  - `sealed class Result<T>` với 2 trạng thái `Success<T>` và `Failure<T>`.
  - Kết hợp với Dart 3 Pattern Matching (`switch (result)`) kiểm soát luồng nghiệp vụ toàn diện (Exhaustiveness Checking), triệt tiêu lỗi thiếu sót case.
- **Hàm bao bọc tập trung (Safe Wrapper - `SafeRunner`)**:
  - Bọc tất cả thao tác đồng bộ hoặc bất đồng bộ có rủi ro phát sinh ngoại lệ.
  - Bắt từ `AppException` (lỗi nghiệp vụ), `TimeoutException`, `Exception` đến các lỗi nghiêm trọng `Error` (như `RangeError`, `TypeError`), ngăn chặn 100% việc ứng dụng bị dừng đột ngột (crash).
  - Sử dụng khối `finally` giải phóng tài nguyên và đo lường thời gian thực thi.
- **Thông báo lỗi thân thiện trên giao diện**:
  - Khi người dùng nhập sai (để trống tên, giá âm, sai định dạng số, trùng ID,...), ứng dụng hiển thị hộp thoại thông báo lỗi ngắn gọn, lịch sự, loại bỏ các chi tiết kỹ thuật phức tạp đối với người dùng cuối.
- **Ghi nhật ký ra file ngoài (`FileLogger`)**:
  - Mọi lỗi phát sinh đều được tự động lưu vết và nối (append) vào tập tin [`app_error.log`](app_error.log).
  - Bản ghi nhật ký bao gồm: Thời gian chính xác, Mức độ (`[ERROR]`), Nguồn gốc (`Tag`), Thông điệp lỗi, Lớp ngoại lệ (`runtimeType`), và Vết ngăn xếp (`StackTrace`).

---

## 📂 Cấu trúc thư mục dự án

```text
product_app/
├── lib/
│   ├── core/
│   │   ├── exceptions/
│   │   │   └── app_exception.dart      # Phân cấp Custom Exception
│   │   ├── mixins/
│   │   │   ├── logger_mixin.dart       # Logger Mixin dùng chung
│   │   │   └── validation_mixin.dart   # Validation Mixin kiểm tra dữ liệu
│   │   └── utils/
│   │       ├── error_mapper.dart       # Chuyển đổi mã lỗi sang thông điệp thân thiện
│   │       ├── file_logger.dart        # Ghi log ra tập tin app_error.log
│   │       ├── result.dart             # Result Pattern với Sealed Class
│   │       └── safe_runner.dart        # Safe Wrapper bắt và gom lỗi tập trung
│   ├── models/
│   │   └── product.dart                # Model sản phẩm (Named/Factory, Mixins)
│   ├── services/
│   │   └── product_service.dart        # Service thao tác dữ liệu sản phẩm
│   ├── ui/
│   │   ├── widgets/
│   │   │   └── product_card.dart       # Widget hiển thị thông tin sản phẩm
│   │   └── product_screen.dart         # Màn hình chính "PT product app"
│   └── main.dart                       # Entry point khởi chạy ứng dụng
├── test/
│   └── widget_test.dart                # Bộ kiểm thử tự động (10 test cases)
├── app_error.log                       # Tập tin ghi nhận lỗi ngoài
└── pubspec.yaml                        # Quản lý dependencies & metadata dự án
```

---

## 🛠️ Hướng dẫn cài đặt và chạy ứng dụng

### Yêu cầu môi trường
- **Flutter SDK**: >= 3.12.0
- **Dart SDK**: >= 3.12.0
- Thiết bị chạy: Windows Desktop, Android Emulator, iOS Simulator hoặc Chrome Web.

### Các bước thực hiện

1. **Clone repository về máy**:
   ```bash
   git clone https://github.com/imagiro2005/product_app.git
   cd product_app
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

4. **Kiểm tra chất lượng mã nguồn (Static Analysis)**:
   ```bash
   flutter analyze
   ```
   *(Đạt kết quả 0 issues, tuân thủ nghiêm ngặt flutter_lints).*

5. **Chạy bộ kiểm thử tự động (Unit & Widget Tests)**:
   ```bash
   flutter test
   ```
   *(Toàn bộ 10/10 test cases đều vượt qua thành công).*

---

## 🧪 Các kịch bản kiểm thử mẫu (Test Scenarios)

| Thao tác người dùng | Dữ liệu kiểm thử | Kết quả bắt lỗi | Ghi log ra file |
| :--- | :--- | :--- | :---: |
| Thêm sản phẩm để trống tên | `Tên: ""` | Bắt lỗi `ValidationException`: *"Trường Tên sản phẩm không được phép để trống."* |  Đã ghi vào `app_error.log` |
| Nhập giá sản phẩm là số âm | `Giá: -50000` | Bắt lỗi `ValidationException`: *"Trường Giá sản phẩm phải là một số dương lớn hơn 0."* |  Đã ghi vào `app_error.log` |
| Nhập ký tự chữ vào ô giá | `Giá: "hai triệu"` | Bắt lỗi `DataParsingException`: *"Giá sản phẩm phải là một số hợp lệ."* |  Đã ghi vào `app_error.log` |
| Thêm mã sản phẩm đã tồn tại | `ID: "PRD-001"` | Bắt lỗi `ValidationException`: *"Mã sản phẩm đã tồn tại trong hệ thống."* |  Đã ghi vào `app_error.log` |

---

## 📄 Bản quyền
Dự án được xây dựng phục vụ cho mục đích học tập và báo cáo học phần môn Lập trình đa nền tảng (Cross-platform Development).
