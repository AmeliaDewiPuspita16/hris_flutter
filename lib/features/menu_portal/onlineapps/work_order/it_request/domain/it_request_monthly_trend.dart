/// Jumlah request IT vs Media pada satu bulan — dipakai chart tren di tab
/// Report.
class ItRequestMonthlyTrend {
  const ItRequestMonthlyTrend({
    required this.month,
    required this.itCount,
    required this.mediaCount,
  });

  /// 1–12.
  final int month;

  final int itCount;
  final int mediaCount;
}
