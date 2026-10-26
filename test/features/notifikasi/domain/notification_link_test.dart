import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/presentation/screens/indent_vehicle_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/est_request/presentation/screens/est_request_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_screen.dart';
import 'package:hris_mobile/features/notifikasi/domain/notification_link.dart';
import 'package:hris_mobile/features/notifikasi/presentation/notification_routes.dart';

void main() {
  group('NotificationLink.fromData', () {
    test('membaca payload FCM dari backend', () {
      final link = NotificationLink.fromData({
        'notification_id': '32',
        'module': 'eprocurement',
        'type': 'approval_needed',
        'id': '9',
        'audience': 'approver',
        'filter': 'pending_dgm',
      })!;

      expect(link.notificationId, 32);
      expect(link.module, NotificationLink.moduleEprocurement);
      expect(link.type, 'approval_needed');
      expect(link.refId, 9);
      expect(link.isApprover, isTrue);
      expect(link.filter, 'pending_dgm');
    });

    test('null untuk pesan tanpa module (mis. uji dari Firebase console)', () {
      expect(NotificationLink.fromData({'title': 'Test'}), isNull);
    });

    test('audience kosong dianggap requester, filter kosong jadi null', () {
      final link = NotificationLink.fromData({
        'module': 'it_request',
        'filter': '',
      })!;

      expect(link.audience, 'requester');
      expect(link.filter, isNull);
      expect(link.notificationId, isNull);
    });
  });

  group('NotificationRoutes.screenFor', () {
    NotificationLink link(String module, String audience, {String type = ''}) =>
        NotificationLink(
          module: module,
          type: type,
          audience: audience,
          filter: 'pending_hod',
        );

    test(
        'IT Request: approver ke tab Approve, handler ke List, pemohon ke Form',
        () {
      ItRequestTab tabFor(String audience) =>
          (NotificationRoutes.screenFor(link('it_request', audience))
                  as ItRequestScreen)
              .initialTab;

      expect(tabFor('approver'), ItRequestTab.approve);
      expect(tabFor('handler'), ItRequestTab.list);
      expect(tabFor('requester'), ItRequestTab.form);
    });

    test('EST Work Order: approver ke tab Approve HOD', () {
      final screen = NotificationRoutes.screenFor(
        link('est_work_order', 'approver'),
      ) as EstRequestScreen;

      expect(screen.initialTabIndex, 1);
    });

    test('Indent Vehicle: HOD, admin driver, dan driver ke tab masing-masing',
        () {
      IndentTab tabFor(String audience, String type) =>
          (NotificationRoutes.screenFor(
            link('indent_vehicle', audience, type: type),
          ) as IndentVehicleScreen)
              .initialTab;

      expect(
          tabFor('approver', 'approval_needed'), IndentTab.supervisorApproval);
      expect(tabFor('handler', 'new_task'), IndentTab.pendingAssignment);
      expect(tabFor('handler', 'trip_assigned'), IndentTab.requests);
      expect(tabFor('requester', 'approved'), IndentTab.requests);
    });

    test('eProcurement: approver langsung ke chip level-nya', () {
      final approver = NotificationRoutes.screenFor(
        link('eprocurement', 'approver'),
      ) as ProcurementPage;
      final requester = NotificationRoutes.screenFor(
        link('eprocurement', 'requester'),
      ) as ProcurementPage;

      expect(approver.initialStatusCode, 'pending_hod');
      expect(requester.initialStatusCode, isNull);
    });

    test('modul tidak dikenal tidak membuka apa-apa', () {
      expect(NotificationRoutes.screenFor(link('hse', 'approver')), isNull);
    });
  });
}
