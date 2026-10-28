import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../menu_portal/onlineapps/procurement/data/procurement_repository.dart';
import '../../menu_portal/onlineapps/procurement/presentation/screens/pr_detail_screen.dart';
import '../../menu_portal/onlineapps/work_order/est_request/data/est_request_repository.dart';
import '../../menu_portal/onlineapps/work_order/est_request/presentation/screens/est_request_detail_screen.dart';
import '../../menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import '../../menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_detail_screen.dart';
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

  /// Membuka tujuan notifikasi yang di-tap.
  ///
  /// Kalau request-nya punya layar detail, langsung ke detail request itu
  /// (diambil dari server dulu, selama itu muncul spinner). Yang langsung ke
  /// detail: IT Request & EST (pemohon dan petugas) serta eProcurement.
  /// Approver IT/EST tetap ke tab approval-nya, karena tombol
  /// Approve/Reject ada di kartu daftar itu, dan Indent Vehicle belum punya
  /// layar detail.
  ///
  /// Gagal mengambil detail (mis. request sudah dihapus) -> snackbar, lalu
  /// jatuh ke halaman modulnya seperti sebelumnya.
  static Future<void> open(BuildContext context, NotificationLink link) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final id = link.refId;
    AppLogger.info(
      'Notifikasi di-tap: module=${link.module} type=${link.type} '
      'audience=${link.audience} id=$id',
    );

    Route<dynamic>? route;

    if (id != null && _opensDetail(link)) {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black26,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );

      try {
        route = await _detailRoute(context, link, id);
      } on ApiException catch (e) {
        AppLogger.info('Detail notifikasi gagal dibuka: ${e.message}');
        messenger?.showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e, stack) {
        AppLogger.error('Detail notifikasi gagal dibuka', e, stack);
      }

      // Tutup spinner.
      navigator.pop();
    }

    if (route == null) {
      final screen = screenFor(link);
      if (screen == null) return;
      route = MaterialPageRoute<void>(builder: (_) => screen);
    }

    await navigator.push(route);
  }

  static bool _opensDetail(NotificationLink link) => switch (link.module) {
        // IT: hanya pemohon yang langsung ke detail; approver dan petugas ke
        // daftar dengan kartu berkedip.
        NotificationLink.moduleItRequest => !link.isApprover && !link.isHandler,
        NotificationLink.moduleEstWorkOrder => !link.isApprover,
        NotificationLink.moduleEprocurement => true,
        _ => false,
      };

  static Future<Route<dynamic>?> _detailRoute(
    BuildContext context,
    NotificationLink link,
    int id,
  ) async {
    switch (link.module) {
      case NotificationLink.moduleItRequest:
        final detail = await context.read<ItRequestRepository>().fetchDetail(id);
        return MaterialPageRoute<void>(
          builder: (_) => ItRequestDetailScreen(
            item: detail,
            // Petugas IT: action bar Respond/Complete harus muncul.
            onItTeamActionDone: link.isHandler ? (_) {} : null,
          ),
        );
      case NotificationLink.moduleEstWorkOrder:
        final detail =
            await context.read<EstRequestRepository>().fetchDetail(id);
        return MaterialPageRoute<bool>(
          builder: (_) => EstRequestDetailScreen(item: detail.item),
        );
      case NotificationLink.moduleEprocurement:
        final pr = await context.read<ProcurementRepository>().fetchDetail(id);
        return MaterialPageRoute<void>(
          builder: (_) => PrDetailScreen(summary: pr),
        );
      default:
        return null;
    }
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
            // Approver (tab Approve) dan petugas (tab List Request): kartu
            // request yang dimaksud dikedipkan.
            highlightId: link.isApprover || link.isHandler ? link.refId : null,
          ),
        // Tab 1 = Approve HOD, 0 = All Request.
        NotificationLink.moduleEstWorkOrder =>
          EstRequestScreen(
            initialTabIndex: link.isApprover ? 1 : 0,
            highlightId: link.isApprover ? link.refId : null,
          ),
        NotificationLink.moduleIndentVehicle =>
          IndentVehicleScreen(
            initialTab: _indentTab(link),
            // Kartu request yang dimaksud notifikasi dikedipkan di daftar.
            highlightId: link.refId?.toString(),
          ),
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
