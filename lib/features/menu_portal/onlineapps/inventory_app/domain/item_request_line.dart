/// Satu baris isian di form Add Request (barang + jumlah + keterangan).
/// Satu submit boleh berisi beberapa baris ("Add Form" di web); server
/// membuat satu request (satu kode REQ) per baris.
class ItemRequestLine {
  const ItemRequestLine({
    required this.itemId,
    required this.quantity,
    this.description = '',
  });

  final int itemId;
  final int quantity;
  final String description;

  Map<String, Object?> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'description': description.trim(),
      };
}
