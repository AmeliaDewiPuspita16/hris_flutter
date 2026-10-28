import '../../../core/logging/app_logger.dart';
import '../../menu_portal/data_app/indent_vehicle/data/indent_vehicle_repository.dart';
import '../../menu_portal/onlineapps/procurement/data/procurement_repository.dart';
import '../../menu_portal/onlineapps/work_order/est_request/data/est_request_repository.dart';
import '../../menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notification_link.dart';

/// Menentukan notifikasi "approval_needed" mana yang request-nya MASIH
/// menunggu keputusan user — itulah yang masuk tab Action.
///
/// Server tidak menandai notifikasi lama yang sudah diputuskan, dan angka di
/// banner "Approvals waiting" hanya jumlah tanpa id. Jadi yang dicek adalah
/// antrean approval tiap modul (IT, EST, Indent, eProcurement): notifikasi
/// dianggap masih menunggu bila request-nya masih ada di antrean itu.
///
/// Antrean hanya diminta untuk modul yang memang punya notifikasi approval,
/// dan gagal memuat satu modul tidak mengganggu yang lain — notifikasinya
/// cuma tidak ikut ke tab Action (tetap ada di tab All).
class PendingApprovalChecker {
  PendingApprovalChecker({
    required ItRequestRepository itRequestRepository,
    required EstRequestRepository estRequestRepository,
    required IndentVehicleRepository indentVehicleRepository,
    required ProcurementRepository procurementRepository,
  })  : _it = itRequestRepository,
        _est = estRequestRepository,
        _indent = indentVehicleRepository,
        _procurement = procurementRepository;

  final ItRequestRepository _it;
  final EstRequestRepository _est;
  final IndentVehicleRepository _indent;
  final ProcurementRepository _procurement;

  static const _approvalType = 'approval_needed';

  /// [AppNotification.id] dari notifikasi di [notifications] yang request-nya
  /// masih menunggu approval.
  Future<Set<String>> stillPending(List<AppNotification> notifications) async {
    final candidates = [
      for (final n in notifications)
        if (n.isFromServer &&
            n.link != null &&
            n.link!.type == _approvalType &&
            n.link!.refId != null)
          n,
    ];
    if (candidates.isEmpty) return {};

    bool has(String module) => candidates.any((n) => n.link!.module == module);

    // Kode status eProcurement yang perlu dicek (mis. `pending_hod`).
    final prCodes = {
      for (final n in candidates)
        if (n.link!.module == NotificationLink.moduleEprocurement &&
            n.link!.filter != null)
          n.link!.filter!,
    };

    final it = has(NotificationLink.moduleItRequest)
        ? _safe('IT', () async {
            final page = await _it.fetchApprovals();
            return {for (final item in page.items) item.id};
          })
        : Future.value(<int>{});

    final est = has(NotificationLink.moduleEstWorkOrder)
        ? _safe('EST', () async {
            final page = await _est.fetchApprovals();
            return {for (final item in page.items) item.id};
          })
        : Future.value(<int>{});

    final indent = has(NotificationLink.moduleIndentVehicle)
        ? _safe('Indent', () async {
            final items = await _indent.fetchApprovals();
            return {
              for (final item in items)
                if (int.tryParse(item.id) != null) int.parse(item.id),
            };
          })
        : Future.value(<int>{});

    final procurement = <String, Future<Set<int>>>{
      for (final code in prCodes)
        code: _safe('eProcurement', () async {
          final page =
              await _procurement.fetchList(statusCode: code, perPage: 100);
          return {for (final item in page.items) item.id};
        }),
    };

    final itIds = await it;
    final estIds = await est;
    final indentIds = await indent;
    final prIds = {
      for (final entry in procurement.entries) entry.key: await entry.value,
    };

    bool pending(AppNotification n) {
      final link = n.link!;
      final id = link.refId!;
      return switch (link.module) {
        NotificationLink.moduleItRequest => itIds.contains(id),
        NotificationLink.moduleEstWorkOrder => estIds.contains(id),
        NotificationLink.moduleIndentVehicle => indentIds.contains(id),
        NotificationLink.moduleEprocurement =>
          prIds[link.filter]?.contains(id) ?? false,
        _ => false,
      };
    }

    return {
      for (final n in candidates)
        if (pending(n)) n.id,
    };
  }

  Future<Set<int>> _safe(String label, Future<Set<int>> Function() load) async {
    try {
      return await load();
    } catch (e, stack) {
      AppLogger.error('Antrean approval $label gagal dimuat', e, stack);
      return <int>{};
    }
  }
}
