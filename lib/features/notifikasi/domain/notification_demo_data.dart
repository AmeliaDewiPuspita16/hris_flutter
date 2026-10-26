import 'app_notification.dart';
import 'notification_category.dart';

import '../../leave_approval/domain/leave_approval_demo_data.dart';
import '../../leave_approval/domain/leave_approval_status.dart';
import '../../pengajuan/domain/leave_type.dart';
import '../../menu_portal/onlineapps/work_order/it_request/domain/approve_request_demo_data.dart';

/// Data contoh untuk halaman Notifications.
///
/// Dibuat sebagai fungsi, bukan konstanta, karena `createdAt` dihitung
/// relatif terhadap waktu sekarang supaya label "25m ago" / "Yesterday"
/// selalu masuk akal kapan pun aplikasi dibuka.
///
/// Entri IT DIBANGUN dari sumber yang sama dengan `_itApprovalCount` di
/// BerandaScreen ([ApproveRequestDemoData]) — bukan ditulis ulang manual —
/// supaya angkanya sinkron dengan tab "Action". Entri EST tidak ada di sini
/// lagi karena EST sudah memakai API sungguhan (antrean approval HOD).
///
/// Entri Leave (kategori Leave & Overtime) dibangun dari
/// [LeaveApprovalDemoData] — sumber yang sama dengan halaman Leave
/// Approvals dan `_leaveApprovalCount` di BerandaScreen, sehingga notifikasi
/// "Action" dan halaman approval selalu membahas pengajuan yang sama.
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
      // IT — sama persis dengan daftar di IT Request > tab "Approve
      // Request", supaya total di sini selalu = _itApprovalCount.
      for (final entry in ApproveRequestDemoData.items().asMap().entries)
        AppNotification(
          id: 'n-it-${entry.value.id}',
          category: NotificationCategory.itRequest,
          title: 'IT request from ${entry.value.requesterName}',
          body: entry.value.description,
          createdAt: reference.subtract(Duration(hours: 3 + entry.key)),
          requiresDecision: true,
        ),
      AppNotification(
        id: 'n3',
        category: NotificationCategory.payroll,
        title: 'September payslip is available',
        body: 'Net pay Rp 12,500,000 · issued 13 Sep',
        createdAt: reference.subtract(const Duration(hours: 10)),
      ),
      AppNotification(
        id: 'n4',
        category: NotificationCategory.attendance,
        title: 'You forgot to check out yesterday',
        body: 'Shift ended 17:00 at Plant 2 · Gate A',
        createdAt: reference.subtract(const Duration(days: 1, hours: 3)),
      ),
      AppNotification(
        id: 'n5',
        category: NotificationCategory.announcement,
        title: 'Payroll cut-off moves to the 23rd',
        body: 'Overtime claims must be approved before 23 Sep, 17:00.',
        createdAt: reference.subtract(const Duration(days: 1, hours: 8)),
        isRead: true,
      ),
      AppNotification(
        id: 'n6',
        category: NotificationCategory.leave,
        title: 'Your annual leave was approved',
        body: '17–19 Jul · 3 days · approved by Dewi Puspita',
        createdAt: reference.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }
}
