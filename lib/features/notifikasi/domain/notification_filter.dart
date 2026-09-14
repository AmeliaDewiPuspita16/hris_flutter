import 'app_notification.dart';
import 'notification_category.dart';

/// Penyaring daftar notifikasi.
///
/// Predikatnya menempel di enum ini supaya layar tidak perlu tahu aturan
/// tiap chip — cukup meneruskan filter yang sedang aktif.
enum NotificationFilter {
  all('All'),
  action('Action'),
  payroll('Payroll'),
  announcements('Announcements');

  const NotificationFilter(this.label);

  final String label;

  bool matches(AppNotification notification) => switch (this) {
        NotificationFilter.all => true,
        NotificationFilter.action => notification.needsAction,
        NotificationFilter.payroll =>
          notification.category == NotificationCategory.payroll,
        NotificationFilter.announcements =>
          notification.category == NotificationCategory.announcement,
      };
}
