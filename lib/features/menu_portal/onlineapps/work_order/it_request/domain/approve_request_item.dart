/// satu permintaan yang menunggu keputusan (approve/reject) tim IT
class ApproveRequestItem {
  const ApproveRequestItem({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.description,
    this.supportType,
  });

  final String id;
  final String requesterName;
  final String department;
  final String description;

  /// Jenis dukungan seperti kolom Support Type di web, mis.
  /// `IT (PERMINTAAN)` atau `Media (PERMINTAAN)`. Null bila tidak diketahui.
  final String? supportType;
}
