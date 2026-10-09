/// Satu baris di tab "Supervisor Approval" — request yang menunggu
/// keputusan atasan (HOD).
///
/// Kolom web: No, Name, Destination, Date, Remark, Action. "No" tidak
/// dipakai di mobile dan "Action" (Approve/Reject) bukan data.
class IndentApprovalItem {
  const IndentApprovalItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    required this.withDriver,
  });

  final String id;
  final String name;
  final String destination;

  /// Tanggal pemakaian, mis. '10-10-2026'.
  final String date;

  /// Rentang jam, mis. '08:00:00 s/d 12:00:00'.
  final String timeRange;
  final String remark;

  /// Jawaban requester ("With Driver"). Tidak ada di tabel web Supervisor
  /// Approval, tapi dibawa supaya saat di-approve request bisa langsung
  /// diteruskan ke Pending Vehicle Assignment dengan isi popup yang benar.
  final bool withDriver;
}
