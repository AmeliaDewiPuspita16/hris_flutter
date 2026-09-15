/// Alamat backend BIIE Portal beserta path endpoint-nya.
///
/// Base URL bisa ditimpa saat build tanpa mengubah kode, berguna untuk
/// menunjuk ke server staging atau ke IP lokal saat pengembangan:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
/// ```
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://biieportal.co.id',
  );

  /// Batas tunggu satu request sebelum dianggap gagal.
  static const Duration timeout = Duration(seconds: 20);

  static const String login = '/api/login';
}
