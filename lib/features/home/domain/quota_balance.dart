/// Satu kartu di bagian ringkasan Beranda ("This month").
///
/// Bentuk kartunya ditentukan oleh [total]:
/// - punya [total] → tampil setengah lebar (dengan progress bar kecuali
///   [showProgress] false)
/// - tanpa [total] → tampil selebar layar, progress diganti [note]
class QuotaBalance {
  const QuotaBalance({
    required this.label,
    required this.value,
    required this.caption,
    this.total,
    this.note,
    this.fractionDigits = 1,
    this.showProgress = true,
  });

  final String label;
  final double value;

  /// Pembanding [value], mis. jumlah hari kerja terjadwal. Null kalau tidak
  /// ada pembandingnya.
  final double? total;

  /// Teks kecil di samping angka besar, mis. "/ 21 days" atau "hrs".
  final String caption;

  /// Catatan rata kanan pada kartu lebar, mis. "across 3 days".
  final String? note;

  /// Jumlah angka di belakang koma pada [formattedValue]: 0 untuk hitungan
  /// hari, 1 untuk jam lembur.
  final int fractionDigits;

  /// False = kartu setengah lebar tanpa progress bar, untuk angka yang
  /// punya pembanding tapi tidak enak dibaca sebagai "isi" (mis. hari
  /// terlambat dari hari hadir).
  final bool showProgress;

  String get formattedValue => value.toStringAsFixed(fractionDigits);

  /// Rasio 0–1 untuk progress bar. Null kalau tidak ada progress bar.
  double? get progress {
    final max = total;
    if (!showProgress || max == null || max <= 0) return null;
    return (value / max).clamp(0.0, 1.0);
  }

  /// Kartu tanpa pembanding ditampilkan selebar layar.
  bool get isWide => total == null;
}
