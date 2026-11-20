/// Periode pembacaan dari server, mis. "01 Aug 2026 – 31 Aug 2026".
///
/// Tampilkan [label] apa adanya, jangan format ulang tanggalnya.
/// start] dan [end] disimpan untuk keperluan lain (urut, perbandingan),
/// bukan untuk ditampilkan.
class MeterPeriod {
  const MeterPeriod({
    required this.label,
    required this.start,
    required this.end,
    this.id,
    this.isActive = false,
  });

  final int? id;

  // Teks siap tampil dari server
  final String label;

  final DateTime start;
  final DateTime end;

  /// `period.status == 'active'`. Periode lama berstatus `inactive`.
  final bool isActive;
}
