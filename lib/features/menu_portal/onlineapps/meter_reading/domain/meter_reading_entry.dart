/// Isian petugas untuk satu meter di form Record New Data.
class MeterReadingEntry {
  const MeterReadingEntry({
    required this.meterId,
    required this.currentValue,
    this.remark,
    this.photoPath,
  });

  final int meterId;

  /// Angka yang terbaca di meter ("Current Value" - wajib)
  final num currentValue;

  /// Opsional, ex: "A", "MSB-1".
  final String? remark;
  final String? photoPath;
}
