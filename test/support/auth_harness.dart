import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/auth/data/auth_repository.dart';

import '../fixtures/login_response.dart';
import 'fake_session_storage.dart';

/// Satu paket AuthRepository beserta bagian-bagian yang perlu diperiksa test.
class AuthHarness {
  AuthHarness._({
    required this.repository,
    required this.apiClient,
    required this.storage,
  });

  /// Membuat harness yang setiap request HTTP-nya dilayani [handler].
  /// Tanpa [handler], server selalu membalas login yang berhasil.
  factory AuthHarness({
    Future<http.Response> Function(http.Request request)? handler,
  }) {
    final storage = FakeSessionStorage();
    final apiClient = ApiClient(
      httpClient: MockClient(
        handler ?? (_) async => AuthHarness.successfulLoginResponse(),
      ),
    );
    return AuthHarness._(
      repository: AuthRepository(apiClient: apiClient, storage: storage),
      apiClient: apiClient,
      storage: storage,
    );
  }

  final AuthRepository repository;
  final ApiClient apiClient;
  final FakeSessionStorage storage;

  static http.Response successfulLoginResponse() =>
      http.Response(jsonEncode(loginResponseEnvelope()), 200);

  static http.Response unauthorizedResponse() => http.Response(
        jsonEncode({'status': 'error', 'message': 'Invalid credentials'}),
        401,
      );
}
