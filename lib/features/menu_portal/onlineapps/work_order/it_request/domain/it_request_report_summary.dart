/// Ringkasan angka untuk tab "Report" IT/Media Request — satu periode
/// (bulan + tahun) sekaligus.
class ItRequestReportSummary {
  const ItRequestReportSummary({
    required this.totalRequest,
    required this.done,
    required this.onProgress,
    required this.onWaiting,
    required this.waitHod,
    required this.completionRate,
    required this.avgResponseDays,
  });

  final int totalRequest;
  final int done;
  final int onProgress;
  final int onWaiting;
  final int waitHod;

  /// Persentase 0–100.
  final int completionRate;

  /// Rata-rata hari sejak disetujui HOD sampai selesai dikerjakan.
  final int avgResponseDays;
}
