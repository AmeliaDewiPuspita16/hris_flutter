import '../../../../../core/utils/json_value.dart';

/// Satu barang yang bisa dipilih di form request
/// (`GET .../inventory/item-request/options` -> `data.items[]`), mis.
/// `ITE00107 - ISOLASI BENING (PCS)`.
class ItemRequestStockOption {
  const ItemRequestStockOption({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.stock,
    this.imageUrl,
    this.category,
    this.subtext,
  });

  final int id;

  /// Kode barang, mis. `ITE00107` atau `STAT00001`.
  final String code;
  final String name;

  /// Satuan, mis. `PCS`, `RIM`, `BOX`, `PACK`.
  final String unit;

  /// Total stok di SEMUA store (boleh desimal); null kalau server tidak
  /// mengirimnya.
  final num? stock;

  /// Foto barang; null/kosong bila belum ada.
  final String? imageUrl;

  /// Nama kategori barang.
  final String? category;

  /// Departemen Inventory Admin yang mengurus barang ini (dan store yang
  /// memegang stok terbanyak), dari `subtext`.
  final String? subtext;

  /// `ITE00107 - ISOLASI BENING`
  String get title => '$code - $name';

  /// `ITE00107 - ISOLASI BENING (PCS)` — format yang sama dengan dropdown web.
  String get displayLabel => unit.isEmpty ? title : '$title ($unit)';

  /// `85` atau `2.5` — tanpa ".0" untuk angka bulat. "-" bila stok tidak
  /// diketahui.
  String get stockLabel => formatInventoryQuantity(stock);

  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id, request
  /// untuk barang ini tidak bisa dikirim.
  factory ItemRequestStockOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons barang inventory tidak memuat id');
    }

    return ItemRequestStockOption(
      id: id,
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      unit: '${json['unit'] ?? ''}',
      stock: _optionalNum(json['stock']),
      imageUrl: textOrNull(json['image_url']),
      category: textOrNull(json['category']),
      subtext: textOrNull(json['subtext']),
    );
  }
}

/// Jumlah/stok untuk tampilan: bilangan bulat tanpa ".0", desimal apa
/// adanya (maks 4 angka di belakang koma, tanpa nol di ujung).
String formatInventoryQuantity(num? value) {
  if (value == null) return '-';
  if (value == value.truncate()) return value.truncate().toString();

  var text = value.toStringAsFixed(4);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
}

/// Server bisa mengirim angka atau teks ("12.5") untuk kolom desimal.
num? _optionalNum(Object? raw) {
  if (raw is num) return raw;
  final text = textOrNull(raw);
  return text == null ? null : num.tryParse(text);
}
