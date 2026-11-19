import '../../../../../core/utils/json_value.dart';
import 'item_request_entry.dart';

/// Satu REQUEST (kode `REQ-…`) berikut semua line yang boleh dilihat user —
/// isi `GET .../inventory/item-request/requests/{id}` (bentuknya sama dengan
/// respons submit):
///
/// ```json
/// { "id": 12, "code": "REQ-0012", "requested_by": {"id": 5, "name": "Ani"},
///   "requested_at": "2026-11-11T11:00:00+07:00", "is_mine": true,
///   "can_verify": false, "lines": [ { "id": 31, "item": {...}, ... } ] }
/// ```
class ItemRequestDetail {
  const ItemRequestDetail({
    required this.id,
    required this.code,
    required this.lines,
    this.canVerify = false,
  });

  final int id;
  final String code;

  /// Line yang boleh dilihat user. Bisa lebih sedikit dari isi request
  /// sebenarnya (kategori yang tidak boleh dilihatnya disembunyikan server).
  final List<ItemRequestEntry> lines;

  /// Ada line yang boleh diputuskan user ini (`can_verify` di tingkat request).
  final bool canVerify;

  /// Melempar [FormatException] bila `id` tidak terbaca.
  factory ItemRequestDetail.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons request tidak memuat id');
    }

    final lines = <ItemRequestEntry>[];
    for (final row
        in (json['lines'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()) {
      try {
        // Line di dalam request mungkin tak membawa objek `request`
        // sendiri; info induknya dioper lewat `parent`.
        lines.add(ItemRequestEntry.fromJson(row, parent: json));
      } on FormatException {
        // Satu line cacat dilewati, sisanya tetap tampil.
      }
    }

    return ItemRequestDetail(
      id: id,
      code: textOrNull(json['code']) ?? '',
      lines: lines,
      canVerify: json['can_verify'] == true,
    );
  }
}
