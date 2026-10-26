/// Đóng gói kết quả của một tác vụ bất đồng bộ bằng Result Pattern
/// kết hợp tính năng Sealed Class và Pattern Matching của Dart 3.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Lấy dữ liệu an toàn nếu thành công, trả về null nếu thất bại
  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  /// Lấy thông báo lỗi nếu thất bại, trả về null nếu thành công
  String? get errorOrNull => switch (this) {
        Success() => null,
        Failure(userMessage: final msg) => msg,
      };

  /// Phương thức ánh xạ hàm tiện ích
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure<T> failure) onFailure,
  }) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      Failure() => onFailure(this as Failure<T>),
    };
  }
}

/// Trạng thái thực thi thành công chứa dữ liệu [data] kiểu tổng quát [T].
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';
}

/// Trạng thái thực thi thất bại chứa thông báo thân thiện và mã lỗi kỹ thuật.
class Failure<T> extends Result<T> {
  /// Thông điệp tiếng Việt thân thiện dùng để hiển thị trực tiếp lên UI (SnackBar/Dialog).
  final String userMessage;

  /// Đối tượng ngoại lệ kỹ thuật gốc phục vụ ghi log hoặc chẩn đoán (Crashlytics).
  final Object technicalError;

  /// Vết ngăn xếp gọi hàm (Call Stack) giúp lập trình viên xác định chính xác dòng lỗi.
  final StackTrace? stackTrace;

  /// Mã lỗi nghiệp vụ định danh (Ví dụ: VALIDATION_ERROR, NETWORK_ERROR).
  final String? errorCode;

  const Failure({
    required this.userMessage,
    required this.technicalError,
    this.stackTrace,
    this.errorCode,
  });

  @override
  String toString() =>
      'Failure(code: $errorCode, userMessage: "$userMessage", technicalError: $technicalError)';
}
