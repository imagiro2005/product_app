import '../exceptions/app_exception.dart';

/// Mixin tái sử dụng tính năng kiểm tra tính hợp lệ của dữ liệu đầu vào.
/// Nhúng vào bất kỳ Model hay Service nào bằng từ khóa `with ValidationMixin`.
mixin ValidationMixin {
  /// Kiểm tra chuỗi không được null hoặc chỉ toàn khoảng trắng.
  void requireNotEmpty(
    String? value,
    String fieldName, {
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      throw ValidationException(
        customMessage ?? 'Trường "$fieldName" không được phép để trống.',
        fieldName: fieldName,
      );
    }
  }

  /// Kiểm tra số phải lớn hơn 0.
  void requirePositiveNumber(
    num? value,
    String fieldName, {
    String? customMessage,
  }) {
    if (value == null) {
      throw ValidationException(
        customMessage ?? 'Trường "$fieldName" không được để trống.',
        fieldName: fieldName,
      );
    }
    if (value <= 0) {
      throw ValidationException(
        customMessage ?? 'Trường "$fieldName" phải là một số dương lớn hơn 0 (Hiện tại: $value).',
        fieldName: fieldName,
      );
    }
  }

  /// Kiểm tra độ dài tối thiểu của chuỗi.
  void requireMinLength(
    String? value,
    int minLength,
    String fieldName, {
    String? customMessage,
  }) {
    if (value == null || value.trim().length < minLength) {
      throw ValidationException(
        customMessage ?? 'Trường "$fieldName" phải chứa ít nhất $minLength ký tự.',
        fieldName: fieldName,
      );
    }
  }

  /// Kiểm tra số nằm trong khoảng [min, max].
  void requireRange(
    num? value,
    num min,
    num max,
    String fieldName, {
    String? customMessage,
  }) {
    if (value == null || value < min || value > max) {
      throw ValidationException(
        customMessage ?? 'Trường "$fieldName" phải nằm trong khoảng từ $min đến $max.',
        fieldName: fieldName,
      );
    }
  }
}
