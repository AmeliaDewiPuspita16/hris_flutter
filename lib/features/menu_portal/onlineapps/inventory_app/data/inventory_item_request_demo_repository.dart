import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/page_meta.dart';
import '../domain/item_request_stock_option.dart';
import '../domain/item_request_entry.dart';
import '../domain/item_request_line.dart';
import '../domain/item_request_page.dart';
import '../domain/item_request_status.dart';

/// Repository Inventory > Request > Item Request yang masih memakai DATA DEMO
/// di memori, karena endpoint-nya belum tersedia.
///
/// Perubahan (tambah, edit, cancel, approve, reject) tersimpan selama
/// instance ini hidup, jadi alurnya bisa dicoba penuh. Data kembali ke awal
/// begitu layar Item Request ditutup. Layar Add/Edit harus memakai instance
/// yang SAMA dengan layar daftar (dioper lewat parameter `repository`).
class InventoryItemRequestDemoRepository {
  InventoryItemRequestDemoRepository() {
    for (final item in _catalog) {
      _stock[item.id] = item.stock ?? 0;
    }
    _requests.addAll(_seed());
  }

  /// Jeda buatan supaya skeleton dan loading state tampak seperti API sungguhan.
  static const _latency = Duration(milliseconds: 450);

  /// Requester "milik sendiri" pada data demo (sama dengan user di web).
  static const _me = 'Aditya Yudha Pratama';

  final Map<int, int> _stock = {};
  final List<_DemoRequest> _requests = [];

  /// Daftar "Request Items": SEMUA user, terbaru di atas.
  Future<ItemRequestPage> fetchRequests({
    int page = 1,
    int perPage = 20,
  }) async {
    await Future<void>.delayed(_latency);

    final all = _sorted();
    final total = all.length;
    final lastPage = total == 0 ? 1 : (total / perPage).ceil();
    final start = (page - 1) * perPage;
    final slice = start >= total
        ? <_DemoRequest>[]
        : all.sublist(start, (start + perPage).clamp(0, total));

    return ItemRequestPage(
      items: [for (final r in slice) _toItem(r)],
      pending: all.where((r) => r.isPending).length,
      counts: ItemRequestStatusCounts(
        pending: all.where((r) => r.isPending).length,
        approved: all
            .where((r) => r.status == ItemRequestStatus.codeApproved)
            .length,
        rejected: all
            .where((r) => r.status == ItemRequestStatus.codeRejected)
            .length,
      ),
      meta: PageMeta(
        currentPage: page,
        lastPage: lastPage,
        perPage: perPage,
        total: total,
      ),
    );
  }

