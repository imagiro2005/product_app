import 'dart:async';
import 'dart:io';
import '../exceptions/app_exception.dart';

/// Bộ ánh xạ lỗi tập trung (Centralized Error Mapper).
/// Chuyển đổi mọi ngoại lệ kỹ thuật (Exception/Error) thành câu thông điệp
/// thân thiện, rõ ràng, hướng dẫn người dùng thay vì hiển thị mã lỗi thô.
class ErrorMessageMapper {
  /// Chuyển đổi ngoại lệ sang câu thông báo giao diện (UI User-friendly Message)
  static String toUserMessage(Object error) {
    // 1. Nhóm Custom AppException của hệ thống
    if (error is ValidationException) {
      return error.message; // Message nghiệp vụ đã rõ ràng
    }

    if (error is NetworkException) {
      return 'Kết nối mạng không ổn định. Vui lòng kiểm tra lại đường truyền Wi-Fi/4G và thử lại.';
    }

    if (error is DataParsingException) {
      return 'Dữ liệu phản hồi từ máy chủ không đúng định dạng. Vui lòng cập nhật ứng dụng hoặc thử lại sau.';
    }

    if (error is NotFoundException) {
      return 'Không tìm thấy thông tin sản phẩm yêu cầu trong kho dữ liệu.';
    }

    if (error is ServerException) {
      return 'Máy chủ đang bảo trì hoặc gặp sự cố (${error.statusCode}). Xin vui lòng quay lại sau ít phút.';
    }

    // 2. Nhóm ngoại lệ chuẩn của Dart SDK
    if (error is SocketException) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng của thiết bị.';
    }

    if (error is TimeoutException) {
      return 'Thời gian phản hồi từ máy chủ quá lâu. Vui lòng thử lại sau.';
    }

    if (error is FormatException) {
      return 'Định dạng dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin đầu vào.';
    }

    // 3. Nhóm lỗi lập trình (Error - Bug)
    if (error is RangeError) {
      return 'Chỉ số dữ liệu vượt ngoài phạm vi danh sách. Hệ thống đang tự động khôi phục.';
    }

    if (error is ArgumentError) {
      return 'Tham số truyền vào hàm không hợp lệ.';
    }

    if (error is TypeError) {
      return 'Lỗi sai lệch kiểu dữ liệu trong quá trình xử lý.';
    }

    // 4. Fallback mặc định an toàn cho các lỗi bất ngờ ngoài dự kiến
    return 'Đã có sự cố ngoài ý muốn xảy ra. Đội ngũ kỹ thuật đã được thông báo để khắc phục.';
  }

  /// Trích xuất mã lỗi định danh (Error Code)
  static String extractErrorCode(Object error) {
    if (error is AppException) {
      return error.code;
    }
    if (error is SocketException) return 'SOCKET_EXCEPTION';
    if (error is TimeoutException) return 'TIMEOUT_EXCEPTION';
    if (error is FormatException) return 'FORMAT_EXCEPTION';
    if (error is Error) return 'SYSTEM_RUNTIME_ERROR';
    return 'UNKNOWN_EXCEPTION';
  }
}
