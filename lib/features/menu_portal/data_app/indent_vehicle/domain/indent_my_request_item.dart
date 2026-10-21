import '../../../../../core/utils/json_value.dart';
import 'indent_json.dart';
import 'indent_progress_status.dart';

/// Satu kartu di tab "My Request" — request milik user yang sedang login,
/// dari `GET /api/indent/list`.
///
/// Sengaja bukan `IndentRequestItem`: respons endpoint ini tidak memuat
/// `name` (selalu milik sendiri) maupun `approval_hod`, sedangkan
/// `IndentRequestItem` mewajibkan kolom Approve. Menebak nilainya akan
/// menampilkan status approval yang bisa salah.
class IndentMyRequestItem {
  const IndentMyRequestItem({
    required this.id,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    required this.status,
    this.vehicle,
    this.driver,
    this.rating,
    this.feedback,
    this.createdAt,
    this.finishedAt,
  });

  final String id;
  final String destination;

  /// Tanggal pemakaian. Server sudah memformatnya untuk tampilan
  /// ('18 Jun 2026'); bila ternyata ISO, [indentDate] mengubahnya.
  final String date;

  /// Rentang jam, mis. '07:30:00 to 15:00:00'.
  final String timeRange;
  final String remark;
  final IndentProgressStatus status;

  /// Plat nomor; null selama belum ditetapkan.
  final String? vehicle;

  /// Nama driver; null bila tanpa driver atau belum ditunjuk (server
  /// mengirim `id_driver` null/0 dan `driver: "Tanpa Driver"`).
  final String? driver;

  /// Bintang 1-5; null bila belum memberi rating.
  final int? rating;

  /// Komentar requester (`feedback_user`); null bila kosong.
  final String? feedback;

  /// Tanggal request dibuat ('17 Jun 2026').
  final String? createdAt;

  /// Tanggal request ditutup; hanya bermakna bila [status] sudah done.
  final String? finishedAt;

  /// Perjalanan selesai tapi requester belum memberi rating.
  bool get awaitsFeedback =>
      status == IndentProgressStatus.done && rating == null;

  /// Memetakan satu objek dari `GET /api/indent/list` (array polos).
  ///
  /// Melempar [FormatException] bila `id` tidak ada.
  factory IndentMyRequestItem.fromJson(Map<String, dynamic> json) {
    final id = indentInt(json['id']);
    if (id == null) throw const FormatException('Indent tanpa id');

    final idDriver = indentInt(json['id_driver']) ?? 0;
    final driverName = idDriver > 0
        ? (textOrNull(json['driver']) ?? 'Driver #$idDriver')
        : null;

    final rating = indentInt(json['rating']);
    final created = json['created_at'];
    final finished = json['date_finish'];

    return IndentMyRequestItem(
      id: '$id',
      destination: textOrNull(json['tujuan']) ?? '-',
      date: indentDate(json['tanggal_pemakaian']),
      timeRange: indentTimeRange(json),
      remark: textOrNull(json['keperluan']) ?? '-',
      status: switch (indentInt(json['status'])) {
        1 => IndentProgressStatus.onProgress,
        3 => IndentProgressStatus.done,
        5 => IndentProgressStatus.cancelled,
        _ => IndentProgressStatus.onWaiting,
      },
      vehicle: textOrNull(json['kendaraan']),
      driver: driverName,
      rating: rating != null && rating > 0 ? rating : null,
      feedback: textOrNull(json['feedback_user']),
      createdAt: created == null ? null : indentDate(created),
      finishedAt: finished == null ? null : indentDate(finished),
    );
  }
}