  /// Antrean "Verification Requests": semua request pending.
  Future<ItemRequestPage> fetchVerifications({
    int page = 1,
    int perPage = 100,
  }) async {
    await Future<void>.delayed(_latency);

    final pending = _sorted().where((r) => r.isPending).toList();

    return ItemRequestPage(
      items: [for (final r in pending) _toItem(r)],
      pending: pending.length,
      meta: PageMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: perPage,
        total: pending.length,
      ),
    );
  }

  /// Barang untuk dropdown "Select Item".
  Future<List<ItemRequestStockOption>> fetchItems() async {
    await Future<void>.delayed(_latency);

    return [
      for (final item in _catalog)
        ItemRequestStockOption(
          id: item.id,
          code: item.code,
          name: item.name,
          unit: item.unit,
          stock: _stock[item.id],
        ),
    ];
  }

  /// Satu request (satu kode REQ) per baris, selalu atas nama user demo.
  /// Menolak jumlah yang melebihi stok, untuk mencoba tampilan galat.
  Future<void> create(List<ItemRequestLine> lines) async {
    await Future<void>.delayed(_latency);

    for (final line in lines) {
      final item = _itemById(line.itemId);
      final stock = _stock[line.itemId] ?? 0;
      if (line.quantity > stock) {
        throw ApiException.server(
          'Stock for ${item.title} is not enough (available: $stock ${item.unit}).',
        );
      }
    }

    for (final line in lines) {
      _requests.add(_DemoRequest(
        id: _nextId(),
        requester: _me,
        itemId: line.itemId,
        quantity: line.quantity.toInt(),
        description: line.reason.trim(),
        status: ItemRequestStatus.codePending,
        requestedAt: DateTime.now(),
      ));
    }
  }

  /// Hanya jumlah dan keterangan; barang terkunci.
  Future<void> update(
    int id, {
    required int quantity,
    required String description,
  }) async {
    await Future<void>.delayed(_latency);

    final request = _ownPending(id, 'edited');
    final stock = _stock[request.itemId] ?? 0;
    if (quantity > stock) {
      throw ApiException.server('Quantity exceeds the available stock ($stock).');
    }

    request
      ..quantity = quantity
      ..description = description.trim();
  }

  /// Tombol "Cancel": request milik sendiri yang masih pending dihapus.
  Future<void> cancel(int id) async {
    await Future<void>.delayed(_latency);

    final request = _ownPending(id, 'cancelled');
    _requests.remove(request);
  }

  /// Approve: status jadi approved dan stok barang berkurang.
  Future<void> approve(int id) async {
    await Future<void>.delayed(_latency);

    final request = _pending(id);
    request.status = ItemRequestStatus.codeApproved;
    final left = (_stock[request.itemId] ?? 0) - request.quantity;
    _stock[request.itemId] = left < 0 ? 0 : left;
  }

  Future<void> reject(int id, {String? reason}) async {
    await Future<void>.delayed(_latency);

    final request = _pending(id);
    request.status = ItemRequestStatus.codeRejected;
    request.rejectReason =
        reason != null && reason.trim().isNotEmpty ? reason.trim() : null;
  }

  // ---------------------------------------------------------------------------

  List<_DemoRequest> _sorted() =>
      [..._requests]..sort((a, b) => b.id.compareTo(a.id));

  int _nextId() =>
      _requests.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;

  _CatalogItem _itemById(int id) => _catalog.firstWhere((i) => i.id == id);

  _DemoRequest _pending(int id) {
    final request = _requests.where((r) => r.id == id).firstOrNull;
    if (request == null) {
      throw const ApiException.server('Request not found.');
    }
    if (!request.isPending) {
      throw const ApiException.server('This request has already been processed.');
    }
    return request;
  }

  _DemoRequest _ownPending(int id, String verb) {
    final request = _pending(id);
    if (request.requester != _me) {
      throw ApiException.server('Only your own requests can be $verb.');
    }
    return request;
  }

  ItemRequestEntry _toItem(_DemoRequest r) {
    final item = _itemById(r.itemId);
    final mine = r.requester == _me;

    return ItemRequestEntry(
      id: r.id,
      code: 'REQ${r.id.toString().padLeft(5, '0')}',
      requesterName: r.requester,
      itemId: item.id,
      itemCode: item.code,
      itemName: item.name,
      unit: item.unit,
      quantity: r.quantity,
      description: r.description,
      status: ItemRequestStatus(
        code: r.status,
        label: '${r.status[0].toUpperCase()}${r.status.substring(1)}',
      ),
      stock: _stock[item.id],
      rejectReason: r.rejectReason,
      requestedAt: r.requestedAt,
      isMine: mine,
      canEdit: mine && r.isPending,
      canCancel: mine && r.isPending,
    );
  }

  // --------------------------------- data demo --------------------------------

  static const _catalog = <_CatalogItem>[
    _CatalogItem(2, 'ITE00002', 'AMPLOP A3 COKLAT', 'PCS', 120),
    _CatalogItem(5, 'ITE00005', 'AMPLOP A3 LOGO', 'PCS', 80),
    _CatalogItem(1, 'ITE00001', 'AMPLOP A4 COKLAT (NO LOGO)', 'PCS', 200),
    _CatalogItem(92, 'ITE00092', 'AMPLOP A4 COKLAT LOGO', 'PCS', 150),
    _CatalogItem(121, 'ITE00121', 'Amplop Jendela', 'PCS', 60),
    _CatalogItem(3, 'ITE00003', 'AMPLOP KECIL COKLAT', 'PCS', 300),
    _CatalogItem(6, 'ITE00006', 'AMPLOP KECIL JENDELA LOGO', 'PCS', 90),
    _CatalogItem(4, 'ITE00004', 'AMPLOP PUTIH A4 LOGO', 'PCS', 110),
    _CatalogItem(94, 'ITE00094', 'AMPLOP PUTIH KECIL 110 x 230mm', 'PCS', 75),
    _CatalogItem(7, 'ITE00007', 'BATERAI AA', 'PCS', 48),
    _CatalogItem(8, 'ITE00008', 'BATERAI AAA', 'PCS', 40),
    _CatalogItem(97, 'ITE00097', 'BENDERA BIIE (90 cm x 135 cm)', 'PCS', 6),
    _CatalogItem(98, 'ITE00098', 'BENDERA K3 90 cm x 135 cm', 'PCS', 4),
    _CatalogItem(96, 'ITE00096', 'BENDERA MERAH PUTIH 120 cm x 180 cm', 'PCS', 5),
    _CatalogItem(9, 'ITE00009', 'BINDER CLIP 15 MM', 'BOX', 25),
    _CatalogItem(10, 'ITE00010', 'BINDER CLIP 19 MM', 'BOX', 30),
    _CatalogItem(38, 'ITE00038', 'GOBY 8401 HITAM', 'PCS', 36),
    _CatalogItem(46, 'ITE00046', 'KERTAS HVS A4 70', 'RIM', 85),
    _CatalogItem(61, 'ITE00061', 'PENA KENKO K-1 HITAM', 'PCS', 120),
    _CatalogItem(70, 'ITE00070', 'SIGN HERE', 'PACK', 14),
    _CatalogItem(95, 'ITE00095', 'PENA JOYKO GP-189', 'PCS', 96),
    _CatalogItem(107, 'ITE00107', 'ISOLASI BENING', 'PCS', 9),
    _CatalogItem(201, 'STAT00001', 'MAGAZINE HOLDER', 'PCS', 22),
  ];

  /// Waktu request terbaru pada data demo; request yang lebih lama mundur 9
  /// jam per nomor, jadi jam dan tanggalnya bervariasi.
  static final _seedBase = DateTime(2026, 11, 11, 11, 0);

  /// 27 request, terbaru di atas, meniru isi tabel di web.
  static List<_DemoRequest> _seed() {
    const p = ItemRequestStatus.codePending;
    const a = ItemRequestStatus.codeApproved;
    const r = ItemRequestStatus.codeRejected;

    _DemoRequest row(int id, String who, int item, int qty, String desc,
            String status, {String? reason}) =>
        _DemoRequest(
          id: id,
          requester: who,
          itemId: item,
          quantity: qty,
          description: desc,
          status: status,
          rejectReason: reason,
          requestedAt: _seedBase.subtract(Duration(hours: (558 - id) * 9)),
        );

    return [
      row(558, 'Adi Mufti Pradana', 70, 1, '', p),
      row(557, 'Imelda Ayu Kinanti', 70, 2, 'Operational FIN', p),
      row(556, 'Sauki Likar Arabi', 61, 10,
          'dear team HR , saya mau minta pena 1 kotak ,untuk kebutuhan fire safey (mencatat kegiatan dijurnal) terima kasih.', p),
      row(555, 'M. Gumri', 95, 11,
          'dear team HR , saya mau minta pena 1 kotak untuk kebutuhan operasional (tulis jurnal) fire safety terima kasih', r,
          reason: 'Minta per box tidak tersedia, silakan request per pcs.'),
      row(554, _me, 107, 1, 'Untuk operasional IT', p),
      row(553, 'Admin IMS', 46, 1, 'Operasional Departemen', p),
      row(552, 'Butyanuriza', 201, 5, 'untuk penyimpanan dokumen kontrak', p),
      row(551, 'Butyanuriza', 38, 3, 'untuk penyimpanan dokumen kontrak', p),
      row(550, 'HSE Admin', 46, 1, 'Untuk Kebutuhan administrasi HSE', a),
      row(549, 'Adi Mufti Pradana', 46, 1, 'print dokumen HSE', r),
      row(548, 'Imelda Ayu Kinanti', 10, 2, 'Kebutuhan arsip bulanan', a),
      row(547, _me, 7, 4, 'Untuk remote dan mouse wireless tim IT', a),
      row(546, 'Heriyanto', 10, 2, '', p),
      row(545, 'Sauki Likar Arabi', 92, 20, 'Pengiriman surat tenant', a),
      row(544, 'Admin IMS', 94, 10, 'Surat undangan rapat', a),
      row(543, 'HSE Admin', 98, 1, 'Pengganti bendera K3 yang robek', a),
      row(542, 'Butyanuriza', 9, 3, 'Operasional legal', a),
      row(541, _me, 8, 6, 'Untuk keyboard dan perangkat IT', p),
      row(540, 'M. Gumri', 61, 5, 'Fire safety checklist harian', a),
      row(539, 'Heriyanto', 1, 15, 'Pengiriman dokumen proyek', a),
      row(538, 'Imelda Ayu Kinanti', 46, 3, 'Print laporan akhir bulan', a),
      row(537, 'Adi Mufti Pradana', 5, 10, 'Dokumen resmi berlogo', r,
          reason: 'Stok amplop logo dicadangkan untuk surat resmi direksi.'),
      row(536, 'Admin IMS', 3, 30, 'Operasional departemen', a),
      row(535, 'Sauki Likar Arabi', 96, 1, 'Upacara 17 Agustus', a),
      row(534, _me, 46, 2, 'Print dokumen IT dan inventaris', a),
      row(533, 'HSE Admin', 97, 1, 'Pengganti bendera BIIE', a),
      row(532, 'Heriyanto', 121, 5, 'Surat tagihan tenant', a),
    ];
  }
}

class _CatalogItem {
  const _CatalogItem(this.id, this.code, this.name, this.unit, this.stock);

  final int id;
  final String code;
  final String name;
  final String unit;
  final int stock;

  String get title => '$code - $name';
}

class _DemoRequest {
  _DemoRequest({
    required this.id,
    required this.requester,
    required this.itemId,
    required this.quantity,
    required this.description,
    required this.status,
    required this.requestedAt,
    this.rejectReason,
  });

  final int id;
  final DateTime requestedAt;
  final String requester;
  final int itemId;
  int quantity;
  String description;
  String status;
  String? rejectReason;

  bool get isPending => status == ItemRequestStatus.codePending;
}
