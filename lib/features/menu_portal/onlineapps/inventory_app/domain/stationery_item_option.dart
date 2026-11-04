import '../../../../../core/utils/json_value.dart';

/// Satu barang stationery yang bisa dipilih di form request
/// (`GET .../inventory/stationery/items`), mis.
/// `ITE00107 - ISOLASI BENING (PCS)`.
class StationeryItemOption {
  const StationeryItemOption({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.stock,
  });

  final int id;

  /// Kode barang, mis. `ITE00107` atau `STAT00001`.
  final String code;
  final String name;

  /// Satuan, mis. `PCS`, `RIM`, `BOX`, `PACK`.
  final String unit;

  /// Stok saat ini; null kalau server tidak mengirimnya.
  final int? stock;

  /// `ITE00107 - ISOLASI BENING`
  String get title => '$code - $name';

  /// `ITE00107 - ISOLASI BENING (PCS)` — format yang sama dengan dropdown web.
  String get displayLabel => unit.isEmpty ? title : '$title ($unit)';

  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id, request
  /// untuk barang ini tidak bisa dikirim.
  factory StationeryItemOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons barang stationery tidak memuat id');
    }

    return StationeryItemOption(
      id: id,
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      unit: '${json['unit'] ?? ''}',
      stock: _optionalInt(json['stock']),
    );
  }
}

int? _optionalInt(Object? raw) {
  if (raw is num) return raw.toInt();
  final text = textOrNull(raw);
  return text == null ? null : int.tryParse(text);
}
