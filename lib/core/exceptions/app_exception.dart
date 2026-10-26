/// Hệ thống Custom Exception phân cấp cho ứng dụng theo chuẩn Clean Code.
/// Mọi ngoại lệ nghiệp vụ trong hệ thống đều kế thừa từ [AppException].
abstract class AppException implements Exception {
  final String message;
  final String code;
  final Object? details;
  final DateTime timestamp;

  AppException(
    this.message, {
    required this.code,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '[$code] $message ${details != null ? "(Chi tiết: $details)" : ""}';
}

/// Ngoại lệ ném ra khi dữ liệu đầu vào không thỏa mãn quy tắc kiểm tra (Validation).
class ValidationException extends AppException {
  final String? fieldName;

  ValidationException(
    super.message, {
    this.fieldName,
    super.details,
  }) : super(code: 'VALIDATION_ERROR');

  @override
  String toString() =>
      '[$code] ${fieldName != null ? "Trường [$fieldName]: " : ""}$message';
}

/// Ngoại lệ ném ra khi xảy ra sự cố mạng, mất kết nối, hoặc máy chủ ngắt quãng.
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException(
    super.message, {
    this.statusCode,
    super.details,
  }) : super(code: 'NETWORK_ERROR');

  @override
  String toString() =>
      '[$code] ${statusCode != null ? "HTTP $statusCode - " : ""}$message';
}

/// Ngoại lệ ném ra khi phân tích cú pháp (Parse JSON/Map) thất bại hoặc sai kiểu dữ liệu.
class DataParsingException extends AppException {
  final String? malformedKey;

  DataParsingException(
    super.message, {
    this.malformedKey,
    super.details,
  }) : super(code: 'PARSING_ERROR');

  @override
  String toString() =>
      '[$code] ${malformedKey != null ? "Khóa [$malformedKey]: " : ""}$message';
}

/// Ngoại lệ ném ra khi không tìm thấy tài nguyên yêu cầu trong kho dữ liệu.
class NotFoundException extends AppException {
  final String? resourceId;

  NotFoundException(
    super.message, {
    this.resourceId,
  }) : super(code: 'NOT_FOUND');
}

/// Ngoại lệ phía máy chủ (HTTP 5xx).
class ServerException extends AppException {
  final int statusCode;

  ServerException(
    super.message, {
    this.statusCode = 500,
    super.details,
  }) : super(code: 'SERVER_ERROR');
}
