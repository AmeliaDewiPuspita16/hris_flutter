import '../../../domain/est_approval_item.dart';

/// Hal hal yang bisa terjadi pada tab "Approval HOD".
sealed class EstApprovalEvent {
  const EstApprovalEvent();
}

/// Layar baru dibuka - muat antrian HOD.
class EstApprovalStarted extends EstApprovalEvent {
  const EstApprovalStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Retry" saat gagal.
class EstApprovalRefreshed extends EstApprovalEvent {
  const EstApprovalRefreshed();
}

/// HOD menekan Approve ([approved] true) atau Reject (false) pada [item].
/// [reason] hanya dipakai saat reject, dan boleh kosong.
class EstApprovalDecided extends EstApprovalEvent {
  const EstApprovalDecided({
    required this.item,
    required this.approved,
    this.reason,
  });

  final EstApprovalItem item;
  final bool approved;
  final String? reason;
}
