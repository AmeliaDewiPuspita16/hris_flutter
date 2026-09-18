/// Barang atau jasa yang diminta — satu baris di tabel ITEMS versi web.
enum PrItemKind {
  goods,
  service;

  String get label => switch (this) {
        PrItemKind.goods => 'Goods',
        PrItemKind.service => 'Service',
      };
}

/// Satu baris item di dalam sebuah Purchase Requisition.
class PrLineItem {
  const PrLineItem({
    required this.description,
    required this.kind,
    required this.qty,
    required this.unit,
    required this.estPrice,
    this.glAccount,
  });

  final String description;
  final PrItemKind kind;
  final int qty;

  /// Satuan seperti "BOX", "PCS", "UNIT".
  final String unit;

  /// Harga satuan perkiraan, dalam Rupiah penuh.
  final int estPrice;

  /// Nomor GL Account. Null selama bagian Finance belum mengisinya —
  /// di web ditampilkan sebagai "—".
  final String? glAccount;

  /// Dihitung, bukan disimpan: subtotal tidak boleh bisa berbeda dari
  /// qty x harga satuan.
  int get subtotal => qty * estPrice;
}
