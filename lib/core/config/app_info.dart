import 'package:package_info_plus/package_info_plus.dart';

/// Versi aplikasi yang sedang terpasang, dibaca dari build (sama dengan
/// `version:` di pubspec.yaml) — bukan ditulis manual supaya tidak pernah
/// berbeda dengan yang diunggah ke Play Store.
class AppInfo {
  const AppInfo._();

  static Future<String>? _label;

  /// Mis. `1.0.0 (2)`: versionName lalu versionCode (angka setelah `+`).
  /// Dibaca sekali lalu disimpan.
  static Future<String> versionLabel() => _label ??= _load();

  static Future<String> _load() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
