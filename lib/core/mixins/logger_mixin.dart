import 'package:flutter/foundation.dart';
import '../utils/file_logger.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Mixin tái sử dụng tính năng ghi log cho bất kỳ Class nào trong hệ thống.
/// Sử dụng từ khóa `with LoggerMixin`.
mixin LoggerMixin {
  /// Bộ nhớ lưu trữ nhật ký toàn cục để hiển thị trực tiếp lên UI Demo.
  static final ValueNotifier<List<LogEntry>> logHistoryNotifier =
      ValueNotifier<List<LogEntry>>([]);

  /// Lấy danh sách nhật ký hiện tại
  static List<LogEntry> get logs => logHistoryNotifier.value;

  /// Xóa toàn bộ nhật ký
  static void clearLogs() {
    logHistoryNotifier.value = [];
  }

  void _addLog(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? customTag,
  }) {
    final tag = customTag ?? runtimeType.toString();
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    // Cập nhật danh sách log cho UI
    logHistoryNotifier.value = [...logHistoryNotifier.value, entry];

    // In ra Debug Console
    final icon = switch (level) {
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };

    debugPrint('$icon [$tag - ${entry.timeFormatted}]: $message');
    if (error != null) {
      debugPrint('   Chi tiết lỗi: $error');
    }
  }

  void logInfo(String message, {String? tag}) {
    _addLog(LogLevel.info, message, customTag: tag);
  }

  void logWarning(String message, {String? tag}) {
    _addLog(LogLevel.warning, message, customTag: tag);
  }

  void logError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    final effectiveTag = tag ?? runtimeType.toString();
    _addLog(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      customTag: effectiveTag,
    );

    // Ghi log lỗi ra file ngoài (External File Logging)
    FileLogger.logErrorToFile(
      message: message,
      error: error,
      stackTrace: stackTrace,
      tag: effectiveTag,
    );
  }
}
