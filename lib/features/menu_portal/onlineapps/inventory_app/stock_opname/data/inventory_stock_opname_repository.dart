import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../../../../../../core/network/api_exception.dart';
import '../domain/opname_item.dart';
import '../domain/opname_record.dart';

/// Entry point of the stock opname feature: knows the endpoints and data
/// shapes, nothing about the UI.
///
/// Every endpoint is for InventoryAdmin / Admin only; any other account gets
/// a 403 whose message is meant to be shown as-is.
class InventoryStockOpnameRepository {
  InventoryStockOpnameRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The rows that can be counted (item + location + system stock).
  ///
  /// Pass [opnameId] (a draft) to get that draft's rows back with their
  /// `counted_qty` and `notes`, so the draft can be continued.
  Future<List<OpnameItem>> fetchCountableItems({int? opnameId}) async {
    final path = opnameId == null
        ? ApiConfig.opnameCountableItems
        : '${ApiConfig.opnameCountableItems}?'
            '${Uri(queryParameters: {'opname_id': '$opnameId'}).query}';
    final list = await _apiClient.getList(path);
    try {
      return [
        for (final row in list)
          OpnameItem.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } on FormatException catch (_) {
      throw _unreadableItem;
    } on TypeError catch (_) {
      throw _unreadableItem;
    }
  }

  /// The stores the user may count and their sub stores
  /// (`data.stores[].subStores[]`).
  Future<OpnameLocations> fetchLocations() async {
    final data = await _apiClient.get(ApiConfig.opnameOptions);
    final stores = data['stores'];
    if (stores is! List) return const OpnameLocations();

    final storeList = <OpnameStore>[];
    final subStores = <OpnameSubStore>[];
    for (final store in stores.whereType<Map>()) {
      final storeId = _asInt(store['id']);
      final storeText = store['text']?.toString();
      if (storeId == null) continue;
      if (storeText != null) {
        storeList.add(OpnameStore(id: storeId, text: storeText));
      }
      final subs = store['subStores'];
      if (subs is! List) continue;
      for (final s in subs.whereType<Map>()) {
        final id = _asInt(s['id']);
        final text = s['text']?.toString();
        if (id != null && text != null) {
          subStores.add(OpnameSubStore(id: id, storeId: storeId, text: text));
        }
      }
    }
    return OpnameLocations(stores: storeList, subStores: subStores);
  }

  /// The item whose label code is [code], with the stock of every location
  /// holding it. Throws an [ApiException] whose message says so when no item
  /// has that code (404).
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
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      if (status == OpnameStatus.draft) 'status': 'draft',
      if (status == OpnameStatus.confirmed) 'status': 'confirmed',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
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
    final data = await _apiClient.get(ApiConfig.opnameDetail(id));
    return _detail(data);
  }

  /// Saves the count results and returns the saved opname.
  ///
  /// - [opnameId] null  -> creates a new opname (`POST`).
  /// - [opnameId] given -> replaces the content of that draft (`PUT`). Every
  ///   row must be sent again: rows that are left out are deleted.
  ///
  /// [confirm] = false -> saved as a draft; stock is NOT changed.
  /// [confirm] = true  -> confirmed immediately: the stock at each location
  ///                      is set to the counted quantity; cannot be undone.
  ///
  /// [storeLocationId] / [subStoreId] are the optional scope of the header.
  /// When given, every row must lie inside it, so only pass them when that
  /// is true. The counter is always the logged-in user (set by the server).
  Future<OpnameDetail> saveCount({
    required List<OpnameItem> counted,
    required bool confirm,
    int? opnameId,
    DateTime? date,
    String? notes,
    int? storeLocationId,
    int? subStoreId,
  }) async {
    final body = <String, dynamic>{
      'opname_date': _formatDate(date ?? DateTime.now()),
      'store_location_id': storeLocationId,
      'sub_store_id': subStoreId,
      if (notes != null) 'notes': notes,
      'confirm': confirm,
      'items': [
        for (final e in counted)
          if (e.isCounted && e.isCountable) e.toSubmitJson(),
      ],
    };
    final data = opnameId == null
        ? await _apiClient.post(ApiConfig.opnameBase, body: body)
        : await _apiClient.put(ApiConfig.opnameDetail(opnameId), body: body);
    return _detail(data);
  }

  /// Confirms a draft. CHANGES STOCK: each location is set to its counted
  /// quantity and the differences are booked. Cannot be undone.
  Future<OpnameDetail> confirm(int id) async {
    final data = await _apiClient.post(ApiConfig.opnameConfirm(id));
    return _detail(data);
  }

  /// Deletes a draft with its rows. Confirmed opnames cannot be deleted (422).
  Future<void> delete(int id) async {
    await _apiClient.delete(ApiConfig.opnameDetail(id));
  }

  OpnameDetail _detail(Map<String, dynamic> data) {
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

  static String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
