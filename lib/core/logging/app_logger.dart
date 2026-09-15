import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Ke mana catatan log dikirim. Bisa diganti pada test untuk memeriksa apa
/// yang dicatat.
typedef LogSink = void Function(
  String message, {
  Object? error,
  StackTrace? stackTrace,
});

/// Catatan diagnostik ke console, hanya aktif pada build debug.
///
/// Sengaja sederhana: tujuannya melacak masalah saat pengembangan, bukan
/// menjadi sistem logging lengkap.
class AppLogger {
  const AppLogger._();

  static LogSink sink = defaultSink;

  /// Menulis ke console lewat `dart:developer`, sehingga terlihat baik di
  /// terminal `flutter run` maupun di DevTools. Diam total pada build rilis.
  static void defaultSink(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    // Pesan diawali penanda supaya gampang disaring di terminal:
    //   flutter run | grep HRIS
    developer.log(
      '[HRIS] $message',
      name: 'HRIS',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Mengembalikan tujuan log ke console.
  static void resetSink() => sink = defaultSink;

  static void info(String message) => sink(message);

  static void error(String message, Object error, [StackTrace? stackTrace]) =>
      sink(message, error: error, stackTrace: stackTrace);
}
