import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/auth/data/auth_repository.dart';
import 'package:hris_mobile/features/notifikasi/data/device_token_repository.dart';

import '../../../fixtures/login_response.dart';
import '../../../support/fake_session_storage.dart';

/// Pendaftaran FCM token ke server lewat AuthRepository: login, buka app
/// (restoreSession), token dirotasi, dan logout.
void main() {
  late FakeSessionStorage storage;
  late List<http.Request> sent;

  setUp(() {
    storage = FakeSessionStorage();
    sent = [];
  });

  /// [deviceStatus] = status HTTP untuk endpoint device-token.
  AuthRepository build({
    int deviceStatus = 200,
    bool withPush = true,
    String? currentToken = 'fcm-abc',
    Stream<String>? refreshes,
  }) {
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        sent.add(request);
        if (request.url.path == '/api/login') {
          return http.Response(jsonEncode(loginResponseEnvelope()), 200);
        }
        if (request.url.path == '/api/portal/apps/device-token') {
          return http.Response(jsonEncode({'message': 'ok'}), deviceStatus);
        }
        return http.Response(jsonEncode({'data': {}, 'message': 'ok'}), 200);
      }),
    );

    return AuthRepository(
      apiClient: apiClient,
      storage: storage,
      deviceTokens: withPush ? DeviceTokenRepository(apiClient: apiClient) : null,
      fcmToken: withPush ? () async => currentToken : null,
      fcmTokenRefreshes: refreshes,
    );
  }

  /// Pendaftaran berjalan tanpa di-await oleh login/restore.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<http.Request> deviceCalls() => [
        for (final r in sent)
          if (r.url.path == '/api/portal/apps/device-token') r,
      ];

  test('login mendaftarkan FCM token beserta platform', () async {
    final repository = build();

    await repository.login(
      email: 'ariputra@biie.co.id',
      password: 'rahasia',
      fcmToken: 'fcm-abc',
    );
    await settle();

    final call = deviceCalls().single;
    expect(call.method, 'POST');
    expect(call.headers['Authorization'], startsWith('Bearer '));
    expect(jsonDecode(call.body), {'token': 'fcm-abc', 'platform': 'android'});
  });

  test('login tetap berhasil walau pendaftaran token gagal', () async {
    final repository = build(deviceStatus: 500);

    final session = await repository.login(
      email: 'ariputra@biie.co.id',
      password: 'rahasia',
      fcmToken: 'fcm-abc',
    );
    await settle();

    expect(session.user.name, 'Ari Putra');
  });

  test('membuka app dengan sesi tersimpan mendaftarkan token terkini',
      () async {
    await build(withPush: false).login(
      email: 'ariputra@biie.co.id',
      password: 'rahasia',
    );
    sent.clear();

    await build(currentToken: 'fcm-baru').restoreSession();
    await settle();

    expect(jsonDecode(deviceCalls().single.body)['token'], 'fcm-baru');
  });

  test('token yang dirotasi didaftarkan ulang selama masih login', () async {
    final refreshes = StreamController<String>();
    final repository = build(refreshes: refreshes.stream);

    refreshes.add('fcm-sebelum-login');
    await settle();
    expect(deviceCalls(), isEmpty);

    await repository.login(email: 'ariputra@biie.co.id', password: 'rahasia');
    refreshes.add('fcm-rotasi');
    await settle();

    expect(jsonDecode(deviceCalls().single.body)['token'], 'fcm-rotasi');
    await refreshes.close();
  });

  test('logout mencabut token SEBELUM sesi dicabut di server', () async {
    final repository = build();
    await repository.login(
      email: 'ariputra@biie.co.id',
      password: 'rahasia',
      fcmToken: 'fcm-abc',
    );
    await settle();
    sent.clear();

    await repository.logout();

    expect(sent.first.method, 'DELETE');
    expect(sent.first.url.path, '/api/portal/apps/device-token');
    expect(sent.first.url.queryParameters['token'], 'fcm-abc');
    expect(sent.first.headers['Authorization'], startsWith('Bearer '));
    expect(sent.last.url.path, '/api/logout');
  });

  test('tanpa DeviceTokenRepository tidak ada panggilan device-token',
      () async {
    final repository = build(withPush: false);

    await repository.login(
      email: 'ariputra@biie.co.id',
      password: 'rahasia',
      fcmToken: 'fcm-abc',
    );
    await settle();
    await repository.logout();

    expect(deviceCalls(), isEmpty);
  });
}
