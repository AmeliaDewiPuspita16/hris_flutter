import 'package:hris_mobile/core/logging/app_logger.dart';

class LogEntry {
  const LogEntry(this.message, this.error, this.stackTrace);

  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Menangkap apa saja yang dicatat [AppLogger] selama sebuah test.
class LogRecorder {
  final List<LogEntry> entries = [];

  List<String> get messages => entries.map((e) => e.message).toList();

  /// Semua pesan digabung, memudahkan pemeriksaan "ada kata ini atau tidak".
  String get combined => messages.join('\n');

  void install() {
    AppLogger.sink = (message, {error, stackTrace}) =>
        entries.add(LogEntry(message, error, stackTrace));
  }
}
