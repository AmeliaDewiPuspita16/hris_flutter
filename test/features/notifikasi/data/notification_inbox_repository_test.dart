import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/notifikasi/data/notification_inbox_repository.dart';
import 'package:hris_mobile/features/notifikasi/domain/notification_category.dart';

/// Bentuk `GET /api/portal/apps/notifications` dari backend.
Map<String, dynamic> inboxEnvelope({int unread = 3}) => {
      'data': [
        {
          'id': 32,
          'module': 'eprocurement',
          'type': 'approval_needed',
          'reference_id': 9,
          'title': 'PR PR/AML/26-09/01 awaiting your approval',
          'body': 'HOD approval: Retribusi PBG',
          'data': {
            'notification_id': '32',
            'module': 'eprocurement',
            'type': 'approval_needed',
            'id': '9',
            'audience': 'approver',
            'filter': 'pending_hod',
          },
          'is_read': false,
          'read_at': null,
          'created_at': '2026-10-26T10:39:25+07:00',
        },
        {
          'id': 31,
          'module': 'it_request',
          'type': 'completed',
          'reference_id': 2419,
          'title': 'Your IT request is completed',
          'body': 'Please rate the service',
          'data': {
            'notification_id': '31',
            'module': 'it_request',
            'type': 'completed',
            'id': '2419',
            'audience': 'requester',
          },
          'is_read': true,
          'read_at': '2026-10-26T09:00:00+07:00',
          'created_at': '2026-10-26T08:00:00+07:00',
        },
      ],
      'summary': {'unread': unread},
      'meta': {'current_page': 1, 'last_page': 1, 'per_page': 50, 'total': 2},
    };

void main() {
  ({NotificationInboxRepository repository, List<http.Request> sent}) build({
    int statusCode = 200,
    Map<String, dynamic>? body,
  }) {
    final sent = <http.Request>[];
    final client = MockClient((request) async {
      sent.add(request);
      return http.Response(jsonEncode(body ?? inboxEnvelope()), statusCode);
    });

    return (
      repository: NotificationInboxRepository(
        apiClient: ApiClient(httpClient: client),
      ),
      sent: sent,
    );
  }

  group('fetchLatest', () {
    test('memanggil endpoint notifikasi dengan per_page', () async {
      final built = build();

      await built.repository.fetchLatest();

      expect(built.sent.single.method, 'GET');
      expect(built.sent.single.url.path, '/api/portal/apps/notifications');
      expect(built.sent.single.url.queryParameters['per_page'], '50');
    });

    test('memetakan baris server ke AppNotification', () async {
      final page = await build().repository.fetchLatest();

      final pr = page.items.first;
      expect(pr.id, 'srv-32');
      expect(pr.serverId, 32);
      expect(pr.isFromServer, isTrue);
      expect(pr.category, NotificationCategory.procurement);
      expect(pr.title, 'PR PR/AML/26-09/01 awaiting your approval');
      expect(pr.isRead, isFalse);
      expect(pr.refId, '9');
      expect(pr.link!.isApprover, isTrue);
      expect(pr.link!.filter, 'pending_hod');

      final it = page.items.last;
      expect(it.category, NotificationCategory.itRequest);
      expect(it.isRead, isTrue);
      expect(it.link!.audience, 'requester');
    });

    test('notifikasi server tidak pernah menunggu Approve/Reject di tab',
        () async {
      final page = await build().repository.fetchLatest();

      expect(page.items.any((n) => n.needsAction), isFalse);
    });

    test('mengambil jumlah belum dibaca dari summary', () async {
      final page = await build(body: inboxEnvelope(unread: 7))
          .repository
          .fetchLatest();

      expect(page.unread, 7);
    });

    test('melempar ApiException saat server gagal', () {
      final built = build(statusCode: 500, body: {'message': 'Server error'});

      expect(built.repository.fetchLatest(), throwsA(isA<ApiException>()));
    });
  });

  test('markRead mengirim POST ke endpoint read milik notifikasi itu',
      () async {
    final built = build(body: {'message': 'ok'});

    await built.repository.markRead(32);

    expect(built.sent.single.method, 'POST');
    expect(
      built.sent.single.url.path,
      '/api/portal/apps/notifications/32/read',
    );
  });

  test('markAllRead mengirim POST ke read-all', () async {
    final built = build(body: {'message': 'ok'});

    await built.repository.markAllRead();

    expect(
      built.sent.single.url.path,
      '/api/portal/apps/notifications/read-all',
    );
  });

  test('delete mengirim DELETE ke notifikasi itu', () async {
    final built = build(body: {'message': 'ok'});

    await built.repository.delete(32);

    expect(built.sent.single.method, 'DELETE');
    expect(built.sent.single.url.path, '/api/portal/apps/notifications/32');
  });
}
