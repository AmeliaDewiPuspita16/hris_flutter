import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/record/ims_document/master_document_file/data/master_document_repository.dart';

/// Bentuk respons sesuai dokumentasi backend: paginasi Laravel bawaan.
Map<String, dynamic> documentsPage() => {
      'current_page': 1,
      'data': [
        {
          'id': 1237,
          'no_document': 'BIIE-HM-001 Rev 4',
          'title': 'Sistem Jaminan Produk Halal',
          'category': 'Manual',
          'department': 'IMS',
          'is_pdf': true,
          'has_obsolete': true,
          'pdf_url': 'http://127.0.0.1:8000/api/record/ims/documents/1237/pdf',
          'updated_at': '2026-08-04T16:34:39+07:00',
        },
        {
          'id': 1300,
          'no_document': 'BIIE-FT-001',
          'title': 'Form Template',
          'category': 'Form Template',
          'department': 'HSE',
          'is_pdf': false,
          'has_obsolete': false,
          'pdf_url': null,
          'updated_at': '2026-04-23T16:38:56+07:00',
        },
      ],
      'last_page': 9,
      'per_page': 2,
      'total': 18,
    };

void main() {
  ({MasterDocumentRepository repository, List<Uri> requests}) build(
    Object body, {
    int statusCode = 200,
  }) {
    final requests = <Uri>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request.url);
        return http.Response(jsonEncode(body), statusCode,
            headers: {'content-type': 'application/json'});
      }),
    )..setToken('abc');
    return (repository: MasterDocumentRepository(apiClient: client), requests: requests);
  }

  test('fetchDocuments mengirim kategori, halaman, dan kata kunci', () async {
    final (:repository, :requests) = build(documentsPage());

    await repository.fetchDocuments(category: 'manual', page: 2, search: ' halal ');

    expect(requests.single.path, ApiConfig.imsDocuments);
    expect(requests.single.queryParameters, {
      'category': 'manual',
      'page': '2',
      'per_page': '50',
      'search': 'halal',
    });
  });

  test('fetchDocuments tidak mengirim search kosong', () async {
    final (:repository, :requests) = build(documentsPage());

    await repository.fetchDocuments(category: 'sop');

    expect(requests.single.queryParameters.containsKey('search'), isFalse);
  });

  test('fetchDocuments membaca baris dan paginasi Laravel', () async {
    final (:repository, requests: _) = build(documentsPage());

    final page = await repository.fetchDocuments(category: 'manual');

    expect(page.meta.currentPage, 1);
    expect(page.meta.lastPage, 9);
    expect(page.meta.total, 18);
    expect(page.meta.hasMore, isTrue);

    final first = page.items.first;
    expect(first.id, 1237);
    expect(first.docNo, 'BIIE-HM-001 Rev 4');
    expect(first.hierarchy, 'IMS');
    expect(first.isPdf, isTrue);
    expect(first.updatedAt, DateTime.parse('2026-08-04T16:34:39+07:00').toLocal());
    // Host 127.0.0.1 dari server diganti base URL aplikasi.
    expect(first.viewUrl, '${ApiConfig.baseUrl}/api/record/ims/documents/1237/pdf');

    final template = page.items.last;
    expect(template.isPdf, isFalse);
  });

  test('fetchCategories membaca list kategori', () async {
    final (:repository, :requests) = build({
      'data': [
        {'key': 'manual', 'label': 'Manual', 'count': 18},
        {'key': 'form_template', 'label': 'Form Template', 'count': 4},
      ],
    });

    final categories = await repository.fetchCategories();

    expect(requests.single.path, ApiConfig.imsDocumentCategories);
    expect(categories.map((c) => c.key), ['manual', 'form_template']);
    expect(categories.first.label, 'Manual');
    expect(categories.first.count, 18);
  });

  test('403 Daily Worker diteruskan dengan pesan server', () async {
    final (:repository, requests: _) = build(
      {'message': 'This account does not have access to IMS documents.'},
      statusCode: 403,
    );

    expect(
      repository.fetchDocuments(category: 'manual'),
      throwsA(isA<ApiException>().having(
        (e) => e.message,
        'message',
        'This account does not have access to IMS documents.',
      )),
    );
  });

  test('pdfHeaders memuat token login', () {
    final (:repository, requests: _) = build(const {});

    expect(repository.pdfHeaders['Authorization'], 'Bearer abc');
  });
}
