import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/hse_work_request/data/hse_work_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/hse_work_request/domain/hse_request_category.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/hse_work_request/domain/hse_request_status.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/hse_work_request/domain/hse_work_request.dart';

/// Respons diambil dari contoh dokumentasi API `hse_permit`.
Map<String, dynamic> _permitJson({
  int id = 162,
  String category = 'RUTIN',
  String status = 'waiting',
  String statusLabel = 'Waiting Approval HOD',
  Map<String, dynamic>? documents,
  Map<String, dynamic>? closing,
}) =>
    {
      'id': id,
      'id_register': 'HSE/REG/2026/11/001',
      'requester': 'Rani Apriyanti',
      'pic': 'Alen Pepa',
      'department_id': 6,
      'department': 'IMS',
      'section': null,
      'category': category,
      'category_label': 'Routine (maintenance, repair)',
      'location': 'STP 1, Dorm Kawasan BIE',
      'materials': 'Tabung gas, blower',
      'vendor': 'PT Maju Jaya',
      'total_workers': 2,
      'date_start': '2026-11-05',
      'date_end': '2026-11-06',
      'acknowledge_by': null,
      'approval_by': null,
      'status': status,
      'status_label': statusLabel,
      'is_mine': true,
      'can_delete': true,
      'can_close': false,
      'created_at': '2026-11-02 16:06:31',
      'general_checklist': ['Melakukan briefing kerja', 'ROA'],
      'other_general_checklist': 'Gas test sebelum masuk',
      'type_of_works': ['Confined space'],
      'other_type_of_work': null,
      'ppe': ['Helm Safety', 'Full body harness'],
      'other_ppe': null,
      'documents':
          documents ?? {'jsa': null, 'timeline': null, 'soft_drawing': null},
      'closing': closing,
    };

