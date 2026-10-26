import 'package:flutter/widgets.dart';

import '../../menu_portal/data_app/indent_vehicle/presentation/screens/indent_vehicle_screen.dart';
import '../../menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';
import '../../menu_portal/onlineapps/work_order/est_request/presentation/screens/est_request_screen.dart';
import '../../menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_screen.dart';
import '../domain/notification_link.dart';

/// Layar yang dibuka saat notifikasi server di-tap.
///
/// Layar detail tiap modul butuh objek lengkapnya, bukan sekadar id, jadi
/// yang dibuka adalah halaman modulnya, langsung di tab yang relevan untuk
/// [NotificationLink.audience] — tab yang sama dengan yang dipakai banner
/// "Approvals waiting" di Beranda.
class NotificationRoutes {
  const NotificationRoutes._();

  /// Null kalau modulnya tidak dikenal (mis. pesan uji dari Firebase
  /// console) — cukup ditandai sudah dibaca.
  static Widget? screenFor(NotificationLink link) => switch (link.module) {
        NotificationLink.moduleItRequest => ItRequestScreen(
            initialTab: link.isApprover
                ? ItRequestTab.approve
                : link.isHandler
                    ? ItRequestTab.list
                    : ItRequestTab.form,
          ),
        // Tab 1 = Approve HOD, 0 = All Request.
        NotificationLink.moduleEstWorkOrder =>
          EstRequestScreen(initialTabIndex: link.isApprover ? 1 : 0),
        NotificationLink.moduleIndentVehicle =>
          IndentVehicleScreen(initialTab: _indentTab(link)),
        NotificationLink.moduleEprocurement => ProcurementPage(
            initialStatusCode: link.isApprover ? link.filter : null,
          ),
        _ => null,
      };

  /// Pending Vehicle Assignment untuk admin driver, Supervisor Approval
  /// untuk HOD, List of User Requests untuk pemohon dan driver. Kalau akun
  /// tidak berhak atas tabnya, layar jatuh ke List of User Requests.
  static IndentTab _indentTab(NotificationLink link) {
    if (link.isApprover) return IndentTab.supervisorApproval;
    if (link.isHandler && link.type == 'new_task') {
      return IndentTab.pendingAssignment;
    }
    return IndentTab.requests;
  }
}
