import 'package:equatable/equatable.dart';

/// A single count row: one item at one location.
///
/// On the server a row is identified by item + store + sub store (the `key`
/// field in the API, e.g. `41|3:7`). The same item on two sub stores is two
/// different rows, so [id] here uses that `key`, not the item id.
class OpnameItem extends Equatable {
  /// The server's `key`. Unique per row, used as the id in the UI.
  final String id;

  /// The item id on the server, sent back when saving the count.
  final int itemId;

  /// Null = the stock is not placed in any store yet ("Unassigned"). Such a
  /// row is shown but cannot be counted (see [isCountable]).
  final int? storeLocationId;

  /// Null = the row is the store itself, not a specific sub store (shelf).
  final int? subStoreId;

  /// The item code printed on its QR / barcode label (e.g. `BIIE-ATK-0002`).
  final String code;

  /// Optional second code that also finds the item. The current API does not
  /// send it; kept so older data still parses.
  final String? internalReference;

  final String name;
  final String unit;
  final String location;

  /// Stock according to the system (the reference value).
  final double systemQty;

  /// The physically counted quantity; null if not counted yet.
  final double? countedQty;

  /// Per-row note (max 255 characters). Kept so a draft that is edited and
  /// saved again does not lose the notes it already had.
  final String? notes;

  const OpnameItem({
    required this.id,
    required this.itemId,
    required this.code,
    required this.name,
    required this.unit,
    required this.location,
    required this.systemQty,
    this.internalReference,
    this.storeLocationId,
    this.subStoreId,
    this.countedQty,
    this.notes,
  });

  /// Whether a scanned / typed code is this item's code or reference.
  bool matchesCode(String code) {
    final c = code.trim().toLowerCase();
    return this.code.toLowerCase() == c ||
        (internalReference != null && internalReference!.toLowerCase() == c);
  }

  bool get isCounted => countedQty != null;

  /// Stock without a store cannot be counted: the server rejects it. Move the
  /// stock into a store in the portal first.
  bool get isCountable => storeLocationId != null;

  /// Difference of counted - system. Positive = surplus, negative =
  /// shortage. Null if not counted yet.
  double? get difference => countedQty == null ? null : countedQty! - systemQty;

  OpnameItem withCount(double qty) => OpnameItem(
    id: id,
    itemId: itemId,
    storeLocationId: storeLocationId,
    subStoreId: subStoreId,
    code: code,
    internalReference: internalReference,
    name: name,
    unit: unit,
    location: location,
    systemQty: systemQty,
    countedQty: qty,
    notes: notes,
  );

  /// From one `data` element of `GET .../stock-opname/countable-items`, or
  /// one element of `items` in an opname detail.
  ///
  /// Throws [FormatException] if the shape is not recognized, so the
  /// repository can turn it into a clear error message.
  factory OpnameItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    final key = json['key'];
    if (item is! Map || key is! String) {
      throw const FormatException('Incomplete countable-items row');
    }
    final itemId = _asInt(item['id']);
    if (itemId == null) {
      throw const FormatException('Missing item.id');
    }
    return OpnameItem(
      id: key,
      itemId: itemId,
      storeLocationId: _asInt(json['store_location_id']),
      subStoreId: _asInt(json['sub_store_id']),
      code: item['code']?.toString() ?? '',
      internalReference: _nonEmpty(item['internal_reference']),
      name: item['name']?.toString() ?? '',
      unit: item['unit']?.toString() ?? '',
      location: json['location_label']?.toString() ?? 'Unassigned',
      systemQty: _asDouble(json['system_qty']) ?? 0,
      countedQty: _asDouble(json['counted_qty']),
      notes: _nonEmpty(json['notes']),
    );
  }

  /// The shape `POST` / `PUT .../stock-opname` expects for a single row.
  /// `sub_store_id: null` means "the store itself". Quantities take at most
  /// 4 decimals.
  Map<String, dynamic> toSubmitJson() => {
    'item_id': itemId,
    'store_location_id': storeLocationId,
    'sub_store_id': subStoreId,
    'counted_qty': double.parse(countedQty!.toStringAsFixed(4)),
    if (notes != null) 'notes': notes,
  };

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String? _nonEmpty(dynamic v) {
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        storeLocationId,
        subStoreId,
        code,
        internalReference,
        name,
        unit,
        location,
        systemQty,
        countedQty,
        notes,
      ];
}

