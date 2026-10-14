import 'indent_approve_status.dart';
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

  /// True kalau perjalanan sudah selesai tapi request belum memberi
  /// rating. Dipakai untuk menampilkan banner feedback; tidak memblokir
  /// pengajuan request baru.
  bool get needsFeedback =>
      status == IndentProgressStatus.done && rating == null;

  /// boleh diedit/dihapus requester selama atasan belum meng-approve.
  bool get canModify => approve == IndentApproveStatus.onWaiting;

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
    );
  }
}
