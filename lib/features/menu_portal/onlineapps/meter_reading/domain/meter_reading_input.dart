/// Isian petugas di form catat / edit / bacaan baru.
///
/// Gantinya `MeterReadingEntry`: karena satu record = satu meter, tidak ada
/// lagi `meterId` — record-nya sendiri yang menjadi sasaran.
class MeterReadingInput {
  const MeterReadingInput({
    required this.currentValue,
    this.notes,
    this.photoPath,
  });

  /// Angka yang terbaca di meter ("Current Value" - wajib, >= 0).
  final num currentValue;

  /// Catatan petugas, maks. 1000 karakter. Kosong dianggap tidak ada.
  final String? notes;

  /// Path berkas foto bukti di perangkat; null = tidak mengganti / tidak ada.
  final String? photoPath;
}