class _Captured {
  late http.BaseRequest request;
  late String body;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hse_permit_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ({HseWorkRequestRepository repo, _Captured captured}) build(
    Object response, {
    int statusCode = 200,
  }) {
    final captured = _Captured();
    final mock = MockClient.streaming((request, bodyStream) async {
      captured
        ..request = request
        ..body = utf8.decode(await bodyStream.toBytes());
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(response))),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    });
    return (
      repo: HseWorkRequestRepository(apiClient: ApiClient(httpClient: mock)),
      captured: captured,
    );
  }

  Future<String> writeFile(String name) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(List.filled(32, 1));
    return file.path;
  }

  HsePermitDraft draft({Map<String, String> documents = const {}}) =>
      HsePermitDraft(
        pic: ' Alen Pepa ',
        departmentId: 3,
        section: 'STP',
        categoryCode: documents.isEmpty ? 'RUTIN' : 'NON-RUTIN',
        location: 'STP 1',
        materials: 'Tabung gas',
        vendor: '',
        totalWorkers: 2,
        dateStart: DateTime(2026, 11, 5),
        dateEnd: DateTime(2026, 11, 6),
        generalChecklist: const ['Melakukan briefing kerja', 'ROA'],
        otherGeneralChecklist: 'Gas test',
        typeOfWorks: const ['Confined space'],
        ppe: const ['Helm Safety', 'Full body harness'],
        documents: documents,
      );

  group('fetchOptions', () {
    test('memetakan opsi form, section EST, dan aturan dokumen', () async {
      final (:repo, :captured) = build({
        'data': {
          'categories': [
            {'code': 'RUTIN', 'label': 'Routine (maintenance, repair)'},
            {'code': 'NON-RUTIN', 'label': 'Non-routine (project & new work)'},
          ],
          'departments': [
            {'id': 1, 'name': 'AML'},
            {'id': 3, 'name': 'EST'},
          ],
          'sections': {
            'department_id': 3,
            'options': ['Nursery', 'Building'],
          },
          'general_checklist': ['Terdapat soft drawing'],
          'type_of_works': ['Hot work'],
          'ppe': ['Helm Safety'],
          'documents': {
            'fields': ['jsa', 'timeline', 'soft_drawing'],
            'required_for': 'NON-RUTIN',
            'extensions': ['pdf'],
            'max_kb': 10240,
          },
        },
      });

      final options = await repo.fetchOptions();

      expect(captured.request.url.path, '/api/portal/apps/hse_permit/options');
      expect(options.categories.last.code, 'NON-RUTIN');
      expect(options.departmentName(3), 'EST');
      expect(options.hasSections(3), isTrue);
      expect(options.hasSections(1), isFalse);
      expect(options.requiresDocuments('NON-RUTIN'), isTrue);
      expect(options.requiresDocuments('RUTIN'), isFalse);
      expect(options.documentFields, ['jsa', 'timeline', 'soft_drawing']);
      expect(options.documentMaxKb, 10240);
    });
  });

  group('fetchPermits', () {
    test('mengirim filter status & mine, membaca meta', () async {
      final (:repo, :captured) = build({
        'data': [
          _permitJson(id: 163, category: 'NON-RUTIN'),
        ],
        'meta': {
          'current_page': 1,
          'last_page': 2,
          'per_page': 20,
          'total': 21
        },
      });

      final page = await repo.fetchPermits(
        status: HseRequestStatus.onProgress,
        mine: true,
      );

      final query = captured.request.url.queryParameters;
      expect(query['status'], 'on_progress');
      expect(query['mine'], '1');
      expect(query['per_page'], '20');
      expect(page.items.single.id, 163);
      expect(page.items.single.category, HseRequestCategory.nonRutin);
      expect(page.meta.hasMore, isTrue);
    });

    test('tanpa filter tidak mengirim status', () async {
      final (:repo, :captured) = build({'data': [], 'meta': {}});
      await repo.fetchPermits();
      expect(
          captured.request.url.queryParameters.containsKey('status'), isFalse);
      expect(captured.request.url.queryParameters.containsKey('mine'), isFalse);
    });
  });

  group('fetchDetail', () {
    test('memetakan dokumen dan closing; dokumen null dibuang', () async {
      final (:repo, :captured) = build({
        'data': _permitJson(
          status: 'done',
          statusLabel: 'Done',
          documents: {
            'jsa': 'https://biieportal.co.id/storage/hse/a.pdf',
            'timeline': null,
          },
          closing: {
            'description': 'Pekerjaan selesai',
            'evidence_url': 'https://biieportal.co.id/storage/hse/done.jpg',
            'closed_at': '2026-11-02 16:06:31',
          },
        ),
      });

      final permit = await repo.fetchDetail(162);

      expect(captured.request.url.path, '/api/portal/apps/hse_permit/162');
      expect(permit.status, HseRequestStatus.done);
      expect(permit.documents.keys, ['jsa']);
      expect(permit.closing?.description, 'Pekerjaan selesai');
      expect(permit.closing?.closedAt, DateTime(2026, 11, 2, 16, 6, 31));
      expect(permit.generalChecklist, ['Melakukan briefing kerja', 'ROA']);
      expect(permit.canDelete, isTrue);
    });
  });

  group('submit', () {
    test('RUTIN dikirim multipart dengan array berindeks', () async {
      final (:repo, :captured) = build(
        {'message': 'HSE work permit submitted.', 'data': _permitJson()},
        statusCode: 201,
      );

      final result = await repo.submit(draft());

      expect(captured.request.method, 'POST');
      expect(captured.request.url.path, '/api/portal/apps/hse_permit');
      final fields = (captured.request as http.MultipartRequest).fields;
      expect(fields['pic'], 'Alen Pepa');
      expect(fields['department_id'], '3');
      expect(fields['section'], 'STP');
      expect(fields['category'], 'RUTIN');
      expect(fields['date_start'], '2026-11-05');
      expect(fields['general_checklist[0]'], 'Melakukan briefing kerja');
      expect(fields['general_checklist[1]'], 'ROA');
      expect(fields['ppe[1]'], 'Full body harness');
      expect(fields.containsKey('vendor'), isFalse, reason: 'vendor kosong');
      expect(fields.containsKey('other_ppe'), isFalse);
      expect(result.message, 'HSE work permit submitted.');
      expect(result.permit.idRegister, 'HSE/REG/2026/11/001');
    });

    test('NON-RUTIN melampirkan ketiga PDF', () async {
      final (:repo, :captured) = build(
        {'message': 'ok', 'data': _permitJson(category: 'NON-RUTIN')},
        statusCode: 201,
      );

      await repo.submit(draft(documents: {
        'jsa': await writeFile('jsa.pdf'),
        'timeline': await writeFile('timeline.pdf'),
        'soft_drawing': await writeFile('drawing.pdf'),
      }));

      final files = (captured.request as http.MultipartRequest).files;
      expect(files.map((f) => f.field), ['jsa', 'timeline', 'soft_drawing']);
      expect(files.first.filename, 'jsa.pdf');
    });

    test('422 dilempar dengan pesan validasi pertama', () async {
      final (:repo, captured: _) = build(
        {
          'message': 'The JSA document (PDF) is required for NON-RUTIN '
              'permits. (and 2 more errors)',
          'errors': {
            'jsa': [
              'The JSA document (PDF) is required for NON-RUTIN permits.'
            ],
          },
        },
        statusCode: 422,
      );

      expect(
        () => repo.submit(draft()),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.badRequest)
            .having(
              (e) => e.message,
              'message',
              'The JSA document (PDF) is required for NON-RUTIN permits.',
            )),
      );
    });
  });

  group('approvals', () {
    test('membaca summary per stage dan mengirim stage', () async {
      final (:repo, :captured) = build({
        'data': [_permitJson(id: 163)],
        'summary': {'hod': 2, 'hse': 1},
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 100,
          'total': 1
        },
      });

      final page = await repo.fetchApprovals(stage: 'hod');

      expect(
          captured.request.url.path, '/api/portal/apps/hse_permit/approvals');
      expect(captured.request.url.queryParameters['stage'], 'hod');
      expect(page.summary, {'hod': 2, 'hse': 1});
      expect(page.summaryTotal, 3);
    });

    test('403 untuk akun bukan approver -> unauthorized', () async {
      final (:repo, captured: _) = build(
        {
          'message':
              'This account does not have HSE work permit approval access.',
        },
        statusCode: 403,
      );

      expect(
        repo.fetchApprovals(),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
      );
    });

    test('approve mengembalikan pesan dan permit terbaru', () async {
      final (:repo, :captured) = build({
        'message': 'HSE work permit approved.',
        'data': _permitJson(status: 'on_progress', statusLabel: 'On Progress'),
      });

      final result = await repo.approve(162);

      expect(captured.request.method, 'POST');
      expect(
          captured.request.url.path, '/api/portal/apps/hse_permit/162/approve');
      expect(result.message, 'HSE work permit approved.');
      expect(result.permit.status, HseRequestStatus.onProgress);
    });

    test('approve 422 meneruskan pesan server', () async {
      final (:repo, captured: _) = build(
        {'message': 'This permit is not waiting for your approval.'},
        statusCode: 422,
      );

      expect(
        repo.approve(162),
        throwsA(isA<ApiException>().having((e) => e.message, 'message',
            'This permit is not waiting for your approval.')),
      );
    });

    test('reject memanggil endpoint reject', () async {
      final (:repo, :captured) = build({
        'message': 'HSE work permit rejected.',
        'data': _permitJson(status: 'reject', statusLabel: 'Reject'),
      });

      final result = await repo.reject(164);

      expect(
          captured.request.url.path, '/api/portal/apps/hse_permit/164/reject');
      expect(result.permit.status, HseRequestStatus.reject);
    });
  });

  group('close & delete', () {
    test('close mengirim deskripsi dan evidence', () async {
      final (:repo, :captured) = build({
        'message': 'HSE work permit closed.',
        'data': _permitJson(status: 'done', statusLabel: 'Done'),
      });

      final result = await repo.close(
        162,
        description: '  Selesai  ',
        evidencePath: await writeFile('done.jpg'),
      );

      final request = captured.request as http.MultipartRequest;
      expect(request.url.path, '/api/portal/apps/hse_permit/162/close');
      expect(request.fields['description'], 'Selesai');
      expect(request.files.single.field, 'evidence');
      expect(result.permit.status, HseRequestStatus.done);
    });

    test('delete mengembalikan pesan server', () async {
      final (:repo, :captured) = build({'message': 'HSE work permit deleted.'});

      final message = await repo.delete(162);

      expect(captured.request.method, 'DELETE');
      expect(captured.request.url.path, '/api/portal/apps/hse_permit/162');
      expect(message, 'HSE work permit deleted.');
    });
  });
}
