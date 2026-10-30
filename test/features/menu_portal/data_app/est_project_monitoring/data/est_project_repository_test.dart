import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/data_app/est_project_monitoring/data/est_project_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../../../fixtures/est_project_response.dart';

void main() {
  late List<http.Request> seen;
  late Map<String, dynamic> reply;

  EstProjectRepository build({int status = 200}) {
    seen = [];
    return EstProjectRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          seen.add(request);
          return http.Response(jsonEncode(reply), status);
        }),
      ),
    );
  }

  setUp(() => reply = {});

  test('fetchExecutiveDashboard GET dan parse seluruh badan', () async {
    reply = estExecutiveDashboardJson;
    final dashboard = await build().fetchExecutiveDashboard();

    expect(seen.single.method, 'GET');
    expect(seen.single.url.path, '/api/est/dashboard/executive');
    expect(dashboard.projects, hasLength(2));
  });

  test('fetchExecutiveDashboard 403 -> unauthorized', () async {
    reply = {'message': 'forbidden'};
    await expectLater(
      build(status: 403).fetchExecutiveDashboard(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
      ),
    );
  });

  test('openSession POST body kosong', () async {
    await build().openSession(3);

    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects/3/sessions/open');
    expect(jsonDecode(seen.single.body), <String, dynamic>{});
  });

  test('closeSession tanpa foto kirim JSON', () async {
    await build().closeSession(3, description: 'ok', autoClockOut: true);

    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects/3/sessions/close');
    expect(
      jsonDecode(seen.single.body),
      {'description': 'ok', 'auto_clock_out': true},
    );
  });

  test('closeSession dengan foto kirim multipart', () async {
    final dir = Directory.systemTemp.createTempSync('est_repo');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);

    await build().closeSession(
      3,
      description: 'ok',
      autoClockOut: false,
      photoPaths: [file.path],
    );

    final request = seen.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/est/projects/3/sessions/close');
    expect(request.headers['content-type'], startsWith('multipart/form-data'));
    expect(request.body, contains('name="photos[]"'));
    expect(request.body, contains('name="auto_clock_out"'));
    expect(request.body, contains('\r\n\r\n0\r\n'));
    expect(request.body, contains('name="description"'));
  });

  test('fetchProjectDetail GET lalu parse', () async {
    reply = estExecProjectFullJson;
    final detail = await build().fetchProjectDetail(1);

    expect(seen.single.method, 'GET');
    expect(seen.single.url.path, '/api/est/projects/1');
    expect(detail.mandors.single.name, 'Siti Aminah');
  });

  test('fetchProjectWorkers membaca data, {} -> []', () async {
    reply = {};
    expect(await build().fetchProjectWorkers(1), isEmpty);
    expect(seen.single.url.path, '/api/est/projects/1/workers');

    reply = {
      'data': [estProjectWorkerJson]
    };
    final workers = await build().fetchProjectWorkers(1);
    expect(workers.single.name, 'Andi Pratama');
  });

  test('assignWorkers POST worker_ids dan mengembalikan balasan', () async {
    reply = {'message': 'ok'};
    final result = await build().assignWorkers(1, [4, 5]);

    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects/1/assign');
    expect(jsonDecode(seen.single.body), {
      'worker_ids': [4, 5]
    });
    expect(result['message'], 'ok');
  });

  test('transferWorkers kirim kunci DW, reason hanya bila diisi', () async {
    await build().transferWorkers(
      1,
      targetProjectId: 2,
      workerIds: [4],
    );
    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects/1/workers/transfer');
    expect(
      jsonDecode(seen.single.body),
      {
        'worker_ids': [4],
        'target_project_id': 2
      },
    );

    await build().transferWorkers(
      1,
      targetProjectId: 2,
      workerIds: [4],
      reason: 'butuh',
    );
    expect(jsonDecode(seen.single.body)['reason'], 'butuh');
  });

  test('requestCloseProject POST close', () async {
    await build().requestCloseProject(1);

    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects/1/close');
  });

  test('assignSubstitute POST body apa adanya', () async {
    final body = {'role': 'mandor', 'substitute_for': 4, 'user_id': 5};
    await build().assignSubstitute(1, body);

    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects/1/substitute');
    expect(jsonDecode(seen.single.body), body);
  });

  test('endSubstitute DELETE', () async {
    await build().endSubstitute(1, 33);

    expect(seen.single.method, 'DELETE');
    expect(seen.single.url.path, '/api/est/projects/1/substitute/33');
  });

  test('fetchMandors GET dan parse', () async {
    reply = {
      'data': [estEmployeeMandorJson]
    };
    final mandors = await build().fetchMandors();

    expect(seen.single.url.path, '/api/est/resources/mandors');
    expect(mandors.single.name, 'Siti Aminah');
  });

  test('fetchAvailableWorkers dan fetchAllWorkers meneruskan query', () async {
    reply = {
      'data': [estAvailableWorkerJson]
    };
    final available = await build()
        .fetchAvailableWorkers(query: {'project_id': '1', 'search': 'de'});
    expect(seen.single.url.path, '/api/est/resources/workers/available');
    expect(
        seen.single.url.queryParameters, {'project_id': '1', 'search': 'de'});
    expect(available.single.name, 'Dewi');

    final all = await build().fetchAllWorkers();
    expect(seen.single.url.path, '/api/est/resources/workers/all');
    expect(all.single.name, 'Dewi');
  });

  test('fetchActiveProjects membaca data, fallback projects', () async {
    reply = {
      'data': [estExecutiveProjectJson]
    };
    expect(await build().fetchActiveProjects(), hasLength(1));
    expect(seen.single.url.path, '/api/est/projects');

    reply = {
      'projects': [estExecutiveProjectJson, estExecutiveProjectMinimalJson]
    };
    expect(await build().fetchActiveProjects(), hasLength(2));
  });

  test('createProject POST dan updateProject PUT', () async {
    await build().createProject({'name': 'A'});
    expect(seen.single.method, 'POST');
    expect(seen.single.url.path, '/api/est/projects');
    expect(jsonDecode(seen.single.body), {'name': 'A'});

    await build().updateProject(8, {'name': 'B'});
    expect(seen.single.method, 'PUT');
    expect(seen.single.url.path, '/api/est/projects/8');
    expect(jsonDecode(seen.single.body), {'name': 'B'});
  });

  test('fetchSubstituteCandidates membaca id longgar dan nama default',
      () async {
    reply = {
      'data': [
        {'user_id': 7, 'name': 'Budi'},
        {'worker_id': 8},
        {'id': 9, 'user_id': 1, 'name': 'Cici'},
      ],
    };
    final mandors = await build().fetchSubstituteCandidates(mandor: true);

    expect(seen.single.url.path, '/api/est/resources/mandors');
    expect(mandors.map((c) => c.id), [7, 8, 9]);
    expect(mandors.map((c) => c.name), ['Budi', '-', 'Cici']);

    final workers = await build().fetchSubstituteCandidates(mandor: false);
    expect(seen.single.url.path, '/api/est/resources/workers/all');
    expect(workers, hasLength(3));
  });
}
