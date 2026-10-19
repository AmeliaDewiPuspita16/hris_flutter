import '../../../../../core/utils/json_value.dart';
import 'indent_json.dart';

/// Satu baris di tab "Supervisor Approval" — request yang menunggu
/// keputusan atasan (HOD).
///
/// Kolom web: No, Name, Destination, Date, Remark, Action. "No" tidak
/// dipakai di mobile dan "Action" (Approve/Reject) bukan data.
class IndentApprovalItem {
  const IndentApprovalItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    required this.withDriver,
  });

  final String id;
  final String name;
  final String destination;

  /// Tanggal pemakaian, mis. '10-10-2026'.
  final String date;

  /// Rentang jam, mis. '08:00:00 s/d 12:00:00'.
  final String timeRange;
  final String remark;

  /// Jawaban requester ("With Driver"). Tidak ada di tabel web Supervisor
  /// Approval, tapi dibawa supaya saat di-approve request bisa langsung
  /// diteruskan ke Pending Vehicle Assignment dengan isi popup yang benar.
  final bool withDriver;

  /// Memetakan satu objek dari `GET /api/list_hod_approve` (array polos,
  /// berisi baris indent lengkap ditambah `name` dan `image`):
  ///
  /// ```json
  /// { "id": 4685, "id_user": 117, "tanggal_pemakaian": "2026-10-22",
  ///   "jam_pergi": "09:00:00", "jam_pulang": "09:05:00",
  ///   "tujuan": "...", "keperluan": "...", "driver": 0,
  ///   "approval_hod": 0, "name": "Aditya Yudha Pratama", ... }
  /// ```
  ///
  /// `image` (foto peminta) tidak dibaca karena kartunya tidak menampilkannya.
  ///
  /// Melempar [FormatException] bila `id` tidak ada.
  factory IndentApprovalItem.fromJson(Map<String, dynamic> json) {
    final id = indentInt(json['id']);
    if (id == null) throw const FormatException('Indent tanpa id');

    final userId = indentInt(json['id_user']);

    return IndentApprovalItem(
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
