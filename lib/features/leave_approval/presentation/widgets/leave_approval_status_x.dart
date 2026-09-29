import '../../../../core/widgets/status_badge.dart';
import '../../domain/leave_approval_status.dart';

extension LeaveApprovalStatusUi on LeaveApprovalStatus {
  /// Pemetaan ke [AppStatus] milik `StatusBadge`: approved memakai gaya
  /// "present" (hijau), sama seperti badge Approved di tab Status Pengajuan.
  AppStatus get appStatus => switch (this) {
        LeaveApprovalStatus.pending => AppStatus.pending,
        LeaveApprovalStatus.approved => AppStatus.present,
        LeaveApprovalStatus.rejected => AppStatus.rejected,
      };
}
