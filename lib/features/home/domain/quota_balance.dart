/// Satu kartu saldo di bagian "Your balances".
///
/// Bentuk kartunya ditentukan oleh [total]:
/// - punya [total] → tampil setengah lebar dengan progress bar
/// - tanpa [total] → tampil selebar layar, progress diganti [note]
class QuotaBalance {
  const QuotaBalance({
    required this.label,
    required this.value,
    required this.caption,
    this.total,
    this.note,
  });

  final String label;
  final double value;

  /// Kuota maksimum. Null kalau saldo tidak punya batas.
  final double? total;

  /// Teks kecil di samping angka besar, mis. "/ 12 days" atau "of 5.0 M".
  final String caption;

  /// Catatan rata kanan pada kartu lebar, mis. "1 day expires 30 Sep".
  final String? note;

  String get formattedValue => value.toStringAsFixed(1);

  /// Rasio 0–1 untuk progress bar. Null kalau saldo tidak punya batas.
  double? get progress {
    final max = total;
    if (max == null || max <= 0) return null;
    return (value / max).clamp(0.0, 1.0);
  }

  /// Kartu tanpa batas kuota ditampilkan selebar layar.
  bool get isWide => total == null;
}
