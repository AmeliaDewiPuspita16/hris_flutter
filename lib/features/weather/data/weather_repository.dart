import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../domain/weather_forecast.dart';

/// Prakiraan cuaca kawasan dari backend portal (yang mengambil & meng-cache
/// data BMKG). Tidak tahu soal HTTP — itu urusan [ApiClient].
class WeatherRepository {
  WeatherRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Melempar [ApiException] bila gagal atau respons tidak dikenali.
  Future<WeatherForecast> fetchForecast() async {
    // getEnvelope, bukan get: `meta` (source, stale) ada sejajar `data`.
    final envelope = await _apiClient.getEnvelope(ApiConfig.weather);
    try {
      return WeatherForecast.fromEnvelope(envelope);
    } on FormatException {
      throw const ApiException.server(
        'The weather forecast could not be read.',
      );
    }
  }
}
