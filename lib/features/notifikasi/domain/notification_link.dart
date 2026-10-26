/// Ke mana sebuah notifikasi server mengarah saat di-tap.
///
/// Dibaca dari data payload FCM, yang bentuknya sama persis dengan kolom
/// `data` di `GET /api/portal/apps/notifications` (lih.
/// MobilePushNotifier di backend):
/// `{notification_id, module, type, id, audience, filter?}` — semua string.
class NotificationLink {
  const NotificationLink({
    required this.module,
    required this.type,
    required this.audience,
    this.notificationId,
    this.refId,
    this.filter,
  });

  static const moduleItRequest = 'it_request';
  static const moduleEprocurement = 'eprocurement';
  static const moduleEstWorkOrder = 'est_work_order';
  static const moduleIndentVehicle = 'indent_vehicle';

  /// `it_request` | `eprocurement` | `est_work_order` | `indent_vehicle`.
  final String module;

  /// Apa yang terjadi, mis. `approval_needed`, `approved`, `new_task`.
  final String type;

  /// Layar siapa yang dibuka: `approver` (antrean approval), `requester`
  /// (request milik sendiri), atau `handler` (petugas yang mengerjakan).
  final String audience;

  /// id baris di tabel notifikasi server, untuk ditandai sudah dibaca.
  final int? notificationId;

  /// id request di modul asalnya.
  final int? refId;

  /// Khusus eProcurement: kode chip status level approval, mis.
  /// `pending_hod` (lih. `PrStatusCode`).
  final String? filter;

  bool get isApprover => audience == 'approver';
  bool get isHandler => audience == 'handler';

  /// Null kalau payload bukan dari notifikasi portal (tanpa `module`), mis.
  /// pesan uji dari Firebase console.
  static NotificationLink? fromData(Map<String, dynamic> data) {
    final module = data['module']?.toString() ?? '';
    if (module.isEmpty) return null;

    final filter = data['filter']?.toString() ?? '';

    return NotificationLink(
      module: module,
      type: data['type']?.toString() ?? '',
      audience: data['audience']?.toString() ?? 'requester',
      notificationId: int.tryParse(data['notification_id']?.toString() ?? ''),
      refId: int.tryParse(data['id']?.toString() ?? ''),
      filter: filter.isEmpty ? null : filter,
    );
  }
}
