/// Saklar fitur yang sudah ada kodenya tapi belum siap dirilis (biasanya
/// karena API-nya belum ada).
///
/// Flag `false` = fitur tampil dalam keadaan nonaktif ("Soon", redup, tidak
/// bisa disentuh), seperti item menu HRIS dengan `isReady: false`. Kodenya
/// tetap ada dan tetap di-compile, jadi mengaktifkan lagi cukup mengubah
/// `false` menjadi `true` di sini.
class FeatureFlags {
  FeatureFlags._();

  /// Bagian "Recent Activity" di Beranda. Biarkan `false` sampai ada API
  /// aktivitas: isinya sekarang masih data contoh
  /// ([HomeDemoData.recentActivities]), sama untuk semua akun.
  static const recentActivity = false;
}
