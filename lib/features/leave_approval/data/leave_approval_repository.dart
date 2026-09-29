import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/leave_approval_demo_data.dart';
import '../domain/leave_approval_request.dart';
import '../domain/leave_approval_status.dart';

/// Sumber data halaman Leave Approvals: daftar pengajuan bawahan yang masuk
/// ke HOD, dan keputusan approve/reject atasnya.
///
/// BELUM ada endpoint approval HRIS — method di bawah bekerja di atas daftar
/// dummy yang disimpan di memori. Karena itu HARUS ada satu instance yang
/// dipakai bersama (dipegang `BerandaScreen`): keputusan yang diambil di
/// halaman approval jadi tercermin di angka badge Beranda dan menu HRIS.
///
/// [ApiClient] sudah disuntik lebih dulu (pola sama dengan
/// `PengajuanRepository`) supaya saat endpoint siap, hanya isi method ini
/// yang diganti jadi `_apiClient.get(...)` / `.post(...)` — bloc, screen,
/// dan widget tidak perlu ikut berubah.
class LeaveApprovalRepository {
  LeaveApprovalRepository({
    required ApiClient apiClient,
    List<LeaveApprovalRequest>? initial,
  })  : _apiClient = apiClient,
        _items = List.of(initial ?? LeaveApprovalDemoData.requests());

  // ignore: unused_field
  final ApiClient _apiClient;

  final List<LeaveApprovalRequest> _items;

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Semua pengajuan yang menjadi tanggung jawab approver ini — yang masih
  /// pending maupun yang sudah diputuskan. Pemisahan tab Pending/History
  /// dilakukan di layar.
  Future<List<LeaveApprovalRequest>> fetchRequests() async {
    await Future.delayed(_simulatedLatency);
    return List.unmodifiable(_items);
  }

  /// Jumlah yang masih pending, untuk badge di Beranda dan menu HRIS tanpa
  /// perlu memuat seluruh daftar.
  Future<int> fetchPendingCount() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _items.where((r) => r.isPending).length;
  }

  /// Menyetujui atau menolak satu pengajuan, mengembalikan versi terbarunya.
  ///
  /// [note] catatan approver; untuk penolakan layar mewajibkannya supaya
  /// pemohon tahu alasannya.
  ///
  /// Melempar [ApiException] bila pengajuan tidak ditemukan atau sudah
  /// diputuskan (mis. oleh approver lain).
  Future<LeaveApprovalRequest> decide(
    String id, {
    required LeaveApprovalDecision decision,
    String? note,
  }) async {
    await Future.delayed(_simulatedLatency);

    final index = _items.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw const ApiException.server('Request not found.');
    }

    final current = _items[index];
    if (!current.isPending) {
      throw const ApiException.server(
        'This request has already been processed.',
      );
    }

    final trimmed = note?.trim();
    final updated = current.copyWith(
      status: decision == LeaveApprovalDecision.approve
          ? LeaveApprovalStatus.approved
          : LeaveApprovalStatus.rejected,
      decidedBy: 'You',
      decidedAt: DateTime.now(),
      decisionNote: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );

    _items[index] = updated;
    return updated;
  }
}
