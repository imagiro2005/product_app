import 'dart:async';
import '../exceptions/app_exception.dart';
import '../mixins/logger_mixin.dart';
import 'error_mapper.dart';
import 'result.dart';

/// Hàm bao bọc (Safe Wrapper) bắt và gom lỗi tập trung cho toàn bộ ứng dụng.
/// Áp dụng Generics `<T>` để bảo đảm an toàn kiểu (Type Safety), kết hợp
/// LoggerMixin để tự động ghi nhật ký và ErrorMessageMapper để chuyển đổi thông báo.
class SafeRunner with LoggerMixin {
  /// Bọc một tác vụ đồng bộ hoặc bất đồng bộ bất kỳ.
  /// Đảm bảo không bao giờ ném ngoại lệ ra ngoài làm sập giao diện (Crash-proof).
  static Future<Result<T>> run<T>(
    FutureOr<T> Function() action, {
    String taskName = 'Tác vụ không tên',
  }) async {
    final runner = SafeRunner();
    final stopwatch = Stopwatch()..start();

    runner.logInfo('Bắt đầu thực thi: "$taskName"');

    try {
      // 1. Thực thi tác vụ có nguy cơ phát sinh lỗi
      final data = await action();

      runner.logInfo(
        'Hoàn tất thành công: "$taskName" (${stopwatch.elapsedMilliseconds}ms)',
      );
      return Success(data);
    } on AppException catch (e, stackTrace) {
      // 2. Bắt các ngoại lệ nghiệp vụ tùy biến (Custom AppException)
      runner.logError('Ngoại lệ nghiệp vụ [$taskName]: $e', e, stackTrace);
      return Failure(
        userMessage: e.message,
        technicalError: e,
        stackTrace: stackTrace,
        errorCode: e.code,
      );
    } on TimeoutException catch (e, stackTrace) {
      // 3. Bắt ngoại lệ hết thời gian chờ
      runner.logError('Hết thời gian phản hồi [$taskName]', e, stackTrace);
      return Failure(
        userMessage: ErrorMessageMapper.toUserMessage(e),
        technicalError: e,
        stackTrace: stackTrace,
        errorCode: 'TIMEOUT_ERROR',
      );
    } on Exception catch (e, stackTrace) {
      // 4. Bắt tất cả các loại ngoại lệ chuẩn khác của Dart
      runner.logError('Ngoại lệ hệ thống [$taskName]: $e', e, stackTrace);
      return Failure(
        userMessage: ErrorMessageMapper.toUserMessage(e),
        technicalError: e,
        stackTrace: stackTrace,
        errorCode: ErrorMessageMapper.extractErrorCode(e),
      );
    } catch (e, stackTrace) {
      // 5. Bắt cả các lỗi nghiêm trọng (Error như RangeError, TypeError, NoSuchMethodError)
      // Chốt chặn cuối cùng ngăn chặn 100% việc ứng dụng bị dừng đột ngột (Crash)
      runner.logError('Lỗi lập trình nghiêm trọng (Error) [$taskName]: $e', e, stackTrace);
      return Failure(
        userMessage: ErrorMessageMapper.toUserMessage(e),
        technicalError: e,
        stackTrace: stackTrace,
        errorCode: ErrorMessageMapper.extractErrorCode(e),
      );
    } finally {
      // 6. Luôn luôn thực thi dù thành công hay thất bại
      stopwatch.stop();
      runner.logInfo(
        '[Finally] Giải phóng tài nguyên cho "$taskName" (Tổng thời gian: ${stopwatch.elapsedMilliseconds}ms)',
      );
    }
  }
}