/// A sub store (shelf) from `GET .../stock-opname/options`
/// (`stores[].subStores[]`). Unlike the old API its [text] carries no code.
class OpnameSubStore extends Equatable {
  final int id;
  final int storeId;
  final String text;

  const OpnameSubStore({
    required this.id,
    required this.storeId,
    required this.text,
  });

  @override
  List<Object?> get props => [id, storeId, text];
}

/// A store from `GET .../stock-opname/options`. [text] is the plain store
/// name (e.g. `Lantai 2 Wisma`), the same as in the location labels.
class OpnameStore extends Equatable {
  final int id;
  final String text;

  const OpnameStore({required this.id, required this.text});

  @override
  List<Object?> get props => [id, text];
}

/// The stores and sub stores the user may count, from one options call.
class OpnameLocations {
  final List<OpnameStore> stores;
  final List<OpnameSubStore> subStores;

  const OpnameLocations({this.stores = const [], this.subStores = const []});
}

/// `GET .../stock-opname/lookup?code=`: one item found by the code on its
/// label, with every location holding it.
class OpnameLookup extends Equatable {
  final int itemId;
  final String code;
  final String? internalReference;
  final String name;
  final String unit;
  final String? category;
  final double? minStock;
  final double totalQty;
  final List<OpnameLookupLocation> locations;

  const OpnameLookup({
    required this.itemId,
    required this.code,
    required this.name,
    required this.unit,
    required this.totalQty,
    required this.locations,
    this.internalReference,
    this.category,
    this.minStock,
  });

  factory OpnameLookup.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    if (item is! Map) throw const FormatException('Missing item');
    final itemId = OpnameItem._asInt(item['id']);
    if (itemId == null) throw const FormatException('Missing item.id');
    final locations = json['locations'];
    return OpnameLookup(
      itemId: itemId,
      code: item['code']?.toString() ?? '',
      internalReference: OpnameItem._nonEmpty(item['internal_reference']),
      name: item['name']?.toString() ?? '',
      unit: item['unit']?.toString() ?? '',
      category: OpnameItem._nonEmpty(item['category']),
      minStock: OpnameItem._asDouble(item['min_stock']),
      totalQty: OpnameItem._asDouble(json['total_qty']) ?? 0,
      locations: [
        if (locations is List)
          for (final l in locations.whereType<Map>())
            OpnameLookupLocation(
              key: l['key']?.toString() ?? '',
              storeLocationId: OpnameItem._asInt(l['store_location_id']),
              subStoreId: OpnameItem._asInt(l['sub_store_id']),
              label: l['location_label']?.toString() ?? 'Unassigned',
              systemQty: OpnameItem._asDouble(l['system_qty']) ?? 0,
            ),
      ],
    );
  }

  /// A count row for this item at one location ([systemQty] there, 0 if the
  /// item has no stock row at that location yet).
  OpnameItem rowAt({
    required int? storeLocationId,
    required int? subStoreId,
    required String label,
  }) {
    final existing = locations
        .where((l) =>
            l.storeLocationId == storeLocationId && l.subStoreId == subStoreId)
        .firstOrNull;
    return OpnameItem(
      id: '$itemId|${storeLocationId ?? 0}:${subStoreId ?? 0}',
      itemId: itemId,
      storeLocationId: storeLocationId,
      subStoreId: subStoreId,
      code: code,
      internalReference: internalReference,
      name: name,
      unit: unit,
      location: existing?.label ?? label,
      systemQty: existing?.systemQty ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        itemId,
        code,
        internalReference,
        name,
        unit,
        category,
        minStock,
        totalQty,
        locations,
      ];
}

class OpnameLookupLocation extends Equatable {
  final String key;
  final int? storeLocationId;
  final int? subStoreId;
  final String label;
  final double systemQty;

  const OpnameLookupLocation({
    required this.key,
    required this.label,
    required this.systemQty,
    this.storeLocationId,
    this.subStoreId,
  });

  /// Stock without a store cannot be counted.
  bool get isCountable => storeLocationId != null;

  @override
  List<Object?> get props => [key, storeLocationId, subStoreId, label, systemQty];
}
