import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/department.dart';

/// Sumber data departemen aktif. Tidak tahu soal HTTP — itu urusan
/// [ApiClient], termasuk membuka amplop `ResponseFormatter` dan menyertakan
/// header `Authorization`.
class DepartmentRepository {
  DepartmentRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Departemen dengan `is_active = 1`, sudah diurutkan menurut nama oleh
  /// server — tidak perlu difilter atau diurutkan ulang di sini.
  ///
  /// Melempar [ApiException] bila gagal (jaringan, sesi berakhir, dll).
  Future<List<Department>> getActiveDepartments() async {
    final data = await _apiClient.getList(ApiConfig.department);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Department.fromJson)
        .toList();
  }
}
