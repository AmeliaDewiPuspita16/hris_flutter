import 'package:hris_mobile/features/auth/data/session_storage.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';

/// Penyimpanan sesi di memori, supaya test repository dan bloc tidak perlu
/// menyentuh Keychain sungguhan.
class FakeSessionStorage implements SessionStorage {
  FakeSessionStorage([this.session]);

  AuthSession? session;

  /// Berapa kali [clear] dipanggil — dipakai untuk memastikan logout benar
  /// membersihkan penyimpanan meski isinya memang sudah kosong.
  int clearCount = 0;

  /// Membuat [read] melempar, meniru Keychain yang tidak bisa diakses.
  bool failOnRead = false;

  @override
  Future<AuthSession?> read() async {
    if (failOnRead) throw StateError('Penyimpanan tidak bisa dibaca');
    return session;
  }

  @override
  Future<void> write(AuthSession session) async => this.session = session;

  @override
  Future<void> clear() async {
    clearCount++;
    session = null;
  }
}
