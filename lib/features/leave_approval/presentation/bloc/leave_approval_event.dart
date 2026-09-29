import '../../domain/leave_approval_status.dart';

/// Hal-hal yang bisa terjadi di halaman Leave Approvals.
sealed class LeaveApprovalEvent {
  const LeaveApprovalEvent();
}

/// Layar baru dibuka — muat daftar.
class LeaveApprovalStarted extends LeaveApprovalEvent {
  const LeaveApprovalStarted();
}

/// Tarik-untuk-muat-ulang atau tombol coba lagi.
class LeaveApprovalRefreshed extends LeaveApprovalEvent {
  const LeaveApprovalRefreshed();
}

/// Approver menekan konfirmasi Approve/Reject pada satu pengajuan.
class LeaveApprovalDecided extends LeaveApprovalEvent {
  const LeaveApprovalDecided(this.id, this.decision, {this.note});

  final String id;
  final LeaveApprovalDecision decision;
  final String? note;
}
