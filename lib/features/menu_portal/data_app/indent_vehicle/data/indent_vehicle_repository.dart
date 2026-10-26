import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/page_meta.dart';
import '../domain/indent_approval_item.dart';
import '../domain/indent_assigned_item.dart';
import '../domain/indent_driver.dart';
import '../domain/indent_json.dart';
import '../domain/indent_pending_item.dart';
import '../domain/indent_request_item.dart';
import '../domain/indent_request_page.dart';

/// pintu ke API Indent Vehicle. Repository ini akan bertambah satu method
/// untuk tiap endpoint yang kita sambungkan.
class IndentVehicleRepository {
  IndentVehicleRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// id driver -> nama, diingat setelah berhasil dimuat supaya halaman 2,
  /// 3, dan seterusnya tidak mengambil ulang daftar driver yang sama.
  /// Diperbarui lagi setiap kali halaman 1 dimuat (muat awal / refresh).
  Map<int, String>? _driverNamesCache;

  Future<List<IndentDriver>> fetchDrivers() async {
    final raw = await _apiClient.getRawList(ApiConfig.indentDrivers);
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) IndentDriver.fromJson(item),
    ];
  }

  /// Satu halaman untuk tab "List of User Requests" — `GET /api/indent`,
  /// berisi request SEMUA user, urutan dari server (terbaru di atas).
  ///
  /// Bentuk respons: `{message, status, data: {current_page, last_page,
  /// ..., data: [ ...request... ]}}`. Objek `data` di tengah itulah yang
  /// dikembalikan `ApiClient.get`; daftarnya ada di `data['data']`, dan
  /// keterangan paginasinya ada di objek yang sama (dibaca [PageMeta]).
  ///
  /// [currentUserId] dipakai menandai mana request milik user yang sedang
  /// login (lihat [IndentRequestItem.isMine]).
  ///
  /// Nama driver tidak dikirim endpoint ini (cuma `id_driver`), jadi daftar
  /// driver diambil bersamaan lalu dicocokkan. Daftar driver itu pelengkap:
  /// bila gagal, daftar request tetap tampil (lihat [_driverNames]).
  ///
  /// Melempar [ApiException] bila daftar request-nya yang gagal.
  Future<IndentRequestPage> fetchRequests({
    int page = 1,
    int? currentUserId,
  }) async {
    // Dua-duanya dimulai dulu baru ditunggu, supaya berjalan paralel.
    final driverNamesRequest = _driverNames(refresh: page == 1);
    final data = await _apiClient.get(
      Uri(path: ApiConfig.indent, queryParameters: {'page': '$page'})
          .toString(),
    );
    final driverNames = await driverNamesRequest;

    final rows = data['data'];
    if (rows is! List) {
      throw const ApiException.server(
        'The indent list was received, but its format was not recognized.',
      );
    }

    final items = <IndentRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(
          IndentRequestItem.fromJson(
            row,
            currentUserId: currentUserId,
            driverNames: driverNames,
          ),
        );
      } on FormatException catch (e) {
        // Satu baris cacat tidak boleh menghilangkan seluruh halaman.
        AppLogger.info('Melewati indent yang tidak bisa dibaca: $e');
      }
    }

    return IndentRequestPage(items: items, meta: PageMeta.fromJson(data));
  }

  /// Membuat request indent baru, atau memperbarui yang sudah ada bila [id]
  /// diisi — `POST /api/indent/vehicle/store` melayani keduanya (server
  /// membaca `id_recuitment`; ejaan itu memang begitu di API).
  ///
  /// [departureTime] dan [returnTime] berformat 'HH:mm'. Tanggal dikirim
  /// 'YYYY-MM-DD' (format permintaan; berbeda dari format tampilan di layar).
  ///
  /// [withDriver] dikirim sebagai 1 atau 0, sama dengan nilai kolom `driver`
  /// yang terbaca di `GET /api/indent`. Dokumen API memberi contoh nama
  /// driver, tapi data asli berisi 0/1 — kalau server ternyata menolak,
  /// inilah satu-satunya baris yang perlu diubah.
  ///
  /// Isi respons tidak dipakai: layar memuat ulang daftar supaya yang
  /// tampil selalu data server (lengkap dengan nama dan status).
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi (pesan dari
  /// field yang salah pertama).
  Future<void> saveIndent({
    int? id,
    required DateTime date,
    required String departureTime,
    required String returnTime,
    required String destination,
    required String purpose,
    required bool withDriver,
  }) async {
    String two(int n) => n.toString().padLeft(2, '0');

    await _apiClient.post(
      ApiConfig.indentStore,
      body: {
        'tanggal': '${date.year}-${two(date.month)}-${two(date.day)}',
        'jam_pergi': departureTime,
        'jam_pulang': returnTime,
        'tujuan': destination,
        'keperluan': purpose,
        'driver': withDriver ? 1 : 0,
        if (id != null) 'id_recuitment': id,
      },
    );
  }

  /// Requester memberi rating (1-5) dan komentar opsional untuk perjalanan
  /// yang sudah selesai — `POST /api/indent/vehicle/store_rating`.
  ///
  /// `feedback_user` hanya dikirim bila ada komentar. Seperti
  /// [assignByAdmin], hanya status HTTP yang diperiksa; isi balasan
  /// (`{message, status, data}`) tidak dipakai karena layar memuat ulang
  /// daftar.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<void> submitRating({
    required int id,
    required int rating,
    String? feedback,
  }) =>
      _apiClient.postRaw(ApiConfig.indentStoreRating, body: {
        'id': id,
        'rating': rating,
        if (feedback != null) 'feedback_user': feedback,
      });

  /// Menghapus request milik sendiri — `DELETE /api/indent/{id}`.
  ///
  /// TODO(api): belum diketahui apakah server menolak hapus pada request yang
  /// sudah di-approve; sementara pembatasannya hanya di aplikasi.
  Future<void> deleteIndent(int id) =>
      _apiClient.delete('${ApiConfig.indent}/$id');

  /// Request yang menunggu keputusan atasan — `GET /api/list_hod_approve`
  /// (array polos). Server sendiri yang membatasi: hanya untuk role `hod`,
  /// hanya departemennya, dan hanya `approval_hod = 0`. Untuk akun lain
  /// server membalas 404 ("No Authentication user"), jadi pemanggil sebaiknya
  /// hanya memanggil ini untuk HOD.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<List<IndentApprovalItem>> fetchApprovals() async {
    final rows = await _apiClient.getRawList(ApiConfig.indentHodList);

    final items = <IndentApprovalItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(IndentApprovalItem.fromJson(row));
      } on FormatException catch (e) {
        AppLogger.info('Melewati approval yang tidak bisa dibaca: $e');
      }
    }
    return items;
  }

  /// HOD menyetujui request — `POST /api/indent/vehicle/approve_hod`. Setelah
  /// ini request masuk ke antrean admin (Pending Vehicle Assignment).
  Future<void> approveByHod(String id) =>
      _apiClient.postRaw(ApiConfig.indentHodApprove, body: {'id': _idBody(id)});

  /// HOD menolak request — `POST /api/indent/vehicle/reject_hod`. Request
  /// tetap berstatus 0; penolakannya ditandai `approval_hod = 2`.
  Future<void> rejectByHod(String id) =>
      _apiClient.postRaw(ApiConfig.indentHodReject, body: {'id': _idBody(id)});

  /// Server memakai id angka; id di layar berupa teks.
  Object _idBody(String id) => int.tryParse(id) ?? id;

  /// Request yang menunggu admin menetapkan kendaraan — `GET
  /// /api/indent/admin/list`, dibungkus `{data: [...], admin: bool}`.
  ///
  /// Isi endpoint ini bergantung role pemanggil: `admin` true hanya untuk
  /// `driver-admin`. Untuk akun lain (mis. `driver`, yang mendapat request
  /// yang ditugaskan kepadanya) hasilnya dibuang dan daftar kosong
  /// dikembalikan, karena itu bukan antrean assignment. Jadi bloc boleh
  /// memuat ini untuk semua akun tanpa perlu mencocokkan nama role.
  ///
  /// Baris yang ditolak HOD (`approval_hod = 2`) atau sudah bukan status 0
  /// dilewati sebagai pengaman, karena dokumentasi API kurang tegas soal
  /// filter di sisi server.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<List<IndentPendingItem>> fetchPendingAssignments() async {
    final envelope = await _apiClient.getEnvelope(ApiConfig.indentAdminList);
    if (envelope['admin'] != true) return const [];

    final rows = envelope['data'];
    if (rows is! List) {
      AppLogger.info('admin/list: data bukan list (${rows.runtimeType})');
      throw const ApiException.server();
    }

    final items = <IndentPendingItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      if (!_awaitsAssignment(row)) continue;

      try {
        items.add(IndentPendingItem.fromJson(row));
      } on FormatException catch (e) {
        AppLogger.info('Melewati pending yang tidak bisa dibaca: $e');
      }
    }
    return items;
  }

  /// Perjalanan yang ditugaskan ke driver yang sedang login — endpoint yang
  /// sama dengan [fetchPendingAssignments] (`GET /api/indent/admin/list`),
  /// tapi untuk akun `driver` isinya indent yang sudah di-approve HOD dan
  /// ditugaskan ke dirinya. Penyaringan per driver dilakukan server.
  ///
  /// `admin: true` berarti akun `driver-admin`: isinya antrean assignment,
  /// bukan tugas driver, jadi dibuang.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<List<IndentAssignedItem>> fetchDriverAssignments() async {
    final envelope = await _apiClient.getEnvelope(ApiConfig.indentAdminList);
    if (envelope['admin'] == true) return const [];

    final rows = envelope['data'];
    if (rows is! List) {
      AppLogger.info('admin/list: data bukan list (${rows.runtimeType})');
      throw const ApiException.server();
    }

    final items = <IndentAssignedItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      if (!_isActiveTrip(row)) continue;

      try {
        items.add(IndentAssignedItem.fromJson(row));
      } on FormatException catch (e) {
        AppLogger.info('Melewati tugas driver yang tidak bisa dibaca: $e');
      }
    }
    return items;
  }

  /// Pengaman bila server mengirim lebih dari yang dijanjikan dokumentasi:
  /// buang yang ditolak HOD, yang statusnya bukan "sedang jalan" (1), dan
  /// yang sudah ditutup driver (`date_close` terisi).
  static bool _isActiveTrip(Map<String, dynamic> row) {
    if (indentInt(row['approval_hod']) == 2) return false;

    final status = indentInt(row['status']);
    if (status != null && status != 1) return false;

    return row['date_close'] == null ||
        row['date_close'].toString().trim().isEmpty;
  }

  static bool _awaitsAssignment(Map<String, dynamic> row) {
    if (indentInt(row['approval_hod']) == 2) return false;

    final status = indentInt(row['status']);
    return status == null || status == 0;
  }

  /// Admin menetapkan kendaraan (dan driver, bila request memakai driver)
  /// — `POST /api/admin_indent/approve` dengan `status: 1`. Request lalu
  /// keluar dari antrean pending.
  ///
  /// `driver` dan `id_driver` hanya dikirim bila ada. Hanya status HTTP
  /// yang diperiksa (bentuk respons endpoint ini tidak seragam dengan yang
  /// lain), jadi gagal-tidaknya penugasan tidak bergantung pada isi balasan.
  Future<void> assignByAdmin({
    required String id,
    required String plateNumber,
    int? driverId,
    String? driverName,
  }) =>
      _apiClient.postRaw(ApiConfig.indentAdminApprove, body: {
        'id': _idBody(id),
        'status': 1,
        'kendaraan': plateNumber,
        if (driverId != null) 'id_driver': driverId,
        if (driverName != null) 'driver': driverName,
      });

  /// Driver menutup request setelah perjalanan selesai —
  /// `POST /api/driver_indent/close_request`.
  ///
  /// Server hanya mengisi `date_close`; `status` tetap 1. Status baru jadi 3
  /// setelah requester memberi rating (`store_rating`). Dokumentasi API
  /// menulis sebaliknya, tapi perilaku server yang berlaku adalah yang ini.
  ///
  /// Hanya status HTTP yang diperiksa, seperti [assignByAdmin].
  Future<void> closeRequest(String id) => _apiClient.postRaw(
        _closeRequestPath,
        body: {'id': _idBody(id)},
      );

  // Boleh dipindah ke ApiConfig bila ingin seragam dengan endpoint lain.
  static const _closeRequestPath = '/api/driver_indent/close_request';

  /// id driver -> nama; kosong bila gagal. Tidak pernah melempar, karena
  /// kegagalan daftar driver tidak boleh membuat seluruh list request gagal.
  /// Hasil kosong akibat gagal tidak disimpan, jadi dicoba lagi lain kali.
  Future<Map<int, String>> _driverNames({required bool refresh}) async {
    final cached = _driverNamesCache;
    if (!refresh && cached != null) return cached;

    try {
      final drivers = await fetchDrivers();
      return _driverNamesCache = {for (final d in drivers) d.id: d.name};
    } on ApiException catch (e) {
      AppLogger.info('Daftar driver tidak dimuat untuk list indent: ${e.message}');
    } catch (e, stack) {
      AppLogger.error('Daftar driver gagal dimuat untuk list indent', e, stack);
    }
    return cached ?? const <int, String>{};
  }
}
