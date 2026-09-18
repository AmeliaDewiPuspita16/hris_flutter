import 'progress_state.dart';

/// Satu tahap di daftar "Approval Progress" — daftar datar bernomor, dari
/// HOD sampai GM.
class ApprovalStep {
  const ApprovalStep({
    required this.title,
    required this.note,
    required this.state,
  });

  /// Ex: "HOD Approval".
  final String title;

  /// Keterangan di bawah judul, ex: "Menunggu persetujuan",
  /// "Belum diproses", "Disetujui 17 Sep 2026".
  final String note;

  final ProgressState state;
}
