import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

/// Mendaftarkan FCM token perangkat ini ke backend supaya push notification
/// sampai ke user yang sedang login, dan mencabutnya saat logout.
///
/// Melempar [ApiException] bila gagal — pemanggil (AuthRepository) yang
/// memutuskan kegagalan ini tidak boleh menggagalkan login/logout.
class DeviceTokenRepository {
  DeviceTokenRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> register(String token) => _apiClient.postAction(
        ApiConfig.deviceToken,
        body: {'token': token, 'platform': _platform},
      );

  /// Lewat query string karena [ApiClient.delete] tidak mengirim body.
  Future<void> unregister(String token) => _apiClient.delete(
        '${ApiConfig.deviceToken}?token=${Uri.encodeQueryComponent(token)}',
      );

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'ios',
      _ => 'android',
    };
  }
}
