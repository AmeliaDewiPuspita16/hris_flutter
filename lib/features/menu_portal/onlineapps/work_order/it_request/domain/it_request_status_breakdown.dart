/// Jumlah request yang masih terbuka (belum selesai) vs sudah ditutup —
/// dipakai ringkasan status per jenis (IT/Media) di tab Report.
class ItRequestStatusBreakdown {
  const ItRequestStatusBreakdown({required this.open, required this.close});

  final int open;
  final int close;

  int get total => open + close;

  /// Persentase yang sudah ditutup, dibulatkan. Null kalau belum ada data
  /// sama sekali (bukan 0%, supaya UI bisa membedakan "belum ada data" dari
  /// "belum ada yang selesai").
  int? get closedPercent => total == 0 ? null : ((close / total) * 100).round();
}
