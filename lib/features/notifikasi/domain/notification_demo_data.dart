import 'app_notification.dart';
// DUMMY DINONAKTIFKAN untuk rilis Play Store — aktifkan lagi bersama kode di
// bawah saat API cuti Openbravo sudah siap.
// import 'notification_category.dart';
//
// import '../../leave_approval/domain/leave_approval_demo_data.dart';
// import '../../leave_approval/domain/leave_approval_status.dart';
// import '../../pengajuan/domain/leave_type.dart';

/// Data contoh untuk halaman Notifications.
///
/// SEMENTARA KOSONG: satu-satunya isi yang tersisa adalah entri Leave yang
/// dibangun dari data dummy (`LeaveApprovalDemoData`). Karena aplikasi akan
/// diunggah ke Play Store, data dummy itu tidak ditampilkan dulu. Notifikasi
/// IT Request, eProcurement, EST Work Order, dan Indent Vehicle sudah datang
/// dari server (NotificationInboxRepository) dan tidak terpengaruh.
///
/// Fungsinya tetap ada (mengembalikan daftar kosong) supaya pemanggil di
/// BerandaScreen tidak perlu diubah. Kode aslinya dikomentari di bawah.
class NotificationDemoData {
  NotificationDemoData._();

  static List<AppNotification> initial({DateTime? now}) {
    return const <AppNotification>[];
  }

  // ---------------------------------------------------------------------------
  // KODE ASLI (dummy Leave) — dikomentari, bukan dihapus.
  // ---------------------------------------------------------------------------
  //
  // static List<AppNotification> initial({DateTime? now}) {
  //   final reference = now ?? DateTime.now();
  //
  //   return [
  //     // Leave — DIBANGUN dari sumber yang sama dengan halaman Leave
  //     // Approvals ([LeaveApprovalDemoData]), bukan ditulis ulang manual.
  //     // Id-nya diturunkan dari id pengajuan (`notificationId`) supaya
  //     // keputusan di halaman itu dan di tab ini bisa saling disinkronkan
  //     // (lihat `BerandaScreen._syncLeaveNotification`).
  //     for (final request in LeaveApprovalDemoData.requests(now: reference)
  //         .where((r) => r.status == LeaveApprovalStatus.pending))
  //       AppNotification(
  //         id: request.notificationId,
  //         category: NotificationCategory.leave,
  //         title: request.type == LeaveType.lembur
  //             ? 'Overtime claim from ${request.requesterName}'
  //             : 'Leave request from ${request.requesterName}',
  //         body: request.summaryLine,
  //         createdAt: request.submittedAt,
  //         requiresDecision: true,
  //       ),
  //   ];
  // }
}
