/// Status sebuah pengajuan dari sisi approver.
enum LeaveApprovalStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),

  /// HRIS `VO`: voided. HRIS does not say whether it was rejected or
  /// cancelled, so it is not shown as either.
  voided('Voided');

  const LeaveApprovalStatus(this.label);

  final String label;
}

/// Keputusan yang bisa diambil approver atas pengajuan yang masih pending.
enum LeaveApprovalDecision { approve, reject }
