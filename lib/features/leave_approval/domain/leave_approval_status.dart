/// Status sebuah pengajuan dari sisi approver.
enum LeaveApprovalStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const LeaveApprovalStatus(this.label);

  final String label;
}

/// Keputusan yang bisa diambil approver atas pengajuan yang masih pending.
enum LeaveApprovalDecision { approve, reject }
