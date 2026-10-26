import 'dart:io';
import 'package:flutter/foundation.dart';

/// Tiện ích ghi nhật ký lỗi ra tập tin ngoài (External File Logger).
/// Ghi nối (append) các thông điệp lỗi, ngoại lệ và stack trace vào tập tin `app_error.log`.
class FileLogger {
  /// Tên tập tin log lỗi mặc định
  static String logFileName = 'app_error.log';

  /// Đối tượng File tương ứng
  static File get logFile => File(logFileName);

  /// Ghi nối thông tin lỗi vào tập tin ngoài
  static Future<void> logErrorToFile({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) async {
    try {
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final sb = StringBuffer();
      sb.writeln('----------------------------------------------------------------');
      sb.writeln('Thời gian : $timestamp | Mức độ: [ERROR]');
      sb.writeln('Nguồn (Tag): [${tag ?? 'UNKNOWN'}]');
      sb.writeln('Thông báo : $message');
      if (error != null) {
        sb.writeln('Loại lỗi  : ${error.runtimeType}');
        sb.writeln('Chi tiết  : $error');
      }
      if (stackTrace != null) {
        sb.writeln('Vết ngăn xếp (StackTrace):');
        sb.writeln(stackTrace.toString().split('\n').take(8).map((line) => '  $line').join('\n'));
      }
      sb.writeln('----------------------------------------------------------------\n');

      final file = logFile;
      await file.writeAsString(sb.toString(), mode: FileMode.append, flush: true);
      debugPrint('📝 [FileLogger] Đã ghi log lỗi vào: ${file.absolute.path}');
    } catch (e) {
      debugPrint('⚠️ [FileLogger] Không thể ghi log ra file: $e');
    }
  }

  /// Đọc toàn bộ nội dung file log
  static Future<String> readLogContent() async {
    try {
      final file = logFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'File log chưa có dữ liệu.';
    } catch (e) {
      return 'Lỗi khi đọc file log: $e';
    }
  }

  /// Làm sạch nội dung file log
  static Future<void> clearLogFile() async {
    try {
      final file = logFile;
      if (await file.exists()) {
        await file.writeAsString('', mode: FileMode.write, flush: true);
      }
    } catch (e) {
      debugPrint('⚠️ [FileLogger] Lỗi khi làm sạch file log: $e');
    }
  }
}
