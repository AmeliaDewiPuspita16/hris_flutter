import 'json_value.dart';

/// Barang atau jasa yang diminta, dari `item_type`.
enum PrItemKind {
  goods,
  service,
  other;

  static PrItemKind fromCode(String code) => switch (code) {
        'goods' => PrItemKind.goods,
        'service' => PrItemKind.service,
        _ => PrItemKind.other,
      };

  String get label => switch (this) {
        PrItemKind.goods => 'Goods',
        PrItemKind.service => 'Service',
        PrItemKind.other => 'Lainnya',
      };
}

/// Satu baris item di dalam sebuah Purchase Requisition.
class PrLineItem {
  const PrLineItem({
    required this.lineNumber,
    required this.kind,
    required this.description,
    required this.quantity,
    required this.uom,
    required this.unitPrice,
    required this.totalPrice,
    this.specification,
    this.glAccount,
    this.segment,
    this.notes,
  });

  /// Nomor baris dari server. Boleh meloncat (1, 3, …) karena baris bisa
  /// dihapus di sisi web — jadi dipakai apa adanya, bukan indeks daftar.
  final int lineNumber;

  final PrItemKind kind;
  final String description;
  final String? specification;

  /// `num`, bukan `int`: server bisa mengirim kuantitas pecahan.
  final num quantity;

  /// Satuan seperti "pcs", "set", "BOX".
  final String uom;

  final int unitPrice;

  /// Dari `total_price` server, bukan hasil qty x harga satuan — server yang
  /// otoritatif atas pembulatan dan diskonnya.
  final int totalPrice;

  final String? glAccount;
  final String? segment;
  final String? notes;

  /// Ex: "1 set", "101 pcs". Kuantitas bulat ditulis tanpa koma.
  String get quantityLabel {
    final value = quantity is int || quantity == quantity.roundToDouble()
        ? quantity.round().toString()
        : '$quantity';
    return '$value $uom';
  }

  factory PrLineItem.fromJson(Map<String, dynamic> json) {
    final lineNumber = json['line_number'];
    final quantity = json['quantity'];

    return PrLineItem(
      lineNumber: lineNumber is int ? lineNumber : 0,
      kind: PrItemKind.fromCode('${json['item_type'] ?? ''}'),
      description: '${json['description'] ?? ''}',
      specification: textOrNull(json['specification']),
      quantity: quantity is num ? quantity : 0,
      uom: '${json['uom'] ?? ''}',
      unitPrice: amountOrZero(json['unit_price']),
      totalPrice: amountOrZero(json['total_price']),
      glAccount: textOrNull(json['gl_account']),
      segment: textOrNull(json['segment']),
      notes: textOrNull(json['notes']),
    );
  }
}
