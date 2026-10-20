import '../../../../../core/utils/json_value.dart';
import 'indent_json.dart';

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

  /// Memetakan satu baris dari `GET /api/indent/admin/list` (di dalam
  /// `data`):
  ///
  /// ```json
  /// { "id": 101, "id_user": 15, "tanggal_pemakaian": "2026-10-20",
  ///   "jam_pergi": "08:00", "jam_pulang": "17:00", "tujuan": "...",
  ///   "keperluan": "...", "status": 0, "approval_hod": 1,
  ///   "name": "Ari Putra", "image": "avatars/ari.jpg" }
  /// ```
  ///
  /// `image` tidak dibaca karena kartunya tidak menampilkannya.
  ///
  /// Dokumentasi API tidak mencantumkan field `driver` (With Driver) di
  /// contoh baris ini. Kalau server tidak mengirimnya, [withDriver] jatuh
  /// ke true (lihat `indentWithDriver`) sehingga admin diminta memilih
  /// driver.
  ///
  /// Melempar [FormatException] bila `id` tidak ada.
  factory IndentPendingItem.fromJson(Map<String, dynamic> json) {
    final id = indentInt(json['id']);
    if (id == null) throw const FormatException('Indent tanpa id');

    final userId = indentInt(json['id_user']);

    return IndentPendingItem(
      id: '$id',
      name: textOrNull(json['name']) ??
          (userId == null ? '-' : 'User #$userId'),
      destination: textOrNull(json['tujuan']) ?? '-',
      date: indentDate(json['tanggal_pemakaian']),
      timeRange: indentTimeRange(json),
      remark: textOrNull(json['keperluan']) ?? '-',
      withDriver: indentWithDriver(json['driver']),
    );
  }
}
