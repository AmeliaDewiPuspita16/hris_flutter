import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../../../../../../core/network/api_exception.dart';
import '../domain/opname_item.dart';
import '../domain/opname_record.dart';

/// Entry point of the stock opname feature: knows the endpoints and data
/// shapes, nothing about the UI.
class InventoryStockOpnameRepository {
  InventoryStockOpnameRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The rows that can be counted (item + location + system stock).
  Future<List<OpnameItem>> fetchCountableItems() async {
    final list = await _apiClient.getList(ApiConfig.opnameCountableItems);
    try {
      return [
        for (final row in list)
          OpnameItem.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } on FormatException catch (_) {
      throw const ApiException.server(
        'Unrecognized item data from the server. Contact the IT team.',
      );
    } on TypeError catch (_) {
      throw const ApiException.server(
        'Unrecognized item data from the server. Contact the IT team.',
      );
    }
  }

  /// All warehouses and their racks. Used to recognize scanned store codes
  /// (e.g. `STR00001`) and rack codes (e.g. `PUT00003`).
  Future<OpnameLocations> fetchLocations() async {
    final data = await _apiClient.get(ApiConfig.opnameOptions);
    final stores = data['stores'];
    if (stores is! List) return const OpnameLocations();

    final storeList = <OpnameStore>[];
    final racks = <OpnameRack>[];
    for (final store in stores.whereType<Map>()) {
      final storeId = _asInt(store['id']);
      final storeText = store['text']?.toString();
      if (storeId == null) continue;
      if (storeText != null) {
        storeList.add(OpnameStore(id: storeId, text: storeText));
      }
      final putaways = store['putaways'];
      if (putaways is! List) continue;
      for (final p in putaways.whereType<Map>()) {
        final id = _asInt(p['id']);
        final text = p['text']?.toString();
        if (id != null && text != null) {
          racks.add(OpnameRack(id: id, storeId: storeId, text: text));
        }
      }
    }
    return OpnameLocations(stores: storeList, racks: racks);
  }

  /// The Estate Material item whose label code (or internal reference) is
  /// [code], with the stock of every location holding it. Throws an
  /// [ApiException] whose message says so when no item has that code.
  Future<OpnameLookup> lookupItem(String code) async {
    final data = await _apiClient.get(
      '${ApiConfig.opnameLookup}?${Uri(queryParameters: {'code': code}).query}',
    );
    try {
      return OpnameLookup.fromJson(data);
    } on FormatException catch (_) {
      throw _unreadableItem;
    } on TypeError catch (_) {
      throw _unreadableItem;
    }
  }

  static const _unreadableItem = ApiException.server(
    'Unrecognized item data from the server. Contact the IT team.',
  );

  /// One page of opname history. A null [status] means all statuses.
  Future<OpnamePage> fetchHistory({
    OpnameStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      if (status == OpnameStatus.draft) 'status': 'draft',
      if (status == OpnameStatus.confirmed) 'status': 'confirmed',
      'page': '$page',
      'per_page': '$perPage',
    };
    // getEnvelope is used because the paging info (`meta`) sits next to
    // `data`.
    final envelope = await _apiClient.getEnvelope(
      '${ApiConfig.opnameBase}?${Uri(queryParameters: query).query}',
    );
    try {
      final data = envelope['data'] as List;
      final meta = envelope['meta'];
      return OpnamePage(
        items: [
          for (final row in data)
            OpnameSummary.fromJson(Map<String, dynamic>.from(row as Map)),
        ],
        currentPage: meta is Map ? (_asInt(meta['current_page']) ?? page) : page,
        lastPage: meta is Map ? (_asInt(meta['last_page']) ?? page) : page,
      );
    } on FormatException catch (_) {
      throw _unreadable;
    } on TypeError catch (_) {
      throw _unreadable;
    }
  }

  /// The full content of one opname, including its rows.
  Future<OpnameDetail> fetchDetail(int id) async {
    final data = await _apiClient.get('${ApiConfig.opnameBase}/$id');
    try {
      return OpnameDetail.fromJson(data);
    } on FormatException catch (_) {
      throw _unreadable;
    } on TypeError catch (_) {
      throw _unreadable;
    }
  }

  static const _unreadable = ApiException.server(
    'Unrecognized opname data from the server. Contact the IT team.',
  );

  /// Sends the count results to the server and returns the opname id.
  ///
  /// [confirm] = false  -> saved as a draft; stock is NOT changed yet.
  /// [confirm] = true   -> confirmed immediately: the stock at each location
  ///                       is set to the counted quantity; cannot be undone.
  Future<int?> submit({
    required List<OpnameItem> counted,
    required String countedBy,
    required bool confirm,
    String? notes,
  }) async {
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final data = await _apiClient.post(
      ApiConfig.opnameBase,
      body: {
        'opname_date': date,
        'counted_by': countedBy,
        if (notes != null) 'notes': notes,
        'confirm': confirm,
        'items': [
          for (final e in counted)
            if (e.isCounted) e.toSubmitJson(),
        ],
      },
    );
    return _asInt(data['id']);
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
