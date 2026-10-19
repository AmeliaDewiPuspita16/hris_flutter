import '../../../domain/indent_approval_item.dart';

/// Hal-hal yang bisa terjadi pada tab "Supervisor Approval".
sealed class IndentApprovalEvent {
  const IndentApprovalEvent();
}

/// Layar baru dibuka — muat daftar request yang menunggu keputusan atasan.
class IndentApprovalStarted extends IndentApprovalEvent {
  const IndentApprovalStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Coba lagi" saat gagal.
class IndentApprovalRefreshed extends IndentApprovalEvent {
  const IndentApprovalRefreshed();
}

/// Atasan menekan Approve ([approved] true) atau Reject (false) pada [item].
class IndentApprovalDecided extends IndentApprovalEvent {
  const IndentApprovalDecided({required this.item, required this.approved});

  final IndentApprovalItem item;
  final bool approved;
}
