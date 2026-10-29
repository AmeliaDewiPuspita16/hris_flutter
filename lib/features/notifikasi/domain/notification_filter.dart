import 'app_notification.dart';
// import 'notification_category.dart'; // dipakai lagi saat tab Payroll & Announcements diaktifkan

/// Penyaring daftar notifikasi.
///
/// Predikatnya menempel di enum ini supaya layar tidak perlu tahu aturan
/// tiap chip — cukup meneruskan filter yang sedang aktif.
enum NotificationFilter {
  all('All'),
  action('Action');
  // Tab Payroll & Announcements DINONAKTIFKAN sementara (belum terhubung ke
  // data sungguhan, belum dipakai untuk rilis Play Store). Saat diaktifkan
  // lagi: ganti `action('Action');` di atas menjadi `action('Action'),` lalu
  // buka komentar dua baris ini beserta dua case di `matches`.
  // payroll('Payroll'),
  // announcements('Announcements');

  const NotificationFilter(this.label);

  final String label;

  bool matches(AppNotification notification) => switch (this) {
        NotificationFilter.all => true,
        NotificationFilter.action => notification.isAction,
        // NotificationFilter.payroll =>
        //     notification.category == NotificationCategory.payroll,
        // NotificationFilter.announcements =>
        //     notification.category == NotificationCategory.announcement,
      };
}
