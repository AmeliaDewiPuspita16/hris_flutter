import '../../../../../core/utils/json_value.dart';
import 'stationery_request_status.dart';

/// Satu baris request stationery (satu barang per request), dipakai untuk
/// daftar "Request Items" DAN antrean "Verification Requests".
///
/// Hak aksi ([canEdit], [canCancel]) dihitung SERVER — di web tombol Edit /
/// Cancel hanya muncul pada request milik sendiri yang masih pending.
/// Aplikasi hanya menampilkan tombol sesuai flag ini.
class StationeryRequestItem {
  const StationeryRequestItem({
    required this.id,
    required this.code,
    required this.requesterName,
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.description,
    required this.status,
    this.stock,
    this.rejectReason,
    this.isMine = false,
    this.canEdit = false,
    this.canCancel = false,
  });

  final int id;

  /// Kode request, mis. `REQ00554`.
  final String code;
  final String requesterName;

  final int? itemId;

  /// `ITE00107`
  final String itemCode;

  /// `ISOLASI BENING`
  final String itemName;

  /// `PCS`, `RIM`, ...
  final String unit;
  final int quantity;

  /// Alasan / keterangan dari requester; kosong kalau tidak diisi.
  final String description;
  final StationeryRequestStatus status;

  /// Stok barang saat ini ("Existing quantity" di form edit web).
  final int? stock;

  /// Alasan penolakan; terisi hanya bila ditolak dan verifier mengisinya.
  final String? rejectReason;

  final bool isMine;
  final bool canEdit;
  final bool canCancel;

  /// `ITE00107 - ISOLASI BENING`
  String get itemLabel => '$itemCode - $itemName';

  /// True bila requester benar-benar mengisi alasan. Teks kosong, "-", dan
  /// "N/A" (yang kadang diketik user atau dikirim server sebagai pengganti
  /// kosong) dianggap tidak ada alasan.
  bool get hasReason {
    final text = description.trim();
    return text.isNotEmpty && text != '-' && text.toUpperCase() != 'N/A';
  }

  /// Teks alasan untuk ditampilkan di kartu: alasan aslinya, atau "-" bila
  /// tidak diisi.
  String get reasonLabel => hasReason ? description.trim() : '-';

  /// `1 PCS`
  String get quantityLabel => unit.isEmpty ? '$quantity' : '$quantity $unit';

  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id, aksi
  /// apa pun pada request ini tidak bisa dikirim.
  factory StationeryRequestItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons request stationery tidak memuat id');
    }

    Map<String, dynamic> section(String key) =>
        json[key] is Map<String, dynamic>
            ? json[key] as Map<String, dynamic>
            : const <String, dynamic>{};

    final requester = section('requester');
    final item = section('item');
    final quantity = json['quantity'];

    return StationeryRequestItem(
      id: id,
      code: '${json['code'] ?? ''}',
      requesterName: '${requester['name'] ?? ''}',
      itemId: item['id'] is int ? item['id'] as int : null,
      itemCode: '${item['code'] ?? ''}',
      itemName: '${item['name'] ?? ''}',
      unit: '${item['unit'] ?? ''}',
      quantity: quantity is num ? quantity.toInt() : intOr(quantity, 0),
      description: textOrNull(json['description']) ?? '',
      status: StationeryRequestStatus.fromJson(json['status']),
      stock: item['stock'] is num ? (item['stock'] as num).toInt() : null,
      rejectReason: textOrNull(json['reject_reason']),
      isMine: json['is_mine'] == true,
      canEdit: json['can_edit'] == true,
      canCancel: json['can_cancel'] == true,
    );
  }
}
