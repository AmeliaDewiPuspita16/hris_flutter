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
  static const String logout = '/api/logout';

  /// Daftar departemen aktif — dipakai buat ngisi dropdown, misalnya di
  /// form pengumuman. Server yang urus filter `is_active` dan urutannya.
  static const String department = '/api/data/department';

  /// Menerbitkan pengumuman HR. Perlu izin `hr-announcement-post`, yang
  /// dimiliki role `hrga` dan `admin`. Dikirim sebagai multipart karena
  /// menerima lampiran `photos[]`.
  static const String hrAnnouncement = '/api/portal/hr_announcement';

  /// Procurement Monitoring. Daftar PR di path ini, detail satu PR di
  /// `$eprocurement/{id}`.
  ///
  /// Endpoint daftarnya menaruh `summary` dan `meta` bersebelahan dengan
  /// `data`, jadi harus diambil lewat [ApiClient.getEnvelope], bukan
  /// `getList`.
  static const String eprocurement = '/api/portal/apps/eprocurement';

  /// IT/Media Request — riwayat permintaan milik user sendiri. Daftar di
  /// path ini, detail satu request di `$itRequest/{id}`.
  ///
  /// Sama seperti [eprocurement], endpoint daftarnya menaruh `summary` dan
  /// `meta` bersebelahan dengan `data`, jadi harus diambil lewat
  /// [ApiClient.getEnvelope].
  static const String itRequest = '/api/portal/apps/it_request';
}
