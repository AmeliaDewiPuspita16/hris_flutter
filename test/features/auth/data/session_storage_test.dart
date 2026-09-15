import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/data/session_storage.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';

import '../../../fixtures/login_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureSessionStorage();
  });

  test('mengembalikan null saat belum ada sesi tersimpan', () async {
    expect(await storage.read(), isNull);
  });

  test('membaca kembali sesi yang baru ditulis', () async {
    final session = AuthSession.fromJson(loginResponseData());

    await storage.write(session);
    final restored = await storage.read();

    expect(restored, isNotNull);
    expect(restored!.token, session.token);
    expect(restored.tokenType, session.tokenType);
    expect(restored.user.email, 'ariputra@biie.co.id');
    expect(restored.user.roles, hasLength(8));
  });

  test('menimpa sesi lama saat menulis sesi baru', () async {
    await storage.write(AuthSession.fromJson(loginResponseData()));
    await storage.write(
      AuthSession.fromJson({
        'access_token': 'token-kedua',
        'user': {'id': 9, 'name': 'Orang Lain', 'email': 'lain@biie.co.id'},
      }),
    );

    final restored = await storage.read();

    expect(restored!.token, 'token-kedua');
    expect(restored.user.email, 'lain@biie.co.id');
  });

  test('clear menghapus sesi tersimpan', () async {
    await storage.write(AuthSession.fromJson(loginResponseData()));

    await storage.clear();

    expect(await storage.read(), isNull);
  });

  test('mengembalikan null saat isi penyimpanan rusak', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_session': 'bukan json sama sekali',
    });

    expect(await SecureSessionStorage().read(), isNull);
  });

  test('mengembalikan null saat sesi tersimpan tidak punya token', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_session': '{"user":{"id":1,"name":"A","email":"a@b.c"}}',
    });

    expect(await SecureSessionStorage().read(), isNull);
  });
}
