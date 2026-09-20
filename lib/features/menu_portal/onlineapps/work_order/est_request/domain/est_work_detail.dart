/// Laporan lengkap pekerjaan EST — di web ini isi PDF report yang dibuka
/// lewat tombol "Show Details", di mobile ditampilkan sebagai layar detail
/// native (lihat `EstRequestDetailScreen`) sesuai keputusan desain: tidak
/// menghasilkan PDF, cukup layar rapi ala app.
class EstWorkDetail {
  const EstWorkDetail({
    required this.duration,
    required this.manPower,
    required this.approvedBy,
    required this.dateApprove,
    required this.startDate,
    required this.endDate,
    required this.workBy,
    required this.verification,
    this.feedbackUser,
  });

  final String duration;
  final String manPower;
  final String approvedBy;
  final String dateApprove;

  final String startDate;
  final String endDate;
  final String workBy;

  /// Contoh: "Wait Verification" — status verifikasi requester atas hasil
  /// pekerjaan. Berubah setelah requester kasih feedback lewat
  /// [EstRequestFeedbackSheet].
  final String verification;

  /// Catatan requester setelah verifikasi, null selama masih menunggu.
  final String? feedbackUser;
}
