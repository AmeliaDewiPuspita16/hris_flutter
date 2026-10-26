import 'app_notification.dart';
import 'notification_category.dart';

import '../../leave_approval/domain/leave_approval_demo_data.dart';
import '../../leave_approval/domain/leave_approval_status.dart';
import '../../pengajuan/domain/leave_type.dart';

/// Data contoh untuk halaman Notifications — sekarang tinggal entri Leave.
///
/// Notifikasi IT Request, eProcurement, EST Work Order, dan Indent Vehicle
/// datang dari server (NotificationInboxRepository), jadi contohnya sudah
/// dibuang. Entri Leave masih di sini karena API cuti Openbravo belum siap:
/// dibangun dari [LeaveApprovalDemoData] — sumber yang sama dengan halaman
/// Leave Approvals dan `_leaveApprovalCount` di BerandaScreen, sehingga
/// notifikasi "Action" dan halaman approval selalu membahas pengajuan yang
/// sama.
///
/// Dibuat sebagai fungsi, bukan konstanta, karena `createdAt` dihitung
/// relatif terhadap waktu sekarang supaya label "25m ago" / "Yesterday"
/// selalu masuk akal kapan pun aplikasi dibuka.
class NotificationDemoData {
  NotificationDemoData._();

  static List<AppNotification> initial({DateTime? now}) {
    final reference = now ?? DateTime.now();

    return [
      // Leave — DIBANGUN dari sumber yang sama dengan halaman Leave
      // Approvals ([LeaveApprovalDemoData]), bukan ditulis ulang manual.
      // Id-nya diturunkan dari id pengajuan (`notificationId`) supaya
      // keputusan di halaman itu dan di tab ini bisa saling disinkronkan
      // (lihat `BerandaScreen._syncLeaveNotification`).
      for (final request in LeaveApprovalDemoData.requests(now: reference)
          .where((r) => r.status == LeaveApprovalStatus.pending))
        AppNotification(
          id: request.notificationId,
          category: NotificationCategory.leave,
          title: request.type == LeaveType.lembur
              ? 'Overtime claim from ${request.requesterName}'
              : 'Leave request from ${request.requesterName}',
          body: request.summaryLine,
          createdAt: request.submittedAt,
          requiresDecision: true,
        ),
    ];
  }
}
