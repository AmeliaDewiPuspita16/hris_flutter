import '../../../../../core/utils/json_value.dart';
import 'indent_approve_status.dart';
import 'indent_json.dart';
import 'indent_progress_status.dart';

/// Satu baris di tabel "List of User Requests" (web: kolom No, Name,
/// Destination, Date, Remark, Vehicle, Approve, Status, Driver, Action).
class IndentRequestItem {
  const IndentRequestItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    required this.approve,
    required this.status,
    this.vehicle,
    this.driver,
    this.rating,
    this.withDriver = true,
    this.isMine = true,
    this.closed = false,
  });

  /// Pengenal unik request (bukan nomor urut). Nomor "No" di web tidak
  /// ditampilkan di mobile, jadi yang disimpan cukup id-nya.
  final String id;
  final String name;
  final String destination;

  /// Tanggal pemakaian, mis. '08-10-2026'.
  final String date;

  /// Rentang jam, mis. '01:00:00 s/d 14:30:00'.
  final String timeRange;
  final String remark;

  /// Plat nomor. Null selama kendaraan belum ditetapkan (request masih
  /// menunggu approval) — di web kolomnya kosong.
  final String? vehicle;

  final IndentApproveStatus approve;
  final IndentProgressStatus status;

  /// Null = belum ada driver ('N/A' di web).
  final String? driver;

  /// Bintang 1-5 dari requester. Cuma terisi kalau [status] sudah
  /// [IndentProgressStatus.done] (kolom "Action" di web).
  final int? rating;

  /// Jawaban requester di form Add Indent ("With Driver"). Dipakai untuk
  /// membedakan "tanpa driver" dari "driver belum ditunjuk" saat [driver]
  /// masih null.
  final bool withDriver;

  /// True kalau request ini milik user yang sedang login. `GET /api/indent`
  /// berisi request SEMUA user, jadi hak edit/hapus dan banner feedback
  /// harus dibatasi ke milik sendiri. Default true supaya data demo dan
  /// request yang baru dibuat lewat form tetap dianggap milik sendiri.
  final bool isMine;

  /// True kalau driver sudah menutup request (`date_close` terisi). Server
  /// TIDAK mengubah `status` saat ditutup: status tetap 1 (On Progress) dan
  /// baru menjadi 3 (Done) ketika requester memberi rating lewat
  /// `store_rating`. Jadi "perjalanan selesai, menunggu feedback" =
  /// status 1 + [closed], bukan status 3.
  final bool closed;

  /// True kalau perjalanan sudah selesai (ditutup driver) tapi request
  /// MILIK SENDIRI belum memberi rating. Dipakai untuk menampilkan banner
  /// feedback; tidak memblokir pengajuan request baru.
  bool get needsFeedback =>
      isMine &&
      rating == null &&
      (status == IndentProgressStatus.done ||
          (status == IndentProgressStatus.onProgress && closed));

  /// boleh diedit/dihapus requester selama atasan belum meng-approve.
  bool get canModify => isMine && approve == IndentApproveStatus.onWaiting;

  IndentRequestItem copyWith({
    String? name,
    String? destination,
    String? date,
    String? timeRange,
    String? remark,
    IndentApproveStatus? approve,
    IndentProgressStatus? status,
    int? rating,
    bool? withDriver,
  }) {
    return IndentRequestItem(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      timeRange: timeRange ?? this.timeRange,
      remark: remark ?? this.remark,
      approve: approve ?? this.approve,
      status: status ?? this.status,
      vehicle: vehicle,
      driver: driver,
      rating: rating ?? this.rating,
      withDriver: withDriver ?? this.withDriver,
      isMine: isMine,
      closed: closed,
    );
  }

  /// Memetakan satu objek di `data.data` milik `GET /api/indent`
  /// (respons berpaginasi):
  ///
  /// ```json
  /// { "id": 4666, "id_user": 121, "tanggal_pemakaian": "2026-10-16",
  ///   "jam_pergi": "13:45:00", "jam_pulang": "14:45:00",
  ///   "tujuan": "...", "keperluan": "...", "kendaraan": "BP 1512 FB",
  ///   "driver": 1, "id_driver": 113, "rating": 0,
  ///   "status": 1, "approval_hod": 1, "name": "Mahyuddin", ... }
  /// ```
  ///
  /// Catatan membaca field-nya:
  /// - `name` = nama peminta;
  /// - tidak ada nama driver, cuma `id_driver` (null bila belum ditunjuk) —
  ///   dicocokkan lewat [driverNames] (id driver -> nama, dari list_driver);
  /// - `driver` berisi angka penanda "With Driver" (bukan nama);
  /// - `rating` 0 = belum diberi rating;
  /// - `date_close` (jam, mis. '14:11:27') terisi saat driver menutup
  ///   request; null sebelum itu (lihat [closed]).
  ///
  /// [currentUserId] dipakai untuk menandai request milik sendiri
  /// ([isMine]).
  ///
  /// Melempar [FormatException] bila `id` tidak ada.
  factory IndentRequestItem.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
    Map<int, String> driverNames = const {},
  }) {
    final id = indentInt(json['id']);
    if (id == null) throw const FormatException('Indent tanpa id');

    final userId = indentInt(json['id_user']);
    final isMine = currentUserId != null && userId == currentUserId;

    // id_driver 0 = belum ada driver yang ditunjuk. Kalau ada tapi namanya
    // tidak ketemu di daftar driver, tampilkan id-nya daripada kosong yang
    // menyesatkan ("belum ditunjuk").
    final idDriver = indentInt(json['id_driver']) ?? 0;
    final driverName = idDriver > 0
        ? (driverNames[idDriver] ?? 'Driver #$idDriver')
        : null;

    final rating = indentInt(json['rating']);

    return IndentRequestItem(
      id: '$id',
      name: textOrNull(json['name']) ??
          (userId == null ? '-' : 'User #$userId'),
      destination: textOrNull(json['tujuan']) ?? '-',
      date: indentDate(json['tanggal_pemakaian']),
      timeRange: indentTimeRange(json),
      remark: textOrNull(json['keperluan']) ?? '-',
      vehicle: textOrNull(json['kendaraan']),
      driver: driverName,
      rating: rating != null && rating > 0 ? rating : null,
      approve: _approveFrom(json['approval_hod']),
      status: _progressFrom(json['status']),
      withDriver: indentWithDriver(json['driver']),
      isMine: isMine,
      closed: textOrNull(json['date_close']) != null,
    );
  }

  static IndentApproveStatus _approveFrom(dynamic value) => switch (indentInt(value)) {
        1 => IndentApproveStatus.approved,
        2 => IndentApproveStatus.rejected,
        _ => IndentApproveStatus.onWaiting,
      };

  static IndentProgressStatus _progressFrom(dynamic value) => switch (indentInt(value)) {
        1 => IndentProgressStatus.onProgress,
        3 => IndentProgressStatus.done,
        5 => IndentProgressStatus.cancelled,
        _ => IndentProgressStatus.onWaiting,
      };
}
