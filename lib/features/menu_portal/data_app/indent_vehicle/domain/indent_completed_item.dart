import '../../../../../core/network/page_meta.dart';
import '../../../../../core/utils/json_value.dart';
import 'indent_json.dart';

/// Satu baris tab "Completed" milik driver — dari
/// `GET /api/indent/driver/history`.
class IndentCompletedItem {
  const IndentCompletedItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    required this.waitingFeedback,
    this.vehicle,
    this.rating,
    this.feedback,
  });

  final String id;

  /// Nama peminta (penumpang), BUKAN nama driver.
  final String name;
  final String destination;
  final String date;
  final String timeRange;
  final String remark;
  final String? vehicle;

  /// True selama status masih 1: driver sudah Finish, requester belum memberi
  /// feedback. Status baru menjadi 3 setelah feedback diberikan.
  final bool waitingFeedback;

  /// Bintang 1-5; null bila belum ada (server mengirim 0).
  final int? rating;

  /// Komentar requester; null bila kosong.
  final String? feedback;

  /// Melempar [FormatException] bila `id` tidak ada.
  factory IndentCompletedItem.fromJson(Map<String, dynamic> json) {
    final id = indentInt(json['id']);
    if (id == null) throw const FormatException('Indent tanpa id');

    final userId = indentInt(json['id_user']);
    final rating = indentInt(json['rating']);

    return IndentCompletedItem(
      id: '$id',
      name: textOrNull(json['name']) ??
          (userId == null ? '-' : 'User #$userId'),
      destination: textOrNull(json['tujuan']) ?? '-',
      date: indentDate(json['tanggal_pemakaian']),
      timeRange: indentTimeRange(json),
      remark: textOrNull(json['keperluan']) ?? '-',
      vehicle: textOrNull(json['kendaraan']),
      waitingFeedback: indentInt(json['status']) != 3,
      rating: rating != null && rating > 0 ? rating : null,
      feedback: textOrNull(json['feedback_user']),
    );
  }
}

/// Satu halaman riwayat driver beserta keterangan paginasinya.
class IndentCompletedPage {
  const IndentCompletedPage({required this.items, required this.meta});

  final List<IndentCompletedItem> items;
  final PageMeta meta;
}
