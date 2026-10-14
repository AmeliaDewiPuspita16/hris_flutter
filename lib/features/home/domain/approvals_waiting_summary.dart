/// Ringkasan `GET /api/portal/apps/notifications/approvals-waiting`, dipecah
/// per modul. Leave TIDAK termasuk di sini — jumlahnya datang dari
/// `LeaveApprovalRepository` sendiri, lihat catatan di [ApprovalsWaitingSummary].
class ApprovalsWaitingSummary {
  const ApprovalsWaitingSummary({
    required this.total,
    required this.itRequest,
    required this.estWorkOrder,
    required this.indentVehicle,
    required this.eprocurement,
  });

  /// Dipakai sebelum respons pertama datang / saat gagal dimuat, supaya
  /// layar tidak perlu menangani null terpisah.
  static const empty = ApprovalsWaitingSummary(
    total: 0,
    itRequest: 0,
    estWorkOrder: 0,
    indentVehicle: 0,
    eprocurement: 0,
  );

  final int total;
  final int itRequest;
  final int estWorkOrder;
  final int indentVehicle;
  final int eprocurement;

  factory ApprovalsWaitingSummary.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    final cat = categories is Map<String, dynamic> ? categories : const <String, dynamic>{};

    return ApprovalsWaitingSummary(
      total: _readInt(json, 'total'),
      itRequest: _readInt(cat, 'it_request'),
      estWorkOrder: _readInt(cat, 'est_work_order'),
      indentVehicle: _readInt(cat, 'indent_vehicle'),
      eprocurement: _readInt(cat, 'eprocurement'),
    );
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}
