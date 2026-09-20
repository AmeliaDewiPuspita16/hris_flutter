/// Rencana kerja yang disusun tim EST untuk satu request — isi modal
/// "Response Request" yang dibuka lewat tombol hijau "Maintenance Plan"

class EstMaintenancePlan {
  const EstMaintenancePlan({
    required this.workingMethod,
    required this.materialAndTools,
    required this.approvalNote,
  });

  final String workingMethod;
  final String materialAndTools;

  /// Baris kecil di bawah kartu rencana, mis. "Wait Approval Section Head" —
  /// status approval internal tim EST atas rencana ini.
  final String approvalNote;
}
