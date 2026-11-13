import 'package:equatable/equatable.dart';

/// A single count row: one item at one location.
///
/// On the server a row is identified by item + warehouse + rack (the `key`
/// field in the API, e.g. `138|0:0`). The same item on two racks is two
/// different rows, so [id] here uses that `key`, not the item id.
class OpnameItem extends Equatable {
  /// The server's `key`. Unique per row, used as the id in the UI.
  final String id;

  /// The item id on the server, sent back when saving the count.
  final int itemId;

  /// Null = the item is not placed in any warehouse yet ("Unassigned").
  final int? storeLocationId;

  /// Null = the item is in a warehouse but not on a specific rack.
  final int? putawayId;

  /// The item code printed on its QR / barcode label (e.g. `ESTM00284`).
  final String code;

  /// The item's own reference (e.g. `ABKA001`); scanning it also finds the
  /// item. Null if the item has none.
  final String? internalReference;

  final String name;
  final String unit;
  final String location;

  /// Stock according to the system (the reference value).
  final double systemQty;

  /// The physically counted quantity; null if not counted yet.
  final double? countedQty;

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
    this.putawayId,
    this.countedQty,
  });

  /// Whether a scanned / typed code is this item's code or reference.
  bool matchesCode(String code) {
    final c = code.trim().toLowerCase();
    return this.code.toLowerCase() == c ||
        (internalReference != null && internalReference!.toLowerCase() == c);
  }

  bool get isCounted => countedQty != null;

  /// Difference of counted - system. Positive = surplus, negative =
  /// shortage. Null if not counted yet.
  double? get difference => countedQty == null ? null : countedQty! - systemQty;

  OpnameItem withCount(double qty) => OpnameItem(
    id: id,
    itemId: itemId,
    storeLocationId: storeLocationId,
    putawayId: putawayId,
    code: code,
    internalReference: internalReference,
    name: name,
    unit: unit,
    location: location,
    systemQty: systemQty,
    countedQty: qty,
  );

  /// From one `data` element of `GET .../stock-opname/countable-items`.
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
      putawayId: _asInt(json['putaway_id']),
      code: item['code']?.toString() ?? '',
      internalReference: _nonEmpty(item['internal_reference']),
      name: item['name']?.toString() ?? '',
      unit: item['unit']?.toString() ?? '',
      location: json['location_label']?.toString() ?? 'Unassigned',
      systemQty: _asDouble(json['system_qty']) ?? 0,
      countedQty: _asDouble(json['counted_qty']),
    );
  }

  /// The shape `POST .../stock-opname` expects for a single row.
  Map<String, dynamic> toSubmitJson() => {
    'item_id': itemId,
    'store_location_id': storeLocationId,
    'putaway_id': putawayId,
    'counted_qty': countedQty,
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
        putawayId,
        code,
        internalReference,
        name,
        unit,
        location,
        systemQty,
        countedQty,
      ];
}

/// A rack from `GET .../stock-opname/options`. [text] looks like
/// `PUT00003 - Test Rak`; [code] is the part before " - ".
class OpnameRack extends Equatable {
  final int id;
  final int storeId;
  final String text;

  const OpnameRack({
    required this.id,
    required this.storeId,
    required this.text,
  });

  String get code => _codeOf(text);

  String get name => _nameOf(text);

  @override
  List<Object?> get props => [id, storeId, text];
}

/// A store (warehouse) from `GET .../stock-opname/options`. [text] looks like
/// `STR00001 - Gudang Utama Estate`; [code] is the part before " - ".
class OpnameStore extends Equatable {
  final int id;
  final String text;

  const OpnameStore({required this.id, required this.text});

  String get code => _codeOf(text);

  /// The store name as the server writes it in location labels.
  String get name => _nameOf(text).replaceAll(' (inactive)', '');

  @override
  List<Object?> get props => [id, text];
}

/// The stores and racks that can be scanned, from one options call.
class OpnameLocations {
  final List<OpnameStore> stores;
  final List<OpnameRack> racks;

  const OpnameLocations({this.stores = const [], this.racks = const []});
}

String _codeOf(String text) {
  final i = text.indexOf(' - ');
  return (i < 0 ? text : text.substring(0, i)).trim();
}

String _nameOf(String text) {
  final i = text.indexOf(' - ');
  return (i < 0 ? text : text.substring(i + 3)).trim();
}

/// `GET .../stock-opname/lookup?code=`: one item found by the code on its
/// label (or its internal reference), with every location holding it.
class OpnameLookup extends Equatable {
  final int itemId;
  final String code;
  final String? internalReference;
  final String name;
  final String unit;
  final String? category;
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
      totalQty: OpnameItem._asDouble(json['total_qty']) ?? 0,
      locations: [
        if (locations is List)
          for (final l in locations.whereType<Map>())
            OpnameLookupLocation(
              key: l['key']?.toString() ?? '',
              storeLocationId: OpnameItem._asInt(l['store_location_id']),
              putawayId: OpnameItem._asInt(l['putaway_id']),
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
    required int? putawayId,
    required String label,
  }) {
    final existing = locations
        .where((l) =>
            l.storeLocationId == storeLocationId && l.putawayId == putawayId)
        .firstOrNull;
    return OpnameItem(
      id: '$itemId|${storeLocationId ?? 0}:${putawayId ?? 0}',
      itemId: itemId,
      storeLocationId: storeLocationId,
      putawayId: putawayId,
      code: code,
      internalReference: internalReference,
      name: name,
      unit: unit,
      location: existing?.label ?? label,
      systemQty: existing?.systemQty ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [itemId, code, internalReference, name, unit, category, totalQty, locations];
}

class OpnameLookupLocation extends Equatable {
  final String key;
  final int? storeLocationId;
  final int? putawayId;
  final String label;
  final double systemQty;

  const OpnameLookupLocation({
    required this.key,
    required this.label,
    required this.systemQty,
    this.storeLocationId,
    this.putawayId,
  });

  @override
  List<Object?> get props => [key, storeLocationId, putawayId, label, systemQty];
}
