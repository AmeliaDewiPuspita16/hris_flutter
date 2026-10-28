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

  /// Leave Approvals sudah terhubung ke API? Selama `false`, angka pending
  /// Leave dianggap 0 sehingga banner "Approvals waiting" di Beranda dan
  /// badge menu HRIS tidak menampilkan data dummy
  /// ([LeaveApprovalRepository] masih memakai daftar contoh di memori).
  /// Ubah ke `true` setelah repository-nya memakai endpoint sungguhan.
  static const leaveApproval = false;

  /// PRATINJAU SAJA: tampilkan tab "My Assignments" (Indent Vehicle) di akun
  /// apa pun dengan data contoh, tanpa memeriksa role `driver` dan tanpa
  /// memanggil API. Matikan (`false`) sebelum rilis.
  static const previewIndentDriverTab = false;
}
