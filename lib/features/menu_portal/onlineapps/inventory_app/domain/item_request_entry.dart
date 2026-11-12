import '../../../../../core/utils/json_value.dart';
import 'item_request_stock_option.dart';
import 'item_request_status.dart';

/// Satu LINE request (satu barang), dipakai untuk daftar "Request Items" DAN
/// antrean "Verification Requests". [id] adalah id LINE (dipakai untuk edit,
/// cancel, approve, reject), sedangkan [requestId] / [code] milik request
/// induknya (satu request `REQ-…` bisa berisi beberapa line).
///
/// Hak aksi ([canEdit], [canCancel], [canVerify]) dihitung SERVER. Aplikasi
/// hanya menampilkan tombol sesuai flag ini.
///
/// Catatan penamaan: [description] adalah kolom `reason` di API baru.
class ItemRequestEntry {
  const ItemRequestEntry({
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
    this.requestId,
    this.stock,
    this.rejectReason,
    this.requestedAt,
    this.imageUrl,
    this.category,
    this.autoApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.isMine = false,
    this.canEdit = false,
    this.canCancel = false,
    this.canVerify = false,
  });

  /// Id LINE.
  final int id;

  /// Id request induk (`request.id`); null pada data demo.
  final int? requestId;

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
  /// Boleh desimal (sampai 4 angka di belakang koma).
  final num quantity;

  /// Alasan / keterangan dari requester; kosong kalau tidak diisi.
  final String description;
  final ItemRequestStatus status;

  /// Stok total barang saat ini. Daftar tidak mengirimnya; hanya detail line
  /// (`current_stock`) — null berarti "tidak diketahui".
  final num? stock;

  /// Alasan penolakan. API baru tidak punya kolom ini (reject tanpa alasan),
  /// jadi selalu null kecuali pada data demo.
  final String? rejectReason;

  /// Kapan request diajukan ("Requested on" di web). Null bila server tidak
  /// mengirimnya.
  final DateTime? requestedAt;

  /// Foto dan kategori barang (`item.image_url`, `item.category`).
  final String? imageUrl;
  final String? category;

  /// True bila line langsung disetujui saat diajukan (requester adalah
  /// Inventory Admin yang mengurus kategorinya dan stok cukup).
  final bool autoApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  final bool isMine;
  final bool canEdit;
  final bool canCancel;

  /// Boleh di-approve / reject oleh user ini.
  final bool canVerify;

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

  /// "11 Nov 2026 11:00" — "-" bila tanggalnya tidak diketahui.
  String get requestedAtLabel {
    final d = requestedAt;
    if (d == null) return '-';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(d.day)} ${months[d.month - 1]} ${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  /// `1 PCS`
  String get quantityLabel {
    final q = formatInventoryQuantity(quantity);
    return unit.isEmpty ? q : '$q $unit';
  }

  /// Membaca satu LINE dari `GET .../inventory/item-request` (atau
  /// `/verifications`, `/{line}`):
  ///
  /// ```json
  /// { "id": 31, "request": {"id": 12, "code": "REQ-0012",
  ///     "requested_by": {"id": 5, "name": "Ani", "avatar_url": "..."},
  ///     "requested_at": "2026-11-11T11:00:00+07:00", "is_mine": true},
  ///   "item": {"id": 7, "code": "ITE00007", "name": "...", "unit": "PCS",
  ///     "image_url": null, "category": "..."},
  ///   "quantity": 2, "reason": "...", "status": {"code": "pending", ...},
  ///   "auto_approved": false, "approved_by": null, "approved_at": null,
  ///   "can_edit": true, "can_cancel": true, "can_verify": false,
  ///   "current_stock": 40 }
  /// ```
  ///
  /// [parent] = objek request induk, dipakai bila line TIDAK membawa objek
  /// `request` sendiri (line di dalam `GET .../requests/{id}`): `id`, `code`,
  /// `requested_by`, `requested_at`, `is_mine` dibaca darinya.
  ///
  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id, aksi
  /// apa pun pada line ini tidak bisa dikirim.
  factory ItemRequestEntry.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? parent,
  }) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons line request tidak memuat id');
    }

    Map<String, dynamic> section(Map<String, dynamic> from, String key) =>
        from[key] is Map<String, dynamic>
            ? from[key] as Map<String, dynamic>
            : const <String, dynamic>{};

    final request = json['request'] is Map<String, dynamic>
        ? section(json, 'request')
        : (parent ?? const <String, dynamic>{});

    // `requested_by` berupa objek {id, name, avatar_url}; teks biasa pun
    // diterima.
    final by = request['requested_by'];
    final requesterName = by is Map<String, dynamic>
        ? (textOrNull(by['name']) ?? '')
        : (textOrNull(by) ?? '');
    final item = section(json, 'item');

    num? number(Object? raw) {
      if (raw is num) return raw;
      final text = textOrNull(raw);
      return text == null ? null : num.tryParse(text);
    }

    return ItemRequestEntry(
      id: id,
      requestId: request['id'] is int ? request['id'] as int : null,
      code: '${request['code'] ?? ''}',
      requesterName: requesterName,
      itemId: item['id'] is int ? item['id'] as int : null,
      itemCode: '${item['code'] ?? ''}',
      itemName: '${item['name'] ?? ''}',
      unit: '${item['unit'] ?? ''}',
      quantity: number(json['quantity']) ?? 0,
      description: textOrNull(json['reason']) ?? '',
      status: ItemRequestStatus.fromJson(json['status']),
      stock: number(json['current_stock']),
      requestedAt:
          DateTime.tryParse('${request['requested_at'] ?? ''}')?.toLocal(),
      imageUrl: textOrNull(item['image_url']),
      category: textOrNull(item['category']),
      autoApproved: json['auto_approved'] == true,
      // Belum teramati: bisa teks nama atau objek {id, name}.
      approvedBy: json['approved_by'] is Map<String, dynamic>
          ? textOrNull((json['approved_by'] as Map<String, dynamic>)['name'])
          : textOrNull(json['approved_by']),
      approvedAt: DateTime.tryParse('${json['approved_at'] ?? ''}')?.toLocal(),
      isMine: request['is_mine'] == true,
      canEdit: json['can_edit'] == true,
      canCancel: json['can_cancel'] == true,
      canVerify: json['can_verify'] == true,
    );
  }
}
