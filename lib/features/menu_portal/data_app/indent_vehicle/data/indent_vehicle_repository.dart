import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../domain/indent_driver.dart';

/// pintu ke API Indent Vehicle. Repository ini akan bertambah satu method
/// untuk tiap endpoint yang kita sambungkan.
class IndentVehicleRepository {
  IndentVehicleRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<IndentDriver>> fetchDrivers() async {
    final raw = await _apiClient.getRawList(ApiConfig.indentDrivers);
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) IndentDriver.fromJson(item),
    ];
  }
}
