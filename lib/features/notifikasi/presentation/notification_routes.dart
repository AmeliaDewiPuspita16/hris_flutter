import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../menu_portal/data_app/indent_vehicle/presentation/screens/indent_vehicle_screen.dart';
import '../../menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';
import '../../menu_portal/onlineapps/work_order/est_request/presentation/screens/est_request_screen.dart';
import '../../menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_screen.dart';
import '../domain/notification_link.dart';

/// Layar yang dibuka saat notifikasi server di-tap.
///
/// Yang dibuka adalah halaman modulnya, langsung di tab yang relevan untuk
/// [NotificationLink.audience] — tab yang sama dengan yang dipakai banner
/// "Approvals waiting" di Beranda — dan kartu request yang dimaksud
/// dikedipkan supaya mudah ditemukan di antara banyak request.
class NotificationRoutes {
  const NotificationRoutes._();

  /// Membuka tujuan notifikasi yang di-tap: halaman modulnya, di tab yang
  /// relevan, dengan kartu request yang dimaksud dikedipkan (lihat
  /// `FlashHighlight`). Tanpa tujuan, tidak melakukan apa-apa.
  static Future<void> open(BuildContext context, NotificationLink link) async {
    AppLogger.info(
      'Notifikasi di-tap: module=${link.module} type=${link.type} '
      'audience=${link.audience} id=${link.refId}',
    );

    final screen = screenFor(link);
    if (screen == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  /// Null kalau modulnya tidak dikenal (mis. pesan uji dari Firebase
  /// console) — cukup ditandai sudah dibaca.
  static Widget? screenFor(NotificationLink link) => switch (link.module) {
        NotificationLink.moduleItRequest => ItRequestScreen(
            initialTab: link.isApprover
                ? ItRequestTab.approve
                : link.isHandler
                    ? ItRequestTab.list
                    : ItRequestTab.form,
            // Kartu request yang dimaksud dikedipkan di tab tujuan.
            highlightId: link.refId,
          ),
        // Tab 1 = Approve HOD, 0 = All Request.
        NotificationLink.moduleEstWorkOrder =>
          EstRequestScreen(
            initialTabIndex: link.isApprover ? 1 : 0,
            highlightId: link.refId,
          ),
        NotificationLink.moduleIndentVehicle =>
          IndentVehicleScreen(
            initialTab: _indentTab(link),
            // Kartu request yang dimaksud notifikasi dikedipkan di daftar.
            highlightId: link.refId?.toString(),
          ),
        NotificationLink.moduleEprocurement => ProcurementPage(
            initialStatusCode: link.isApprover ? link.filter : null,
            highlightId: link.refId,
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
