/// Lembur yang sudah TERJADI pada satu hari — realisasi dari check-in/out
/// fingerprint, bukan pengajuan. Bentuknya mengikuti satu item `days` pada
/// `GET /api/portal/apps/hris/overtime` (belum tersambung; sekarang diisi
/// data dummy).
class OvertimeDay {
  const OvertimeDay({
    required this.date,
    required this.minutes,
    required this.checkIn,
    required this.checkOut,
    required this.shift,
  });

  final DateTime date;

  /// Lama lembur dalam menit (`overtime_minutes`).
  final int minutes;

  final DateTime checkIn;
  final DateTime checkOut;

  /// Teks shift apa adanya, mis. "N (08:00–17:00)".
  final String shift;
}
