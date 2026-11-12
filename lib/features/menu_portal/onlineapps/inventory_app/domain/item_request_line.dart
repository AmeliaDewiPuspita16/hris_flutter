/// Satu baris isian di form Add Request (barang + jumlah + keterangan).
/// Satu submit boleh berisi beberapa baris dan dikirim sebagai
/// satu request (`POST /item-request` dengan `items[]`); server
/// membuat SATU kode REQ yang berisi semua baris itu sebagai line.
class ItemRequestLine {
  const ItemRequestLine({
    required this.itemId,
    required this.quantity,
    required this.reason,
  });

  final int itemId;

  /// Lebih dari 0, boleh desimal sampai 4 angka di belakang koma.
  final num quantity;

  final String reason;

  Map<String, Object?> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'reason': reason.trim(),
      };
}

/// Membaca isian jumlah dari form: `2`, `2.5`, atau `2,5` (koma dianggap
/// titik desimal). Null bila bukan angka atau lebih dari 4 angka di belakang
/// koma — batas yang sama dengan server. Bilangan bulat dikembalikan sebagai
/// `int` supaya terkirim `2`, bukan `2.0`.
///
/// Nilai 0 ikut dikembalikan; pemeriksaan "harus lebih dari 0" ada di
/// pemanggil.
num? parseInventoryQuantity(String text) {
  final raw = text.trim();
  if (!RegExp(r'^\d+([.,]\d{1,4})?$').hasMatch(raw)) return null;

  final value = num.parse(raw.replaceAll(',', '.'));
  return value == value.truncate() ? value.truncate() : value;
}
