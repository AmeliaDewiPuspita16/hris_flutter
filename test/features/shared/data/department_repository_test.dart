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
