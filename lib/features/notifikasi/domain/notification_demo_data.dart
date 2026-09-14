import 'app_notification.dart';
import 'notification_category.dart';

/// Data contoh untuk halaman Notifications.
///
/// Dibuat sebagai fungsi, bukan konstanta, karena `createdAt` dihitung
/// relatif terhadap waktu sekarang supaya label "25m ago" / "Yesterday"
/// selalu masuk akal kapan pun aplikasi dibuka.
class NotificationDemoData {
  NotificationDemoData._();

  static List<AppNotification> initial({DateTime? now}) {
    final reference = now ?? DateTime.now();

    return [
      AppNotification(
        id: 'n1',
        category: NotificationCategory.approval,
        title: 'Leave request from Budi Santoso',
        body: 'Annual leave · 22–24 Sep · 3 days',
        createdAt: reference.subtract(const Duration(minutes: 25)),
        requiresDecision: true,
      ),
      AppNotification(
        id: 'n2',
        category: NotificationCategory.approval,
        title: 'Overtime claim from Rina Wijaya',
        body: '12 Sep · 18:30–21:00 · 2h 30m',
        createdAt: reference.subtract(const Duration(hours: 2)),
        requiresDecision: true,
      ),
      AppNotification(
        id: 'n3',
        category: NotificationCategory.payroll,
        title: 'September payslip is available',
        body: 'Net pay Rp 12,500,000 · issued 13 Sep',
        createdAt: reference.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n4',
        category: NotificationCategory.attendance,
        title: 'You forgot to clock out yesterday',
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
