/// Satu baris di tab "Pending Vehicle Assignment" — request yang sudah
/// masuk tapi belum ditetapkan kendaraan (dan driver)-nya oleh admin driver.
///
/// Kolom web: No, Name, Destination, Date, Remark, With Driver, Action.
/// Kolom "Action" (tombol Assign) bukan data, jadi tidak ada di model.
class IndentPendingItem {
  const IndentPendingItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    required this.withDriver,
  });

  /// Pengenal unik untuk menghapus baris dari list setelah di-assign.
  final String id;
  final String name;
  final String destination;

  /// Tanggal pemakaian, mis. '10-10-2026'.
  final String date;

  /// Rentang jam, mis. '15:30:00 s/d 16:30:00'.
  final String timeRange;
  final String remark;

  /// Jawaban requester di form Add New Indent ("With Driver": Yes/No).
  /// Menentukan isi popup Assign: kalau true, admin wajib memilih driver;
  /// kalau false, cukup isi plat nomor.
  final bool withDriver;
}
