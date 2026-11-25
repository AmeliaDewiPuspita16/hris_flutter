/// Izin aksi atas satu PR untuk user yang sedang login, dari objek
/// `approval` di respons detail `GET /api/portal/apps/eprocurement/{id}`.
///
/// Server yang menentukan, aplikasi hanya menampilkan. Izinnya berbeda per
/// PR, per tahap, dan per akun: misalnya di tahap Under Review tombol Reject
/// tidak tersedia, dan HOD department lain tidak boleh bertindak sama sekali.
class PrApprovalPermission {
  const PrApprovalPermission({
    this.canAct = false,
    this.canApprove = false,
    this.canRequestRevision = false,
    this.canReject = false,
  });

  /// Akun ini boleh bertindak pada PR ini sekarang.
  final bool canAct;

  final bool canApprove;
  final bool canRequestRevision;
  final bool canReject;

  /// Tidak boleh apa-apa. Dipakai bila objek `approval` tidak ada atau
  /// bentuknya tidak dikenali, supaya gagalnya aman (tombol tidak tampil).
  static const none = PrApprovalPermission();

  ///  Ada setidaknya satu tombol yang boleh tampil.
  bool get hasAnyAction => canApprove || canRequestRevision || canReject;

  factory PrApprovalPermission.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return none;
    return PrApprovalPermission(
      canAct: json['can_act'] == true,
      canApprove: json['can_approve'] == true,
      canRequestRevision: json['can_request_revision'] == true,
      canReject: json['can_reject'] == true,
    );
  }
}
