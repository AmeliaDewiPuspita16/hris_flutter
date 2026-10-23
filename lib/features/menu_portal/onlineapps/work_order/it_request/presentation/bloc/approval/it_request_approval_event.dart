import '../../../domain/approve_request_item.dart';

/// Hal-hal yang bisa terjadi pada tab "Approve Request".
sealed class ItRequestApprovalEvent {
  const ItRequestApprovalEvent();
}

/// Layar baru dibuka — muat antrean HOD.
class ItRequestApprovalStarted extends ItRequestApprovalEvent {
  const ItRequestApprovalStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Retry" saat gagal.
class ItRequestApprovalRefreshed extends ItRequestApprovalEvent {
  const ItRequestApprovalRefreshed();
}

/// HOD menekan Approve ([approved] true) atau Reject (false) pada [item].
/// [reason] hanya dipakai saat reject, dan boleh kosong.
class ItRequestApprovalDecided extends ItRequestApprovalEvent {
  const ItRequestApprovalDecided({
    required this.item,
    required this.approved,
    this.reason,
  });

  final ApproveRequestItem item;
  final bool approved;
  final String? reason;
}
