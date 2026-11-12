import 'stationery_item_option.dart';
import 'stationery_request_status.dart';

/// Hak akses user di Item Request, dari `data.permissions`. Menggantikan
/// tebakan lewat 401/403 untuk menentukan siapa yang melihat tab Verification.
class ItemRequestPermissions {
  const ItemRequestPermissions({
    this.canSeeOthers = false,
    this.canVerify = false,
  });

  /// Inventory Admin / Reviewer / Admin: melihat line milik orang lain pada
  /// kategori yang boleh dikelolanya, dan antrean verifikasi.
  final bool canSeeOthers;

  /// Inventory Admin / Admin: boleh approve / reject. Reviewer hanya melihat.
  final bool canVerify;

  /// Tab Verification tampil untuk siapa pun yang boleh melihat antreannya
  /// (server membalas 403 untuk akun lain).
  bool get canOpenVerification => canSeeOthers || canVerify;

  factory ItemRequestPermissions.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return const ItemRequestPermissions();

    return ItemRequestPermissions(
      canSeeOthers: raw['can_see_others'] == true,
      canVerify: raw['can_verify'] == true,
    );
  }
}

/// Isi `GET .../inventory/item-request/options`.
///
/// ```json
/// "data": {
///   "items": [{"id": 7, "code": "ITE00007", "name": "BATERAI AA", ...}],
///   "statuses": [{"code": "pending", "label": "Pending"}, ...],
///   "permissions": {"can_see_others": false, "can_verify": false}
/// }
/// ```
class ItemRequestOptions {
  const ItemRequestOptions({
    required this.items,
    required this.statuses,
    required this.permissions,
  });

  /// Barang aktif yang boleh diminta.
  final List<StationeryItemOption> items;

  /// Pilihan filter status untuk daftar (kode + label dari server).
  final List<StationeryRequestStatus> statuses;

  final ItemRequestPermissions permissions;

  factory ItemRequestOptions.fromJson(Map<String, dynamic> json) {
    final items = <StationeryItemOption>[];
    for (final row in (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()) {
      try {
        items.add(StationeryItemOption.fromJson(row));
      } on FormatException {
        // Barang tanpa id tidak bisa diminta; lewati, sisanya tetap tampil.
      }
    }

    return ItemRequestOptions(
      items: items,
      statuses: [
        for (final row in (json['statuses'] as List<dynamic>? ?? const []))
          StationeryRequestStatus.fromJson(row),
      ],
      permissions: ItemRequestPermissions.fromJson(json['permissions']),
    );
  }
}
