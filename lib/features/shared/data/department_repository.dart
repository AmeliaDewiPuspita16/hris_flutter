import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/department.dart';

/// Sumber data departemen aktif. Tidak tahu soal HTTP — itu urusan
/// [ApiClient], termasuk membuka amplop `ResponseFormatter` dan menyertakan
/// header `Authorization`.
///
/// Hasilnya disimpan di memori setelah pengambilan pertama yang berhasil.
/// Daftar departemen adalah data referensi yang praktis tidak berubah selama
/// aplikasi berjalan, sementara form pengumuman bisa dibuka berkali-kali —
/// tanpa cache, tiap pembukaan berarti satu request dan satu spinner.
class DepartmentRepository {
  DepartmentRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Hasil yang sudah berhasil diambil. Null berarti belum pernah.
  List<Department>? _cached;

  /// Pengambilan yang sedang berjalan, dipakai bersama oleh pemanggil yang
  /// datang bersamaan supaya tidak ada dua request untuk data yang sama.
  Future<List<Department>>? _inFlight;

  /// Departemen dengan `is_active = 1`, sudah diurutkan menurut nama oleh
  /// server — tidak perlu difilter atau diurutkan ulang di sini.
  ///
  /// Melempar [ApiException] bila gagal (jaringan, sesi berakhir, dll).
  /// Kegagalan tidak pernah disimpan, jadi percobaan berikutnya benar-benar
  /// menghubungi server lagi.
  Future<List<Department>> getActiveDepartments() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);

    return _inFlight ??= _fetch();
  }

  Future<List<Department>> _fetch() async {
    try {
      final data = await _apiClient.getList(ApiConfig.department);
      final departments = List<Department>.unmodifiable(
        data.whereType<Map<String, dynamic>>().map(Department.fromJson),
      );
      _cached = departments;
      return departments;
    } finally {
      _inFlight = null;
    }
  }
}
