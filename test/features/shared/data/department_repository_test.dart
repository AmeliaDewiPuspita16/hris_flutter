import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/shared/data/department_repository.dart';

void main() {
  DepartmentRepository repositoryThatResponds(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return DepartmentRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
    );
  }

  /// Respons sungguhan `GET /api/data/department`: hanya `data`, tanpa
  /// `code`/`status`/`message` seperti amplop endpoint login.
  http.Response departmentResponse() => http.Response(
        jsonEncode({
          'data': [
            {'id': 1, 'name': 'AML'},
            {'id': 11, 'name': 'BDD'},
            {'id': 7, 'name': 'CDD'},
            {'id': 8, 'name': 'HR & GA'},
            {'id': 17, 'name': 'ITM'},
          ],
        }),
        200,
      );

  test('membaca daftar departemen dari respons tanpa amplop status', () async {
    final repository = repositoryThatResponds((_) async => departmentResponse());

    final departments = await repository.getActiveDepartments();

    expect(departments, hasLength(5));
    expect(departments.first.id, 1);
    expect(departments.first.name, 'AML');
    expect(departments.last.name, 'ITM');
  });

  test('mempertahankan urutan dari server', () async {
    final repository = repositoryThatResponds((_) async => departmentResponse());

    final names = (await repository.getActiveDepartments())
        .map((d) => d.name)
        .toList();

    expect(names, ['AML', 'BDD', 'CDD', 'HR & GA', 'ITM']);
  });

  test('memanggil endpoint departemen dengan header Authorization', () async {
    late http.Request sent;
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        sent = request;
        return departmentResponse();
      }),
    )..setToken('9999|token-palsu');

    await DepartmentRepository(apiClient: apiClient).getActiveDepartments();

    expect(sent.url.path, '/api/data/department');
    expect(sent.headers['Authorization'], 'Bearer 9999|token-palsu');
  });

  test('mengembalikan daftar kosong saat server mengirim data kosong',
      () async {
    final repository = repositoryThatResponds(
      (_) async => http.Response(jsonEncode({'data': []}), 200),
    );

    expect(await repository.getActiveDepartments(), isEmpty);
  });

  test('tetap melempar sesi berakhir saat token ditolak', () async {
    final repository = repositoryThatResponds(
      (_) async => http.Response(
        jsonEncode({'message': 'Unauthenticated.'}),
        401,
      ),
    );

    await expectLater(
      repository.getActiveDepartments(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
      ),
    );
  });

  group('cache', () {
    test('tidak memanggil server lagi pada permintaan kedua', () async {
      var requestCount = 0;
      final repository = repositoryThatResponds((_) async {
        requestCount++;
        return departmentResponse();
      });

      await repository.getActiveDepartments();
      await repository.getActiveDepartments();

      expect(requestCount, 1);
    });

    test('mengembalikan isi yang sama dari cache', () async {
      final repository = repositoryThatResponds(
        (_) async => departmentResponse(),
      );

      final first = await repository.getActiveDepartments();
      final second = await repository.getActiveDepartments();

      expect(second.map((d) => d.name), first.map((d) => d.name));
    });

    test('tidak menyimpan hasil saat permintaan pertama gagal', () async {
      var requestCount = 0;
      final repository = repositoryThatResponds((_) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(jsonEncode({'message': 'Server error'}), 500);
        }
        return departmentResponse();
      });

      await expectLater(
        repository.getActiveDepartments(),
        throwsA(isA<ApiException>()),
      );
      final departments = await repository.getActiveDepartments();

      expect(requestCount, 2);
      expect(departments, hasLength(5));
    });

    test('hanya mengirim satu request saat dua pemanggil meminta bersamaan',
        () async {
      var requestCount = 0;
      final release = Completer<void>();
      final repository = repositoryThatResponds((_) async {
        requestCount++;
        await release.future;
        return departmentResponse();
      });

      final first = repository.getActiveDepartments();
      final second = repository.getActiveDepartments();
      release.complete();
      await Future.wait([first, second]);

      expect(requestCount, 1);
    });

    test('daftar yang dikembalikan tidak bisa diubah pemanggil', () async {
      final repository = repositoryThatResponds(
        (_) async => departmentResponse(),
      );

      final departments = await repository.getActiveDepartments();

      // Kalau bisa diubah, satu pemanggil yang menyortir atau menghapus isi
      // daftar akan merusak cache untuk semua pemanggil berikutnya.
      expect(() => departments.clear(), throwsUnsupportedError);
    });
  });

  test('tetap menolak amplop yang jelas menandai gagal', () async {
    final repository = repositoryThatResponds(
      (_) async => http.Response(
        jsonEncode({'status': 'error', 'message': 'Akun nonaktif', 'data': []}),
        200,
      ),
    );

    await expectLater(
      repository.getActiveDepartments(),
      throwsA(isA<ApiException>()),
    );
  });
}
